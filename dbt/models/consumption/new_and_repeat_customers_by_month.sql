-- P04 — Quantos clientes estrearam em cada mês, e quantos voltaram em 90 dias?
--
-- **A coorte é a do mês da estreia, não a da recompra.** Um cliente que estreou
-- em janeiro e voltou em março conta na coorte de **janeiro** — é assim que a
-- taxa de um mês para de mudar depois de fechada a janela. Contar no mês da
-- recompra faria toda coorte antiga variar para sempre.

with estreia as (

    -- Primeira compra realizada de cada cliente, com o canal em que ela
    -- aconteceu. `distinct on` sobre a chave natural, não a da versão: um
    -- cliente com duas versões continua sendo um cliente.
    select distinct on (c.customer_natural_key)
        c.customer_natural_key,
        c.customer_segment_name,
        f.placed_at                                 as first_order_at,
        f.date_key                                  as first_order_date_key,
        f.sales_channel_key
    from {{ ref('fact_sales_order_item') }} f
    join {{ ref('dim_customer') }} c using (customer_key)
    where f.is_realised
    order by c.customer_natural_key, f.placed_at

),

recompra as (

    -- Existe segundo pedido dentro da janela declarada, contada da estreia.
    select
        e.customer_natural_key,
        min(f.placed_at)                            as second_order_at
    from estreia e
    join {{ ref('dim_customer') }} c
      on c.customer_natural_key = e.customer_natural_key
    join {{ ref('fact_sales_order_item') }} f
      on f.customer_key = c.customer_key
     and f.is_realised
     and f.placed_at > e.first_order_at
    group by e.customer_natural_key

)

select
    d.year_month,
    d.year_number,
    d.month_number,
    ch.sales_channel_name,
    e.customer_segment_name,

    count(*)                                        as new_customer_count,
    count(*) filter (
        where r.second_order_at is not null
          and r.second_order_at <= e.first_order_at
              + interval '{{ var("repeat_purchase_window_days") }} days'
    )                                               as returning_customer_count,
    round(
        100.0 * count(*) filter (
            where r.second_order_at is not null
              and r.second_order_at <= e.first_order_at
                  + interval '{{ var("repeat_purchase_window_days") }} days'
        ) / nullif(count(*), 0), 2
    )                                               as repeat_purchase_rate_pct
from estreia e
join {{ ref('dim_date') }} d on d.date_key = e.first_order_date_key
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_key = e.sales_channel_key
left join recompra r on r.customer_natural_key = e.customer_natural_key
group by 1, 2, 3, 4, 5
