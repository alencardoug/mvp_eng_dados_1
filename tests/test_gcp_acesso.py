"""O acesso por dataset do BigQuery é derivado da declaração do dbt (Etapa 13, G3)."""

from __future__ import annotations

import json

import pytest

from mvp_ed1.gcp import acesso


def _manifest(nodes=(), sources=()) -> dict:
    return {
        "nodes": {f"n{i}": n for i, n in enumerate(nodes)},
        "sources": {f"s{i}": s for i, s in enumerate(sources)},
    }


def _no(schema, writers=None, tipo="model"):
    return {"resource_type": tipo, "schema": schema, "config": {"meta": {"writers": writers} if writers else {}}}


def _fonte(schema, nome, writers=(), select=(), proprio=None):
    meta = {"writers": list(writers), "grants": {"select": list(select)}}
    return {"schema": schema, "name": nome, "source_meta": meta, "meta": proprio if proprio is not None else meta}


def test_escritor_ganha_edicao_e_leitor_da_fonte_ganha_leitura():
    d = acesso.derivar(_manifest(
        nodes=[_no("staging", ["transformer"]), _no("staging", ["transformer"], "snapshot"), _no("x", tipo="test")],
        sources=[_fonte("raw", "a", ["ingestor"], ["transformer"]), _fonte("raw", "b", ["ingestor"], ["transformer"])],
    ))
    assert d["acesso_por_dataset"] == [
        {"dataset": "raw", "role": acesso.ESCRITA, "papel": "ingestor"},
        {"dataset": "staging", "role": acesso.ESCRITA, "papel": "transformer"},
        {"dataset": "raw", "role": acesso.LEITURA, "papel": "transformer"},
    ]
    assert d["pendentes_por_tabela"] == []


def test_quem_escreve_nao_ganha_leitura_repetida():
    d = acesso.derivar(_manifest(sources=[_fonte("governance", "c", ["ingestor"], ["ingestor", "auditor"])]))
    assert [(a["role"], a["papel"]) for a in d["acesso_por_dataset"]] == [
        (acesso.ESCRITA, "ingestor"), (acesso.LEITURA, "auditor")]


def test_concessao_que_substitui_a_da_fonte_fica_registrada_como_pendente():
    proprio = {"grants": {"select": ["streamer", "transformer"], "insert": ["streamer"]}}
    d = acesso.derivar(_manifest(sources=[_fonte("raw", "stream", ["ingestor"], ["transformer"], proprio)]))
    assert d["pendentes_por_tabela"] == [
        {"tabela": "raw.stream", "grants": {"insert": ["streamer"], "select": ["streamer", "transformer"]}}]


def test_privilegio_de_fonte_sem_traducao_e_recusado():
    fonte = _fonte("raw", "a", ["ingestor"])
    fonte["source_meta"]["grants"] = {"insert": ["ingestor"]}
    with pytest.raises(ValueError, match="sem tradução"):
        acesso.derivar(_manifest(sources=[fonte]))


def test_o_arquivo_do_terraform_e_o_que_a_declaracao_da():
    """Erro no derivado se corrige na declaração (CLAUDE.md §5): o arquivo versionado tem de ser
    exatamente o que o manifest atual dá."""
    if not acesso.MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    esperado = acesso.derivar(json.loads(acesso.MANIFEST.read_text(encoding="utf-8")))
    assert json.loads(acesso.SAIDA.read_text(encoding="utf-8")) == esperado
