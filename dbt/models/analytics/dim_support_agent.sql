-- Agente de atendimento — SCD tipo 2, no padrão misto do projeto.
--
--   **tipo 2** — equipe, estado de atividade e exclusão. A equipe é o que
--                classifica o chamado, e reescrevê-la migraria a métrica de uma
--                equipe para outra sem que nada tivesse acontecido.
--   **tipo 1** — nome, e-mail, data de contratação e a carga atendida. Os três
--                primeiros descrevem a pessoa; o último é sobre hoje.

with versoes as (

    select
        *,
        row_number() over (partition by support_agent_id order by dbt_valid_from)
            as numero_da_versao
    from {{ ref('scd_support_agent') }}

),

atual as (

    select * from {{ ref('support_agents') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['v.support_agent_id', 'v.dbt_valid_from']) }}
                                                            as support_agent_key,
    v.support_agent_id                                      as support_agent_natural_key,

    -- ── Tipo 1 ──────────────────────────────────────────────────────────────
    a.agent_code,
    a.agent_first_name,
    a.agent_last_name,
    a.agent_full_name,
    a.agent_email,
    a.hired_at,
    a.handled_ticket_count,
    a.handled_event_count,

    -- ── Tipo 2 ──────────────────────────────────────────────────────────────
    v.agent_team,
    v.agent_is_active,
    v.is_deleted,

    case
        when v.numero_da_versao = 1 then timestamptz '{{ var("period_start") }} 00:00-03'
        else v.dbt_valid_from
    end                                                     as valid_from,
    v.dbt_valid_to                                          as valid_to,
    v.dbt_valid_to is null                                  as is_current
from versoes v
join atual a on a.support_agent_id = v.support_agent_id

union all

-- Membro desconhecido. `ticket_events.agent_id` é nulo quando o autor do evento
-- é o **cliente**, e `support_tickets.assigned_agent_id` é nulo enquanto o
-- chamado não tem dono. Sem esta linha, a fato precisaria de chave nula — e
-- chave nula some de todo recorte por agente, silenciosamente.
--
-- A vigência cobre o período inteiro: o membro desconhecido não tem história.
select
    {{ chave_desconhecida() }}                              as support_agent_key,
    -1                                                      as support_agent_natural_key,
    'AGT-0000'                                              as agent_code,
    'Sem'                                                   as agent_first_name,
    'agente'                                                as agent_last_name,
    'Sem agente'                                            as agent_full_name,
    'desconhecido@exemplo.invalid'                          as agent_email,
    date '{{ var("period_start") }}'                        as hired_at,
    0                                                       as handled_ticket_count,
    0                                                       as handled_event_count,
    'Desconhecido'                                          as agent_team,
    false                                                   as agent_is_active,
    false                                                   as is_deleted,
    timestamptz '{{ var("period_start") }} 00:00-03'         as valid_from,
    cast(null as timestamptz)                               as valid_to,
    true                                                    as is_current
