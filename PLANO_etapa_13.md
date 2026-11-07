# Plano — Etapa 13: replicação no GCP com Terraform (M6)

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item, como o plano da Etapa 12 saiu. Escrito em 06/11/2026 sobre `8309b66`
> (`main`, `v1.1.0` aceita), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: **[medido]** tem saída de comando ou página oficial lida por trás;
> **[planejado]** é intenção; **[estimado]** é número que ninguém mediu. Não se misturam (P5).
>
> **Revisão 1 — 06/11/2026.** Primeira versão.
>
> **Revisão 2 — 07/11/2026.** Aplica a rodada 1 do Codex (`REVISAO.md`: nove bloqueantes, dois
> ajustes, RV13-1-01…11) e as decisões do Owner de 07/11: **escopo inteiro mantido** depois do
> parecer, D69 = Debezium Server → Pub/Sub, D70, D71 = o dbt aplica as *tags*, D72, D73, D74. O que
> mudou de forma: o desmonte ganhou **relógio de emergência** independente do `destroy` (RV13-1-01)
> e ordem com ação por resíduo (RV13-1-02); o desenvolvimento foi **redimensionado pela medição**
> do Codex e dividido em portas de prontidão antes da janela (RV13-1-03); o legado, o caminho
> quente e a DAG ganharam contrato inteiro, não só a escrita (RV13-1-04…06); o catálogo entra
> como trabalho de dialeto (RV13-1-07); as *tags* têm ciclo por produtor (RV13-1-08); *authorized
> views* e Secret Manager ganharam bloco (RV13-1-09); a prova separa exercício de teste vazio e o
> aceite tem portão formal (RV13-1-10); a estimativa por serviço vem **antes** do `apply`
> (RV13-1-11). E a janela cara **mudou de dia** — quarta e quinta de manhã, não terça e quarta —,
> para dar ao desenvolvimento o dia que a medição mostrou faltar. A *Situação* de cada achado está
> no `REVISAO.md`.
>
> **Revisão 3 — 07/11/2026.** Aplica a rodada 2 (RV13-2-01…05: um bloqueante, três ajustes, uma
> observação). O contrato da D75 passa a exigir exclusão por chave sob concorrência e a prova de dois
> lotes simultâneos (RV13-2-01); as portas separam falha funcional de pré-requisito de `apply`
> (RV13-2-02); a parte cara termina quarta 22:00, e a janela total vai de terça 08:00 a quinta
> 12:00 (RV13-2-03); o mapa de paridade reflete a D70 e o destino da D75 (RV13-2-04); o GKE é zonal,
> com dois nós no total (RV13-2-05).

---

## 0. O prazo manda

A Etapa 13 foi **autorizada pelo Owner em 06/11/2026**. A conta GCP está em **Free Trial, não
convertida**: em 06/11, **R$ 1.740,37 de crédito e 9 dias restantes** — o fim real é por volta de
15/11. O Owner fixou **sete dias**, preventivamente. Falhar no desmonte é falhar no projeto.

As regras que se sobrepõem a qualquer outra coisa neste plano:

1. **Nada cobrável de pé depois de quinta-feira, 12/11/2026, 18:00 (America/Sao_Paulo).** Sexta,
   13/11, é folga, não janela.
2. **O relógio de emergência é independente do `destroy`** (§6.4): quinta **12:00** o faturamento
   do projeto é desligado **haja o que houver**; **15:00** o projeto é apagado, com o Owner.
3. **Encurta-se o escopo, nunca a margem.** O que não estiver pronto numa porta (§6.2) vira
   pendência registrada; a janela cara não se estende. **Critério de M6 que ficar pendente deixa
   o M6 incompleto: sem aceite e sem *tag* `v2.0.0`** — o desmonte acontece do mesmo jeito.
4. **O taxímetro sobe por degrau de preço.** BigQuery, Cloud Storage, Pub/Sub, IAM e taxonomias
   (centavos) nascem no sábado; Cloud SQL (barato) na segunda; GKE com Airbyte e Debezium
   (médio) na terça, para integração; **Composer e Dataflow só na janela**, quarta.

O que a Free Trial muda **[medido, 06/11/2026]**:

| Fato | Fonte | Efeito no plano |
|---|---|---|
| Sem aumento de cota; sem GPU, Windows, Marketplace | [free-cloud-features](https://docs.cloud.google.com/free/docs/free-cloud-features) | Airbyte por Helm, não Marketplace; o dimensionamento cabe na cota que existe |
| Cota `CPUS_ALL_REGIONS` = 32 e `IN_USE_ADDRESSES` = 8 **em outro projeto** da conta | `gcloud compute project-info describe --project analisador-de-risco` | **não prova** a cota do projeto novo: lida no G0, e o dimensionamento da §8 é conferido contra ela |
| Fim da avaliação: recursos parados, 30 dias de carência, depois apagados | idem | rede de segurança contra cobrança, **não** é o desmonte |
| O crédito não paga a API do Gemini | idem | o Gemini como verificador não consome o crédito |
| Nove projetos na mesma conta de faturamento, um deles o `bi-como-codigo`, com recursos de 06/11 | `gcloud projects list`; `~/Projetos/_gcp_resources_20261106_bi_como_codigo/` | o crédito é da conta; os outros projetos **não** entram no desmonte deste plano, mas o fim da avaliação os atinge também — fica registrado para o Owner |

---

## 1. Escopo

**Todos os critérios de conclusão da Etapa 13** no
[plano](docs/plano_de_desenvolvimento.md#etapa-13--replicação-no-gcp-com-terraform--m6) — decisão do
Owner de 06/11, **reafirmada em 07/11** depois do parecer da rodada 1.

| Critério | Bloco | Prova |
|---|---|---|
| Todo item do [mapa de paridade](docs/arquitetura.md#5-mapa-de-paridade-local--gcp) com equivalente provisionado | G0–G6; a matriz da §7.1 | uma linha de evidência por linha do mapa |
| `terraform plan` revisado antes de cada `apply` | G3 | rito da §6.3 |
| Particionamento, *clustering*, retenção e políticas definidos antes do provisionamento | G1 (fatos), G3 (*datasets*, *buckets*) | revisão do declarativo antes do `apply` |
| *Policy tag* em cada coluna sensível pelo fluxo automatizado, acesso negado, sem credencial longeva | G4 | inventário de **todas** as colunas sensíveis × YAML, depois de cada operação que recria objeto (§7.3) |
| Composer e Airbyte criados e destruídos na mesma janela, custo estimado e real | G3, G6, G7 | a **janela total** vai de terça 10, 08:00 (GKE com Airbyte) a quinta 12, 12:00 (faturamento desligado), e a **parte cara** — Composer e Dataflow — de quarta 07:00 a 22:00; estimativa por serviço e duração aprovada antes do `apply` (G0); duração real de cada serviço registrada; custo real conciliado depois (G8) |
| *Batch* e *streaming* juntos, tamanho/tempo/custo, `caminhos_de_ingestao_reconciliam` | G2, G6 | §7.2 |
| Paridade funcional com a fase local | G6 | §7 |
| Metadados no Dataplex; estimativa de custo por serviço | G5; G0 | §7.4; a estimativa na [Capacidade](docs/capacidade_e_recuperacao.md) antes do primeiro `apply` cobrável |

**Fora:** o alto volume (D68), a operação continuada e o CI/CD além do fluxo das *policy tags*
([Termo](Abertura_de_projeto.md) §4), e a **recuperação pelo pacote** (`make recovery-*`), que não
tem linha no mapa. **Dentro**, porque a DAG chama em toda execução e o ADR-0050 exige: a
recuperação da captura (`capture_recovery.recover`) e o livro retido.

---

## 2. Decisões

### 2.1 Tomadas em 06/11/2026

- **Autorização da Etapa 13** — Termo v1.3 §11, plano, Pendências.
- **D68 — fase GCP no fator `dev`** — Pendências §2; notas no ADR-0014 e no ADR-0016.
- **Escopo inteiro; revisões em rodadas com prazo** (o plano até domingo, 08/11; uma rodada no
  `plan` caro). Achado bloqueante sempre para tudo.
- **Gemini como verificador de fatos; Codex como revisor do plano contra o repositório.**

### 2.2 Tomadas em 07/11/2026, sobre a rodada 1

- **Escopo inteiro reafirmado.** O Owner preferiu manter todos os critérios até 12/11 a uma janela
  parcial com segunda janela paga depois. Consequência registrada na regra 3 do §0.
- **D69 — o caminho quente chega ao Pub/Sub pelo Debezium Server** (*sink* `pubsub`), num *pod* do
  mesmo GKE do Airbyte; o Beam no Dataflow lê com `ReadFromPubSub`. Sai o Datastream do mapa.
  [ADR-0051](docs/adr/0051-cdc-da-fase-gcp-pelo-debezium-server.md), que fixa a garantia do
  ADR-0019 — idempotência por `movement_id`, alerta só do evento que entrou — através da troca.
- **D70 — retenção sem trava no *bucket* do livro retido**, removida no desmonte antes de
  esvaziar o *bucket*. A trava do ADR-0050 fica declarada como contrapartida de produção, **não
  medida**; nota datada no ADR-0050.
- **D71 — o dbt aplica as *policy tags*** pela propriedade de coluna `policy_tags`
  ([dbt — policy tags](https://docs.getdbt.com/reference/resource-configs/bigquery-configs#policy-tags)),
  gerada do mesmo YAML de classificação; o fluxo do ADR-0025 cria e mantém taxonomia e *tags* e
  **converge as tabelas que o dbt não materializa** (G4). Motivo, confirmado: substituir uma tabela
  apaga "all existing policy tags on the original table"
  ([column-level-security](https://docs.cloud.google.com/bigquery/docs/column-level-security-intro)).
  Nota datada no ADR-0025.
- **D72 — Airbyte → BigQuery por *Batched Standard Inserts*** com a identidade do *pod*, sem
  `credentials_json` e sem HMAC. A combinação *chart* + *pod* de *job* + Workload Identity não está
  documentada: é **porta de integração** na terça (§6.2), não premissa.
- **D73 — `us-central1`**; **Composer 3** `composer-3-airflow-3.2.2-build.9` (Airflow 3 GA no
  Composer desde 15/04/2026; o *build* é de 20/10 —
  [release notes](https://docs.cloud.google.com/composer/docs/release-notes)), ambiente *small*;
  **GKE Standard zonal** (`us-central1-a`) com um *pool* de 2 nós **no total**; *chart* do Airbyte `2.3.0`, o mesmo de
  `AIRBYTE_CHART_VERSION`.
- **D74 — projeto dedicado, estado local do Terraform, desmonte em três camadas com relógio de
  emergência** (§6.4).

### 2.3 Ainda abertas, para decidir no bloco indicado

- **D43** — a guarda de identidade: medida no G1 nas **três** noções de "mesma chave" da
  [Pendência](docs/pendencias.md) (igualdade textual em `classification.sql`, `identidade_canonica`
  e `chave_canonica`), com as formas de `tests/test_legado_remocao.py:237–252`; o Owner decide com o
  número, depois da janela. Até lá, **não se declara paridade de identidade**.
- **D75 — a idempotência do *sink* no BigQuery** (G2.3, ADR-0051): o PostgreSQL usa `on conflict
  (movement_id) do nothing returning` para emitir alerta **só** do evento que entrou. O BigQuery não
  tem `returning`. Proposta: *script* com transação por lote — inserir numa tabela de passagem,
  `MERGE` pela chave, e devolver os `movement_id` que não existiam antes do `MERGE`; *insertId* e a
  deduplicação do Dataflow **não** contam como garantia (ADR-0051). **Contrato que o mecanismo tem
  de cumprir** (RV13-2-01): (i) duas decisões concorrentes de inserir a mesma chave não podem as
  duas vencer — transações do BigQuery que só leem e acrescentam **rodam em paralelo**
  ([transactions](https://docs.cloud.google.com/bigquery/docs/transactions#transaction_concurrency)),
  então a transação sozinha não é exclusão mútua: o mecanismo precisa serializar por chave (por
  exemplo, a escrita agrupada por `movement_id` num passo com estado do Beam, um escritor por chave)
  ou detectar o conflito e reexecutar; (ii) conflito e reexecução tratados sem emitir alerta duas
  vezes; (iii) o resultado de um *job* cujo retorno se perdeu é recuperado pelo identificador do
  *job*, sem reenviar às cegas. O mecanismo é escolhido e provado no G2.3 e registrado no
  *Streaming*; a garantia não está em aberto, só o meio.

---

## 3. Achados de abertura (06/11/2026)

Os quatro da revisão 1, agora resolvidos por decisão: o Datastream não entrega em Pub/Sub (D69);
a retenção travada põe *lien* no projeto e impede apagá-lo
([bucket-lock](https://docs.cloud.google.com/storage/docs/bucket-lock)) (D70); o modo recomendado
do destino BigQuery do Airbyte exige HMAC (D72); `create or replace` apaga *policy tags* —
**confirmado** (D71).

---

## 4. O tamanho do desenvolvimento [medido pelo Codex, 07/11/2026]

A revisão 1 dizia que a conversão do dbt era "a maior parte `::`". **Errado.** Dos 106 modelos com
sintaxe só do PostgreSQL, só 4 a 8 (conforme o classificador) se resumem a *cast*; os demais têm
JSON, *regex*, calendário e fuso, `extract(epoch …)` e agregações. **81 dos 106 são gerados** por
`src/mvp_ed1/legacy/` (`dbt.py`, `regras.py`, `classification.py`, `classification.sql`) — o
trabalho é no **gerador**, com regeneração determinística para os dois alvos, nunca no SQL gerado.
Sete macros emitem SQL do PostgreSQL (`chave_canonica`, `identidade_canonica`,
`dias_no_calendario`, `snapshot_get_time`, `explicado_pela_quarentena`,
`test_fato_reconcilia_com_a_condutora`, `vigencias_sem_sobreposicao`); duas já se desligam fora
dele (`aplicar_acesso_por_camada`, `analisar_apos_materializar`).

No Python, o que muda para BigQuery, Cloud Storage, Cloud SQL e Pub/Sub — cada um com
`arquivo:linha` no `REVISAO.md`: a captura do legado (leitura e escrita), a recuperação, o livro,
a guarda de identidade do Airbyte, o DDL da governança, o catálogo (`models/sensitivity.py`
analisa o SQL com `read="postgres"`), e o *streaming* inteiro (fonte, *sink*, semeadura, alerta).

**Ninguém mediu horas.** O cronograma da §6.1 é estimativa do autor. O que o torna administrável
não é o número, é a porta: cada bloco tem prova **antes** da janela, e a porta de terça, 20:00,
decide o que entra nela.

---

## 5. Os blocos

### G0 — fundação (sábado, 07/11)

Projeto dedicado `mvp-ed1-gcp-<sufixo>` ligado à conta da avaliação; **conferências do Owner
na consola, antes de qualquer outro recurso**: permissão de desligar o faturamento do projeto
(`billing.resourceAssociations.delete`), vínculo não travado e nenhum *lien* (`gcloud alpha
resource-manager liens list`); cota do projeto lida. Orçamento com alertas em US$ 25, 50 e 75 —
recurso da **conta** de faturamento, que o `delete` do projeto não remove (G7). APIs. ADC do Owner
(`gcloud auth application-default login`, passo dele). Esqueleto de `terraform/` (módulos
`fundacao`, `rede`, `iam`, `segredos`, `bigquery`, `storage`, `cloud_sql`, `pubsub`, `gke`,
`airbyte`, `debezium`, `composer`, `dataflow`, `governanca`), alvos `make gcp-*` com *preflight*
que recusa sem o projeto certo no ambiente. **A estimativa por serviço** (serviço, região,
configuração, duração prevista, fonte de preço com data) entra na
[Capacidade](docs/capacidade_e_recuperacao.md) **antes** do primeiro `apply` cobrável (RV13-1-11).
**Prova:** `plan` do `fundacao` limpo; cota e permissões lidas e coladas.

### G1 — dbt em dois alvos (sábado a terça)

1. **Geradores do legado** (`legacy/dbt.py`, `regras.py`, `classification.py`,
   `classification.sql`) emitindo os dois dialetos; os 81 modelos gerados regenerados para os dois
   alvos e conferidos pela regeneração determinística que já existe (`make legacy-models`).
2. **As sete macros** com `adapter.dispatch`; a de vigência com o fuso escrito, sem literal
   `timestamptz` implícito.
3. **Os ~25 modelos escritos à mão**, os 4 *snapshots*, os 34 testes singulares e os contratos.
4. Alvo `gcp` em `dbt/profiles.yml` (BigQuery, ADC/OAuth, sem chave); nove *datasets* pelo
   `generate_schema_name`; `partition_by`/`cluster_by` nas fatos só no alvo `gcp`; `+grants`
   traduzido; `persist_docs` por coluna (pré-requisito do `policy_tags`, D71).
5. ***Authorized views*** (RV13-1-09): as views de `consumption` autorizadas nos *datasets* que
   leem, por `grant_access_to` — mecanismo distinto do `+grants`
   ([dbt — authorized views](https://docs.getdbt.com/reference/resource-configs/bigquery-configs#authorized-views)).
6. **D43 medida** nas três identidades (§2.3).

**Carga de desenvolvimento:** o bruto do armazém local copiado para o BigQuery, para o dbt ter o
que transformar até o Airbyte do GKE existir. Ferramenta de desenvolvimento, **não é evidência**;
os *datasets* dela são apagados antes da janela, e a janela carrega pelo caminho real.

**Prova:** `dbt build --target gcp` verde sobre a carga de desenvolvimento — testes de dados e
reconciliações entre camadas; `make check` local verde (cada modelo mexido passa pelos dois alvos);
o analista lê `consumption` e é **negado** em `analytics`.

### G2 — o Python na nuvem (sábado a terça)

**G2.1 — legado, certificado, recuperação e livro** (RV13-1-04). Contrato de *backend* explícito
para cada chamador da CLI e da DAG: **leitura** do bruto retido e do certificado no BigQuery
(`captura.py`, `capture_recovery.py`, `ledger.py`); **escrita** do certificado em *staging* +
`MERGE` pela chave `(tentativa, tabela)`, com confirmação do *job* do BigQuery **antes** de soltar
os *locks*; **locks** de abertura e por tentativa no Cloud SQL (hoje na mesma transação do
*insert* — separados); **livro** no Cloud Storage com `ifGenerationMatch=0` no lugar do `os.link`;
**DDL da governança** (`governance.py`) no *dataset* `governance`; a **guarda de identidade** do
`airbyte.py`, que abre o armazém **antes** do disparo, lendo do BigQuery. **Época inicial** aberta no
projeto novo (`make ledger-baseline` portado), sem a qual o portão recusa a primeira captura.
**Prova antes da janela:** os casos do ADR-0044/0050 com API simulada (resposta parcial, retorno
perdido, reenvio sem remedir) verdes; na terça, contra Cloud SQL e BigQuery reais: primeira
captura, recuperação de tentativa interrompida, segunda captura, nenhum POST indevido, memória
anterior intacta.

**G2.2 — catálogo** (RV13-1-07). `models/sensitivity.py` com dialeto e tipos lidos do alvo, não
fixos em `postgres`; leitura do *manifest* BigQuery. **Prova:** compilar os dois alvos e comparar o
conjunto de folhas e a classificação de **todas** as colunas — diferença zero, ou cada diferença
explicada; é ela que alimenta as *tags* do G4.

**G2.3 — caminho quente** (RV13-1-05, D69, D75, ADR-0051). Debezium Server com `sink.type=pubsub`,
o mesmo conector de `streaming/connectors/inventory_movements.yml` (`decimal.handling.mode:
string`, *slot* e *publication* homônimos), `schemas.enable=false` fixado para o envelope chegar com
`op/after/source` no topo (`envelope.py:60`), *offsets* num disco persistente do GKE (apagado no
desmonte), autenticação pela identidade do *pod*. No Beam: fonte `ReadFromPubSub` com *ack*
nativo; **semeadura** do saldo lendo o BigQuery (`pipeline.py:160`); **alerta** publicado no
Pub/Sub, não no Kafka (`transport.py:261`); *sink* BigQuery com a idempotência da D75. **Prova antes
da janela** (terça, Pub/Sub e BigQuery reais, Debezium no GKE): *snapshot* e CDC pelo *parser*,
decimal e fuso exatos, reinício do *pod* e do *worker*, o mesmo movimento reenviado dentro e fora da
janela de deduplicação e depois de retorno perdido, **dois lotes concorrentes com a mesma chave
nova** e duplicata dentro do mesmo lote — conferindo unicidade física, saldo e quais eventos foram
ao alerta —, contagem física igual à de eventos, alerta observado. Sem essa prova o caminho quente
não entra na janela, e o critério fica incompleto. D62 e D63 continuam o que são — pendências locais aceitas.

**G2.4 — a DAG no Composer** (RV13-1-06). Layout declarado: `fluxo_batch.py` e o pacote `mvp_ed1`
em `dags/`; o projeto dbt, o glossário que ele referencia e os pacotes dbt em `data/`
(`/home/airflow/gcs/data`); `PROJETO` lido do ambiente, não fixo em `/opt/mvp_ed1`; *target* e *logs*
do dbt num diretório temporário por execução; dependências travadas (`dbt-core 1.12.3`,
`dbt-bigquery`, SQLAlchemy, psycopg, PyYAML) conferidas contra a lista de pacotes da imagem e o
aviso de `google-api-core` das *release notes* de 30/10; *Connections* e *Variables* pelo
*backend* do Secret Manager; rede do Composer até o Cloud SQL (IP privado) e até a API do Airbyte
(*load balancer* interno do GKE). **Prova antes da janela:** a DAG importa e o `dbt` roda no layout
de destino numa imagem local do Composer (ferramenta de desenvolvimento local do Composer, se
suportar a imagem 3 — a conferir; senão, `apache/airflow:3.2.2` com o mesmo layout e as mesmas
versões). **Na janela, antes do fluxo inteiro:** *smoke test* no Composer — importação, uma tarefa
de cada tipo.

### G3 — Terraform (sábado a terça; `apply` em degraus)

Os módulos do G0. Rede com IP privado para o Cloud SQL; **Cloud SQL e GKE com
`deletion_protection = false` no estado**; Cloud SQL sem *backup* retido; *datasets* com retenção e
expiração; todo *bucket* — do livro, de *staging* e *temp* do Beam, do Composer — declarado, com
`force_destroy` e, no do livro, a retenção sem trava da D70; Workload Identity no GKE; Airbyte e
Debezium por `helm_release`; **Secret Manager** (RV13-1-09) com as senhas dos usuários do Cloud SQL
geradas pelo Terraform e lidas em execução pelo Composer (*backend* de segredos) e entregues ao
Airbyte pelo *provider* dele no `apply` — o estado local passa a conter segredos, e é por isso que
fica fora do Git (`.gitignore`) e só em `terraform/` e na cópia em `data/`. Composer por último.
**Prova:** o rito da §6.3 em cada `apply`; rodada do Codex no `plan` caro na terça.

### G4 — *policy tags* (domingo a terça)

Taxonomia e *tags* criadas pelo fluxo do ADR-0025 (`.github/workflows/`, *Workload Identity
Federation* com *attribute condition* no repositório, permissão só de *policy tags*). **Ciclo por
produtor** (D71, RV13-1-08):

| Produtor | Quem aplica | Quando |
|---|---|---|
| Modelos e *snapshots* do dbt | o próprio dbt, `policy_tags` gerado do YAML | a cada *build* |
| Fontes do Airbyte (`raw`, `raw_legacy`) | o fluxo, em modo de convergência | tarefa da DAG logo depois de cada sincronização e antes do dbt; e no disparo por YAML |
| *Sink* do caminho quente, `governance` | o fluxo, em convergência | depois do `apply` e no disparo por YAML |

**Prova:** inventário de **todas** as colunas sensíveis contra o YAML, repetido depois da carga
inicial, de uma nova sincronização, de um *rebuild*/*full refresh* e de uma reclassificação; uma
identidade sem `datacatalog.categoryFineGrainedReader` **negada** e uma com ele permitida, com o
*log* de auditoria das duas; nenhuma chave **`USER_MANAGED`** em conta de serviço alguma (as do
sistema existem por desenho).

### G5 — catálogo e linhagem (segunda a quarta)

Descrições pelo `persist_docs`; `domain`/`owner` como metadado do catálogo; linhagem por coluna do
módulo do [Dicionário §3](docs/dicionario_de_dados.md#3-linhagem) (já portado no G2.2) enviada à
Data Lineage API como eventos OpenLineage — **a aceitação de linhagem por coluna não está
confirmada**: conferir com o Gemini (URL oficial) no sábado; se a API não aceitar, a linha do mapa
fica pendente e é dita assim. **Prova:** linhagem de uma coluna de `consumption` até a origem na
consola, e o número de arestas publicadas igual ao do módulo.

### G6 — a parte cara da janela (quarta 07:00 → 22:00)

O roteiro da §7. Provas até **21:00**; **exportação** do registro de execução e das medições para
`data/medicoes/etapa_13/` até **21:30**; Composer e Dataflow removidos até **22:00**. Nada da
parte cara roda de madrugada.

### G7 — desmonte (quarta 21:30 → quinta 15:00)

A ordem da §6.5 e o relógio da §6.4.

### G8 — documentação e aceite (quinta a sexta, e depois)

O mapa da [Arquitetura §5](docs/arquitetura.md#5-mapa-de-paridade-local--gcp) com o medido (a
captura já corrigida pelo ADR-0051 em 07/11; D70 e D72 nas linhas do livro e da ingestão); dicionário, catálogo e linhagem; capítulo 07 do
`NAVEGANDO_GCP` alinhado; Pendências com o que a Etapa 13 exercitou da V1, por recorte (lote 1 →
G2.1; lote 2 → G1.5 e a guarda de identidade; lote 3 → G2.2 e a macro de vigência). **Portão
formal de aceite** (RV13-1-10): a definição de pronto do [`CLAUDE.md`](CLAUDE.md) §7 inteira —
migrações do zero, cobertura de tabelas e casos de borda, segredos e `.gitignore`, revisão integral
do declarativo **pelo Owner**, distinta da revisão técnica do `plan`. Custo real conciliado por
serviço **depois** de o faturamento estar completo (até dois dias depois do desligamento,
[modify-project](https://docs.cloud.google.com/billing/docs/how-to/modify-project#disable_billing_for_a_project));
na sexta, se ainda incompleto, registrado como **parcial**, e o fechamento econômico fica pendente
— sem estender a vida de recurso nenhum. *Tag* `v2.0.0` (D47) **só** com todos os critérios.

---

## 6. A janela

### 6.1 Cronograma [estimado]

| Quando | O quê | Taxímetro |
|---|---|---|
| sáb 07 | revisão 2 do plano e rodada 2 do Codex; ADR-0051; G0; G1 e G2 começam; BigQuery, GCS e Pub/Sub de desenvolvimento | centavos |
| dom 08 | **revisão do plano encerrada**; G1, G2, G3 e G4 em curso | centavos |
| seg 09 | Cloud SQL de pé (`apply` barato); G2.1 contra Cloud SQL e BigQuery reais; G1 em curso | barato |
| ter 10 | GKE + Airbyte + Debezium de pé; portas de integração (§6.2); rodada do Codex no `plan` caro | médio |
| **ter 10, 20:00** | **porta da janela** (§6.2) | |
| **qua 11, 07:00** | Composer (~25 min para nascer, [create-environments](https://docs.cloud.google.com/composer/docs/composer-3/create-environments)) e Dataflow; *smoke test*; `fluxo_batch` de ponta a ponta; *streaming* simultâneo; as duas capturas da §7.2 | caro |
| **qua 11, 20:00** | **ponto de decisão**: o que não rodou vira pendência; a janela não se estende | |
| qua 11, 21:00–22:00 | provas encerradas, exportação, Composer e Dataflow fora (§6.5 passos 1–2) | caro → médio |
| qui 12, 07:00 | desmonte do restante (§6.5 passos 3–10) | médio → zero |
| **qui 12, 12:00** | **faturamento desligado, haja o que houver** (§6.4) | zero |
| **qui 12, 15:00** | **projeto apagado, com o Owner** | |
| sex 13 | folga; custo parcial; documentação | |

### 6.2 As portas

| Porta | Quando | Passa se | Se não passar |
|---|---|---|---|
| P1 — plano | dom 08, 20:00 | revisão encerrada, sem bloqueante aberto | o bloco do bloqueante **não** começa; o Owner decide entre corrigir a tempo ou cortar o bloco (M6 incompleto) |
| P2 — dialeto | seg 09, 20:00 | `dbt build --target gcp` verde; catálogo comparado (G2.2) | o que falta não entra na janela; pendência |
| P3 — integração | ter 10, 18:00 | Airbyte → BigQuery sem chave (D72); G2.1 real; G2.3 real; DAG importada no layout | idem, por bloco |
| **P4 — janela** | **ter 10, 20:00** | P2 e P3, estimativa aprovada, `plan` caro revisado | **falha funcional** de P2/P3: a janela abre com os blocos que passaram e cujas dependências passaram, e o M6 fica incompleto. **Estimativa não aprovada ou `plan` não revisado: nenhum recurso daquele degrau nasce** — esses dois são pré-requisitos de todo `apply`, não blocos cortáveis |

### 6.3 O rito de cada `apply`

`terraform plan -out` salvo em `data/medicoes/etapa_13/`, lido inteiro (contagem de criar/alterar/
destruir contra o esperado do módulo), aprovado pelo Owner, e só então `apply` do arquivo salvo.
Nenhum `apply` sem `-out`; nenhum `-auto-approve`. Antes de cada `apply` cobrável, a linha da
estimativa daquele degrau já está na Capacidade.

### 6.4 O relógio de emergência (RV13-1-01)

Independe do sucesso de qualquer passo da §6.5. Responsável: o Owner, com o Claude Code operando.

| Hora | Ação | Espera máxima |
|---|---|---|
| qua 11, 22:00 | Composer e Dataflow fora (§6.5 passos 1–2), ou escalada: remoção manual por `gcloud` | 1 h; depois, o Owner pela consola |
| qui 12, 07:00 | início da §6.5 | — |
| qui 12, 11:00 | o que a §6.5 não removeu é anotado e **abandonado** à camada 2 | — |
| **qui 12, 12:00** | `gcloud billing projects unlink`; conferir `billingEnabled: false` e guardar a saída | 30 min; se falhar, o Owner desliga pela consola |
| **qui 12, 15:00** | `gcloud projects delete`, com o Owner; guardar o estado retornado (`DELETE_REQUESTED`) — é pedido de exclusão, não eliminação física instantânea | — |
| qui 12, 18:00 | limite duro | — |

### 6.5 A ordem do desmonte (RV13-1-02)

Cada passo tem ação e prova; a rede, o IAM e as APIs ficam de pé até o último.

1. **Parar quem produz:** pausar a DAG; parar o produtor; **drenar e cancelar o *job* Dataflow**
   (`gcloud dataflow jobs list --status=active` vazio).
2. **Composer** (`destroy` do módulo) e o *bucket* dele, se sobrar.
3. **Debezium Server** (`helm uninstall`), e o *slot* de replicação **removido no Cloud SQL**
   (`pg_drop_replication_slot`) enquanto o Cloud SQL existe.
4. **Airbyte** (`helm uninstall`) com a API do Kubernetes ainda disponível; apagar *Services* do tipo
   *LoadBalancer*, PVCs e PVs — o GKE **retém** discos persistentes ao apagar o *cluster*
   ([deleting-a-cluster](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster)).
5. **GKE** (`destroy`); conferir discos e *forwarding rules* órfãos.
6. **Retenção do *bucket* do livro removida** (D70), depois o `destroy` de todos os *buckets*
   (`force_destroy`), incluindo os do Beam.
7. **Cloud SQL** (`destroy`), conferindo que nenhum *backup* ficou retido.
8. **BigQuery, Pub/Sub, Secret Manager, taxonomias, IAM, rede** (`destroy`).
9. **Inventário de resíduos** (`gcloud asset search-all-resources --scope=projects/<id>`):
   esperado vazio, salvo uma **lista identificada** do que o projeto cria por padrão; cada item fora
   dela tem ação e prova, não só registro.
10. **Orçamento** apagado da conta de faturamento (não sai com o projeto).
11. Camadas 2 e 3 no relógio da §6.4.

---

## 7. Paridade funcional — o que se mede na janela

Com o gerador determinístico (mesma `seed`, mesma `as_of_date`, fator `dev`), nos dois alvos.

### 7.1 A matriz do mapa

Uma linha de evidência por linha da [Arquitetura §5](docs/arquitetura.md#5-mapa-de-paridade-local--gcp),
com o mapa corrigido em 07/11 (D69, D70 e o destino quente idempotente da D75): o que foi provisionado, a consulta ou o *log* que prova, e
`medido`/`não medido` com motivo. Linha sem evidência não conta como paridade.

### 7.2 Dados e memória

- Contagens por camada e reconciliações entre camadas no BigQuery iguais às da fase local na mesma
  geração; os testes do dbt nos dois alvos (PASS comparado); as views de `consumption` com a mesma
  soma de controle por view — comparação de dados normalizados, **com os metadados de execução
  excluídos explicitamente**.
- **Duas capturas do legado** (RV13-1-10): a primeira, uma mudança controlada na origem pelo
  gerador (o diário de mutações da regeneração da v1.1.0), a segunda — com a matriz de resultados
  esperados: a primeira captura preservada, a transição exercitada
  (`legacy_capture_transitions`), a exclusão física detectada (ADR-0045). Uma captura só não
  exercita o intervalo.
- `caminhos_de_ingestao_reconciliam` com *batch* e *streaming* simultâneos; tempo de cada
  sincronização, do `dbt build` e da latência do caminho quente; tamanho por *dataset*.
- Cobertura: toda tabela populada e todo caso de borda representado, como a §7 do `CLAUDE.md` pede
  — não só a contagem de PASS.

### 7.3 Acesso

O analista lê `consumption` e é negado em `analytics`; o inventário de *tags* da §G4; o segredo do
Secret Manager lido **só** pela identidade destinatária.

### 7.4 Catálogo

A linhagem publicada (G5) e as descrições e `domain`/`owner` visíveis.

O que não se medir fica escrito como **não medido**, com o motivo, e conta contra o M6.

---

## 8. Premissas e o não verificado

- A cota do projeto novo e o dimensionamento [estimado]: Cloud SQL 2 vCPU; GKE **zonal**, um *pool* de 2 nós `e2-standard-4` **no total**
  (8 vCPU; um *pool* regional teria 2 por zona, 6 nós e 24 vCPU — RV13-2-05), autoescala desligada; Dataflow 1 *worker*; Composer 3 fora da cota do projeto. Conferido no G0.
- A ferramenta de desenvolvimento local do Composer **suporta** Airflow 3.2.2 desde o *build*.3
  ([run-local-airflow-environments](https://docs.cloud.google.com/composer/docs/composer-3/run-local-airflow-environments));
  instalação, importação e pacotes seguem por provar, e o ensaio respeita o R11.
- Linhagem por coluna: eventos OpenLineage **customizados** materializam arestas por tabela e **não**
  renderizam linhagem por coluna na consola
  ([openlineage-mapping](https://docs.cloud.google.com/knowledge-catalog/docs/openlineage-mapping)).
  Resposta HTTP de sucesso não é prova por coluna; se não houver caminho suportado, a linha do mapa
  fica pendente (G5) e o M6 incompleto.
- Workload Identity no *sink* do Debezium Server e nos *pods* de *job* do Airbyte (D69, D72).
- Faturamento e relatórios de custo acessíveis depois do fim da avaliação (G8) — **exportar o
  relatório por serviço na sexta**, para não depender disso.
- `dbt-bigquery` compatível com `dbt-core 1.12.3`, e com os pacotes da imagem do Composer.

---

## 9. Verificação de fatos

A busca na web do Gemini está sem cota no nível gratuito (429 em todos os modelos; o
`gemini-2.5-flash` responde "no longer available to new users"). Funciona a leitura de **URL
indicada** pela ferramenta `url_context`, conferida em 07/11 com a página de destinos do
Datastream. Daqui em diante, cada fato do §8 é perguntado ao Gemini **com a URL oficial**, e a
resposta entra em `CONVERSAS_COM_CHAT/gemini/` com o trecho citado; o Codex tem rede nas rodadas.

---

## 10. Revisão

**Encerrada em 07/11/2026 — porta P1 passada.** Três rodadas do Codex: 11 achados (9 bloqueantes,
2 ajustes), 5 (1 bloqueante, 3 ajustes, 1 observação) e 0 — todos corrigidos no plano. O parecer
inteiro, com a *Situação* de cada achado, está no `REVISAO.md` do *commit* `62541b2`, removido no
*commit* seguinte. "Resolvido no plano" é correção documental: as provas continuam por executar.
