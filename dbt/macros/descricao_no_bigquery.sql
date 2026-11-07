{#-
    A descrição e a *policy tag* de cada coluna no BigQuery (Etapa 13, G1.4 e G4).

    O `persist_docs` grava a descrição de cada coluna na tabela. O PostgreSQL aceita
    comentário de qualquer tamanho; o BigQuery recusa a coluna com mais de 1.024 caracteres,
    e a recusa derruba o modelo inteiro (medido em 07/11/2026: quatro views de `consumption`).
    O texto inteiro continua sendo o do `.yml`, e é ele que o catálogo publica. No BigQuery,
    a descrição longa é cortada no limite com a indicação de onde está o resto.

    **A *policy tag* (D71, D79).** O mesmo `update_columns` grava o `policyTags` de toda
    coluna documentada — vazio, se a coluna não declara `policy_tags`. A *tag* não é escrita
    nos `.yml`: ela é **derivada** aqui de `meta.sensitivity`, a classificação que já existe em
    cada coluna, pelo mapa nível → *tag* que o Terraform cria (`MVP_POLICY_TAGS`, saída
    `policy_tags`). Duas verdades sobre a mesma coluna não existem. Só em tabela: *view* não
    leva *policy tag* — o controle dela é o das colunas que ela lê, autorizada ou não. Sem o
    mapa (fase local, ou antes do `apply`), nenhuma coluna é marcada.
-#}
{% macro bigquery__alter_column_comment(relation, column_dict) -%}
    {%- set limite = 1024 -%}
    {%- set aviso = ' […] texto completo no catálogo (dbt docs).' -%}
    {%- set tags = mvp_policy_tags() -%}
    {%- set marcar = relation.type == 'table' -%}
    {%- set colunas = {} -%}
    {%- for nome, coluna in column_dict.items() -%}
        {%- set copia = coluna.copy() -%}
        {%- set descricao = copia.get('description') or '' -%}
        {%- if descricao | length > limite -%}
            {%- do copia.update({'description': descricao[:limite - aviso | length] ~ aviso}) -%}
        {%- endif -%}
        {%- set nivel = (copia.get('meta') or {}).get('sensitivity') -%}
        {%- do copia.update({'policy_tags': [tags[nivel]] if (marcar and nivel in tags) else []}) -%}
        {%- do colunas.update({nome: copia}) -%}
    {%- endfor -%}
    {% do adapter.update_columns(relation, colunas) %}
{%- endmacro %}


{#- O mapa nível → nome da *policy tag*, do ambiente; `{}` sem ele. Mapa malformado para o build:
    marcar errado é pior do que não marcar, e as duas coisas têm de ser visíveis. -#}
{% macro mvp_policy_tags() -%}
    {%- set bruto = env_var('MVP_POLICY_TAGS', '{}') | trim -%}
    {%- set mapa = fromjson(bruto if bruto else '{}') -%}
    {%- if mapa is not mapping -%}
        {{ exceptions.raise_compiler_error("MVP_POLICY_TAGS não é um objeto JSON: " ~ bruto) }}
    {%- endif -%}
    {{ return(mapa) }}
{%- endmacro %}
