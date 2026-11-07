-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.purchase_order_items`, na forma que `stg_retail__purchase_order_items`
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
    source_table = 'purchase_order_items'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS purchase_order_item_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.purchase_order_id')
  ) AS INT64) AS purchase_order_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.product_variant_id')
  ) AS INT64) AS product_variant_id,
  CAST(CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.quantity_ordered')
  ) AS INT64) AS INT64) AS quantity_ordered,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.unit_cost')
  ) AS NUMERIC) AS unit_cost,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.total_cost')
  ) AS NUMERIC) AS total_cost,
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
    where source_table = 'purchase_order_items'

)

select
    (cleaned_payload->>'id')::bigint                    as purchase_order_item_id,
    (cleaned_payload->>'purchase_order_id')::bigint     as purchase_order_id,
    (cleaned_payload->>'product_variant_id')::bigint    as product_variant_id,
    cast((cleaned_payload->>'quantity_ordered')::integer as integer) as quantity_ordered,
    (cleaned_payload->>'unit_cost')::numeric(14, 4)     as unit_cost,
    (cleaned_payload->>'total_cost')::numeric(14, 2)    as total_cost,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
