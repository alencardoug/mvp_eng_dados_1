-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.shipments`, na forma que `stg_retail__shipments`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'shipments'

)

select
    (cleaned_payload->>'id')::bigint                    as shipment_id,
    (cleaned_payload->>'shipment_code')::text           as shipment_code,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    (cleaned_payload->>'carrier_id')::bigint            as carrier_id,
    (cleaned_payload->>'warehouse_id')::bigint          as warehouse_id,
    (cleaned_payload->>'status')::text                  as shipment_status,
    (cleaned_payload->>'tracking_code')::text           as tracking_code,
    (cleaned_payload->>'freight_amount')::numeric(14, 2) as freight_amount,
    (cleaned_payload->>'shipped_at')::timestamptz       as shipped_at,
    (cleaned_payload->>'estimated_delivery_at')::timestamptz as estimated_delivery_at,
    (cleaned_payload->>'delivered_at')::timestamptz     as delivered_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
