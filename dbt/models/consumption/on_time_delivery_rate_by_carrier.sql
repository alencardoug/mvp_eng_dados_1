-- P13 — Qual a fração de entregas dentro do prazo prometido, por transportadora
-- e modalidade, mês a mês?
--
-- **Grão da remessa** ([ADR-0033](../../../docs/adr/0033-entrega-medida-em-dois-graos.md)):
-- transportadora e modalidade são atributos da remessa, e é nela que a promessa
-- de prazo existe. O pedido dividido em duas remessas conta **duas vezes** aqui,
-- de propósito — foram duas promessas e duas chegadas.
--
-- O mês é o da **chegada**, não o do despacho: a pergunta é sobre entregas
-- realizadas, e uma remessa que saiu em janeiro e chegou em fevereiro é uma
-- entrega de fevereiro.
--
-- A fato está no grão do item; a redução a remessa é o `distinct` abaixo. Sem
-- ele, uma caixa com seis itens pesaria seis vezes na taxa, e a transportadora
-- que leva pedidos maiores pareceria melhor ou pior sem que nada tivesse
-- mudado na pontualidade dela.

with remessas as (

    select distinct
        f.shipment_id,
        f.delivered_date_key,
        f.carrier_key,
        f.warehouse_key,
        f.is_on_time,
        f.is_split_order,
        f.delivery_delay_days,
        f.transit_days,
        f.failed_attempt_count
    from {{ ref('fact_shipment_item') }} f
    where f.is_delivered

)

select
    d.year_number,
    d.month_number,
    d.year_month,
    c.carrier_name,
    c.service_level,
    w.warehouse_name,
    w.warehouse_region,

    count(*)                                                as delivered_count,
    count(*) filter (where r.is_on_time)                    as on_time_count,
    count(*) filter (where not r.is_on_time)                as late_count,
    count(*) filter (where r.is_split_order)                as split_order_shipment_count,

    -- Não aditiva: recalcula-se a cada recorte, e nunca se soma entre linhas.
    round(
        count(*) filter (where r.is_on_time)::numeric / nullif(count(*), 0), 4
    )                                                       as on_time_rate,

    -- Positivo é atraso, negativo é adiantamento. A média sobre as atrasadas
    -- responde "quando atrasa, atrasa quanto" — pergunta diferente de "com que
    -- frequência atrasa", e as duas juntas é que descrevem a transportadora.
    round(avg(r.delivery_delay_days) filter (where not r.is_on_time), 4)
                                                            as avg_delay_days_when_late,
    round(avg(r.transit_days), 4)                           as avg_transit_days,
    sum(r.failed_attempt_count)                             as failed_attempt_count
from remessas r
join {{ ref('dim_date') }} d on d.date_key = r.delivered_date_key
join {{ ref('dim_carrier') }} c on c.carrier_key = r.carrier_key
join {{ ref('dim_warehouse') }} w on w.warehouse_key = r.warehouse_key
group by 1, 2, 3, 4, 5, 6, 7
