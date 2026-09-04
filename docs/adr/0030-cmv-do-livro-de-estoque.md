# ADR-0030 — Tirar o custo do produto vendido do livro de estoque

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 6) |
| Substitui / é substituída por | — |

## Contexto

A pergunta **P08** — "qual o lucro bruto e a margem por categoria e mês?" — exige um custo, e a
origem oferece três lugares onde ele existe, com significados diferentes:

| Onde | O que significa |
|---|---|
| `purchase_order_items.unit_cost` | O custo **negociado** com o fornecedor, no momento da compra |
| `goods_receipt_items.unit_cost` | O custo no **recebimento físico**, que pode divergir do negociado |
| `inventory_movements.unit_cost` | O custo **do que saiu**, registrado no próprio evento de saída |

Escolher entre eles não é detalhe de implementação: é a decisão que determina todo número de margem
do projeto, e a que decide se a margem de 2024 pode mudar por causa de uma compra feita hoje.

Há um segundo problema, de modelagem: `fact_sales_order_item` tem grão de **item de pedido** e o
livro de estoque tem grão de **movimento**, ligado à remessa e não ao item. Juntar os dois linha a
linha exigiria atravessar `shipment_items` — que é escopo da Etapa 8 — e misturaria dois grãos na
mesma consulta, que é o erro clássico de modelagem dimensional.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Custo do movimento de saída** | Historicamente correto **por construção**: o custo foi registrado no instante da saída e nada depois o move. Os 7.012 movimentos de venda já o carregam. E resolve o problema de grão sem juntá-lo: a margem vira *drill across* entre duas fatos por dimensões conformadas | Exige que as duas fatos concordem nas dimensões, e um teste de reconciliação para provar que concordam. Uma dimensão que exista em uma e não na outra torna o recorte impossível — e é assim que se descobre que a conformação era só intenção |
| Custo médio ponderado por SKU | Convenção contábil mais comum no varejo brasileiro; simples de explicar e de auditar | O número é **corrente**: uma compra feita hoje muda a margem de 2024. É exatamente o problema que o [ADR-0029](0029-exclusao-logica-como-marca-na-dimensao.md) acabou de resolver do lado da exclusão lógica, reintroduzido do lado do custo |
| Custo da última compra | O mais barato de calcular | A versão pior da anterior: uma negociação pontual, boa ou ruim, reescreve a margem de dois anos |
| FIFO percorrendo o livro | O mais fiel ao fluxo físico, e exercitaria o livro de eventos em profundidade | Exige janela ordenada por par armazém/SKU sobre 13 mil movimentos, e o ganho de precisão é indistinguível nesta escala. Complexidade sem valor demonstrável, que o Termo §8 veda |

## Decisão

**O custo do produto vendido é o do movimento de saída do livro de estoque.**

`fact_inventory_movement` carrega `cost_amount = |quantity_delta| × unit_cost` como medida aditiva.
O CMV de um recorte é a soma desse valor nos movimentos de tipo `sale_dispatch`.

**A margem é calculada por *drill across*, não por *join***. Cada fato é agregada ao seu próprio
grão até a granularidade comum — data, produto, categoria — e só então as duas são combinadas:

```
receita  ← fact_sales_order_item,  agregada por (data, produto)
CMV      ← fact_inventory_movement, agregada por (data, produto), tipo sale_dispatch
margem   ← receita − CMV, na granularidade comum
```

Nenhuma linha de uma fato encosta em linha da outra. É o que torna a comparação legítima apesar de
os grãos serem diferentes, e é o que a expressão "dimensão conformada" significa na prática.

**A reconciliação é teste, não confiança:** a soma de `cost_amount` dos movimentos de venda precisa
fechar com a saída física registrada no livro, e a data de saída é a do **movimento**, não a do
pedido — despachar em janeiro o que foi vendido em dezembro é normal, e a margem de janeiro é que
carrega o custo.

## Consequências

- **Positivas:** a margem histórica para de depender do preço de compra de hoje; o livro de eventos
  ganha uma segunda razão de existir além do *streaming*; e o projeto passa a exercitar *drill
  across* entre fatos de grãos diferentes, que é o teste real de uma dimensão conformada.
- **Negativas:** a margem fica sujeita ao **descasamento temporal** entre venda e expedição — um
  pedido de dezembro despachado em janeiro põe receita e custo em meses diferentes. É o
  comportamento contábil correto por competência do estoque, e é **contraintuitivo**: quem olhar
  margem mensal sem saber disso vai achar que há erro. Fica dito na definição do conceito e na
  descrição da view. E há um segundo custo: pedido que ainda não foi despachado tem receita sem
  custo, então a margem de um mês só estabiliza quando a expedição fecha.
- **Paridade com o GCP:** nenhuma. É soma de coluna e agregação por dimensão conformada; o BigQuery
  faz igual. O *drill across* inclusive se beneficia lá, porque duas agregações separadas
  particionadas por data custam menos que um *join* entre fatos.
- **Documentos a atualizar:** [Glossário de Negócio](../glossario_de_negocio/) — os conceitos de
  lucro bruto e custo do produto vendido; [Modelo de Dados](../modelo_de_dados.md) §3.1 — a medida
  de custo em `fact_inventory_movement`; [Qualidade de Dados](../qualidade_de_dados.md) — o teste de
  reconciliação entre as duas fatos.
