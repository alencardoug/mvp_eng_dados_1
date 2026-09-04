{#-
    O schema declarado é o schema criado — sem prefixo do alvo.

    O padrão do dbt concatena o schema do perfil com o do modelo, e
    `staging` viraria `analytics_staging`. As camadas do ADR-0008 têm nome
    próprio e o ADR-0011 concede acesso *por camada*: um schema com nome
    inesperado é uma concessão que não pega.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
