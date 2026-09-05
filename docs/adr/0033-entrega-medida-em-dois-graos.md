# ADR-0033 — Medir a entrega em dois grãos, e nomear os dois no glossário

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 8) |
| Substitui / é substituída por | — |

## Contexto

A Etapa 8 tem entre os seus critérios de conclusão dois que se cruzam: *"pedido dividido em mais de
uma remessa tratado corretamente"* e *"prazo prometido e realizado definidos no glossário"*. Eles se
cruzam porque **o pedido dividido não tem um prazo prometido**.

O gerador reparte 22% dos pedidos em duas remessas (`remessa_dividida`, em
`src/mvp_ed1/generator/geracao.yml`), e cada remessa recebe a sua própria promessa, calculada a
partir da modalidade da transportadora que a leva —
`prazo_prometido_dias: {standard: [4, 9], express: [2, 4], same_day: [0, 1]}`. O pedido dividido tem
portanto **duas** promessas, possivelmente de modalidades diferentes, e duas chegadas. Perguntar
"esse pedido chegou no prazo?" sem dizer em qual grão é uma pergunta sem resposta única.

As duas perguntas da etapa pedem grãos diferentes, e é isso que fecha a questão:

| Pergunta | O que corta | Onde o atributo mora |
|---|---|---|
| [P13](../glossario_de_negocio/perguntas_de_negocio.md) — fração de entregas no prazo | transportadora e modalidade | na **remessa**: `carrier_id` e `service_level` |
| [P14](../glossario_de_negocio/perguntas_de_negocio.md) — tempo médio entre pedido e entrega | região e modalidade | o marco inicial é do **pedido**; a chegada, da remessa |

O [ADR-0018](0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md) já fixou que fatos e views
nascem das perguntas. A pergunta aqui é anterior: qual é a **unidade medida** antes de escolher o
fato.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Dois conceitos: *entrega no prazo* na remessa e *ciclo de entrega* no pedido** | Cada pergunta é respondida no grão em que ela existe. P13 corta por transportadora e modalidade, que são atributos da remessa, e não precisa inventar uma transportadora para o pedido levado por duas. P14 mede o que o cliente sente — do pedido feito até a última caixa na porta. E o pedido dividido deixa de ser caso de borda escondido: vira o teste que separa os dois conceitos, porque é exatamente onde eles divergem | Dois termos no glossário, com a disciplina permanente de nunca somar um com o outro. Uma taxa medida em remessas e uma média medida em pedidos não se combinam, e quem cruzar as duas views produz número sem significado |
| Só no grão da remessa | Um conceito, um fato, nada a explicar. É o mais barato | P14 passaria a responder *"tempo até a chegada de uma remessa qualquer"*, não *"até o pedido chegar"*. Em pedido dividido a primeira metade chega antes, e a média fica **otimista por construção** — o erro é sistemático, não ruído, e cresce com a fração de pedidos divididos |
| Só no grão do pedido | Reflete o cliente nas duas perguntas, e o pedido dividido está no prazo só quando a última remessa chega — que é a leitura honesta | P13 pede corte por transportadora e modalidade. No pedido levado por duas transportadoras o corte não tem valor único, e responder exigiria escolher uma delas por regra arbitrária. A pergunta ficaria sem resposta defensável |
| Um conceito com parâmetro de grão | Um só nome, calculado nos dois níveis conforme o uso | É o pior dos dois: o número muda de significado sem mudar de nome, que é precisamente o defeito que um glossário existe para impedir |

## Decisão

A entrega é medida em **dois conceitos nomeados e separados**:

- **Entrega no prazo** (`on_time_delivery`) — grão da **remessa**. Uma remessa está no prazo quando
  a sua chegada não é posterior à sua `estimated_delivery_at`. É o conceito de P13, e o denominador
  são as remessas entregues, não as despachadas.
- **Ciclo de entrega** (`order_to_delivery_cycle`) — grão do **pedido**. Conta de `placed_at` até a
  chegada da **última** remessa do pedido. Pedido com alguma remessa ainda não entregue não tem
  ciclo fechado e fica fora da média. É o conceito de P14.

Cada um vira um arquivo no [Glossário de Negócio](../glossario_de_negocio/), e cada definição diz
explicitamente que o outro existe e em que grão vive.

## Consequências

- **Positivas:** as duas views respondem exatamente o que foi perguntado, sem cláusula escondida. O
  pedido dividido — que o gerador produz de propósito, em 22% dos casos — passa a ter teste próprio:
  o ciclo do pedido é, por construção, maior ou igual ao da sua remessa mais lenta, e essa
  desigualdade é verificável. E o projeto exercita um caso real de **fato de grão diferente da
  pergunta**, que é o mesmo músculo do *drill across* do
  [ADR-0030](0030-cmv-do-livro-de-estoque.md).
- **Negativas:** dois números que parecem a mesma coisa e não são. A taxa de P13 e a média de P14
  não se cruzam, não se somam e podem contar populações distintas — um pedido com uma remessa
  entregue e outra extraviada aparece em P13 e **não** aparece em P14. Isso fica escrito nas duas
  definições e na descrição das duas views, e ainda assim é o custo aceito aqui.
- **Paridade com o GCP:** nenhuma. É escolha de grão e agregação; o BigQuery calcula igual. A
  definição viaja como bloco `docs` importado pelo dbt, do mesmo jeito nas duas fases.
- **Documentos a atualizar:** [Glossário de Negócio](../glossario_de_negocio/) — os dois conceitos
  novos e o índice; [Modelo de Dados](../modelo_de_dados.md) — o grão declarado de
  `fact_shipment_item`; [Qualidade de Dados](../qualidade_de_dados.md) — o teste do pedido dividido.
