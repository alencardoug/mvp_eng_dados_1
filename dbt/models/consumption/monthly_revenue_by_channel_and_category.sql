-- P01 — Qual a receita líquida por mês, canal e categoria de produto?
--
-- É a pergunta base do datamart: as demais recortam esta de outra forma.
--
-- **Só venda realizada.** Pedido que não chegou a `paid` ainda pode não virar
-- nada, e contá-lo como receita seria confundir intenção com fato.
--
-- **SKU excluído do catálogo continua contando** (ADR-0029): a venda de 2024
-- aconteceu, e o cadastro de hoje não a desfaz. Quem quiser só o catálogo vivo
-- filtra `product_is_deleted`, que viaja junto.

select
    d.year_month,
    d.year_number,
    d.month_number,
    ch.sales_channel_name,
    ch.channel_type,
    cat.root_category_name,
    cat.category_name,

    count(distinct f.order_id)                      as order_count,
    sum(f.quantity)                                 as unit_count,
    sum(f.gross_revenue_amount)                     as gross_revenue_amount,
    sum(f.discount_amount)                          as discount_amount,
    sum(f.net_revenue_amount)                       as net_revenue_amount
from {{ ref('fact_sales_order_item') }} f
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_sales_channel') }} ch using (sales_channel_key)
join {{ ref('dim_category') }} cat using (category_key)
where f.is_realised
group by 1, 2, 3, 4, 5, 6, 7
