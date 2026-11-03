-- O capturado da P09 é todo o capturado da fato, nem mais nem menos (D67).
--
-- A view atribui a captura de cada pagamento ao grupo da primeira autorização
-- aprovada dele. Se um pagamento capturasse sem autorização aprovada, ou se a
-- atribuição contasse uma captura duas vezes, os dois totais divergiriam — e a
-- linha devolvida diz quanto.

with na_view as (

    select coalesce(sum(captured_amount), 0) as captured_amount
    from {{ ref('payment_approval_rate_by_method') }}

),

na_fato as (

    select coalesce(sum(captured_amount), 0) as captured_amount
    from {{ ref('fact_payment_transaction') }}
    where transaction_type = 'capture'

)

select v.captured_amount as na_view, f.captured_amount as na_fato
from na_view v cross join na_fato f
where v.captured_amount <> f.captured_amount
