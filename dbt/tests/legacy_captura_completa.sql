-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A captura selecionada é **certificada** em todas as tabelas declaradas.
--
-- Até 14/09/2026 este teste perguntava se cada tabela tinha ao menos uma linha
-- na captura — e isso aceitava a geração 15: 39 tabelas, job `succeeded`,
-- total exato. Agora ele lê o certificado do ADR-0044, escrito em duas fases
-- em volta da sincronização: origem antes e depois do job (contagem e hash de
-- conteúdo), bruto recebido com o `sync_id` do job. Tabela com zero na origem
-- e zero no bruto é completa — "legitimamente vazia" é medida, não lista.
--
-- Cada linha do resultado é uma tabela em que a captura selecionada não tem
-- certificado `complete`, ou em que o bruto de hoje não tem mais as linhas que
-- o certificado disse ter recebido.

{% if target.type == 'bigquery' %}
WITH selecionada AS (
  SELECT
    snapshot_id
  FROM {{ ref('legacy_selected_capture') }}
), declaradas AS (
  SELECT
    *
  FROM UNNEST([
    STRUCT('brands' AS _c0),
    STRUCT('campaigns' AS _c0),
    STRUCT('carriers' AS _c0),
    STRUCT('customer_segments' AS _c0),
    STRUCT('payment_methods' AS _c0),
    STRUCT('product_categories' AS _c0),
    STRUCT('sales_channels' AS _c0),
    STRUCT('suppliers' AS _c0),
    STRUCT('support_agents' AS _c0),
    STRUCT('warehouses' AS _c0),
    STRUCT('coupons' AS _c0),
    STRUCT('customers' AS _c0),
    STRUCT('price_lists' AS _c0),
    STRUCT('products' AS _c0),
    STRUCT('purchase_orders' AS _c0),
    STRUCT('carts' AS _c0),
    STRUCT('customer_addresses' AS _c0),
    STRUCT('customer_contacts' AS _c0),
    STRUCT('customer_preferences' AS _c0),
    STRUCT('goods_receipts' AS _c0),
    STRUCT('product_variants' AS _c0),
    STRUCT('cart_items' AS _c0),
    STRUCT('inventory_balances' AS _c0),
    STRUCT('inventory_movements' AS _c0),
    STRUCT('orders' AS _c0),
    STRUCT('product_prices' AS _c0),
    STRUCT('purchase_order_items' AS _c0),
    STRUCT('coupon_redemptions' AS _c0),
    STRUCT('goods_receipt_items' AS _c0),
    STRUCT('order_items' AS _c0),
    STRUCT('order_status_history' AS _c0),
    STRUCT('payments' AS _c0),
    STRUCT('shipments' AS _c0),
    STRUCT('stock_reservations' AS _c0),
    STRUCT('delivery_events' AS _c0),
    STRUCT('payment_transactions' AS _c0),
    STRUCT('shipment_items' AS _c0),
    STRUCT('support_tickets' AS _c0),
    STRUCT('refunds' AS _c0),
    STRUCT('ticket_events' AS _c0)
  ]) AS _values
), certificado AS (
  SELECT
    source_table AS tabela,
    status,
    received_rows
  FROM {{ source('governance', 'legacy_captures') }}
  WHERE
    snapshot_id = (
      SELECT
        snapshot_id
      FROM selecionada
    )
), no_bruto AS (
  SELECT
    'brands' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'brands') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'campaigns' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'campaigns') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'carriers' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'carriers') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'customer_segments' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_segments') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'payment_methods' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'payment_methods') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'product_categories' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'product_categories') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'sales_channels' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'sales_channels') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'suppliers' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'suppliers') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'support_agents' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'support_agents') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'warehouses' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'warehouses') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'coupons' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'coupons') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'customers' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customers') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'price_lists' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'price_lists') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'products' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'products') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'purchase_orders' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'purchase_orders') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'carts' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'carts') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'customer_addresses' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_addresses') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'customer_contacts' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_contacts') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'customer_preferences' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'customer_preferences') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'goods_receipts' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'goods_receipts') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'product_variants' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'product_variants') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'cart_items' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'cart_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'inventory_balances' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'inventory_balances') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'inventory_movements' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'inventory_movements') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'orders' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'orders') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'product_prices' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'product_prices') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'purchase_order_items' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'purchase_order_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'coupon_redemptions' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'coupon_redemptions') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'goods_receipt_items' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'goods_receipt_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'order_items' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'order_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'order_status_history' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'order_status_history') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'payments' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'payments') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'shipments' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'shipments') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'stock_reservations' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'stock_reservations') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'delivery_events' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'delivery_events') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'payment_transactions' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'payment_transactions') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'shipment_items' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'shipment_items') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'support_tickets' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'support_tickets') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'refunds' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'refunds') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
  UNION ALL
  SELECT
    'ticket_events' AS tabela,
    COUNT(*) AS linhas
  FROM {{ source('legacy', 'ticket_events') }}
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM selecionada
    )
)
SELECT
  d.tabela,
  (
    SELECT
      snapshot_id
    FROM selecionada
  ) AS snapshot_id,
  COALESCE(c.status, 'sem certificado') AS status,
  c.received_rows,
  b.linhas AS linhas_no_bruto
FROM declaradas AS d
LEFT JOIN certificado AS c
  ON c.tabela = d.tabela
LEFT JOIN no_bruto AS b
  ON b.tabela = d.tabela
WHERE
  c.status IS DISTINCT FROM 'complete' OR c.received_rows IS DISTINCT FROM b.linhas
{% else %}with selecionada as (

    select snapshot_id from {{ ref('legacy_selected_capture') }}

),

declaradas (tabela) as (

    values ('brands'), ('campaigns'), ('carriers'), ('customer_segments'), ('payment_methods'), ('product_categories'), ('sales_channels'), ('suppliers'), ('support_agents'), ('warehouses'), ('coupons'), ('customers'), ('price_lists'), ('products'), ('purchase_orders'), ('carts'), ('customer_addresses'), ('customer_contacts'), ('customer_preferences'), ('goods_receipts'), ('product_variants'), ('cart_items'), ('inventory_balances'), ('inventory_movements'), ('orders'), ('product_prices'), ('purchase_order_items'), ('coupon_redemptions'), ('goods_receipt_items'), ('order_items'), ('order_status_history'), ('payments'), ('shipments'), ('stock_reservations'), ('delivery_events'), ('payment_transactions'), ('shipment_items'), ('support_tickets'), ('refunds'), ('ticket_events')

),

certificado as (

    select source_table as tabela, status, received_rows
    from {{ source('governance', 'legacy_captures') }}
    where snapshot_id = (select snapshot_id from selecionada)

),

no_bruto as (

    select 'brands' as tabela, count(*) as linhas from {{ source('legacy', 'brands') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'campaigns' as tabela, count(*) as linhas from {{ source('legacy', 'campaigns') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'carriers' as tabela, count(*) as linhas from {{ source('legacy', 'carriers') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'customer_segments' as tabela, count(*) as linhas from {{ source('legacy', 'customer_segments') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'payment_methods' as tabela, count(*) as linhas from {{ source('legacy', 'payment_methods') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'product_categories' as tabela, count(*) as linhas from {{ source('legacy', 'product_categories') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'sales_channels' as tabela, count(*) as linhas from {{ source('legacy', 'sales_channels') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'suppliers' as tabela, count(*) as linhas from {{ source('legacy', 'suppliers') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'support_agents' as tabela, count(*) as linhas from {{ source('legacy', 'support_agents') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'warehouses' as tabela, count(*) as linhas from {{ source('legacy', 'warehouses') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'coupons' as tabela, count(*) as linhas from {{ source('legacy', 'coupons') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'customers' as tabela, count(*) as linhas from {{ source('legacy', 'customers') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'price_lists' as tabela, count(*) as linhas from {{ source('legacy', 'price_lists') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'products' as tabela, count(*) as linhas from {{ source('legacy', 'products') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'purchase_orders' as tabela, count(*) as linhas from {{ source('legacy', 'purchase_orders') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'carts' as tabela, count(*) as linhas from {{ source('legacy', 'carts') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'customer_addresses' as tabela, count(*) as linhas from {{ source('legacy', 'customer_addresses') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'customer_contacts' as tabela, count(*) as linhas from {{ source('legacy', 'customer_contacts') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'customer_preferences' as tabela, count(*) as linhas from {{ source('legacy', 'customer_preferences') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'goods_receipts' as tabela, count(*) as linhas from {{ source('legacy', 'goods_receipts') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'product_variants' as tabela, count(*) as linhas from {{ source('legacy', 'product_variants') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'cart_items' as tabela, count(*) as linhas from {{ source('legacy', 'cart_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'inventory_balances' as tabela, count(*) as linhas from {{ source('legacy', 'inventory_balances') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'inventory_movements' as tabela, count(*) as linhas from {{ source('legacy', 'inventory_movements') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'orders' as tabela, count(*) as linhas from {{ source('legacy', 'orders') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'product_prices' as tabela, count(*) as linhas from {{ source('legacy', 'product_prices') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'purchase_order_items' as tabela, count(*) as linhas from {{ source('legacy', 'purchase_order_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'coupon_redemptions' as tabela, count(*) as linhas from {{ source('legacy', 'coupon_redemptions') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'goods_receipt_items' as tabela, count(*) as linhas from {{ source('legacy', 'goods_receipt_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'order_items' as tabela, count(*) as linhas from {{ source('legacy', 'order_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'order_status_history' as tabela, count(*) as linhas from {{ source('legacy', 'order_status_history') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'payments' as tabela, count(*) as linhas from {{ source('legacy', 'payments') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'shipments' as tabela, count(*) as linhas from {{ source('legacy', 'shipments') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'stock_reservations' as tabela, count(*) as linhas from {{ source('legacy', 'stock_reservations') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'delivery_events' as tabela, count(*) as linhas from {{ source('legacy', 'delivery_events') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'payment_transactions' as tabela, count(*) as linhas from {{ source('legacy', 'payment_transactions') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'shipment_items' as tabela, count(*) as linhas from {{ source('legacy', 'shipment_items') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'support_tickets' as tabela, count(*) as linhas from {{ source('legacy', 'support_tickets') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'refunds' as tabela, count(*) as linhas from {{ source('legacy', 'refunds') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)
    union all
    select 'ticket_events' as tabela, count(*) as linhas from {{ source('legacy', 'ticket_events') }} where (_airbyte_meta->>'sync_id')::bigint = (select snapshot_id from selecionada)

)

select
    d.tabela,
    (select snapshot_id from selecionada)       as snapshot_id,
    coalesce(c.status, 'sem certificado')       as status,
    c.received_rows,
    b.linhas                                    as linhas_no_bruto
from declaradas d
left join certificado c on c.tabela = d.tabela
left join no_bruto b on b.tabela = d.tabela
where c.status is distinct from 'complete'
   or c.received_rows is distinct from b.linhas{% endif %}
