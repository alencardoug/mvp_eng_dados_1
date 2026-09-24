#!/usr/bin/env bash
# Verificação de recursos antes de subir mais um subconjunto do ambiente.
#
# Trata o risco R11 (docs/riscos.md): Airbyte, Airflow, Redpanda e Kafka Connect
# simultâneos esgotam a memória da máquina local. A política de quais subconjuntos
# bastam a cada cenário vive em docs/execucao_local.md §5 — não é repetida aqui.
#
# Uso:  docker/preflight.sh <airbyte|airflow|streaming> [--trocar]
#       docker/preflight.sh trabalho        só "há trabalho em andamento?"
# Sai 0 se cabe (ou se a janela está parada), 1 se não — e "não sei" é 1.
#
# Sem `--trocar` ele só observa e informa — é o modo de `make preflight`, que
# precisa poder ser rodado sem efeito nenhum. Com `--trocar`, que é como os
# alvos `*-up` o chamam, ele **pausa** o ambiente conflitante em vez de recusar:
# `docker stop`, que devolve a memória inteira, preserva contêiner e dados e
# volta sem reinstalar nada. Nunca `down`/`uninstall` — desmontar é decisão de
# quem opera, e no caso do Airbyte custa uma reinstalação inteira (Execução
# Local §6).
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
  trabalho)        FAMILIA="" ;;   # pergunta só sobre trabalho em andamento
  *) echo "preflight: alvo desconhecido '$ALVO' (use airbyte, airflow, streaming ou trabalho)" >&2; exit 2 ;;
esac

if [ "$ALVO" != trabalho ]; then
  custo_var="CUSTO_${ALVO}"
  CUSTO="${!custo_var}"
fi

# --- o que já está de pé -----------------------------------------------------
# O Airbyte continua sendo reconhecido pelo nome: o nó do cluster é criado pelo
# `abctl`, não pelo Compose, e `airbyte-abctl-control-plane` é nome declarado
# pela ferramenta. Airflow, streaming e bancos vêm de `resolver`, por rótulo.
#
# **Enumerar é pré-condição de decidir (RVE-08).** Se o `docker ps` falha, o
# estado é indeterminado — e indeterminado bloqueia. Tratar a falha como "não
# há nada de pé" liberava o pacote e a troca de ambiente sem conhecer o estado,
# e fazia uma parada não conferida passar por parada feita. Por isso as
# consultas abaixo têm **três** respostas: 0 de pé, 1 parado ou ausente, 4 não
# sei — e cada chamador trata a terceira por extenso.
_airbyte_no_ar() {
	local nomes
	nomes=$(docker ps --format '{{.Names}}' 2>/dev/null) || return 4
	printf '%s\n' "$nomes" | grep -qx 'airbyte-abctl-control-plane'
}

# Um ambiente pelo nome, para reconsultar depois de agir sobre ele.
_ainda_no_ar() {
	local nomes
	case "$1" in
	Airbyte)   _airbyte_no_ar ;;
	Airflow)   nomes=$(resolver @airflow) || return 4; [ -n "$nomes" ] ;;
	streaming) nomes=$(resolver @streaming) || return 4; [ -n "$nomes" ] ;;
	*) return 1 ;;
	esac
}

# Parar e religar respondem pelo **estado resultante**, não pelo código de saída
# do `docker`. O código não basta: `xargs` sobre lista vazia sai 0 sem parar
# nada, e uma parada parcial deixa metade do ambiente de pé. Anunciar "pausado"
# sem conferir é pior que não pausar — o preflight libera o alvo achando que
# desfez o conflito, e os dois ambientes sobem juntos, que é o R11. E "não
# consegui conferir" **não** é "parou": só o estado lido conta.
#
# O que estava de pé **antes** de cada pausa fica anotado por ambiente: é o
# conjunto que desfazer a pausa recompõe (RVE2-03).
declare -A ANTES_DA_PAUSA=()

_parar() {
	local nomes=""
	case "$1" in
	streaming) nomes=$(resolver @streaming) || return 1 ;;
	Airflow)   nomes=$(resolver @airflow) || return 1 ;;
	Airbyte)   nomes=airbyte-abctl-control-plane ;;
	esac
	ANTES_DA_PAUSA[$1]="$nomes"
	# shellcheck disable=SC2086
	[ -n "$nomes" ] && docker stop $nomes >/dev/null 2>&1
	_ainda_no_ar "$1"
	[ $? -eq 1 ]
}

# Religa **exatamente** o que estava de pé antes da pausa e confere que cada
# um voltou. Não "algum de pé" (RVE-11): um grupo recomposto pela metade é o
# mesmo defeito da pausa parcial, visto do outro lado. E não o grupo inteiro
# (RVE2-03): ele inclui o que já estava parado antes da troca, e desfazer uma
# troca recusada pelo R11 não pode terminar com **mais** de pé do que havia.
_religar() {
	local antes de_pe nome
	antes="${ANTES_DA_PAUSA[$1]:-}"
	[ -z "$antes" ] && return 0   # nada foi parado — nada a recompor
	# shellcheck disable=SC2086
	docker start $antes >/dev/null 2>&1
	case "$1" in
	Airbyte)   _ainda_no_ar Airbyte; return ;;
	streaming) de_pe=$(resolver @streaming) || return 1 ;;
	Airflow)   de_pe=$(resolver @airflow) || return 1 ;;
	esac
	for nome in $antes; do
		# shellcheck disable=SC2086
		printf '%s\n' $de_pe | grep -qxF -- "$nome" || return 1
	done
}

# Desfaz as pausas já feitas. Restauração que falha é dita em voz alta e por
# nome: o ambiente ficou pior do que estava, e quem opera precisa saber qual.
_restaurar() {
	local nome
	for nome in "$@"; do
		if _religar "$nome"; then
			echo "[preflight] $nome restaurado."
		else
			echo "[preflight] ATENÇÃO: falhei em restaurar $nome — ele ficou parado, ao menos em parte."
		fi
	done
}

# Processos do projeto no *host*: o pipeline Beam e o produtor rodam fora dos
# contêineres (Capacidade §2.4), e o produtor escreve na origem **com ou sem**
# Redpanda de pé. Conferir só quando o transporte está no ar deixava o produtor
# invisível justamente na janela do pacote (RVE-09). Ecoa a descrição ou nada;
# `pgrep` que não responde é indeterminado, não ausência.
_processos_no_host() {
	pgrep -f "mvp_ed1[.]streaming" >/dev/null 2>&1
	case $? in
	0) echo "pipeline Beam ou produtor no host" ;;
	1) ;;
	*) echo "indeterminado — pgrep não respondeu" ;;
	esac
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
		_processos_no_host
		;;
	esac
}

# --- só a pergunta do trabalho em andamento ----------------------------------
# `recovery-pack` e a manutenção da restauração precisam saber se há trabalho
# no ar — **não** se cabe subir mais um ambiente. Perguntar pelo alvo errado é
# o que fazia o pacote recusar com o Airbyte já de pé: o preflight somava os
# 4,9 GB de subir de novo o que já estava rodando.
if [ "$ALVO" = trabalho ]; then
  ATIVO=""
  for nome in Airbyte Airflow streaming; do
    _ainda_no_ar "$nome"
    case $? in
    0) ocupado=$(_trabalho_ativo "$nome") ;;
    1) continue ;;
    *) ocupado="indeterminado — não consegui enumerar os contêineres (o Docker respondeu?)" ;;
    esac
    [ -n "$ocupado" ] && ATIVO="$ATIVO\n  $nome: $ocupado"
  done
  # O host é consultado sempre, e não só com o transporte de pé (RVE-09).
  ocupado=$(_processos_no_host)
  [ -n "$ocupado" ] && ATIVO="$ATIVO\n  host: $ocupado"
  if [ -n "$ATIVO" ]; then
    echo "[preflight] há trabalho em andamento:"
    printf "%b\n" "$ATIVO"
    exit 1
  fi
  echo "[preflight] nenhum trabalho em andamento — janela parada."
  exit 0
fi

# Sem enumeração não há decisão: recusa antes de projetar memória ou pausar.
_estado() {  # $1 = ambiente; ecoa true, false ou indeterminado
  _ainda_no_ar "$1"
  case $? in 0) echo true ;; 1) echo false ;; *) echo indeterminado ;; esac
}
AIRBYTE_NO_AR=$(_estado Airbyte)
AIRFLOW_NO_AR=$(_estado Airflow)
STREAMING_NO_AR=$(_estado streaming)
for par in "Airbyte:$AIRBYTE_NO_AR" "Airflow:$AIRFLOW_NO_AR" "streaming:$STREAMING_NO_AR"; do
  [ "${par#*:}" = indeterminado ] || continue
  echo ""
  echo "RECUSADO — não consegui enumerar os contêineres de '${par%%:*}' (o Docker respondeu?)."
  echo "  Sem saber o que está de pé, subir '$ALVO' é subir às cegas — que é o R11."
  exit 1
done

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

# --- o alvo já de pé (D53) ---------------------------------------------------
# Subir o que já está inteiro de pé não acrescenta memória: o que ele ocupa já
# está fora do `MemAvailable`. Cobrar o custo de novo recusava `airbyte-up` com
# o cluster rodando — "sobraria 0,3 GB" com 5,2 GB livres, em 23/09/2026 — e
# mandava fechar programas quando a causa era a conta. De pé pela metade
# continua cobrado inteiro: o que falta subir custa, e não há medida por
# serviço para descontar o resto.
#
# A família não muda: o alvo de pé não autoriza a outra a continuar de pé
# junto, e a troca abaixo vale igual. Também não muda o que ninguém confere —
# o acréscimo de uma sincronização sobre o Airbyte ocioso, até o pico do custo
# acima: `sync-airbyte` nunca passou por aqui.
_inteiro_no_ar() {
	local servico nomes
	case "$1" in
	airbyte) $AIRBYTE_NO_AR ;;
	*)
		for servico in $(_expandir "@$1"); do
			nomes=$(resolver "$servico") || return 1
			[ -n "$nomes" ] || return 1
		done ;;
	esac
}
ALVO_DE_PE=false
_inteiro_no_ar "$ALVO" && ALVO_DE_PE=true
$ALVO_DE_PE && CUSTO=0

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
if $ALVO_DE_PE; then
  echo "[preflight] '$ALVO' já está de pé — nada a cobrar"
else
  echo "[preflight] '$ALVO' custa ~$(_gb "$CUSTO") — sobraria $(_gb "$PROJECAO")"
fi

# --- veredito ----------------------------------------------------------------
RECUSA=""
if [ ${#CONFLITO[@]} -gt 0 ]; then
  RECUSA="batch e streaming não sobem juntos (R11; a validação é por partes, ADR-0046)"
elif ! $ALVO_DE_PE && [ "$PROJECAO" -lt "$FOLGA_MINIMA" ]; then
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
  # alvo aqui subiria o segundo ambiente por cima do primeiro. O grupo que
  # falhou também é recomposto (RVE-11): `docker stop` pode ter parado três dos
  # quatro contêineres do Airflow antes de falhar no quarto, e "continua de pé"
  # não pode significar "de pé pela metade".
  if [ -n "$FALHOU" ]; then
    [ ${#PAUSADOS[@]} -gt 0 ] && _restaurar "${PAUSADOS[@]}"
    if [ -z "${ANTES_DA_PAUSA[$FALHOU]:-}" ]; then
      echo "[preflight] nada de $FALHOU chegou a ser parado."
    elif _religar "$FALHOU"; then
      echo "[preflight] $FALHOU recomposto — o que a pausa parcial tinha parado voltou."
    else
      echo "[preflight] ATENÇÃO: $FALHOU ficou parcialmente parado — confira com 'make ps' e 'docker ps -a'."
    fi
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
  RECUSA=""
  if $ALVO_DE_PE; then
    # Pausar só devolveu memória, e o alvo não acrescenta nada: não há conta a
    # refazer. Desfazer a pausa aqui religaria a outra família ao lado dele.
    echo "[preflight] RAM disponível agora: $(_gb "$DISPONIVEL")"
  else
    echo "[preflight] RAM disponível agora: $(_gb "$DISPONIVEL") — sobraria $(_gb "$PROJECAO")"
  fi
  if ! $ALVO_DE_PE && [ "$PROJECAO" -lt "$FOLGA_MINIMA" ]; then
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
