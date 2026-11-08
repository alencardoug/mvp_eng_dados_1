"""O oráculo da memória lendo o bruto no BigQuery: as consultas do `expected_deletion_rows` (Etapa 13, G2.1).

O caminho do PostgreSQL tem os testes de integração de `test_oraculo_da_memoria.py`; aqui, o do
BigQuery: o SQL montado (sem rede) e, com `GCP_TESTES=1`, as duas consultas contra um *dataset*
temporário de verdade — viagem no tempo, `unnest` de parâmetro e `to_json` do `struct`.
"""

from __future__ import annotations

import os
import uuid

import pytest

from mvp_ed1.legacy import armazem as dialeto
from mvp_ed1.legacy import schema
from mvp_ed1.recovery import memory_oracle as mo

TABELA = "brands"


def _falso():
    bq = dialeto.BigQuery(cliente=None, projeto="p", coordenador=None)
    pedidos = []

    def linhas(sql, parametros=None, **_):
        pedidos.append((sql, parametros))
        if "to_json" in sql:
            return [{"p": '{"id": "1", "name": "a"}'}, {"p": {"id": "1", "name": "b"}}]
        return [{"s": 7, "v": "1"}, {"s": 8, "v": "2"}]

    bq.linhas = linhas
    return bq, pedidos


def test_a_presenca_e_o_payload_no_dialeto_do_bigquery():
    bq, pedidos = _falso()
    assert mo._presenca(bq, TABELA, "id", [7, 8]) == [(7, "1"), (8, "2")]
    assert mo._payload(bq, TABELA, "id", 7, ["1"]) == [{"id": "1", "name": "a"}, {"id": "1", "name": "b"}]
    presenca, payload = pedidos
    assert "`p.raw_legacy.brands`" in presenca[0] and "in unnest(:ids)" in presenca[0]
    assert "cast(json_value(_airbyte_meta, '$.sync_id') as int64)" in presenca[0]
    assert presenca[1] == {"ids": [7, 8]}
    # Todas as colunas declaradas, e só elas, no objeto.
    assert all(f"`{c}` as `{c}`" in payload[0] for c in schema.colunas(TABELA))
    assert "_airbyte" not in payload[0].split(" from ")[0]
    assert payload[1] == {"c": 7, "v": ["1"]}


@pytest.mark.skipif(os.environ.get("GCP_TESTES") != "1", reason="só com GCP_TESTES=1 (BigQuery real)")
def test_no_bigquery_de_verdade_a_presenca_e_o_payload():
    from google.cloud import bigquery

    projeto, local = os.environ["GCP_PROJECT_ID"], os.environ["GCP_BQ_LOCATION"]
    cliente = bigquery.Client(project=projeto, location=local)
    dataset = f"memoria_teste_{uuid.uuid4().hex[:8]}"
    novo = bigquery.Dataset(f"{projeto}.{dataset}")
    novo.location = local
    cliente.create_dataset(novo, exists_ok=False)
    try:
        colunas = schema.colunas(TABELA)
        ddl = ", ".join(f"`{c}` string" for c in colunas)
        cliente.query(f"create table `{projeto}.{dataset}.{TABELA}` ({ddl}, _airbyte_meta json)").result()
        valores = []
        for sync, chave, nome in ((7, "1", "antes"), (7, "2", "fica"), (8, "2", "fica")):
            campos = ", ".join("'" + (chave if c == "id" else nome if c == "name" else "x") + "'" for c in colunas)
            valores.append(f"({campos}, json '{{\"sync_id\": {sync}}}')")
        cliente.query(f"insert into `{projeto}.{dataset}.{TABELA}` values {', '.join(valores)}").result()

        bq = dialeto.BigQuery(cliente, projeto, coordenador=None, local=local,
                              renomear={"raw_legacy": dataset}).no_instante()
        assert sorted(mo._presenca(bq, TABELA, "id", [7, 8])) == [(7, "1"), (7, "2"), (8, "2")]
        assert mo._presenca(bq, TABELA, "id", [8]) == [(8, "2")]
        payload = mo._payload(bq, TABELA, "id", 7, ["1"])
        assert len(payload) == 1 and payload[0]["id"] == "1" and payload[0]["name"] == "antes"
        assert set(payload[0]) == set(colunas)
    finally:
        cliente.delete_dataset(f"{projeto}.{dataset}", delete_contents=True, not_found_ok=True)
