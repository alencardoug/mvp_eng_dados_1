"""Os portões da captura do legado — H6 da regeneração da v1.1.0.

Toda tentativa que a CLI ou a DAG abre termina registrada pelo próprio
chamador no livro retido (`recovery/ledger.py`), antes de qualquer build:

* **a lógica do portão**, sem banco: o registro é tomado com o certificado como
  estiver, nunca substitui outro, e fora da primeira tentativa da tarefa nada
  se escreve (N31);
* **a CLI** registra antes de voltar, e falha quando não consegue;
* **a DAG**, por estrutura — o Airflow do `.venv` não importa o módulo dela (ver
  `test_identidade_captura.py`) —: o portão entre `concluir_captura_do_legado` e
  `dbt_seed`, rodando seja qual for o desfecho da conclusão;
* **a configuração**: a variável no `.env`, a montagem no Airflow e a macro que
  acrescenta a variável a um `.env` antigo, rodada de verdade;
* **o lock da tentativa**, contra o armazém: *advisory lock* não grava dado.
"""

from __future__ import annotations

import ast
import contextlib
import datetime as dt
import json
import os
import pathlib
import re
import subprocess

import pytest
import yaml

from mvp_ed1 import airbyte
from mvp_ed1.legacy import captura
from mvp_ed1.recovery import capture_recovery, ledger

RAIZ = pathlib.Path(__file__).resolve().parents[1]
DAG = RAIZ / "airflow" / "dags" / "fluxo_batch.py"
AGORA = dt.datetime(2026, 11, 4, 12, 0, tzinfo=dt.timezone.utc)


def _registro(status: str, job_id: int | None = 44) -> dict:
    return {
        "format": ledger.FORMAT, "kind": "attempt", "capture_attempt_id": "t1", "job_id": job_id,
        "certificate": {"rows": [{"source_table": "brands", "status": status}], "count": 1, "digest": "d"},
        "raw": None,
    }


@pytest.fixture
def livro(tmp_path, monkeypatch):
    """Um livro com uma época, e o banco trocado por dublês: o lock e a medida."""
    ledger.open_epoch(tmp_path, {"format": ledger.FORMAT, "kind": "baseline"}, agora=AGORA)
    monkeypatch.setenv(ledger.ENV, str(tmp_path))
    estado = {"registro": _registro("complete"), "locks": []}

    @contextlib.contextmanager
    def bloqueio(_armazem, tentativa, esperar=True):
        estado["locks"].append(("toma", tentativa))
        yield
        estado["locks"].append(("solta", tentativa))

    def medir(_armazem, tentativa, *, caller, agora=None):
        estado["locks_na_medida"] = list(estado["locks"])
        return {**estado["registro"], "capture_attempt_id": tentativa, "caller": dict(caller)}

    monkeypatch.setattr(captura, "bloqueio_da_tentativa", bloqueio)
    monkeypatch.setattr(ledger, "attempt_record", medir)
    estado["epoca"] = ledger.current_epoch(tmp_path)
    return estado


def _publicados(epoca: pathlib.Path) -> list[str]:
    return sorted(p.name for p in epoca.iterdir() if p.name != ledger.BASELINE)


# ── A lógica do portão ───────────────────────────────────────────────────────
@pytest.mark.parametrize("status", ["complete", "incomplete", "unstable", "inconsistent", "abandoned"])
def test_o_certificado_e_registrado_como_estiver(livro, status) -> None:
    livro["registro"] = _registro(status)
    publicado, registro = ledger.gate(None, "t1", caller={"kind": "dag"}, run_id="manual__x", try_number=1)
    gravado = json.loads(publicado.path.read_text())
    assert gravado["caller"] == {"kind": "dag", "run_id": "manual__x", "try_number": 1}
    assert ledger.certificate_status(gravado) == status
    assert _publicados(livro["epoca"]) == ["dag_manual__x_t1_attempt.json"]


def test_o_registro_e_tomado_e_publicado_segurando_o_lock_da_tentativa(livro) -> None:
    ledger.gate(None, "t1", caller={}, try_number=1)
    assert livro["locks_na_medida"] == [("toma", "t1")]
    assert livro["locks"] == [("toma", "t1"), ("solta", "t1")]


def test_pendente_com_job_final_e_registrado_como_pendente(livro) -> None:
    livro["registro"] = _registro("pending")
    publicado, _ = ledger.gate(None, "t1", caller={}, try_number=1, job_state=lambda _job: "failed")
    assert ledger.certificate_status(json.loads(publicado.path.read_text())) == "pending"


@pytest.mark.parametrize(
    ("job_id", "estado", "motivo"),
    [(None, None, "sem job"), (44, lambda _j: "running", "running"), (44, None, "sem observador")],
)
def test_pendente_sem_job_final_fica_para_a_recuperacao(livro, job_id, estado, motivo) -> None:
    livro["registro"] = _registro("pending", job_id)
    with pytest.raises(ledger.GateRefused, match=motivo):
        ledger.gate(None, "t1", caller={}, try_number=1, job_state=estado)
    assert _publicados(livro["epoca"]) == []


def test_o_portao_limpo_falha_na_segunda_tentativa_sem_tocar_o_primeiro_registro(livro) -> None:
    primeiro, _ = ledger.gate(None, "t1", caller={}, run_id="manual__x", try_number=1)
    antes = primeiro.path.read_bytes()
    livro["registro"] = _registro("unstable")
    with pytest.raises(ledger.GateRefused, match="proibido"):
        ledger.gate(None, "t1", caller={}, run_id="manual__x", try_number=2)
    assert primeiro.path.read_bytes() == antes
    assert "locks_na_medida" in livro and livro["locks"] == [("toma", "t1"), ("solta", "t1")]


def test_um_registro_existente_faz_o_portao_falhar(livro) -> None:
    primeiro, _ = ledger.gate(None, "t1", caller={}, run_id="manual__x", try_number=1)
    antes = primeiro.path.read_bytes()
    with pytest.raises(ledger.LedgerError, match="nunca é substituído"):
        ledger.gate(None, "t1", caller={}, run_id="manual__x", try_number=1)
    assert primeiro.path.read_bytes() == antes


def test_sem_tentativa_aberta_nada_se_registra(livro) -> None:
    with pytest.raises(ledger.GateRefused, match="nenhuma tentativa"):
        ledger.gate(None, None, caller={}, try_number=1)


@pytest.mark.parametrize("caso", ["sem_variavel", "vazia", "sem_epoca"])
def test_sem_livro_utilizavel_o_portao_falha_antes_de_medir(livro, monkeypatch, tmp_path_factory, caso) -> None:
    if caso == "sem_variavel":
        monkeypatch.delenv(ledger.ENV)
    elif caso == "vazia":
        monkeypatch.setenv(ledger.ENV, "")
    else:
        monkeypatch.setenv(ledger.ENV, str(tmp_path_factory.mktemp("sem_epoca")))
    with pytest.raises(ledger.LedgerError):
        ledger.gate(None, "t1", caller={}, try_number=1)
    assert "locks_na_medida" not in livro


@pytest.mark.skipif(os.geteuid() == 0, reason="root escreve em diretório sem permissão")
def test_uma_epoca_sem_escrita_faz_o_portao_falhar(livro) -> None:
    livro["epoca"].chmod(0o500)
    try:
        with pytest.raises(OSError):
            ledger.gate(None, "t1", caller={}, try_number=1)
    finally:
        livro["epoca"].chmod(0o700)
    assert _publicados(livro["epoca"]) == []


# ── A CLI ────────────────────────────────────────────────────────────────────
@pytest.fixture
def cli(livro, monkeypatch):
    """`sincronizar_certificando` sem Airbyte: o disparo, a espera e as fases são dublês."""
    eventos: list[str] = []
    monkeypatch.setattr(airbyte, "estado_do_job", lambda _jwt: (lambda _j: "succeeded"))
    monkeypatch.setattr(airbyte, "disparar", lambda *_a: eventos.append("disparo") or {"jobId": 44})
    monkeypatch.setattr(airbyte, "acompanhar", lambda job, _jwt: {"status": "succeeded", "jobId": job})
    monkeypatch.setattr(captura, "iniciar", lambda *_a, **k: eventos.append("iniciar") or k["tentativa"])
    monkeypatch.setattr(captura, "registrar_job", lambda *_a: eventos.append("registrar_job"))
    monkeypatch.setattr(captura, "conferir_antes_do_disparo", lambda *_a: eventos.append("conferir"))
    monkeypatch.setattr(capture_recovery, "recover",
                        lambda *_a, **_k: eventos.append("recuperacao") or {"published": []})
    # O id que a CLI sorteia para a tentativa, fixo para o nome do registro ser previsível.
    import types
    import uuid

    monkeypatch.setattr(uuid, "uuid4", lambda: types.SimpleNamespace(hex="t1"))

    def concluir(*_a):
        eventos.append("concluir")
        return {"status": "complete", "tabelas": {}, "capture_attempt_id": "t1", "snapshot_id": 44}

    monkeypatch.setattr(captura, "concluir", concluir)
    original = ledger.gate

    def portao(*a, **k):
        eventos.append("portao")
        return original(*a, **k)

    monkeypatch.setattr(ledger, "gate", portao)
    return {"eventos": eventos, **livro}


def test_a_cli_registra_a_propria_tentativa_antes_de_voltar(cli) -> None:
    job, certificado = airbyte.sincronizar_certificando("id", "legacy_para_raw_legacy", "jwt")
    assert cli["eventos"] == ["recuperacao", "iniciar", "conferir", "disparo", "registrar_job", "concluir", "portao"]
    # O lock da tentativa da CLI cobre da abertura ao registro; o portão não o toma de novo.
    assert cli["locks"] == [("toma", "t1"), ("solta", "t1")]
    assert _publicados(cli["epoca"]) == ["cli_t1_attempt.json"]
    assert json.loads((cli["epoca"] / "cli_t1_attempt.json").read_text())["caller"]["kind"] == "cli"
    assert certificado["status"] == "complete"


def test_a_cli_falha_quando_o_registro_nao_e_escrito(cli) -> None:
    ledger.publish(cli["epoca"], "cli_t1_attempt.json", {"kind": "attempt", "ocupado": True})
    with pytest.raises(ledger.LedgerError, match="nunca é substituído"):
        airbyte.sincronizar_certificando("id", "legacy_para_raw_legacy", "jwt")
    assert cli["eventos"][-1] == "portao"


def test_sem_epoca_a_cli_nem_abre_a_tentativa(cli, monkeypatch, tmp_path_factory) -> None:
    monkeypatch.setenv(ledger.ENV, str(tmp_path_factory.mktemp("sem_epoca")))
    with pytest.raises(ledger.LedgerError, match="nenhuma época"):
        airbyte.sincronizar_certificando("id", "legacy_para_raw_legacy", "jwt")
    assert cli["eventos"] == []


def test_a_fase_de_recuperacao_diz_quando_nada_esta_devido(cli, capsys) -> None:
    airbyte.sincronizar_certificando("id", "legacy_para_raw_legacy", "jwt")
    saida = capsys.readouterr().out
    assert "recuperação: nada devido" in saida
    assert "recuperação registrou" not in saida


def test_a_fase_de_recuperacao_lista_o_que_registrou(cli, monkeypatch, capsys) -> None:
    monkeypatch.setattr(capture_recovery, "recover", lambda *_a, **_k: {"published": ["epoca/x.json"]})
    airbyte.sincronizar_certificando("id", "legacy_para_raw_legacy", "jwt")
    saida = capsys.readouterr().out
    assert "recuperação registrou: epoca/x.json" in saida
    assert "nada devido" not in saida


# ── A DAG, por estrutura ─────────────────────────────────────────────────────
def _arvore() -> ast.Module:
    return ast.parse(DAG.read_text(encoding="utf-8"))


def _funcao(nome: str) -> ast.FunctionDef:
    return next(n for n in ast.walk(_arvore()) if isinstance(n, ast.FunctionDef) and n.name == nome)


def _arestas() -> set[tuple[str, str]]:
    """As arestas `a >> b` da DAG, pelos nomes das variáveis, com as listas abertas."""
    def nomes(no) -> list[str]:
        if isinstance(no, ast.Name):
            return [no.id]
        if isinstance(no, ast.List):
            return [e.id for e in no.elts if isinstance(e, ast.Name)]
        if isinstance(no, ast.BinOp) and isinstance(no.op, ast.RShift):
            return nomes(no.right)
        return []

    arestas = set()
    for no in ast.walk(_arvore()):
        if isinstance(no, ast.BinOp) and isinstance(no.op, ast.RShift):
            for a in nomes(no.left):
                for b in nomes(no.right if not isinstance(no.right, ast.BinOp) else no.right.left):
                    arestas.add((a, b))
    return arestas


def _variaveis() -> dict[str, str]:
    """Variável da DAG → a função de tarefa que a produz."""
    saida = {}
    for no in ast.walk(_funcao("fluxo_batch")):
        if isinstance(no, ast.Assign) and isinstance(no.targets[0], ast.Name) and isinstance(no.value, ast.Call):
            alvo = no.value.func
            while isinstance(alvo, (ast.Call, ast.Attribute)):
                alvo = alvo.func if isinstance(alvo, ast.Call) else alvo.value
            if isinstance(alvo, ast.Name):
                saida[no.targets[0].id] = alvo.id
    return saida


def test_o_portao_fica_entre_a_conclusao_e_o_primeiro_build() -> None:
    variaveis = _variaveis()
    assert variaveis["registro"] == "registrar_captura_do_legado"
    assert variaveis["captura_legada"] == "concluir_captura_do_legado"
    assert variaveis["semear"] == "camada"
    arestas = _arestas()
    assert ("captura_legada", "registro") in arestas
    assert {("captura_principal", "semear"), ("captura_legada", "semear"), ("registro", "semear")} <= arestas
    # Nenhum build antes do portão: o único caminho até as camadas passa por `semear`.
    assert not any(b == "registro" for a, b in arestas if a != "captura_legada")


def test_a_dag_tem_quinze_tarefas() -> None:
    tarefas = [n.name for n in _funcao("fluxo_batch").body if isinstance(n, ast.FunctionDef)]
    assert tarefas == ["sincronizar", "retomar_capturas_do_legado", "iniciar_captura_do_legado",
                       "concluir_captura_do_legado", "registrar_captura_do_legado", "camada"]
    camadas = [n for n in ast.walk(_funcao("fluxo_batch"))
               if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "camada"]
    # 2 sincronizações + recuperação + iniciar + concluir + portão + 9 camadas de dbt.
    assert 2 + 4 + len(camadas) == 15


def test_o_portao_roda_seja_qual_for_o_desfecho_da_conclusao() -> None:
    decorador = next(d for d in _funcao("registrar_captura_do_legado").decorator_list if isinstance(d, ast.Call))
    assert {k.arg: k.value.value for k in decorador.keywords} == {"trigger_rule": "all_done"}


def test_o_portao_publica_antes_de_falhar_pelo_certificado() -> None:
    corpo = ast.unparse(_funcao("registrar_captura_do_legado"))
    assert corpo.index("ledger.gate(") < corpo.index("raise RuntimeError")
    assert "try_number=ti.try_number" in corpo and "run_id=contexto['run_id']" in corpo


def test_a_fase_1_da_dag_confere_a_epoca_antes_de_abrir_a_tentativa() -> None:
    corpo = ast.unparse(_funcao("iniciar_captura_do_legado"))
    assert corpo.index("ledger.writable_epoch()") < corpo.index("captura.iniciar(")


def test_a_recuperacao_vem_antes_da_fase_1() -> None:
    assert _variaveis()["recuperacao"] == "retomar_capturas_do_legado"
    assert ("recuperacao", "tentativa") in _arestas()
    assert "capture_recovery.recover(" in ast.unparse(_funcao("retomar_capturas_do_legado"))


def test_a_fase_1_abre_sob_a_barreira_segurando_o_lock_da_tentativa() -> None:
    corpo = ast.unparse(_funcao("iniciar_captura_do_legado"))
    assert corpo.index("captura.bloqueio_da_tentativa(armazem, tentativa)") < corpo.index("captura.iniciar(")
    assert "barreira=capture_recovery.opening_barrier(" in corpo and "tentativa=tentativa" in corpo


def test_a_sincronizacao_do_legado_confere_e_associa_segurando_o_lock() -> None:
    """RR-39: o lock antes de tudo; a conferência antes do POST; o job associado ainda dentro."""
    corpo = ast.unparse(_funcao("sincronizar"))
    lock = corpo.index("captura.bloqueio_da_tentativa(armazem, tentativa)")
    dentro = corpo.index("with bloqueio:")
    assert lock < dentro < corpo.index("airbyte.token()") < corpo.index("captura.conferir_antes_do_disparo(")
    assert corpo.index("captura.conferir_antes_do_disparo(") < corpo.index("airbyte.disparar(")
    assert corpo.index("airbyte.disparar(") < corpo.index("captura.registrar_job(") < corpo.index("airbyte.acompanhar(")
    # A espera pelo job fica fora do lock.
    bloco = next(n for n in ast.walk(_funcao("sincronizar")) if isinstance(n, ast.With))
    assert "acompanhar" not in ast.unparse(bloco)


# ── A configuração ───────────────────────────────────────────────────────────
def _makefile() -> str:
    return (RAIZ / "Makefile").read_text(encoding="utf-8")


def test_quem_captura_ou_sobe_o_airflow_garante_o_livro_antes() -> None:
    from test_makefile import _receitas

    receitas = _receitas(_makefile())
    assert receitas["sync-legacy"][0] == "$(GARANTIR_LIVRO_NO_ENV)"
    sobe = next(i for i, l in enumerate(receitas["airflow-up"]) if "$(COMPOSE_AIRFLOW) up" in l)
    assert "$(GARANTIR_LIVRO_NO_ENV)" in receitas["airflow-up"][:sobe]
    assert any("LEGACY_LEDGER_DIR=" in l for l in receitas["env"])


def test_o_airflow_monta_o_livro_e_nao_sobe_sem_ele() -> None:
    texto = (RAIZ / "docker" / "docker-compose.airflow.yml").read_text(encoding="utf-8")
    comum = yaml.safe_load(texto)["x-airflow-comum"]
    assert comum["environment"]["LEGACY_LEDGER_DIR"] == "/opt/mvp_ed1_ledger"
    montagem = next(v for v in comum["volumes"] if v.endswith(":/opt/mvp_ed1_ledger"))
    assert montagem.startswith("${LEGACY_LEDGER_DIR:?")
    assert not montagem.endswith(":ro")


def _rodar_macro(tmp_path: pathlib.Path, env: str) -> subprocess.CompletedProcess[str]:
    """A macro do `Makefile` real, copiada para um `Makefile` de rascunho e rodada."""
    definicao = re.search(r"^GARANTIR_LIVRO_NO_ENV = .*?\n\n", _makefile(), re.S | re.M).group(0)
    (tmp_path / "Makefile").write_text(definicao + "t:\n\t@$(GARANTIR_LIVRO_NO_ENV)\n", encoding="utf-8")
    (tmp_path / ".env").write_text(env, encoding="utf-8")
    return subprocess.run(["make", "-s", "t"], cwd=tmp_path, capture_output=True, text=True, check=False)


def test_um_env_antigo_ganha_a_raiz_e_o_diretorio(tmp_path) -> None:
    r = _rodar_macro(tmp_path, "WAREHOUSE_DB_PORT=5434\n")
    assert r.returncode == 0, r.stderr
    linhas = (tmp_path / ".env").read_text().splitlines()
    assert f"LEGACY_LEDGER_DIR={tmp_path}/data/memoria_do_legado" in linhas
    assert (tmp_path / "data" / "memoria_do_legado").is_dir()
    # Rodar de novo não acrescenta outra vez.
    assert _rodar_macro(tmp_path, (tmp_path / ".env").read_text()).returncode == 0
    assert (tmp_path / ".env").read_text().count("LEGACY_LEDGER_DIR=") == 1


def test_uma_raiz_vazia_faz_a_macro_falhar(tmp_path) -> None:
    assert _rodar_macro(tmp_path, "LEGACY_LEDGER_DIR=\n").returncode != 0


def test_a_raiz_ja_declarada_e_respeitada(tmp_path) -> None:
    destino = tmp_path / "outro"
    r = _rodar_macro(tmp_path, f"LEGACY_LEDGER_DIR={destino}\n")
    assert r.returncode == 0, r.stderr
    assert destino.is_dir() and not (tmp_path / "data").exists()


# ── O lock da tentativa, contra o armazém ────────────────────────────────────
@pytest.fixture(scope="module")
def armazem():
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    from sqlalchemy import create_engine, text

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
def test_o_lock_da_tentativa_e_de_um_processo_so_e_sai_com_ele(armazem) -> None:
    tentativa = f"teste-lock-{os.getpid()}"
    with captura.bloqueio_da_tentativa(armazem, tentativa):
        with pytest.raises(captura.TentativaOcupada):
            with captura.bloqueio_da_tentativa(armazem, tentativa, esperar=False):
                pass
        # Outra tentativa não é afetada.
        with captura.bloqueio_da_tentativa(armazem, tentativa + "-outra", esperar=False):
            pass
    # Solto o primeiro, o lock volta a estar livre — nenhum ficou preso a uma conexão do pool.
    with captura.bloqueio_da_tentativa(armazem, tentativa, esperar=False):
        pass
