-- P03 — Quais os 25 SKUs de maior receita, e quanto cada um pesa na categoria?
--
-- A participação na categoria é **não aditiva**: somar as frações de dois SKUs
-- só faz sentido dentro da mesma categoria, e nunca entre categorias
-- diferentes.
--
-- O corte em 25 é a pergunta, não uma limitação técnica: a view responde "quais
-- são os 25 maiores", e mudar o número é mudar a pergunta — o que nasce como
-- nova versão da view (ADR-0018).

with por_sku as (

    select
        p.product_natural_key,
        p.sku,
        p.product_name,
        cat.category_name,
        cat.root_category_name,
        b.brand_name,
        bool_or(p.is_deleted)                       as is_deleted,
        sum(f.quantity)                             as unit_count,
        sum(f.net_revenue_amount)                   as net_revenue_amount
    from {{ ref('fact_sales_order_item') }} f
    join {{ ref('dim_product') }} p using (product_key)
    join {{ ref('dim_category') }} cat using (category_key)
    left join {{ ref('dim_brand') }} b using (brand_key)
    where f.is_realised
    group by 1, 2, 3, 4, 5, 6

),

por_categoria as (

    select
        category_name,
        sum(net_revenue_amount)                     as category_net_revenue_amount
    from por_sku
    group by 1

),

classificado as (

    select
        s.*,
        c.category_net_revenue_amount,
        rank() over (order by s.net_revenue_amount desc) as revenue_rank
    from por_sku s
    join por_categoria c using (category_name)

)

select
    revenue_rank,
    product_natural_key,
    sku,
    product_name,
    category_name,
    root_category_name,
    brand_name,
    is_deleted,
    unit_count,
    net_revenue_amount,
    category_net_revenue_amount,
    round(100 * net_revenue_amount / nullif(category_net_revenue_amount, 0), 2)
                                                    as category_revenue_share_pct
from classificado
where revenue_rank <= 25
