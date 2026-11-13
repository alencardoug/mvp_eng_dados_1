"""A atribuição da diferença de paridade, tabela a tabela e por origem (G8; PLANO_etapa_13 §11.4)."""

from __future__ import annotations

import datetime as dt
import decimal

import pytest

from mvp_ed1.gcp import atribuicao


def _venda(chave, origem="retail", valor="10.50", quando=dt.datetime(2026, 9, 1, 12, tzinfo=dt.timezone.utc)):
    return {"order_item_key": chave, "source_system": origem, "net_amount": decimal.Decimal(valor),
            "placed_at": quando, "_loaded_at": dt.datetime.now(dt.timezone.utc)}


def test_mesma_linha_com_grafias_diferentes_e_igual():
    local = [_venda("a"), _venda("b", "legacy")]
    nuvem = [_venda("a", valor="10.5000"), _venda("b", "legacy",
             quando=dt.datetime(2026, 9, 1, 9, tzinfo=dt.timezone(dt.timedelta(hours=-3))))]
    r = atribuicao.comparar_tabela(local, nuvem)
    assert r["chave"] == "order_item_key" and r["colunas_excluidas"] == ["_loaded_at"]
    assert r["grupos"]["retail"]["iguais"] == 1 and r["grupos"]["legacy"]["iguais"] == 1
    assert all(g["diferentes"] == 0 and g["so_local"] == 0 and g["so_nuvem"] == 0 for g in r["grupos"].values())


def test_separa_por_origem_o_que_falta_e_o_que_diverge():
    local = [_venda("a"), _venda("b"), _venda("x", "legacy"), _venda("y", "legacy")]
    nuvem = [_venda("a"), _venda("b", valor="11"), _venda("c"), _venda("x", "legacy")]
    g = atribuicao.comparar_tabela(local, nuvem)["grupos"]
    assert (g["retail"]["iguais"], g["retail"]["diferentes"], g["retail"]["so_nuvem"]) == (1, 1, 1)
    assert g["retail"]["colunas_que_divergem"] == {"net_amount": 1}
    assert g["retail"]["exemplos_diferentes"] == [{"chave": "b", "net_amount": ["10.5", "11"]}]
    assert (g["legacy"]["iguais"], g["legacy"]["so_local"], g["legacy"]["exemplos_so_local"]) == (1, 1, ["y"])


def test_tabela_sem_source_system_vira_um_grupo_so():
    linha = {"date_key": "20260901", "year": 2026}
    r = atribuicao.comparar_tabela([linha], [dict(linha)])
    assert list(r["grupos"]) == [atribuicao.SEM_ORIGEM] and r["grupos"][atribuicao.SEM_ORIGEM]["iguais"] == 1


def test_coluna_de_um_lado_so_e_declarada_e_nao_comparada():
    local = [{"brand_key": "k", "source_system": "retail", "name": "A", "extra": 1}]
    nuvem = [{"brand_key": "k", "source_system": "retail", "name": "A"}]
    r = atribuicao.comparar_tabela(local, nuvem)
    assert r["colunas_so_local"] == ["extra"] and r["grupos"]["retail"]["iguais"] == 1


def test_recusa_primeira_coluna_que_nao_e_chave_e_chave_repetida():
    with pytest.raises(ValueError, match="não é chave"):
        atribuicao.comparar_tabela([{"name": "a"}], [{"name": "a"}])
    with pytest.raises(ValueError, match="repetida"):
        atribuicao.comparar_tabela([_venda("a"), _venda("a")], [_venda("a")])


def _versao(chave, natural, inicio, origem="retail", nome="A"):
    return {"customer_key": chave, "source_system": origem, "customer_natural_key": natural, "name": nome,
            "valid_from": dt.datetime(2026, 9, inicio, tzinfo=dt.timezone.utc)}


def test_chave_scd_com_hash_diferente_casa_pela_versao():
    # O mesmo cliente em duas versões, com chaves diferentes em cada dialeto: casa pela ordem da versão.
    local = [_versao("l2", 7, 2, nome="B"), _versao("l1", 7, 1)]
    nuvem = [_versao("n1", 7, 1), _versao("n2", 7, 2, nome="B")]
    a, b = atribuicao.identidades_scd("dim_customer", local), atribuicao.identidades_scd("dim_customer", nuvem)
    assert a == {"l1": ("retail", "7", 1), "l2": ("retail", "7", 2)} and b["n2"] == ("retail", "7", 2)
    r = atribuicao.comparar_tabela(atribuicao.resolver(local, {"customer_key": a}),
                                   atribuicao.resolver(nuvem, {"customer_key": b}))
    assert r["grupos"]["retail"]["iguais"] == 2 and r["grupos"]["retail"]["diferentes"] == 0


def test_estrangeira_resolvida_e_chave_desconhecida_aparece():
    mapa_l, mapa_n = {"l1": ("retail", "7", 1)}, {"n1": ("retail", "7", 1)}
    fato_l = [{"order_item_key": "f", "customer_key": "l1"}, {"order_item_key": "g", "customer_key": "perdida"}]
    fato_n = [{"order_item_key": "f", "customer_key": "n1"}, {"order_item_key": "g", "customer_key": "n1"}]
    r = atribuicao.comparar_tabela(atribuicao.resolver(fato_l, {"customer_key": mapa_l}),
                                   atribuicao.resolver(fato_n, {"customer_key": mapa_n}))
    g = r["grupos"][atribuicao.SEM_ORIGEM]
    assert (g["iguais"], g["diferentes"], g["colunas_que_divergem"]) == (1, 1, {"customer_key": 1})


def test_dimensao_sem_versao_nao_e_scd():
    assert atribuicao.identidades_scd("dim_brand", [{"brand_key": "k", "source_system": "retail"}]) is None
