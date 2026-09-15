"""O schema `governance` do armazém — DDL versionado, idempotente e com teste.

O [ADR-0023] declarou o schema e fechou o seu escopo em quatro conjuntos; o
[ADR-0044] materializa a primeira tabela do conjunto "log de execução":
`legacy_captures`, o certificado por *stream* de cada captura do legado. O
armazém não tem Alembic (o ADR-0010 não o exige ali), então o ciclo de vida
destas tabelas vive aqui: uma lista **ordenada** de migrações, cada uma
idempotente, aplicadas por `garantir()` e registradas em `governance._versions`.
Acrescentar coluna é acrescentar uma migração à lista — nunca editar a anterior.

Se a Etapa 11 decidir levar o armazém para o Alembic, esta lista é o que vira
histórico; até lá, é o que impede DDL solto.
"""

from __future__ import annotations

from sqlalchemy import Engine, text

SCHEMA = "governance"

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
