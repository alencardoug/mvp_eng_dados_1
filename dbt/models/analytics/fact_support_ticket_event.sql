-- Fato de evento de atendimento.
--
-- **Grão: um evento de um chamado.** Criação, atribuição, mensagem, mudança de
-- estado, resolução e reabertura — o rastro inteiro, não só o desfecho.
--
-- ── Por que o grão é o evento, e não o chamado ──────────────────────────────
-- `support_tickets.status` diz onde o chamado está hoje. Um chamado resolvido,
-- reaberto e resolvido de novo termina em `resolved`, exatamente como um que foi
-- resolvido de primeira — e são coisas muito diferentes. Perguntas de esforço e
-- de duração só o livro responde. É a mesma leitura do ADR-0030 no estoque e do
-- [ADR-0034](../../../docs/adr/0034-entrega-do-livro-de-eventos.md) na entrega.
--
-- ── As duas âncoras ─────────────────────────────────────────────────────────
-- O **agente** entra pela versão vigente no instante do evento: a equipe que
-- atendeu é a que existia então. O **cliente**, pela versão vigente na abertura
-- do chamado — o chamado é um só, e trocar de versão no meio dele partiria a
-- contagem.
--
-- ── Os dois membros desconhecidos ───────────────────────────────────────────
-- `support_agent_key` aterrissa no membro desconhecido quando o autor do evento
-- é o **cliente**, e `sales_channel_key` quando o chamado não nasceu de um
-- pedido — 15% deles, por construção. Nos dois casos a ausência é junção que
-- não tem par, e não fato: por isso membro desconhecido, e não nulo.
--
-- ── A medida que se repete ──────────────────────────────────────────────────
-- `ticket_count` **não** está aqui. Contar chamados sobre uma fato de eventos
-- exige `count(distinct support_ticket_id)`, e uma coluna chamada `ticket_count`
-- valendo 1 em cada evento seria um convite a somá-la — dando o número de
-- eventos com nome de número de chamados. `event_count` é o que se soma.

with eventos as (

    select * from {{ ref('ticket_events') }}

),

chamados as (

    select * from {{ ref('support_tickets') }}

),

base as (

    select
        e.ticket_event_id,
        e.support_ticket_id,
        e.support_agent_id,
        e.ticket_event_type,
        e.occurred_at,
        e.event_sequence,
        e.is_ticket_creation,
        e.is_assignment,
        e.is_message,
        e.is_status_change,
        e.is_resolution,
        e.is_reopening,
        e.is_from_customer,

        t.ticket_number,
        t.customer_id,
        t.order_id,
        t.ticket_category,
        t.ticket_priority,
        t.ticket_status,
        t.opened_at,
        t.closed_at,
        t.is_closed,
        t.has_order,
        t.was_reopened,
        t.is_solved_first_time,
        t.reopening_count,
        t.hours_to_assignment,
        t.hours_to_resolution,

        o.sales_channel_id,
        o.placed_at                                     as order_placed_at,
        cast(e.occurred_at at time zone 'America/Sao_Paulo' as date) as event_date
    from eventos e
    join chamados t on t.support_ticket_id = e.support_ticket_id
    left join {{ ref('orders') }} o on o.order_id = t.order_id

)

select
    {{ dbt_utils.generate_surrogate_key(['b.ticket_event_id']) }} as support_ticket_event_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    d.date_key,
    cu.customer_key,
    sc.support_category_key,
    ag.support_agent_key,
    coalesce(ch.sales_channel_key, {{ chave_desconhecida() }}) as sales_channel_key,
    coalesce(g.geography_key, {{ chave_desconhecida() }})      as geography_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    b.ticket_event_id,
    b.support_ticket_id,
    b.ticket_number,
    b.order_id,
    b.ticket_event_type,
    b.ticket_category,
    b.ticket_priority,
    b.ticket_status,
    b.event_sequence,
    b.occurred_at,
    b.opened_at,
    b.closed_at,
    b.order_placed_at,

    -- ── Sinalizadores ────────────────────────────────────────────────────────
    b.is_ticket_creation,
    b.is_assignment,
    b.is_message,
    b.is_status_change,
    b.is_resolution,
    b.is_reopening,
    b.is_from_customer,
    b.is_closed,
    b.has_order,
    b.was_reopened,
    b.is_solved_first_time,

    -- ── Medidas ──────────────────────────────────────────────────────────────
    -- Aditiva: eventos. Não aditivas: as durações, que são do chamado e se
    -- repetem em cada evento dele — reduza ao chamado antes de tirar média.
    1                                                   as event_count,
    b.reopening_count,
    b.hours_to_assignment,
    b.hours_to_resolution
from base b
join {{ ref('dim_date') }} d on d.full_date = b.event_date
join {{ ref('dim_support_category') }} sc
  on sc.support_category_natural_key = b.ticket_category

-- Versão do agente vigente no instante do evento; membro desconhecido quando o
-- autor é o cliente.
join {{ ref('dim_support_agent') }} ag
  on ag.support_agent_natural_key = coalesce(b.support_agent_id, -1)
 and b.occurred_at >= ag.valid_from
 and (ag.valid_to is null or b.occurred_at < ag.valid_to)

-- Versão do cliente vigente na abertura do chamado.
join {{ ref('dim_customer') }} cu
  on cu.customer_natural_key = b.customer_id
 and b.opened_at >= cu.valid_from
 and (cu.valid_to is null or b.opened_at < cu.valid_to)

left join {{ ref('dim_sales_channel') }} ch
       on ch.sales_channel_natural_key = b.sales_channel_id
left join {{ ref('dim_geography') }} g
  on g.country = cu.country and g.state_code = cu.state_code and g.city = cu.city
