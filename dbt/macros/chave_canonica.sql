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
      inteiro  sinal opcional, dígitos, e à volta **só os brancos ASCII** que o
               `isspace` do cast aceita (espaço, TAB, LF, VT, FF, CR): `\s` do
               regex casaria U+00A0 e U+2003, que o cast recusa (RV10-2-04);
               os zeros à esquerda saem antes de qualquer conversão, porque o
               cast aceita quantos forem e o `numeric` estoura acima de
               131.072 dígitos; o domínio é conferido sobre no máximo 19
               dígitos significativos, em `numeric`, antes do `cast` ao tipo

    No BigQuery a mesma macro escreve `SAFE_CAST` aos mesmos tipos.
-#}
{% macro chave_canonica(expressao, tipo) -%}
    {%- set dominios = {
        'bigint':   ('-9223372036854775808', '9223372036854775807'),
        'integer':  ('-2147483648', '2147483647'),
        'smallint': ('-32768', '32767'),
    } -%}
    {%- if tipo in dominios -%}
    {%- set aparado = "btrim((" ~ expressao ~ "), E' \\t\\n\\x0b\\x0c\\r')" -%}
    {%- set significativo = "regexp_replace(" ~ aparado ~ ", '^([+-]?)0*([0-9])', '\\1\\2')" -%}
    (case
        when ({{ expressao }}) ~ '^[ \t\n\v\f\r]*[+-]?[0-9]+[ \t\n\v\f\r]*$' then
            case
                when length(regexp_replace({{ aparado }}, '^[+-]?0*', '')) <= 19 then
                    case
                        when ({{ significativo }})::numeric between {{ dominios[tipo][0] }} and {{ dominios[tipo][1] }}
                            then (({{ significativo }})::numeric::{{ tipo }})::text
                    end
            end
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
