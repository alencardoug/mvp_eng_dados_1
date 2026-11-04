"""A fase de recuperação (H7) diante do que a revisão do lote 1 da v1.1.0 achou.

Rodam as implementações reais de `recover`, `retomar`, `concluir`, `attempt_record`,
`publish`, `held`, `barrier` e do T3; o banco é um adaptador em memória que guarda
as 40 linhas do certificado e aplica os UPDATEs emitidos, e o livro é publicado de
verdade num diretório temporário. O adaptador vem da sonda E2 da revisão (Codex,
04/11/2026). Não modela concorrência nem *rollback* do PostgreSQL: nenhum dos três
casos depende deles. Sem banco — roda no `check-offline`.
"""

from __future__ import annotations

import copy
import datetime as dt
from contextlib import nullcontext

import pytest

from mvp_ed1.legacy import captura, schema
from mvp_ed1.recovery import capture_recovery as rec
from mvp_ed1.recovery import ledger
from mvp_ed1.recovery import memory_oracle as mo

UTC = dt.timezone.utc
INICIO = dt.datetime(2026, 11, 4, 10, 0, 0, 500000, tzinfo=UTC)
AGORA = INICIO + dt.timedelta(hours=2)          # depois da carência sem job
TABELAS = schema.tabelas()


def _pendentes(job):
    return [dict(capture_attempt_id="a", source_table=t, connection_name="legacy_para_raw_legacy",
                 started_at=INICIO, job_id=job, snapshot_id=None, status="pending",
                 source_rows_before=1, source_hash_before="original", source_rows_after=None,
                 source_hash_after=None, received_rows=None, received_hash=None,
                 sync_id_matches=None, completed_at=None) for t in TABELAS]


class _Resultado:
    def __init__(self, linhas=(), rowcount=0):
        self.linhas, self.rowcount = linhas, rowcount

    def all(self):
        return self.linhas

    def __iter__(self):
        return iter(self.linhas)


class _Banco:
    """O certificado de uma tentativa em memória, com os UPDATEs de `concluir` e de `_abandonar`."""

    def __init__(self, linhas):
        self.linhas = linhas

    def connect(self):
        return nullcontext(self)

    def begin(self):
        return nullcontext(self)

    def execute(self, sql, p=None):
        s = str(sql)
        if s.startswith("select source_table, job_id, source_rows_before"):
            return _Resultado([tuple(r[k] for k in ("source_table", "job_id", "source_rows_before",
                                                     "source_hash_before", "status", "snapshot_id"))
                               for r in self.linhas])
        if s.startswith("select source_table, job_id, status"):
            return _Resultado([tuple(r[k] for k in ("source_table", "job_id", "status", "snapshot_id"))
                               for r in self.linhas])
        if "set status = 'abandoned'" in s:
            for r in self.linhas:
                r.update(status="abandoned", completed_at=AGORA)
            return _Resultado(rowcount=len(self.linhas))
        if "set source_rows_after" in s:
            for r in self.linhas:
                if r["source_table"] == p["t"] and r["status"] == "pending":
                    for chave, param in [("source_rows_after", "na"), ("source_hash_after", "ha"),
                                         ("received_rows", "nr"), ("received_hash", "hr"), ("sync_id_matches", "m"),
                                         ("status", "s"), ("completed_at", "quando"), ("snapshot_id", "g")]:
                        r[chave] = p[param]
            return _Resultado(rowcount=1)
        raise AssertionError(f"SQL não modelado: {s[:80]}")


def _cenario(tmp_path, *, job, listagem, antes=None):
    """Monta o mundo e devolve `(rodar, banco, epoca)`; `antes(banco, epoca)` mexe nele antes da recuperação."""
    banco = _Banco(_pendentes(job))
    bruto = {t: {"rows": 1, "digest": "raw", "generations": [1]} for t in TABELAS}
    epoca = ledger.open_epoch(tmp_path, dict(format=1, kind="baseline", taken_at=(INICIO - dt.timedelta(hours=1)).isoformat(),
                                             captures={}, certificate={"rows": []})).path.parent

    def armazem(_conexao):
        return rec.Warehouse({"a": ledger.canonical_rows(banco.linhas)}, {"a": INICIO}, set())

    def certificado(_conexao, attempt_id=None):
        linhas = ledger.canonical_rows(banco.linhas)
        return {"rows": linhas, "count": len(linhas), "digest": "fixture"}

    mp = pytest.MonkeyPatch()
    mp.setattr(ledger, "_read_only", lambda _: nullcontext(banco))
    mp.setattr(ledger, "certificate_rows", certificado)
    mp.setattr(ledger.leitura, "_linhas", lambda _c, q, *a: [{"job_id": banco.linhas[0]["job_id"]}])
    mp.setattr(ledger, "measure_capture", lambda *_: copy.deepcopy(bruto))
    mp.setattr(rec, "read_warehouse", armazem)
    mp.setattr(captura, "_pendentes", lambda _: [("a", banco.linhas[0]["job_id"], INICIO)]
               if banco.linhas[0]["status"] == "pending" else [])
    mp.setattr(captura, "bloqueio_da_tentativa", lambda *a, **k: nullcontext())
    mp.setattr(captura, "medir_origem", lambda _: {t: captura.Medida(1, "alterado") for t in TABELAS})
    mp.setattr(captura, "medir_recebido", lambda _, job: {t: captura.Recebido(1, "alterado", (1,), 0) for t in TABELAS})
    if antes is not None:
        antes(banco, epoca)

    def rodar():
        try:
            return rec.recover(None, banco, job_state=lambda _: "succeeded", listar=lambda: listagem, caller={},
                               environ={ledger.ENV: str(tmp_path)}, agora=AGORA)
        finally:
            mp.undo()

    return rodar, banco, epoca, bruto, armazem


def test_certificado_adulterado_depois_do_registro_para_sem_ser_adotado(tmp_path) -> None:
    """RVL1-03: a recuperação publicava a transição sobre o valor alterado e certificava `complete`."""
    listagem = rec.Listing([], None)

    def adulterar(banco, epoca):
        ledger.publish(epoca, "primeiro.json", ledger.attempt_record(banco, "a", caller={}))
        for r in banco.linhas:
            r["source_hash_before"] = "alterado"     # o antes retido exigia `unstable`

    rodar, banco, epoca, _, _ = _cenario(tmp_path, job=9, listagem=listagem, antes=adulterar)
    with pytest.raises(rec.RecoveryStopped, match="difere do último registro dela no livro"):
        rodar()
    assert {r["status"] for r in banco.linhas} == {"pending"}, "nada se retomou"
    assert sorted(r["kind"] for r in ledger.records(epoca)) == ["attempt", "baseline"], "nenhuma transição"


def test_a_transicao_leva_o_job_associado_e_o_t3_aceita_a_recuperacao_integra(tmp_path) -> None:
    """RVL1-04: a transição nascia com `raw=None`, e o T3 recusava a recuperação íntegra."""
    listagem = rec.Listing([{"id": 9, "type": "sync", "status": "succeeded",
                             "started_at": (INICIO + dt.timedelta(seconds=2)).isoformat()}], None)
    rodar, banco, epoca, bruto, armazem = _cenario(tmp_path, job=None, listagem=listagem)
    feito = rodar()
    assert feito["transitions"] == {"a": "abandonada"}
    registros = ledger.records(epoca)
    transicao = next(r for r in registros if r["kind"] == "transition")
    assert transicao["associated_job"] == 9 and transicao["raw"] == bruto
    memoria = mo.Memory(certificate=armazem(None).certificate, captures={"9": bruto}, certified=[], received={},
                        selected=None, quarantine=None, quarantine_by_table={}, classification=None, versions=[],
                        deletions=None)
    assert mo.check(registros, memoria) == []


def test_job_em_segundos_no_limite_da_janela_para_antes_de_registrar_ou_abandonar(tmp_path) -> None:
    """RVL1-05: a listagem real dá `startTime` em segundos; o job de `10:00:00` pode ser de antes de `10:00:00.5`."""
    listagem = rec.Listing([{"id": 9, "type": "sync", "status": "running",
                             "started_at": "2026-11-04T10:00:00Z"}], None)
    rodar, banco, epoca, _, _ = _cenario(tmp_path, job=None, listagem=listagem)
    with pytest.raises(rec.RecoveryStopped, match="início em segundos no limite da janela"):
        rodar()
    assert {r["status"] for r in banco.linhas} == {"pending"}, "nada se abandonou"
    assert [r["kind"] for r in ledger.records(epoca)] == ["baseline"], "nada se registrou"


@pytest.mark.parametrize("inicio_do_job, esperado", [
    ("2026-11-04T10:00:00.750000Z", ("job", 9)),      # exato e dentro
    ("2026-11-04T10:00:00.250000Z", ("job", None)),   # exato e antes do início
    ("2026-11-04T10:00:01Z", ("job", 9)),             # em segundos, o segundo inteiro dentro
    ("2026-11-04T09:59:59Z", ("job", None)),          # em segundos, o segundo inteiro antes
    ("2026-11-04T10:00:00Z", ("stop", "limite da janela")),  # em segundos, atravessa o início
])
def test_reconcile_trata_a_precisao_do_inicio_do_job(inicio_do_job, esperado) -> None:
    armazem = rec.Warehouse({"a": []}, {"a": INICIO}, set())
    estado = rec.Held(baseline_taken_at=INICIO - dt.timedelta(hours=1))
    listagem = rec.Listing([{"id": 9, "type": "sync", "status": "succeeded", "started_at": inicio_do_job}], None)
    achado = rec.reconcile("a", armazem, estado, listagem, AGORA)
    if esperado[0] == "job":
        assert achado.job == esperado[1] and achado.stop is None
    else:
        assert achado.job is None and esperado[1] in achado.stop


def test_o_fim_da_janela_tambem_e_limite() -> None:
    """O segundo que atravessa o início da tentativa seguinte também não se decide."""
    seguinte = INICIO + dt.timedelta(seconds=30, microseconds=200000)
    armazem = rec.Warehouse({"a": [], "b": []}, {"a": INICIO, "b": seguinte}, set())
    estado = rec.Held(baseline_taken_at=INICIO - dt.timedelta(hours=1))
    listagem = rec.Listing([{"id": 9, "type": "sync", "status": "succeeded",
                             "started_at": "2026-11-04T10:00:30Z"}], None)
    assert "limite da janela" in rec.reconcile("a", armazem, estado, listagem, AGORA).stop
