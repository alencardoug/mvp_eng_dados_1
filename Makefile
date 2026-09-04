# Interface única de operação do projeto (ADR-0012, Execução Local).
# O contrato completo — inclusive os alvos que ainda não existem e a etapa em
# que cada um nasce — está em docs/execucao_local.md. Aqui vive só o que já
# funciona: duplicar a lista seria defeito (P8).

SHELL := /bin/bash
.DEFAULT_GOAL := help

COMPOSE := docker compose --env-file .env -f docker/docker-compose.yml
# O .env é carregado em cada receita: `make` roda um shell novo por linha.
ALEMBIC := set -a; . ./.env; set +a; .venv/bin/alembic
# O gerador lê a conexão do ambiente, nunca de argumento (mvp_ed1/db.py).
GERADOR := set -a; . ./.env; set +a; .venv/bin/python -m mvp_ed1.generator.cli
BASE := source_db legacy_db warehouse_db

.PHONY: help env install up down reset ps logs psql-source psql-legacy psql-warehouse \
        migrate migrate-down migrate-new migrate-status catalog seed-data seed-plan size-report test \
        require-env require-venv

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
