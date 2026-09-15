{#-
    A chave de negócio de uma tabela do legado, canonizada **pelo tipo declarado** da PK.

    ── Por que não basta `identidade_canonica` ────────────────────────────────
    Aquela macro só normaliza inteiros por extenso (`08` = `8`), e diz isso no
    próprio texto. A chave primária de `inventory_movements` é `Uuid`: dois
    textos do mesmo UUID em caixas diferentes não casam por ela (medido em
    14/09/2026, achado P12). Comparar presença entre capturas com uma chave que
    não reconhece a própria identidade acusaria remoção e inclusão onde só a
    representação mudou.

    ── O contrato (ADR-0045) ──────────────────────────────────────────────────
    O tipo vem do modelo SQLAlchemy — o gerador o lê de `Base.metadata` e o
    escreve aqui como literal, tabela a tabela. Para cada tipo, a regra de
    "mesma chave" é a do próprio PostgreSQL ao converter, e a fronteira é a
    conversão: o que não converte para o tipo **não tem identidade** — devolve
    nulo, é contado à parte e nunca é relabelado (o achado que o rejeitou
    continua sendo o do catálogo).

      inteiro  →  o número, sem zero à esquerda nem espaço; `08` = `8`
      uuid     →  o UUID em minúsculas, com hífens; caixa e forma não importam
      texto    →  o texto sem espaço à volta; vazio é nulo

    No BigQuery a mesma macro escreve `SAFE_CAST` aos mesmos tipos.
-#}
{% macro chave_canonica(expressao, tipo) -%}
    {%- if tipo == 'inteiro' -%}
    (case
        when ({{ expressao }}) ~ '^\s*-?[0-9]+\s*$' then (({{ expressao }})::numeric)::text
        else null
     end)
    {%- elif tipo == 'uuid' -%}
    (case
        when ({{ expressao }}) ~* '^\s*\{?[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}\}?\s*$'
            then (trim(({{ expressao }}))::uuid)::text
        else null
     end)
    {%- elif tipo == 'texto' -%}
    nullif(trim(({{ expressao }})), '')
    {%- else -%}
    {{ exceptions.raise_compiler_error("chave_canonica: tipo desconhecido " ~ tipo) }}
    {%- endif -%}
{%- endmacro %}
