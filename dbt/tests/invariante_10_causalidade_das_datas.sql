-- Invariante 10 — as datas respeitam a causalidade do ciclo.
--
-- O pedido é feito, separado, despachado, chega e — se for o caso — volta.
-- Nenhuma dessas etapas pode anteceder a anterior, e nenhum `CHECK` de coluna
-- consegue dizer isso: a causalidade atravessa `orders`, `shipments` e
-- `delivery_events`.
--
-- Cada linha devolvida nomeia a etapa que saiu de ordem, para que a falha diga
-- **qual** elo quebrou em vez de apenas que algo quebrou.

with remessas as (

    select
        s.shipment_id,
        s.order_id,
        o.placed_at,
        s.shipped_at,
        s.picked_up_at,
        s.delivered_at,
        s.returned_at,
        s.estimated_delivery_at
    from {{ ref('shipments') }} s
    join {{ ref('orders') }} o on o.order_id = s.order_id

)

select shipment_id, 'despacho antes do pedido' as violacao
from remessas where shipped_at < placed_at

union all
select shipment_id, 'coleta antes do despacho'
from remessas where picked_up_at < shipped_at

union all
select shipment_id, 'entrega antes do despacho'
from remessas where delivered_at < shipped_at

union all
select shipment_id, 'entrega antes do pedido'
from remessas where delivered_at < placed_at

union all
select shipment_id, 'devolucao antes da entrega'
from remessas where returned_at < delivered_at

union all
-- Promessa anterior ao despacho seria prazo prometido para trás: a promessa é
-- feita **no** despacho e olha para a frente.
select shipment_id, 'promessa antes do despacho'
from remessas where estimated_delivery_at < shipped_at
