{#-
    O `+grants` das camadas no BigQuery (Etapa 13, PLANO_etapa_13 G1.4).

    As camadas declaram quem lê com os papéis do ADR-0011 (`select: [analyst, transformer]`).
    No PostgreSQL eles são *roles* sem login; no BigQuery, o mapa de paridade (Arquitetura §5,
    "Controle de acesso") diz "uma conta de serviço por papel". Esta macro traduz a declaração
    no momento de aplicar, sem mudar o `dbt_project.yml`: a declaração continua uma só.

        select        → roles/bigquery.dataViewer
        <papel>       → serviceAccount:mvp-<papel>@<projeto>.iam.gserviceaccount.com

    As contas nascem no Terraform (`terraform/iam.tf`), uma por papel de
    `mvp_ed1.governance.PAPEIS`. Privilégio ou papel sem tradução é recusado, não ignorado:
    concessão que não pega é o defeito que o ADR-0011 existe para evitar.
-#}

{% macro bigquery__apply_grants(relation, grant_config, should_revoke=True) %}
    {%- set privileges = {'select': 'roles/bigquery.dataViewer'} -%}
    {%- set roles = ['ingestor', 'transformer', 'streamer', 'analyst', 'auditor'] -%}
    {%- set translated = {} -%}
    {%- for privilege, grantees in (grant_config or {}).items() -%}
        {%- if privilege not in privileges -%}
            {{ exceptions.raise_compiler_error("privilégio sem tradução para o BigQuery: " ~ privilege) }}
        {%- endif -%}
        {%- set principals = [] -%}
        {%- for role in grantees -%}
            {%- if role not in roles -%}
                {{ exceptions.raise_compiler_error("papel fora do ADR-0011: " ~ role) }}
            {%- endif -%}
            {%- do principals.append('serviceAccount:mvp-' ~ role ~ '@' ~ target.project ~ '.iam.gserviceaccount.com') -%}
        {%- endfor -%}
        {%- do translated.update({privileges[privilege]: principals}) -%}
    {%- endfor -%}
    {{ return(default__apply_grants(relation, translated, should_revoke)) }}
{% endmacro %}
