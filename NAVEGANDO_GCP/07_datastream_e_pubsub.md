# 07 — Datastream e Pub/Sub: o caminho quente, até o transporte

**Em uma frase.** Datastream é o Debezium gerenciado: lê o WAL do Cloud SQL (*logical decoding*)
e entrega cada mudança de `oltp.inventory_movements`; Pub/Sub é o Redpanda gerenciado: o tópico
que guarda os eventos até o Dataflow (cap. 08) consumir. Os dois cobram por **GB processado**, não
por hora — os mais baratos da janela.

**Quanto custa e por quê.** Datastream por GB capturado (e o *backfill* inicial conta); Pub/Sub por
GB publicado + entregue, com os primeiros 10 GB grátis
([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)). Neste volume (13.700
movimentos + o que o produtor emitir), centavos. O que custa de verdade aqui é **tempo de
depuração**: um *stream* que não sai de `Starting` costuma ser rede ou flag do Cloud SQL (cap. 03).

**Onde fica.** Datastream: ☰ → *Datastream* → *Streams*, *Connection profiles*, *Private
connectivity* (`console.cloud.google.com/datastream/streams`). Pub/Sub: ☰ → *Pub/Sub* →
*Topics*, *Subscriptions*, *Schemas*, *Snapshots* (`console.cloud.google.com/cloudpubsub/topic/list`).

**O que é deste projeto aqui.** Um *stream* do Cloud SQL (perfil de conexão PostgreSQL, com
*publication* e *replication slot* — os nomes vêm de `streaming/connectors/inventory_movements.yml`
traduzido) para o destino que a Etapa 13 escolher. **Atenção ao mapa:** o Datastream entrega
nativamente em BigQuery ou em Cloud Storage; a paridade "Datastream → Pub/Sub → Dataflow" da
[Arquitetura §5](../docs/arquitetura.md#5-mapa-de-paridade-local--gcp) pressupõe um passo entre os
dois (Cloud Storage com notificação em Pub/Sub, ou o *template* Dataflow *Datastream to BigQuery*).
Qual o Terraform escolheu é a primeira coisa a ler na página do *stream*. Os tópicos:
`mvp.oltp.inventory_movements` (eventos) e `mvp.alerts.inventory_low_stock` (o alerta da
[Streaming §5](../docs/streaming.md#5-ramificação-de-alerta)), com as assinaturas do Dataflow.

## Roteiro guiado — Datastream

1. **Streams → o *stream*.** Estado (`Running`, `Paused`, `Failed`), origem, destino, **Objects**
   (as tabelas incluídas: só `oltp.inventory_movements`?), *backfill* por objeto (estado,
   linhas). *Por quê:* *backfill* é o *snapshot* do Debezium — o mesmo "re-*snapshot*" da
   [Execução Local §3.2](../docs/execucao_local.md#32-regerar-uma-origem-que-já-alimenta-streaming)
   tem aqui um botão: *Objects → Initiate backfill*.
2. **Monitoring do *stream*.** *Throughput*, **data freshness** (atraso entre a mudança na origem e
   a entrega), *unsupported events*, *system latency*. *Por quê:* *freshness* é a latência do
   caminho quente medida pelo próprio serviço — número para o registro.
3. **Connection profiles.** O perfil PostgreSQL: *hostname*/IP privado, usuário (com
   `REPLICATION`), *publication* e *replication slot* declarados. *Test connection*. *Por quê:* é
   onde 90 % dos problemas de CDC estão; e é o `connectors/*.yml` local em forma de tela.
4. **Logs.** `resource.type="datastream.googleapis.com/Stream"`. Procure o início do *backfill* e
   a transição para CDC. *Por quê:* prova de que o *snapshot* fechou e o contínuo começou.
5. **No Cloud SQL (cap. 03):** `select * from pg_replication_slots` e `pg_publication_tables`.
   *Por quê:* os dois lados da mesma coisa; *slot* ativo = Datastream conectado.

## Roteiro guiado — Pub/Sub

6. **Topics → `mvp.oltp.inventory_movements`.** *Details* (retenção de mensagens, *schema* se
   houver), *Subscriptions* (a do Dataflow), **Metrics** (*publish rate*, *message size*),
   **Messages → Pull** (puxa uma amostra sem confirmar — veja o envelope: é o
   `envelope.py` do projeto, ou o formato do Datastream). *Por quê:* ver a mensagem crua é o
   `rpk topic consume` da fase local.
7. **Subscriptions → a do Dataflow.** *Details*: *ack deadline*, retenção, *dead-letter topic*,
   *exactly-once*. **Metrics**: *unacked messages* (fila) e **oldest unacked message age**
   (atraso). *Por quê:* fila crescendo com Dataflow de pé = o *job* não acompanha; fila
   crescendo com Dataflow parado = o que vai ser reprocessado quando subir (o *snapshot*
   duplicado do ADR-0019 é aqui que se vê).
8. **Publicar à mão.** *Messages → Publish message* no tópico de eventos com um evento válido (copie
   um do *Pull*). Veja o Dataflow (cap. 08) consumir e a linha aparecer em
   `raw.inventory_movements_stream`. Publique **o mesmo** de novo: a idempotência por
   `movement_id` (ADR-0019) tem de rejeitar — é o `make stream-duplicate` na nuvem. *Por quê:* a
   prova de idempotência sem a qual a garantia é só intenção (Streaming §3.2).
9. **`mvp.alerts.inventory_low_stock`.** Crie uma assinatura de *pull* só sua (*Create
   subscription*) e puxe: os alertas de estoque baixo emitidos pelo *pipeline*. *Por quê:* é o
   `make stream-alerts` — e uma assinatura criada à mão é algo que **sobrevive ao `destroy`**
   se o Terraform não a conhece; apague depois (cap. 11).

## Onde aciona, onde registra, o que controla

- **Aciona:** Datastream — *Start/Pause/Resume* do *stream*, *Initiate backfill*; Pub/Sub —
  publicação (Datastream, o *pipeline*, ou você).
- **Registra:** página do *stream* (objetos, *freshness*), *logs*; métricas do tópico e da
  assinatura (Monitoring), *Messages → Pull*.
- **Controla:** objetos incluídos, *backfill*; retenção, *ack deadline*, *dead-letter*, *schema*,
  IAM por tópico/assinatura (`pubsub.subscriber` para o `streamer`).

## Armadilhas

- *Stream* pausado com *slot* vivo **retém WAL** no Cloud SQL — disco cresce (cap. 03).
- Retenção de mensagem padrão do Pub/Sub é 7 dias; mensagem não confirmada em assinatura sem
  consumidor fica lá e é reentregue quando o consumidor voltar — e reentrega é duplicata, que a
  idempotência trata, mas conta no *reprocessed*.
- Assinatura criada à mão fora do Terraform sobrevive ao `destroy`.
- Datastream não entrega em Pub/Sub diretamente; confira o desenho real do Terraform antes de
  procurar "o tópico do Datastream".

## Evidência a levar

- Captura da página do *stream* com *Objects* e o *backfill* concluído; *data freshness*.
- `pg_replication_slots` no Cloud SQL com o *slot* ativo.
- Uma mensagem puxada do tópico de eventos (o envelope) e uma do tópico de alertas.
- Métrica *oldest unacked message age* da assinatura durante o *pipeline* de pé.
- O resultado da publicação duplicada (a linha não dobrou em `raw.inventory_movements_stream`).

## O que você saberá dizer depois

- "O CDC é Datastream lendo o *replication slot* do Cloud SQL; acompanhei o *backfill* virar CDC
  nos *logs* e medi o *freshness*."
- "Puxei mensagens cruas do tópico, publiquei uma duplicada e provei a idempotência no destino."
- "Fila e atraso de uma assinatura se leem em *unacked messages* e *oldest unacked age*."
