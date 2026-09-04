-- Invariante 3 — uma captura nunca excede o valor autorizado.
--
-- Atravessa linhas de `payment_transactions`: a autorização é um evento e a
-- captura é outro, e o modelo transacional não consegue compará-los em uma
-- `CHECK`. Capturar mais do que se autorizou é o defeito financeiro clássico —
-- passa por toda validação de linha e só aparece na conciliação bancária.

select
    payment_id,
    payment_code,
    authorized_amount,
    captured_amount,
    captured_amount - authorized_amount as excesso
from {{ ref('payments') }}
where captured_amount > authorized_amount + 0.001
