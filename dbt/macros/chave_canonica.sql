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

      bigint / integer / smallint
               →  o número no domínio do tipo, sem zero à esquerda, sinal nem
                  espaço; `08` = `+8` = ` 8 ` = `8`; fora do domínio é nulo
      uuid     →  o UUID em minúsculas, com hífens; caixa, chaves e a posição
                  dos hífens não importam
      texto    →  o texto sem espaço à volta; vazio é nulo

    ── A guarda é a gramática do PostgreSQL, e nada mais ─────────────────────
    A guarda existe porque um `cast` que falha derruba o build inteiro, e o
    contrato pede nulo. Ela precisa aceitar **exatamente** o que o `cast`
    aceita: mais larga, deixa passar texto que estoura (`{UUID` sem fechar,
    inteiro fora do bigint — achados RV10-04/05); mais estreita, nega
    identidade a representação válida (`a0ee-bc99-…`, `+8`). O que está
    abaixo foi medido contra o PostgreSQL 16 em 15/09/2026, forma a forma:

      uuid     32 hexadecimais, hífen opcional depois de qualquer grupo de
               quatro (nunca no início, no fim ou dobrado), chaves `{}` só
               aos pares, nenhum espaço à volta — o `cast` do uuid não apara
      inteiro  a gramática de `pg_strtoint64` do PostgreSQL 16: brancos ASCII à
               volta — só os que o `isspace` do cast aceita (espaço, TAB, LF,
               VT, FF, CR); `\s` casaria U+00A0 e U+2003, que ele recusa
               (RV10-2-04) —, sinal opcional, e o número em **decimal, hexa
               (`0x`), octal (`0o`) ou binário (`0b`)**, com `_` como separador
               entre dígitos — nunca no fim, nunca dobrado, e no início só
               depois do prefixo (`0x_8` converte; `_8` não). Medido forma a
               forma em 16/09/2026 (RV10-3-01): `0x8`, `0o10`, `0b1000` e
               `1_000` são a chave `8` e `1000`. O valor sai da soma dos
               dígitos na base, em `numeric`, com os zeros à esquerda fora
               antes — o cast aceita quantos forem —, e o domínio é conferido
               em `numeric` antes do `cast` ao tipo: mais dígitos do que o
               domínio comporta (19 decimais, 16 hexa, 22 octais, 64 binários)
               é nulo sem chegar à soma.

    No BigQuery a mesma macro escreve `SAFE_CAST` aos mesmos tipos.
-#}
{% macro chave_canonica(expressao, tipo) -%}
    {%- set dominios = {
        'bigint':   ('-9223372036854775808', '9223372036854775807'),
        'integer':  ('-2147483648', '2147483647'),
        'smallint': ('-32768', '32767'),
    } -%}
    {%- if tipo in dominios -%}
    {#- A gramática, forma a forma: brancos ASCII, sinal, e o número numa das
        quatro bases, com `_` só entre dígitos (ou logo depois do prefixo).
        `~*` cobre `0X`, `0O`, `0B` e os hexadecimais em maiúsculas. -#}
    {%- set brancos = "[ \\t\\n\\v\\f\\r]" -%}
    {%- set gramatica = "^" ~ brancos ~ "*[+-]?(0x_?[0-9a-f]+(_[0-9a-f]+)*|0o_?[0-7]+(_[0-7]+)*|0b_?[01]+(_[01]+)*|[0-9]+(_[0-9]+)*)" ~ brancos ~ "*$" -%}
    (case
        when ({{ expressao }}) ~* '{{ gramatica }}' then (
            select case
                when valor between {{ dominios[tipo][0] }} and {{ dominios[tipo][1] }}
                    then (valor::{{ tipo }})::text
            end
            from (
                {#- só o que passou na guarda chega aqui: sem branco à volta,
                    sem `_`, em minúsculas -#}
                select replace(lower(btrim(({{ expressao }}), E' \t\n\x0b\x0c\r')), '_', '') as texto
            ) as aparado
            cross join lateral (
                select left(texto, 1) = '-' as negativo, ltrim(texto, '+-') as corpo
            ) as com_sinal
            cross join lateral (
                select
                    case left(corpo, 2) when '0x' then 16 when '0o' then 8 when '0b' then 2 else 10 end as base,
                    ltrim(case when left(corpo, 2) in ('0x', '0o', '0b') then substr(corpo, 3) else corpo end, '0') as digitos
            ) as na_base
            cross join lateral (
                {#- a soma dos dígitos na base, exata em `numeric`; o limite de
                    dígitos é o do domínio do bigint, e tudo acima dele já está
                    fora de qualquer dos três domínios -#}
                select
                    (case when negativo then -1 else 1 end) * (
                        select coalesce(sum((position(substr(digitos, i, 1) in '0123456789abcdef') - 1) * (base::numeric ^ (length(digitos) - i))), 0)
                        from generate_series(1, length(digitos)) as i
                    ) as valor
                where length(digitos) <= case base when 16 then 16 when 8 then 22 when 2 then 64 else 19 end
            ) as convertido
        )
     end)
    {%- elif tipo == 'uuid' -%}
    (case
        when ({{ expressao }}) ~* '^(\{([0-9a-f]{4}-?){7}[0-9a-f]{4}\}|([0-9a-f]{4}-?){7}[0-9a-f]{4})$'
            then (({{ expressao }})::uuid)::text
        else null
     end)
    {%- elif tipo == 'texto' -%}
    nullif(trim(({{ expressao }})), '')
    {%- else -%}
    {{ exceptions.raise_compiler_error("chave_canonica: tipo desconhecido " ~ tipo) }}
    {%- endif -%}
{%- endmacro %}
