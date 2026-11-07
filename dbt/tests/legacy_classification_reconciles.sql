-- As comparações com quarantine rodam depois de ambas as saídas existirem.
-- includes duplicata física; não conta os vários achados como várias linhas.
with counts as (
    select source_system, snapshot_id, source_table, count(*) as extracted,
        cast(0 as bigint) as classified, cast(0 as bigint) as eligible, cast(0 as bigint) as rejected
    from {{ ref('legacy_records') }} group by 1, 2, 3
    union all
    select source_system, snapshot_id, source_table, 0, count(*),
        {{ contar_onde("classification in ('accepted', 'corrected')") }},
        {{ contar_onde("classification = 'rejected'") }}
    from {{ ref('legacy_classifications') }} group by 1, 2, 3
)
select source_system, snapshot_id, source_table from counts
group by 1, 2, 3
having sum(extracted) <> sum(classified) or sum(extracted) <> sum(eligible) + sum(rejected)
