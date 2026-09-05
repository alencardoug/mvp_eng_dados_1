# Registro de Decisões (ADR)

> **O que vive aqui:** as decisões do projeto — as tomadas (um arquivo ADR cada) e as ainda
> abertas, quando houver (seção 3).
>
> **O que não vive aqui:** a arquitetura resultante (ver [Arquitetura](../arquitetura.md)) e a
> ordem de execução (ver [Plano de Desenvolvimento](../plano_de_desenvolvimento.md)).

Um **ADR** registra uma decisão relevante, o contexto que a motivou, as alternativas consideradas e
as consequências aceitas. O objetivo não é documentar o que foi feito, e sim **por que** — de modo
que a decisão possa ser revista com conhecimento de causa, inclusive na replicação para o GCP.

---

## 1. Como funciona

1. Enquanto a escolha está aberta, ela é uma **decisão pendente** (`Dnn`) na tabela da seção 3.
2. Quando é decidida, nasce um arquivo `NNNN-titulo-em-kebab-case.md` a partir do
   [`0000-template.md`](0000-template.md), e a pendência sai da tabela.
3. Um ADR aceito **nunca é apagado nem reescrito**. Se for revertido, passa a `Substituída` e o
   novo ADR referencia o anterior.
4. Toda *mudança relevante*, no sentido do [Termo de Abertura](../../Abertura_de_projeto.md), exige
   um ADR.
5. Todo ADR declara a sua **contrapartida na fase GCP**. Decisão sem equivalente na nuvem não é
   aceitável (princípio **P4**).

A numeração `Dnn` é sequencial mas **não é densa**: uma lacuna não significa decisão perdida.
**D19** nunca existiu — verificado em 03/09/2026 contra todas as revisões do repositório — e o
identificador não será reaproveitado, para que nenhuma referência antiga passe a apontar para outra
decisão.

**Estados:** `Proposta` · `Aceita` · `Rejeitada` · `Substituída`

---

## 2. Decisões registradas

| ADR | Título | Estado | Resolve |
|---|---|---|---|
| [0001](0001-registrar-decisoes-em-adr.md) | Registrar decisões de arquitetura em ADR | Aceita | — |
| [0002](0002-dominio-marketplace-omnichannel.md) | Adotar um marketplace de varejo *omnichannel* como domínio | Aceita | D01 |
| [0003](0003-stack-airbyte-dbt-airflow.md) | Adotar Airbyte, dbt e Airflow desde a fase local | Aceita | D06, D07, D08 |
| [0004](0004-terraform-como-iac.md) | Usar Terraform para levar o ambiente local ao GCP | Aceita | D12 |
| [0005](0005-geracao-com-faker-orientada-a-configuracao.md) | Gerar dados com Faker por meio de um motor orientado a configuração | Aceita | D05 |
| [0006](0006-streaming-de-estoque-com-cdc-e-beam.md) | Incluir um fluxo de streaming de estoque com CDC e Apache Beam | Aceita | Mecanismo de baixa latência |
| [0007](0007-catalogo-como-codigo.md) | Manter o catálogo de dados como código | Aceita | Ferramenta de catálogo local |
| [0008](0008-schemas-do-armazem.md) | Fixar os schemas do armazém e separar estágio de schema | Aceita | D02 |
| [0009](0009-sqlalchemy-para-acesso-a-dados.md) | Usar SQLAlchemy para o acesso a dados em Python | Aceita | D03 |
| [0010](0010-alembic-para-migracoes.md) | Usar Alembic para as migrações de schema | Aceita | D04 |
| [0011](0011-classificacao-e-papeis-de-acesso.md) | Fixar os níveis de classificação e os papéis de acesso | Aceita | D09 |
| [0012](0012-repositorio-com-pacote-instalavel.md) | Organizar o repositório com `src/` como pacote instalável | Aceita | D10 |
| [0013](0013-nomenclatura-por-prefixo-de-tipo.md) | Nomear objetos de banco com prefixo por tipo | Aceita | D13 |
| [0014](0014-volume-por-proporcoes-e-fator-de-escala.md) | Parametrizar o volume por proporções e fator de escala | Aceita | D26 |
| [0015](0015-sincronizacao-e-exclusoes.md) | Fixar o critério de sincronização e o tratamento de exclusões | Aceita | D20, D21 |
| [0016](0016-materializacao-por-camada.md) | Materializar por camada, com incremental como exceção justificada | Aceita | D23 |
| [0017](0017-chaves-substitutas-e-scd.md) | Derivar chaves substitutas por hash e historizar com snapshots | Aceita | D25 |
| [0018](0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md) | Derivar fatos e views de consumo das perguntas de negócio | Aceita | D24, D27 |
| [0019](0019-saldo-em-deltas-com-entrega-idempotente.md) | Manter o saldo de estoque como deltas imutáveis, com entrega idempotente | Aceita | D16, D17, D18 |
| [0020](0020-debezium-sobre-kafka-connect.md) | Implantar o Debezium sobre Kafka Connect | Aceita | D29 |
| [0021](0021-procedencia-no-empilhamento.md) | Carregar a procedência em coluna própria no empilhamento | Aceita | D15 |
| [0022](0022-catalogo-declarativo-de-falhas-do-legado.md) | Declarar as falhas do legado em catálogo único | Aceita | D28 |
| [0023](0023-escopo-do-schema-governance.md) | Restringir o schema `governance` a controle e auditoria | Aceita | D14 |
| [0024](0024-airbyte-e-airflow-no-gcp.md) | Replicar Airbyte e Airflow no GCP preservando a paridade | Aceita | D11, D22 |
| [0025](0025-policy-tags-por-fluxo-automatizado.md) | Aplicar as policy tags por fluxo automatizado | Aceita | Q1 |
| [0026](0026-uv-para-ambiente-e-dependencias.md) | Adotar `uv` para o ambiente e as dependências Python | Aceita | Ambiente e interpretador Python |
| [0027](0027-configuracao-do-gerador-em-yaml.md) | Declarar o gerador em YAML, com o piso derivado dos modelos | Aceita | Formato e piso da configuração |
| [0028](0028-fato-de-carrinho-para-o-funil.md) | Acrescentar uma fato de carrinho para o funil de conversão | Aceita | Lacuna do funil de conversão |
| [0029](0029-exclusao-logica-como-marca-na-dimensao.md) | Carregar a exclusão lógica como marca até a dimensão | Aceita | D30 |
| [0030](0030-cmv-do-livro-de-estoque.md) | Tirar o custo do produto vendido do livro de estoque | Aceita | Origem do CMV |
| [0031](0031-aterrissagem-do-caminho-quente-em-raw.md) | Aterrissar o caminho quente em `raw` e transformar o Airbyte em reconciliação | Aceita | Aterrissagem, *snapshot* e papel do Airbyte |
| [0032](0032-fonte-python-no-lugar-do-kafkaio.md) | Ler o transporte com fonte Python, e não com o KafkaIO do Beam | Aceita | Ponta de leitura sem Java |
| [0033](0033-entrega-medida-em-dois-graos.md) | Medir a entrega em dois grãos, e nomear os dois no glossário | Aceita | Grão da medição de entrega |
| [0034](0034-entrega-do-livro-de-eventos.md) | Tirar a data de entrega do livro de eventos, não da coluna da remessa | Aceita | Procedência da data de entrega |
| [0035](0035-aposentar-dimensoes-sem-pergunta.md) | Aposentar `dim_time` e `dim_currency`, que nenhuma pergunta recorta | Aceita | Escopo do inventário dimensional |
| [0036](0036-recompra-ancorada-no-pedido.md) | Ancorar a recompra pós-atendimento no pedido | Aceita | Âncora da janela de P16 |

---

## 3. Decisões pendentes

| # | Decisão | Levantada em | Efeito de não decidir |
|---|---|---|---|
| **D31** | Corrigir no gerador a remessa que nasce sem item, ou aceitá-la como caso de borda | Etapa 8, ao construir `fact_shipment_item` | A taxa de P13 conta 3.141 entregas onde `trusted.shipments` diz 3.221, e a diferença precisa ser explicada a cada leitura |

**D31** nasceu de um achado, não de uma escolha de projeto: 91 das 3.647 remessas não têm item
nenhum — todas em pedidos divididos, quando cada item do pedido tem quantidade 1 e o repartidor dá
zero unidades ao primeiro lote. Caixa vazia é estado que a operação real não produz (**P10**).

O que a torna decisão, e não conserto: a correção é no gerador da **Etapa 4**, e mexer no consumo de
aleatoriedade dele desloca a sequência — quanto disso alcança `shipments`, `delivery_events` e o que
depende deles **não foi medido**, e por isso não é afirmado (**P5**). Aceitar a correção é aceitar
refazer e reescrever as medições registradas. Enquanto a decisão não vem, o teste
`remessa_leva_ao_menos_um_item` roda com severidade `warn` a cada `build`: o número fica à vista sem
travar a entrega.

As decisões de abertura das Etapas 8 e 9 foram fechadas no mesmo dia em que foram levantadas, por
interrogatório: em que grão a entrega é medida, quando o pedido se divide em duas remessas
([ADR-0033](0033-entrega-medida-em-dois-graos.md)); de onde sai a data de entrega realizada — do
livro de eventos, não da coluna da remessa ([ADR-0034](0034-entrega-do-livro-de-eventos.md)); o que
fazer com as duas dimensões que nenhuma pergunta recorta
([ADR-0035](0035-aposentar-dimensoes-sem-pergunta.md)); e de que marco corre a janela de recompra de
P16 ([ADR-0036](0036-recompra-ancorada-no-pedido.md)).

Antes delas, as três que a Etapa 7 levantou foram fechadas do mesmo modo: onde o caminho quente
aterrissa, quem faz o *backfill* dele e o que acontece com o *stream* do Airbyte — todas no
[ADR-0031](0031-aterrissagem-do-caminho-quente-em-raw.md) —, e como o *pipeline* lê o transporte sem
Java na máquina, no [ADR-0032](0032-fonte-python-no-lugar-do-kafkaio.md).

As duas primeiras nasceram de **documentos aceitos que se contradiziam**: o ADR-0008 proíbe ler de
camada posterior, o `streaming.md` desenhava o Beam escrevendo em `analytics`, e o ADR-0016
concedera a exceção incremental justamente porque o *streaming* alimentaria a fato. Contradição
entre decisões vigentes é decisão nova, e volta ao Owner — não se resolve escolhendo em silêncio
qual documento vale.

O procedimento — registrar como pendência, devolver ao Owner, e só então implementar — está na
seção 1.
