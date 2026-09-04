-- P02 — Qual o ticket médio por pedido, por canal e por segmento, mês a mês?
--
-- O ticket médio é **não aditivo**: a média das médias mensais não é a média do
-- ano. Por isso a view entrega o numerador e o denominador ao lado do
-- resultado — quem reagregar por trimestre soma os dois e divide de novo, em
-- vez de somar ticket médio com ticket médio.
--
-- O denominador é o **pedido**, não o item: um pedido de cinco itens conta uma
-- vez.

select
    d.year_month,
    d.year_number,
    d.month_number,
    ch.sales_channel_name,
    c.customer_segment_name,

    count(distinct f.order_id)                      as order_count,
    sum(f.net_revenue_amount)                       as net_revenue_amount,
    round(
        sum(f.net_revenue_amount) / nullif(count(distinct f.order_id), 0), 2
    )                                               as average_order_value
from {{ ref('fact_sales_order_item') }} f
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_sales_channel') }} ch using (sales_channel_key)
join {{ ref('dim_customer') }} c using (customer_key)
where f.is_realised
group by 1, 2, 3, 4, 5
