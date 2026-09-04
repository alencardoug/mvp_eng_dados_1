-- SKU com produto, categoria e marca conformados — o grão de `dim_product`.
--
-- A hierarquia de categorias é achatada aqui, e não na dimensão: a árvore tem
-- no máximo três níveis (`CHECK depth <= 3` no modelo transacional), então dois
-- `left join` bastam e a consulta recursiva não se justifica. Se a profundidade
-- crescer, este é o modelo que muda — e só ele.

with variantes as (

    select * from {{ ref('stg_retail__product_variants') }}

),

produtos as (

    select * from {{ ref('stg_retail__products') }}

),

categorias as (

    select * from {{ ref('stg_retail__product_categories') }}

),

marcas as (

    select * from {{ ref('stg_retail__brands') }}

),

hierarquia as (

    select
        c.product_category_id,
        c.product_category_name,
        c.category_depth,
        -- Raiz da árvore, seja qual for o nível em que a folha está.
        coalesce(avo.product_category_name, pai.product_category_name, c.product_category_name)
            as root_category_name,
        case c.category_depth
            when 2 then pai.product_category_name
            when 1 then c.product_category_name
        end as sub_category_name,
        c.is_deleted as category_is_deleted
    from categorias c
    left join categorias pai on pai.product_category_id = c.parent_product_category_id
    left join categorias avo on avo.product_category_id = pai.parent_product_category_id

)

select
    v.product_variant_id,
    v.sku,
    v.variant_size,
    v.variant_color,
    v.variant_package,
    v.barcode,
    v.weight_grams,
    v.is_active                                       as variant_is_active,

    p.product_id,
    p.product_code,
    p.product_name,
    p.product_status,
    p.launched_at,

    h.product_category_id,
    h.product_category_name                           as leaf_category_name,
    h.sub_category_name,
    h.root_category_name,
    h.category_depth,

    b.brand_id,
    b.brand_name,
    b.brand_country,

    -- Um SKU está excluído se ele próprio, o produto ou a categoria estiverem.
    -- É a leitura conservadora: o que sumiu do catálogo por qualquer caminho
    -- fica marcado, e nada é filtrado (ADR-0029).
    (v.is_deleted or p.is_deleted or coalesce(h.category_is_deleted, false)) as is_deleted,
    v.is_deleted                                      as variant_is_deleted,
    p.is_deleted                                      as product_is_deleted,

    v.source_created_at,
    greatest(v.source_updated_at, p.source_updated_at) as source_updated_at
from variantes v
join produtos p on p.product_id = v.product_id
join hierarquia h on h.product_category_id = p.product_category_id
left join marcas b on b.brand_id = p.brand_id
