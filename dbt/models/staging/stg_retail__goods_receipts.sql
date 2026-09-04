-- Registro do recebimento físico de uma ordem de compra.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'goods_receipts') }}
),

renomeado as (
    select
        id                                        as goods_receipt_id,
        receipt_number,
        purchase_order_id,
        warehouse_id,
        received_at,
        status                                    as goods_receipt_status,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
