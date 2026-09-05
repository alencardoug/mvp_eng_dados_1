-- P14 — Qual o tempo médio entre pedido e entrega, por região e modalidade?
--
-- **Grão do pedido** ([ADR-0033](../../../docs/adr/0033-entrega-medida-em-dois-graos.md)):
-- o ciclo conta de `placed_at` até a chegada da **última** remessa, porque é
-- quando o pedido chegou inteiro que o cliente considera que chegou.
--
-- Pedido com alguma remessa ainda em trânsito, extraviada ou nunca despachada
-- **não entra**: ele não tem tempo até a entrega, tem tempo até agora, que é
-- outra medida. Excluir é o que impede a média de melhorar quando uma remessa
-- se perde.
--
-- A modalidade é a da remessa que **fechou** o ciclo — a última a chegar. Hoje
-- o gerador dá uma transportadora por pedido e as duas leituras coincidem; a
-- regra está escrita porque o dia em que deixarem de coincidir não avisa.
--
-- Esta view e a de P13 **não se cruzam**: uma conta remessas, a outra conta
-- pedidos, e um pedido com uma remessa entregue e outra extraviada aparece lá e
-- não aparece aqui.

with pedidos as (

    select distinct
        f.order_id,
        f.delivered_date_key,
        f.geography_key,
        f.carrier_key,
        f.is_split_order,
        f.order_shipment_count,
        f.order_to_delivery_days
    from {{ ref('fact_shipment_item') }} f
    where f.is_order_cycle_closed
      and f.is_cycle_closing_shipment

)

select
    d.year_number,
    d.month_number,
    d.year_month,
    g.region,
    g.state_code,
    c.service_level,
    c.carrier_name,

    count(*)                                                as order_count,
    count(*) filter (where p.is_split_order)                as split_order_count,
    sum(p.order_shipment_count)                             as shipment_count,

    -- Não aditivas: médias e mediana. A mediana está aqui porque a cauda de
    -- entregas muito atrasadas puxa a média e esconde o caso típico — as duas
    -- lado a lado dizem se a operação é lenta ou apenas irregular.
    round(avg(p.order_to_delivery_days), 4)                 as avg_order_to_delivery_days,
    round(
        percentile_cont(0.5) within group (order by p.order_to_delivery_days)::numeric, 4
    )                                                       as median_order_to_delivery_days,
    round(max(p.order_to_delivery_days), 4)                 as max_order_to_delivery_days
from pedidos p
join {{ ref('dim_date') }} d on d.date_key = p.delivered_date_key
join {{ ref('dim_geography') }} g on g.geography_key = p.geography_key
join {{ ref('dim_carrier') }} c on c.carrier_key = p.carrier_key
group by 1, 2, 3, 4, 5, 6, 7
