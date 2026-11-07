{#-
    `distinct on` nos dois alvos (Etapa 13, PLANO_etapa_13 G1).

    O PostgreSQL tem `select distinct on (chaves) … order by ordem`: uma linha por chave, a
    primeira na ordem. O BigQuery não tem; o equivalente é `qualify row_number() over
    (partition by chaves order by ordem) = 1`, que funciona sem `where` (medido em 07/11/2026).

    Em duas metades, porque a ordem pode usar coluna que não está na lista do `select`
    (`dim_product` ordena por `product_variant_id`) — envolver o `select` numa subconsulta a
    perderia:

        select {{ distinct_on('source_system, brand_id') }}
            source_system, brand_id, brand_name
        from atual
        {{ distinct_on_order('source_system, brand_id', 'source_system, brand_id, product_variant_id') }}

    No PostgreSQL o SQL gerado é **o mesmo de antes** da Etapa 13, caractere a caractere nas
    duas pontas: o caminho local não muda.
-#}

{% macro distinct_on(keys) -%}
    {{ return(adapter.dispatch('distinct_on')(keys)) }}
{%- endmacro %}

{% macro default__distinct_on(keys) -%}
    distinct on ({{ keys }})
{%- endmacro %}

{% macro bigquery__distinct_on(keys) -%}
{%- endmacro %}


{% macro distinct_on_order(keys, order) -%}
    {{ return(adapter.dispatch('distinct_on_order')(keys, order)) }}
{%- endmacro %}

{% macro default__distinct_on_order(keys, order) -%}
    order by {{ order }}
{%- endmacro %}

{% macro bigquery__distinct_on_order(keys, order) -%}
    qualify row_number() over (partition by {{ keys }} order by {{ order }}) = 1
{%- endmacro %}


{#- `bool_and` nos dois alvos. O `bool_or` já tem a macro do próprio dbt (`dbt.bool_or`);
    o `bool_and`, não. No BigQuery as duas são `logical_and` e `logical_or`. -#}
{% macro bool_and(expression) -%}
    {{ return(adapter.dispatch('bool_and')(expression)) }}
{%- endmacro %}

{% macro default__bool_and(expression) -%}
    bool_and({{ expression }})
{%- endmacro %}

{% macro bigquery__bool_and(expression) -%}
    logical_and({{ expression }})
{%- endmacro %}
