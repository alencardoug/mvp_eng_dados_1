-- P12 — Quais SKUs estão abaixo do ponto de reposição **agora**, por armazém.
--
-- ═══ A view onde o caminho quente e o frio se encontram ═════════════════════
-- É a única pergunta do projeto cuja resposta muda entre duas execuções
-- seguidas sem ninguém rodar nada. É também a única que compõe as duas
-- materializações sob um contrato só, que é o que o ADR-0006 foi buscar ao
-- incluir o *streaming*: caminho quente e frio servindo o mesmo consumidor.
--
-- A composição é a clássica da arquitetura Lambda:
--
--   frio   ← `fact_inventory_movement`, tudo que o dbt já absorveu
--   quente ← deltas em `raw` que a fato **ainda não** contém
--   saldo  ← frio + quente
--
-- ── Por que a fronteira é a chave do evento, e não o tempo ──────────────────
-- O corte óbvio seria "eventos posteriores ao último que a fato viu". Ele
-- perde exatamente o caso que o fluxo existe para tratar: um movimento que
-- **ocorreu** antes dessa fronteira e **chegou** depois dela — o evento
-- atrasado — cairia fora dos dois lados e sumiria do saldo. A fronteira é a
-- ausência do `movement_id` na fato, que é exata e não depende de relógio.
--
-- ── Por que "agora" é o último evento, e não `current_date` ─────────────────
-- Nenhum modelo do projeto usa `current_date` (dbt_project.yml): o mesmo dado
-- daria número diferente a cada execução e a reprodutibilidade (P2) acabaria.
-- Aqui "agora" é o instante do movimento mais recente do livro — o único
-- relógio que o próprio dado carrega, e que avança quando o fluxo avança.

{{ config(materialized='view') }}

with frio as (

    select
        w.warehouse_natural_key                             as warehouse_id,
        p.product_natural_key                               as product_variant_id,
        f.movement_id,
        f.quantity_delta,
        f.quantity_out,
        f.is_sale,
        f.occurred_at
    from {{ ref('fact_inventory_movement') }} f
    join {{ ref('dim_warehouse') }} w on w.warehouse_key = f.warehouse_key
    join {{ ref('dim_product') }} p   on p.product_key = f.product_key

),

quente as (

    select
        s.warehouse_id,
        s.product_variant_id,
        s.movement_id,
        cast(s.quantity_delta as integer)                   as quantity_delta,
        case when s.quantity_delta < 0 then cast(-s.quantity_delta as integer) else 0 end
                                                            as quantity_out,
        s.movement_type = 'sale_dispatch'                   as is_sale,
        s.occurred_at
    from {{ source('retail', 'inventory_movements_stream') }} s
    where not exists (
        select 1 from {{ ref('fact_inventory_movement') }} f
        where f.movement_id = s.movement_id
    )

),

livro as (
    select *, false as do_caminho_quente from frio
    union all
    select *, true  as do_caminho_quente from quente
),

agora as (select max(occurred_at) as instante from livro),

posicao as (

    select
        l.warehouse_id,
        l.product_variant_id,
        sum(l.quantity_delta)                                       as quantity_on_hand,
        sum(l.quantity_delta) filter (where not l.do_caminho_quente) as quantity_from_batch,
        sum(l.quantity_delta) filter (where l.do_caminho_quente)     as quantity_from_stream,
        count(*) filter (where l.do_caminho_quente)                  as stream_movement_count,
        max(l.occurred_at)                                           as last_movement_at,
        -- Consumo da janela de cobertura: só venda. Transferência e devolução
        -- ao fornecedor também tiram do armazém, e nenhuma das duas é demanda —
        -- somá-las encurtaria a cobertura e faria o alerta disparar cedo.
        sum(l.quantity_out) filter (
            where l.is_sale
              and l.occurred_at >= (select instante from agora)
                                   - interval '{{ var("cover_window_days") }} days'
        )                                                            as window_sold_units
    from livro l
    group by l.warehouse_id, l.product_variant_id

)

select
    -- ── Dimensões ───────────────────────────────────────────────────────────
    w.warehouse_name,
    w.warehouse_region,
    p.sku,
    p.product_name,
    p.leaf_category_name                                    as category_name,
    p.brand_name,

    -- ── Posição ─────────────────────────────────────────────────────────────
    -- `quantity_on_hand` é **semiaditiva**: soma por armazém e SKU, nunca ao
    -- longo do tempo. É uma fotografia, e fotografias não se empilham.
    cast(pos.quantity_on_hand as integer)                   as quantity_on_hand,
    cast(coalesce(b.quantity_reserved, 0) as integer)       as quantity_reserved,
    cast(pos.quantity_on_hand - coalesce(b.quantity_reserved, 0) as integer)
                                                            as quantity_available,

    -- ── De onde veio o número ───────────────────────────────────────────────
    -- As duas parcelas ficam à vista de propósito: sem elas, ninguém consegue
    -- dizer se um saldo estranho veio do lote ou do fluxo, e o caminho quente
    -- vira caixa-preta na única view que o consome.
    cast(coalesce(pos.quantity_from_batch, 0) as integer)   as quantity_from_batch,
    cast(coalesce(pos.quantity_from_stream, 0) as integer)  as quantity_from_stream,
    pos.stream_movement_count,

    -- ── Cobertura ───────────────────────────────────────────────────────────
    cast({{ var("reorder_point_units") }} as integer)       as reorder_point,
    -- **Ruptura**: saldo disponível zerado ou negativo — não há o que vender.
    (pos.quantity_on_hand - coalesce(b.quantity_reserved, 0)) <= 0 as is_stockout,
    round(pos.window_sold_units / {{ var("cover_window_days") }}::numeric, 3)
                                                            as daily_demand_units,
    -- **Cobertura**, em dias: quanto o saldo dura ao ritmo da demanda recente.
    -- **Não aditiva** — é razão. Nula quando não houve venda na janela: SKU sem
    -- demanda não tem cobertura finita, e escrever zero ali diria o oposto.
    case
        when pos.window_sold_units > 0
        then round(
            (pos.quantity_on_hand - coalesce(b.quantity_reserved, 0))
            / (pos.window_sold_units / {{ var("cover_window_days") }}::numeric), 1
        )
    end                                                     as days_of_cover,

    pos.last_movement_at
from posicao pos
join {{ ref('dim_warehouse') }} w on w.warehouse_natural_key = pos.warehouse_id
join {{ ref('dim_product') }} p
  on p.product_natural_key = pos.product_variant_id
 and p.is_current
left join {{ ref('inventory_balances') }} b
  on b.warehouse_id = pos.warehouse_id
 and b.product_variant_id = pos.product_variant_id
where pos.quantity_on_hand - coalesce(b.quantity_reserved, 0) < {{ var("reorder_point_units") }}
order by days_of_cover nulls last, quantity_available
