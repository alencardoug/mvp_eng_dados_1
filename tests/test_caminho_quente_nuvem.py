"""O caminho quente na fase GCP (Etapa 13, G2.3): envelope achatado (D78) e a escrita da D75.

A unidade usa um BigQuery simulado para a regra do lote — dedupe dentro do lote,
"o que entrou" relido e conferido com o *job*. A parte real (`GCP_TESTES=1`) roda a
mesma regra no BigQuery de verdade, num *dataset* temporário apagado no fim.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import threading
import uuid
from decimal import Decimal

import pytest

from mvp_ed1.streaming import nuvem
from mvp_ed1.streaming.config import Destino, carregar
from mvp_ed1.streaming.envelope import ContratoViolado, decodificar

DESTINO = Destino(schema="raw", tabela="inventory_movements_stream", lote_de_escrita=500)


def _evento(movement_id: str, **mais) -> dict:
    base = {
        "movement_id": movement_id, "event_sequence": "7", "idempotency_key": f"k-{movement_id}",
        "warehouse_id": 1, "product_variant_id": 2, "movement_type": "sale", "quantity_delta": -3,
        "unit_cost": "10.123456", "source_type": "order", "source_id": "o-1", "correlation_id": None,
        "causation_id": None, "aggregate_version": 1, "occurred_at": "2026-11-07T15:00:00.123456Z",
        "recorded_at": "2026-11-07T15:00:01Z", "schema_version": 1, "metadata": None,
    }
    return {**base, **mais}


# ── Envelope achatado (D78) ──────────────────────────────────────────────────

def test_envelope_achatado_aceita_insercao_com_lsn_e_recusa_alteracao():
    evento = decodificar(json.dumps(_evento("m1", __op="c", __lsn=123)))
    assert (evento["_operacao"], evento["_lsn"], evento["_do_snapshot"]) == ("c", 123, False)
    assert evento["unit_cost"] == Decimal("10.123456") and evento["occurred_at"].tzinfo is not None
    assert not any(campo.startswith("__") for campo in evento)
    assert decodificar(json.dumps(_evento("m1", __op="r")))["_do_snapshot"] is True
    for proibido in ({"__op": "u"}, {"__op": "d", "__deleted": "true"}, {"__op": "c", "__deleted": "true"},
                     {"__op": "x"}):
        with pytest.raises(ContratoViolado):
            decodificar(json.dumps(_evento("m1", **proibido)))


def test_a_declaracao_tem_a_secao_da_nuvem_com_os_nomes_do_terraform():
    fluxo = carregar()
    assert fluxo.nuvem.assinatura_de_eventos == f"{fluxo.transporte.topico_de_eventos}.beam"
    assert fluxo.nuvem.topico_de_alertas == fluxo.transporte.topico_de_alertas
    assert fluxo.nuvem.atributo_de_tempo == "occurred_at"


def test_o_fragmento_e_estavel_e_o_mesmo_para_a_mesma_chave():
    # Valor fixo: o `hash` do Python mudaria a cada interpretador, e o mesmo movimento
    # cairia em fragmentos diferentes em dois workers — a garantia (i) da D75 cairia.
    valores = {nuvem.fragmento(f"m-{i}", 4) for i in range(200)}
    assert valores == {0, 1, 2, 3}
    import zlib
    assert nuvem.fragmento("m-123", 4) == zlib.crc32(b"m-123") % 4


# ── A regra do lote (D75), com o BigQuery simulado ───────────────────────────

class _BigQuery:
    """Simula o `MERGE` (insere o que não casa) e a releitura pelo instante."""

    def __init__(self, ja_existem=(), mentir_afetadas=None):
        self.linhas_gravadas: dict[str, dt.datetime] = {k: dt.datetime(2020, 1, 1, tzinfo=dt.timezone.utc)
                                                       for k in ja_existem}
        self.mentir = mentir_afetadas

    def tabela(self, q):
        return f"`p.{q}`"

    def dml(self, sql, parametros, *, rotulo):
        novas = 0
        for linha in parametros["linhas"]:
            chave = linha.campos["movement_id"][1]
            if chave not in self.linhas_gravadas:
                self.linhas_gravadas[chave] = linha.campos["_stream_extracted_at"][1]
                novas += 1
        return novas if self.mentir is None else self.mentir

    def linhas(self, sql, parametros):
        return [{"movement_id": k} for k in parametros["ids"]
                if self.linhas_gravadas.get(k) == parametros["agora"]]


def _tipados(*ids):
    return [decodificar(json.dumps(_evento(i, __op="c"))) for i in ids]


def test_o_lote_grava_uma_vez_por_chave_e_devolve_so_o_que_entrou():
    bq = _BigQuery(ja_existem={"velho"})
    entraram, duplicados = nuvem.escrever_lote(bq, DESTINO, _tipados("a", "b", "a", "velho"))
    assert [e["movement_id"] for e in entraram] == ["a", "b"]
    assert duplicados == 2  # o "a" repetido no lote e o "velho" já gravado
    # Reexecutar o mesmo lote não devolve nada: o alerta sai, no máximo, uma vez (ii).
    assert nuvem.escrever_lote(bq, DESTINO, _tipados("a", "b")) == ([], 2)


def test_job_e_tabela_em_desacordo_param_a_escrita():
    with pytest.raises(RuntimeError, match="não se sabe"):
        nuvem.escrever_lote(_BigQuery(mentir_afetadas=5), DESTINO, _tipados("a"))


def test_o_ddl_tem_as_colunas_do_destino_local_na_mesma_ordem():
    from mvp_ed1.streaming.sink import tabela

    assert [n for n, _ in nuvem.COLUNAS] == [c.name for c in tabela(DESTINO).columns]


def test_o_grafo_da_nuvem_monta_sem_rodar(monkeypatch):
    import apache_beam as beam

    from mvp_ed1.streaming.pipeline import construir, opcoes

    monkeypatch.setenv("GCP_PROJECT_ID", "projeto-de-teste")
    p = beam.Pipeline(options=opcoes())  # montado e nunca rodado: nada sai da máquina
    colecoes = construir(p, carregar(), nuvem=True)
    assert set(colecoes) == {"eventos", "unicos", "novos", "alertas"}
    nomes = {t.full_label for t in p.transforms_stack[0].parts}
    assert {"LerDoTransporte", "GravarDeltas", "AcumularSaldo", "PublicarAlerta"} <= nomes


# ── Real (GCP_TESTES=1) ──────────────────────────────────────────────────────

@pytest.fixture
def real():
    if os.environ.get("GCP_TESTES") != "1":
        pytest.skip("só com GCP_TESTES=1 (BigQuery real)")
    from google.cloud import bigquery

    projeto = os.environ["GCP_PROJECT_ID"]
    cliente = bigquery.Client(project=projeto)
    dataset = f"quente_teste_{uuid.uuid4().hex[:8]}"
    novo = bigquery.Dataset(f"{projeto}.{dataset}")
    novo.location = os.environ["GCP_BQ_LOCATION"]
    cliente.create_dataset(novo)
    bq = nuvem.armazem()
    bq.renomear = {"raw": dataset}
    try:
        nuvem.garantir_tabela(bq, DESTINO)
        yield bq
    finally:
        cliente.delete_dataset(f"{projeto}.{dataset}", delete_contents=True, not_found_ok=True)
        bq.dispose()


def test_no_bigquery_de_verdade_o_lote_e_idempotente_e_exato(real):
    entraram, duplicados = nuvem.escrever_lote(real, DESTINO, _tipados("a", "b", "a"))
    assert sorted(e["movement_id"] for e in entraram) == ["a", "b"] and duplicados == 1
    assert nuvem.escrever_lote(real, DESTINO, _tipados("a", "b", "c"))[0][0]["movement_id"] == "c"
    linhas = real.linhas(f"select movement_id, unit_cost, occurred_at, _stream_partition from "
                         f"{real.tabela(DESTINO.qualificado)} order by 1")
    assert [l["movement_id"] for l in linhas] == ["a", "b", "c"]
    # Decimal e instante exatos, do envelope ao destino; sem partição no Pub/Sub.
    assert linhas[0]["unit_cost"] == Decimal("10.123456")
    assert linhas[0]["occurred_at"] == dt.datetime(2026, 11, 7, 15, 0, 0, 123456, tzinfo=dt.timezone.utc)
    assert linhas[0]["_stream_partition"] is None


def test_no_bigquery_de_verdade_o_mesmo_fragmento_em_serie_nao_duplica(real):
    """Dois lotes com a mesma chave nova, um depois do outro — o que o fragmento garante (i)."""
    primeiro = nuvem.escrever_lote(real, DESTINO, _tipados("novo", "x"))[0]
    segundo = nuvem.escrever_lote(real, DESTINO, _tipados("novo", "y"))[0]
    assert [e["movement_id"] for e in primeiro] == ["novo", "x"]
    assert [e["movement_id"] for e in segundo] == ["y"]
    ((n,),) = [tuple(l.values()) for l in real.linhas(
        f"select count(*) from {real.tabela(DESTINO.qualificado)} where movement_id = 'novo'")]
    assert n == 1


def test_no_bigquery_de_verdade_fragmentos_diferentes_escrevem_em_paralelo(real):
    """Chaves diferentes em lotes concorrentes: cada um devolve exatamente o seu."""
    resultados: dict[str, list[str]] = {}

    def escrever(nome, ids):
        resultados[nome] = sorted(e["movement_id"] for e in nuvem.escrever_lote(real, DESTINO, _tipados(*ids))[0])

    fios = [threading.Thread(target=escrever, args=("p", ["p1", "p2"])),
            threading.Thread(target=escrever, args=("q", ["q1", "q2"]))]
    for f in fios:
        f.start()
    for f in fios:
        f.join()
    assert resultados == {"p": ["p1", "p2"], "q": ["q1", "q2"]}


def test_no_bigquery_de_verdade_a_semente_ve_so_o_que_veio_antes(real):
    nuvem.escrever_lote(real, DESTINO, _tipados("s1"))
    inicio, linhas = nuvem.semente(real, DESTINO)
    assert linhas == [(1, 2, -3)] and inicio.tzinfo is not None
