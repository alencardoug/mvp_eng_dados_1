-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.refunds`, na forma que `stg_retail__refunds`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'refunds'

)

select
    (cleaned_payload->>'id')::bigint                    as refund_id,
    (cleaned_payload->>'refund_code')::text             as refund_code,
    (cleaned_payload->>'payment_transaction_id')::bigint as payment_transaction_id,
    (cleaned_payload->>'amount')::numeric(14, 2)        as refund_amount,
    (cleaned_payload->>'reason')::text                  as refund_reason,
    (cleaned_payload->>'status')::text                  as refund_status,
    (cleaned_payload->>'refunded_at')::timestamptz      as refunded_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
