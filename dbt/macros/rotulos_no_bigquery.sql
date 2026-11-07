{#-
    O metadado de catálogo como *label* do BigQuery (Etapa 13, G5; D80).

    `domain`, `owner` e `retention` já vivem no `meta` de cada modelo — o `domain` derivado da
    origem que o modelo conduz, os outros declarados por camada no `dbt_project.yml` — e são o
    que o `dbt docs` publica. No BigQuery eles viram *labels* da tabela ou da view, que o Dataplex
    mostra e filtra: a mesma fonte, nenhuma cópia escrita à mão.

    *Label* só aceita minúscula, dígito, `_` e `-`, até 63 caracteres; o valor é normalizado e,
    se não sobrar nada, o *label* sai. Fora do BigQuery a macro devolve vazio, e o dbt ignora
    *hook* em branco.
-#}
{% macro rotulos_no_bigquery() -%}
    {%- if target.type == 'bigquery' -%}
        {%- set meta = config.get('meta') or {} -%}
        {%- set rotulos = [] -%}
        {%- for chave in ['domain', 'owner', 'retention'] -%}
            {%- set valor = modules.re.sub('[^a-z0-9_-]', '_', (meta.get(chave) or '') | string | lower)[:63] -%}
            {%- if valor | replace('_', '') -%}
                {%- do rotulos.append("('" ~ chave ~ "', '" ~ valor ~ "')") -%}
            {%- endif -%}
        {%- endfor -%}
        {%- if rotulos -%}
            alter {{ 'view' if config.get('materialized') == 'view' else 'table' }} {{ this }}
            set options (labels = [{{ rotulos | join(', ') }}])
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
