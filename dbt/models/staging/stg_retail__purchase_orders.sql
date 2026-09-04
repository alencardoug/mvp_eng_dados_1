-- Cabeçalho das ordens de compra enviadas a fornecedores.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'purchase_orders') }}
),

renomeado as (
    select
        id                                        as purchase_order_id,
        po_number,
        supplier_id,
        status                                    as purchase_order_status,
        ordered_at,
        expected_at,
        currency,
        total_amount                              as purchase_order_total_amount,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
