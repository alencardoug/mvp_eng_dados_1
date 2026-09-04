-- Grão comercial do pedido: um SKU comprado em uma linha.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais. A regra de
-- negócio mora em `trusted`; a agregação, em `analytics`.

with fonte as (
    select * from {{ source('retail', 'order_items') }}
),

renomeado as (
    select
        id                                        as order_item_id,
        order_id,
        product_variant_id,

        -- ── Por que o `cast` ─────────────────────────────────────────────────
        -- O Airbyte **alarga** o tipo: `integer` na origem chega como `bigint`
        -- em `raw`. A diferença não é cosmética — em PostgreSQL `sum(integer)`
        -- devolve `bigint`, mas `sum(bigint)` devolve `numeric`, e o contrato
        -- da view de consumo quebra três camadas adiante com "data type
        -- mismatch". Tipar de volta é literalmente o trabalho desta camada.
        cast(quantity as integer)                 as quantity,
        unit_price,
        discount_amount,
        tax_amount,
        total_amount                              as line_total_amount,

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
