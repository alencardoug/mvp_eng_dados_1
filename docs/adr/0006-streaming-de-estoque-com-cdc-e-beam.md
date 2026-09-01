# ADR-0006 — Incluir um fluxo de streaming de estoque com CDC e Apache Beam

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisões pendentes resolvidas | Mecanismo de baixa latência e transporte |

## Contexto

Um pipeline exclusivamente *batch* não exercita as questões mais difíceis de dados: ordenação,
duplicidade, eventos atrasados e correção retroativa de janelas já fechadas. O Owner decidiu
incluir um fluxo contínuo pequeno.

A restrição é o princípio **P6** (simplicidade arquitetural): o fluxo precisa caber em um único
domínio e não pode contaminar o restante do projeto. `inventory_movements` é a candidata natural —
é a única tabela modelada como livro de eventos imutáveis, com inserção apenas e correção por
evento compensatório.

A restrição mais forte, porém, é o princípio **P4**: o fluxo tem de existir nas duas fases sem
reprojeto.

## Alternativas consideradas

| Papel | Alternativas | Por que a escolhida venceu |
|---|---|---|
| Captura | **Debezium** · *polling* por `updated_at` · gatilhos no banco | Lê o log de transações: sem consulta pesada na origem e sem perder eventos entre execuções; equivale ao Datastream na nuvem |
| Transporte | **Redpanda** · Kafka · RabbitMQ | Compatível com a API do Kafka e muito mais leve em Docker; caminho direto para Pub/Sub |
| Processamento | **Apache Beam** · consumidor Python próprio · Flink · Spark Structured Streaming | O mesmo código roda no `DirectRunner` local e no Dataflow gerenciado — é o único que entrega paridade literal de código |

Um consumidor Python próprio seria mais simples de escrever, mas teria de ser reescrito para a
nuvem e obrigaria a implementar à mão *watermarks*, janelas e tolerância a atraso — exatamente os
conceitos que o fluxo existe para exercitar.

## Decisão

O fluxo de streaming cobre **apenas `inventory_movements`**, com:

- **Debezium** capturando o log de transações do PostgreSQL (Datastream no GCP);
- **Redpanda** como transporte (Pub/Sub no GCP);
- **Apache Beam** em Python, com `DirectRunner` local e Dataflow no GCP;
- destino em tabela de saldo em tempo real, unificada às fotografias *batch* por uma view de
  consumo;
- uma ramificação que emite alerta quando o saldo de um SKU cai abaixo de um limiar.

O Airbyte permanece responsável pelo *backfill*, pela reconciliação periódica e por todas as demais
39 tabelas.

## Consequências

- **Positivas:** o projeto passa a ter caminho quente e caminho frio convivendo sob o mesmo
  contrato de consumo, exercitando tempo de evento, *watermarks*, *allowed lateness*, deduplicação
  e entrega *at least once* — com paridade literal de código entre as fases.
- **Negativas:** três componentes novos no ambiente local e a curva de aprendizado do Beam, que tem
  sintaxe própria e verbosa — risco **R13**. Mitigações: escopo de um único domínio; o fluxo só
  entra na Etapa 7, com o *batch* já funcionando; o *boilerplate* é gerado com apoio de IA e
  revisado.
- **Paridade com o GCP:** cada componente tem equivalente direto, registrado no
  [mapa de paridade](../arquitetura.md#5-mapa-de-paridade-local--gcp).
- **Documentos a atualizar:** [Streaming](../streaming.md), [Arquitetura](../arquitetura.md),
  [Modelo de Dados](../modelo_de_dados.md), [Qualidade de Dados](../qualidade_de_dados.md),
  [Termo de Abertura](../../Abertura_de_projeto.md) — o streaming deixa de estar fora do escopo.
