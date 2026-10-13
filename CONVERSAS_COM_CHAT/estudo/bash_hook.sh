# Relógio de estudo da trilha — o terminal. Carregado pelo ~/.bashrc (study_clock.py install-hook).
#
# Para cada comando digitado DENTRO da pasta do projeto, grava em data/estudo/terminal.jsonl o início
# (o horário que o próprio bash guarda no histórico ao apertar Enter), o fim (a volta do prompt) e só
# o NOME do programa — nunca o comando inteiro, que pode carregar senha. `claude` e `codex` ficam de
# fora: têm registro próprio. ESTUDO_SEM_REGISTRO=1 desliga. Comandos começados por espaço e repetidos
# idênticos não entram no histórico (HISTCONTROL=ignoreboth) e, por isso, não são vistos.

case $- in *i*) ;; *) return 0 ;; esac

__estudo_raiz="${ESTUDO_RAIZ:-$HOME/Projetos/mvp_eng_dados_1}"
__estudo_log="${ESTUDO_TERMINAL_LOG:-$__estudo_raiz/data/estudo/terminal.jsonl}"
__estudo_ultimo=""

__estudo_registrar() {
  local rc=$?
  [ -n "${ESTUDO_SEM_REGISTRO:-}" ] && return $rc
  local linha numero inicio resto
  linha=$(HISTTIMEFORMAT='%s ' builtin history 1) || return $rc
  read -r numero inicio resto <<< "$linha"
  if [ -z "$__estudo_ultimo" ]; then
    __estudo_ultimo="${numero:-0}"   # o primeiro prompt só marca onde o histórico está
    return $rc
  fi
  [ -z "$resto" ] || [ "$numero" = "$__estudo_ultimo" ] && return $rc
  __estudo_ultimo="$numero"
  case "$PWD/" in "$__estudo_raiz"/*) ;; *) return $rc ;; esac
  local -a palavras
  read -r -a palavras <<< "$resto"
  local programa=""
  for programa in "${palavras[@]}"; do
    case "$programa" in *=*) continue ;; *) break ;; esac
  done
  programa="${programa##*/}"
  programa="${programa//[^A-Za-z0-9._+-]/}"
  case "$programa" in "" | claude | codex) return $rc ;; esac
  [[ "$inicio" =~ ^[0-9]+$ ]] || return $rc
  mkdir -p "${__estudo_log%/*}" 2>/dev/null
  printf '{"end":"%s","program":"%s","start":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$programa" "$(date -u -d "@$inicio" +%Y-%m-%dT%H:%M:%SZ)" >> "$__estudo_log"
  return $rc
}

case ";${PROMPT_COMMAND:-};" in
  *";__estudo_registrar;"*) ;;
  *) PROMPT_COMMAND="__estudo_registrar${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
