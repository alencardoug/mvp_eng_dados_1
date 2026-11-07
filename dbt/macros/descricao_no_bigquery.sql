{#-
    A descrição de coluna no BigQuery (Etapa 13, G1.4).

    O `persist_docs` grava a descrição de cada coluna na tabela. O PostgreSQL aceita
    comentário de qualquer tamanho; o BigQuery recusa a coluna com mais de 1.024 caracteres,
    e a recusa derruba o modelo inteiro (medido em 07/11/2026: quatro views de `consumption`).

    O texto inteiro continua sendo o do `.yml`, e é ele que o catálogo publica. No BigQuery,
    a descrição longa é cortada no limite com a indicação de onde está o resto. O resto do
    dicionário da coluna (as `policy_tags` da D71, entre outros) passa intacto.
-#}
{% macro bigquery__alter_column_comment(relation, column_dict) -%}
    {%- set limite = 1024 -%}
    {%- set aviso = ' […] texto completo no catálogo (dbt docs).' -%}
    {%- set colunas = {} -%}
    {%- for nome, coluna in column_dict.items() -%}
        {%- set copia = coluna.copy() -%}
        {%- set descricao = copia.get('description') or '' -%}
        {%- if descricao | length > limite -%}
            {%- do copia.update({'description': descricao[:limite - aviso | length] ~ aviso}) -%}
        {%- endif -%}
        {%- do colunas.update({nome: copia}) -%}
    {%- endfor -%}
    {% do adapter.update_columns(relation, colunas) %}
{%- endmacro %}
