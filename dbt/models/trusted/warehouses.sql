-- Armazéns, com a geografia conformada da mesma forma que o cliente.
--
-- A UF do armazém vai à mesma `dim_geography` que a do endereço de entrega —
-- é o que permite, na Etapa 8, perguntar "quanto sai de cada região e vai para
-- qual" sem duas geografias que não se somam.

select
    w.warehouse_id,
    w.warehouse_code,
    w.warehouse_name,
    w.warehouse_city,
    w.warehouse_state,
    s.state_name                                as warehouse_state_name,
    s.region                                    as warehouse_region,
    w.warehouse_country,
    w.capacity_units,
    w.is_active,
    w.is_deleted,
    w.source_created_at,
    w.source_updated_at
from {{ ref('stg_retail__warehouses') }} w
left join {{ ref('brazilian_states') }} s on s.state_code = w.warehouse_state
