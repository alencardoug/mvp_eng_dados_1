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
WITH RECURSIVE rules AS (
  SELECT
    *
  FROM UNNEST([
    STRUCT('NULL_DISGUISED' AS _c0, 'correct' AS _c1, 'Converter para nulo de verdade.' AS _c2),
    STRUCT(
      'EMAIL_MALFORMED' AS _c0,
      'reject' AS _c1,
      'Endereço inválido; não há correção segura.' AS _c2
    ),
    STRUCT(
      'BOOL_VARIANT' AS _c0,
      'correct' AS _c1,
      'Mapear somente as variantes declaradas; `sim`, `S` e `1` são verdadeiro.' AS _c2
    ),
    STRUCT(
      'ENUM_UNKNOWN' AS _c0,
      'reject' AS _c1,
      'Estado desconhecido; mapear exigiria inventar equivalência.' AS _c2
    ),
    STRUCT(
      'DATE_IMPOSSIBLE' AS _c0,
      'reject' AS _c1,
      'Data impossível ou incompleta; não há valor único a inferir.' AS _c2
    ),
    STRUCT(
      'DATE_FUTURE' AS _c0,
      'reject' AS _c1,
      'Fato consumado não acontece no futuro.' AS _c2
    ),
    STRUCT(
      'DATE_FORMAT_KNOWN' AS _c0,
      'correct' AS _c1,
      'Interpretar pelo formato declarado e normalizar para ISO.' AS _c2
    ),
    STRUCT(
      'DATE_TZ_MISSING' AS _c0,
      'correct' AS _c1,
      'Aplicar o fuso declarado da origem — `America/Sao_Paulo`.' AS _c2
    ),
    STRUCT(
      'DATE_UNPARSEABLE' AS _c0,
      'reject' AS _c1,
      'Não há data a inferir de um texto que não é data.' AS _c2
    ),
    STRUCT(
      'NUM_OUT_OF_RANGE' AS _c0,
      'reject' AS _c1,
      'Quantidade impossível; corrigir exigiria adivinhar o valor certo.' AS _c2
    ),
    STRUCT(
      'NUM_TEXT_EQUIV' AS _c0,
      'correct' AS _c1,
      'Interpretar por extenso ou com casa decimal nula; `oito`, `8.0` e `8,0` são 8.' AS _c2
    ),
    STRUCT(
      'NUM_AMBIGUOUS' AS _c0,
      'reject' AS _c1,
      'Não há regra determinística válida para o grão.' AS _c2
    ),
    STRUCT(
      'MONEY_NEGATIVE' AS _c0,
      'reject' AS _c1,
      'Valor negativo onde o domínio não o permite.' AS _c2
    ),
    STRUCT(
      'MONEY_LOCALE' AS _c0,
      'correct' AS _c1,
      'Normalizar locale e moeda antes da conversão decimal; `R$ 1.234,56` é 1234.56.' AS _c2
    ),
    STRUCT(
      'MONEY_AMBIGUOUS' AS _c0,
      'reject' AS _c1,
      'Não há interpretação única para o valor; converter exigiria adivinhar o separador.' AS _c2
    ),
    STRUCT(
      'TEXT_TRUNCATED' AS _c0,
      'reject' AS _c1,
      'O que foi perdido no corte não se restaura.' AS _c2
    ),
    STRUCT(
      'TEXT_DELIMITER' AS _c0,
      'reject' AS _c1,
      'A linha veio deslocada na importação; o conteúdo dos campos seguintes se perdeu.' AS _c2
    ),
    STRUCT(
      'TEXT_ENCODING' AS _c0,
      'correct' AS _c1,
      'Reverter o par de codificações quando ele é identificável; `JosÃ©` é `José`.' AS _c2
    ),
    STRUCT(
      'TEXT_ENCODING_AMBIGUOUS' AS _c0,
      'reject' AS _c1,
      'Reverter só o trecho reconhecido corromperia o resto da célula.' AS _c2
    ),
    STRUCT(
      'TEXT_WHITESPACE_CASE' AS _c0,
      'correct' AS _c1,
      'Padronizar espaçamento e caixa conforme a convenção do campo.' AS _c2
    ),
    STRUCT(
      'FK_ORPHAN' AS _c0,
      'reject' AS _c1,
      'A linha aponta para um registro que não existe.' AS _c2
    ),
    STRUCT(
      'DUP_EXACT' AS _c0,
      'reject' AS _c1,
      'Ocorrência excedente de duplicata exata; a canônica foi mantida.' AS _c2
    ),
    STRUCT(
      'DUP_PARTIAL' AS _c0,
      'reject' AS _c1,
      'Não há critério de desempate seguro entre as versões.' AS _c2
    ),
    STRUCT(
      'TOTAL_MISMATCH' AS _c0,
      'reject' AS _c1,
      'O total não reconcilia com os itens; corrigir exigiria escolher qual lado vale.' AS _c2
    ),
    STRUCT(
      'NULL_REQUIRED' AS _c0,
      'reject' AS _c1,
      'Ausência de valor obrigatório; preencher exigiria inventar um valor de negócio.' AS _c2
    ),
    STRUCT(
      'PARENT_REJECTED' AS _c0,
      'reject' AS _c1,
      'O pai foi rejeitado; empilhar o filho produziria fato sem a entidade que o explica.' AS _c2
    )
  ]) AS _values
), records AS (
  SELECT
    *
  FROM {{ ref('legacy_records') }}
), canonical AS (
  SELECT
    r.*,
    MIN(legacy_row_id) OVER (PARTITION BY source_system, snapshot_id, source_table, original_payload) AS canonical_row_id
  FROM records AS r
), keys AS (
  SELECT
    r.source_system,
    r.snapshot_id,
    r.source_table,
    r.legacy_row_id,
    r.original_payload,
    JSON_EXTRACT(k.spec, '$.columns') AS columns,
    v.key_value
  FROM records AS r
  CROSS JOIN LATERAL jsonb_array_elements(JSON_EXTRACT(r.record_contract, '$.unique_keys')) AS k
  CROSS JOIN LATERAL (
    SELECT
      TO_JSON(ARRAY_AGG(JSON_EXTRACT_SCALAR(r.cleaned_payload, c.name) ORDER BY c.position)) AS key_value,
      LOGICAL_AND(JSON_EXTRACT_SCALAR(r.cleaned_payload, c.name) IS NOT NULL) AS complete
    FROM jsonb_array_elements_text(JSON_EXTRACT(k.spec, '$.columns')) WITH ORDINALITY AS c
  ) AS v
  WHERE
    v.complete
    AND NOT EXISTS(
      SELECT
        1
      FROM jsonb_array_elements(JSON_EXTRACT(k.spec, '$.conditions')) AS condition
      WHERE
        NOT COALESCE(
          CASE JSON_EXTRACT_SCALAR(condition, '$.kind')
            WHEN 'is_null'
            THEN JSON_EXTRACT_SCALAR(r.cleaned_payload, (
              JSON_EXTRACT_SCALAR(condition, '$.column')
            )) IS NULL
            WHEN 'is_not_null'
            THEN JSON_EXTRACT_SCALAR(r.cleaned_payload, (
              JSON_EXTRACT_SCALAR(condition, '$.column')
            )) IS NOT NULL
            WHEN 'is_true'
            THEN JSON_EXTRACT_SCALAR(r.cleaned_payload, (
              JSON_EXTRACT_SCALAR(condition, '$.column')
            )) = 'true'
          END,
          FALSE
        )
    )
), conflicting_keys AS (
  SELECT
    source_system,
    snapshot_id,
    source_table,
    columns,
    key_value
  FROM keys
  GROUP BY
    source_system,
    snapshot_id,
    source_table,
    columns,
    key_value
  HAVING
    COUNT(DISTINCT original_payload) > 1
), references_to_parents AS (
  SELECT
    r.source_system,
    r.snapshot_id,
    r.source_table,
    r.legacy_row_id,
    JSON_EXTRACT_SCALAR(f.value, '$.column') AS column_name,
    JSON_EXTRACT_SCALAR(f.value, '$.table') AS parent_table,
    JSON_EXTRACT_SCALAR(f.value, '$.key') AS parent_key,
    JSON_EXTRACT_SCALAR(r.cleaned_payload, (
      JSON_EXTRACT_SCALAR(f.value, '$.column')
    )) AS parent_value
  FROM records AS r
  CROSS JOIN LATERAL jsonb_array_elements(JSON_EXTRACT(r.record_contract, '$.references')) AS f
  WHERE
    JSON_EXTRACT_SCALAR(r.cleaned_payload, (
      JSON_EXTRACT_SCALAR(f.value, '$.column')
    )) IS NOT NULL
), edges AS (
  /* Excedente exato não vira pai: a referência resolve à canônica. */
  SELECT
    f.*,
    p.legacy_row_id AS parent_row_id
  FROM references_to_parents AS f
  JOIN canonical AS p
    ON p.source_system = f.source_system
    AND p.snapshot_id = f.snapshot_id
    AND p.source_table = f.parent_table
    AND JSON_EXTRACT_SCALAR(p.cleaned_payload, f.parent_key) = f.parent_value
    AND p.legacy_row_id = p.canonical_row_id
), own_findings AS (
  SELECT
    r.source_system,
    r.snapshot_id,
    r.source_table,
    r.legacy_row_id,
    f.key AS column_name,
    f.value AS code,
    CAST('{}' AS JSONB) AS context
  FROM records AS r
  CROSS JOIN LATERAL jsonb_each_text(r.value_findings) AS f
  UNION ALL
  SELECT
    r.source_system,
    r.snapshot_id,
    r.source_table,
    r.legacy_row_id,
    c.name,
    'NULL_REQUIRED',
    CAST('{}' AS JSONB)
  FROM records AS r
  CROSS JOIN LATERAL jsonb_array_elements_text(JSON_EXTRACT(r.record_contract, '$.required')) AS c
  WHERE
    JSON_EXTRACT_SCALAR(r.cleaned_payload, c.name) IS NULL
  UNION ALL
  SELECT
    r.source_system,
    r.snapshot_id,
    r.source_table,
    r.legacy_row_id,
    CAST(NULL AS STRING),
    'DUP_EXACT',
    JSON_OBJECT('canonical_row_id', r.canonical_row_id)
  FROM canonical AS r
  WHERE
    r.legacy_row_id <> r.canonical_row_id
  UNION ALL
  SELECT DISTINCT
    k.source_system,
    k.snapshot_id,
    k.source_table,
    k.legacy_row_id,
    CAST(NULL AS STRING),
    'DUP_PARTIAL',
    JSON_OBJECT('key_columns', k.columns)
  FROM keys AS k
  JOIN conflicting_keys AS f
    USING (source_system, snapshot_id, source_table, columns, key_value)
  UNION ALL
  SELECT
    f.source_system,
    f.snapshot_id,
    f.source_table,
    f.legacy_row_id,
    f.column_name,
    'FK_ORPHAN',
    JSON_OBJECT('parent_table', f.parent_table, 'parent_key', f.parent_key)
  FROM references_to_parents AS f
  WHERE
    NOT EXISTS(
      SELECT
        1
      FROM edges AS e
      WHERE
        e.source_system = f.source_system
        AND e.snapshot_id = f.snapshot_id
        AND e.source_table = f.source_table
        AND e.legacy_row_id = f.legacy_row_id
        AND e.column_name = f.column_name
    )
), base_roots AS (
  SELECT DISTINCT
    f.source_system,
    f.snapshot_id,
    f.source_table,
    f.legacy_row_id
  FROM own_findings AS f
  JOIN rules
    ON rules.code = f.code
  WHERE
    rules.action = 'reject'
), item_totals AS (
  /* Soma **todos** os itens capturados do pedido, descontando apenas a */
  /* duplicata exata — que contaria a mesma linha duas vezes. */
  /* Excluir aqui os itens já rejeitados, como esta consulta fazia, criava uma */
  /* **circularidade**: a cascata tirava itens da soma, a soma deixava de */
  /* bater com o subtotal, o pedido virava `TOTAL_MISMATCH`, e isso alimentava */
  /* uma cascata maior. Media-se 114 pedidos não reconciliados de 177; contra */
  /* todos os itens capturados, 175 reconciliam e 2 divergem de verdade. */
  /* O critério certo é o do negócio: o total declarado reconcilia com o que a */
  /* origem **registrou**, e não com o que sobrou depois do tratamento. Se um */
  /* item foi rejeitado por defeito próprio, isso é um achado do item — não */
  /* torna o total do pedido inconsistente. */
  SELECT
    r.source_system,
    r.snapshot_id,
    JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.order_id') AS order_id,
    SUM(
      CASE
        WHEN pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.quantity'), 'numeric')
        AND pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.unit_price'), 'numeric')
        THEN CAST((
          JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.quantity')
        ) AS NUMERIC) * CAST((
          JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.unit_price')
        ) AS NUMERIC)
      END
    ) AS gross_amount,
    LOGICAL_AND(
      COALESCE(
        pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.quantity'), 'numeric'),
        FALSE
      )
      AND COALESCE(
        pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.unit_price'), 'numeric'),
        FALSE
      )
    ) AS valid_amounts
  FROM records AS r
  WHERE
    r.source_table = 'order_items'
    AND NOT EXISTS(
      SELECT
        1
      FROM canonical AS c
      WHERE
        c.source_system = r.source_system
        AND c.snapshot_id = r.snapshot_id
        AND c.source_table = r.source_table
        AND c.legacy_row_id = r.legacy_row_id
        AND c.legacy_row_id <> c.canonical_row_id
    )
  GROUP BY
    r.source_system,
    r.snapshot_id,
    JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.order_id')
), order_amounts AS (
  SELECT
    r.*,
    CASE
      WHEN pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.total_amount'), 'numeric')
      THEN CAST((
        JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.total_amount')
      ) AS NUMERIC)
    END AS declared_total,
    CASE
      WHEN pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.subtotal_amount'), 'numeric')
      THEN CAST((
        JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.subtotal_amount')
      ) AS NUMERIC)
    END AS declared_subtotal,
    CASE
      WHEN pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.discount_amount'), 'numeric')
      AND pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.shipping_amount'), 'numeric')
      AND pg_input_is_valid(JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.tax_amount'), 'numeric')
      THEN -CAST((
        JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.discount_amount')
      ) AS NUMERIC) + CAST((
        JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.shipping_amount')
      ) AS NUMERIC) + CAST((
        JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.tax_amount')
      ) AS NUMERIC)
    END AS adjustments
  FROM records AS r
  WHERE
    source_table = 'orders'
), total_findings AS (
  SELECT
    r.source_system,
    r.snapshot_id,
    r.source_table,
    r.legacy_row_id,
    CAST('total_amount' AS STRING) AS column_name,
    CAST('TOTAL_MISMATCH' AS STRING) AS code,
    JSON_OBJECT(
      'declared_total',
      r.declared_total,
      'declared_subtotal',
      r.declared_subtotal,
      'eligible_items_gross_amount',
      COALESCE(i.gross_amount, 0)
    ) AS context
  FROM order_amounts AS r
  LEFT JOIN item_totals AS i
    ON i.source_system = r.source_system
    AND i.snapshot_id = r.snapshot_id
    AND i.order_id = JSON_EXTRACT_SCALAR(r.cleaned_payload, '$.id')
  WHERE
    r.declared_total <> r.declared_subtotal + r.adjustments
    OR (
      COALESCE(i.valid_amounts, TRUE)
      AND ABS(r.declared_subtotal - COALESCE(i.gross_amount, 0)) > 0.01
    )
), direct_findings AS (
  SELECT
    *
  FROM own_findings
  UNION ALL
  SELECT
    *
  FROM total_findings
), roots AS (
  SELECT
    *
  FROM base_roots
  UNION DISTINCT
  SELECT
    source_system,
    snapshot_id,
    source_table,
    legacy_row_id
  FROM total_findings
), rejected AS (
  SELECT
    *
  FROM roots
  UNION DISTINCT
  SELECT
    e.source_system,
    e.snapshot_id,
    e.source_table,
    e.legacy_row_id
  FROM edges AS e
  JOIN rejected AS p
    ON p.source_system = e.source_system
    AND p.snapshot_id = e.snapshot_id
    AND p.source_table = e.parent_table
    AND p.legacy_row_id = e.parent_row_id
), all_findings AS (
  SELECT
    *
  FROM direct_findings
  UNION ALL
  SELECT
    e.source_system,
    e.snapshot_id,
    e.source_table,
    e.legacy_row_id,
    e.column_name,
    'PARENT_REJECTED',
    JSON_OBJECT('parent_table', e.parent_table, 'parent_row_id', e.parent_row_id)
  FROM edges AS e
  JOIN rejected AS p
    ON p.source_system = e.source_system
    AND p.snapshot_id = e.snapshot_id
    AND p.source_table = e.parent_table
    AND p.legacy_row_id = e.parent_row_id
  WHERE
    NOT EXISTS(
      SELECT
        1
      FROM roots AS d
      WHERE
        d.source_system = e.source_system
        AND d.snapshot_id = e.snapshot_id
        AND d.source_table = e.source_table
        AND d.legacy_row_id = e.legacy_row_id
    )
), summaries AS (
  SELECT
    f.source_system,
    f.snapshot_id,
    f.source_table,
    f.legacy_row_id,
    LOGICAL_OR(rules.action = 'reject') AS has_rejection,
    LOGICAL_OR(rules.action = 'correct') AS has_correction,
    LOGICAL_OR(rules.action = 'reject' AND NOT f.code IN ('DUP_EXACT', 'PARENT_REJECTED')) AS own_invalid,
    LOGICAL_OR(f.code = 'DUP_EXACT') AS duplicate_excess,
    TO_JSON(
      ARRAY_AGG(
        JSON_OBJECT(
          'code',
          f.code,
          'column',
          f.column_name,
          'action',
          rules.action,
          'reason',
          rules.reason,
          'context',
          f.context,
          'original_value',
          JSON_EXTRACT(r.original_payload, f.column_name),
          'cleaned_value',
          JSON_EXTRACT(r.cleaned_payload, f.column_name)
        ) ORDER BY f.code, f.column_name, CAST(f.context AS STRING)
      )
    ) AS findings
  FROM all_findings AS f
  JOIN rules
    ON rules.code = f.code
  JOIN records AS r
    USING (source_system, snapshot_id, source_table, legacy_row_id)
  GROUP BY
    f.source_system,
    f.snapshot_id,
    f.source_table,
    f.legacy_row_id
)
SELECT
  r.source_system,
  r.snapshot_id,
  r.snapshot_at,
  r.source_table,
  r.legacy_row_id,
  CAST(9 AS INT64) AS catalog_version,
  CAST('607e6288f4f57e39' /* Impressão digital do tratamento (D34): a versão é o rótulo humano, esta */ /* é a identidade do que ele de fato produz. É por ela que a quarentena */ /* recusa substituir uma auditoria sob a mesma versão. */ AS STRING) AS treatment_fingerprint,
  r.original_payload,
  r.cleaned_payload,
  CAST(CASE
    WHEN s.has_rejection
    THEN 'rejected'
    WHEN s.has_correction
    THEN 'corrected'
    ELSE 'accepted'
  END AS STRING) AS classification,
  CAST(CASE
    WHEN s.own_invalid
    THEN 'own_invalid'
    WHEN s.duplicate_excess
    THEN 'duplicate_excess'
    WHEN s.has_rejection
    THEN 'parent_rejected'
  END AS STRING) AS rejection_origin,
  COALESCE(s.findings, CAST('[]' AS JSONB)) AS findings
FROM records AS r
LEFT JOIN summaries AS s
  USING (source_system, snapshot_id, source_table, legacy_row_id)
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
