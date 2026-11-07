"""O armazém BigQuery do G2.1 (Etapa 13): o resultado é o do *job*, não o da resposta.

A parte de unidade usa um cliente simulado — o que se testa é a regra de
espera e de não reenvio, não o BigQuery. A parte real, com `GCP_TESTES=1`, roda
o ciclo da captura contra o BigQuery de verdade, num *dataset* temporário para o
certificado, com o lock no PostgreSQL local fazendo o papel do Cloud SQL.
"""

from __future__ import annotations

import datetime as dt
import os
import threading
import types
import uuid

import pytest

from mvp_ed1.legacy import armazem as modulo
from mvp_ed1.legacy.armazem import BigQuery, ErroDoJob, JobPerdido, Struct, _arrobas


class _Job:
    def __init__(self, afetadas=40, erro=None, estado="DONE"):
        self.num_dml_affected_rows = afetadas
        self.error_result = erro
        self.state = estado

    def result(self, *a, **k):
        return []


class _Cliente:
    """Registra cada `query`; `falha` decide o que acontece com a resposta."""

    def __init__(self, falha=None, job=None):
        self.enviadas: list[str] = []
        self.falha = falha
        self.jobs: dict[str, _Job] = {}
        self.job = job or _Job()

    def query(self, sql, job_config=None, job_id=None, job_retry=None, location=None):
        self.enviadas.append(job_id)
        self.jobs[job_id] = self.job      # a requisição chegou: o job existe
        if self.falha is not None:
            raise self.falha
        return self.job

    def get_job(self, job_id, location=None):
        from google.api_core import exceptions as gexc

        if job_id not in self.jobs:
            raise gexc.NotFound("job")
        return self.jobs[job_id]


def _armazem(cliente) -> BigQuery:
    relogio = iter(range(0, 10_000, 1))
    return BigQuery(cliente, "p", coordenador=None, relogio=lambda: next(relogio), pausa=lambda s: None)


def test_parametros_viram_arrobas_sem_tocar_no_cast_do_postgres():
    assert _arrobas("where a = :a and b = :b_2 and c::text = x") == "where a = @a and b = @b_2 and c::text = x"
    assert _arrobas("'12:00' and json_value(m, '$.sync_id') = :j") == "'12:00' and json_value(m, '$.sync_id') = @j"


def test_resposta_perdida_le_o_job_e_nao_reenvia():
    cliente = _Cliente(falha=ConnectionError("reset"))
    assert _armazem(cliente).dml("update t set x = 1", rotulo="r") == 40
    assert len(cliente.enviadas) == 1, "reenviar uma DML já aplicada gravaria zero e pareceria recusa"


def test_conflito_do_id_le_o_job_existente():
    from google.api_core import exceptions as gexc

    cliente = _Cliente(falha=gexc.Conflict("já existe"))
    assert _armazem(cliente).dml("update t set x = 1", rotulo="r") == 40
    assert len(cliente.enviadas) == 1


def test_erro_do_job_e_nao_gravou():
    from google.api_core import exceptions as gexc

    cliente = _Cliente(falha=gexc.BadRequest("Could not serialize access to table due to concurrent update"))
    with pytest.raises(ErroDoJob):
        _armazem(cliente).dml("update t set x = 1", rotulo="r")


def test_job_terminado_com_erro_tambem_e_nao_gravou():
    cliente = _Cliente(falha=ConnectionError("reset"), job=_Job(erro={"reason": "invalidQuery"}))
    with pytest.raises(ErroDoJob):
        _armazem(cliente).dml("update t set x = 1", rotulo="r")


def test_job_que_nao_termina_para_com_erro_e_nao_finge_resultado():
    cliente = _Cliente(falha=ConnectionError("reset"), job=_Job(estado="RUNNING"))
    with pytest.raises(JobPerdido):
        _armazem(cliente).dml("update t set x = 1", rotulo="r")


def test_parametro_de_lista_de_structs_e_tipado():
    p = modulo._parametro("v", [Struct({"t": ("STRING", "brands"), "n": ("INT64", 3)})])
    assert p.array_type == "STRUCT" and len(p.values) == 1
    assert modulo._parametro("g", ("INT64", None)).value is None
    with pytest.raises(TypeError):
        modulo._parametro("x", object())


def test_o_ambiente_escolhe_o_armazem_e_o_coordenador_e_o_legado(monkeypatch):
    from google.cloud import bigquery

    monkeypatch.setattr(bigquery, "Client", lambda **k: types.SimpleNamespace(**k))  # sem credencial
    legado = object()
    escolhido = modulo.do_ambiente(legado, {"LEGACY_WAREHOUSE": "bigquery", "GCP_PROJECT_ID": "p",
                                            "GCP_BQ_LOCATION": "us-central1"})
    assert isinstance(escolhido, BigQuery) and escolhido.coordenador is legado
    assert escolhido.local == "us-central1" and modulo.coordenador(escolhido) is legado
    with pytest.raises(RuntimeError, match="GCP_BQ_LOCATION"):
        modulo.do_ambiente(legado, {"LEGACY_WAREHOUSE": "bigquery", "GCP_PROJECT_ID": "p"})
    with pytest.raises(RuntimeError, match="postgres ou bigquery"):
        modulo.do_ambiente(legado, {"LEGACY_WAREHOUSE": "oracle"})


def test_leitura_num_instante_nao_escreve():
    a = BigQuery(_Cliente(), "p", coordenador=None, instante=dt.datetime(2026, 11, 7, tzinfo=dt.timezone.utc))
    assert "for system_time as of timestamp '2026-11-07T00:00:00+00:00'" in a.tabela("governance.legacy_captures")
    with pytest.raises(RuntimeError, match="não escreve"):
        a.dml("update t set x = 1", rotulo="r")


# ── O ciclo real (GCP_TESTES=1) ──────────────────────────────────────────────

@pytest.fixture
def real():
    """BigQuery de verdade, com o certificado num *dataset* temporário e o bruto do `raw_legacy` da carga dev."""
    if os.environ.get("GCP_TESTES") != "1":
        pytest.skip("só com GCP_TESTES=1 (BigQuery real)")
    from google.cloud import bigquery
    from sqlalchemy import create_engine

    from mvp_ed1 import governance
    from mvp_ed1.db import LEGACY, WAREHOUSE, database_url

    projeto = os.environ["GCP_PROJECT_ID"]
    cliente = bigquery.Client(project=projeto)
    dataset = f"captura_teste_{uuid.uuid4().hex[:8]}"
    novo = bigquery.Dataset(f"{projeto}.{dataset}")
    novo.location = os.environ["GCP_BQ_LOCATION"]
    cliente.create_dataset(novo, exists_ok=False)
    legado = create_engine(database_url(LEGACY))
    coordenador = create_engine(database_url(WAREHOUSE))   # o papel do Cloud SQL: um PostgreSQL
    try:
        governance.garantir_bigquery(cliente, projeto, dataset)
        yield types.SimpleNamespace(
            armazem=BigQuery(cliente, projeto, coordenador=coordenador, local=os.environ["GCP_BQ_LOCATION"],
                             renomear={"governance": dataset}),
            legado=legado, cliente=cliente, dataset=f"{projeto}.{dataset}",
        )
    finally:
        cliente.delete_dataset(f"{projeto}.{dataset}", delete_contents=True, not_found_ok=True)
        legado.dispose()
        coordenador.dispose()


def _sem_pendente(armazem) -> list[str]:
    """Uma barreira mínima: recusa abrir com outra tentativa pendente — o que mostra a serialização."""
    from mvp_ed1.legacy import captura

    return [f"pendente {a}" for a, _, _ in captura._pendentes(armazem)]


def test_no_bigquery_de_verdade_o_ciclo_da_captura(real):
    from mvp_ed1.legacy import captura, schema

    a = real.armazem
    tentativa = captura.iniciar(real.legado, a, "teste", barreira=lambda _: [])
    assert captura._pendentes(a)[0][0] == tentativa
    # Id repetido grava zero e falha, sem tocar nas 40 (o insert que falha do PostgreSQL).
    with pytest.raises(captura.AberturaRecusada):
        captura.iniciar(real.legado, a, "teste", barreira=_sem_pendente)
    with pytest.raises(captura.IdRepetido):
        captura.iniciar(real.legado, a, "teste", barreira=lambda _: [], tentativa=tentativa)

    captura.conferir_antes_do_disparo(a, tentativa)
    # O job da carga dev (`sync_id` presente no bruto), e o registro é idempotente para ele.
    job = int(a.escalar(f"select min(cast({a.sync_id()} as int64)) from {a.do_bruto('raw_legacy', 'brands')}"))
    captura.registrar_job(a, tentativa, job)
    captura.registrar_job(a, tentativa, job)
    with pytest.raises(captura.TentativaIndisponivel):
        captura.registrar_job(a, tentativa, job + 1)

    certificado = captura.concluir(real.legado, a, tentativa)
    assert certificado["job_id"] == job and set(certificado["tabelas"]) == set(schema.tabelas())
    assert captura.PENDING not in certificado["tabelas"].values()
    # Reenvio da fase 2 não remede: devolve o gravado, mesmo sem origem para medir.
    original = captura.medir_origem
    captura.medir_origem = lambda *_: (_ for _ in ()).throw(AssertionError("remediu a origem"))
    try:
        assert captura.concluir(real.legado, a, tentativa) == certificado
    finally:
        captura.medir_origem = original


def test_no_bigquery_de_verdade_duas_aberturas_concorrentes_se_serializam(real):
    """O lock de sessão no coordenador serializa a abertura como o `xact_lock` serializava."""
    from mvp_ed1.legacy import captura

    resultados: dict[str, object] = {}

    def abrir(nome: str) -> None:
        try:
            resultados[nome] = captura.iniciar(real.legado, real.armazem, "teste", barreira=_sem_pendente)
        except captura.AberturaRecusada as erro:
            resultados[nome] = erro

    fios = [threading.Thread(target=abrir, args=(n,)) for n in ("a", "b")]
    for fio in fios:
        fio.start()
    for fio in fios:
        fio.join()
    abertas = [r for r in resultados.values() if isinstance(r, str)]
    assert len(abertas) == 1, resultados
    assert [a for a, _, _ in captura._pendentes(real.armazem)] == abertas


def test_no_bigquery_de_verdade_resposta_perdida_nao_duplica_nem_recusa(real):
    """O *job* da abertura roda, a resposta some: a abertura vale, sem reenvio."""
    from mvp_ed1.legacy import captura

    cliente = real.armazem.cliente
    original = cliente.query

    def perde_a_resposta(sql, job_config=None, job_id=None, **k):
        job = original(sql, job_config=job_config, job_id=job_id, **k)
        if job_id and job_id.startswith("mvp_abertura_"):
            job.result()
            raise ConnectionError("a resposta se perdeu")
        return job

    cliente.query = perde_a_resposta
    try:
        tentativa = captura.iniciar(real.legado, real.armazem, "teste", barreira=lambda _: [])
    finally:
        cliente.query = original
    assert [a for a, _, _ in captura._pendentes(real.armazem)] == [tentativa]
    ((n,),) = captura._ler(real.armazem, f"select count(*) from {captura._t(real.armazem)}")
    assert n == 40


def test_no_bigquery_de_verdade_abandono_so_fora_da_carencia(real):
    from mvp_ed1.legacy import captura

    antes = dt.datetime.now(dt.timezone.utc) - captura.CARENCIA_SEM_JOB - dt.timedelta(minutes=1)
    tentativa = captura.iniciar(real.legado, real.armazem, "teste", barreira=lambda _: [], agora=antes)
    jovem = captura.iniciar(real.legado, real.armazem, "teste", barreira=lambda _: [])
    assert captura.retomar(real.legado, real.armazem) == {tentativa: "abandonada", jovem: "ativa"}
    assert captura.concluir(real.legado, real.armazem, tentativa)["status"] == captura.ABANDONED
