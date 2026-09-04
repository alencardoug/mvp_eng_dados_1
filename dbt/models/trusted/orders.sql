-- Pedido com os agregados dos seus itens.
--
-- `subtotal_amount`, `discount_amount` e `total_amount` vêm da origem e são o
-- **preço acordado no momento da compra** (Modelo de Dados §2.10): não são
-- recalculados aqui. Os agregados ao lado servem para conferir que os dois
-- concordam — a reconciliação é teste, não correção silenciosa.

with pedidos as (

    select * from {{ ref('stg_retail__orders') }}

),

itens as (

    select
        order_id,
        count(*)                        as item_count,
        sum(quantity)                   as unit_count,
        sum(gross_revenue_amount)       as items_gross_revenue_amount,
        sum(net_revenue_amount)         as items_net_revenue_amount
    from {{ ref('order_items') }}
    group by order_id

)

select
    p.order_id,
    p.order_number,
    p.customer_id,
    p.sales_channel_id,
    p.cart_id,
    p.order_status,
    p.placed_at,
    p.currency,

    p.subtotal_amount,
    p.order_discount_amount,
    p.shipping_amount,
    p.order_tax_amount,
    p.order_total_amount,

    coalesce(i.item_count, 0)               as item_count,
    coalesce(i.unit_count, 0)               as unit_count,
    coalesce(i.items_gross_revenue_amount, 0) as items_gross_revenue_amount,
    coalesce(i.items_net_revenue_amount, 0)   as items_net_revenue_amount,

    -- Venda direta em loja não passa por carrinho; é o que separa o funil
    -- digital do presencial na análise de conversão.
    p.cart_id is not null                   as is_from_cart,
    p.order_status = 'cancelled'            as is_cancelled,
    -- "Chegou a ser pago" é o que conta como venda realizada em toda pergunta
    -- de receita: pedido pendente ainda pode não virar nada.
    p.order_status in ('paid', 'picking', 'shipped', 'delivered', 'returned')
                                            as is_realised,

    p.is_deleted,
    p.source_created_at,
    p.source_updated_at
from pedidos p
left join itens i on i.order_id = p.order_id
