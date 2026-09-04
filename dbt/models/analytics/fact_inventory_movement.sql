-- Fato de movimentação de estoque.
--
-- **Grão: um movimento de um SKU em um armazém.**
--
-- ═══ A única exceção incremental do projeto ═══════════════════════════════════
-- O [ADR-0016](docs/adr/0016-materializacao-por-camada.md) fixou `table` em
-- `analytics` e declarou esta a **única** exceção — concedida porque a Etapa 7
-- alimenta esta fato por *streaming*, e reconstruí-la por inteiro a cada
-- execução contradiria o propósito do fluxo contínuo.
--
-- A exceção veio com quatro proteções **obrigatórias**. Sem elas ela não é
-- concedida, e por isso as quatro estão aqui, nomeadas:
--
--   1. `unique_key` no identificador do evento — `movement_id`, logo abaixo.
--   2. Filtro por **tempo de evento** com margem de atraso, nunca por tempo de
--      carga. Está no bloco `is_incremental()`.
--   3. `--full-refresh` agendado e registrado no plano — Etapa 12.
--   4. Teste de reconciliação contra a reconstrução completa — em
--      `_analytics__models.yml`.
--
-- **Por que tempo de evento e não tempo de carga.** Filtrar por `recorded_at`
-- pareceria mais simples e perderia o evento atrasado: um movimento que ocorreu
-- ontem e chegou hoje tem `recorded_at` novo e `occurred_at` velho. A margem
-- abaixo é o quanto de atraso o filtro tolera, e é ela que decide o que se
-- perde — não o acaso.

{{
    config(
        materialized='incremental',
        unique_key='movement_id',
        incremental_strategy='merge',
        on_schema_change='fail',
    )
}}

with movimentos as (

    select * from {{ ref('inventory_movements') }}

    {% if is_incremental() %}
    -- Margem de atraso: reprocessa a janela inteira em vez de confiar que o
    -- evento chegou em ordem. `merge` com `unique_key` torna o reprocessamento
    -- idempotente, então reler é barato e perder não é.
    where occurred_at >= (
        select coalesce(max(occurred_at), timestamptz '{{ var("period_start") }}')
        from {{ this }}
    ) - interval '{{ var("atraso_maximo_dias") }} days'
    {% endif %}

)

select
    {{ dbt_utils.generate_surrogate_key(['m.movement_id']) }} as movement_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    d.date_key,
    p.product_key,
    w.warehouse_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    m.movement_id,
    m.event_sequence,
    m.idempotency_key,
    m.movement_type,
    m.source_type,
    m.source_id,
    m.correlation_id,
    m.aggregate_version,
    m.occurred_at,
    m.recorded_at,
    cast(m.occurred_at at time zone 'America/Sao_Paulo' as date) as movement_date,
    m.is_inbound,
    m.is_outbound,
    m.is_sale,

    -- ── Medidas ──────────────────────────────────────────────────────────────
    -- `quantity_delta` é **semiaditiva**: soma por armazém e SKU para dar
    -- saldo, e **não** se soma ao longo do tempo — três meses somados dariam um
    -- estoque que nunca existiu. `quantity_in` e `quantity_out` são aditivas em
    -- qualquer recorte, e é por elas que se mede fluxo.
    m.quantity_delta,
    m.quantity_in,
    m.quantity_out,
    m.unit_cost,
    m.movement_cost_amount,
    -- Custo do produto vendido (ADR-0030): zero em tudo que não é venda.
    m.cogs_amount,
    m.recording_delay_seconds
from movimentos m
join {{ ref('dim_date') }} d
  on d.full_date = cast(m.occurred_at at time zone 'America/Sao_Paulo' as date)

-- Versão do SKU vigente no instante do movimento.
join {{ ref('dim_product') }} p
  on p.product_natural_key = m.product_variant_id
 and m.occurred_at >= p.valid_from
 and (p.valid_to is null or m.occurred_at < p.valid_to)

join {{ ref('dim_warehouse') }} w on w.warehouse_natural_key = m.warehouse_id
