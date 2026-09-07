-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A captura do legado que esta execução lê.
--
-- `legacy_snapshot_id` escolhe explicitamente, para reprocessar uma captura
-- antiga; sem ele, vale a mais recente. Que ela **exista** e esteja
-- **completa** não se assume: é o que os testes `legacy_captura_existe` e
-- `legacy_captura_completa` conferem.

{{ config(materialized='table') }}

with geracoes as (

    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'brands') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'campaigns') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'carriers') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'customer_segments') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'payment_methods') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'product_categories') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'sales_channels') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'suppliers') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'support_agents') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'warehouses') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'coupons') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'customers') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'price_lists') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'products') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'purchase_orders') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'carts') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'customer_addresses') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'customer_contacts') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'customer_preferences') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'goods_receipts') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'product_variants') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'cart_items') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'inventory_balances') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'inventory_movements') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'orders') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'product_prices') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'purchase_order_items') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'coupon_redemptions') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'goods_receipt_items') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'order_items') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'order_status_history') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'payments') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'shipments') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'stock_reservations') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'delivery_events') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'payment_transactions') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'shipment_items') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'support_tickets') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'refunds') }}
    union all
    select max(_airbyte_generation_id) as snapshot_id from {{ source('legacy', 'ticket_events') }}

)

select coalesce(
    {{ legacy_snapshot_id() }},
    (select max(snapshot_id) from geracoes)
)::bigint                                       as snapshot_id
