-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- O que cada modelo empilhou é o que a ponte lhe entregou.
--
-- Segunda metade de `empilhados = aceitos + corrigidos` (Origem Legada §6).
-- Divergir aqui não é arredondamento: é junção interna derrubando registro do
-- legado em silêncio — o pai que ficou para trás, a chave que não casou —, que
-- é o descarte mudo que a regra 4 proíbe.
--
-- Só as tabelas **condutoras** aparecem: as de enriquecimento entram noutro
-- grão e não têm linha própria para contar. A divisão está em
-- `src/mvp_ed1/legacy/ponte.py`.
--
-- Uma linha no resultado é um modelo em que as duas contagens divergiram.

select
    'campaigns'                          as modelo,
    'campaigns'                                  as tabela,
    (select count(*) from {{ ref('legado__campaigns') }}) as aptos,
    (select count(*) from {{ ref('campaigns') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__campaigns') }})
   <> (select count(*) from {{ ref('campaigns') }}
        where source_system = 'legacy')

union all

select
    'carriers'                          as modelo,
    'carriers'                                  as tabela,
    (select count(*) from {{ ref('legado__carriers') }}) as aptos,
    (select count(*) from {{ ref('carriers') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__carriers') }})
   <> (select count(*) from {{ ref('carriers') }}
        where source_system = 'legacy')

union all

select
    'carts'                          as modelo,
    'carts'                                  as tabela,
    (select count(*) from {{ ref('legado__carts') }}) as aptos,
    (select count(*) from {{ ref('carts') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__carts') }})
   <> (select count(*) from {{ ref('carts') }}
        where source_system = 'legacy')

union all

select
    'coupon_redemptions'                          as modelo,
    'coupon_redemptions'                                  as tabela,
    (select count(*) from {{ ref('legado__coupon_redemptions') }}) as aptos,
    (select count(*) from {{ ref('coupon_redemptions') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__coupon_redemptions') }})
   <> (select count(*) from {{ ref('coupon_redemptions') }}
        where source_system = 'legacy')

union all

select
    'coupons'                          as modelo,
    'coupons'                                  as tabela,
    (select count(*) from {{ ref('legado__coupons') }}) as aptos,
    (select count(*) from {{ ref('coupons') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__coupons') }})
   <> (select count(*) from {{ ref('coupons') }}
        where source_system = 'legacy')

union all

select
    'customers'                          as modelo,
    'customers'                                  as tabela,
    (select count(*) from {{ ref('legado__customers') }}) as aptos,
    (select count(*) from {{ ref('customers') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__customers') }})
   <> (select count(*) from {{ ref('customers') }}
        where source_system = 'legacy')

union all

select
    'delivery_events'                          as modelo,
    'delivery_events'                                  as tabela,
    (select count(*) from {{ ref('legado__delivery_events') }}) as aptos,
    (select count(*) from {{ ref('delivery_events') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__delivery_events') }})
   <> (select count(*) from {{ ref('delivery_events') }}
        where source_system = 'legacy')

union all

select
    'inventory_balances'                          as modelo,
    'inventory_balances'                                  as tabela,
    (select count(*) from {{ ref('legado__inventory_balances') }}) as aptos,
    (select count(*) from {{ ref('inventory_balances') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__inventory_balances') }})
   <> (select count(*) from {{ ref('inventory_balances') }}
        where source_system = 'legacy')

union all

select
    'inventory_movements'                          as modelo,
    'inventory_movements'                                  as tabela,
    (select count(*) from {{ ref('legado__inventory_movements') }}) as aptos,
    (select count(*) from {{ ref('inventory_movements') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__inventory_movements') }})
   <> (select count(*) from {{ ref('inventory_movements') }}
        where source_system = 'legacy')

union all

select
    'order_items'                          as modelo,
    'order_items'                                  as tabela,
    (select count(*) from {{ ref('legado__order_items') }}) as aptos,
    (select count(*) from {{ ref('order_items') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__order_items') }})
   <> (select count(*) from {{ ref('order_items') }}
        where source_system = 'legacy')

union all

select
    'order_status_events'                          as modelo,
    'order_status_history'                                  as tabela,
    (select count(*) from {{ ref('legado__order_status_history') }}) as aptos,
    (select count(*) from {{ ref('order_status_events') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__order_status_history') }})
   <> (select count(*) from {{ ref('order_status_events') }}
        where source_system = 'legacy')

union all

select
    'orders'                          as modelo,
    'orders'                                  as tabela,
    (select count(*) from {{ ref('legado__orders') }}) as aptos,
    (select count(*) from {{ ref('orders') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__orders') }})
   <> (select count(*) from {{ ref('orders') }}
        where source_system = 'legacy')

union all

select
    'payment_methods'                          as modelo,
    'payment_methods'                                  as tabela,
    (select count(*) from {{ ref('legado__payment_methods') }}) as aptos,
    (select count(*) from {{ ref('payment_methods') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__payment_methods') }})
   <> (select count(*) from {{ ref('payment_methods') }}
        where source_system = 'legacy')

union all

select
    'payment_transactions'                          as modelo,
    'payment_transactions'                                  as tabela,
    (select count(*) from {{ ref('legado__payment_transactions') }}) as aptos,
    (select count(*) from {{ ref('payment_transactions') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__payment_transactions') }})
   <> (select count(*) from {{ ref('payment_transactions') }}
        where source_system = 'legacy')

union all

select
    'payments'                          as modelo,
    'payments'                                  as tabela,
    (select count(*) from {{ ref('legado__payments') }}) as aptos,
    (select count(*) from {{ ref('payments') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__payments') }})
   <> (select count(*) from {{ ref('payments') }}
        where source_system = 'legacy')

union all

select
    'product_skus'                          as modelo,
    'product_variants'                                  as tabela,
    (select count(*) from {{ ref('legado__product_variants') }}) as aptos,
    (select count(*) from {{ ref('product_skus') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__product_variants') }})
   <> (select count(*) from {{ ref('product_skus') }}
        where source_system = 'legacy')

union all

select
    'purchase_order_items'                          as modelo,
    'purchase_order_items'                                  as tabela,
    (select count(*) from {{ ref('legado__purchase_order_items') }}) as aptos,
    (select count(*) from {{ ref('purchase_order_items') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__purchase_order_items') }})
   <> (select count(*) from {{ ref('purchase_order_items') }}
        where source_system = 'legacy')

union all

select
    'purchase_orders'                          as modelo,
    'purchase_orders'                                  as tabela,
    (select count(*) from {{ ref('legado__purchase_orders') }}) as aptos,
    (select count(*) from {{ ref('purchase_orders') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__purchase_orders') }})
   <> (select count(*) from {{ ref('purchase_orders') }}
        where source_system = 'legacy')

union all

select
    'refunds'                          as modelo,
    'refunds'                                  as tabela,
    (select count(*) from {{ ref('legado__refunds') }}) as aptos,
    (select count(*) from {{ ref('refunds') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__refunds') }})
   <> (select count(*) from {{ ref('refunds') }}
        where source_system = 'legacy')

union all

select
    'sales_channels'                          as modelo,
    'sales_channels'                                  as tabela,
    (select count(*) from {{ ref('legado__sales_channels') }}) as aptos,
    (select count(*) from {{ ref('sales_channels') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__sales_channels') }})
   <> (select count(*) from {{ ref('sales_channels') }}
        where source_system = 'legacy')

union all

select
    'shipment_items'                          as modelo,
    'shipment_items'                                  as tabela,
    (select count(*) from {{ ref('legado__shipment_items') }}) as aptos,
    (select count(*) from {{ ref('shipment_items') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__shipment_items') }})
   <> (select count(*) from {{ ref('shipment_items') }}
        where source_system = 'legacy')

union all

select
    'shipments'                          as modelo,
    'shipments'                                  as tabela,
    (select count(*) from {{ ref('legado__shipments') }}) as aptos,
    (select count(*) from {{ ref('shipments') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__shipments') }})
   <> (select count(*) from {{ ref('shipments') }}
        where source_system = 'legacy')

union all

select
    'suppliers'                          as modelo,
    'suppliers'                                  as tabela,
    (select count(*) from {{ ref('legado__suppliers') }}) as aptos,
    (select count(*) from {{ ref('suppliers') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__suppliers') }})
   <> (select count(*) from {{ ref('suppliers') }}
        where source_system = 'legacy')

union all

select
    'support_agents'                          as modelo,
    'support_agents'                                  as tabela,
    (select count(*) from {{ ref('legado__support_agents') }}) as aptos,
    (select count(*) from {{ ref('support_agents') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__support_agents') }})
   <> (select count(*) from {{ ref('support_agents') }}
        where source_system = 'legacy')

union all

select
    'support_tickets'                          as modelo,
    'support_tickets'                                  as tabela,
    (select count(*) from {{ ref('legado__support_tickets') }}) as aptos,
    (select count(*) from {{ ref('support_tickets') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__support_tickets') }})
   <> (select count(*) from {{ ref('support_tickets') }}
        where source_system = 'legacy')

union all

select
    'ticket_events'                          as modelo,
    'ticket_events'                                  as tabela,
    (select count(*) from {{ ref('legado__ticket_events') }}) as aptos,
    (select count(*) from {{ ref('ticket_events') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__ticket_events') }})
   <> (select count(*) from {{ ref('ticket_events') }}
        where source_system = 'legacy')

union all

select
    'warehouses'                          as modelo,
    'warehouses'                                  as tabela,
    (select count(*) from {{ ref('legado__warehouses') }}) as aptos,
    (select count(*) from {{ ref('warehouses') }}
        where source_system = 'legacy')         as empilhados
where (select count(*) from {{ ref('legado__warehouses') }})
   <> (select count(*) from {{ ref('warehouses') }}
        where source_system = 'legacy')
