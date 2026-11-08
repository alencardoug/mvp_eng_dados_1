# Interface única de operação do projeto (ADR-0012, Execução Local).
# O contrato completo — inclusive os alvos que ainda não existem e a etapa em
# que cada um nasce — está em docs/execucao_local.md. Aqui vive só o que já
# funciona: duplicar a lista seria defeito (P8).

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Composições separadas compartilham o nome do projeto, então cada uma vê as
# outras como "órfãs" e sugere `--remove-orphans` — que aqui apagaria os três
# bancos. A sugestão é perigosa, e o aviso é desligado por isso.
export COMPOSE_IGNORE_ORPHANS := true

COMPOSE := docker compose --env-file .env -f docker/docker-compose.yml
COMPOSE_AIRFLOW := docker compose --env-file .env -f docker/docker-compose.airflow.yml
COMPOSE_STREAM := docker compose --env-file .env -f docker/docker-compose.streaming.yml
# O .env é carregado em cada receita: `make` roda um shell novo por linha.
ALEMBIC := set -a; . ./.env; set +a; .venv/bin/alembic
ALEMBIC_LEGACY := set -a; . ./.env; set +a; .venv/bin/alembic -n legacy
# O gerador lê a conexão do ambiente, nunca de argumento (mvp_ed1/db.py).
GERADOR := set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.generator.cli
# O caminho quente lê conexão e parâmetros do ambiente e de streaming/*.yml.
STREAM := set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.streaming.cli

# Ferramentas externas, fixadas em .tools/ e ignoradas pelo Git. A versão vive
# aqui, não na máquina de quem clona: o projeto fixa imagem por digest e
# interpretador por série, e ferramenta de linha de comando não é exceção.
ABCTL_VERSION := v0.30.4
# Fixar o abctl não fixa o Airbyte: sem `--chart-version`, o v0.30.4 instala o
# chart mais recente do repositório. 2.3.0 é o que o B5 instalou e mediu do
# zero em 25/09/2026; trocar é decisão, não efeito de data (RVF12-10).
AIRBYTE_CHART_VERSION := 2.3.0
TERRAFORM_VERSION := 1.16.1
# O acesso desta máquina ao Cloud SQL da Etapa 13 (IP público sem rede autorizada: só o
# proxy entra, por TLS e IAM). A soma é a das notas da versão, conferida no download.
CLOUD_SQL_PROXY_VERSION := v2.26.3
CLOUD_SQL_PROXY_SHA256 := 5533a05cdbf12f8a0cb46db34c775847a496e181d47f863284d3d02b0fad49fa
# O Helm da linha 3, a do provider do Terraform (hashicorp/helm 3.3): renderiza o chart local do
# Debezium Server antes do `apply` e desinstala os releases no desmonte (§6.5 passos 3–4).
HELM_VERSION := v3.22.1
HELM_SHA256 := 896cf63684a42a723d61c980369d6e588330927deb13676ca0d85006dd6da0ea
# O kubectl do GKE (A30): lê do cluster as credenciais do Airbyte e o IP do *load balancer*
# interno para o Secret Manager (`gcp-composer-segredos`). Uma versão menor de folga para cada
# lado do plano de controle; o canal REGULAR fica atrás da estável. A soma é a de dl.k8s.io.
KUBECTL_VERSION := v1.35.10
KUBECTL_SHA256 := c49a28f1f4efc4d475ed05f47f2ce8e563bf7bef69ed77fe1b924ea6d83b6327
ABCTL := DO_NOT_TRACK=1 .tools/abctl
TERRAFORM := .tools/terraform -chdir=airbyte

# O dbt lê a conexão do ambiente (dbt/profiles.yml) e os perfis do próprio
# diretório do projeto, nunca de ~/.dbt.
DBT := set -a; . ./.env; set +a; cd dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt

# Credenciais do Airbyte no momento da execução; nunca gravadas em arquivo.
CREDENCIAIS = eval "$$($(ABCTL) local credentials 2>/dev/null \
	| sed 's/\x1b\[[0-9;]*m//g' \
	| sed -n 's/.*Client-Id: \(\S*\).*/AIRBYTE_CLIENT_ID=\1/p; s/.*Client-Secret: \(\S*\).*/AIRBYTE_CLIENT_SECRET=\1/p' \
	| sed 's/^/export /')" 
# A interface e a API do Airbyte local, na porta padrão do `abctl`.
AIRBYTE_WEB := http://localhost:8000
BASE := source_db legacy_db warehouse_db

# Resolução de contêineres por rótulo do Compose. A regra vive em
# docker/conteineres.sh — dono único —, e daqui só se consome: a composição do
# Airflow não declara `container_name`, e procurar por prefixo de nome nunca
# achou nada (RV12-2-03). Os grupos de serviço (`@airflow`, `@streaming`,
# `@bancos`) também são declarados lá, e citados aqui por nome: repetir a lista
# neste arquivo seria a mesma divergência, um serviço novo depois.
CONTEINERES := docker/conteineres.sh
AIRFLOW_CLI := docker/airflow_cli.sh

# A rede do projeto (D55). As três composições a declaram `external`, e ela
# nasce aqui, antes de qualquer `up`: nenhum `down` a remove. Gerida pelo
# Compose, ela ia embora no `make down` dos bancos, e os contêineres pausados
# do Airflow e do streaming ficavam presos ao ID da rede antiga — o `docker
# start` recusava ("network … not found"), e nem `airflow-up` recriava o
# `airflow_db`. Foi assim de 21/09 a 24/09/2026. O nome é o que o Compose já
# dava à rede, para que os contêineres de pé continuem nela sem recriação.
# Nenhum alvo a remove: ela não guarda estado, e removê-la é o que prendia os
# pausados.
#
# **O nome do projeto é o que o Compose resolve (RVE4-01)**, e vem de
# `conteineres.sh`, dono da regra, que o pergunta ao próprio Compose. Uma
# leitura do `.env` por `sed` divergia dele em formas válidas do arquivo, e a
# garantia preparava uma rede enquanto o `up` exigia outra — "declared as
# external, but could not be found". Sem o nome, nada é criado.
GARANTIR_REDE = projeto=$$($(CONTEINERES) projeto) \
	|| { echo "ERRO: o Compose não disse o nome do projeto — sem ele a rede não tem nome, e nada foi criado."; exit 1; }; \
	docker network inspect "$${projeto}_default" >/dev/null 2>&1 \
	|| docker network create "$${projeto}_default" >/dev/null \
	|| { echo "ERRO: a rede $${projeto}_default não existe e não consegui criá-la — o Docker respondeu?"; exit 1; }

# O login de leitura (Governança §7) nasce no `garantir()`, e o `.env` de um
# checkout anterior a ele não tem as chaves: acrescentam-se aqui, como o
# `airflow-up` faz com os segredos do Airflow. Nunca sobrescreve.
GARANTIR_LEITOR_NO_ENV = grep -q '^WAREHOUSE_READER_USER=' .env || { \
	echo "acrescentando o login de leitura do armazém ao .env"; \
	pw() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32; }; \
	{ echo ""; echo "\# Login só de leitura do armazém (v1.1.0) — acrescentado por 'make dbt-build'."; \
	  echo "WAREHOUSE_READER_USER=consumption_reader"; \
	  echo "WAREHOUSE_READER_PASSWORD=$$(pw)"; } >> .env; }

# O livro retido da memória do legado (v1.1.0, H6): a raiz em que a CLI e a DAG
# registram cada tentativa de captura. Um `.env` de antes dele a ganha aqui,
# com o diretório criado; uma variável vazia faz o `mkdir` falhar — o registro
# nunca é pulado. O Airflow monta o mesmo diretório, gravável.
GARANTIR_LIVRO_NO_ENV = grep -q '^LEGACY_LEDGER_DIR=' .env || { \
	echo "acrescentando a raiz do livro retido da memória do legado ao .env"; \
	{ echo ""; echo "\# Livro retido da memória do legado (v1.1.0) — acrescentado pelo Makefile."; \
	  echo "LEGACY_LEDGER_DIR=$(abspath data/memoria_do_legado)"; } >> .env; }; \
	mkdir -p "$$(grep '^LEGACY_LEDGER_DIR=' .env | tail -1 | cut -d= -f2-)"

# A linha de base que abre a época seguinte do livro (T4, H8; ADR-0050). Dois
# chamadores: `ledger-baseline`, do operador, e o passo 8 da restauração.
LIVRO_LINHA_DE_BASE = set -a; . ./.env; set +a; $(CREDENCIAIS); .venv/bin/python -m mvp_ed1.recovery.ledger baseline

# Ponto único de recuperação (Etapa 12, B4). A lógica vive em
# `mvp_ed1.recovery`; aqui fica a sequência, porque ela mistura pg_restore,
# stream-*, airbyte-* e dbt-rebuild — e a interface de operação é o Makefile
# (ADR-0012). `RECOVERY_DIR` é **absoluto**, sempre (RV12-09), e impresso em
# toda execução: num alvo composto o relativo resolveria contra quem chama, e
# em B5 quem chama é o clone.
RECOVERY := set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.recovery
RECOVERY_DIR ?= $(abspath data/recovery)
# O jobId que o passo 8 da restauração disparou, para o passo 9 conferir a
# captura dele e não a que o banco disser (RVE2-01). Fora de `candidato/`: é
# estado desta restauração, não conteúdo do pacote.
RECOVERY_JOB = $(RECOVERY_DIR)/job-do-passo-8

# Medição (Etapa 12, B1). A lógica vive em docker/medir.sh; daqui só se passa
# o alvo. `ATE=` é o que separa "disparei" de "rodou".
MEDIR := docker/medir.sh
DAG := fluxo_batch

# Verificação de recursos antes de subir um subconjunto pesado do ambiente (R11).
# A lógica vive em docker/preflight.sh. O contrato daqui: `--trocar` autoriza o
# script a **pausar** o ambiente conflitante — nunca a desmontá-lo —, de modo que
# subir um já derruba o outro sozinho; recusa continua sendo erro; e FORCE=1 é a
# autorização explícita do Owner, mesmo idioma de `seed-data` e `reset`.
define preflight
@if [ "$(FORCE)" = "1" ]; then \
	echo "[preflight] ignorado por FORCE=1 — subida de $(1) autorizada pelo Owner."; \
else \
	docker/preflight.sh $(1) --trocar; \
fi
endef

.PHONY: help env install up down reset ps logs psql-source psql-legacy psql-warehouse \
        pgcli-source pgcli-legacy pgcli-warehouse \
        migrate migrate-down migrate-new migrate-status migrate-legacy migrate-legacy-down \
        migrate-legacy-status migrate-legacy-new catalog seed-data seed-plan size-report test test-carga \
        tools airbyte-up airbyte-down airbyte-credentials airbyte-config airbyte-plan sync-airbyte \
        dbt-build dbt-drop-snapshots dbt-test dbt-docs airflow-up airflow-down dag-run dag-status \
        stream-up stream-down stream-connector stream-status stream-run stream-produce \
        stream-duplicate stream-alerts stream-reset-sink \
        preflight airbyte-pause airbyte-resume stream-pause stream-resume \
        airflow-pause airflow-resume medir dag-wait stream-corte stream-wait docs-generate \
        docs-check secrets-history dbt-rebuild check-offline \
        recovery-pack recovery-verify recovery-rebase recovery-airbyte-jobs recovery-restore recovery-promote \
        generation-measure generation-compare generation-realism ledger-baseline ledger-attempt ledger-treatment memory-oracle source-oracle \
        gcp-preflight gcp-plan gcp-apply gcp-sql-proxy gcp-origens-migrar gcp-origens-povoar gcp-origens-oraculo \
        gcp-origens-replicacao gcp-g21-prova gcp-airbyte-config gcp-armazem-zerar gcp-armazem-governanca gcp-livro-epoca \
        gcp-dbt-build gcp-oraculos gcp-carga-dev gcp-composer-prova \
        gcp-composer-segredos gcp-composer-publicar gcp-composer-smoke \
        gcp-dataflow-tabela gcp-dataflow-validar gcp-dataflow-lancar gcp-dataflow-parar \
        gcp-desmonte-parar gcp-desmonte-slot gcp-desmonte-kubernetes gcp-desmonte-orfaos gcp-desmonte-sql gcp-desmonte-linhagem \
        gcp-desmonte-inventario gcp-desmonte-orcamento gcp-desligar-faturamento gcp-apagar-projeto \
        require-env require-venv require-abctl require-terraform require-cloud-sql-proxy require-kubectl

help: ## Lista os alvos disponíveis
	@echo "Alvos disponíveis:"
	@grep -hE '^[a-z][a-zA-Z_-]*:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Contrato completo da operação: docs/execucao_local.md"

require-venv:
	@test -x .venv/bin/alembic || { \
		echo "ERRO: ambiente Python ausente. Rode 'make install'."; \
		exit 1; \
	}

require-env:
	@test -f .env || { \
		echo "ERRO: .env não existe. Rode 'make env' para gerá-lo."; \
		exit 1; \
	}

env: ## Gera um .env com portas padrão e senhas aleatórias (não sobrescreve)
	@if [ -f .env ] && [ "$(FORCE)" != "1" ]; then \
		echo "ERRO: .env já existe. Use 'make env FORCE=1' para regerar."; \
		echo "      Regerar troca as senhas: os volumes existentes deixam de abrir."; \
		exit 1; \
	fi
	@pw() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32; }; \
	{ \
		echo "# Gerado por 'make env'. NUNCA versionar — ver .gitignore."; \
		echo "COMPOSE_PROJECT_NAME=mvp_ed1"; \
		echo ""; \
		echo "SOURCE_DB_NAME=source_db"; \
		echo "SOURCE_DB_USER=mvp_source"; \
		echo "SOURCE_DB_PASSWORD=$$(pw)"; \
		echo "SOURCE_DB_PORT=5432"; \
		echo ""; \
		echo "LEGACY_DB_NAME=legacy_db"; \
		echo "LEGACY_DB_USER=mvp_legacy"; \
		echo "LEGACY_DB_PASSWORD=$$(pw)"; \
		echo "LEGACY_DB_PORT=5433"; \
		echo ""; \
		echo "WAREHOUSE_DB_NAME=warehouse_db"; \
		echo "WAREHOUSE_DB_USER=mvp_warehouse"; \
		echo "WAREHOUSE_DB_PASSWORD=$$(pw)"; \
		echo "WAREHOUSE_DB_PORT=5434"; \
		echo "WAREHOUSE_READER_USER=consumption_reader"; \
		echo "WAREHOUSE_READER_PASSWORD=$$(pw)"; \
		echo ""; \
		echo "# Livro retido da memória do legado (v1.1.0) — fora do Git, montado no Airflow."; \
		echo "LEGACY_LEDGER_DIR=$(abspath data/memoria_do_legado)"; \
		echo ""; \
		echo "# Airflow (Etapa 5) — porta e segredos do orquestrador."; \
		echo "AIRFLOW_PORT=8081"; \
		echo "AIRFLOW_JWT_SECRET=$$(pw)"; \
		echo "AIRFLOW_FERNET_KEY=$$(pw)"; \
		echo "AIRFLOW_DB_NAME=airflow"; \
		echo "AIRFLOW_DB_USER=airflow"; \
		echo "AIRFLOW_DB_PASSWORD=$$(pw)"; \
		echo ""; \
		echo "# Caminho quente (Etapa 7) — portas do transporte e do Connect."; \
		echo "REDPANDA_PORT=19092"; \
		echo "REDPANDA_ADMIN_PORT=19644"; \
		echo "KAFKA_CONNECT_PORT=8083"; \
	} > .env
	@chmod 600 .env
	@mkdir -p "$(abspath data/memoria_do_legado)"
	@echo "'.env' criado com senhas aleatórias e permissão 600."

install: ## Cria o .venv com Python 3.11, instala o projeto em modo editável e os pacotes dbt da trava
	uv sync
	@# Os pacotes do dbt — dbt_utils, dbt_expectations, dbt_date — não vêm do
	@# `uv`: sem eles, o primeiro comando dbt de um clone falha no `parse`
	@# (RV12-07, medido na revisão do plano). `dbt deps` instala as versões do
	@# `package-lock.yml` versionado, e não as mais novas que o `packages.yml`
	@# aceita. Não precisa do `.env`: o perfil só é lido por quem conecta.
	cd dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt deps
	@echo ""
	@echo "Ambiente pronto. O 'uv.lock' e o 'dbt/package-lock.yml' são as travas — versione-os."
	@.venv/bin/python -c "import mvp_ed1, sys; print(f'mvp_ed1 {mvp_ed1.__version__} sobre Python {sys.version.split()[0]}')"

up: require-env ## Sobe os três bancos e espera ficarem saudáveis
	@$(GARANTIR_REDE)
	$(COMPOSE) up -d --wait $(BASE)
	@echo ""
	@$(MAKE) --no-print-directory ps

down: require-env ## Derruba os contêineres preservando os volumes
	$(COMPOSE) down

reset: require-env ## DESTRÓI estado: derruba e apaga os volumes
	@if [ "$(FORCE)" != "1" ]; then \
		read -p "Apagar TODOS os volumes dos três bancos? [s/N] " r; \
		[ "$$r" = "s" ] || { echo "Cancelado."; exit 1; }; \
	fi
	$(COMPOSE) down -v
	@echo "Volumes apagados. O próximo 'make up' começa do zero."

migrate: require-env require-venv ## Aplica as migrações Alembic até a última
	@$(ALEMBIC) upgrade head

migrate-down: require-env require-venv ## Desfaz migrações; TO=base derruba tudo, padrão -1
	@$(ALEMBIC) downgrade $(or $(TO),-1)

migrate-new: require-env require-venv ## Gera rascunho de migração; exige M="mensagem"
	@test -n '$(M)' || { echo 'ERRO: use make migrate-new M="o que mudou"'; exit 1; }
	@$(ALEMBIC) revision --autogenerate -m '$(M)'
	@echo ""
	@echo "RASCUNHO gerado. Revise antes de aplicar: o autogenerate não detecta"
	@echo "renomeação, conversão de tipo nem mudança de constraint (ADR-0010)."

catalog: require-venv ## Regenera dicionário, inventário, diagrama ER, a classificação e a descrição derivadas e a linhagem por coluna
	@.venv/bin/python -m mvp_ed1.models.export
	@# A sensibilidade e a descrição de cada coluna do armazém são derivadas das
	@# declaradas nos modelos, pelo SQL compilado — precisa do manifest de um
	@# `make dbt-build` recente. Sem ele, avisa e não escreve nada. A linhagem
	@# por coluna (Dicionário §3) sai da mesma leitura, guardada em
	@# dbt/target, logo depois. Texto do staging mudou? A ponte do legado o
	@# copia: `make legacy-models` e este alvo de novo (Governança §5.1).
	@.venv/bin/python -m mvp_ed1.models.sensitivity
	@.venv/bin/python -m mvp_ed1.models.lineage

seed-data: require-env require-venv ## Gera e carrega os dados sintéticos; SCALE, SEED, AS_OF, FORCE=1
	@$(GERADOR) seed \
		$(if $(SCALE),--scale $(SCALE)) $(if $(SEED),--seed $(SEED)) \
		$(if $(AS_OF),--as-of $(AS_OF)) $(if $(filter 1,$(FORCE)),--force) \
		$(if $(filter 1,$(DRY_RUN)),--dry-run)

seed-legacy: require-env require-venv migrate-legacy ## Gera a origem legada com as falhas do catálogo; FORCE=1 trunca antes
	@# O legado tem semente e fator próprios, declarados no catálogo — não são
	@# argumentos. Duas origens compartilhando sequência deixariam de ser duas.
	@# O schema vem da migração (dependência acima), nunca da carga.
	@set -a; . ./.env; set +a; \
		.venv/bin/python -m mvp_ed1.legacy.cli seed $(if $(filter 1,$(FORCE)),--force)

legacy-models: require-venv ## Regenera os modelos dbt de limpeza a partir do catálogo
	@# Derivado, não escrito à mão: erro aqui se corrige no catálogo ou em
	@# `regras.py`, e não no arquivo gerado (CLAUDE.md §5).
	@.venv/bin/python -m mvp_ed1.legacy.cli models

legacy-catalogo: require-venv ## Imprime o catálogo de falhas em português, para revisão sem abrir o YAML
	@.venv/bin/python -m mvp_ed1.legacy.cli catalogo

legacy-plan: require-venv ## Mostra o que o legado geraria e injetaria, sem tocar no banco
	@.venv/bin/python -m mvp_ed1.legacy.cli plan

seed-plan: require-venv ## Mostra o plano de volume das 40 tabelas, sem tocar no banco
	@.venv/bin/python -m mvp_ed1.generator.cli plan $(if $(SCALE),--scale $(SCALE))

generation-measure: require-venv ## T1: gera as duas origens em memória e mede cada tabela, sem tocar banco; SCALE, SEED, AS_OF
	@.venv/bin/python -m mvp_ed1.recovery.sources measure \
		$(if $(SCALE),--scale $(SCALE)) $(if $(SEED),--seed $(SEED)) $(if $(AS_OF),--as-of $(AS_OF))

generation-compare: require-venv ## T1: o que muda entre duas medidas da geração — tabelas e chaves do legado; ANTES=, DEPOIS=, MANIFESTO_ANTES= (o diário de mutações entra no lado de antes)
	@test -n '$(ANTES)' && test -n '$(DEPOIS)' || { echo 'ERRO: use make generation-compare ANTES=<medida> DEPOIS=<medida>'; exit 1; }
	@.venv/bin/python -m mvp_ed1.recovery.sources compare '$(ANTES)' '$(DEPOIS)' \
		$(if $(MANIFESTO_ANTES),--before-manifest '$(MANIFESTO_ANTES)')

generation-realism: require-venv ## H3: M7 a M9 (árvore, preço por folha, venda antes do lançamento) sobre a geração em memória; SCALE, SEED, AS_OF
	@.venv/bin/python -m mvp_ed1.recovery.realism \
		$(if $(SCALE),--scale $(SCALE)) $(if $(SEED),--seed $(SEED)) $(if $(AS_OF),--as-of $(AS_OF))

ledger-baseline: require-env require-venv require-abctl ## T4/H8: abre a época seguinte do livro retido com a linha de base da memória de agora; recusa com trabalho em andamento
	@$(GARANTIR_LIVRO_NO_ENV)
	@docker/preflight.sh trabalho || { echo "RECUSADO — há trabalho em andamento: a linha de base pede a janela parada."; exit 1; }
	@$(LIVRO_LINHA_DE_BASE)

ledger-attempt: require-env require-venv ## T4: o registro de uma tentativa à mão, na época corrente; TENTATIVA=<capture_attempt_id> NOME=<linha>_a<n>_memoria.json — recusa com o lock dela tomado
	@test -n '$(TENTATIVA)' && test -n '$(NOME)' || { echo 'ERRO: use make ledger-attempt TENTATIVA=<id> NOME=<D2_a1_memoria.json>'; exit 1; }
	@set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.recovery.ledger attempt --attempt '$(TENTATIVA)' --name '$(NOME)'

ledger-treatment: require-env require-venv ## T4: o registro do tratamento corrente e das rejeitadas dele, na época corrente; NOME=<linha>_a<n>_tratamento.json
	@test -n '$(NOME)' || { echo 'ERRO: use make ledger-treatment NOME=<D3_a1_tratamento.json>'; exit 1; }
	@set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.recovery.ledger treatment --name '$(NOME)'

memory-oracle: require-env require-venv ## T3: a memória do legado contra o livro retido, somente leitura; LIVRO_DE_CAPTURAS=<json com "certified"> do diário; REMOCOES_ACEITAS=<comparação do H2>; REAPARICOES_ACEITAS=<comparação do H2 sobre o estado real>
	@set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.recovery.memory_oracle \
		$(if $(LIVRO_DE_CAPTURAS),--capture-ledger '$(LIVRO_DE_CAPTURAS)') \
		$(if $(REMOCOES_ACEITAS),--accepted-removals '$(REMOCOES_ACEITAS)') \
		$(if $(REAPARICOES_ACEITAS),--accepted-reappearances '$(REAPARICOES_ACEITAS)')

source-oracle: require-env require-venv ## T2: as duas origens, em sessão somente leitura, contra uma medida; MEDIDA=, CALIBRACAO=1
	@test -n '$(MEDIDA)' || { echo 'ERRO: use make source-oracle MEDIDA=<medida da geração>'; exit 1; }
	@set -a; . ./.env; set +a; RECOVERY_DIR="$(RECOVERY_DIR)" \
		.venv/bin/python -m mvp_ed1.recovery.sources oracle '$(MEDIDA)' $(if $(filter 1,$(CALIBRACAO)),--calibration)

size-report: require-env require-venv ## Tamanho por banco, tabela e índice — observação, não limite
	@$(GERADOR) size-report

tools: ## Baixa abctl, Terraform, o Cloud SQL Auth Proxy, o Helm e o kubectl fixados para .tools/ (fora do Git)
	@mkdir -p .tools
	@test -x .tools/abctl || { \
		echo "baixando abctl $(ABCTL_VERSION)"; \
		curl -sSL "https://github.com/airbytehq/abctl/releases/download/$(ABCTL_VERSION)/abctl-$(ABCTL_VERSION)-linux-amd64.tar.gz" \
			| tar -xz -C .tools --strip-components=1 abctl-$(ABCTL_VERSION)-linux-amd64/abctl; \
		chmod +x .tools/abctl; }
	@test -x .tools/terraform || { \
		echo "baixando Terraform $(TERRAFORM_VERSION)"; \
		curl -sSL "https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip" -o /tmp/tf.zip; \
		unzip -oq /tmp/tf.zip -d .tools && rm -f /tmp/tf.zip; }
	@test -x .tools/cloud-sql-proxy || { \
		echo "baixando Cloud SQL Auth Proxy $(CLOUD_SQL_PROXY_VERSION)"; \
		curl -sSL "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/$(CLOUD_SQL_PROXY_VERSION)/cloud-sql-proxy.linux.amd64" \
			-o .tools/cloud-sql-proxy.baixado \
		&& echo "$(CLOUD_SQL_PROXY_SHA256)  .tools/cloud-sql-proxy.baixado" | sha256sum -c --quiet \
		&& mv .tools/cloud-sql-proxy.baixado .tools/cloud-sql-proxy && chmod +x .tools/cloud-sql-proxy \
		|| { rm -f .tools/cloud-sql-proxy.baixado; echo "ERRO: o proxy baixado não confere com a soma fixada"; exit 1; }; }
	@test -x .tools/helm || { \
		echo "baixando Helm $(HELM_VERSION)"; \
		curl -sSL "https://get.helm.sh/helm-$(HELM_VERSION)-linux-amd64.tar.gz" -o .tools/helm.tar.gz \
		&& echo "$(HELM_SHA256)  .tools/helm.tar.gz" | sha256sum -c --quiet \
		&& tar -xzf .tools/helm.tar.gz -C .tools --strip-components=1 linux-amd64/helm && rm -f .tools/helm.tar.gz \
		|| { rm -f .tools/helm.tar.gz; echo "ERRO: o Helm baixado não confere com a soma fixada"; exit 1; }; }
	@test -x .tools/kubectl || { \
		echo "baixando kubectl $(KUBECTL_VERSION)"; \
		curl -sSL "https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/linux/amd64/kubectl" -o .tools/kubectl.baixado \
		&& echo "$(KUBECTL_SHA256)  .tools/kubectl.baixado" | sha256sum -c --quiet \
		&& mv .tools/kubectl.baixado .tools/kubectl && chmod +x .tools/kubectl \
		|| { rm -f .tools/kubectl.baixado; echo "ERRO: o kubectl baixado não confere com a soma fixada"; exit 1; }; }
	@.tools/abctl version 2>/dev/null | tail -1; .tools/terraform version | head -1; .tools/cloud-sql-proxy --version; .tools/helm version --short; .tools/kubectl version --client | head -1

require-abctl:
	@test -x .tools/abctl || { echo "ERRO: abctl ausente. Rode 'make tools'."; exit 1; }

require-terraform:
	@test -x .tools/terraform || { echo "ERRO: Terraform ausente. Rode 'make tools'."; exit 1; }

require-cloud-sql-proxy:
	@test -x .tools/cloud-sql-proxy || { echo "ERRO: Cloud SQL Auth Proxy ausente. Rode 'make tools'."; exit 1; }

require-kubectl:
	@test -x .tools/kubectl || { echo "ERRO: kubectl ausente. Rode 'make tools'."; exit 1; }

preflight: ## Diz se cabe subir um subconjunto; ALVO=airbyte|airflow|streaming|trabalho
	@docker/preflight.sh $(ALVO)

medir: ## Mede um alvo: ALVO= [ATE=<alvo de espera>], ou CENARIO=streaming [LIMITE=n]
	@$(MEDIR) $(if $(CENARIO),--cenario $(CENARIO) $(if $(LIMITE),--limite $(LIMITE)),$(ALVO) $(if $(ATE),--ate $(ATE)))

# ── Pausa e retomada ────────────────────────────────────────────────────────
# Devolver memória à máquina sem desmontar nada. `airbyte-down` é
# `abctl local uninstall`: destrói o cluster, e voltar custa uma reinstalação
# inteira — que é justamente onde mora a armadilha do `PG_VERSION`
# (Execução Local §6). Parar o contêiner libera a mesma memória e volta sem
# reinstalar nada — quanto leva está em `AGUARDAR_API_AIRBYTE`, medido.
#
# **Retomar passa pela mesma troca que subir (D54).** Os `*-resume` religavam
# sem conferir memória nem conflito, e o preflight mandava retomar por eles:
# retomar o Airbyte com o *streaming* de pé subia as duas famílias juntas, que
# é o R11. `FORCE=1` continua sendo o caminho sem conferência — agora o único,
# e do Owner. Antes da troca, cada retomada confere que há o que religar: sem
# isso, o preflight pausaria o outro ambiente à toa.
airbyte-pause: ## Para o cluster do Airbyte liberando a memória, sem desmontá-lo
	@docker stop airbyte-abctl-control-plane >/dev/null 2>&1 && \
		echo "Airbyte pausado. Retomar: make airbyte-resume" || \
		echo "Airbyte já não estava de pé."

# O estado do nó do Airbyte, lido antes de decidir: `running`, `exited`, ou
# vazio quando ele não existe. Consulta que falha não é "não existe" (RVE-08) —
# em `airbyte-up`, a consulta vazia levava ao `abctl local install` —, e um
# estado que nenhum caminho sabe tratar (um `docker pause`, por exemplo) também
# recusa antes de mexer em qualquer coisa.
ESTADO_AIRBYTE = estado=$$(docker ps -a -f 'name=^airbyte-abctl-control-plane$$' --format '{{.State}}') \
	|| { echo "ERRO: o Docker não respondeu — sem saber o estado do cluster, nada foi tocado."; exit 1; }; \
	case "$$estado" in running|exited|"") ;; \
	*) echo "ERRO: o cluster está '$$estado' — nem de pé, nem pausado, nem ausente. Veja 'docker ps -a'."; exit 1 ;; \
	esac

# Esperar a API do Airbyte: uma receita, três chamadores — `airbyte-resume` e os
# ramos "pausado" e "de pé" de `airbyte-up`. Variável, e não `$(MAKE) ...`
# dentro do `case` de `airbyte-up`: o `make` executa de verdade, mesmo sob
# `-n`, toda linha em cujo texto aparece `$(MAKE)`, e aquela linha tinha no
# outro ramo o `abctl local install` — um `make -n recovery-restore` o chamou
# com o Airbyte de pé (23/09/2026).
#
# **Pronto é a API responder `available:true`, não um pod (RVE3-02).** Medido
# em três retomadas reais em 23/09/2026: o nó lista os sandboxes da partida
# anterior como `NotReady`, e o `grep -q Ready` da espera antiga casava neles —
# dizia "pronto" em 5,6 s. Nem pod serve: o primeiro sandbox fica pronto em
# ~5 s, e o Kubernetes chegou a dizer 8/8 prontos aos 5 s, estado de antes da
# pausa. A API respondeu entre 74 s e 101 s (74 s com 9,0 GB livres depois da
# pausa, 96 s com 6,3 GB), e o ingress devolve 503 na metade final. Quem vem
# depois — `recovery-airbyte-jobs`, `sync-airbyte` — usa a API e o banco dela.
# O prazo, 60 consultas com 5 s de pausa entre elas, é três vezes o medido, e
# esgotá-lo é erro. A pausa não é o período: esgotado de verdade, ele levou
# 301 s com a API recusando na hora e 602 s com cada consulta gastando os 5 s
# do `--max-time` — por isso a mensagem diz o tempo que o bash contou, e não
# uma cadência. Sem `curl` a espera seria cega — o `2>/dev/null` engoliria o
# "command not found" e o prazo venceria dizendo que a API não respondeu —,
# por isso a falta dele (`CURL_DA_ESPERA`) recusa antes da troca do preflight e
# de religar qualquer coisa.
CURL_DA_ESPERA = command -v curl >/dev/null \
	|| { echo "ERRO: curl ausente — é por ele que se espera a API do Airbyte."; exit 1; }
AGUARDAR_API_AIRBYTE = printf "aguardando a API do Airbyte"; pronta=; \
	for i in $$(seq 1 60); do \
		if curl -s --max-time 5 $(AIRBYTE_WEB)/api/v1/health 2>/dev/null | grep -Eq '"available": *true'; then \
			pronta=1; break; fi; \
		printf "."; sleep 5; done; \
	[ -n "$$pronta" ] || { echo " tempo esgotado: a API não respondeu a 60 consultas em $$SECONDS s."; \
		echo "  Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'."; exit 1; }; \
	echo " pronta."
RETOMAR_AIRBYTE = docker start airbyte-abctl-control-plane >/dev/null \
	|| { echo "ERRO: o cluster não religou — veja 'docker ps -a'."; exit 1; }; \
	$(AGUARDAR_API_AIRBYTE)

airbyte-resume: ## Religa o cluster do Airbyte pausado, pela troca do preflight, e espera a API responder
	@$(ESTADO_AIRBYTE); [ -n "$$estado" ] || { echo "ERRO: cluster não existe. Use 'make airbyte-up'."; exit 1; }; \
		$(CURL_DA_ESPERA)
	$(call preflight,airbyte)
	@$(RETOMAR_AIRBYTE)

stream-pause: ## Para Redpanda e Kafka Connect preservando os contêineres e o conector
	@RETOMAR_COM='make stream-resume' $(CONTEINERES) pausar streaming @streaming; \
		s=$$?; [ $$s -eq 3 ] && exit 0 || exit $$s

stream-resume: ## Religa Redpanda e Kafka Connect pausados, pela troca do preflight
	@n=$$($(CONTEINERES) resolver --todos @streaming) || { echo "ERRO: o Docker não respondeu — nada foi tocado."; exit 1; }; \
		[ -n "$$n" ] || { echo "streaming não tem contêineres neste projeto — use 'make stream-up'."; exit 1; }
	$(call preflight,streaming)
	@$(CONTEINERES) retomar streaming @streaming
	@echo "O conector Debezium volta do ponto em que parou."

airflow-pause: ## Para os contêineres do Airflow liberando a memória
	@RETOMAR_COM='make airflow-resume' $(CONTEINERES) pausar Airflow @airflow; \
		s=$$?; [ $$s -eq 3 ] && exit 0 || exit $$s

airflow-resume: ## Religa os contêineres do Airflow pausados, pela troca do preflight
	@n=$$($(CONTEINERES) resolver --todos @airflow) || { echo "ERRO: o Docker não respondeu — nada foi tocado."; exit 1; }; \
		[ -n "$$n" ] || { echo "Airflow não tem contêineres neste projeto — use 'make airflow-up'."; exit 1; }
	$(call preflight,airflow)
	@$(CONTEINERES) retomar Airflow @airflow

airbyte-up: require-abctl ## Sobe o Airbyte local: instala, retoma o pausado ou confere o que já está de pé
	@# Três estados, três caminhos — e o que cada um precisa é conferido antes
	@# da troca do preflight, que pausaria o outro ambiente por nada:
	@#   ausente → instala;
	@#   pausado → retoma, seja por `airbyte-pause`, seja pela troca que o
	@#     preflight faz ao subir o streaming. Não reinstala: o `abctl` valida o
	@#     cluster antes de qualquer coisa e recusa um contêiner parado, e
	@#     reinstalar esbarra no `PG_VERSION` (§6);
	@#   de pé   → confere a API (D53). O `abctl local install` sobre o cluster de
	@#     pé abortou no `PG_VERSION` em 05/09 e em 23/09/2026 (§6), e reaplicar o
	@#     chart não é o que "subir" promete.
	@$(ESTADO_AIRBYTE); [ -z "$$estado" ] || $(CURL_DA_ESPERA)
	$(call preflight,airbyte)
	@$(ESTADO_AIRBYTE); case "$$estado" in \
		running) echo "cluster de pé — conferindo a API"; $(AGUARDAR_API_AIRBYTE) ;; \
		exited) echo "cluster pausado — retomando em vez de reinstalar"; $(RETOMAR_AIRBYTE) ;; \
		"") $(ABCTL) local install --chart-version $(AIRBYTE_CHART_VERSION) --values airbyte/values.yaml ;; \
	esac
	@echo ""
	@echo "Interface em $(AIRBYTE_WEB) — credenciais em 'make airbyte-credentials'."

airbyte-down: require-abctl ## Derruba o Airbyte, preservando os dados dele
	@$(ABCTL) local uninstall

airbyte-credentials: require-abctl ## Mostra as credenciais do Airbyte local
	@$(ABCTL) local credentials

# As variáveis do Terraform do Airbyte local: as credenciais do `abctl`, o *workspace* e os três
# bancos do `.env`. Uma definição para os dois alvos que leem a raiz `airbyte/`.
AIRBYTE_TF_ENV = set -a; . ./.env; set +a; $(CREDENCIAIS); \
	export TF_VAR_airbyte_client_id="$$AIRBYTE_CLIENT_ID"; \
	export TF_VAR_airbyte_client_secret="$$AIRBYTE_CLIENT_SECRET"; \
	export TF_VAR_airbyte_workspace_id="$${AIRBYTE_WORKSPACE_ID:-$$(.venv/bin/python -m mvp_ed1.airbyte workspace)}"; \
	export TF_VAR_source_db_name="$$SOURCE_DB_NAME" TF_VAR_source_db_user="$$SOURCE_DB_USER" TF_VAR_source_db_password="$$SOURCE_DB_PASSWORD"; \
	export TF_VAR_legacy_db_name="$$LEGACY_DB_NAME" TF_VAR_legacy_db_user="$$LEGACY_DB_USER" TF_VAR_legacy_db_password="$$LEGACY_DB_PASSWORD" TF_VAR_legacy_db_port="$$LEGACY_DB_PORT"; \
	export TF_VAR_warehouse_db_name="$$WAREHOUSE_DB_NAME" TF_VAR_warehouse_db_user="$$WAREHOUSE_DB_USER" TF_VAR_warehouse_db_password="$$WAREHOUSE_DB_PASSWORD"

airbyte-config: require-env require-terraform ## Cria fonte, destino e conexão a partir do Terraform
	@# `-parallelism=1`: num Airbyte recém-instalado a tabela de segredos nasce na
	@# primeira escrita, por `CREATE TABLE IF NOT EXISTS`, que o PostgreSQL não
	@# serializa. No B5, em 25/09/2026, quatro criações simultâneas colidiram
	@# (`duplicate key … pg_type_typname_nsp_index`) e o Airbyte devolveu 500. Seis
	@# recursos, um por vez, custam segundos.
	@$(AIRBYTE_TF_ENV); \
		$(TERRAFORM) init -input=false -no-color >/dev/null && $(TERRAFORM) apply -input=false -parallelism=1 $(if $(filter 1,$(AUTO)),-auto-approve)

airbyte-plan: require-env require-terraform ## Mostra o que o airbyte-config mudaria no Airbyte local, sem aplicar; falha se há mudança ou erro, e diz qual
	@# O `-detailed-exitcode` distingue nada (0), erro (1) e mudança (2), mas o `make` devolve 2
	@# para qualquer falha de receita: quem diz qual das três foi é a última linha.
	@$(AIRBYTE_TF_ENV); \
		$(TERRAFORM) init -input=false -no-color >/dev/null || exit 1; \
		$(TERRAFORM) plan -input=false -no-color -detailed-exitcode; rc=$$?; \
		case $$rc in \
			0) echo "airbyte-plan: nada a mudar" ;; \
			2) echo "airbyte-plan: HÁ MUDANÇA (acima); nada foi aplicado"; exit 1 ;; \
			*) echo "airbyte-plan: o plan falhou (acima)"; exit 1 ;; \
		esac

sync-airbyte: require-env require-abctl ## Sincroniza oltp -> raw; RESET=1 descarta o cursor antes
	@$(CREDENCIAIS); \
		$(if $(filter 1,$(RESET)),.venv/bin/python -m mvp_ed1.airbyte reset &&) \
		.venv/bin/python -m mvp_ed1.airbyte sync

sync-legacy: require-env require-abctl ## Captura o legado -> raw_legacy e a certifica (ADR-0044); cada execução acrescenta um snapshot; JOB_EM= grava o jobId
	@# Sem RESET: o modo é `full_refresh_append` (ADR-0037), e descartar o
	@# estado aqui não faria a carga anterior voltar — ela está retida de
	@# propósito. Duas execuções são duas capturas, que é o ponto.
	@# `--certificar-legado` põe a sincronização entre as duas fases do
	@# certificado: origem medida antes, origem e bruto conferidos depois.
	@# `JOB_EM=<arquivo>` grava o jobId da captura concluída e certificada — é
	@# como o passo 9 da restauração recebe a identidade do passo 8 (RVE2-01).
	@$(GARANTIR_LIVRO_NO_ENV)
	@set -a; . ./.env; set +a; $(CREDENCIAIS); \
		.venv/bin/python -m mvp_ed1.airbyte sync --connection legacy_para_raw_legacy --certificar-legado \
		$(if $(JOB_EM),--job-em "$(JOB_EM)")

dbt-build: require-env require-venv ## Roda os modelos dbt e os testes; RESET=1 refaz histórico SCD e incrementais
	@# `--full-refresh` junto com o descarte do histórico, e não por precaução:
	@# refazer os snapshots troca **todas** as chaves substitutas, e a fato
	@# incremental continuaria apontando para as antigas. O teste de
	@# `relationships` pega — depois de 13.514 linhas órfãs.
	@# `governance.legacy_captures` é `source` dos modelos do legado (ADR-0044):
	@# garantir o schema antes de compilar é o que evita "relation does not exist"
	@# num armazém que ainda não teve sincronização certificada.
	@# O descarte e o build em linhas separadas, e não ligados por `&&`: o `make`
	@# executa sob `-n` toda linha em cujo texto aparece `$(MAKE)` — mesmo com o
	@# `RESET` desligado —, e o `&&` levava junto o `dbt build` (23/09/2026).
	@$(GARANTIR_LEITOR_NO_ENV)
	@set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.governance garantir
	@$(if $(filter 1,$(RESET)),$(MAKE) --no-print-directory dbt-drop-snapshots)
	@$(DBT) build $(if $(filter 1,$(RESET)),--full-refresh) $(DBT_ARGS)

airflow-up: require-env require-abctl ## Sobe o Airflow local (LocalExecutor, três contêineres)
	$(call preflight,airflow)
	@grep -q '^AIRFLOW_JWT_SECRET=' .env || { \
		echo "acrescentando os segredos do Airflow ao .env"; \
		pw() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32; }; \
		{ echo ""; echo "# Airflow (Etapa 5) — acrescentado por 'make airflow-up'."; \
		  echo "AIRFLOW_PORT=8081"; \
		  echo "AIRFLOW_JWT_SECRET=$$(pw)"; \
		  echo "AIRFLOW_FERNET_KEY=$$(pw)"; } >> .env; }
	@$(GARANTIR_LIVRO_NO_ENV)
	@$(GARANTIR_REDE)
	@$(CREDENCIAIS); \
		AIRFLOW_UID="$$(id -u)" \
		AIRBYTE_CLIENT_ID="$$AIRBYTE_CLIENT_ID" AIRBYTE_CLIENT_SECRET="$$AIRBYTE_CLIENT_SECRET" \
		$(COMPOSE_AIRFLOW) up -d --build --wait airflow_apiserver airflow_scheduler airflow_dag_processor
	@echo ""
	@echo "Airflow em http://localhost:$$(grep ^AIRFLOW_PORT .env | cut -d= -f2) — usuário admin. A senha é gerada pelo Airflow quando o api-server"
	@echo "termina de subir, uns 20 s depois daqui, e se lê com:"
	@echo "  docker exec $$($(CONTEINERES) resolver airflow_apiserver | head -1) cat /opt/airflow/simple_auth_manager_passwords.json.generated"

airflow-down: require-env ## Derruba o Airflow; FORCE=1 apaga também o histórico de execuções
	@$(COMPOSE_AIRFLOW) down $(if $(filter 1,$(FORCE)),-v)

dag-run: require-env ## Dispara a DAG do caminho frio e imprime o run_id
	@# O run_id é capturado e gravado em data/medicoes/ultimo_run_id: sem ele
	@# não há como esperar *aquela* execução, e "a última" muda de identidade
	@# se alguém dispara outra. A espera do processador de DAGs e o unpause
	@# ficam no script, que é o dono do assunto.
	@run=$$($(AIRFLOW_CLI) disparar $(DAG)) || exit 1; \
		echo "DAG '$(DAG)' disparada: $$run"; \
		echo "Acompanhe em http://localhost:$$(grep ^AIRFLOW_PORT .env | cut -d= -f2)"; \
		echo "ou por: make dag-status; espere o fim com: make dag-wait"

dag-wait: require-env ## Espera a execução terminar; RUN_ID= (padrão: a última disparada), PRAZO=
	@$(AIRFLOW_CLI) aguardar $(DAG) "$(RUN_ID)" $(or $(PRAZO),1800)

dag-status: require-env ## Mostra o estado das tarefas da última execução da DAG
	@$(COMPOSE_AIRFLOW) exec -T airflow_scheduler \
		airflow tasks states-for-dag-run fluxo_batch \
		"$$($(COMPOSE_AIRFLOW) exec -T airflow_scheduler airflow dags list-runs fluxo_batch -o plain 2>/dev/null | grep -oE 'manual__[0-9T:.+-]+' | head -1)" \
		-o plain 2>/dev/null | grep -viE 'alembic|plugin'

# ── Caminho quente (Etapa 7) ────────────────────────────────────────────────
stream-up: require-env ## Sobe Redpanda e Kafka Connect e aplica o conector Debezium
	$(call preflight,streaming)
	@$(GARANTIR_REDE)
	@$(COMPOSE_STREAM) up -d --wait redpanda kafka_connect
	@$(MAKE) --no-print-directory stream-connector
	@echo ""
	@echo "Transporte em localhost:$${REDPANDA_PORT:-19092}; Connect em http://localhost:$${KAFKA_CONNECT_PORT:-8083}."
	@echo "O pipeline é processo em primeiro plano: 'make stream-run'."

stream-connector: require-env ## Aplica as declarações de streaming/connectors/ pela API REST
	@$(STREAM) connector

stream-status: require-env ## Estado do conector Debezium e das tarefas
	@$(STREAM) status

stream-run: require-env ## Sobe o pipeline Beam (primeiro plano; Ctrl-C encerra)
	@# Primeiro plano de propósito: job de streaming que sobe em segundo plano
	@# e morre em silêncio é o pior modo de falha possível — o tópico enche, o
	@# saldo congela e nada avisa.
	@$(STREAM) pipeline

stream-produce: require-env ## Emite eventos novos no livro da origem; LIMITE=, SEED=
	@$(STREAM) produzir $(if $(LIMITE),--limite $(LIMITE)) $(if $(SEED),--semente $(SEED))

stream-duplicate: require-env ## Republica mensagens no transporte — teste de idempotência; QUANTAS=
	@$(STREAM) duplicar $(if $(QUANTAS),--quantas $(QUANTAS))

stream-corte: require-env ## Imprime o max(event_sequence) da origem — o fim de uma medição
	@$(STREAM) corte

stream-wait: require-env ## Espera o livro quente alcançar ATE_SEQ=; PID= vigia o pipeline, PRAZO=
	@test -n "$(ATE_SEQ)" || { echo "ERRO: ATE_SEQ= é obrigatório — espera sem corte mediria para sempre."; exit 2; }
	@$(STREAM) aguardar --ate-seq $(ATE_SEQ) $(if $(PID),--pid $(PID)) $(if $(PRAZO),--prazo $(PRAZO))

stream-alerts: require-env ## Lê e resume o tópico de alerta de estoque baixo
	@$(STREAM) alertas $(if $(MOSTRAR),--mostrar $(MOSTRAR)) $(if $(GRUPO),--grupo $(GRUPO))

stream-down: require-env $(if $(filter 1,$(FORCE)),require-venv) ## Derruba Connect e mensageria; FORCE=1 apaga também os tópicos
	@$(COMPOSE_STREAM) down $(if $(filter 1,$(FORCE)),-v)
	@# O slot de replicação fica no `source_db` e sobrevive à queda do Connect:
	@# sem removê-lo, o PostgreSQL segura WAL para um consumidor que não existe
	@# mais, até o disco acabar. É a pegadinha clássica de CDC.
	@$(if $(filter 1,$(FORCE)),set -a; . ./.env; set +a; \
		.venv/bin/python -m mvp_ed1.streaming.maintenance drop-slots --force)

stream-reset-sink: require-env require-venv ## Esvazia SÓ o destino do streaming; exige FORCE=1 e consumidores parados
	@set -a; . ./.env; set +a; \
		.venv/bin/python -m mvp_ed1.streaming.maintenance reset-sink $(if $(filter 1,$(FORCE)),--force)

# ── Ponto único de recuperação (Etapa 12, B4) ───────────────────────────────
recovery-pack: require-env require-venv ## Monta o candidato a pacote; exige janela parada e árvore limpa
	@echo "[recovery] RECOVERY_DIR = $(RECOVERY_DIR)"
	@# Janela parada: a mesma pergunta do preflight, e pelas mesmas razões. Um
	@# dump tirado no meio de uma sincronização descreve um estado que nunca
	@# existiu inteiro.
	@docker/preflight.sh trabalho || { \
		echo "RECUSADO — o corte precisa de janela parada: um dump tirado no meio de uma"; \
		echo "  sincronização descreve um estado que nunca existiu inteiro."; \
		exit 1; }
	@$(RECOVERY) --dir "$(RECOVERY_DIR)" pack

recovery-verify: require-env require-venv ## Confere o pacote sem restaurar nada; DIR=, CONTRA_O_BANCO=1
	@echo "[recovery] RECOVERY_DIR = $(or $(DIR),$(RECOVERY_DIR))"
	@$(RECOVERY) --dir "$(or $(DIR),$(RECOVERY_DIR))" verify $(if $(filter 1,$(CONTRA_O_BANCO)),--contra-o-banco)

recovery-rebase: require-env require-venv ## Re-basa as gerações retidas do bruto (passo 4b); DRY_RUN=1 só mostra
	@$(RECOVERY) rebase $(if $(filter 1,$(DRY_RUN)),--dry-run)

recovery-airbyte-jobs: require-env require-venv ## Num Airbyte novo, avança o contador de jobs para além da captura retida (D50)
	@# Só a sequência interna é tocada — nenhum job nasce. A listagem da API,
	@# que a guarda lê, só muda quando o job seguinte existir: por isso, na
	@# sequência de restauração, `sync-airbyte` vem antes de `sync-legacy`.
	@$(RECOVERY) avancar-jobs

recovery-promote: require-env require-venv ## candidato/ -> aprovado/, depois de verify e de uma restauração validada
	@echo "[recovery] RECOVERY_DIR = $(RECOVERY_DIR)"
	@$(RECOVERY) --dir "$(RECOVERY_DIR)" promote

recovery-restore: require-env require-venv ## A sequência de restauração, passo a passo; exige RESTAURAR=1
	@# A autorização é RESTAURAR=1, **não** FORCE — e é consumida aqui, na
	@# entrada (RV12-06). Os submakes de descarte recebem FORCE=1 um a um; os
	@# de subida recebem FORCE= vazio, com o preflight obrigatório. FORCE não
	@# atravessa o restore: herdá-lo faria a subida do streaming e do Airbyte
	@# ignorar o R11 justamente quando a máquina está mais carregada.
	@test "$(RESTAURAR)" = "1" || { \
		echo "RECUSADO — 'recovery-restore' destrói o estado atual dos três bancos."; \
		echo "  Confira o pacote primeiro (make recovery-verify) e autorize com RESTAURAR=1."; \
		exit 1; }
	@echo "[recovery] RECOVERY_DIR = $(RECOVERY_DIR)"
	@echo "── 1/9 conferindo o pacote ──"
	@$(MAKE) --no-print-directory recovery-verify DIR="$(RECOVERY_DIR)"
	@echo "── 2/9 manutenção: janela parada, DAG pausada ──"
	@docker/preflight.sh trabalho || { echo "RECUSADO — há trabalho em andamento."; exit 1; }
	@# Airflow ausente (3) é seguro: nada pode disparar a DAG. Pausa que falhou ou
	@# não se sabe (1) não é — um scheduler de pé dispararia a DAG no meio da
	@# troca dos bancos, e `|| true` era exatamente isso (RVE-17).
	@$(AIRFLOW_CLI) pausar $(DAG); s=$$?; [ $$s -eq 0 ] || [ $$s -eq 3 ] || { \
		echo "RECUSADO — há Airflow de pé e a DAG '$(DAG)' não foi pausada: uma execução"; \
		echo "  poderia começar no meio da troca dos bancos. Pause você mesmo (make airflow-pause"; \
		echo "  ou 'docker/airflow_cli.sh pausar $(DAG)') e rode de novo."; exit 1; }
	@echo "── 3/9 descartando o CDC enquanto a origem antiga ainda existe ──"
	@$(MAKE) --no-print-directory stream-down FORCE=1
	@$(MAKE) --no-print-directory stream-reset-sink FORCE=1
	@echo "── 4/9 pg_restore das duas fontes e da memória do armazém ──"
	@$(RECOVERY) --dir "$(RECOVERY_DIR)" restore-dumps
	@echo "── 4b/9 re-base das gerações retidas (D52) ──"
	@$(MAKE) --no-print-directory recovery-rebase
	@echo "── 5/9 conferindo o conteúdo restaurado contra o manifesto ──"
	@$(MAKE) --no-print-directory recovery-verify DIR="$(RECOVERY_DIR)" CONTRA_O_BANCO=1
	@echo "── 6/9 devolvendo os artefatos de trabalho ──"
	@$(RECOVERY) --dir "$(RECOVERY_DIR)" restore-artefatos
	@echo "── 7/9 novo snapshot do caminho quente ──"
	@$(MAKE) --no-print-directory medir CENARIO=streaming FORCE=
	@echo "── 8/9 reconstruindo sem apagar o que acabou de voltar ──"
	@$(MAKE) --no-print-directory airbyte-up FORCE=
	@# D50: num Airbyte novo o contador de jobs recomeça em 1, abaixo das
	@# capturas retidas; avança antes de qualquer sincronização. Com o mesmo
	@# Airbyte de sempre, o alvo lê, constata e não escreve nada (RVE-06).
	@$(MAKE) --no-print-directory recovery-airbyte-jobs
	@$(MAKE) --no-print-directory sync-airbyte RESET=1
	@# H8 (ADR-0050): a restauração substitui a memória por desenho, e o livro
	@# do estado substituído pararia a captura dela. Abre a sua época, com a
	@# linha de base do estado restaurado e já conferido no passo 5, antes da
	@# primeira captura — com o Airbyte de pé, que lista os jobs. Uma restauração
	@# repetida abre outra; as anteriores ficam como estavam.
	@$(GARANTIR_LIVRO_NO_ENV)
	@$(LIVRO_LINHA_DE_BASE)
	@# O job é o desta execução, nunca o de uma anterior que tenha sobrado.
	@rm -f "$(RECOVERY_JOB)"
	@$(MAKE) --no-print-directory sync-legacy JOB_EM="$(RECOVERY_JOB)"
	@$(MAKE) --no-print-directory dbt-rebuild
	@$(MAKE) --no-print-directory check
	@echo "── 9/9 oráculos explícitos ──"
	@job=$$(cat "$(RECOVERY_JOB)" 2>/dev/null); [ -n "$$job" ] || { \
		echo "RECUSADO — o passo 8 não deixou o jobId da captura em $(RECOVERY_JOB);"; \
		echo "  sem ele o passo 9 conferiria a captura que o banco disser, não a disparada."; exit 1; }; \
		$(RECOVERY) --dir "$(RECOVERY_DIR)" conferir-restauracao --job "$$job"
	@echo "recovery-restore: a sequência inteira passou. 'make recovery-promote' aprova o pacote."

dbt-rebuild: require-env require-venv ## Reconstrói TUDO sem derrubar os snapshots — o alvo de uma restauração
	@# A diferença para `dbt-build RESET=1` é uma linha e é o bloco inteiro:
	@# aquele chama `dbt-drop-snapshots` antes do `--full-refresh`. Derrubar o
	@# schema `snapshots` é certo depois de **regerar a origem** — as chaves
	@# substitutas mudam todas e a fato incremental precisa acompanhar — e
	@# **errado depois de um restore**, porque o histórico SCD que acabou de
	@# voltar do pacote não se reconstrói de lugar nenhum.
	@#
	@# O `--full-refresh` sozinho refaz a fato incremental sobre as chaves
	@# substitutas restauradas, e o `dbt snapshot` só acrescenta versão se
	@# `trusted` mudou — o que não muda. A quarentena restaurada sobrevive:
	@# `rejected_legacy_records` lê a própria tabela anterior por
	@# `adapter.get_relation` e retém tudo que não seja da captura corrente sob
	@# a impressão vigente. É o mecanismo que acumulou as 63.802 linhas.
	@$(GARANTIR_LEITOR_NO_ENV)
	@set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.governance garantir
	@$(DBT) build --full-refresh $(DBT_ARGS)

dbt-drop-snapshots: require-env require-venv ## DESTRÓI o histórico SCD; use depois de regerar a origem
	@echo "descartando o schema 'snapshots' — o histórico SCD será refeito do zero"
	@set -a; . ./.env; set +a; \
		PGPASSWORD="$$WAREHOUSE_DB_PASSWORD" .venv/bin/python -c "\
import os, sqlalchemy as sa; \
from mvp_ed1.db import database_url, WAREHOUSE; \
e = sa.create_engine(database_url(WAREHOUSE)); \
c = e.connect(); c.execute(sa.text('drop schema if exists snapshots cascade')); c.commit(); \
print('  schema snapshots descartado')"

dbt-test: require-env require-venv ## Somente os testes de dados
	@$(DBT) test $(DBT_ARGS)

docs-check: require-venv ## Confere links, âncoras e citações de ADR nos documentos rastreados
	@.venv/bin/python -m mvp_ed1.docs_check

secrets-history: require-venv ## Varre TODO o histórico por forma de credencial, sem depender do .env
	@.venv/bin/python -m mvp_ed1.secrets_review --historico

docs-generate: require-env require-venv ## Só gera o catálogo — tem fim, e por isso é o que se mede
	@$(DBT) docs generate

dbt-docs: require-env require-venv docs-generate ## Gera e serve o catálogo com dicionário, linhagem e glossário
	@# O gerar é o `docs-generate`; aqui só se serve. `$(DBT)` entra em `dbt/`, e
	@# usá-lo duas vezes na mesma linha fazia a segunda procurar `./.env` e `dbt/`
	@# de dentro de `dbt/` — o catálogo saía, e o servidor não subia (B5, 25/09/2026).
	@$(DBT) docs serve

test: require-venv ## Testes de código Python (pytest); CARGA=1 roda a carga em banco efêmero; FATO=1 inclui o teste que escreve na fato
	@# Dois interruptores, de propósito. `CARGA=1` substitui a origem pela carga
	@# reduzida e por isso só roda em banco efêmero (alvo `test-carga`); `FATO=1`
	@# escreve no armazém de trabalho por desenho (repara e confere) e é
	@# autorização à parte. Uma flag só para os dois foi o que pôs a origem de
	@# trabalho em fator 0,05 duas vezes.
	@# `-rs` lista cada pulado com o motivo, e é por este alvo que o `check` os
	@# lista: pulado não é verificado, e o Termo pede a lista (plano, §7.6).
	@set -a; [ -f .env ] && . ./.env; set +a; \
		MVP_TESTE_FATO=$(if $(filter 1,$(FATO)),1,0) .venv/bin/pytest -q -rs
	@$(if $(filter 1,$(CARGA)),$(MAKE) --no-print-directory test-carga,true)

check: require-env require-venv ## Verificação completa, parando na primeira falha: segredos, dbt build + testes de dados, classificação e linhagem derivadas, pytest; FATO=1 inclui o teste que escreve na fato
	@# Quatro etapas, nesta ordem e sem seguir depois de uma falha. Segredos
	@# primeiro porque custa um segundo e é a regra inviolável nº 1; o dbt antes
	@# do pytest porque a suíte Python lê o armazém que o build acabou de
	@# construir (captura selecionada, intervalo, memória); a classificação e a
	@# linhagem derivadas depois do build porque leem o manifest dele. `RESET=1` e `FATO=1`
	@# passam adiante com o mesmo significado que têm nos alvos de origem.
	@# A varredura do HISTÓRICO (`make secrets-history`) fica fora: o histórico
	@# só cresce, e conferi-lo a cada `check` cobraria 25 s por nada. Ela entra
	@# na definição de pronto e no dossiê.
	@echo "── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──"
	@.venv/bin/python -m mvp_ed1.secrets_review
	@.venv/bin/python -m mvp_ed1.docs_check
	@echo "── 2/4 dbt build: modelos, testes de dados e reconciliações ──"
	@$(MAKE) --no-print-directory dbt-build RESET=$(RESET)
	@echo "── 3/4 classificação, descrição e linhagem derivadas em dia com os modelos ──"
	@.venv/bin/python -m mvp_ed1.models.sensitivity --check
	@.venv/bin/python -m mvp_ed1.models.lineage --check
	@echo "── 4/4 pytest: código, contratos e integração ──"
	@$(MAKE) --no-print-directory test FATO=$(FATO)
	@echo "check: as quatro etapas passaram"

check-offline: require-env require-venv ## O que se confere sem nada de pé: segredos, documentos e a suíte sem os testes de integração
	@# O primeiro comando do clone de B5, antes de subir qualquer contêiner
	@# (RV12-2-04): mede o que não depende de banco, `dbt` nem serviço, e por
	@# isso roda num checkout novo, sem `dbt/target` nem dados gerados. O
	@# `check` completo continua o mesmo e roda depois das ingestões. Quem
	@# precisa de banco ou do `dbt` leva a marca `integracao` — achados por uma
	@# sonda que nega e anota cada acesso, com as variáveis de conexão
	@# presentes, porque sem elas os guardas de `skip` escondem o acesso. O que
	@# fica de fora é listado: os pulados, com o motivo; os de integração, por
	@# arquivo.
	@echo "── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──"
	@.venv/bin/python -m mvp_ed1.secrets_review
	@.venv/bin/python -m mvp_ed1.docs_check
	@echo "── 2/3 pytest sem os testes de integração ──"
	@set -a; . ./.env; set +a; MVP_TESTE_FATO=0 .venv/bin/pytest -q -rs -m "not integracao"
	@echo "── 3/3 o que ficou de fora: os de integração, que rodam no make check ──"
	@# `pipefail`: sem ele o código do encadeamento é o do `uniq`, e uma coleta
	@# que falhava terminava em "as três etapas passaram" sem o inventário (RVB5-03).
	@set -o pipefail; .venv/bin/pytest -q --co -m integracao | sed -n 's/::.*//p' | sort | uniq -c || { \
		echo "ERRO: a coleta dos testes de integração falhou — sem o inventário do que ficou de fora,"; \
		echo "  o check-offline não passa."; exit 1; }
	@echo "check-offline: as três etapas passaram"

test-carga: require-env require-venv ## Teste de carga da origem num banco efêmero, criado e derrubado aqui
	@# O banco nasce ao lado do `source_db`, com sufixo `_carga`, recebe as
	@# migrações e morre no fim — inclusive quando o teste falha (`trap`). O
	@# teste recusa rodar se o banco a que se conectou não for o que este alvo
	@# declarou em MVP_TESTE_CARGA_DB.
	@# O contêiner da origem é resolvido pelos rótulos do Compose: com o nome
	@# literal, num clone com outro COMPOSE_PROJECT_NAME o banco efêmero nasceria
	@# no contêiner do projeto ANTIGO enquanto o Alembic migra o do clone.
	@set -a; . ./.env; set +a; \
		fonte=$$($(CONTEINERES) resolver source_db | head -1); \
		[ -n "$$fonte" ] || { echo "ERRO: não resolvi o contêiner 'source_db' deste projeto. Rode 'make up'."; exit 1; }; \
		efemero="$${SOURCE_DB_NAME}_carga_$$$$"; \
		psql_src() { docker exec -e PGPASSWORD="$$SOURCE_DB_PASSWORD" "$$fonte" \
			psql -v ON_ERROR_STOP=1 -q -U "$$SOURCE_DB_USER" -d postgres "$$@"; }; \
		trap 'psql_src -c "drop database if exists \"$$efemero\"" && echo "banco efêmero $$efemero removido"' EXIT; \
		psql_src -c "create database \"$$efemero\"" && echo "banco efêmero $$efemero criado"; \
		SOURCE_DB_NAME="$$efemero" .venv/bin/alembic upgrade head; \
		SOURCE_DB_NAME="$$efemero" MVP_TESTE_CARGA=1 MVP_TESTE_CARGA_DB="$$efemero" \
			.venv/bin/pytest -q tests/test_carga.py

migrate-legacy: require-env require-venv ## Aplica as migrações do schema legado (legacy_db) até a última
	@$(ALEMBIC_LEGACY) upgrade head

migrate-legacy-down: require-env require-venv ## Desfaz migrações do legado; TO=base derruba tudo, padrão -1
	@$(ALEMBIC_LEGACY) downgrade $(or $(TO),-1)

migrate-legacy-status: require-env require-venv ## Revisão aplicada no legacy_db e diferença contra a declaração
	@$(ALEMBIC_LEGACY) current --verbose && $(ALEMBIC_LEGACY) check

migrate-legacy-new: require-env require-venv ## Gera rascunho de migração do legado; exige M="mensagem"
	@test -n '$(M)' || { echo 'ERRO: use make migrate-legacy-new M="o que mudou"'; exit 1; }
	@$(ALEMBIC_LEGACY) revision --autogenerate -m '$(M)'

migrate-status: require-env require-venv ## Mostra a revisão aplicada no banco
	@$(ALEMBIC) current --verbose

ps: require-env ## Mostra o estado dos contêineres
	@$(COMPOSE) ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'

logs: require-env ## Acompanha os logs (SERVICE=source_db para filtrar)
	$(COMPOSE) logs -f --tail=50 $(SERVICE)

psql-source: require-env ## Abre o psql na origem transacional
	@$(COMPOSE) exec source_db psql -U "$$(grep ^SOURCE_DB_USER .env | cut -d= -f2)" -d "$$(grep ^SOURCE_DB_NAME .env | cut -d= -f2)"

psql-legacy: require-env ## Abre o psql na origem legada
	@$(COMPOSE) exec legacy_db psql -U "$$(grep ^LEGACY_DB_USER .env | cut -d= -f2)" -d "$$(grep ^LEGACY_DB_NAME .env | cut -d= -f2)"

psql-warehouse: require-env ## Abre o psql no armazém
	@$(COMPOSE) exec warehouse_db psql -U "$$(grep ^WAREHOUSE_DB_USER .env | cut -d= -f2)" -d "$$(grep ^WAREHOUSE_DB_NAME .env | cut -d= -f2)"

# O pgcli é o cliente interativo do Owner para explorar com autocompletar de
# colunas; vive fora do projeto (`uv tool`) e conecta pela porta publicada no
# host. A sessão nasce somente leitura, cai sozinha se ficar parada dentro de
# uma transação — o bloqueio de leitura seguraria o `dbt run` e as migrações —
# e pede confirmação antes de qualquer comando destrutivo. O nome de aplicação
# `pgcli` a identifica em `pg_stat_activity`.
define pgcli
@command -v pgcli >/dev/null || { \
	echo "ERRO: pgcli ausente. Instale com: uv tool install --with 'psycopg[binary]' pgcli"; \
	exit 1; \
}
@set -a; . ./.env; set +a; \
	PGPASSWORD="$${$(1)_DB_PASSWORD}" \
	PGOPTIONS="-c default_transaction_read_only=on -c idle_in_transaction_session_timeout=5min" \
	exec pgcli --warn all --application-name pgcli --auto-vertical-output \
		-h localhost -p "$${$(1)_DB_PORT}" -U "$${$(1)_DB_USER}" -d "$${$(1)_DB_NAME}"
endef

pgcli-source: require-env ## Abre o pgcli, somente leitura, na origem transacional
	$(call pgcli,SOURCE)

pgcli-legacy: require-env ## Abre o pgcli, somente leitura, na origem legada
	$(call pgcli,LEGACY)

pgcli-warehouse: require-env ## Abre o pgcli, somente leitura, no armazém
	$(call pgcli,WAREHOUSE)

# ── Fase GCP (Etapa 13) ───────────────────────────────────────────────────────
# Todo alvo `gcp-*` passa pelo `gcp-preflight`: o projeto do `.env` (GCP_PROJECT_ID),
# o do `terraform.tfvars` e o *quota project* das credenciais (ADC) têm de ser o mesmo,
# ou nada roda — um `plan` ou um `dbt build` contra o projeto errado é o erro que não
# se desfaz. `apply` só de plano salvo e aprovado pelo Owner (rito §6.3 do PLANO_etapa_13):
# não há alvo que planeje e aplique de uma vez.
GCP_TF := .tools/terraform -chdir=terraform
GCP_PLANOS := data/medicoes/etapa_13/planos
# A porta local do proxy do Cloud SQL: fora das portas dos bancos locais do `.env`.
GCP_SQL_PORTA ?= 15432
# O `.env` e o projeto do `gcloud`. O `core/project` da configuração do `gcloud` desta máquina é
# outro projeto (medido em 08/11/2026, Registro §30): comando sem `--project` iria para ele, e a
# cota de API faturada nele também. Todo alvo `gcp-*` carrega o `.env` por aqui.
GCP_ENV = set -a; . ./.env; set +a; export CLOUDSDK_CORE_PROJECT="$$GCP_PROJECT_ID"

gcp-preflight: require-env require-venv require-terraform ## Recusa se .env, terraform.tfvars e ADC não apontam o mesmo projeto GCP
	@$(GCP_ENV); \
	test -n "$$GCP_PROJECT_ID" || { echo "ERRO: GCP_PROJECT_ID ausente no .env."; exit 1; }; \
	test -f terraform/terraform.tfvars || { echo "ERRO: terraform/terraform.tfvars ausente (copie o .example)."; exit 1; }; \
	tf=$$(sed -n 's/^project_id *= *"\(.*\)"/\1/p' terraform/terraform.tfvars); \
	test "$$tf" = "$$GCP_PROJECT_ID" || { echo "ERRO: terraform.tfvars aponta '$$tf', o .env '$$GCP_PROJECT_ID'."; exit 1; }; \
	adc=$$(.venv/bin/python -c 'import json,pathlib; print(json.loads((pathlib.Path.home()/".config/gcloud/application_default_credentials.json").read_text()).get("quota_project_id",""))' 2>/dev/null); \
	test "$$adc" = "$$GCP_PROJECT_ID" || { echo "ERRO: o quota project das credenciais (ADC) é '$$adc', não '$$GCP_PROJECT_ID'."; exit 1; }; \
	echo "gcp-preflight: projeto $$GCP_PROJECT_ID nos três lugares"

gcp-plan: gcp-preflight ## Salva um plano para o Owner aprovar: NOME=06_cloud_sql VARS="enable_cloud_sql=true", ou o do desmonte: PASSO=2 (§6.5)
	@# VARS liga um degrau só neste plano, sem mexer no terraform.tfvars: o plano salvo leva os
	@# valores dentro, e o `gcp-apply` dele aplica exatamente o que foi lido e aprovado. Como o
	@# terraform.tfvars só liga o degrau barato, o VARS de cada plano da janela leva **todos** os
	@# degraus de pé, não só o novo: o esquecido seria destruído. A guarda do `mvp_ed1.gcp.desmonte`
	@# recusa plano de construção que destrói (DESTROI=n, o número lido no plano, é a exceção do
	@# Owner) e plano de desmonte que cria; o plano recusado vira `.tfplan.recusado` e não se aplica.
	@# PASSO=n tira nome e VARS da declaração do desmonte, a janela inteira menos o já desmontado.
	@$(GCP_ENV); \
	if test -n "$(PASSO)"; then \
		test -z "$(NOME)$(VARS)$(DESTROI)" || { echo "ERRO: PASSO= já diz o nome e o VARS do plano; não passe NOME, VARS nem DESTROI."; exit 1; }; \
		atribuicoes=$$(.venv/bin/python -m mvp_ed1.gcp.desmonte plano --passo "$(PASSO)") || exit 1; \
		eval "$$atribuicoes"; \
	else \
		nome="$(NOME)"; vars="$(VARS)"; modo=construcao; destruir=; \
		test -n "$$nome" || { echo "ERRO: NOME=<nn_assunto> obrigatório (ou PASSO=n no desmonte)."; exit 1; }; \
	fi; \
	args=; for v in $$vars; do args="$$args -var $$v"; done; \
	echo "gcp-plan: $$nome ($$modo) $$destruir $$vars"; \
	$(GCP_TF) plan -no-color $$destruir $$args -out="../$(GCP_PLANOS)/$$nome.tfplan" > "$(GCP_PLANOS)/$$nome.txt" 2>&1; \
	rc=$$?; grep -E "Plan:|No changes" "$(GCP_PLANOS)/$$nome.txt"; test $$rc = 0 || exit $$rc; \
	$(GCP_TF) show -json "../$(GCP_PLANOS)/$$nome.tfplan" \
		| .venv/bin/python -m mvp_ed1.gcp.desmonte conferir-plano --modo "$$modo" $(if $(DESTROI),--destroi $(DESTROI)) \
		|| { mv "$(GCP_PLANOS)/$$nome.tfplan" "$(GCP_PLANOS)/$$nome.tfplan.recusado"; exit 1; }

gcp-apply: gcp-preflight ## Aplica um plano JÁ APROVADO pelo Owner: NOME=06_cloud_sql (ou PASSO=n no desmonte); guarda o estado antes
	@$(GCP_ENV); \
	nome="$(NOME)"; \
	if test -n "$(PASSO)"; then \
		atribuicoes=$$(.venv/bin/python -m mvp_ed1.gcp.desmonte plano --passo "$(PASSO)") || exit 1; \
		eval "$$atribuicoes"; \
	fi; \
	test -n "$$nome" && test -f "$(GCP_PLANOS)/$$nome.tfplan" || { echo "ERRO: plano '$$nome' não existe; rode gcp-plan."; exit 1; }; \
	cp terraform/terraform.tfstate "$(GCP_PLANOS)/tfstate_$$nome.bak"; \
	$(GCP_TF) apply -no-color "../$(GCP_PLANOS)/$$nome.tfplan" > "$(GCP_PLANOS)/$${nome}_apply.txt" 2>&1; \
	rc=$$?; tail -3 "$(GCP_PLANOS)/$${nome}_apply.txt"; exit $$rc

gcp-sql-proxy: gcp-preflight require-cloud-sql-proxy ## Abre o Cloud SQL em 127.0.0.1:15432 (GCP_SQL_PORTA=) pelo Auth Proxy; primeiro plano, Ctrl-C fecha
	@# Sem rede autorizada no Cloud SQL: só o proxy entra, com a ADC do Owner (cloudsql.client).
	@conexao=$$($(GCP_TF) output -raw cloud_sql_conexao) || { echo "ERRO: sem Cloud SQL no estado (degrau 06)."; exit 1; }; \
		.tools/cloud-sql-proxy --address 127.0.0.1 --port $(GCP_SQL_PORTA) "$$conexao"

# As duas origens no Cloud SQL para os comandos locais: o proxy em segundo plano (fecha no fim da
# receita), as senhas do Secret Manager e `SOURCE_DB_*`/`LEGACY_DB_*` apontando para ele, **por cima**
# do `.env`, que segue apontando para os bancos locais. Usuário e banco são os do `.env`, os mesmos
# do `cloud_sql_origens` (cloud_sql.tf). Os alvos chamam o `alembic` e as CLIs direto, sem as
# macros locais (`ALEMBIC`, `GERADOR`): elas recarregam o `.env` e desfariam o que está aqui.
# Os registros da carga (o `geracao.json` e o manifesto do legado) vão para `GCP_REGISTROS`
# (`mvp_ed1.registros`): da raiz, a carga do Cloud SQL encerraria o diário de mutações aberto do
# manifesto local, que descreve o `legacy_db` local.
GCP_REGISTROS := $(abspath data/medicoes/etapa_13/origens_cloud_sql)
# Uma limpeza só por receita: a pasta temporária `base` e os processos de segundo plano que os
# macros abrem (o proxy, o `port-forward`), cada um somado a `pids`. Um `trap` por macro
# substituiria o do anterior, e um deles ficaria aberto.
GCP_LIMPEZA = base=$$(mktemp -d) && pids= && trap 'kill $$pids 2>/dev/null; rm -rf "$$base"' EXIT
GCP_ORIGENS = conexao=$$($(GCP_TF) output -raw cloud_sql_conexao 2>/dev/null) \
		|| { echo "ERRO: sem Cloud SQL no estado (degrau 06)."; exit 1; }; \
	.tools/cloud-sql-proxy --address 127.0.0.1 --port $(GCP_SQL_PORTA) "$$conexao" > /dev/null 2>&1 & proxy=$$!; \
	pids="$$pids $$proxy"; \
	for _ in $$(seq 30); do (exec 3<>/dev/tcp/127.0.0.1/$(GCP_SQL_PORTA)) 2>/dev/null && break; kill -0 $$proxy 2>/dev/null || break; sleep 1; done; \
	(exec 3<>/dev/tcp/127.0.0.1/$(GCP_SQL_PORTA)) 2>/dev/null || { echo "ERRO: o proxy do Cloud SQL não abriu."; exit 1; }; \
	for origem in source legacy; do \
		senha=$$(gcloud secrets versions access latest --secret "mvp-ed1-$$origem-db-password" --project "$$GCP_PROJECT_ID") || exit 1; \
		prefixo=$$(echo "$$origem" | tr a-z A-Z)_DB; \
		export "$${prefixo}_HOST=127.0.0.1" "$${prefixo}_PORT=$(GCP_SQL_PORTA)" "$${prefixo}_PASSWORD=$$senha"; \
	done; \
	export MVP_REGISTROS_DIR="$(GCP_REGISTROS)"; \
	echo "origens: Cloud SQL $$conexao pelo proxy em 127.0.0.1:$(GCP_SQL_PORTA); registros em $(GCP_REGISTROS)"

gcp-origens-migrar: gcp-preflight require-cloud-sql-proxy ## Segunda: aplica as migrações das duas origens no Cloud SQL (source_db e legacy_db), do zero
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GCP_ORIGENS); \
	.venv/bin/alembic upgrade head && .venv/bin/alembic -n legacy upgrade head \
	&& .venv/bin/alembic current && .venv/bin/alembic -n legacy current

gcp-origens-povoar: gcp-preflight require-cloud-sql-proxy ## Segunda: gera as duas origens no Cloud SQL com a semente, o fator e a data declarados (os da fase local)
	@# Sem SCALE, SEED nem AS_OF: a paridade da §7.2 pede a mesma geração da fase local, e o padrão
	@# é a declaração. O gerador recusa banco com dados; aqui não há FORCE.
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GCP_ORIGENS); \
	.venv/bin/python -m mvp_ed1.generator.cli seed && .venv/bin/python -m mvp_ed1.legacy.cli seed

gcp-origens-oraculo: gcp-preflight require-cloud-sql-proxy ## Segunda: o oráculo das origens contra o Cloud SQL, somente leitura; MEDIDA= de `make generation-measure`
	@test -n '$(MEDIDA)' || { echo 'ERRO: use make gcp-origens-oraculo MEDIDA=<medida da geração>'; exit 1; }
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GCP_ORIGENS); \
	RECOVERY_DIR="$(RECOVERY_DIR)" .venv/bin/python -m mvp_ed1.recovery.sources oracle '$(MEDIDA)'

gcp-origens-replicacao: gcp-preflight require-cloud-sql-proxy ## Segunda: concede REPLICATION ao usuário da origem no Cloud SQL (o do Debezium Server) e confere em pg_roles
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GCP_ORIGENS); .venv/bin/python -m mvp_ed1.gcp.origens replicacao

gcp-g21-prova: gcp-preflight require-cloud-sql-proxy ## Segunda: as provas do G2.1 contra o BigQuery real com os locks no Cloud SQL (o banco legado é o coordenador, A21)
	@# Os testes de `GCP_TESTES=1` criam e apagam um *dataset* temporário; o coordenador deles é o
	@# `WAREHOUSE_DB_*`, que aqui aponta para o legado no Cloud SQL, como no ambiente da nuvem.
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GCP_ORIGENS); mkdir -p data/medicoes/etapa_13/g2_1; \
	export WAREHOUSE_DB_HOST=127.0.0.1 WAREHOUSE_DB_PORT=$(GCP_SQL_PORTA) WAREHOUSE_DB_NAME="$$LEGACY_DB_NAME" \
		WAREHOUSE_DB_USER="$$LEGACY_DB_USER" WAREHOUSE_DB_PASSWORD="$$LEGACY_DB_PASSWORD"; \
	saida="data/medicoes/etapa_13/g2_1/cloud_sql_$$(date -u +%Y%m%dT%H%M%SZ).txt"; \
	GCP_TESTES=1 .venv/bin/python -m pytest -q -p no:cacheprovider tests/test_armazem_bigquery.py \
		tests/test_livro_gcs.py tests/test_governanca_bigquery.py 2>&1 | tee "$$saida"; \
	rc=$${PIPESTATUS[0]}; echo "gcp-g21-prova: $$saida"; exit $$rc

gcp-dbt-build: gcp-preflight ## dbt build no alvo gcp (BigQuery), com target e logs separados do local
	@# O mapa nível → policy tag do Terraform (G4, D71): o dbt marca as colunas das tabelas que
	@# materializa. Sem a taxonomia aplicada a saída não existe, e nada é marcado.
	@tags=$$($(GCP_TF) output -json policy_tags 2>/dev/null) || tags='{}'; \
		cd dbt && set -a && . ../.env && set +a && MVP_POLICY_TAGS="$$tags" \
		../.venv/bin/dbt build --target gcp --target-path target_gcp $(ARGS)

gcp-oraculos: gcp-preflight ## Paridade local × BigQuery: classificação do legado, contagens das camadas e catálogo
	@$(GCP_ENV); \
	.venv/bin/python -m mvp_ed1.gcp.oraculo trusted.legacy_classifications \
		--chave source_system,snapshot_id,source_table,legacy_row_id \
		--colunas classification,rejection_origin,catalog_version,treatment_fingerprint \
		--json findings:code,column && \
	.venv/bin/python -m mvp_ed1.gcp.oraculo contagens; \
	.venv/bin/python -m mvp_ed1.gcp.catalogo

# A imagem do Composer da D73, pelo *digest* — a de que o ambiente nasce na janela. A prova do G2.4
# roda nela, não numa parecida: a lista de pacotes é a da imagem, não a de uma reconstrução.
COMPOSER_IMAGEM := us-docker.pkg.dev/cloud-airflow-releaser/airflow-worker-scheduler-3-2-2/airflow-worker-scheduler-3-2-2:composer-3-airflow-3.2.2-build.9@sha256:96e0cc9471c8c30561ddf6f0c9d702c8fffeee3d182a4990874270501e182bfe
TAREFA ?= dbt_staging

gcp-composer-prova: gcp-preflight ## G2.4: a DAG importa e uma tarefa de dbt (TAREFA=dbt_staging) roda no layout do Composer, na imagem dele
	@# Um contêiner só, sem scheduler nem banco de metadados (R11: ~1 GB com o dbt). O layout
	@# nasce numa pasta nova e entra somente leitura: o que a tarefa escrever fora do temporário
	@# dela falha. Os pacotes do ambiente entram por cima da imagem, como o Composer faz, e o
	@# `pip check` confere que nada da imagem quebrou. A ADC do Owner faz o papel da conta do ambiente.
	@# Roda como o usuário `airflow` da imagem (uid 999), como no Composer: `/home/airflow` é 700
	@# dele. Por isso a ADC entra por uma cópia legível *dentro* da pasta temporária — que é 700 do
	@# Owner no host e some no fim —, no lugar em que o gcloud a deixa, e o relatório sai por uma
	@# pasta dela, copiado depois.
	@$(GCP_ENV); \
	base=$$(mktemp -d) && trap 'rm -rf "$$base"' EXIT; \
	.venv/bin/python -m mvp_ed1.gcp.composer montar "$$base/gcs" > /dev/null || exit 1; \
	tags=$$($(GCP_TF) output -json policy_tags 2>/dev/null) || tags='{}'; \
	install -m 644 "$$HOME/.config/gcloud/application_default_credentials.json" "$$base/adc.json"; \
	mkdir -m 777 "$$base/saida"; \
	docker run --rm --entrypoint bash \
		-v "$$base/gcs:/home/airflow/gcs:ro" \
		-v "$(abspath airflow/requirements-composer.txt):/requisitos.txt:ro" \
		-v "$$base/adc.json:/home/airflow/.config/gcloud/application_default_credentials.json:ro" \
		-v "$$base/saida:/saida" -e GCP_PROJECT_ID -e GCP_BQ_LOCATION \
		-e MVP_POLICY_TAGS="$$tags" -e MVP_PROJECT_DIR=/home/airflow/gcs/data \
		-e DBT_PROFILES_DIR=/home/airflow/gcs/data/dbt -e DBT_TARGET=gcp \
		-e PYTHONPATH=/home/airflow/gcs/dags -e AIRFLOW__CORE__DAGS_FOLDER=/home/airflow/gcs/dags \
		$(COMPOSER_IMAGEM) -c 'pip install -q --user --no-warn-script-location -r /requisitos.txt \
			&& pip check && python -m mvp_ed1.gcp.prova_composer --tarefa $(TAREFA) --saida /saida/prova_composer.json'; \
	rc=$$?; mkdir -p data/medicoes/etapa_13/g2_4; \
	cp "$$base/saida/prova_composer.json" \
		"data/medicoes/etapa_13/g2_4/prova_composer_$(TAREFA)_$$(date -u +%Y%m%dT%H%M%SZ).json" 2>/dev/null; \
	exit $$rc

# ── Composer na janela (quarta): segredos, layout e smoke test, nesta ordem ──────────────────────
# O nome do ambiente e o bucket vêm do `output composer`; vazio é "o degrau não está aplicado".
COMPOSER_SAIDA = $(GCP_TF) output -json composer | .venv/bin/python -c 'import json,sys; print((json.load(sys.stdin) or {}).get("$(1)", ""))'
# O `kubectl` contra o GKE, sem `kubeconfig`: o endereço e a CA da saída do Terraform, o *token* da
# ADC. Pede `base` (uma pasta temporária) já criada; define a função `k`.
GKE_KUBECTL = ep=$$($(GCP_TF) output -raw gke_endpoint 2>/dev/null); \
	test -n "$$ep" || { echo "ERRO: sem GKE no estado (degrau 08)."; exit 1; }; \
	$(GCP_TF) output -raw gke_ca | base64 -d > "$$base/ca.crt"; \
	token=$$(gcloud auth application-default print-access-token) || exit 1; \
	k() { .tools/kubectl --server="https://$$ep" --certificate-authority="$$base/ca.crt" --token="$$token" "$$@"; }
# A API do Airbyte do GKE nesta máquina: um `port-forward` para o Service do `airbyte-server` (o
# load balancer é interno e daqui não se alcança) e as credenciais do Secret `airbyte-auth-secrets`
# no ambiente, sem passar pela tela. Pede `GCP_LIMPEZA` e `GKE_KUBECTL` antes.
GCP_AIRBYTE_PORTA ?= 18001
GKE_AIRBYTE = remota=$$(k -n airbyte get service airbyte-airbyte-server-svc -o jsonpath='{.spec.ports[0].port}') || exit 1; \
	k -n airbyte port-forward service/airbyte-airbyte-server-svc "$(GCP_AIRBYTE_PORTA):$$remota" > "$$base/port-forward.log" 2>&1 & pids="$$pids $$!"; \
	for _ in $$(seq 30); do (exec 3<>/dev/tcp/127.0.0.1/$(GCP_AIRBYTE_PORTA)) 2>/dev/null && break; sleep 1; done; \
	(exec 3<>/dev/tcp/127.0.0.1/$(GCP_AIRBYTE_PORTA)) 2>/dev/null || { echo "ERRO: o port-forward do Airbyte não abriu:"; cat "$$base/port-forward.log"; exit 1; }; \
	AIRBYTE_CLIENT_ID=$$(k -n airbyte get secret airbyte-auth-secrets -o jsonpath='{.data.instance-admin-client-id}' | base64 -d) || exit 1; \
	AIRBYTE_CLIENT_SECRET=$$(k -n airbyte get secret airbyte-auth-secrets -o jsonpath='{.data.instance-admin-client-secret}' | base64 -d) || exit 1; \
	test -n "$$AIRBYTE_CLIENT_ID" && test -n "$$AIRBYTE_CLIENT_SECRET" || { echo "ERRO: credenciais do Airbyte vazias no cluster."; exit 1; }; \
	export AIRBYTE_URL="http://127.0.0.1:$(GCP_AIRBYTE_PORTA)/api/public/v1" AIRBYTE_CLIENT_ID AIRBYTE_CLIENT_SECRET; \
	echo "airbyte: API do GKE em $$AIRBYTE_URL (port-forward)"

gcp-composer-segredos: gcp-preflight require-kubectl ## Janela: grava no Secret Manager as credenciais do Airbyte do GKE e o endereço do load balancer interno, sem mostrá-los
	@# O bootloader do chart gera as credenciais no Secret `airbyte-auth-secrets`, e o IP do load
	@# balancer interno só existe depois do Service: nenhum dos dois o Terraform conhece no plano.
	@# Os valores passam por arquivos de uma pasta 700 que some no fim; nada vai para a tela.
	@$(GCP_ENV); \
	base=$$(mktemp -d) && trap 'rm -rf "$$base"' EXIT; \
	$(GKE_KUBECTL); \
	ip=$$(k -n airbyte get service airbyte-airbyte-server-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}') || exit 1; \
	porta=$$(k -n airbyte get service airbyte-airbyte-server-svc -o jsonpath='{.spec.ports[0].port}') || exit 1; \
	test -n "$$ip" || { echo "ERRO: o load balancer interno do Airbyte ainda não tem IP."; exit 1; }; \
	printf 'http://%s:%s/api/public/v1' "$$ip" "$$porta" > "$$base/airbyte-url"; \
	for chave in id secret; do \
		k -n airbyte get secret airbyte-auth-secrets -o jsonpath="{.data.instance-admin-client-$$chave}" \
			| base64 -d > "$$base/airbyte-client-$$chave" || exit 1; \
	done; \
	for nome in airbyte-client-id airbyte-client-secret airbyte-url; do \
		test -s "$$base/$$nome" || { echo "ERRO: $$nome vazio no cluster."; exit 1; }; \
		gcloud secrets versions add "mvp-ed1-$$nome" --project "$$GCP_PROJECT_ID" \
			--data-file="$$base/$$nome" > /dev/null || exit 1; \
		echo "gcp-composer-segredos: mvp-ed1-$$nome gravado"; \
	done

gcp-composer-publicar: gcp-preflight ## Janela: publica o layout do G2.4 (dags/ e data/) no bucket do Composer; o que sobrou de publicação anterior sai
	@# O mesmo `montar` da prova local, numa pasta nova; o `rsync` apaga do bucket o que o layout
	@# não tem — menos o `airflow_monitoring.py`, que o próprio Composer põe em dags/.
	@$(GCP_ENV); \
	bucket=$$($(call COMPOSER_SAIDA,bucket)); \
	test -n "$$bucket" || { echo "ERRO: sem Composer no estado (enable_composer)."; exit 1; }; \
	base=$$(mktemp -d) && trap 'rm -rf "$$base"' EXIT; \
	.venv/bin/python -m mvp_ed1.gcp.composer montar "$$base/gcs" > /dev/null || exit 1; \
	gcloud storage rsync --recursive --delete-unmatched-destination-objects \
		--exclude='^airflow_monitoring\.py$$' "$$base/gcs/dags" "gs://$$bucket/dags" || exit 1; \
	gcloud storage rsync --recursive --delete-unmatched-destination-objects \
		"$$base/gcs/data" "gs://$$bucket/data" || exit 1; \
	echo "gcp-composer-publicar: layout em gs://$$bucket (dags/ e data/)"

gcp-composer-smoke: gcp-preflight ## Janela: as DAGs importam e a diagnostico_composer roda inteira no Composer (nada escreve); falha dizendo onde
	@# Depois do `gcp-composer-segredos` e do `gcp-composer-publicar`, e antes da `fluxo_batch`.
	@# A CLI do Airflow pelo `gcloud` (grupo `dags`, aceito até o Airflow 3.3.0). A DAG nasce
	@# pausada: o `unpause` é dela só, e ela não tem agendamento.
	@$(GCP_ENV); \
	nome=$$($(call COMPOSER_SAIDA,nome)); \
	test -n "$$nome" || { echo "ERRO: sem Composer no estado (enable_composer)."; exit 1; }; \
	g() { gcloud composer environments run "$$nome" --location "$$GCP_BQ_LOCATION" --project "$$GCP_PROJECT_ID" "$$@"; }; \
	erros=$$(g dags list-import-errors -- -o json 2>/dev/null) || exit 1; \
	printf '%s' "$$erros" | .venv/bin/python -c 'import json,sys; t=sys.stdin.read().strip(); e=[] if not t or "No data found" in t else json.loads(t); print("importação:", "sem erro" if not e else e); sys.exit(1 if e else 0)' || exit 1; \
	g dags unpause -- diagnostico_composer -y > /dev/null || exit 1; \
	run="smoke_$$(date -u +%Y%m%dT%H%M%S)"; \
	g dags trigger -- diagnostico_composer --run-id "$$run" > /dev/null || exit 1; \
	for _ in $$(seq 60); do \
		sleep 15; \
		estado=$$(g dags list-runs -- diagnostico_composer -o json 2>/dev/null | RUN="$$run" .venv/bin/python -c 'import json,os,sys; r=[x for x in json.load(sys.stdin) if x.get("run_id")==os.environ["RUN"]]; print(r[0]["state"] if r else "")'); \
		case "$$estado" in \
			success) echo "gcp-composer-smoke: $$run terminou com sucesso"; exit 0 ;; \
			failed) echo "gcp-composer-smoke: $$run FALHOU — a tarefa que falhou diz o quê, no log dela"; exit 1 ;; \
		esac; \
	done; \
	echo "gcp-composer-smoke: $$run não terminou em 15 min (último estado: $$estado)"; exit 1

# ── Dataflow: o caminho quente gerenciado (ensaio na terça, D83; parte cara na quarta) ──────────
# A saída `dataflow` do Terraform diz conta, sub-rede, bucket e região; o pacote do worker é o
# `mvp_ed1` sem dependências (`streaming/dataflow/pyproject.toml`), montado a cada chamada.
DATAFLOW_JOB := mvp-ed1-caminho-quente
DATAFLOW_EVIDENCIA := data/medicoes/etapa_13/g23
DATAFLOW_PREPARAR = base=$$(mktemp -d) && trap 'rm -rf "$$base"' EXIT; \
	$(GCP_TF) output -json dataflow > "$$base/tf.json" 2>/dev/null \
		|| { echo "ERRO: sem a saída dataflow no estado (o próximo apply a grava)."; exit 1; }; \
	uv build -q --wheel streaming/dataflow --out-dir "$$base/pacote" > /dev/null || exit 1; \
	pacote=$$(ls "$$base"/pacote/*.whl)

gcp-dataflow-tabela: gcp-preflight ## Cria o destino do caminho quente no BigQuery com a ADC do Owner, se não existe (antes do apply com enable_dataflow)
	@$(GCP_ENV); .venv/bin/python -m mvp_ed1.streaming.dataflow tabela

gcp-dataflow-validar: gcp-preflight ## Monta o job do Dataflow inteiro sem enviar (dry run, custo zero) e confere conta, máquina, rede e IP
	@$(GCP_ENV); $(DATAFLOW_PREPARAR); \
	mkdir -p $(DATAFLOW_EVIDENCIA); \
	.venv/bin/python -m mvp_ed1.streaming.dataflow validar --terraform "$$base/tf.json" --pacote "$$pacote" \
		--saida "$(DATAFLOW_EVIDENCIA)/dataflow_job_$$(date -u +%Y%m%dT%H%M%SZ).json"

gcp-dataflow-lancar: gcp-dataflow-validar ## Janela: lança o caminho quente no Dataflow (1 worker, como mvp-streamer); cobra até o gcp-dataflow-parar
	@$(GCP_ENV); $(DATAFLOW_PREPARAR); \
	.venv/bin/python -m mvp_ed1.streaming.dataflow lancar --terraform "$$base/tf.json" --pacote "$$pacote"

gcp-dataflow-parar: gcp-preflight ## Drena o job do caminho quente (até 15 min), cancela se não terminar, e prova que nenhum ficou ativo (§6.5 passo 1)
	@$(GCP_ENV); \
	regiao=$$($(GCP_TF) output -json dataflow | .venv/bin/python -c 'import json,sys; print(json.load(sys.stdin)["regiao"])') || exit 1; \
	ativos() { gcloud dataflow jobs list --project "$$GCP_PROJECT_ID" --region "$$regiao" --status=active \
		--filter="name=$(DATAFLOW_JOB)" --format="value(id)"; }; \
	ids=$$(ativos) || exit 1; \
	test -n "$$ids" || { echo "gcp-dataflow-parar: nenhum job ativo"; exit 0; }; \
	for id in $$ids; do gcloud dataflow jobs drain "$$id" --project "$$GCP_PROJECT_ID" --region "$$regiao" || exit 1; done; \
	for _ in $$(seq 60); do sleep 15; test -z "$$(ativos)" && { echo "gcp-dataflow-parar: drenado; nenhum job ativo"; exit 0; }; done; \
	echo "gcp-dataflow-parar: a drenagem não terminou em 15 min; cancelando"; \
	for id in $$(ativos); do gcloud dataflow jobs cancel "$$id" --project "$$GCP_PROJECT_ID" --region "$$regiao" || exit 1; done; \
	for _ in $$(seq 20); do sleep 15; test -z "$$(ativos)" && { echo "gcp-dataflow-parar: cancelado; nenhum job ativo"; exit 0; }; done; \
	echo "ERRO: ainda há job ativo; o relógio da §6.4 manda escalar"; exit 1

gcp-carga-dev: gcp-preflight ## Copia o bruto local para o BigQuery (desenvolvimento; APAGAR=1 apaga as cópias)
	@$(GCP_ENV); .venv/bin/python -m mvp_ed1.gcp.carga_dev $(if $(APAGAR),--apagar)

# ── Terça: o Airbyte do GKE configurado e a época inicial do livro (A43) ──────────────────────────
# Na ordem: gcp-airbyte-config → gcp-armazem-zerar → gcp-armazem-governanca → gcp-livro-epoca, e
# só então a primeira sincronização. Depois do zerar, o `gcp-dbt-build` de ensaio não tem o que ler.

gcp-airbyte-config: gcp-preflight require-kubectl require-terraform ## Terça: a raiz airbyte/ no Airbyte do GKE (workspace gcp do Terraform), pelo port-forward; o apply mostra o plano e só aplica com yes
	@# O plano salvo da §6.3 levaria para um arquivo as senhas do Cloud SQL e o segredo do Airbyte,
	@# que entram como variáveis. O `apply` interativo mostra o plano inteiro e só aplica com o `yes`
	@# do Owner, como no `airbyte-config` local, sem arquivo (A45). O workspace vai por
	@# `TF_WORKSPACE`, que não muda o selecionado: o `airbyte-config` local segue no `default`.
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GKE_KUBECTL); $(GKE_AIRBYTE); \
	ip=$$($(GCP_TF) output -raw cloud_sql_ip_privado 2>/dev/null) && test -n "$$ip" \
		|| { echo "ERRO: sem Cloud SQL no estado (degrau 06)."; exit 1; }; \
	for origem in source legacy; do \
		senha=$$(gcloud secrets versions access latest --secret "mvp-ed1-$$origem-db-password" --project "$$GCP_PROJECT_ID") || exit 1; \
		export "TF_VAR_$${origem}_db_password=$$senha"; \
	done; \
	workspace=$$(.venv/bin/python -m mvp_ed1.airbyte workspace) || exit 1; \
	export TF_VAR_airbyte_server_url="$$AIRBYTE_URL" TF_VAR_airbyte_client_id="$$AIRBYTE_CLIENT_ID" \
		TF_VAR_airbyte_client_secret="$$AIRBYTE_CLIENT_SECRET" TF_VAR_airbyte_workspace_id="$$workspace" \
		TF_VAR_armazem=bigquery TF_VAR_gcp_project_id="$$GCP_PROJECT_ID" TF_VAR_gcp_bq_location="$$GCP_BQ_LOCATION" \
		TF_VAR_source_db_host="$$ip" TF_VAR_source_db_port=5432 TF_VAR_legacy_db_host="$$ip" TF_VAR_legacy_db_port=5432 \
		TF_VAR_source_db_name="$$SOURCE_DB_NAME" TF_VAR_source_db_user="$$SOURCE_DB_USER" \
		TF_VAR_legacy_db_name="$$LEGACY_DB_NAME" TF_VAR_legacy_db_user="$$LEGACY_DB_USER" \
		TF_VAR_warehouse_db_name= TF_VAR_warehouse_db_user= TF_VAR_warehouse_db_password=; \
	$(TERRAFORM) init -input=false -no-color > /dev/null || exit 1; \
	$(TERRAFORM) workspace list | grep -qw gcp || $(TERRAFORM) workspace new gcp > /dev/null || exit 1; \
	$(TERRAFORM) workspace select default > /dev/null || exit 1; \
	TF_WORKSPACE=gcp $(TERRAFORM) apply -parallelism=1; rc=$$?; \
	test "$$($(TERRAFORM) workspace show)" = default || echo "AVISO: a raiz airbyte/ não está no workspace default; rode: .tools/terraform -chdir=airbyte workspace select default"; \
	exit $$rc

gcp-armazem-zerar: gcp-preflight ## Terça, antes da época: apaga toda tabela e view dos nove datasets (a cópia do gcp-carga-dev e os dbt build de ensaio); CONFIRMA=<id do projeto>
	@$(GCP_ENV); \
	datasets=$$($(GCP_TF) output -json datasets) || exit 1; \
	.venv/bin/python -m mvp_ed1.gcp.armazem_janela zerar --datasets "$$datasets" --confirmar "$(CONFIRMA)"

gcp-armazem-governanca: gcp-preflight ## Terça, depois do zerar: as migrações do governance no BigQuery (governance.garantir_bigquery)
	@$(GCP_ENV); .venv/bin/python -m mvp_ed1.gcp.armazem_janela governanca

gcp-livro-epoca: gcp-preflight require-kubectl require-cloud-sql-proxy ## Terça, antes da primeira captura: abre a época inicial do livro no Cloud Storage (BigQuery, Cloud SQL e os jobs do Airbyte do GKE); recusa com época aberta ou armazém com dado
	@# O `ledger-baseline` da fase local apontado para a nuvem, por cima do `.env`: o armazém
	@# BigQuery, o livro na saída `livro_raiz`, o legado no Cloud SQL (o coordenador, A21) e o
	@# Airbyte do GKE, de que a linha de base lista os jobs da conexão legada.
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GKE_KUBECTL); $(GKE_AIRBYTE); $(GCP_ORIGENS); \
	raiz=$$($(GCP_TF) output -raw livro_raiz 2>/dev/null) && test -n "$$raiz" \
		|| { echo "ERRO: sem a saída livro_raiz no estado (o próximo apply a grava)."; exit 1; }; \
	datasets=$$($(GCP_TF) output -json datasets) || exit 1; \
	export LEGACY_WAREHOUSE=bigquery LEGACY_LEDGER_DIR="$$raiz"; \
	.venv/bin/python -m mvp_ed1.gcp.armazem_janela pronto --datasets "$$datasets" || exit 1; \
	.venv/bin/python -m mvp_ed1.recovery.ledger baseline

# ── Desmonte (PLANO_etapa_13 §6.5; quinta, 12/11) ──────────────────────────────────────────────
# A ordem é a da §6.5. Os planos saem de `make gcp-plan PASSO=n` — o VARS vem do
# `mvp_ed1.gcp.desmonte`, a janela inteira menos o já desmontado — e o `apply` de cada um é o rito
# de sempre, com o Owner. Os alvos daqui são os passos sem Terraform: cada um faz a ação e a prova,
# e falha dizendo o que sobrou. O relógio da §6.4 independe deles.
DESMONTE_EVIDENCIA := data/medicoes/etapa_13/g7

gcp-desmonte-parar: gcp-preflight gcp-dataflow-parar ## Desmonte, passo 1: Dataflow drenado, DAGs do Composer pausadas sem execução em curso, fluxo das policy tags desligado
	@# O produtor de movimentos roda no terminal do Owner e para lá, com Ctrl-C: daqui não se vê
	@# processo de outro terminal sem o risco do `pgrep -f` casar com o próprio comando.
	@$(GCP_ENV); \
	nome=$$($(call COMPOSER_SAIDA,nome)); \
	if test -n "$$nome"; then \
		g() { gcloud composer environments run "$$nome" --location "$$GCP_BQ_LOCATION" --project "$$GCP_PROJECT_ID" "$$@"; }; \
		for dag in fluxo_batch diagnostico_composer; do g dags pause -- "$$dag" -y > /dev/null || exit 1; done; \
		for dag in fluxo_batch diagnostico_composer; do \
			for estado in running queued; do \
				n=$$(g dags list-runs -- "$$dag" --state "$$estado" -o json 2>/dev/null | .venv/bin/python -c 'import json,sys; t=sys.stdin.read().strip(); print(0 if not t or "No data found" in t else len(json.loads(t)))') || exit 1; \
				test "$$n" = 0 || { echo "ERRO: $$dag com $$n execução(ões) $$estado; espere terminar (ou marque falha na interface) e repita."; exit 1; }; \
			done; \
		done; \
		echo "gcp-desmonte-parar: DAGs pausadas, nenhuma execução em curso"; \
	else echo "gcp-desmonte-parar: sem Composer no estado"; fi; \
	gh variable set MVP_GCP_ATIVO --body false || exit 1; \
	test "$$(gh variable get MVP_GCP_ATIVO)" = false || { echo "ERRO: MVP_GCP_ATIVO não ficou false."; exit 1; }; \
	echo "gcp-desmonte-parar: MVP_GCP_ATIVO=false (D79). O produtor, se estiver rodando, para no terminal dele."

gcp-desmonte-slot: gcp-preflight require-cloud-sql-proxy ## Desmonte, passo 3: depois do plano 21, remove do Cloud SQL o slot de replicação do Debezium e prova a ausência
	@# Sem o Debezium Server (plano 21) o slot fica inativo e segura WAL até a instância sair, e o
	@# disco não cresce sozinho (`disk_autoresize = false`). A remoção recusa slot ativo: com o
	@# Debezium de pé, nada sai. O proxy abre e fecha aqui; a senha vai do Secret Manager para o
	@# ambiente do processo, não para a tela (`GCP_ORIGENS`).
	@$(GCP_ENV); $(GCP_LIMPEZA); $(GCP_ORIGENS); \
	.venv/bin/python -m mvp_ed1.streaming.maintenance drop-slots --force

gcp-desmonte-kubernetes: gcp-preflight require-kubectl ## Desmonte, passo 4: depois do plano 21, apaga os namespaces do Airbyte e do Debezium e prova que nenhum PV nem load balancer ficou
	@# O `helm uninstall` do plano 21 não leva os PVCs dos StatefulSets do chart do Airbyte — o banco
	@# interno e o MinIO (`volumeClaimTemplates` do chart 2.3.0, sem política de retenção) —, e o
	@# GKE retém disco persistente ao apagar o cluster. O namespace leva os PVCs; o PV dinâmico, de
	@# política Delete, leva o disco. Só depois disto o plano 22.
	@$(GCP_ENV); \
	base=$$(mktemp -d) && trap 'rm -rf "$$base"' EXIT; \
	$(GKE_KUBECTL); \
	for ns in airbyte debezium; do k delete namespace "$$ns" --ignore-not-found --wait=true --timeout=15m || exit 1; done; \
	lb=$$(k get services -A -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}/{.metadata.name} {end}') || exit 1; \
	test -z "$$lb" || { echo "ERRO: Service LoadBalancer de pé: $$lb"; exit 1; }; \
	for _ in $$(seq 40); do pvs=$$(k get pv -o name) || exit 1; test -z "$$pvs" && break; sleep 15; done; \
	test -z "$$pvs" || { echo "ERRO: PV ainda no cluster depois de 10 min: $$pvs"; exit 1; }; \
	echo "gcp-desmonte-kubernetes: namespaces apagados; nenhum PV nem load balancer no cluster"

gcp-desmonte-orfaos: gcp-preflight ## Desmonte, passo 5: depois do plano 22, prova que o GKE e o Composer não deixaram disco, instância, load balancer nem firewall
	@$(GCP_ENV); \
	falhou=; \
	listar() { gcloud compute "$$@" --project "$$GCP_PROJECT_ID" --format="value(name)"; }; \
	for categoria in "disks list" "instances list" "instance-groups list" "forwarding-rules list" \
		"backend-services list" "health-checks list" "target-pools list" "network-attachments list"; do \
		achados=$$(listar $$categoria) || exit 1; \
		test -z "$$achados" || { echo "ÓRFÃO ($$categoria): $$achados"; falhou=1; }; \
	done; \
	achados=$$(listar addresses list --filter="name!=mvp-ed1-servicos-privados") || exit 1; \
	test -z "$$achados" || { echo "ÓRFÃO (addresses list): $$achados"; falhou=1; }; \
	achados=$$(listar firewall-rules list --filter="network~/mvp-ed1$$") || exit 1; \
	test -z "$$achados" || { echo "ÓRFÃO (firewall-rules na mvp-ed1): $$achados"; falhou=1; }; \
	test -z "$$falhou" || exit 1; \
	echo "gcp-desmonte-orfaos: nada do GKE nem do Composer sobrou no Compute Engine"

gcp-desmonte-sql: gcp-preflight ## Desmonte, passo 7: depois do plano 23, prova que nenhuma instância do Cloud SQL nem backup retido ficou
	@# `--instance=-` lista os backups de todas as instâncias, inclusive os retidos de instância
	@# apagada (`retain_backups_on_delete`, explícito `false` no cloud_sql.tf).
	@$(GCP_ENV); \
	instancias=$$(gcloud sql instances list --project "$$GCP_PROJECT_ID" --format="value(name)") || exit 1; \
	test -z "$$instancias" || { echo "ERRO: instância do Cloud SQL de pé: $$instancias"; exit 1; }; \
	backups=$$(gcloud sql backups list --instance=- --project "$$GCP_PROJECT_ID" --format="value(id,instance)") || exit 1; \
	test -z "$$backups" || { echo "ERRO: backup retido: $$backups"; exit 1; }; \
	echo "gcp-desmonte-sql: nenhuma instância nem backup do Cloud SQL no projeto"

gcp-desmonte-linhagem: gcp-preflight ## Desmonte, passo 8: antes do plano 24, apaga os processos da Data Lineage API; recusa sem a captura de tela da linhagem (G5)
	@# Os processos não têm `destroy` (ninguém os declarou no Terraform), e a captura de tela é a
	@# evidência que fica da linhagem: sem o arquivo, nada se apaga.
	@ls docs/registro_fase_gcp/capturas/*linhagem* > /dev/null 2>&1 \
		|| { echo "ERRO: sem captura da linhagem em docs/registro_fase_gcp/capturas/ (G5); tire-a antes."; exit 1; }
	@$(GCP_ENV); .venv/bin/python -m mvp_ed1.gcp.desmonte linhagem

gcp-desmonte-inventario: gcp-preflight ## Desmonte, passo 9: o Cloud Asset Inventory do projeto contra src/mvp_ed1/gcp/residuos_esperados.yml; falha listando cada resíduo
	@# O inventário atrasa: recurso apagado há minutos ainda pode aparecer. Resíduo listado se
	@# confere na consola antes de virar ação; repetir o alvo minutos depois faz parte da prova.
	@$(GCP_ENV); mkdir -p $(DESMONTE_EVIDENCIA); \
	quando=$$(date -u +%Y%m%dT%H%M%SZ); \
	gcloud asset search-all-resources --scope="projects/$$GCP_PROJECT_ID" --format=json \
		> "$(DESMONTE_EVIDENCIA)/inventario_$$quando.json" || exit 1; \
	.venv/bin/python -m mvp_ed1.gcp.desmonte inventario --entrada "$(DESMONTE_EVIDENCIA)/inventario_$$quando.json" \
		--saida "$(DESMONTE_EVIDENCIA)/residuos_$$quando.json"

gcp-desmonte-orcamento: gcp-preflight ## Desmonte, passo 10: depois do plano 25, prova que o orçamento saiu da conta de faturamento
	@$(GCP_ENV); \
	conta=$$(sed -n 's/^billing_account_id *= *"\(.*\)"/\1/p' terraform/terraform.tfvars); \
	test -n "$$conta" || { echo "ERRO: billing_account_id ausente no terraform.tfvars."; exit 1; }; \
	achados=$$(gcloud billing budgets list --billing-account="$$conta" --filter='displayName="mvp-ed1 Etapa 13"' --format="value(name)") || exit 1; \
	test -z "$$achados" || { echo "ERRO: o orçamento continua na conta: $$achados"; exit 1; }; \
	echo "gcp-desmonte-orcamento: nenhum orçamento 'mvp-ed1 Etapa 13' na conta de faturamento"

gcp-desligar-faturamento: gcp-preflight ## §6.4, qui 12/11 12:00 — camada 2: desvincula o faturamento (CONFIRMA=<id do projeto>) e guarda a prova billingEnabled=false
	@$(GCP_ENV); \
	test "$(CONFIRMA)" = "$$GCP_PROJECT_ID" || { echo "ERRO: para todo recurso pago do projeto; repita com CONFIRMA=$$GCP_PROJECT_ID."; exit 1; }; \
	mkdir -p $(DESMONTE_EVIDENCIA); saida="$(DESMONTE_EVIDENCIA)/faturamento_$$(date -u +%Y%m%dT%H%M%SZ).json"; \
	gcloud billing projects unlink "$$GCP_PROJECT_ID" > /dev/null || exit 1; \
	gcloud billing projects describe "$$GCP_PROJECT_ID" --format=json > "$$saida" || exit 1; \
	.venv/bin/python -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get("billingEnabled") is False or "billingEnabled" not in d else 1)' "$$saida" \
		|| { echo "ERRO: o faturamento continua ligado ($$saida); o Owner desliga pela consola."; exit 1; }; \
	echo "gcp-desligar-faturamento: billingEnabled=false · $$saida"

gcp-apagar-projeto: gcp-preflight ## §6.4, qui 12/11 15:00 — camada 3, com o Owner: pede a exclusão do projeto (CONFIRMA=<id do projeto>) e guarda o DELETE_REQUESTED
	@# Depois da exclusão a cota não pode mais ir para o projeto: a conferência usa o projeto padrão
	@# do `gcloud` (sem o CLOUDSDK_CORE_PROJECT).
	@$(GCP_ENV); \
	test "$(CONFIRMA)" = "$$GCP_PROJECT_ID" || { echo "ERRO: pede a exclusão do projeto inteiro; repita com CONFIRMA=$$GCP_PROJECT_ID."; exit 1; }; \
	mkdir -p $(DESMONTE_EVIDENCIA); saida="$(DESMONTE_EVIDENCIA)/projeto_$$(date -u +%Y%m%dT%H%M%SZ).json"; \
	gcloud projects delete "$$GCP_PROJECT_ID" --quiet || exit 1; \
	env -u CLOUDSDK_CORE_PROJECT gcloud projects describe "$$GCP_PROJECT_ID" --format=json > "$$saida" || exit 1; \
	estado=$$(.venv/bin/python -c 'import json,sys; print(json.load(open(sys.argv[1])).get("lifecycleState",""))' "$$saida"); \
	test "$$estado" = DELETE_REQUESTED || { echo "ERRO: estado '$$estado', não DELETE_REQUESTED ($$saida)."; exit 1; }; \
	echo "gcp-apagar-projeto: DELETE_REQUESTED — pedido de exclusão, não eliminação imediata · $$saida"
