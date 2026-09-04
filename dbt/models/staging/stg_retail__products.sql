-- Produto conceitual vendido pelo marketplace.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'products') }}
),

renomeado as (
    select
        id                                        as product_id,
        product_code,
        category_id                               as product_category_id,
        brand_id,
        name                                      as product_name,
        description                               as product_description,
        status                                    as product_status,
        launched_at,

        -- Marcas de origem e de carga. `ingested_at` é o carimbo do Airbyte;
        -- `source_updated_at` é o tempo de negócio e o cursor do ADR-0015.
        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
