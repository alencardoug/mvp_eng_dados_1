# Interface única de operação do projeto (ADR-0012, Execução Local).
# O contrato completo — inclusive os alvos que ainda não existem e a etapa em
# que cada um nasce — está em docs/execucao_local.md. Aqui vive só o que já
# funciona: duplicar a lista seria defeito (P8).

SHELL := /bin/bash
.DEFAULT_GOAL := help

COMPOSE := docker compose --env-file .env -f docker/docker-compose.yml
COMPOSE_AIRFLOW := docker compose --env-file .env -f docker/docker-compose.airflow.yml
# O .env é carregado em cada receita: `make` roda um shell novo por linha.
ALEMBIC := set -a; . ./.env; set +a; .venv/bin/alembic
# O gerador lê a conexão do ambiente, nunca de argumento (mvp_ed1/db.py).
GERADOR := set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.generator.cli

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
BASE := source_db legacy_db warehouse_db

.PHONY: help env install up down reset ps logs psql-source psql-legacy psql-warehouse \
        migrate migrate-down migrate-new migrate-status catalog seed-data seed-plan size-report test \
        tools airbyte-up airbyte-down airbyte-credentials airbyte-config sync-airbyte \
        dbt-build dbt-drop-snapshots dbt-test dbt-docs airflow-up airflow-down dag-run dag-status \
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

catalog: require-venv ## Regenera dicionário, inventário e diagrama ER dos modelos e da configuração
	@.venv/bin/python -m mvp_ed1.models.export

seed-data: require-env require-venv ## Gera e carrega os dados sintéticos; SCALE, SEED, AS_OF, FORCE=1
	@$(GERADOR) seed \
		$(if $(SCALE),--scale $(SCALE)) $(if $(SEED),--seed $(SEED)) \
		$(if $(AS_OF),--as-of $(AS_OF)) $(if $(filter 1,$(FORCE)),--force) \
		$(if $(filter 1,$(DRY_RUN)),--dry-run)

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

airbyte-up: require-abctl ## Sobe o Airbyte local (cluster próprio; ~9 GB de imagens na primeira vez)
	@$(ABCTL) local install --values airbyte/values.yaml
	@echo ""
	@echo "Interface em http://localhost:8000 — credenciais em 'make airbyte-credentials'."

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
		export TF_VAR_warehouse_db_name="$$WAREHOUSE_DB_NAME" TF_VAR_warehouse_db_user="$$WAREHOUSE_DB_USER" TF_VAR_warehouse_db_password="$$WAREHOUSE_DB_PASSWORD"; \
		$(TERRAFORM) init -input=false -no-color >/dev/null && $(TERRAFORM) apply -input=false $(if $(filter 1,$(AUTO)),-auto-approve)

sync-airbyte: require-env require-abctl ## Sincroniza oltp -> raw; RESET=1 descarta o cursor antes
	@$(CREDENCIAIS); \
		$(if $(filter 1,$(RESET)),.venv/bin/python -m mvp_ed1.airbyte reset &&) \
		.venv/bin/python -m mvp_ed1.airbyte sync

dbt-build: require-env require-venv ## Roda os modelos dbt e os testes; RESET=1 refaz histórico SCD e incrementais
	@# `--full-refresh` junto com o descarte do histórico, e não por precaução:
	@# refazer os snapshots troca **todas** as chaves substitutas, e a fato
	@# incremental continuaria apontando para as antigas. O teste de
	@# `relationships` pega — depois de 13.514 linhas órfãs.
	@$(if $(filter 1,$(RESET)),$(MAKE) --no-print-directory dbt-drop-snapshots &&) \
		$(DBT) build $(if $(filter 1,$(RESET)),--full-refresh) $(DBT_ARGS)

airflow-up: require-env require-abctl ## Sobe o Airflow local (LocalExecutor, três contêineres)
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

dag-run: require-env ## Dispara a DAG do caminho frio (fluxo_batch)
	@# DAG nasce pausada no Airflow, e execução enfileirada em DAG pausada fica
	@# `queued` para sempre — o disparo "funciona" e não faz nada. Espera o
	@# processador de DAGs registrá-la antes de despausar: logo depois de um
	@# `airflow-up`, ela ainda não existe no banco de metadados.
	@for i in $$(seq 1 30); do \
		$(COMPOSE_AIRFLOW) exec -T airflow_scheduler \
			airflow dags unpause fluxo_batch >/dev/null 2>&1 && break; \
		sleep 2; \
	done
	@$(COMPOSE_AIRFLOW) exec -T airflow_scheduler airflow dags trigger fluxo_batch >/dev/null
	@echo "DAG 'fluxo_batch' disparada. Acompanhe em http://localhost:$$(grep ^AIRFLOW_PORT .env | cut -d= -f2)"
	@echo "ou por: make dag-status"

dag-status: require-env ## Mostra o estado das tarefas da última execução da DAG
	@$(COMPOSE_AIRFLOW) exec -T airflow_scheduler \
		airflow tasks states-for-dag-run fluxo_batch \
		"$$($(COMPOSE_AIRFLOW) exec -T airflow_scheduler airflow dags list-runs fluxo_batch -o plain 2>/dev/null | grep -oE 'manual__[0-9T:.+-]+' | head -1)" \
		-o plain 2>/dev/null | grep -viE 'alembic|plugin'

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

dbt-docs: require-env require-venv ## Gera e serve o catálogo com dicionário, linhagem e glossário
	@$(DBT) docs generate && $(DBT) docs serve

test: require-venv ## Testes de código Python (pytest); CARGA=1 inclui a que escreve no banco
	@set -a; [ -f .env ] && . ./.env; set +a; \
		MVP_TESTE_CARGA=$(if $(filter 1,$(CARGA)),1,0) .venv/bin/pytest -q

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
