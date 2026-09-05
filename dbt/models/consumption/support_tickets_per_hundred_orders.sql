-- P15 — Quantos chamados por 100 pedidos, por categoria de chamado e canal,
-- mês a mês?
--
-- ── Duas fatos, dois grãos, um *drill across* ───────────────────────────────
-- O numerador vem de `fact_support_ticket_event` e o denominador de
-- `fact_sales_order_item`. Nenhuma das duas está no grão da resposta: a
-- primeira está no grão do **evento** e a segunda no do **item**. Cada uma é
-- reduzida ao seu grão de contagem antes de se encontrarem — que é o que o
-- ADR-0030 chama de *drill across*, e o motivo de não haver `join` entre fatos
-- aqui.
--
-- ── O denominador é do canal, não da categoria ──────────────────────────────
-- Pedido não tem categoria de chamado, e não faria sentido ter. Por isso a
-- coluna se chama `channel_order_count`, e não `order_count`: ela é do mês e do
-- canal, e **se repete** em cada linha de categoria. Somá-la ao longo das
-- categorias multiplica os pedidos pelo número de categorias — o nome existe
-- para que quem for somar pare antes.
--
-- ── Duas ausências previstas, e o que cada uma significa ────────────────────
-- **Linha com `channel_order_count` nulo.** São os chamados do canal *Sem
-- canal* — os que não nasceram de pedido. Sem pedido não há canal, e sem canal
-- não há denominador: a contagem aparece e a taxa fica nula, que é a resposta
-- honesta. Foram 45 dos 400 chamados na execução de referência, e **todos** de
-- lá: nenhum canal real ficou sem denominador em mês nenhum.
--
-- **Mês e canal que não aparecem.** A view tem linha onde houve ao menos um
-- chamado. Mês com pedidos e nenhum chamado não vira linha de zero — seriam
-- seis linhas por combinação, uma por categoria, e a view passaria a ser
-- majoritariamente vazio. Quem precisa da grade completa a produz na leitura,
-- contra `dim_date`.
--
-- ── O mês é o da abertura ───────────────────────────────────────────────────
-- Um chamado é contado no mês em que foi **aberto**, e a redução ao evento
-- `created` é o que garante isso. Contar por evento poria o mesmo chamado em
-- dois meses, e contar pelo fechamento diria que o mês passado melhorou porque
-- os chamados dele ainda não fecharam.

with chamados as (

    select
        f.date_key,
        f.sales_channel_key,
        f.support_category_key,
        f.support_ticket_id,
        f.ticket_priority,
        f.was_reopened,
        f.is_solved_first_time,
        f.hours_to_resolution
    from {{ ref('fact_support_ticket_event') }} f
    where f.is_ticket_creation

),

pedidos as (

    select
        date_key,
        sales_channel_key,
        count(distinct order_id)                        as channel_order_count
    from {{ ref('fact_sales_order_item') }}
    where is_realised
    group by date_key, sales_channel_key

),

pedidos_por_mes as (

    select
        d.year_month,
        p.sales_channel_key,
        sum(p.channel_order_count)                      as channel_order_count
    from pedidos p
    join {{ ref('dim_date') }} d on d.date_key = p.date_key
    group by d.year_month, p.sales_channel_key

),

chamados_por_mes as (

    select
        d.year_number,
        d.month_number,
        d.year_month,
        c.sales_channel_key,
        c.support_category_key,
        count(*)                                        as ticket_count,
        count(*) filter (where c.ticket_priority in ('high', 'urgent'))
                                                        as high_priority_ticket_count,
        count(*) filter (where c.was_reopened)          as reopened_ticket_count,
        count(*) filter (where c.is_solved_first_time)  as solved_first_time_count,
        round(avg(c.hours_to_resolution), 2)            as avg_hours_to_resolution
    from chamados c
    join {{ ref('dim_date') }} d on d.date_key = c.date_key
    group by 1, 2, 3, 4, 5

)

select
    t.year_number,
    t.month_number,
    t.year_month,
    ch.sales_channel_name,
    ch.channel_type,
    cat.support_category_name,
    cat.support_category_group,

    t.ticket_count,
    t.high_priority_ticket_count,
    t.reopened_ticket_count,
    t.solved_first_time_count,
    p.channel_order_count,

    -- Não aditiva: recalcula-se a cada recorte. Numerador e denominador vão ao
    -- lado, como em toda view de razão do projeto.
    round(t.ticket_count * 100.0 / nullif(p.channel_order_count, 0), 4)
                                                        as tickets_per_hundred_orders,
    t.avg_hours_to_resolution
from chamados_por_mes t
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_key = t.sales_channel_key
join {{ ref('dim_support_category') }} cat on cat.support_category_key = t.support_category_key
left join pedidos_por_mes p
       on p.year_month = t.year_month
      and p.sales_channel_key = t.sales_channel_key
