"""O certificado de captura do legado (ADR-0044): regra pura, duas fases e o que já está retido.

Três níveis, porque cada um responde a uma pergunta diferente:

* **a regra** (`decidir`) — sem banco, com medidas fictícias: é onde os casos
  que contagem não vê ficam explícitos — alteração sem mudança de contagem,
  duplicata compensando perda, linhas de outro job na geração;
* **as duas fases** — em bancos efêmeros criados ao lado dos de trabalho:
  `iniciar` grava o "antes", `registrar_job` grava o job, `concluir` decide;
  reenviar é idempotente; a tentativa que ficou pendente é recuperada com o
  "antes" gravado ou abandonada. Nada disto toca `governance` do armazém real;
* **o retido** — somente leitura sobre o armazém de trabalho: a geração 16 do
  job 26 é `complete` nas 40 tabelas contra o `legacy_db` de hoje (o mesmo
  lote), e a geração 15 do job 25 é `incomplete` — `brands` não veio. É a
  contraprova que o revisor apontou, medida em vez de anunciada.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import uuid

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

from mvp_ed1 import governance
from mvp_ed1.db import LEGACY, WAREHOUSE, database_url
from mvp_ed1.legacy import captura, schema

M, R = captura.Medida, captura.Recebido


# ── A regra ──────────────────────────────────────────────────────────────────

@pytest.mark.parametrize(
    "antes,depois,recebido,esperado",
    [
        (M(3, "h"), M(3, "h"), R(3, "h", (7,), 0), captura.COMPLETE),
        (M(0, "vazio"), M(0, "vazio"), R(0, "vazio", (), 0), captura.COMPLETE),  # legitimamente vazia
        (M(3, "h"), M(3, "h2"), R(3, "h2", (7,), 0), captura.UNSTABLE),         # origem mudou; contagem igual
        (M(3, "h"), M(3, "h"), R(3, "h3", (7,), 0), captura.INCOMPLETE),         # duplicata compensando perda
        (M(3, "h"), M(3, "h"), R(2, "h4", (7,), 0), captura.INCOMPLETE),         # linha faltando
        (M(3, "h"), M(3, "h"), R(3, "h", (7,), 1), captura.INCONSISTENT),        # intrusa de outro job
        (M(3, "h"), M(3, "h"), R(3, "h", (7, 8), 0), captura.INCONSISTENT),      # job em duas gerações
        (M(3, "h"), M(4, "h5"), R(3, "h", (7,), 1), captura.INCONSISTENT),       # inconsistente vence instável
    ],
)
def test_decidir_na_ordem_de_gravidade(antes, depois, recebido, esperado) -> None:
    assert captura.decidir(antes, depois, recebido) == esperado


# ── As duas fases, em bancos efêmeros ────────────────────────────────────────

pytestmark_integracao = pytest.mark.integracao


def _engine(prefixo: str, nome: str):
    anterior = os.environ[f"{prefixo}_NAME"]
    os.environ[f"{prefixo}_NAME"] = nome
    try:
        return create_engine(database_url(prefixo))
    finally:
        os.environ[f"{prefixo}_NAME"] = anterior


@pytest.fixture(scope="module")
def administradores():
    if not os.environ.get("LEGACY_DB_PASSWORD") or not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    legado = create_engine(database_url(LEGACY), isolation_level="AUTOCOMMIT")
    armazem = create_engine(database_url(WAREHOUSE), isolation_level="AUTOCOMMIT")
    try:
        for motor in (legado, armazem):
            with motor.connect() as conexao:
                conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover
        pytest.skip(f"bancos indisponíveis: {erro}")
    yield legado, armazem
    legado.dispose()
    armazem.dispose()


@pytest.fixture
def efemeros(administradores):
    """Um `legacy_db` migrado e um armazém só com `raw_legacy` vazio, ambos efêmeros."""
    adm_legado, adm_armazem = administradores
    sufixo = uuid.uuid4().hex[:8]
    nome_legado, nome_armazem = f"legacy_teste_captura_{sufixo}", f"warehouse_teste_captura_{sufixo}"
    with adm_legado.connect() as conexao:
        conexao.execute(text(f'create database "{nome_legado}"'))
    with adm_armazem.connect() as conexao:
        conexao.execute(text(f'create database "{nome_armazem}"'))

    anterior = os.environ["LEGACY_DB_NAME"]
    os.environ["LEGACY_DB_NAME"] = nome_legado
    try:
        command.upgrade(Config("alembic.ini", ini_section="legacy"), "head")
    finally:
        os.environ["LEGACY_DB_NAME"] = anterior
    legado = _engine(LEGACY, nome_legado)
    armazem = _engine(WAREHOUSE, nome_armazem)
    with armazem.begin() as conexao:
        conexao.execute(text("create schema raw_legacy"))
        for tabela in schema.tabelas():
            colunas = ", ".join(f'"{c}" varchar' for c in schema.colunas(tabela))
            conexao.execute(
                text(
                    f'create table raw_legacy."{tabela}" (_airbyte_raw_id varchar, '
                    "_airbyte_extracted_at timestamptz default now(), _airbyte_meta jsonb, "
                    f"_airbyte_generation_id bigint, {colunas}, legacy_row_id bigint)"
                )
            )
    yield legado, armazem
    legado.dispose()
    armazem.dispose()
    with adm_legado.connect() as conexao:
        conexao.execute(text(f'drop database if exists "{nome_legado}" with (force)'))
    with adm_armazem.connect() as conexao:
        conexao.execute(text(f'drop database if exists "{nome_armazem}" with (force)'))


def _semear_origem(legado) -> None:
    with legado.begin() as conexao:
        conexao.execute(text("insert into legacy.brands (id, code, name) values ('1','b1','Acme'), ('2','b2','')"))
        conexao.execute(text("insert into legacy.warehouses (id, code, name) values ('1','w1','Central')"))


def _simular_job(armazem, legado, job_id: int, geracao: int, *, tabelas=None) -> None:
    """Copia a origem para o bruto como o Airbyte faria: `''` vira nulo, `sync_id` = job."""
    with legado.connect() as origem, armazem.begin() as destino:
        for tabela in tabelas or schema.tabelas():
            colunas = list(schema.colunas(tabela))
            linhas = origem.execute(
                text(f'select legacy_row_id, {", ".join(colunas)} from legacy."{tabela}" order by legacy_row_id')
            ).all()
            for linha in linhas:
                valores = {c: (None if v == "" else v) for c, v in zip(colunas, linha[1:])}
                nomes = ", ".join(f'"{c}"' for c in colunas)
                marcadores = ", ".join(f":{c}" for c in colunas)
                destino.execute(
                    text(
                        f'insert into raw_legacy."{tabela}" (_airbyte_raw_id, _airbyte_meta, '
                        f"_airbyte_generation_id, legacy_row_id, {nomes}) values "
                        f"(:raw, cast(:meta as jsonb), :g, :rid, {marcadores})"
                    ),
                    {"raw": uuid.uuid4().hex, "meta": json.dumps({"sync_id": job_id, "changes": []}),
                     "g": geracao, "rid": linha[0], **valores},
                )


@pytest.mark.integracao
def test_governance_e_idempotente_e_versionado(efemeros) -> None:
    _, armazem = efemeros
    todas = [nome for nome, _ in governance.MIGRACOES]
    assert governance.garantir(armazem) == todas
    assert governance.garantir(armazem) == []
    assert governance.versoes(armazem) == todas


@pytest.mark.integracao
def test_duas_fases_certificam_uma_captura_integra_e_sao_idempotentes(efemeros) -> None:
    legado, armazem = efemeros
    _semear_origem(legado)
    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 901)
    _simular_job(armazem, legado, job_id=901, geracao=1)

    primeira = captura.concluir(legado, armazem, tentativa)
    assert (primeira["status"], primeira["snapshot_id"], primeira["job_id"]) == (captura.COMPLETE, 901, 901)
    assert set(primeira["tabelas"].values()) == {captura.COMPLETE}, "tabelas vazias dos dois lados são completas"
    assert captura.certificadas(armazem) == [901]

    segunda = captura.concluir(legado, armazem, tentativa)  # reenvio da fase 2
    assert segunda == primeira
    with armazem.connect() as conexao:
        linhas = conexao.execute(
            text(f"select count(*), count(distinct status) from {captura.TABELA} where capture_attempt_id = :a"),
            {"a": tentativa},
        ).one()
    assert linhas == (40, 1), "uma linha por tabela, mesmo depois do reenvio"


@pytest.mark.integracao
def test_conteudo_alterado_sem_mudar_contagem_e_instavel_e_perda_compensada_e_incompleta(efemeros) -> None:
    legado, armazem = efemeros
    _semear_origem(legado)

    # (c) a origem muda entre a fase 1 e o fim do job: mesma contagem, outro conteúdo.
    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 902)
    _simular_job(armazem, legado, job_id=902, geracao=2)
    with legado.begin() as conexao:
        conexao.execute(text("update legacy.brands set name = 'Acme S.A.' where id = '1'"))
    instavel = captura.concluir(legado, armazem, tentativa)
    assert instavel["status"] == captura.UNSTABLE and instavel["tabelas"]["brands"] == captura.UNSTABLE
    assert instavel["snapshot_id"] is None

    # (d) o bruto recebe a mesma contagem, mas uma linha duplicada no lugar de outra.
    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 903)
    _simular_job(armazem, legado, job_id=903, geracao=3)
    with armazem.begin() as conexao:
        conexao.execute(
            text("update raw_legacy.brands set legacy_row_id = 1, id = '1', code = 'b1', name = 'Acme S.A.' "
                 "where _airbyte_generation_id = 3 and legacy_row_id = 2")
        )
    compensada = captura.concluir(legado, armazem, tentativa)
    assert compensada["tabelas"]["brands"] == captura.INCOMPLETE
    assert compensada["status"] == captura.INCOMPLETE
    assert captura.certificadas(armazem) == []


@pytest.mark.integracao
def test_tabela_ausente_e_incompleta_e_linha_de_outro_job_e_inconsistente(efemeros) -> None:
    legado, armazem = efemeros
    _semear_origem(legado)
    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 904)
    _simular_job(armazem, legado, job_id=904, geracao=4, tabelas=[t for t in schema.tabelas() if t != "brands"])
    faltando = captura.concluir(legado, armazem, tentativa)
    assert faltando["tabelas"]["brands"] == captura.INCOMPLETE and faltando["tabelas"]["warehouses"] == captura.COMPLETE

    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 905)
    _simular_job(armazem, legado, job_id=905, geracao=5)
    with armazem.begin() as conexao:
        conexao.execute(
            text("insert into raw_legacy.brands (_airbyte_raw_id, _airbyte_meta, _airbyte_generation_id, legacy_row_id, id) "
                 "values ('x', '{\"sync_id\": 999}', 5, 3, '3')")
        )
    intrusa = captura.concluir(legado, armazem, tentativa)
    assert intrusa["tabelas"]["brands"] == captura.INCONSISTENT and intrusa["status"] == captura.INCONSISTENT


def _estados(armazem) -> dict[str, str]:
    with armazem.connect() as conexao:
        return dict(
            conexao.execute(
                text(f"select capture_attempt_id, min(status) from {captura.TABELA} group by 1")
            ).all()
        )


@pytest.mark.integracao
def test_tentativa_pendente_e_recuperada_com_o_antes_gravado_ou_abandonada(efemeros) -> None:
    legado, armazem = efemeros
    _semear_origem(legado)

    # Falha entre a sincronização e a fase 2: o job existe e terminou, a fase 2 não rodou.
    interrompida = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, interrompida, 906)
    _simular_job(armazem, legado, job_id=906, geracao=6)
    # Falha antes de o job nascer: não há o que certificar.
    sem_job = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")

    # A próxima fase 1 resolve as duas antes de abrir a sua — a que tem job só
    # porque o Airbyte diz que ele terminou; a sem job só porque a carência passou.
    depois_da_carencia = dt.datetime.now(dt.timezone.utc) + captura.CARENCIA_SEM_JOB
    nova = captura.iniciar(
        legado, armazem, "legacy_para_raw_legacy",
        estado_do_job=lambda job_id: "succeeded", agora=depois_da_carencia,
    )
    estados = _estados(armazem)
    assert estados[interrompida] == captura.COMPLETE, "recuperada a partir do antes gravado"
    assert estados[sem_job] == captura.ABANDONED
    assert estados[nova] == captura.PENDING
    assert captura.certificadas(armazem) == [906]


@pytest.mark.integracao
def test_a_retomada_nao_fecha_tentativa_com_job_em_curso_nem_sem_job_dentro_da_carencia(efemeros) -> None:
    """RV10-03: retomar durante a sincronização deixava o bruto parcial como `incomplete`."""
    legado, armazem = efemeros
    _semear_origem(legado)

    em_curso = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, em_curso, 907)
    _simular_job(armazem, legado, job_id=907, geracao=7, tabelas=["brands"])  # o job ainda escreve
    a_caminho = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")  # outro chamador, antes do job nascer

    consultas: list[int] = []

    def airbyte_diz_running(job_id: int) -> str:
        consultas.append(job_id)
        return "running"

    feito = captura.retomar(legado, armazem, estado_do_job=airbyte_diz_running)
    assert feito == {em_curso: "ativa", a_caminho: "ativa"} and consultas == [907]
    assert _estados(armazem) == {em_curso: captura.PENDING, a_caminho: captura.PENDING}

    # Sem observador ninguém fecha a que tem job: pendente é melhor que `incomplete` falso.
    assert captura.retomar(legado, armazem)[em_curso] == "sem_observador"
    assert _estados(armazem)[em_curso] == captura.PENDING

    # O job termina, o bruto completa, e só então a retomada conclui — com o antes gravado.
    _simular_job(armazem, legado, job_id=907, geracao=7, tabelas=[t for t in schema.tabelas() if t != "brands"])
    feito = captura.retomar(legado, armazem, estado_do_job=lambda job_id: "succeeded")
    assert feito[em_curso] == "concluida" and feito[a_caminho] == "ativa"
    assert _estados(armazem)[em_curso] == captura.COMPLETE and captura.certificadas(armazem) == [907]

    # Passada a carência, a sem job é abandonada.
    depois = dt.datetime.now(dt.timezone.utc) + captura.CARENCIA_SEM_JOB
    assert captura.retomar(legado, armazem, agora=depois) == {a_caminho: "abandonada"}


@pytest.mark.integracao
def test_reenviar_a_conclusao_devolve_o_certificado_gravado_sem_remedir_a_origem(efemeros) -> None:
    """RV10-02: remedir depois de uma alteração legítima revogava um `complete` histórico."""
    legado, armazem = efemeros
    _semear_origem(legado)
    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 908)
    _simular_job(armazem, legado, job_id=908, geracao=8)
    primeira = captura.concluir(legado, armazem, tentativa)
    assert primeira["status"] == captura.COMPLETE

    with legado.begin() as conexao:  # a origem segue a vida depois do job
        conexao.execute(text("update legacy.brands set name = 'Acme S.A.' where id = '1'"))
    with armazem.connect() as conexao:
        antes = conexao.execute(
            text(f"select source_hash_after, completed_at from {captura.TABELA} where capture_attempt_id = :a and source_table = 'brands'"),
            {"a": tentativa},
        ).one()

    segunda = captura.concluir(legado, armazem, tentativa)
    assert segunda == primeira
    with armazem.connect() as conexao:
        depois = conexao.execute(
            text(f"select source_hash_after, completed_at from {captura.TABELA} where capture_attempt_id = :a and source_table = 'brands'"),
            {"a": tentativa},
        ).one()
    assert depois == antes, "nada foi remedido nem regravado"
    assert captura.certificadas(armazem) == [908]


class _ArmazemQueCai:
    """Um armazém cuja transação de escrita morre depois de N comandos — a interrupção da fase 2."""

    def __init__(self, engine, depois_de: int):
        self._engine, self._depois_de = engine, depois_de

    def connect(self):
        return self._engine.connect()

    def begin(self):
        externo = self

        class _Transacao:
            def __enter__(self):
                self._cm = externo._engine.begin()
                conexao = self._cm.__enter__()
                executados = 0

                class _Conexao:
                    def execute(self, *args, **kwargs):
                        nonlocal executados
                        executados += 1
                        if executados > externo._depois_de:
                            raise RuntimeError("interrompida no meio da publicação")
                        return conexao.execute(*args, **kwargs)

                return _Conexao()

            def __exit__(self, *args):
                return self._cm.__exit__(*args)

        return _Transacao()


@pytest.mark.integracao
def test_interrupcao_no_meio_da_publicacao_nao_deixa_nada_e_a_retomada_conclui(efemeros) -> None:
    """RV10-01: veredito e identidade saem juntos, ou não saem."""
    legado, armazem = efemeros
    _semear_origem(legado)
    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, 909)
    _simular_job(armazem, legado, job_id=909, geracao=9)

    with pytest.raises(RuntimeError, match="interrompida"):
        captura.concluir(legado, _ArmazemQueCai(armazem, depois_de=25), tentativa)

    with armazem.connect() as conexao:
        status, com_identidade = conexao.execute(
            text(f"select min(status), count(snapshot_id) from {captura.TABELA} where capture_attempt_id = :a"),
            {"a": tentativa},
        ).one()
    assert (status, com_identidade) == (captura.PENDING, 0), "as 40 linhas continuam pendentes e sem identidade"
    assert captura.certificadas(armazem) == []
    assert [a for a, _, _ in captura._pendentes(armazem)] == [tentativa]

    feito = captura.retomar(legado, armazem, estado_do_job=lambda job_id: "succeeded")
    assert feito == {tentativa: "concluida"}
    assert captura.certificadas(armazem) == [909]

