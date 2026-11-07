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
linha juntada (RVL2-2-02). No `in (select …)`, uma forma só: tupla plana, a
origem de fora casando na mesma posição com a origem **qualificada** de uma
relação declarada na subconsulta, aliases distintos (RVL2-3-03, RVL2-4-02/03).

O princípio, depois de quatro rodadas de revisão: **a guarda aceita o que consegue
provar e acusa o resto.** Um falso positivo numa forma não reconhecida custa
reescrever a view na forma reconhecida; um falso negativo é o pedido 37 fundido. Na projeção, `'retail'
as source_system` conta como origem: é a forma de quem só lê uma delas.

**Limite:** a guarda lê a sintaxe de cada cláusula, não o fluxo entre elas. O
escopo ela resolve só para a exceção da fonte de origem única: o qualificador é
procurado no `from` do próprio `select` e dos que o envolvem, nunca numa CTE
vizinha (RVL2-3-02), e só vale se nomeia uma relação só na consulta inteira e
nenhum item de `from`/`join` ficou sem nome legível — os nós inspecionados estão
em `_relacao_sem_nome` (RVL2-4-01, RVL2-6-02, RVL2-7-01); para o resto, é o
que está escrito, com os nomes normalizados como o PostgreSQL (RVL2-6-01). Coluna
qualificada por schema não entra em prova nenhuma (RVL2-6-03). A origem renomeada (`source_system as origin`) não é reconhecida e é acusada, por
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
from sqlglot.optimizer.normalize_identifiers import normalize_identifiers

RAIZ = pathlib.Path(__file__).resolve().parents[1]
CONSUMO = RAIZ / "dbt" / "models" / "consumption"

ORIGEM = "source_system"
_IDENTIFICADOR = re.compile(r"(_id|_natural_key)$")
_REF = re.compile(r"\{\{\s*ref\(\s*'([a-z0-9_]+)'\s*\)\s*\}\}")
_SOURCE = re.compile(r"\{\{\s*source\(\s*'([a-z0-9_]+)'\s*,\s*'([a-z0-9_]+)'\s*\)\s*\}\}")
_VAR = re.compile(r"\{\{\s*var\(\s*[\"'][a-z0-9_]+[\"']\s*\)\s*\}\}")
_CONFIG = re.compile(r"\{\{\s*config\(.*?\)\s*\}\}", re.S)
#: A janela de dias no calendário (macro `dias_no_calendario`): para a identidade, só o instante importa.
_DIAS = re.compile(r"\{\{\s*dias_no_calendario\(\s*'([^']*)'\s*,\s*-?var\(\s*[\"'][a-z0-9_]+[\"']\s*\)\s*\)\s*\}\}")
#: As macros de dialeto da Etapa 13 (`dbt/macros/distinct_on.sql`), lidas na forma que o alvo
#: local compila — a mesma que esta guarda sempre leu. Forma fora destas continua recusada.
_DISTINCT_ON = re.compile(r"\{\{\s*distinct_on\(\s*'([^']*)'\s*\)\s*\}\}")
_DISTINCT_ON_ORDER = re.compile(r"\{\{\s*distinct_on_order\(\s*'([^']*)'\s*,\s*'([^']*)'\s*\)\s*\}\}")
_BOOL = re.compile(r"""\{\{\s*(?:dbt\.)?(bool_or|bool_and)\(\s*(["'])(.*?)\2\s*\)\s*\}\}""")


def _sql(caminho: pathlib.Path) -> str:
    """O modelo como SQL puro: `ref` e `source` viram nomes, `var` vira um número, e a
    janela `dias_no_calendario(instante, n)` vira o instante.

    O valor da variável não importa — a guarda lê identidade, não janela.
    """
    texto = caminho.read_text(encoding="utf-8")
    texto = _CONFIG.sub("", texto)
    texto = _DIAS.sub(r"(\1)", texto)
    texto = _REF.sub(r"\1", texto)
    texto = _SOURCE.sub(r"\1.\2", texto)
    texto = _VAR.sub("1", texto)
    texto = _DISTINCT_ON.sub(r"distinct on (\1)", texto)
    texto = _DISTINCT_ON_ORDER.sub(r"order by \2", texto)
    texto = _BOOL.sub(r"\1(\3)", texto)
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


def _fontes_diretas_lista(select: exp.Select) -> list[exp.Expression]:
    """Os itens do `from` e dos `join` deste `select`, sem descer."""
    origem = select.args.get("from_")
    return ([origem.this] if origem else []) + [j.this for j in select.args.get("joins") or []]


def _fontes_diretas(select: exp.Select) -> dict[str, exp.Expression]:
    """O que o `from` e os `join` deste `select` nomeiam, pelo qualificador — sem descer."""
    return {i.alias_or_name: i for i in _fontes_diretas_lista(select)}


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


def _ligacoes(arvore: exp.Expression, qualificador: str) -> list[exp.Expression]:
    """Toda relação da consulta inteira que o qualificador nomeia.

    Todo alias de relação — de tabela, subconsulta, CTE, `values`, `lateral`,
    `unnest` — é um `TableAlias`; tabela sem alias se nomeia pelo próprio nome.
    Contar o alias, e não os tipos de relação, é o que não deixa uma forma nova
    de fora (RVL2-5-01)."""
    return [a.parent for a in arvore.find_all(exp.TableAlias) if a.name == qualificador] + [
        t for t in arvore.find_all(exp.Table) if not t.alias and t.name == qualificador
    ]


def _relacao_sem_nome(arvore: exp.Expression) -> bool:
    """Uma relação cujo nome a guarda não lê. Diante dela, a contagem de ligações
    não é prova, e a exceção não vale para a consulta (RVL2-6-02, RVL2-7-01).

    O que se inspeciona, e só isto: todo item de `from`/`join` de todo `select`
    que não seja tabela nomeada nem tenha alias — a função no `from`, como
    `json_to_record(…) as (…)` ou `unnest(…)`, que o PostgreSQL nomeia pela
    função —, todo `unnest` sem alias em qualquer ponto, e todo `TableAlias` ou
    `Table` de nome vazio."""
    itens = [i for sel in arvore.find_all(exp.Select) for i in _fontes_diretas_lista(sel)]
    return (
        any(not (isinstance(i, exp.Table) and i.name) and not i.alias for i in itens)
        or any(not u.alias for u in arvore.find_all(exp.Unnest))
        or any(not a.name for a in arvore.find_all(exp.TableAlias))
        or any(not t.name and not t.alias for t in arvore.find_all(exp.Table))
    )


def _qualificacao_longa(colunas) -> bool:
    """`trusted.orders.order_id` e `orders.order_id` têm o mesmo `.table` e podem ser
    relações diferentes: coluna com schema ou catálogo não entra em prova (RVL2-6-03)."""
    return any(c.args.get("db") or c.args.get("catalog") for c in colunas)


def _origem_fixa_por_fonte(no: exp.Expression, qualificador: str) -> set[str]:
    """A origem de um lado que lê, no próprio escopo, uma fonte de origem única.

    Só quando o qualificador nomeia **uma relação só na consulta inteira**: um
    alias repetido — um join entre parênteses, uma subconsulta que o reaproveita —
    é escopo que a guarda não resolve, e ela não concede a exceção (RVL2-4-01)."""
    raiz = no.root()
    if not qualificador or len(_ligacoes(raiz, qualificador)) != 1 or _relacao_sem_nome(raiz):
        return set()
    relacao = _relacao_do_lado(no, qualificador)
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
    if _qualificacao_longa(condicao.find_all(exp.Column)):
        return False
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
    """`(a.source_system, a.order_id) in (select b.source_system, b.order_id from b)`
    — e só essa forma (RVL2-3-03, RVL2-4-02, RVL2-4-03).

    A guarda aceita o que consegue provar e acusa o resto. Prova é: tupla plana de
    colunas dos dois lados, do mesmo tamanho; a origem na mesma posição; de fora,
    **todas as posições** com um qualificador só, não vazio, que a subconsulta
    não declara; de dentro, todas **qualificadas** por uma relação só, declarada no
    `from` da própria subconsulta. Nenhuma posição sai da prova — uma coluna comum
    de outra relação também multiplica as linhas (RVL2-5-03) —, e coluna de fora sem
    qualificador pode ser de qualquer relação de fora (RVL2-5-02). Coluna sem qualificador dentro pode ser a de fora — o
    PostgreSQL a procura lá quando a relação interna não a tem —, e origem de uma
    relação com identificador de outra não liga nada. Alias igual nos dois escopos,
    tupla aninhada e `select *` também acusam: são formas que a guarda não resolve."""
    consulta = pertence.args["query"]
    consulta = consulta.this if isinstance(consulta, exp.Subquery) else consulta
    if not isinstance(pertence.this, exp.Tuple) or not isinstance(consulta, exp.Select):
        return False
    fora = list(pertence.this.expressions)
    dentro = [d.this if isinstance(d, exp.Alias) else d for d in consulta.expressions]
    if len(fora) != len(dentro) or not all(isinstance(c, exp.Column) and not c.is_star for c in fora + dentro):
        return False  # `b.*` é `Column(Star)` no sqlglot: expansão, não coluna (RVL2-6-04)
    if _qualificacao_longa(fora + dentro):
        return False
    proprias = set(_fontes_diretas(consulta))
    de_fora = {f.table for f in fora}
    de_dentro = {d.table for d in dentro}
    return (
        any(f.name == ORIGEM and d.name == ORIGEM for f, d in zip(fora, dentro))
        and len(de_fora) == 1 and "" not in de_fora and not de_fora & proprias
        and len(de_dentro) == 1 and "" not in de_dentro and de_dentro <= proprias
    )


def violacoes(sql: str) -> list[str]:
    """Cada uso de identificador sem a origem ao lado, descrito em uma linha."""
    # Os nomes como o PostgreSQL os vê: sem aspas vira minúscula, entre aspas fica
    # como está — `S` e `s` são o mesmo alias, `"S"` é outro (RVL2-6-01, RVL2-6-05).
    arvore = normalize_identifiers(sqlglot.parse_one(sql, read="postgres"), dialect="postgres")
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
        # O identificador de qualquer dos lados chama a prova, não só o de fora (RVL2-6-06).
        consulta = pertence.args["query"]
        nomes = _colunas(pertence.this) | set().union(*(_colunas(d) for d in getattr(
            consulta.this if isinstance(consulta, exp.Subquery) else consulta, "expressions", [])))
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
        ("select * from a where (a.source_system, a.order_id) in (select b.source_system, b.order_id from b)", 0),
        # RVL2-5-02: de fora sem qualificador pode ser origem de `a` e identificador de `c`
        ("select * from a where (source_system, order_id) in (select b.source_system, b.order_id from b)", 1),
        ("select * from a cross join c where (source_system, order_id) in"
         " (select b.source_system, b.order_id from b)", 1),
        # RVL2-5-03: nenhuma posição sai da prova
        ("select * from a where (a.source_system, a.tag, a.order_id) in"
         " (select b.source_system, c.customer_id, b.order_id from b cross join c)", 1),
        ("select * from a where (a.source_system, a.tag, a.order_id) in"
         " (select b.source_system, c.tag, b.order_id from b cross join c)", 1),
        ("select * from a where (a.source_system, a.tag, a.order_id) in"
         " (select b.source_system, b.tag, b.order_id from b)", 0),
        ("select * from a where (source_system, order_id) in (select source_system, order_id from b)", 1),
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
        # RVL2-4-01: alias repetido num join entre parênteses não empresta a fonte de fora
        ("select * from retail.orders s where exists (select 1 from (a x join b s"
         " on x.order_id = s.order_id and x.source_system = 'retail'))", 1),
        # RVL2-5-01: alias de `values`, `lateral` ou `unnest` também esconde o de fora
        ("select * from retail.orders s where exists (select 1 from (a x join (values ('legacy', 1))"
         " s(source_system, order_id) on x.order_id = s.order_id and x.source_system = 'retail'))", 1),
        ("select * from retail.orders s where exists (select 1 from (a x join lateral"
         " (select order_id from b) s on x.order_id = s.order_id and x.source_system = 'retail'))", 1),
        ("select * from retail.orders s where exists (select 1 from (a x join unnest(array[1])"
         " s(order_id) on x.order_id = s.order_id and x.source_system = 'retail'))", 1),
        # RVL2-6-01/05: os nomes como o PostgreSQL os vê — sem aspas, a caixa não importa
        ("select * from retail.orders s where exists (select 1 from (a x join b S"
         " on x.order_id = s.order_id and x.source_system = 'retail'))", 1),
        ("select * from a join b on a.ORDER_ID = b.ORDER_ID", 1),
        # RVL2-6-02: função no `from` sem alias é relação que a guarda não nomeia
        ("select * from retail.orders s where exists (select 1 from json_to_record('{}')"
         " as (source_system text, order_id int) where json_to_record.order_id = s.order_id"
         " and json_to_record.source_system = 'retail')", 1),
        # RVL2-7-01: `unnest` sem alias também é relação sem nome legível
        ("select * from retail.orders unnest where exists (select 1 from (a x join unnest(array[1])"
         " on x.order_id = unnest.order_id and x.source_system = 'retail'))", 1),
        # RVL2-6-03: schema na coluna não entra em prova
        ("select * from a where (a.source_system, a.order_id) in"
         " (select orders.source_system, trusted.orders.order_id from orders)", 1),
        # RVL2-6-04: `b.*` é expansão, não coluna
        ("select * from a where (a.source_system, a.order_id) in (select b.source_system, b.* from b)", 1),
        # RVL2-6-06: identificador só do lado de dentro também chama a prova
        ("select * from a where a.tag in (select b.order_id from b)", 1),
        ("select * from a where (a.source_system, a.tag) in (select b.source_system, b.order_id from b)", 0),
        # RVL2-4-02: origem sem qualificador dentro, ou de outra relação, não prova nada
        ("select * from a where (a.source_system, a.order_id) in (select source_system, b.order_id from b)", 1),
        ("select * from a where (a.source_system, a.order_id) in"
         " (select b.source_system, c.order_id from b cross join c)", 1),
        ("select * from a where (a.source_system, a.order_id) in (select source_system, 37)", 1),
        # RVL2-4-03: formas que a guarda não resolve acusam, declaradas — alias igual nos dois
        # escopos, tupla aninhada, `select *`; com aliases distintos e alias de coluna, passa
        ("select * from a x where (x.source_system, x.order_id) in"
         " (select x.source_system, x.order_id from b x)", 1),
        ("select * from a where ((a.source_system, a.order_id), a.customer_id) in"
         " (select (b.source_system, b.order_id), b.customer_id from b)", 1),
        ("select * from a where (a.source_system, a.order_id) in (select * from b)", 1),
        ("select * from a x where (x.source_system, x.order_id) in"
         " (select y.source_system as source_system, y.order_id as order_id from b y)", 0),
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
