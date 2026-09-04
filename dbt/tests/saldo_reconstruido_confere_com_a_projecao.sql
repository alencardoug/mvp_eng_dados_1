-- Critério de conclusão da Etapa 6: o saldo reconstruído do livro de eventos
-- confere com `inventory_balances`.
--
-- O livro é a fonte da verdade e o saldo é projeção (Modelo de Dados §2.10).
-- Este teste é o que impede a projeção de divergir em silêncio — que é
-- exatamente o defeito que uma projeção pode ter, e o único que ninguém percebe
-- olhando só para ela.

select
    warehouse_id,
    product_variant_id,
    quantity_on_hand,
    rebuilt_quantity_on_hand,
    balance_drift
from {{ ref('inventory_balances') }}
where balance_drift <> 0
