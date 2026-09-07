-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.suppliers`, na forma que `stg_retail__suppliers`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'suppliers'

)

select
    (cleaned_payload->>'id')::bigint                    as supplier_id,
    (cleaned_payload->>'supplier_code')::text           as supplier_code,
    (cleaned_payload->>'legal_name')::text              as supplier_legal_name,
    (cleaned_payload->>'trade_name')::text              as supplier_trade_name,
    (cleaned_payload->>'document')::text                as supplier_document,
    (cleaned_payload->>'contact_email')::text           as supplier_contact_email,
    (cleaned_payload->>'country')::text                 as supplier_country,
    cast((cleaned_payload->>'payment_terms_days')::integer as integer) as payment_terms_days,
    (cleaned_payload->>'is_active')::boolean            as is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
