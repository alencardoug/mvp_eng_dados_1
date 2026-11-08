"""As duas capturas da janela: as mutações declaradas e a matriz do diário no BigQuery (§7.2; ADR-0045)."""

from __future__ import annotations

import json
import pathlib

import pytest

from mvp_ed1.gcp import mutacoes_janela
from mvp_ed1.legacy import armazem as dialeto
from mvp_ed1.legacy import diario, mutacoes, schema

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MAKEFILE = (RAIZ / "Makefile").read_text(encoding="utf-8")


def test_a_declaracao_cobre_remocao_insercao_e_alteracao_em_tabelas_do_legado():
    itens = mutacoes_janela.declaradas()
    assert {op for op, _ in itens} == set(mutacoes_janela.OPERACOES)
    for operacao, argumentos in itens:
        assert argumentos["tabela"] in schema.tabelas()
        if operacao == "remover":
            assert argumentos.get("quantidade"), "a escolha é do oráculo, entre as aptas"
        if operacao == "inserir":
            assert set(argumentos["valores"]) <= set(schema.colunas(argumentos["tabela"]))


def _manifesto(tmp_path, diario_atual):
    caminho = tmp_path / "manifesto.json"
    caminho.write_text(json.dumps({"mutacoes": diario_atual}), encoding="utf-8")
    return caminho


def test_aplicar_duas_vezes_e_recusado(tmp_path):
    with pytest.raises(RuntimeError, match="já foram aplicadas"):
        mutacoes_janela.aplicar(None, _manifesto(tmp_path, [{"tipo": "remover"}]), mutacoes_janela.declaradas())


def test_cada_mutacao_vai_para_o_manifesto_dado(tmp_path, monkeypatch):
    manifesto = _manifesto(tmp_path, [])
    chamadas = []
    registro = {"hash_antes": {"hash": "a" * 12}, "hash_depois": {"hash": "b" * 12}}
    for nome in mutacoes_janela.OPERACOES:
        monkeypatch.setattr(mutacoes, nome, lambda *a, _n=nome, **k: chamadas.append((_n, k["manifesto"])) or registro)
    mutacoes_janela.aplicar(None, manifesto, mutacoes_janela.declaradas())
    assert [n for n, _ in chamadas] == [op for op, _ in mutacoes_janela.declaradas()]
    assert {m for _, m in chamadas} == {manifesto}


def test_a_matriz_le_o_bigquery_pelo_dialeto():
    bq = dialeto.BigQuery(cliente=None, projeto="p", coordenador=None)
    pedidos = []

    def linhas(sql, parametros=None, **_):
        pedidos.append(sql)
        if "legacy_selected_capture" in sql:
            return [{"snapshot_id": 12}]
        if "max(snapshot_id)" in sql:
            return [{"anterior": 10}]
        if "distinct previous_snapshot_id" in sql:
            return [{"previous_snapshot_id": 10, "selected_snapshot_id": 12}]
        if "legacy_capture_transitions" in sql:
            return [{"source_table": "brands", "business_key": "2", "transition": "removida", "rows_after": 0},
                    {"source_table": "brands", "business_key": "9", "transition": "adicionada", "rows_after": 1}]
        return [{"source_table": "brands", "business_key": "2", "last_seen_snapshot_id": 10,
                 "removed_in_snapshot_id": 12}]

    bq.linhas = linhas
    diario_atual = [{"tipo": "remover", "tabela": "brands", "presenca_apos_commit": {"2": 0}},
                    {"tipo": "inserir", "tabela": "brands", "presenca_apos_commit": {"9": 1}}]
    assert diario.veredito(bq, diario_atual) == ("passa",)
    assert all("`p." in sql for sql in pedidos), "todo nome qualificado pelo projeto"


def test_os_alvos_da_quarta():
    def receita(alvo):
        return MAKEFILE.split(f"\n{alvo}:", 1)[1].split("\n\n", 1)[0]

    assert "$(call COMPOSER_RODAR,fluxo_batch," in receita("gcp-composer-fluxo")
    assert "$(call COMPOSER_RODAR,diagnostico_composer," in receita("gcp-composer-smoke")
    assert "$(GCP_LIMPEZA); $(GCP_ORIGENS); .venv/bin/python -m mvp_ed1.gcp.mutacoes_janela" in receita("gcp-legado-mutar")
    matriz = receita("gcp-legado-matriz")
    assert 'LEGACY_WAREHOUSE=bigquery MVP_REGISTROS_DIR="$(GCP_REGISTROS)"' in matriz
    rodar = MAKEFILE.split("\nCOMPOSER_RODAR = ", 1)[1].split("\n\n", 1)[0]
    assert "tasks states-for-dag-run" in rodar and "$(COMPOSER_EVIDENCIA)" in rodar
