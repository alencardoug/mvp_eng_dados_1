-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.customer_addresses`, na forma que `stg_retail__customer_addresses`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'customer_addresses'

)

select
    (cleaned_payload->>'id')::bigint                    as customer_address_id,
    (cleaned_payload->>'customer_id')::bigint           as customer_id,
    (cleaned_payload->>'address_type')::text            as address_type,
    (cleaned_payload->>'street')::text                  as street,
    (cleaned_payload->>'number')::text                  as street_number,
    (cleaned_payload->>'complement')::text              as complement,
    (cleaned_payload->>'district')::text                as district,
    (cleaned_payload->>'city')::text                    as city,
    (cleaned_payload->>'state')::text                   as state,
    (cleaned_payload->>'postal_code')::text             as postal_code,
    (cleaned_payload->>'country')::text                 as country,
    (cleaned_payload->>'is_primary')::boolean           as is_primary,
    (cleaned_payload->>'valid_from')::timestamptz       as valid_from,
    (cleaned_payload->>'valid_to')::timestamptz         as valid_to,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
