-- Classificação exclusiva com todos os achados; não consulta o manifesto.
with recursive
rules(code, action, reason) as (values
__RULES__
),
records as (
    select * from __RECORDS__
),
canonical as (
    select r.*,
        min(legacy_row_id) over (
            partition by source_system, snapshot_id, source_table, original_payload
        ) as canonical_row_id
    from records r
),
keys as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        r.original_payload, k.spec->'columns' as columns, v.key_value
    from records r
    cross join lateral jsonb_array_elements(r.record_contract->'unique_keys') k(spec)
    cross join lateral (
        select jsonb_agg(r.cleaned_payload->>c.name order by c.position) as key_value,
            bool_and(r.cleaned_payload->>c.name is not null) as complete
        from jsonb_array_elements_text(k.spec->'columns') with ordinality c(name, position)
    ) v
    where v.complete
    and not exists (
        select 1 from jsonb_array_elements(k.spec->'conditions') condition
        where not coalesce(case condition->>'kind'
            when 'is_null' then r.cleaned_payload->>(condition->>'column') is null
            when 'is_not_null' then r.cleaned_payload->>(condition->>'column') is not null
            when 'is_true' then r.cleaned_payload->>(condition->>'column') = 'true'
        end, false)
    )
),
conflicting_keys as (
    select source_system, snapshot_id, source_table, columns, key_value
    from keys
    group by source_system, snapshot_id, source_table, columns, key_value
    having count(distinct original_payload) > 1
),
references_to_parents as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        f.value->>'column' as column_name, f.value->>'table' as parent_table,
        f.value->>'key' as parent_key, r.cleaned_payload->>(f.value->>'column') as parent_value
    from records r
    cross join lateral jsonb_array_elements(r.record_contract->'references') f(value)
    where r.cleaned_payload->>(f.value->>'column') is not null
),
edges as (
    -- Excedente exato não vira pai: a referência resolve à canônica.
    select f.*, p.legacy_row_id as parent_row_id
    from references_to_parents f
    join canonical p on p.source_system = f.source_system and p.snapshot_id = f.snapshot_id
        and p.source_table = f.parent_table
        and p.cleaned_payload->>f.parent_key = f.parent_value
        and p.legacy_row_id = p.canonical_row_id
),
own_findings as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        f.key as column_name, f.value as code, '{}'::jsonb as context
    from records r cross join lateral jsonb_each_text(r.value_findings) f

    union all
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        c.name, 'NULL_REQUIRED', '{}'::jsonb
    from records r
    cross join lateral jsonb_array_elements_text(r.record_contract->'required') c(name)
    where r.cleaned_payload->>c.name is null

    union all
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        null::text, 'DUP_EXACT', jsonb_build_object('canonical_row_id', r.canonical_row_id)
    from canonical r where r.legacy_row_id <> r.canonical_row_id

    union all
    select distinct k.source_system, k.snapshot_id, k.source_table, k.legacy_row_id,
        null::text, 'DUP_PARTIAL', jsonb_build_object('key_columns', k.columns)
    from keys k join conflicting_keys f using (source_system, snapshot_id, source_table, columns, key_value)

    union all
    select f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id,
        f.column_name, 'FK_ORPHAN', jsonb_build_object('parent_table', f.parent_table, 'parent_key', f.parent_key)
    from references_to_parents f
    where not exists (
        select 1 from edges e
        where e.source_system = f.source_system and e.snapshot_id = f.snapshot_id
            and e.source_table = f.source_table and e.legacy_row_id = f.legacy_row_id
            and e.column_name = f.column_name
    )
),
base_roots as (
    select distinct f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id
    from own_findings f join rules on rules.code = f.code where rules.action = 'reject'
),
item_totals as (
    -- Soma **todos** os itens capturados do pedido, descontando apenas a
    -- duplicata exata — que contaria a mesma linha duas vezes.
    --
    -- Excluir aqui os itens já rejeitados, como esta consulta fazia, criava uma
    -- **circularidade**: a cascata tirava itens da soma, a soma deixava de
    -- bater com o subtotal, o pedido virava `TOTAL_MISMATCH`, e isso alimentava
    -- uma cascata maior. Media-se 114 pedidos não reconciliados de 177; contra
    -- todos os itens capturados, 175 reconciliam e 2 divergem de verdade.
    --
    -- O critério certo é o do negócio: o total declarado reconcilia com o que a
    -- origem **registrou**, e não com o que sobrou depois do tratamento. Se um
    -- item foi rejeitado por defeito próprio, isso é um achado do item — não
    -- torna o total do pedido inconsistente.
    select r.source_system, r.snapshot_id, r.cleaned_payload->>'order_id' as order_id,
        sum(case when pg_input_is_valid(r.cleaned_payload->>'quantity', 'numeric')
                      and pg_input_is_valid(r.cleaned_payload->>'unit_price', 'numeric')
                 then (r.cleaned_payload->>'quantity')::numeric * (r.cleaned_payload->>'unit_price')::numeric
            end) as gross_amount,
        bool_and(coalesce(pg_input_is_valid(r.cleaned_payload->>'quantity', 'numeric'), false)
            and coalesce(pg_input_is_valid(r.cleaned_payload->>'unit_price', 'numeric'), false)) as valid_amounts
    from records r
    where r.source_table = 'order_items' and not exists (
        select 1 from canonical c where c.source_system = r.source_system
            and c.snapshot_id = r.snapshot_id and c.source_table = r.source_table
            and c.legacy_row_id = r.legacy_row_id
            and c.legacy_row_id <> c.canonical_row_id
    )
    group by r.source_system, r.snapshot_id, r.cleaned_payload->>'order_id'
),
order_amounts as (
    select r.*,
        case when pg_input_is_valid(r.cleaned_payload->>'total_amount', 'numeric')
            then (r.cleaned_payload->>'total_amount')::numeric end as declared_total,
        case when pg_input_is_valid(r.cleaned_payload->>'subtotal_amount', 'numeric')
            then (r.cleaned_payload->>'subtotal_amount')::numeric end as declared_subtotal,
        case when pg_input_is_valid(r.cleaned_payload->>'discount_amount', 'numeric')
            and pg_input_is_valid(r.cleaned_payload->>'shipping_amount', 'numeric')
            and pg_input_is_valid(r.cleaned_payload->>'tax_amount', 'numeric')
            then -(r.cleaned_payload->>'discount_amount')::numeric
                + (r.cleaned_payload->>'shipping_amount')::numeric
                + (r.cleaned_payload->>'tax_amount')::numeric end as adjustments
    from records r where source_table = 'orders'
),
total_findings as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        'total_amount'::text as column_name, 'TOTAL_MISMATCH'::text as code,
        jsonb_build_object('declared_total', r.declared_total, 'declared_subtotal', r.declared_subtotal,
            'eligible_items_gross_amount', coalesce(i.gross_amount, 0)) as context
    from order_amounts r left join item_totals i on i.source_system = r.source_system
        and i.snapshot_id = r.snapshot_id and i.order_id = r.cleaned_payload->>'id'
    where r.declared_total <> r.declared_subtotal + r.adjustments
        or (coalesce(i.valid_amounts, true) and abs(r.declared_subtotal - coalesce(i.gross_amount, 0)) > __TOLERANCE__)
),
direct_findings as (
    select * from own_findings union all select * from total_findings
),
roots as (
    select * from base_roots
    union
    select source_system, snapshot_id, source_table, legacy_row_id from total_findings
),
rejected as (
    select * from roots
    union
    select e.source_system, e.snapshot_id, e.source_table, e.legacy_row_id
    from edges e join rejected p on p.source_system = e.source_system and p.snapshot_id = e.snapshot_id
        and p.source_table = e.parent_table and p.legacy_row_id = e.parent_row_id
),
all_findings as (
    select * from direct_findings
    union all
    select e.source_system, e.snapshot_id, e.source_table, e.legacy_row_id,
        e.column_name, 'PARENT_REJECTED',
        jsonb_build_object('parent_table', e.parent_table, 'parent_row_id', e.parent_row_id)
    from edges e join rejected p on p.source_system = e.source_system and p.snapshot_id = e.snapshot_id
        and p.source_table = e.parent_table and p.legacy_row_id = e.parent_row_id
    where not exists (
        select 1 from roots d where d.source_system = e.source_system and d.snapshot_id = e.snapshot_id
            and d.source_table = e.source_table and d.legacy_row_id = e.legacy_row_id
    )
),
summaries as (
    select f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id,
        bool_or(rules.action = 'reject') as has_rejection,
        bool_or(rules.action = 'correct') as has_correction,
        bool_or(rules.action = 'reject' and f.code not in ('DUP_EXACT', 'PARENT_REJECTED')) as own_invalid,
        bool_or(f.code = 'DUP_EXACT') as duplicate_excess,
        jsonb_agg(jsonb_build_object('code', f.code, 'column', f.column_name,
            'action', rules.action, 'reason', rules.reason, 'context', f.context,
            'original_value', r.original_payload->f.column_name,
            'cleaned_value', r.cleaned_payload->f.column_name)
            order by f.code, f.column_name, f.context::text) as findings
    from all_findings f join rules on rules.code = f.code
    join records r using (source_system, snapshot_id, source_table, legacy_row_id)
    group by f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id
)
select r.source_system, r.snapshot_id, r.snapshot_at, r.source_table, r.legacy_row_id,
    __VERSION__::integer as catalog_version,
    r.original_payload, r.cleaned_payload,
    case when s.has_rejection then 'rejected'
         when s.has_correction then 'corrected' else 'accepted' end::text as classification,
    case when s.own_invalid then 'own_invalid'
         when s.duplicate_excess then 'duplicate_excess'
         when s.has_rejection then 'parent_rejected' end::text as rejection_origin,
    coalesce(s.findings, '[]'::jsonb) as findings
from records r left join summaries s using (source_system, snapshot_id, source_table, legacy_row_id)
