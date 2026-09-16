"""Exclusão física do legado (ADR-0045): o diário das mutações e a comparação entre capturas.

Quatro níveis:

* **o diário**, em banco efêmero e manifesto temporário: `remover`, `inserir` e
  `alterar` gravam o que o banco **devolveu** — não o que se pretendia —,
  confirmam depois do `commit` e registram o hash de conteúdo antes e depois.
  É o esperado independente que a prova entre capturas usa;
* **a fronteira da identidade**: a macro renderizada e o espelho em Python
  contra o `cast` nativo, forma a forma, nos dois bancos;
* **o ciclo inteiro em bancos efêmeros**: duas capturas certificadas, mutações
  entre elas, os modelos gerados executados de verdade e o mesmo consumidor do
  ciclo real — é onde redução, aumento e troca só de representação são provados
  até o fim;
* **o ciclo real**, somente leitura sobre o armazém de trabalho: chave cuja
  última mutação foi remoção está em `legacy_removed_records` e só aparece em
  `legacy_capture_transitions` como `removida`; chave presente está fora da
  memória e com linhas depois — em qualquer transição de multiplicidade. Só
  roda quando há diário e a captura selecionada é posterior às mutações — ou
  seja, dentro do bloco de sincronizações do plano (B em diante).
"""

from __future__ import annotations

import json
import os
import pathlib
import time
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


def test_o_diario_registra_a_multiplicidade_canonica_depois_do_commit(legado_efemero, manifesto_temporario) -> None:
    """RV10-2-06/07: apagar um alias não remove a chave; alterar a PK move a identidade."""
    # A semente tem `'08'`; `'8'` entra como segunda representação da mesma chave canônica.
    mutacoes.inserir(legado_efemero, "brands", {"id": "8", "code": "b8b", "name": "Oito bis"}, manifesto=manifesto_temporario)
    alias = mutacoes.remover(legado_efemero, "brands", chaves=["08"], manifesto=manifesto_temporario)
    assert alias["linhas_apagadas"] == 1 and alias["restantes_apos_commit"] == 0, "a igualdade textual não vê `'8'`"
    assert alias["presenca_apos_commit"] == {"8": 1}, "a chave canônica 8 sobrevive: é redução, não remoção"

    pk = mutacoes.alterar(legado_efemero, "brands", "1", "id", "2", manifesto=manifesto_temporario)
    assert pk["devolvidas"] == [{"legacy_row_id": 1, "valor": "2"}]
    # `'2'` já existia (Bravo): a chave canônica 2 passa a ter duas linhas físicas.
    assert pk["presenca_apos_commit"] == {"1": 0, "2": 2}

    # RV10-3-02: alteração de zero linhas não toca chave nenhuma — `{777: 0}`
    # seria uma testemunha de ausência para uma chave que nunca existiu.
    nada = mutacoes.alterar(legado_efemero, "brands", "777", "name", "Nada", manifesto=manifesto_temporario)
    assert nada["devolvidas"] == [] and nada["presenca_apos_commit"] == {}
    assert nada["hash_antes"] == nada["hash_depois"]

    # RV10-3-01: trocar só a representação da PK (`'8'` → `'0x8'`) mantém a chave canônica.
    hexa = mutacoes.alterar(legado_efemero, "brands", "8", "id", "0x8", manifesto=manifesto_temporario)
    assert hexa["devolvidas"] == [{"legacy_row_id": 4, "valor": "0x8"}]
    assert hexa["presenca_apos_commit"] == {"8": 1}

    diario = json.loads(manifesto_temporario.resolve().read_text(encoding="utf-8"))["mutacoes"]
    assert mutacoes.efeito_liquido(diario) == {("brands", "8"): True, ("brands", "1"): False, ("brands", "2"): True}


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

    # Com `presenca_apos_commit` (entradas de 15/09 em diante) vale a multiplicidade confirmada,
    # não o RETURNING: o alias apagado deixa a chave presente; a PK alterada move a identidade.
    diario_novo = [
        {"tipo": "remover", "tabela": "brands", "chave": "id", "chaves": ["08"],
         "devolvidas": [{"legacy_row_id": 3, "id": "08"}], "linhas_apagadas": 1, "presenca_apos_commit": {"8": 1}},
        {"tipo": "alterar", "tabela": "brands", "chave": "id", "valor_da_chave": "1", "coluna": "id",
         "antes": [{"legacy_row_id": 1, "valor": "1"}], "devolvidas": [{"legacy_row_id": 1, "valor": "2"}],
         "presenca_apos_commit": {"1": 0, "2": 1}},
    ]
    assert mutacoes.efeito_liquido(diario_novo) == {("brands", "8"): True, ("brands", "1"): False, ("brands", "2"): True}


@pytest.mark.parametrize(
    "valor,tipo,esperado",
    [
        ("08", "bigint", "8"), ("+8", "bigint", "8"), (" 8 ", "bigint", "8"), ("-0", "bigint", "0"),
        ("9223372036854775807", "bigint", "9223372036854775807"),
        ("9223372036854775808", "bigint", None), ("8.0", "bigint", None), ("", "bigint", None),
        ("2147483648", "integer", None), ("2147483647", "integer", "2147483647"),
        # terceira rodada (RV10-3-01): as bases e o separador do PostgreSQL 16
        ("0x8", "bigint", "8"), ("0X8", "bigint", "8"), ("0o10", "bigint", "8"), ("0b1000", "bigint", "8"),
        ("1_000", "bigint", "1000"), ("0x_8", "bigint", "8"), ("-0x8000000000000000", "bigint", "-9223372036854775808"),
        ("0x8000000000000000", "bigint", None), ("0x8_", "bigint", None), ("_8", "bigint", None),
        ("1__0", "bigint", None), ("0x8", "smallint", "8"), ("0x8000", "smallint", None),
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


@pytest.mark.parametrize(
    "valor",
    ["0" * 131080 + "x", "0" * 131080 + "_", "1_" * 65540 + "x", "0x" + "f" * 131080 + "g", "123_" * 32770 + "x",
     "0x_" + "f" * 131080 + "_"],
    ids=["zeros+x", "zeros+_", "1_…x", "0xf…g", "123_…x", "0x_f…_"],
)
def test_a_canonizacao_recusa_entrada_longa_invalida_em_tempo_linear(valor) -> None:
    """RV10-3-03: `0*` seguido de `[0-9]+` custava mais de 2 s em 131.080 zeros com sufixo inválido."""
    inicio = time.perf_counter()
    assert remocao.canonizar(valor, "bigint") is None
    assert time.perf_counter() - inicio < 1.0, "a guarda não é linear no tamanho da entrada"


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
        # segunda rodada (RV10-2-05): `$` do Python aceitava a quebra final
        "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11\n",
    ],
    "bigint": ["8", "08", "+8", " 8 ", "-0", "-9223372036854775808", "9223372036854775807",
               "9223372036854775808", "-9223372036854775809", "99999999999999999999", "8.0", "1e3", "", " ", "x", "٨",
               # segunda rodada (RV10-2-04/05): brancos que o cast aceita e os que só o `\s` aceitava;
               # zeros à esquerda sem limite; mais dígitos do que o `numeric` guarda
               "\t8\n", "\x0b8\x0c", "8\n", "\u20038\u2003", "\xa08\xa0", "0" * 5000 + "8", "0" * 131080,
               "9" * 25, "9" * 131073, "-" + "0" * 40 + "9223372036854775808",
               # terceira rodada (RV10-3-01): hexa, octal, binário e `_`, como `pg_strtoint64` os lê —
               # e as fronteiras de cada base, dos dois lados do domínio
               "0x8", "0X8", "+0x8", "-0x8", " 0x8 ", "0x_8", "0x8_8", "0x8_", "0x_", "0x", "0x8__8", "0xg", "00x8",
               "0x7fffffffffffffff", "0x8000000000000000", "-0x8000000000000000", "0xFFFFFFFFFFFFFFFF",
               "0x" + "0" * 40 + "8", "0x1_0000_0000_0000_0000",
               "0o10", "0O10", "0o_10", "0o10_", "0o8", "0o" + "7" * 21, "0o1" + "0" * 21, "-0o1" + "0" * 21,
               "0o1" + "0" * 20 + "1", "0b1000", "0B1000", "0b_1", "0b1_", "0b2", "0b" + "1" * 63, "0b1" + "0" * 63,
               "-0b1" + "0" * 63, "1_000", "_1000", "1000_", "1__000", "0_8", "00_8", "0_x8", "1_0_0", "+1_0", "-_1",
               # RV10-3-03: longas e inválidas — a guarda tem de recusar em tempo linear
               "0" * 131080 + "x", "0" * 131080 + "_", "1_" * 65540 + "x", "0x" + "f" * 131080 + "g"],
    "integer": ["2147483647", "2147483648", "-2147483648", "-2147483649", "+7",
                "0x7fffffff", "0x80000000", "-0x80000000", "0o1_0", "0b" + "1" * 31, "2_147_483_647"],
    "smallint": ["32767", "32768", "-32768", "-32769", "0x7fff", "0x8000", "-0x8000", "0o77777", "0b" + "1" * 15],
}


def _macro():
    """A macro `chave_canonica` do arquivo vigente, como callable Jinja."""
    import jinja2

    class _Excecoes:
        def raise_compiler_error(self, mensagem):  # noqa: D401 — a interface do dbt
            raise RuntimeError(mensagem)

    fonte = pathlib.Path("dbt/macros/chave_canonica.sql").read_text(encoding="utf-8")
    return jinja2.Environment().from_string(fonte, globals={"exceptions": _Excecoes()}).module.chave_canonica


def _macro_renderizada(tipo: str) -> str:
    return _macro()(":v", tipo)


@pytest.fixture(scope="module")
def bancos(administrador):
    """O legado e o armazém: a macro roda no armazém, e os dois são a mesma imagem por *digest*."""
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado")
    armazem = create_engine(database_url(WAREHOUSE), isolation_level="AUTOCOMMIT")
    yield {"legacy_db": administrador, "warehouse_db": armazem}
    armazem.dispose()


@pytest.mark.parametrize("banco", ["legacy_db", "warehouse_db"])
@pytest.mark.parametrize("tipo", sorted(FORMAS))
def test_a_macro_real_devolve_o_que_o_cast_do_postgresql_devolve_ou_nulo(bancos, banco, tipo) -> None:
    """A guarda aceita exatamente o que o `cast` aceita; o resto é nulo, nunca erro (ADR-0045).

    Executa a macro **renderizada** e, ao lado, a conversão nativa, cada uma na
    sua transação — uma conversão que lança não pode contaminar a próxima:
    onde o `cast` converte, a macro devolve o mesmo texto; onde ele lança, a
    macro devolve nulo, sem lançar. É o teste que a revisão pediu — os exemplos
    com chaves já canonizadas não exercitam a fronteira (RV10-04/05) —, nos
    dois bancos (RV10-2-04). Só `SELECT`, em transação somente leitura.
    """
    expressao = _macro_renderizada(tipo)
    divergencias = []
    motor = bancos[banco]
    for valor in FORMAS[tipo]:
        with motor.connect() as conexao:
            conexao.execute(text("set default_transaction_read_only = on"))
            try:
                pela_macro = conexao.execute(text(f"select {expressao}"), {"v": valor}).scalar_one()
            except Exception as erro:  # noqa: BLE001 — a macro nunca pode lançar
                divergencias.append((valor[:40], f"MACRO LANÇOU {type(erro).__name__}", None))
                continue
        with motor.connect() as conexao:
            conexao.execute(text("set default_transaction_read_only = on"))
            try:
                nativa = conexao.execute(text(f"select (:v)::{tipo}::text"), {"v": valor}).scalar_one()
            except Exception:  # noqa: BLE001 — o cast lançou: a macro tem de devolver nulo
                nativa = None
        if pela_macro != nativa:
            divergencias.append((valor[:40], pela_macro, nativa))
        assert remocao.canonizar(valor, tipo) == nativa, (valor[:40], "a canonização em Python diverge do cast")
    assert not divergencias, divergencias


# ── O consumidor do diário: o que o intervalo e a memória têm de mostrar ─────

def _ler_intervalo_e_memoria(conexao) -> tuple[dict, dict]:
    """Por `(tabela, chave)`: `(transição, rows_after)` do intervalo, e `(last_seen, removed_in)` da memória."""
    intervalo = {
        (t, k): (tr, depois)
        for t, k, tr, depois in conexao.execute(
            text("select source_table, business_key, transition, rows_after from trusted.legacy_capture_transitions "
                 "where business_key is not null")
        )
    }
    memoria = {
        (t, k): (ls, ri)
        for t, k, ls, ri in conexao.execute(
            text("select source_table, business_key, last_seen_snapshot_id, removed_in_snapshot_id "
                 "from trusted.legacy_removed_records")
        )
    }
    return intervalo, memoria


def _faltas(efeito: dict[tuple[str, str], bool], intervalo: dict, memoria: dict) -> list[tuple]:
    """O que o efeito líquido do diário exige e os modelos não mostram.

    Chave presente: fora da memória, e no intervalo com `rows_after > 0` — em
    qualquer transição de multiplicidade (`mantida`, `adicionada`, `reduzida`,
    `aumentada`), porque apagar um alias com outro sobrevivente **é** redução
    (RV10-3-04). Chave ausente: na memória, e no intervalo só como `removida`.
    Fora do intervalo (`None`) é chave que não mudou entre as duas últimas
    certificadas — a memória sozinha responde.
    """
    faltas = []
    for (tabela, chave), presente in efeito.items():
        transicao, depois = intervalo.get((tabela, chave), (None, None))
        if presente:
            if (tabela, chave) in memoria:
                faltas.append(("presente mas na memória", tabela, chave))
            if transicao is not None and not depois > 0:
                faltas.append(("presente mas removida no intervalo", tabela, chave, transicao))
        else:
            if (tabela, chave) not in memoria:
                faltas.append(("ausente e fora da memória", tabela, chave))
            if transicao is not None and transicao != "removida":
                faltas.append(("ausente mas presente no intervalo", tabela, chave, transicao))
    return faltas


def test_o_consumidor_aceita_reducao_e_aumento_e_recusa_o_que_contradiz_o_diario() -> None:
    """RV10-3-04: `['8', '08'] → ['8']` é `reduzida` com a chave presente, e o teste tem de aceitar."""
    efeito = {("brands", "8"): True, ("brands", "9"): True, ("brands", "1"): False, ("brands", "2"): False,
              ("brands", "3"): True, ("brands", "4"): False}
    intervalo = {("brands", "8"): ("reduzida", 1), ("brands", "9"): ("aumentada", 2),
                 ("brands", "1"): ("removida", 0), ("brands", "2"): ("removida", 0)}
    memoria = {("brands", "1"): (1, 2), ("brands", "2"): (1, 2), ("brands", "4"): (1, 2)}
    assert _faltas(efeito, intervalo, memoria) == []

    # Cada contradição tem nome: presença na memória, remoção no intervalo, ausência sem memória.
    assert _faltas({("brands", "8"): True}, intervalo, {("brands", "8"): (1, 2)}) == [("presente mas na memória", "brands", "8")]
    assert _faltas({("brands", "1"): True}, intervalo, {}) == [("presente mas removida no intervalo", "brands", "1", "removida")]
    assert _faltas({("brands", "8"): False}, intervalo, {}) == [
        ("ausente e fora da memória", "brands", "8"), ("ausente mas presente no intervalo", "brands", "8", "reduzida"),
    ]


# ── O ciclo inteiro, em bancos efêmeros: duas certificadas e os modelos reais ─

def _modelos_renderizados(selecionada: int) -> dict[str, str]:
    """Os SQL gerados por `remocao`, com `source`, `ref`, `config` e a macro real resolvidos para o armazém efêmero."""
    import jinja2

    fontes = {"legacy_presence_by_capture": remocao.presenca_por_captura(), "legacy_capture_transitions": remocao.transicoes(),
              "legacy_removed_records": remocao.removidos(), "legado_presenca_fisica_reconcilia": remocao.teste_presenca_fisica()}
    ambiente = jinja2.Environment()
    contexto = {
        "source": lambda origem, nome: {"legacy": f'raw_legacy."{nome}"', "governance": f"governance.{nome}"}[origem],
        "ref": lambda nome: (f"(select {selecionada}::bigint as snapshot_id) as {nome}"
                             if nome == "legacy_selected_capture" else f'trusted."{nome}"'),
        "config": lambda **kwargs: "",
        "chave_canonica": _macro(),
    }
    return {nome: ambiente.from_string(fonte).render(**contexto) for nome, fonte in fontes.items()}


def _construir_modelos(armazem, selecionada: int) -> list[tuple]:
    """Materializa os três modelos na ordem do dbt e devolve as linhas do teste de reconciliação."""
    sql = _modelos_renderizados(selecionada)
    with armazem.begin() as conexao:
        conexao.execute(text("drop schema if exists trusted cascade"))
        conexao.execute(text("create schema trusted"))
        for modelo in ("legacy_presence_by_capture", "legacy_capture_transitions", "legacy_removed_records"):
            conexao.execute(text(f'create table trusted."{modelo}" as {sql[modelo]}'))
        return conexao.execute(text(sql["legado_presenca_fisica_reconcilia"])).all()


def _certificar(legado, armazem, job: int) -> int:
    from test_captura_legado import _simular_job

    from mvp_ed1.legacy import captura

    tentativa = captura.iniciar(legado, armazem, "legacy_para_raw_legacy")
    captura.registrar_job(armazem, tentativa, job)
    _simular_job(armazem, legado, job_id=job, geracao=job)
    certificado = captura.concluir(legado, armazem, tentativa)
    assert certificado["status"] == captura.COMPLETE, certificado
    return certificado["snapshot_id"]


from test_captura_legado import administradores, efemeros  # noqa: E402, F401 — fixtures dos bancos efêmeros


def test_o_ciclo_inteiro_entre_duas_certificadas_concorda_com_o_diario(efemeros, manifesto_temporario) -> None:
    """Duas capturas certificadas, mutações entre elas, os modelos reais e o consumidor (RV10-3-01/02/04).

    O que a segunda rodada provou só no nível do diário aqui atravessa o SQL
    gerado: troca só de representação (`'8'` → `'0x8'`) é `mantida`; apagar
    um alias é `reduzida`, inserir outro é `aumentada`, e nenhum dos dois entra
    na memória; alterar chave inexistente não deixa rastro; remover de verdade
    é `removida` com `removed_in` na captura seguinte. A equação física fecha,
    e `_faltas` — o mesmo consumidor do ciclo real — não acusa nada.
    """
    legado, armazem = efemeros
    with legado.begin() as conexao:
        conexao.execute(text(
            "insert into legacy.brands (id, code, name) values "
            "('1','b1','Acme'), ('2','b2','Bravo'), ('8','b8','Oito'), ('08','b08','Oito bis'), ('9','b9','Nove'), ('x','bx','Sem id')"
        ))
    anterior = _certificar(legado, armazem, job=1)

    mutacoes.alterar(legado, "brands", "8", "id", "0x8", manifesto=manifesto_temporario)      # só representação
    mutacoes.remover(legado, "brands", chaves=["08"], manifesto=manifesto_temporario)         # alias: redução
    mutacoes.inserir(legado, "brands", {"id": "0o11", "code": "b9b", "name": "Nove bis"}, manifesto=manifesto_temporario)  # alias: aumento
    mutacoes.alterar(legado, "brands", "777", "name", "Nada", manifesto=manifesto_temporario)  # sem linha
    mutacoes.remover(legado, "brands", chaves=["2"], manifesto=manifesto_temporario)          # remoção real
    mutacoes.alterar(legado, "brands", "1", "name", "Acme S.A.", manifesto=manifesto_temporario)  # conteúdo: mantida
    selecionada = _certificar(legado, armazem, job=2)

    diario = json.loads(manifesto_temporario.resolve().read_text(encoding="utf-8"))["mutacoes"]
    efeito = mutacoes.efeito_liquido(diario)
    assert efeito == {("brands", "8"): True, ("brands", "9"): True, ("brands", "2"): False, ("brands", "1"): True}

    assert _construir_modelos(armazem, selecionada) == [], "a equação física não fechou"
    with armazem.connect() as conexao:
        intervalo, memoria = _ler_intervalo_e_memoria(conexao)
        sem_identidade = conexao.execute(text(
            "select rows_before, rows_after from trusted.legacy_capture_transitions where business_key is null"
        )).all()
    assert intervalo == {
        ("brands", "1"): ("mantida", 1), ("brands", "2"): ("removida", 0),
        ("brands", "8"): ("reduzida", 1), ("brands", "9"): ("aumentada", 2),
    }
    assert sem_identidade == [(1, 1)], "`'x'` é sem identidade nos dois lados"
    assert memoria == {("brands", "2"): (anterior, selecionada)}
    assert _faltas(efeito, intervalo, memoria) == []


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
    memória e só pode aparecer no intervalo como `removida`; chave cuja última
    mutação a deixou presente não pode estar na memória, e no intervalo tem
    `rows_after > 0` — em qualquer transição de multiplicidade (`_faltas`).
    """
    with armazem.connect() as conexao:
        if not _tabela_existe(conexao, "trusted", "legacy_capture_transitions"):
            pytest.skip("modelos de exclusão física não construídos")
        intervalo, memoria = _ler_intervalo_e_memoria(conexao)
        limites = conexao.execute(
            text("select min(previous_snapshot_id), min(selected_snapshot_id) from trusted.legacy_capture_transitions")
        ).one()
    if not intervalo:
        pytest.skip("sem intervalo: a captura selecionada não tem anterior certificada")

    record_property("interval", f"{limites[0]}->{limites[1]}")
    efeito = mutacoes.efeito_liquido(diario)
    faltas = _faltas(efeito, intervalo, memoria)
    record_property("diary_entries", len(diario))
    record_property("net_absent_keys", sum(not p for p in efeito.values()))
    assert not faltas, f"efeito líquido do diário sem correspondência: {faltas[:10]}"
