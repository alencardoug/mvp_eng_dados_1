-- Item de pedido com a receita já calculada — o grão de `fact_sales_order_item`.
--
-- **É aqui que a receita líquida é definida**, uma vez só, para que nenhum
-- modelo adiante a recalcule de outro jeito. A definição é a do Glossário de
-- Negócio: quantidade × preço praticado, menos o desconto da linha. Frete e
-- imposto ficam de fora — o primeiro é valor de pedido e não de item, o segundo
-- é dedução, não receita.

with itens as (

    select * from {{ ref('stg_retail__order_items') }}

)

select
    order_item_id,
    order_id,
    product_variant_id,
    quantity,
    unit_price,

    -- `unit_price` tem quatro casas e o valor transacionado tem duas: o
    -- arredondamento é obrigatório, e fazê-lo aqui evita que cada consumidor
    -- arredonde em um ponto diferente da conta.
    round(quantity * unit_price, 2)                          as gross_revenue_amount,
    discount_amount,
    round(quantity * unit_price, 2) - discount_amount        as net_revenue_amount,
    tax_amount,
    line_total_amount,

    is_deleted,
    source_created_at,
    source_updated_at
from itens
