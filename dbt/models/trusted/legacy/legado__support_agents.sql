-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.support_agents`, na forma que `stg_retail__support_agents`
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
    source_table = 'support_agents'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS support_agent_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.agent_code')
  ) AS STRING) AS agent_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.first_name')
  ) AS STRING) AS agent_first_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.last_name')
  ) AS STRING) AS agent_last_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.first_name')
  ) AS STRING) || ' ' || CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.last_name')
  ) AS STRING) AS agent_full_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.email')
  ) AS STRING) AS agent_email,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.team')
  ) AS STRING) AS agent_team,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.hired_at')
  ) AS TIMESTAMP) AS hired_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.is_active')
  ) AS BOOL) AS agent_is_active,
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
    where source_table = 'support_agents'

)

select
    (cleaned_payload->>'id')::bigint                    as support_agent_id,
    (cleaned_payload->>'agent_code')::text              as agent_code,
    (cleaned_payload->>'first_name')::text              as agent_first_name,
    (cleaned_payload->>'last_name')::text               as agent_last_name,
    (cleaned_payload->>'first_name')::text || ' ' || (cleaned_payload->>'last_name')::text as agent_full_name,
    (cleaned_payload->>'email')::text                   as agent_email,
    (cleaned_payload->>'team')::text                    as agent_team,
    (cleaned_payload->>'hired_at')::timestamptz         as hired_at,
    (cleaned_payload->>'is_active')::boolean            as agent_is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
