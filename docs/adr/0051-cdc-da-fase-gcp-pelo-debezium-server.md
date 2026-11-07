# ADR-0051 — Levar o CDC da fase GCP ao Pub/Sub pelo Debezium Server

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 07/11/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D69 |
| Substitui / é substituída por | — (troca a contrapartida GCP da captura declarada no ADR-0006 e no ADR-0020, que ficam como estão) |

## Contexto

O [ADR-0006](0006-streaming-de-estoque-com-cdc-e-beam.md) e o
[ADR-0020](0020-debezium-sobre-kafka-connect.md) declararam o **Datastream** como contrapartida GCP
do Debezium, e o [mapa de paridade](../arquitetura.md#5-mapa-de-paridade-local--gcp) encadeou
Datastream → Pub/Sub → `ReadFromPubSub`. Na abertura da Etapa 13 (06/11/2026), a página oficial de
destinos mostrou que o Datastream entrega **só** em BigQuery, Cloud Storage e tabelas Iceberg no
BigQuery ([destinations](https://docs.cloud.google.com/datastream/docs/destinations)) — Pub/Sub não é
destino. O encadeamento do mapa não existe como estava escrito.

Há um segundo problema, menos visível: o *parser* do caminho quente (`streaming/envelope.py`) lê o
envelope do Debezium (`op`, `after`, `source`), e o Datastream produz outro formato, com outro
metadado. E a garantia do [ADR-0019](0019-saldo-em-deltas-com-entrega-idempotente.md) — o mesmo
movimento nunca soma duas vezes, e o alerta só sai do evento que de fato entrou — é cumprida hoje
pelo `on conflict (movement_id) do nothing returning` do PostgreSQL.

A decisão precisava sair antes do Terraform da Etapa 13, que tem prazo duro (o fim da avaliação
gratuita da conta GCP).

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Debezium Server com *sink* `pubsub`**, num *pod* do GKE do Airbyte | *Sink* oficial (Debezium 3.7, [debezium-server](https://debezium.io/documentation/reference/stable/operations/debezium-server.html)); o mesmo conector declarado em `streaming/connectors/`; o mesmo envelope chega ao Beam, que muda só a leitura para `ReadFromPubSub`, como o mapa já dizia; custo marginal num *cluster* que a Etapa 13 já cria | O CDC deixa de ser gerenciado: *offsets* em disco a manter, *pod* a operar; a página não documenta a autenticação do *sink* nem a igualdade do envelope com o do Kafka Connect — as duas passam a ser prova, não premissa |
| Datastream → Cloud Storage → notificação Pub/Sub → Beam | Serviço gerenciado; o padrão documentado pela Google | O Beam passa a ler arquivos Avro/JSON com outro metadado: reescrita do *parser* e da ordenação — desenvolvimento, não replicação, dentro de um prazo duro |
| Datastream → BigQuery direto | O mais simples de operar | Some o Beam, a ramificação de alerta e o processamento contínuo: a paridade do caminho quente deixa de existir |

## Decisão

Na fase GCP, a captura do caminho quente é o **Debezium Server com *sink* `pubsub`**, lendo o log do
Cloud SQL for PostgreSQL com o mesmo conector da fase local, e o Beam no Dataflow lê o tópico com
`ReadFromPubSub`. **A garantia do ADR-0019 atravessa a troca sem afrouxar:** o *sink* no BigQuery é
idempotente por `movement_id` e emite alerta só do evento que entrou. O `insertId` do BigQuery e a
deduplicação do Dataflow **não** contam como essa garantia; o mecanismo que a cumpre no BigQuery —
o equivalente do `returning` — é escolhido e provado na Etapa 13 (D75) e registrado no
[*Streaming*](../streaming.md).

## Consequências

- **Positivas:** o envelope e o *parser* sobrevivem; a mudança no Beam fica na fonte, no *sink*, na
  semeadura e no publicador de alerta; o mapa de paridade volta a ter uma cadeia que existe.
- **Negativas:** sai o serviço gerenciado — o *pod* do Debezium Server e o disco dos seus *offsets*
  são infraestrutura a operar e a desmontar (o *slot* de replicação inclusive). O capítulo 07 do
  `NAVEGANDO_GCP`, escrito para o Datastream, fica parcialmente desatualizado. Autenticação sem
  chave, envelope igual e *offsets* persistentes são riscos aceitos até a prova da Etapa 13.
- **Paridade com o GCP:** é o objeto da decisão. Local: Debezium sobre Kafka Connect → Redpanda →
  Beam (Prism). GCP: Debezium Server → Pub/Sub → Beam (Dataflow). A troca para um CDC gerenciado
  fica para a operação continuada, com ADR próprio.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §4 e §5; [*Streaming*](../streaming.md)
  — a tabela de camadas; [Glossário](../glossario.md) — Datastream e Debezium Server;
  [Plano de Desenvolvimento](../plano_de_desenvolvimento.md) — os artefatos da Etapa 13.
