-- Hierarquia de categorias do catálogo, até três níveis.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'product_categories') }}
),

renomeado as (
    select
        id                                        as product_category_id,
        code                                      as product_category_code,
        name                                      as product_category_name,
        parent_id                                 as parent_product_category_id,
        depth                                     as category_depth,
        is_active,

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
