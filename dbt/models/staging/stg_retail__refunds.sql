-- Reembolsos totais ou parciais de transações capturadas.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'refunds') }}
),

renomeado as (
    select
        id                                        as refund_id,
        refund_code,
        payment_transaction_id,
        amount                                    as refund_amount,
        reason                                    as refund_reason,
        status                                    as refund_status,
        refunded_at,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
