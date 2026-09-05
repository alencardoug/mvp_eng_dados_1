-- Rastro da remessa: coleta, trânsito, saída para entrega, tentativa, chegada
-- e devolução.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- **Este livro é a fonte da data de entrega realizada** (ADR-0034), não um
-- rastro descritivo ao lado de `shipments.delivered_at`. A distinção importa
-- porque o livro carrega o que a coluna não carrega: a tentativa frustrada, o
-- trânsito multi-trecho e a ordem `delivered` → `returned`, que é o que separa
-- uma entrega devolvida depois de uma entrega que não houve.

-- Deduplicação de entrega ao menos uma vez, pelo mesmo motivo de
-- `stg_retail__payment_transactions`: o modo `append` do ADR-0015 relê a
-- fronteira do cursor e reescreve linhas já entregues.
with fonte as (
    select distinct on (id) *
    from {{ source('retail', 'delivery_events') }}
    order by id, _airbyte_extracted_at desc
),

renomeado as (
    select
        id                                        as delivery_event_id,
        shipment_id,
        event_type                                as delivery_event_type,
        occurred_at,
        location                                  as event_location,
        description                               as event_description,

        -- Livro de eventos: sem `updated_at` e sem `deleted_at` de propósito.
        created_at                                as source_created_at,
        false                                     as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
