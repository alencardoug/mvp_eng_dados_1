-- Cadastro sintético dos fornecedores.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'suppliers') }}
),

renomeado as (
    select
        id                                        as supplier_id,
        supplier_code,
        legal_name                                as supplier_legal_name,
        trade_name                                as supplier_trade_name,
        document                                  as supplier_document,
        contact_email                             as supplier_contact_email,
        country                                   as supplier_country,
        cast(payment_terms_days as integer)       as payment_terms_days,
        is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
