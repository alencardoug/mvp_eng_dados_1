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


def test_o_streamer_consulta_a_assinatura_que_o_dataflow_le():
    """Registro §49: com só o `subscriber`, o Dataflow não lê a configuração da assinatura `beam`
    ("User not authorized") e não faz nenhum *pull*. O `viewer` entra só nela, para o `streamer`."""
    import pathlib
    import re

    tf = (pathlib.Path(__file__).resolve().parent.parent / "terraform" / "armazenamento.tf").read_text(encoding="utf-8")
    bloco = re.search(r'resource "google_pubsub_subscription_iam_member" "consulta" \{(.*?)\n\}', tf, re.S)
    assert bloco, "falta a concessão de leitura da configuração da assinatura"
    corpo = bloco.group(1)
    assert 'toset(["beam"])' in corpo
    assert 'role         = "roles/pubsub.viewer"' in corpo
    assert 'google_service_account.role["streamer"].member' in corpo


def test_o_streamer_cria_a_assinatura_de_watermark_com_o_minimo():
    """Registro §49: com `timestamp_attribute`, o Dataflow cria a assinatura de acompanhamento no
    tópico. O papel próprio tem só as quatro permissões de assinatura — nada de tópico, nada de
    `pubsub.editor` — e o anexo ao tópico vem do `subscriber` nele, tudo no degrau do Dataflow."""
    import pathlib
    import re

    tf = (pathlib.Path(__file__).resolve().parent.parent / "terraform" / "dataflow.tf").read_text(encoding="utf-8")

    def bloco(tipo, nome):
        achado = re.search(rf'resource "{tipo}" "{nome}" \{{(.*?)\n\}}', tf, re.S)
        assert achado, f"falta {tipo}.{nome}"
        return achado.group(1)

    papel = bloco("google_project_iam_custom_role", "rastreio_watermark")
    assert set(re.findall(r'"(pubsub\.[a-z.]+)"', papel)) == {
        "pubsub.subscriptions.create", "pubsub.subscriptions.get",
        "pubsub.subscriptions.consume", "pubsub.subscriptions.delete",
    }
    for corpo in (papel, bloco("google_project_iam_member", "streamer_rastreio_watermark"),
                  bloco("google_pubsub_topic_iam_member", "streamer_anexa_rastreio")):
        assert "count = local.dataflow ? 1 : 0" in corpo
    anexo = bloco("google_pubsub_topic_iam_member", "streamer_anexa_rastreio")
    assert 'google_pubsub_topic.this["eventos"].name' in anexo and '"roles/pubsub.subscriber"' in anexo
    assert "pubsub.editor" not in tf.split("rastreio_watermark", 1)[1].split("google_bigquery_table_iam_member", 1)[0]


def test_o_ingestor_tem_o_post_de_dataset_e_o_airbyte_internal_e_declarado():
    """Registro §49: o destino BigQuery do Airbyte faz `POST` de criação de cada dataset que usa, e
    o `airbyte_internal` nasce no Terraform, só com o ingestor — tudo no degrau das aplicações."""
    import pathlib
    import re

    tf = (pathlib.Path(__file__).resolve().parent.parent / "terraform" / "aplicacoes_gke.tf").read_text(encoding="utf-8")

    def bloco(tipo, nome):
        achado = re.search(rf'resource "{tipo}" "{nome}" \{{(.*?)\n\}}', tf, re.S)
        assert achado, f"falta {tipo}.{nome}"
        return achado.group(1)

    papel = bloco("google_project_iam_custom_role", "criar_dataset")
    assert re.findall(r'"(bigquery\.[a-z.]+)"', papel) == ["bigquery.datasets.create"]
    assert 'google_service_account.role["ingestor"].member' in bloco("google_project_iam_member", "ingestor_criar_dataset")
    dataset = bloco("google_bigquery_dataset", "airbyte_internal")
    assert 'dataset_id                 = "airbyte_internal"' in dataset
    # RVT-1-03: a lista é autoritativa e tem exatamente duas entradas — os donos e o ingestor.
    entradas = re.findall(r"access \{(.*?)\n  \}", dataset, re.S)
    assert len(entradas) == 2
    assert 'role          = "OWNER"' in entradas[0] and 'special_group = "projectOwners"' in entradas[0]
    assert 'role          = "WRITER"' in entradas[1] and 'google_service_account.role["ingestor"].email' in entradas[1]
    codigo = "\n".join(linha for linha in dataset.splitlines() if not linha.strip().startswith("#"))
    assert "projectReaders" not in codigo and "projectWriters" not in codigo
    assert 'resource "google_bigquery_dataset_access" "airbyte_internal"' not in tf
    assert re.search(r"removed \{\n  from = google_bigquery_dataset_access\.airbyte_internal\n\n  lifecycle \{\n    destroy = false", tf)
    for nome in ("criar_dataset", "ingestor_criar_dataset", "airbyte_internal"):
        assert re.search(rf'"{nome}" \{{\n  count = local\.aplicacoes \? 1 : 0', tf)
