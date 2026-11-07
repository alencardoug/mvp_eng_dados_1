-- Gerado por make legacy-models; altere legacy/classification.py ou classification.sql.
-- Classificação exclusiva com todos os achados; não consulta o manifesto.
{%- set parametros_da_impressao = {'as_of_date': '2026-09-01'} %}
{%- for nome, gravado in parametros_da_impressao.items() %}
{%- set efetivo = var(nome, '<ausente>') | string %}
{%- if efetivo != gravado %}
{{ exceptions.raise_compiler_error(
    "Configuração e artefato divergem: nesta execução " ~ nome ~ " vale " ~ efetivo ~
    ", mas a impressão digital deste modelo foi gerada com " ~ nome ~ "=" ~ gravado ~
    ". Rode `make legacy-models` para regerar, ou retire o --vars. D34: a mesma"
    " identidade de tratamento não pode cobrir dois resultados.") }}
{%- endif %}
{%- endfor %}
{% if target.type == 'bigquery' %}
-- Classificação exclusiva com todos os achados — versão BigQuery (Etapa 13, G1.1).
-- A MESMA regra de classification.sql, escrita para o BigQuery; a equivalência é
-- provada pelo oráculo semântico (mesmo bruto, os dois alvos, classificação igual
-- linha a linha), não por inspeção. As diferenças de dialeto, uma a uma:
--   * JSON não entra em PARTITION BY, GROUP BY nem DISTINCT: compara-se pelo
--     TO_JSON_STRING, que é estável porque todo payload nasce do mesmo JSON_OBJECT;
--   * `lateral jsonb_array_elements` vira UNNEST(JSON_QUERY_ARRAY(...)), e
--     `jsonb_each_text`, UNNEST(JSON_KEYS(..., 1));
--   * `payload->>coluna` com coluna dinâmica vira JSON_VALUE(payload[coluna]);
--   * `pg_input_is_valid(x, 'numeric')` vira SAFE_CAST(x AS BIGNUMERIC) IS NOT NULL;
--   * o recursivo do PostgreSQL usa UNION, que deduplica e por isso termina em ciclo;
--     o do BigQuery só aceita UNION ALL — a profundidade é limitada, e o modelo recusa
--     se alguma ocorrência só é alcançada no limite (rejected abaixo);
--   * ORDER BY ascendente põe nulo por último no PostgreSQL e primeiro no BigQuery:
--     a ordem do resultado leva `x is null` antes de cada chave anulável.
with recursive
rules as (
    select * from unnest(array<struct<code string, action string, reason string>>[
("NULL_DISGUISED", "correct", "Converter para nulo de verdade."),
("EMAIL_MALFORMED", "reject", "Endereço inválido; não há correção segura."),
("BOOL_VARIANT", "correct", "Mapear somente as variantes declaradas; `sim`, `S` e `1` são verdadeiro."),
("ENUM_UNKNOWN", "reject", "Estado desconhecido; mapear exigiria inventar equivalência."),
("DATE_IMPOSSIBLE", "reject", "Data impossível ou incompleta; não há valor único a inferir."),
("DATE_FUTURE", "reject", "Fato consumado não acontece no futuro."),
("DATE_FORMAT_KNOWN", "correct", "Interpretar pelo formato declarado e normalizar para ISO."),
("DATE_TZ_MISSING", "correct", "Aplicar o fuso declarado da origem — `America/Sao_Paulo`."),
("DATE_UNPARSEABLE", "reject", "Não há data a inferir de um texto que não é data."),
("NUM_OUT_OF_RANGE", "reject", "Quantidade impossível; corrigir exigiria adivinhar o valor certo."),
("NUM_TEXT_EQUIV", "correct", "Interpretar por extenso ou com casa decimal nula; `oito`, `8.0` e `8,0` são 8."),
("NUM_AMBIGUOUS", "reject", "Não há regra determinística válida para o grão."),
("MONEY_NEGATIVE", "reject", "Valor negativo onde o domínio não o permite."),
("MONEY_LOCALE", "correct", "Normalizar locale e moeda antes da conversão decimal; `R$ 1.234,56` é 1234.56."),
("MONEY_AMBIGUOUS", "reject", "Não há interpretação única para o valor; converter exigiria adivinhar o separador."),
("TEXT_TRUNCATED", "reject", "O que foi perdido no corte não se restaura."),
("TEXT_DELIMITER", "reject", "A linha veio deslocada na importação; o conteúdo dos campos seguintes se perdeu."),
("TEXT_ENCODING", "correct", "Reverter o par de codificações quando ele é identificável; `JosÃ©` é `José`."),
("TEXT_ENCODING_AMBIGUOUS", "reject", "Reverter só o trecho reconhecido corromperia o resto da célula."),
("TEXT_WHITESPACE_CASE", "correct", "Padronizar espaçamento e caixa conforme a convenção do campo."),
("FK_ORPHAN", "reject", "A linha aponta para um registro que não existe."),
("DUP_EXACT", "reject", "Ocorrência excedente de duplicata exata; a canônica foi mantida."),
("DUP_PARTIAL", "reject", "Não há critério de desempate seguro entre as versões."),
("TOTAL_MISMATCH", "reject", "O total não reconcilia com os itens; corrigir exigiria escolher qual lado vale."),
("NULL_REQUIRED", "reject", "Ausência de valor obrigatório; preencher exigiria inventar um valor de negócio."),
("PARENT_REJECTED", "reject", "O pai foi rejeitado; empilhar o filho produziria fato sem a entidade que o explica.")
    ])
),
records as (
    select * from {{ ref('legacy_records') }}
),
canonical as (
    select r.*,
        min(legacy_row_id) over (
            partition by source_system, snapshot_id, source_table, to_json_string(original_payload)
        ) as canonical_row_id
    from records r
),
keys as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        to_json_string(r.original_payload) as original_payload_text,
        to_json_string(spec['columns']) as columns,
        to_json_string(array(
            -- O coalesce só protege o ARRAY de elemento nulo: as chaves com nulo saem no `where`.
            select coalesce(json_value(r.cleaned_payload[c]), '')
            from unnest(json_value_array(spec['columns'])) c with offset position
            order by position
        )) as key_value
    from records r
    cross join unnest(json_query_array(r.record_contract['unique_keys'])) spec
    where not exists (
        select 1 from unnest(json_value_array(spec['columns'])) c
        where json_value(r.cleaned_payload[c]) is null
    )
    and not exists (
        select 1 from unnest(json_query_array(spec['conditions'])) condition
        where not coalesce(case json_value(condition['kind'])
            when 'is_null' then json_value(r.cleaned_payload[json_value(condition['column'])]) is null
            when 'is_not_null' then json_value(r.cleaned_payload[json_value(condition['column'])]) is not null
            when 'is_true' then json_value(r.cleaned_payload[json_value(condition['column'])]) = 'true'
        end, false)
    )
),
conflicting_keys as (
    select source_system, snapshot_id, source_table, columns, key_value
    from keys
    group by source_system, snapshot_id, source_table, columns, key_value
    having count(distinct original_payload_text) > 1
),
references_to_parents as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        json_value(f['column']) as column_name, json_value(f['table']) as parent_table,
        json_value(f['key']) as parent_key,
        json_value(r.cleaned_payload[json_value(f['column'])]) as parent_value
    from records r
    cross join unnest(json_query_array(r.record_contract['references'])) f
    where json_value(r.cleaned_payload[json_value(f['column'])]) is not null
),
edges as (
    -- Excedente exato não vira pai: a referência resolve à canônica.
    select f.*, p.legacy_row_id as parent_row_id
    from references_to_parents f
    join canonical p on p.source_system = f.source_system and p.snapshot_id = f.snapshot_id
        and p.source_table = f.parent_table
        and json_value(p.cleaned_payload[f.parent_key]) = f.parent_value
        and p.legacy_row_id = p.canonical_row_id
),
own_findings as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        k as column_name, json_value(r.value_findings[k]) as code, json '{}' as context
    from records r cross join unnest(json_keys(r.value_findings, 1)) k

    union all
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        c, 'NULL_REQUIRED', json '{}'
    from records r
    cross join unnest(json_value_array(r.record_contract['required'])) c
    where json_value(r.cleaned_payload[c]) is null

    union all
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        cast(null as string), 'DUP_EXACT', json_object('canonical_row_id', r.canonical_row_id)
    from canonical r where r.legacy_row_id <> r.canonical_row_id

    union all
    select d.source_system, d.snapshot_id, d.source_table, d.legacy_row_id,
        cast(null as string), 'DUP_PARTIAL', json_object('key_columns', parse_json(d.columns))
    from (
        select distinct k.source_system, k.snapshot_id, k.source_table, k.legacy_row_id, k.columns
        from keys k join conflicting_keys f using (source_system, snapshot_id, source_table, columns, key_value)
    ) d

    union all
    select f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id,
        f.column_name, 'FK_ORPHAN', json_object('parent_table', f.parent_table, 'parent_key', f.parent_key)
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
    -- O mesmo critério de classification.sql: todos os itens capturados do pedido,
    -- descontada só a duplicata exata.
    select r.source_system, r.snapshot_id, json_value(r.cleaned_payload['order_id']) as order_id,
        sum(case when safe_cast(json_value(r.cleaned_payload['quantity']) as bignumeric) is not null
                      and safe_cast(json_value(r.cleaned_payload['unit_price']) as bignumeric) is not null
                 then cast(json_value(r.cleaned_payload['quantity']) as bignumeric)
                    * cast(json_value(r.cleaned_payload['unit_price']) as bignumeric)
            end) as gross_amount,
        logical_and(safe_cast(json_value(r.cleaned_payload['quantity']) as bignumeric) is not null
            and safe_cast(json_value(r.cleaned_payload['unit_price']) as bignumeric) is not null) as valid_amounts
    from records r
    where r.source_table = 'order_items' and not exists (
        select 1 from canonical c where c.source_system = r.source_system
            and c.snapshot_id = r.snapshot_id and c.source_table = r.source_table
            and c.legacy_row_id = r.legacy_row_id
            and c.legacy_row_id <> c.canonical_row_id
    )
    group by r.source_system, r.snapshot_id, json_value(r.cleaned_payload['order_id'])
),
order_amounts as (
    select r.*,
        safe_cast(json_value(r.cleaned_payload['total_amount']) as bignumeric) as declared_total,
        safe_cast(json_value(r.cleaned_payload['subtotal_amount']) as bignumeric) as declared_subtotal,
        case when safe_cast(json_value(r.cleaned_payload['discount_amount']) as bignumeric) is not null
            and safe_cast(json_value(r.cleaned_payload['shipping_amount']) as bignumeric) is not null
            and safe_cast(json_value(r.cleaned_payload['tax_amount']) as bignumeric) is not null
            then -cast(json_value(r.cleaned_payload['discount_amount']) as bignumeric)
                + cast(json_value(r.cleaned_payload['shipping_amount']) as bignumeric)
                + cast(json_value(r.cleaned_payload['tax_amount']) as bignumeric) end as adjustments
    from records r where source_table = 'orders'
),
total_findings as (
    select r.source_system, r.snapshot_id, r.source_table, r.legacy_row_id,
        'total_amount' as column_name, 'TOTAL_MISMATCH' as code,
        json_object('declared_total', r.declared_total, 'declared_subtotal', r.declared_subtotal,
            'eligible_items_gross_amount', coalesce(i.gross_amount, 0)) as context
    from order_amounts r left join item_totals i on i.source_system = r.source_system
        and i.snapshot_id = r.snapshot_id and i.order_id = json_value(r.cleaned_payload['id'])
    where r.declared_total <> r.declared_subtotal + r.adjustments
        or (coalesce(i.valid_amounts, true) and abs(r.declared_subtotal - coalesce(i.gross_amount, 0)) > 0.01)
),
direct_findings as (
    select * from own_findings union all select * from total_findings
),
roots as (
    select source_system, snapshot_id, source_table, legacy_row_id from base_roots
    union distinct
    select source_system, snapshot_id, source_table, legacy_row_id from total_findings
),
rejected_walk as (
    select source_system, snapshot_id, source_table, legacy_row_id, 0 as depth from roots
    union all
    select e.source_system, e.snapshot_id, e.source_table, e.legacy_row_id, p.depth + 1
    from edges e join rejected_walk p on p.source_system = e.source_system and p.snapshot_id = e.snapshot_id
        and p.source_table = e.parent_table and p.legacy_row_id = e.parent_row_id
    where p.depth < 64
),
rejected as (
    -- A menor profundidade de cada ocorrência. Se alguma só aparece na 64, pode haver
    -- caminho mais longo que o limite cortou — a cascata estaria incompleta (guarda no
    -- `where` final). Ciclo não dispara: no ciclo, a ocorrência já apareceu antes.
    select source_system, snapshot_id, source_table, legacy_row_id, min(depth) as depth
    from rejected_walk
    group by source_system, snapshot_id, source_table, legacy_row_id
),
all_findings as (
    select * from direct_findings
    union all
    select e.source_system, e.snapshot_id, e.source_table, e.legacy_row_id,
        e.column_name, 'PARENT_REJECTED',
        json_object('parent_table', e.parent_table, 'parent_row_id', e.parent_row_id)
    from edges e join rejected p on p.source_system = e.source_system and p.snapshot_id = e.snapshot_id
        and p.source_table = e.parent_table and p.legacy_row_id = e.parent_row_id
    -- O `not exists` do PostgreSQL, como anti-junção: o BigQuery não descorrelaciona o
    -- subquery sobre `roots` (uma `union distinct`).
    left join roots d on d.source_system = e.source_system and d.snapshot_id = e.snapshot_id
        and d.source_table = e.source_table and d.legacy_row_id = e.legacy_row_id
    where d.legacy_row_id is null
),
summaries as (
    select f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id,
        logical_or(rules.action = 'reject') as has_rejection,
        logical_or(rules.action = 'correct') as has_correction,
        logical_or(rules.action = 'reject' and f.code not in ('DUP_EXACT', 'PARENT_REJECTED')) as own_invalid,
        logical_or(f.code = 'DUP_EXACT') as duplicate_excess,
        to_json(array_agg(json_object('code', f.code, 'column', f.column_name,
            'action', rules.action, 'reason', rules.reason, 'context', f.context,
            'original_value', r.original_payload[f.column_name],
            'cleaned_value', r.cleaned_payload[f.column_name])
            -- Agregado do BigQuery não aceita NULLS LAST em ordem ascendente: o `is null`
            -- antes de cada chave põe o nulo por último, como no PostgreSQL. O código nunca é nulo.
            order by f.code, f.column_name is null, f.column_name,
                to_json_string(f.context) is null, to_json_string(f.context))) as findings
    from all_findings f join rules on rules.code = f.code
    join records r using (source_system, snapshot_id, source_table, legacy_row_id)
    group by f.source_system, f.snapshot_id, f.source_table, f.legacy_row_id
)
select r.source_system, r.snapshot_id, r.snapshot_at, r.source_table, r.legacy_row_id,
    cast(9 as int64) as catalog_version,
    -- A impressão digital do tratamento é a do texto PostgreSQL (D34): esta versão
    -- é a mesma regra noutro dialeto, provada igual pelo oráculo semântico.
    "607e6288f4f57e39" as treatment_fingerprint,
    r.original_payload, r.cleaned_payload,
    case when s.has_rejection then 'rejected'
         when s.has_correction then 'corrected' else 'accepted' end as classification,
    case when s.own_invalid then 'own_invalid'
         when s.duplicate_excess then 'duplicate_excess'
         when s.has_rejection then 'parent_rejected' end as rejection_origin,
    coalesce(s.findings, json '[]') as findings
from records r left join summaries s using (source_system, snapshot_id, source_table, legacy_row_id)
where if(exists(select 1 from rejected where depth >= 64),
    error('cascata de rejeição com ocorrência na profundidade 64: aumente o limite'), true)
{% else %}with recursive
rules(code, action, reason) as (values
('NULL_DISGUISED', 'correct', 'Converter para nulo de verdade.'),
('EMAIL_MALFORMED', 'reject', 'Endereço inválido; não há correção segura.'),
('BOOL_VARIANT', 'correct', 'Mapear somente as variantes declaradas; `sim`, `S` e `1` são verdadeiro.'),
('ENUM_UNKNOWN', 'reject', 'Estado desconhecido; mapear exigiria inventar equivalência.'),
('DATE_IMPOSSIBLE', 'reject', 'Data impossível ou incompleta; não há valor único a inferir.'),
('DATE_FUTURE', 'reject', 'Fato consumado não acontece no futuro.'),
('DATE_FORMAT_KNOWN', 'correct', 'Interpretar pelo formato declarado e normalizar para ISO.'),
('DATE_TZ_MISSING', 'correct', 'Aplicar o fuso declarado da origem — `America/Sao_Paulo`.'),
('DATE_UNPARSEABLE', 'reject', 'Não há data a inferir de um texto que não é data.'),
('NUM_OUT_OF_RANGE', 'reject', 'Quantidade impossível; corrigir exigiria adivinhar o valor certo.'),
('NUM_TEXT_EQUIV', 'correct', 'Interpretar por extenso ou com casa decimal nula; `oito`, `8.0` e `8,0` são 8.'),
('NUM_AMBIGUOUS', 'reject', 'Não há regra determinística válida para o grão.'),
('MONEY_NEGATIVE', 'reject', 'Valor negativo onde o domínio não o permite.'),
('MONEY_LOCALE', 'correct', 'Normalizar locale e moeda antes da conversão decimal; `R$ 1.234,56` é 1234.56.'),
('MONEY_AMBIGUOUS', 'reject', 'Não há interpretação única para o valor; converter exigiria adivinhar o separador.'),
('TEXT_TRUNCATED', 'reject', 'O que foi perdido no corte não se restaura.'),
('TEXT_DELIMITER', 'reject', 'A linha veio deslocada na importação; o conteúdo dos campos seguintes se perdeu.'),
('TEXT_ENCODING', 'correct', 'Reverter o par de codificações quando ele é identificável; `JosÃ©` é `José`.'),
('TEXT_ENCODING_AMBIGUOUS', 'reject', 'Reverter só o trecho reconhecido corromperia o resto da célula.'),
('TEXT_WHITESPACE_CASE', 'correct', 'Padronizar espaçamento e caixa conforme a convenção do campo.'),
('FK_ORPHAN', 'reject', 'A linha aponta para um registro que não existe.'),
('DUP_EXACT', 'reject', 'Ocorrência excedente de duplicata exata; a canônica foi mantida.'),
('DUP_PARTIAL', 'reject', 'Não há critério de desempate seguro entre as versões.'),
('TOTAL_MISMATCH', 'reject', 'O total não reconcilia com os itens; corrigir exigiria escolher qual lado vale.'),
('NULL_REQUIRED', 'reject', 'Ausência de valor obrigatório; preencher exigiria inventar um valor de negócio.'),
('PARENT_REJECTED', 'reject', 'O pai foi rejeitado; empilhar o filho produziria fato sem a entidade que o explica.')
),
records as (
    select * from {{ ref('legacy_records') }}
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
        or (coalesce(i.valid_amounts, true) and abs(r.declared_subtotal - coalesce(i.gross_amount, 0)) > 0.01)
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
    9::integer as catalog_version,
    -- Impressão digital do tratamento (D34): a versão é o rótulo humano, esta
    -- é a identidade do que ele de fato produz. É por ela que a quarentena
    -- recusa substituir uma auditoria sob a mesma versão.
    '607e6288f4f57e39'::text as treatment_fingerprint,
    r.original_payload, r.cleaned_payload,
    case when s.has_rejection then 'rejected'
         when s.has_correction then 'corrected' else 'accepted' end::text as classification,
    case when s.own_invalid then 'own_invalid'
         when s.duplicate_excess then 'duplicate_excess'
         when s.has_rejection then 'parent_rejected' end::text as rejection_origin,
    coalesce(s.findings, '[]'::jsonb) as findings
from records r left join summaries s using (source_system, snapshot_id, source_table, legacy_row_id){% endif %}
