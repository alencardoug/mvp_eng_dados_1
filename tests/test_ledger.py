"""O livro retido da memória do legado (T4) e as épocas dele (H8).

A raiz, as épocas e a publicação sem substituição se testam sem banco; as
medidas, contra o armazém, em sessão somente leitura.
"""

from __future__ import annotations

import datetime as dt
import json
import os

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.recovery import ledger

AGORA = dt.datetime(2026, 11, 4, 12, 0, tzinfo=dt.timezone.utc)


def _baseline(**extra) -> dict:
    return {"format": ledger.FORMAT, "kind": "baseline", "taken_at": AGORA.isoformat(), **extra}


# ── A raiz ───────────────────────────────────────────────────────────────────
@pytest.mark.parametrize("valor", [None, "", "   "])
def test_sem_variavel_nao_ha_livro(valor) -> None:
    ambiente = {} if valor is None else {ledger.ENV: valor}
    with pytest.raises(ledger.LedgerError, match="ausente ou vazia"):
        ledger.root(ambiente)


def test_a_raiz_precisa_ser_um_diretorio(tmp_path) -> None:
    with pytest.raises(ledger.LedgerError, match="não é um diretório"):
        ledger.root({ledger.ENV: str(tmp_path / "nao_existe")})
    assert ledger.root({ledger.ENV: str(tmp_path)}) == tmp_path


# ── Épocas ───────────────────────────────────────────────────────────────────
def test_sem_epoca_nao_ha_epoca_corrente(tmp_path) -> None:
    with pytest.raises(ledger.LedgerError, match="nenhuma época"):
        ledger.current_epoch(tmp_path)


def test_a_epoca_corrente_e_a_mais_nova_com_linha_de_base(tmp_path) -> None:
    primeira = ledger.open_epoch(tmp_path, _baseline(n=1), agora=AGORA).path.parent
    segunda = ledger.open_epoch(tmp_path, _baseline(n=2), agora=AGORA).path.parent
    assert [p.name for p in ledger.epochs(tmp_path)] == [primeira.name, segunda.name]
    assert primeira.name.startswith("epoch_0001_") and segunda.name.startswith("epoch_0002_")
    assert ledger.current_epoch(tmp_path) == segunda
    # A anterior fica como estava.
    assert json.loads((primeira / ledger.BASELINE).read_text())["n"] == 1


def test_uma_epoca_sem_linha_de_base_valida_e_pulada(tmp_path) -> None:
    valida = ledger.open_epoch(tmp_path, _baseline(), agora=AGORA).path.parent
    # Uma abertura interrompida antes da linha de base, e uma com linha de base de outra forma.
    (tmp_path / "epoch_0002_20261104T120000Z").mkdir()
    quebrada = tmp_path / "epoch_0003_20261104T120000Z"
    quebrada.mkdir()
    (quebrada / ledger.BASELINE).write_text(json.dumps({"kind": "baseline", "format": 999}))
    assert ledger.current_epoch(tmp_path) == valida
    # A próxima abertura não reusa número.
    assert ledger.open_epoch(tmp_path, _baseline(), agora=AGORA).path.parent.name.startswith("epoch_0004_")


def test_so_linha_de_base_abre_epoca(tmp_path) -> None:
    with pytest.raises(ledger.LedgerError, match="só uma linha de base"):
        ledger.open_epoch(tmp_path, {"format": ledger.FORMAT, "kind": "attempt"})
    assert ledger.epochs(tmp_path) == []


# ── Publicação ───────────────────────────────────────────────────────────────
def test_um_registro_nunca_e_substituido(tmp_path) -> None:
    epoca = ledger.open_epoch(tmp_path, _baseline(), agora=AGORA).path.parent
    publicado = ledger.publish(epoca, "cli_abc_attempt.json", {"kind": "attempt", "v": 1})
    with pytest.raises(ledger.LedgerError, match="nunca é substituído"):
        ledger.publish(epoca, "cli_abc_attempt.json", {"kind": "attempt", "v": 2})
    assert json.loads(publicado.path.read_text())["v"] == 1
    assert publicado.sha256 == __import__("hashlib").sha256(publicado.path.read_bytes()).hexdigest()
    # Nenhum temporário fica para trás, nem do que falhou.
    assert [p.name for p in epoca.iterdir() if p.name.startswith(".")] == []


def test_os_registros_se_leem_pelo_conteudo(tmp_path) -> None:
    epoca = ledger.open_epoch(tmp_path, _baseline(), agora=AGORA).path.parent
    ledger.publish(epoca, "x.json", {"kind": "attempt", "capture_attempt_id": "a1"})
    (epoca / ".restos.tmp").write_text("{}")
    assert sorted(r["kind"] for r in ledger.records(epoca)) == ["attempt", "baseline"]


@pytest.mark.parametrize("nome", ["../fora.json", ".escondido.json", "a/b.json"])
def test_nome_de_registro_invalido_e_recusado(tmp_path, nome) -> None:
    with pytest.raises(ledger.LedgerError, match="nome de registro inválido"):
        ledger.publish(tmp_path, nome, {})


@pytest.mark.parametrize("nome", ["D2_a1_memoria", "registro.txt", "registro.json.bak"])
def test_nome_que_a_leitura_ignoraria_e_recusado(tmp_path, nome) -> None:
    """RVL1-07: `records` só lê `.json`, e a publicação devolvia sucesso fora da leitura."""
    epoca = ledger.open_epoch(tmp_path, _baseline(), agora=AGORA).path.parent
    with pytest.raises(ledger.LedgerError, match="sem .json"):
        ledger.publish(epoca, nome, {"kind": "attempt", "capture_attempt_id": "perdida"})
    assert [p.name for p in epoca.iterdir()] == ["baseline.json"]


def _dubles_do_portao(monkeypatch, medir):
    from contextlib import nullcontext

    from mvp_ed1.legacy import captura

    monkeypatch.setattr(ledger, "attempt_record", medir)
    monkeypatch.setattr(captura, "bloqueio_da_tentativa", lambda *a, **k: nullcontext())


def test_registro_manual_nao_reabre_tentativa_que_a_epoca_guarda(tmp_path, monkeypatch) -> None:
    """RVL1-06: um segundo nome publicava um segundo primeiro registro da mesma tentativa."""
    ledger.open_epoch(tmp_path, _baseline(), agora=AGORA)
    registro = {"format": 1, "kind": "attempt", "capture_attempt_id": "a", "certificate": {"rows": []}}
    _dubles_do_portao(monkeypatch, lambda *a, **k: registro)
    ambiente = {ledger.ENV: str(tmp_path)}
    ledger.operator_record(None, "a", "D2_a1_memoria.json", environ=ambiente)
    with pytest.raises(ledger.LedgerError, match="já guarda a tentativa a"):
        ledger.operator_record(None, "a", "D2_a2_memoria.json", environ=ambiente)
    ledger.operator_record(None, "b", "D2_b1_memoria.json", environ=ambiente)  # outra tentativa, sim


def test_o_portao_mede_o_bruto_depois_de_o_job_estar_final(tmp_path, monkeypatch) -> None:
    """RVL1-08: o retrato da primeira leitura podia ser de um job que terminou entre ela e a consulta."""
    ledger.open_epoch(tmp_path, _baseline(), agora=AGORA)
    estado = {"linhas": 1, "status": "running"}

    def medir(*a, **k):
        return {"kind": "attempt", "capture_attempt_id": "a", "job_id": 9,
                "certificate": {"rows": [{"status": "pending"}]}, "raw": {"brands": {"rows": estado["linhas"]}}}

    def final(_job):
        estado.update(linhas=2, status="succeeded")   # a última escrita do job, depois da 1ª leitura
        return estado["status"]

    _dubles_do_portao(monkeypatch, medir)
    _, registro = ledger.gate(None, "a", caller={}, job_state=final, environ={ledger.ENV: str(tmp_path)})
    assert registro["raw"]["brands"]["rows"] == 2


@pytest.mark.skipif(os.geteuid() == 0, reason="root escreve em diretório sem permissão")
def test_um_diretorio_sem_escrita_falha_na_prova_e_na_publicacao(tmp_path) -> None:
    epoca = ledger.open_epoch(tmp_path, _baseline(), agora=AGORA).path.parent
    epoca.chmod(0o500)
    try:
        with pytest.raises(OSError):
            ledger.probe_writable(epoca)
        with pytest.raises(OSError):
            ledger.publish(epoca, "x.json", {})
    finally:
        epoca.chmod(0o700)
    ledger.probe_writable(epoca)


def test_o_nome_do_registro_de_portao_e_pela_execucao_e_pela_tentativa() -> None:
    assert ledger.gate_record_name("ab12", run_id="manual__2026-11-04T12:00:00+00:00") == (
        "dag_manual__2026-11-04T12_00_00+00_00_ab12_attempt.json"
    )
    assert ledger.gate_record_name("ab12") == "cli_ab12_attempt.json"


def test_os_jobs_da_conexao_legada_saem_da_listagem() -> None:
    listagem = [
        {"jobId": 7, "connectionId": "leg", "jobType": "sync", "status": "succeeded", "startTime": "t7"},
        {"jobId": 8, "connectionId": "oltp", "jobType": "sync", "status": "running", "startTime": "t8"},
    ]
    assert ledger.legacy_jobs(listagem, "leg") == [
        {"id": 7, "type": "sync", "status": "succeeded", "started_at": "t7"}
    ]


# ── Medidas, contra o armazém ────────────────────────────────────────────────
@pytest.fixture(scope="module")
def armazem():
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    from mvp_ed1.db import WAREHOUSE, database_url

    motor = create_engine(database_url(WAREHOUSE))
    try:
        with motor.connect() as conexao:
            conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover — depende do ambiente
        motor.dispose()
        pytest.skip(f"PostgreSQL indisponível: {erro}")
    yield motor
    motor.dispose()


@pytest.mark.integracao
def test_o_registro_de_uma_tentativa_certificada_mede_o_que_o_certificado_recebeu(armazem) -> None:
    """Independente do certificado: as linhas do job contadas de novo dão o `received_rows` dele."""
    with armazem.connect() as conexao:
        tentativa = conexao.execute(text(
            f"select capture_attempt_id from {ledger.CERTIFICATE} where status = 'complete' "
            "group by 1 order by max(completed_at) desc limit 1"
        )).scalar()
        recebidas = dict(conexao.execute(text(
            f"select source_table, received_rows from {ledger.CERTIFICATE} where capture_attempt_id = :a"
        ), {"a": tentativa}).all())
    if tentativa is None:
        pytest.skip("nenhuma captura certificada no armazém")
    registro = ledger.attempt_record(armazem, tentativa, caller={"kind": "test"}, agora=AGORA)
    assert registro["kind"] == "attempt" and registro["job_id"] is not None
    assert registro["certificate"]["count"] == len(recebidas) == 40
    assert {t: m["rows"] for t, m in registro["raw"].items()} == recebidas
    # Uma geração por tabela que recebeu linhas, e a forma canônica guardada por inteiro.
    assert all(len(m["generations"]) == 1 for m in registro["raw"].values() if m["rows"])
    assert {linha["status"] for linha in registro["certificate"]["rows"]} == {"complete"}
    # O registro é publicável como está.
    json.dumps(registro)


@pytest.mark.integracao
def test_tentativa_que_nao_existe_e_recusada(armazem) -> None:
    with pytest.raises(ledger.LedgerError, match="não existe"):
        ledger.attempt_record(armazem, "nao-existe", caller={})


# ── A linha de comando do operador ───────────────────────────────────────────
@pytest.fixture
def linha_de_base_sem_banco(tmp_path, monkeypatch):
    from mvp_ed1 import airbyte

    monkeypatch.setenv(ledger.ENV, str(tmp_path))
    monkeypatch.setattr(airbyte, "token", lambda: "jwt")
    monkeypatch.setattr(airbyte, "conexao", lambda _nome, _jwt: "leg")
    monkeypatch.setattr(ledger, "baseline_record", lambda _engine, jobs: {
        "format": ledger.FORMAT, "kind": "baseline", "captures": {}, "certificate": {"count": 0},
        "airbyte_jobs": list(jobs),
    })
    listagem = {"data": [
        {"jobId": 3, "connectionId": "leg", "jobType": "sync", "status": "succeeded", "startTime": "t3"},
        {"jobId": 4, "connectionId": "oltp", "jobType": "sync", "status": "succeeded", "startTime": "t4"},
    ]}
    monkeypatch.setattr(airbyte, "jobs", lambda _jwt, _limite: listagem)
    return tmp_path, listagem


def test_a_linha_de_base_abre_a_epoca_com_os_jobs_da_conexao_legada(linha_de_base_sem_banco) -> None:
    raiz, _ = linha_de_base_sem_banco
    assert ledger.main(["baseline"]) == 0
    epoca = ledger.current_epoch(raiz)
    assert json.loads((epoca / ledger.BASELINE).read_text())["airbyte_jobs"] == [
        {"id": 3, "type": "sync", "status": "succeeded", "started_at": "t3"}
    ]


def test_uma_listagem_cheia_recusa_sem_abrir_epoca(linha_de_base_sem_banco) -> None:
    raiz, listagem = linha_de_base_sem_banco
    listagem["data"] = [{"jobId": i, "connectionId": "leg"} for i in range(ledger.JOBS_LISTED)]
    assert ledger.main(["baseline"]) == 2
    assert ledger.epochs(raiz) == []


def test_a_linha_de_base_pede_a_janela_parada() -> None:
    from test_makefile import RAIZ, _receitas

    receitas = _receitas((RAIZ / "Makefile").read_text(encoding="utf-8"))["ledger-baseline"]
    janela = next(i for i, l in enumerate(receitas) if "preflight.sh trabalho" in l)
    assert janela < receitas.index("$(LIVRO_LINHA_DE_BASE)")


def test_a_restauracao_abre_a_sua_epoca_depois_da_conferencia_e_antes_da_captura() -> None:
    """H8: depois do conteúdo conferido contra o manifesto e do Airbyte de pé, antes do `sync-legacy`."""
    from test_makefile import RAIZ, _receitas

    texto = (RAIZ / "Makefile").read_text(encoding="utf-8")
    passos = _receitas(texto)["recovery-restore"]

    def onde(trecho: str) -> int:
        return next(i for i, l in enumerate(passos) if trecho in l)

    epoca = passos.index("$(LIVRO_LINHA_DE_BASE)")
    assert onde("CONTRA_O_BANCO=1") < onde("airbyte-up") < onde("recovery-airbyte-jobs") < epoca
    assert passos[epoca - 1] == "$(GARANTIR_LIVRO_NO_ENV)"
    assert epoca < onde("sync-legacy") < onde("dbt-rebuild")
    assert "mvp_ed1.recovery.ledger baseline" in next(l for l in texto.splitlines() if l.startswith("LIVRO_LINHA_DE_BASE ="))


@pytest.mark.integracao
def test_o_registro_de_tratamento_da_a_fatia_da_quarentena(armazem) -> None:
    """Independente da classificação: as rejeitadas da fatia corrente somam o que a quarentena tem nela."""
    from mvp_ed1.recovery import leitura

    registro = ledger.treatment_record(armazem, caller={"kind": "test"}, agora=AGORA)
    assert registro["kind"] == ledger.TREATMENT and registro["treatments"]
    quarentena = leitura.oraculo_da_quarentena(armazem)
    for fatia, tabelas in registro["rejected"].items():
        assert sum(t["rows"] for t in tabelas.values()) == quarentena[fatia]["linhas"], fatia
    assert sum(t["rows"] for f in registro["rejected"].values() for t in f.values()) > 0
    json.dumps(registro)
