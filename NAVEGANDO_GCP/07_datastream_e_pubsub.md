# 07 — Debezium Server e Pub/Sub: o caminho quente, até o transporte

> Reescrito em 09/11/2026: o Datastream saiu da arquitetura ([ADR-0051](../docs/adr/0051-cdc-da-fase-gcp-pelo-debezium-server.md),
> D69), porque não entrega em Pub/Sub. O nome do arquivo ficou, para não quebrar referências.
>
> **Quando fazer.** **Ter 10**, nos passos 2 a 9 e 21 a 29 da §6.8; os tópicos e as assinaturas já existem e dá para olhá-los hoje, ainda sem mensagens de movimentos.

**Em uma frase.** O mesmo conector Debezium da fase local, agora como **Debezium Server** num *pod*
do GKE, lê o log do Cloud SQL (*logical decoding*) e publica cada mudança de
`oltp.inventory_movements` no Pub/Sub, que é o Redpanda gerenciado: o tópico guarda os eventos até
o Dataflow (cap. 08) consumir.

**Quanto custa e por quê.** O Pub/Sub cobra por volume, e este cabe no nível gratuito; o *pod* do
Debezium roda nos nós do GKE já contados no cap. 05 (os dois na
[Capacidade §2.14](../docs/capacidade_e_recuperacao.md#214-a-estimativa-da-janela-da-etapa-13--07112026)). O que custa aqui é operar: o *pod* e o disco dos *offsets* são
infraestrutura sua, não um serviço gerenciado.

**Onde fica.** Debezium: ☰ → *Kubernetes Engine* → *Workloads*, *namespace* `debezium`. Pub/Sub: ☰ →
*Pub/Sub* → *Topics*, *Subscriptions* (`console.cloud.google.com/cloudpubsub/topic/list`).

**O que é deste projeto aqui.** O *pod* com a conta `debezium-server` (*Workload Identity*, agindo
como `mvp-streamer`, sem chave); o *slot* de replicação `mvp_inventory_movements` no Cloud SQL; três
tópicos — `mvp.oltp.inventory_movements` (eventos), `mvp.alerts.inventory_low_stock` (alertas) e
`mvp-heartbeat.mvp` — e duas assinaturas: `mvp.oltp.inventory_movements.beam`, do Dataflow, e
`mvp.alerts.inventory_low_stock.observacao`, que os alvos do roteiro leem.

## Roteiro guiado — Debezium Server

1. **O estado, pelo alvo do roteiro.** `make gcp-debezium-status` (§6.8, passo 2): *pod*, fim do log e
   *slot*. *O que olhar:* `Running` e `slot mvp_inventory_movements: ativo`. *Por quê:* *slot* ativo é
   o Debezium conectado à origem.
2. **Workloads → o *pod*.** Reinícios, CPU e memória, e o disco dos *offsets*. *Por quê:* os
   *offsets* em disco são o que deixa o *pod* reiniciar sem repetir o *snapshot*; a prova disso é o
   passo 24 da §6.8.
3. **Logs.** `resource.type="k8s_container"` e `resource.labels.namespace_name="debezium"`. Procure o
   fim do *snapshot* e a passagem para o *streaming*. *Por quê:* prova de que o *snapshot* fechou e o
   contínuo começou.
4. **No Cloud SQL (cap. 03):** `select * from pg_replication_slots` e `pg_publication_tables`.
   *Por quê:* os dois lados da mesma coisa.

## Roteiro guiado — Pub/Sub

5. **Topics → `mvp.oltp.inventory_movements`.** *Details* (retenção), *Subscriptions*, **Metrics**
   (*publish rate*, *message size*). *Por quê:* mostra o volume que o Debezium publicou.
6. **Subscriptions → `.beam`.** *Details*: *ack deadline*, retenção. **Metrics**: *unacked messages*
   (fila) e **oldest unacked message age** (atraso). *Por quê:* fila crescendo com Dataflow de pé = o
   *job* não acompanha; fila crescendo com Dataflow parado é o esperado, e é o que os passos 21 a 23
   da §6.8 medem.
7. **Ver a mensagem crua, em lugar seguro.** Não use *Pull* na `.beam`: ela é a fila que os passos
   21 a 26 da §6.8 contam. Só na `.observacao`, e **sem confirmar** (*Enable ack messages* desligado),
   porque o `make gcp-quente-conferir` lê os alertas dela. *Por quê:* é o `rpk topic consume` da fase
   local.
8. **A idempotência, por quem já a prova.** Não publique à mão no tópico real: o passo 26 da §6.8
   confere "nem perdido, nem repetido". O `make gcp-quente-prova` (§6.8, passo 3) testa duplicatas em
   recursos temporários; leia o relatório em `data/medicoes/etapa_13/g23/`. *Por quê:* a garantia do
   ADR-0019 no BigQuery é a D75.

## Onde aciona, onde registra, o que controla

- **Aciona:** o Terraform instala o *release* (§6.7, passo 5); `make gcp-debezium-reiniciar` reinicia
  o *pod*; os movimentos vêm de `make gcp-quente-produzir` ou `make gcp-quente-latencia`.
- **Registra:** *logs* do *pod* (Cloud Logging), métricas do tópico e da assinatura, `pg_replication_slots`.
- **Controla:** o *chart* em `terraform/charts/debezium-server`; retenção, *ack deadline* e IAM por
  tópico e assinatura, no Terraform.

## Armadilhas

- *Slot* vivo sem consumidor **retém WAL** no Cloud SQL: o disco cresce. O alvo
  `make gcp-desmonte-slot` tira o *slot* no desmonte (§6.5, passo 3).
- Mensagem não confirmada é reentregue quando o consumidor volta. A idempotência trata, mas conta em
  `eventos_duplicados`.
- Assinatura criada à mão fica fora do Terraform e reprova o inventário de quinta. Para praticar, use
  o bloco 10.1 do laboratório, no `mvp-ed1-estudo`.

## Evidência a levar

- A saída de `make gcp-debezium-status` com o *slot* ativo; a medição de latência da §6.8, passo 27.
- Métrica *oldest unacked message age* da `.beam` com o Dataflow parado e de pé.
- Uma mensagem de alerta da `.observacao`.
- O relatório de `make gcp-quente-prova`.

## O que você saberá dizer depois

- "O Datastream não entrega em Pub/Sub; o CDC é Debezium Server no GKE, sem chave, lendo o *slot* do
  Cloud SQL."
- "Parei o Dataflow, vi a fila crescer na assinatura e provei que cada movimento entrou uma vez."
- "Fila e atraso de uma assinatura se leem em *unacked messages* e *oldest unacked age*."
