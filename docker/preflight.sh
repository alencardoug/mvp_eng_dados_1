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
  for c in "${CONFLITO[@]}"; do
    nome="${c%%:*}"
    echo "[preflight] $nome está de pé e não convive com '$ALVO' — pausando."
    case "$nome" in
      streaming) docker stop mvp_ed1_kafka_connect mvp_ed1_redpanda >/dev/null 2>&1 ;;
      Airbyte)   docker stop airbyte-abctl-control-plane >/dev/null 2>&1 ;;
      Airflow)   docker ps --format '{{.Names}}' | grep '^airflow_' | xargs -r docker stop >/dev/null 2>&1 ;;
    esac
    echo "[preflight] $nome pausado — retomar com ${c#*:}"
  done

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
  [ "$PROJECAO" -lt "$FOLGA_MINIMA" ] && \
    RECUSA="mesmo depois de pausar, sobraria menos que a folga mínima de $(_gb "$FOLGA_MINIMA")"
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
