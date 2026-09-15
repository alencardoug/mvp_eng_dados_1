-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Presença física por captura, tabela e chave canônica (ADR-0045).
--
-- Só capturas **certificadas** entram (ADR-0044), mais a selecionada — que é
-- certificada por definição, salvo quando `legacy_snapshot_id` reprocessa uma
-- antiga. A chave é a PK declarada no SQLAlchemy, canonizada pelo tipo:
-- `business_key` nulo é linha **sem identidade**, contada à parte.

{{ config(materialized='table') }}

with certificadas as (

    select snapshot_id
    from {{ source('governance', 'legacy_captures') }}
    where status = 'complete'
    group by snapshot_id
    having count(distinct source_table) = 40

),

selecionada as (

    select snapshot_id from {{ ref('legacy_selected_capture') }}

),

consideradas as (

    select snapshot_id from certificadas
    union
    select snapshot_id from selecionada where snapshot_id is not null

)

select
    'brands'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'country', r."country", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'brands') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'campaigns'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'objective', r."objective", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'budget_amount', r."budget_amount", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'campaigns') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'carriers'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'service_level', r."service_level", 'tracking_url_template', r."tracking_url_template", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'carriers') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'customer_segments'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'description', r."description", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'customer_segments') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'payment_methods'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'method_type', r."method_type", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'payment_methods') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'product_categories'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'parent_id', r."parent_id", 'depth', r."depth", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'product_categories') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'sales_channels'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'channel_type', r."channel_type", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'sales_channels') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'suppliers'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'supplier_code', r."supplier_code", 'legal_name', r."legal_name", 'trade_name', r."trade_name", 'document', r."document", 'contact_email', r."contact_email", 'country', r."country", 'payment_terms_days', r."payment_terms_days", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'suppliers') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'support_agents'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'agent_code', r."agent_code", 'first_name', r."first_name", 'last_name', r."last_name", 'email', r."email", 'team', r."team", 'hired_at', r."hired_at", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'support_agents') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'warehouses'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'city', r."city", 'state', r."state", 'country', r."country", 'capacity_units', r."capacity_units", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'warehouses') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'coupons'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'campaign_id', r."campaign_id", 'discount_type', r."discount_type", 'discount_value', r."discount_value", 'min_order_amount', r."min_order_amount", 'max_redemptions', r."max_redemptions", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'coupons') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'customers'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'customer_code', r."customer_code", 'segment_id', r."segment_id", 'first_name', r."first_name", 'last_name', r."last_name", 'document', r."document", 'birth_date', r."birth_date", 'status', r."status", 'registered_at', r."registered_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'customers') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'price_lists'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'sales_channel_id', r."sales_channel_id", 'currency', r."currency", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'price_lists') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'products'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'product_code', r."product_code", 'category_id', r."category_id", 'brand_id', r."brand_id", 'name', r."name", 'description', r."description", 'status', r."status", 'launched_at', r."launched_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'products') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'purchase_orders'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'po_number', r."po_number", 'supplier_id', r."supplier_id", 'status', r."status", 'ordered_at', r."ordered_at", 'expected_at', r."expected_at", 'currency', r."currency", 'total_amount', r."total_amount", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'purchase_orders') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'carts'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'cart_code', r."cart_code", 'customer_id', r."customer_id", 'sales_channel_id', r."sales_channel_id", 'status', r."status", 'expires_at', r."expires_at", 'converted_at', r."converted_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'carts') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'customer_addresses'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'customer_id', r."customer_id", 'address_type', r."address_type", 'street', r."street", 'number', r."number", 'complement', r."complement", 'district', r."district", 'city', r."city", 'state', r."state", 'postal_code', r."postal_code", 'country', r."country", 'is_primary', r."is_primary", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'customer_addresses') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'customer_contacts'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'customer_id', r."customer_id", 'contact_type', r."contact_type", 'contact_value', r."contact_value", 'is_primary', r."is_primary", 'is_verified', r."is_verified", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'customer_contacts') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'customer_preferences'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'customer_id', r."customer_id", 'language', r."language", 'currency', r."currency", 'marketing_opt_in', r."marketing_opt_in", 'newsletter_opt_in', r."newsletter_opt_in", 'consent_updated_at', r."consent_updated_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'customer_preferences') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'goods_receipts'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'receipt_number', r."receipt_number", 'purchase_order_id', r."purchase_order_id", 'warehouse_id', r."warehouse_id", 'received_at', r."received_at", 'status', r."status", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'goods_receipts') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'product_variants'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'product_id', r."product_id", 'sku', r."sku", 'size', r."size", 'color', r."color", 'package', r."package", 'barcode', r."barcode", 'weight_grams', r."weight_grams", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'product_variants') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'cart_items'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'cart_id', r."cart_id", 'product_variant_id', r."product_variant_id", 'quantity', r."quantity", 'unit_price', r."unit_price", 'added_at', r."added_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'cart_items') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'inventory_balances'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'warehouse_id', r."warehouse_id", 'product_variant_id', r."product_variant_id", 'quantity_on_hand', r."quantity_on_hand", 'quantity_reserved', r."quantity_reserved", 'last_movement_at', r."last_movement_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'inventory_balances') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'inventory_movements'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."movement_id"', 'uuid') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('movement_id', r."movement_id", 'idempotency_key', r."idempotency_key", 'warehouse_id', r."warehouse_id", 'product_variant_id', r."product_variant_id", 'movement_type', r."movement_type", 'quantity_delta', r."quantity_delta", 'unit_cost', r."unit_cost", 'source_type', r."source_type", 'source_id', r."source_id", 'correlation_id', r."correlation_id", 'causation_id', r."causation_id", 'aggregate_version', r."aggregate_version", 'occurred_at', r."occurred_at", 'recorded_at', r."recorded_at", 'schema_version', r."schema_version", 'metadata', r."metadata") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'inventory_movements') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'orders'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'order_number', r."order_number", 'customer_id', r."customer_id", 'sales_channel_id', r."sales_channel_id", 'cart_id', r."cart_id", 'status', r."status", 'placed_at', r."placed_at", 'currency', r."currency", 'subtotal_amount', r."subtotal_amount", 'discount_amount', r."discount_amount", 'shipping_amount', r."shipping_amount", 'tax_amount', r."tax_amount", 'total_amount', r."total_amount", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'orders') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'product_prices'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'price_list_id', r."price_list_id", 'product_variant_id', r."product_variant_id", 'unit_price', r."unit_price", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'product_prices') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'purchase_order_items'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'purchase_order_id', r."purchase_order_id", 'product_variant_id', r."product_variant_id", 'quantity_ordered', r."quantity_ordered", 'unit_cost', r."unit_cost", 'total_cost', r."total_cost", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'purchase_order_items') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'coupon_redemptions'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'coupon_id', r."coupon_id", 'customer_id', r."customer_id", 'order_id', r."order_id", 'discount_amount', r."discount_amount", 'redeemed_at', r."redeemed_at", 'created_at', r."created_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'coupon_redemptions') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'goods_receipt_items'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'goods_receipt_id', r."goods_receipt_id", 'purchase_order_item_id', r."purchase_order_item_id", 'quantity_received', r."quantity_received", 'unit_cost', r."unit_cost", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'goods_receipt_items') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'order_items'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'order_id', r."order_id", 'product_variant_id', r."product_variant_id", 'quantity', r."quantity", 'unit_price', r."unit_price", 'discount_amount', r."discount_amount", 'tax_amount', r."tax_amount", 'total_amount', r."total_amount", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'order_items') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'order_status_history'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'order_id', r."order_id", 'from_status', r."from_status", 'to_status', r."to_status", 'changed_at', r."changed_at", 'reason', r."reason", 'created_at', r."created_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'order_status_history') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'payments'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'payment_code', r."payment_code", 'order_id', r."order_id", 'payment_method_id', r."payment_method_id", 'status', r."status", 'amount', r."amount", 'currency', r."currency", 'installments', r."installments", 'authorized_at', r."authorized_at", 'captured_at', r."captured_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'payments') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'shipments'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'shipment_code', r."shipment_code", 'order_id', r."order_id", 'carrier_id', r."carrier_id", 'warehouse_id', r."warehouse_id", 'status', r."status", 'tracking_code', r."tracking_code", 'freight_amount', r."freight_amount", 'shipped_at', r."shipped_at", 'estimated_delivery_at', r."estimated_delivery_at", 'delivered_at', r."delivered_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'shipments') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'stock_reservations'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'reservation_code', r."reservation_code", 'warehouse_id', r."warehouse_id", 'product_variant_id', r."product_variant_id", 'cart_id', r."cart_id", 'order_id', r."order_id", 'quantity', r."quantity", 'status', r."status", 'expires_at', r."expires_at", 'released_at', r."released_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'stock_reservations') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'delivery_events'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'shipment_id', r."shipment_id", 'event_type', r."event_type", 'occurred_at', r."occurred_at", 'location', r."location", 'description', r."description", 'created_at', r."created_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'delivery_events') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'payment_transactions'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'transaction_code', r."transaction_code", 'payment_id', r."payment_id", 'transaction_type', r."transaction_type", 'result', r."result", 'amount', r."amount", 'gateway_response_code', r."gateway_response_code", 'occurred_at', r."occurred_at", 'created_at', r."created_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'payment_transactions') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'shipment_items'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'shipment_id', r."shipment_id", 'order_item_id', r."order_item_id", 'quantity', r."quantity", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'shipment_items') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'support_tickets'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'ticket_number', r."ticket_number", 'customer_id', r."customer_id", 'order_id', r."order_id", 'shipment_id', r."shipment_id", 'assigned_agent_id', r."assigned_agent_id", 'category', r."category", 'priority', r."priority", 'status', r."status", 'subject', r."subject", 'opened_at', r."opened_at", 'closed_at', r."closed_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'support_tickets') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'refunds'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'refund_code', r."refund_code", 'payment_transaction_id', r."payment_transaction_id", 'amount', r."amount", 'reason', r."reason", 'status', r."status", 'refunded_at', r."refunded_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'refunds') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3

union all

select
    'ticket_events'::text                                          as source_table,
    r._airbyte_generation_id                                  as snapshot_id,
    {{ chave_canonica('r."id"', 'inteiro') }}                  as business_key,
    count(*)                                                  as n,
    jsonb_agg(jsonb_build_object('id', r."id", 'ticket_id', r."ticket_id", 'agent_id', r."agent_id", 'event_type', r."event_type", 'occurred_at', r."occurred_at", 'message', r."message", 'created_at', r."created_at") order by r.legacy_row_id) as payloads
from {{ source('legacy', 'ticket_events') }} r
where r._airbyte_generation_id in (select snapshot_id from consideradas)
group by 1, 2, 3
