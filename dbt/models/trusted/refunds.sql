-- Reembolsos, ligados ao pagamento e ao pedido que os originaram.
--
-- O reembolso aponta para a **transação de captura** que está sendo revertida,
-- não para o pagamento: é a captura que tem dinheiro para devolver, e é contra
-- ela que a invariante 4 se verifica.

with reembolsos as (

    select * from {{ ref('stg_retail__refunds') }}

),

capturas as (

    select
        payment_transaction_id,
        payment_id,
        transaction_amount                          as captured_amount,
        occurred_at                                 as captured_at
    from {{ ref('payment_transactions') }}
    where is_capture and is_approved

)

select
    r.refund_id,
    r.refund_code,
    r.payment_transaction_id,
    c.payment_id,
    p.order_id,
    r.refund_amount,
    r.refund_reason,
    r.refund_status,
    r.refunded_at,

    c.captured_amount,
    c.captured_at,
    r.refund_status = 'completed'                   as is_completed,
    -- Reembolso integral ou parcial: a distinção interessa porque a devolução
    -- parcial costuma ser ajuste, e a integral costuma ser cancelamento.
    r.refund_amount >= c.captured_amount            as is_full_refund,

    r.is_deleted,
    r.source_created_at,
    r.source_updated_at
from reembolsos r
left join capturas c on c.payment_transaction_id = r.payment_transaction_id
left join {{ ref('payments') }} p on p.payment_id = c.payment_id
