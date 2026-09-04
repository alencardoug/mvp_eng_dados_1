# ADR-0020 — Implantar o Debezium sobre Kafka Connect

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D29 |

## Contexto

O [ADR-0006](0006-streaming-de-estoque-com-cdc-e-beam.md) escolheu o Debezium sem decidir **como**
ele roda. Há duas formas de implantação, e elas diferem em quase tudo que importa depois: como o
conector é configurado, o que acontece quando ele cai, e onde o cursor é persistido — que o
[ADR-0019](0019-saldo-em-deltas-com-entrega-idempotente.md) resolveu delegando ao conector.

Enquanto o orçamento de 4 GB estava em vigor, o consumo de memória do Kafka Connect — cerca de 1 GB
a mais — era argumento decisivo. O [ADR-0014](0014-volume-por-proporcoes-e-fator-de-escala.md)
retirou essa restrição, e o princípio **P10** passou a ordenar as alternativas por fidelidade à
prática de produção. **A recomendação anterior se inverteu**, e este ADR registra a inversão.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Kafka Connect** | É como o Debezium roda em empresa: API REST para criar, pausar e reconfigurar conector sem derrubar nada; *offsets*, status e histórico de schema em tópicos; SMTs e múltiplos conectores no mesmo *cluster*. É o único caminho que exercita o operacional real de CDC — reinicialização de tarefa, evolução de schema, rebalanceamento | Cerca de 1 GB de memória a mais e mais uma peça no `docker-compose`; a API REST é mais uma superfície a entender |
| Debezium Server autônomo | Processo único, bem mais leve, menos peças para compreender | Configuração estática — mudar exige reiniciar; sem API de gestão; estado em arquivo local; sem SMTs. É a opção de laboratório, e o projeto rejeitou explicitamente o padrão de laboratório |
| Debezium embarcado na aplicação Beam | Menos infraestrutura e menor latência, sem transporte intermediário | Acopla captura e processamento no mesmo processo — uma falha derruba os dois — e elimina o buffer do Redpanda, que é o que permite reprocessar. Contraria o desenho do ADR-0006 |

## Decisão

O Debezium roda como conector sobre **Kafka Connect**, no mesmo `docker-compose` do Redpanda,
configurado por arquivo versionado e aplicado pela API REST.

Os tópicos internos de *offset*, status e histórico de schema são os previstos pelo
[ADR-0019](0019-saldo-em-deltas-com-entrega-idempotente.md) — esta decisão é o que os torna
possíveis.

## Consequências

- **Positivas:** o cursor e o histórico de schema passam a ser responsabilidade do conector, sem
  código do projeto; reconfigurar o conector deixa de exigir parada; evolução de schema na origem
  passa a ser um cenário exercitável e não uma surpresa da fase GCP.
- **Negativas:** aproximadamente 1 GB de memória a mais no ambiente local e mais um serviço a subir,
  configurar e diagnosticar. Custo aceito por **P10**, e viabilizado pelo ADR-0014.
- **Paridade com o GCP:** o Datastream substitui o par Kafka Connect + Debezium, gerenciando
  conector e cursor pelo mesmo modelo conceitual — configuração declarativa, estado do lado do
  serviço, reinício sem perda. O que se aprende operando o conector aqui se transfere; o que não se
  transfere é o arquivo de configuração, que é reexpresso em Terraform.
- **Documentos a atualizar:** [Streaming](../streaming.md) — a forma de implantação;
  [Arquitetura](../arquitetura.md) §3 e §5 — o componente e a paridade;
  [Execução Local](../execucao_local.md) — o serviço a subir;
  [Capacidade e Recuperação](../capacidade_e_recuperacao.md) — a memória do ambiente.
