{#-
    As duas origens da mesma tabela, uma sobre a outra.

    `trusted` é a camada do empilhamento (ADR-0021, Origem Legada §6): é aqui
    que o registro apto da origem legada se junta ao da origem principal. A
    macro existe para que a explicação disto viva **uma vez**, e não repetida
    em cada modelo que empilha.

    ── Por que `source_system` entra como coluna ─────────────────────────────
    Dois sistemas numeram entidades a partir de 1. Sem a origem na identidade,
    o cliente 42 de um seria o cliente 42 do outro, e os dois se somariam num
    registro que nunca existiu. Com ela, a chave natural passa a ser
    (`source_system`, chave da origem) — e é assim que a chave substituta da
    dimensão é derivada (ADR-0039).

    O corolário vale para toda junção entre modelos de `trusted`: casar só pelo
    identificador da origem junta linhas de sistemas diferentes. A origem entra
    na condição junto com a chave, sempre.

    ── O que atravessa ──────────────────────────────────────────────────────
    Só `accepted` e `corrected` chegam pela ponte. O rejeitado fica em
    `quarantine`, com o motivo (regra 4). Tabela do legado sem contraparte na
    origem principal não é empilhável e não passa por aqui — a lista está em
    `src/mvp_ed1/legacy/ponte.py`.

    O domínio de `source_system` é declarado e fechado — `retail` e `legacy`,
    e nada mais. Caminho de ingestão não é sistema de origem: Airbyte e Beam
    transportam o mesmo `retail` (Origem Legada §6).
-#}
{% macro empilhado(tabela) -%}

    select 'retail' as source_system, *
    from {{ ref('stg_retail__' ~ tabela) }}

    union all

    select 'legacy' as source_system, *
    from {{ ref('legado__' ~ tabela) }}

{%- endmacro %}
