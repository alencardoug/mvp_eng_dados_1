-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A captura selecionada existe em `raw_legacy`.
--
-- ── O buraco que este teste fecha ─────────────────────────────────────────
-- Um `legacy_snapshot_id` inexistente selecionava zero linhas nas 40 origens,
-- e o teste de consistência devolvia zero violações — porque ele agrupa o que
-- está presente, e não havia nada presente para desmentir. Pipeline vazio
-- passando por pipeline correto é o pior resultado possível: nada falha, e
-- nada aconteceu.
--
-- Duas violações, uma consulta: a seleção não resolveu para número nenhum, ou
-- resolveu para um número que não está em lugar nenhum do bruto.

{% if target.type == 'bigquery' %}
WITH selecionada AS (
  SELECT
    snapshot_id
  FROM {{ ref('legacy_selected_capture') }}
), presente AS (
  SELECT
    1
  FROM {{ source('legacy', 'brands') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'campaigns') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'carriers') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'customer_segments') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'payment_methods') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'product_categories') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'sales_channels') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'suppliers') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'support_agents') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'warehouses') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'coupons') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'customers') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'price_lists') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'products') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'purchase_orders') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'carts') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'customer_addresses') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'customer_contacts') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'customer_preferences') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'goods_receipts') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'product_variants') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'cart_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'inventory_balances') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'inventory_movements') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'orders') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'product_prices') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'purchase_order_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'coupon_redemptions') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'goods_receipt_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'order_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'order_status_history') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'payments') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'shipments') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'stock_reservations') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'delivery_events') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'payment_transactions') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'shipment_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'support_tickets') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'refunds') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    1
  FROM {{ source('legacy', 'ticket_events') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
)
SELECT
  (
    SELECT
      snapshot_id
    FROM selecionada
  ) AS snapshot_id,
  'a captura selecionada não existe em raw_legacy' AS violacao
WHERE
  NOT EXISTS(
    SELECT
      1
    FROM presente
  )
UNION ALL
SELECT
  CAST(NULL AS INT64),
  'nenhuma captura foi selecionada'
WHERE
  (
    SELECT
      snapshot_id
    FROM selecionada
  ) IS NULL
{% else %}with selecionada as (

    select snapshot_id from {{ ref('legacy_selected_capture') }}

),

presente as (

    select 1 from {{ source('legacy', 'brands') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'campaigns') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'carriers') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'customer_segments') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'payment_methods') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'product_categories') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'sales_channels') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'suppliers') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'support_agents') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'warehouses') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'coupons') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'customers') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'price_lists') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'products') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'purchase_orders') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'carts') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'customer_addresses') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'customer_contacts') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'customer_preferences') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'goods_receipts') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'product_variants') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'cart_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'inventory_balances') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'inventory_movements') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'orders') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'product_prices') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'purchase_order_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'coupon_redemptions') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'goods_receipt_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'order_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'order_status_history') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'payments') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'shipments') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'stock_reservations') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'delivery_events') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'payment_transactions') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'shipment_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'support_tickets') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'refunds') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 1 from {{ source('legacy', 'ticket_events') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)

)

select
    (select snapshot_id from selecionada)       as snapshot_id,
    'a captura selecionada não existe em raw_legacy' as violacao
where not exists (select 1 from presente)

union all

select
    null::bigint,
    'nenhuma captura foi selecionada'
where (select snapshot_id from selecionada) is null{% endif %}
