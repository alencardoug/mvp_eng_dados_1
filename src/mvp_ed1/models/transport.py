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

from dataclasses import dataclass
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
    """A saída é calculada; `kind` diz como, e `shape` a forma, quando uma convenção pode reconhecê-la."""
    kind: str
    shape: str | None = None


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


def _constant(valores: list[str]) -> Computed:
    return Computed("constant", "constant:" + "|".join(sorted(set(valores))))


def combine_union(partes: list[Transport]) -> Transport:
    """Uma coluna de `union`, a partir do que ela é em cada ramo (N41, N45)."""
    transportam = [p for p in partes if isinstance(p, Carry)]
    calculam = [p for p in partes if isinstance(p, Computed)]
    if all(p.kind == "constant" for p in calculam):
        if transportam:
            return Carry(frozenset().union(*(p.leaves for p in transportam)))
        return _constant([v for p in calculam for v in (p.shape or "constant:").removeprefix("constant:").split("|") if v])
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
            return _constant([valor])
        if isinstance(e, exp.Cast) and isinstance(unparen(e.this), exp.Column):
            dentro = resolver(unparen(e.this), escopo)
            if not isinstance(dentro, Carry):
                return Computed("cast")
            alvo = e.to.sql("postgres")
            if all(origin_type(folha) == alvo for folha in dentro.leaves):
                return dentro
            return Computed("cast")
        sujeito = _is_not_null(e)
        if isinstance(sujeito, exp.Column):
            return Computed("is_not_null", f"not_null:{sujeito.name}")
        return Computed(type(e).__name__.lower())

    for escopo in traverse_scope(query):
        consulta = escopo.expression
        while isinstance(consulta, (exp.Lateral, exp.Subquery)):
            consulta = consulta.this
        if isinstance(consulta, exp.SetOperation):
            ramos = [saidas.get(id(r), saidas.get(id(r.expression), {})) for r in (escopo.union_scopes or [])]
            nomes = [list(r.keys()) for r in ramos]
            resultado = {
                nome: combine_union([ramo[ramo_nomes[posicao]] for ramo, ramo_nomes in zip(ramos, nomes) if posicao < len(ramo_nomes)])
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
