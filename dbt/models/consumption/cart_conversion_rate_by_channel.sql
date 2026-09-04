-- P07 — Qual a taxa de conversão de carrinho em pedido, por canal e mês?
--
-- **O carrinho é contado no mês em que foi criado**, não no mês em que
-- converteu: por isso o recorte usa `cart_created_date_key`. Um carrinho aberto
-- em 30 de novembro e convertido em 2 de dezembro pertence a novembro nas duas
-- contagens — senão a taxa de dezembro poderia passar de 100%.
--
-- **O denominador é `closed_cart_count`**, não `cart_count`: carrinho ainda
-- aberto e dentro do prazo não tem desfecho, e incluí-lo faria a taxa dos meses
-- recentes cair sozinha com o passar dos dias.

select
    d.year_month,
    d.year_number,
    d.month_number,
    ch.sales_channel_name,
    ch.channel_type,

    sum(f.cart_count)                               as cart_count,
    sum(f.closed_cart_count)                        as closed_cart_count,
    sum(f.converted_cart_count)                     as converted_cart_count,
    sum(f.abandoned_cart_count)                     as abandoned_cart_count,
    round(
        100.0 * sum(f.converted_cart_count) / nullif(sum(f.closed_cart_count), 0), 2
    )                                               as cart_conversion_rate_pct,
    sum(f.cart_value_amount)                        as cart_value_amount,
    sum(f.abandoned_value_amount)                   as abandoned_value_amount
from {{ ref('fact_cart_event') }} f
join {{ ref('dim_date') }} d on d.date_key = f.cart_created_date_key
join {{ ref('dim_sales_channel') }} ch using (sales_channel_key)
group by 1, 2, 3, 4, 5
