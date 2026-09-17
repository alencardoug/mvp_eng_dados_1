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

with registros as (

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
      )
