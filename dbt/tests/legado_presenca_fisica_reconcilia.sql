-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A equação física entre a certificada anterior e a selecionada (ADR-0045):
--
--   linhas(anterior) − Σ max(0, n_ant − n_sel) + Σ max(0, n_sel − n_ant)
--     + (sem_identidade_sel − sem_identidade_ant) = linhas(selecionada)
--
-- por tabela, em **linhas físicas** contadas direto no bruto — não nas
-- transições. É o que garante que o modelo de intervalo descreve o que o bruto
-- tem, e não o contrário. Sem anterior certificada não há linhas a cobrar.

{% if target.type == 'bigquery' %}
WITH transicoes AS (
  SELECT
    *
  FROM {{ ref('legacy_capture_transitions') }}
), bruto AS (
  SELECT
    'brands' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'brands') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'campaigns' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'campaigns') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'carriers' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'carriers') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'customer_segments' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_segments') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'payment_methods' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'payment_methods') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'product_categories' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'product_categories') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'sales_channels' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'sales_channels') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'suppliers' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'suppliers') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'support_agents' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'support_agents') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'warehouses' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'warehouses') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'coupons' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'coupons') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'customers' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customers') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'price_lists' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'price_lists') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'products' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'products') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'purchase_orders' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'purchase_orders') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'carts' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'carts') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'customer_addresses' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_addresses') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'customer_contacts' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_contacts') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'customer_preferences' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_preferences') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'goods_receipts' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'goods_receipts') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'product_variants' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'product_variants') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'cart_items' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'cart_items') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'inventory_balances' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'inventory_balances') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'inventory_movements' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'inventory_movements') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'orders' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'orders') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'product_prices' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'product_prices') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'purchase_order_items' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'purchase_order_items') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'coupon_redemptions' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'coupon_redemptions') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'goods_receipt_items' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'goods_receipt_items') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'order_items' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'order_items') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'order_status_history' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'order_status_history') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'payments' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'payments') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'shipments' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'shipments') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'stock_reservations' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'stock_reservations') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'delivery_events' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'delivery_events') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'payment_transactions' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'payment_transactions') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'shipment_items' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'shipment_items') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'support_tickets' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'support_tickets') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'refunds' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'refunds') }}
  GROUP BY
    1,
    2
  UNION ALL
  SELECT
    'ticket_events' AS source_table,
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) AS snapshot_id,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'ticket_events') }}
  GROUP BY
    1,
    2
), por_tabela AS (
  SELECT
    source_table,
    MIN(previous_snapshot_id) AS previous_snapshot_id,
    MIN(selected_snapshot_id) AS selected_snapshot_id,
    SUM(
      CASE
        WHEN business_key IS NOT NULL
        THEN GREATEST(rows_before - rows_after, 0)
        ELSE 0
      END
    ) AS perdidas,
    SUM(
      CASE
        WHEN business_key IS NOT NULL
        THEN GREATEST(rows_after - rows_before, 0)
        ELSE 0
      END
    ) AS ganhas,
    SUM(CASE WHEN business_key IS NULL THEN rows_after - rows_before ELSE 0 END) AS delta_sem_identidade
  FROM transicoes
  GROUP BY
    source_table
)
SELECT
  t.source_table,
  COALESCE(a.linhas, 0) AS linhas_anterior,
  COALESCE(s.linhas, 0) AS linhas_selecionada,
  t.perdidas,
  t.ganhas,
  t.delta_sem_identidade,
  COALESCE(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade AS calculado
FROM por_tabela AS t
LEFT JOIN bruto AS a
  ON a.source_table = t.source_table AND a.snapshot_id = t.previous_snapshot_id
LEFT JOIN bruto AS s
  ON s.source_table = t.source_table AND s.snapshot_id = t.selected_snapshot_id
WHERE
  COALESCE(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade <> COALESCE(s.linhas, 0)
{% else %}with transicoes as (

    select * from {{ ref('legacy_capture_transitions') }}

),

bruto as (

    select 'brands' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'brands') }} group by 1, 2
    union all
    select 'campaigns' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'campaigns') }} group by 1, 2
    union all
    select 'carriers' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'carriers') }} group by 1, 2
    union all
    select 'customer_segments' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_segments') }} group by 1, 2
    union all
    select 'payment_methods' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'payment_methods') }} group by 1, 2
    union all
    select 'product_categories' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'product_categories') }} group by 1, 2
    union all
    select 'sales_channels' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'sales_channels') }} group by 1, 2
    union all
    select 'suppliers' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'suppliers') }} group by 1, 2
    union all
    select 'support_agents' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'support_agents') }} group by 1, 2
    union all
    select 'warehouses' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'warehouses') }} group by 1, 2
    union all
    select 'coupons' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'coupons') }} group by 1, 2
    union all
    select 'customers' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'customers') }} group by 1, 2
    union all
    select 'price_lists' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'price_lists') }} group by 1, 2
    union all
    select 'products' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'products') }} group by 1, 2
    union all
    select 'purchase_orders' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'purchase_orders') }} group by 1, 2
    union all
    select 'carts' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'carts') }} group by 1, 2
    union all
    select 'customer_addresses' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_addresses') }} group by 1, 2
    union all
    select 'customer_contacts' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_contacts') }} group by 1, 2
    union all
    select 'customer_preferences' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_preferences') }} group by 1, 2
    union all
    select 'goods_receipts' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'goods_receipts') }} group by 1, 2
    union all
    select 'product_variants' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'product_variants') }} group by 1, 2
    union all
    select 'cart_items' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'cart_items') }} group by 1, 2
    union all
    select 'inventory_balances' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'inventory_balances') }} group by 1, 2
    union all
    select 'inventory_movements' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'inventory_movements') }} group by 1, 2
    union all
    select 'orders' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'orders') }} group by 1, 2
    union all
    select 'product_prices' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'product_prices') }} group by 1, 2
    union all
    select 'purchase_order_items' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'purchase_order_items') }} group by 1, 2
    union all
    select 'coupon_redemptions' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'coupon_redemptions') }} group by 1, 2
    union all
    select 'goods_receipt_items' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'goods_receipt_items') }} group by 1, 2
    union all
    select 'order_items' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'order_items') }} group by 1, 2
    union all
    select 'order_status_history' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'order_status_history') }} group by 1, 2
    union all
    select 'payments' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'payments') }} group by 1, 2
    union all
    select 'shipments' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'shipments') }} group by 1, 2
    union all
    select 'stock_reservations' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'stock_reservations') }} group by 1, 2
    union all
    select 'delivery_events' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'delivery_events') }} group by 1, 2
    union all
    select 'payment_transactions' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'payment_transactions') }} group by 1, 2
    union all
    select 'shipment_items' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'shipment_items') }} group by 1, 2
    union all
    select 'support_tickets' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'support_tickets') }} group by 1, 2
    union all
    select 'refunds' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'refunds') }} group by 1, 2
    union all
    select 'ticket_events' as source_table, (_airbyte_meta->>'sync_id')::bigint as snapshot_id, count(*) as linhas from {{ source('legacy', 'ticket_events') }} group by 1, 2

),

por_tabela as (

    select
        source_table,
        min(previous_snapshot_id)                                   as previous_snapshot_id,
        min(selected_snapshot_id)                                   as selected_snapshot_id,
        sum(case when business_key is not null then greatest(rows_before - rows_after, 0) else 0 end) as perdidas,
        sum(case when business_key is not null then greatest(rows_after - rows_before, 0) else 0 end) as ganhas,
        sum(case when business_key is null then rows_after - rows_before else 0 end)                  as delta_sem_identidade
    from transicoes
    group by source_table

)

select
    t.source_table,
    coalesce(a.linhas, 0)                                           as linhas_anterior,
    coalesce(s.linhas, 0)                                           as linhas_selecionada,
    t.perdidas, t.ganhas, t.delta_sem_identidade,
    coalesce(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade as calculado
from por_tabela t
left join bruto a on a.source_table = t.source_table and a.snapshot_id = t.previous_snapshot_id
left join bruto s on s.source_table = t.source_table and s.snapshot_id = t.selected_snapshot_id
where coalesce(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade <> coalesce(s.linhas, 0){% endif %}
