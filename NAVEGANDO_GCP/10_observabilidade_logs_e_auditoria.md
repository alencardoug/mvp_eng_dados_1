# 10 — Cloud Logging, Monitoring e *audit logs*: a prova

**Em uma frase.** Tudo o que cada produto fez hoje está no Cloud Logging, com uma linguagem de
consulta; tudo o que **você** fez está nos *audit logs*, escritos pelo próprio GCP; e o Monitoring
tem as métricas de todos (fila do Pub/Sub, *workers* do Composer, *backlog* do Dataflow) num
painel só. É o `docker logs` + `make dag-status` + `pg_stat` num lugar — e é o capítulo que
transforma "eu vi" em "está registrado".

**Quanto custa e por quê.** Ingestão de *logs* acima de 50 GB/mês cobra; neste volume, nada.
Retenção padrão de 30 dias no *bucket* `_Default` — **os *logs* somem em 30 dias**, então o que
for evidência se exporta (CSV, ou *sink* para BigQuery/Cloud Storage) antes.

**Onde fica.** ☰ → *Logging* → *Logs Explorer* (`console.cloud.google.com/logs/query`); *Log
Router* (*sinks*), *Logs Storage* (retenção). ☰ → *Monitoring* → *Dashboards*, *Metrics explorer*,
*Alerting*. *Audit logs* são *logs* com `logName` terminando em `cloudaudit.googleapis.com/activity`
(admin) e `…/data_access` (leituras; ligado por serviço em *IAM & Admin → Audit Logs*, cap. 02).

**O que é deste projeto aqui.** Os `resource.type` de cada peça:
`cloud_composer_environment`, `k8s_container` (Airbyte), `cloudsql_database`,
`bigquery_project`/`bigquery_dataset` (audit), `datastream.googleapis.com/Stream`,
`pubsub_topic`/`pubsub_subscription`, `dataflow_step`, `gce_instance` (workers). E o seu usuário
como `protoPayload.authenticationInfo.principalEmail` em cada ação administrativa de hoje.

## Roteiro guiado

1. **Logs Explorer — a linguagem.** No editor de consulta:
   ```
   resource.type="cloud_composer_environment"
   labels.workflow="fluxo_batch"
   severity>=WARNING
   ```
   *Por quê:* filtro por recurso + rótulo + severidade é 90 % do uso. Salve a consulta
   (*Save*) — consulta salva é evidência reproduzível.
2. **A trilha de hoje — administrativa.**
   ```
   logName:"cloudaudit.googleapis.com/activity"
   protoPayload.authenticationInfo.principalEmail="<seu e-mail>"
   ```
   *O que olhar:* `methodName` (`SetIamPolicy`, `google.cloud.composer…`, `CreateJob`,
   `datastream…`), recurso, hora. *Por quê:* **é a lista do que você fez no GCP hoje, escrita
   pelo GCP.** Exporte em CSV. É a evidência mais forte de todo o dia.
3. **A trilha — acesso a dado.** Com *Data Access* ligado para o BigQuery:
   ```
   logName:"cloudaudit.googleapis.com/data_access"
   protoPayload.serviceName="bigquery.googleapis.com"
   protoPayload.authenticationInfo.principalEmail="analyst@…"
   ```
   *O que olhar:* a leitura negada do cap. 04 §9 / cap. 09 §3, com `PERMISSION_DENIED` e a
   *policy tag* no detalhe; e a permitida, com `jobCompletedEvent`. *Por quê:* a asserção de falha
   da Governança §7 com carimbo do sistema.
4. **O que o Terraform criou.**
   ```
   logName:"cloudaudit.googleapis.com/activity"
   protoPayload.methodName=~"(create|insert|Create|Insert)"
   timestamp>="2026-09-<segunda>T00:00:00Z"
   ```
   *Por quê:* a lista de recursos nascidos na segunda — o inverso do desmonte (cap. 11): tudo o
   que aparece aqui tem de ter um `delete` correspondente na quinta.
5. **Logs Storage.** Retenção do *bucket* `_Default` (30 dias). *Por quê:* saber que a evidência
   expira; se quiser guardar, *Log Router → Create sink* para um *bucket* GCS ou *dataset*
   BigQuery (`logs`) — com filtro só nos *audit logs*, para não pagar por volume.
6. **Monitoring → Metrics explorer.** Três métricas para achar (*Select a metric*, busque pelo
   nome):
   - `pubsub.googleapis.com/subscription/oldest_unacked_message_age` (a fila do caminho quente);
   - `composer.googleapis.com/environment/…` (`num_celery_workers`, `unfinished_task_instances`);
   - `dataflow.googleapis.com/job/backlog_seconds` (ou `system_lag`).
   *Por quê:* as três respondem "está acompanhando?" sem abrir três consolas. Monte um
   *dashboard* com as três (*Dashboards → Create*) — leva 5 minutos e é uma captura que diz
   "operei".
7. **Alerting.** Crie **uma** política: `oldest_unacked_message_age > 600 s` por 5 min →
   notificação por e-mail. *Por quê:* alerta de operação, não de fatura (esse é o cap. 01); e é o
   tipo de coisa que um ambiente corporativo tem e a fase local não podia ter.
8. **Error Reporting** (☰ → *Error Reporting*): erros de aplicação agrupados (Dataflow, Composer)
   *Por quê:* se um `dbt` falhou, aparece aqui agrupado por mensagem, antes de você abrir o *Grid*.

## Onde aciona, onde registra, o que controla

- **Aciona:** nada — é passivo; alertas disparam por condição.
- **Registra:** tudo. É o registro.
- **Controla:** retenção por *bucket* de *logs*, *sinks*, exclusões (filtros de descarte — cuidado:
  descartar *audit logs* é apagar a prova), políticas de alerta, quais serviços têm *Data Access*
  ligado.

## Armadilhas

- 30 dias e some. Exporte o que for evidência na própria semana.
- *Data Access* do BigQuery desligado = nenhuma leitura fica registrada = a prova do acesso
  negado não existe. Ligar é grátis neste volume; ligue **antes** do teste.
- *Log* de tarefa do Composer também está no *bucket* — e o *bucket* sobrevive ao ambiente;
  o Logging some em 30 dias. Os dois se complementam.
- Consulta no Logs Explorer sem intervalo de tempo curto é lenta; ponha o intervalo primeiro.

## Evidência a levar

- CSV da trilha administrativa do dia (passo 2) — **a peça central do caderno**.
- CSV dos *audit logs* de acesso do `analyst` (negado e permitido).
- As consultas salvas (nome + texto).
- Captura do *dashboard* com as três métricas durante o *pipeline* de pé.
- Captura da política de alerta.

## O que você saberá dizer depois

- "Tudo o que fiz na janela está nos *audit logs* de atividade; exportei a trilha com a
  consulta X."
- "Liguei *Data Access* no BigQuery antes de testar o acesso negado, e o *log* da negação cita a
  *policy tag*."
- "Montei um painel com fila do Pub/Sub, *workers* do Composer e *backlog* do Dataflow, e um
  alerta sobre a fila."
