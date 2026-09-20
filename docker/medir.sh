#!/usr/bin/env bash
# Medir um alvo do Makefile: quanto demorou, quanta memória sobrou, e se
# **rodou** ou só foi disparado.
#
# A diferença entre disparar e rodar é o motivo deste arquivo existir. `dag-run`
# devolve o controle assim que o Airflow aceita o disparo; `stream-run` nunca
# devolve. Medir o primeiro sem esperar mede a latência do `trigger`, e o
# segundo não tem fim natural nenhum. Por isso:
#
#   medir.sh <alvo> [--ate <alvo de espera>]     executa e, se pedido, espera
#   medir.sh --cenario streaming [--limite n]    o caso do pipeline concorrente
#   medir.sh --agregar <arquivo de amostras>     só agrega (é o que os testes usam)
#
# **Os extremos são amostrados, não garantidos.** A cada `INTERVALO` segundos o
# medidor lê `MemAvailable` e a soma do uso dos contêineres, e guarda o mínimo
# e o máximo com o instante, o intervalo e o número de amostras. Um pico entre
# duas amostras não aparece, e é por isso que o intervalo e a contagem vão no
# registro: sem eles o número parece uma garantia.
#
# **Os dois números não medem a mesma coisa, e ficam lado a lado por isso.** O
# `MemAvailable` inclui a estação inteira — navegador, editor, sessões de
# agente. A soma dos contêineres **não inclui** o Beam nem o produtor, que
# rodam no processo Python do *host*.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=conteineres.sh
. "$RAIZ/docker/conteineres.sh"

INTERVALO="${MEDIR_INTERVALO:-2}"
DESTINO="${MEDIR_DIR:-$RAIZ/data/medicoes}"
PRAZO_ENCERRAMENTO="${MEDIR_PRAZO_ENCERRAMENTO:-60}"

_agora() { date -u +%Y-%m-%dT%H:%M:%SZ; }
_epoch() { date +%s; }

_mem_disponivel() { awk '/^MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0; }

# Soma do uso de memória dos contêineres, em MB. `docker stats` devolve
# "1.234GiB / 11.5GiB"; só a primeira parcela interessa, e a unidade varia.
_mem_conteineres() {
	docker stats --no-stream --format '{{.MemUsage}}' 2>/dev/null \
		| awk -F' / ' '{
			v = $1
			u = v; gsub(/[0-9.]/, "", u)
			gsub(/[^0-9.]/, "", v)
			if (u == "GiB") v *= 1024
			else if (u == "KiB") v /= 1024
			else if (u == "B") v = 0
			total += v
		} END { printf "%d", total }'
}

# ── Amostragem ──────────────────────────────────────────────────────────────
# Uma amostra por linha: `epoch mem_disponivel_mb mem_conteineres_mb`.
_amostrar_ate_morrer() {  # $1 = arquivo de amostras, $2 = PID a vigiar
	while kill -0 "$2" 2>/dev/null; do
		printf '%s %s %s\n' "$(_epoch)" "$(_mem_disponivel)" "$(_mem_conteineres)" >> "$1"
		sleep "$INTERVALO"
	done
}

# Agrega a série: extremos com instante, intervalo e contagem. Saída em linhas
# `chave=valor`, para quem chama montar o JSON — é o pedaço que os testes
# exercitam com uma série sintética, sem docker e sem /proc.
agregar() {  # $1 = arquivo de amostras
	awk '
		NR == 1 { min_disp = $2; min_t = $1; max_cont = $3; max_t = $1; primeiro = $1 }
		$2 < min_disp { min_disp = $2; min_t = $1 }
		$3 > max_cont { max_cont = $3; max_t = $1 }
		{ ultimo = $1; n += 1 }
		END {
			if (n == 0) { print "amostras=0"; exit }
			printf "amostras=%d\n", n
			printf "disponivel_minimo_mb=%d\n", min_disp
			printf "disponivel_minimo_em=%d\n", min_t
			printf "conteineres_maximo_mb=%d\n", max_cont
			printf "conteineres_maximo_em=%d\n", max_t
			printf "janela_s=%d\n", ultimo - primeiro
		}
	' "$1"
}

# ── Estado da estação, no início ────────────────────────────────────────────
_de_pe() {
	local lista=()
	docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'airbyte-abctl-control-plane' && lista+=("Airbyte")
	[ -n "$(resolver @airflow)" ] && lista+=("Airflow")
	[ -n "$(resolver @streaming)" ] && lista+=("streaming")
	[ -n "$(resolver @bancos)" ] && lista+=("bancos")
	[ ${#lista[@]} -eq 0 ] && { printf 'nada'; return; }
	printf '%s' "$(IFS=,; echo "${lista[*]}")"
}

# ── Registro ────────────────────────────────────────────────────────────────
_json_escapar() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

_escrever() {  # $1 = arquivo, resto vem das variáveis do processo
	mkdir -p "$(dirname "$1")"
	local ate_json="null"
	[ -n "$ATE" ] && ate_json="\"$(_json_escapar "$ATE")\""
	{
		printf '{\n'
		printf '  "alvo": "%s",\n' "$(_json_escapar "$ALVO")"
		printf '  "ate": %s,\n' "$ate_json"
		printf '  "inicio": "%s",\n' "$INICIO_ISO"
		printf '  "fim": "%s",\n' "$(_agora)"
		printf '  "duracao_involucro_s": %d,\n' "$DURACAO"
		printf '  "codigo_de_saida": %d,\n' "$CODIGO"
		printf '  "interrompido": %s,\n' "$INTERROMPIDO"
		printf '  "estacao": {"disponivel_mb": %d, "de_pe": "%s", "loadavg": "%s"},\n' \
			"$MEM_INICIAL" "$DE_PE" "$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)"
		printf '  "amostragem": {"intervalo_s": %s' "$INTERVALO"
		local chave valor
		while IFS='=' read -r chave valor; do
			[ -z "$chave" ] && continue
			case "$chave" in
			*_em) printf ', "%s": "%s"' "$chave" "$(date -u -d "@$valor" +%Y-%m-%dT%H:%M:%SZ)" ;;
			*)    printf ', "%s": %s' "$chave" "$valor" ;;
			esac
		done < <(agregar "$AMOSTRAS")
		printf '},\n'
		printf '  "limite": "a soma dos contêineres não inclui o Beam nem o produtor, que rodam no host; os extremos são amostrados"\n'
		printf '}\n'
	} > "$1"
}

_linha_da_tabela() {
	local valores
	valores=$(agregar "$AMOSTRAS")
	local n disp cont
	n=$(printf '%s\n' "$valores" | sed -n 's/^amostras=//p')
	disp=$(printf '%s\n' "$valores" | sed -n 's/^disponivel_minimo_mb=//p')
	cont=$(printf '%s\n' "$valores" | sed -n 's/^conteineres_maximo_mb=//p')
	printf '| %s | %s | %dm %02ds | %s GB | %s GB | %s amostras a cada %ss |\n' \
		"$ALVO" "$DE_PE" "$((DURACAO / 60))" "$((DURACAO % 60))" \
		"$(awk -v m="${disp:-0}" 'BEGIN{printf "%.1f", m/1024}')" \
		"$(awk -v m="${cont:-0}" 'BEGIN{printf "%.1f", m/1024}')" \
		"${n:-0}" "$INTERVALO"
}

# ── Execução ────────────────────────────────────────────────────────────────
# Grupos de processo que ESTE medidor iniciou — só eles são encerrados.
#
# Grupo, e não PID: o `make` que sobe o pipeline é um invólucro, e o Beam roda
# como filho dele. Sinalizar só o invólucro o mata e **deixa o Beam órfão**,
# segurando o tópico e a memória exatamente quando o medidor anuncia que
# encerrou. O `setsid` põe cada um num grupo próprio, e é o grupo que recebe o
# sinal — o que também garante que nada de fora seja tocado.
FILHOS=()

_encerrar_filhos() {
	local pgid esperou
	for pgid in "${FILHOS[@]:-}"; do
		[ -z "$pgid" ] && continue
		kill -0 -- "-$pgid" 2>/dev/null || continue
		echo "[medir] encerrando o que iniciei: grupo $pgid (SIGINT)"
		kill -INT -- "-$pgid" 2>/dev/null
		esperou=0
		while kill -0 -- "-$pgid" 2>/dev/null && [ "$esperou" -lt "$PRAZO_ENCERRAMENTO" ]; do
			sleep 1; esperou=$((esperou + 1))
		done
		if kill -0 -- "-$pgid" 2>/dev/null; then
			echo "[medir] grupo $pgid não saiu em ${PRAZO_ENCERRAMENTO}s — SIGKILL"
			kill -KILL -- "-$pgid" 2>/dev/null
		else
			echo "[medir] grupo $pgid encerrou limpo em ${esperou}s"
		fi
	done
}

_interrompido() {
	INTERROMPIDO=true
	echo ""
	echo "[medir] interrompido — encerrando o que iniciei antes de sair."
	_encerrar_filhos
	exit 130
}

# Executa um alvo do Makefile.
#
# **O `make` achata o código de saída da receita em 2.** Qualquer `exit N` de
# dentro de uma receita chega aqui como 2, e por isso o registro guarda o
# código **do invólucro**, não o do comando. A distinção que importa — "a DAG
# falhou" contra "a espera venceu" — fica na mensagem do alvo de espera, que a
# escreve por extenso, e não num número que o `make` não sabe transportar.
_executar_alvo() { make --no-print-directory "$@"; }

# ── Argumentos ──────────────────────────────────────────────────────────────
ALVO=""; ATE=""; CENARIO=""; LIMITE=""
while [ $# -gt 0 ]; do
	case "$1" in
	--agregar) agregar "$2"; exit 0 ;;
	--ate)     ATE="$2"; shift ;;
	--cenario) CENARIO="$2"; shift ;;
	--limite)  LIMITE="$2"; shift ;;
	--*) echo "medir.sh: opção desconhecida '$1'" >&2; exit 2 ;;
	*) ALVO="$1" ;;
	esac
	shift
done

if [ -n "$CENARIO" ]; then ALVO="cenario:$CENARIO"; fi
[ -z "$ALVO" ] && { echo "uso: medir.sh <alvo> [--ate <alvo>] | --cenario streaming [--limite n]" >&2; exit 2; }

# Alvo inexistente falha ANTES de amostrar: medir o nada produz um registro
# que parece uma medição e não é.
if [ -z "$CENARIO" ]; then
	make -n "$ALVO" >/dev/null 2>&1 || {
		echo "ERRO: '$ALVO' não é um alvo do Makefile — nada foi medido." >&2
		exit 2
	}
	if [ -n "$ATE" ]; then
		make -n "$ATE" >/dev/null 2>&1 || {
			echo "ERRO: '$ATE' não é um alvo do Makefile — nada foi medido." >&2
			exit 2
		}
	fi
fi

INTERROMPIDO=false
trap _interrompido INT TERM

INICIO_ISO="$(_agora)"
INICIO_EPOCH="$(_epoch)"
MEM_INICIAL="$(_mem_disponivel)"
DE_PE="$(_de_pe)"
AMOSTRAS="$(mktemp)"
trap 'rm -f "$AMOSTRAS"' EXIT

echo "[medir] $ALVO — início $INICIO_ISO; estação: $(awk -v m="$MEM_INICIAL" 'BEGIN{printf "%.1f GB", m/1024}') livres, de pé: $DE_PE"

# O amostrador vigia ESTE processo e morre com ele.
_amostrar_ate_morrer "$AMOSTRAS" $$ &
AMOSTRADOR=$!

CODIGO=0
if [ -n "$CENARIO" ]; then
	case "$CENARIO" in
	streaming)
		# (1) sobe o transporte, com o preflight ativo — a troca de ambientes
		#     acontece aqui, e é ela que deixa o Airbyte pausado.
		_executar_alvo stream-up || CODIGO=$?
		if [ "$CODIGO" -eq 0 ]; then
			# (2) o pipeline em segundo plano, sob guarda: o PID é anotado, e só
			#     ele é encerrado no fim.
			setsid make --no-print-directory stream-run &
			BEAM=$!
			FILHOS+=("$BEAM")
			echo "[medir] pipeline Beam sob guarda: grupo $BEAM"
			sleep "$INTERVALO"
			kill -0 -- "-$BEAM" 2>/dev/null \
				|| { echo "ERRO: o pipeline morreu ao subir." >&2; CODIGO=1; }
		fi
		if [ "$CODIGO" -eq 0 ] && [ -n "$LIMITE" ]; then
			# (3) o produtor em primeiro plano, até terminar.
			_executar_alvo stream-produce LIMITE="$LIMITE" || CODIGO=$?
		fi
		if [ "$CODIGO" -eq 0 ]; then
			# (4) o corte é lido AGORA — depois do produtor, nunca antes.
			CORTE=$(_executar_alvo stream-corte) || CODIGO=$?
			echo "[medir] corte lido depois do produtor: event_sequence <= ${CORTE:-?}"
		fi
		if [ "$CODIGO" -eq 0 ]; then
			# (5) espera o livro alcançar o corte, vigiando o pipeline. Se ele
			#     morrer sob a espera, ela falha em vez de esgotar o prazo.
			_executar_alvo stream-wait ATE_SEQ="$CORTE" PID="$BEAM" || CODIGO=$?
		fi
		# (6) encerra só o que iniciou, sempre — inclusive quando algo falhou.
		_encerrar_filhos
		;;
	*) echo "medir.sh: cenário desconhecido '$CENARIO'" >&2; CODIGO=2 ;;
	esac
else
	_executar_alvo "$ALVO" || CODIGO=$?
	if [ "$CODIGO" -eq 0 ] && [ -n "$ATE" ]; then
		_executar_alvo "$ATE" || CODIGO=$?
	fi
fi

DURACAO=$(( $(_epoch) - INICIO_EPOCH ))
kill "$AMOSTRADOR" 2>/dev/null; wait "$AMOSTRADOR" 2>/dev/null

ARQUIVO="$DESTINO/$(date -u +%Y-%m-%d)_$(printf '%s' "$ALVO" | tr -c 'a-zA-Z0-9' '_').json"
_escrever "$ARQUIVO"
echo "[medir] registro: $ARQUIVO"
_linha_da_tabela
exit "$CODIGO"
