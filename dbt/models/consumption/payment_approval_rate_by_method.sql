-- P09 — Qual a taxa de aprovação por meio de pagamento e parcelamento?
--
-- O denominador é a **tentativa de autorização**, não o pagamento: um pedido
-- que precisou de três tentativas conta três vezes, que é o número que a
-- operação quer ver. Contar por pagamento esconderia justamente o atrito.
--
-- A taxa é não aditiva; numerador e denominador vão ao lado, como sempre.

select
    d.year_month,
    d.year_number,
    d.month_number,
    pm.payment_method_name,
    pm.method_type,
    f.installments,
    f.is_instalment_plan,

    sum(f.authorization_count)                      as authorization_attempt_count,
    sum(f.approved_authorization_count)             as approved_authorization_count,
    round(
        100.0 * sum(f.approved_authorization_count)
        / nullif(sum(f.authorization_count), 0), 2
    )                                               as approval_rate_pct,
    sum(f.authorized_amount)                        as authorized_amount,
    sum(f.captured_amount)                          as captured_amount
from {{ ref('fact_payment_transaction') }} f
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_payment_method') }} pm using (payment_method_key)
where f.transaction_type = 'authorization'
group by 1, 2, 3, 4, 5, 6, 7
