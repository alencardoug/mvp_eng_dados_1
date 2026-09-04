-- Quantidades efetivamente recebidas por item da ordem.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'goods_receipt_items') }}
),

renomeado as (
    select
        id                                        as goods_receipt_item_id,
        goods_receipt_id,
        purchase_order_item_id,
        cast(quantity_received as integer)        as quantity_received,
        unit_cost,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
