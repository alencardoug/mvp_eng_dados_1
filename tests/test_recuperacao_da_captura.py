"""A fase de recuperação das capturas do legado — H7 da regeneração da v1.1.0.

Três níveis:

* **a barreira, a reconciliação e a leitura da época**, puras: cada diferença
  que a barreira tem de parar, uma por vez, sobre um estado limpo que passa;
* **a fase inteira e a abertura**, em bancos efêmeros criados ao lado dos de
  trabalho (os de `test_captura_legado.py`) e num livro temporário: nada toca a
  `governance` real. Onde ela para, nenhuma tentativa é aberta;
* **a CLI**, de verdade, contra os efêmeros, com o Airbyte trocado: o registro
  de transição existe antes de o disparo ser chamado.
"""

from __future__ import annotations

import datetime as dt
import json
import uuid

import pytest
from sqlalchemy import text

from mvp_ed1 import airbyte, governance
from mvp_ed1.legacy import captura
from mvp_ed1.recovery import capture_recovery as rec
from mvp_ed1.recovery import ledger

from test_captura_legado import (  # noqa: F401 — fixtures dos bancos efêmeros
    SEM_BARREIRA,
    _semear_origem,
    _simular_job,
    administradores,
    efemeros,
)

UTC = dt.timezone.utc
BASE = dt.datetime(2026, 11, 1, 12, 0, tzinfo=UTC)


# ── A barreira, pura ─────────────────────────────────────────────────────────
def _linhas(tentativa: str, job: int | None, status: str = "complete") -> list[dict]:
    return [{"capture_attempt_id": tentativa, "source_table": t, "job_id": job, "status": status}
            for t in ("brands", "orders")]


def _job(job: int, quando: dt.datetime, status: str = "succeeded") -> dict:
    return {"id": job, "type": "sync", "status": status, "started_at": quando.isoformat()}


@pytest.fixture
def limpo():
    """A época com a captura 7 na linha de base e a tentativa `b` (job 9) registrada depois."""
    estado = rec.Held(
        rows={"a": _linhas("a", 7), "b": _linhas("b", 9)},
        kinds={"a": "baseline", "b": ledger.TRANSITION},
        baseline_captures={"7"}, baseline_taken_at=BASE,
    )
    armazem = rec.Warehouse(
        certificate={"a": _linhas("a", 7), "b": _linhas("b", 9)},
        started={"a": BASE - dt.timedelta(days=1), "b": BASE + dt.timedelta(hours=1)},
        sync_ids={"7", "9"},
    )
    listagem = rec.Listing(jobs=[_job(5, BASE - dt.timedelta(days=2)), _job(9, BASE + dt.timedelta(hours=1))],
                           oldest=None)
    return estado, armazem, listagem


def test_o_estado_limpo_passa(limpo) -> None:
    assert rec.barrier(*limpo) == []


def test_tentativa_sem_registro_para(limpo) -> None:
    estado, armazem, listagem = limpo
    armazem.certificate["c"] = _linhas("c", None, "abandoned")
    assert rec.barrier(estado, armazem, listagem) == ["tentativa c sem registro na época"]


@pytest.mark.parametrize("campo", ["status", "job_id", "source_table"])
def test_certificado_mudado_fora_da_transicao_para(limpo, campo) -> None:
    estado, armazem, listagem = limpo
    armazem.certificate["b"][0][campo] = "trocado"
    assert any("difere do último registro" in p for p in rec.barrier(estado, armazem, listagem))


def test_final_sem_registro_da_transicao_para(limpo) -> None:
    """N34: o registro da transição falhou; o último que a época tem ainda é `pending`."""
    estado, armazem, listagem = limpo
    estado.rows["b"] = _linhas("b", 9, "pending")
    estado.kinds["b"] = ledger.ATTEMPT
    assert rec.barrier(estado, armazem, listagem) == ["tentativa b: o certificado difere do último registro (attempt)"]


def test_pendente_para(limpo) -> None:
    estado, armazem, listagem = limpo
    armazem.certificate["b"] = estado.rows["b"] = _linhas("b", 9, "pending")
    assert rec.barrier(estado, armazem, listagem) == ["tentativa b ainda pending"]


def test_tentativa_que_sumiu_do_certificado_para(limpo) -> None:
    """Também o caso de uma restauração que tirou capturas da época (H8)."""
    estado, armazem, listagem = limpo
    del armazem.certificate["b"]
    armazem.sync_ids.discard("9")
    problemas = rec.barrier(estado, armazem, listagem)
    assert "tentativa b, registrada na época, sumiu do certificado" in problemas


def test_sync_id_sem_explicacao_para(limpo) -> None:
    estado, armazem, listagem = limpo
    armazem.sync_ids.add("12")
    assert rec.barrier(estado, armazem, listagem) == [
        "sync_id 12 do bruto sem tentativa registrada nem captura da linha de base"
    ]


def test_job_sem_dono_depois_da_linha_de_base_para_e_o_de_antes_nao(limpo) -> None:
    estado, armazem, listagem = limpo
    listagem.jobs.append(_job(11, BASE + dt.timedelta(hours=2)))
    listagem.jobs.append(_job(4, BASE - dt.timedelta(hours=2)))  # da linha de base (O8)
    assert rec.barrier(estado, armazem, listagem) == [
        "job 11 da conexão legada, de depois da linha de base, reivindicado por 0 tentativas"
    ]


def test_job_reivindicado_por_duas_tentativas_para(limpo) -> None:
    estado, armazem, listagem = limpo
    estado.associated["c"] = 9
    assert any("reivindicado por 2 tentativas" in p for p in rec.barrier(estado, armazem, listagem))


def test_listagem_que_nao_chega_a_linha_de_base_para(limpo) -> None:
    estado, armazem, _ = limpo
    curta = rec.Listing(jobs=[_job(9, BASE + dt.timedelta(hours=1))], oldest=BASE + dt.timedelta(minutes=30))
    assert rec.barrier(estado, armazem, curta) == [
        "a listagem do Airbyte não chega à linha de base: o inventário de jobs está incompleto"
    ]


def test_a_associacao_explica_o_sync_id_e_o_job(limpo) -> None:
    """A tentativa sem job a que a reconciliação associou o job 11: o bruto dele e o job ficam explicados."""
    estado, armazem, listagem = limpo
    armazem.certificate["c"] = estado.rows["c"] = _linhas("c", None, "abandoned")
    estado.associated["c"] = 11
    armazem.sync_ids.add("11")
    listagem.jobs.append(_job(11, BASE + dt.timedelta(hours=2)))
    assert rec.barrier(estado, armazem, listagem) == []


# ── A reconciliação de uma tentativa sem job, pura ───────────────────────────
@pytest.fixture
def sem_job(limpo):
    estado, armazem, listagem = limpo
    armazem.certificate["c"] = _linhas("c", None, "pending")
    armazem.started["c"] = BASE + dt.timedelta(hours=3)
    armazem.started["d"] = BASE + dt.timedelta(hours=5)  # a tentativa seguinte fecha a janela
    return estado, armazem, listagem


AGORA = BASE + dt.timedelta(hours=10)


def test_sem_job_na_janela_e_sem_bruto_sem_dono_e_tentativa_sem_job(sem_job) -> None:
    achado = rec.reconcile("c", sem_job[1], sem_job[0], sem_job[2], AGORA)
    assert achado.job is None and achado.stop is None


def test_um_job_na_janela_e_o_da_tentativa(sem_job) -> None:
    estado, armazem, listagem = sem_job
    listagem.jobs.append(_job(12, BASE + dt.timedelta(hours=4), "running"))
    achado = rec.reconcile("c", armazem, estado, listagem, AGORA)
    assert (achado.job, achado.job_status, achado.stop) == (12, "running", None)


def test_o_job_depois_da_janela_nao_conta(sem_job) -> None:
    estado, armazem, listagem = sem_job
    listagem.jobs.append(_job(12, BASE + dt.timedelta(hours=6)))
    assert rec.reconcile("c", armazem, estado, listagem, AGORA).job is None


def test_job_de_outra_tentativa_nao_e_candidato(sem_job) -> None:
    estado, armazem, listagem = sem_job
    armazem.certificate["e"] = _linhas("e", 12)
    listagem.jobs.append(_job(12, BASE + dt.timedelta(hours=4)))
    assert rec.reconcile("c", armazem, estado, listagem, AGORA).job is None


def test_dois_jobs_na_janela_param(sem_job) -> None:
    estado, armazem, listagem = sem_job
    listagem.jobs.extend([_job(12, BASE + dt.timedelta(hours=4)), _job(13, BASE + dt.timedelta(hours=4, minutes=1))])
    assert "2 jobs na janela" in rec.reconcile("c", armazem, estado, listagem, AGORA).stop


def test_sem_job_mas_com_bruto_sem_dono_para(sem_job) -> None:
    estado, armazem, listagem = sem_job
    armazem.sync_ids.add("14")
    assert "sync_id sem tentativa" in rec.reconcile("c", armazem, estado, listagem, AGORA).stop


def test_listagem_que_nao_chega_ao_inicio_da_janela_para(sem_job) -> None:
    estado, armazem, _ = sem_job
    curta = rec.Listing(jobs=[], oldest=BASE + dt.timedelta(hours=4))
    assert "não chega ao início da janela" in rec.reconcile("c", armazem, estado, curta, AGORA).stop


# ── A leitura da época ───────────────────────────────────────────────────────
def test_o_ultimo_registro_e_a_transicao_sobre_a_tentativa_sobre_a_linha_de_base() -> None:
    registros = [
        {"kind": "baseline", "taken_at": BASE.isoformat(), "captures": {"7": {}},
         "certificate": {"rows": _linhas("a", 7, "pending")}},
        {"kind": ledger.TRANSITION, "capture_attempt_id": "a", "taken_at": "2026-11-01T13:00:00+00:00",
         "certificate": {"rows": _linhas("a", 7)}},
        {"kind": ledger.ATTEMPT, "capture_attempt_id": "a", "taken_at": "2026-11-01T14:00:00+00:00",
         "certificate": {"rows": _linhas("a", 7, "pending")}},
        {"kind": ledger.ATTEMPT, "capture_attempt_id": "c", "taken_at": "2026-11-01T15:00:00+00:00",
         "certificate": {"rows": _linhas("c", None, "pending")}, "associated_job": 11},
    ]
    estado = rec.held(registros)
    assert estado.rows["a"] == _linhas("a", 7) and estado.kinds["a"] == ledger.TRANSITION
    assert estado.associated == {"c": 11} and estado.baseline_captures == {"7"}
    assert estado.claims() == {7: ["a"], 11: ["c"]}


def test_uma_epoca_precisa_de_exatamente_uma_linha_de_base() -> None:
    with pytest.raises(ledger.LedgerError, match="0 linhas de base"):
        rec.held([])


# ── A fase inteira, em bancos efêmeros ───────────────────────────────────────
CONEXAO = "legacy_para_raw_legacy"


@pytest.fixture
def mundo(efemeros, tmp_path, monkeypatch):
    """Bancos efêmeros, um livro com a época aberta agora e um Airbyte de mentira."""
    legado, armazem = efemeros
    _semear_origem(legado)
    governance.garantir(armazem)
    monkeypatch.setenv(ledger.ENV, str(tmp_path))
    estado = {"jobs": {}, "listagem_falha": False, "raiz": tmp_path, "legado": legado, "armazem": armazem}

    def abrir_epoca() -> None:
        with ledger._read_only(armazem) as conexao:
            linha_de_base = {"format": ledger.FORMAT, "kind": "baseline",
                             "taken_at": dt.datetime.now(UTC).isoformat(),
                             "captures": ledger.measure_captures(conexao),
                             "certificate": ledger.certificate_rows(conexao)}
        ledger.open_epoch(tmp_path, linha_de_base)

    def listar() -> rec.Listing:
        if estado["listagem_falha"]:
            raise airbyte.AirbyteIndisponivel("o Airbyte não respondeu")
        return rec.Listing(jobs=[{"id": j, "type": "sync", "status": s, "started_at": q.isoformat()}
                                 for j, (s, q) in sorted(estado["jobs"].items())], oldest=None)

    estado["abrir_epoca"] = abrir_epoca
    estado["listar"] = listar
    estado["job_state"] = lambda job: estado["jobs"][job][0]
    abrir_epoca()
    return estado


def _job_no_airbyte(mundo, job: int, status: str = "succeeded") -> None:
    mundo["jobs"][job] = (status, dt.datetime.now(UTC))


def _abrir(mundo, **k) -> str:
    """Uma abertura como os chamadores fazem: sob a barreira de abertura."""
    return captura.iniciar(mundo["legado"], mundo["armazem"], CONEXAO,
                           barreira=rec.opening_barrier(mundo["listar"]), **k)


def _capturar(mundo, job: int, geracao: int, *, registrar=True, status="succeeded") -> str:
    """Abre, associa o job, o bruto chega; com `registrar`, conclui e passa pelo portão."""
    tentativa = _abrir(mundo)
    captura.registrar_job(mundo["armazem"], tentativa, job)
    _job_no_airbyte(mundo, job, status)
    _simular_job(mundo["armazem"], mundo["legado"], job_id=job, geracao=geracao)
    if registrar:
        captura.concluir(mundo["legado"], mundo["armazem"], tentativa)
        ledger.gate(mundo["armazem"], tentativa, caller={"kind": "test"})
    return tentativa


def _recuperar(mundo, **k):
    return rec.recover(mundo["legado"], mundo["armazem"], job_state=mundo["job_state"],
                       listar=mundo["listar"], caller={"kind": "test"}, **k)


def _estado(mundo, tentativa: str) -> set[str]:
    with mundo["armazem"].connect() as conexao:
        return {s for (s,) in conexao.execute(
            text(f"select distinct status from {ledger.CERTIFICATE} where capture_attempt_id = :a"), {"a": tentativa}
        )}


def _tentativas(mundo) -> int:
    with mundo["armazem"].connect() as conexao:
        return conexao.execute(text(f"select count(distinct capture_attempt_id) from {ledger.CERTIFICATE}")).scalar()


def _nomes(mundo) -> list[str]:
    return sorted(p.name for p in ledger.current_epoch(mundo["raiz"]).iterdir() if p.name != ledger.BASELINE)


@pytest.mark.integracao
def test_uma_captura_registrada_pelo_portao_deixa_a_barreira_passar(mundo) -> None:
    _capturar(mundo, 901, 1)
    assert _recuperar(mundo)["transitions"] == {}
    assert _abrir(mundo)  # abre


@pytest.mark.integracao
def test_pendente_registrada_com_job_final_e_finalizada_com_transicao(mundo) -> None:
    tentativa = _capturar(mundo, 901, 1, registrar=False)
    ledger.publish(ledger.current_epoch(mundo["raiz"]), f"dag_x_{tentativa}_attempt.json",
                   ledger.attempt_record(mundo["armazem"], tentativa, caller={"kind": "dag"}))
    relatorio = _recuperar(mundo)
    assert relatorio["transitions"] == {tentativa: "concluida"} and _estado(mundo, tentativa) == {"complete"}
    # A já registrada não ganha outro registro de tentativa, só o de transição.
    assert _nomes(mundo) == [f"dag_x_{tentativa}_attempt.json", f"recovery_{tentativa}_transition.json"]
    transicao = json.loads((ledger.current_epoch(mundo["raiz"]) / f"recovery_{tentativa}_transition.json").read_text())
    assert transicao["kind"] == ledger.TRANSITION and ledger.certificate_status(transicao) == "complete"
    # Rodar de novo não registra nada duas vezes.
    assert _recuperar(mundo) == {**relatorio, "recorded": [], "transitions": {}, "published": []}


@pytest.mark.integracao
def test_pendente_final_sem_registro_e_registrada_e_finalizada(mundo) -> None:
    tentativa = _capturar(mundo, 901, 1, registrar=False)
    relatorio = _recuperar(mundo)
    assert relatorio["recorded"] == [tentativa]
    assert _nomes(mundo) == [f"recovery_{tentativa}_attempt.json", f"recovery_{tentativa}_transition.json"]
    tentativa_rec = json.loads((ledger.current_epoch(mundo["raiz"]) / f"recovery_{tentativa}_attempt.json").read_text())
    assert ledger.certificate_status(tentativa_rec) == "pending"


@pytest.mark.integracao
def test_job_que_termina_entre_1_e_2_nao_e_finalizado_e_a_fase_para(mundo) -> None:
    tentativa = _capturar(mundo, 901, 1, registrar=False, status="running")
    respostas = iter(["running", "succeeded", "succeeded"])
    with pytest.raises(rec.RecoveryStopped, match="ativa: job 901 running"):
        rec.recover(mundo["legado"], mundo["armazem"], job_state=lambda _j: next(respostas),
                    listar=mundo["listar"], caller={})
    assert _estado(mundo, tentativa) == {"pending"} and _nomes(mundo) == []
    with pytest.raises(captura.AberturaRecusada):
        _abrir(mundo)
    assert _tentativas(mundo) == 1


@pytest.mark.integracao
def test_final_sem_registro_para_a_barreira(mundo) -> None:
    tentativa = _capturar(mundo, 901, 1, registrar=False)
    captura.concluir(mundo["legado"], mundo["armazem"], tentativa)  # finalizada fora da recuperação
    with pytest.raises(rec.RecoveryStopped, match=f"tentativa {tentativa} sem registro"):
        _recuperar(mundo)
    with pytest.raises(captura.AberturaRecusada):
        _abrir(mundo)


@pytest.mark.integracao
def test_a_transicao_que_nao_se_registra_para_e_a_seguinte_nao_adota_a_leitura(mundo, monkeypatch) -> None:
    tentativa = _capturar(mundo, 901, 1, registrar=False)
    original = ledger.publish

    def falha_na_transicao(epoca, nome, conteudo):
        if nome.endswith("_transition.json"):
            raise OSError("disco cheio")
        return original(epoca, nome, conteudo)

    monkeypatch.setattr(ledger, "publish", falha_na_transicao)
    with pytest.raises(OSError, match="disco cheio"):
        _recuperar(mundo)
    assert _estado(mundo, tentativa) == {"complete"} and _tentativas(mundo) == 1
    monkeypatch.setattr(ledger, "publish", original)
    with mundo["armazem"].begin() as conexao:  # o valor que a transição escreveu muda no meio-tempo
        conexao.execute(text(f"update {ledger.CERTIFICATE} set completed_at = completed_at + interval '1 minute'"))
    with pytest.raises(rec.RecoveryStopped, match="difere do último registro"):
        _recuperar(mundo)
    assert f"recovery_{tentativa}_transition.json" not in _nomes(mundo)


@pytest.mark.integracao
def test_certificado_mudado_fora_da_transicao_para(mundo) -> None:
    _capturar(mundo, 901, 1)
    with mundo["armazem"].begin() as conexao:
        conexao.execute(text(f"update {ledger.CERTIFICATE} set source_hash_before = 'outro' "
                             "where source_table = 'brands'"))
    with pytest.raises(rec.RecoveryStopped, match="difere do último registro"):
        _recuperar(mundo)


@pytest.mark.integracao
def test_sync_id_e_job_sem_tentativa_param(mundo) -> None:
    _capturar(mundo, 901, 1)
    _simular_job(mundo["armazem"], mundo["legado"], job_id=950, geracao=2, tabelas=["brands"])
    with pytest.raises(rec.RecoveryStopped, match="sync_id 950"):
        _recuperar(mundo)
    with mundo["armazem"].begin() as conexao:
        conexao.execute(text("delete from raw_legacy.brands where _airbyte_meta->>'sync_id' = '950'"))
    _job_no_airbyte(mundo, 951)
    with pytest.raises(rec.RecoveryStopped, match="job 951 .* reivindicado por 0"):
        _recuperar(mundo)


@pytest.mark.integracao
def test_predecessora_ativa_para_com_o_motivo(mundo) -> None:
    em_curso = _capturar(mundo, 901, 1, registrar=False, status="running")
    with pytest.raises(rec.RecoveryStopped, match=f"tentativa {em_curso} ativa: job 901 running"):
        _recuperar(mundo)
    mundo["jobs"][901] = ("succeeded", mundo["jobs"][901][1])
    captura.concluir(mundo["legado"], mundo["armazem"], em_curso)
    ledger.gate(mundo["armazem"], em_curso, caller={})
    a_caminho = _abrir(mundo)  # sem job, dentro da carência
    with pytest.raises(rec.RecoveryStopped, match=f"tentativa {a_caminho} ativa: sem job, dentro da carência"):
        _recuperar(mundo)


@pytest.mark.integracao
def test_o_lock_tomado_e_chamador_vivo_seja_qual_for_a_idade(mundo) -> None:
    tentativa = uuid.uuid4().hex
    depois = dt.datetime.now(UTC) + captura.CARENCIA_SEM_JOB + dt.timedelta(minutes=1)
    with captura.bloqueio_da_tentativa(mundo["armazem"], tentativa):
        _abrir(mundo, tentativa=tentativa)
        with pytest.raises(rec.RecoveryStopped, match="o lock está com um chamador vivo"):
            _recuperar(mundo, agora=depois)
        assert _estado(mundo, tentativa) == {"pending"} and _nomes(mundo) == []
        # T4 à mão também recusa.
        with pytest.raises(captura.TentativaOcupada):
            ledger.operator_record(mundo["armazem"], tentativa, "D2_a1_memoria.json")


@pytest.mark.integracao
def test_sem_job_passada_a_carencia_e_abandonada_com_registro_e_o_atrasado_nao_dispara(mundo) -> None:
    """A DAG solta o lock entre a fase 1 e a sincronização: um atraso aí, e a recuperação de outro abandona."""
    atrasada = _abrir(mundo)
    depois = dt.datetime.now(UTC) + captura.CARENCIA_SEM_JOB + dt.timedelta(minutes=1)
    relatorio = _recuperar(mundo, agora=depois)
    assert relatorio["transitions"] == {atrasada: "abandonada"} and _estado(mundo, atrasada) == {"abandoned"}
    registro = json.loads((ledger.current_epoch(mundo["raiz"]) / f"recovery_{atrasada}_attempt.json").read_text())
    assert registro["associated_job"] is None and registro["reconciliation"]["window"]
    # O chamador atrasado retoma: a conferência de antes do POST recusa — zero POSTs.
    with captura.bloqueio_da_tentativa(mundo["armazem"], atrasada):
        with pytest.raises(captura.TentativaIndisponivel, match="nenhum job é criado"):
            captura.conferir_antes_do_disparo(mundo["armazem"], atrasada)


@pytest.mark.integracao
def test_sem_job_com_um_job_na_janela_e_associada_e_o_bruto_fica_explicado(mundo) -> None:
    """Interrompida entre o disparo e o `registrar_job`: o job existe e escreveu."""
    interrompida = _abrir(mundo)
    _job_no_airbyte(mundo, 902)
    _simular_job(mundo["armazem"], mundo["legado"], job_id=902, geracao=3)
    depois = dt.datetime.now(UTC) + captura.CARENCIA_SEM_JOB + dt.timedelta(minutes=1)
    relatorio = _recuperar(mundo, agora=depois)
    assert relatorio["transitions"] == {interrompida: "abandonada"}
    registro = json.loads((ledger.current_epoch(mundo["raiz"]) / f"recovery_{interrompida}_attempt.json").read_text())
    assert registro["associated_job"] == 902 and registro["raw"]["brands"]["rows"] == 2
    assert _abrir(mundo)  # o sync_id 902 e o job 902 explicados pela associação


@pytest.mark.integracao
def test_sem_listagem_a_reconciliacao_nao_se_faz_e_nada_se_abre(mundo) -> None:
    _abrir(mundo)
    mundo["listagem_falha"] = True
    depois = dt.datetime.now(UTC) + captura.CARENCIA_SEM_JOB + dt.timedelta(minutes=1)
    with pytest.raises(rec.RecoveryStopped, match="não se leu"):
        _recuperar(mundo, agora=depois)
    with pytest.raises(airbyte.AirbyteIndisponivel):
        _abrir(mundo)
    assert _tentativas(mundo) == 1


# ── A abertura, entre dois chamadores ────────────────────────────────────────
@pytest.mark.integracao
def test_a_segunda_abertura_espera_o_registro_da_primeira(mundo) -> None:
    """Pendente, depois final sem registro: recusada; publicado o registro, aberta."""
    primeira = _abrir(mundo)
    with pytest.raises(captura.AberturaRecusada, match=f"tentativa {primeira} ainda pending"):
        _abrir(mundo)
    captura.registrar_job(mundo["armazem"], primeira, 903)
    _job_no_airbyte(mundo, 903)
    _simular_job(mundo["armazem"], mundo["legado"], job_id=903, geracao=4)
    captura.concluir(mundo["legado"], mundo["armazem"], primeira)
    with pytest.raises(captura.AberturaRecusada, match=f"tentativa {primeira} sem registro"):
        _abrir(mundo)
    assert _tentativas(mundo) == 1
    ledger.gate(mundo["armazem"], primeira, caller={})
    assert _abrir(mundo) and _tentativas(mundo) == 2


@pytest.mark.integracao
def test_leitura_lenta_ou_que_falha_na_abertura_nao_abre_e_solta_o_lock(mundo, monkeypatch) -> None:
    def lenta(conexao):
        monkeypatch.setattr(rec, "STATEMENT_TIMEOUT_MS", 200)
        rec.read_warehouse(conexao)
        conexao.execute(text("select pg_sleep(2)"))
        return []

    with pytest.raises(Exception, match="statement timeout|canceling statement"):
        captura.iniciar(mundo["legado"], mundo["armazem"], CONEXAO, barreira=lenta)
    monkeypatch.setattr(rec, "STATEMENT_TIMEOUT_MS", 120_000)

    def falha(_conexao):
        raise RuntimeError("leitura falhou")

    with pytest.raises(RuntimeError, match="leitura falhou"):
        captura.iniciar(mundo["legado"], mundo["armazem"], CONEXAO, barreira=falha)
    assert _tentativas(mundo) == 0
    # O lock de abertura saiu com as transações: uma invocação nova lê de novo e abre.
    assert _abrir(mundo) and _tentativas(mundo) == 1


@pytest.mark.integracao
def test_um_id_repetido_na_abertura_falha_em_vez_de_sobrescrever(mundo) -> None:
    tentativa = _capturar(mundo, 901, 1)
    with pytest.raises(Exception, match="duplicate key|unique"):
        captura.iniciar(mundo["legado"], mundo["armazem"], CONEXAO, barreira=SEM_BARREIRA, tentativa=tentativa)
    assert _estado(mundo, tentativa) == {"complete"}


@pytest.mark.integracao
def test_uma_epoca_nova_parte_do_estado_de_agora(mundo) -> None:
    """H8: a época nova não herda o que a anterior esperava; a anterior fica como estava."""
    primeira = ledger.current_epoch(mundo["raiz"])
    tentativa = _capturar(mundo, 901, 1, registrar=False)
    captura.concluir(mundo["legado"], mundo["armazem"], tentativa)  # final sem registro: a época 1 para
    with pytest.raises(rec.RecoveryStopped):
        _recuperar(mundo)
    mundo["abrir_epoca"]()  # uma restauração abre a sua
    assert ledger.current_epoch(mundo["raiz"]) != primeira and primeira.exists()
    assert _recuperar(mundo)["recorded"] == [] and _abrir(mundo)


# ── A CLI, de verdade, contra os efêmeros ────────────────────────────────────
@pytest.mark.integracao
def test_a_cli_registra_a_transicao_antes_de_disparar(mundo, monkeypatch) -> None:
    pendente = _capturar(mundo, 901, 1, registrar=False)
    ledger.publish(ledger.current_epoch(mundo["raiz"]), f"dag_x_{pendente}_attempt.json",
                   ledger.attempt_record(mundo["armazem"], pendente, caller={"kind": "dag"}))
    monkeypatch.setenv("LEGACY_DB_NAME", mundo["legado"].url.database)
    monkeypatch.setenv("WAREHOUSE_DB_NAME", mundo["armazem"].url.database)
    monkeypatch.setattr(airbyte, "estado_do_job", lambda _jwt: mundo["job_state"])
    monkeypatch.setattr(rec, "airbyte_listing", lambda _jwt, _conexao: mundo["listar"]())
    disparos: list[list[str]] = []

    def disparar(_nome, _conexao, _jwt):
        disparos.append(_nomes(mundo))
        _job_no_airbyte(mundo, 904)
        _simular_job(mundo["armazem"], mundo["legado"], job_id=904, geracao=5)
        return {"jobId": 904}

    monkeypatch.setattr(airbyte, "disparar", disparar)
    monkeypatch.setattr(airbyte, "acompanhar", lambda job, _jwt: {"status": "succeeded", "jobId": job})
    job, certificado = airbyte.sincronizar_certificando("leg", CONEXAO, "jwt")
    assert disparos == [[f"dag_x_{pendente}_attempt.json", f"recovery_{pendente}_transition.json"]]
    assert job["jobId"] == 904 and certificado["status"] == "complete"
    assert f"cli_{certificado['capture_attempt_id']}_attempt.json" in _nomes(mundo)
    assert _recuperar(mundo)["transitions"] == {}  # tudo registrado: a próxima passa


@pytest.mark.integracao
def test_a_cli_que_para_na_recuperacao_nao_abre_nem_dispara(mundo, monkeypatch) -> None:
    _capturar(mundo, 901, 1, registrar=False, status="running")
    monkeypatch.setenv("LEGACY_DB_NAME", mundo["legado"].url.database)
    monkeypatch.setenv("WAREHOUSE_DB_NAME", mundo["armazem"].url.database)
    monkeypatch.setattr(airbyte, "estado_do_job", lambda _jwt: mundo["job_state"])
    monkeypatch.setattr(rec, "airbyte_listing", lambda _jwt, _conexao: mundo["listar"]())
    monkeypatch.setattr(airbyte, "disparar", lambda *_a: pytest.fail("disparou"))
    with pytest.raises(rec.RecoveryStopped):
        airbyte.sincronizar_certificando("leg", CONEXAO, "jwt")
    assert _tentativas(mundo) == 1
