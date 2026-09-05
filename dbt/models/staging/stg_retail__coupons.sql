-- Cupons, com a regra de desconto e as condições de uso.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- As três condições que a invariante 12 verifica moram aqui e são carregadas
-- sem alteração: vigência (`valid_from`/`valid_to`), valor mínimo do pedido
-- (`min_order_amount`) e teto de resgates (`max_redemptions`). Nulo em
-- `min_order_amount` é "sem piso"; nulo em `max_redemptions` é "sem teto" — em
-- nenhum dos dois é dado faltando.

with fonte as (
    select * from {{ source('retail', 'coupons') }}
),

renomeado as (
    select
        id                                        as coupon_id,
        code                                      as coupon_code,
        campaign_id,
        discount_type,
        discount_value,
        min_order_amount,
        max_redemptions,
        valid_from                                as coupon_valid_from,
        valid_to                                  as coupon_valid_to,
        is_active                                 as coupon_is_active,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
