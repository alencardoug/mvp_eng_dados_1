-- P16 — Qual a taxa de recompra em 90 dias dos clientes que abriram chamado,
-- comparada à dos que não abriram?
--
-- ── A unidade é o pedido ────────────────────────────────────────────────────
-- Os 90 dias correm do **pedido**, não da estreia do cliente nem do chamado
-- ([ADR-0036](../../../docs/adr/0036-recompra-ancorada-no-pedido.md)). É o que
-- dá aos dois grupos a mesma âncora e a mesma janela: sem isso, a diferença
-- entre eles mediria o desenho da medida, não o atendimento.
--
-- **Não é a recompra de P04.** Aquela conta clientes de uma coorte de estreia;
-- esta conta pedidos. Os dois números não se somam e não se dividem um pelo
-- outro.
--
-- ── Quem fica de fora, e por quê ────────────────────────────────────────────
-- Pedido cuja janela de 90 dias ainda não fechou em `as_of_date` não entra:
-- janela aberta não é ausência de recompra, e incluí-la faria a taxa dos meses
-- recentes cair sozinha. Chamado sem pedido associado — 15% deles — também não
-- entra: não há pedido a partir do qual contar.
--
-- ── Como ler as linhas ──────────────────────────────────────────────────────
-- O grupo de comparação é a linha `has_support_ticket = false`, uma por mês e
-- canal. As demais são por categoria de chamado, e **um pedido que gerou
-- chamados de duas categorias aparece nas duas** — somar `order_count` ao longo
-- das categorias conta esse pedido duas vezes. A taxa dentro de cada linha
-- continua correta, que é o que a pergunta pede.

with pedidos as (

    select distinct
        f.order_id,
        f.date_key,
        f.sales_channel_key,
        f.has_post_order_repeat,
        f.days_to_next_order
    from {{ ref('fact_sales_order_item') }} f
    where f.is_realised
      and f.is_repeat_window_closed

),

-- Pedidos que geraram chamado, por categoria. `distinct` porque a fato está no
-- grão do evento: um chamado com seis eventos não pode contar seis vezes.
com_chamado as (

    select distinct
        t.order_id,
        t.support_category_key
    from {{ ref('fact_support_ticket_event') }} t
    where t.order_id is not null

),

-- Um pedido por linha de categoria, mais uma linha por pedido sem chamado
-- nenhum. É a união que produz os dois grupos comparáveis.
classificado as (

    select
        p.order_id,
        p.date_key,
        p.sales_channel_key,
        p.has_post_order_repeat,
        p.days_to_next_order,
        true                                            as has_support_ticket,
        c.support_category_key
    from pedidos p
    join com_chamado c on c.order_id = p.order_id

    union all

    select
        p.order_id,
        p.date_key,
        p.sales_channel_key,
        p.has_post_order_repeat,
        p.days_to_next_order,
        false                                           as has_support_ticket,
        null::text                                      as support_category_key
    from pedidos p
    where not exists (select 1 from com_chamado c where c.order_id = p.order_id)

)

select
    d.year_number,
    d.month_number,
    d.year_month,
    ch.sales_channel_name,
    cl.has_support_ticket,
    coalesce(cat.support_category_name, 'Sem chamado') as support_category_name,

    count(*)                                            as order_count,
    count(*) filter (where cl.has_post_order_repeat)    as repeat_order_count,

    -- Não aditiva.
    round(
        count(*) filter (where cl.has_post_order_repeat)::numeric / nullif(count(*), 0), 4
    )                                                   as repeat_purchase_rate,

    -- Quando volta, volta em quanto tempo. Pergunta diferente de "com que
    -- frequência volta", e as duas juntas é que descrevem o efeito.
    round(avg(cl.days_to_next_order) filter (where cl.has_post_order_repeat), 2)
                                                        as avg_days_to_next_order
from classificado cl
join {{ ref('dim_date') }} d on d.date_key = cl.date_key
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_key = cl.sales_channel_key
left join {{ ref('dim_support_category') }} cat
       on cat.support_category_key = cl.support_category_key
group by 1, 2, 3, 4, 5, 6
