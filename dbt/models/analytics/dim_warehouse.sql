-- Armazém — SCD tipo 1, com a geografia conformada.
--
-- `geography_key` aponta para a **mesma** `dim_geography` que o endereço de
-- entrega usa. É isso que permite, na Etapa 8, cruzar origem da remessa com
-- destino do cliente sem duas geografias que não se somam.

select
    {{ dbt_utils.generate_surrogate_key(['w.warehouse_id']) }} as warehouse_key,
    w.warehouse_id                                  as warehouse_natural_key,
    w.warehouse_code,
    w.warehouse_name,
    w.warehouse_city,
    w.warehouse_state,
    w.warehouse_state_name,
    w.warehouse_region,
    w.warehouse_country,
    w.capacity_units,
    coalesce(g.geography_key, {{ chave_desconhecida() }}) as geography_key,
    w.is_active,
    w.is_deleted
from {{ ref('warehouses') }} w
left join {{ ref('dim_geography') }} g
       on g.country = w.warehouse_country
      and g.state_code = w.warehouse_state
      and g.city = w.warehouse_city
