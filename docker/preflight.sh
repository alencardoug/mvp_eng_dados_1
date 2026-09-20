#!/usr/bin/env bash
# Verificação de recursos antes de subir mais um subconjunto do ambiente.
#
# Trata o risco R11 (docs/riscos.md): Airbyte, Airflow, Redpanda e Kafka Connect
# simultâneos esgotam a memória da máquina local. A política de quais subconjuntos
# bastam a cada cenário vive em docs/execucao_local.md §5 — não é repetida aqui.
#
# Uso:  docker/preflight.sh <airbyte|airflow|streaming> [--trocar]
# Sai 0 se cabe, 1 se não cabe.
#
# Sem `--trocar` ele só observa e informa — é o modo de `make preflight`, que
# precisa poder ser rodado sem efeito nenhum. Com `--trocar`, que é como os
# alvos `*-up` o chamam, ele **pausa** o ambiente conflitante em vez de recusar:
# `docker stop`, que devolve a memória inteira, preserva contêiner e dados e
# volta em ~20 s. Nunca `down`/`uninstall` — desmontar é decisão de quem opera,
# e no caso do Airbyte custa uma reinstalação inteira (Execução Local §6).
#
# Os custos abaixo são MEDIDOS, e cada um cita onde o número vive (P5).
set -uo pipefail

# Resolução de contêineres por rótulo do Compose — dono único do assunto, e a
# razão de o Airflow ter ficado invisível aqui até a Etapa 12 (RV12-2-03).
# shellcheck source=conteineres.sh
. "$(dirname "${BASH_SOURCE[0]}")/conteineres.sh"
# As armadilhas da CLI do Airflow — ruído no stdout, `dag_id` obrigatório, DAG
# repetida — vivem num arquivo só; aqui fica a política, não o transporte.
# shellcheck source=airflow_cli.sh
. "$(dirname "${BASH_SOURCE[0]}")/airflow_cli.sh"

ALVO="${1:?uso: preflight.sh <airbyte|airflow|streaming> [--trocar]}"
TROCAR=false
[ "${2:-}" = "--trocar" ] && TROCAR=true

# Prazos da verificação de trabalho em andamento (RV12-4-04). Sem eles,
# "não responde" não chega sozinho a desfecho nenhum: uma consulta pendurada
# pendura quem chamou. Expirar é **indeterminado**, e indeterminado é bloqueio.
PRAZO_CONSULTA="${PREFLIGHT_PRAZO_CONSULTA:-20}"
PRAZO_TOTAL="${PREFLIGHT_PRAZO_TOTAL:-90}"
AIRFLOW_PRAZO_CONSULTA="$PRAZO_CONSULTA"

# --- custos, em MB -----------------------------------------------------------
# Airbyte: PICO medido em 07/09/2026 durante `make sync-airbyte`, amostrando o
#          contêiner do cluster kind a cada 10 s: 4,95 GiB
#          (docs/capacidade_e_recuperacao.md §2.9). Ocioso ele fica
#          em ~3,6 GiB, mas o número que interessa é o pico: quem sobe o Airbyte
#          vai sincronizar, e autorizar pelo ocioso é autorizar um travamento
#          alguns minutos depois.
# Airflow: DERIVADO — os ~6 GB do batch (§2.3) menos o Airbyte e os três bancos.
#          Marcado como derivado de propósito: não foi medido isoladamente.
# Streaming: medido na Etapa 7 — Redpanda 51 MB + Kafka Connect 434 MB (§2.4).
#          O pipeline Beam roda fora dos contêineres e não está incluído aqui.
CUSTO_airbyte=5000
CUSTO_airflow=1400
CUSTO_streaming=485

# Folga que precisa sobrar para o host depois de subir. O ambiente de trabalho do
# Owner — VS Code, sessões de agente e navegador — foi medido em ~4 GB em
# 07/09/2026; abaixo de 1,5 GB livres a máquina entra em thrashing de swap e
# congela, que foi o incidente que originou esta verificação.
FOLGA_MINIMA=1500

# --- famílias ----------------------------------------------------------------
# Batch e streaming não sobem juntos (R11, §2.5); a Etapa 12 valida por partes (ADR-0046).
case "$ALVO" in
  airbyte|airflow) FAMILIA="batch" ;;
  streaming)       FAMILIA="streaming" ;;
  *) echo "preflight: alvo desconhecido '$ALVO' (use airbyte, airflow ou streaming)" >&2; exit 2 ;;
esac

custo_var="CUSTO_${ALVO}"
CUSTO="${!custo_var}"

# --- o que já está de pé -----------------------------------------------------
# O Airbyte continua sendo reconhecido pelo nome: o nó do cluster é criado pelo
# `abctl`, não pelo Compose, e `airbyte-abctl-control-plane` é nome declarado
# pela ferramenta. Airflow, streaming e bancos vêm de `resolver`, por rótulo.
_airbyte_no_ar() {
	docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'airbyte-abctl-control-plane'
}

# Um ambiente pelo nome, para reconsultar depois de agir sobre ele.
_ainda_no_ar() {
	case "$1" in
	Airbyte)   _airbyte_no_ar ;;
	Airflow)   [ -n "$(resolver @airflow)" ] ;;
	streaming) [ -n "$(resolver @streaming)" ] ;;
	*) return 1 ;;
	esac
}

# Parar e religar respondem pelo **estado resultante**, não pelo código de saída
# do `docker`. O código não basta: `xargs` sobre lista vazia sai 0 sem parar
# nada, e uma parada parcial deixa metade do ambiente de pé. Anunciar "pausado"
# sem conferir é pior que não pausar — o preflight libera o alvo achando que
# desfez o conflito, e os dois ambientes sobem juntos, que é o R11.
_parar() {
	local nomes=""
	case "$1" in
	streaming) nomes=$(resolver @streaming) ;;
	Airflow)   nomes=$(resolver @airflow) ;;
	Airbyte)   nomes=airbyte-abctl-control-plane ;;
	esac
	# shellcheck disable=SC2086
	[ -n "$nomes" ] && docker stop $nomes >/dev/null 2>&1
	! _ainda_no_ar "$1"
}

_religar() {
	local nomes=""
	case "$1" in
	streaming) nomes=$(resolver --todos @streaming) ;;
	Airflow)   nomes=$(resolver --todos @airflow) ;;
	Airbyte)   nomes=airbyte-abctl-control-plane ;;
	esac
	# shellcheck disable=SC2086
	[ -n "$nomes" ] && docker start $nomes >/dev/null 2>&1
	_ainda_no_ar "$1"
}

# Desfaz as pausas já feitas. Restauração que falha é dita em voz alta e por
# nome: o ambiente ficou pior do que estava, e quem opera precisa saber qual.
_restaurar() {
	local nome
	for nome in "$@"; do
		if _religar "$nome"; then
			echo "[preflight] $nome restaurado."
		else
			echo "[preflight] ATENÇÃO: falhei em restaurar $nome — ele ficou parado."
		fi
	done
}

# Trabalho em andamento no ambiente que seria pausado. Pausar é barato para um
# serviço ocioso e caro para um que está no meio de alguma coisa: `docker stop`
# durante uma sincronização a mata, e durante uma DAG mata a execução. Ecoa a
# descrição do que está rodando, ou nada.
#
# Falha de verificação NÃO é sinônimo de "não há trabalho": se o comando não
# responde, o retorno é "indeterminado" e quem chama trata como bloqueio. Perder
# uma sincronização silenciosamente é pior que uma recusa a mais.
# A consulta de trabalho do Airflow, escrita por inteiro (RV12-3-03, RV12-4-04):
#
# - **por DAG, porque o Airflow 3.2.2 exige `dag_id`** — sem ele a CLI sai com
#   código 2, e o "corrigido só o nome" do preflight recusaria toda troca;
# - **o conjunto de DAGs é lido, não fixado**, com os repetidos descartados: a
#   versão instalada devolve a mesma DAG seis vezes, e a segunda DAG do projeto
#   não pode depender de alguém lembrar de editar este arquivo;
# - **DAG pausada não é DAG ociosa** — `is_paused` não é filtro aqui;
# - **`queued` conta como trabalho**: a CLI filtra o estado exato, e uma
#   execução enfileirada pode começar entre esta consulta e o `docker stop`;
# - **prazo por consulta e prazo total**: expirar é indeterminado, que bloqueia.
#
# Enumerar DAGs **não** é medir a saúde do scheduler: o comando lê os metadados.
# O que esta função afirma é "não há execução conhecida", não "o processo vive".
_airflow_trabalho_ativo() {
	local inicio bruto dags dag estado run
	airflow_scheduler >/dev/null || {
		echo "indeterminado — não resolvi o contêiner do scheduler pelos rótulos do Compose"
		return
	}
	inicio=$SECONDS

	bruto=$(airflow_cli dags list -o json) \
		|| { echo "indeterminado — enumeração de DAGs não respondeu no prazo de ${PRAZO_CONSULTA}s"; return; }
	case "$(airflow_forma_da_lista "$bruto")" in
	vazia) return ;;   # nenhuma DAG registrada — ocioso
	lista) ;;
	*) echo "indeterminado — enumeração de DAGs ilegível"; return ;;
	esac

	dags=$(printf '%s\n' "$bruto" | airflow_limpar_log | airflow_dag_ids)
	[ -z "$dags" ] && { echo "indeterminado — enumeração sem dag_id legível"; return; }

	for dag in $dags; do
		for estado in queued running; do
			if [ $((SECONDS - inicio)) -ge "$PRAZO_TOTAL" ]; then
				echo "indeterminado — prazo total de ${PRAZO_TOTAL}s esgotado na verificação"
				return
			fi
			bruto=$(airflow_cli dags list-runs "$dag" --state "$estado" -o json) \
				|| { echo "indeterminado — consulta de execuções '$estado' da DAG $dag não respondeu"; return; }
			case "$(airflow_forma_da_lista "$bruto")" in
			vazia) ;;
			lista)
				run=$(airflow_campo "$bruto" run_id)
				echo "DAG $dag com execução $estado${run:+ ($run)}"
				return ;;
			*) echo "indeterminado — resposta ilegível para a DAG $dag no estado $estado"; return ;;
			esac
		done
	done
}

_trabalho_ativo() {
	case "$1" in
	Airbyte)
		local pods
		pods=$(timeout "$PRAZO_CONSULTA" docker exec airbyte-abctl-control-plane \
			crictl pods --state Ready 2>/dev/null) \
			|| { echo "indeterminado — cluster não respondeu no prazo de ${PRAZO_CONSULTA}s"; return; }
		echo "$pods" | grep -qE "replication-job|orchestrator-repl" \
			&& echo "sincronização em andamento"
		;;
	Airflow)
		_airflow_trabalho_ativo
		;;
	streaming)
		# O pipeline Beam roda fora dos contêineres, no processo Python do host
		# (Capacidade §2.4) — parar o transporte sob ele o quebra.
		pgrep -f "mvp_ed1[.]streaming" >/dev/null 2>&1 \
			&& echo "pipeline Beam ou produtor em primeiro plano"
		;;
	esac
}

AIRBYTE_NO_AR=false;   _ainda_no_ar Airbyte   && AIRBYTE_NO_AR=true
AIRFLOW_NO_AR=false;   _ainda_no_ar Airflow   && AIRFLOW_NO_AR=true
STREAMING_NO_AR=false; _ainda_no_ar streaming && STREAMING_NO_AR=true

DE_PE=(); CONFLITO=()
$AIRBYTE_NO_AR   && DE_PE+=("Airbyte (cluster kind)")
$AIRFLOW_NO_AR   && DE_PE+=("Airflow")
$STREAMING_NO_AR && DE_PE+=("streaming (Redpanda + Kafka Connect)")

if [ "$FAMILIA" = "batch" ] && $STREAMING_NO_AR; then
  CONFLITO+=("streaming:make stream-resume")
fi
if [ "$FAMILIA" = "streaming" ]; then
  $AIRBYTE_NO_AR && CONFLITO+=("Airbyte:make airbyte-resume")
  $AIRFLOW_NO_AR && CONFLITO+=("Airflow:make airflow-resume")
fi

# --- memória -----------------------------------------------------------------
DISPONIVEL=$(awk '/^MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
PROJECAO=$((DISPONIVEL - CUSTO))

_gb() { awk -v m="$1" 'BEGIN {printf "%.1f GB", m/1024}'; }

echo "[preflight] RAM disponível agora: $(_gb "$DISPONIVEL")"
if [ ${#DE_PE[@]} -gt 0 ]; then
  echo "[preflight] Já de pé: $(IFS='; '; echo "${DE_PE[*]}")"
else
  echo "[preflight] Já de pé: nada além dos bancos"
fi
echo "[preflight] '$ALVO' custa ~$(_gb "$CUSTO") — sobraria $(_gb "$PROJECAO")"

# --- veredito ----------------------------------------------------------------
RECUSA=""
if [ ${#CONFLITO[@]} -gt 0 ]; then
  RECUSA="batch e streaming não sobem juntos (R11; a validação é por partes, ADR-0046)"
elif [ "$PROJECAO" -lt "$FOLGA_MINIMA" ]; then
  RECUSA="sobraria menos que a folga mínima de $(_gb "$FOLGA_MINIMA") para o host"
fi

# Com --trocar, conflito de família não é recusa: é troca. Pausa o outro
# ambiente, devolve a memória e remede antes de decidir.
if [ ${#CONFLITO[@]} -gt 0 ] && $TROCAR; then
  # Nada é pausado antes de todos serem verificados: pausar metade e desistir na
  # outra deixa o ambiente pior do que estava.
  for c in "${CONFLITO[@]}"; do
    nome="${c%%:*}"
    ocupado=$(_trabalho_ativo "$nome")
    if [ -n "$ocupado" ]; then
      echo ""
      echo "RECUSADO — $nome tem trabalho em andamento: $ocupado."
      echo "  Pausar agora o mataria no meio, sem deixar rastro do que se perdeu."
      echo ""
      echo "  Espere terminar e rode de novo, ou pause você mesmo quando puder:"
      case "$nome" in
        streaming) echo "    make stream-pause" ;;
        Airbyte)   echo "    make airbyte-pause" ;;
        Airflow)   echo "    make airflow-pause" ;;
      esac
      echo ""
      echo "  FORCE=1 sobe assim mesmo, sem pausar nada — e aí os dois ambientes"
      echo "  ficam de pé juntos, que é o que o R11 diz não caber."
      exit 1
    fi
  done

  PAUSADOS=()
  FALHOU=""
  for c in "${CONFLITO[@]}"; do
    nome="${c%%:*}"
    echo "[preflight] $nome está de pé e ocioso — pausando."
    if ! _parar "$nome"; then
      FALHOU="$nome"
      echo "[preflight] falhei em pausar $nome — ele continua de pé."
      break
    fi
    PAUSADOS+=("$nome")
    echo "[preflight] $nome pausado — retomar com ${c#*:}"
  done

  # Pausa que não aconteceu não elimina conflito. Recua tudo e recusa: liberar o
  # alvo aqui subiria o segundo ambiente por cima do primeiro.
  if [ -n "$FALHOU" ]; then
    [ ${#PAUSADOS[@]} -gt 0 ] && _restaurar "${PAUSADOS[@]}"
    echo ""
    echo "RECUSADO — não consegui pausar $FALHOU, e ele continua de pé."
    echo "  Subir '$ALVO' em cima dele é o que o R11 diz não caber."
    echo ""
    echo "  Veja o que houve e pause você mesmo:"
    case "$FALHOU" in
      streaming) echo "    docker stop \$(docker/conteineres.sh resolver @streaming)" ;;
      Airbyte)   echo "    docker stop airbyte-abctl-control-plane" ;;
      Airflow)   echo "    docker stop \$(docker/conteineres.sh resolver @airflow)" ;;
    esac
    exit 1
  fi

  # O kernel não devolve a memória no instante do stop; espera estabilizar.
  ANTES="$DISPONIVEL"
  for _ in $(seq 1 10); do
    sleep 2
    DISPONIVEL=$(awk '/^MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo)
    [ "$DISPONIVEL" -gt "$((ANTES + 200))" ] && break
  done

  PROJECAO=$((DISPONIVEL - CUSTO))
  CONFLITO=()
  echo "[preflight] RAM disponível agora: $(_gb "$DISPONIVEL") — sobraria $(_gb "$PROJECAO")"
  RECUSA=""
  if [ "$PROJECAO" -lt "$FOLGA_MINIMA" ]; then
    # Pausar e desistir deixaria o ambiente pior do que estava: quem rodou o
    # alvo não pediu para derrubar nada, pediu para subir. Desfaz.
    echo "[preflight] não cabe mesmo assim — restaurando o que foi pausado."
    [ ${#PAUSADOS[@]} -gt 0 ] && _restaurar "${PAUSADOS[@]}"
    RECUSA="mesmo depois de pausar $(IFS=' e '; echo "${PAUSADOS[*]}"), sobraria menos que a folga mínima de $(_gb "$FOLGA_MINIMA")"
  fi
fi

if [ -z "$RECUSA" ]; then
  echo "[preflight] OK"
  exit 0
fi

echo ""
echo "RECUSADO — $RECUSA."
echo "  A política de quais subconjuntos bastam está em docs/execucao_local.md §5."
echo ""
if [ ${#CONFLITO[@]} -gt 0 ]; then
  echo "  Pause primeiro:"
  for c in "${CONFLITO[@]}"; do
    n="${c%%:*}"
    case "$n" in streaming) cmd="make stream-pause";; Airbyte) cmd="make airbyte-pause";; Airflow) cmd="make airflow-pause";; esac
    printf '    %-38s (pausa %s; retomar com %s)\n' "$cmd" "$n" "${c#*:}"
  done
else
  echo "  Feche o que não está em uso — VS Code, navegador, sessões de agente —"
  echo "  ou derrube o que estiver de pé, e rode de novo."
fi
echo ""
echo "  Se ambos são mesmo necessários (reconciliar o CDC contra a"
echo "  carga completa), isto é uma PAUSA para o Owner liberar recursos:"
echo "  peça a ele, confirme, e então autorize com FORCE=1."
exit 1
