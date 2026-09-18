"""Acesso por papel: o que a Governança §7 declara é o que o armazém concede — e nada mais.

Os cinco papéis do ADR-0011 existem como grupos de privilégio sem login
(`mvp_ed1.governance`, migração `0003_papeis_de_acesso`). A concessão é
declarada onde a camada é declarada — `+grants` e `meta.writers` no
`dbt_project.yml`, `meta.grants` e `meta.writers` nos `_sources.yml` — e
aplicada pelo dbt objeto a objeto e pelo `on-run-end` schema a schema
(`macros/aplicar_acesso_por_camada.sql`).

Este teste faz três coisas, na ordem em que se lê a política: confere que o
**declarado** é a §7; confere que os papéis existem, sem login e sem
superpoderes; e — o que o ADR-0011 pede — **assume cada papel e executa**:
leitura em cada objeto declarado das nove camadas, escrita (criar tabela,
revertida) em cada schema, e `insert` na tabela de aterrissagem do caminho
quente. O que a política permite tem de passar; o que ela não permite tem de
falhar com *permission denied*. `set role` avalia privilégios como se o papel
tivesse feito o login (PostgreSQL, SET ROLE), e por isso não há senha nova no
`.env`: quem se conecta é o superusuário, que os assume.
"""

from __future__ import annotations

import json
import os
import pathlib

import psycopg.errors
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import DBAPIError
from sqlalchemy.pool import NullPool

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.governance import PAPEIS

pytestmark = pytest.mark.integracao

RAIZ = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"

#: Governança §7, por camada: quem lê e quem escreve. `streamer` só escreve, e
#: só a própria tabela — a exceção está em EXCECOES.
POLITICA: dict[str, dict[str, list[str]]] = {
    "raw":         {"le": ["transformer"],            "escreve": ["ingestor", "streamer"]},
    "raw_legacy":  {"le": ["transformer"],            "escreve": ["ingestor"]},
    "staging":     {"le": ["transformer"],            "escreve": ["transformer"]},
    "trusted":     {"le": ["transformer"],            "escreve": ["transformer"]},
    "analytics":   {"le": ["transformer"],            "escreve": ["transformer"]},
    "consumption": {"le": ["analyst", "transformer"], "escreve": ["transformer"]},
    "quarantine":  {"le": ["auditor", "transformer"], "escreve": ["transformer"]},
    "snapshots":   {"le": ["transformer"],            "escreve": ["transformer"]},
    "governance":  {"le": ["auditor", "transformer"], "escreve": ["ingestor"]},
}

#: Tabelas cuja concessão difere da camada (ADR-0031): a aterrissagem do
#: caminho quente é escrita pelo Beam, e o `returning` do `insert` lê a chave.
EXCECOES: dict[tuple[str, str], dict[str, list[str]]] = {
    ("raw", "inventory_movements_stream"): {"select": ["streamer", "transformer"], "insert": ["streamer"]},
}

ATERRISSAGEM = ("raw", "inventory_movements_stream")


def _leitores(schema: str, tabela: str) -> set[str]:
    excecao = EXCECOES.get((schema, tabela))
    return set(excecao["select"]) if excecao else set(POLITICA[schema]["le"])


@pytest.fixture(scope="module")
def declaradas() -> dict[tuple[str, str], dict]:
    """`(schema, relação) → {grants, writers}` de tudo o que o dbt declara nas nove camadas."""
    if not MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    saida: dict[tuple[str, str], dict] = {}
    for no in manifest["nodes"].values():
        if no["resource_type"] in ("model", "seed", "snapshot") and no["config"].get("enabled", True):
            saida[(no["schema"], no.get("alias") or no["name"])] = {
                "grants": {p: set(r) for p, r in (no["config"].get("grants") or {}).items()},
                "writers": set((no["config"].get("meta") or {}).get("writers") or []),
            }
    for fonte in manifest["sources"].values():
        meta = fonte.get("meta") or {}  # o dbt funde o `meta` da fonte no de cada tabela
        saida[(fonte["schema"], fonte["identifier"])] = {
            "grants": {p: set(r) for p, r in (meta.get("grants") or {}).items()},
            "writers": set(meta.get("writers") or []),
        }
    return saida


@pytest.fixture(scope="module")
def motor():
    """Conexão de superusuário com o armazém, sem *pool*: `set role` não pode vazar entre probes."""
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    motor = create_engine(database_url(WAREHOUSE), poolclass=NullPool)
    try:
        with motor.connect() as conexao:
            conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover — depende do ambiente
        motor.dispose()
        pytest.skip(f"armazém indisponível: {erro}")
    yield motor
    motor.dispose()


@pytest.fixture(scope="module")
def materializadas(motor, declaradas) -> list[tuple[str, str]]:
    """Objetos declarados que existem no armazém — o que dá para exercitar."""
    with motor.connect() as conexao:
        existentes = set(conexao.execute(text(
            "select table_schema, table_name from information_schema.tables where table_schema = any(:camadas)"
        ), {"camadas": list(POLITICA)}).all())
    alvo = sorted(existentes & set(declaradas))
    if not alvo:
        pytest.skip("armazém sem camadas materializadas; rode `make dbt-build`")
    return alvo


def _negado(erro: DBAPIError) -> bool:
    return isinstance(erro.orig, psycopg.errors.InsufficientPrivilege)


def _tenta(conexao, comando: str) -> bool:
    """Executa como o papel corrente; `True` se passou, `False` se foi *permission denied*.

    Qualquer outro erro sobe: um objeto que não existe ou um comando errado não
    são "acesso negado", e o teste não pode tomá-los por isso.
    """
    try:
        conexao.execute(text(comando))
    except DBAPIError as erro:
        if _negado(erro):
            return False
        raise
    return True


@pytest.fixture(scope="module")
def leituras(motor, materializadas) -> dict[tuple[str, str, str], bool]:
    """`(papel, schema, tabela) → conseguiu ler`, medido papel a papel, objeto a objeto."""
    resultado: dict[tuple[str, str, str], bool] = {}
    for papel in PAPEIS:
        with motor.connect().execution_options(isolation_level="AUTOCOMMIT") as conexao:
            conexao.execute(text(f"set role {papel}"))
            for schema, tabela in materializadas:
                resultado[(papel, schema, tabela)] = _tenta(conexao, f"select 1 from {schema}.{tabela} limit 0")
    return resultado


# ── O declarado é a política ──────────────────────────────────────────────────


def test_o_declarado_e_a_politica_da_governanca(declaradas) -> None:
    """Cada objeto declara exatamente os leitores e os escritores que a §7 fixa para a camada dele."""
    fora = sorted(f"{s}.{t}" for (s, t) in declaradas if s not in POLITICA)
    assert fora == [], f"objetos declarados fora das nove camadas: {fora}"
    sem_objeto = sorted(schema for schema in POLITICA if not any(s == schema for (s, _) in declaradas))
    assert sem_objeto == [], f"camadas da política sem nenhum objeto declarado: {sem_objeto}"

    divergentes: list[str] = []
    for (schema, tabela), declarado in sorted(declaradas.items()):
        esperado = EXCECOES.get((schema, tabela)) or {"select": POLITICA[schema]["le"]}
        grants = {p: set(r) for p, r in esperado.items()}
        if declarado["grants"] != grants:
            divergentes.append(f"{schema}.{tabela}: grants {declarado['grants']!r}, política {grants!r}")
        if declarado["writers"] != set(POLITICA[schema]["escreve"]):
            divergentes.append(f"{schema}.{tabela}: writers {sorted(declarado['writers'])!r}, "
                               f"política {POLITICA[schema]['escreve']!r}")
    assert divergentes == [], "\n".join(divergentes[:15])


def test_a_politica_so_cita_os_papeis_do_adr_0011() -> None:
    citados = {p for regra in POLITICA.values() for lista in regra.values() for p in lista}
    citados |= {p for regra in EXCECOES.values() for lista in regra.values() for p in lista}
    assert citados == set(PAPEIS)


# ── Os papéis existem ─────────────────────────────────────────────────────────


def test_os_papeis_existem_sem_login_e_sem_superpoderes(motor) -> None:
    """Os cinco do ADR-0011, como grupos: sem login, sem `superuser` — e nenhum grupo além deles."""
    with motor.connect() as conexao:
        linhas = conexao.execute(text(
            "select rolname, rolcanlogin, rolsuper from pg_roles where not rolcanlogin and rolname not like 'pg\\_%'"
        )).all()
    grupos = {nome: (login, superuser) for nome, login, superuser in linhas}
    assert set(grupos) == set(PAPEIS), f"grupos no armazém: {sorted(grupos)}"
    assert all(not superuser for _, superuser in grupos.values())


# ── Cada papel, executando ────────────────────────────────────────────────────


def test_cada_papel_le_exatamente_o_que_a_politica_permite(leituras, materializadas, record_property) -> None:
    """Leitura permitida passa; leitura não permitida falha — nos dois sentidos, em todo objeto."""
    divergentes = sorted(
        f"{papel} {'leu' if conseguiu else 'não leu'} {schema}.{tabela}"
        for (papel, schema, tabela), conseguiu in leituras.items()
        if conseguiu != (papel in _leitores(schema, tabela))
    )
    record_property("objects", len(materializadas))
    record_property("probes", len(leituras))
    assert divergentes == [], "\n".join(divergentes[:20])


def test_o_perfil_de_analise_nao_alcanca_raw_staging_nem_trusted(leituras, materializadas) -> None:
    """O critério da Etapa 11, pelo nome: `analyst` lê `consumption` inteira e nada fora dela."""
    alcancou = sorted(f"{s}.{t}" for (p, s, t), ok in leituras.items() if p == "analyst" and ok and s != "consumption")
    assert alcancou == [], f"analyst alcançou: {alcancou}"
    nao_leu = sorted(f"{s}.{t}" for (p, s, t), ok in leituras.items() if p == "analyst" and not ok and s == "consumption")
    assert nao_leu == [], f"analyst não leu em consumption: {nao_leu}"
    assert {s for s, _ in materializadas} >= {"raw", "staging", "trusted", "consumption"}


def test_cada_papel_escreve_so_onde_a_politica_permite(motor, materializadas) -> None:
    """Criar tabela em cada schema, como cada papel, dentro de transação revertida: nada fica."""
    schemas = sorted({s for s, _ in materializadas})
    divergentes: list[str] = []
    for papel in PAPEIS:
        for schema in schemas:
            with motor.connect() as conexao:
                conexao.execute(text(f"set role {papel}"))
                conseguiu = _tenta(conexao, f"create table {schema}.__probe_de_acesso (x int)")
                conexao.rollback()
            if conseguiu != (papel in POLITICA[schema]["escreve"]):
                divergentes.append(f"{papel} {'criou' if conseguiu else 'não criou'} em {schema}")
    assert divergentes == [], "\n".join(divergentes)
    with motor.connect() as conexao:
        sobras = conexao.execute(text(
            "select count(*) from information_schema.tables where table_name = '__probe_de_acesso'"
        )).scalar_one()
    assert sobras == 0


def test_a_aterrissagem_do_caminho_quente_aceita_so_o_streamer(motor, materializadas) -> None:
    """`insert ... returning` na tabela do Beam: só o `streamer`; o `transformer` lê, mas não escreve."""
    if ATERRISSAGEM not in materializadas:
        pytest.skip("raw.inventory_movements_stream ainda não existe; rode `make stream-up`")
    schema, tabela = ATERRISSAGEM
    divergentes: list[str] = []
    for papel in PAPEIS:
        with motor.connect() as conexao:
            conexao.execute(text(f"set role {papel}"))
            conseguiu = _tenta(conexao, f"insert into {schema}.{tabela} select * from {schema}.{tabela} where false "
                                        f"returning movement_id")
            conexao.rollback()
        if conseguiu != (papel in EXCECOES[ATERRISSAGEM]["insert"]):
            divergentes.append(f"{papel} {'inseriu' if conseguiu else 'não inseriu'}")
    assert divergentes == []
