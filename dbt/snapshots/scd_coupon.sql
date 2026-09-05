{#
    Histórico de atributos do cupom — SCD tipo 2 (ADR-0017).

    Um cupom que muda de campanha ou de regra de desconto muda como o resgate
    de ontem se agrega: o pedido de março continua tendo sido descontado pela
    regra de março, e pela campanha de março.

    `check_cols` **declaradas**, nunca `all`. Aqui isso não é só higiene: o
    modelo `coupons` carrega `redemption_count`, que muda a cada resgate novo.
    Com "all", cada resgate criaria uma versão do cupom, e a dimensão passaria a
    ter mais linhas que a fato que ela recorta.

    `is_deleted` entra pelo ADR-0029 — a exclusão é atributo que muda, e a
    versão anterior continua existindo para o resgate histórico se juntar a ela.
#}

{% snapshot scd_coupon %}

{{
    config(
        unique_key='coupon_id',
        strategy='check',
        check_cols=[
            'campaign_id',
            'discount_type',
            'discount_value',
            'min_order_amount',
            'coupon_is_active',
            'is_deleted',
        ],
    )
}}

select * from {{ ref('coupons') }}

{% endsnapshot %}
