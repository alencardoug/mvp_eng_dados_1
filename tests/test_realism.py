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
