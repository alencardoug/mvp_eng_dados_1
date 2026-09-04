-- Invariante 4 — a soma dos reembolsos nunca excede o valor capturado.
--
-- Também atravessa linhas: são vários reembolsos parciais contra uma captura.
-- Devolver mais do que se recebeu é dinheiro saindo do caixa sem contrapartida,
-- e nenhuma constraint de linha o impede.

select
    payment_id,
    payment_code,
    captured_amount,
    refunded_amount,
    refunded_amount - captured_amount as excesso
from {{ ref('payments') }}
where refunded_amount > captured_amount + 0.001
