# 08 — Dataflow: o processamento contínuo

**Em uma frase.** O mesmo *pipeline* Beam de `src/mvp_ed1/streaming/pipeline.py`, com
`--runner DataflowRunner`: a Google provisiona os *workers*, distribui o grafo, escala e reinicia.
A fonte troca o `DoFn` divisível do [ADR-0032](../docs/adr/0032-fonte-python-no-lugar-do-kafkaio.md)
por `ReadFromPubSub`; o destino troca o `INSERT … ON CONFLICT` por *streaming inserts* em
`raw.inventory_movements_stream` (ou `Storage Write API`). A janela de 1 minuto, o atraso tolerado
de 20 min e a idempotência por `movement_id` são os mesmos.

**Quanto custa e por quê.** Por **hora de *worker*** (vCPU, memória, disco) enquanto o *job* está
de pé — *streaming job* não termina sozinho. Um *worker* pequeno, casa de US$ 60–120/mês
([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)); mais o *Streaming Engine* por
dado processado e os *streaming inserts* no BigQuery por GB. O erro caro: *autoscaling* sem teto
(`--max_num_workers`) numa rajada, ou o *job* esquecido de pé depois da janela.

**Onde fica.** ☰ → *Dataflow* → *Jobs* (`console.cloud.google.com/dataflow/jobs`). Página do
*job*: **Job graph**, **Job metrics**, *Job info* (painel lateral), **Logs** (painel inferior:
*Job logs*, *Worker logs*, *Diagnostics*), *Autoscaling*, *Execution details*. Também *Snapshots*
e *Pipelines* (agendamento de *batch* — não usamos).

**O que é deste projeto aqui.** Um *job* de *streaming* com o nome que o `make stream-run` da nuvem
der (ex.: `mvp-ed1-inventory-stream`), lendo a assinatura do cap. 07, escrevendo em
`raw.inventory_movements_stream` e publicando alertas; região igual à do BigQuery; conta de
serviço dos *workers* = `streamer` (ADR-0011: "conta de serviço do Dataflow"); as métricas
personalizadas do *pipeline* (tentados, inseridos, duplicados — o `GravarEventos` conta) devem
aparecer em *Job metrics → Custom counters*.

## Roteiro guiado

1. **Jobs.** O *job* com estado `Running`, tipo *Streaming*, região, hora de início, SDK
   (Python x.y, Beam x.y). *Por quê:* hora de início → horas de *worker* → custo.
2. **Job graph.** As etapas com nome (os `>>` do `pipeline.py`: leitura, janela, dedup, saldo,
   escrita, alerta). Clique numa etapa: *throughput* (elementos/s), **data watermark**, *system
   lag*, *wall time*. *Por quê:* o *watermark* de cada etapa é a
   [Streaming §3.3](../docs/streaming.md#33-eventos-atrasados) em forma de número vivo — atrasos
   se leem aqui.
3. **Job metrics.** *Autoscaling* (número de *workers* ao longo do tempo), *Throughput*,
   *Backlog* (segundos de dado ainda não processado — **é o "fila" do Pub/Sub visto do
   consumidor**), *CPU utilization*, **Custom counters** (as métricas do `GravarEventos`:
   tentados vs inseridos; a diferença é a duplicata). *Por quê:* os contadores personalizados
   são a prova de idempotência do cap. 07 §8 pelo lado do processador.
4. **Job info.** Conta de serviço dos *workers*, tipo de máquina, `max_num_workers`, *Streaming
   Engine* on/off, opções do *pipeline* (as flags que você passou). *Por quê:* onde o teto de
   custo está; e a conta de serviço é o `streamer`.
5. **Logs → Worker logs.** Filtre por `ERROR`. Depois `INFO` da etapa de escrita. *Por quê:* o
   *log* do *worker* é onde "*permission denied* no BigQuery" ou "*schema mismatch*" aparecem;
   *Job logs* é o que o serviço diz sobre o *job* (escalou, reiniciou *worker*).
6. **Execution details.** Progresso por etapa, *stragglers*. *Por quê:* raramente útil aqui, mas
   é onde um *streaming job* mostra um estágio travado.
7. **Produza eventos** (`make stream-produce` apontado para a origem na nuvem, ou uma publicação
   à mão — cap. 07 §8) e veja: *Backlog* sobe e desce, *throughput* da etapa de leitura, os
   contadores incrementam, a linha em `raw.inventory_movements_stream` no BigQuery (lembre do
   *streaming buffer*, cap. 04 §8). *Por quê:* a cadeia inteira do caminho quente, ponta a ponta,
   com o número em cada elo.
8. **Batch e streaming ao mesmo tempo** (o critério do ADR-0046, medido **aqui**, não na fase
   local): com o *job* de pé, dispare `fluxo_batch` (cap. 06) e depois rode o teste
   `caminhos_de_ingestao_reconciliam`. Registre tamanho, tempo e custo. *Por quê:* é um critério de
   conclusão da Etapa 13 por extenso.
9. **Drain vs Cancel.** No fim, use **Drain** (fecha a fonte, termina o que está em voo, encerra):
   nada se perde. *Cancel* mata; *Stop* não existe para *streaming*. *Por quê:* *drain* é o que se
   faz num *job* de produção; e é o primeiro item do desmonte (cap. 11), antes do `destroy`.

## Onde aciona, onde registra, o que controla

- **Aciona:** `python -m mvp_ed1.streaming.cli … --runner DataflowRunner --region … --project …`
  (ou um *Flex Template*); *Drain/Cancel* na consola ou `gcloud dataflow jobs drain`.
- **Registra:** página do *job* (grafo, métricas, contadores, *autoscaling*), *Worker/Job logs*
  (Cloud Logging, `resource.type="dataflow_step"`), Monitoring (`dataflow.googleapis.com/job/…`).
- **Controla:** `max_num_workers`, máquina, *Streaming Engine*, conta de serviço, região, *drain*;
  *update* de *job* em voo (troca o código sem perder estado — vale saber que existe).

## Armadilhas

- *Streaming job* **não termina**: esquecido, cobra até alguém drenar. É o segundo item mais
  perigoso do desmonte, depois do Composer.
- `max_num_workers` sem teto + rajada = *autoscaling* para cima e fatura.
- *Streaming inserts* cobram por GB e ficam no *buffer* (cap. 04); *Storage Write API* é a
  alternativa mais barata — decisão da Etapa 13, não do dia.
- Conta de serviço dos *workers* sem `pubsub.subscriber`/`bigquery.dataEditor` no *dataset*
  `raw` = *job* sobe e não faz nada, com `ERROR` só nos *worker logs*.
- Região do *job* diferente da do tópico/BigQuery = tráfego entre regiões (cap. 01).

## Evidência a levar

- Captura do *Job graph* com *watermark* e *throughput* numa etapa.
- Captura de *Job metrics*: *autoscaling*, *backlog* e **custom counters**.
- *Job info* (máquina, `max_num_workers`, conta de serviço).
- Uma linha de *Worker logs* da escrita em BigQuery; a consulta do Logs Explorer.
- Os números do passo 8 (batch + streaming juntos): tamanho, tempo, custo — planejado ≠ medido.
- Hora de início e hora do *drain* → horas de *worker*.

## O que você saberá dizer depois

- "O *pipeline* Beam rodou no Dataflow com `ReadFromPubSub`; li *watermark* e *backlog* por
  etapa e os contadores de idempotência em *Custom counters*."
- "Drenei o *job* em vez de cancelar, e o *drain* foi o primeiro passo do desmonte."
- "Medi *batch* e *streaming* de pé ao mesmo tempo — o critério do ADR-0046 que a fase local
  não podia medir."
