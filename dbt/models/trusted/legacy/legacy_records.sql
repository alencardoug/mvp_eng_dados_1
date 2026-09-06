-- Gerado por make legacy-models; altere legacy/classification.py ou classification.sql.
select 'brands'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'country', r."country", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__brands') }} r
union all
select 'campaigns'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'objective', r."objective", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'budget_amount', r."budget_amount", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "objective", "valid_from", "valid_to", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__campaigns') }} r
union all
select 'carriers'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'service_level', r."service_level", 'tracking_url_template', r."tracking_url_template", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "service_level", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__carriers') }} r
union all
select 'customer_segments'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'description', r."description", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__customer_segments') }} r
union all
select 'payment_methods'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'method_type', r."method_type", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "method_type", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__payment_methods') }} r
union all
select 'product_categories'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'parent_id', r."parent_id", 'depth', r."depth", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "parent_id", "key": "id", "table": "product_categories"}], "required": ["id", "code", "name", "depth", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__product_categories') }} r
union all
select 'sales_channels'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'channel_type', r."channel_type", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "channel_type", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__sales_channels') }} r
union all
select 'suppliers'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'supplier_code', r."supplier_code", 'legal_name', r."legal_name", 'trade_name', r."trade_name", 'document', r."document", 'contact_email', r."contact_email", 'country', r."country", 'payment_terms_days', r."payment_terms_days", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "supplier_code", "legal_name", "document", "country", "payment_terms_days", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["document"], "conditions": []}, {"columns": ["id"], "conditions": []}, {"columns": ["supplier_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__suppliers') }} r
union all
select 'support_agents'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'agent_code', r."agent_code", 'first_name', r."first_name", 'last_name', r."last_name", 'email', r."email", 'team', r."team", 'hired_at', r."hired_at", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "agent_code", "first_name", "last_name", "email", "team", "hired_at", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["agent_code"], "conditions": []}, {"columns": ["email"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__support_agents') }} r
union all
select 'warehouses'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'city', r."city", 'state', r."state", 'country', r."country", 'capacity_units', r."capacity_units", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [], "required": ["id", "code", "name", "city", "state", "country", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__warehouses') }} r
union all
select 'coupons'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'campaign_id', r."campaign_id", 'discount_type', r."discount_type", 'discount_value', r."discount_value", 'min_order_amount', r."min_order_amount", 'max_redemptions', r."max_redemptions", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "campaign_id", "key": "id", "table": "campaigns"}], "required": ["id", "code", "campaign_id", "discount_type", "discount_value", "valid_from", "valid_to", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__coupons') }} r
union all
select 'customers'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'customer_code', r."customer_code", 'segment_id', r."segment_id", 'first_name', r."first_name", 'last_name', r."last_name", 'document', r."document", 'birth_date', r."birth_date", 'status', r."status", 'registered_at', r."registered_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "segment_id", "key": "id", "table": "customer_segments"}], "required": ["id", "customer_code", "first_name", "last_name", "document", "status", "registered_at", "created_at", "updated_at"], "unique_keys": [{"columns": ["customer_code"], "conditions": []}, {"columns": ["document"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__customers') }} r
union all
select 'price_lists'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'code', r."code", 'name', r."name", 'sales_channel_id', r."sales_channel_id", 'currency', r."currency", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "sales_channel_id", "key": "id", "table": "sales_channels"}], "required": ["id", "code", "name", "currency", "valid_from", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__price_lists') }} r
union all
select 'products'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'product_code', r."product_code", 'category_id', r."category_id", 'brand_id', r."brand_id", 'name', r."name", 'description', r."description", 'status', r."status", 'launched_at', r."launched_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "category_id", "key": "id", "table": "product_categories"}, {"column": "brand_id", "key": "id", "table": "brands"}], "required": ["id", "product_code", "category_id", "name", "status", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["product_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__products') }} r
union all
select 'purchase_orders'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'po_number', r."po_number", 'supplier_id', r."supplier_id", 'status', r."status", 'ordered_at', r."ordered_at", 'expected_at', r."expected_at", 'currency', r."currency", 'total_amount', r."total_amount", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "supplier_id", "key": "id", "table": "suppliers"}], "required": ["id", "po_number", "supplier_id", "status", "ordered_at", "currency", "total_amount", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["po_number"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__purchase_orders') }} r
union all
select 'carts'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'cart_code', r."cart_code", 'customer_id', r."customer_id", 'sales_channel_id', r."sales_channel_id", 'status', r."status", 'expires_at', r."expires_at", 'converted_at', r."converted_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "customer_id", "key": "id", "table": "customers"}, {"column": "sales_channel_id", "key": "id", "table": "sales_channels"}], "required": ["id", "cart_code", "sales_channel_id", "status", "created_at", "updated_at"], "unique_keys": [{"columns": ["cart_code"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__carts') }} r
union all
select 'customer_addresses'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'customer_id', r."customer_id", 'address_type', r."address_type", 'street', r."street", 'number', r."number", 'complement', r."complement", 'district', r."district", 'city', r."city", 'state', r."state", 'postal_code', r."postal_code", 'country', r."country", 'is_primary', r."is_primary", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "customer_id", "key": "id", "table": "customers"}], "required": ["id", "customer_id", "address_type", "street", "city", "state", "postal_code", "country", "is_primary", "valid_from", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["customer_id", "address_type"], "conditions": [{"column": "is_primary", "kind": "is_true"}, {"column": "deleted_at", "kind": "is_null"}]}]}'::jsonb as record_contract
from {{ ref('stg_legacy__customer_addresses') }} r
union all
select 'customer_contacts'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'customer_id', r."customer_id", 'contact_type', r."contact_type", 'contact_value', r."contact_value", 'is_primary', r."is_primary", 'is_verified', r."is_verified", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "customer_id", "key": "id", "table": "customers"}], "required": ["id", "customer_id", "contact_type", "contact_value", "is_primary", "is_verified", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["customer_id", "contact_type"], "conditions": [{"column": "is_primary", "kind": "is_true"}, {"column": "deleted_at", "kind": "is_null"}]}]}'::jsonb as record_contract
from {{ ref('stg_legacy__customer_contacts') }} r
union all
select 'customer_preferences'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'customer_id', r."customer_id", 'language', r."language", 'currency', r."currency", 'marketing_opt_in', r."marketing_opt_in", 'newsletter_opt_in', r."newsletter_opt_in", 'consent_updated_at', r."consent_updated_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "customer_id", "key": "id", "table": "customers"}], "required": ["id", "customer_id", "language", "currency", "marketing_opt_in", "newsletter_opt_in", "created_at", "updated_at"], "unique_keys": [{"columns": ["customer_id"], "conditions": []}, {"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__customer_preferences') }} r
union all
select 'goods_receipts'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'receipt_number', r."receipt_number", 'purchase_order_id', r."purchase_order_id", 'warehouse_id', r."warehouse_id", 'received_at', r."received_at", 'status', r."status", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "purchase_order_id", "key": "id", "table": "purchase_orders"}, {"column": "warehouse_id", "key": "id", "table": "warehouses"}], "required": ["id", "receipt_number", "purchase_order_id", "warehouse_id", "received_at", "status", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["receipt_number"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__goods_receipts') }} r
union all
select 'product_variants'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'product_id', r."product_id", 'sku', r."sku", 'size', r."size", 'color', r."color", 'package', r."package", 'barcode', r."barcode", 'weight_grams', r."weight_grams", 'is_active', r."is_active", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "product_id", "key": "id", "table": "products"}], "required": ["id", "product_id", "sku", "is_active", "created_at", "updated_at"], "unique_keys": [{"columns": ["barcode"], "conditions": []}, {"columns": ["id"], "conditions": []}, {"columns": ["sku"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__product_variants') }} r
union all
select 'cart_items'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'cart_id', r."cart_id", 'product_variant_id', r."product_variant_id", 'quantity', r."quantity", 'unit_price', r."unit_price", 'added_at', r."added_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "cart_id", "key": "id", "table": "carts"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}], "required": ["id", "cart_id", "product_variant_id", "quantity", "unit_price", "added_at", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__cart_items') }} r
union all
select 'inventory_balances'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'warehouse_id', r."warehouse_id", 'product_variant_id', r."product_variant_id", 'quantity_on_hand', r."quantity_on_hand", 'quantity_reserved', r."quantity_reserved", 'last_movement_at', r."last_movement_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "warehouse_id", "key": "id", "table": "warehouses"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}], "required": ["id", "warehouse_id", "product_variant_id", "quantity_on_hand", "quantity_reserved", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["warehouse_id", "product_variant_id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__inventory_balances') }} r
union all
select 'inventory_movements'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('movement_id', r."movement_id", 'idempotency_key', r."idempotency_key", 'warehouse_id', r."warehouse_id", 'product_variant_id', r."product_variant_id", 'movement_type', r."movement_type", 'quantity_delta', r."quantity_delta", 'unit_cost', r."unit_cost", 'source_type', r."source_type", 'source_id', r."source_id", 'correlation_id', r."correlation_id", 'causation_id', r."causation_id", 'aggregate_version', r."aggregate_version", 'occurred_at', r."occurred_at", 'recorded_at', r."recorded_at", 'schema_version', r."schema_version", 'metadata', r."metadata") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "warehouse_id", "key": "id", "table": "warehouses"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}], "required": ["movement_id", "idempotency_key", "warehouse_id", "product_variant_id", "movement_type", "quantity_delta", "source_type", "source_id", "aggregate_version", "occurred_at", "recorded_at", "schema_version"], "unique_keys": [{"columns": ["idempotency_key"], "conditions": []}, {"columns": ["movement_id"], "conditions": []}, {"columns": ["warehouse_id", "product_variant_id", "aggregate_version"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__inventory_movements') }} r
union all
select 'orders'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'order_number', r."order_number", 'customer_id', r."customer_id", 'sales_channel_id', r."sales_channel_id", 'cart_id', r."cart_id", 'status', r."status", 'placed_at', r."placed_at", 'currency', r."currency", 'subtotal_amount', r."subtotal_amount", 'discount_amount', r."discount_amount", 'shipping_amount', r."shipping_amount", 'tax_amount', r."tax_amount", 'total_amount', r."total_amount", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "customer_id", "key": "id", "table": "customers"}, {"column": "sales_channel_id", "key": "id", "table": "sales_channels"}, {"column": "cart_id", "key": "id", "table": "carts"}], "required": ["id", "order_number", "customer_id", "sales_channel_id", "status", "placed_at", "currency", "subtotal_amount", "discount_amount", "shipping_amount", "tax_amount", "total_amount", "created_at", "updated_at"], "unique_keys": [{"columns": ["cart_id"], "conditions": []}, {"columns": ["id"], "conditions": []}, {"columns": ["order_number"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__orders') }} r
union all
select 'product_prices'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'price_list_id', r."price_list_id", 'product_variant_id', r."product_variant_id", 'unit_price', r."unit_price", 'valid_from', r."valid_from", 'valid_to', r."valid_to", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "price_list_id", "key": "id", "table": "price_lists"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}], "required": ["id", "price_list_id", "product_variant_id", "unit_price", "valid_from", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["price_list_id", "product_variant_id", "valid_from"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__product_prices') }} r
union all
select 'purchase_order_items'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'purchase_order_id', r."purchase_order_id", 'product_variant_id', r."product_variant_id", 'quantity_ordered', r."quantity_ordered", 'unit_cost', r."unit_cost", 'total_cost', r."total_cost", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "purchase_order_id", "key": "id", "table": "purchase_orders"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}], "required": ["id", "purchase_order_id", "product_variant_id", "quantity_ordered", "unit_cost", "total_cost", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["purchase_order_id", "product_variant_id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__purchase_order_items') }} r
union all
select 'coupon_redemptions'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'coupon_id', r."coupon_id", 'customer_id', r."customer_id", 'order_id', r."order_id", 'discount_amount', r."discount_amount", 'redeemed_at', r."redeemed_at", 'created_at', r."created_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "coupon_id", "key": "id", "table": "coupons"}, {"column": "customer_id", "key": "id", "table": "customers"}, {"column": "order_id", "key": "id", "table": "orders"}], "required": ["id", "coupon_id", "customer_id", "order_id", "discount_amount", "redeemed_at", "created_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["order_id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__coupon_redemptions') }} r
union all
select 'goods_receipt_items'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'goods_receipt_id', r."goods_receipt_id", 'purchase_order_item_id', r."purchase_order_item_id", 'quantity_received', r."quantity_received", 'unit_cost', r."unit_cost", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "goods_receipt_id", "key": "id", "table": "goods_receipts"}, {"column": "purchase_order_item_id", "key": "id", "table": "purchase_order_items"}], "required": ["id", "goods_receipt_id", "purchase_order_item_id", "quantity_received", "unit_cost", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["goods_receipt_id", "purchase_order_item_id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__goods_receipt_items') }} r
union all
select 'order_items'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'order_id', r."order_id", 'product_variant_id', r."product_variant_id", 'quantity', r."quantity", 'unit_price', r."unit_price", 'discount_amount', r."discount_amount", 'tax_amount', r."tax_amount", 'total_amount', r."total_amount", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "order_id", "key": "id", "table": "orders"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}], "required": ["id", "order_id", "product_variant_id", "quantity", "unit_price", "discount_amount", "tax_amount", "total_amount", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["order_id", "product_variant_id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__order_items') }} r
union all
select 'order_status_history'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'order_id', r."order_id", 'from_status', r."from_status", 'to_status', r."to_status", 'changed_at', r."changed_at", 'reason', r."reason", 'created_at', r."created_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "order_id", "key": "id", "table": "orders"}], "required": ["id", "order_id", "to_status", "changed_at", "created_at"], "unique_keys": [{"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__order_status_history') }} r
union all
select 'payments'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'payment_code', r."payment_code", 'order_id', r."order_id", 'payment_method_id', r."payment_method_id", 'status', r."status", 'amount', r."amount", 'currency', r."currency", 'installments', r."installments", 'authorized_at', r."authorized_at", 'captured_at', r."captured_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "order_id", "key": "id", "table": "orders"}, {"column": "payment_method_id", "key": "id", "table": "payment_methods"}], "required": ["id", "payment_code", "order_id", "payment_method_id", "status", "amount", "currency", "installments", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["payment_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__payments') }} r
union all
select 'shipments'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'shipment_code', r."shipment_code", 'order_id', r."order_id", 'carrier_id', r."carrier_id", 'warehouse_id', r."warehouse_id", 'status', r."status", 'tracking_code', r."tracking_code", 'freight_amount', r."freight_amount", 'shipped_at', r."shipped_at", 'estimated_delivery_at', r."estimated_delivery_at", 'delivered_at', r."delivered_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "order_id", "key": "id", "table": "orders"}, {"column": "carrier_id", "key": "id", "table": "carriers"}, {"column": "warehouse_id", "key": "id", "table": "warehouses"}], "required": ["id", "shipment_code", "order_id", "carrier_id", "warehouse_id", "status", "freight_amount", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["shipment_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__shipments') }} r
union all
select 'stock_reservations'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'reservation_code', r."reservation_code", 'warehouse_id', r."warehouse_id", 'product_variant_id', r."product_variant_id", 'cart_id', r."cart_id", 'order_id', r."order_id", 'quantity', r."quantity", 'status', r."status", 'expires_at', r."expires_at", 'released_at', r."released_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "warehouse_id", "key": "id", "table": "warehouses"}, {"column": "product_variant_id", "key": "id", "table": "product_variants"}, {"column": "cart_id", "key": "id", "table": "carts"}, {"column": "order_id", "key": "id", "table": "orders"}], "required": ["id", "reservation_code", "warehouse_id", "product_variant_id", "quantity", "status", "expires_at", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["reservation_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__stock_reservations') }} r
union all
select 'delivery_events'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'shipment_id', r."shipment_id", 'event_type', r."event_type", 'occurred_at', r."occurred_at", 'location', r."location", 'description', r."description", 'created_at', r."created_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "shipment_id", "key": "id", "table": "shipments"}], "required": ["id", "shipment_id", "event_type", "occurred_at", "created_at"], "unique_keys": [{"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__delivery_events') }} r
union all
select 'payment_transactions'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'transaction_code', r."transaction_code", 'payment_id', r."payment_id", 'transaction_type', r."transaction_type", 'result', r."result", 'amount', r."amount", 'gateway_response_code', r."gateway_response_code", 'occurred_at', r."occurred_at", 'created_at', r."created_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "payment_id", "key": "id", "table": "payments"}], "required": ["id", "transaction_code", "payment_id", "transaction_type", "result", "amount", "occurred_at", "created_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["transaction_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__payment_transactions') }} r
union all
select 'shipment_items'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'shipment_id', r."shipment_id", 'order_item_id', r."order_item_id", 'quantity', r."quantity", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "shipment_id", "key": "id", "table": "shipments"}, {"column": "order_item_id", "key": "id", "table": "order_items"}], "required": ["id", "shipment_id", "order_item_id", "quantity", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["shipment_id", "order_item_id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__shipment_items') }} r
union all
select 'support_tickets'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'ticket_number', r."ticket_number", 'customer_id', r."customer_id", 'order_id', r."order_id", 'shipment_id', r."shipment_id", 'assigned_agent_id', r."assigned_agent_id", 'category', r."category", 'priority', r."priority", 'status', r."status", 'subject', r."subject", 'opened_at', r."opened_at", 'closed_at', r."closed_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "customer_id", "key": "id", "table": "customers"}, {"column": "order_id", "key": "id", "table": "orders"}, {"column": "shipment_id", "key": "id", "table": "shipments"}, {"column": "assigned_agent_id", "key": "id", "table": "support_agents"}], "required": ["id", "ticket_number", "customer_id", "category", "priority", "status", "subject", "opened_at", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["ticket_number"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__support_tickets') }} r
union all
select 'refunds'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'refund_code', r."refund_code", 'payment_transaction_id', r."payment_transaction_id", 'amount', r."amount", 'reason', r."reason", 'status', r."status", 'refunded_at', r."refunded_at", 'created_at', r."created_at", 'updated_at', r."updated_at", 'deleted_at', r."deleted_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "payment_transaction_id", "key": "id", "table": "payment_transactions"}], "required": ["id", "refund_code", "payment_transaction_id", "amount", "status", "created_at", "updated_at"], "unique_keys": [{"columns": ["id"], "conditions": []}, {"columns": ["refund_code"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__refunds') }} r
union all
select 'ticket_events'::text as source_table,
    r.source_system, r.snapshot_id, r.snapshot_at, r.legacy_row_id,
    r.original_payload, jsonb_build_object('id', r."id", 'ticket_id', r."ticket_id", 'agent_id', r."agent_id", 'event_type', r."event_type", 'occurred_at', r."occurred_at", 'message', r."message", 'created_at', r."created_at") as cleaned_payload,
    r.achados as value_findings, '{"references": [{"column": "ticket_id", "key": "id", "table": "support_tickets"}, {"column": "agent_id", "key": "id", "table": "support_agents"}], "required": ["id", "ticket_id", "event_type", "occurred_at", "created_at"], "unique_keys": [{"columns": ["id"], "conditions": []}]}'::jsonb as record_contract
from {{ ref('stg_legacy__ticket_events') }} r
