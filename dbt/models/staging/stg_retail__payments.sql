-- Intenção de pagamento associada ao pedido.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'payments') }}
),

renomeado as (
    select
        id                                        as payment_id,
        payment_code,
        order_id,
        payment_method_id,
        status                                    as payment_status,
        amount                                    as payment_amount,
        currency,
        cast(installments as integer)             as installments,
        authorized_at,
        captured_at,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
