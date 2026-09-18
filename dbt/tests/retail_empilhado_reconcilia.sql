-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- O que cada modelo empilhou da origem principal é o que o `staging` lhe deu.
--
-- A fronteira `staging → trusted` da Qualidade §7, no ramo `retail` — o irmão
-- de `legado_empilhado_reconcilia`, que cobre o ramo legado. O `staging` já
-- deduplicou a entrega ao menos uma vez do Airbyte; daqui até `trusted` não se
-- perde nem se ganha registro: junção interna que derruba linha, ou `where`
-- que a filtra sem mandá-la para `quarantine`, é o descarte mudo que a regra
-- 4 proíbe. A mesma lista de condutoras dos dois lados: o que o legado
-- empilha é o que a origem principal empilha.
--
-- Uma linha no resultado é um modelo em que as duas contagens divergiram.

select
    'campaigns'                          as modelo,
    'campaigns'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__campaigns') }}) as em_staging,
    (select count(*) from {{ ref('campaigns') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__campaigns') }})
   <> (select count(*) from {{ ref('campaigns') }}
        where source_system = 'retail')

union all

select
    'carriers'                          as modelo,
    'carriers'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__carriers') }}) as em_staging,
    (select count(*) from {{ ref('carriers') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__carriers') }})
   <> (select count(*) from {{ ref('carriers') }}
        where source_system = 'retail')

union all

select
    'carts'                          as modelo,
    'carts'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__carts') }}) as em_staging,
    (select count(*) from {{ ref('carts') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__carts') }})
   <> (select count(*) from {{ ref('carts') }}
        where source_system = 'retail')

union all

select
    'coupon_redemptions'                          as modelo,
    'coupon_redemptions'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__coupon_redemptions') }}) as em_staging,
    (select count(*) from {{ ref('coupon_redemptions') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__coupon_redemptions') }})
   <> (select count(*) from {{ ref('coupon_redemptions') }}
        where source_system = 'retail')

union all

select
    'coupons'                          as modelo,
    'coupons'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__coupons') }}) as em_staging,
    (select count(*) from {{ ref('coupons') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__coupons') }})
   <> (select count(*) from {{ ref('coupons') }}
        where source_system = 'retail')

union all

select
    'customers'                          as modelo,
    'customers'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__customers') }}) as em_staging,
    (select count(*) from {{ ref('customers') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__customers') }})
   <> (select count(*) from {{ ref('customers') }}
        where source_system = 'retail')

union all

select
    'delivery_events'                          as modelo,
    'delivery_events'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__delivery_events') }}) as em_staging,
    (select count(*) from {{ ref('delivery_events') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__delivery_events') }})
   <> (select count(*) from {{ ref('delivery_events') }}
        where source_system = 'retail')

union all

select
    'inventory_balances'                          as modelo,
    'inventory_balances'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__inventory_balances') }}) as em_staging,
    (select count(*) from {{ ref('inventory_balances') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__inventory_balances') }})
   <> (select count(*) from {{ ref('inventory_balances') }}
        where source_system = 'retail')

union all

select
    'inventory_movements'                          as modelo,
    'inventory_movements'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__inventory_movements') }}) as em_staging,
    (select count(*) from {{ ref('inventory_movements') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__inventory_movements') }})
   <> (select count(*) from {{ ref('inventory_movements') }}
        where source_system = 'retail')

union all

select
    'order_items'                          as modelo,
    'order_items'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__order_items') }}) as em_staging,
    (select count(*) from {{ ref('order_items') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__order_items') }})
   <> (select count(*) from {{ ref('order_items') }}
        where source_system = 'retail')

union all

select
    'order_status_events'                          as modelo,
    'order_status_history'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__order_status_history') }}) as em_staging,
    (select count(*) from {{ ref('order_status_events') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__order_status_history') }})
   <> (select count(*) from {{ ref('order_status_events') }}
        where source_system = 'retail')

union all

select
    'orders'                          as modelo,
    'orders'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__orders') }}) as em_staging,
    (select count(*) from {{ ref('orders') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__orders') }})
   <> (select count(*) from {{ ref('orders') }}
        where source_system = 'retail')

union all

select
    'payment_methods'                          as modelo,
    'payment_methods'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__payment_methods') }}) as em_staging,
    (select count(*) from {{ ref('payment_methods') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__payment_methods') }})
   <> (select count(*) from {{ ref('payment_methods') }}
        where source_system = 'retail')

union all

select
    'payment_transactions'                          as modelo,
    'payment_transactions'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__payment_transactions') }}) as em_staging,
    (select count(*) from {{ ref('payment_transactions') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__payment_transactions') }})
   <> (select count(*) from {{ ref('payment_transactions') }}
        where source_system = 'retail')

union all

select
    'payments'                          as modelo,
    'payments'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__payments') }}) as em_staging,
    (select count(*) from {{ ref('payments') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__payments') }})
   <> (select count(*) from {{ ref('payments') }}
        where source_system = 'retail')

union all

select
    'product_skus'                          as modelo,
    'product_variants'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__product_variants') }}) as em_staging,
    (select count(*) from {{ ref('product_skus') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__product_variants') }})
   <> (select count(*) from {{ ref('product_skus') }}
        where source_system = 'retail')

union all

select
    'purchase_order_items'                          as modelo,
    'purchase_order_items'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__purchase_order_items') }}) as em_staging,
    (select count(*) from {{ ref('purchase_order_items') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__purchase_order_items') }})
   <> (select count(*) from {{ ref('purchase_order_items') }}
        where source_system = 'retail')

union all

select
    'purchase_orders'                          as modelo,
    'purchase_orders'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__purchase_orders') }}) as em_staging,
    (select count(*) from {{ ref('purchase_orders') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__purchase_orders') }})
   <> (select count(*) from {{ ref('purchase_orders') }}
        where source_system = 'retail')

union all

select
    'refunds'                          as modelo,
    'refunds'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__refunds') }}) as em_staging,
    (select count(*) from {{ ref('refunds') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__refunds') }})
   <> (select count(*) from {{ ref('refunds') }}
        where source_system = 'retail')

union all

select
    'sales_channels'                          as modelo,
    'sales_channels'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__sales_channels') }}) as em_staging,
    (select count(*) from {{ ref('sales_channels') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__sales_channels') }})
   <> (select count(*) from {{ ref('sales_channels') }}
        where source_system = 'retail')

union all

select
    'shipment_items'                          as modelo,
    'shipment_items'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__shipment_items') }}) as em_staging,
    (select count(*) from {{ ref('shipment_items') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__shipment_items') }})
   <> (select count(*) from {{ ref('shipment_items') }}
        where source_system = 'retail')

union all

select
    'shipments'                          as modelo,
    'shipments'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__shipments') }}) as em_staging,
    (select count(*) from {{ ref('shipments') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__shipments') }})
   <> (select count(*) from {{ ref('shipments') }}
        where source_system = 'retail')

union all

select
    'suppliers'                          as modelo,
    'suppliers'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__suppliers') }}) as em_staging,
    (select count(*) from {{ ref('suppliers') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__suppliers') }})
   <> (select count(*) from {{ ref('suppliers') }}
        where source_system = 'retail')

union all

select
    'support_agents'                          as modelo,
    'support_agents'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__support_agents') }}) as em_staging,
    (select count(*) from {{ ref('support_agents') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__support_agents') }})
   <> (select count(*) from {{ ref('support_agents') }}
        where source_system = 'retail')

union all

select
    'support_tickets'                          as modelo,
    'support_tickets'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__support_tickets') }}) as em_staging,
    (select count(*) from {{ ref('support_tickets') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__support_tickets') }})
   <> (select count(*) from {{ ref('support_tickets') }}
        where source_system = 'retail')

union all

select
    'ticket_events'                          as modelo,
    'ticket_events'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__ticket_events') }}) as em_staging,
    (select count(*) from {{ ref('ticket_events') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__ticket_events') }})
   <> (select count(*) from {{ ref('ticket_events') }}
        where source_system = 'retail')

union all

select
    'warehouses'                          as modelo,
    'warehouses'                                  as tabela,
    (select count(*) from {{ ref('stg_retail__warehouses') }}) as em_staging,
    (select count(*) from {{ ref('warehouses') }}
        where source_system = 'retail')         as empilhados
where (select count(*) from {{ ref('stg_retail__warehouses') }})
   <> (select count(*) from {{ ref('warehouses') }}
        where source_system = 'retail')
