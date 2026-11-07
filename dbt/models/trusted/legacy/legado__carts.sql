-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.carts`, na forma que `stg_retail__carts`
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
    source_table = 'carts'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS cart_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.cart_code')
  ) AS STRING) AS cart_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.customer_id')
  ) AS INT64) AS customer_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.sales_channel_id')
  ) AS INT64) AS sales_channel_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.status')
  ) AS STRING) AS cart_status,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.created_at')
  ) AS TIMESTAMP) AS cart_created_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.expires_at')
  ) AS TIMESTAMP) AS cart_expires_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.converted_at')
  ) AS TIMESTAMP) AS cart_converted_at,
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
    where source_table = 'carts'

)

select
    (cleaned_payload->>'id')::bigint                    as cart_id,
    (cleaned_payload->>'cart_code')::text               as cart_code,
    (cleaned_payload->>'customer_id')::bigint           as customer_id,
    (cleaned_payload->>'sales_channel_id')::bigint      as sales_channel_id,
    (cleaned_payload->>'status')::text                  as cart_status,
    (cleaned_payload->>'created_at')::timestamptz       as cart_created_at,
    (cleaned_payload->>'expires_at')::timestamptz       as cart_expires_at,
    (cleaned_payload->>'converted_at')::timestamptz     as cart_converted_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
