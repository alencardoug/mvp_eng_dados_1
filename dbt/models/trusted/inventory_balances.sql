-- Saldo de estoque, ao lado do saldo **reconstruído do livro**.
--
-- Este modelo existe para uma coisa: tornar possível o critério de conclusão da
-- Etapa 6 — "saldo de estoque reconstruído a partir dos movimentos confere com
-- `inventory_balances`". Ele traz os dois números lado a lado, e um teste
-- verifica que a diferença é zero.
--
-- Não é redundância: `inventory_balances` é **projeção** mantida pela origem, e
-- o livro é a fonte da verdade (Modelo de Dados §2.10). Guardar os dois é o que
-- permite descobrir que a projeção divergiu — que é justamente o defeito que
-- uma projeção pode ter.

with saldos as (

    select * from {{ ref('stg_retail__inventory_balances') }}

),

reconstruido as (

    select
        warehouse_id,
        product_variant_id,
        sum(quantity_delta)                         as rebuilt_quantity_on_hand,
        sum(quantity_in)                            as quantity_in,
        sum(quantity_out)                           as quantity_out,
        count(*)                                    as movement_count,
        max(occurred_at)                            as last_movement_at
    from {{ ref('inventory_movements') }}
    group by warehouse_id, product_variant_id

),

reservado as (

    -- Invariante 8: reserva liberada, expirada ou consumida **não** ocupa saldo.
    select
        warehouse_id,
        product_variant_id,
        sum(quantity_reserved) filter (where reservation_status = 'active')
                                                    as active_reserved_quantity
    from {{ ref('stg_retail__stock_reservations') }}
    group by warehouse_id, product_variant_id

)

select
    s.inventory_balance_id,
    s.warehouse_id,
    s.product_variant_id,

    s.quantity_on_hand,
    s.quantity_reserved,
    s.quantity_available,
    s.last_movement_at,

    coalesce(r.rebuilt_quantity_on_hand, 0)         as rebuilt_quantity_on_hand,
    coalesce(r.quantity_in, 0)                      as quantity_in,
    coalesce(r.quantity_out, 0)                     as quantity_out,
    coalesce(r.movement_count, 0)                   as movement_count,
    -- A diferença é a medida da reconciliação: zero é o resultado esperado, e
    -- qualquer outra coisa é a projeção tendo divergido do livro.
    s.quantity_on_hand - coalesce(r.rebuilt_quantity_on_hand, 0) as balance_drift,

    coalesce(v.active_reserved_quantity, 0)         as active_reserved_quantity,
    s.quantity_reserved - coalesce(v.active_reserved_quantity, 0) as reserved_drift,

    s.is_deleted,
    s.source_created_at,
    s.source_updated_at
from saldos s
left join reconstruido r
       on r.warehouse_id = s.warehouse_id
      and r.product_variant_id = s.product_variant_id
left join reservado v
       on v.warehouse_id = s.warehouse_id
      and v.product_variant_id = s.product_variant_id
