# 04 — BigQuery: o armazém

**Em uma frase.** O `warehouse_db` sem servidor: nove *datasets* no lugar de nove schemas, tabelas
particionadas e clusterizadas no lugar de índices, *authorized views* no lugar do `grant select` a
`analyst`, e o dbt escrevendo tudo com o dialeto adaptado. Cobra por **byte lido** (consulta) e por
GB guardado — não por hora.

**Quanto custa e por quê.** Neste volume, centavos: US$ 0,02/GB/mês de armazenamento e
US$ 6,25/TB consultado, com 1 TB/mês grátis ([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)).
O que faz subir: `SELECT *` sem filtro de partição em tabela grande, e *streaming inserts* (por GB
inserido — é o caminho do Dataflow, cap. 08).

**Onde fica.** ☰ → *BigQuery* → *Studio* (`console.cloud.google.com/bigquery`). Painel esquerdo:
*Explorer* (projeto → *datasets* → tabelas/views); centro: editor e resultados; embaixo: *Job
history* (*Personal* e *Project*). Ao lado: *Scheduled queries*, *Data transfers*, *Policy tags*
(taxonomias — cap. 09).

**O que é deste projeto aqui.** *Datasets* `raw`, `raw_legacy`, `staging`, `trusted`,
`snapshots`, `analytics`, `consumption`, `quarantine`, `governance`. Em `analytics`, as dez fatos
particionadas por data e clusterizadas por chave; em `consumption`, as 16 views de negócio como
*authorized views*; em `raw`, `inventory_movements_stream` recebendo *streaming inserts* do
Dataflow; em `governance`, `legacy_captures` (o certificado do ADR-0044, com `MERGE`). O dbt roda
do Composer com a conta `transformer`.

## Roteiro guiado

1. **Explorer.** Expanda o projeto: os nove *datasets*. Clique em `analytics` → *Details*: região,
   expiração padrão de tabela, *labels*. *Por quê:* região igual à do Cloud SQL/Composer; expiração
   padrão é a retenção da [Governança §8](../docs/governanca_de_dados.md#8-retenção) em forma de
   propriedade.
2. **Uma fato.** `analytics.fact_sales_order_item` → *Schema* (tipos, `policy tag` na coluna,
   descrição vinda do `.yml` do dbt), *Details* (linhas, bytes, **partitioned by**, **clustered
   by**, *partition expiration*), *Preview* (grátis — não gasta consulta), **Lineage** (aba; cap.
   09). *Por quê:* partição e *cluster* são o critério da Etapa 13 "definidos antes do
   provisionamento" — aqui você vê se o dbt os aplicou.
3. **Uma consulta com custo visível.** No editor: `select count(*) from analytics.fact_sales_order_item`.
   Antes de rodar, o canto superior direito mostra **"This query will process X MB"**. Rode. Em
   *Job information*: bytes processados, *slot time*, cache hit. Agora
   `select * from analytics.fact_sales_order_item where order_date = '2026-08-01'` (a coluna de
   partição): veja o estimador cair. *Por quê:* é a única prova de que a partição está sendo
   usada — e o que você vai dizer sobre custo.
4. **Authorized view.** `consumption.<uma view>` → *Details*: SQL da view. Depois no *dataset*
   `analytics` → *Sharing → Authorize views*: a lista de views de `consumption` autorizadas a ler
   `analytics`. *Por quê:* é o mecanismo pelo qual `analyst` lê a view sem ter acesso ao
   *dataset* de baixo — o "authorized view em dataset próprio" da Arquitetura §5.
5. **Permissões por *dataset*.** `consumption` → *Sharing → Permissions*: `analyst` como
   `BigQuery Data Viewer`; `trusted` → o mesmo painel: `analyst` **ausente**. *Por quê:* a tabela da
   §7 lida na tela. (Cap. 02 explicou por que isso não aparece no IAM do projeto.)
6. **Job history → Project history.** Filtre pela conta `transformer`: cada modelo do dbt é um
   *job* com SQL, bytes, duração e *labels* (`dbt_invocation_id`, se o dbt os enviar). *Por quê:*
   é o `run_results.json` visto pelo lado do servidor — o registro de que o Composer rodou o dbt.
7. **`INFORMATION_SCHEMA`** — três consultas para salvar:
   ```sql
   -- o que o dbt executou hoje, por usuário, com bytes e duração
   select user_email, job_id, creation_time, total_bytes_processed, total_slot_ms, statement_type
   from `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
   where creation_time > timestamp_sub(current_timestamp(), interval 1 day)
   order by creation_time desc;
   -- tamanho por tabela (o `make size-report` daqui)
   select table_schema, table_name, total_rows, total_logical_bytes/1e6 as mb
   from `region-us`.INFORMATION_SCHEMA.TABLE_STORAGE order by mb desc;
   -- partições de uma fato
   select partition_id, total_rows from `analytics`.INFORMATION_SCHEMA.PARTITIONS
   where table_name = 'fact_sales_order_item' order by partition_id;
   ```
   (troque `region-us` pela região do projeto). *Por quê:* medição reproduzível, e é a mesma
   família de consulta do `pg_stat`/`size-report` local.
8. **`raw.inventory_movements_stream` → Details.** *Streaming buffer*: linhas ainda no *buffer*
   (chegaram pelo Dataflow, ainda não consolidadas — não aparecem em *Preview* nem em cópia de
   tabela por até ~90 min). *Por quê:* é a diferença de comportamento que um *streaming insert* tem
   e uma tabela normal não; quem operou Dataflow → BigQuery sabe disso.
9. **Consulta como `analyst`.** No Cloud Shell:
   `bq --impersonate_service_account=analyst@… query 'select 1 from trusted.orders limit 1'` →
   **Access Denied**; a mesma sobre `consumption.<view>` → resultado. *Por quê:* a asserção de
   falha da §7 executada, e ela fica nos *audit logs* (cap. 10). Coluna com *policy tag*: cap. 09.

## Onde aciona, onde registra, o que controla

- **Aciona:** editor, `bq`, o dbt no Composer, *scheduled queries*, *Data transfers*.
- **Registra:** *Job history*, `INFORMATION_SCHEMA.JOBS*`, *audit logs* (com *Data Access* ligado,
  **quem leu qual tabela**), *Details* de cada tabela (linhas/bytes/última modificação).
- **Controla:** IAM por *dataset* e por tabela, *authorized views*, *policy tags*, partição e
  expiração, retenção padrão do *dataset*, cotas de consulta por dia (*IAM → Quotas → BigQuery*),
  *reservations* (não use: é a modalidade por *slot* fixo; a do projeto é *on-demand*).

## Armadilhas

- *Preview* é grátis; `SELECT *` não. O estimador antes de rodar é o freio.
- Região de *dataset* é imutável: *dataset* em região diferente da do Cloud SQL/Composer não se
  corrige — se recria.
- *Streaming buffer*: dado "sumido" logo depois do Dataflow é dado no *buffer*.
- *Authorized view* precisa ser **re-autorizada** se o *dataset* de baixo for recriado pelo
  Terraform; o dbt não faz isso sozinho (confira se o HCL faz).
- `dbt` no BigQuery: `+grants` funciona (IAM por tabela), mas *grants* de schema não existem — o
  `on-run-end` local devolve vazio de propósito (macro `aplicar_acesso_por_camada`).

## Evidência a levar

- Captura de *Details* de uma fato com *partitioned by* / *clustered by*.
- As duas execuções do passo 3 (com e sem filtro de partição) com bytes processados.
- Captura de *Sharing → Permissions* de `consumption` e de `trusted`.
- Saída das três consultas de `INFORMATION_SCHEMA` (CSV).
- Saída do `bq` como `analyst`: uma negada, uma permitida.

## O que você saberá dizer depois

- "As fatos são particionadas por data e clusterizadas por chave; mostrei o estimador cair de X
  para Y MB com o filtro de partição."
- "O consumo é por *authorized view* em *dataset* próprio: `analyst` lê a view e não o
  *dataset* de baixo — provei com `bq` impersonando a conta."
- "Li o histórico de *jobs* do dbt por `INFORMATION_SCHEMA.JOBS` — bytes e *slot time* por modelo."
