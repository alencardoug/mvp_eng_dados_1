-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.campaigns`, na forma que `stg_retail__campaigns`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'campaigns'

)

select
    (cleaned_payload->>'id')::bigint                    as campaign_id,
    (cleaned_payload->>'code')::text                    as campaign_code,
    (cleaned_payload->>'name')::text                    as campaign_name,
    (cleaned_payload->>'objective')::text               as campaign_objective,
    (cleaned_payload->>'valid_from')::timestamptz       as campaign_valid_from,
    (cleaned_payload->>'valid_to')::timestamptz         as campaign_valid_to,
    (cleaned_payload->>'budget_amount')::numeric(14, 2) as budget_amount,
    (cleaned_payload->>'is_active')::boolean            as campaign_is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
