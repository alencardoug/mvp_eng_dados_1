-- Campanhas de marketing, com objetivo e vigência.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'campaigns') }}
),

renomeado as (
    select
        id                                        as campaign_id,
        code                                      as campaign_code,
        name                                      as campaign_name,
        objective                                 as campaign_objective,
        valid_from                                as campaign_valid_from,
        valid_to                                  as campaign_valid_to,
        budget_amount,
        is_active                                 as campaign_is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
