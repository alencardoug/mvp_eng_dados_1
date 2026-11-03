"""T1 e T2 da regeneração da v1.1.0 — o que se prova sem banco.

A leitura dos bancos (`read_oltp`, `read_legacy`) roda no banco efêmero de
`make test-carga` (`test_carga.py`); aqui ficam a medida em memória, a
comparação de duas medidas, o encadeamento do diário do legado e o veredito do
oráculo sobre leituras dadas.
"""

from __future__ import annotations

import copy

import pytest

from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.writer import ORDEM
from mvp_ed1.recovery import sources


def _medida(**mudancas) -> dict:
    """Uma medida mínima da T1, com duas tabelas por origem."""
    base = {
        "format": sources.FORMAT,
        "kind": "generation",
        "digest_format": sources.oraculos.FORMATO,
        "provenance": {"commit": "abc", "trees": {}, "uncommitted": [], "measured_at": "x"},
        "oltp": {
            "parameters": {"seed": 1, "as_of": "2026-09-01", "scale": "dev"},
            "tables": {
                "brands": {"rows": 2, "digest": "d1"},
                sources.LEDGER: {"rows": 10, "digest": "d2"},
                sources.BALANCES: {"rows": 3, "digest": "d3"},
            },
        },
        "legacy": {
            "parameters": {"semente": 2, "fator": 0.05, "versao_catalogo": 9},
            "batch_hash": "lote",
            "tables": {"campaigns": {"linhas": 9, "hash": "h1"}, "customers": {"linhas": 75, "hash": "h2"}},
            "keys": {
                "customers": {"column": "id", "type": "bigint", "keys": {"1": 1, "2": 1}, "without_identity": 0},
            },
        },
    }
    for caminho, valor in mudancas.items():
        alvo = base
        *pais, folha = caminho.split("__")
        for pai in pais:
            alvo = alvo[pai]
        alvo[folha] = valor
    return base


# ── T1: a medida em memória ──────────────────────────────────────────────────
def test_a_medida_usa_os_parametros_do_seed_data_e_mede_o_conjunto_gerado(dados) -> None:
    medida = sources.measure()
    assert medida["oltp"]["parameters"] == {"seed": 20260904, "as_of": "2026-09-01", "scale": "dev"}
    assert medida["oltp"]["tables"] == sources.oltp_tables(dados)
    assert {t: r["rows"] for t, r in medida["oltp"]["tables"].items()} == {
        t: len(dados[t]) for t in ORDEM
    }
    assert set(medida["legacy"]["tables"]) == set(medida["legacy"]["keys"])
    assert medida["legacy"]["parameters"]["versao_catalogo"] >= 1


def test_o_digest_ve_a_celula_gravada_e_ignora_o_campo_auxiliar(dados) -> None:
    colunas = Motor.colunas_gravaveis("brands")
    original = sources.table_digest(dados["brands"], colunas)

    auxiliar = copy.deepcopy(dados["brands"])
    auxiliar[0]["__qualquer"] = "muda a forma, não o resultado"
    assert sources.table_digest(auxiliar, colunas) == original

    gravada = copy.deepcopy(dados["brands"])
    gravada[0]["name"] = gravada[0]["name"] + "!"
    assert sources.table_digest(gravada, colunas)["digest"] != original["digest"]
    assert sources.table_digest(gravada, colunas)["rows"] == original["rows"]


def test_a_chave_do_legado_e_a_canonica_com_multiplicidade() -> None:
    chaves = sources.legacy_keys({"customers": [{"id": "08"}, {"id": "8"}, {"id": "0x9"}, {"id": ""}, {"id": "abc"}, {"id": None}]})
    assert chaves["customers"]["column"] == "id"
    assert chaves["customers"]["keys"] == {"8": 2, "9": 1}
    assert chaves["customers"]["without_identity"] == 3
    assert chaves["campaigns"]["keys"] == {} and chaves["campaigns"]["without_identity"] == 0


def test_as_transicoes_de_chave_sao_as_classes_do_intervalo() -> None:
    transicoes = sources.key_transitions({"1": 1, "2": 2, "3": 1, "4": 1}, {"2": 1, "3": 2, "4": 1, "5": 1})
    assert transicoes == {
        "removed": ["1"], "added": ["5"], "reduced": ["2"], "increased": ["3"], "kept": ["4"]
    }


# ── T1: duas medidas comparadas ──────────────────────────────────────────────
def test_comparar_mostra_as_tabelas_que_mudam_e_as_chaves() -> None:
    antes = _medida()
    depois = _medida(
        oltp__tables={**antes["oltp"]["tables"], "brands": {"rows": 2, "digest": "outro"}},
        legacy__batch_hash="lote2",
        legacy__keys={"customers": {"column": "id", "type": "bigint", "keys": {"2": 1, "3": 1}, "without_identity": 1}},
    )
    relatorio = sources.compare(antes, depois)
    assert list(relatorio["oltp"]["changed"]) == ["brands"]
    assert relatorio["oltp"]["changed"]["brands"]["before"] == {"rows": 2, "digest": "d1"}
    assert relatorio["legacy"]["changed"] == {}
    assert relatorio["legacy"]["tables_with_key_changes"] == ["customers"]
    clientes = relatorio["legacy"]["keys"]["customers"]
    assert clientes["changed"] == {"removed": ["1"], "added": ["3"]}
    assert clientes["without_identity"] == {"before": 0, "after": 1}


def test_comparar_duas_medidas_iguais_nao_aponta_nada() -> None:
    relatorio = sources.compare(_medida(), _medida())
    assert relatorio["oltp"]["changed"] == {} and relatorio["legacy"]["changed"] == {}
    assert relatorio["legacy"]["tables_with_key_changes"] == []


@pytest.mark.parametrize(
    "mudanca",
    [
        {"oltp__parameters": {"seed": 2, "as_of": "2026-09-01", "scale": "dev"}},
        {"legacy__parameters": {"semente": 3, "fator": 0.05, "versao_catalogo": 9}},
        {"digest_format": 1},
        {"kind": "oracle"},
    ],
)
def test_comparar_recusa_medidas_que_nao_sao_da_mesma_geracao(mudanca) -> None:
    with pytest.raises(sources.Refused):
        sources.compare(_medida(), _medida(**mudanca))


def test_a_versao_do_catalogo_e_informacao_e_nao_recusa() -> None:
    depois = _medida(legacy__parameters={"semente": 2, "fator": 0.05, "versao_catalogo": 10})
    assert sources.compare(_medida(), depois)["catalog_version"] == {"before": 9, "after": 10}


# ── T2: o esperado do legado ─────────────────────────────────────────────────
def _manifesto(*mutacoes, lote: str = "lote") -> dict:
    return {"lote": {"hash": lote}, "mutacoes": list(mutacoes)}


def test_o_esperado_do_legado_aplica_o_diario_em_ordem() -> None:
    lote = _medida()["legacy"]
    manifesto = _manifesto(
        {"tipo": "alterar", "tabela": "campaigns", "hash_antes": {"linhas": 9, "hash": "h1"}, "hash_depois": {"linhas": 9, "hash": "h1b"}},
        {"tipo": "remover", "tabela": "campaigns", "hash_antes": {"linhas": 9, "hash": "h1b"}, "hash_depois": {"linhas": 8, "hash": "h1c"}},
    )
    esperado, problemas = sources.expected_legacy(lote, manifesto)
    assert problemas == []
    assert esperado["campaigns"] == {"linhas": 8, "hash": "h1c"}
    assert esperado["customers"] == {"linhas": 75, "hash": "h2"}


def test_um_diario_que_nao_encadeia_e_problema() -> None:
    manifesto = _manifesto(
        {"tipo": "remover", "tabela": "customers", "hash_antes": {"linhas": 75, "hash": "outro"}, "hash_depois": {"linhas": 72, "hash": "h2b"}},
    )
    _, problemas = sources.expected_legacy(_medida()["legacy"], manifesto)
    assert len(problemas) == 1 and "não encadeia" in problemas[0]


def test_um_manifesto_de_outro_lote_e_problema() -> None:
    _, problemas = sources.expected_legacy(_medida()["legacy"], _manifesto(lote="outro"))
    assert len(problemas) == 1 and "descreve o lote outro" in problemas[0]


# ── T2: o veredito sobre leituras dadas ──────────────────────────────────────
def _oraculo(monkeypatch, medida, *, oltp=None, gerado=None, legado=None, calibracao=None):
    lido_oltp = oltp if oltp is not None else copy.deepcopy(medida["oltp"]["tables"])
    lido_legado = legado if legado is not None else copy.deepcopy(medida["legacy"]["tables"])
    leituras = {}

    def ler_oltp(engine, *, ledger_up_to=None):
        leituras["ledger_up_to"] = ledger_up_to
        return {"tables": lido_oltp, "generated": gerado or {}}

    monkeypatch.setattr(sources, "read_oltp", ler_oltp)
    monkeypatch.setattr(sources, "read_legacy", lambda engine: lido_legado)
    relatorio = sources.oracle(
        medida, source=None, legacy=None, legacy_manifest=_manifesto(), calibration_up_to=calibracao
    )
    return relatorio, leituras


def test_o_oraculo_aprova_o_conteudo_igual(monkeypatch) -> None:
    relatorio, leituras = _oraculo(monkeypatch, _medida())
    assert relatorio["ok"] and relatorio["different"] == [] and relatorio["problems"] == []
    assert leituras["ledger_up_to"] is None


def test_o_oraculo_acusa_conteudo_diferente_com_a_mesma_contagem(monkeypatch) -> None:
    medida = _medida()
    lido = copy.deepcopy(medida["oltp"]["tables"])
    lido["brands"] = {"rows": 2, "digest": "outro"}
    relatorio, _ = _oraculo(monkeypatch, medida, oltp=lido)
    assert not relatorio["ok"] and relatorio["different"] == ["oltp.brands"]


def test_o_oraculo_acusa_o_legado_diferente(monkeypatch) -> None:
    medida = _medida()
    lido = copy.deepcopy(medida["legacy"]["tables"])
    lido["customers"] = {"linhas": 72, "hash": "h2b"}
    relatorio, _ = _oraculo(monkeypatch, medida, legado=lido)
    assert relatorio["different"] == ["legacy.customers"]


def test_o_oraculo_acusa_coluna_gerada_fora_da_regra(monkeypatch) -> None:
    gerado = {sources.LEDGER: {sources.LEDGER_SEQUENCE: {"ok": False, "rows": 10, "max": 11}}}
    relatorio, _ = _oraculo(monkeypatch, _medida(), gerado=gerado)
    assert not relatorio["ok"] and sources.LEDGER_SEQUENCE in relatorio["problems"][0]


def test_a_calibracao_exclui_o_saldo_e_corta_o_livro(monkeypatch) -> None:
    medida = _medida()
    lido = copy.deepcopy(medida["oltp"]["tables"])
    lido[sources.BALANCES] = {"rows": 11, "digest": "o produtor moveu"}
    gerado = {sources.BALANCES: {"quantity_available": {"ok": False}}}
    relatorio, leituras = _oraculo(monkeypatch, medida, oltp=lido, gerado=gerado, calibracao=10)
    assert relatorio["ok"], relatorio["problems"]
    assert leituras["ledger_up_to"] == 10
    assert relatorio["oltp"]["tables"][sources.BALANCES]["status"] == "excluded"


def test_a_calibracao_exige_que_a_t1_gere_o_livro_do_corte(monkeypatch) -> None:
    relatorio, _ = _oraculo(monkeypatch, _medida(), calibracao=13_700)
    assert not relatorio["ok"] and "13700" in relatorio["problems"][0]


def test_sem_calibracao_o_saldo_e_julgado(monkeypatch) -> None:
    medida = _medida()
    lido = copy.deepcopy(medida["oltp"]["tables"])
    lido[sources.BALANCES] = {"rows": 11, "digest": "outro"}
    relatorio, _ = _oraculo(monkeypatch, medida, oltp=lido)
    assert relatorio["different"] == [f"oltp.{sources.BALANCES}"]


def test_o_oraculo_recusa_o_que_nao_e_medida_da_t1(monkeypatch) -> None:
    with pytest.raises(sources.Refused):
        _oraculo(monkeypatch, _medida(kind="comparison"))
