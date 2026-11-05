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
tivesse feito o login (PostgreSQL, SET ROLE), e por isso não há senha por
papel no `.env`: quem se conecta é o superusuário, que os assume.

A exceção é o **login de leitura** (`WAREHOUSE_READER_*`, membro de `analyst`),
e por isso a prova dele é outra: uma conexão de verdade com ele — não `set
role` a partir do superusuário —, que lê `consumption`, é recusada nas demais
camadas, não escreve e não escala.
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

from mvp_ed1.db import WAREHOUSE, database_url, reader_url
from mvp_ed1.governance import FECHADAS_A_PUBLIC, LEITOR_USUARIO, PAPEIS, PAPEL_DO_LEITOR

pytestmark = pytest.mark.integracao

RAIZ = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"

#: Governança §7, por camada: quem lê e quem escreve (`create` no schema).
#: `streamer` não escreve schema nenhum: escreve uma tabela só, e a concessão
#: dela está em EXCECOES — criar outra tabela em `raw` tem de lhe ser negado.
POLITICA: dict[str, dict[str, list[str]]] = {
    "raw":         {"le": ["transformer"],            "escreve": ["ingestor"]},
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


# ── O login de leitura, conectado como ele mesmo ──────────────────────────────


@pytest.fixture(scope="module")
def leitor(motor):
    """Conexão com o login de leitura — a credencial dele, não `set role` do superusuário."""
    if not os.environ.get(LEITOR_USUARIO):
        pytest.fail(f"sem {LEITOR_USUARIO} no .env: acrescente as chaves de .env.example e rode `make dbt-build`")
    leitor = create_engine(reader_url(), poolclass=NullPool)
    yield leitor
    leitor.dispose()


def test_o_login_de_leitura_e_membro_so_de_analyst_e_sem_superpoderes(motor) -> None:
    usuario = os.environ.get(LEITOR_USUARIO)
    with motor.connect() as conexao:
        atributos = conexao.execute(text(
            "select rolcanlogin, rolinherit, rolsuper, rolcreatedb, rolcreaterole, rolreplication, rolbypassrls"
            " from pg_roles where rolname = :u"
        ), {"u": usuario}).one()
        papeis = conexao.execute(text(
            "select g.rolname, m.admin_option from pg_auth_members m join pg_roles g on g.oid = m.roleid"
            " join pg_roles u on u.oid = m.member where u.rolname = :u"
        ), {"u": usuario}).all()
        membros = conexao.execute(text(
            "select count(*) from pg_auth_members m join pg_roles g on g.oid = m.roleid where g.rolname = :u"
        ), {"u": usuario}).scalar_one()
    assert tuple(atributos) == (True, True, False, False, False, False, False)
    assert [tuple(p) for p in papeis] == [(PAPEL_DO_LEITOR, False)]
    assert membros == 0, "alguém herda do login de leitura"


def test_o_login_de_leitura_le_consumption_e_nada_mais(leitor, materializadas, record_property) -> None:
    divergentes: list[str] = []
    with leitor.connect().execution_options(isolation_level="AUTOCOMMIT") as conexao:
        for schema, tabela in materializadas:
            conseguiu = _tenta(conexao, f"select 1 from {schema}.{tabela} limit 0")
            if conseguiu != (schema == "consumption"):
                divergentes.append(f"{'leu' if conseguiu else 'não leu'} {schema}.{tabela}")
    record_property("probes", len(materializadas))
    assert divergentes == [], "\n".join(divergentes[:20])
    assert {s for s, _ in materializadas} >= {"raw", "staging", "trusted", "analytics", "consumption"}


def test_o_login_de_leitura_nao_escreve(leitor, materializadas) -> None:
    """Privilégio, não só o padrão da sessão: cada tentativa pede `read write` antes e é negada."""
    tentativas = [f"create table {s}.__probe_do_leitor (x int)" for s in sorted({s for s, _ in materializadas})]
    tentativas += ["create temporary table __probe_do_leitor (x int)", "create schema __probe_do_leitor"]
    # RVL2-01: os *large objects* ficam fora dos grants de tabela, e os locks são os da captura.
    tentativas += ["select lo_create(0)", "select lo_creat(-1)", "select lo_from_bytea(0, decode('41', 'hex'))",
                   "select pg_advisory_lock(1)", "select pg_try_advisory_lock(1, 2)",
                   "select pg_advisory_xact_lock(1)",
                   # RVL2-2-01: escrita no WAL, que com `false` nem o rollback desfaz — aqui só `true`
                   "select pg_logical_emit_message(true, '__probe_do_leitor', 'revertida')"]
    escreveu: list[str] = []
    for comando in tentativas:
        with leitor.connect() as conexao:
            conexao.execute(text("set transaction read write"))
            if _tenta(conexao, comando):
                escreveu.append(comando)
            conexao.rollback()
    assert escreveu == []
    with leitor.connect() as conexao:
        assert conexao.execute(text("show default_transaction_read_only")).scalar_one() == "on"


def test_nenhuma_assinatura_fechada_a_public_executa_pelo_leitor(motor) -> None:
    """Toda assinatura de cada nome de `FECHADAS_A_PUBLIC`, e não só as que o teste acima chama."""
    with motor.connect() as conexao:
        abertas = conexao.execute(text(
            "select p.oid::regprocedure::text from pg_proc p where p.pronamespace = 'pg_catalog'::regnamespace"
            " and p.proname = any(:n) and has_function_privilege(:u, p.oid, 'execute') order by 1"
        ), {"n": list(FECHADAS_A_PUBLIC), "u": os.environ[LEITOR_USUARIO]}).scalars().all()
        temporaria = conexao.execute(text(
            "select has_database_privilege(:u, current_database(), 'temporary')"
        ), {"u": os.environ[LEITOR_USUARIO]}).scalar_one()
    assert abertas == []
    assert temporaria is False


#: O que continua aberto ao leitor entre as funções **voláteis**, nome a nome e
#: com o motivo (RVL2-2-01). O motivo diz por que a função fica aberta, não que
#: ela não tenha efeito nenhum. O recorte é este, e só este (RVL2-3-05):
#: - **por nome**: uma sobrecarga nova de um nome já classificado não muda o
#:   conjunto e passa;
#: - **só voláteis**: as estáveis e imutáveis ficam fora, inclusive as que têm
#:   efeito interno — `txid_current` e `pg_current_xact_id` são estáveis e alocam
#:   um XID;
#: - fora também as que pedem ou devolvem `internal`, gatilho ou *handler*, que
#:   SQL não chama (`cannot cast type unknown to internal`).
#: Um nome volátil novo numa versão do PostgreSQL faz
#: `test_o_que_fica_aberto_ao_leitor_e_o_classificado` falhar até entrar aqui ou
#: em `governance.FECHADAS_A_PUBLIC`.
ABERTAS_AO_LEITOR: dict[str, tuple[str, ...]] = {
    # Leem o servidor, ou valem só para a própria sessão e transação. `set_config`
    # recusa o parâmetro privilegiado (sondado na revisão do lote 2).
    "leitura ou efeito na própria sessão": (
        "amvalidate", "array_sample", "array_shuffle", "clock_timestamp", "current_query", "currtid2",
        "gen_random_uuid", "pg_blocking_pids",
        "pg_collation_actual_version", "pg_control_checkpoint", "pg_control_init", "pg_control_recovery",
        "pg_control_system", "pg_current_wal_flush_lsn", "pg_current_wal_insert_lsn", "pg_current_wal_lsn",
        "pg_database_collation_actual_version", "pg_database_size",
        "pg_get_multixact_members", "pg_get_wal_replay_pause_state", "pg_get_wal_resource_managers",
        "pg_indexes_size", "pg_is_in_recovery", "pg_is_wal_replay_paused", "pg_isolation_test_session_is_blocked",
        "pg_jit_available", "pg_last_committed_xact", "pg_last_wal_receive_lsn", "pg_last_wal_replay_lsn",
        "pg_last_xact_replay_timestamp", "pg_lock_status", "pg_notification_queue_usage", "pg_partition_ancestors",
        "pg_partition_tree", "pg_prepared_xact", "pg_relation_size", "pg_safe_snapshot_blocking_pids",
        "pg_sleep", "pg_sleep_for", "pg_sleep_until", "pg_stat_clear_snapshot", "pg_stat_force_next_flush",
        "pg_stat_get_io", "pg_stat_get_recovery_prefetch", "pg_stat_get_xact_blocks_fetched",
        "pg_stat_get_xact_blocks_hit", "pg_stat_get_xact_function_calls", "pg_stat_get_xact_function_self_time",
        "pg_stat_get_xact_function_total_time", "pg_stat_get_xact_numscans", "pg_stat_get_xact_tuples_deleted",
        "pg_stat_get_xact_tuples_fetched", "pg_stat_get_xact_tuples_hot_updated",
        "pg_stat_get_xact_tuples_inserted", "pg_stat_get_xact_tuples_newpage_updated",
        "pg_stat_get_xact_tuples_returned", "pg_stat_get_xact_tuples_updated", "pg_table_size",
        "pg_tablespace_size", "pg_total_relation_size", "pg_xact_commit_timestamp",
        "pg_xact_commit_timestamp_origin", "pg_xact_status", "plpgsql_validator",
        "random", "random_normal", "set_config", "setseed", "timeofday", "txid_status",
    ),
    # Executam SQL que quem chama escreve, com o privilégio de quem chama: alcançam
    # o mesmo que o leitor alcança direto — inclusive `pg_notify` dentro do
    # `select` (sondado na rodada 3 do lote 2) —, e nada além (RVL2-3-05).
    "executam SQL de quem chama": (
        "cursor_to_xml", "cursor_to_xmlschema", "query_to_xml", "query_to_xml_and_xmlschema",
        "query_to_xmlschema", "ts_rewrite", "ts_stat",
    ),
    # Efeito interno do servidor, sem dado: o *snapshot* exportado é um arquivo
    # transitório que dura a transação (RVL2-3-05).
    "efeito interno, sem dado": ("pg_export_snapshot",),
    # Ler e soltar: sem criar *large object* nem tomar lock, não há o que ler nem soltar.
    "ler large object, soltar lock": (
        "lo_close", "lo_get", "lo_lseek", "lo_lseek64", "lo_tell", "lo_tell64", "loread",
        "pg_advisory_unlock", "pg_advisory_unlock_all", "pg_advisory_unlock_shared",
    ),
    # O servidor recusa por dentro: atributo de replicação, modo de *upgrade*,
    # superusuário, script de extensão — sondado em `test_o_servidor_recusa_o_que_verifica_por_dentro`.
    "verificadas pelo servidor": (
        "binary_upgrade_create_empty_extension", "binary_upgrade_set_missing_value",
        "binary_upgrade_set_next_array_pg_type_oid", "binary_upgrade_set_next_heap_pg_class_oid",
        "binary_upgrade_set_next_heap_relfilenode", "binary_upgrade_set_next_index_pg_class_oid",
        "binary_upgrade_set_next_index_relfilenode", "binary_upgrade_set_next_multirange_array_pg_type_oid",
        "binary_upgrade_set_next_multirange_pg_type_oid", "binary_upgrade_set_next_pg_authid_oid",
        "binary_upgrade_set_next_pg_enum_oid", "binary_upgrade_set_next_pg_tablespace_oid",
        "binary_upgrade_set_next_pg_type_oid", "binary_upgrade_set_next_toast_pg_class_oid",
        "binary_upgrade_set_next_toast_relfilenode", "binary_upgrade_set_record_init_privs",
        "pg_copy_logical_replication_slot", "pg_copy_physical_replication_slot",
        "pg_create_logical_replication_slot", "pg_create_physical_replication_slot", "pg_drop_replication_slot",
        "pg_logical_slot_get_binary_changes", "pg_logical_slot_get_changes", "pg_logical_slot_peek_binary_changes",
        "pg_logical_slot_peek_changes", "pg_replication_slot_advance",
        "pg_extension_config_dump", "pg_import_system_collations", "pg_nextoid", "pg_read_file_old",
        "pg_rotate_logfile_old", "pg_stop_making_pinned_objects",
    ),
    # Pedem o objeto: dono do índice BRIN/GIN, privilégio na sequência. O armazém
    # não tem nenhum dos dois — `test_o_servidor_recusa_o_que_verifica_por_dentro`
    # confere, e um que apareça obriga a sondá-lo.
    "verificadas no objeto": (
        "brin_desummarize_range", "brin_summarize_new_values", "brin_summarize_range", "gin_clean_pending_list",
        "currval", "lastval", "nextval", "pg_sequence_last_value", "setval",
    ),
    # Interferem, dentro do limite que a Governança §7 declara (RVL2-2-05): o
    # sinal só alcança sessão do próprio login, e `notify` é comando SQL também.
    "interferência declarada": ("pg_cancel_backend", "pg_notify", "pg_terminate_backend"),
}

#: Uma chamada de cada família verificada pelo servidor, com o SQLSTATE da recusa.
#: `{pid}` é uma sessão do superusuário, ociosa, aberta pelo próprio teste. Todo
#: slot pedido é **temporário** — some com a sessão que o criou —, e o teste ainda
#: apaga, como superusuário, qualquer `__probe_do_leitor*` que sobre (RVL2-3-01).
RECUSADAS_POR_DENTRO: tuple[tuple[str, str], ...] = (
    ("select pg_create_physical_replication_slot('__probe_do_leitor', false, true)", "42501"),
    ("select pg_create_logical_replication_slot('__probe_do_leitor', 'test_decoding', true, false)", "42501"),
    ("select pg_drop_replication_slot('__probe_do_leitor')", "42501"),
    ("select pg_replication_slot_advance('__probe_do_leitor', '0/0')", "42501"),
    ("select pg_copy_logical_replication_slot('__probe_do_leitor', '__probe_do_leitor_b', true)", "42501"),
    ("select * from pg_logical_slot_get_changes('__probe_do_leitor', null, null)", "42501"),
    ("select binary_upgrade_set_next_pg_type_oid(1)", "55P02"),
    ("select binary_upgrade_set_record_init_privs(false)", "55P02"),
    ("select pg_nextoid('pg_class', 'oid', 'pg_class_oid_index')", "42501"),
    ("select pg_stop_making_pinned_objects()", "42501"),
    ("select pg_import_system_collations('public')", "42501"),
    ("select pg_read_file_old('/etc/hostname', 0, 1)", "42501"),
    ("select pg_rotate_logfile_old()", "42501"),
    ("select pg_extension_config_dump('consumption.monthly_revenue_by_channel_and_category', '')", "0A000"),
    ("select set_config('session_replication_role', 'replica', true)", "42501"),
    ("select pg_cancel_backend({pid})", "42501"),
    ("select pg_terminate_backend({pid}, 0)", "42501"),
)

_CHAMAVEIS = (
    "p.provolatile = 'v' and has_function_privilege(:u, p.oid, 'execute')"
    " and p.prorettype not in ('internal'::regtype, 'language_handler'::regtype, 'trigger'::regtype,"
    " 'event_trigger'::regtype, 'table_am_handler'::regtype, 'index_am_handler'::regtype,"
    " 'tsm_handler'::regtype, 'fdw_handler'::regtype)"
    " and not ('internal'::regtype = any(p.proargtypes::regtype[]))"
)


def test_o_que_fica_aberto_ao_leitor_e_o_classificado(motor) -> None:
    """RVL2-2-01: a lista de fechadas era argumento; este é o oráculo do que sobra."""
    with motor.connect() as conexao:
        abertas = set(conexao.execute(text(
            f"select distinct p.proname from pg_proc p where {_CHAMAVEIS}"
            " and p.pronamespace = 'pg_catalog'::regnamespace"
        ), {"u": os.environ[LEITOR_USUARIO]}).scalars())
        fora_do_catalogo = conexao.execute(text(
            f"select p.oid::regprocedure::text from pg_proc p where {_CHAMAVEIS}"
            " and p.pronamespace <> 'pg_catalog'::regnamespace order by 1"
        ), {"u": os.environ[LEITOR_USUARIO]}).scalars().all()
    classificadas = set().union(*ABERTAS_AO_LEITOR.values())
    assert sum(map(len, ABERTAS_AO_LEITOR.values())) == len(classificadas), "nome em dois motivos"
    assert not classificadas & set(FECHADAS_A_PUBLIC)
    assert sorted(abertas - classificadas) == [], "aberta ao leitor sem classificação"
    assert sorted(classificadas - abertas) == [], "classificada que o leitor já não alcança"
    assert fora_do_catalogo == [], "função volátil de usuário executável pelo leitor"


def test_o_servidor_recusa_o_que_verifica_por_dentro(motor, leitor) -> None:
    """As famílias de "verificadas pelo servidor", chamadas pelo leitor: cada uma recusada, e nada fica."""
    with motor.connect() as conexao:
        objetos = conexao.execute(text(
            "select (select count(*) from pg_class c join pg_am a on a.oid = c.relam"
            "        where c.relkind = 'i' and a.amname in ('brin', 'gin')),"
            "       (select count(*) from pg_class where relkind = 'S')"
        )).one()
    assert tuple(objetos) == (0, 0), "índice BRIN/GIN ou sequência no armazém: sonde as \"verificadas no objeto\""
    aceitas: list[str] = []
    try:
        with motor.connect() as alvo:
            pid = alvo.execute(text("select pg_backend_pid()")).scalar_one()
            for comando, esperado in RECUSADAS_POR_DENTRO:
                with leitor.connect() as conexao:
                    conexao.execute(text("set transaction read write"))
                    try:
                        conexao.execute(text(comando.format(pid=pid)))
                        aceitas.append(comando)
                    except DBAPIError as erro:
                        assert erro.orig.sqlstate == esperado, (comando, erro.orig.sqlstate, str(erro.orig))
                    conexao.rollback()
            assert alvo.execute(text("select 1")).scalar_one() == 1, "a sessão-alvo foi encerrada"
    finally:
        # A limpeza não depende da permissão que está sendo testada: quem apaga é o superusuário.
        with motor.begin() as conexao:
            sobras = conexao.execute(text(
                "select slot_name from pg_replication_slots where slot_name like :p"
            ), {"p": r"\_\_probe\_do\_leitor%"}).scalars().all()
            for slot in sobras:
                conexao.execute(text("select pg_drop_replication_slot(:s)"), {"s": slot})
    assert aceitas == []
    assert sobras == [], "slot de sonda criado pelo leitor"


def test_padrao_que_o_leitor_tira_de_si_volta_no_garantir(motor, leitor) -> None:
    """RVL2-3-07: o leitor tira o próprio padrão de leitura, no banco e no global, e o `garantir()` repõe.

    O padrão por banco vence o global: repor só o global o deixava valendo."""
    from mvp_ed1 import governance

    usuario = os.environ[LEITOR_USUARIO]
    with motor.connect() as conexao:
        banco = conexao.execute(text("select current_database()")).scalar_one()
    ajustes = text(
        "select coalesce(d.datname, '*'), s.setconfig from pg_db_role_setting s"
        " left join pg_database d on d.oid = s.setdatabase where s.setrole = to_regrole(:u) order by 1"
    )
    try:
        with leitor.connect() as conexao:
            conexao.execute(text("set transaction read write"))
            conexao.exec_driver_sql(f'alter role {usuario} in database "{banco}" set default_transaction_read_only = off')
            conexao.exec_driver_sql(f"alter role {usuario} set statement_timeout = '1h'")
            conexao.commit()
        with leitor.connect() as conexao:
            assert conexao.execute(text("show default_transaction_read_only")).scalar_one() == "off"
        governance.garantir(motor, governance.leitor_do_ambiente())
        with leitor.connect() as conexao:
            assert conexao.execute(text("show default_transaction_read_only")).scalar_one() == "on"
            assert conexao.execute(text("show statement_timeout")).scalar_one() == "0"
        with motor.connect() as conexao:
            assert [tuple(l) for l in conexao.execute(ajustes, {"u": usuario})] == [
                ("*", ["default_transaction_read_only=on"])
            ]
    finally:
        with motor.begin() as conexao:
            conexao.exec_driver_sql(f'alter role {usuario} in database "{banco}" reset all')
            conexao.exec_driver_sql(f"alter role {usuario} reset all")
            conexao.exec_driver_sql(f"alter role {usuario} set default_transaction_read_only = on")


def test_membro_com_nome_que_fecharia_o_identificador_sai_sem_injetar(motor) -> None:
    """RVL2-02 com papel de verdade: o `garantir()` o tira do leitor e não executa o resto do nome."""
    from mvp_ed1 import governance

    usuario, nome = os.environ[LEITOR_USUARIO], 'x" from consumption_reader; alter role analyst superuser; --'
    with motor.begin() as conexao:
        conexao.exec_driver_sql(f'create role "{nome.replace(chr(34), chr(34) * 2)}" nologin')
        conexao.exec_driver_sql(f'grant "{nome.replace(chr(34), chr(34) * 2)}" to {usuario}')
    try:
        governance.garantir(motor, governance.leitor_do_ambiente())
        with motor.connect() as conexao:
            membro = conexao.execute(text(
                "select count(*) from pg_auth_members m join pg_roles g on g.oid = m.roleid"
                " join pg_roles u on u.oid = m.member where u.rolname = :u and g.rolname = :n"
            ), {"u": usuario, "n": nome}).scalar_one()
            super_ = conexao.execute(text("select rolsuper from pg_roles where rolname = 'analyst'")).scalar_one()
        assert membro == 0
        assert super_ is False
    finally:
        with motor.begin() as conexao:
            conexao.exec_driver_sql(f'drop role if exists "{nome.replace(chr(34), chr(34) * 2)}"')


def test_o_login_de_leitura_nao_escala(leitor) -> None:
    superusuario = os.environ["WAREHOUSE_DB_USER"]
    tentativas = [f"set role {p}" for p in PAPEIS if p != PAPEL_DO_LEITOR]
    tentativas += [
        f"set role {superusuario}",
        f"set session authorization {superusuario}",
        f"alter role {os.environ[LEITOR_USUARIO]} createrole",
        f"grant {PAPEL_DO_LEITOR} to auditor",
        "create role __probe_do_leitor",
    ]
    escalou: list[str] = []
    for comando in tentativas:
        with leitor.connect() as conexao:
            conexao.execute(text("set transaction read write"))
            if _tenta(conexao, comando):
                escalou.append(comando)
            conexao.rollback()
    assert escalou == []
