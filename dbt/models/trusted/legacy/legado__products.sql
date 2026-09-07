-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.products`, na forma que `stg_retail__products`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'products'

)

select
    (cleaned_payload->>'id')::bigint                    as product_id,
    (cleaned_payload->>'product_code')::text            as product_code,
    (cleaned_payload->>'category_id')::bigint           as product_category_id,
    (cleaned_payload->>'brand_id')::bigint              as brand_id,
    (cleaned_payload->>'name')::text                    as product_name,
    (cleaned_payload->>'description')::text             as product_description,
    (cleaned_payload->>'status')::text                  as product_status,
    (cleaned_payload->>'launched_at')::timestamptz      as launched_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
