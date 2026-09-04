-- P06 — Qual o desconto concedido como fração da receita bruta, por canal e mês?
--
-- A fração é **não aditiva**: somar as frações de dois meses não dá a fração do
-- bimestre. Numerador e denominador vão ao lado, como nas demais views de razão.
--
-- Na Etapa 9, com `fact_coupon_redemption` construída, esta pergunta ganha o
-- recorte por campanha. A view atual permanece: mudança quebrante nasce como
-- nova versão (ADR-0018).

select
    d.year_month,
    d.year_number,
    d.month_number,
    ch.sales_channel_name,
    ch.channel_type,
    cat.root_category_name,

    count(distinct f.order_id)                      as order_count,
    sum(f.gross_revenue_amount)                     as gross_revenue_amount,
    sum(f.discount_amount)                          as discount_amount,
    sum(f.net_revenue_amount)                       as net_revenue_amount,
    round(
        100.0 * sum(f.discount_amount) / nullif(sum(f.gross_revenue_amount), 0), 2
    )                                               as discount_share_pct
from {{ ref('fact_sales_order_item') }} f
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_sales_channel') }} ch using (sales_channel_key)
join {{ ref('dim_category') }} cat using (category_key)
where f.is_realised
group by 1, 2, 3, 4, 5, 6
