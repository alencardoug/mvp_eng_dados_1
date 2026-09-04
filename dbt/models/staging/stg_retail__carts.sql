-- Carrinhos abertos, convertidos, abandonados ou expirados.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'carts') }}
),

renomeado as (
    select
        id                                        as cart_id,
        cart_code,
        customer_id,
        sales_channel_id,
        status                                    as cart_status,
        created_at                                as cart_created_at,
        expires_at                                as cart_expires_at,
        converted_at                              as cart_converted_at,

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
