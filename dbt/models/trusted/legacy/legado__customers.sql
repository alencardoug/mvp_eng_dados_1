-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.customers`, na forma que `stg_retail__customers`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'customers'

)

select
    (cleaned_payload->>'id')::bigint                    as customer_id,
    (cleaned_payload->>'customer_code')::text           as customer_code,
    (cleaned_payload->>'segment_id')::bigint            as customer_segment_id,
    (cleaned_payload->>'first_name')::text              as first_name,
    (cleaned_payload->>'last_name')::text               as last_name,
    (cleaned_payload->>'first_name')::text || ' ' || (cleaned_payload->>'last_name')::text as customer_full_name,
    (cleaned_payload->>'document')::text                as customer_document,
    (cleaned_payload->>'birth_date')::date              as birth_date,
    (cleaned_payload->>'status')::text                  as customer_status,
    (cleaned_payload->>'registered_at')::timestamptz    as registered_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
