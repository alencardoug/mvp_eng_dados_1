"""O que cada coluna de um modelo faz com o valor que lê: transporta, ou calcula.

── Para que serve ───────────────────────────────────────────────────────────────
A descrição de uma coluna só pode ser herdada de outra quando o valor chega
intacto — e a linhagem não sabe disso: cópia, soma, arredondamento e `cast`
têm a mesma folha (M21 do plano do `bi-como-codigo`, RV2-08). Este módulo lê o
SQL compilado, escopo a escopo, e classifica a expressão de cada coluna de
saída a cada salto. É a infraestrutura da herança de descrição
(`models/descriptions.py`); não decide texto nenhum.

── A regra, conservadora de propósito ─────────────────────────────────────────
* **Transporta** (`Carry`): referência pura a uma coluna — com ou sem apelido —
  e o `cast` que **devolve a coluna ao tipo declarado na origem** (o
  `cast(quantity as integer)` do `staging`, sobre um `Integer` dos modelos
  SQLAlchemy que o Airbyte grava mais largo). Todo outro `cast` calcula: um
  tipo diferente do declarado, ou desconhecido, pode estreitar o valor.
* **Calcula** (`Computed`): agregação, aritmética, função, `case`, comparação,
  janela, subconsulta, literal, gerado. O tipo da expressão fica anotado, e a
  forma de duas delas também — a constante e o `x IS NOT NULL` —, porque são
  as que as convenções do projeto reconhecem (N44).
* **União**: transporta quando pelo menos um ramo transporta e os demais são
  **constantes** — o membro desconhecido das dimensões, um literal de
  preenchimento, não vota (N45). As folhas são as de todos os ramos que
  transportam, e é quem as lê que exige o mesmo texto em todas (N41). Ramo que
  calcula faz a união calcular.

O que decide o ramo de um `case`, a condição de um `join` ou de um `where` não
importa aqui: a pergunta é só se o valor da saída é o valor de uma entrada.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable

from sqlglot import exp
from sqlglot.optimizer.scope import Scope, traverse_scope

Leaf = tuple[str, str, str]


@dataclass(frozen=True)
class Carry:
    """A saída é o valor destas colunas, intacto: uma por ramo de união que transporta."""
    leaves: frozenset[Leaf]


@dataclass(frozen=True)
class Computed:
    """A saída é calculada; `kind` diz como, e `shape` a forma, quando uma convenção pode reconhecê-la.

    `type` é o tipo que a própria expressão declara, quando declara: o do `cast`
    (`0::real`, `(payload->>'id')::bigint`), `BOOLEAN` de teste e comparação,
    `TEXT` de concatenação. Numa união, o da constante entra na resolução do tipo de
    saída; e o de qualquer cálculo vira o tipo conhecido da coluna para quem a lê
    depois (RVL3-3-03). Não entra na igualdade: é anotação, não classificação."""
    kind: str
    shape: str | None = None
    type: str | None = field(default=None, compare=False)


Transport = Carry | Computed


def unparen(e: exp.Expression) -> exp.Expression:
    while isinstance(e, exp.Paren):
        e = e.this
    return e


def constant_value(e: exp.Expression) -> str | None:
    """O texto da constante — literal, nulo, booleano, negativo ou `cast` de constante —; `None` se não for uma."""
    e = unparen(e)
    if isinstance(e, exp.Cast):
        return constant_value(e.this)
    if isinstance(e, exp.Neg):
        valor = constant_value(e.this)
        return None if valor is None else f"-{valor}"
    if isinstance(e, exp.Literal):
        return e.this
    if isinstance(e, exp.Null):
        return "null"
    if isinstance(e, exp.Boolean):
        return "true" if e.this else "false"
    return None


def _is_not_null(e: exp.Expression) -> exp.Expression | None:
    """O sujeito de `x IS NOT NULL` — que o `sqlglot` lê como `Is(negate=True)` ou como `Not(Is(...))`."""
    if isinstance(e, exp.Is) and e.args.get("negate") and isinstance(e.expression, exp.Null):
        return unparen(e.this)
    if isinstance(e, exp.Not) and isinstance(unparen(e.this), exp.Is) and not unparen(e.this).args.get("negate") \
            and isinstance(unparen(e.this).expression, exp.Null):
        return unparen(unparen(e.this).this)
    return None


_BOOLEANOS = (exp.Is, exp.Not, exp.EQ, exp.NEQ, exp.GT, exp.GTE, exp.LT, exp.LTE, exp.And, exp.Or,
              exp.In, exp.Between, exp.Like, exp.ILike, exp.Exists, exp.NullSafeEQ, exp.NullSafeNEQ)


def _declared_type(e: exp.Expression) -> str | None:
    """O tipo que a expressão declara por si, sem precisar do tipo das entradas — ou `None`."""
    e = unparen(e)
    if isinstance(e, exp.Cast):
        return e.to.sql("postgres")
    if isinstance(e, _BOOLEANOS):
        return "BOOLEAN"
    if isinstance(e, exp.DPipe):
        return "TEXT"
    return None


def materialized_type(t: "Transport") -> str | None:
    """O tipo que a coluna calculada tem depois de materializada, quando a expressão o diz:
    o declarado (`cast`, teste, concatenação) e o da constante sem `cast` — booleano,
    inteiro, numérico, texto. `null` sem tipo não diz nada."""
    if not isinstance(t, Computed):
        return None
    if t.type:
        return None if "|" in t.type else t.type
    if t.kind != "constant" or not t.shape:
        return None
    valores = [v for v in t.shape.removeprefix("constant:").split("|") if v]
    if not valores or "null" in valores:
        return None
    if all(v in ("true", "false") for v in valores):
        return "BOOLEAN"
    if all(v.lstrip("-").isdigit() for v in valores):
        return "INTEGER"
    try:
        [float(v) for v in valores]
        return "NUMERIC"
    except ValueError:
        return "TEXT"


def constant_type(e: exp.Expression) -> str | None:
    """O tipo explícito de uma constante — o do `cast` mais de fora —, ou `None` se ela não tiver."""
    e = unparen(e)
    if isinstance(e, exp.Cast):
        return e.to.sql("postgres")
    if isinstance(e, exp.Neg):
        return constant_type(e.this)
    return None


def _constant(valores: list[str], tipo: str | None = None) -> Computed:
    return Computed("constant", "constant:" + "|".join(sorted(set(valores))), tipo)


#: Os tipos pelo nome canônico do PostgreSQL — o `sqlglot` e o SQLAlchemy grafam diferente.
_SINONIMOS = {
    "INT": "INTEGER", "INT4": "INTEGER", "INT2": "SMALLINT", "INT8": "BIGINT",
    "DECIMAL": "NUMERIC", "FLOAT4": "REAL", "FLOAT": "DOUBLE PRECISION", "FLOAT8": "DOUBLE PRECISION",
    "DOUBLE": "DOUBLE PRECISION", "TIMESTAMPTZ": "TIMESTAMP WITH TIME ZONE",
    "TIMESTAMP WITHOUT TIME ZONE": "TIMESTAMP", "BOOL": "BOOLEAN", "CHARACTER VARYING": "VARCHAR",
    "CHARACTER": "CHAR", "BPCHAR": "CHAR", "STRING": "TEXT",
}

#: Categoria e posição na ordem de conversão implícita de cada tipo que a união pode converter.
#: Numa categoria, a união resolve o tipo mais alto presente (o preferido, quando há), e todo
#: ramo é convertido para ele (PostgreSQL, "UNION, CASE, and Related Constructs").
_ORDEM = {
    "SMALLINT": ("numerico", 0), "INTEGER": ("numerico", 1), "BIGINT": ("numerico", 2), "NUMERIC": ("numerico", 3),
    "REAL": ("numerico", 4), "DOUBLE PRECISION": ("numerico", 5),
    "DATE": ("data", 0), "TIMESTAMP": ("data", 1), "TIMESTAMP WITH TIME ZONE": ("data", 2),
}


def canonical_type(tipo: str) -> str:
    base = " ".join(tipo.upper().split("(")[0].split())
    return _SINONIMOS.get(base, base)


def _conversao_preserva(de: str, para: str) -> bool:
    """Converter um valor de `de` para `para` não muda o valor: alargar inteiro, inteiro para
    numérico exato. Inteiro ou exato para ponto flutuante perde; data para instante muda o
    tipo do valor; `timestamp` para `timestamptz` depende do fuso da sessão."""
    if de == para:
        return True
    cd, pd = _ORDEM[de]
    cp, pp = _ORDEM[para]
    return cd == cp == "numerico" and pp <= 3 and pd <= pp


def _uniao_preserva(transportados: set[str], todos: set[str]) -> bool:
    """O tipo que a união resolve deixa intacto todo valor transportado?

    Só as categorias numérica e de data/hora convertem implicitamente entre tipos
    diferentes; entre as demais — texto e `uuid`, texto e `jsonb` — o PostgreSQL
    recusaria a união, e uma união que constrói tem os tipos físicos iguais (o
    declarado na origem pode diferir do físico que o Airbyte grava: `uuid` vira
    `varchar`)."""
    todos = {canonical_type(t) for t in todos}
    transportados = {canonical_type(t) for t in transportados}
    for categoria in ("numerico", "data"):
        presentes = {t for t in todos if _ORDEM.get(t, ("", 0))[0] == categoria}
        if len(presentes) < 2:
            continue
        resolvido = max(presentes, key=lambda t: _ORDEM[t][1])
        if not all(_conversao_preserva(t, resolvido) for t in transportados if t in presentes):
            return False
    return True


def combine_union(partes: list[Transport], origin_type: Callable[[Leaf], str | None] = lambda _: None) -> Transport:
    """Uma coluna de `union`, a partir do que ela é em cada ramo (N41, N45).

    O PostgreSQL resolve **um** tipo para a coluna da união, a partir de todos os
    ramos, e converte cada ramo para ele (RVL3-02): `id` `bigint` unido a `0::real`
    sai `real`, e `16777217` vira `16777216`. Por isso a união só transporta quando
    a conversão não pode mudar o valor transportado: os tipos declarados das folhas
    e os das constantes com `cast` cabem juntos sem perda (`_uniao_preserva`).
    Constante sem tipo — literal, `null` — se resolve pelo tipo dos outros ramos e
    não muda o valor. Folha de tipo desconhecido não prova nada: com mais de uma
    folha, ou diante de constante tipada, a união não transporta (RVL3-3-03). O tipo
    conhecido vem da origem, do `cast` e do que a expressão declara (`_declared_type`)."""
    transportam = [p for p in partes if isinstance(p, Carry)]
    calculam = [p for p in partes if isinstance(p, Computed)]
    if all(p.kind == "constant" for p in calculam):
        # Uma subunião só de constantes guarda **todos** os tipos que viu ("A|B"): o tipo
        # que ela resolve entra na união de fora (RVL3-2-02).
        tipados = {t for p in calculam if p.type is not None for t in p.type.split("|")}
        if transportam:
            folhas = frozenset().union(*(p.leaves for p in transportam))
            tipos = [origin_type(f) for f in folhas]
            conhecidos = {t for t in tipos if t is not None}
            if not _uniao_preserva(conhecidos, conhecidos | tipados):
                return Computed("union_coercion")
            # Tipo desconhecido não se prova: com mais de uma folha, ou diante de
            # constante tipada, a união pode converter — e a herança não vale (RVL3-3-03).
            if None in tipos and (len(folhas) > 1 or tipados):
                return Computed("union_unproven")
            return Carry(folhas)
        return _constant([v for p in calculam for v in (p.shape or "constant:").removeprefix("constant:").split("|") if v],
                         "|".join(sorted(tipados)) if tipados else None)
    return Computed("union")


def carries_by_output(query: exp.Expression, propria: tuple[str, str], origin_type: Callable[[Leaf], str | None]) -> dict[str, Transport]:
    """Por coluna de saída da consulta qualificada, o que ela faz com o valor.

    Percorre os escopos de dentro para fora, como `sensitivity._leaves_by_output`:
    a saída de um escopo é lida pelo seguinte pelo nome, e a de um `union` casa os
    ramos pela posição. `origin_type(folha)` devolve o tipo declarado na origem
    de uma coluna já classificada, ou `None` quando não se sabe.
    """
    saidas: dict[int, dict[str, Transport]] = {}

    def resolver(coluna: exp.Column, escopo: Scope) -> Transport:
        atual: Scope | None = escopo
        while atual is not None:
            fonte = atual.sources.get(coluna.table)
            if isinstance(fonte, exp.Table):
                if not fonte.db or (fonte.db, fonte.name) == propria:   # função de tabela, ou `{{ this }}`
                    return Computed("self_or_function")
                return Carry(frozenset({(fonte.db, fonte.name, coluna.name)}))
            if isinstance(fonte, Scope):
                conhecidas = saidas.get(id(fonte), saidas.get(id(fonte.expression), {}))
                if coluna.name in conhecidas:
                    return conhecidas[coluna.name]
                return Computed("table_function" if "*" in conhecidas else "unresolved")
            if fonte is not None:                                       # `unnest`, `values`
                return Computed("unnest_or_values")
            atual = atual.parent
        return Computed("unresolved")

    def classificar(projecao: exp.Expression, escopo: Scope) -> Transport:
        e = unparen(projecao.this if isinstance(projecao, exp.Alias) else projecao)
        if isinstance(e, exp.Column):
            return resolver(e, escopo)
        valor = constant_value(e)
        if valor is not None:
            return _constant([valor], constant_type(e))
        if isinstance(e, exp.Cast) and isinstance(unparen(e.this), exp.Column):
            dentro = resolver(unparen(e.this), escopo)
            alvo = e.to.sql("postgres")
            if not isinstance(dentro, Carry):
                return Computed("cast", None, alvo)
            if all(origin_type(folha) == alvo for folha in dentro.leaves):
                return dentro
            return Computed("cast", None, alvo)
        sujeito = _is_not_null(e)
        if isinstance(sujeito, exp.Column):
            return Computed("is_not_null", f"not_null:{sujeito.name}", "BOOLEAN")
        return Computed(type(e).__name__.lower(), None, _declared_type(e))

    for escopo in traverse_scope(query):
        consulta = escopo.expression
        while isinstance(consulta, (exp.Lateral, exp.Subquery)):
            consulta = consulta.this
        if isinstance(consulta, exp.SetOperation):
            ramos = [saidas.get(id(r), saidas.get(id(r.expression), {})) for r in (escopo.union_scopes or [])]
            nomes = [list(r.keys()) for r in ramos]
            resultado = {
                nome: combine_union([ramo[ramo_nomes[posicao]] for ramo, ramo_nomes in zip(ramos, nomes) if posicao < len(ramo_nomes)],
                                    origin_type)
                for posicao, nome in enumerate(nomes[0] if nomes else [])
            }
        elif isinstance(consulta, exp.Query):
            resultado = {projecao.alias_or_name: classificar(projecao, escopo) for projecao in consulta.selects}
        else:                                                           # `cross join lateral jsonb_each_text(x) f`
            resultado = {"*": Computed("table_function")}
        saidas[id(escopo)] = saidas[id(escopo.expression)] = saidas[id(consulta)] = resultado
        if isinstance(consulta.parent, exp.Subquery):
            saidas[id(consulta.parent)] = resultado
    return saidas.get(id(query), {})
