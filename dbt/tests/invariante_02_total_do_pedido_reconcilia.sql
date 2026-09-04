-- Invariante 2 — o total do pedido reconcilia itens, desconto, frete e imposto.
--
-- A `CHECK total_reconcilia` do modelo garante a coerência **interna** dos
-- cinco campos do pedido. O que ela não alcança é a coerência entre o pedido e
-- os seus itens: `subtotal_amount` precisa ser a soma do que foi vendido, e
-- isso atravessa duas tabelas.

select
    order_id,
    subtotal_amount,
    items_gross_revenue_amount,
    subtotal_amount - items_gross_revenue_amount as diferenca
from {{ ref('orders') }}
where item_count > 0
  -- Um centavo de tolerância: `unit_price` tem quatro casas e o total tem duas,
  -- então o arredondamento por linha é legítimo e a igualdade exata seria falsa
  -- por construção.
  and abs(subtotal_amount - items_gross_revenue_amount) > 0.01
