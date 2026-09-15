-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A equação física entre a certificada anterior e a selecionada (ADR-0045):
--
--   linhas(anterior) − Σ max(0, n_ant − n_sel) + Σ max(0, n_sel − n_ant)
--     + (sem_identidade_sel − sem_identidade_ant) = linhas(selecionada)
--
-- por tabela, em **linhas físicas** contadas direto no bruto — não nas
-- transições. É o que garante que o modelo de intervalo descreve o que o bruto
-- tem, e não o contrário. Sem anterior certificada não há linhas a cobrar.

with transicoes as (

    select * from {{ ref('legacy_capture_transitions') }}

),

bruto as (

    select 'brands' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'brands') }} group by 1, 2
    union all
    select 'campaigns' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'campaigns') }} group by 1, 2
    union all
    select 'carriers' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'carriers') }} group by 1, 2
    union all
    select 'customer_segments' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_segments') }} group by 1, 2
    union all
    select 'payment_methods' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'payment_methods') }} group by 1, 2
    union all
    select 'product_categories' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'product_categories') }} group by 1, 2
    union all
    select 'sales_channels' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'sales_channels') }} group by 1, 2
    union all
    select 'suppliers' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'suppliers') }} group by 1, 2
    union all
    select 'support_agents' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'support_agents') }} group by 1, 2
    union all
    select 'warehouses' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'warehouses') }} group by 1, 2
    union all
    select 'coupons' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'coupons') }} group by 1, 2
    union all
    select 'customers' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'customers') }} group by 1, 2
    union all
    select 'price_lists' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'price_lists') }} group by 1, 2
    union all
    select 'products' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'products') }} group by 1, 2
    union all
    select 'purchase_orders' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'purchase_orders') }} group by 1, 2
    union all
    select 'carts' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'carts') }} group by 1, 2
    union all
    select 'customer_addresses' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_addresses') }} group by 1, 2
    union all
    select 'customer_contacts' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_contacts') }} group by 1, 2
    union all
    select 'customer_preferences' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'customer_preferences') }} group by 1, 2
    union all
    select 'goods_receipts' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'goods_receipts') }} group by 1, 2
    union all
    select 'product_variants' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'product_variants') }} group by 1, 2
    union all
    select 'cart_items' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'cart_items') }} group by 1, 2
    union all
    select 'inventory_balances' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'inventory_balances') }} group by 1, 2
    union all
    select 'inventory_movements' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'inventory_movements') }} group by 1, 2
    union all
    select 'orders' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'orders') }} group by 1, 2
    union all
    select 'product_prices' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'product_prices') }} group by 1, 2
    union all
    select 'purchase_order_items' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'purchase_order_items') }} group by 1, 2
    union all
    select 'coupon_redemptions' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'coupon_redemptions') }} group by 1, 2
    union all
    select 'goods_receipt_items' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'goods_receipt_items') }} group by 1, 2
    union all
    select 'order_items' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'order_items') }} group by 1, 2
    union all
    select 'order_status_history' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'order_status_history') }} group by 1, 2
    union all
    select 'payments' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'payments') }} group by 1, 2
    union all
    select 'shipments' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'shipments') }} group by 1, 2
    union all
    select 'stock_reservations' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'stock_reservations') }} group by 1, 2
    union all
    select 'delivery_events' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'delivery_events') }} group by 1, 2
    union all
    select 'payment_transactions' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'payment_transactions') }} group by 1, 2
    union all
    select 'shipment_items' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'shipment_items') }} group by 1, 2
    union all
    select 'support_tickets' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'support_tickets') }} group by 1, 2
    union all
    select 'refunds' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'refunds') }} group by 1, 2
    union all
    select 'ticket_events' as source_table, _airbyte_generation_id as snapshot_id, count(*) as linhas from {{ source('legacy', 'ticket_events') }} group by 1, 2

),

por_tabela as (

    select
        source_table,
        min(previous_snapshot_id)                                   as previous_snapshot_id,
        min(selected_snapshot_id)                                   as selected_snapshot_id,
        sum(case when business_key is not null then greatest(rows_before - rows_after, 0) else 0 end) as perdidas,
        sum(case when business_key is not null then greatest(rows_after - rows_before, 0) else 0 end) as ganhas,
        sum(case when business_key is null then rows_after - rows_before else 0 end)                  as delta_sem_identidade
    from transicoes
    group by source_table

)

select
    t.source_table,
    coalesce(a.linhas, 0)                                           as linhas_anterior,
    coalesce(s.linhas, 0)                                           as linhas_selecionada,
    t.perdidas, t.ganhas, t.delta_sem_identidade,
    coalesce(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade as calculado
from por_tabela t
left join bruto a on a.source_table = t.source_table and a.snapshot_id = t.previous_snapshot_id
left join bruto s on s.source_table = t.source_table and s.snapshot_id = t.selected_snapshot_id
where coalesce(a.linhas, 0) - t.perdidas + t.ganhas + t.delta_sem_identidade <> coalesce(s.linhas, 0)
