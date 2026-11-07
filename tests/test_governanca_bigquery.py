"""O DDL do `governance` no BigQuery declara o mesmo certificado do PostgreSQL (Etapa 13, G2.1)."""

from __future__ import annotations

import os
import uuid

import pytest
import sqlglot
from sqlglot import exp

from mvp_ed1 import governance

#: O tipo do PostgreSQL e o do BigQuery que guardam o mesmo valor. `integer` vira INT64: o BigQuery
#: só tem um inteiro, e o certificado nunca conta mais que o `integer` local aceita.
EQUIVALENTE = {"TEXT": "TEXT", "BIGINT": "BIGINT", "INT": "BIGINT", "BOOLEAN": "BOOLEAN",
               "TIMESTAMPTZ": "TIMESTAMPTZ"}


def _colunas(sql: str, dialeto: str) -> dict[str, tuple[str, bool]]:
    tabela = sqlglot.parse_one(sql, read=dialeto)
    saida = {}
    for coluna in tabela.find_all(exp.ColumnDef):
        tipo = coluna.args["kind"].this.name
        nao_nulo = any(isinstance(c.kind, exp.NotNullColumnConstraint) for c in coluna.constraints)
        saida[coluna.name] = (EQUIVALENTE.get(tipo, tipo) if dialeto == "postgres" else tipo, nao_nulo)
    return saida


def _create(migracoes) -> str:
    return next(c for c in dict(migracoes)["0001_legacy_captures"] if "create table" in c)


def test_as_migracoes_tem_os_mesmos_nomes_na_mesma_ordem():
    assert [n for n, _ in governance.MIGRACOES] == [n for n, _ in governance.MIGRACOES_BIGQUERY]


def test_o_certificado_tem_as_mesmas_colunas_tipos_e_nulidade():
    local = _colunas(_create(governance.MIGRACOES), "postgres")
    nuvem = _colunas(_create(governance.MIGRACOES_BIGQUERY).format(projeto="p", dataset="governance"), "bigquery")
    assert list(local) == list(nuvem) and local == nuvem


def test_o_que_o_bigquery_nao_impoe_vira_teste_da_fonte():
    """`check` e `primary key` não são impostos no BigQuery; a regra mora nos testes da fonte, que
    rodam nos dois alvos."""
    import yaml

    from mvp_ed1.recovery.ledger import CERTIFICATE  # "governance.legacy_captures"

    fontes = yaml.safe_load(open("dbt/models/staging/legacy/_legacy__sources.yml", encoding="utf-8"))
    fonte = next(f for f in fontes["sources"] if f["schema"] == "governance")
    tabela = next(t for t in fonte["tables"] if f"{fonte['schema']}.{t['name']}" == CERTIFICATE)
    status = next(c for c in tabela["columns"] if c["name"] == "status")
    valores = next(t["accepted_values"]["values"] for t in status["data_tests"] if "accepted_values" in t)
    pg = _create(governance.MIGRACOES)
    assert sorted(valores) == sorted(v.strip(" '") for v in pg.split("status in (")[1].split(")")[0].split(","))
    unicidade = next(t["dbt_utils.unique_combination_of_columns"]["arguments"]["combination_of_columns"]
                     for t in tabela["data_tests"] if "dbt_utils.unique_combination_of_columns" in t)
    assert unicidade == ["capture_attempt_id", "source_table"]


@pytest.mark.skipif(os.environ.get("GCP_TESTES") != "1", reason="só com GCP_TESTES=1 (BigQuery real)")
def test_no_bigquery_de_verdade_as_migracoes_aplicam_do_zero_e_nao_repetem():
    from google.cloud import bigquery

    projeto = os.environ["GCP_PROJECT_ID"]
    cliente = bigquery.Client(project=projeto)
    dataset = f"governance_teste_{uuid.uuid4().hex[:8]}"
    novo = bigquery.Dataset(f"{projeto}.{dataset}")
    novo.location = os.environ["GCP_BQ_LOCATION"]
    cliente.create_dataset(novo, exists_ok=False)
    try:
        assert governance.garantir_bigquery(cliente, projeto, dataset) == [n for n, _ in governance.MIGRACOES_BIGQUERY]
        assert governance.garantir_bigquery(cliente, projeto, dataset) == []
        tabela = cliente.get_table(f"{projeto}.{dataset}.legacy_captures")
        assert tabela.clustering_fields == ["snapshot_id", "status"]
        assert [c.name for c in tabela.schema] == list(_colunas(_create(governance.MIGRACOES), "postgres"))
    finally:
        cliente.delete_dataset(f"{projeto}.{dataset}", delete_contents=True, not_found_ok=True)
