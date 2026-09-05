-- Fato de resgate de cupom.
--
-- **Grão: um uso de cupom.** Um por pedido, garantido por índice único na
-- origem — é o que torna o desconto atribuível sem ambiguidade.
--
-- ── Duas âncoras temporais, de propósito ────────────────────────────────────
-- O **cupom** entra pela versão vigente no instante do **resgate**: a regra que
-- valeu é a que estava em vigor quando o cliente usou. O **cliente** entra pela
-- versão vigente no instante da **venda**, que é a mesma âncora de
-- `fact_sales_order_item` — sem isso, a mesma compra apareceria sob duas
-- versões diferentes do mesmo cliente em duas fatos.
--
-- ── O valor do pedido está aqui, e pode ────────────────────────────────────
-- `order_subtotal_amount` é de grão de pedido, e normalmente não caberia numa
-- fato de outro grão. Cabe aqui porque a relação é **um para um**: um resgate
-- por pedido, um pedido por resgate. Não há fan-out a multiplicar, e é o
-- denominador natural de "quanto do pedido o cupom descontou".

with resgates as (

    select * from {{ ref('coupon_redemptions') }}

),

base as (

    select
        r.*,
        o.customer_id                                   as order_customer_id,
        o.sales_channel_id,
        o.order_number,
        o.is_realised,
        cast(r.redeemed_at at time zone 'America/Sao_Paulo' as date) as redemption_date
    from resgates r
    join {{ ref('orders') }} o on o.order_id = r.order_id

)

select
    {{ dbt_utils.generate_surrogate_key(['b.coupon_redemption_id']) }} as coupon_redemption_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    d.date_key,
    cp.coupon_key,
    cm.campaign_key,
    cu.customer_key,
    ch.sales_channel_key,
    coalesce(g.geography_key, {{ chave_desconhecida() }}) as geography_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    b.coupon_redemption_id,
    b.coupon_id,
    b.order_id,
    b.order_number,
    b.coupon_code,
    b.discount_type,
    b.campaign_objective,
    b.redemption_sequence,
    b.redeemed_at,
    b.placed_at,

    -- ── Elegibilidade (invariante 12) ────────────────────────────────────────
    b.is_within_validity,
    b.is_above_minimum,
    b.is_within_limit,
    b.is_discount_bounded,
    b.is_within_validity and b.is_above_minimum and b.is_within_limit
                                                        as is_eligible,
    b.order_is_cancelled,
    b.is_realised,

    -- ── Medidas ──────────────────────────────────────────────────────────────
    1                                                   as redemption_count,
    b.coupon_discount_amount,
    b.order_subtotal_amount,
    b.order_total_amount,
    case
        when b.order_subtotal_amount > 0
        then b.coupon_discount_amount / b.order_subtotal_amount
    end::numeric(12, 6)                                 as discount_share_of_order
from base b
join {{ ref('dim_date') }} d on d.full_date = b.redemption_date

-- Versão do cupom vigente no instante do resgate.
join {{ ref('dim_coupon') }} cp
  on cp.coupon_natural_key = b.coupon_id
 and b.redeemed_at >= cp.valid_from
 and (cp.valid_to is null or b.redeemed_at < cp.valid_to)

join {{ ref('dim_campaign') }} cm on cm.campaign_natural_key = b.campaign_id

-- Versão do cliente vigente no instante da venda — mesma âncora da fato de
-- vendas, para que as duas contem a mesma história do mesmo cliente.
join {{ ref('dim_customer') }} cu
  on cu.customer_natural_key = b.order_customer_id
 and b.placed_at >= cu.valid_from
 and (cu.valid_to is null or b.placed_at < cu.valid_to)

join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_natural_key = b.sales_channel_id
left join {{ ref('dim_geography') }} g
  on g.country = cu.country and g.state_code = cu.state_code and g.city = cu.city
