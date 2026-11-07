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

{% if target.type == 'bigquery' %}
WITH apto AS (
  SELECT
    *
  FROM {{ ref('legacy_eligible_records') }}
  WHERE
    source_table = 'campaigns'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS campaign_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.code')
  ) AS STRING) AS campaign_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.name')
  ) AS STRING) AS campaign_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.objective')
  ) AS STRING) AS campaign_objective,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.valid_from')
  ) AS TIMESTAMP) AS campaign_valid_from,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.valid_to')
  ) AS TIMESTAMP) AS campaign_valid_to,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.budget_amount')
  ) AS NUMERIC) AS budget_amount,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.is_active')
  ) AS BOOL) AS campaign_is_active,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.created_at')
  ) AS TIMESTAMP) AS source_created_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.updated_at')
  ) AS TIMESTAMP) AS source_updated_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.deleted_at')
  ) AS TIMESTAMP) AS source_deleted_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.deleted_at')
  ) AS TIMESTAMP) IS NOT NULL AS is_deleted,
  snapshot_at AS ingested_at
FROM apto
{% else %}with apto as (

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
from apto{% endif %}
