"""The realism fixes of v1.1.0 in the generator, checked in memory.

The category tree (N37 of the bi-como-codigo plan), the price range of each
leaf (N38) and the launch before the first sale (N39). Each answers a
measurement of the plan's §2 — M7, M8 and M9 — redone here on the generated
dataset; stage 1.6 redoes them in the warehouse.
"""

from __future__ import annotations

import pytest

from mvp_ed1.generator.config import ARQUIVO, Config, ConfiguracaoInvalida, carregar, nos_da_arvore
from mvp_ed1.generator.dataset import Dataset


def _broken(tmp_path, old: str, new: str):
    text = ARQUIVO.read_text(encoding="utf-8")
    broken = text.replace(old, new)
    assert broken != text, "the target of the test changed in the YAML"
    path = tmp_path / "broken.yml"
    path.write_text(broken, encoding="utf-8")
    return path


# ── N37: the category tree ───────────────────────────────────────────────────
def test_every_leaf_sits_under_the_root_and_middle_the_tree_declares(config: Config, dados: Dataset) -> None:
    declared = {name: parent for name, _, parent in nos_da_arvore(config.tabelas["product_categories"].arvore)}
    by_id = {row["id"]: row for row in dados["product_categories"]}
    for row in dados["product_categories"]:
        parent = by_id[row["parent_id"]]["name"] if row["parent_id"] else None
        assert parent == declared[row["name"]], row["name"]
        assert row["depth"] == (0 if parent is None else by_id[row["parent_id"]]["depth"] + 1)
    assert {row["name"] for row in dados["product_categories"]} == set(declared)


def test_products_sit_only_on_leaves(dados: Dataset) -> None:
    leaves = {row["id"] for row in dados["product_categories"] if row["depth"] == 2}
    assert {row["category_id"] for row in dados["products"]} <= leaves


def test_the_product_name_starts_with_its_leaf(dados: Dataset) -> None:
    names = {row["id"]: row["name"] for row in dados["product_categories"]}
    assert all(row["name"].startswith(names[row["category_id"]] + " ") for row in dados["products"])


def test_the_category_count_is_the_tree_at_any_scale(config: Config, dados: Dataset, dados_reduzidos: Dataset) -> None:
    size = len(nos_da_arvore(config.tabelas["product_categories"].arvore))
    assert size == 28
    assert len(dados["product_categories"]) == len(dados_reduzidos["product_categories"]) == size
    assert config.linhas("product_categories", 1000.0) == size


def test_a_floor_that_differs_from_the_tree_is_refused(tmp_path) -> None:
    path = _broken(tmp_path, "    min_rows: 28\n", "    min_rows: 24\n")
    with pytest.raises(ConfiguracaoInvalida, match="a contagem é a árvore"):
        carregar(path)


def test_a_repeated_name_in_the_tree_is_refused(tmp_path) -> None:
    path = _broken(tmp_path, "Treino: [Halteres, Tapetes de ioga]", "Treino: [Halteres, Panelas]")
    with pytest.raises(ConfiguracaoInvalida, match="nomes repetidos"):
        carregar(path)


def test_a_middle_without_leaves_is_refused(tmp_path) -> None:
    path = _broken(tmp_path, "Camping: [Barracas, Sacos de dormir]", "Camping: []")
    with pytest.raises(ConfiguracaoInvalida, match="lista de folhas"):
        carregar(path)


# ── N38: the price range of each leaf ────────────────────────────────────────
def _leaf_of_variant(dados: Dataset) -> dict[int, str]:
    category = {row["id"]: row["name"] for row in dados["product_categories"]}
    product = {row["id"]: category[row["category_id"]] for row in dados["products"]}
    return {row["id"]: product[row["product_id"]] for row in dados["product_variants"]}


@pytest.mark.parametrize("dataset_fixture", ["dados", "dados_reduzidos"])
def test_every_price_of_a_leaf_stays_in_its_declared_range(request, config: Config, dataset_fixture) -> None:
    """M8 in memory: the list, channel, readjusted, cart and sale prices — none outside."""
    from mvp_ed1.generator.pricing import within

    data = request.getfixturevalue(dataset_fixture)
    ranges = config.tabelas["product_variants"].processo["faixa_de_preco_por_folha"]
    leaf = _leaf_of_variant(data)
    outside = [
        (table, row["unit_price"], leaf[row["product_variant_id"]])
        for table in ("product_prices", "cart_items", "order_items")
        for row in data[table]
        if not within(row["unit_price"], ranges[leaf[row["product_variant_id"]]])
    ]
    assert outside == []


def test_leaves_with_dearer_ranges_sell_dearer(config: Config, dados: Dataset) -> None:
    """The axis of P01 gains meaning: the leaf medians follow the declared ranges."""
    import statistics

    ranges = config.tabelas["product_variants"].processo["faixa_de_preco_por_folha"]
    leaf = _leaf_of_variant(dados)
    sold: dict[str, list[float]] = {}
    for row in dados["order_items"]:
        sold.setdefault(leaf[row["product_variant_id"]], []).append(float(row["unit_price"]))
    median = {name: statistics.median(prices) for name, prices in sold.items()}
    assert median["Notebooks"] > median["Sofás"] > median["Camisetas"] > median["Organizadores"] * 0.9
    assert median["Notebooks"] > 10 * median["Organizadores"]
    assert set(median) == set(ranges)


def test_the_log_uniform_draw_puts_half_below_the_geometric_middle() -> None:
    import datetime as dt

    from mvp_ed1.generator.rng import Fonte

    fonte = Fonte(1, dt.date(2026, 9, 1), "teste", "pt_BR")
    values = [fonte.log_uniforme(30, 3000, 2) for _ in range(20_000)]
    assert all(30 <= v <= 3000 for v in values)
    below = sum(v < 300 for v in values) / len(values)
    assert 0.48 < below < 0.52  # a uniform draw would put 9% below


def test_the_base_range_keeps_every_derived_price_inside() -> None:
    from mvp_ed1.generator.pricing import base_range, envelope

    low, high = envelope()
    inner = base_range(29.90, 299.90)
    assert inner[0] * low > 29.90 and inner[1] * high < 299.90


def test_a_leaf_without_a_price_range_is_refused(tmp_path) -> None:
    path = _broken(tmp_path, "        Sacos de dormir: [89.90, 1299.00]\n", "")
    with pytest.raises(ConfiguracaoInvalida, match="folhas sem faixa de preço"):
        carregar(path)


def test_a_price_range_for_what_is_not_a_leaf_is_refused(tmp_path) -> None:
    path = _broken(tmp_path, "        Sacos de dormir: [89.90, 1299.00]\n", "        Sacos de dormir: [89.90, 1299.00]\n        Camping: [10.00, 100.00]\n")
    with pytest.raises(ConfiguracaoInvalida, match="não é folha da árvore"):
        carregar(path)


def test_a_range_too_narrow_for_the_multipliers_is_refused(tmp_path) -> None:
    path = _broken(tmp_path, "Camisetas: [29.90, 299.90]", "Camisetas: [29.90, 49.90]")
    with pytest.raises(ConfiguracaoInvalida, match="estreita demais"):
        carregar(path)


# ── H3: the measurement that records M7 to M9 ───────────────────────────────
def test_the_h3_measurement_reports_m7_to_m9_closed(config: Config, dados: Dataset) -> None:
    """What `make generation-realism` writes agrees with the checks above, on the same dataset."""
    from mvp_ed1.recovery.realism import realism

    report = realism(dados, config)
    assert report["m7"]["declared_tree"] and report["m7"]["differing_from_declared"] == []
    assert report["m7"]["leaves_with_products"] == 16
    assert report["m8"]["outside_declared"] == 0
    assert report["m8"]["items"] == report["m9"]["items"] == len(dados["order_items"])
    assert report["m9"]["sold_before_launch"] == 0


def test_the_h3_measurement_reads_a_generator_with_nothing_declared(config: Config, dados: Dataset) -> None:
    """Without tree or ranges — the generator before the fixes — it measures and leaves the divergence blank."""
    import copy

    from mvp_ed1.recovery.realism import realism

    bare = copy.deepcopy(config)
    del bare.tabelas["product_categories"].processo["arvore"]
    del bare.tabelas["product_variants"].processo["faixa_de_preco_por_folha"]
    report = realism(dados, bare)
    assert report["m7"]["differing_from_declared"] is None
    assert report["m8"]["outside_declared"] is None
    assert all(row["declared_range"] is None for row in report["m8"]["per_leaf"].values())
    assert len(report["m7"]["paths"]) == 16
