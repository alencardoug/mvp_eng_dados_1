-- Categoria comercial — SCD tipo 1.
--
-- O Modelo de Dados §3.2 a declara como "SCD tipo 2 **quando aplicável**", e
-- aqui ela não é: a hierarquia do catálogo é estável, e a mudança que importaria
-- — um produto trocar de categoria — já é historizada em `dim_product`, que é
-- tipo 2. Historizar a categoria também guardaria a mesma informação duas
-- vezes.

with categorias as (

    select distinct
        product_category_id,
        leaf_category_name,
        sub_category_name,
        root_category_name,
        category_depth
    from {{ ref('product_skus') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['product_category_id']) }} as category_key,
    product_category_id                                 as category_natural_key,
    leaf_category_name                                  as category_name,
    coalesce(sub_category_name, leaf_category_name)     as sub_category_name,
    root_category_name,
    category_depth
from categorias
