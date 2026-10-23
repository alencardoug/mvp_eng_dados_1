"""Nenhuma view de consumo conta, agrupa ou junta por identificador sem a origem.

── A regra, e por que ela precisa de guarda ───────────────────────────────────
Dois sistemas numeram pedidos a partir de 1. A identidade de um registro é o
par (`source_system`, identificador da origem) — a macro `empilhado` diz isso
uma vez: "a origem entra na condição junto com a chave, sempre". Contar
`distinct order_id` sozinho funde o pedido 37 do legado com o pedido 37 do
varejo, e o número sai menor sem nenhum erro.

Foi o que aconteceu: P05 e P06 contavam um pedido a menos num grupo cada —
126 `order_id` existem nas duas origens —, e nenhum teste via. O `build` não
tem como ver: a view é válida, só conta errado. P01 e P02 tinham a mesma
forma e escapavam só porque nenhum grupo delas juntava os dois pedidos.

── O que este teste lê ────────────────────────────────────────────────────────
O SQL dos modelos de `consumption`, sem banco, analisado pelo `sqlglot` — o
mesmo analisador da linhagem. Identificador é a coluna `*_id` ou
`*_natural_key`; a chave substituta (`*_key`) já carrega a origem (ADR-0039) e
fica de fora. Quatro formas, cada uma com a origem obrigatória ao lado:

- `count(distinct …)` sobre identificador;
- `select distinct` que projeta identificador;
- `group by` que agrupa por identificador, inclusive por posição;
- igualdade entre identificadores numa junção ou numa subconsulta correlata.

Origem fixada por literal (`f.source_system = 'retail'`, ou `'retail' as
source_system`) conta como origem: é a forma de quem só lê uma delas.
"""

from __future__ import annotations

import pathlib
import re

import pytest
import sqlglot
from sqlglot import exp

RAIZ = pathlib.Path(__file__).resolve().parents[1]
CONSUMO = RAIZ / "dbt" / "models" / "consumption"

ORIGEM = "source_system"
_IDENTIFICADOR = re.compile(r"(_id|_natural_key)$")
_REF = re.compile(r"\{\{\s*ref\(\s*'([a-z0-9_]+)'\s*\)\s*\}\}")
_SOURCE = re.compile(r"\{\{\s*source\(\s*'([a-z0-9_]+)'\s*,\s*'([a-z0-9_]+)'\s*\)\s*\}\}")
_VAR = re.compile(r"\{\{\s*var\(\s*[\"'][a-z0-9_]+[\"']\s*\)\s*\}\}")
_CONFIG = re.compile(r"\{\{\s*config\(.*?\)\s*\}\}", re.S)


def _sql(caminho: pathlib.Path) -> str:
    """O modelo como SQL puro: `ref` e `source` viram nomes, `var` vira um número.

    O valor da variável não importa — a guarda lê identidade, não janela.
    """
    texto = caminho.read_text(encoding="utf-8")
    texto = _CONFIG.sub("", texto)
    texto = _REF.sub(r"\1", texto)
    texto = _SOURCE.sub(r"\1.\2", texto)
    texto = _VAR.sub("1", texto)
    if "{{" in texto or "{%" in texto:
        raise AssertionError(f"{caminho.name}: Jinja além de ref — ensine o teste a lê-lo")
    return texto


def _colunas(no: exp.Expression) -> set[str]:
    return {c.name for c in no.find_all(exp.Column)}


def _e_identificador(nome: str) -> bool:
    return bool(_IDENTIFICADOR.search(nome))


def _nome_de_saida(projecao: exp.Expression) -> str:
    return projecao.alias_or_name


def _resolver_agrupamento(select: exp.Select, item: exp.Expression) -> exp.Expression:
    """`group by 3` é a terceira projeção; o resto é a própria expressão."""
    if isinstance(item, exp.Literal) and item.is_int:
        return select.expressions[int(item.this) - 1]
    return item


def violacoes(sql: str) -> list[str]:
    """Cada uso de identificador sem a origem ao lado, descrito em uma linha."""
    arvore = sqlglot.parse_one(sql, read="postgres")
    achados: list[str] = []

    for contagem in arvore.find_all(exp.Count):
        alvo = contagem.this
        if isinstance(alvo, exp.Distinct):
            nomes = _colunas(alvo)
            if any(map(_e_identificador, nomes)) and ORIGEM not in nomes:
                achados.append(f"count(distinct) sem a origem: {contagem.sql()}")

    for select in arvore.find_all(exp.Select):
        projecoes = select.expressions
        saidas = {_nome_de_saida(p) for p in projecoes}
        if select.args.get("distinct"):
            if any(map(_e_identificador, saidas)) and ORIGEM not in saidas:
                ids = sorted(n for n in saidas if _e_identificador(n))
                achados.append(f"select distinct sem a origem: {', '.join(ids)}")

        grupo = select.args.get("group")
        if grupo:
            itens = [_resolver_agrupamento(select, i) for i in grupo.expressions]
            nomes = {_nome_de_saida(i) for i in itens} | set().union(*(_colunas(i) for i in itens))
            if any(map(_e_identificador, nomes)) and ORIGEM not in nomes:
                ids = sorted(n for n in nomes if _e_identificador(n))
                achados.append(f"group by sem a origem: {', '.join(ids)}")

    # Cada igualdade responde à cláusula que a contém de perto — a do `exists`,
    # não a do `where` de fora que o envolve.
    acusadas: list[exp.Expression] = []
    for igualdade in arvore.find_all(exp.EQ):
        lados = (igualdade.left, igualdade.right)
        if not all(isinstance(l, exp.Column) and _e_identificador(l.name) for l in lados):
            continue
        clausula = igualdade.find_ancestor(exp.Where, exp.Join)
        condicao = clausula.this if isinstance(clausula, exp.Where) else clausula.args.get("on")
        if ORIGEM not in _colunas(condicao) and not any(condicao is a for a in acusadas):
            acusadas.append(condicao)
            achados.append(f"junção sem a origem: {condicao.sql()}")

    return achados


MODELOS = sorted(CONSUMO.glob("*.sql"))


def test_ha_views_para_ler() -> None:
    """Sem isto, um caminho errado faria o teste abaixo passar por vacuidade."""
    assert len(MODELOS) == 16


@pytest.mark.parametrize("modelo", MODELOS, ids=lambda p: p.stem)
def test_view_usa_a_origem_com_o_identificador(modelo: pathlib.Path) -> None:
    achados = violacoes(_sql(modelo))
    assert not achados, f"{modelo.name}:\n  " + "\n  ".join(achados)


@pytest.mark.parametrize(
    ("sql", "esperado"),
    [
        ("select count(distinct order_id) from f", 1),
        ("select count(distinct (source_system, order_id)) from f", 0),
        ("select count(distinct customer_key) from f", 0),
        ("select distinct shipment_id, carrier_key from f", 1),
        ("select distinct source_system, shipment_id, carrier_key from f", 0),
        ("select product_natural_key, sum(q) from f group by 1", 1),
        ("select p.source_system, p.product_natural_key, sum(q) from f p group by 1, 2", 0),
        ("select 'retail' as source_system, s.movement_id from s group by 1, 2", 0),
        ("select * from a join b on a.order_id = b.order_id", 1),
        ("select * from a join b on a.source_system = b.source_system and a.order_id = b.order_id", 0),
        ("select * from a where exists (select 1 from b where b.movement_id = a.movement_id)", 1),
        ("select * from a where exists (select 1 from b where b.source_system = 'retail'"
         " and b.movement_id = a.movement_id)", 0),
        ("select * from a join b on a.year_month = b.year_month", 0),
    ],
)
def test_a_guarda_reconhece_cada_forma(sql: str, esperado: int) -> None:
    """Contraprovas: cada forma acusada sem a origem e aceita com ela."""
    assert len(violacoes(sql)) == esperado, violacoes(sql)
