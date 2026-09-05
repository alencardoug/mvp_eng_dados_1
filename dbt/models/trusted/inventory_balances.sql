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
--
-- ═══ O corte comum, e por que a Etapa 7 obrigou a ele ════════════════════════
-- Até a Etapa 6 os dois números vinham da mesma carga, no mesmo instante, e
-- comparar era trivial. A Etapa 7 deu ao livro um caminho próprio: o movimento
-- chega pelo CDC em segundos, e a projeção continua chegando pelo Airbyte,
-- quando a carga rodar (ADR-0031).
--
-- Sem tratamento, o teste de reconciliação passa a acusar **1.284 divergências
-- que não são divergências** — é a diferença de latência entre dois caminhos,
-- não defeito na projeção. Foi exatamente o que aconteceu na primeira execução
-- da Etapa 7, e é a armadilha que qualquer arquitetura de caminho quente e frio
-- arma para as suas próprias reconciliações.
--
-- O corte é por `recorded_at`: a projeção lida no instante T reflete todo
-- movimento **registrado na origem** antes de T, porque a origem grava o
-- movimento e move o saldo na mesma transação (Modelo de Dados §5.4). Comparar
-- o livro inteiro contra uma fotografia antiga compara coisas diferentes; cortar
-- o livro em T compara as mesmas.
--
-- Note que o corte é por `recorded_at` e **não** por `occurred_at`: evento
-- atrasado tem tempo de negócio antigo e tempo de registro novo, e é o de
-- registro que diz se a projeção já o tinha visto.

with saldos as (

    select * from {{ ref('stg_retail__inventory_balances') }}

),

reconstruido as (

    select
        m.warehouse_id,
        m.product_variant_id,
        sum(m.quantity_delta)                       as rebuilt_quantity_on_hand,
        sum(m.quantity_in)                          as quantity_in,
        sum(m.quantity_out)                         as quantity_out,
        count(*)                                    as movement_count,
        max(m.occurred_at)                          as last_movement_at
    from {{ ref('inventory_movements') }} m
    join saldos s
      on s.warehouse_id = m.warehouse_id
     and s.product_variant_id = m.product_variant_id
    where m.recorded_at <= s.ingested_at
    group by m.warehouse_id, m.product_variant_id

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
