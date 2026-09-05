-- Chamados, com o que o livro de eventos conta sobre cada um.
--
-- ── Reabertura é o sinal que a coluna de estado esconde ─────────────────────
-- `support_tickets.status` diz onde o chamado está hoje. Um chamado resolvido,
-- reaberto e resolvido de novo termina em `resolved` — igual a um que foi
-- resolvido de primeira, e são coisas muito diferentes para quem mede
-- atendimento. A contagem de `reopened` vem do livro, e é ela que separa os
-- dois.
--
-- Mesma leitura que o [ADR-0034](../../../docs/adr/0034-entrega-do-livro-de-eventos.md)
-- fez na entrega e o ADR-0030 no estoque: projeção corrente responde "onde
-- está", livro responde "o que aconteceu".
--
-- `order_id` é nulo em parte dos chamados — nem todo contato nasce de um
-- pedido. Não é dado faltando, e é o que exclui esses chamados da comparação de
-- P16, que é ancorada no pedido ([ADR-0036](../../../docs/adr/0036-recompra-ancorada-no-pedido.md)).

with chamados as (

    select * from {{ ref('stg_retail__support_tickets') }}

),

livro as (

    select
        support_ticket_id,
        min(occurred_at)                                    as first_event_at,
        max(occurred_at)                                    as last_event_at,
        min(occurred_at) filter (where is_assignment)       as first_assigned_at,
        min(occurred_at) filter (where is_resolution)       as first_resolved_at,
        max(occurred_at) filter (where is_resolution)       as last_resolved_at,
        count(*)                                            as ticket_event_count,
        count(*) filter (where is_reopening)                as reopening_count,
        count(*) filter (where is_message)                  as message_count,
        count(*) filter (where is_message and is_from_customer) as customer_message_count
    from {{ ref('ticket_events') }}
    group by support_ticket_id

)

select
    t.support_ticket_id,
    t.ticket_number,
    t.customer_id,
    t.order_id,
    t.shipment_id,
    t.assigned_agent_id,
    t.ticket_category,
    t.ticket_priority,
    t.ticket_status,
    t.ticket_subject,
    t.opened_at,
    t.closed_at,

    l.first_event_at,
    l.last_event_at,
    l.first_assigned_at,
    l.first_resolved_at,
    l.last_resolved_at,
    coalesce(l.ticket_event_count, 0)                       as ticket_event_count,
    coalesce(l.reopening_count, 0)                          as reopening_count,
    coalesce(l.message_count, 0)                            as message_count,
    coalesce(l.customer_message_count, 0)                   as customer_message_count,

    -- ── Sinalizadores de estado ──────────────────────────────────────────────
    t.ticket_status in ('resolved', 'closed')               as is_closed,
    t.order_id is not null                                  as has_order,
    coalesce(l.reopening_count, 0) > 0                      as was_reopened,
    coalesce(l.reopening_count, 0) = 0 and l.first_resolved_at is not null
                                                            as is_solved_first_time,

    -- ── Durações, todas não aditivas ─────────────────────────────────────────
    -- Da abertura à primeira atribuição: o tempo em que o chamado ficou sem
    -- dono. Da abertura à primeira resolução: o tempo que o cliente esperou.
    case
        when l.first_assigned_at is not null
        then extract(epoch from l.first_assigned_at - t.opened_at) / 3600.0
    end::numeric(12, 4)                                     as hours_to_assignment,
    case
        when l.first_resolved_at is not null
        then extract(epoch from l.first_resolved_at - t.opened_at) / 3600.0
    end::numeric(12, 4)                                     as hours_to_resolution,
    case
        when t.closed_at is not null
        then extract(epoch from t.closed_at - t.opened_at) / 3600.0
    end::numeric(12, 4)                                     as hours_open,

    t.is_deleted,
    t.source_created_at,
    t.source_updated_at
from chamados t
left join livro l on l.support_ticket_id = t.support_ticket_id
