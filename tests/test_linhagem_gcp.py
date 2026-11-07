"""A linhagem no GCP: as travessias publicadas e a régua da paridade (Etapa 13, G5; D80)."""

from __future__ import annotations

import json
import pathlib
import uuid

import yaml

from mvp_ed1.gcp import linhagem

BANCOS = {"retail": "origem", "legacy": "legado"}


def _travessias():
    return linhagem.travessias("p", "us-central1", BANCOS)


def test_uma_travessia_por_tabela_e_os_dois_trechos_do_caminho_quente():
    streams = yaml.safe_load(pathlib.Path("airbyte/streams.yml").read_text(encoding="utf-8"))["origens"]
    jobs = [t["job"] for t in _travessias()]
    retail, legacy = len(streams["retail"]["tabelas"]), len(streams["legacy"]["tabelas"])
    assert len(jobs) == retail + legacy + 3 and len(set(jobs)) == len(jobs)
    assert {"captura.certificado", "debezium-server.inventory_movements", "beam.caminho_quente"} <= set(jobs)


def test_os_nomes_seguem_os_fqn_da_data_lineage_api():
    por_job = {t["job"]: t for t in _travessias()}
    debezium, beam = por_job["debezium-server.inventory_movements"], por_job["beam.caminho_quente"]
    assert debezium["entradas"] == ["cloudsql_postgresql:p.us-central1.mvp-ed1-origens.origem.oltp.inventory_movements"]
    assert debezium["saidas"] == beam["entradas"] == ["pubsub:topic:p.mvp.oltp.inventory_movements"]
    assert beam["saidas"] == ["bigquery:p.raw.inventory_movements_stream"]
    assert len(por_job["captura.certificado"]["entradas"]) == 40


def test_o_evento_e_idempotente_e_o_pubsub_vai_no_formato_do_openlineage():
    travessia = next(t for t in _travessias() if t["job"] == "beam.caminho_quente")
    import datetime as dt

    a = linhagem.evento(travessia, dt.datetime(2026, 11, 7, tzinfo=dt.timezone.utc))
    b = linhagem.evento(travessia, dt.datetime(2026, 11, 8, tzinfo=dt.timezone.utc))
    assert a["run"]["runId"] == b["run"]["runId"] and uuid.UUID(a["run"]["runId"]).version == 5
    assert a["job"] == {"namespace": "mvp-ed1", "name": "beam.caminho_quente"}
    assert a["inputs"] == [{"namespace": "pubsub", "name": "topic:p:mvp.oltp.inventory_movements"}]
    assert a["outputs"] == [{"namespace": "bigquery", "name": "p.raw.inventory_movements_stream"}]


def test_a_regua_da_paridade_e_o_sql_e_nao_a_declaracao():
    manifest = json.loads(pathlib.Path("dbt/target/manifest.json").read_text(encoding="utf-8"))
    arestas = linhagem.arestas_do_modulo(manifest)
    assert arestas and all(folhas for folhas in arestas.values())
    # Nenhuma coluna de fonte é alvo: a paridade compara o que o dbt materializa.
    assert not {a for a in arestas if a[0] in ("raw", "raw_legacy", "governance")}
