-- Invariante 13: toda remessa contém ao menos um item.
-- Bloqueante após a correção do gerador (D31). A fato tem grão de item;
-- uma remessa vazia desapareceria das métricas de entrega do consumo (P13).

select
    s.shipment_id,
    s.shipment_code,
    s.order_id,
    s.shipment_status
from {{ ref('shipments') }} s
left join {{ ref('shipment_items') }} i on i.shipment_id = s.shipment_id
group by s.shipment_id, s.shipment_code, s.order_id, s.shipment_status
having count(i.shipment_item_id) = 0
