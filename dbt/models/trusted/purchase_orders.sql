-- Cabeçalho da ordem de compra, com os agregados dos seus itens.

with ordens as (

    select * from {{ ref('stg_retail__purchase_orders') }}

),

itens as (

    select
        purchase_order_id,
        count(*)                                    as item_count,
        sum(quantity_ordered)                       as quantity_ordered,
        sum(quantity_received)                      as quantity_received,
        sum(ordered_cost_amount)                    as items_ordered_cost_amount,
        sum(received_cost_amount)                   as items_received_cost_amount
    from {{ ref('purchase_order_items') }}
    group by purchase_order_id

)

select
    o.purchase_order_id,
    o.po_number,
    o.supplier_id,
    o.purchase_order_status,
    o.ordered_at,
    o.expected_at,
    o.currency,
    o.purchase_order_total_amount,

    coalesce(i.item_count, 0)                       as item_count,
    coalesce(i.quantity_ordered, 0)                 as quantity_ordered,
    coalesce(i.quantity_received, 0)                as quantity_received,
    coalesce(i.items_ordered_cost_amount, 0)        as items_ordered_cost_amount,
    coalesce(i.items_received_cost_amount, 0)       as items_received_cost_amount,

    o.purchase_order_status = 'received'            as is_fully_received,
    o.purchase_order_status = 'cancelled'           as is_cancelled,

    o.is_deleted,
    o.source_created_at,
    o.source_updated_at
from ordens o
left join itens i on i.purchase_order_id = o.purchase_order_id
