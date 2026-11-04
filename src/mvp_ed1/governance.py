"""O schema `governance` do armazém — DDL versionado, idempotente e com teste.

O [ADR-0023] declarou o schema e fechou o seu escopo em quatro conjuntos; o
[ADR-0044] materializa a primeira tabela do conjunto "log de execução":
`legacy_captures`, o certificado por *stream* de cada captura do legado. O
armazém não tem Alembic (o ADR-0010 não o exige ali), então o ciclo de vida
destas tabelas vive aqui: uma lista **ordenada** de migrações, cada uma
idempotente, aplicadas por `garantir()` e registradas em `governance._versions`.
Acrescentar coluna é acrescentar uma migração à lista — nunca editar a anterior.

Os papéis de acesso do [ADR-0011] nascem aqui pela mesma razão: são objetos do
*cluster*, não do dbt, e um `init` do contêiner só roda com o volume vazio — um
armazém já povoado nunca os receberia. `garantir()` os cria se faltarem, a cada
execução, no ambiente novo e no existente. O que cada papel alcança não está
aqui: é declarado camada a camada no dbt (`+grants`, `meta.writers`,
`meta.grants`) e aplicado ao fim de cada execução
(`macros/aplicar_acesso_por_camada.sql`).

O **login de leitura** nasce aqui pela mesma razão (N4 do plano do
`bi-como-codigo`, v1.1.0): o primeiro consumidor que se conecta como membro do
próprio papel, em vez do superusuário. Ver `_garantir_leitor`.

Se a Etapa 11 decidir levar o armazém para o Alembic, esta lista é o que vira
histórico; até lá, é o que impede DDL solto.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import os
import re
import secrets

from sqlalchemy import Engine, text

SCHEMA = "governance"

#: Papéis de acesso (ADR-0011, Governança §7), na ordem da tabela. São grupos de
#: privilégio **sem login**: quem se conecta é membro de um deles — hoje o único
#: login do armazém é o superusuário do `.env`, que os assume por `set role`.
#: Sem login não há senha nova no `.env`, e o equivalente na fase GCP é o mesmo:
#: grupo IAM ou conta de serviço, nunca uma credencial por papel.
PAPEIS: tuple[str, ...] = ("ingestor", "transformer", "streamer", "analyst", "auditor")

_DESCRICAO_DOS_PAPEIS: dict[str, str] = {
    "ingestor": "Escreve raw e raw_legacy (Airbyte) e o certificado de captura em governance; lê só o que é seu.",
    "transformer": "Escreve staging, trusted, analytics, consumption, quarantine e snapshots (dbt); lê as camadas anteriores.",
    "streamer": "Escreve raw.inventory_movements_stream (Beam, ADR-0031); nada mais.",
    "analyst": "Lê consumption, e só consumption — o contrato de consumo é a view (ADR-0008).",
    "auditor": "Lê quarantine e governance; não escreve.",
}

#: Variáveis do `.env` com o login de leitura. O banco, a porta e o host são os
#: do armazém (`WAREHOUSE_DB_*`): muda só quem se conecta.
LEITOR_USUARIO = "WAREHOUSE_READER_USER"
LEITOR_SENHA = "WAREHOUSE_READER_PASSWORD"

#: O papel do leitor — e o único. Membro de `analyst`, ele lê o que `analyst` lê.
PAPEL_DO_LEITOR = "analyst"

#: Conferidos com `fullmatch`: `$` com `match` aceitava um `\n` no fim (RVL2-02).
_NOME = re.compile(r"[a-z_][a-z0-9_]{0,62}")
#: A forma que `make env` gera. Mais estreita que o necessário de propósito: a
#: senha nunca precisa de escape, e uma senha curta ou estranha é recusada.
_SENHA = re.compile(r"[A-Za-z0-9]{24,}")

#: Funções do `pg_catalog` que o PostgreSQL deixa a `PUBLIC` e que fazem um
#: login sem nenhum grant escrever ou interferir (RVL2-01, revisão do lote 2 da
#: v1.1.0): os *large objects* ficam fora dos grants de tabela — o leitor os
#: criava pedindo `read write` —, e os *advisory locks* são os mesmos com que a
#: captura marca chamador vivo (`legacy.captura.bloqueio_da_tentativa`): um
#: leitor que tomasse o de uma tentativa a deixaria pendente para sempre. Toda
#: assinatura de cada nome sai de `PUBLIC`; o superusuário, que é quem captura,
#: carrega e transforma, não depende de `EXECUTE`. Ler um *large object* e soltar
#: um lock ficam: sem criar nem tomar, não há o que ler nem o que soltar.
FECHADAS_A_PUBLIC: tuple[str, ...] = (
    "lo_creat", "lo_create", "lo_from_bytea", "lo_open", "lo_put", "lowrite",
    "lo_truncate", "lo_truncate64", "lo_unlink",
    "pg_advisory_lock", "pg_advisory_lock_shared", "pg_advisory_xact_lock", "pg_advisory_xact_lock_shared",
    "pg_try_advisory_lock", "pg_try_advisory_lock_shared", "pg_try_advisory_xact_lock",
    "pg_try_advisory_xact_lock_shared",
)

#: Migrações em ordem: (nome, comandos). Cada comando é idempotente por si.
MIGRACOES: tuple[tuple[str, tuple[str, ...]], ...] = (
    (
        "0001_legacy_captures",
        (
            f"create schema if not exists {SCHEMA}",
            f"""
            create table if not exists {SCHEMA}.legacy_captures (
                capture_attempt_id   text        not null,
                source_table         text        not null,
                connection_name      text        not null,
                job_id               bigint,
                snapshot_id          bigint,
                source_rows_before   integer     not null,
                source_hash_before   text        not null,
                source_rows_after    integer,
                source_hash_after    text,
                received_rows        integer,
                received_hash        text,
                sync_id_matches      boolean,
                status               text        not null,
                started_at           timestamptz not null,
                completed_at         timestamptz,
                primary key (capture_attempt_id, source_table),
                constraint ck_legacy_captures_status check (
                    status in ('pending', 'complete', 'unstable', 'incomplete', 'inconsistent', 'abandoned')
                )
            )
            """,
            f"""
            comment on table {SCHEMA}.legacy_captures is
            'Certificado por stream de cada captura do legado (ADR-0044): origem antes e depois do job, bruto recebido, vínculo com o job. Lido pelo fluxo só para elegibilidade.'
            """,
            f"create index if not exists ix_legacy_captures_snapshot on {SCHEMA}.legacy_captures (snapshot_id, status)",
        ),
    ),
    (
        # A identidade da captura passou a ser o job (`schema.CAPTURA_SQL`),
        # não a geração do Airbyte, que é por stream. Os certificados já
        # gravados carregavam a geração; passam a carregar o job — o mesmo
        # dado que já estava em `job_id`.
        "0002_snapshot_id_e_o_job",
        (
            f"update {SCHEMA}.legacy_captures set snapshot_id = job_id where job_id is not null",
            f"comment on column {SCHEMA}.legacy_captures.snapshot_id is "
            "'Identidade da captura = job de sincronização (_airbyte_meta.sync_id); desde 15/09/2026, não a geração, que é por stream.'",
        ),
    ),
)


def _garantir_papeis(conexao) -> None:
    """Cria os papéis que faltam. Não é migração de propósito: migração roda uma
    vez, e um papel apagado à mão só voltaria com outra migração; aqui ele volta
    na execução seguinte. `create role` não tem `if not exists` — o bloco `do`
    faz as vezes. Os papéis são criados, nunca alterados nem apagados por aqui;
    o que cada um alcança é assunto do dbt (ver docstring do módulo)."""
    for papel in PAPEIS:
        conexao.execute(
            text(
                f"""
                do $$
                begin
                    if not exists (select from pg_roles where rolname = '{papel}') then
                        create role {papel} nologin;
                    end if;
                end
                $$
                """
            )
        )
        conexao.execute(text(f"comment on role {papel} is '{_DESCRICAO_DOS_PAPEIS[papel]}'"))


def _verificador_scram(senha: str, iteracoes: int = 4096) -> str:
    """O verificador SCRAM-SHA-256 da senha, calculado aqui (RFC 5802, RFC 7677).

    É o que o PostgreSQL guarda de qualquer forma; mandá-lo pronto faz a senha
    em texto nunca chegar ao servidor — nem a um log de comandos, se alguém o
    ligar. É o que o `\\password` do `psql` faz. A normalização SASLprep do RFC
    não muda nada aqui: `_SENHA` só aceita ASCII alfanumérico."""
    sal = secrets.token_bytes(16)
    salgada = hashlib.pbkdf2_hmac("sha256", senha.encode(), sal, iteracoes)
    cliente = hmac.new(salgada, b"Client Key", hashlib.sha256).digest()
    servidor = hmac.new(salgada, b"Server Key", hashlib.sha256).digest()
    b64 = lambda b: base64.b64encode(b).decode()  # noqa: E731
    return f"SCRAM-SHA-256${iteracoes}:{b64(sal)}${b64(hashlib.sha256(cliente).digest())}:{b64(servidor)}"


def leitor_do_ambiente(ambiente: dict[str, str] | None = None) -> tuple[str, str] | None:
    """`(usuário, senha)` do login de leitura, ou `None` se o `.env` não o declara."""
    ambiente = os.environ if ambiente is None else ambiente
    usuario, senha = ambiente.get(LEITOR_USUARIO), ambiente.get(LEITOR_SENHA)
    if not usuario and not senha:
        return None
    if not usuario or not senha:
        raise RuntimeError(f"defina {LEITOR_USUARIO} e {LEITOR_SENHA} juntos no .env, ou nenhum dos dois")
    if not _NOME.fullmatch(usuario) or usuario in PAPEIS or usuario == ambiente.get("WAREHOUSE_DB_USER"):
        raise RuntimeError(f"{LEITOR_USUARIO} inválido: um nome novo, minúsculo, que não seja papel nem o superusuário")
    if not _SENHA.fullmatch(senha):
        raise RuntimeError(f"{LEITOR_SENHA} fora da forma de `make env`: 24 ou mais letras e dígitos")
    return usuario, senha


def _garantir_leitor(conexao, usuario: str, senha: str) -> None:
    """O login de leitura, inteiro, a cada execução — como os papéis.

    Membro de `analyst` e de nada mais, sem `admin option`; sem nenhum dos
    atributos que escalam (`superuser`, `createdb`, `createrole`, `replication`,
    `bypassrls`); leitura como padrão da sessão; e a senha do `.env`, reposta a
    cada vez, para que o `.env` seja sempre a verdade. O que já estiver diferente
    é desfeito — o mesmo princípio do `on-run-end`, que revoga o não declarado.

    E `temporary` sai de `PUBLIC` no banco, com as funções de `FECHADAS_A_PUBLIC`:
    sem isso, todo login cria tabela temporária e *large object* e toma os locks
    da captura, e "não escreve" teria exceções. Os demais logins são o
    superusuário, a quem a revogação não alcança.

    O que vem do catálogo — os papéis de que o login é membro, o nome do banco,
    as assinaturas das funções — se compõe no servidor, com `format('%I')`, e
    nunca passa por texto Python (RVL2-02). O que vem do `.env` já chega
    validado por `leitor_do_ambiente`."""
    conexao.execute(text(
        f"""
        do $$
        begin
            if not exists (select from pg_roles where rolname = '{usuario}') then
                create role {usuario} login;
            end if;
        end
        $$
        """
    ))
    # `exec_driver_sql`, e não `text()`: os `:` do verificador virariam parâmetros.
    # Na falha, o comando não sobe com o erro — ele leva o verificador.
    try:
        conexao.exec_driver_sql(
            f"alter role {usuario} with login inherit nosuperuser nocreatedb nocreaterole noreplication "
            f"nobypassrls password '{_verificador_scram(senha)}'"
        )
    except Exception as erro:
        raise RuntimeError(f"não foi possível definir o login {usuario}: {type(erro.__cause__ or erro).__name__}") from None
    conexao.execute(text(f"alter role {usuario} set default_transaction_read_only = on"))
    conexao.execute(text(
        f"""
        do $$
        declare r record;
        begin
            for r in select g.rolname from pg_auth_members m join pg_roles g on g.oid = m.roleid
                     join pg_roles u on u.oid = m.member
                     where u.rolname = '{usuario}' and g.rolname <> '{PAPEL_DO_LEITOR}' loop
                execute format('revoke %I from %I', r.rolname, '{usuario}');
            end loop;
        end
        $$
        """
    ))
    conexao.execute(text(f"revoke admin option for {PAPEL_DO_LEITOR} from {usuario}"))
    conexao.execute(text(f"grant {PAPEL_DO_LEITOR} to {usuario}"))
    conexao.execute(text(f"comment on role {usuario} is 'Login só de leitura, membro de {PAPEL_DO_LEITOR}: o consumidor de fora do armazém (v1.1.0).'"))
    _fechar_a_public(conexao)


def _fechar_a_public(conexao) -> None:
    """`temporary` no banco e `EXECUTE` em cada assinatura de `FECHADAS_A_PUBLIC`, tirados de `PUBLIC`.

    Um nome da lista que o `pg_catalog` não tem é erro, não pulo: uma versão do
    PostgreSQL que o renomeasse deixaria o caminho aberto calada."""
    existentes = set(conexao.execute(text(
        "select distinct proname from pg_proc where pronamespace = 'pg_catalog'::regnamespace and proname = any(:n)"
    ), {"n": list(FECHADAS_A_PUBLIC)}).scalars().all())
    if faltam := sorted(set(FECHADAS_A_PUBLIC) - existentes):
        raise RuntimeError(f"funções a fechar que o pg_catalog não tem: {faltam}")
    nomes = ", ".join(f"'{n}'" for n in FECHADAS_A_PUBLIC)
    conexao.execute(text(
        f"""
        do $$
        declare r record;
        begin
            execute format('revoke temporary on database %I from public', current_database());
            for r in select p.oid::regprocedure as f from pg_proc p
                     where p.pronamespace = 'pg_catalog'::regnamespace and p.proname in ({nomes}) loop
                execute format('revoke execute on function %s from public', r.f);
            end loop;
        end
        $$
        """
    ))


def garantir_papeis(engine: Engine) -> None:
    """Só os papéis, sem as migrações — o que a restauração pede antes do `pg_restore` do armazém.

    O dump da memória traz os `GRANT`s de `governance`, `quarantine`, `snapshots` e `raw_legacy` para
    estes papéis, e num armazém recém-criado por `make up` eles ainda não existem: o `pg_restore`
    recusava e desfazia o dump inteiro (RVB5-01). Papel é do *cluster*, não do dump — criá-lo antes
    não conflita com o `--clean` da restauração, e as migrações ficam para o dump trazer."""
    with engine.begin() as conexao:
        _garantir_papeis(conexao)


def garantir(engine: Engine, leitor: tuple[str, str] | None = None) -> list[str]:
    """Aplica as migrações que faltam e devolve os nomes aplicados nesta chamada.

    Com `leitor`, garante também o login de leitura (`_garantir_leitor`)."""
    aplicadas: list[str] = []
    with engine.begin() as conexao:
        conexao.execute(text(f"create schema if not exists {SCHEMA}"))
        conexao.execute(
            text(
                f"create table if not exists {SCHEMA}._versions "
                "(nome text primary key, aplicada_em timestamptz not null default now())"
            )
        )
        feitas = {
            linha[0] for linha in conexao.execute(text(f"select nome from {SCHEMA}._versions"))
        }
        for nome, comandos in MIGRACOES:
            if nome in feitas:
                continue
            for comando in comandos:
                conexao.execute(text(comando))
            conexao.execute(text(f"insert into {SCHEMA}._versions (nome) values (:n)"), {"n": nome})
            aplicadas.append(nome)
        _garantir_papeis(conexao)
        if leitor is not None:
            _garantir_leitor(conexao, *leitor)
    return aplicadas


def versoes(engine: Engine) -> list[str]:
    with engine.connect() as conexao:
        try:
            return [
                linha[0]
                for linha in conexao.execute(
                    text(f"select nome from {SCHEMA}._versions order by aplicada_em, nome")
                )
            ]
        except Exception:  # noqa: BLE001 — schema ainda não existe
            return []


def main(argv: list[str] | None = None) -> int:
    """`python -m mvp_ed1.governance garantir` — o que `make dbt-build` chama antes de compilar."""
    import argparse

    from sqlalchemy import create_engine

    from mvp_ed1.db import WAREHOUSE, database_url

    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.governance")
    parser.add_argument("comando", choices=["garantir", "versoes"])
    args = parser.parse_args(argv)
    engine = create_engine(database_url(WAREHOUSE))
    if args.comando == "garantir":
        leitor = leitor_do_ambiente()
        aplicadas = garantir(engine, leitor)
        print("governance: " + (", ".join(aplicadas) if aplicadas else "nada a aplicar"))
        if leitor is None:
            print(f"governance: aviso — sem {LEITOR_USUARIO} no .env, o login de leitura não foi garantido")
    else:
        print("\n".join(versoes(engine)) or "governance: nenhuma migração aplicada")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
