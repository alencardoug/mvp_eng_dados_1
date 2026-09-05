-- Cupom — SCD tipo 2, no padrão misto do projeto (Modelo de Dados §3.2).
--
--   **tipo 2** — campanha, tipo e valor do desconto, piso do pedido, estado de
--                atividade e exclusão. São os atributos pelos quais se recorta
--                um resgate histórico.
--   **tipo 1** — o código do cupom, o teto de resgates e o uso acumulado. Este
--                último é de natureza corrente: "quantas vezes este cupom já
--                foi usado" é pergunta sobre hoje, não sobre o instante do
--                resgate.

with versoes as (

    select
        *,
        row_number() over (partition by coupon_id order by dbt_valid_from)
            as numero_da_versao
    from {{ ref('scd_coupon') }}

),

atual as (

    select * from {{ ref('coupons') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['v.coupon_id', 'v.dbt_valid_from']) }} as coupon_key,
    v.coupon_id                                             as coupon_natural_key,

    -- ── Tipo 1: descrevem o cupom, ou descrevem o hoje ──────────────────────
    a.coupon_code,
    a.coupon_valid_from,
    a.coupon_valid_to,
    a.max_redemptions,
    a.redemption_count,
    a.redeemed_discount_amount,
    a.is_exhausted,
    a.is_redeemable_now,

    -- ── Tipo 2: classificam o resgate no instante em que ele aconteceu ──────
    v.campaign_id,
    v.campaign_code,
    v.campaign_name,
    v.campaign_objective,
    v.discount_type,
    v.discount_value,
    v.min_order_amount,
    v.coupon_is_active,
    v.is_deleted,

    -- Vigência da primeira versão estendida até `period_start`, como nas demais
    -- SCD do projeto: o `dbt snapshot` marca `dbt_valid_from` no instante da
    -- primeira execução, e sem isto todo resgate anterior a ela fica sem versão
    -- à qual se juntar — a fato sairia vazia.
    case
        when v.numero_da_versao = 1 then timestamptz '{{ var("period_start") }} 00:00-03'
        else v.dbt_valid_from
    end                                                     as valid_from,
    v.dbt_valid_to                                          as valid_to,
    v.dbt_valid_to is null                                  as is_current
from versoes v
join atual a on a.coupon_id = v.coupon_id
