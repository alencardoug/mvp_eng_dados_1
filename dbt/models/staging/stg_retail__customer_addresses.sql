-- Endereços de cobrança e entrega, com vigência.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'customer_addresses') }}
),

renomeado as (
    select
        id                                        as customer_address_id,
        customer_id,
        address_type,
        street,
        number                                    as street_number,
        complement,
        district,
        city,
        state,
        postal_code,
        country,
        is_primary,
        valid_from,
        valid_to,

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
