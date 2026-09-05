-- Rastro do chamado — criação, atribuição, mensagem, mudança de estado,
-- resolução e reabertura.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- `agent_id` nulo é **autor cliente**, não dado faltando: é assim que se separa
-- o que o atendimento respondeu do que o cliente escreveu.

with fonte as (
    select distinct on (id) *
    from {{ source('retail', 'ticket_events') }}
    order by id, _airbyte_extracted_at desc
),

renomeado as (
    select
        id                                        as ticket_event_id,
        ticket_id                                 as support_ticket_id,
        agent_id                                  as support_agent_id,
        event_type                                as ticket_event_type,
        occurred_at,
        message                                   as ticket_message,

        created_at                                as source_created_at,
        false                                     as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
