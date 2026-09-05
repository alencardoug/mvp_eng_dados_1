-- Livro append-only de entradas, saídas, ajustes e transferências.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.
--
-- ── O encontro dos dois caminhos (ADR-0031) ─────────────────────────────────
-- Este é o único modelo do projeto que lê **duas** fontes da mesma tabela:
--
--   `inventory_movements`         — carga completa do Airbyte, fora do caminho
--                                   crítico, servindo de reconciliação;
--   `inventory_movements_stream`  — deltas do CDC gravados pelo pipeline Beam,
--                                   o caminho oficial de ingestão incremental.
--
-- As duas carregam o mesmo livro imutável, e o `snapshot.mode=initial` do
-- conector garante que o caminho quente também tenha o histórico completo. A
-- sobreposição é, portanto, total — e é justamente por isso que ela vale como
-- teste: se a deduplicação falhar, a fato dobra de tamanho e nada mais fecha.
--
-- ── Deduplicação de entrega ao menos uma vez ────────────────────────────────
-- Vale para os dois caminhos, pelo mesmo motivo. O modo `append` do ADR-0015 é
-- *at least once* e o Airbyte relê a fronteira do cursor; o transporte do
-- ADR-0019 é *at least once* e reentrega mensagem. `raw` fica *at least once*;
-- `staging` entrega exatamente uma vez, e é essa a fronteira.
--
-- `movement_id` é a chave: é a chave primária do evento na origem, e é imutável
-- por contrato (Modelo de Dados §5). Corrigir um evento publicado é inserir
-- outro, compensatório — nunca reescrever este.

with lote as (

    select
        movement_id, event_sequence, idempotency_key, warehouse_id,
        product_variant_id, movement_type, quantity_delta, unit_cost,
        source_type, source_id, correlation_id, causation_id,
        aggregate_version, occurred_at, recorded_at, schema_version, metadata,
        _airbyte_extracted_at   as ingested_at,
        'batch'                 as caminho
    from {{ source('retail', 'inventory_movements') }}

),

continuo as (

    select
        movement_id, event_sequence, idempotency_key, warehouse_id,
        product_variant_id, movement_type, quantity_delta, unit_cost,
        source_type, source_id, correlation_id, causation_id,
        aggregate_version, occurred_at, recorded_at, schema_version, metadata,
        _stream_extracted_at    as ingested_at,
        'stream'                as caminho
    from {{ source('retail', 'inventory_movements_stream') }}

),

combinado as (

    select * from continuo
    union all
    select * from lote

),

-- Por onde cada movimento chegou. São **linhagem**, não conveniência: é por
-- estas duas colunas que o teste de reconciliação entre os caminhos pergunta
-- se algum evento chegou por um e não pelo outro — que é o sintoma de lacuna
-- no CDC ou de carga desatualizada, e o único jeito de vê-lo.
chegadas as (

    select
        movement_id,
        bool_or(caminho = 'stream')     as arrived_by_stream,
        bool_or(caminho = 'batch')      as arrived_by_batch,
        min(ingested_at)                as first_ingested_at,
        max(ingested_at)                as ingested_at
    from combinado
    group by movement_id

),

-- O payload vem de uma entrega só. `caminho` desempata em favor de `stream`
-- ('stream' > 'batch' na ordenação), que é o caminho oficial; e entre duas
-- entregas do mesmo caminho vence a mais recente.
unico as (

    select distinct on (movement_id) *
    from combinado
    order by movement_id, caminho desc, ingested_at desc

),

renomeado as (
    select
        u.movement_id,
        u.event_sequence,
        u.idempotency_key,
        u.warehouse_id,
        u.product_variant_id,
        u.movement_type,
        cast(u.quantity_delta as integer)           as quantity_delta,
        u.unit_cost,
        u.source_type,
        u.source_id,
        u.correlation_id,
        u.causation_id,
        u.aggregate_version,
        u.occurred_at,
        u.recorded_at,
        cast(u.schema_version as integer)           as schema_version,
        u.metadata                                  as event_metadata,

        -- ── Linhagem de ingestão (ADR-0031) ────────────────────────────────
        c.arrived_by_stream,
        c.arrived_by_batch,

        -- Livro de eventos: sem `created_at`, sem `updated_at` e sem
        -- `deleted_at` de propósito. `recorded_at` é o carimbo da origem, e
        -- corrigir um evento publicado é inserir outro, compensatório.
        u.recorded_at                               as source_created_at,
        false                                       as is_deleted,
        c.first_ingested_at                         as ingested_at
    from unico u
    join chegadas c using (movement_id)
)

select * from renomeado
