# Relógio de estudo da trilha — o terminal. Carregado pelo ~/.bashrc (study_clock.py install-hook).
#
# Para cada comando digitado DENTRO da pasta do projeto, grava em data/estudo/terminal.jsonl o início
# (o horário que o próprio bash guarda no histórico ao apertar Enter), o fim (a volta do prompt) e só
# o NOME do programa — nunca o comando inteiro, que pode carregar senha. Enquanto o comando roda, um
# vigia em segundo plano confere a cada ESTUDO_VIGIA_SEG segundos (20) se houve tecla neste terminal —
# o horário de acesso do dispositivo do terminal, o mesmo sinal que o `w` usa para a ociosidade — e
# grava o minuto, sem a tecla. É o que mede o estudo dentro de um `psql` ou de um contêiner.
# `claude` e `codex` ficam de fora: têm registro próprio. ESTUDO_SEM_REGISTRO=1 desliga. Comandos
# começados por espaço e repetidos idênticos não entram no histórico (HISTCONTROL=ignoreboth) e, por
# isso, não são vistos.

case $- in *i*) ;; *) return 0 ;; esac

__estudo_raiz="${ESTUDO_RAIZ:-$HOME/Projetos/mvp_eng_dados_1}"
__estudo_log="${ESTUDO_TERMINAL_LOG:-$__estudo_raiz/data/estudo/terminal.jsonl}"
__estudo_pid="${XDG_RUNTIME_DIR:-/tmp}/estudo_vigia.$$"
__estudo_ultimo=""

# O nome do programa da última linha do histórico; vazio se não deve ser registrado.
__estudo_programa() {
  local resto="$1" programa=""
  local -a palavras
  read -r -a palavras <<< "$resto"
  for programa in "${palavras[@]}"; do
    case "$programa" in *=*) continue ;; *) break ;; esac
  done
  programa="${programa##*/}"
  programa="${programa//[^A-Za-z0-9._+-]/}"
  case "$programa" in claude | codex) programa="" ;; esac
  printf '%s' "$programa"
}

# O vigia: grava o minuto de cada tecla nova no terminal, até receber TERM (a volta do prompt) ou o
# shell que o lançou sumir. Na saída, uma última amostra pega a tecla que encerrou o programa.
__estudo_vigiar() {
  local terminal="$1" pai="$2" visto minuto gravado="" filho
  visto=$(stat -c %X "$terminal" 2>/dev/null) || return 0
  __estudo_amostrar() {
    local agora
    agora=$(stat -c %X "$terminal" 2>/dev/null) || return 1
    [ "$agora" = "$visto" ] && return 0
    visto="$agora"
    minuto=$(date -u -d "@$agora" +%Y-%m-%dT%H:%M:00Z)
    [ "$minuto" = "$gravado" ] && return 0
    gravado="$minuto"
    printf '{"input":"%s"}\n' "$minuto" >> "$__estudo_log"
  }
  __estudo_largar() {  # o shell sumiu sem voltar ao prompt: o arquivo do PID, se ainda é deste vigia, sai
    [ -n "$filho" ] && kill "$filho" 2>/dev/null
    [ "$(cat "$__estudo_pid" 2>/dev/null)" = "$BASHPID" ] && rm -f "$__estudo_pid"
  }
  trap '__estudo_amostrar; [ -n "$filho" ] && kill "$filho" 2>/dev/null; exit 0' TERM
  trap '__estudo_largar; exit 0' HUP
  while kill -0 "$pai" 2>/dev/null; do
    sleep "${ESTUDO_VIGIA_SEG:-20}" & filho=$!
    wait "$filho"
    __estudo_amostrar || break
  done
  __estudo_largar
  return 0
}

# Roda pelo PS0, entre o Enter e o início do comando, num subshell: lança o vigia e anota o PID.
__estudo_iniciar() {
  [ -n "${ESTUDO_SEM_REGISTRO:-}" ] && return 0
  case "$PWD/" in "$__estudo_raiz"/*) ;; *) return 0 ;; esac
  local linha numero inicio resto terminal
  linha=$(HISTTIMEFORMAT='%s ' builtin history 1) || return 0
  read -r numero inicio resto <<< "$linha"
  [ -n "$(__estudo_programa "$resto")" ] || return 0
  terminal=$(tty 2>/dev/null) || return 0
  mkdir -p "${__estudo_log%/*}" 2>/dev/null
  __estudo_vigiar "$terminal" "$$" > /dev/null 2>&1 < /dev/null &
  printf '%s' "$!" > "$__estudo_pid"
}

__estudo_parar() {
  [ -f "$__estudo_pid" ] || return 0
  kill "$(cat "$__estudo_pid")" 2>/dev/null
  rm -f "$__estudo_pid"
}

__estudo_registrar() {
  local rc=$?
  __estudo_parar
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
  local programa
  programa=$(__estudo_programa "$resto")
  [ -n "$programa" ] || return $rc
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
case "${PS0:-}" in
  *'$(__estudo_iniciar)'*) ;;
  *) PS0="${PS0:-}"'$(__estudo_iniciar)' ;;
esac
