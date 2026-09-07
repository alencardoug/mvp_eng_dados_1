-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.warehouses`, na forma que `stg_retail__warehouses`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'warehouses'

)

select
    (cleaned_payload->>'id')::bigint                    as warehouse_id,
    (cleaned_payload->>'code')::text                    as warehouse_code,
    (cleaned_payload->>'name')::text                    as warehouse_name,
    (cleaned_payload->>'city')::text                    as warehouse_city,
    (cleaned_payload->>'state')::text                   as warehouse_state,
    (cleaned_payload->>'country')::text                 as warehouse_country,
    cast((cleaned_payload->>'capacity_units')::integer as integer) as capacity_units,
    (cleaned_payload->>'is_active')::boolean            as is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
