-- Agentes de atendimento, com equipe e data de contratação.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'support_agents') }}
),

renomeado as (
    select
        id                                        as support_agent_id,
        agent_code,
        first_name                                as agent_first_name,
        last_name                                 as agent_last_name,
        first_name || ' ' || last_name            as agent_full_name,
        email                                     as agent_email,
        team                                      as agent_team,
        hired_at,
        is_active                                 as agent_is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
