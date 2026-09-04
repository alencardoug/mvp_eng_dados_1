-- Cadastro de clientes. Concentra a maior parte dos campos `personal` do projeto.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'customers') }}
),

renomeado as (
    select
        id                                        as customer_id,
        customer_code,
        segment_id                                as customer_segment_id,
        first_name,
        last_name,
        first_name || ' ' || last_name             as customer_full_name,
        document                                  as customer_document,
        birth_date,
        status                                    as customer_status,
        registered_at,

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
