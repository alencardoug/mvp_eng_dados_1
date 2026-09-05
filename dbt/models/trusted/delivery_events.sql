-- Livro da entrega — o grão de rastreamento da remessa.
--
-- **É a fonte da data de entrega realizada** (ADR-0034). A coluna
-- `shipments.delivered_at` é a projeção corrente do mesmo fato, e projeção
-- corrente muda de valor retroativamente: quem mede prazo histórico contra ela
-- mede contra o último `update`, não contra o que aconteceu.
--
-- Uma remessa devolvida registra `delivered` **e depois** `returned`, nessa
-- ordem. É por isso que a devolução não apaga a entrega: a caixa chegou, e o
-- que veio depois é fato posterior, contado à parte.

with eventos as (

    select * from {{ ref('stg_retail__delivery_events') }}

)

select
    delivery_event_id,
    shipment_id,
    delivery_event_type,
    occurred_at,
    event_location,
    event_description,

    -- Sinalizadores que toda pergunta de entrega usa, definidos uma vez.
    delivery_event_type = 'delivered'                       as is_delivery,
    delivery_event_type = 'returned'                        as is_return,
    delivery_event_type = 'delivery_attempt'                as is_failed_attempt,
    delivery_event_type = 'picked_up'                       as is_pickup,
    delivery_event_type = 'out_for_delivery'                as is_out_for_delivery,

    -- Ordem do evento dentro da remessa. É o que permite perguntar "o que veio
    -- antes da devolução" sem reordenar a tabela em cada consulta.
    row_number() over (partition by shipment_id order by occurred_at, delivery_event_id)
                                                            as event_sequence,

    is_deleted,
    source_created_at
from eventos
