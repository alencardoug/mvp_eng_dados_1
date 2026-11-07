-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.product_variants`, na forma que `stg_retail__product_variants`
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
    source_table = 'product_variants'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS product_variant_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.product_id')
  ) AS INT64) AS product_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.sku')
  ) AS STRING) AS sku,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.size')
  ) AS STRING) AS variant_size,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.color')
  ) AS STRING) AS variant_color,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.package')
  ) AS STRING) AS variant_package,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.barcode')
  ) AS STRING) AS barcode,
  CAST(CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.weight_grams')
  ) AS INT64) AS INT64) AS weight_grams,
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
    where source_table = 'product_variants'

)

select
    (cleaned_payload->>'id')::bigint                    as product_variant_id,
    (cleaned_payload->>'product_id')::bigint            as product_id,
    (cleaned_payload->>'sku')::text                     as sku,
    (cleaned_payload->>'size')::text                    as variant_size,
    (cleaned_payload->>'color')::text                   as variant_color,
    (cleaned_payload->>'package')::text                 as variant_package,
    (cleaned_payload->>'barcode')::text                 as barcode,
    cast((cleaned_payload->>'weight_grams')::integer as integer) as weight_grams,
    (cleaned_payload->>'is_active')::boolean            as is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
