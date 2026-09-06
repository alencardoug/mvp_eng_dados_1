-- As comparações com quarantine rodam depois de ambas as saídas existirem.
-- includes duplicata física; não conta os vários achados como várias linhas.
with counts as (
    select source_system, snapshot_id, source_table, count(*) as extracted,
        0::bigint as classified, 0::bigint as eligible, 0::bigint as rejected
    from {{ ref('legacy_records') }} group by 1, 2, 3
    union all
    select source_system, snapshot_id, source_table, 0, count(*),
        count(*) filter (where classification in ('accepted', 'corrected')),
        count(*) filter (where classification = 'rejected')
    from {{ ref('legacy_classifications') }} group by 1, 2, 3
)
select source_system, snapshot_id, source_table from counts
group by 1, 2, 3
having sum(extracted) <> sum(classified) or sum(extracted) <> sum(eligible) + sum(rejected)
