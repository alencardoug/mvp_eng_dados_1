-- Dependências explícitas: o primeiro build não testa quarentena inexistente.
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
