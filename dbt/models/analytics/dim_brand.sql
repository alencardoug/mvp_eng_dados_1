-- Marca — SCD tipo 1 (Modelo de Dados §3.2).
--
-- A marca chega aqui pelo SKU, não por modelo próprio em `trusted`: ela é
-- atributo do catálogo, e `product_skus` já a conforma. `distinct on` mantém a
-- dimensão com uma linha por marca mesmo que o catálogo cresça.

with marcas as (

    select distinct on (brand_id)
        brand_id,
        brand_name,
        brand_country
    from {{ ref('product_skus') }}
    where brand_id is not null
    order by brand_id, product_variant_id

)

select
    {{ dbt_utils.generate_surrogate_key(['brand_id']) }} as brand_key,
    brand_id                                            as brand_natural_key,
    brand_name,
    brand_country
from marcas
