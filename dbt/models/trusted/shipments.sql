-- Remessas, com a entrega tirada do livro e a coluna da origem ao lado como
-- conferência.
--
-- ── De onde vem a data de entrega ───────────────────────────────────────────
-- `delivered_at` é o evento `delivered` do livro `delivery_events`
-- ([ADR-0034](../../../docs/adr/0034-entrega-do-livro-de-eventos.md)), e não a
-- coluna `shipments.delivered_at` da origem. Essa coluna continua aqui, como
-- `delivered_at_projected`, com um único propósito: ser comparada. A divergência
-- entre as duas é um teste, e a remessa que a origem diz entregue sem evento
-- correspondente vai para `quarantine` com motivo — não é descartada, e não é
-- preenchida pela coluna.
--
-- ── O que é "no prazo" ──────────────────────────────────────────────────────
-- A remessa está no prazo quando a chegada não é posterior à promessa que ela
-- carregava. É o grão em que P13 pergunta, porque transportadora e modalidade
-- são atributos da **remessa**, não do pedido
-- ([ADR-0033](../../../docs/adr/0033-entrega-medida-em-dois-graos.md)).
--
-- O denominador é `is_delivered`, não o total despachado: uma remessa em
-- trânsito ainda não está atrasada, e contá-la como fora do prazo confundiria
-- "não chegou ainda" com "chegou tarde".

with remessas as (

    select * from {{ ref('stg_retail__shipments') }}

),

-- Um resumo por remessa do que o livro registra. É a agregação que o ADR-0034
-- aceitou pagar em troca de a data de entrega ser um fato com momento próprio.
livro as (

    select
        shipment_id,
        max(occurred_at) filter (where is_delivery)         as delivered_at,
        max(occurred_at) filter (where is_return)           as returned_at,
        min(occurred_at) filter (where is_pickup)           as picked_up_at,
        min(occurred_at) filter (where is_out_for_delivery) as out_for_delivery_at,
        count(*) filter (where is_failed_attempt)           as failed_attempt_count,
        count(*)                                            as delivery_event_count,
        min(occurred_at)                                    as first_event_at,
        max(occurred_at)                                    as last_event_at
    from {{ ref('delivery_events') }}
    group by shipment_id

),

combinado as (

    select
        r.shipment_id,
        r.shipment_code,
        r.order_id,
        r.carrier_id,
        r.warehouse_id,
        r.shipment_status,
        r.tracking_code,
        r.freight_amount,
        r.shipped_at,
        r.estimated_delivery_at,

        -- A entrega, do livro.
        l.delivered_at,
        l.returned_at,
        l.picked_up_at,
        l.out_for_delivery_at,
        coalesce(l.failed_attempt_count, 0)                 as failed_attempt_count,
        coalesce(l.delivery_event_count, 0)                 as delivery_event_count,
        l.first_event_at,
        l.last_event_at,

        -- A mesma entrega, como a origem projetou. Existe para ser conferida.
        r.delivered_at                                      as delivered_at_projected,

        r.is_deleted,
        r.source_created_at,
        r.source_updated_at
    from remessas r
    left join livro l on l.shipment_id = r.shipment_id

)

select
    shipment_id,
    shipment_code,
    order_id,
    carrier_id,
    warehouse_id,
    shipment_status,
    tracking_code,
    freight_amount,

    shipped_at,
    estimated_delivery_at,
    delivered_at,
    returned_at,
    picked_up_at,
    out_for_delivery_at,
    delivered_at_projected,

    failed_attempt_count,
    delivery_event_count,
    first_event_at,
    last_event_at,

    -- ── Sinalizadores de estado ──────────────────────────────────────────────
    delivered_at is not null                                as is_delivered,
    returned_at is not null                                 as is_returned,
    shipment_status = 'lost'                                as is_lost,
    shipped_at is not null                                  as is_dispatched,

    -- ── Prazo ────────────────────────────────────────────────────────────────
    -- Nulo quando não houve entrega: "no prazo" é pergunta que só existe depois
    -- da chegada. Contar remessa em trânsito como atrasada trocaria "ainda não
    -- chegou" por "chegou tarde", que são coisas diferentes.
    case
        when delivered_at is not null
        then delivered_at <= estimated_delivery_at
    end                                                     as is_on_time,
    case
        when delivered_at is not null
        then extract(epoch from delivered_at - estimated_delivery_at) / 86400.0
    end::numeric(12, 4)                                     as delivery_delay_days,
    case
        when delivered_at is not null and shipped_at is not null
        then extract(epoch from delivered_at - shipped_at) / 86400.0
    end::numeric(12, 4)                                     as transit_days,

    -- ── Conferência entre livro e projeção ───────────────────────────────────
    -- Verdadeiro quando a origem diz que entregou e o livro não registra a
    -- chegada. É a condição de quarentena do ADR-0034, e é medida aqui para
    -- que o modelo de rejeição e o teste leiam a mesma definição.
    delivered_at_projected is not null and delivered_at is null
                                                            as is_delivery_unbacked,

    is_deleted,
    source_created_at,
    source_updated_at
from combinado
