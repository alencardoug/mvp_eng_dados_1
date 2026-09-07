-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.stock_reservations`, na forma que `stg_retail__stock_reservations`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'stock_reservations'

)

select
    (cleaned_payload->>'id')::bigint                    as stock_reservation_id,
    (cleaned_payload->>'reservation_code')::text        as reservation_code,
    (cleaned_payload->>'warehouse_id')::bigint          as warehouse_id,
    (cleaned_payload->>'product_variant_id')::bigint    as product_variant_id,
    (cleaned_payload->>'cart_id')::bigint               as cart_id,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    cast((cleaned_payload->>'quantity')::integer as integer) as quantity_reserved,
    (cleaned_payload->>'status')::text                  as reservation_status,
    (cleaned_payload->>'expires_at')::timestamptz       as expires_at,
    (cleaned_payload->>'released_at')::timestamptz      as released_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
