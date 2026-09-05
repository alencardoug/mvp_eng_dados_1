-- Chamados de atendimento.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- `order_id` é **nulo em 15% dos chamados**, por construção do gerador: nem
-- todo contato nasce de um pedido. É esse nulo que faz P16 precisar decidir a
-- âncora da janela ([ADR-0036](../../../docs/adr/0036-recompra-ancorada-no-pedido.md)) —
-- chamado sem pedido não entra na comparação, porque não há pedido a partir do
-- qual contar.

with fonte as (
    select * from {{ source('retail', 'support_tickets') }}
),

renomeado as (
    select
        id                                        as support_ticket_id,
        ticket_number,
        customer_id,
        order_id,
        shipment_id,
        assigned_agent_id,
        category                                  as ticket_category,
        priority                                  as ticket_priority,
        status                                    as ticket_status,
        subject                                   as ticket_subject,
        opened_at,
        closed_at,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
