# ADR-0003 — Adotar Airbyte, dbt e Airflow desde a fase local

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisões pendentes resolvidas | D06 (transformação), D07 (testes), D08 (orquestração) e a escolha da ferramenta de ingestão |

## Contexto

O projeto precisa de ingestão, transformação e orquestração. Havia duas filosofias possíveis:
começar com scripts próprios e adotar ferramentas depois, ou adotar desde o início as ferramentas
que serão usadas na nuvem.

O fator decisivo é o princípio **P4** (paridade local ↔ GCP) somado ao objetivo de aprendizado
declarado pelo Owner: o valor do MVP está em exercitar as ferramentas reais do mercado, não em
reimplementá-las.

## Alternativas consideradas

| Papel | Alternativas | Por que a escolhida venceu |
|---|---|---|
| Ingestão | **Airbyte** · extratores Python próprios · `pg_dump`/COPY | Conectores, controle de estado incremental e metadados de sincronização prontos; mesmo produto disponível na nuvem |
| Transformação | **dbt** · SQL puro versionado · Python + SQL | Traz junto testes, documentação e linhagem — três entregas do Termo em uma ferramenta; roda igual em PostgreSQL e BigQuery |
| Orquestração | **Airflow** · `make`/CLI própria · orquestrador leve | Dependências explícitas, reexecução parcial e histórico; é o padrão que a fase GCP terá de qualquer forma |
| Testes de dados | **dbt + `dbt-expectations`** · framework dedicado · asserts em Python | Testes ficam ao lado do modelo que verificam; o pacote cobre as regras que os testes nativos não alcançam |

O contra-argumento sério ao Airbyte local é o **consumo de memória**. Foi avaliada a alternativa de
gerar conectores de extração próprios em Python, com bibliotecas leves como `DuckDB` ou `pandas`,
apenas para a fase local, substituindo-os por serviços gerenciados na nuvem. Ela foi **rejeitada**
porque cria dois caminhos de ingestão diferentes entre as fases — o oposto do princípio **P4** — e
retira do MVP justamente a prática de operar uma ferramenta de ingestão real.

## Decisão

**Airbyte** para ingestão, **dbt** para transformação, testes, documentação e linhagem, e
**Airflow** para orquestração, desde a fase local. Testes de dados com dbt e `dbt-expectations`;
`pytest` para o código Python.

O `Makefile` permanece como interface de operação — ele **chama** as ferramentas, não as substitui.

## Consequências

- **Positivas:** o que for construído localmente migra por configuração, não por reescrita;
  catálogo, linhagem e testes nascem do mesmo artefato que define o modelo; o repositório demonstra
  operação de ferramentas de mercado.
- **Negativas:** o ambiente local fica pesado — risco **R11**. Mitigação: os alvos do `Makefile`
  sobem apenas o subconjunto necessário a cada etapa, e o perfil `smoke` mantém o volume baixo
  durante o desenvolvimento. Há também curva de aprendizado nas três ferramentas, absorvida ao
  longo dos cortes verticais.
- **Paridade com o GCP:** dbt roda nas duas fases com adaptação de dialeto; Airflow precisa de
  serviço de execução na nuvem (**D22**); a viabilidade do Airbyte no GCP é avaliada na Etapa 13
  (**D11**).
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md),
  [Qualidade de Dados](../qualidade_de_dados.md), [Execução Local](../execucao_local.md),
  [Registro de Riscos](../riscos.md).
