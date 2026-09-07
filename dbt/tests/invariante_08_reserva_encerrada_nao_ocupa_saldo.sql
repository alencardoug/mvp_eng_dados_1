{{ config(tags=['legado_reconciliacao']) }}

-- Depende da quarentena: a exceção tolerada precisa da contrapartida, e a DAG
-- constrói `quarantine` **depois** de `trusted`. Sem a etiqueta, este teste
-- roda na tarefa de `trusted` e lê a auditoria da captura anterior — ou não
-- encontra relação nenhuma na primeira execução.

-- Invariante 8 — reserva liberada, expirada ou consumida não ocupa saldo.
--
-- O teste é `reserved_drift <= 0`, e a direção é o ponto.
--
-- `reserved_drift` é `quantity_reserved` menos a soma das reservas **ativas**.
-- Negativo é legítimo: a `CHECK reserva_limitada_ao_saldo` do modelo impede que
-- a reserva ultrapasse o saldo, então uma reserva feita quando havia estoque
-- pode ficar sem lastro depois — é venda além do estoque, e acontece.
--
-- **Positivo é a violação**: significaria que o saldo está segurando quantidade
-- que reserva ativa nenhuma justifica — ou seja, reserva encerrada que continua
-- ocupando espaço.

select
    b.source_system,
    b.warehouse_id,
    b.product_variant_id,
    b.quantity_reserved,
    b.active_reserved_quantity,
    b.reserved_drift
from {{ ref('inventory_balances') }} b
where b.reserved_drift > 0
  -- Reserva em quarentena explica a diferença; ver a macro.
  and not {{ explicado_pela_quarentena(
        'stock_reservations', ['warehouse_id', 'product_variant_id'], 'b') }}
