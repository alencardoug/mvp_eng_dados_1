# 10 — Cloud Logging, Monitoring e *audit logs*: a prova

> **Quando fazer.** **Seg 09**, passos 2 a 5. **Qua 11**, passos 1, 6 e 8, com o Composer e o Dataflow de pé.

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
`cloud_composer_environment`, `k8s_container` (Airbyte, Debezium), `cloudsql_database`,
`bigquery_project`/`bigquery_dataset` (audit),
`pubsub_topic`/`pubsub_subscription`, `dataflow_step`, `gce_instance` (workers). E o seu usuário
como `protoPayload.authenticationInfo.principalEmail` em cada ação administrativa de hoje.

## Roteiro guiado

1. **Logs Explorer — a linguagem.** No editor de consulta:
   ```
   resource.type="cloud_composer_environment"
   labels.workflow="fluxo_batch"
   severity>=WARNING
   ```
   Antes da quarta, troque para `resource.type="cloudsql_database"`. *Por quê:* filtro por recurso +
   rótulo + severidade é 90 % do uso. Anote o texto da consulta no caderno: é evidência reproduzível,
   e não cria objeto no projeto.
2. **A trilha de hoje — administrativa.**
   ```
   logName:"cloudaudit.googleapis.com/activity"
   protoPayload.authenticationInfo.principalEmail="<seu e-mail>"
   ```
   *O que olhar:* `methodName` (`SetIamPolicy`, `google.cloud.composer…`, `CreateJob`,
   recurso, hora. *Por quê:* **é a lista do que você fez no GCP hoje, escrita
   pelo GCP.** Exporte em CSV. É a evidência mais forte de todo o dia.
3. **A trilha — acesso a dado.** Com *Data Access* ligado para o BigQuery:
   ```
   logName:"cloudaudit.googleapis.com/data_access"
   protoPayload.serviceName="bigquery.googleapis.com"
   protoPayload.authenticationInfo.principalEmail="mvp-prova-sem-leitura@mvp-ed1-gcp.iam.gserviceaccount.com"
   ```
   *O que olhar:* a leitura negada do cap. 04 §9 / cap. 09 §3, com `PERMISSION_DENIED` e a
   *policy tag* no detalhe; e a permitida, com `jobCompletedEvent`. *Por quê:* a asserção de falha
   da Governança §7 com carimbo do sistema.
4. **O que o Terraform criou.**
   ```
   logName:"cloudaudit.googleapis.com/activity"
   protoPayload.methodName=~"(create|insert|Create|Insert)"
   timestamp>="2026-11-07T00:00:00Z"
   ```
   *Por quê:* a lista de recursos nascidos desde 07/11 — o inverso do desmonte (cap. 11): tudo o
   que aparece aqui tem de ter um `delete` correspondente na quinta.
5. **Logs Storage.** Só olhe a retenção do *bucket* `_Default` (30 dias). *Por quê:* saber que a
   evidência expira. Aqui, o que importa se exporta em CSV: o projeto é apagado na quinta, e um
   *sink* criado à mão reprovaria o inventário.
6. **Monitoring → Metrics explorer.** Três métricas para achar (*Select a metric*, busque pelo
   nome):
   - `pubsub.googleapis.com/subscription/oldest_unacked_message_age` (a fila do caminho quente);
   - `composer.googleapis.com/environment/…` (`num_celery_workers`, `unfinished_task_instances`);
   - `dataflow.googleapis.com/job/backlog_seconds` (ou `system_lag`).
   *Por quê:* as três respondem "está acompanhando?" sem abrir três consolas. Monte um
   *dashboard* com as três (*Dashboards → Create*) só no `mvp-ed1-estudo`; no `mvp-ed1-gcp`, olhe
   pelo *Metrics explorer*, sem salvar.
7. **Alerting.** Só no `mvp-ed1-estudo` (depois do bloco 10.1 do laboratório, com a assinatura de lá), crie **uma** política: `oldest_unacked_message_age > 600 s` por 5 min →
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

- 30 dias e some; e, com o projeto apagado na quinta, antes disso. Exporte o que for evidência até quinta, 12:00.
- *Data Access* desligado = nenhuma leitura fica registrada = a prova do acesso negado não existe.
  No BigQuery, os *logs* de leitura vêm ligados. Confira, sem mudar nada.
- *Log* de tarefa do Composer também está no *bucket*, que sai no desmonte: o
  `make gcp-composer-exportar` guarda antes.
- Consulta no Logs Explorer sem intervalo de tempo curto é lenta; ponha o intervalo primeiro.

## Evidência a levar

- CSV da trilha administrativa do dia (passo 2) — **a peça central do caderno**.
- CSV dos *audit logs* de acesso de `mvp-prova-sem-leitura` (negado) e `mvp-analyst` (permitido).
- As consultas usadas (texto).
- Captura do *Metrics explorer* com as métricas durante o *pipeline* de pé.
- Captura da política de alerta.

## O que você saberá dizer depois

- "Tudo o que fiz na janela está nos *audit logs* de atividade; exportei a trilha com a
  consulta X."
- "O *log* de *Data Access* do BigQuery registrou o acesso negado, e cita a *policy tag*."
- "Montei um painel com fila do Pub/Sub, *workers* do Composer e *backlog* do Dataflow, e um
  alerta sobre a fila."
