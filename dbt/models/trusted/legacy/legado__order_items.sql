-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.order_items`, na forma que `stg_retail__order_items`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'order_items'

)

select
    (cleaned_payload->>'id')::bigint                    as order_item_id,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    (cleaned_payload->>'product_variant_id')::bigint    as product_variant_id,
    cast((cleaned_payload->>'quantity')::integer as integer) as quantity,
    (cleaned_payload->>'unit_price')::numeric(14, 4)    as unit_price,
    (cleaned_payload->>'discount_amount')::numeric(14, 2) as discount_amount,
    (cleaned_payload->>'tax_amount')::numeric(14, 2)    as tax_amount,
    (cleaned_payload->>'total_amount')::numeric(14, 2)  as line_total_amount,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
