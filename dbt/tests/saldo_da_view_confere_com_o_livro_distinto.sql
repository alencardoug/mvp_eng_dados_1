-- A fronteira *batch* + streaming → view de saldo (Qualidade §7, ADR-0031).
--
-- `skus_below_reorder_point` compõe o caminho frio (a fato) com o quente (os
-- deltas em `raw` que a fato ainda não absorveu), e a fronteira entre os dois
-- é a ausência do `movement_id` na fato. Este teste **refaz a resposta por
-- outro caminho**: o livro é o conjunto distinto de movimentos por (origem,
-- `movement_id`) na união da fato com a aterrissagem — dedupe, não anti-join —,
-- a posição é a soma dos deltas, o filtro é o mesmo ponto de reposição, e as
-- dimensões entram pelas chaves. O que a view publica tem de ser exatamente
-- isso, linha a linha, nas três parcelas: saldo, do lote, do fluxo.
--
-- Pega o que os outros testes não veem: movimento contado nas duas parcelas
-- (anti-join sem a origem), posição que some na junção com a dimensão, e
-- parcela do fluxo que não bate com o que está em `raw` e fora da fato. A
-- resposta muda com o fluxo de pé, e o teste muda junto: os dois leem o mesmo
-- instante do armazém.
--
-- `except all` compara multiconjuntos: um par (armazém, SKU) presente nas duas
-- origens aparece duas vezes na view, com números diferentes, e é assim que
-- tem de aparecer — a view não expõe a origem, o teste a resolve pelas chaves.
--
-- Uma linha no resultado é uma posição que a view mostra e o livro não, ou o
-- contrário.

with fato as (

    select
        f.source_system,
        w.warehouse_natural_key                         as warehouse_id,
        p.product_natural_key                           as product_variant_id,
        f.movement_id,
        f.quantity_delta,
        false                                           as do_fluxo
    from {{ ref('fact_inventory_movement') }} f
    join {{ ref('dim_warehouse') }} w on w.warehouse_key = f.warehouse_key
    join {{ ref('dim_product') }} p   on p.product_key = f.product_key

),

aterrissagem as (

    select
        'retail'                                        as source_system,
        s.warehouse_id,
        s.product_variant_id,
        s.movement_id,
        cast(s.quantity_delta as integer)               as quantity_delta,
        true                                            as do_fluxo
    from {{ source('retail', 'inventory_movements_stream') }} s

),

-- Um movimento, uma vez: o que está na fato vale pela fato (`do_fluxo` falso
-- ordena primeiro); o que só está na aterrissagem é a parcela do fluxo.
livro as (

    select distinct on (source_system, movement_id) *
    from (select * from fato union all select * from aterrissagem) tudo
    order by source_system, movement_id, do_fluxo

),

posicao as (

    select
        source_system,
        warehouse_id,
        product_variant_id,
        sum(quantity_delta)                                 as quantity_on_hand,
        coalesce(sum(quantity_delta) filter (where not do_fluxo), 0) as quantity_from_batch,
        coalesce(sum(quantity_delta) filter (where do_fluxo), 0)     as quantity_from_stream
    from livro
    group by 1, 2, 3

),

esperado as (

    select
        w.warehouse_name,
        p.sku,
        cast(pos.quantity_on_hand as integer)               as quantity_on_hand,
        cast(pos.quantity_from_batch as integer)            as quantity_from_batch,
        cast(pos.quantity_from_stream as integer)           as quantity_from_stream
    from posicao pos
    join {{ ref('dim_warehouse') }} w
      on  w.source_system = pos.source_system
     and w.warehouse_natural_key = pos.warehouse_id
    join {{ ref('dim_product') }} p
      on  p.source_system = pos.source_system
     and p.product_natural_key = pos.product_variant_id
     and p.is_current
    left join {{ ref('inventory_balances') }} b
      on  b.source_system = pos.source_system
     and b.warehouse_id = pos.warehouse_id
     and b.product_variant_id = pos.product_variant_id
    where pos.quantity_on_hand - coalesce(b.quantity_reserved, 0) < {{ var("reorder_point_units") }}

),

publicado as (

    select warehouse_name, sku, quantity_on_hand, quantity_from_batch, quantity_from_stream
    from {{ ref('skus_below_reorder_point') }}

)

select 'falta na view' as problema, * from (select * from esperado except all select * from publicado) faltam

union all

select 'sobra na view' as problema, * from (select * from publicado except all select * from esperado) sobram
