"""O que a prova do caminho quente cobra do alerta: conteúdo, e não só existência (RV13J-3-03)."""

from __future__ import annotations

import pytest

from mvp_ed1.gcp import prova_quente

LINHAS = ["m1", "m2", "m3", "semente", "tarde"]


def _abertura(**troca):
    alerta = {"motivo": "abertura", "warehouse_id": 1, "product_variant_id": 2, "limiar": 25,
              "quantity_before": 29, "quantity_on_hand": 23}
    alerta.update(troca)
    return alerta


#: As travessias que o `AcumularSaldoEAlertar` real produz em todas as ordens e partições de painel
#: dos quatro movimentos (enumeração da rodada 4 da revisão, RV13J-4-02: 3.600 ordens conferidas).
POSSIVEIS = [(25, 23), (26, 24), (27, 23), (28, 24), (29, 23), (30, 24)]


def test_as_travessias_aceitas_sao_exatamente_as_possiveis():
    assert sorted(prova_quente.TRAVESSIAS) == POSSIVEIS


@pytest.mark.parametrize("antes, depois", POSSIVEIS)
def test_as_travessias_que_a_ordem_dos_paineis_permite_passam(antes, depois):
    assert prova_quente.conferir(LINHAS, 23, [_abertura(quantity_before=antes, quantity_on_hand=depois)]) == []


@pytest.mark.parametrize("antes, depois", [(25, 24), (26, 23), (27, 24), (28, 23), (29, 24), (30, 23)])
def test_as_travessias_impossiveis_reprovam(antes, depois):
    assert prova_quente.conferir(LINHAS, 23, [_abertura(quantity_before=antes, quantity_on_hand=depois)])


@pytest.mark.parametrize("alerta", [
    {"motivo": "abertura"},
    _abertura(quantity_before=999, quantity_on_hand=-999),
    _abertura(warehouse_id=999),
    _abertura(product_variant_id=999),
    _abertura(limiar=10),
    _abertura(quantity_before=24, quantity_on_hand=23),
    _abertura(motivo="normalizacao"),
])
def test_abertura_com_conteudo_errado_reprova(alerta):
    assert prova_quente.conferir(LINHAS, 23, [alerta])


def test_duas_aberturas_ou_nenhuma_reprovam():
    assert prova_quente.conferir(LINHAS, 23, [])
    assert prova_quente.conferir(LINHAS, 23, [_abertura(), _abertura()])
    assert prova_quente.conferir(LINHAS, 22, [_abertura()])
    assert prova_quente.conferir(LINHAS[:-1], 23, [_abertura()])
