-- Livro de eventos de estoque, com o valor de cada movimento.
--
-- **É aqui que o custo do produto vendido nasce** (ADR-0030): o movimento de
-- saída carrega o `unit_cost` do que saiu, registrado no instante da saída. Não
-- é custo médio nem custo da última compra — é o custo daquele evento, e nada
-- que aconteça depois o move.
--
-- ── Por que as medidas são separadas por sentido ─────────────────────────────
-- `quantity_delta` é assinado, e somá-lo dá o saldo — que é o que se quer para
-- o saldo, e é errado para "quanto entrou". Entrada e saída viram colunas
-- próprias, sempre positivas, para que toda soma esteja certa em qualquer
-- recorte sem ninguém precisar lembrar de filtrar por tipo.

{% set tipos_de_saida = "('sale_dispatch', 'supplier_return', 'transfer_out', 'adjustment_out')" %}

with movimentos as (

    select * from {{ ref('stg_retail__inventory_movements') }}

)

select
    movement_id,
    event_sequence,
    idempotency_key,
    warehouse_id,
    product_variant_id,
    movement_type,
    source_type,
    source_id,
    correlation_id,
    causation_id,
    aggregate_version,
    occurred_at,
    recorded_at,
    schema_version,
    event_metadata,

    -- ── Sentido do movimento ────────────────────────────────────────────────
    movement_type in {{ tipos_de_saida }}                   as is_outbound,
    movement_type not in {{ tipos_de_saida }}               as is_inbound,
    movement_type = 'sale_dispatch'                         as is_sale,

    -- ── Quantidades: assinada para saldo, absolutas para fluxo ──────────────
    quantity_delta,
    case when quantity_delta > 0 then quantity_delta else 0 end     as quantity_in,
    case when quantity_delta < 0 then -quantity_delta else 0 end    as quantity_out,

    -- ── Valor ───────────────────────────────────────────────────────────────
    unit_cost,
    round(abs(quantity_delta) * coalesce(unit_cost, 0), 2)  as movement_cost_amount,
    -- Custo do produto vendido: só a saída por venda. Devolução ao fornecedor e
    -- transferência também são saídas, e nenhuma das duas é venda — somá-las
    -- inflaria o CMV com movimentação interna.
    case
        when movement_type = 'sale_dispatch'
        then round(abs(quantity_delta) * coalesce(unit_cost, 0), 2)
        else 0
    end                                                     as cogs_amount,

    -- Atraso entre o momento de negócio e o registro na origem. É o que a
    -- Etapa 7 vai usar como marca d'água do processamento por tempo de evento.
    extract(epoch from (recorded_at - occurred_at))::int     as recording_delay_seconds,

    is_deleted,
    source_created_at
from movimentos
