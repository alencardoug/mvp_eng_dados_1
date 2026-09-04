-- Saldo atual de cada SKU por armazém — projeção do livro de eventos.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'inventory_balances') }}
),

renomeado as (
    select
        id                                        as inventory_balance_id,
        warehouse_id,
        product_variant_id,
        cast(quantity_on_hand as integer)         as quantity_on_hand,
        cast(quantity_reserved as integer)        as quantity_reserved,
        cast(quantity_available as integer)       as quantity_available,
        last_movement_at,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
