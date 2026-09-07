-- Agentes de atendimento, com a carga atendida.
--
-- A equipe (`agent_team`) é o atributo que classifica o chamado numa análise, e
-- é ela que faz a dimensão ser tipo 2: um agente que muda de equipe não pode
-- reescrever a que atendeu o chamado do ano passado.

with agentes as (

    {{ empilhado('support_agents') }}

),

carga as (

    select
        source_system,
        support_agent_id,
        count(distinct support_ticket_id)           as ticket_event_ticket_count,
        count(*)                                    as ticket_event_count
    from ({{ empilhado('ticket_events') }}) te
    where support_agent_id is not null
    group by source_system, support_agent_id

)

select
    a.source_system,
    a.support_agent_id,
    a.agent_code,
    a.agent_first_name,
    a.agent_last_name,
    a.agent_full_name,
    a.agent_email,
    a.agent_team,
    a.hired_at,
    a.agent_is_active,

    coalesce(c.ticket_event_ticket_count, 0)        as handled_ticket_count,
    coalesce(c.ticket_event_count, 0)               as handled_event_count,

    a.is_deleted,
    a.source_created_at,
    a.source_updated_at
from agentes a
left join carga c
    on c.source_system = a.source_system
    and c.support_agent_id = a.support_agent_id
