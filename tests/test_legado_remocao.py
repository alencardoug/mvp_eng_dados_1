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
import pathlib
import uuid

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

from mvp_ed1.db import LEGACY, WAREHOUSE, database_url
from mvp_ed1.legacy import mutacoes, remocao, schema

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


def test_o_efeito_liquido_sai_do_que_o_banco_devolveu_e_nao_do_que_se_pediu() -> None:
    """Remoção parcial, alteração sem correspondência e chave por extenso (RV10-10)."""
    diario = [
        # Pediu `1` e `999`; só `1` existia. `999` não entra no efeito: o diário
        # não sabe se ela existia, e marcá-la ausente fabricaria uma testemunha.
        {"tipo": "remover", "tabela": "brands", "chave": "id", "chaves": ["1", "999"],
         "devolvidas": [{"legacy_row_id": 1, "id": "1", "code": "b1", "name": "Acme"}], "linhas_apagadas": 1},
        # `08` apagado é a chave canônica `8`, como o intervalo a grava.
        {"tipo": "remover", "tabela": "brands", "chave": "id", "chaves": ["08"],
         "devolvidas": [{"legacy_row_id": 3, "id": "08", "code": "b8", "name": "Oito"}], "linhas_apagadas": 1},
        # Alteração de zero linhas não diz que a chave existe.
        {"tipo": "alterar", "tabela": "brands", "chave": "id", "valor_da_chave": "777", "coluna": "name",
         "antes": [], "devolvidas": []},
        # Alteração com linha devolvida diz que existe — sem sobrescrever remoção anterior.
        {"tipo": "alterar", "tabela": "brands", "chave": "id", "valor_da_chave": "2", "coluna": "name",
         "antes": [{"legacy_row_id": 2, "valor": "Bravo"}], "devolvidas": [{"legacy_row_id": 2, "valor": None}]},
        {"tipo": "inserir", "tabela": "brands", "chave": "id", "devolvida": {"legacy_row_id": 4, "id": "+9", "code": "b9", "name": "Nova"}},
        # Chave sem identidade (não converte para bigint) fica fora da comparação.
        {"tipo": "inserir", "tabela": "brands", "chave": "id", "devolvida": {"legacy_row_id": 5, "id": "x", "code": "bx", "name": "Sem id"}},
    ]
    assert mutacoes.efeito_liquido(diario) == {
        ("brands", "1"): False,
        ("brands", "8"): False,
        ("brands", "2"): True,
        ("brands", "9"): True,
    }


@pytest.mark.parametrize(
    "valor,tipo,esperado",
    [
        ("08", "bigint", "8"), ("+8", "bigint", "8"), (" 8 ", "bigint", "8"), ("-0", "bigint", "0"),
        ("9223372036854775807", "bigint", "9223372036854775807"),
        ("9223372036854775808", "bigint", None), ("8.0", "bigint", None), ("", "bigint", None),
        ("2147483648", "integer", None), ("2147483647", "integer", "2147483647"),
        ("A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11", "uuid", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"),
        ("{a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11}", "uuid", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"),
        ("a0eebc999c0b4ef8bb6d6bb9bd380a11", "uuid", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"),
        ("{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "uuid", None),
        ("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}", "uuid", None),
        (" a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "uuid", None),
        ("a0eebc99-9c0b--4ef8-bb6d-6bb9bd380a11", "uuid", None),
        ("  x  ", "texto", "x"), ("   ", "texto", None), (None, "uuid", None),
    ],
)
def test_a_canonizacao_em_python_segue_a_gramatica_do_postgresql(valor, tipo, esperado) -> None:
    assert remocao.canonizar(valor, tipo) == esperado


def test_a_chave_declarada_carrega_o_dominio_do_tipo() -> None:
    assert remocao.chave("brands") == ("id", "bigint")
    assert remocao.chave("inventory_movements") == ("movement_id", "uuid")


# ── A macro real, no PostgreSQL instalado ────────────────────────────────────

FORMAS = {
    "uuid": [
        "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11",
        "{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}", "a0eebc999c0b4ef8bb6d6bb9bd380a11",
        "a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11", "a0eebc99-9c0b4ef8-bb6d6bb9bd380a11",
        "{a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11}",
        # o que a guarda antiga deixava passar e o cast derrubava (RV10-04)
        "{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}",
        "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11-", "-a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        "a0eebc99-9c0b--4ef8-bb6d-6bb9bd380a11", "a0e-ebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        "  a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11  ", "{ a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11 }",
        "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a1", "", "x",
    ],
    "bigint": ["8", "08", "+8", " 8 ", "-0", "-9223372036854775808", "9223372036854775807",
               "9223372036854775808", "-9223372036854775809", "99999999999999999999", "8.0", "1e3", "", " ", "x", "٨"],
    "integer": ["2147483647", "2147483648", "-2147483648", "-2147483649", "+7"],
}


def _macro_renderizada(tipo: str) -> str:
    import jinja2

    class _Excecoes:
        def raise_compiler_error(self, mensagem):  # noqa: D401 — a interface do dbt
            raise RuntimeError(mensagem)

    fonte = pathlib.Path("dbt/macros/chave_canonica.sql").read_text(encoding="utf-8")
    modulo = jinja2.Environment().from_string(fonte, globals={"exceptions": _Excecoes()}).module
    return modulo.chave_canonica(":v", tipo)


@pytest.mark.parametrize("tipo", sorted(FORMAS))
def test_a_macro_real_devolve_o_que_o_cast_do_postgresql_devolve_ou_nulo(administrador, tipo) -> None:
    """A guarda aceita exatamente o que o `cast` aceita; o resto é nulo, nunca erro (ADR-0045).

    Executa a macro **renderizada** e, ao lado, a conversão nativa em bloco
    próprio: onde o `cast` converte, a macro devolve o mesmo texto; onde ele
    lança, a macro devolve nulo. É o teste que a revisão pediu — os exemplos
    com chaves já canonizadas não exercitam a fronteira (RV10-04/05). Só
    `SELECT`, em transação somente leitura.
    """
    expressao = _macro_renderizada(tipo)
    divergencias = []
    with administrador.connect() as conexao:
        conexao.execute(text("set default_transaction_read_only = on"))
        for valor in FORMAS[tipo]:
            pela_macro = conexao.execute(text(f"select {expressao}"), {"v": valor}).scalar_one()
            try:
                nativa = conexao.execute(text(f"select (:v)::{tipo}::text"), {"v": valor}).scalar_one()
            except Exception:  # noqa: BLE001 — o cast lançou: a macro tem de devolver nulo
                nativa = None
            if pela_macro != nativa:
                divergencias.append((valor, pela_macro, nativa))
            assert remocao.canonizar(valor, tipo) == nativa, (valor, "a canonização em Python diverge do cast")
    assert not divergencias, divergencias


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
    for (tabela, chave), presente in mutacoes.efeito_liquido(diario).items():
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
    record_property("net_absent_keys", sum(not p for p in mutacoes.efeito_liquido(diario).values()))
    assert not faltas, f"efeito líquido do diário sem correspondência: {faltas[:10]}"
