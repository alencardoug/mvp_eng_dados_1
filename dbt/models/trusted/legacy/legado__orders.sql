-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.orders`, na forma que `stg_retail__orders`
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
    source_table = 'orders'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS order_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.order_number')
  ) AS STRING) AS order_number,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.customer_id')
  ) AS INT64) AS customer_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.sales_channel_id')
  ) AS INT64) AS sales_channel_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.cart_id')
  ) AS INT64) AS cart_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.status')
  ) AS STRING) AS order_status,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.placed_at')
  ) AS TIMESTAMP) AS placed_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.currency')
  ) AS STRING) AS currency,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.subtotal_amount')
  ) AS NUMERIC) AS subtotal_amount,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.discount_amount')
  ) AS NUMERIC) AS order_discount_amount,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.shipping_amount')
  ) AS NUMERIC) AS shipping_amount,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.tax_amount')
  ) AS NUMERIC) AS order_tax_amount,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.total_amount')
  ) AS NUMERIC) AS order_total_amount,
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
    where source_table = 'orders'

)

select
    (cleaned_payload->>'id')::bigint                    as order_id,
    (cleaned_payload->>'order_number')::text            as order_number,
    (cleaned_payload->>'customer_id')::bigint           as customer_id,
    (cleaned_payload->>'sales_channel_id')::bigint      as sales_channel_id,
    (cleaned_payload->>'cart_id')::bigint               as cart_id,
    (cleaned_payload->>'status')::text                  as order_status,
    (cleaned_payload->>'placed_at')::timestamptz        as placed_at,
    (cleaned_payload->>'currency')::text                as currency,
    (cleaned_payload->>'subtotal_amount')::numeric(14, 2) as subtotal_amount,
    (cleaned_payload->>'discount_amount')::numeric(14, 2) as order_discount_amount,
    (cleaned_payload->>'shipping_amount')::numeric(14, 2) as shipping_amount,
    (cleaned_payload->>'tax_amount')::numeric(14, 2)    as order_tax_amount,
    (cleaned_payload->>'total_amount')::numeric(14, 2)  as order_total_amount,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
