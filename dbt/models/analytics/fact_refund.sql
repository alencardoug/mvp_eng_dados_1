-- Fato de reembolso.
--
-- **Grão: um reembolso realizado.** Separada de `fact_payment_transaction`
-- porque o reembolso tem atributos próprios — motivo, estado, se é integral —
-- que não existem nas outras operações. Guardá-los na fato de transação
-- deixaria três quartos das linhas com colunas nulas.

select
    {{ dbt_utils.generate_surrogate_key(['r.source_system', 'r.refund_id']) }}
                                                    as refund_key,
    r.source_system,

    d.date_key,
    pm.payment_method_key,
    c.customer_key,
    ch.sales_channel_key,

    r.refund_id,
    r.refund_code,
    r.payment_transaction_id,
    r.payment_id,
    r.order_id,
    o.order_number,
    r.refund_reason,
    r.refund_status,
    r.refunded_at,
    r.is_completed,
    r.is_full_refund,

    1                                               as refund_count,
    r.refund_amount,
    r.captured_amount                               as originally_captured_amount,
    case when r.is_completed then r.refund_amount else 0 end as completed_refund_amount
from {{ ref('refunds') }} r
join {{ ref('orders') }} o
  on o.source_system = r.source_system and o.order_id = r.order_id
join {{ ref('payments') }} p
  on p.source_system = r.source_system and p.payment_id = r.payment_id
join {{ ref('dim_date') }} d
  on d.full_date = cast(coalesce(r.refunded_at, r.source_created_at) at time zone 'America/Sao_Paulo' as date)
join {{ ref('dim_payment_method') }} pm
  on pm.source_system = p.source_system
 and pm.payment_method_natural_key = p.payment_method_id
join {{ ref('dim_sales_channel') }} ch
  on ch.source_system = o.source_system
 and ch.sales_channel_natural_key = o.sales_channel_id
join {{ ref('dim_customer') }} c
  on c.source_system = o.source_system
 and c.customer_natural_key = o.customer_id
 and o.placed_at >= c.valid_from
 and (c.valid_to is null or o.placed_at < c.valid_to)
