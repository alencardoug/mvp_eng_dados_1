-- Uso efetivo de cupom — um por pedido, garantido por índice único na origem.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

-- Deduplicação de entrega ao menos uma vez, pelo mesmo motivo de
-- `stg_retail__payment_transactions`: o modo `append` do ADR-0015 relê a
-- fronteira do cursor.
with fonte as (
    select distinct on (id) *
    from {{ source('retail', 'coupon_redemptions') }}
    order by id, _airbyte_extracted_at desc
),

renomeado as (
    select
        id                                        as coupon_redemption_id,
        coupon_id,
        customer_id,
        order_id,
        discount_amount                           as coupon_discount_amount,
        redeemed_at,

        created_at                                as source_created_at,
        false                                     as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
