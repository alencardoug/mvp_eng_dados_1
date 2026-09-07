-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.inventory_movements`, na forma que `stg_retail__inventory_movements`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'inventory_movements'

)

select
    (cleaned_payload->>'movement_id')::text             as movement_id,
    legacy_row_id                                       as event_sequence,
    (cleaned_payload->>'idempotency_key')::text         as idempotency_key,
    (cleaned_payload->>'warehouse_id')::bigint          as warehouse_id,
    (cleaned_payload->>'product_variant_id')::bigint    as product_variant_id,
    (cleaned_payload->>'movement_type')::text           as movement_type,
    cast((cleaned_payload->>'quantity_delta')::integer as integer) as quantity_delta,
    (cleaned_payload->>'unit_cost')::numeric(14, 4)     as unit_cost,
    (cleaned_payload->>'source_type')::text             as source_type,
    (cleaned_payload->>'source_id')::text               as source_id,
    (cleaned_payload->>'correlation_id')::text          as correlation_id,
    (cleaned_payload->>'causation_id')::text            as causation_id,
    (cleaned_payload->>'aggregate_version')::bigint     as aggregate_version,
    (cleaned_payload->>'occurred_at')::timestamptz      as occurred_at,
    (cleaned_payload->>'recorded_at')::timestamptz      as recorded_at,
    cast((cleaned_payload->>'schema_version')::smallint as integer) as schema_version,
    (cleaned_payload->>'metadata')::text                as event_metadata,
    false                                               as arrived_by_stream,
    true                                                as arrived_by_batch,
    (cleaned_payload->>'recorded_at')::timestamptz      as source_created_at,
    false                                               as is_deleted,
    snapshot_at                                         as ingested_at
from apto
