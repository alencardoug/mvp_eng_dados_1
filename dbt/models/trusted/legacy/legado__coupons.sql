-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.coupons`, na forma que `stg_retail__coupons`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'coupons'

)

select
    (cleaned_payload->>'id')::bigint                    as coupon_id,
    (cleaned_payload->>'code')::text                    as coupon_code,
    (cleaned_payload->>'campaign_id')::bigint           as campaign_id,
    (cleaned_payload->>'discount_type')::text           as discount_type,
    (cleaned_payload->>'discount_value')::numeric(14, 2) as discount_value,
    (cleaned_payload->>'min_order_amount')::numeric(14, 2) as min_order_amount,
    (cleaned_payload->>'max_redemptions')::integer      as max_redemptions,
    (cleaned_payload->>'valid_from')::timestamptz       as coupon_valid_from,
    (cleaned_payload->>'valid_to')::timestamptz         as coupon_valid_to,
    (cleaned_payload->>'is_active')::boolean            as coupon_is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
