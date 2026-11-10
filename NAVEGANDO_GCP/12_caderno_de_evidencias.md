# 12 — Caderno de evidências

> **Quando fazer.** Durante a semana, e fechado **sex 13 em diante**, com o custo real.

> Preencha **durante** e **logo depois** da viagem. Duas colunas que nunca se misturam:
> *planejado* (o que este guia disse que você veria) e *medido* (o que viu, com número, captura ou
> consulta). Vazio é resposta válida — "não medido" é melhor que inventado (P5).

## 1. A trilha (a peça central)

| | Planejado | Medido |
|---|---|---|
| CSV dos *audit logs* de atividade do dia, com seu e-mail (cap. 10 §2) | 1 arquivo | |
| Consulta usada | `logName:"…/activity" AND principalEmail="…"` | |
| Nº de ações administrativas registradas | — | |
| Recursos criados desde 07/11 (cap. 10 §4) vs. `terraform state list` | mesmo número | |

## 2. Por produto — o que trouxe

Marque `✓` só com o arquivo salvo (captura, CSV, *log*, texto da consulta). Onde há número,
escreva o número.

| Produto | Evidência | ✓ | Número / arquivo |
|---|---|---|---|
| Billing | *Reports* por serviço com URL dos filtros | | |
| Billing | Orçamento da janela com limiares | | |
| Billing | Custo real da janela (semana seguinte) | | est.: 40–70 US$ · med.: |
| IAM | Tabela IAM das contas `mvp-` | | |
| IAM | *Keys* vazia em cada conta de serviço | | |
| IAM | *Policy Troubleshooter*: `analyst` × `trusted` = negado | | |
| IAM | `gcloud projects get-iam-policy` salvo | | |
| Cloud SQL | *Overview* + *Flags* (`cloudsql.logical_decoding`) | | |
| Cloud SQL | Contagens de 3–4 tabelas de `oltp` (reconciliação) | | |
| BigQuery | *Details* de uma fato: *partitioned by* / *clustered by* | | |
| BigQuery | Consulta com e sem filtro de partição: bytes | | sem: · com: |
| BigQuery | Permissão da `mvp-analyst` numa view de `consumption`; ausência em `trusted` | | |
| BigQuery | `INFORMATION_SCHEMA.JOBS` do dbt (CSV) | | nº de *jobs*: |
| BigQuery | `bq` como `analyst`: negado em `trusted`, permitido em `consumption` | | |
| Airbyte/GKE | *Workloads* com *restarts* | | restarts: |
| Airbyte/GKE | *Streams* da conexão `retail` × `airbyte/streams.yml` | | |
| Airbyte/GKE | Um *job* + *log* do *pod* (consulta) | | duração: |
| Airbyte/GKE | `sync_id` em `raw` (consulta) | | |
| **Composer** | *Environment configuration* | | tamanho: · workers min/max: |
| **Composer** | *Grid* com `fluxo_batch` verde + `run_id` | | duração: |
| **Composer** | *Log* de `dbt_fronteiras` com `PASS=… TOTAL=…` | | |
| **Composer** | *XCom* de `concluir_captura_do_legado` | | snapshot: |
| **Composer** | *Browse → Audit Logs* com *trigger* e *clear* | | |
| **Composer** | *Monitoring* durante a execução | | |
| **Composer** | Hora de criação → hora de exclusão | | horas de ambiente: |
| Debezium | `make gcp-debezium-status` com o *pod* `Running` | | latência (§6.8, passo 27): |
| Debezium | `pg_replication_slots` ativo | | |
| Pub/Sub | Uma mensagem de alerta (`.observacao`, sem confirmar) | | |
| Pub/Sub | *oldest unacked message age* com *pipeline* de pé | | |
| Pub/Sub | Relatório de `make gcp-quente-prova` (duplicata em recurso temporário) | | |
| Dataflow | *Job graph* com *watermark*/*throughput* | | |
| Dataflow | *Custom counters* (tentados / inseridos / duplicados) | | |
| Dataflow | *Job info* (máquina, `max_num_workers`, conta) | | |
| Dataflow | *Batch* + *streaming* juntos: tamanho, tempo, custo (ADR-0046) | | |
| Dataflow | Hora de início → hora do *drain* | | horas de *worker*: |
| Dataplex | Taxonomia com *Enforce* ligado + permissões de `personal` | | |
| Dataplex | Coluna com *tag* em `raw` **e** em `analytics` | | |
| Dataplex | `bq` como `mvp-prova-sem-leitura`: coluna negada citando a *policy tag* | | |
| Dataplex | Execução do fluxo do ADR-0025 (*log*, federação) | | |
| Dataplex | Grafo de *Lineage* de uma view até `raw` | | |
| Logging | CSV dos *audit logs* de acesso negado e permitido | | |
| Logging | *Metrics explorer* com as métricas do *pipeline* de pé | | |
| Terraform | `state list` (segunda) + planos de destruição da §6.5 | | recursos: |
| Terraform | *Asset Inventory* de segunda + `make gcp-desmonte-inventario` | | sobreviventes: |

## 3. O que ficou pendente

Tudo o que o roteiro pedia e não foi visto, com o motivo (sem tempo, produto não subiu, decisão
da Etapa 13 diferente da suposta pelo guia). Vira insumo da segunda janela, não extensão desta.

| Item | Capítulo | Motivo |
|---|---|---|
| | | |

## 4. Onde o guia estava errado

Menu que mudou de nome, produto que não funciona como descrito, custo fora da ordem de grandeza.
Corrija o capítulo — o guia serve para a próxima janela.

| Capítulo | O que dizia | O que é |
|---|---|---|
| | | |

## 5. As frases que você agora pode dizer

Copie de cada capítulo (§ *O que você saberá dizer depois*) **só as que têm evidência marcada
acima**. É a lista para a entrevista, e a régua é simples: frase sem arquivo não entra.

1.
2.
3.
