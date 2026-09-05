-- Livro do chamado — o grão de `fact_support_ticket_event`.
--
-- Seis tipos de evento, e a diferença entre eles é o que separa "quanto tempo o
-- chamado levou" de "quanto tempo o cliente esperou": `created` abre,
-- `assigned` põe um agente, `message` é interação, `status_changed` move o
-- estado, `resolved` fecha e `reopened` desfaz o fechamento.
--
-- `support_agent_id` nulo é **autor cliente**, não dado faltando.

with eventos as (

    select * from {{ ref('stg_retail__ticket_events') }}

)

select
    ticket_event_id,
    support_ticket_id,
    support_agent_id,
    ticket_event_type,
    occurred_at,
    ticket_message,

    ticket_event_type = 'created'                   as is_ticket_creation,
    ticket_event_type = 'assigned'                  as is_assignment,
    ticket_event_type = 'message'                   as is_message,
    ticket_event_type = 'status_changed'            as is_status_change,
    ticket_event_type = 'resolved'                  as is_resolution,
    ticket_event_type = 'reopened'                  as is_reopening,
    support_agent_id is null                        as is_from_customer,

    row_number() over (partition by support_ticket_id order by occurred_at, ticket_event_id)
                                                    as event_sequence,

    is_deleted,
    source_created_at
from eventos
