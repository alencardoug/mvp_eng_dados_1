-- Intenção de pagamento, com o que efetivamente aconteceu com ela.
--
-- **Invariantes 3 e 4 nascem aqui.** Elas atravessam linhas — capturado contra
-- autorizado, reembolsado contra capturado — e por isso o modelo transacional
-- não as expressa como `CHECK`. Agregar os totais neste grão é o que permite
-- testá-las com um `where` em vez de uma consulta correlacionada.

with pagamentos as (

    {{ empilhado('payments') }}

),

operacoes as (

    select
        source_system,
        payment_id,
        count(*)                                    as transaction_count,
        count(*) filter (where is_authorization)     as authorization_count,
        count(*) filter (where is_authorization and is_approved) as approved_authorization_count,
        sum(authorized_amount)                       as authorized_amount,
        sum(captured_amount)                         as captured_amount,
        sum(refunded_amount)                         as refunded_amount,
        min(occurred_at) filter (where is_authorization and is_approved) as first_authorized_at,
        min(occurred_at) filter (where is_capture and is_approved)       as first_captured_at
    from {{ ref('payment_transactions') }}
    group by source_system, payment_id

)

select
    p.source_system,
    p.payment_id,
    p.payment_code,
    p.order_id,
    p.payment_method_id,
    p.payment_status,
    p.payment_amount,
    p.currency,
    p.installments,
    p.authorized_at,
    p.captured_at,

    coalesce(o.transaction_count, 0)                as transaction_count,
    coalesce(o.authorization_count, 0)              as authorization_count,
    coalesce(o.approved_authorization_count, 0)     as approved_authorization_count,
    coalesce(o.authorized_amount, 0)                as authorized_amount,
    coalesce(o.captured_amount, 0)                  as captured_amount,
    coalesce(o.refunded_amount, 0)                  as refunded_amount,
    -- O que sobrou de fato: capturado menos devolvido. É este o número que
    -- reconcilia com a receita, não o capturado bruto.
    coalesce(o.captured_amount, 0) - coalesce(o.refunded_amount, 0) as net_captured_amount,
    o.first_authorized_at,
    o.first_captured_at,

    p.payment_status in ('captured', 'refunded')    as is_captured,
    p.payment_status = 'failed'                     as is_failed,
    p.installments > 1                              as is_instalment_plan,

    p.is_deleted,
    p.source_created_at,
    p.source_updated_at
from pagamentos p
left join operacoes o on o.source_system = p.source_system and o.payment_id = p.payment_id
