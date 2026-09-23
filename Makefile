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
TERRAFORM_VERSION := 1.16.1
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
        migrate migrate-down migrate-new migrate-status migrate-legacy migrate-legacy-down \
        migrate-legacy-status migrate-legacy-new catalog seed-data seed-plan size-report test test-carga \
        tools airbyte-up airbyte-down airbyte-credentials airbyte-config sync-airbyte \
        dbt-build dbt-drop-snapshots dbt-test dbt-docs airflow-up airflow-down dag-run dag-status \
        stream-up stream-down stream-connector stream-status stream-run stream-produce \
        stream-duplicate stream-alerts stream-reset-sink \
        preflight airbyte-pause airbyte-resume stream-pause stream-resume \
        airflow-pause airflow-resume medir dag-wait stream-corte stream-wait docs-generate \
        docs-check secrets-history dbt-rebuild \
        recovery-pack recovery-verify recovery-rebase recovery-airbyte-jobs recovery-restore recovery-promote \
        require-env require-venv require-abctl require-terraform

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
	@echo "'.env' criado com senhas aleatórias e permissão 600."

install: ## Cria o .venv com Python 3.11 e instala o projeto em modo editável
	uv sync
	@echo ""
	@echo "Ambiente pronto. O 'uv.lock' é a trava — versione-o."
	@.venv/bin/python -c "import mvp_ed1, sys; print(f'mvp_ed1 {mvp_ed1.__version__} sobre Python {sys.version.split()[0]}')"

up: require-env ## Sobe os três bancos e espera ficarem saudáveis
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

catalog: require-venv ## Regenera dicionário, inventário, diagrama ER, a classificação derivada e a linhagem por coluna
	@.venv/bin/python -m mvp_ed1.models.export
	@# A sensibilidade de cada coluna do armazém é derivada da declarada nos
	@# modelos, por linhagem do SQL compilado — precisa do manifest de um
	@# `make dbt-build` recente. Sem ele, avisa e não escreve nada. A linhagem
	@# por coluna (Dicionário §3) sai da mesma leitura, logo depois.
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

size-report: require-env require-venv ## Tamanho por banco, tabela e índice — observação, não limite
	@$(GERADOR) size-report

tools: ## Baixa abctl e Terraform fixados para .tools/ (fora do Git)
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
	@.tools/abctl version 2>/dev/null | tail -1; .tools/terraform version | head -1

require-abctl:
	@test -x .tools/abctl || { echo "ERRO: abctl ausente. Rode 'make tools'."; exit 1; }

require-terraform:
	@test -x .tools/terraform || { echo "ERRO: Terraform ausente. Rode 'make tools'."; exit 1; }

preflight: ## Diz se cabe subir um subconjunto; ALVO=airbyte|airflow|streaming|trabalho
	@docker/preflight.sh $(ALVO)

medir: ## Mede um alvo: ALVO= [ATE=<alvo de espera>], ou CENARIO=streaming [LIMITE=n]
	@$(MEDIR) $(if $(CENARIO),--cenario $(CENARIO) $(if $(LIMITE),--limite $(LIMITE)),$(ALVO) $(if $(ATE),--ate $(ATE)))

# ── Pausa e retomada ────────────────────────────────────────────────────────
# Devolver memória à máquina sem desmontar nada. `airbyte-down` é
# `abctl local uninstall`: destrói o cluster, e voltar custa uma reinstalação
# inteira — que é justamente onde mora a armadilha do `PG_VERSION`
# (Execução Local §6). Parar o contêiner libera a mesma memória e volta sem
# reinstalar nada — quanto leva está em `RETOMAR_AIRBYTE`, medido.
airbyte-pause: ## Para o cluster do Airbyte liberando a memória, sem desmontá-lo
	@docker stop airbyte-abctl-control-plane >/dev/null 2>&1 && \
		echo "Airbyte pausado. Retomar: make airbyte-resume" || \
		echo "Airbyte já não estava de pé."

# Religar o cluster pausado e esperar a API do Airbyte: uma receita, dois
# chamadores — `airbyte-resume` e o ramo "pausado" de `airbyte-up`. Variável, e
# não `$(MAKE) airbyte-resume` dentro do `if` de `airbyte-up`: o `make` executa
# de verdade, mesmo sob `-n`, toda linha em cujo texto aparece `$(MAKE)`, e
# aquela linha tinha no outro ramo o `abctl local install` — um
# `make -n recovery-restore` o chamou com o Airbyte de pé (23/09/2026).
#
# **Pronto é a API responder `available:true`, não um pod (RVE3-02).** Medido
# em duas retomadas reais em 23/09/2026: o nó lista os sandboxes da partida
# anterior como `NotReady`, e o `grep -q Ready` da espera antiga casava neles —
# dizia "pronto" em 5,6 s. Nem pod serve: o primeiro sandbox fica pronto em
# ~5 s, e o Kubernetes chegou a dizer 8/8 prontos aos 5 s, estado de antes da
# pausa. A API respondeu em 101 s e em 96 s; o ingress devolve 503 na metade
# final. Quem vem depois — `recovery-airbyte-jobs`, `sync-airbyte` — usa a API
# e o banco dela. O prazo, 60 consultas a cada 5 s, é três vezes o medido, e
# esgotá-lo é erro. Sem `curl` a espera seria cega — o `2>/dev/null` engoliria
# o "command not found" e o prazo venceria dizendo que a API não respondeu —,
# por isso a falta dele recusa antes de religar qualquer coisa.
RETOMAR_AIRBYTE = command -v curl >/dev/null \
	|| { echo "ERRO: curl ausente — é por ele que a retomada espera a API do Airbyte."; exit 1; }; \
	docker start airbyte-abctl-control-plane >/dev/null \
	|| { echo "ERRO: cluster não existe. Use 'make airbyte-up'."; exit 1; }; \
	printf "aguardando a API do Airbyte"; pronta=; \
	for i in $$(seq 1 60); do \
		if curl -s --max-time 5 $(AIRBYTE_WEB)/api/v1/health 2>/dev/null | grep -Eq '"available": *true'; then \
			pronta=1; break; fi; \
		printf "."; sleep 5; done; \
	[ -n "$$pronta" ] || { echo " tempo esgotado: a API não respondeu em 5 min."; \
		echo "  Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'."; exit 1; }; \
	echo " pronta."

airbyte-resume: ## Religa o cluster do Airbyte pausado e espera a API responder
	@$(RETOMAR_AIRBYTE)

stream-pause: ## Para Redpanda e Kafka Connect preservando os contêineres e o conector
	@RETOMAR_COM='make stream-resume' $(CONTEINERES) pausar streaming @streaming; \
		s=$$?; [ $$s -eq 3 ] && exit 0 || exit $$s

stream-resume: ## Religa Redpanda e Kafka Connect pausados
	@$(CONTEINERES) retomar streaming @streaming || { echo "Use 'make stream-up' se os contêineres não existem."; exit 1; }
	@echo "O conector Debezium volta do ponto em que parou."

airflow-pause: ## Para os contêineres do Airflow liberando a memória
	@RETOMAR_COM='make airflow-resume' $(CONTEINERES) pausar Airflow @airflow; \
		s=$$?; [ $$s -eq 3 ] && exit 0 || exit $$s

airflow-resume: ## Religa os contêineres do Airflow pausados
	@$(CONTEINERES) retomar Airflow @airflow

airbyte-up: require-abctl ## Sobe o Airbyte local; retoma se estiver pausado
	$(call preflight,airbyte)
	@# Cluster pausado — por `airbyte-pause`, ou pela troca automática que o
	@# preflight faz ao subir o streaming — não se reinstala: o `abctl` valida o
	@# cluster antes de qualquer coisa e recusa um contêiner parado. Retomar leva
	@# ~100 s até a API responder; reinstalar leva minutos e esbarra no
	@# `PG_VERSION` (§6).
	@if [ -n "$$(docker ps -aq -f 'name=^airbyte-abctl-control-plane$$' -f status=exited)" ]; then \
		echo "cluster pausado — retomando em vez de reinstalar"; \
		$(RETOMAR_AIRBYTE); \
	else \
		$(ABCTL) local install --values airbyte/values.yaml; \
	fi
	@echo ""
	@echo "Interface em $(AIRBYTE_WEB) — credenciais em 'make airbyte-credentials'."

airbyte-down: require-abctl ## Derruba o Airbyte, preservando os dados dele
	@$(ABCTL) local uninstall

airbyte-credentials: require-abctl ## Mostra as credenciais do Airbyte local
	@$(ABCTL) local credentials

airbyte-config: require-env require-terraform ## Cria fonte, destino e conexão a partir do Terraform
	@set -a; . ./.env; set +a; $(CREDENCIAIS); \
		export TF_VAR_airbyte_client_id="$$AIRBYTE_CLIENT_ID"; \
		export TF_VAR_airbyte_client_secret="$$AIRBYTE_CLIENT_SECRET"; \
		export TF_VAR_airbyte_workspace_id="$${AIRBYTE_WORKSPACE_ID:-$$(.venv/bin/python -m mvp_ed1.airbyte workspace)}"; \
		export TF_VAR_source_db_name="$$SOURCE_DB_NAME" TF_VAR_source_db_user="$$SOURCE_DB_USER" TF_VAR_source_db_password="$$SOURCE_DB_PASSWORD"; \
		export TF_VAR_legacy_db_name="$$LEGACY_DB_NAME" TF_VAR_legacy_db_user="$$LEGACY_DB_USER" TF_VAR_legacy_db_password="$$LEGACY_DB_PASSWORD" TF_VAR_legacy_db_port="$$LEGACY_DB_PORT"; \
		export TF_VAR_warehouse_db_name="$$WAREHOUSE_DB_NAME" TF_VAR_warehouse_db_user="$$WAREHOUSE_DB_USER" TF_VAR_warehouse_db_password="$$WAREHOUSE_DB_PASSWORD"; \
		$(TERRAFORM) init -input=false -no-color >/dev/null && $(TERRAFORM) apply -input=false $(if $(filter 1,$(AUTO)),-auto-approve)

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
	@$(CREDENCIAIS); \
		AIRFLOW_UID="$$(id -u)" \
		AIRBYTE_CLIENT_ID="$$AIRBYTE_CLIENT_ID" AIRBYTE_CLIENT_SECRET="$$AIRBYTE_CLIENT_SECRET" \
		$(COMPOSE_AIRFLOW) up -d --build --wait airflow_apiserver airflow_scheduler airflow_dag_processor
	@echo ""
	@echo "Airflow em http://localhost:$$(grep ^AIRFLOW_PORT .env | cut -d= -f2) — admin / admin."

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

dbt-docs: require-env require-venv ## Gera e serve o catálogo com dicionário, linhagem e glossário
	@$(DBT) docs generate && $(DBT) docs serve

test: require-venv ## Testes de código Python (pytest); CARGA=1 roda a carga em banco efêmero; FATO=1 inclui o teste que escreve na fato
	@# Dois interruptores, de propósito. `CARGA=1` substitui a origem pela carga
	@# reduzida e por isso só roda em banco efêmero (alvo `test-carga`); `FATO=1`
	@# escreve no armazém de trabalho por desenho (repara e confere) e é
	@# autorização à parte. Uma flag só para os dois foi o que pôs a origem de
	@# trabalho em fator 0,05 duas vezes.
	@set -a; [ -f .env ] && . ./.env; set +a; \
		MVP_TESTE_FATO=$(if $(filter 1,$(FATO)),1,0) .venv/bin/pytest -q
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
	@echo "── 3/4 classificação derivada e linhagem em dia com os modelos ──"
	@.venv/bin/python -m mvp_ed1.models.sensitivity --check
	@.venv/bin/python -m mvp_ed1.models.lineage --check
	@echo "── 4/4 pytest: código, contratos e integração ──"
	@$(MAKE) --no-print-directory test FATO=$(FATO)
	@echo "check: as quatro etapas passaram"

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
