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

{% if target.type == 'bigquery' %}
WITH apto AS (
  SELECT
    *
  FROM {{ ref('legacy_eligible_records') }}
  WHERE
    source_table = 'customers'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS customer_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.customer_code')
  ) AS STRING) AS customer_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.segment_id')
  ) AS INT64) AS customer_segment_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.first_name')
  ) AS STRING) AS first_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.last_name')
  ) AS STRING) AS last_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.first_name')
  ) AS STRING) || ' ' || CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.last_name')
  ) AS STRING) AS customer_full_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.document')
  ) AS STRING) AS customer_document,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.birth_date')
  ) AS DATE) AS birth_date,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.status')
  ) AS STRING) AS customer_status,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.registered_at')
  ) AS TIMESTAMP) AS registered_at,
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
from apto{% endif %}
