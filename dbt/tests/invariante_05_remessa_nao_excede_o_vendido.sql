-- Invariante 5 — uma remessa não contém quantidade superior à vendida.
--
-- Atravessa `shipment_items`, `order_items` e as remessas anteriores do mesmo
-- pedido, e por isso o modelo transacional não a expressa como `CHECK`: um
-- `CHECK` só enxerga a própria linha.
--
-- Um pedido pode ir em várias remessas, e é a **soma** delas que não pode
-- ultrapassar o vendido. Testar remessa a remessa deixaria passar o caso que
-- importa: duas remessas de metade cada, e uma terceira de metade de novo.

with enviado as (

    select
        order_item_id,
        sum(quantity_shipped) as quantity_shipped
    from {{ ref('stg_retail__shipment_items') }}
    group by order_item_id

)

select
    e.order_item_id,
    e.quantity_shipped,
    i.quantity as quantity_sold
from enviado e
join {{ ref('order_items') }} i on i.order_item_id = e.order_item_id
where e.quantity_shipped > i.quantity
