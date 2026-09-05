-- Transições de estado do pedido, uma linha por mudança.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- É o grão de `fact_order_status_event`. `from_status` é nulo na criação do
-- pedido — a primeira linha não vem de estado nenhum —, e a origem garante por
-- `check` que origem e destino nunca são iguais: transição que não transiciona
-- não é registrada.

with fonte as (
    select distinct on (id) *
    from {{ source('retail', 'order_status_history') }}
    order by id, _airbyte_extracted_at desc
),

renomeado as (
    select
        id                                        as order_status_event_id,
        order_id,
        from_status,
        to_status,
        changed_at,
        reason                                    as change_reason,

        created_at                                as source_created_at,
        false                                     as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
