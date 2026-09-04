-- Centros de distribuição ou locais de estoque.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'warehouses') }}
),

renomeado as (
    select
        id                                        as warehouse_id,
        code                                      as warehouse_code,
        name                                      as warehouse_name,
        city                                      as warehouse_city,
        state                                     as warehouse_state,
        country                                   as warehouse_country,
        cast(capacity_units as integer)           as capacity_units,
        is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
