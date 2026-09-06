{% macro legacy_snapshot_id() -%}
    {# Seleção explícita para reprocessamento; nunca interpolar SQL arbitrário. #}
    {% set snapshot = var('legacy_snapshot_id', none) %}
    {% if snapshot is none %}
        {{ return('null') }}
    {% endif %}
    {% if not (snapshot | string).isdigit() %}
        {{ exceptions.raise_compiler_error('legacy_snapshot_id deve ser um inteiro não negativo') }}
    {% endif %}
    {{ return(snapshot | int) }}
{%- endmacro %}
