-- Nenhum fato apto depende de pai órfão ou rejeitado na mesma captura.
with eligible as (
    select * from {{ ref('legacy_eligible_records') }}
)
{#- O BigQuery não tem `lateral` nem `->>` (Etapa 13, G1): a lista de referências vira
    UNNEST, e o `not exists` correlacionado, anti-junção. -#}
{% if target.type == 'bigquery' -%}
select c.source_system, c.snapshot_id, c.source_table, c.legacy_row_id, to_json_string(f) as reference
from eligible c
join {{ ref('legacy_records') }} r using (source_system, snapshot_id, source_table, legacy_row_id)
cross join unnest(json_query_array(r.record_contract['references'])) f
left join eligible p
    on p.source_system = c.source_system and p.snapshot_id = c.snapshot_id
    and p.source_table = json_value(f['table'])
    and json_value(p.cleaned_payload[json_value(f['key'])]) = json_value(c.cleaned_payload[json_value(f['column'])])
where json_value(c.cleaned_payload[json_value(f['column'])]) is not null
and p.legacy_row_id is null
{%- else -%}
select c.source_system, c.snapshot_id, c.source_table, c.legacy_row_id, f.value as reference
from eligible c
join {{ ref('legacy_records') }} r using (source_system, snapshot_id, source_table, legacy_row_id)
cross join lateral jsonb_array_elements(r.record_contract->'references') f(value)
where c.cleaned_payload->>(f.value->>'column') is not null
and not exists (
    select 1 from eligible p
    where p.source_system = c.source_system and p.snapshot_id = c.snapshot_id
        and p.source_table = f.value->>'table'
        and p.cleaned_payload->>(f.value->>'key') = c.cleaned_payload->>(f.value->>'column')
)
{%- endif %}
