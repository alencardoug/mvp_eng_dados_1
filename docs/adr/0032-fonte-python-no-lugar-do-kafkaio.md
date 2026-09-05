# ADR-0032 — Ler o transporte com fonte Python, e não com o KafkaIO do Beam

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na implementação da Etapa 7) |
| Substitui / é substituída por | — |

## Contexto

O [ADR-0006](0006-streaming-de-estoque-com-cdc-e-beam.md) escolheu o Apache Beam por um motivo
declarado: *"o mesmo código roda no `DirectRunner` local e no Dataflow gerenciado — é o único que
entrega paridade literal de código"*. Essa é a aplicação mais forte do princípio **P4** no projeto.

O Beam oferece `ReadFromKafka` para ler o transporte. Ele não é uma transformação Python: é
*cross-language*, implementada em Java. Usá-la exige **duas** peças Java em execução — um serviço de
expansão, na construção do *pipeline*, e um *harness* do SDK Java em contêiner, na execução.

A máquina da fase local não tem Java instalado, e o orçamento é de 4 CPUs já compartilhadas por
Redpanda, Kafka Connect, três instâncias PostgreSQL e o próprio processo Python. O
[Streaming §2](../streaming.md) já declara, porém, o critério que resolve a questão: *"trocam-se as
pontas — origem e destino —, não a lógica"*. A pergunta é se a ponta de leitura pode ser uma dessas
pontas.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **`DoFn` divisível não-limitado, em Python** | A lógica — janela por tempo de evento, *watermark*, *allowed lateness*, gatilhos, deduplicação, estado por chave, ramificação de alerta e destino — permanece Beam puro e idêntica à que roda no Dataflow. A ponta trocada é a mesma que o Streaming §2 já previa trocar: no Dataflow ela vira `ReadFromPubSub`, e nenhuma outra linha muda. E o `DoFn` implementa a mesma semântica que o KafkaIO implementa: restrição por partição, avanço por *offset*, autocheckpoint e *watermark* estimado por atraso limitado | A ponta de leitura local **não** é a classe que o Beam oferece, então o que se aprende operando-a é a semântica, não a API. Cerca de 120 linhas de código de fronteira que passam a ser do projeto, e o projeto passa a ser dono dos defeitos delas |
| `ReadFromKafka` com as peças Java em contêiner | Paridade máxima na ponta de leitura: a classe é a que o Beam oferece e a que se usaria em produção | Somaria dois contêineres Java (~1,7 GB) ao Redpanda e ao Kafka Connect, em 4 CPUs — o mesmo teto que já quase inviabilizou a Etapa 5. E move o esforço da etapa para depuração do arcabouço de portabilidade do Beam, que não é o assunto que a etapa existe para exercitar |
| Instalar Java na máquina e rodar o serviço de expansão no host | Elimina um dos dois contêineres | Não elimina o *harness*, que continua sendo contêiner; e acrescenta uma dependência de máquina fora do `docker-compose`, contra o **P2** — o ambiente deixa de subir do zero em máquina limpa |
| Consumidor Python simples, sem Beam | O mais simples de tudo | Foi rejeitado no ADR-0006 e continua rejeitado: obrigaria a implementar à mão *watermarks*, janelas e tolerância a atraso, que são exatamente os conceitos que o fluxo existe para exercitar |

## Decisão

A leitura do transporte é um **`DoFn` divisível não-limitado escrito em Python**, em
`mvp_ed1/streaming/transport.py`. Todo o resto do *pipeline* é Beam idiomático e não sabe de onde os
eventos vieram.

O limite fica registrado onde é lido: no cabeçalho do módulo e na seção de **limites honestos** do
[Streaming §2.1](../streaming.md), ao lado das outras ressalvas da execução local.

## Consequências

- **Positivas:** a etapa cabe na máquina, e a lógica — que é o que se leva para o Dataflow —
  permanece intacta e testável. O `DoFn` divisível obrigou a entender o contrato de restrição e
  *watermark* que o KafkaIO esconde, e duas armadilhas reais só apareceram por isso: um leitor
  criado em `setup` é compartilhado por invocações concorrentes do runner e reposiciona a si mesmo,
  e uma partição de log não admite divisão dinâmica — a metade de um intervalo aberto é um offset
  que não existe.
- **Negativas:** a ponta de leitura é código do projeto, e defeito nela é do projeto. A paridade de
  **código** na leitura deixa de existir; sobra a paridade de **semântica**, que é menos do que o
  ADR-0006 prometeu e precisa ser dito com essas palavras. Quem for para o Dataflow troca a fonte
  por `ReadFromPubSub` e não reaproveita nada deste módulo — o que, note-se, também seria verdade
  com o `ReadFromKafka`.
- **Paridade com o GCP:** direta e, neste ponto, mais simples. `ReadFromPubSub` é transformação
  **nativa do SDK Python**, sem Java e sem serviço de expansão: a ponta que aqui é código do projeto
  vira uma linha de biblioteca lá. O módulo de transporte é o único arquivo do caminho quente que
  não atravessa para a nuvem, e é por desenho.
- **Documentos a atualizar:** [Streaming](../streaming.md) §2.1 — o limite honesto da ponta de
  leitura; [Arquitetura](../arquitetura.md) — o mapa de paridade da camada de processamento.
