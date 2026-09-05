-- Máquina de estados do pedido, uma linha por transição percorrida.
--
-- É o grão de `fact_order_status_event`. A origem já garante por `check` que a
-- transição é efetiva (origem distinta do destino) e que ambos os estados
-- pertencem ao domínio; o que se acrescenta aqui é a **posição de cada
-- transição no caminho** e o tempo que o pedido passou no estado anterior.
--
-- `from_status` nulo é a criação do pedido: a primeira transição não vem de
-- estado nenhum. Não é dado faltando.
--
-- A legalidade da transição não é decidida aqui: ela está declarada na *seed*
-- `order_status_transitions`, e o teste `transicao_de_estado_e_declarada`
-- confronta o que aconteceu com o que é permitido. Regra em modelo é regra que
-- ninguém revisa; regra em artefato declarativo é revisável de uma olhada.

with eventos as (

    select * from {{ ref('stg_retail__order_status_history') }}

),

ordenado as (

    select
        e.*,
        row_number() over (partition by order_id order by changed_at, order_status_event_id)
                                                        as status_sequence,
        lag(changed_at) over (partition by order_id order by changed_at, order_status_event_id)
                                                        as previous_changed_at,
        max(changed_at) over (partition by order_id)    as last_changed_at
    from eventos e

)

select
    order_status_event_id,
    order_id,
    from_status,
    to_status,
    changed_at,
    change_reason,
    status_sequence,
    previous_changed_at,

    -- Quanto tempo o pedido ficou no estado de origem antes desta transição.
    -- Nulo na primeira, que não tem estado anterior.
    case
        when previous_changed_at is not null
        then extract(epoch from changed_at - previous_changed_at) / 3600.0
    end::numeric(12, 4)                                 as hours_in_previous_status,

    from_status is null                                 as is_order_creation,
    changed_at = last_changed_at                        as is_current_status,
    -- Terminal é o estado do qual **nada sai**, e só `cancelled` e `returned`
    -- são: `delivered` ainda pode virar devolução. Confundir os dois faria a
    -- devolução parecer transição a partir de um estado final.
    to_status in ('cancelled', 'returned')              as is_terminal_status,
    to_status = 'cancelled'                             as is_cancellation,
    to_status = 'returned'                              as is_return,

    is_deleted,
    source_created_at
from ordenado
