{#-
    Acesso por camada (Governança §7, ADR-0011), aplicado ao fim de cada execução.

    ── Onde cada coisa é declarada ──────────────────────────────────────────
    A concessão vive onde a camada vive, como a retenção:
    * `+grants` por camada no `dbt_project.yml` — quem **lê** cada objeto que o
      dbt materializa. O próprio dbt aplica, objeto a objeto, logo depois de
      materializar; esta macro não repete isso.
    * `meta.grants` por fonte nos `_sources.yml` — quem lê `raw`, `raw_legacy` e
      `governance`, que o dbt não materializa e por isso não concede. O dbt
      funde o `meta` da fonte no de cada tabela, e é o da tabela que vale aqui:
      `meta.grants` numa tabela **substitui** o da fonte naquela tabela, lista
      completa, como o `+grants` de um modelo substitui o da camada.
    * `meta.writers` por camada e por fonte — quem **escreve** o schema: recebe
      `create`, que é o que um escritor que é dono das próprias tabelas precisa.

    Tabela de fonte não é recriada pelo dbt, e por isso a concessão nela é
    zerada antes de ser refeita — o que alguém deu à mão sai na execução
    seguinte. Objeto de modelo nasce sem concessão nenhuma a cada build, e o
    `+grants` põe só o declarado.

    ── O que esta macro faz ─────────────────────────────────────────────────
    Grant em objeto não alcança nada sem `usage` no schema, e o dbt não trata
    o nível de schema. Daqui saem: `usage` para todo papel com concessão em
    algum objeto do schema ou declarado escritor dele; `create` para os
    escritores; os grants das fontes; e o `revoke` do que **não** está declarado
    — um papel que deixou de ser leitor de uma camada perde o `usage` na
    execução seguinte, sem mão humana. Só schemas e tabelas que existem entram:
    numa execução parcial em ambiente novo não há o que conceder.

    Hoje o dbt executa como o superusuário do `.env`, dono de tudo — o que faz
    os grants das camadas de origem caberem aqui. Quando cada componente tiver a
    própria identidade, a concessão sobre `raw` passa a quem for dono dele.
    No BigQuery o `+grants` do dbt basta e o nível de dataset é do Terraform:
    a macro devolve vazio, e o dbt ignora hook em branco.
-#}
{% macro aplicar_acesso_por_camada() -%}
{%- if target.type != 'postgres' or not execute -%}
    {{ return('') }}
{%- endif -%}

{%- set leitores = {} -%}    {# schema -> papéis com concessão em algum objeto #}
{%- set escritores = {} -%}  {# schema -> papéis declarados em meta.writers #}
{%- set por_tabela = [] -%}  {# (schema, tabela, grants) de cada tabela de fonte #}

{%- for no in graph.nodes.values() -%}
    {%- if no.resource_type in ('model', 'seed', 'snapshot') and no.config.get('enabled', true) -%}
        {%- for papeis in (no.config.get('grants') or {}).values() -%}
            {%- do leitores.setdefault(no.schema, []).extend(papeis) -%}
        {%- endfor -%}
        {%- do escritores.setdefault(no.schema, []).extend((no.config.get('meta') or {}).get('writers') or []) -%}
    {%- endif -%}
{%- endfor -%}

{%- for fonte in graph.sources.values() -%}
    {%- set meta = fonte.meta or {} -%}
    {%- set grants = meta.get('grants') or {} -%}
    {%- if grants -%}
        {%- do por_tabela.append((fonte.schema, fonte.identifier, grants)) -%}
        {%- for papeis in grants.values() -%}
            {%- do leitores.setdefault(fonte.schema, []).extend(papeis) -%}
        {%- endfor -%}
    {%- endif -%}
    {%- do escritores.setdefault(fonte.schema, []).extend(meta.get('writers') or []) -%}
{%- endfor -%}

{%- set schemas_existentes = run_query("select nspname from pg_namespace").columns[0].values() | list -%}
{%- set tabelas_existentes = run_query(
    "select table_schema || '.' || table_name from information_schema.tables"
).columns[0].values() | list -%}
{#- Os papéis são os grupos sem login (governance.PAPEIS); o superusuário tem login. -#}
{%- set papeis = run_query(
    "select rolname from pg_roles where not rolcanlogin and rolname not like 'pg\\_%'"
).columns[0].values() | list -%}

{%- set comandos = [] -%}
{%- set schemas = ((leitores.keys() | list) + (escritores.keys() | list)) | unique | sort -%}
{%- for schema in schemas if schema in schemas_existentes -%}
    {%- set quem_le = leitores.get(schema, []) | unique | sort | list -%}
    {%- set quem_escreve = escritores.get(schema, []) | unique | sort | list -%}
    {%- set quem_entra = (quem_le + quem_escreve) | unique | sort | list -%}
    {%- for papel in papeis | sort if papel not in quem_entra -%}
        {%- do comandos.append("revoke all privileges on all tables in schema " ~ schema ~ " from " ~ papel) -%}
        {%- do comandos.append("revoke all privileges on schema " ~ schema ~ " from " ~ papel) -%}
    {%- endfor -%}
    {%- if quem_entra -%}
        {%- do comandos.append("grant usage on schema " ~ schema ~ " to " ~ (quem_entra | join(', '))) -%}
    {%- endif -%}
    {%- if quem_escreve -%}
        {%- do comandos.append("grant create on schema " ~ schema ~ " to " ~ (quem_escreve | join(', '))) -%}
    {%- endif -%}
{%- endfor -%}
{%- for schema, tabela, grants in por_tabela if (schema ~ '.' ~ tabela) in tabelas_existentes -%}
    {#- Tabela de fonte não é recriada pelo dbt: o que estiver a mais nela só sai zerando antes. -#}
    {%- do comandos.append("revoke all privileges on " ~ schema ~ "." ~ tabela ~ " from " ~ (papeis | sort | join(', '))) -%}
    {%- for privilegio, grantees in grants.items() -%}
        {%- do comandos.append("grant " ~ privilegio ~ " on " ~ schema ~ "." ~ tabela ~ " to " ~ (grantees | unique | sort | join(', '))) -%}
    {%- endfor -%}
{%- endfor -%}
{{ comandos | join('; ') }}
{%- endmacro %}
