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
    warehouse_id,
    product_variant_id,
    quantity_reserved,
    active_reserved_quantity,
    reserved_drift
from {{ ref('inventory_balances') }}
where reserved_drift > 0
