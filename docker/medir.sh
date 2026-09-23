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

# **Leitura que falha é `NA`, nunca zero (RVE2-02).** As duas leituras abaixo
# somavam a entrada vazia — `docker stats` que não respondeu, `/proc/meminfo`
# ilegível — e devolviam 0, que o registro gravava como medição. Um zero
# inventado na tabela de capacidade de B5 é o que o P5 proíbe: o que não foi
# lido vai como não medido, e a amostra conta como falha.
_mem_disponivel() {
	local mb
	mb=$(awk '/^MemAvailable:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
	if [ -n "$mb" ]; then printf '%s' "$mb"; else printf 'NA'; fi
}

# Soma do uso de memória dos contêineres, em MB. `docker stats` devolve
# "1.234GiB / 11.5GiB"; só a primeira parcela interessa, e a unidade varia.
# Nenhum contêiner de pé é soma zero **lida**; uma linha sem número (`--`,
# contêiner que o Docker não conseguiu medir) torna a amostra inteira `NA`.
_mem_conteineres() {
	local uso
	uso=$(docker stats --no-stream --format '{{.MemUsage}}' 2>/dev/null) || { printf 'NA'; return; }
	printf '%s\n' "$uso" | awk -F' / ' '
		NF == 0 { next }
		{
			v = $1
			u = v; gsub(/[0-9.]/, "", u)
			gsub(/[^0-9.]/, "", v)
			if (v == "") { ilegivel = 1; next }
			if (u == "GiB") v *= 1024
			else if (u == "TiB") v *= 1024 * 1024
			else if (u == "KiB" || u == "kB") v /= 1024
			else if (u == "B") v = 0
			total += v
		} END { if (ilegivel) printf "NA"; else printf "%d", total }'
}

# ── Amostragem ──────────────────────────────────────────────────────────────
# Uma amostra por linha: `epoch mem_disponivel_mb mem_conteineres_mb`, com
# `NA` no lugar da leitura que falhou.
_amostrar_ate_morrer() {  # $1 = arquivo de amostras, $2 = PID a vigiar
	while kill -0 "$2" 2>/dev/null; do
		printf '%s %s %s\n' "$(_epoch)" "$(_mem_disponivel)" "$(_mem_conteineres)" >> "$1"
		sleep "$INTERVALO"
	done
}

# Agrega a série: extremos com instante, intervalo e contagem. Saída em linhas
# `chave=valor`, para quem chama montar o JSON — é o pedaço que os testes
# exercitam com uma série sintética, sem docker e sem /proc.
#
# Cada grandeza conta as **suas** falhas, e o extremo sai só das amostras
# válidas dela. Sem nenhuma válida o extremo é `null` — não medido —, e o
# instante dele não existe.
agregar() {  # $1 = arquivo de amostras
	awk '
		NF == 0 { next }
		{ n += 1; if (n == 1) primeiro = $1; ultimo = $1 }
		$2 == "NA" { falhas_disp += 1 }
		$2 != "NA" { validas_disp += 1; if (validas_disp == 1 || $2 + 0 < min_disp) { min_disp = $2 + 0; min_t = $1 } }
		$3 == "NA" { falhas_cont += 1 }
		$3 != "NA" { validas_cont += 1; if (validas_cont == 1 || $3 + 0 > max_cont) { max_cont = $3 + 0; max_t = $1 } }
		END {
			if (n == 0) { print "amostras=0"; exit }
			printf "amostras=%d\n", n
			if (validas_disp) printf "disponivel_minimo_mb=%d\ndisponivel_minimo_em=%d\n", min_disp, min_t
			else print "disponivel_minimo_mb=null"
			printf "disponivel_falhas=%d\n", falhas_disp
			if (validas_cont) printf "conteineres_maximo_mb=%d\nconteineres_maximo_em=%d\n", max_cont, max_t
			else print "conteineres_maximo_mb=null"
			printf "conteineres_falhas=%d\n", falhas_cont
			printf "janela_s=%d\n", ultimo - primeiro
		}
	' "$1"
}

# ── Estado da estação, no início ────────────────────────────────────────────
# "indeterminado" quando o Docker não responde — o registro não afirma um
# estado que não leu (RVE-08).
_de_pe() {
	local lista=() nomes par
	nomes=$(docker ps --format '{{.Names}}' 2>/dev/null) || { printf 'indeterminado'; return; }
	printf '%s\n' "$nomes" | grep -qx 'airbyte-abctl-control-plane' && lista+=("Airbyte")
	for par in "@airflow:Airflow" "@streaming:streaming" "@bancos:bancos"; do
		nomes=$(resolver "${par%%:*}") || { printf 'indeterminado'; return; }
		[ -n "$nomes" ] && lista+=("${par#*:}")
	done
	[ ${#lista[@]} -eq 0 ] && { printf 'nada'; return; }
	printf '%s' "$(IFS=,; echo "${lista[*]}")"
}

# ── Registro ────────────────────────────────────────────────────────────────
_json_escapar() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
_numero_ou_null() { case "$1" in ''|NA|null) printf 'null' ;; *) printf '%d' "$1" ;; esac; }

# MB em GB para o humano ler — ou "não medido", que é diferente de 0,0 GB.
_gb() { case "$1" in ''|NA|null) printf 'não medido' ;; *) awk -v m="$1" 'BEGIN{printf "%.1f GB", m/1024}' ;; esac; }

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
		printf '  "parametros": {"limite": %s, "corte": %s},\n' "${LIMITE:-null}" "${CORTE:-null}"
		printf '  "estacao": {"disponivel_mb": %s, "de_pe": "%s", "loadavg": "%s"},\n' \
			"$(_numero_ou_null "$MEM_INICIAL")" "$DE_PE" "$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)"
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

# Um arquivo por execução, nunca por dia: snapshot, eventos novos e a
# recuperação de B5 são três medições de `cenario:streaming`, e um nome por
# dia deixava só a última (RVE-13). O instante vai no nome, e os parâmetros
# que distinguem duas execuções do mesmo alvo — `LIMITE`, `ATE` — também.
_nome_do_registro() {
	local base sufixo="" nome
	base="$DESTINO/$(date -u +%Y-%m-%dT%H%M%SZ)_$(printf '%s' "$ALVO" | tr -c 'a-zA-Z0-9' '_')"
	[ -n "$LIMITE" ] && sufixo="${sufixo}_limite_${LIMITE}"
	[ -n "$ATE" ] && sufixo="${sufixo}_ate_$(printf '%s' "$ATE" | tr -c 'a-zA-Z0-9' '_')"
	nome="${base}${sufixo}.json"
	# Duas execuções no mesmo segundo não se sobrescrevem.
	[ -e "$nome" ] && nome="${base}${sufixo}_$$.json"
	printf '%s' "$nome"
}

_linha_da_tabela() {
	local valores
	valores=$(agregar "$AMOSTRAS")
	local n disp cont falhas_disp falhas_cont nota=""
	n=$(printf '%s\n' "$valores" | sed -n 's/^amostras=//p')
	disp=$(printf '%s\n' "$valores" | sed -n 's/^disponivel_minimo_mb=//p')
	cont=$(printf '%s\n' "$valores" | sed -n 's/^conteineres_maximo_mb=//p')
	falhas_disp=$(printf '%s\n' "$valores" | sed -n 's/^disponivel_falhas=//p')
	falhas_cont=$(printf '%s\n' "$valores" | sed -n 's/^conteineres_falhas=//p')
	[ "${falhas_disp:-0}" -gt 0 ] && nota="${nota}; MemAvailable não lido em ${falhas_disp}"
	[ "${falhas_cont:-0}" -gt 0 ] && nota="${nota}; soma dos contêineres não lida em ${falhas_cont}"
	if [ -n "$nota" ]; then
		echo "[medir] ATENÇÃO: leitura que falhou não é zero — o registro diz quantas faltaram${nota}."
	fi
	printf '| %s | %s | %dm %02ds | %s | %s | %s amostras a cada %ss%s |\n' \
		"$ALVO" "$DE_PE" "$((DURACAO / 60))" "$((DURACAO % 60))" \
		"$(_gb "$disp")" "$(_gb "$cont")" "${n:-0}" "$INTERVALO" "$nota"
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

# O fim é um só, para os dois desfechos: o registro sai também quando a
# medição é interrompida — antes, o trap saía com 130 e nenhum JSON, e uma
# medição abortada não deixava rastro nem de ter começado (RVE-12).
_finalizar() {
	DURACAO=$(( $(_epoch) - INICIO_EPOCH ))
	kill "$AMOSTRADOR" 2>/dev/null; wait "$AMOSTRADOR" 2>/dev/null
	ARQUIVO="$(_nome_do_registro)"
	_escrever "$ARQUIVO"
	echo "[medir] registro: $ARQUIVO"
	_linha_da_tabela
}

# O alvo em primeiro plano termina por conta própria — um Ctrl-C alcança o
# grupo inteiro, e o bash só entrega o sinal a este script depois que o filho
# em primeiro plano sai. O que o medidor iniciou por `setsid` é dele, e é ele
# quem encerra.
_interrompido() {
	INTERROMPIDO=true
	CODIGO=130
	echo ""
	echo "[medir] interrompido — encerrando o que iniciei antes de sair."
	_encerrar_filhos
	_finalizar
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
#
# **Não é `make -n`.** O `make` executa de verdade toda linha de receita que
# contenha `$(MAKE)`, mesmo sob `-n` — é como ele traça a recursão —, e a
# "validação" de `airbyte-up` chegava a chamar `abctl local install` antes de
# o preflight rodar (RVE-02, medido em 21/09/2026 com executáveis simulados).
# "O alvo existe?" se responde lendo a base de dados do `make`, sem executar
# nada: com um objetivo que não existe, ele imprime a base e para.
#
# O `make` sai 2 pelo objetivo inexistente — é o esperado, e o `|| true` o
# tira do `pipefail`. Sem `grep -q`: o `grep` que sai cedo mataria o `make`
# com SIGPIPE, e a existência viraria "não existe".
_alvo_existe() {
	{ make -pn __medir_nenhum_alvo__ 2>/dev/null || true; } \
		| sed -n 's/^\([^ #:=%][^ :=%]*\):.*/\1/p' | grep -Fx -- "$1" >/dev/null
}

if [ -z "$CENARIO" ]; then
	_alvo_existe "$ALVO" || {
		echo "ERRO: '$ALVO' não é um alvo do Makefile — nada foi medido." >&2
		exit 2
	}
	if [ -n "$ATE" ]; then
		_alvo_existe "$ATE" || {
			echo "ERRO: '$ATE' não é um alvo do Makefile — nada foi medido." >&2
			exit 2
		}
	fi
fi

INTERROMPIDO=false
CODIGO=0
CORTE=""
INICIO_ISO="$(_agora)"
INICIO_EPOCH="$(_epoch)"
MEM_INICIAL="$(_mem_disponivel)"
DE_PE="$(_de_pe)"
AMOSTRAS="$(mktemp)"
trap 'rm -f "$AMOSTRAS"' EXIT

echo "[medir] $ALVO — início $INICIO_ISO; estação: $(_gb "$MEM_INICIAL") livres, de pé: $DE_PE"

# O amostrador vigia ESTE processo e morre com ele.
_amostrar_ate_morrer "$AMOSTRAS" $$ &
AMOSTRADOR=$!

# Só depois de tudo que `_finalizar` precisa existir: um sinal antes disto
# seria um registro escrito com variáveis vazias.
trap _interrompido INT TERM
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

_finalizar
exit "$CODIGO"
