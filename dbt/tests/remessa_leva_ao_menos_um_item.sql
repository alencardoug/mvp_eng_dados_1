-- Invariante 13: toda remessa contém ao menos um item.
-- Bloqueante após a correção do gerador (D31). A fato tem grão de item;
-- uma remessa vazia desapareceria das métricas de entrega do consumo (P13).

select
    s.source_system,
    s.shipment_id,
    s.shipment_code,
    s.order_id,
    s.shipment_status
from {{ ref('shipments') }} s
left join {{ ref('shipment_items') }} i
    on i.source_system = s.source_system and i.shipment_id = s.shipment_id
-- Caixa em quarentena explica a remessa sem item; ver a macro.
where not {{ explicado_pela_quarentena('shipment_items', ['shipment_id'], 's') }}
group by s.source_system, s.shipment_id, s.shipment_code, s.order_id, s.shipment_status
having count(i.shipment_item_id) = 0
