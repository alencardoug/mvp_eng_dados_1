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

with selecionada as (

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

    select 'brands' as tabela, count(*) as linhas from {{ source('legacy', 'brands') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'campaigns' as tabela, count(*) as linhas from {{ source('legacy', 'campaigns') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'carriers' as tabela, count(*) as linhas from {{ source('legacy', 'carriers') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'customer_segments' as tabela, count(*) as linhas from {{ source('legacy', 'customer_segments') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'payment_methods' as tabela, count(*) as linhas from {{ source('legacy', 'payment_methods') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'product_categories' as tabela, count(*) as linhas from {{ source('legacy', 'product_categories') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'sales_channels' as tabela, count(*) as linhas from {{ source('legacy', 'sales_channels') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'suppliers' as tabela, count(*) as linhas from {{ source('legacy', 'suppliers') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'support_agents' as tabela, count(*) as linhas from {{ source('legacy', 'support_agents') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'warehouses' as tabela, count(*) as linhas from {{ source('legacy', 'warehouses') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'coupons' as tabela, count(*) as linhas from {{ source('legacy', 'coupons') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'customers' as tabela, count(*) as linhas from {{ source('legacy', 'customers') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'price_lists' as tabela, count(*) as linhas from {{ source('legacy', 'price_lists') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'products' as tabela, count(*) as linhas from {{ source('legacy', 'products') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'purchase_orders' as tabela, count(*) as linhas from {{ source('legacy', 'purchase_orders') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'carts' as tabela, count(*) as linhas from {{ source('legacy', 'carts') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'customer_addresses' as tabela, count(*) as linhas from {{ source('legacy', 'customer_addresses') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'customer_contacts' as tabela, count(*) as linhas from {{ source('legacy', 'customer_contacts') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'customer_preferences' as tabela, count(*) as linhas from {{ source('legacy', 'customer_preferences') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'goods_receipts' as tabela, count(*) as linhas from {{ source('legacy', 'goods_receipts') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'product_variants' as tabela, count(*) as linhas from {{ source('legacy', 'product_variants') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'cart_items' as tabela, count(*) as linhas from {{ source('legacy', 'cart_items') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'inventory_balances' as tabela, count(*) as linhas from {{ source('legacy', 'inventory_balances') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'inventory_movements' as tabela, count(*) as linhas from {{ source('legacy', 'inventory_movements') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'orders' as tabela, count(*) as linhas from {{ source('legacy', 'orders') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'product_prices' as tabela, count(*) as linhas from {{ source('legacy', 'product_prices') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'purchase_order_items' as tabela, count(*) as linhas from {{ source('legacy', 'purchase_order_items') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'coupon_redemptions' as tabela, count(*) as linhas from {{ source('legacy', 'coupon_redemptions') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'goods_receipt_items' as tabela, count(*) as linhas from {{ source('legacy', 'goods_receipt_items') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'order_items' as tabela, count(*) as linhas from {{ source('legacy', 'order_items') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'order_status_history' as tabela, count(*) as linhas from {{ source('legacy', 'order_status_history') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'payments' as tabela, count(*) as linhas from {{ source('legacy', 'payments') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'shipments' as tabela, count(*) as linhas from {{ source('legacy', 'shipments') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'stock_reservations' as tabela, count(*) as linhas from {{ source('legacy', 'stock_reservations') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'delivery_events' as tabela, count(*) as linhas from {{ source('legacy', 'delivery_events') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'payment_transactions' as tabela, count(*) as linhas from {{ source('legacy', 'payment_transactions') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'shipment_items' as tabela, count(*) as linhas from {{ source('legacy', 'shipment_items') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'support_tickets' as tabela, count(*) as linhas from {{ source('legacy', 'support_tickets') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'refunds' as tabela, count(*) as linhas from {{ source('legacy', 'refunds') }} where _airbyte_generation_id = (select snapshot_id from selecionada)
    union all
    select 'ticket_events' as tabela, count(*) as linhas from {{ source('legacy', 'ticket_events') }} where _airbyte_generation_id = (select snapshot_id from selecionada)

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
   or c.received_rows is distinct from b.linhas
