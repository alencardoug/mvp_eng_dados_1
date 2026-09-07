-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.goods_receipts`, na forma que `stg_retail__goods_receipts`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'goods_receipts'

)

select
    (cleaned_payload->>'id')::bigint                    as goods_receipt_id,
    (cleaned_payload->>'receipt_number')::text          as receipt_number,
    (cleaned_payload->>'purchase_order_id')::bigint     as purchase_order_id,
    (cleaned_payload->>'warehouse_id')::bigint          as warehouse_id,
    (cleaned_payload->>'received_at')::timestamptz      as received_at,
    (cleaned_payload->>'status')::text                  as goods_receipt_status,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
