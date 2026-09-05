-- Pedido com os agregados dos seus itens.
--
-- `subtotal_amount`, `discount_amount` e `total_amount` vêm da origem e são o
-- **preço acordado no momento da compra** (Modelo de Dados §2.10): não são
-- recalculados aqui. Os agregados ao lado servem para conferir que os dois
-- concordam — a reconciliação é teste, não correção silenciosa.

with pedidos as (

    select * from {{ ref('stg_retail__orders') }}

),

-- ── Recompra pós-pedido (ADR-0036) ──────────────────────────────────────────
-- Depois deste pedido, o cliente fez outro em até 90 dias? A âncora é o pedido,
-- não a estreia do cliente: é o que permite comparar pedidos que geraram
-- chamado com pedidos que não geraram, com a mesma janela dos dois lados.
--
-- Só pedido **realizado** entra, dos dois lados da conta. Pedido cancelado não
-- é compra, e contá-lo como retorno diria que o cliente voltou quando ele
-- desistiu.
--
-- Este é um conceito **diferente** da recompra de P04, que conta clientes de
-- uma coorte de estreia. Os dois nunca se somam.
recompra as (

    select
        order_id,
        customer_id,
        placed_at,
        lead(placed_at) over (partition by customer_id order by placed_at, order_id)
                                                as next_order_at
    from {{ ref('stg_retail__orders') }}
    where order_status in ('paid', 'picking', 'shipped', 'delivered', 'returned')

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

    -- ── Recompra pós-pedido, no grão do pedido (ADR-0036) ───────────────────
    r.next_order_at,
    case
        when r.next_order_at is not null
        then extract(epoch from r.next_order_at - p.placed_at) / 86400.0
    end::numeric(12, 4)                     as days_to_next_order,

    -- A janela fecha 90 dias depois do pedido. Enquanto ela está aberta, o
    -- pedido **não** tem resposta: incluí-lo como "não houve recompra" faria a
    -- taxa dos meses recentes cair sozinha, sem que nada tivesse acontecido.
    p.placed_at + interval '{{ var("repeat_purchase_window_days") }} days'
        <= timestamptz '{{ var("as_of_date") }} 00:00-03'
                                            as is_repeat_window_closed,
    case
        when p.placed_at + interval '{{ var("repeat_purchase_window_days") }} days'
             <= timestamptz '{{ var("as_of_date") }} 00:00-03'
        then r.next_order_at is not null
             and r.next_order_at <= p.placed_at
                 + interval '{{ var("repeat_purchase_window_days") }} days'
    end                                     as has_post_order_repeat,

    p.is_deleted,
    p.source_created_at,
    p.source_updated_at
from pedidos p
left join itens i on i.order_id = p.order_id
left join recompra r on r.order_id = p.order_id
