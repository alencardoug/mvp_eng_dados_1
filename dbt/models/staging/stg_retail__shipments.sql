-- Remessas criadas para atender pedidos.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- Ingerida na Etapa 6 apenas para a invariante 5; a fato de remessa e as
-- perguntas de logística nascem na Etapa 8.

with fonte as (
    select * from {{ source('retail', 'shipments') }}
),

renomeado as (
    select
        id                                        as shipment_id,
        shipment_code,
        order_id,
        carrier_id,
        warehouse_id,
        status                                    as shipment_status,
        tracking_code,
        freight_amount,
        shipped_at,
        estimated_delivery_at,
        delivered_at,

        created_at                                as source_created_at,
        updated_at                                as source_updated_at,
        deleted_at                                as source_deleted_at,
        deleted_at is not null                    as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
