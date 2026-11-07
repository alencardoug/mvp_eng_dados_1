-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Sentinela da identidade do vínculo (17/09/2026, registrada junto à D43).
--
-- A classificação resolve a referência ao pai por igualdade **textual**
-- (`classification.sql`, CTE `edges`); a comparação entre capturas resolve a
-- mesma chave pela forma **canônica** do tipo (`chave_canonica`, ADR-0045).
-- Enquanto as chaves do bruto forem inteiros e UUIDs limpos as duas coincidem.
-- No dia em que um pai for escrito `0x8` e o filho `8`, o intervalo dirá
-- `mantida` e a limpeza dirá `FK_ORPHAN` — e este teste acusa o filho, em vez
-- de deixar a divergência passar como órfão legítimo. Não muda tratamento
-- nenhum: unificar as noções de identidade é decisão da D43.

{% if target.type == 'bigquery' %}
WITH registros AS (
  SELECT
    source_table,
    legacy_row_id,
    cleaned_payload
  FROM {{ ref('legacy_records') }}
)
SELECT
  'product_categories' AS source_table,
  f.legacy_row_id,
  'parent_id' AS column_name,
  'product_categories' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.parent_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'product_categories'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.parent_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_categories'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.parent_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_categories' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'parent_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'coupons' AS source_table,
  f.legacy_row_id,
  'campaign_id' AS column_name,
  'campaigns' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.campaign_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'coupons'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.campaign_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'campaigns'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.campaign_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'campaigns' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'campaign_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'customers' AS source_table,
  f.legacy_row_id,
  'segment_id' AS column_name,
  'customer_segments' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.segment_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'customers'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.segment_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customer_segments'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.segment_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customer_segments' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'segment_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'price_lists' AS source_table,
  f.legacy_row_id,
  'sales_channel_id' AS column_name,
  'sales_channels' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'price_lists'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'sales_channels'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'sales_channels' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'sales_channel_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'products' AS source_table,
  f.legacy_row_id,
  'brand_id' AS column_name,
  'brands' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.brand_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'products'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.brand_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'brands'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.brand_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'brands' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'brand_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'products' AS source_table,
  f.legacy_row_id,
  'category_id' AS column_name,
  'product_categories' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.category_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'products'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.category_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_categories'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.category_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_categories' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'category_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'purchase_orders' AS source_table,
  f.legacy_row_id,
  'supplier_id' AS column_name,
  'suppliers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.supplier_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'purchase_orders'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.supplier_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'suppliers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.supplier_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'suppliers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'supplier_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'carts' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'carts'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'carts' AS source_table,
  f.legacy_row_id,
  'sales_channel_id' AS column_name,
  'sales_channels' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'carts'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'sales_channels'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'sales_channels' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'sales_channel_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'customer_addresses' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'customer_addresses'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'customer_contacts' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'customer_contacts'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'customer_preferences' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'customer_preferences'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'goods_receipts' AS source_table,
  f.legacy_row_id,
  'purchase_order_id' AS column_name,
  'purchase_orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'goods_receipts'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'purchase_orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'purchase_orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'purchase_order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'goods_receipts' AS source_table,
  f.legacy_row_id,
  'warehouse_id' AS column_name,
  'warehouses' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'goods_receipts'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'product_variants' AS source_table,
  f.legacy_row_id,
  'product_id' AS column_name,
  'products' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'product_variants'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'products'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'products' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'cart_items' AS source_table,
  f.legacy_row_id,
  'cart_id' AS column_name,
  'carts' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'cart_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carts'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carts' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'cart_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'cart_items' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'cart_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'inventory_balances' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'inventory_balances'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'inventory_balances' AS source_table,
  f.legacy_row_id,
  'warehouse_id' AS column_name,
  'warehouses' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'inventory_balances'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'inventory_movements' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'inventory_movements'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'inventory_movements' AS source_table,
  f.legacy_row_id,
  'warehouse_id' AS column_name,
  'warehouses' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'inventory_movements'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'orders' AS source_table,
  f.legacy_row_id,
  'cart_id' AS column_name,
  'carts' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'orders'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carts'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carts' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'cart_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'orders' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'orders'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'orders' AS source_table,
  f.legacy_row_id,
  'sales_channel_id' AS column_name,
  'sales_channels' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'orders'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'sales_channels'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.sales_channel_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'sales_channels' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'sales_channel_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'product_prices' AS source_table,
  f.legacy_row_id,
  'price_list_id' AS column_name,
  'price_lists' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.price_list_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'product_prices'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.price_list_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'price_lists'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.price_list_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'price_lists' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'price_list_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'product_prices' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'product_prices'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'purchase_order_items' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'purchase_order_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'purchase_order_items' AS source_table,
  f.legacy_row_id,
  'purchase_order_id' AS column_name,
  'purchase_orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'purchase_order_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'purchase_orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'purchase_orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'purchase_order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'coupon_redemptions' AS source_table,
  f.legacy_row_id,
  'coupon_id' AS column_name,
  'coupons' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.coupon_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'coupon_redemptions'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.coupon_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'coupons'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.coupon_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'coupons' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'coupon_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'coupon_redemptions' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'coupon_redemptions'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'coupon_redemptions' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'coupon_redemptions'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'goods_receipt_items' AS source_table,
  f.legacy_row_id,
  'goods_receipt_id' AS column_name,
  'goods_receipts' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.goods_receipt_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'goods_receipt_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.goods_receipt_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'goods_receipts'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.goods_receipt_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'goods_receipts' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'goods_receipt_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'goods_receipt_items' AS source_table,
  f.legacy_row_id,
  'purchase_order_item_id' AS column_name,
  'purchase_order_items' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_item_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'goods_receipt_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_item_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'purchase_order_items'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.purchase_order_item_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'purchase_order_items' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'purchase_order_item_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'order_items' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'order_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'order_items' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'order_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'order_status_history' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'order_status_history'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'payments' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'payments'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'payments' AS source_table,
  f.legacy_row_id,
  'payment_method_id' AS column_name,
  'payment_methods' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_method_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'payments'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_method_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'payment_methods'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_method_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'payment_methods' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'payment_method_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'shipments' AS source_table,
  f.legacy_row_id,
  'carrier_id' AS column_name,
  'carriers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.carrier_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'shipments'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.carrier_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carriers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.carrier_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carriers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'carrier_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'shipments' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'shipments'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'shipments' AS source_table,
  f.legacy_row_id,
  'warehouse_id' AS column_name,
  'warehouses' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'shipments'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'stock_reservations' AS source_table,
  f.legacy_row_id,
  'cart_id' AS column_name,
  'carts' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'stock_reservations'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carts'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.cart_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'carts' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'cart_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'stock_reservations' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'stock_reservations'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'stock_reservations' AS source_table,
  f.legacy_row_id,
  'product_variant_id' AS column_name,
  'product_variants' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'stock_reservations'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.product_variant_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'product_variants' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'stock_reservations' AS source_table,
  f.legacy_row_id,
  'warehouse_id' AS column_name,
  'warehouses' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'stock_reservations'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.warehouse_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'warehouses' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'delivery_events' AS source_table,
  f.legacy_row_id,
  'shipment_id' AS column_name,
  'shipments' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'delivery_events'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'shipments'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'shipments' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'shipment_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'payment_transactions' AS source_table,
  f.legacy_row_id,
  'payment_id' AS column_name,
  'payments' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'payment_transactions'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'payments'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'payments' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'payment_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'shipment_items' AS source_table,
  f.legacy_row_id,
  'order_item_id' AS column_name,
  'order_items' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_item_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'shipment_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_item_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'order_items'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_item_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'order_items' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_item_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'shipment_items' AS source_table,
  f.legacy_row_id,
  'shipment_id' AS column_name,
  'shipments' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'shipment_items'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'shipments'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'shipments' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'shipment_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'support_tickets' AS source_table,
  f.legacy_row_id,
  'assigned_agent_id' AS column_name,
  'support_agents' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.assigned_agent_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'support_tickets'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.assigned_agent_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'support_agents'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.assigned_agent_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'support_agents' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'assigned_agent_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'support_tickets' AS source_table,
  f.legacy_row_id,
  'customer_id' AS column_name,
  'customers' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'support_tickets'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.customer_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'customers' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'support_tickets' AS source_table,
  f.legacy_row_id,
  'order_id' AS column_name,
  'orders' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'support_tickets'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.order_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'orders' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'support_tickets' AS source_table,
  f.legacy_row_id,
  'shipment_id' AS column_name,
  'shipments' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'support_tickets'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'shipments'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.shipment_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'shipments' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'shipment_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'refunds' AS source_table,
  f.legacy_row_id,
  'payment_transaction_id' AS column_name,
  'payment_transactions' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_transaction_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'refunds'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_transaction_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'payment_transactions'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.payment_transaction_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'payment_transactions' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'payment_transaction_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'ticket_events' AS source_table,
  f.legacy_row_id,
  'agent_id' AS column_name,
  'support_agents' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.agent_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'ticket_events'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.agent_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'support_agents'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.agent_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'support_agents' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'agent_id'", 'bigint') }}
  )
UNION ALL
SELECT
  'ticket_events' AS source_table,
  f.legacy_row_id,
  'ticket_id' AS column_name,
  'support_tickets' AS parent_table,
  JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.ticket_id') AS parent_value
FROM registros AS f
WHERE
  f.source_table = 'ticket_events'
  AND JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.ticket_id') IS NOT NULL
  AND NOT EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'support_tickets'
      AND JSON_EXTRACT_SCALAR(p.cleaned_payload, '$.id') = JSON_EXTRACT_SCALAR(f.cleaned_payload, '$.ticket_id')
  )
  AND EXISTS(
    SELECT
      1
    FROM registros AS p
    WHERE
      p.source_table = 'support_tickets' AND {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }} = {{ chave_canonica("f.cleaned_payload->>'ticket_id'", 'bigint') }}
  )
{% else %}with registros as (

    select source_table, legacy_row_id, cleaned_payload
    from {{ ref('legacy_records') }}

)

    select 'product_categories' as source_table, f.legacy_row_id, 'parent_id' as column_name,
        'product_categories' as parent_table, f.cleaned_payload->>'parent_id' as parent_value
    from registros f
    where f.source_table = 'product_categories' and f.cleaned_payload->>'parent_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_categories' and p.cleaned_payload->>'id' = f.cleaned_payload->>'parent_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_categories'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'parent_id'", 'bigint') }}
      )
    union all
    select 'coupons' as source_table, f.legacy_row_id, 'campaign_id' as column_name,
        'campaigns' as parent_table, f.cleaned_payload->>'campaign_id' as parent_value
    from registros f
    where f.source_table = 'coupons' and f.cleaned_payload->>'campaign_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'campaigns' and p.cleaned_payload->>'id' = f.cleaned_payload->>'campaign_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'campaigns'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'campaign_id'", 'bigint') }}
      )
    union all
    select 'customers' as source_table, f.legacy_row_id, 'segment_id' as column_name,
        'customer_segments' as parent_table, f.cleaned_payload->>'segment_id' as parent_value
    from registros f
    where f.source_table = 'customers' and f.cleaned_payload->>'segment_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customer_segments' and p.cleaned_payload->>'id' = f.cleaned_payload->>'segment_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customer_segments'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'segment_id'", 'bigint') }}
      )
    union all
    select 'price_lists' as source_table, f.legacy_row_id, 'sales_channel_id' as column_name,
        'sales_channels' as parent_table, f.cleaned_payload->>'sales_channel_id' as parent_value
    from registros f
    where f.source_table = 'price_lists' and f.cleaned_payload->>'sales_channel_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'sales_channels' and p.cleaned_payload->>'id' = f.cleaned_payload->>'sales_channel_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'sales_channels'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'sales_channel_id'", 'bigint') }}
      )
    union all
    select 'products' as source_table, f.legacy_row_id, 'brand_id' as column_name,
        'brands' as parent_table, f.cleaned_payload->>'brand_id' as parent_value
    from registros f
    where f.source_table = 'products' and f.cleaned_payload->>'brand_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'brands' and p.cleaned_payload->>'id' = f.cleaned_payload->>'brand_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'brands'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'brand_id'", 'bigint') }}
      )
    union all
    select 'products' as source_table, f.legacy_row_id, 'category_id' as column_name,
        'product_categories' as parent_table, f.cleaned_payload->>'category_id' as parent_value
    from registros f
    where f.source_table = 'products' and f.cleaned_payload->>'category_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_categories' and p.cleaned_payload->>'id' = f.cleaned_payload->>'category_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_categories'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'category_id'", 'bigint') }}
      )
    union all
    select 'purchase_orders' as source_table, f.legacy_row_id, 'supplier_id' as column_name,
        'suppliers' as parent_table, f.cleaned_payload->>'supplier_id' as parent_value
    from registros f
    where f.source_table = 'purchase_orders' and f.cleaned_payload->>'supplier_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'suppliers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'supplier_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'suppliers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'supplier_id'", 'bigint') }}
      )
    union all
    select 'carts' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'carts' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'carts' as source_table, f.legacy_row_id, 'sales_channel_id' as column_name,
        'sales_channels' as parent_table, f.cleaned_payload->>'sales_channel_id' as parent_value
    from registros f
    where f.source_table = 'carts' and f.cleaned_payload->>'sales_channel_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'sales_channels' and p.cleaned_payload->>'id' = f.cleaned_payload->>'sales_channel_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'sales_channels'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'sales_channel_id'", 'bigint') }}
      )
    union all
    select 'customer_addresses' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'customer_addresses' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'customer_contacts' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'customer_contacts' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'customer_preferences' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'customer_preferences' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'goods_receipts' as source_table, f.legacy_row_id, 'purchase_order_id' as column_name,
        'purchase_orders' as parent_table, f.cleaned_payload->>'purchase_order_id' as parent_value
    from registros f
    where f.source_table = 'goods_receipts' and f.cleaned_payload->>'purchase_order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'purchase_orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'purchase_order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'purchase_orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'purchase_order_id'", 'bigint') }}
      )
    union all
    select 'goods_receipts' as source_table, f.legacy_row_id, 'warehouse_id' as column_name,
        'warehouses' as parent_table, f.cleaned_payload->>'warehouse_id' as parent_value
    from registros f
    where f.source_table = 'goods_receipts' and f.cleaned_payload->>'warehouse_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'warehouses' and p.cleaned_payload->>'id' = f.cleaned_payload->>'warehouse_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'warehouses'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
      )
    union all
    select 'product_variants' as source_table, f.legacy_row_id, 'product_id' as column_name,
        'products' as parent_table, f.cleaned_payload->>'product_id' as parent_value
    from registros f
    where f.source_table = 'product_variants' and f.cleaned_payload->>'product_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'products' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'products'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_id'", 'bigint') }}
      )
    union all
    select 'cart_items' as source_table, f.legacy_row_id, 'cart_id' as column_name,
        'carts' as parent_table, f.cleaned_payload->>'cart_id' as parent_value
    from registros f
    where f.source_table = 'cart_items' and f.cleaned_payload->>'cart_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'carts' and p.cleaned_payload->>'id' = f.cleaned_payload->>'cart_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'carts'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'cart_id'", 'bigint') }}
      )
    union all
    select 'cart_items' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'cart_items' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'inventory_balances' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'inventory_balances' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'inventory_balances' as source_table, f.legacy_row_id, 'warehouse_id' as column_name,
        'warehouses' as parent_table, f.cleaned_payload->>'warehouse_id' as parent_value
    from registros f
    where f.source_table = 'inventory_balances' and f.cleaned_payload->>'warehouse_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'warehouses' and p.cleaned_payload->>'id' = f.cleaned_payload->>'warehouse_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'warehouses'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
      )
    union all
    select 'inventory_movements' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'inventory_movements' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'inventory_movements' as source_table, f.legacy_row_id, 'warehouse_id' as column_name,
        'warehouses' as parent_table, f.cleaned_payload->>'warehouse_id' as parent_value
    from registros f
    where f.source_table = 'inventory_movements' and f.cleaned_payload->>'warehouse_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'warehouses' and p.cleaned_payload->>'id' = f.cleaned_payload->>'warehouse_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'warehouses'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
      )
    union all
    select 'orders' as source_table, f.legacy_row_id, 'cart_id' as column_name,
        'carts' as parent_table, f.cleaned_payload->>'cart_id' as parent_value
    from registros f
    where f.source_table = 'orders' and f.cleaned_payload->>'cart_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'carts' and p.cleaned_payload->>'id' = f.cleaned_payload->>'cart_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'carts'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'cart_id'", 'bigint') }}
      )
    union all
    select 'orders' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'orders' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'orders' as source_table, f.legacy_row_id, 'sales_channel_id' as column_name,
        'sales_channels' as parent_table, f.cleaned_payload->>'sales_channel_id' as parent_value
    from registros f
    where f.source_table = 'orders' and f.cleaned_payload->>'sales_channel_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'sales_channels' and p.cleaned_payload->>'id' = f.cleaned_payload->>'sales_channel_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'sales_channels'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'sales_channel_id'", 'bigint') }}
      )
    union all
    select 'product_prices' as source_table, f.legacy_row_id, 'price_list_id' as column_name,
        'price_lists' as parent_table, f.cleaned_payload->>'price_list_id' as parent_value
    from registros f
    where f.source_table = 'product_prices' and f.cleaned_payload->>'price_list_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'price_lists' and p.cleaned_payload->>'id' = f.cleaned_payload->>'price_list_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'price_lists'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'price_list_id'", 'bigint') }}
      )
    union all
    select 'product_prices' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'product_prices' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'purchase_order_items' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'purchase_order_items' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'purchase_order_items' as source_table, f.legacy_row_id, 'purchase_order_id' as column_name,
        'purchase_orders' as parent_table, f.cleaned_payload->>'purchase_order_id' as parent_value
    from registros f
    where f.source_table = 'purchase_order_items' and f.cleaned_payload->>'purchase_order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'purchase_orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'purchase_order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'purchase_orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'purchase_order_id'", 'bigint') }}
      )
    union all
    select 'coupon_redemptions' as source_table, f.legacy_row_id, 'coupon_id' as column_name,
        'coupons' as parent_table, f.cleaned_payload->>'coupon_id' as parent_value
    from registros f
    where f.source_table = 'coupon_redemptions' and f.cleaned_payload->>'coupon_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'coupons' and p.cleaned_payload->>'id' = f.cleaned_payload->>'coupon_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'coupons'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'coupon_id'", 'bigint') }}
      )
    union all
    select 'coupon_redemptions' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'coupon_redemptions' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'coupon_redemptions' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'coupon_redemptions' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'goods_receipt_items' as source_table, f.legacy_row_id, 'goods_receipt_id' as column_name,
        'goods_receipts' as parent_table, f.cleaned_payload->>'goods_receipt_id' as parent_value
    from registros f
    where f.source_table = 'goods_receipt_items' and f.cleaned_payload->>'goods_receipt_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'goods_receipts' and p.cleaned_payload->>'id' = f.cleaned_payload->>'goods_receipt_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'goods_receipts'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'goods_receipt_id'", 'bigint') }}
      )
    union all
    select 'goods_receipt_items' as source_table, f.legacy_row_id, 'purchase_order_item_id' as column_name,
        'purchase_order_items' as parent_table, f.cleaned_payload->>'purchase_order_item_id' as parent_value
    from registros f
    where f.source_table = 'goods_receipt_items' and f.cleaned_payload->>'purchase_order_item_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'purchase_order_items' and p.cleaned_payload->>'id' = f.cleaned_payload->>'purchase_order_item_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'purchase_order_items'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'purchase_order_item_id'", 'bigint') }}
      )
    union all
    select 'order_items' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'order_items' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'order_items' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'order_items' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'order_status_history' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'order_status_history' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'payments' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'payments' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'payments' as source_table, f.legacy_row_id, 'payment_method_id' as column_name,
        'payment_methods' as parent_table, f.cleaned_payload->>'payment_method_id' as parent_value
    from registros f
    where f.source_table = 'payments' and f.cleaned_payload->>'payment_method_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'payment_methods' and p.cleaned_payload->>'id' = f.cleaned_payload->>'payment_method_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'payment_methods'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'payment_method_id'", 'bigint') }}
      )
    union all
    select 'shipments' as source_table, f.legacy_row_id, 'carrier_id' as column_name,
        'carriers' as parent_table, f.cleaned_payload->>'carrier_id' as parent_value
    from registros f
    where f.source_table = 'shipments' and f.cleaned_payload->>'carrier_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'carriers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'carrier_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'carriers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'carrier_id'", 'bigint') }}
      )
    union all
    select 'shipments' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'shipments' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'shipments' as source_table, f.legacy_row_id, 'warehouse_id' as column_name,
        'warehouses' as parent_table, f.cleaned_payload->>'warehouse_id' as parent_value
    from registros f
    where f.source_table = 'shipments' and f.cleaned_payload->>'warehouse_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'warehouses' and p.cleaned_payload->>'id' = f.cleaned_payload->>'warehouse_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'warehouses'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
      )
    union all
    select 'stock_reservations' as source_table, f.legacy_row_id, 'cart_id' as column_name,
        'carts' as parent_table, f.cleaned_payload->>'cart_id' as parent_value
    from registros f
    where f.source_table = 'stock_reservations' and f.cleaned_payload->>'cart_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'carts' and p.cleaned_payload->>'id' = f.cleaned_payload->>'cart_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'carts'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'cart_id'", 'bigint') }}
      )
    union all
    select 'stock_reservations' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'stock_reservations' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'stock_reservations' as source_table, f.legacy_row_id, 'product_variant_id' as column_name,
        'product_variants' as parent_table, f.cleaned_payload->>'product_variant_id' as parent_value
    from registros f
    where f.source_table = 'stock_reservations' and f.cleaned_payload->>'product_variant_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'product_variants' and p.cleaned_payload->>'id' = f.cleaned_payload->>'product_variant_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'product_variants'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'product_variant_id'", 'bigint') }}
      )
    union all
    select 'stock_reservations' as source_table, f.legacy_row_id, 'warehouse_id' as column_name,
        'warehouses' as parent_table, f.cleaned_payload->>'warehouse_id' as parent_value
    from registros f
    where f.source_table = 'stock_reservations' and f.cleaned_payload->>'warehouse_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'warehouses' and p.cleaned_payload->>'id' = f.cleaned_payload->>'warehouse_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'warehouses'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'warehouse_id'", 'bigint') }}
      )
    union all
    select 'delivery_events' as source_table, f.legacy_row_id, 'shipment_id' as column_name,
        'shipments' as parent_table, f.cleaned_payload->>'shipment_id' as parent_value
    from registros f
    where f.source_table = 'delivery_events' and f.cleaned_payload->>'shipment_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'shipments' and p.cleaned_payload->>'id' = f.cleaned_payload->>'shipment_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'shipments'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'shipment_id'", 'bigint') }}
      )
    union all
    select 'payment_transactions' as source_table, f.legacy_row_id, 'payment_id' as column_name,
        'payments' as parent_table, f.cleaned_payload->>'payment_id' as parent_value
    from registros f
    where f.source_table = 'payment_transactions' and f.cleaned_payload->>'payment_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'payments' and p.cleaned_payload->>'id' = f.cleaned_payload->>'payment_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'payments'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'payment_id'", 'bigint') }}
      )
    union all
    select 'shipment_items' as source_table, f.legacy_row_id, 'order_item_id' as column_name,
        'order_items' as parent_table, f.cleaned_payload->>'order_item_id' as parent_value
    from registros f
    where f.source_table = 'shipment_items' and f.cleaned_payload->>'order_item_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'order_items' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_item_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'order_items'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_item_id'", 'bigint') }}
      )
    union all
    select 'shipment_items' as source_table, f.legacy_row_id, 'shipment_id' as column_name,
        'shipments' as parent_table, f.cleaned_payload->>'shipment_id' as parent_value
    from registros f
    where f.source_table = 'shipment_items' and f.cleaned_payload->>'shipment_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'shipments' and p.cleaned_payload->>'id' = f.cleaned_payload->>'shipment_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'shipments'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'shipment_id'", 'bigint') }}
      )
    union all
    select 'support_tickets' as source_table, f.legacy_row_id, 'assigned_agent_id' as column_name,
        'support_agents' as parent_table, f.cleaned_payload->>'assigned_agent_id' as parent_value
    from registros f
    where f.source_table = 'support_tickets' and f.cleaned_payload->>'assigned_agent_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'support_agents' and p.cleaned_payload->>'id' = f.cleaned_payload->>'assigned_agent_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'support_agents'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'assigned_agent_id'", 'bigint') }}
      )
    union all
    select 'support_tickets' as source_table, f.legacy_row_id, 'customer_id' as column_name,
        'customers' as parent_table, f.cleaned_payload->>'customer_id' as parent_value
    from registros f
    where f.source_table = 'support_tickets' and f.cleaned_payload->>'customer_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'customers' and p.cleaned_payload->>'id' = f.cleaned_payload->>'customer_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'customers'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'customer_id'", 'bigint') }}
      )
    union all
    select 'support_tickets' as source_table, f.legacy_row_id, 'order_id' as column_name,
        'orders' as parent_table, f.cleaned_payload->>'order_id' as parent_value
    from registros f
    where f.source_table = 'support_tickets' and f.cleaned_payload->>'order_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'orders' and p.cleaned_payload->>'id' = f.cleaned_payload->>'order_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'orders'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'order_id'", 'bigint') }}
      )
    union all
    select 'support_tickets' as source_table, f.legacy_row_id, 'shipment_id' as column_name,
        'shipments' as parent_table, f.cleaned_payload->>'shipment_id' as parent_value
    from registros f
    where f.source_table = 'support_tickets' and f.cleaned_payload->>'shipment_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'shipments' and p.cleaned_payload->>'id' = f.cleaned_payload->>'shipment_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'shipments'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'shipment_id'", 'bigint') }}
      )
    union all
    select 'refunds' as source_table, f.legacy_row_id, 'payment_transaction_id' as column_name,
        'payment_transactions' as parent_table, f.cleaned_payload->>'payment_transaction_id' as parent_value
    from registros f
    where f.source_table = 'refunds' and f.cleaned_payload->>'payment_transaction_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'payment_transactions' and p.cleaned_payload->>'id' = f.cleaned_payload->>'payment_transaction_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'payment_transactions'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'payment_transaction_id'", 'bigint') }}
      )
    union all
    select 'ticket_events' as source_table, f.legacy_row_id, 'agent_id' as column_name,
        'support_agents' as parent_table, f.cleaned_payload->>'agent_id' as parent_value
    from registros f
    where f.source_table = 'ticket_events' and f.cleaned_payload->>'agent_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'support_agents' and p.cleaned_payload->>'id' = f.cleaned_payload->>'agent_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'support_agents'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'agent_id'", 'bigint') }}
      )
    union all
    select 'ticket_events' as source_table, f.legacy_row_id, 'ticket_id' as column_name,
        'support_tickets' as parent_table, f.cleaned_payload->>'ticket_id' as parent_value
    from registros f
    where f.source_table = 'ticket_events' and f.cleaned_payload->>'ticket_id' is not null
      and not exists (
          select 1 from registros p
          where p.source_table = 'support_tickets' and p.cleaned_payload->>'id' = f.cleaned_payload->>'ticket_id'
      )
      and exists (
          select 1 from registros p
          where p.source_table = 'support_tickets'
            and {{ chave_canonica("p.cleaned_payload->>'id'", 'bigint') }}
              = {{ chave_canonica("f.cleaned_payload->>'ticket_id'", 'bigint') }}
      ){% endif %}
