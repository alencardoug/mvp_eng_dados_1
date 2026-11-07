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

{% if target.type == 'bigquery' %}
SELECT
  'campaigns' AS modelo,
  'campaigns' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__campaigns') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('campaigns') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__campaigns') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('campaigns') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'carriers' AS modelo,
  'carriers' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__carriers') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('carriers') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__carriers') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('carriers') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'carts' AS modelo,
  'carts' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__carts') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('carts') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__carts') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('carts') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'coupon_redemptions' AS modelo,
  'coupon_redemptions' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__coupon_redemptions') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('coupon_redemptions') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__coupon_redemptions') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('coupon_redemptions') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'coupons' AS modelo,
  'coupons' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__coupons') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('coupons') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__coupons') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('coupons') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'customers' AS modelo,
  'customers' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__customers') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('customers') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__customers') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('customers') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'delivery_events' AS modelo,
  'delivery_events' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__delivery_events') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('delivery_events') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__delivery_events') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('delivery_events') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'inventory_balances' AS modelo,
  'inventory_balances' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__inventory_balances') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_balances') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__inventory_balances') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_balances') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'inventory_movements' AS modelo,
  'inventory_movements' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__inventory_movements') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_movements') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__inventory_movements') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_movements') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'order_items' AS modelo,
  'order_items' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__order_items') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('order_items') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__order_items') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('order_items') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'order_status_events' AS modelo,
  'order_status_history' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__order_status_history') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('order_status_events') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__order_status_history') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('order_status_events') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'orders' AS modelo,
  'orders' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__orders') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('orders') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__orders') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('orders') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'payment_methods' AS modelo,
  'payment_methods' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__payment_methods') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_methods') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__payment_methods') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_methods') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'payment_transactions' AS modelo,
  'payment_transactions' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__payment_transactions') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_transactions') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__payment_transactions') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_transactions') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'payments' AS modelo,
  'payments' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__payments') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('payments') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__payments') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('payments') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'product_skus' AS modelo,
  'product_variants' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__product_variants') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('product_skus') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__product_variants') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('product_skus') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'purchase_order_items' AS modelo,
  'purchase_order_items' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__purchase_order_items') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_order_items') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__purchase_order_items') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_order_items') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'purchase_orders' AS modelo,
  'purchase_orders' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__purchase_orders') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_orders') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__purchase_orders') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_orders') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'refunds' AS modelo,
  'refunds' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__refunds') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('refunds') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__refunds') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('refunds') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'sales_channels' AS modelo,
  'sales_channels' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__sales_channels') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('sales_channels') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__sales_channels') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('sales_channels') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'shipment_items' AS modelo,
  'shipment_items' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__shipment_items') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('shipment_items') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__shipment_items') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('shipment_items') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'shipments' AS modelo,
  'shipments' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__shipments') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('shipments') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__shipments') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('shipments') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'suppliers' AS modelo,
  'suppliers' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__suppliers') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('suppliers') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__suppliers') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('suppliers') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'support_agents' AS modelo,
  'support_agents' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__support_agents') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('support_agents') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__support_agents') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('support_agents') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'support_tickets' AS modelo,
  'support_tickets' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__support_tickets') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('support_tickets') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__support_tickets') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('support_tickets') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'ticket_events' AS modelo,
  'ticket_events' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__ticket_events') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('ticket_events') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__ticket_events') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('ticket_events') }}
    WHERE
      source_system = 'legacy'
  )
UNION ALL
SELECT
  'warehouses' AS modelo,
  'warehouses' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__warehouses') }}
  ) AS aptos,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('warehouses') }}
    WHERE
      source_system = 'legacy'
  ) AS empilhados
FROM (
  SELECT
    1
) AS sem_from
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('legado__warehouses') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('warehouses') }}
    WHERE
      source_system = 'legacy'
  )
{% else %}select
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
        where source_system = 'legacy'){% endif %}
