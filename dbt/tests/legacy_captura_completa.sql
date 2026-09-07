-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Toda tabela declarada tem linha na captura selecionada.
--
-- É o que separa **tabela legitimamente vazia** de **captura ausente ou
-- incompleta**, que do bruto sozinho são indistinguíveis: as duas aparecem
-- como zero linhas. A separação é declarada, não inferida — as 40 tabelas do
-- legado têm dado, e a exceção, se um dia existir, tem nome em
-- `VAZIAS_LEGITIMAS`.
--
-- Uma linha no resultado é uma tabela que não veio na captura que está sendo
-- lida.

with selecionada as (

    select snapshot_id from {{ ref('legacy_selected_capture') }}

)

select
    'brands'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'brands') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'campaigns'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'campaigns') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'carriers'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'carriers') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'customer_segments'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'customer_segments') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'payment_methods'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'payment_methods') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'product_categories'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'product_categories') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'sales_channels'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'sales_channels') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'suppliers'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'suppliers') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'support_agents'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'support_agents') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'warehouses'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'warehouses') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'coupons'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'coupons') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'customers'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'customers') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'price_lists'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'price_lists') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'products'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'products') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'purchase_orders'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'purchase_orders') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'carts'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'carts') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'customer_addresses'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'customer_addresses') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'customer_contacts'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'customer_contacts') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'customer_preferences'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'customer_preferences') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'goods_receipts'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'goods_receipts') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'product_variants'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'product_variants') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'cart_items'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'cart_items') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'inventory_balances'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'inventory_balances') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'inventory_movements'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'inventory_movements') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'orders'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'orders') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'product_prices'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'product_prices') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'purchase_order_items'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'purchase_order_items') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'coupon_redemptions'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'coupon_redemptions') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'goods_receipt_items'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'goods_receipt_items') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'order_items'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'order_items') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'order_status_history'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'order_status_history') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'payments'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'payments') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'shipments'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'shipments') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'stock_reservations'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'stock_reservations') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'delivery_events'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'delivery_events') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'payment_transactions'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'payment_transactions') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'shipment_items'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'shipment_items') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'support_tickets'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'support_tickets') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'refunds'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'refunds') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)

union all

select
    'ticket_events'                                  as tabela,
    (select snapshot_id from selecionada)       as snapshot_id
where not exists (
    select 1 from {{ source('legacy', 'ticket_events') }}
    where _airbyte_generation_id = (select snapshot_id from selecionada)
)
