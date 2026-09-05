-- Transportadoras contratadas, com a modalidade de serviço que cada uma presta.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'carriers') }}
),

renomeado as (
    select
        id                                        as carrier_id,
        code                                      as carrier_code,
        name                                      as carrier_name,
        service_level,
        tracking_url_template,
        is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
