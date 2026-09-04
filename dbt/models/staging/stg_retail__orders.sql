-- Cabeçalho do pedido: cliente, canal, valores e estado atual.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'orders') }}
),

renomeado as (
    select
        id                                        as order_id,
        order_number,
        customer_id,
        sales_channel_id,
        cart_id,
        status                                    as order_status,
        placed_at,
        currency,
        subtotal_amount,
        discount_amount                           as order_discount_amount,
        shipping_amount,
        tax_amount                                as order_tax_amount,
        total_amount                              as order_total_amount,

        -- Marcas de origem e de carga. `ingested_at` é o carimbo do Airbyte;
        -- `source_updated_at` é o tempo de negócio e o cursor do ADR-0015.
        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
