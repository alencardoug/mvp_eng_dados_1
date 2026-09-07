-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.coupon_redemptions`, na forma que `stg_retail__coupon_redemptions`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'coupon_redemptions'

)

select
    (cleaned_payload->>'id')::bigint                    as coupon_redemption_id,
    (cleaned_payload->>'coupon_id')::bigint             as coupon_id,
    (cleaned_payload->>'customer_id')::bigint           as customer_id,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    (cleaned_payload->>'discount_amount')::numeric(14, 2) as coupon_discount_amount,
    (cleaned_payload->>'redeemed_at')::timestamptz      as redeemed_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    false                                               as is_deleted,
    snapshot_at                                         as ingested_at
from apto
