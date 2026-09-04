-- Item de ordem de compra, com o que foi efetivamente recebido.
--
-- **Invariante 6 nasce aqui:** o recebido não supera o solicitado. Ela atravessa
-- `goods_receipt_items` e `purchase_order_items`, e por isso o modelo
-- transacional não a expressa como `CHECK` — agregar o recebido neste grão é o
-- que torna a verificação um `where`.
--
-- Só recebimento **concluído** conta. Um recebimento `pending` ainda não trouxe
-- mercadoria e um `rejected` a devolveu: contá-los faria a ordem parecer
-- atendida sem que nada tivesse entrado no armazém.

with itens as (

    select * from {{ ref('stg_retail__purchase_order_items') }}

),

recebido as (

    select
        gri.purchase_order_item_id,
        sum(gri.quantity_received)                  as quantity_received,
        sum(gri.quantity_received * gri.unit_cost)  as received_cost_amount,
        min(gr.received_at)                         as first_received_at,
        max(gr.received_at)                         as last_received_at
    from {{ ref('stg_retail__goods_receipt_items') }} gri
    join {{ ref('stg_retail__goods_receipts') }} gr using (goods_receipt_id)
    where gr.goods_receipt_status = 'completed'
    group by gri.purchase_order_item_id

)

select
    i.purchase_order_item_id,
    i.purchase_order_id,
    i.product_variant_id,
    i.quantity_ordered,
    i.unit_cost,
    i.total_cost                                    as ordered_cost_amount,

    coalesce(r.quantity_received, 0)                as quantity_received,
    coalesce(round(r.received_cost_amount, 2), 0)   as received_cost_amount,
    i.quantity_ordered - coalesce(r.quantity_received, 0) as quantity_outstanding,
    r.first_received_at,
    r.last_received_at,

    coalesce(r.quantity_received, 0) >= i.quantity_ordered      as is_fully_received,
    coalesce(r.quantity_received, 0) = 0                        as is_not_received,

    i.is_deleted,
    i.source_created_at,
    i.source_updated_at
from itens i
left join recebido r on r.purchase_order_item_id = i.purchase_order_item_id
