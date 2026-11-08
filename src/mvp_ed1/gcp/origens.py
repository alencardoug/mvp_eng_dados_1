"""As origens no Cloud SQL: o atributo de replicação do usuário da origem (Etapa 13, G2.3).

O Debezium Server lê o `source_db` pelo usuário da origem (`terraform/aplicacoes_gke.tf`), e o
`pgoutput` pede o atributo `REPLICATION` nele. No Cloud SQL quem o concede é um membro do
`cloudsqlsuperuser` — o usuário criado pela API é —, e não há superusuário de verdade. O ambiente
é o que o `make gcp-origens-replicacao` monta: o proxy local e a senha do Secret Manager.

    python -m mvp_ed1.gcp.origens replicacao
"""

from __future__ import annotations

import argparse
import sys

CONCEDER = "alter role current_user with replication"
CONFERIR = "select rolreplication from pg_roles where rolname = current_user"


def replicacao(engine) -> tuple[bool, bool]:
    """(tinha antes, tem depois). Concede só se faltar; a conferência é pelo catálogo."""
    from sqlalchemy import text

    with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conexao:
        antes = bool(conexao.execute(text(CONFERIR)).scalar_one())
        if not antes:
            conexao.execute(text(CONCEDER))
        depois = bool(conexao.execute(text(CONFERIR)).scalar_one())
    return antes, depois


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.gcp.origens", description=__doc__.split("\n")[0])
    ap.add_argument("comando", choices=["replicacao"])
    ap.parse_args(argv)

    from sqlalchemy import create_engine

    from mvp_ed1.db import SOURCE, database_url

    engine = create_engine(database_url(SOURCE))
    try:
        antes, depois = replicacao(engine)
    finally:
        engine.dispose()
    if not depois:
        print("ERRO: o usuário da origem continua sem REPLICATION", file=sys.stderr)
        return 1
    print("replicação: " + ("já concedida" if antes else "concedida agora") + "; conferida em pg_roles")
    return 0


if __name__ == "__main__":
    sys.exit(main())
