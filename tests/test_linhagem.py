"""Linhagem por coluna: toda coluna fecha numa origem, e a origem é a que o SQL diz.

Duas metades. A regra (`models/lineage.py`), provada sem banco e sem manifest:
o fecho transitivo para na fonte, na seed ou na coluna gerada; `meta.lineage`
substitui o que o SQL dá, e folha declarada que não existe é problema; a ponte
do legado declara, coluna a coluna, de que coluna de `raw_legacy` vem. E a
medição sobre o manifest real: nenhum problema, toda coluna com origem, o
consumo apontando para as colunas que o SQL usa — e nunca para o payload
inteiro do legado, que é o que a declaração da ponte existe para evitar.
"""

from __future__ import annotations

import json
import pathlib

import pytest

from mvp_ed1.legacy import ponte
from mvp_ed1.models import lineage as l
from mvp_ed1.models import sensitivity

RAIZ = pathlib.Path(__file__).resolve().parents[1]


# ── A regra, por extenso ─────────────────────────────────────────────────────


def test_o_fecho_para_na_fonte_na_seed_ou_na_coluna_gerada() -> None:
    linhagem = l.Lineage(
        leaves={
            ("staging", "a"): {"x": {("raw", "t", "c1")}, "k": set()},
            ("trusted", "s"): {"uf": set()},
            ("trusted", "b"): {"y": {("staging", "a", "x"), ("staging", "a", "k"), ("trusted", "s", "uf")}},
            ("consumption", "v"): {"z": {("trusted", "b", "y")}},
        },
        seeds={("trusted", "s")},
    )
    origens = linhagem.origins("consumption", "v", "z")
    assert origens == {("raw", "t", "c1"), ("staging", "a", "k"), ("trusted", "s", "uf")}
    assert {linhagem.kind(o) for o in origens} == {"fonte", "gerada", "seed"}
    assert linhagem.origins("raw", "t", "c1") == {("raw", "t", "c1")}
    totais = l.summary(linhagem)
    assert totais["consumption"] == {"colunas": 1, "de_fonte": 1}
    assert totais["trusted"] == {"colunas": 2, "de_fonte": 1, "de_seed": 1}
    assert totais["staging"] == {"colunas": 2, "de_fonte": 1, "geradas": 1}


def _manifest(colunas: dict) -> dict:
    return {
        "sources": {},
        "nodes": {
            "model.t.m": {
                "unique_id": "model.t.m", "resource_type": "model", "name": "m", "alias": "m",
                "database": "wh", "schema": "trusted", "depends_on": {"nodes": []},
                "compiled_code": 'select first_name as nome, id from "wh"."raw"."customers"',
                "columns": colunas,
            }
        },
    }


def test_meta_lineage_substitui_o_sql_e_folha_inexistente_e_problema() -> None:
    sem_declaracao = l.build(_manifest({}))
    assert sem_declaracao.problems == []
    assert sem_declaracao.origins("trusted", "m", "nome") == {("raw", "customers", "first_name")}

    declarado = l.build(_manifest({
        "nome": {"name": "nome", "meta": {"lineage": ["raw_legacy.customers.first_name"]}},
        "id": {"name": "id", "meta": {"lineage": []}},
    }))
    assert declarado.problems == []
    assert declarado.origins("trusted", "m", "nome") == {("raw_legacy", "customers", "first_name")}
    assert declarado.origins("trusted", "m", "id") == {("trusted", "m", "id")}   # constante declarada: gerada

    errado = l.build(_manifest({"nome": {"name": "nome", "meta": {"lineage": ["raw.customers.nao_existe"]}}}))
    assert len(errado.problems) == 1 and "raw.customers.nao_existe" in errado.problems[0]


def test_a_ponte_declara_de_que_coluna_de_raw_legacy_cada_apelido_vem() -> None:
    orders = dict(ponte.origens("orders"))
    assert orders["order_total_amount"] == ["raw_legacy.orders.total_amount"]
    assert orders["is_deleted"] == ["raw_legacy.orders.deleted_at"]
    assert orders["ingested_at"] == ["raw_legacy.orders._airbyte_extracted_at"]
    balances = dict(ponte.origens("inventory_balances"))
    # derivada recalculada: as duas colunas da expressão declarada no modelo
    assert balances["quantity_available"] == [
        "raw_legacy.inventory_balances.quantity_on_hand", "raw_legacy.inventory_balances.quantity_reserved",
    ]
    movements = dict(ponte.origens("inventory_movements"))
    assert movements["arrived_by_stream"] == []      # constante: o legado não tem caminho quente
    assert movements["event_sequence"] == ["raw_legacy.inventory_movements.legacy_row_id"]


def test_a_declaracao_das_pontes_esta_em_dia() -> None:
    gerada = RAIZ / "dbt/models/trusted/legacy/_pontes__models.yml"
    assert gerada.read_text(encoding="utf-8") == ponte.models_yml(), "regenere com make legacy-models"


# ── A medição sobre o manifest ────────────────────────────────────────────────


@pytest.fixture(scope="module")
def derivacao() -> tuple[sensitivity.Derivation, dict]:
    """A leitura do SQL compilado, feita uma vez: é o que custa (~20 s)."""
    if not l.MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    manifest = json.loads(l.MANIFEST.read_text(encoding="utf-8"))
    if not any(no.get("compiled_code") for no in manifest["nodes"].values()):
        pytest.skip("manifest sem SQL compilado; rode `make dbt-build`")
    return sensitivity.derive(manifest), manifest


@pytest.fixture(scope="module")
def linhagem(derivacao) -> tuple[l.Lineage, dict]:
    derivado, manifest = derivacao
    return l.build(manifest, derivado), manifest


def test_toda_coluna_de_todo_modelo_fecha_numa_origem(linhagem, record_property) -> None:
    lin, _ = linhagem
    assert lin.problems == [], "\n".join(lin.problems[:10])
    sem_origem = [f"{s}.{r}.{c}" for (s, r), cols in lin.leaves.items() for c in cols if not lin.origins(s, r, c)]
    assert sem_origem == []
    totais = l.summary(lin)
    total = sum(c["colunas"] for c in totais.values())
    record_property("columns", total)
    record_property("relations", len(lin.leaves))
    assert set(totais) == set(l.LAYERS)
    assert total == sum(len(cols) for cols in lin.leaves.values())


def test_o_consumo_aponta_para_as_colunas_que_o_sql_usa(linhagem) -> None:
    """Conferido contra o código: a receita líquida por categoria vem dos itens de pedido — retail e legado —,
    e o custo, do livro de movimentos pelos dois caminhos de ingestão mais o legado."""
    lin, _ = linhagem
    receita = lin.origins("consumption", "gross_margin_by_category", "net_revenue_amount")
    assert receita == {
        (camada, "order_items", coluna)
        for camada in ("raw", "raw_legacy") for coluna in ("discount_amount", "quantity", "unit_price")
    }
    custo = lin.origins("consumption", "gross_margin_by_category", "cost_of_goods_sold")
    assert custo == {
        (camada, tabela, coluna)
        for camada, tabela in (("raw", "inventory_movements"), ("raw", "inventory_movements_stream"), ("raw_legacy", "inventory_movements"))
        for coluna in ("quantity_delta", "unit_cost")
    }
    assert lin.origins("consumption", "gross_margin_by_category", "year_month") == {("analytics", "dim_date", "year_month")}


def _maior_conjunto_de_origens(lin: l.Lineage, schema: str) -> tuple[int, str]:
    return max((len(lin.origins(s, r, c)), f"{r}.{c}") for (s, r), cols in lin.leaves.items() if s == schema for c in cols)


def test_nenhuma_coluna_de_consumo_aponta_para_o_payload_inteiro_do_legado(linhagem, derivacao, record_property) -> None:
    """A declaração da ponte é o que fecha o legado — e a contraprova está embutida: sem ela, a mesma
    leitura faz uma coluna de consumo apontar para as centenas de colunas do payload das 40 tabelas."""
    lin, manifest = linhagem
    com = _maior_conjunto_de_origens(lin, "consumption")
    record_property("max_origins", com[0])
    assert com[0] <= 20, com
    sem = _maior_conjunto_de_origens(l.build(manifest, derivacao[0], declared=False), "consumption")
    assert sem[0] >= 400, sem


def test_a_secao_3_do_dicionario_esta_em_dia(linhagem) -> None:
    lin, manifest = linhagem
    texto = l.DICIONARIO.read_text(encoding="utf-8")
    assert l._section(texto) == l.render(lin, manifest), "regenere com make catalog"
