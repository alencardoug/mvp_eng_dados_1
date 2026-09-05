# Perguntas de Negócio

> **O que vive aqui:** as perguntas que o datamart existe para responder, e o que cada uma exige do
> modelo dimensional — fato, medidas com a sua aditividade, dimensões e a view de consumo.
>
> **O que não vive aqui:** a definição dos conceitos que as perguntas usam (ver os arquivos de
> conceito neste mesmo diretório); o grão e a contagem de cada fato (ver
> [Modelo de Dados](../modelo_de_dados.md#3-modelo-dimensional--26-tabelas-em-analytics)); a
> materialização das views (ver [ADR-0016](../adr/0016-materializacao-por-camada.md)).

| Campo | Informação |
|---|---|
| Método | Perguntas antes do SQL ([ADR-0018](../adr/0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md)) |
| Quantidade | 16 |
| Situação | **P01 a P11** com view construída; P12 a P16 nas Etapas 7 a 9 |
| Última revisão | 04/09/2026 |

---

## 1. Como ler esta lista

Uma pergunta é concreta quando nomeia a **métrica**, o **recorte** e o **período**. *"Qual a margem
por categoria e canal no trimestre?"* é pergunta; *"analisar vendas"* não é.

Cada pergunta declara o que exige do modelo:

- as **medidas**, classificadas como **aditiva** (soma em qualquer dimensão), **semiaditiva** (soma
  em todas menos tempo — o caso do saldo de estoque) ou **não aditiva** (razões e percentuais, que
  se recalculam a cada recorte e nunca se somam);
- as **dimensões conformadas** que a atendem;
- a **view de consumo** que a responde, com `contract: enforced`.

**A aditividade não é anotação: é o que impede erro.** Somar uma medida semiaditiva ao longo do
tempo produz um número que parece certo e não é — saldo de estoque somado mês a mês vira uma
quantidade que nunca existiu. Declará-la aqui é o que permite ao teste detectar o erro em vez de
apenas documentá-lo.

As views não recebem prefixo de tipo: são nomeadas pela pergunta que respondem
([ADR-0013](../adr/0013-nomenclatura-por-prefixo-de-tipo.md)). O nome é em inglês, como todo objeto
de banco; a pergunta é em português, como todo documento.

---

## 2. Núcleo comercial — Etapa 5

Estas sete são as que viram view agora. Seis se apoiam em `fact_sales_order_item`, cujo grão é
**uma linha de item de pedido**; a sétima, em `fact_cart_event`.

O ADR-0018 previa "12 a 15 perguntas". São 16 porque a decisão de acrescentar a fato de carrinho —
tomada ao redigir esta lista, e registrada no
[ADR-0028](../adr/0028-fato-de-carrinho-para-o-funil.md) — trouxe junto a pergunta que a justifica.

### P01 — Qual a receita líquida por mês, canal e categoria de produto?

| | |
|---|---|
| **Fato** | `fact_sales_order_item` |
| **Medidas** | `net_revenue_amount` (aditiva) · `gross_revenue_amount` (aditiva) · `discount_amount` (aditiva) · `quantity` (aditiva) |
| **Dimensões** | `dim_date` · `dim_sales_channel` · `dim_category` · `dim_product` |
| **View** | `monthly_revenue_by_channel_and_category` |

É a pergunta base do datamart: todas as outras a recortam de outra forma. É também a que fixa a
definição de [receita líquida](receita_liquida.md), da qual dependem P02, P03, P05 e P06.

### P02 — Qual o ticket médio por pedido, por canal e por segmento de cliente, mês a mês?

| | |
|---|---|
| **Fato** | `fact_sales_order_item` |
| **Medidas** | `net_revenue_amount` (aditiva) · `order_count` (aditiva, contagem distinta de pedido) · `average_order_value` (**não aditiva** — razão entre as duas) |
| **Dimensões** | `dim_date` · `dim_sales_channel` · `dim_customer` |
| **View** | `average_order_value_by_channel_and_segment` |

O [ticket médio](ticket_medio.md) é razão, não soma: a média das médias mensais não é a média do
ano. A view entrega numerador e denominador ao lado do resultado, para que qualquer reagregação
seja possível sem recalcular errado.

### P03 — Quais os 25 SKUs de maior receita no período, e quanto cada um pesa na receita da sua categoria?

| | |
|---|---|
| **Fato** | `fact_sales_order_item` |
| **Medidas** | `net_revenue_amount` (aditiva) · `quantity` (aditiva) · `category_revenue_share` (**não aditiva** — fração) |
| **Dimensões** | `dim_product` · `dim_category` · `dim_brand` · `dim_date` |
| **View** | `top_skus_by_revenue` |

### P04 — Quantos clientes compraram pela primeira vez em cada mês, e quantos deles voltaram a comprar em 90 dias?

| | |
|---|---|
| **Fato** | `fact_sales_order_item` |
| **Medidas** | `new_customer_count` (aditiva) · `returning_customer_count` (aditiva) · `repeat_purchase_rate_90d` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_sales_channel` · `dim_customer` |
| **View** | `new_and_repeat_customers_by_month` |

Depende dos conceitos de [cliente ativo](cliente_ativo.md) e
[recorrência de compra](recorrencia_de_compra.md). É a pergunta que a Etapa 9 estende para *churn*.

### P05 — Qual a receita e o número de pedidos por estado e região de entrega, por trimestre?

| | |
|---|---|
| **Fato** | `fact_sales_order_item` |
| **Medidas** | `net_revenue_amount` (aditiva) · `order_count` (aditiva) |
| **Dimensões** | `dim_date` · `dim_geography` · `dim_sales_channel` |
| **View** | `revenue_by_delivery_region` |

`dim_geography` é conformada: a mesma dimensão atende entrega aqui e origem de remessa na Etapa 8.

### P06 — Qual o desconto concedido como fração da receita bruta, por canal e mês?

| | |
|---|---|
| **Fato** | `fact_sales_order_item` |
| **Medidas** | `gross_revenue_amount` (aditiva) · `discount_amount` (aditiva) · `discount_share` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_sales_channel` · `dim_category` |
| **View** | `discount_share_by_channel` |

Na Etapa 9, com `fact_coupon_redemption` construída, esta pergunta ganha o recorte por campanha —
mas a view atual permanece: mudança quebrante nasce como `v2`
([ADR-0018](../adr/0018-fatos-e-views-a-partir-de-perguntas-de-negocio.md)).

### P07 — Qual a taxa de conversão de carrinho em pedido, por canal e mês?

| | |
|---|---|
| **Fato** | `fact_cart_event` |
| **Medidas** | `cart_count` (aditiva) · `converted_cart_count` (aditiva) · `cart_conversion_rate` (**não aditiva**) · `abandoned_cart_value` (aditiva) |
| **Dimensões** | `dim_date` · `dim_sales_channel` · `dim_customer` |
| **View** | `cart_conversion_rate_by_channel` |

Usa [carrinho abandonado](carrinho_abandonado.md) e [taxa de conversão](taxa_de_conversao.md). É a
pergunta que justifica a décima fato ([ADR-0028](../adr/0028-fato-de-carrinho-para-o-funil.md)):
sem ela, `carts` e `cart_items` — 1,5 dos 2,5 milhões de linhas da proporção de referência — seriam
gerados, ingeridos e limpos para não alimentar pergunta nenhuma.

---

## 3. Financeiro e estoque — Etapa 6

Estas quatro viraram view na Etapa 6. A **P08** é a primeira que combina duas
fatos: receita vem de `fact_sales_order_item` e custo de `fact_inventory_movement`,
cada uma agregada ao seu grão e depois cruzadas na granularidade comum
([ADR-0030](../adr/0030-cmv-do-livro-de-estoque.md)).

### P08 — Qual o lucro bruto e a margem por categoria e mês?

Usa [lucro bruto](lucro_bruto.md) e
[custo do produto vendido](custo_do_produto_vendido.md).

| | |
|---|---|
| **Fatos** | `fact_sales_order_item` · `fact_purchase_order_item` |
| **Medidas** | `net_revenue_amount` (aditiva) · `cost_of_goods_sold` (aditiva) · `gross_profit_amount` (aditiva) · `gross_margin_pct` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_category` · `dim_product` |
| **View** | `gross_margin_by_category` |

### P09 — Qual a taxa de aprovação de pagamento por meio de pagamento e número de parcelas?

| | |
|---|---|
| **Fato** | `fact_payment_transaction` |
| **Medidas** | `attempt_count` (aditiva) · `approved_count` (aditiva) · `approval_rate` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_payment_method` · `dim_sales_channel` |
| **View** | `payment_approval_rate_by_method` |

### P10 — Qual o valor reembolsado como fração do capturado, por motivo e mês?

| | |
|---|---|
| **Fatos** | `fact_refund` · `fact_payment_transaction` |
| **Medidas** | `refunded_amount` (aditiva) · `captured_amount` (aditiva) · `refund_rate` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_payment_method` · `dim_category` |
| **View** | `refund_rate_by_reason` |

### P11 — Qual o giro de estoque por SKU e armazém no trimestre?

| | |
|---|---|
| **Fato** | `fact_inventory_movement` |
| **Medidas** | `quantity_out` (aditiva) · `quantity_on_hand` (**semiaditiva** — soma por armazém e SKU, nunca ao longo do tempo) · `inventory_turnover` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_product` · `dim_warehouse` |
| **View** | `inventory_turnover_by_sku_and_warehouse` |

É a pergunta que exige a aditividade declarada: somar `quantity_on_hand` de três meses produz um
estoque que nunca existiu.

---

## 4. Estoque em tempo real — Etapa 7

### P12 — Quais SKUs estão abaixo do ponto de reposição agora, por armazém?

| | |
|---|---|
| **Fato** | `fact_inventory_movement` + os deltas que ela ainda não absorveu |
| **Medidas** | `quantity_available` (**semiaditiva**) · `days_of_cover` (**não aditiva**) |
| **Dimensões** | `dim_product` · `dim_warehouse` |
| **View** | `skus_below_reorder_point` |

Depende de [ruptura de estoque](ruptura_de_estoque.md) e de
[cobertura de estoque](cobertura_de_estoque.md) — os dois conceitos escritos na Etapa 7, que é a
que construiu o modelo correspondente.

É a única pergunta cuja resposta muda entre duas execuções seguidas sem ninguém rodar nada, e por
isso a única que exercita o caminho quente. A composição está descrita em
[Streaming §4.1](../streaming.md#41-onde-o-quente-e-o-frio-se-encontram): a fronteira entre o que a
fato já absorveu e o que só existe no fluxo é a **ausência do `movement_id` na fato**, e não um
corte por tempo — que perderia justamente o evento atrasado.

---

## 5. Entrega e logística — Etapa 8

### P13 — Qual a fração de entregas dentro do prazo prometido, por transportadora e modalidade, mês a mês?

| | |
|---|---|
| **Fatos** | `fact_shipment_item` · `fact_order_status_event` |
| **Medidas** | `delivered_count` (aditiva) · `on_time_count` (aditiva) · `on_time_rate` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_carrier` · `dim_warehouse` |
| **View** | `on_time_delivery_rate_by_carrier` |

### P14 — Qual o tempo médio entre pedido e entrega, por região e modalidade?

| | |
|---|---|
| **Fatos** | `fact_shipment_item` · `fact_order_status_event` |
| **Medidas** | `order_to_delivery_days` (**não aditiva** — média) · `delivered_count` (aditiva) |
| **Dimensões** | `dim_date` · `dim_geography` · `dim_carrier` |
| **View** | `order_to_delivery_time_by_region` |

---

## 6. Relacionamento e atendimento — Etapa 9

### P15 — Quantos chamados por 100 pedidos, por categoria de chamado e canal, mês a mês?

| | |
|---|---|
| **Fatos** | `fact_support_ticket_event` · `fact_sales_order_item` |
| **Medidas** | `ticket_count` (aditiva) · `order_count` (aditiva) · `tickets_per_hundred_orders` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_support_category` · `dim_sales_channel` |
| **View** | `support_tickets_per_hundred_orders` |

### P16 — Qual a taxa de recompra em 90 dias dos clientes que abriram chamado, comparada à dos que não abriram?

| | |
|---|---|
| **Fatos** | `fact_support_ticket_event` · `fact_sales_order_item` |
| **Medidas** | `customer_count` (aditiva) · `repeat_purchase_rate_90d` (**não aditiva**) |
| **Dimensões** | `dim_date` · `dim_customer` · `dim_support_category` |
| **View** | `repeat_purchase_rate_after_support` |

Depende dos conceitos de *churn* e de *recompra pós-atendimento*, escritos na Etapa 9.

---

## 7. O que estas perguntas deixam de fora

Registrado para que a ausência seja escolha, e não esquecimento:

- **Segmentação por valor de cliente (RFM).** Exige uma dimensão derivada que o modelo não declara.
  Fora do escopo da fase local.
- **Previsão e série temporal.** O Termo de Abertura não as inclui; o MVP entrega o dado que as
  tornaria possíveis, não os modelos.
