"""O SQL gerado do legado nos dois alvos (Etapa 13, PLANO_etapa_13 G1.1).

O gerador do legado (`dbt.py`, `regras.py`, `classification.py`, `ponte.py`, `remocao.py`)
escreve PostgreSQL — dezenas de milhares de *casts* `::`, expressões regulares POSIX, `->>`,
`to_date`, `convert_from`. Reescrever esse gerador para dois dialetos duplicaria a declaração
que o Owner revisa. Em vez disso, o **mesmo** SQL gerado é traduzido para o BigQuery pelo
`sqlglot` (já dependência do catálogo) e o modelo leva os dois corpos:

    <cabeçalho Jinja, igual>
    {% if target.type == 'bigquery' %}<tradução>{% else %}<PostgreSQL, intacto>{% endif %}

**O corpo PostgreSQL não muda um caractere**: o oráculo é compilar o alvo local antes e
depois e comparar os arquivos (diff vazio). O corpo BigQuery é derivado, e a sua prova é
semântica: o mesmo bruto, nos dois alvos, dá a mesma classificação linha a linha.

O Jinja dentro do corpo (`ref`, `source`, `var`, as macros de identidade) vira um
identificador provisório para o `sqlglot` e volta depois da tradução; o
`{{ 'materialized' if target.type == 'postgres' else '' }}` sai, porque o BigQuery não tem.
"""

from __future__ import annotations

import re

import sqlglot
from sqlglot import exp
from sqlglot.errors import ErrorLevel

_JINJA = re.compile(r"\{\{.*?\}\}|\{%.*?%\}", re.S)
_INICIO = re.compile(r"(?m)^(with|select)\b")


def _separa(conteudo: str) -> tuple[str, str]:
    """Cabeçalho (comentários, `config`, `set`) e corpo SQL."""
    m = _INICIO.search(conteudo)
    if m is None:
        raise ValueError("modelo sem `with`/`select` no início de linha")
    return conteudo[: m.start()], conteudo[m.start() :]


def _pos_traducao(sql: str) -> str:
    """O que o `sqlglot` não sabe traduzir sozinho, com o motivo de cada regra."""
    # Escapes de code point: POSIX do PostgreSQL usa \u00XX; o RE2 do BigQuery, \x{00XX}.
    sql = re.sub(r"\\u([0-9a-fA-F]{4})", r"\\x{\1}", sql)
    return sql


def _so_o_primeiro_grupo(padrao: str) -> str:
    """Grupos depois do primeiro viram não capturantes.

    `substring(v from 'p')` do PostgreSQL devolve o **primeiro** grupo; o `REGEXP_EXTRACT` do
    BigQuery recusa padrão com mais de um. `PARTE_OFFSET_HORA` tem dois.
    """
    saida, vistos, i = [], 0, 0
    while i < len(padrao):
        ch = padrao[i]
        if ch == "\\":
            saida.append(padrao[i : i + 2])
            i += 2
            continue
        if ch == "(" and not padrao.startswith("(?", i):
            vistos += 1
            saida.append("(" if vistos == 1 else "(?:")
            i += 1
            continue
        saida.append(ch)
        i += 1
    return "".join(saida)


def _traduz_no(no: exp.Expression) -> exp.Expression:
    """As funções do PostgreSQL que o `sqlglot` não leva ao BigQuery sozinho."""
    # substring(v from 'padrão'): a forma de expressão regular; nulo sem casamento, nos dois.
    if isinstance(no, exp.Substring) and isinstance(no.args.get("start"), exp.Literal) \
            and no.args["start"].is_string and no.args.get("length") is None:
        padrao = _so_o_primeiro_grupo(no.args["start"].this)
        return exp.RegexpExtract(this=no.this, expression=exp.Literal.string(padrao))
    # convert_from(convert_to(x, 'LATIN1'), 'UTF8'): desfazer o mojibake. Só roda depois da
    # guarda LATIN1_REVERSIVEL (regras.py), que garante que todo code point cabe num byte e
    # que os bytes formam UTF-8 válido — por isso a versão SAFE nunca troca nada por U+FFFD.
    if isinstance(no, exp.Anonymous) and no.name.lower() == "convert_from":
        dentro = no.expressions[0]
        if isinstance(dentro, exp.Anonymous) and dentro.name.lower() == "convert_to":
            x = dentro.expressions[0]
            return exp.Anonymous(this="SAFE_CONVERT_BYTES_TO_STRING", expressions=[
                exp.Anonymous(this="CODE_POINTS_TO_BYTES", expressions=[
                    exp.Anonymous(this="TO_CODE_POINTS", expressions=[x])])])
        raise ValueError("convert_from sem convert_to dentro: forma não prevista")
    # split_part(a, d, n): fora do alcance o PostgreSQL devolve '', e o SPLIT do BigQuery, nulo.
    if isinstance(no, exp.SplitPart):
        n = no.args["part_index"]
        if not (isinstance(n, exp.Literal) and not n.is_string and int(n.this) > 0):
            raise ValueError("split_part com índice não positivo: forma não prevista")
        return exp.Coalesce(this=exp.Bracket(
            this=exp.Split(this=no.this, expression=no.args["delimiter"]),
            expressions=[exp.Anonymous(this="SAFE_ORDINAL", expressions=[n])]),
            expressions=[exp.Literal.string("")])
    # JSON: jsonb_build_object → JSON_OBJECT (pares chave, valor), jsonb_strip_nulls →
    # JSON_STRIP_NULLS, jsonb_agg(x order by …) → TO_JSON(ARRAY_AGG(x order by …)). Os elementos
    # agregados pelo gerador são objetos, nunca nulos — o ARRAY_AGG do BigQuery recusaria nulo.
    if isinstance(no, exp.Anonymous):
        nome = no.name.lower()
        if nome == "jsonb_build_object":
            return exp.Anonymous(this="JSON_OBJECT", expressions=no.expressions)
        if nome == "jsonb_strip_nulls":
            return exp.Anonymous(this="JSON_STRIP_NULLS", expressions=no.expressions)
        if nome == "jsonb_agg":
            if len(no.expressions) != 1:
                raise ValueError("jsonb_agg com mais de um argumento: forma não prevista")
            return exp.Anonymous(this="TO_JSON", expressions=[exp.ArrayAgg(this=no.expressions[0])])
    # `x::timestamp at time zone 'Z'`: o PostgreSQL lê o horário sem fuso como local de Z e
    # devolve o instante. No BigQuery, isso é TIMESTAMP(DATETIME, 'Z'). A outra direção do
    # `at time zone` (instante → horário local) não aparece no gerador e é recusada.
    if isinstance(no, exp.AtTimeZone):
        alvo = no.this
        if isinstance(alvo, exp.Cast) and alvo.to.this == exp.DataType.Type.TIMESTAMP:
            return exp.Anonymous(this="TIMESTAMP", expressions=[
                exp.Cast(this=alvo.this, to=exp.DataType.build("DATETIME")), no.args["zone"]])
        raise ValueError("at time zone sobre instante com fuso: forma não prevista")
    return no


def para_bigquery(corpo: str) -> str:
    """Traduz um corpo SQL do PostgreSQL com Jinja embutido para o BigQuery."""
    marcas: dict[str, str] = {}

    def marca(m: re.Match) -> str:
        token = m.group(0)
        if "if target.type" in token:  # o `materialized` do CTE (ADR-0047): só PostgreSQL
            return ""
        chave = f"jj{len(marcas)}x"
        marcas[chave] = token
        return chave

    provisorio = _JINJA.sub(marca, corpo)
    arvores = sqlglot.parse(provisorio, read="postgres")
    if len(arvores) != 1:
        raise ValueError(f"esperava um comando, a análise deu {len(arvores)}")
    # Ponto fixo: o `transform` não desce nos filhos de um nó que ele acabou de trocar
    # (`jsonb_strip_nulls(jsonb_build_object(…))` traduzia só o de fora).
    arvore = arvores[0]
    for _ in range(8):
        nova = arvore.transform(_traduz_no)
        if nova == arvore:
            break
        arvore = nova
    else:
        raise ValueError("a tradução não convergiu em 8 passadas")
    sql = arvore.sql(dialect="bigquery", pretty=True, unsupported_level=ErrorLevel.IGNORE)
    for chave, token in marcas.items():
        sql, n = re.subn(rf"`?{chave}`?", lambda _m, t=token: t, sql, flags=re.I)
        if n == 0:
            raise ValueError(f"o marcador {chave} ({token[:40]}) sumiu na tradução")
    return _pos_traducao(sql)


def dois_dialetos(conteudo: str) -> str:
    """O modelo com o corpo PostgreSQL intacto e o corpo BigQuery traduzido."""
    cabecalho, corpo = _separa(conteudo)
    # O Jinja tira **uma** quebra de linha do fim do modelo. Com o `{% endif %}` depois do
    # corpo, ela deixaria de ser a última e passaria a sair na compilação: o corpo entra sem
    # ela, e ela volta depois do `{% endif %}`, onde o Jinja a tira como antes.
    final = "\n" if corpo.endswith("\n") else ""
    return (
        cabecalho
        + "{% if target.type == 'bigquery' %}\n"
        + para_bigquery(corpo)
        + "\n{% else %}"
        + corpo[: len(corpo) - len(final)]
        + "{% endif %}"
        + final
    )
