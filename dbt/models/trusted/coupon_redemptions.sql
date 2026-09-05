-- Uso de cupom — o grão de `fact_coupon_redemption`.
--
-- Um resgate por pedido, garantido por índice único na origem. É o que permite
-- ratear o desconto do cupom na venda sem ambiguidade: dois cupons no mesmo
-- pedido tornariam a atribuição do desconto uma escolha, e escolha silenciosa é
-- o que este projeto não faz.
--
-- ── Elegibilidade verificada, não presumida ─────────────────────────────────
-- Os três sinalizadores abaixo dizem, resgate a resgate, se a regra do cupom
-- foi respeitada. Eles existem para que a invariante 12 seja **testável** em
-- vez de afirmada, e para que a falha diga qual das três condições quebrou.
--
-- O gerador produz resgates elegíveis por construção; os sinalizadores não
-- confiam nisso. Regra verificada só onde é produzida é regra que ninguém
-- confere depois.

with resgates as (

    select * from {{ ref('stg_retail__coupon_redemptions') }}

),

cupons as (

    select * from {{ ref('coupons') }}

),

pedidos as (

    select
        order_id,
        order_total_amount,
        subtotal_amount,
        placed_at,
        is_cancelled
    from {{ ref('orders') }}

),

-- Posição do resgate na fila do cupom. É contra ela que o teto se verifica: o
-- 5.001º resgate de um cupom com teto de 5.000 é o que viola a regra, e não o
-- cupom inteiro.
ordenado as (

    select
        r.*,
        row_number() over (partition by r.coupon_id order by r.redeemed_at, r.coupon_redemption_id)
            as redemption_sequence
    from resgates r

)

select
    r.coupon_redemption_id,
    r.coupon_id,
    r.customer_id,
    r.order_id,
    r.coupon_discount_amount,
    r.redeemed_at,
    r.redemption_sequence,

    c.coupon_code,
    c.campaign_id,
    c.campaign_objective,
    c.discount_type,
    c.discount_value,
    c.min_order_amount,
    c.max_redemptions,

    o.placed_at,
    o.subtotal_amount                               as order_subtotal_amount,
    o.order_total_amount,

    -- ── As três condições da invariante 12 ───────────────────────────────────
    r.redeemed_at between c.coupon_valid_from and c.coupon_valid_to
                                                    as is_within_validity,
    c.min_order_amount is null or o.subtotal_amount >= c.min_order_amount
                                                    as is_above_minimum,
    c.max_redemptions is null or r.redemption_sequence <= c.max_redemptions
                                                    as is_within_limit,

    -- O desconto concedido nunca supera o valor do pedido: cupom não paga o
    -- cliente para comprar.
    r.coupon_discount_amount <= o.subtotal_amount   as is_discount_bounded,

    o.is_cancelled                                  as order_is_cancelled,
    r.is_deleted,
    r.source_created_at
from ordenado r
join cupons c on c.coupon_id = r.coupon_id
join pedidos o on o.order_id = r.order_id
