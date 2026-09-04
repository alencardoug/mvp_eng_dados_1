-- Fato de compra.
--
-- **Grão: um item de uma ordem de compra.** O que foi pedido a um fornecedor,
-- e o que dele chegou.
--
-- `quantity_outstanding` é a medida que a operação olha: o que foi pedido e
-- ainda não entrou. Ela é aditiva e some sozinha quando a ordem fecha.

select
    {{ dbt_utils.generate_surrogate_key(['i.purchase_order_item_id']) }} as purchase_order_item_key,

    d.date_key,
    s.supplier_key,
    p.product_key,
    cat.category_key,

    i.purchase_order_item_id,
    i.purchase_order_id,
    o.po_number,
    o.purchase_order_status,
    o.ordered_at,
    o.expected_at,
    i.first_received_at,
    i.last_received_at,
    i.is_fully_received,
    i.is_not_received,
    o.is_cancelled,

    i.quantity_ordered,
    i.quantity_received,
    i.quantity_outstanding,
    i.unit_cost,
    i.ordered_cost_amount,
    i.received_cost_amount
from {{ ref('purchase_order_items') }} i
join {{ ref('purchase_orders') }} o on o.purchase_order_id = i.purchase_order_id
join {{ ref('dim_date') }} d
  on d.full_date = cast(o.ordered_at at time zone 'America/Sao_Paulo' as date)
join {{ ref('dim_supplier') }} s on s.supplier_natural_key = o.supplier_id

-- Versão do SKU vigente no momento da compra.
join {{ ref('dim_product') }} p
  on p.product_natural_key = i.product_variant_id
 and o.ordered_at >= p.valid_from
 and (p.valid_to is null or o.ordered_at < p.valid_to)

join {{ ref('dim_category') }} cat on cat.category_natural_key = p.product_category_id
