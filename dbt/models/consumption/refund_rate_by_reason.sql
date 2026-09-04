-- P10 — Qual o valor reembolsado como fração do capturado, por motivo e mês?
--
-- O denominador é o capturado **do mês do reembolso**, não do mês da venda: a
-- pergunta é "quanto do que entrou saiu de volta", e as duas pontas precisam
-- ser do mesmo período para a fração significar algo.
--
-- Também é *drill across*: reembolso e captura são fatos diferentes, agregadas
-- separadamente e combinadas na granularidade comum.

with reembolsos as (

    select
        d.year_month,
        d.year_number,
        d.month_number,
        pm.payment_method_name,
        coalesce(f.refund_reason, 'Sem motivo registrado') as refund_reason,
        sum(f.refund_count)                         as refund_count,
        sum(f.completed_refund_amount)              as refunded_amount
    from {{ ref('fact_refund') }} f
    join {{ ref('dim_date') }} d using (date_key)
    join {{ ref('dim_payment_method') }} pm using (payment_method_key)
    group by 1, 2, 3, 4, 5

),

capturas as (

    select
        d.year_month,
        pm.payment_method_name,
        sum(t.captured_amount)                      as captured_amount
    from {{ ref('fact_payment_transaction') }} t
    join {{ ref('dim_date') }} d using (date_key)
    join {{ ref('dim_payment_method') }} pm using (payment_method_key)
    group by 1, 2

)

select
    r.year_month,
    r.year_number,
    r.month_number,
    r.payment_method_name,
    r.refund_reason,
    r.refund_count,
    r.refunded_amount,
    coalesce(c.captured_amount, 0)                  as captured_amount,
    round(100.0 * r.refunded_amount / nullif(c.captured_amount, 0), 2) as refund_rate_pct
from reembolsos r
left join capturas c
    on  c.year_month = r.year_month
    and c.payment_method_name = r.payment_method_name
