{{ config(tags=['legado_reconciliacao']) }}

-- Dependências explícitas: o primeiro build não testa quarentena inexistente.
--
-- ── Por que este teste tem etiqueta própria ──────────────────────────────────
-- Ele é o único que compara `trusted` com `quarantine`, e a DAG constrói as
-- duas em tarefas diferentes, nessa ordem. Rodando junto de `trusted`, ele
-- comparava a classificação da captura nova com uma quarentena ainda da
-- anterior, e acusava 2.268 divergências que eram só ordem de execução.
--
-- A etiqueta o move para a tarefa da quarentena, onde os dois lados já
-- existem. O `--exclude` na tarefa de `trusted` é o outro lado da mesma moeda:
-- sem ele, a seleção indireta do dbt o traria de volta.
with expected as (
    select * from {{ ref('legacy_classifications') }}
), actual as (
    select * from {{ ref('legacy_eligible_records') }}
    union all
    select q.* from {{ ref('rejected_legacy_records') }} q
    where exists (
        select 1 from expected e where e.source_system = q.source_system
            and e.snapshot_id = q.snapshot_id and e.source_table = q.source_table
            and e.catalog_version = q.catalog_version
    )
)
(select * from expected except all select * from actual)
union all
(select * from actual except all select * from expected)
