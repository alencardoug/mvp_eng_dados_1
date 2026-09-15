"""Exclusão física do legado (ADR-0045): o diário das mutações e a comparação entre capturas.

Dois níveis:

* **o diário**, em banco efêmero e manifesto temporário: `remover`, `inserir` e
  `alterar` gravam o que o banco **devolveu** — não o que se pretendia —,
  confirmam depois do `commit` e registram o hash de conteúdo antes e depois.
  É o esperado independente que a prova entre capturas usa;
* **o ciclo real**, somente leitura sobre o armazém de trabalho: para cada
  remoção do diário, a chave aparece como `removida` em
  `legacy_capture_transitions` e em `legacy_removed_records` com o
  `removed_in` da captura seguinte; inserções aparecem como `adicionada`;
  alterações são `mantida` (rejeição nova não é remoção). Só roda quando há
  diário e a captura selecionada é posterior às mutações — ou seja, dentro do
  bloco de sincronizações do plano (B em diante).
"""

from __future__ import annotations

import json
import os
import uuid

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

from mvp_ed1.db import LEGACY, WAREHOUSE, database_url
from mvp_ed1.legacy import mutacoes, schema

pytestmark = pytest.mark.integracao


@pytest.fixture(scope="module")
def administrador():
    if not os.environ.get("LEGACY_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    motor = create_engine(database_url(LEGACY), isolation_level="AUTOCOMMIT")
    try:
        with motor.connect() as conexao:
            conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover
        pytest.skip(f"legacy_db indisponível: {erro}")
    yield motor
    motor.dispose()


@pytest.fixture
def legado_efemero(administrador):
    nome = f"legacy_teste_mutacoes_{uuid.uuid4().hex[:8]}"
    with administrador.connect() as conexao:
        conexao.execute(text(f'create database "{nome}"'))
    anterior = os.environ["LEGACY_DB_NAME"]
    os.environ["LEGACY_DB_NAME"] = nome
    try:
        command.upgrade(Config("alembic.ini", ini_section="legacy"), "head")
        engine = create_engine(database_url(LEGACY))
    finally:
        os.environ["LEGACY_DB_NAME"] = anterior
    with engine.begin() as conexao:
        conexao.execute(text("insert into legacy.brands (id, code, name) values ('1','b1','Acme'), ('2','b2','Bravo'), ('08','b8','Oito')"))
    yield engine
    engine.dispose()
    with administrador.connect() as conexao:
        conexao.execute(text(f'drop database if exists "{nome}" with (force)'))


@pytest.fixture
def manifesto_temporario(tmp_path):
    caminho = tmp_path / "manifesto-teste.json"
    caminho.write_text(json.dumps({
        "lote": {"hash": "teste", "tabelas": {}, "parametros": {}},
        "achados": [],
        "veredito": [["brands", 1, "accepted", None, [], {}], ["brands", 2, "rejected", "own_invalid", [], {}],
                     ["brands", 3, "corrected", None, [], {}]],
        "mutacoes": [],
    }), encoding="utf-8")
    link = tmp_path / "manifesto.json"
    link.symlink_to(caminho.name)
    return link


def test_remover_grava_o_que_o_banco_devolveu_e_escolhe_aptas_pelo_oraculo(legado_efemero, manifesto_temporario) -> None:
    # `--quantidade 1` escolhe a primeira apta em ordem física: legacy_row_id 1 (a 2 é rejeitada).
    registro = mutacoes.remover(legado_efemero, "brands", quantidade=1, manifesto=manifesto_temporario)
    assert registro["chaves"] == ["1"] and registro["linhas_apagadas"] == 1
    assert registro["devolvidas"][0]["legacy_row_id"] == 1 and registro["devolvidas"][0]["name"] == "Acme"
    assert registro["restantes_apos_commit"] == 0 and "erro" not in registro
    assert registro["hash_antes"]["linhas"] == 3 and registro["hash_depois"]["linhas"] == 2
    assert registro["hash_antes"]["hash"] != registro["hash_depois"]["hash"]

    diario = json.loads(manifesto_temporario.resolve().read_text(encoding="utf-8"))["mutacoes"]
    assert [m["tipo"] for m in diario] == ["remover"]

    # Chave inexistente: nada devolvido, e o diário diz isso em vez de fingir.
    vazio = mutacoes.remover(legado_efemero, "brands", chaves=["999"], manifesto=manifesto_temporario)
    assert vazio["linhas_apagadas"] == 0 and vazio["hash_antes"] == vazio["hash_depois"]


def test_inserir_e_alterar_registram_antes_e_depois(legado_efemero, manifesto_temporario) -> None:
    inserida = mutacoes.inserir(legado_efemero, "brands", {"id": "9", "code": "b9", "name": "Nova"}, manifesto=manifesto_temporario)
    assert inserida["devolvida"]["legacy_row_id"] == 4 and inserida["hash_depois"]["linhas"] == 4

    alterada = mutacoes.alterar(legado_efemero, "brands", "2", "name", None, manifesto=manifesto_temporario)
    assert alterada["antes"] == [{"legacy_row_id": 2, "valor": "Bravo"}]
    assert alterada["devolvidas"] == [{"legacy_row_id": 2, "valor": None}]
    assert alterada["hash_antes"]["linhas"] == alterada["hash_depois"]["linhas"] == 4
    assert alterada["hash_antes"]["hash"] != alterada["hash_depois"]["hash"], "conteúdo mudou sem mudar contagem"

    with pytest.raises(ValueError, match="colunas desconhecidas"):
        mutacoes.inserir(legado_efemero, "brands", {"nao_existe": "x"}, manifesto=manifesto_temporario)


# ── O ciclo real, somente leitura ────────────────────────────────────────────

@pytest.fixture(scope="module")
def armazem():
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado")
    motor = create_engine(database_url(WAREHOUSE))
    yield motor
    motor.dispose()


@pytest.fixture(scope="module")
def diario():
    if not mutacoes.MANIFESTO.exists():
        pytest.skip("sem manifesto")
    manifesto = json.loads(mutacoes.MANIFESTO.resolve().read_text(encoding="utf-8"))
    if not manifesto.get("mutacoes"):
        pytest.skip("sem mutações no diário: a prova entre capturas ainda não aconteceu")
    return manifesto["mutacoes"]


def _tabela_existe(conexao, esquema, nome) -> bool:
    return bool(conexao.execute(
        text("select count(*) from information_schema.tables where table_schema = :s and table_name = :t"),
        {"s": esquema, "t": nome},
    ).scalar_one())


def _efeito_liquido(diario: list[dict]) -> dict[tuple[str, str], bool]:
    """Por (tabela, chave), se a linha **existe** na origem depois da última mutação do diário."""
    presente: dict[tuple[str, str], bool] = {}
    for mutacao in diario:
        tabela = mutacao["tabela"]
        if mutacao["tipo"] == "remover":
            for chave in mutacao["chaves"]:
                if mutacao["linhas_apagadas"]:
                    presente[(tabela, str(chave))] = False
        elif mutacao["tipo"] == "inserir":
            presente[(tabela, str(mutacao["devolvida"][mutacao["chave"]]))] = True
        elif mutacao["tipo"] == "alterar":
            presente.setdefault((tabela, str(mutacao["valor_da_chave"])), True)
    return presente


def test_as_mutacoes_do_diario_aparecem_nas_transicoes_e_na_memoria(armazem, diario, record_property) -> None:
    """O efeito líquido do diário é o que a memória e o intervalo têm de mostrar.

    O diário atravessa várias capturas: uma chave apagada em B e reposta em D
    está `mantida` hoje e **fora** da memória — é o comportamento certo, e o
    teste o cobra assim. Chave cuja última mutação foi remoção precisa estar na
    memória e não pode aparecer como `adicionada`/`mantida`; chave cuja última
    mutação foi inserção não pode estar na memória; alteração é `mantida`.
    """
    with armazem.connect() as conexao:
        if not _tabela_existe(conexao, "trusted", "legacy_capture_transitions"):
            pytest.skip("modelos de exclusão física não construídos")
        transicoes = conexao.execute(
            text("select source_table, business_key, transition, previous_snapshot_id, selected_snapshot_id "
                 "from trusted.legacy_capture_transitions")
        ).all()
        memoria = {
            (t, k): (ls, ri)
            for t, k, ls, ri in conexao.execute(
                text("select source_table, business_key, last_seen_snapshot_id, removed_in_snapshot_id "
                     "from trusted.legacy_removed_records")
            )
        }
    if not transicoes:
        pytest.skip("sem intervalo: a captura selecionada não tem anterior certificada")

    por_chave = {(t, k): tr for t, k, tr, *_ in transicoes}
    record_property("interval", f"{transicoes[0][3]}->{transicoes[0][4]}")
    faltas = []
    for (tabela, chave), presente in _efeito_liquido(diario).items():
        transicao = por_chave.get((tabela, chave))
        if presente:
            if (tabela, chave) in memoria:
                faltas.append(("presente mas na memória", tabela, chave))
            if transicao not in ("mantida", "adicionada", None):
                faltas.append(("presente com transição estranha", tabela, chave, transicao))
        else:
            if (tabela, chave) not in memoria:
                faltas.append(("ausente e fora da memória", tabela, chave))
            if transicao in ("mantida", "adicionada"):
                faltas.append(("ausente mas presente no intervalo", tabela, chave, transicao))
    record_property("diary_entries", len(diario))
    record_property("net_absent_keys", sum(not p for p in _efeito_liquido(diario).values()))
    assert not faltas, f"efeito líquido do diário sem correspondência: {faltas[:10]}"
