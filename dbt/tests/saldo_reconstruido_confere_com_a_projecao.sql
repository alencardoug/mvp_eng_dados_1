{{ config(tags=['legado_reconciliacao']) }}

-- Depende da quarentena: a exceção tolerada precisa da contrapartida, e a DAG
-- constrói `quarantine` **depois** de `trusted`. Sem a etiqueta, este teste
-- roda na tarefa de `trusted` e lê a auditoria da captura anterior — ou não
-- encontra relação nenhuma na primeira execução.

-- Critério de conclusão da Etapa 6: o saldo reconstruído do livro de eventos
-- confere com `inventory_balances`.
--
-- O livro é a fonte da verdade e o saldo é projeção (Modelo de Dados §2.10).
-- Este teste é o que impede a projeção de divergir em silêncio — que é
-- exatamente o defeito que uma projeção pode ter, e o único que ninguém percebe
-- olhando só para ela.

select
    b.source_system,
    b.warehouse_id,
    b.product_variant_id,
    b.quantity_on_hand,
    b.rebuilt_quantity_on_hand,
    b.balance_drift
from {{ ref('inventory_balances') }} b
where b.balance_drift <> 0
  -- Movimento em quarentena explica a diferença; ver a macro.
  and not {{ explicado_pela_quarentena(
        'inventory_movements', ['warehouse_id', 'product_variant_id'], 'b') }}
