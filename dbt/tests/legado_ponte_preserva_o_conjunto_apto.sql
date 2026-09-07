-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A ponte entrega o conjunto apto inteiro, tabela por tabela.
--
-- É a primeira metade de `empilhados = aceitos + corrigidos` (Origem Legada
-- §6): entre o julgamento e a entrada em `trusted` não se perde nem se ganha
-- registro. A segunda metade — que o modelo `trusted` empilhou o que a ponte
-- entregou — está em `legado_empilhado_reconcilia`.
--
-- Uma linha no resultado é uma tabela em que as duas contagens divergiram.

select
    'brands'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'brands')        as aptos,
    (select count(*) from {{ ref('legado__brands') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'brands')
   <> (select count(*) from {{ ref('legado__brands') }})

union all

select
    'campaigns'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'campaigns')        as aptos,
    (select count(*) from {{ ref('legado__campaigns') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'campaigns')
   <> (select count(*) from {{ ref('legado__campaigns') }})

union all

select
    'carriers'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'carriers')        as aptos,
    (select count(*) from {{ ref('legado__carriers') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'carriers')
   <> (select count(*) from {{ ref('legado__carriers') }})

union all

select
    'customer_segments'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'customer_segments')        as aptos,
    (select count(*) from {{ ref('legado__customer_segments') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'customer_segments')
   <> (select count(*) from {{ ref('legado__customer_segments') }})

union all

select
    'payment_methods'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'payment_methods')        as aptos,
    (select count(*) from {{ ref('legado__payment_methods') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'payment_methods')
   <> (select count(*) from {{ ref('legado__payment_methods') }})

union all

select
    'product_categories'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'product_categories')        as aptos,
    (select count(*) from {{ ref('legado__product_categories') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'product_categories')
   <> (select count(*) from {{ ref('legado__product_categories') }})

union all

select
    'sales_channels'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'sales_channels')        as aptos,
    (select count(*) from {{ ref('legado__sales_channels') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'sales_channels')
   <> (select count(*) from {{ ref('legado__sales_channels') }})

union all

select
    'suppliers'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'suppliers')        as aptos,
    (select count(*) from {{ ref('legado__suppliers') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'suppliers')
   <> (select count(*) from {{ ref('legado__suppliers') }})

union all

select
    'support_agents'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'support_agents')        as aptos,
    (select count(*) from {{ ref('legado__support_agents') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'support_agents')
   <> (select count(*) from {{ ref('legado__support_agents') }})

union all

select
    'warehouses'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'warehouses')        as aptos,
    (select count(*) from {{ ref('legado__warehouses') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'warehouses')
   <> (select count(*) from {{ ref('legado__warehouses') }})

union all

select
    'coupons'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'coupons')        as aptos,
    (select count(*) from {{ ref('legado__coupons') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'coupons')
   <> (select count(*) from {{ ref('legado__coupons') }})

union all

select
    'customers'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'customers')        as aptos,
    (select count(*) from {{ ref('legado__customers') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'customers')
   <> (select count(*) from {{ ref('legado__customers') }})

union all

select
    'products'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'products')        as aptos,
    (select count(*) from {{ ref('legado__products') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'products')
   <> (select count(*) from {{ ref('legado__products') }})

union all

select
    'purchase_orders'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'purchase_orders')        as aptos,
    (select count(*) from {{ ref('legado__purchase_orders') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'purchase_orders')
   <> (select count(*) from {{ ref('legado__purchase_orders') }})

union all

select
    'carts'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'carts')        as aptos,
    (select count(*) from {{ ref('legado__carts') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'carts')
   <> (select count(*) from {{ ref('legado__carts') }})

union all

select
    'customer_addresses'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'customer_addresses')        as aptos,
    (select count(*) from {{ ref('legado__customer_addresses') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'customer_addresses')
   <> (select count(*) from {{ ref('legado__customer_addresses') }})

union all

select
    'goods_receipts'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'goods_receipts')        as aptos,
    (select count(*) from {{ ref('legado__goods_receipts') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'goods_receipts')
   <> (select count(*) from {{ ref('legado__goods_receipts') }})

union all

select
    'product_variants'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'product_variants')        as aptos,
    (select count(*) from {{ ref('legado__product_variants') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'product_variants')
   <> (select count(*) from {{ ref('legado__product_variants') }})

union all

select
    'cart_items'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'cart_items')        as aptos,
    (select count(*) from {{ ref('legado__cart_items') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'cart_items')
   <> (select count(*) from {{ ref('legado__cart_items') }})

union all

select
    'inventory_balances'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'inventory_balances')        as aptos,
    (select count(*) from {{ ref('legado__inventory_balances') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'inventory_balances')
   <> (select count(*) from {{ ref('legado__inventory_balances') }})

union all

select
    'inventory_movements'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'inventory_movements')        as aptos,
    (select count(*) from {{ ref('legado__inventory_movements') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'inventory_movements')
   <> (select count(*) from {{ ref('legado__inventory_movements') }})

union all

select
    'orders'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'orders')        as aptos,
    (select count(*) from {{ ref('legado__orders') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'orders')
   <> (select count(*) from {{ ref('legado__orders') }})

union all

select
    'purchase_order_items'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'purchase_order_items')        as aptos,
    (select count(*) from {{ ref('legado__purchase_order_items') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'purchase_order_items')
   <> (select count(*) from {{ ref('legado__purchase_order_items') }})

union all

select
    'coupon_redemptions'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'coupon_redemptions')        as aptos,
    (select count(*) from {{ ref('legado__coupon_redemptions') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'coupon_redemptions')
   <> (select count(*) from {{ ref('legado__coupon_redemptions') }})

union all

select
    'goods_receipt_items'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'goods_receipt_items')        as aptos,
    (select count(*) from {{ ref('legado__goods_receipt_items') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'goods_receipt_items')
   <> (select count(*) from {{ ref('legado__goods_receipt_items') }})

union all

select
    'order_items'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'order_items')        as aptos,
    (select count(*) from {{ ref('legado__order_items') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'order_items')
   <> (select count(*) from {{ ref('legado__order_items') }})

union all

select
    'order_status_history'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'order_status_history')        as aptos,
    (select count(*) from {{ ref('legado__order_status_history') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'order_status_history')
   <> (select count(*) from {{ ref('legado__order_status_history') }})

union all

select
    'payments'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'payments')        as aptos,
    (select count(*) from {{ ref('legado__payments') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'payments')
   <> (select count(*) from {{ ref('legado__payments') }})

union all

select
    'shipments'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'shipments')        as aptos,
    (select count(*) from {{ ref('legado__shipments') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'shipments')
   <> (select count(*) from {{ ref('legado__shipments') }})

union all

select
    'stock_reservations'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'stock_reservations')        as aptos,
    (select count(*) from {{ ref('legado__stock_reservations') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'stock_reservations')
   <> (select count(*) from {{ ref('legado__stock_reservations') }})

union all

select
    'delivery_events'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'delivery_events')        as aptos,
    (select count(*) from {{ ref('legado__delivery_events') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'delivery_events')
   <> (select count(*) from {{ ref('legado__delivery_events') }})

union all

select
    'payment_transactions'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'payment_transactions')        as aptos,
    (select count(*) from {{ ref('legado__payment_transactions') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'payment_transactions')
   <> (select count(*) from {{ ref('legado__payment_transactions') }})

union all

select
    'shipment_items'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'shipment_items')        as aptos,
    (select count(*) from {{ ref('legado__shipment_items') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'shipment_items')
   <> (select count(*) from {{ ref('legado__shipment_items') }})

union all

select
    'support_tickets'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'support_tickets')        as aptos,
    (select count(*) from {{ ref('legado__support_tickets') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'support_tickets')
   <> (select count(*) from {{ ref('legado__support_tickets') }})

union all

select
    'refunds'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'refunds')        as aptos,
    (select count(*) from {{ ref('legado__refunds') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'refunds')
   <> (select count(*) from {{ ref('legado__refunds') }})

union all

select
    'ticket_events'                                  as tabela,
    (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'ticket_events')        as aptos,
    (select count(*) from {{ ref('legado__ticket_events') }}) as na_ponte
where (select count(*) from {{ ref('legacy_eligible_records') }}
        where source_table = 'ticket_events')
   <> (select count(*) from {{ ref('legado__ticket_events') }})
