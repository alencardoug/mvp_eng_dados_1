-- P08 — Qual o lucro bruto e a margem por categoria e mês?
--
-- ── *Drill across*, não *join* ───────────────────────────────────────────────
-- Receita vem de `fact_sales_order_item`, cujo grão é item de pedido. Custo vem
-- de `fact_inventory_movement`, cujo grão é movimento e cuja ligação é com a
-- remessa, não com o item. **Nenhuma linha de uma encosta em linha da outra**:
-- cada fato é agregada ao seu próprio grão até a granularidade comum — mês e
-- categoria — e só então as duas se combinam (ADR-0030).
--
-- É o que torna a comparação legítima apesar de os grãos serem diferentes, e é
-- o que "dimensão conformada" significa na prática.
--
-- ── O descasamento temporal é real, e é para ser visto ───────────────────────
-- A receita é do mês da **venda**; o custo é do mês da **expedição**. Um pedido
-- de dezembro despachado em janeiro põe os dois em meses diferentes, e a margem
-- de janeiro carrega custo sem receita correspondente. É o comportamento
-- contábil correto por competência do estoque, e é contraintuitivo — por isso o
-- `full outer join`: o mês que tem só um dos lados aparece, em vez de sumir.

with receita as (

    select
        d.year_month,
        d.year_number,
        d.month_number,
        cat.root_category_name,
        cat.category_name,
        sum(f.net_revenue_amount)                   as net_revenue_amount,
        sum(f.quantity)                             as unit_count
    from {{ ref('fact_sales_order_item') }} f
    join {{ ref('dim_date') }} d using (date_key)
    join {{ ref('dim_category') }} cat using (category_key)
    where f.is_realised
    group by 1, 2, 3, 4, 5

),

custo as (

    select
        d.year_month,
        d.year_number,
        d.month_number,
        cat.root_category_name,
        cat.category_name,
        sum(m.cogs_amount)                          as cost_of_goods_sold,
        sum(m.quantity_out)                         as dispatched_unit_count
    from {{ ref('fact_inventory_movement') }} m
    join {{ ref('dim_date') }} d using (date_key)
    join {{ ref('dim_product') }} p using (product_key)
    join {{ ref('dim_category') }} cat on cat.category_natural_key = p.product_category_id
    where m.is_sale
    group by 1, 2, 3, 4, 5

)

select
    coalesce(r.year_month, c.year_month)                 as year_month,
    coalesce(r.year_number, c.year_number)               as year_number,
    coalesce(r.month_number, c.month_number)             as month_number,
    coalesce(r.root_category_name, c.root_category_name) as root_category_name,
    coalesce(r.category_name, c.category_name)           as category_name,

    coalesce(r.net_revenue_amount, 0)                    as net_revenue_amount,
    coalesce(c.cost_of_goods_sold, 0)                    as cost_of_goods_sold,
    coalesce(r.net_revenue_amount, 0) - coalesce(c.cost_of_goods_sold, 0)
                                                         as gross_profit_amount,
    round(
        100.0 * (coalesce(r.net_revenue_amount, 0) - coalesce(c.cost_of_goods_sold, 0))
        / nullif(r.net_revenue_amount, 0), 2
    )                                                    as gross_margin_pct,
    coalesce(r.unit_count, 0)                            as unit_count,
    coalesce(c.dispatched_unit_count, 0)                 as dispatched_unit_count
from receita r
full outer join custo c
    on  c.year_month = r.year_month
    and c.category_name = r.category_name
