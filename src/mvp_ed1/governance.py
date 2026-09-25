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

Se a Etapa 11 decidir levar o armazém para o Alembic, esta lista é o que vira
histórico; até lá, é o que impede DDL solto.
"""

from __future__ import annotations

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


def garantir_papeis(engine: Engine) -> None:
    """Só os papéis, sem as migrações — o que a restauração pede antes do `pg_restore` do armazém.

    O dump da memória traz os `GRANT`s de `governance`, `quarantine`, `snapshots` e `raw_legacy` para
    estes papéis, e num armazém recém-criado por `make up` eles ainda não existem: o `pg_restore`
    recusava e desfazia o dump inteiro (RVB5-01). Papel é do *cluster*, não do dump — criá-lo antes
    não conflita com o `--clean` da restauração, e as migrações ficam para o dump trazer."""
    with engine.begin() as conexao:
        _garantir_papeis(conexao)


def garantir(engine: Engine) -> list[str]:
    """Aplica as migrações que faltam e devolve os nomes aplicados nesta chamada."""
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
        aplicadas = garantir(engine)
        print("governance: " + (", ".join(aplicadas) if aplicadas else "nada a aplicar"))
    else:
        print("\n".join(versoes(engine)) or "governance: nenhuma migração aplicada")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
