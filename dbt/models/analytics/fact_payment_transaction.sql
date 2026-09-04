-- Fato de operação financeira.
--
-- **Grão: uma tentativa ou operação financeira.** Autorização, captura, estorno
-- ou reembolso, cada uma na sua linha, tenha dado certo ou não.
--
-- ── Por que a operação recusada fica ─────────────────────────────────────────
-- É tentador guardar só o que deu certo. Mas "quantas tentativas foram precisas
-- para receber" é a pergunta P09, e ela só existe se a recusa estiver aqui. Uma
-- fato que guarda apenas o sucesso responde quanto entrou e nunca quanto custou
-- entrar.
--
-- ── Por que as medidas são separadas por tipo ────────────────────────────────
-- `transaction_amount` é o valor da operação, seja ela qual for — somá-lo entre
-- tipos daria autorização mais captura mais reembolso, que não é dinheiro
-- nenhum. As colunas por tipo já vêm zeradas fora do seu caso, e por isso são
-- aditivas em qualquer recorte.

select
    {{ dbt_utils.generate_surrogate_key(['t.payment_transaction_id']) }} as payment_transaction_key,

    d.date_key,
    pm.payment_method_key,
    c.customer_key,
    ch.sales_channel_key,

    t.payment_transaction_id,
    t.transaction_code,
    t.payment_id,
    p.payment_code,
    p.order_id,
    o.order_number,
    t.transaction_type,
    t.transaction_result,
    t.gateway_response_code,
    t.occurred_at,
    p.installments,
    p.is_instalment_plan,

    -- ── Medidas, todas aditivas ──────────────────────────────────────────────
    1                                               as attempt_count,
    case when t.is_approved then 1 else 0 end       as approved_count,
    case when t.is_authorization then 1 else 0 end  as authorization_count,
    case when t.is_authorization and t.is_approved then 1 else 0 end
                                                    as approved_authorization_count,
    t.transaction_amount,
    t.authorized_amount,
    t.captured_amount,
    t.refunded_amount
from {{ ref('payment_transactions') }} t
join {{ ref('payments') }} p on p.payment_id = t.payment_id
join {{ ref('orders') }} o on o.order_id = p.order_id
join {{ ref('dim_date') }} d
  on d.full_date = cast(t.occurred_at at time zone 'America/Sao_Paulo' as date)
join {{ ref('dim_payment_method') }} pm on pm.payment_method_natural_key = p.payment_method_id
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_natural_key = o.sales_channel_id

-- Versão do cliente vigente quando o pedido foi feito, e não quando a transação
-- ocorreu: a transação pertence ao pedido, e é o pedido que define o cliente.
join {{ ref('dim_customer') }} c
  on c.customer_natural_key = o.customer_id
 and o.placed_at >= c.valid_from
 and (c.valid_to is null or o.placed_at < c.valid_to)
