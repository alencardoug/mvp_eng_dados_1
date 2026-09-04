-- P05 — Qual a receita e o número de pedidos por estado e região, por trimestre?
--
-- A geografia é a do endereço principal de entrega do cliente, na versão
-- vigente no momento da venda: mudança de endereço hoje não move a receita de
-- 2024 de região.

select
    d.year_number,
    d.quarter_number,
    d.year_number || '-T' || d.quarter_number       as year_quarter,
    g.region,
    g.state_code,
    g.state_name,
    ch.sales_channel_name,

    count(distinct f.order_id)                      as order_count,
    count(distinct f.customer_key)                  as customer_version_count,
    sum(f.quantity)                                 as unit_count,
    sum(f.net_revenue_amount)                       as net_revenue_amount
from {{ ref('fact_sales_order_item') }} f
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_geography') }} g using (geography_key)
join {{ ref('dim_sales_channel') }} ch using (sales_channel_key)
where f.is_realised
group by 1, 2, 3, 4, 5, 6, 7
