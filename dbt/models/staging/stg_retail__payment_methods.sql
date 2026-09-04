-- Meios de pagamento aceitos; nenhuma credencial é armazenada.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'payment_methods') }}
),

renomeado as (
    select
        id                                        as payment_method_id,
        code                                      as payment_method_code,
        name                                      as payment_method_name,
        method_type,
        is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
