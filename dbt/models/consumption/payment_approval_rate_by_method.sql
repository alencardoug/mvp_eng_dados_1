-- P09 — Qual a taxa de aprovação por meio de pagamento e parcelamento?
--
-- O denominador é a **tentativa de autorização**, não o pagamento: um pedido
-- que precisou de três tentativas conta três vezes, que é o número que a
-- operação quer ver. Contar por pagamento esconderia justamente o atrito.
--
-- A taxa é não aditiva; numerador e denominador vão ao lado, como sempre.
--
-- ── O capturado vem da captura, não da autorização (D67) ─────────────────────
-- A captura é outra transação do mesmo pagamento, e nas linhas de autorização
-- o valor capturado é zero: lido delas, a coluna era sempre zero. O capturado
-- de cada pagamento entra no grupo da **primeira autorização aprovada** dele —
-- uma vez só, para que a coluna siga aditiva entre grupos. Pagamento sem
-- autorização aprovada não tem o que capturar (invariante 3), e o teste
-- `p09_capturado_reconcilia_com_a_fato` cobra que nada fique de fora.

with capturado as (

    select source_system, payment_id, sum(captured_amount) as captured_amount
    from {{ ref('fact_payment_transaction') }}
    where transaction_type = 'capture'
    group by 1, 2

),

autorizacoes as (

    select
        f.*,
        f.approved_authorization_count = 1
        and row_number() over (
            partition by f.source_system, f.payment_id, f.approved_authorization_count
            order by f.occurred_at, f.payment_transaction_id
        ) = 1                                       as is_first_approval
    from {{ ref('fact_payment_transaction') }} f
    where f.transaction_type = 'authorization'

)

select
    d.year_month,
    d.year_number,
    d.month_number,
    pm.payment_method_name,
    pm.method_type,
    a.installments,
    a.is_instalment_plan,

    sum(a.authorization_count)                      as authorization_attempt_count,
    sum(a.approved_authorization_count)             as approved_authorization_count,
    round(
        cast(100.0 as numeric) * sum(a.approved_authorization_count)
        / nullif(sum(a.authorization_count), 0), 2
    )                                               as approval_rate_pct,
    sum(a.authorized_amount)                        as authorized_amount,
    coalesce({{ agregado_onde('sum', "c.captured_amount", "a.is_first_approval") }}, 0)
                                                    as captured_amount
from autorizacoes a
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_payment_method') }} pm using (payment_method_key)
left join capturado c
    on c.source_system = a.source_system and c.payment_id = a.payment_id
group by 1, 2, 3, 4, 5, 6, 7
