#!/usr/bin/env bash
# Falar com o Airflow pela linha de comando — dono único das três armadilhas.
#
# Carregado com `source` por `docker/preflight.sh` e `docker/medir.sh`, que
# fariam a mesma coisa de dois jeitos diferentes se cada um tivesse a sua cópia.
# As armadilhas, todas medidas no Airflow 3.2.2 instalado (Etapa 12, §16 e §17):
#
# 1. **O ruído de inicialização sai no `stdout`**, não no stderr: as linhas de
#    log do Alembic e dos plugins vêm antes do JSON, e `2>/dev/null` não limpa
#    nada. O JSON é o que resta depois de descartar as linhas com carimbo.
# 2. **`dags list-runs` exige `dag_id`** — sem ele a CLI sai com código 2.
# 3. **`dags list` devolve a mesma DAG seis vezes**, e o conjunto precisa ser
#    lido, não fixado: a segunda DAG do projeto não pode depender de alguém
#    lembrar de editar um arquivo de infraestrutura.
#
# Toda consulta roda sob prazo (`AIRFLOW_PRAZO_CONSULTA`). Comando que não
# responde não é "não há nada": quem chama trata a falha como indeterminada.
set -uo pipefail

# shellcheck source=conteineres.sh
. "$(dirname "${BASH_SOURCE[0]}")/conteineres.sh"

AIRFLOW_PRAZO_CONSULTA="${AIRFLOW_PRAZO_CONSULTA:-20}"
AIRFLOW_SCHEDULER="${AIRFLOW_SCHEDULER:-}"

# Resolve o scheduler uma vez por processo. 1 se não há scheduler de pé; 4 se
# o Docker não respondeu — e os dois não se confundem (RVE-08, RVE-17).
airflow_scheduler() {
	[ -n "$AIRFLOW_SCHEDULER" ] && { printf '%s' "$AIRFLOW_SCHEDULER"; return 0; }
	local nomes
	nomes=$(resolver airflow_scheduler) || return 4
	AIRFLOW_SCHEDULER=$(printf '%s\n' "$nomes" | head -1)
	[ -z "$AIRFLOW_SCHEDULER" ] && return 1
	printf '%s' "$AIRFLOW_SCHEDULER"
}

# Descarta as linhas de log do stdout, deixando só a resposta.
airflow_limpar_log() {
	sed -E '/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z?[[:space:]]+\[/d; /^[[:space:]]*$/d'
}

# Uma consulta, com prazo próprio. Sai 124 quando expira; 125 se não resolveu
# o contêiner — os dois são "indeterminado" para quem chama.
airflow_cli() {
	local nome
	nome=$(airflow_scheduler) || return 125
	timeout "$AIRFLOW_PRAZO_CONSULTA" docker exec "$nome" airflow "$@" 2>/dev/null
}

# Um campo de texto do primeiro objeto de uma resposta JSON.
airflow_campo() {  # $1 = json, $2 = nome do campo
	printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" \
		| head -1 | sed -E 's/.*"([^"]+)"$/\1/'
}

# Os `dag_id` distintos, lidos da enumeração — os repetidos descartados.
airflow_dag_ids() {
	grep -oE '"dag_id"[[:space:]]*:[[:space:]]*"[^"]+"' \
		| sed -E 's/.*"([^"]+)"$/\1/' | sort -u
}

# Classifica uma resposta que deve ser uma lista JSON: `vazia`, `lista` ou
# `ilegivel`. É o que separa "não há execução" de "não entendi a resposta".
airflow_forma_da_lista() {
	local limpo
	limpo=$(printf '%s\n' "$1" | airflow_limpar_log | tr -d '[:space:]')
	case "$limpo" in
	"[]") echo vazia ;;
	\[*)  echo lista ;;
	*)    echo ilegivel ;;
	esac
}

# ── Disparar e esperar ──────────────────────────────────────────────────────
# `dag-run` descartava a saída do `trigger`, e com ela o `run_id`. Sem o
# `run_id` não há como esperar *aquela* execução: "a última" muda de identidade
# se alguém dispara outra, e a medição passaria a falar de outra coisa.
MEDICOES_DIR="${MEDIR_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/data/medicoes}"
ARQUIVO_ULTIMO_RUN="$MEDICOES_DIR/ultimo_run_id"

airflow_disparar() {  # $1 = dag_id
	local dag="$1" bruto run i
	# DAG nasce pausada, e execução enfileirada em DAG pausada fica `queued`
	# para sempre — o disparo "funciona" e não faz nada. Logo depois de um
	# `airflow-up` ela ainda não existe no banco de metadados.
	for i in $(seq 1 30); do
		airflow_cli dags unpause "$dag" >/dev/null 2>&1 && break
		sleep 2
	done
	bruto=$(airflow_cli dags trigger "$dag" -o json) || {
		echo "ERRO: o disparo de '$dag' não respondeu." >&2
		return 1
	}
	run=$(airflow_campo "$bruto" run_id)
	[ -z "$run" ] && { echo "ERRO: disparei '$dag' e não li o run_id de volta." >&2; return 1; }
	mkdir -p "$MEDICOES_DIR" && printf '%s\n' "$run" > "$ARQUIVO_ULTIMO_RUN"
	printf '%s\n' "$run"
}

# A execução está na lista, com este `run_id` **exato** e neste estado?
# 0 sim, 1 não, 2 lista ilegível. Interpreta o JSON de verdade (RVE-14): a
# busca por substring aceitava `rve-100` como resposta para `rve-10`, e a
# espera anunciava um sucesso que era de outra execução. O ruído de log é
# descartado antes; o Python é o do projeto, que toda operação já exige.
airflow_run_na_lista() {  # $1 = resposta bruta, $2 = run_id, $3 = estado
	local python
	python="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.venv/bin/python"
	[ -x "$python" ] || python=python3
	printf '%s\n' "$1" | airflow_limpar_log | "$python" -c '
import json, sys
run, estado = sys.argv[1], sys.argv[2]
try:
    itens = json.load(sys.stdin)
except ValueError:
    sys.exit(2)
if not isinstance(itens, list):
    sys.exit(2)
achou = any(
    isinstance(item, dict) and item.get("run_id") == run and item.get("state") == estado
    for item in itens
)
sys.exit(0 if achou else 1)
' "$2" "$3"
}

# Espera uma execução chegar a estado terminal. 0 = success, 1 = failed,
# 2 = prazo ou indeterminado — porque não saber não é sucesso.
airflow_aguardar_run() {  # $1 = dag_id, $2 = run_id, $3 = prazo em segundos
	local dag="$1" run="$2" prazo="${3:-1800}" inicio estado bruto forma
	inicio=$SECONDS
	while :; do
		for estado in success failed; do
			bruto=$(airflow_cli dags list-runs "$dag" --state "$estado" -o json) || {
				echo "[dag-wait] consulta de '$estado' não respondeu — tentando de novo" >&2
				continue
			}
			forma=$(airflow_forma_da_lista "$bruto")
			[ "$forma" = ilegivel ] && {
				echo "[dag-wait] resposta ilegível para '$estado' — tentando de novo" >&2
				continue
			}
			[ "$forma" = vazia ] && continue
			airflow_run_na_lista "$bruto" "$run" "$estado"
			case $? in
			0)
				echo "[dag-wait] $run terminou: $estado ($((SECONDS - inicio))s de espera)"
				[ "$estado" = success ] && return 0 || return 1 ;;
			1) ;;
			*) echo "[dag-wait] resposta ilegível para '$estado' — tentando de novo" >&2 ;;
			esac
		done
		if [ $((SECONDS - inicio)) -ge "$prazo" ]; then
			echo "ERRO: $run não chegou a estado terminal em ${prazo}s — a espera venceu, e vencer não é sucesso." >&2
			return 2
		fi
		sleep "${AIRFLOW_INTERVALO_ESPERA:-10}"
	done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	acao="${1:?uso: airflow_cli.sh <disparar|aguardar> ...}"; shift
	case "$acao" in
	disparar) airflow_disparar "$@" ;;
	pausar)
		# Pausar a DAG é manutenção, não desligamento: execução enfileirada em
		# DAG pausada fica `queued` e não começa — que é exatamente o que a
		# restauração precisa enquanto troca os três bancos por baixo.
		#
		# Três desfechos, e quem chama precisa distingui-los (RVE-17): 0 pausou;
		# 3 não há Airflow de pé — nada pode executar a DAG, e é seguro seguir;
		# 1 há Airflow (ou não se sabe) e a pausa não aconteceu — seguir seria
		# descartar os bancos com um scheduler capaz de disparar a DAG no meio.
		dag="${1:?uso: airflow_cli.sh pausar <dag_id>}"
		airflow_scheduler >/dev/null; s=$?
		if [ $s -eq 1 ]; then
			echo "Airflow não está de pé — não há DAG a pausar, e nenhuma execução pode começar."
			exit 3
		elif [ $s -ne 0 ]; then
			echo "não sei se o Airflow está de pé — o Docker não respondeu." >&2
			exit 1
		fi
		airflow_cli dags pause "$dag" >/dev/null \
			&& echo "DAG ${dag} pausada." \
			|| { echo "não consegui pausar a DAG ${dag} — o Airflow respondeu?" >&2; exit 1; } ;;
	despausar)
		airflow_cli dags unpause "${1:?uso: airflow_cli.sh despausar <dag_id>}" >/dev/null \
			&& echo "DAG ${1} despausada." ;;
	aguardar)
		dag="${1:?uso: airflow_cli.sh aguardar <dag_id> [run_id] [prazo]}"
		run="${2:-}"
		[ -z "$run" ] && [ -f "$ARQUIVO_ULTIMO_RUN" ] && run=$(cat "$ARQUIVO_ULTIMO_RUN")
		[ -z "$run" ] && { echo "ERRO: sem RUN_ID e sem $ARQUIVO_ULTIMO_RUN — não sei qual execução esperar." >&2; exit 2; }
		airflow_aguardar_run "$dag" "$run" "${3:-1800}" ;;
	*) echo "airflow_cli.sh: ação desconhecida '$acao'" >&2; exit 2 ;;
	esac
fi
