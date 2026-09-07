-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.purchase_orders`, na forma que `stg_retail__purchase_orders`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'purchase_orders'

)

select
    (cleaned_payload->>'id')::bigint                    as purchase_order_id,
    (cleaned_payload->>'po_number')::text               as po_number,
    (cleaned_payload->>'supplier_id')::bigint           as supplier_id,
    (cleaned_payload->>'status')::text                  as purchase_order_status,
    (cleaned_payload->>'ordered_at')::timestamptz       as ordered_at,
    (cleaned_payload->>'expected_at')::timestamptz      as expected_at,
    (cleaned_payload->>'currency')::text                as currency,
    (cleaned_payload->>'total_amount')::numeric(14, 2)  as purchase_order_total_amount,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
