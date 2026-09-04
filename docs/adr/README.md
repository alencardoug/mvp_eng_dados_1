# Registro de Decisões (ADR)

> **O que vive aqui:** as decisões do projeto — as tomadas (um arquivo ADR cada) e as ainda
> abertas, quando houver (seção 3).
>
> **O que não vive aqui:** a arquitetura resultante (ver [Arquitetura](../arquitetura.md)) e a
> ordem de execução (ver [Plano de Desenvolvimento](../plano_de_desenvolvimento.md)).

Um **ADR** registra uma decisão relevante, o contexto que a motivou, as alternativas consideradas e
as consequências aceitas. O objetivo não é documentar o que foi feito, e sim **por que** — de modo
que a decisão possa ser revista com conhecimento de causa, inclusive na replicação para o GCP.

---

## 1. Como funciona

1. Enquanto a escolha está aberta, ela é uma **decisão pendente** (`Dnn`) na tabela da seção 3.
2. Quando é decidida, nasce um arquivo `NNNN-titulo-em-kebab-case.md` a partir do
   [`0000-template.md`](0000-template.md), e a pendência sai da tabela.
3. Um ADR aceito **nunca é apagado nem reescrito**. Se for revertido, passa a `Substituída` e o
   novo ADR referencia o anterior.
4. Toda *mudança relevante*, no sentido do [Termo de Abertura](../../Abertura_de_projeto.md), exige
   um ADR.
5. Todo ADR declara a sua **contrapartida na fase GCP**. Decisão sem equivalente na nuvem não é
   aceitável (princípio **P4**).

A numeração `Dnn` é sequencial mas **não é densa**: uma lacuna não significa decisão perdida.
**D19** nunca existiu — verificado em 03/09/2026 contra todas as revisões do repositório — e o
identificador não será reaproveitado, para que nenhuma referência antiga passe a apontar para outra
decisão.

**Estados:** `Proposta` · `Aceita` · `Rejeitada` · `Substituída`

---

## 2. Decisões registradas

| ADR | Título | Estado | Resolve |
|---|---|---|---|
| [0001](0001-registrar-decisoes-em-adr.md) | Registrar decisões de arquitetura em ADR | Aceita | — |
| [0002](0002-dominio-marketplace-omnichannel.md) | Adotar um marketplace de varejo *omnichannel* como domínio | Aceita | D01 |
| [0003](0003-stack-airbyte-dbt-airflow.md) | Adotar Airbyte, dbt e Airflow desde a fase local | Aceita | D06, D07, D08 |
| [0004](0004-terraform-como-iac.md) | Usar Terraform para levar o ambiente local ao GCP | Aceita | D12 |
| [0005](0005-geracao-com-faker-orientada-a-configuracao.md) | Gerar dados com Faker por meio de um motor orientado a configuração | Aceita | D05 |
| [0006](0006-streaming-de-estoque-com-cdc-e-beam.md) | Incluir um fluxo de streaming de estoque com CDC e Apache Beam | Aceita | Mecanismo de baixa latência |
| [0007](0007-catalogo-como-codigo.md) | Manter o catálogo de dados como código | Aceita | Ferramenta de catálogo local |
| [0008](0008-schemas-do-armazem.md) | Fixar os schemas do armazém e separar estágio de schema | Aceita | D02 |
| [0009](0009-sqlalchemy-para-acesso-a-dados.md) | Usar SQLAlchemy para o acesso a dados em Python | Aceita | D03 |
| [0010](0010-alembic-para-migracoes.md) | Usar Alembic para as migrações de schema | Aceita | D04 |
| [0011](0011-classificacao-e-papeis-de-acesso.md) | Fixar os níveis de classificação e os papéis de acesso | Aceita | D09 |
| [0012](0012-repositorio-com-pacote-instalavel.md) | Organizar o repositório com `src/` como pacote instalável | Aceita | D10 |
| [0013](0013-nomenclatura-por-prefixo-de-tipo.md) | Nomear objetos de banco com prefixo por tipo | Aceita | D13 |
| [0014](0014-volume-por-proporcoes-e-fator-de-escala.md) | Parametrizar o volume por proporções e fator de escala | Aceita | D26 |
| [0015](0015-sincronizacao-e-exclusoes.md) | Fixar o critério de sincronização e o tratamento de exclusões | Aceita | D20, D21 |
| [0016](0016-materializacao-por-camada.md) | Materializar por camada, com incremental como exceção justificada | Aceita | D23 |
| [0017](0017-chaves-substitutas-e-scd.md) | Derivar chaves substitutas por hash e historizar com snapshots | Aceita | D25 |
| [0018](0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md) | Derivar fatos e views de consumo das perguntas de negócio | Aceita | D24, D27 |
| [0019](0019-saldo-em-deltas-com-entrega-idempotente.md) | Manter o saldo de estoque como deltas imutáveis, com entrega idempotente | Aceita | D16, D17, D18 |
| [0020](0020-debezium-sobre-kafka-connect.md) | Implantar o Debezium sobre Kafka Connect | Aceita | D29 |
| [0021](0021-procedencia-no-empilhamento.md) | Carregar a procedência em coluna própria no empilhamento | Aceita | D15 |
| [0022](0022-catalogo-declarativo-de-falhas-do-legado.md) | Declarar as falhas do legado em catálogo único | Aceita | D28 |
| [0023](0023-escopo-do-schema-governance.md) | Restringir o schema `governance` a controle e auditoria | Aceita | D14 |
| [0024](0024-airbyte-e-airflow-no-gcp.md) | Replicar Airbyte e Airflow no GCP preservando a paridade | Aceita | D11, D22 |
| [0025](0025-policy-tags-por-fluxo-automatizado.md) | Aplicar as policy tags por fluxo automatizado | Aceita | Q1 |
| [0026](0026-uv-para-ambiente-e-dependencias.md) | Adotar `uv` para o ambiente e as dependências Python | Aceita | Ambiente e interpretador Python |
| [0027](0027-configuracao-do-gerador-em-yaml.md) | Declarar o gerador em YAML, com o piso derivado dos modelos | Aceita | Formato e piso da configuração |
| [0028](0028-fato-de-carrinho-para-o-funil.md) | Acrescentar uma fato de carrinho para o funil de conversão | Aceita | Lacuna do funil de conversão |

---

## 3. Decisões pendentes

| # | Questão | Onde trava | Levantada em |
|---|---|---|---|
| **D31** | O Airbyte OSS não agenda replicação em máquina de 4 CPUs. Como a ingestão segue? | Etapa 5 — **bloqueia a etapa inteira** | 04/09/2026 |
| **D30** | Exclusão lógica: `staging` **filtra** a linha excluída, ou **carrega a marca** até o datamart? | Etapa 5 — `trusted` e as dimensões | 04/09/2026 |

### D31 — o Airbyte não cabe nesta máquina

Fato medido, não hipótese: o *pod* de replicação do Airbyte 2.2.0 pede **4 CPUs** (2 orquestrador +
1 por conector) e a máquina tem 4, com 1,1 já reservado pela plataforma. O Kubernetes responde
`Insufficient cpu`, o job fica `Pending` e a interface mostra "running" — falha silenciosa.

Três remédios foram tentados e **nenhum** alterou o pedido do *pod*: `--low-resource-mode`, que é a
resposta documentada do Airbyte para máquina apertada; as variáveis genéricas
`JOB_MAIN_CONTAINER_CPU_REQUEST` e `REPLICATION_ORCHESTRATOR_CPU_REQUEST`; e
`CONNECTOR_SPECIFIC_RESOURCE_DEFAULTS_ENABLED=false`. O resto da ingestão **funciona**: a conexão
com a origem, a descoberta de schema e a verificação do destino passam.

Isto atinge a premissa do [ADR-0003](0003-stack-airbyte-dbt-airflow.md), que escolheu o Airbyte
sabendo que ele é pesado e mitigou o custo com "subir apenas o subconjunto necessário" — mitigação
que não ajuda quando **um único job excede a máquina inteira**.

As saídas, para o Owner escolher:

| Saída | O que custa |
|---|---|
| Máquina com mais CPUs para a fase local | Nada muda no projeto; muda o pré-requisito de hardware, que passa a ser 8 CPUs e precisa ser dito no documento de Execução Local |
| Continuar procurando o parâmetro que reduz o pedido | Pode não existir na versão 2.2.0; já custou uma sessão |
| Fixar uma versão anterior do Airbyte, que usava `docker-compose` | Volta a um caminho descontinuado pelo próprio Airbyte, sem correção nem atualização |
| Reabrir o ADR-0003 na parte de ingestão | Recusado uma vez com argumento que continua válido — dois caminhos de ingestão entre as fases, contra o **P4** |

### D30 — as duas leituras do ADR-0015

O [ADR-0015](0015-sincronizacao-e-exclusoes.md) diz as duas coisas, em seções diferentes, e a
implementação da Etapa 5 obrigou a escolher:

- a **Decisão** diz que `deleted_at` "é preenchido e o incremental **o propaga até o datamart**" —
  o que só faz sentido se o datamart souber da exclusão, isto é, se ela viajar como marca;
- as **Consequências** dizem que "todo modelo de `staging` precisa **filtrá-la**".

Não é detalhe de estilo. Filtrar em `staging` faz um SKU excluído sumir de `dim_product`, e o
pedido histórico que o comprou passa a apontar para uma dimensão que não existe mais — o dado de
ontem muda porque o cadastro mudou hoje. Carregar a marca mantém o *join* e deixa a exclusão
visível como atributo, ao custo de todo modelo adiante precisar decidir se filtra.

**O estado atual do código** é a leitura da *Decisão*: `staging` expõe `is_deleted` e não filtra.
É reversível — o que muda com a resposta é `trusted` e as dimensões, ainda não escritos.

O procedimento — registrar como pendência, devolver ao Owner, e só então implementar — está na
seção 1.
