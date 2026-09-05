-- Cupons, com a campanha que os emitiu e o uso acumulado.
--
-- ── As três condições de elegibilidade ──────────────────────────────────────
-- A invariante 12 diz que o cupom só é usado dentro da vigência e segundo as
-- suas regras. São três condições independentes, e cada uma falha de um jeito
-- diferente:
--
--   vigência     o resgate cai entre `valid_from` e `valid_to`;
--   piso         o pedido alcança `min_order_amount`, quando há um;
--   teto         o total de resgates não passa de `max_redemptions`, quando há.
--
-- Nulo em `min_order_amount` é *sem piso* e nulo em `max_redemptions` é *sem
-- teto* — em nenhum dos dois é dado faltando. Quem verifica cada resgate é
-- `coupon_redemptions`; o que se acumula aqui é o teto, que é do cupom e não do
-- resgate.

with cupons as (

    select * from {{ ref('stg_retail__coupons') }}

),

campanhas as (

    select * from {{ ref('campaigns') }}

),

uso as (

    select
        coupon_id,
        count(*)                                    as redemption_count,
        sum(coupon_discount_amount)                 as redeemed_discount_amount,
        min(redeemed_at)                            as first_redeemed_at,
        max(redeemed_at)                            as last_redeemed_at
    from {{ ref('stg_retail__coupon_redemptions') }}
    group by coupon_id

)

select
    c.coupon_id,
    c.coupon_code,
    c.campaign_id,
    ca.campaign_code,
    ca.campaign_name,
    ca.campaign_objective,

    c.discount_type,
    c.discount_value,
    c.min_order_amount,
    c.max_redemptions,
    c.coupon_valid_from,
    c.coupon_valid_to,
    c.coupon_is_active,

    coalesce(u.redemption_count, 0)                 as redemption_count,
    coalesce(u.redeemed_discount_amount, 0)         as redeemed_discount_amount,
    u.first_redeemed_at,
    u.last_redeemed_at,

    -- Teto atingido. `max_redemptions` nulo é sem teto, e nesse caso o cupom
    -- nunca se esgota — `false`, não nulo.
    c.max_redemptions is not null
        and coalesce(u.redemption_count, 0) >= c.max_redemptions  as is_exhausted,

    timestamptz '{{ var("as_of_date") }} 00:00-03'
        between c.coupon_valid_from and c.coupon_valid_to         as is_redeemable_now,

    c.is_deleted,
    c.source_created_at,
    c.source_updated_at
from cupons c
join campanhas ca on ca.campaign_id = c.campaign_id
left join uso u on u.coupon_id = c.coupon_id
