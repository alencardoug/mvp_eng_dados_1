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
   (médio) na terça, para integração; **Composer e Dataflow na janela**, quarta — o Dataflow com um
   ensaio de ~1 h na terça, depois da prova do caminho quente (D83, 08/11/2026).

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
- **D78 — o tempo de evento chega ao Pub/Sub como atributo** (decidida em 07/11/2026, à tarde, no
  G2.3): no Debezium Server, `ExtractNewRecordState` (`add.fields=op,lsn`,
  `delete.tombstone.handling.mode=rewrite`) e `HeaderFrom` copiando `occurred_at` para cabeçalho,
  que o *sink* passa a atributo; o Beam lê com `timestamp_attribute`. **Debezium Server
  `3.7.1.Final`** fixado por *digest* — a primeira versão com o atributo cru (dbz#2783). Motivo e
  fontes no [Registro §18](docs/registro_fase_gcp.md#18-g23-aberto-o-tempo-de-evento-no-pubsub-07112026-tarde).

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

**G2.1 — o contrato de *backend*, operação a operação** (proposta de 07/11/2026; **aprovado pelo Owner no mesmo dia** e implementado — [Registro §17](docs/registro_fase_gcp.md#17-g21-terceira-peça-a-captura-com-o-certificado-no-bigquery-07112026-tarde), com as escolhas A18–A21).

Escrito antes de mexer em `captura.py`, `capture_recovery.py` e nas leituras do `ledger`, porque o
que muda é **onde** cada garantia mora, e isso se revisa melhor em tabela do que em *diff*. Feito
até aqui: o livro no Cloud Storage e o DDL do `governance`
([Registro §14 e §15](docs/registro_fase_gcp.md#14-g21-primeira-peça-o-livro-retido-no-cloud-storage-07112026-manhã)).

**A forma.** Dois papéis, que hoje são um `Engine` só: o **armazém** (o certificado e o bruto) e o
**coordenador** (os *locks*). Local, os dois são o mesmo PostgreSQL, e o código não muda de
comportamento. GCP, o armazém é o BigQuery (cliente `google-cloud-bigquery`, já dependência do
projeto pelo `dbt-bigquery`; **sem** `sqlalchemy-bigquery`, que seria dependência nova) e o
coordenador é o Cloud SQL das origens. Cada função recebe os dois explicitamente.

| Operação (`captura.py`) | Local (PostgreSQL) | GCP | A garantia, e onde ela mora no GCP |
|---|---|---|---|
| `bloqueio_da_tentativa` | `pg_advisory_lock` de sessão, conexão descartada no fim | o **mesmo**, no Cloud SQL | chamador vivo = lock tomado; o Cloud SQL é PostgreSQL |
| `iniciar` | `pg_advisory_xact_lock` de abertura + barreira + `insert` das 40 linhas, **uma transação** | lock de abertura **de sessão** no Cloud SQL; barreira lendo BigQuery e livro; 40 linhas numa tabela de passagem + `MERGE` pela chave `(tentativa, tabela)`, `insert` só quando não casa; **job confirmado** (`DONE`, sem erro, 40 linhas afetadas) **antes** de soltar o lock | a próxima abertura só começa depois de o `MERGE` estar visível (DML do BigQuery é consistente ao terminar o *job*); o `MERGE` torna a reexecução idempotente se a resposta do *job* se perder (recupera-se pelo `job_id`, não reenviando) |
| `conferir_antes_do_disparo` | `count(*)` pendentes sem job | o mesmo `select` no BigQuery | lido com o lock da tentativa tomado no Cloud SQL |
| `registrar_job` | `update … where (job_id is null and pending) or job_id = :j`, `rowcount = 40` | o mesmo `update` no BigQuery, `num_dml_affected_rows = 40` | o filtro do `update` é a guarda, nos dois; conflito de DML concorrente no BigQuery é erro do *job*, tratado como "não gravou" e relido |
| `medir_origem` | `hash_no_banco(legado)` | o mesmo, no Cloud SQL | inalterado: o *hash* é Python sobre linhas lidas |
| `medir_recebido` | `hash_no_banco(armazém, filtro sync_id)` + gerações + intrusas | as mesmas três leituras no BigQuery, com `JSON_VALUE(_airbyte_meta, '$.sync_id')` | o *hash* continua Python; **a provar**: que o Airbyte entrega as colunas `text` do legado como `STRING` sem mudar o texto (o vazio virando nulo já é normalizado) |
| `_publicar` | 40 `update … and status = 'pending'` numa transação | uma transação multi-instrução (`BEGIN … COMMIT`) com os 40 `update`, ou um `MERGE` da passagem | a guarda `pending` no próprio `update`: quem publicou primeiro vence, o segundo grava zero e lê o gravado |
| `_abandonar` | `update … pending and job_id is null and started_at <= :limite`, `rowcount = 40` | o mesmo `update` | condição revalidada no `update`, nos dois |
| `_gravado`, `_pendentes`, `certificadas` | `select` | o mesmo `select` | — |

**O que fica de fora do contrato, e por quê.** `governance.garantir` em `iniciar`: no GCP o DDL é
`garantir_bigquery`, chamado na preparação do ambiente (época inicial), não a cada captura — cada
chamada custaria um *job* de consulta a mais.

**O que precisa de prova antes da janela** (a do plano, com o contrato acima): os casos do
ADR-0044/0050 com o BigQuery simulado — resposta parcial, retorno perdido, reenvio sem remedir — e,
na terça, contra Cloud SQL e BigQuery reais. Um caso novo que o contrato pede: **dois `iniciar`
concorrentes**, para mostrar que o lock de sessão no Cloud SQL serializa a abertura como o
`xact_lock` serializava.

**Decisão do Owner:** nenhuma escolha de ferramenta nova (o cliente é o que já existe).
A mudança de `xact_lock` para lock de sessão na abertura é forçada pelo meio — a transação do
PostgreSQL não envolve o *job* do BigQuery — e mantém a garantia escrita no `iniciar` ("nenhuma
segunda abertura cabe entre a primeira e o registro dela"), desde que o lock só saia depois de o
`MERGE` confirmar.

**G2.2 — catálogo** (RV13-1-07). `models/sensitivity.py` com dialeto e tipos lidos do alvo, não
fixos em `postgres`; leitura do *manifest* BigQuery. **Prova:** compilar os dois alvos e comparar o
conjunto de folhas e a classificação de **todas** as colunas — diferença zero, ou cada diferença
explicada; é ela que alimenta as *tags* do G4.

**G2.3 — caminho quente** (RV13-1-05, D69, D75, ADR-0051). Debezium Server com `sink.type=pubsub`,
o mesmo conector de `streaming/connectors/inventory_movements.yml` (`decimal.handling.mode:
string`, *slot* e *publication* homônimos), `schemas.enable=false`, e o envelope **achatado** com
`op` e `lsn` como campos e `occurred_at` como atributo (D78; `envelope.py` recusa `u/d` pelo `__op`), *offsets* num disco persistente do GKE (apagado no
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

> **Revisto pela D80 (07/11/2026, Owner):** evento customizado não leva linhagem por coluna, e o
> BigQuery já a captura sozinho dos *jobs* do dbt. Por coluna, a **nativa**, medida contra o
> módulo (paridade); por tabela, as travessias de fora do BigQuery, pela API nativa (o *endpoint*
> OpenLineage recusa o Cloud SQL); `domain`/`owner` como *labels* do BigQuery pelo dbt.
> [Registro §23](docs/registro_fase_gcp.md#23-g5-catálogo-e-linhagem-07112026-noite).

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

### G9 — as evidências e o caso de portfólio (do G0 ao G8)

**O objetivo do Owner** (07/11/2026): comprovar que ele consegue replicar uma estrutura local
adequada na nuvem — e mostrar isso no portfólio, como caso, por código, capturas de tela,
documentos e páginas, em conteúdo **humanamente interessante**. Como a infraestrutura é destruída,
**o que não for capturado antes do `destroy` não existe para o portfólio.** Por isso a captura é
roteiro, não improviso.

**Onde fica cada coisa:**

| Evidência | Onde | Quem produz |
|---|---|---|
| O processo, em ordem, com comandos e saídas | [Registro da fase GCP](docs/registro_fase_gcp.md) | Claude Code, no momento |
| Capturas da consola e GIFs | `docs/registro_fase_gcp/capturas/`, nome `AAAA-MM-DD_NN_assunto` | Claude Code, pelo Chrome do Owner (Claude in Chrome); o e-mail e o avatar do Owner podem aparecer (decisão de 07/11), o ID da conta de faturamento fica fora do quadro |
| Saídas de `plan`/`apply`/`destroy` e consultas | trechos no Registro; os planos binários ficam em `data/` | Claude Code |
| Diagrama local ↔ GCP | Registro e caso | Claude Code, no G8 |
| O caso de portfólio | redigido aqui, no texto do projeto B em `CONVERSAS_COM_CHAT/TEXTO_PORTFOLIO_engenharia_de_dados.md`; publicado pelo Owner no portfólio (`/v1/projects/*`) **depois do M6**, pelas regras de lá — decisão de 07/11 | Claude Code redige; o Owner publica; o repositório do portfólio não é tocado sem pedido |

**O roteiro de capturas** — cada uma com a frase que ela prova:

| # | Quando | O que | O que prova |
|---|---|---|---|
| 01 | G0 ✓ | Painel do projeto recém-criado, com a faixa do crédito e dos dias restantes | o ponto de partida e o relógio |
| 02 | G0 | O orçamento com os créditos excluídos | o custo é vigiado de verdade |
| 03 | seg | BigQuery: os nove *datasets*, uma fato particionada e clusterizada | as camadas atravessaram |
| 04 | seg | Cloud SQL: a instância e os dois bancos | a origem existe na nuvem |
| 05 | ter | GKE: os *workloads* do Airbyte e do Debezium Server | o mesmo Airbyte, no GKE |
| 06 | ter | Airbyte: a sincronização para o BigQuery, sem chave | D72 |
| 07 | qua | Composer: a DAG `fluxo_batch` com as tarefas verdes | a mesma DAG, gerenciada |
| 08 | qua | Dataflow: o grafo do *job* e as métricas | o mesmo Beam, gerenciado |
| 09 | qua | Pub/Sub: os tópicos e uma mensagem de alerta | o caminho quente de ponta a ponta |
| 10 | qua | A mesma consulta de `consumption` no PostgreSQL local e no BigQuery, lado a lado, com o mesmo número | **paridade** — a captura central do caso |
| 11 | qua | *Policy tag* numa coluna e a consulta **negada** a quem não pode | governança aplicada, não declarada |
| 12 | qua | *Authorized view*: o analista lê a view e é negado na tabela | idem |
| 13 | qua | Linhagem no catálogo | o catálogo atravessou (ou o limite dela, dito como é) |
| 14 | qua | *Logs* de auditoria da negação | a prova fica registrada pela própria nuvem |
| 15 | qua 21:30 | O `terraform destroy` do degrau caro | o desmonte é código |
| 16 | qui | Inventário de recursos vazio | nada ficou para trás |
| 17 | qui 12:00 | Faturamento do projeto desligado | o relógio de emergência funcionou |
| 18 | qui 15:00 | Projeto em exclusão | o fim declarado |
| 19 | sex e depois | O relatório de custo por serviço | estimado × real |

Mais dois GIFs na quarta: a DAG rodando no Composer e o grafo do Dataflow recebendo eventos.

**O que torna o caso interessante** (fio da narrativa, para o G8): o prazo de sete dias e a conta
que se apaga sozinha; as quatro armadilhas achadas **antes** de gastar — o Datastream que não fala
com o Pub/Sub, a trava de retenção que impediria apagar o projeto, as *policy tags* que somem a cada
*build*, a idempotência que quebra sob concorrência —; a revisão por outro agente pegando nove
bloqueantes num plano que parecia pronto; o dia da janela; o desmonte provado; o custo estimado
contra o real. E, se houver, o que **não** deu certo, dito como é.

---

## 6. A janela

### 6.1 Cronograma [estimado]

| Quando | O quê | Taxímetro |
|---|---|---|
| sáb 07 | revisão 2 do plano e rodada 2 do Codex; ADR-0051; G0; G1 e G2 começam; BigQuery, GCS e Pub/Sub de desenvolvimento | centavos |
| dom 08 | **revisão do plano encerrada**; G1, G2, G3 e G4 em curso | centavos |
| seg 09 | Cloud SQL de pé (`apply` barato), povoado e provado; G2.1 contra Cloud SQL e BigQuery reais — o roteiro da §6.6; G1 em curso | barato |
| ter 10 | GKE + Airbyte + Debezium de pé; o armazém zerado e a época inicial do livro, depois do Airbyte (§6.7); portas de integração (§6.2); ensaio do Dataflow, ~1 h (D83); rodada do Codex no `plan` caro | médio |
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

O binário do plano leva o estado anterior inteiro, e com ele o que o estado tem de segredo: as
senhas do Cloud SQL, e o *token* da ADC que os *providers* do Kubernetes e do Helm leem
(RV13J-1-01). Por isso ele nasce com permissão só do dono (`umask 077`) e **sai depois do `apply`**
que o consumiu; o que fica como evidência é o texto do plano, onde o Terraform mascara os sensíveis.
O plano da raiz `airbyte/` nem chega a `data/`: nasce e é aplicado na pasta temporária do
`gcp-airbyte-config`. É a forma de conciliar o rito com o segredo no plano que o Owner decidiu
(D84, D86): os `.tfplan` já aplicados de `data/medicoes/etapa_13/planos/` saem também.

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

O projeto de estudo `mvp-ed1-estudo` (exploração do Owner, fora do M6; Registro §42) segue o mesmo
relógio, à mão, porque os alvos do `make` só operam o projeto do `.env`: até quarta 22:00 nada dele
fica rodando; às 12:00 de quinta, `gcloud billing projects unlink mvp-ed1-estudo` e
`gcloud billing projects describe mvp-ed1-estudo`, que deve dizer `billingEnabled: false`; às 15:00,
`gcloud projects delete mvp-ed1-estudo`.

### 6.5 A ordem do desmonte (RV13-1-02)

Cada passo tem ação e prova; a rede, o IAM e as APIs ficam de pé até o último. Os planos saem de
`make gcp-plan PASSO=n`, e o `VARS` de cada um vem de `mvp_ed1.gcp.desmonte`: a janela inteira
ligada, menos o que já foi desmontado. O `apply` é o rito da §6.3, `make gcp-apply PASSO=n`. A
guarda do `gcp-plan` recusa plano de desmonte que cria, e plano de construção que destrói. Os
passos sem Terraform são alvos `gcp-desmonte-*`, e cada um falha dizendo o que sobrou
([Registro §30](docs/registro_fase_gcp.md#30-g7-o-desmonte-em-alvos-do-make-08112026-madrugada)).

1. **Parar quem produz** — `make gcp-desmonte-parar`:
   - drena o *job* Dataflow pelo `gcp-dataflow-parar` (`gcloud dataflow jobs list --status=active`
     vazio);
   - pausa as DAGs e recusa seguir com execução em curso;
   - **desliga o fluxo das *policy tags*** (`gh variable set MVP_GCP_ATIVO --body false`, D79). Sem
     isso, o próximo *push* do YAML tentaria autenticar num projeto apagado.

   O produtor para no terminal dele.
2. **Composer** e o *bucket* dele (`force_destroy`), com o IAM do Dataflow:
   `make gcp-plan PASSO=2` (`20_desmonte_composer`).
3. **Debezium Server** e **Airbyte** (`helm uninstall`) com a API do Kubernetes ainda disponível:
   `make gcp-plan PASSO=3` (`21_desmonte_aplicacoes`). Depois, o *slot* de replicação **removido
   no Cloud SQL** (`pg_drop_replication_slot`) enquanto o Cloud SQL existe:
   `make gcp-desmonte-slot`.
4. **PVCs e PVs**: `make gcp-desmonte-kubernetes` apaga os *namespaces* e prova que nenhum PV nem
   *Service* *LoadBalancer* ficou. O GKE **retém** discos persistentes ao apagar o *cluster*
   ([deleting-a-cluster](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster)),
   e o `helm uninstall` não leva os PVCs dos StatefulSets do Airbyte.
5. **GKE**: `make gcp-plan PASSO=5` (`22_desmonte_gke`). Depois, discos, *forwarding rules* e
   regras de *firewall* órfãos: `make gcp-desmonte-orfaos`.
6. **Retenção do *bucket* do livro removida** (D70), no mesmo plano do passo 7
   (`ledger_retention_seconds = 0`). Os *buckets*, incluindo os do Beam, saem com
   `force_destroy` no passo 8, com o resto do degrau barato, que é o interruptor deles.
7. **Cloud SQL**: `make gcp-plan PASSO=7` (`23_desmonte_cloud_sql`). Depois,
   `make gcp-desmonte-sql` confere que nenhum *backup* ficou retido.
8. **Linhagem, depois BigQuery, *buckets*, Pub/Sub, Secret Manager, taxonomias, IAM e rede**:
   - `make gcp-desmonte-linhagem` apaga os processos da Data Lineage API. Recusa sem a captura de
     tela do G5;
   - em seguida, `make gcp-plan PASSO=8` (`24_desmonte_barato`). O *peering* dos serviços
     privados sai com `REMOVE_PEERING` (`terraform/rede.tf`).
9. **Inventário de resíduos** (`gcloud asset search-all-resources --scope=projects/<id>`) —
   `make gcp-desmonte-inventario`:
   - esperado vazio, salvo a **lista identificada** do que o projeto cria por padrão
     (`src/mvp_ed1/gcp/residuos_esperados.yml`, medida em 08/11);
   - cada item fora dela tem ação e prova, não só registro.
10. **Orçamento** apagado da conta de faturamento (não sai com o projeto):
    `make gcp-plan PASSO=10` (`25_desmonte_raiz`, `-destroy`). Depois,
    `make gcp-desmonte-orcamento`.
11. Camadas 2 e 3 no relógio da §6.4:
    - `make gcp-desligar-faturamento CONFIRMA=<id>`;
    - `make gcp-apagar-projeto CONFIRMA=<id>`.

    Cada um guarda a prova em `data/medicoes/etapa_13/g7/`.

### 6.6 Roteiro de segunda (09/11): o Cloud SQL de pé, povoado e provado

Para o Owner executar, um comando por passo, no terminal, na raiz do repositório. Cada passo diz o
que conferir antes, o que deve aparecer e o que fazer se não aparecer. Nenhum passo mexe no `.env`:
os alvos `gcp-origens-*` apontam os comandos locais para o Cloud SQL por cima dele, pelo proxy, com
as senhas lidas do Secret Manager. Os registros da carga vão para
`data/medicoes/etapa_13/origens_cloud_sql/`, e os da fase local ficam como estão
([Registro §31](docs/registro_fase_gcp.md#31-o-roteiro-de-segunda-e-as-origens-no-cloud-sql-08112026-madrugada)).
O Claude Code anota cada saída no Registro no momento em que ela aparece.

**A regra de falha, para todos os roteiros (§6.6 a §6.9 e §6.5)** (RV13J-1-14). Cada passo diz o que
deve aparecer; o que ele não diz segue esta regra:

1. **`ERRO`, `RECUSADO` ou `FALHOU` num passo que só lê ou confere** (preflight, conferir, oráculo,
   inventário, prova): o passo é repetível. Repita uma vez; se repetir o mesmo, o Claude Code
   registra, e **os passos que dependem dele não rodam** — cada passo que pode cortar outros diz
   quais. Nenhuma saída vazia é sucesso: "nada encontrado" só vale quando o alvo o diz com todas as
   letras.
2. **Falha num `gcp-plan`**: nada foi aplicado; não siga para o `gcp-apply` daquele plano.
3. **Falha num `gcp-apply`**: **não repita o `apply`**. Rode o `gcp-plan` de novo, que mostra o que
   ficou, e decida pelo plano novo — o estado guardado (`tfstate_<nome>.bak`) é a volta.
4. **Falha num passo que escreve** (sincronização, mutação, registro no livro): leia a mensagem antes
   de repetir. Os alvos que escrevem recusam repetir o que já foi feito, e dizem de onde retomar.
5. **O relógio da §6.4 vale sobre todos.** Nenhum passo se estende além da hora dele; o que não
   rodou vira pendência, e o desmonte começa na hora.

**A época inicial do livro não é de segunda.** O `ledger baseline` lista os *jobs* da conexão
legada do Airbyte, e o Airbyte do projeto só existe depois do `apply` do GKE, na terça. Rodada
segunda, ela leria o Airbyte **local**.

**Passo 1 — o projeto certo nos três lugares.**

```
make gcp-preflight
```

Deve aparecer `gcp-preflight: projeto mvp-ed1-gcp nos três lugares`. Se reclamar da ADC, renove as
credenciais num terminal próprio (`gcloud auth application-default login`) e repita.

**Passo 2 — o plano do degrau 06.**

```
make gcp-plan NOME=06_cloud_sql VARS="enable_cloud_sql=true"
```

Deve aparecer `Plan: 11 to add, 1 to change, 0 to destroy.` e, embaixo,
`conferir-plano: construção: 11 a criar, 1 a alterar, 0 a destruir`. A alteração é o
`deletion_policy` da conexão de serviços privados (Registro §30). Se os números forem outros, ou a
guarda recusar, **pare**: nada foi aplicado, e o Claude Code lê o plano com você.

**Passo 3 — ler o plano.** Abra `data/medicoes/etapa_13/planos/06_cloud_sql.txt` e confira:

- 11 criações: a instância `mvp-ed1-origens`, os 2 bancos, os 2 usuários, as 2 senhas e os 2
  segredos com as versões;
- a única alteração é `google_service_networking_connection.this[0]`, de `DELETE` para
  `REMOVE_PEERING`.

**Passo 4 — aplicar.** O taxímetro do Cloud SQL começa aqui (Capacidade §2.14).

```
make gcp-apply NOME=06_cloud_sql
```

Deve terminar com `Apply complete! Resources: 11 added, 1 changed, 0 destroyed.` A instância leva
minutos para nascer. Se falhar no meio, **não repita**: o estado anterior está em
`data/medicoes/etapa_13/planos/tfstate_06_cloud_sql.bak`, e o Claude Code lê o erro em
`06_cloud_sql_apply.txt` antes de qualquer novo plano.

**Passo 5 — o schema das duas origens.**

```
make gcp-origens-migrar
```

Deve aparecer `origens: Cloud SQL … pelo proxy em 127.0.0.1:15432` e, no fim, a revisão `(head)`
das duas cadeias de migração. Se o proxy não abrir, confira se outro processo ocupa a porta 15432
(`ERRO: a porta 15432 já está ocupada`). O alvo abre o **próprio** proxy e não usa o de outro
terminal: se for um `make gcp-sql-proxy` seu, feche-o (Ctrl-C lá) e repita; se não souber de quem é,
`ss -ltnp 'sport = :15432'` mostra o processo — pergunte ao Claude Code antes de encerrar.

**Passo 6 — os dados das duas origens.** A geração da fase local, sem parâmetro.

```
make gcp-origens-povoar
```

Devem aparecer as duas cargas: `carregadas … linhas`, do gerador, e `carregado: … linhas`, do
legado. Se o gerador disser
que as tabelas já contêm dados, **pare**: não há `FORCE` neste alvo.

**Passo 7 — o lote do legado é o da fase local.**

```
ls data/medicoes/etapa_13/origens_cloud_sql/legacy/
```

Deve listar `manifesto-060c3fc983fb71984764e6d3074e8e6e.json`, o mesmo lote do manifesto local
(ensaiado em 08/11 sem banco). Outro *hash* é achado de paridade: anote e siga.

**Passo 8 — a medida da geração.** Em memória, sem banco.

```
make generation-measure
```

Copie o caminho que ele imprimir no fim (`data/medicoes/v1_1_0/…_geracao_….json`).

**Passo 9 — o oráculo das origens contra o Cloud SQL.** Somente leitura.

```
make gcp-origens-oraculo MEDIDA=<o caminho do passo 8>
```

Deve terminar sem problema listado. Problema listado é achado de paridade da §7.2: anote e siga, que
o Cloud SQL não volta atrás.

**Passo 10 — o atributo de replicação do Debezium (G2.3).**

```
make gcp-origens-replicacao
```

Deve aparecer `replicação: concedida agora; conferida em pg_roles`. Se o Cloud SQL recusar o
`ALTER ROLE`, **pare**: sem o atributo o Debezium de terça não abre o *slot*, e o Claude Code
procura com você a forma que o Cloud SQL aceita.

**Passo 11 — as provas do G2.1 com os *locks* no Cloud SQL.**

```
make gcp-g21-prova
```

Deve terminar com `passed`, nenhum `failed`, e o caminho da saída em `data/medicoes/etapa_13/g2_1/`.
Os testes criam e apagam um *dataset* temporário. Teste que falha não derruba nada: anote e siga.

**No fim do dia:** nada a desligar. O Cloud SQL fica de pé até o desmonte de quinta, e o proxy de
cada alvo fechou com ele. Não rode `make ledger-baseline` nem edite o `.env`.

### 6.7 Roteiro de terça (10/11), parte 1: o GKE, o Airbyte configurado e a época inicial

Como a §6.6: um comando por passo, na raiz do repositório. O `VARS` de cada plano leva **todos**
os degraus de pé, e a guarda recusa o plano que destrói. A parte 2 — as capturas, o dbt, as *tags*, o
Debezium e o ensaio do Dataflow (D83) — é a §6.8. Os números de plano marcados *pelo código* não foram medidos: só
saem com o degrau anterior de pé.

**Passo 1 — o projeto certo.**

```
make gcp-preflight
```

**Passo 2 — o plano do *cluster*.**

```
make gcp-plan NOME=08_gke VARS="enable_cloud_sql=true enable_gke=true"
```

Deve aparecer `11 a criar, 0 a alterar, 0 a destruir`, o mesmo do `08_gke` do Registro §21: o
*cluster*, o *pool*, a conta dos nós, o Cloud NAT e o Workload Identity. Leia
`data/medicoes/etapa_13/planos/08_gke.txt` antes do passo 3.

**Passo 3 — aplicar.** O taxímetro do GKE começa aqui.

```
make gcp-apply NOME=08_gke
```

Deve terminar com `Apply complete! Resources: 11 added, 0 changed, 0 destroyed.` e a linha de que o
binário do plano saiu. O *cluster* leva uns 10 minutos. Erro: a regra 3 da §6.6 — **não repita**; o
`gcp-plan` de novo mostra o que ficou. Sem *cluster*, a §6.7 para aqui, e a terça segue só com o que
não depende do GKE (nada da §6.8 roda).

**Passo 4 — o plano dos *releases*.**

```
make gcp-plan NOME=09_aplicacoes VARS="enable_cloud_sql=true enable_gke=true enable_gke_apps=true"
```

Pelo código, `2 a criar`: o `helm_release` do Debezium Server e o do Airbyte. Leia o plano.

**Passo 5 — aplicar.** A instalação do Airbyte leva minutos, até 20 (`timeout` do *release*).

```
make gcp-apply NOME=09_aplicacoes
```

Deve terminar com `Apply complete! Resources: 2 added, 0 changed, 0 destroyed.` Erro por `timeout`
do Airbyte: a regra 3 da §6.6; o Claude Code lê o estado do *release* (`helm status` pelo
`kubectl`) antes de qualquer novo plano. Sem os dois *releases*, os passos 6 a 9 não rodam.

**Passo 6 — as fontes, os destinos e as conexões no Airbyte do GKE.**

```
make gcp-airbyte-config
```

Deve aparecer `airbyte: API do GKE em http://127.0.0.1:18001/api/public/v1 (port-forward)`, e o
Terraform mostra o plano **salvo** — o rito da §6.3: o binário fica na pasta temporária, porque leva
as senhas, e o texto, com os sensíveis mascarados, em `data/medicoes/etapa_13/planos/airbyte_gcp_…txt`.
Pelo código, `6 to add`: duas fontes no Cloud SQL, dois destinos BigQuery e duas conexões. Leia e,
se estiver certo, digite o id do projeto (`mvp-ed1-gcp`); qualquer outra coisa sai sem aplicar. Ele
não mexe no Airbyte local: o estado é o do *workspace* `gcp` da raiz `airbyte/`. Se o fim disser
`AVISO: … workspace default`, rode o comando que o aviso mostra. `ERRO: a porta 18001 já está
ocupada`: um *port-forward* de outro terminal ficou aberto; feche-o e repita.

**Passo 7 — zerar o armazém.** Apaga a cópia de desenvolvimento e as saídas dos `dbt build` de
ensaio, e não toca nos *datasets*, no IAM nem nas *policy tags*.

```
make gcp-armazem-zerar CONFIRMA=mvp-ed1-gcp
```

Deve aparecer `armazém zerado: N tabelas e views apagadas`, perto de 278 (medido em 08/11). Daqui
até a primeira sincronização, o `gcp-dbt-build` não tem o que ler.

**Passo 8 — a governança da nuvem.**

```
make gcp-armazem-governanca
```

Deve listar as migrações aplicadas (`governance (BigQuery): 0001_…, 0002_…`).

**Passo 9 — a época inicial do livro.**

```
make gcp-livro-epoca
```

Deve aparecer `pronto para a época inicial` e, embaixo, `época aberta: gs://mvp-ed1-gcp-livro/legado/…`,
com `0 capturas no bruto, 0 linhas de certificado, 0 jobs da conexão legada`. Se aparecer
`RECUSADO`, a linha diz o quê: armazém com dado (volte ao passo 7) ou época já aberta (**pare**: o
livro nunca é reescrito).

### 6.8 Roteiro de terça (10/11), parte 2: o caminho quente, as capturas, o dbt e as provas

Continua a §6.7, depois da época inicial. Junta o que a porta P3 (§6.2) pede às 18:00: Airbyte →
BigQuery sem chave (D72), G2.1 real e G2.3 real. Vale a regra de falha da §6.6.

**A ordem é a das fontes antes dos consumidores** (RV13J-1-02). O zerar da §6.7 levou também o
`raw.inventory_movements_stream`, que nenhuma sincronização recria: ele é do caminho quente. O
`dbt build` lê essa tabela (o *staging* dos movimentos, a *view* `skus_below_reorder_point`) e o
teste `caminhos_de_ingestao_reconciliam` cobra os dois caminhos iguais. Por isso o caminho quente
nasce e alcança o *snapshot* **antes** das capturas e do *build* (passos 3 a 9), e os movimentos
novos da prova só nascem **depois** da paridade (passos 21 a 28).

O ensaio do Dataflow é o da D83, em duas partes: o *snapshot* (passos 7 a 9, uns 20 min) e as
provas de reinício e a latência (passos 22 a 29, uns 40 min).

**O que prova o G2.3** — cada item da lista da §G2.3, com o cenário que o exercita e o estado
dele hoje (RV13J-2-01). *Provado por comando* é o que um passo daqui exercita e confere; *garantido
pelo desenho* é o que o código impede e nenhum passo força; *não atendido* fica assim escrito.

| Item da §G2.3 | Cenário | Estado |
|---|---|---|
| *snapshot* e CDC pelo *parser*; contagem física igual à de eventos | passos 8, 23, 26 e 28: o conferir compara cada `movement_id` e as 16 colunas de negócio dos dois lados, e acusa perdido, indevido e repetido | provado por comando |
| decimal e fuso exatos | passo 3: `NUMERIC` e microssegundos do envelope ao destino (`test_no_bigquery_de_verdade_o_lote_e_idempotente_e_exato`); e o conteúdo dos passos 8 e 23 | provado por comando |
| duplicata dentro do mesmo lote | passo 3: o lote com `a` duas vezes grava uma e conta a duplicata | provado por comando |
| o mesmo movimento reenviado **dentro** da janela de deduplicação | passo 3, `gcp.prova_quente`: `m2` publicado duas vezes, barrado, uma linha, o saldo e o alerta certos | provado por comando |
| o mesmo movimento reenviado **fora** da janela de deduplicação | o lote que repete chaves já gravadas não devolve nada (passo 3, o mesmo lote de novo), e o saldo e o alerta pendem **do que a escrita devolve**, não da leitura (`pipeline.py`, `novos = unicos \| gravar`). Nenhum passo publica um reenvio depois de a janela expirar | a escrita, provada; o saldo e o alerta, garantidos pelo desenho — **não exercitados de ponta a ponta** |
| depois de **retorno perdido** | passo 3: o `MERGE` roda, a resposta some; o teste exige **uma** submissão, a busca do *job* pelo mesmo id, e os eventos devolvidos iguais aos do lote (`test_no_bigquery_de_verdade_a_resposta_perdida_do_lote_nao_duplica_nem_cala`, novo, **nunca rodado** — roda pela primeira vez no passo 3). O saldo e o alerta pendem do que a escrita devolve, e não são exercitados nesse cenário | a escrita, provada por comando se o passo 3 passar; o saldo e o alerta, garantidos pelo desenho |
| **dois lotes concorrentes com a mesma chave nova** | não há: a mesma chave cai sempre no mesmo fragmento (`fragmento`, o `crc32` do `movement_id`), e o `GroupIntoBatches` processa uma chave por vez. O passo 3 prova a mesma chave em dois lotes **seguidos** e chaves **diferentes** em lotes concorrentes; um `MERGE` só de inserção concorrente com a mesma chave **não** é o que o BigQuery serializa | garantido pelo desenho — **não atendido como prova** |
| reinício do *worker* | passos 21 a 23: parar o *job*, produzir com ele parado e lançar outro — é **retomada da assinatura** por um *job* novo, não a recuperação de um *worker* dentro do mesmo *job* | retomada provada por comando; recuperação no mesmo *job* **não atendida** |
| reinício do *pod* do Debezium | passo 24: o log do *pod* mais novo é lido até ele passar ao *streaming* (`Starting streaming`); passa só com `A previous offset indicating a completed snapshot has been found.` antes disso e sem `Snapshot step 1 - Preparing` (`mvp_ed1.gcp.debezium_log`); o conferir do passo 26 acusa perdido e repetido. As frases são as do conector 3.6.2, lidas nos *jars* da imagem local; a 3.7.1 da janela não foi conferida, e frase mudada dá `NÃO CONCLUSIVO`, nunca aprovação | provado por comando, se o log disser |
| unicidade física, saldo e quais eventos foram ao alerta | passo 3, `gcp.prova_quente` (`conferir`): cinco linhas, a duplicata barrada, saldo durável 23 e **uma** abertura no par publicado, com o limiar 25 cruzado numa das seis travessias que os quatro movimentos podem dar (de 25, 27 ou 29 para 23; de 26, 28 ou 30 para 24) — qual delas depende da ordem dos painéis, e não se fixa | provado por comando |
| alerta observado no caminho do GKE | passos 8, 23, 26 e 28 listam os alertas lidos; o do GKE depende de o saldo cruzar o limiar, e não se força | observado se acontecer; o provado é o do passo 3 |

**O G2.3 não passa inteiro.** Dois itens da §G2.3 ficam não atendidos como prova — os lotes
concorrentes com a mesma chave e a recuperação do *worker* dentro do mesmo *job* — e um, o reenvio
fora da janela, só na escrita. Pela §G2.3, "sem essa prova o caminho quente não entra na janela, e o
critério fica incompleto". **O Owner decidiu que ele entra na quarta assim, declarado incompleto
nesses três itens (D87)**: o desenho impede os dois casos, e cortá-lo tiraria a reconciliação com
*streaming* simultâneo da §7.2. Com os passos 3 ou 8 vermelhos, nem isso: o caminho quente não entra.

**Passo 1 — a folga do `kubectl`.**

```
make gcp-gke-versao
```

Deve mostrar as duas versões, a uma versão menor uma da outra no máximo. Se recusar, o Claude Code
troca a versão fixada no `Makefile` antes de qualquer outro passo que use o `kubectl`.

**Passo 2 — o Debezium Server.** Ele subiu na §6.7 (passo 5) e fez o *snapshot* para o Pub/Sub.

```
make gcp-debezium-status
```

Deve mostrar o *pod* `Running`, o fim do log sem erro e `slot mvp_inventory_movements: ativo`. Se o
*pod* não estiver `Running` ou o *slot* faltar, **pare o bloco quente** (passos 3 a 9 e 21 a 29): as
capturas (passos 10 a 20) seguem, mas o `dbt build` vai falhar no teste de reconciliação, e o G2.3
fica não atendido.

**Passo 3 — as provas do G2.3 no BigQuery e no Pub/Sub reais.** Não usa o GKE nem o Dataflow: cria
e apaga recursos temporários.

```
make gcp-quente-prova
```

Deve terminar com `gcp-quente-prova: as duas provas passaram`, todos os testes passando (nenhum
pulado) e o relatório do grafo em `data/medicoes/etapa_13/g23/`. Se falhar, o G2.3 não passa: o
Claude Code registra o teste que falhou, e o bloco quente para aqui.

**Passo 4 — o destino do caminho quente.** Antes do plano do Dataflow, que dá IAM nela.

```
make gcp-dataflow-tabela
```

Deve aparecer `destino pronto: …inventory_movements_stream` (o zerar a levou, e ela nasce de novo).
Se falhar, pare o bloco quente: sem a tabela, o plano do passo 5 não tem onde dar o IAM.

**Passo 5 — o plano e o `apply` do Dataflow.**

```
make gcp-plan NOME=11_dataflow VARS="enable_cloud_sql=true enable_gke=true enable_gke_apps=true enable_dataflow=true"
```

Deve dar `4 a criar, 0 a alterar, 0 a destruir`, o mesmo do Registro §29. Outro número, ou
`RECUSADO`: **não aplique**; o Claude Code lê o plano e explica a diferença. Lido e certo:

```
make gcp-apply NOME=11_dataflow
```

Deve terminar com `Apply complete! Resources: 4 added, 0 changed, 0 destroyed.` Erro no `apply`:
**não repita**; rode o `gcp-plan` de novo, que mostra o que ficou, e decida pelo plano novo.

**Passo 6 — o *job* montado, sem enviar.**

```
make gcp-dataflow-validar
```

Nenhuma divergência. Se houver, **pare**: nada foi enviado.

**Passo 7 — lançar.** O taxímetro do Dataflow começa aqui.

```
make gcp-dataflow-lancar
```

Deve aparecer `job enviado: …`. Acompanhe na consola do Dataflow até o *worker* subir, uns minutos.

**Passo 8 — o *snapshot* no BigQuery, por chave e conteúdo.**

```
make gcp-quente-conferir
```

Repita até não aparecer `PENDENTE`: o *worker* lê o acumulado da assinatura, guardado por uma
semana. Deve terminar com `conteúdo: os N movimentos iguais por chave e pelas 16 colunas de
negócio`. `FALHOU — …` não é espera: é movimento perdido, indevido, repetido ou com valor diferente
— o G2.3 não passa; siga ao passo 9 e registre. Os alertas lidos aparecem embaixo.

**Passo 9 — parar o Dataflow até as provas de reinício.**

```
make gcp-dataflow-parar
```

Deve terminar com `nenhum job ativo`. `ERRO: a listagem … falhou`: repita; não conclua nada da saída
vazia.

**Passo 10 — a origem principal para o `raw`.**

```
make gcp-sync-retail
```

Deve terminar com `concluída: … linhas`. O destino escreve sem chave, pela conta `mvp-ingestor` via
Workload Identity: é a prova da D72. Falhou: repita uma vez; falhou de novo, os passos 15 a 18
param (o *build* não tem o bruto), e as capturas do legado (11 a 13) seguem.

**Passo 11 — a primeira captura do legado.**

```
make gcp-sync-legacy
```

Deve aparecer `recuperação: nada devido`, o andamento do *job* (`job …: running · … linhas`) e, no
fim, o certificado e `concluída`. A tentativa fica registrada no livro do Cloud Storage.

**Passo 12 — uma captura interrompida.** Rode de novo e, na primeira linha `job …: running`, aperte
**Ctrl-C**.

```
make gcp-sync-legacy
```

O *job* segue no Airbyte e a tentativa fica pendente, que é o que o passo 13 resolve. Espere o *job*
terminar, uns minutos, como o do passo 11.

**Passo 13 — a recuperação e a segunda captura.**

```
make gcp-sync-legacy
```

Deve aparecer `recuperação registrou: gs://…` para a tentativa do passo 12, e depois uma captura
nova certificada. Se a barreira recusar porque o *job* do passo 12 ainda corre, espere e repita:
nada se abriu.

**Passo 14 — as *tags* nas fontes recém-escritas.**

```
make gcp-tags-convergir
```

Deve terminar com `gcp-tags-convergir: fontes convergidas`. `AUSENTE — …`: a fonte não existe — volte
ao passo que a escreve (10, 11 ou 4) antes de seguir.

**Passo 15 — o `dbt build` sobre o dado real.**

```
make gcp-dbt-build
```

O esperado é o PASS do Registro §22 (909), com 0 erros. **Teste** que falha (`FAIL`) é achado de
paridade: o Claude Code o registra, e os passos 16 a 20 seguem. **Erro** de modelo (`ERROR`) deixa
consumidores sem tabela: os passos 16 a 20 param, e o bloco quente (21 a 29) segue.

**Passo 16 — o tratamento da terça no livro.** Antes de qualquer outro `dbt build`: é o que o T3
cobra da quarentena da terça quando o tratamento de quarta a substituir.

```
make gcp-livro-tratamento NOME=terca_tratamento.json
```

Deve aparecer `registro de tratamento: gs://…/terca_tratamento.json · sha256 …`. Falhou: repita; sem
ele, o T3 da quarta (§6.9 passo 13) falha.

**Passo 17 — o inventário das *tags*.**

```
make gcp-tags-inventario
```

Deve dizer `0 divergências, nenhuma tabela ausente`. É a repetição do G4 depois de uma
sincronização (Registro §22). Divergência ou ausente: achado do G4, registrado; siga.

**Passo 18 — a paridade com a fase local.**

```
make gcp-oraculos
```

As contagens por camada, o **conteúdo** das *views* de `consumption` e o catálogo contra o local —
o estado corrente (D85). Ele lê o armazém local: o banco dele precisa estar de pé (`make ps`). Cada
comparação diz o seu veredito, e o alvo falha se uma falhar. Medido no estado de desenvolvimento
(Registro §37): 13 das 16 *views* iguais em conteúdo; diferem as duas de estoque, que leem os
movimentos ao vivo de cada ambiente, e a de margem do mês corrente. A classificação do legado casa
por `snapshot_id`, que é o *job* de cada Airbyte, e os *jobs* diferem entre o local e a nuvem: o
alvo diz que ela **não é comparável entre ambientes** e não a compara (D85). Pelo mesmo motivo,
a contagem da história de cada ambiente — os schemas `raw_legacy` e `snapshots`, o `governance.legacy_captures` e os três modelos do legado que leem capturas anteriores (`legacy_presence_by_capture`, `legacy_capture_transitions`, `legacy_removed_records`) — sai marcada como não comparável e não reprova; o resto reprova, e objeto que existe num
lado só reprova sempre (RV0811-1-01). O Claude Code registra
cada diferença; nenhuma bloqueia os passos seguintes.

**Passo 19 — a memória anterior intacta (T3).** Somente leitura; leva minutos, porque mede o
recebido de cada captura certificada.

```
make gcp-memoria-oraculo
```

Deve terminar com `T3: memória contida`. `PROBLEMA` listado é achado do G2.1: o Claude Code
registra, e o G2.1 não passa na P3.

**Passo 20 — nenhum POST indevido.**

```
make gcp-jobs-auditoria
```

Deve dizer quantos *jobs* da conexão legada nasceram desde a linha de base e quantas tentativas os
citam no livro — três e três, depois dos passos 11 a 13 — e `nenhum POST indevido`. Outra coisa é
achado do G2.1.

**Passo 21 — movimentos com o Dataflow parado.** Esperam na assinatura `beam`.

```
make gcp-quente-produzir LIMITE=20
```

Deve terminar com `20 eventos emitidos` (ou 21, se o último for um par de transferência).

**Passo 22 — o *worker* de novo: o reinício.**

```
make gcp-dataflow-lancar
```

Deve aparecer `job enviado: …`; espere o *worker* subir.

**Passo 23 — os que esperaram entraram uma vez.**

```
make gcp-quente-conferir
```

Repita até não aparecer `PENDENTE`; o fim é o `conteúdo: … iguais` do passo 8, agora com os 20.

**Passo 24 — o *pod* do Debezium de novo: o reinício.**

```
make gcp-debezium-reiniciar
```

Deve mostrar `deployment "debezium-server" successfully rolled out`, o fim do log do *pod* novo e
`gcp-debezium-reiniciar: o pod novo retomou dos offsets, sem snapshot`; o log inteiro fica em
`data/medicoes/etapa_13/g23/`. `FALHOU — o pod novo refez o snapshot`: os *offsets* do disco não
valeram, e o reinício do *pod* não passa no G2.3 — siga, e o passo 26 mostra se houve repetido.
`NÃO CONCLUSIVO`: o Claude Code lê o log guardado antes de dar o item por provado.

**Passo 25 — movimentos depois do reinício.**

```
make gcp-quente-produzir LIMITE=20
```

**Passo 26 — nem perdido, nem repetido.**

```
make gcp-quente-conferir
```

Repita até não aparecer `PENDENTE`. `FALHOU — … repetido` aqui é o *snapshot* refeito: o G2.3 não
passa no reinício do *pod*.

**Passo 27 — movimentos novos, ao vivo, e a latência.** O alvo emite 200 movimentos e consulta o
destino a cada 5 s até ver todos.

```
make gcp-quente-latencia
```

Deve imprimir `p50_s`, `p95_s` e `max_s` com `"completo": true`, e guardar o relatório em
`data/medicoes/etapa_13/g23/`. É a latência que um leitor do destino vê: do `recorded_at` na origem
até a primeira consulta que mostra o evento, com resolução de 5 s. `INCOMPLETO — …` diz por quê (o
produtor falhou, a origem não recebeu os 200, o destino não mostrou todos em 15 min): não é medida;
o Claude Code registra, e a latência da §7.2 fica não medida na terça.

**Passo 28 — o destino alcançou a origem.**

```
make gcp-quente-conferir
```

**Passo 29 — parar o Dataflow.**

```
make gcp-dataflow-parar
```

Deve terminar com `nenhum job ativo`. O Debezium Server e o GKE ficam para a quarta.

### 6.9 Roteiro de quarta (11/11): o Composer, a segunda captura e a saída até as 22:00

A parte cara (G6). Começa às 07:00, com a porta P4 passada (§6.2) e a terça inteira de pé: o Cloud
SQL, o GKE com o Airbyte e o Debezium, a época e as capturas da §6.8. Os horários são os da §6.1 e
do relógio da §6.4. O que não rodar até as 20:00 vira pendência, e a janela não se estende. Vale a
regra de falha da §6.6.

**Passo 1 — o projeto certo.**

```
make gcp-preflight
```

**Passo 2 — o plano do Composer.**

```
make gcp-plan NOME=10_composer VARS="enable_cloud_sql=true enable_gke=true enable_gke_apps=true enable_dataflow=true enable_composer=true"
```

Deve dar `14 a criar, 0 a alterar, 0 a destruir`: os 14 do Composer dentro dos 36 do Registro §28.
Leia o plano.

**Passo 3 — aplicar.** O ambiente leva uns 25 minutos para nascer, e a parte cara começa aqui.

```
make gcp-apply NOME=10_composer
```

Deve terminar com `Apply complete! Resources: 14 added, 0 changed, 0 destroyed.` Erro: a regra 3 da
§6.6. Sem Composer, os passos 4 a 6, 9 e 16 não rodam; a segunda captura pode sair pelo
`make gcp-sync-legacy` e o `make gcp-dbt-build` desta máquina (passos 11 a 15 seguem), e a
`fluxo_batch` no Composer fica não atendida.

**Passo 4 — os segredos do Airbyte para o Composer.**

```
make gcp-composer-segredos
```

Devem aparecer as três linhas `gcp-composer-segredos: mvp-ed1-… gravado`.

**Passo 5 — o layout no *bucket*.**

```
make gcp-composer-publicar
```

Deve terminar com `gcp-composer-publicar: layout em gs://… (dags/ e data/)`. Falhou: repita; o
`rsync` só põe no *bucket* o layout montado agora. Sem layout, o passo 6 não roda.

**Passo 6 — o *smoke test*.** Nada escreve.

```
make gcp-composer-smoke
```

Deve terminar com `diagnostico_composer: … terminou com sucesso`. Se a tarefa `rede` falhar, o
Composer não chega ao Cloud SQL pelo *peering* dos serviços privados, a hipótese aberta do Registro
§28. **Pare**: a saída é o Cloud SQL por Private Service Connect, e a decisão é sua.

**Passo 7 — o caminho quente ligado.** O `lancar` valida antes de enviar.

```
make gcp-dataflow-lancar
```

Repita `make gcp-quente-conferir` até não aparecer `PENDENTE`.

**Passo 8 — a mudança controlada na origem legada.** Entre a captura certificada da terça e a de
hoje, as mutações de `src/mvp_ed1/gcp/mutacoes_da_janela.yml`, com o diário. Uma vez só.

```
make gcp-legado-mutar
```

Devem aparecer as quatro mutações (`remover brands`, `remover customers`, `inserir brands`,
`alterar brands`, cada uma com o *hash* antes e depois) e `… mutações aplicadas agora; o diário tem
as 4 da janela`. Rodado de novo com o diário completo, diz `o diário já tem 4 de 4` e não aplica
nada: siga. Se falhar no meio, as que confirmaram ficam no diário; rode **o mesmo comando** de novo,
que retoma da que falta (`retomando da seguinte`) sem repetir as feitas. **`RECUSADO`** (o diário
não é o da declaração, ou a tabela mudou fora dele): **pare as provas das duas capturas** (passos
12 e 13); o Claude Code lê o diário e o banco, e o passo 9 roda mesmo assim.

**Passo 9 — a `fluxo_batch` de ponta a ponta, com o *streaming* junto.**

```
make gcp-composer-fluxo
```

Enquanto ela roda, num **segundo terminal**, a latência com o *batch* junto:

```
make gcp-quente-latencia LIMITE=500
```

O primeiro terminal deve terminar com `fluxo_batch: … terminou com sucesso · tarefas em …` e a lista
das tarefas com o estado e a duração de cada uma, gravada em `data/medicoes/etapa_13/g6/`: são os
tempos de sincronização e de `dbt build` da §7.2. O teste `caminhos_de_ingestao_reconciliam` roda
dentro do `dbt build` dela. `… terminou com sucesso, mas os tempos das tarefas NÃO foram coletados`:
a DAG passou e a medida não existe — rode o comando que a linha mostra
(`make gcp-composer-tarefas DAG=fluxo_batch RUN=…`). `FALHOU`: a tarefa que falhou diz o quê; o
Claude Code lê o log dela, e os passos 10 a 15 rodam com o que a DAG deixou. O segundo terminal
segue a regra do passo 27 da §6.8.

**Passo 10 — o tratamento da quarta no livro.** Depois do `dbt build` da `fluxo_batch`, como na
terça (§6.8 passo 16).

```
make gcp-livro-tratamento NOME=quarta_tratamento.json
```

Deve aparecer `registro de tratamento: gs://…/quarta_tratamento.json · sha256 …`.

**Passo 11 — o destino quente alcançou a origem.**

```
make gcp-quente-conferir
```

Repita até não aparecer `PENDENTE`.

**Passo 12 — a matriz das duas capturas (§7.2).**

```
make gcp-legado-matriz
```

Deve terminar com `matriz das duas capturas: o intervalo e a memória mostram o efeito líquido do
diário`. `FALHOU` lista cada chave do diário que o intervalo ou a memória não mostram: é achado do
ADR-0045, registrado; os passos seguintes rodam. `RECUSADO: … não tem anterior certificada` quer
dizer que a captura da `fluxo_batch` não certificou: a matriz fica não medida.

**Passo 13 — a primeira captura preservada (T3).**

```
make gcp-memoria-oraculo
```

Deve terminar com `T3: memória contida`. As remoções aceitas na memória de exclusões são as do
diário (a marca e os três clientes que o passo 8 removeu, `mutacoes_da_janela.yml`), e não um
número escrito aqui. `PROBLEMA` listado é
achado do G2.1, registrado; não bloqueia os passos seguintes.

**Passo 14 — nenhum POST indevido.**

```
make gcp-jobs-auditoria
```

Agora são quatro *jobs* da conexão legada e quatro tentativas: os três da terça e o da `fluxo_batch`.
Outra contagem, ou `POST indevido`: achado do G2.1, registrado.

**Passo 15 — as *tags*, a paridade e o tamanho.**

```
make gcp-tags-inventario
```

```
make gcp-oraculos
```

```
make gcp-armazem-tamanho
```

O primeiro deve dizer `0 divergências, nenhuma tabela ausente`. O segundo repete a comparação da
terça (§6.8 passo 18) e agora tem diferenças **esperadas** além das de terça: as mutações do passo 8
existem só na nuvem (as contagens do legado nas camadas de estado) e os movimentos da latência de terça e
de hoje, só no caminho quente da nuvem (as *views* de estoque). O Claude Code registra cada
diferença contra esse esperado; uma fora dele é achado de paridade. O último imprime, por *dataset*,
as tabelas, as linhas e os bytes lógicos, e guarda o relatório em `data/medicoes/etapa_13/g6/`. É o
"tamanho por *dataset*" da §7.2. Nenhum dos três bloqueia a exportação.

**20:00 — o ponto de decisão.** O Claude Code registra o que passou e o que não rodou, e o que não
rodou vira pendência.

**Passo 16 — a exportação, antes das 21:30.** O *bucket* do Composer sai no desmonte, e os logs do
Airflow com ele.

```
make gcp-composer-exportar
```

Deve terminar com `gcp-composer-exportar: logs em data/medicoes/etapa_13/g6/logs (N arquivos)`, N
maior que zero. Falhou: repita — o `rsync` só copia o que falta. Falhou de novo: baixe a pasta
`logs/` do *bucket* pela consola. **O passo 18 não começa** sem os logs aqui, ou sem você declarar
que eles se perdem (registrado); o relógio das 22:00 vale sobre isso, e logs perdidos viram limite
declarado da §7.2.

**Passo 17 — parar quem produz (§6.5, passo 1), até as 22:00.**

```
make gcp-desmonte-parar
```

Deve terminar com o Dataflow sem *job* ativo, as DAGs pausadas e `MVP_GCP_ATIVO=false`.
`ERRO: … a listagem … falhou`: repita; uma listagem que falha nunca vale como "nada em curso".

**Passo 18 — o Composer fora (§6.5, passo 2).**

```
make gcp-plan PASSO=2
```

Leia o plano: só destruições, o Composer e o IAM do Dataflow. Então:

```
make gcp-apply PASSO=2
```

Se às 22:00 o Composer ou o Dataflow ainda estiverem de pé, vale o relógio da §6.4: uma hora para
removê-los pelo `gcloud`, e depois a consola, por você.

---

## 7. Paridade funcional — o que se mede na janela

Com o gerador determinístico (mesma `seed`, mesma `as_of_date`, fator `dev`), nos dois alvos.

### 7.1 A matriz do mapa

Uma linha de evidência por linha da [Arquitetura §5](docs/arquitetura.md#5-mapa-de-paridade-local--gcp),
com o mapa corrigido em 07/11 (D69, D70 e o destino quente idempotente da D75): o que foi provisionado, a consulta ou o *log* que prova, e
`medido`/`não medido` com motivo. Linha sem evidência não conta como paridade.

### 7.2 Dados e memória

- Contagens por camada e reconciliações entre camadas no BigQuery iguais às da fase local na mesma
  geração, no estado: a classificação por captura e a contagem da história de cada ambiente
  (`oraculo.e_historia`) não são comparáveis entre ambientes (D85); os testes do
  dbt nos dois alvos (PASS comparado); as views de `consumption` com a mesma soma de controle por
  view — comparação de dados normalizados, **com os metadados de execução excluídos
  explicitamente**.
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
