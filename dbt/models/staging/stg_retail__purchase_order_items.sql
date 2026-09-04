-- Produtos, quantidades e custos solicitados ao fornecedor.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'purchase_order_items') }}
),

renomeado as (
    select
        id                                        as purchase_order_item_id,
        purchase_order_id,
        product_variant_id,
        cast(quantity_ordered as integer)         as quantity_ordered,
        unit_cost,
        total_cost,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
