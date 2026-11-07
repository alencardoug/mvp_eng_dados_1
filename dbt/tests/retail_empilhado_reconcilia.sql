-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

{{ config(tags=['fronteira']) }}

-- Compara `staging` com `trusted`, que a DAG constrói em tarefas diferentes:
-- roda na tarefa `dbt_fronteiras`, depois das duas (airflow/dags/fluxo_batch.py).
--
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

{% if target.type == 'bigquery' %}
SELECT
  'campaigns' AS modelo,
  'campaigns' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__campaigns') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('campaigns') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__campaigns') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('campaigns') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'carriers' AS modelo,
  'carriers' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__carriers') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('carriers') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__carriers') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('carriers') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'carts' AS modelo,
  'carts' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__carts') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('carts') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__carts') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('carts') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'coupon_redemptions' AS modelo,
  'coupon_redemptions' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__coupon_redemptions') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('coupon_redemptions') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__coupon_redemptions') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('coupon_redemptions') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'coupons' AS modelo,
  'coupons' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__coupons') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('coupons') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__coupons') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('coupons') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'customers' AS modelo,
  'customers' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__customers') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('customers') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__customers') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('customers') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'delivery_events' AS modelo,
  'delivery_events' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__delivery_events') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('delivery_events') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__delivery_events') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('delivery_events') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'inventory_balances' AS modelo,
  'inventory_balances' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__inventory_balances') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_balances') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__inventory_balances') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_balances') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'inventory_movements' AS modelo,
  'inventory_movements' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__inventory_movements') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_movements') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__inventory_movements') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('inventory_movements') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'order_items' AS modelo,
  'order_items' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__order_items') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('order_items') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__order_items') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('order_items') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'order_status_events' AS modelo,
  'order_status_history' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__order_status_history') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('order_status_events') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__order_status_history') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('order_status_events') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'orders' AS modelo,
  'orders' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__orders') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('orders') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__orders') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('orders') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'payment_methods' AS modelo,
  'payment_methods' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__payment_methods') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_methods') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__payment_methods') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_methods') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'payment_transactions' AS modelo,
  'payment_transactions' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__payment_transactions') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_transactions') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__payment_transactions') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('payment_transactions') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'payments' AS modelo,
  'payments' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__payments') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('payments') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__payments') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('payments') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'product_skus' AS modelo,
  'product_variants' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__product_variants') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('product_skus') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__product_variants') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('product_skus') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'purchase_order_items' AS modelo,
  'purchase_order_items' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__purchase_order_items') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_order_items') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__purchase_order_items') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_order_items') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'purchase_orders' AS modelo,
  'purchase_orders' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__purchase_orders') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_orders') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__purchase_orders') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('purchase_orders') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'refunds' AS modelo,
  'refunds' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__refunds') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('refunds') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__refunds') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('refunds') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'sales_channels' AS modelo,
  'sales_channels' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__sales_channels') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('sales_channels') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__sales_channels') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('sales_channels') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'shipment_items' AS modelo,
  'shipment_items' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__shipment_items') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('shipment_items') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__shipment_items') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('shipment_items') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'shipments' AS modelo,
  'shipments' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__shipments') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('shipments') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__shipments') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('shipments') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'suppliers' AS modelo,
  'suppliers' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__suppliers') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('suppliers') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__suppliers') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('suppliers') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'support_agents' AS modelo,
  'support_agents' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__support_agents') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('support_agents') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__support_agents') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('support_agents') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'support_tickets' AS modelo,
  'support_tickets' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__support_tickets') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('support_tickets') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__support_tickets') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('support_tickets') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'ticket_events' AS modelo,
  'ticket_events' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__ticket_events') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('ticket_events') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__ticket_events') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('ticket_events') }}
    WHERE
      source_system = 'retail'
  )
UNION ALL
SELECT
  'warehouses' AS modelo,
  'warehouses' AS tabela,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__warehouses') }}
  ) AS em_staging,
  (
    SELECT
      COUNT(*)
    FROM {{ ref('warehouses') }}
    WHERE
      source_system = 'retail'
  ) AS empilhados
WHERE
  (
    SELECT
      COUNT(*)
    FROM {{ ref('stg_retail__warehouses') }}
  ) <> (
    SELECT
      COUNT(*)
    FROM {{ ref('warehouses') }}
    WHERE
      source_system = 'retail'
  )
{% else %}select
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
        where source_system = 'retail'){% endif %}
