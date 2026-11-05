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
fica de fora. Seis formas, cada uma com a origem obrigatória ao lado:

- `count(distinct …)` sobre identificador;
- `select distinct` que projeta identificador;
- `distinct on (…)` cuja chave tem identificador — a chave, não a projeção;
- `group by` que agrupa por identificador, inclusive por posição;
- janela `partition by` identificador;
- igualdade entre identificadores numa junção ou numa subconsulta correlata
  (`=`, `is not distinct from`, `using`, `in (select …)`), com a origem
  restringindo **os dois lados**.

"Os dois lados" quer dizer: a origem igualada entre os mesmos dois lados, ou fixada
em cada um com o mesmo valor — por literal (`f.source_system = 'retail'`, também
com `::text`) ou por ler, no escopo do próprio lado, uma fonte dbt de origem única
(`source('retail', …)`, a forma de P12). Só vale o termo ligado por `and` no topo
da condição: sob `or`, `not` ou numa subconsulta de terceiro ele não restringe a
linha juntada (RVL2-2-02). No `in (select …)`, a origem de fora casa, na mesma
posição, com a origem da subconsulta (RVL2-3-03). Na projeção, `'retail'
as source_system` conta como origem: é a forma de quem só lê uma delas.

**Limite:** a guarda lê a sintaxe de cada cláusula, não o fluxo entre elas. O
escopo ela resolve só para a exceção da fonte de origem única: o qualificador é
procurado no `from` do próprio `select` e dos que o envolvem, nunca numa CTE
vizinha (RVL2-3-02); para o resto, é o que está escrito. A origem renomeada (`source_system as origin`) não é reconhecida e é acusada, por
cautela — mantenha o nome. Passam sem achado: uma CTE que já perdeu
`source_system` e depois reduz por `count(*)` sobre linhas de identificadores
repetidos, e um `union` (sem `all`) que deduplica sem a origem. As 16 views foram
lidas uma a uma na revisão do lote 2 da v1.1.0 sem nenhuma dessas formas (RVL2-03,
RVL2-2-04); uma view nova que as use precisa ensinar o teste.
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


# `source('retail', …)` e `source('legacy', …)`: o nome da fonte dbt é a própria
# origem — toda linha de uma tabela dessas tem aquela origem e só ela.
_ORIGENS = {"retail", "legacy"}


def _conjuncoes(condicao: exp.Expression) -> list[exp.Expression]:
    """Os termos ligados por `and` no topo da condição — o que vale para toda linha.

    Igualdade sob `or` ou `not`, ou dentro de uma subconsulta, não restringe a
    linha juntada, e por isso não entra (RVL2-2-02)."""
    while isinstance(condicao, exp.Paren):
        condicao = condicao.this
    if isinstance(condicao, exp.And):
        return _conjuncoes(condicao.left) + _conjuncoes(condicao.right)
    return [condicao]


def _fontes_diretas(select: exp.Select) -> dict[str, exp.Expression]:
    """O que o `from` e os `join` deste `select` nomeiam, pelo qualificador — sem descer."""
    origem = select.args.get("from_")
    itens = ([origem.this] if origem else []) + [j.this for j in select.args.get("joins") or []]
    return {i.alias_or_name: i for i in itens}


def _relacao_do_lado(no: exp.Expression, qualificador: str) -> exp.Expression | None:
    """A relação que o qualificador nomeia no escopo do nó: o `select` mais próximo
    que o declara, subindo pelas subconsultas correlatas — nunca uma CTE vizinha,
    nem de dentro de uma CTE para a consulta que a usa (RVL2-3-02)."""
    atual = no
    while atual is not None:
        if isinstance(atual, exp.Select) and qualificador in (fontes := _fontes_diretas(atual)):
            return fontes[qualificador]
        if isinstance(atual, exp.CTE):
            return None
        atual = atual.parent
    return None


def _origem_fixa_por_fonte(no: exp.Expression, qualificador: str) -> set[str]:
    """A origem de um lado que lê, no próprio escopo, uma fonte de origem única."""
    relacao = _relacao_do_lado(no, qualificador) if qualificador else None
    if isinstance(relacao, exp.Table) and relacao.db in _ORIGENS:
        return {relacao.db}
    return set()


def _texto_literal(no: exp.Expression) -> str | None:
    """`'retail'`, ou `'retail'::text` — o *cast* que não muda o valor (RVL2-3-04).

    `varchar(3)` truncaria, e por isso só conta o tipo sem parâmetro."""
    if isinstance(no, exp.Cast) and no.to.this in (exp.DataType.Type.TEXT, exp.DataType.Type.VARCHAR) \
            and not no.to.expressions:
        no = no.this
    return no.this if isinstance(no, exp.Literal) and no.is_string else None


def _origem_correlaciona(condicao: exp.Expression, lados: set[str], no: exp.Expression) -> bool:
    """A origem restringe **os dois lados** da igualdade de identificadores.

    Ou a condição iguala a origem entre esses mesmos dois lados, ou cada lado tem
    a origem fixada — por literal na condição, ou por ler, no próprio escopo, uma
    fonte de origem única — e é a mesma nos dois. Literal num lado só deixa o
    outro livre: `a.order_id = b.order_id and b.source_system = 'retail'` junta o
    37 do legado com o 37 do varejo (RVL2-2-02)."""
    fixadas: dict[str, set[str]] = {}
    for termo in _conjuncoes(condicao):
        if not isinstance(termo, (exp.EQ, exp.NullSafeEQ)):
            continue
        colunas = [l for l in (termo.left, termo.right) if isinstance(l, exp.Column) and l.name == ORIGEM]
        literais = [t for t in map(_texto_literal, (termo.left, termo.right)) if t is not None]
        if len(colunas) == 2 and {c.table for c in colunas} == lados:
            return True
        if len(colunas) == 1 and len(literais) == 1:
            fixadas.setdefault(colunas[0].table, set()).add(literais[0])
    origens = [fixadas.get(lado) or _origem_fixa_por_fonte(no, lado) for lado in lados]
    return all(len(o) == 1 for o in origens) and len(set().union(*origens)) == 1


def _pertence_correlaciona(pertence: exp.In) -> bool:
    """`(origem, id) in (select origem, id from b)`: a origem de fora casa, na mesma
    posição, com a origem **da subconsulta** — não com um literal, nem com a coluna
    de fora citada de novo lá dentro (RVL2-3-03)."""
    fora = pertence.this.expressions if isinstance(pertence.this, exp.Tuple) else [pertence.this]
    consulta = pertence.args["query"]
    consulta = consulta.this if isinstance(consulta, exp.Subquery) else consulta
    if not isinstance(consulta, exp.Select) or len(consulta.expressions) != len(fora):
        return False
    proprias = _fontes_diretas(consulta)
    for esquerda, direita in zip(fora, consulta.expressions):
        direita = direita.this if isinstance(direita, exp.Alias) else direita
        if (isinstance(esquerda, exp.Column) and esquerda.name == ORIGEM
                and isinstance(direita, exp.Column) and direita.name == ORIGEM
                and esquerda.table not in proprias and (not direita.table or direita.table in proprias)):
            return True
    return False


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
        distinto = select.args.get("distinct")
        if distinto and distinto.args.get("on"):
            # `distinct on (…)` reduz pela chave entre parênteses, não pela projeção (RVL2-03).
            chave = set().union(*(_colunas(i) | {_nome_de_saida(i)} for i in distinto.args["on"].expressions))
            if any(map(_e_identificador, chave)) and ORIGEM not in chave:
                ids = sorted(n for n in chave if _e_identificador(n))
                achados.append(f"distinct on sem a origem: {', '.join(ids)}")
        elif distinto:
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

    for janela in arvore.find_all(exp.Window):
        particao = set().union(*(_colunas(i) for i in janela.args.get("partition_by") or []))
        if any(map(_e_identificador, particao)) and ORIGEM not in particao:
            ids = sorted(n for n in particao if _e_identificador(n))
            achados.append(f"janela particionada sem a origem: {', '.join(ids)}")

    # Cada igualdade responde à cláusula que a contém de perto — a do `exists`,
    # não a do `where` de fora que o envolve. A origem tem de restringir **os
    # dois lados** que o identificador liga (RVL2-03, RVL2-2-02). A igualdade
    # nula-segura (`is not distinct from`) é igualdade também (RVL2-2-03).
    acusadas: list[exp.Expression] = []
    for igualdade in arvore.find_all(exp.EQ, exp.NullSafeEQ):
        lados = (igualdade.left, igualdade.right)
        if not all(isinstance(l, exp.Column) and _e_identificador(l.name) for l in lados):
            continue
        # A cláusula mais próxima; se antes dela vem um `select`, a igualdade está
        # na projeção, em qualquer nível — não junta nem reduz linha (RVL2-3-06).
        clausula = igualdade.find_ancestor(exp.Where, exp.Join, exp.Select)
        if not isinstance(clausula, (exp.Where, exp.Join)):
            continue
        condicao = clausula.this if isinstance(clausula, exp.Where) else clausula.args.get("on")
        if condicao is None:
            continue
        if _origem_correlaciona(condicao, {l.table for l in lados}, igualdade) or any(condicao is a for a in acusadas):
            continue
        acusadas.append(condicao)
        achados.append(f"junção sem a origem: {condicao.sql()}")

    # `join … using (…)` é a mesma igualdade escrita pelo nome (RVL2-2-04).
    for juncao in arvore.find_all(exp.Join):
        nomes = {i.name for i in juncao.args.get("using") or []}
        if any(map(_e_identificador, nomes)) and ORIGEM not in nomes:
            ids = sorted(n for n in nomes if _e_identificador(n))
            achados.append(f"junção using sem a origem: {', '.join(ids)}")

    # `… in (select …)` é uma semijunção: o identificador sozinho casa com o da
    # outra origem (RVL2-2-04).
    for pertence in arvore.find_all(exp.In):
        if pertence.args.get("query") is None:
            continue
        nomes = _colunas(pertence.this)
        if any(map(_e_identificador, nomes)) and not _pertence_correlaciona(pertence):
            ids = sorted(n for n in nomes if _e_identificador(n))
            achados.append(f"in (subconsulta) sem a origem: {', '.join(ids)}")

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
        # literal num lado só deixa o outro livre (RVL2-2-02) …
        ("select * from a where exists (select 1 from b where b.source_system = 'retail'"
         " and b.movement_id = a.movement_id)", 1),
        ("select * from a where exists (select 1 from b where b.source_system = 'retail'"
         " and a.source_system = 'retail' and b.movement_id = a.movement_id)", 0),
        ("select * from a join b on a.order_id = b.order_id"
         " and a.source_system = 'legacy' and b.source_system = 'retail'", 1),
        # … salvo quando o outro lado lê uma fonte de origem única, a forma de P12
        ("select * from retail.stream s where not exists (select 1 from f"
         " where f.source_system = 'retail' and f.movement_id = s.movement_id)", 0),
        ("select * from legacy.stream s where not exists (select 1 from f"
         " where f.source_system = 'retail' and f.movement_id = s.movement_id)", 1),
        ("select * from a join b on a.year_month = b.year_month", 0),
        # RVL2-03: a origem na projeção não entra na chave do `distinct on`
        ("select distinct on (order_id) source_system, order_id from f", 1),
        ("select distinct on (source_system, order_id) source_system, order_id from f", 0),
        # … nem a origem de uma tabela igualada a ela mesma correlaciona os lados
        ("select * from a join b on a.order_id = b.order_id and a.source_system = a.source_system", 1),
        ("select * from a join b on a.order_id = b.order_id and b.source_system = c.source_system", 1),
        ("select * from a join b on b.source_system = a.source_system and a.order_id = b.order_id", 0),
        # … e a janela particionada pelo identificador funde as duas origens
        ("select row_number() over (partition by order_id) from f", 1),
        ("select row_number() over (partition by source_system, order_id) from f", 0),
        ("select rank() over (partition by year_month order by x) from f", 0),
        # RVL2-2-02: origem sob `or`, `not` ou numa subconsulta de terceiro não restringe
        ("select * from a join b on a.order_id = b.order_id and b.source_system = 'retail'", 1),
        ("select * from a join b on a.order_id = b.order_id and exists"
         " (select 1 from c where c.source_system = 'retail')", 1),
        ("select * from a join b on a.order_id = b.order_id or a.source_system = b.source_system", 1),
        ("select * from a join b on a.order_id = b.order_id and not (a.source_system = b.source_system)", 1),
        ("select * from a join b on (a.order_id = b.order_id and (a.source_system = b.source_system))", 0),
        # RVL2-2-03: a igualdade nula-segura da origem é igualdade
        ("select * from a join b on a.order_id = b.order_id"
         " and a.source_system is not distinct from b.source_system", 0),
        # RVL2-2-04: a mesma igualdade escrita de outro jeito
        ("select * from a join b on a.order_id is not distinct from b.order_id", 1),
        ("select * from a join b using (order_id)", 1),
        ("select * from a join b using (source_system, order_id)", 0),
        ("select * from a where order_id in (select order_id from b)", 1),
        ("select * from a where order_id not in (select order_id from b)", 1),
        ("select * from a where (source_system, order_id) in (select source_system, order_id from b)", 0),
        ("select * from a where order_id in (1, 2)", 0),
        ("select a.order_id = b.order_id from a cross join b", 0),
        # RVL2-3-02: a fonte de origem única vale no escopo do lado, não em CTE vizinha
        ("with c as (select * from retail.orders x cross join retail.order_items y)"
         " select * from a x join b y on x.order_id = y.order_id", 1),
        ("select * from a s join b f on s.order_id = f.order_id and f.source_system = 'retail'"
         " where exists (select 1 from retail.orders s)", 1),
        ("with c as (select * from retail.orders s)"
         " select * from a s join b f on s.order_id = f.order_id and f.source_system = 'retail'", 1),
        ("select * from retail.orders s join b f on s.order_id = f.order_id and f.source_system = 'retail'", 0),
        # RVL2-3-03: no `in`, a origem de fora casa com a da subconsulta, na mesma posição
        ("select * from a where (source_system, order_id) in (select 'retail', order_id from b)", 1),
        ("select * from a where (a.source_system, a.order_id) in (select a.source_system, b.order_id from b)", 1),
        ("select * from a where (a.source_system, a.order_id) in (select b.source_system, b.order_id from b)", 0),
        ("select * from a where (order_id, source_system) in (select source_system, order_id from b)", 1),
        ("select * from a where (source_system, order_id) not in (select order_id, source_system from b)", 1),
        # RVL2-3-04: o cast para texto sem parâmetro não muda o literal; `varchar(3)` muda
        ("select * from a join b on a.order_id = b.order_id"
         " and a.source_system = 'retail'::text and b.source_system = 'retail'", 0),
        ("select * from a join b on a.order_id = b.order_id"
         " and a.source_system = 'retail'::varchar(3) and b.source_system = 'retail'", 1),
        # RVL2-3-06: igualdade na projeção de uma subconsulta juntada por `using`
        ("select * from a join (select order_id = other_id as flag, source_system, order_id from b) b"
         " using (source_system, order_id)", 0),
        # Limite declarado: a origem renomeada não é reconhecida — acusa, por cautela
        ("with x as (select source_system as origin, order_id from a)"
         " select * from x join b on x.order_id = b.order_id and x.origin = b.source_system", 1),
    ],
)
def test_a_guarda_reconhece_cada_forma(sql: str, esperado: int) -> None:
    """Contraprovas: cada forma acusada sem a origem e aceita com ela."""
    assert len(violacoes(sql)) == esperado, violacoes(sql)
