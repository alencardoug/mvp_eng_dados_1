# Execução Local

> **O que vive aqui:** como operar o projeto pelo terminal — pré-requisitos, comandos e ordem de
> execução.
>
> **O que não vive aqui:** o que cada componente faz (ver [Arquitetura](arquitetura.md)); os
> parâmetros do gerador (ver [Geração de Dados](geracao_de_dados.md)); o orçamento de disco (ver
> [Capacidade e Recuperação](capacidade_e_recuperacao.md)).

| Campo | Informação |
|---|---|
| Interface | `Makefile` — a operação inteira acontece no terminal |
| Versão | 1.5 |
| Situação | Alvos das Etapas **2 a 4** implementados e conferidos; os demais nascem na etapa indicada |
| Última revisão | 04/09/2026 |

Este documento é, hoje, o **contrato** do que a execução local deve oferecer. Cada alvo é
preenchido e conferido — executando-o — na etapa em que nasce, conforme o
[Plano de Desenvolvimento](plano_de_desenvolvimento.md).

---

## 1. Pré-requisitos

| Requisito | Observação |
|---|---|
| Docker e Docker Compose | Todo o ambiente roda em contêineres |
| `uv` | Gerencia interpretador, dependências e ambiente ([ADR-0026](adr/0026-uv-para-ambiente-e-dependencias.md)). Instala o Python 3.11 sozinho — não é preciso ter Python antes |
| `abctl` e Terraform | Baixados por `make tools` nas versões fixadas no `Makefile`, para `.tools/`. Não precisam existir na máquina antes |
| **CPU** | **A restrição descoberta na Etapa 5.** Quatro núcleos é o mínimo documentado do Airbyte para a *plataforma* — o *pod* de replicação pede outros quatro. Ver seção 6 |
| Python 3.11 | Fixado por paridade com o Cloud Composer. `make install` cria o `.venv` e instala o pacote ([ADR-0012](adr/0012-repositorio-com-pacote-instalavel.md)) |
| `make` | Interface única de operação |
| Disco livre | **Pelo menos 8 GB** — o volume de dados é baixo por desenho ([ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md)); o espaço é para imagem, log e WAL |
| Memória | Airbyte, Airflow, Redpanda e Kafka Connect não precisam subir ao mesmo tempo; ver seção 5. Com o Airbyte e o Airflow juntos, contar com **cerca de 6 GB** |

Nenhum serviço de nuvem é necessário na fase local, e nenhuma credencial de nuvem deve existir na
máquina para executá-la.

---

## 2. Configuração

```bash
make env        # gera o .env com portas padrão e senhas aleatórias, permissão 600
make install    # instala o Python 3.11 e o pacote no .venv
```

O `.env.example` é versionado com as chaves e **sem** valores, e serve para declarar quais chaves
existem — não para ser copiado e preenchido à mão. `make env` recusa sobrescrever um `.env`
existente, porque trocar as senhas torna os volumes já criados inacessíveis. Ver
[Política de Governança de Dados](governanca_de_dados.md#9-tratamento-de-segredos).

---

## 3. Ciclo completo

A sequência abaixo leva de um repositório recém-clonado até as views de consumo.

| # | Comando | O que faz | Disponível na |
|---|---|---|---|
| 1 | `make up` | Sobe os contêineres base: `source_db`, `legacy_db`, `warehouse_db` | Etapa 2 |
| 2 | `make migrate` | Aplica as migrações Alembic até a última revisão | Etapa 3 |
| 3 | `make seed-data` | Gera os dados sintéticos da origem principal | Etapa 4 |
| 3b | `make seed-plan` | Mostra o plano de volume das 40 tabelas, sem tocar no banco | Etapa 4 |
| 4 | `make seed-legacy` | Gera a origem legada com as falhas intencionais | Etapa 10 |
| 4b | `make airbyte-up` | Sobe o Airbyte local, em cluster próprio | Etapa 5 |
| 4c | `make airbyte-config` | Cria fonte, destino e conexão por Terraform | Etapa 5 |
| 5 | `make sync-airbyte` | Executa as sincronizações para `raw` e `raw_legacy` | Etapa 5 |
| 6 | `make dbt-build` | Roda os modelos dbt e os testes de dados; `RESET=1` refaz o histórico SCD | Etapa 5 |
| 7 | `make stream-up` | Sobe Redpanda, Kafka Connect com o conector Debezium e o *job* Beam | Etapa 7 |
| 8 | `make stream-produce` | Executa o produtor de eventos de estoque | Etapa 7 |
| 9 | `make dbt-docs` | Gera e serve o catálogo com dicionário, linhagem e glossário | Etapa 5 |
| 10 | `make size-report` | Relatório de tamanho por banco, schema, tabela e índice — observação, não limite | Etapa 4 |
| 11 | `make check` | Verificação completa: testes, reconciliações e revisão de segredos | Etapa 12 |

### 3.1 Parâmetros do gerador

Passados por variável do alvo, nunca editados no código. O padrão de todos vem da
[configuração do gerador](../src/mvp_ed1/generator/geracao.yml).

```bash
make seed-data                      # fator `dev`, padrão em todas as etapas
make seed-data SCALE=10             # fator maior, quando houver motivo declarado
make seed-data SEED=42 AS_OF=2026-06-30   # outra semente e outra data de corte
make seed-data DRY_RUN=1            # gera e mede em memória, sem escrever no banco
make seed-data FORCE=1              # trunca as 40 tabelas antes de carregar
```

O volume é expresso por **fator de escala** sobre um conjunto único de proporções
([ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md)). Não há perfis de tamanho.

**`make seed-data` recusa carregar sobre dados existentes.** É o mesmo contrato de `make env` e
`make reset`: comando que destrói estado não destrói sozinho. `FORCE=1` autoriza o truncamento das
40 tabelas antes da carga.

A mesma `SEED` com a mesma `AS_OF` recria exatamente os mesmos dados
([ADR-0005](adr/0005-geracao-com-faker-orientada-a-configuracao.md)) — inclusive as chaves
primárias, porque o gerador as atribui e o `COPY` as escreve.

---

## 4. Alvos auxiliares

| Comando | O que faz | Disponível na |
|---|---|---|
| `make help` | Lista os alvos já implementados | Etapa 2 |
| `make ps` | Estado e portas dos contêineres | Etapa 2 |
| `make logs` | Acompanha os logs; `SERVICE=source_db` filtra | Etapa 2 |
| `make psql-source` · `make psql-legacy` · `make psql-warehouse` | Abre o `psql` no banco correspondente | Etapa 2 |
| `make down` | Derruba os contêineres preservando os volumes | Etapa 2 |
| `make reset` | Derruba e apaga os volumes — recomeço do zero | Etapa 2 |
| `make migrate-down` | Desfaz migrações; `TO=base` derruba tudo | Etapa 3 |
| `make migrate-new` | Gera rascunho de migração; exige `M="o que mudou"` | Etapa 3 |
| `make migrate-status` | Mostra a revisão aplicada no banco | Etapa 3 |
| `make catalog` | Regenera dicionário, inventário de tabelas e diagrama ER dos modelos e da configuração | Etapa 3 |
| `make dbt-drop-snapshots` | **Destrói** o histórico SCD; só depois de regerar a origem | Etapa 5 |
| `make tools` | Baixa `abctl` e Terraform nas versões fixadas, para `.tools/` | Etapa 5 |
| `make airbyte-credentials` | Mostra as credenciais do Airbyte local | Etapa 5 |
| `make airbyte-down` | Derruba o Airbyte | Etapa 5 |
| `make test` | Testes de código Python (`pytest`); `CARGA=1` inclui a que escreve no banco | Etapa 4 |
| `make dbt-test` | Somente os testes de dados | Etapa 5 |
| `make airflow-up` | Sobe o Airflow (LocalExecutor, três contêineres) | Etapa 5 |
| `make airflow-down` | Derruba o Airflow preservando o histórico de execuções | Etapa 5 |
| `make dag-status` | Estado das tarefas da última execução da DAG | Etapa 5 |
| `make dag-run` | Despausa e dispara a DAG do corte comercial | Etapa 5 |
| `make stream-down` | Derruba Kafka Connect, mensageria e o *job* | Etapa 7 |
| `make recover-dump` | Gera o pacote candidato do ponto de recuperação | Etapa 12 |
| `make recover-restore` | Restaura as origens a partir do pacote aprovado | Etapa 12 |

> `make reset`, `make seed-data FORCE=1`, `make sync-airbyte RESET=1`, `make dbt-build RESET=1`,
> `make dbt-drop-snapshots`, `make test CARGA=1` e `make recover-restore` **destroem estado**. Todos
> exigem a variável explícita, exceto `dbt-drop-snapshots`, cujo nome já é o aviso;
> `recover-restore` só é executado mediante decisão explícita do responsável técnico.

---

## 5. Executando por partes

Não é necessário — nem recomendável — manter tudo ativo ao mesmo tempo. O ambiente foi desenhado
para subir em subconjuntos, mitigação direta do risco **R11**:

| Cenário | O que precisa estar de pé |
|---|---|
| Desenvolver modelos dbt | `make up` + dados já carregados |
| Rodar o fluxo pelo orquestrador | `make up` + `make airbyte-up` + `make airflow-up` |
| Ajustar o gerador | `make up` apenas — ou nada, com `DRY_RUN=1` |
| Trabalhar no streaming | `make up` + `make stream-up` |
| Execução completa de validação | Tudo simultaneamente — apenas na Etapa 12 |

---

## 6. Solução de problemas

Preenchido com os problemas **realmente encontrados**, e não com hipóteses — princípio **P5**.

### `make size-report` acusa tamanho maior do que a carga justifica

Uma carga que falha no meio deixa tuplas mortas: o `COPY` desfaz a transação, mas o espaço só volta
com `VACUUM`. Uma execução seguinte escreve por cima disso, e o relatório soma as duas. Foi o que
aconteceu na primeira medição da Etapa 4 — 86 MB onde havia 55.

`make seed-data FORCE=1` trunca antes de carregar, e `TRUNCATE` devolve o espaço na hora. Para uma
medição que vá para documento, comece do zero:

```bash
make reset FORCE=1 && make up && make migrate && make seed-data
```

### A sincronização do Airbyte fica `running` para sempre e não move linha

Sintoma: `make sync-airbyte` imprime `running · 0 linhas` indefinidamente, a interface mostra o job
ativo, e `raw` continua vazio.

Diagnóstico:

```bash
docker exec airbyte-abctl-control-plane \
  kubectl get pods -n airbyte-abctl | grep replication
```

`Pending` com o evento `Insufficient cpu` é o caso: o *pod* de replicação pede **4 CPUs** — 2 para o
orquestrador e 1 para cada conector —, e a plataforma já segura 1,1 dos 4 da máquina. O Kubernetes
não agenda, o Airbyte não avisa, e o job fica vivo sem executar.

**Solução:** `make airbyte-up`, que passa [`airbyte/values.yaml`](../airbyte/values.yaml) ao
`abctl`. Ele fixa `global.workloads.resources` com pedidos de 100m por contêiner, e o *pod* passa a
pedir 300m em vez de 4 CPUs.

Três caminhos **não** funcionam, e estão registrados no próprio `values.yaml` para não serem
tentados de novo: `--low-resource-mode`, que é a resposta documentada do Airbyte;
`global.jobs.resources`, que o chart marca como depreciada com a ressalva "replication is not
consumed"; e alterar o ConfigMap à mão, que a instalação seguinte desfaz.

### Regerei os dados e o `raw` continua com o conteúdo antigo

Sintoma: `make seed-data FORCE=1` recarrega a origem, `make sync-airbyte` diz "concluída" com poucas
linhas, e o datamart continua mostrando o dado anterior.

É consequência direta da geração ser **determinística**. A mesma `seed` produz os mesmos
`updated_at`, e `updated_at` é o cursor das oito tabelas em `dedup_history`
([ADR-0015](adr/0015-sincronizacao-e-exclusoes.md)): o Airbyte olha para o cursor, não vê nada mais
recente e não traz nada. O conteúdo mudou; o carimbo, não.

É o mesmo defeito que em produção se chama "alguém alterou a linha sem tocar no `updated_at`" — só
que aqui ele é produzido pela reprodutibilidade, que é uma virtude. Depois de **regerar** os dados,
descarte o cursor:

```bash
make sync-airbyte RESET=1
```

`RESET=1` apaga o estado do cursor e o conteúdo de `raw` antes de sincronizar. Não é preciso em
operação normal, quando cada alteração da origem move o seu próprio `updated_at`.

### A DAG foi disparada, o Airflow diz `queued`, e nada acontece

DAG nasce **pausada** no Airflow, e execução enfileirada em DAG pausada fica `queued` para sempre —
o disparo "funciona" e não faz nada. `make dag-run` despausa antes de disparar, e espera a DAG ser
registrada: logo depois de um `make airflow-up` ela ainda não existe no banco de metadados.

Se acontecer mesmo assim, confirme com `airflow dags list` que a coluna `is_paused` está em `False`.

### `Permission denied` ou `Connection refused` nas tarefas da DAG

Dois erros que apareceram construindo, com causas diferentes e não óbvias:

- **`Permission denied: '/opt/mvp_ed1/.env'`** — o contêiner não monta o repositório inteiro, só os
  diretórios de que precisa. O `.env` fica de fora **por desenho**: least privilege, e ele tem
  permissão 600 de outro usuário. Se aparecer, alguém acrescentou uma montagem ampla demais.
- **`httpx.ConnectError: Connection refused`** — no Airflow 3 a tarefa não fala com o banco de
  metadados: fala com o *api-server* pela API de execução. O padrão aponta para `localhost:8080`,
  que dentro do contêiner do *scheduler* não é ninguém. O compose declara
  `AIRFLOW__CORE__EXECUTION_API_SERVER_URL`; sem ela, toda tarefa morre sem dizer que era isso.

### Regerei os dados e o datamart continua mostrando o conteúdo antigo

Depois de `make sync-airbyte RESET=1` o `raw` está certo, mas a dimensão continua errada. A causa é
o **histórico SCD**: o `dbt snapshot` guarda versões, e regerar a origem não apaga o que ele já
guardou — ele passa a ser história de um dado que não existe mais.

Pior, ele acerta ao errar: a venda de 2024 aponta corretamente para a versão que valia em 2024, e
essa versão tem o conteúdo anterior. O modelo está certo; a premissa é que mudou.

```bash
make dbt-build RESET=1
```

`RESET=1` descarta o schema `snapshots` antes de construir, e o histórico é refeito do zero. **Só
em desenvolvimento**: em operação, o histórico é o ativo, e descartá-lo é perda de dado.

A sequência completa depois de regerar a origem é:

```bash
make seed-data FORCE=1 && make sync-airbyte RESET=1 && make dbt-build RESET=1
```

### A sincronização falha com "cannot drop table because other objects depend on it"

O modo `full_refresh_overwrite` **derruba** a tabela de destino a cada carga, e as views de
`staging` dependem dela. A primeira sincronização passa; a segunda falha.

O tratamento está no Terraform do destino: `drop_cascade = true`. O que ele apaga são as views que
o `dbt build` recria em seguida, não dado — o `raw` é declarado descartável pelo
[ADR-0008](adr/0008-schemas-do-armazem.md), e a fonte da verdade é `oltp`.

**A consequência precisa ser dita:** a ordem `sync-airbyte` → `dbt-build` deixa de ser preferência e
passa a ser obrigatória. Entre as duas, as views de `staging` não existem. É uma das razões de o
[ADR-0003](adr/0003-stack-airbyte-dbt-airflow.md) ter ido buscar um orquestrador.

### `make seed-data` recusa executar

Mensagem `N tabelas já contêm dados`. É o comportamento pretendido — ver
[seção 3.1](#31-parâmetros-do-gerador). Use `FORCE=1` se realmente quiser descartar a carga atual.
