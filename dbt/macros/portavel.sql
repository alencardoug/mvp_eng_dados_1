{#-
    SQL nos dois alvos: o que o PostgreSQL e o BigQuery escrevem diferente (Etapa 13,
    PLANO_etapa_13 G1.2–G1.3).

    Cada macro tem duas metades. A `default__` emite **o texto que o modelo tinha antes da
    Etapa 13**: o caminho local compila igual, e o oráculo de compilação confere isso
    arquivo a arquivo. A `bigquery__` emite o equivalente no GoogleSQL, com o motivo quando
    a equivalência não é óbvia; a prova dela é o oráculo semântico (os dois alvos sobre o
    mesmo bruto, comparados linha a linha).

    O que é portável sem macro fica sem macro: `cast(x as int)`, `cast(x as numeric)` e
    `is distinct from` valem nos dois.
-#}


{#- A meia-noite de uma data num deslocamento fixo — o `as_of_date` às 00:00 de São Paulo.
    O BigQuery exige os segundos no literal. -#}
{% macro meia_noite(data, deslocamento='-03') -%}
    {{ return(adapter.dispatch('meia_noite')(data, deslocamento)) }}
{%- endmacro %}
{% macro default__meia_noite(data, deslocamento) -%}
    timestamptz '{{ data }} 00:00{{ deslocamento }}'
{%- endmacro %}
{% macro bigquery__meia_noite(data, deslocamento) -%}
    timestamp '{{ data }} 00:00:00{{ deslocamento }}'
{%- endmacro %}


{#- A data de um instante no calendário de São Paulo. -#}
{% macro data_em_sao_paulo(instante) -%}
    {{ return(adapter.dispatch('data_em_sao_paulo')(instante)) }}
{%- endmacro %}
{% macro default__data_em_sao_paulo(instante) -%}
    cast({{ instante }} at time zone 'America/Sao_Paulo' as date)
{%- endmacro %}
{% macro bigquery__data_em_sao_paulo(instante) -%}
    date({{ instante }}, 'America/Sao_Paulo')
{%- endmacro %}


{#- Uma coluna de vigência do `dbt snapshot` lida como instante. No PostgreSQL ela é
    `timestamp` sem fuso, gravada em UTC (`snapshot_get_time`); no BigQuery já é
    `TIMESTAMP`, que é instante. -#}
{% macro vigencia_do_snapshot(coluna) -%}
    {{ return(adapter.dispatch('vigencia_do_snapshot')(coluna)) }}
{%- endmacro %}
{% macro default__vigencia_do_snapshot(coluna) -%}
    {{ coluna }} at time zone 'UTC'
{%- endmacro %}
{% macro bigquery__vigencia_do_snapshot(coluna) -%}
    {{ coluna }}
{%- endmacro %}


{#- Agregado condicional. O BigQuery não tem `filter (where …)`: `countif` para a contagem,
    e o valor anulado fora da condição para os outros — `sum`, `min`, `max` e `avg`
    ignoram nulo, como ignoram a linha filtrada. -#}
{% macro contar_onde(condicao) -%}
    {{ return(adapter.dispatch('contar_onde')(condicao)) }}
{%- endmacro %}
{% macro default__contar_onde(condicao) -%}
    count(*) filter (where {{ condicao }})
{%- endmacro %}
{% macro bigquery__contar_onde(condicao) -%}
    countif({{ condicao }})
{%- endmacro %}

{% macro agregado_onde(funcao, expressao, condicao) -%}
    {{ return(adapter.dispatch('agregado_onde')(funcao, expressao, condicao)) }}
{%- endmacro %}
{% macro default__agregado_onde(funcao, expressao, condicao) -%}
    {{ funcao }}({{ expressao }}) filter (where {{ condicao }})
{%- endmacro %}
{% macro bigquery__agregado_onde(funcao, expressao, condicao) -%}
    {{ funcao }}(if({{ condicao }}, {{ expressao }}, null))
{%- endmacro %}


{#- Duração entre dois instantes. O `extract(epoch …)` do PostgreSQL devolve `numeric`
    exato; no BigQuery, a diferença em microssegundos convertida para NUMERIC antes da
    divisão — dividir INT64 daria FLOAT64, e o arredondamento para quatro casas que todo
    chamador faz depois poderia cair do outro lado. -#}
{% macro segundos_entre(fim, inicio) -%}
    {{ return(adapter.dispatch('segundos_entre')(fim, inicio)) }}
{%- endmacro %}
{% macro default__segundos_entre(fim, inicio) -%}
    extract(epoch from ({{ fim }} - {{ inicio }}))
{%- endmacro %}
{% macro bigquery__segundos_entre(fim, inicio) -%}
    (cast(timestamp_diff({{ fim }}, {{ inicio }}, microsecond) as numeric) / 1000000)
{%- endmacro %}

{% macro horas_entre(fim, inicio) -%}
    {{ return(adapter.dispatch('horas_entre')(fim, inicio)) }}
{%- endmacro %}
{% macro default__horas_entre(fim, inicio) -%}
    extract(epoch from {{ fim }} - {{ inicio }}) / 3600.0
{%- endmacro %}
{% macro bigquery__horas_entre(fim, inicio) -%}
    (cast(timestamp_diff({{ fim }}, {{ inicio }}, microsecond) as numeric) / 3600000000)
{%- endmacro %}

{% macro dias_entre(fim, inicio) -%}
    {{ return(adapter.dispatch('dias_entre')(fim, inicio)) }}
{%- endmacro %}
{% macro default__dias_entre(fim, inicio) -%}
    extract(epoch from {{ fim }} - {{ inicio }}) / 86400.0
{%- endmacro %}
{% macro bigquery__dias_entre(fim, inicio) -%}
    (cast(timestamp_diff({{ fim }}, {{ inicio }}, microsecond) as numeric) / 86400000000)
{%- endmacro %}


{#- O texto de uma chave de um objeto JSON (`->>`). -#}
{% macro campo_json(objeto, chave) -%}
    {{ return(adapter.dispatch('campo_json')(objeto, chave)) }}
{%- endmacro %}
{% macro default__campo_json(objeto, chave) -%}
    {{ objeto }}->>{{ chave }}
{%- endmacro %}
{% macro bigquery__campo_json(objeto, chave) -%}
    json_value({{ objeto }}[{{ chave }}])
{%- endmacro %}


{#- O nome do tipo texto: `text` no PostgreSQL, `string` no BigQuery. -#}
{% macro tipo_texto() -%}
    {{ return(adapter.dispatch('tipo_texto')()) }}
{%- endmacro %}
{% macro default__tipo_texto() -%}text{%- endmacro %}
{% macro bigquery__tipo_texto() -%}string{%- endmacro %}

{#- O nome do tipo instante: `timestamptz` no PostgreSQL, `timestamp` no BigQuery. -#}
{% macro tipo_instante() -%}
    {{ return(adapter.dispatch('tipo_instante')()) }}
{%- endmacro %}
{% macro default__tipo_instante() -%}timestamptz{%- endmacro %}
{% macro bigquery__tipo_instante() -%}timestamp{%- endmacro %}


{#- Mediana exata (`percentile_cont(0.5)`). O `percentile_cont` do BigQuery só existe como
    função de janela, e o agrupamento do chamador não cabe numa janela. No agregado, a
    mediana sai da lista ordenada: o elemento do meio, ou a interpolação dos dois do meio
    pela mesma conta do PostgreSQL (`a + (b - a) * 0,5`, em FLOAT64 como lá, que devolve
    `double precision`). Nulos ficam de fora nos dois. -#}
{% macro mediana(expressao) -%}
    {{ return(adapter.dispatch('mediana')(expressao)) }}
{%- endmacro %}
{% macro default__mediana(expressao) -%}
    percentile_cont(0.5) within group (order by {{ expressao }})
{%- endmacro %}
{% macro bigquery__mediana(expressao) -%}
    {%- set ordenado = "array_agg(cast(" ~ expressao ~ " as float64) ignore nulls order by " ~ expressao ~ ")" -%}
    {%- set baixo = ordenado ~ "[safe_offset(div(count(" ~ expressao ~ ") - 1, 2))]" -%}
    {%- set alto = ordenado ~ "[safe_offset(div(count(" ~ expressao ~ "), 2))]" -%}
    ({{ baixo }} + ({{ alto }} - {{ baixo }}) * 0.5)
{%- endmacro %}


{#- Contagem de combinações distintas: `count(distinct (a, b))`. O BigQuery não conta
    STRUCT distinto; conta o texto JSON dele, que é único por combinação. -#}
{% macro contar_distintos(colunas) -%}
    {{ return(adapter.dispatch('contar_distintos')(colunas)) }}
{%- endmacro %}
{% macro default__contar_distintos(colunas) -%}
    count(distinct ({{ colunas | join(', ') }}))
{%- endmacro %}
{% macro bigquery__contar_distintos(colunas) -%}
    count(distinct to_json_string(struct({{ colunas | join(', ') }})))
{%- endmacro %}


{#- O calendário (`dim_date`). O PostgreSQL gera a série com `generate_series` sobre
    `interval`; o BigQuery, com `generate_date_array`. Os nomes de mês e de dia saem em
    inglês nos dois (`lc_time` do armazém local é `en_US`; o `FORMAT_DATE` do BigQuery
    não tem outra língua). `isodow` e a semana ISO não existem no BigQuery com esse nome:
    o `DAYOFWEEK` dele começa no domingo (1), e a semana ISO é `ISOWEEK`. -#}
{% macro serie_de_datas(inicio, fim, horizonte_dias) -%}
    {{ return(adapter.dispatch('serie_de_datas')(inicio, fim, horizonte_dias)) }}
{%- endmacro %}
{% macro default__serie_de_datas(inicio, fim, horizonte_dias) -%}
    select generate_series(
        date '{{ inicio }}',
        date '{{ fim }}' + interval '{{ horizonte_dias }} days',
        interval '1 day'
    )::date as full_date
{%- endmacro %}
{% macro bigquery__serie_de_datas(inicio, fim, horizonte_dias) -%}
    select full_date
    from unnest(generate_date_array(
        date '{{ inicio }}', date_add(date '{{ fim }}', interval {{ horizonte_dias }} day)
    )) as full_date
{%- endmacro %}

{% macro parte_da_data(parte, data) -%}
    {{ return(adapter.dispatch('parte_da_data')(parte, data)) }}
{%- endmacro %}
{% macro default__parte_da_data(parte, data) -%}
    {%- if parte == 'month_name' -%} to_char({{ data }}, 'TMMonth')
    {%- elif parte == 'day_name' -%} to_char({{ data }}, 'TMDay')
    {%- elif parte == 'year_month' -%} to_char({{ data }}, 'YYYY-MM')
    {%- elif parte == 'isodow' -%} extract(isodow from {{ data }})
    {%- elif parte == 'isoweek' -%} extract(week from {{ data }})
    {%- elif parte in ('month', 'quarter', 'year') -%} date_trunc('{{ parte }}', {{ data }})::date
    {%- else -%} {{ exceptions.raise_compiler_error("parte_da_data: parte desconhecida " ~ parte) }}
    {%- endif -%}
{%- endmacro %}
{% macro bigquery__parte_da_data(parte, data) -%}
    {%- if parte == 'month_name' -%} format_date('%B', {{ data }})
    {%- elif parte == 'day_name' -%} format_date('%A', {{ data }})
    {%- elif parte == 'year_month' -%} format_date('%Y-%m', {{ data }})
    {%- elif parte == 'isodow' -%} (mod(extract(dayofweek from {{ data }}) + 5, 7) + 1)
    {%- elif parte == 'isoweek' -%} extract(isoweek from {{ data }})
    {%- elif parte in ('month', 'quarter', 'year') -%} date_trunc({{ data }}, {{ parte }})
    {%- else -%} {{ exceptions.raise_compiler_error("parte_da_data: parte desconhecida " ~ parte) }}
    {%- endif -%}
{%- endmacro %}


{#- Decimal de escala fixa: `numeric(12, 4)`. O BigQuery recusa tipo parametrizado no
    `cast` e na tabela; o equivalente é arredondar na escala, metade para longe do zero,
    como o PostgreSQL arredonda ao converter. Em bloco, porque o que se converte é um
    `case` inteiro:

        {% call decimal_fixo(12, 4) %}case … end{% endcall %} as transit_days
-#}
{% macro decimal_fixo(precisao, escala) -%}
    {{ return(adapter.dispatch('decimal_fixo')(caller(), precisao, escala)) }}
{%- endmacro %}
{% macro default__decimal_fixo(expressao, precisao, escala) -%}
    cast({{ expressao }} as numeric({{ precisao }}, {{ escala }}))
{%- endmacro %}
{% macro bigquery__decimal_fixo(expressao, precisao, escala) -%}
    round(cast({{ expressao }} as numeric), {{ escala }})
{%- endmacro %}


{#- Diferença de multiconjuntos (`except all`): as linhas de `a` que sobram depois de
    descontar, uma a uma, as iguais de `b`. O BigQuery só tem `except distinct`, e nem
    ele compara JSON. A linha inteira vira o texto JSON dela (`to_json_string(t)`, pelo
    nome das colunas — `a` e `b` têm as mesmas), e a ocorrência da linha entre as iguais
    vira número: sobra a ocorrência que o outro lado não tem. -#}
{% macro diferenca_multiconjunto(a, b) -%}
    {{ return(adapter.dispatch('diferenca_multiconjunto')(a, b)) }}
{%- endmacro %}
{% macro default__diferenca_multiconjunto(a, b) -%}
    select * from {{ a }} except all select * from {{ b }}
{%- endmacro %}
{% macro bigquery__diferenca_multiconjunto(a, b) -%}
    select x.* except (_linha, _ocorrencia)
    from (
        select t.*, to_json_string(t) as _linha,
            row_number() over (partition by to_json_string(t)) as _ocorrencia
        from {{ a }} as t
    ) as x
    left join (
        select to_json_string(t) as _linha,
            row_number() over (partition by to_json_string(t)) as _ocorrencia
        from {{ b }} as t
    ) as y
        on y._linha = x._linha and y._ocorrencia = x._ocorrencia
    where y._linha is null
{%- endmacro %}
