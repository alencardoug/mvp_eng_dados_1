-- Quantidades de itens de pedido incluídas em cada remessa.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'shipment_items') }}
),

renomeado as (
    select
        id                                        as shipment_item_id,
        shipment_id,
        order_item_id,
        cast(quantity as integer)                 as quantity_shipped,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
