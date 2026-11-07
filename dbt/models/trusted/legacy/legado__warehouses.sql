-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.warehouses`, na forma que `stg_retail__warehouses`
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
    source_table = 'warehouses'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS warehouse_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.code')
  ) AS STRING) AS warehouse_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.name')
  ) AS STRING) AS warehouse_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.city')
  ) AS STRING) AS warehouse_city,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.state')
  ) AS STRING) AS warehouse_state,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.country')
  ) AS STRING) AS warehouse_country,
  CAST(CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.capacity_units')
  ) AS INT64) AS INT64) AS capacity_units,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.is_active')
  ) AS BOOL) AS is_active,
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
    where source_table = 'warehouses'

)

select
    (cleaned_payload->>'id')::bigint                    as warehouse_id,
    (cleaned_payload->>'code')::text                    as warehouse_code,
    (cleaned_payload->>'name')::text                    as warehouse_name,
    (cleaned_payload->>'city')::text                    as warehouse_city,
    (cleaned_payload->>'state')::text                   as warehouse_state,
    (cleaned_payload->>'country')::text                 as warehouse_country,
    cast((cleaned_payload->>'capacity_units')::integer as integer) as capacity_units,
    (cleaned_payload->>'is_active')::boolean            as is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
