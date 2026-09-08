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

ALVO="${1:?uso: preflight.sh <airbyte|airflow|streaming> [--trocar]}"
TROCAR=false
[ "${2:-}" = "--trocar" ] && TROCAR=true

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
# Batch e streaming não sobem juntos fora da Etapa 12 (R11, §2.5).
case "$ALVO" in
  airbyte|airflow) FAMILIA="batch" ;;
  streaming)       FAMILIA="streaming" ;;
  *) echo "preflight: alvo desconhecido '$ALVO' (use airbyte, airflow ou streaming)" >&2; exit 2 ;;
esac

custo_var="CUSTO_${ALVO}"
CUSTO="${!custo_var}"

# --- o que já está de pé -----------------------------------------------------
_no_ar() { docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "$1"; }

# Um ambiente pelo nome, para reconsultar depois de agir sobre ele.
_ainda_no_ar() {
	case "$1" in
	Airbyte)   _no_ar '^airbyte-abctl-control-plane$' ;;
	Airflow)   _no_ar '^airflow_' ;;
	streaming) _no_ar '_(redpanda|kafka_connect)$' ;;
	*) return 1 ;;
	esac
}

# Parar e religar respondem pelo **estado resultante**, não pelo código de saída
# do `docker`. O código não basta: `xargs` sobre lista vazia sai 0 sem parar
# nada, e uma parada parcial deixa metade do ambiente de pé. Anunciar "pausado"
# sem conferir é pior que não pausar — o preflight libera o alvo achando que
# desfez o conflito, e os dois ambientes sobem juntos, que é o R11.
_parar() {
	case "$1" in
	streaming) docker stop mvp_ed1_kafka_connect mvp_ed1_redpanda >/dev/null 2>&1 ;;
	Airbyte)   docker stop airbyte-abctl-control-plane >/dev/null 2>&1 ;;
	Airflow)   docker ps --format '{{.Names}}' | grep '^airflow_' | xargs -r docker stop >/dev/null 2>&1 ;;
	esac
	! _ainda_no_ar "$1"
}

_religar() {
	case "$1" in
	streaming) docker start mvp_ed1_redpanda mvp_ed1_kafka_connect >/dev/null 2>&1 ;;
	Airbyte)   docker start airbyte-abctl-control-plane >/dev/null 2>&1 ;;
	Airflow)   docker ps -a --format '{{.Names}}' | grep '^airflow_' | xargs -r docker start >/dev/null 2>&1 ;;
	esac
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
_trabalho_ativo() {
	case "$1" in
	Airbyte)
		local pods
		pods=$(docker exec airbyte-abctl-control-plane crictl pods --state Ready 2>/dev/null) \
			|| { echo "indeterminado — cluster não respondeu"; return; }
		echo "$pods" | grep -qE "replication-job|orchestrator-repl" \
			&& echo "sincronização em andamento"
		;;
	Airflow)
		local runs
		runs=$(docker exec airflow_scheduler airflow dags list-runs --state running -o plain 2>/dev/null) \
			|| { echo "indeterminado — scheduler não respondeu"; return; }
		echo "$runs" | grep -qE "^[a-z_]+[[:space:]]+" && echo "DAG em execução"
		;;
	streaming)
		# O pipeline Beam roda fora dos contêineres, no processo Python do host
		# (Capacidade §2.4) — parar o transporte sob ele o quebra.
		pgrep -f "mvp_ed1[.]streaming" >/dev/null 2>&1 \
			&& echo "pipeline Beam ou produtor em primeiro plano"
		;;
	esac
}

AIRBYTE_NO_AR=false;   _no_ar '^airbyte-abctl-control-plane$' && AIRBYTE_NO_AR=true
AIRFLOW_NO_AR=false;   _no_ar '^airflow_'                     && AIRFLOW_NO_AR=true
STREAMING_NO_AR=false; _no_ar '_(redpanda|kafka_connect)$'    && STREAMING_NO_AR=true

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
  RECUSA="batch e streaming juntos só na Etapa 12 (R11)"
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
      streaming) echo "    docker stop mvp_ed1_kafka_connect mvp_ed1_redpanda" ;;
      Airbyte)   echo "    docker stop airbyte-abctl-control-plane" ;;
      Airflow)   echo "    docker ps --format '{{.Names}}' | grep '^airflow_' | xargs -r docker stop" ;;
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
echo "  Se ambos são mesmo necessários (Etapa 12, ou reconciliar CDC contra a"
echo "  carga completa), isto é uma PAUSA para o Owner liberar recursos:"
echo "  peça a ele, confirme, e então autorize com FORCE=1."
exit 1
