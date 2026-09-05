-- Fato de evento de estado do pedido.
--
-- **Grão: uma transição de estado.** Uma linha é *"este pedido saiu deste
-- estado e entrou naquele, neste momento"*. É a máquina de estados do pedido
-- vista como fato, e não como coluna corrente: `orders.order_status` diz onde o
-- pedido está **hoje**, e esta fato diz por onde ele passou.
--
-- A distinção é a mesma que o ADR-0030 fez no estoque e o
-- [ADR-0034](../../../docs/adr/0034-entrega-do-livro-de-eventos.md) fez na
-- entrega: projeção corrente responde "onde está", livro responde "o que
-- aconteceu", e perguntas de duração só a segunda responde.
--
-- ── A medida que não se soma ────────────────────────────────────────────────
-- `hours_in_previous_status` é o tempo que o pedido passou no estado de origem.
-- É **não aditiva**: somá-la ao longo das transições de um pedido dá o tempo
-- total do ciclo, o que é útil, mas somá-la entre pedidos não dá nada.
-- `transition_count` é a medida aditiva, e é sempre 1 — a contagem de linhas
-- explicitada, para que o `sum` seja possível sem `count(*)` disfarçado.

with eventos as (

    select * from {{ ref('order_status_events') }}

),

pedidos as (

    select * from {{ ref('orders') }}

),

base as (

    select
        e.order_status_event_id,
        e.order_id,
        e.from_status,
        e.to_status,
        e.changed_at,
        e.change_reason,
        e.status_sequence,
        e.previous_changed_at,
        e.hours_in_previous_status,
        e.is_order_creation,
        e.is_current_status,
        e.is_terminal_status,
        e.is_cancellation,
        e.is_return,

        p.customer_id,
        p.sales_channel_id,
        p.order_number,
        p.placed_at,
        p.order_status,
        p.is_realised,
        cast(e.changed_at at time zone 'America/Sao_Paulo' as date) as change_date
    from eventos e
    join pedidos p on p.order_id = e.order_id

)

select
    {{ dbt_utils.generate_surrogate_key(['b.order_status_event_id']) }} as order_status_event_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    d.date_key,
    cu.customer_key,
    ch.sales_channel_key,
    coalesce(g.geography_key, {{ chave_desconhecida() }}) as geography_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    b.order_id,
    b.order_status_event_id,
    b.order_number,
    b.from_status,
    b.to_status,
    b.change_reason,
    b.status_sequence,
    b.placed_at,
    b.changed_at,
    b.previous_changed_at,
    b.order_status                                  as current_order_status,

    b.is_order_creation,
    b.is_current_status,
    b.is_terminal_status,
    b.is_cancellation,
    b.is_return,
    b.is_realised,

    -- ── Medidas ──────────────────────────────────────────────────────────────
    1                                               as transition_count,
    b.hours_in_previous_status
from base b
join {{ ref('dim_date') }} d on d.full_date = b.change_date
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_natural_key = b.sales_channel_id

-- Versão do cliente vigente no instante da **venda**: a transição pertence ao
-- pedido, e o pedido foi feito por aquela versão do cliente.
join {{ ref('dim_customer') }} cu
  on cu.customer_natural_key = b.customer_id
 and b.placed_at >= cu.valid_from
 and (cu.valid_to is null or b.placed_at < cu.valid_to)

left join {{ ref('dim_geography') }} g
  on g.country = cu.country and g.state_code = cu.state_code and g.city = cu.city
