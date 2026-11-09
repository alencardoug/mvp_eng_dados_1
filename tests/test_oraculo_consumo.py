"""O conteúdo das views de consumption nos dois alvos, e não só a contagem (§7.2; RV13J-1-09)."""

from __future__ import annotations

import datetime as dt
import decimal

from mvp_ed1.gcp import oraculo


def _linha(canal="web", receita="10.50", taxa=0.333333333):
    return {"channel": canal, "revenue": decimal.Decimal(receita), "rate": taxa,
            "month": dt.date(2026, 9, 1), "_loaded_at": dt.datetime.now(dt.timezone.utc)}


def test_mesmo_conteudo_com_grafias_diferentes_passa():
    local = {"v": [_linha(), _linha("loja", "3")]}
    nuvem = {"v": [_linha("loja", "3.000"), _linha(receita="10.5000", taxa=0.3333333334)]}
    assert oraculo.comparar_views(local, nuvem) == []


def test_mesma_contagem_e_valor_diferente_reprova():
    problemas = oraculo.comparar_views({"v": [_linha(), _linha("loja")]}, {"v": [_linha(), _linha("loja", "10.51")]})
    assert len(problemas) == 1 and "1 linha(s) só no local e 1 só no BigQuery" in problemas[0]


def test_repeticao_conta_no_multiconjunto():
    assert oraculo.comparar_views({"v": [_linha(), _linha("loja")]}, {"v": [_linha(), _linha()]})


def test_view_ou_coluna_de_um_lado_so_reprova():
    assert oraculo.comparar_views({"v": [_linha()], "w": [_linha()]}, {"v": [_linha()]}) == ["w: só no local"]
    sem = {k: v for k, v in _linha().items() if k != "rate"}
    assert "colunas diferentes" in oraculo.comparar_views({"v": [_linha()]}, {"v": [sem]})[0]


def test_as_colunas_de_execucao_saem_declaradas():
    comparadas, excluidas, _ = oraculo.conteudo([_linha()])
    assert excluidas == ["_loaded_at"] and "_loaded_at" not in comparadas


def test_contagem_diferente_so_reprova_fora_da_historia(capsys):
    """D85: a contagem da história de cada ambiente não reprova; a do estado, sim."""
    local = {("raw_legacy", "a"): 9, ("governance", "legacy_captures"): 4, ("snapshots", "c"): 7,
             ("trusted", "legacy_presence_by_capture"): 20, ("trusted", "d"): 3}
    nuvem = {("raw_legacy", "a"): 3, ("governance", "legacy_captures"): 2, ("snapshots", "c"): 1,
             ("trusted", "legacy_presence_by_capture"): 10, ("trusted", "d"): 3}
    assert oraculo.comparar_contagens(local, nuvem) == 0
    assert "4 só na contagem da história (não comparáveis, D85)" in capsys.readouterr().out
    assert oraculo.comparar_contagens(local, {**nuvem, ("trusted", "d"): 2}) == 1


def test_migracoes_e_objeto_de_um_lado_so_reprovam_mesmo_na_historia():
    """RV0811-1-01: `_versions` é estado, e a presença não depende do número de capturas."""
    assert oraculo.comparar_contagens({("governance", "_versions"): 2}, {("governance", "_versions"): 1}) == 1
    assert oraculo.comparar_contagens({("snapshots", "scd_product"): 7}, {}) == 1
    assert oraculo.comparar_contagens({}, {("raw_legacy", "brands"): 3}) == 1
    assert oraculo.comparar_contagens({("staging", "e"): 1}, {}) == 1
