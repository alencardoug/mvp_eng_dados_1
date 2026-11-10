# 08 — Dataflow: o processamento contínuo

> **Quando fazer.** **Ter 10**, com o *job* de pé nos passos 7 a 9 e 22 a 29 da §6.8; **qua 11**, nos passos 7 a 17 da §6.9. Fora disso, não há *job* para olhar.

**Em uma frase.** O mesmo *pipeline* Beam de `src/mvp_ed1/streaming/pipeline.py`, com
`--runner DataflowRunner`: a Google provisiona os *workers*, distribui o grafo, escala e reinicia.
A fonte troca o `DoFn` divisível do [ADR-0032](../docs/adr/0032-fonte-python-no-lugar-do-kafkaio.md)
por `ReadFromPubSub`; o destino troca o `INSERT … ON CONFLICT` pela escrita idempotente da D75 em
`raw.inventory_movements_stream` (`streaming/nuvem.py`). A janela de 1 minuto, o atraso tolerado
de 20 min e a idempotência por `movement_id` são os mesmos.

**Quanto custa e por quê.** Por **hora de *worker*** (vCPU, memória, disco) enquanto o *job* está
de pé — *streaming job* não termina sozinho. Um *worker* `n1-standard-2`
([Capacidade §2.14](../docs/capacidade_e_recuperacao.md#214-a-estimativa-da-janela-da-etapa-13--07112026)), mais o *Streaming Engine* por dado processado. O erro caro é o *job*
esquecido de pé depois da janela; o *autoscaling* está travado em `--max_num_workers=1`.

**Onde fica.** ☰ → *Dataflow* → *Jobs* (`console.cloud.google.com/dataflow/jobs`). Página do
*job*: **Job graph**, **Job metrics**, *Job info* (painel lateral), **Logs** (painel inferior:
*Job logs*, *Worker logs*, *Diagnostics*), *Autoscaling*, *Execution details*. Também *Snapshots*
e *Pipelines* (agendamento de *batch* — não usamos).

**O que é deste projeto aqui.** O *job* de *streaming* `mvp-ed1-caminho-quente`, lançado por
`make gcp-dataflow-lancar` (§6.8, passo 7), lendo a assinatura `.beam` do cap. 07, escrevendo em
`raw.inventory_movements_stream` e publicando alertas; em `us-central1`, sem IP público nos
*workers*; conta dos *workers* = `mvp-streamer` (D82); as métricas do *pipeline*
(`eventos_gravados`, `eventos_duplicados`, `retransmissoes_no_transporte`, `alertas_emitidos`,
`janelas_corrigidas`) em *Job metrics → Custom counters*.

## Roteiro guiado

1. **Jobs.** O *job* com estado `Running`, tipo *Streaming*, região, hora de início, SDK
   (Python x.y, Beam x.y). *Por quê:* hora de início → horas de *worker* → custo.
2. **Job graph.** As etapas com nome (os `>>` do `pipeline.py`: leitura, janela, dedup, saldo,
   escrita, alerta). Clique numa etapa: *throughput* (elementos/s), **data watermark**, *system
   lag*, *wall time*. *Por quê:* o *watermark* de cada etapa é a
   [Streaming §3.3](../docs/streaming.md#33-eventos-atrasados) em forma de número vivo — atrasos
   se leem aqui.
3. **Job metrics.** *Throughput*,
   *Backlog* (segundos de dado ainda não processado — **é o "fila" do Pub/Sub visto do
   consumidor**), *CPU utilization*, **Custom counters** (`eventos_gravados` e
   `eventos_duplicados`). *Por quê:* os contadores personalizados
   são a prova de idempotência pelo lado do processador.
4. **Job info.** Conta de serviço dos *workers*, tipo de máquina, `max_num_workers`, *Streaming
   Engine* on/off, opções do *pipeline* (as flags que você passou). *Por quê:* onde o teto de
   custo está; e a conta de serviço é o `streamer`.
5. **Logs → Worker logs.** Filtre por `ERROR`. Depois `INFO` da etapa de escrita. *Por quê:* o
   *log* do *worker* é onde "*permission denied* no BigQuery" ou "*schema mismatch*" aparecem;
   *Job logs* é o que o serviço diz sobre o *job* (escalou, reiniciou *worker*).
6. **Execution details.** Progresso por etapa, *stragglers*. *Por quê:* raramente útil aqui, mas
   é onde um *streaming job* mostra um estágio travado.
7. **Acompanhe os eventos do roteiro** (`make gcp-quente-produzir` e `make gcp-quente-latencia`,
   §6.8, passos 25 e 27) e veja: *Backlog* sobe e desce, *throughput* da etapa de leitura, os
   contadores incrementam, a linha em `raw.inventory_movements_stream` no BigQuery (lembre do
   *streaming buffer*, cap. 04 §8). *Por quê:* a cadeia inteira do caminho quente, ponta a ponta,
   com o número em cada elo.
8. **Batch e streaming ao mesmo tempo** (o critério do ADR-0046, medido **aqui**, não na fase
   local): é o passo 9 da §6.9, em que a `fluxo_batch` roda com o *job* de pé e o teste
   `caminhos_de_ingestao_reconciliam` vem dentro do `dbt build` dela. *Por quê:* é um critério de
   conclusão da Etapa 13 por extenso.
9. **Drain vs Cancel.** Quem drena é o `make gcp-dataflow-parar`, e a consola só acompanha. **Drain** (fecha a fonte, termina o que está em voo, encerra):
   nada se perde. *Cancel* mata; *Stop* não existe para *streaming*. *Por quê:* *drain* é o que se
   faz num *job* de produção; e é o primeiro item do desmonte (cap. 11), antes do `destroy`.

## Onde aciona, onde registra, o que controla

- **Aciona:** `make gcp-dataflow-validar` (sem enviar) e `make gcp-dataflow-lancar`;
  `make gcp-dataflow-parar` drena.
- **Registra:** página do *job* (grafo, métricas, contadores, *autoscaling*), *Worker/Job logs*
  (Cloud Logging, `resource.type="dataflow_step"`), Monitoring (`dataflow.googleapis.com/job/…`).
- **Controla:** `max_num_workers`, máquina, *Streaming Engine*, conta de serviço, região, *drain*;
  *update* de *job* em voo (troca o código sem perder estado — vale saber que existe).

## Armadilhas

- *Streaming job* **não termina**: esquecido, cobra até alguém drenar. É o segundo item mais
  perigoso do desmonte, depois do Composer.
- Conta dos *workers* sem `pubsub.subscriber` ou sem escrita na tabela de destino = *job* sobe e não faz nada, com `ERROR` só nos *worker logs*.
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
