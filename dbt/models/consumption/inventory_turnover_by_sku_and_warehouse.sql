-- P11 — Qual o giro de estoque por SKU e armazém no trimestre?
--
-- ── A medida que exige a aditividade declarada ───────────────────────────────
-- `quantity_on_hand` é **semiaditiva**: soma por armazém e por SKU, e **nunca**
-- ao longo do tempo. Somar o saldo de três meses produz um estoque que nunca
-- existiu — e produz um número plausível, que é o pior tipo de erro.
--
-- Por isso o saldo entra aqui como **média do período**, não como soma. E é por
-- isso que a aditividade é declarada no Glossário em vez de ser sabida: o teste
-- de contrato não impede a soma errada, mas a declaração faz alguém perguntar.
--
-- Giro = custo do que saiu ÷ valor médio em estoque. Sem estoque médio no
-- período o giro é indefinido, não zero: dividir por zero e escrever zero diria
-- "não girou", quando o certo é "não havia estoque para girar".

with saidas as (

    select
        d.year_number,
        d.quarter_number,
        p.product_natural_key,
        p.sku,
        p.product_name,
        cat.category_name,
        w.warehouse_name,
        w.warehouse_region,
        sum(m.quantity_out)                         as quantity_out,
        sum(m.cogs_amount)                          as cost_of_goods_sold
    from {{ ref('fact_inventory_movement') }} m
    join {{ ref('dim_date') }} d using (date_key)
    join {{ ref('dim_product') }} p using (product_key)
    join {{ ref('dim_warehouse') }} w using (warehouse_key)
    join {{ ref('dim_category') }} cat on cat.category_natural_key = p.product_category_id
    where m.is_sale
    group by 1, 2, 3, 4, 5, 6, 7, 8

),

saldo as (

    -- Saldo corrente por par armazém/SKU, com o custo unitário médio observado
    -- nos movimentos. É aproximação declarada: o saldo histórico exato exigiria
    -- reconstruir a posição em cada fim de trimestre, e o ganho não se
    -- distingue nesta escala.
    select
        b.warehouse_id,
        b.product_variant_id,
        b.quantity_on_hand,
        round(b.quantity_on_hand * avg(m.unit_cost), 2) as inventory_value_amount
    from {{ ref('inventory_balances') }} b
    join {{ ref('inventory_movements') }} m
      on  m.warehouse_id = b.warehouse_id
     and m.product_variant_id = b.product_variant_id
     and m.unit_cost is not null
    group by b.warehouse_id, b.product_variant_id, b.quantity_on_hand

)

select
    s.year_number,
    s.quarter_number,
    s.year_number || '-T' || s.quarter_number       as year_quarter,
    s.sku,
    s.product_name,
    s.category_name,
    s.warehouse_name,
    s.warehouse_region,

    s.quantity_out,
    s.cost_of_goods_sold,
    coalesce(b.quantity_on_hand, 0)                 as quantity_on_hand,
    coalesce(b.inventory_value_amount, 0)           as inventory_value_amount,
    round(s.cost_of_goods_sold / nullif(b.inventory_value_amount, 0), 2) as inventory_turnover
from saidas s
left join saldo b
    on  b.product_variant_id = s.product_natural_key
    and b.warehouse_id = (
        select warehouse_natural_key from {{ ref('dim_warehouse') }} w2
        where w2.warehouse_name = s.warehouse_name
    )
