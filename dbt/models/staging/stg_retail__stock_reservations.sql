-- Reserva de quantidade para carrinhos ou pedidos.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

with fonte as (
    select * from {{ source('retail', 'stock_reservations') }}
),

renomeado as (
    select
        id                                        as stock_reservation_id,
        reservation_code,
        warehouse_id,
        product_variant_id,
        cart_id,
        order_id,
        cast(quantity as integer)                 as quantity_reserved,
        status                                    as reservation_status,
        expires_at,
        released_at,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
