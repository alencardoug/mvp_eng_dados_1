#!/usr/bin/env bash
# Resolução de contêineres deste projeto — por **rótulo do Compose**, nunca por
# prefixo de nome.
#
# Por que existe (RV12-2-03, §0 do plano da Etapa 12): a composição do Airflow
# não declara `container_name`, então o Compose gera `<projeto>-<serviço>-<n>`.
# Quem procurava `^airflow_` nunca achava nada — `AIRFLOW_NO_AR` era sempre
# falso, a mitigação do R11 estava furada para o Airflow desde que existe, e os
# alvos de pausa anunciavam sucesso sobre uma lista vazia. O rótulo
# `com.docker.compose.service` é declarado pelo Compose em todo contêiner que
# ele cria, com ou sem `container_name`, e não muda com o nome do projeto.
#
# É o **dono único** do assunto: preflight e Makefile consomem daqui em vez de
# repetir a regra. Executado, é uma CLI; carregado com `source`, são funções.
#
# Uso:
#   conteineres.sh resolver [--todos] <serviço|@grupo>...   nomes, um por linha
#   conteineres.sh pausar   <rótulo> <serviço|@grupo>...    para e CONFERE o estado
#   conteineres.sh retomar  <rótulo> <serviço|@grupo>...    religa e CONFERE o estado
#
# `@airflow`, `@streaming` e `@bancos` são os grupos declarados abaixo. Quem
# consome — preflight e Makefile — cita o grupo, nunca repete a lista: lista
# repetida em dois arquivos diverge no primeiro serviço novo.
#
# `pausar` e `retomar` respondem pelo **estado resultante**, não pelo código de
# saída do `docker`: `xargs` sobre lista vazia sai 0 sem parar nada, e foi assim
# que `airflow-pause` passou a imprimir "Airflow pausado." com o Airflow inteiro
# de pé. Códigos: 0 fez, 3 não havia o que fazer, 1 tentou e não conseguiu,
# 4 não sei — o Docker não respondeu.
#
# **Lista vazia e falha de enumeração são respostas diferentes (RVE-08).**
# `resolver` sai 4 quando o `docker ps` falha, e quem consome trata isso como
# indeterminado — nunca como "não há contêiner": foi assim que uma consulta
# indisponível chegou a liberar o pacote e a troca de ambiente sem conhecer o
# estado. `pausar` e `retomar` recusam-se a anunciar um estado que não leram.
#
# `RETOMAR_COM` é a dica impressa depois de uma pausa bem-sucedida.
set -uo pipefail

# --- os grupos de serviços, declarados uma vez -------------------------------
# `airflow_init` fica de fora de propósito: é tarefa de uma vez só, que termina
# e fica `exited`. Religá-la em `retomar` reexecutaria a inicialização.
SERVICOS_AIRFLOW=(airflow_scheduler airflow_apiserver airflow_dag_processor airflow_db)
SERVICOS_STREAMING=(redpanda kafka_connect)
SERVICOS_BANCOS=(source_db legacy_db warehouse_db)

# Expande `@grupo` nos serviços que o compõem; o resto passa como está.
_expandir() {
	local a
	for a in "$@"; do
		case "$a" in
		@airflow)   printf '%s\n' "${SERVICOS_AIRFLOW[@]}" ;;
		@streaming) printf '%s\n' "${SERVICOS_STREAMING[@]}" ;;
		@bancos)    printf '%s\n' "${SERVICOS_BANCOS[@]}" ;;
		@*) echo "conteineres.sh: grupo desconhecido '$a'" >&2; return 2 ;;
		*) printf '%s\n' "$a" ;;
		esac
	done
}

_raiz_do_projeto() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }

# O nome do projeto é o mesmo que o Compose usa: do ambiente, senão do `.env`,
# senão o padrão das composições. Um clone com outro nome resolve os próprios
# contêineres, e não os do checkout antigo.
projeto_compose() {
	if [ -n "${COMPOSE_PROJECT_NAME:-}" ]; then
		printf '%s' "$COMPOSE_PROJECT_NAME"
		return
	fi
	local env_file valor=""
	env_file="$(_raiz_do_projeto)/.env"
	if [ -f "$env_file" ]; then
		valor=$(sed -n 's/^COMPOSE_PROJECT_NAME=//p' "$env_file" | head -1 | tr -d '"'"'"' \r')
	fi
	printf '%s' "${valor:-mvp_ed1}"
}

# Nomes dos contêineres de um ou mais serviços. Sem `--todos`, só os de pé.
# Sai 4, sem imprimir nada, se o `docker ps` falhar em qualquer consulta.
resolver() {
	local todos=false
	if [ "${1:-}" = "--todos" ]; then todos=true; shift; fi
	local projeto servico nomes
	projeto=$(projeto_compose)
	for servico in $(_expandir "$@"); do
		if $todos; then
			nomes=$(docker ps -a --filter "label=com.docker.compose.project=$projeto" \
				--filter "label=com.docker.compose.service=$servico" \
				--format '{{.Names}}' 2>/dev/null) || return 4
		else
			nomes=$(docker ps --filter "label=com.docker.compose.project=$projeto" \
				--filter "label=com.docker.compose.service=$servico" \
				--format '{{.Names}}' 2>/dev/null) || return 4
		fi
		[ -n "$nomes" ] && printf '%s\n' "$nomes"
	done
	return 0
}

_quantos() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | wc -l; }

pausar() {
	local rotulo="$1"; shift
	local antes restantes
	antes=$(resolver "$@") || {
		echo "ATENÇÃO: não sei se $rotulo está de pé — o Docker não respondeu. Nada foi parado."
		return 4
	}
	if [ -z "$antes" ]; then
		echo "$rotulo já não estava de pé."
		return 3
	fi
	# shellcheck disable=SC2086
	docker stop $antes >/dev/null 2>&1
	restantes=$(resolver "$@") || {
		echo "ATENÇÃO: mandei parar $rotulo e não consegui conferir o resultado — o Docker não respondeu."
		return 1
	}
	if [ -n "$restantes" ]; then
		echo "ATENÇÃO: $rotulo NÃO foi pausado — $(_quantos "$restantes") de $(_quantos "$antes") continuam de pé:"
		printf '  %s\n' $restantes
		return 1
	fi
	echo "$rotulo pausado — $(_quantos "$antes") contêineres parados.${RETOMAR_COM:+ Retomar: $RETOMAR_COM}"
	return 0
}

retomar() {
	local rotulo="$1"; shift
	local alvos de_pe ausentes
	alvos=$(resolver --todos "$@") || {
		echo "ATENÇÃO: não sei quais contêineres $rotulo tem — o Docker não respondeu. Nada foi religado."
		return 4
	}
	if [ -z "$alvos" ]; then
		echo "$rotulo não tem contêineres neste projeto — nada a retomar."
		return 3
	fi
	# shellcheck disable=SC2086
	docker start $alvos >/dev/null 2>&1
	de_pe=$(resolver "$@") || {
		echo "ATENÇÃO: mandei religar $rotulo e não consegui conferir o resultado — o Docker não respondeu."
		return 1
	}
	ausentes=$(comm -23 <(printf '%s\n' $alvos | sort) <(printf '%s\n' $de_pe | sort))
	if [ -n "$ausentes" ]; then
		echo "ATENÇÃO: $rotulo NÃO voltou por inteiro — $(_quantos "$ausentes") de $(_quantos "$alvos") continuam parados:"
		printf '  %s\n' $ausentes
		return 1
	fi
	echo "$rotulo retomado — $(_quantos "$alvos") contêineres de pé."
	return 0
}

# --- CLI, só quando executado ------------------------------------------------
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	acao="${1:?uso: conteineres.sh <resolver|pausar|retomar> ...}"; shift
	case "$acao" in
	resolver) resolver "$@" ;;
	pausar)   pausar "$@" ;;
	retomar)  retomar "$@" ;;
	*) echo "conteineres.sh: ação desconhecida '$acao'" >&2; exit 2 ;;
	esac
fi
