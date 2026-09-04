"""Ambiente de execução das migrações (ADR-0010).

A URL do banco vem de `mvp_ed1.db`, que a monta a partir de variáveis de
ambiente: o `alembic.ini` não contém credencial alguma.
"""

from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

from mvp_ed1.db import database_url
from mvp_ed1.models import SCHEMA, Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

#: Os modelos são a fonte de verdade do schema (ADR-0009).
target_metadata = Base.metadata


def include_object(obj, name, type_, reflected, compare_to) -> bool:
    """Ignora tudo que não pertence ao schema da origem transacional.

    Sem este filtro, o `autogenerate` proporia derrubar objetos que não são do
    projeto — inclusive a própria tabela de versão do Alembic.
    """
    if type_ == "table":
        return obj.schema == SCHEMA
    return True


def run_migrations_offline() -> None:
    context.configure(
        url=database_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        include_schemas=True,
        include_object=include_object,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    engine = create_engine(database_url(), poolclass=pool.NullPool)
    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            include_schemas=True,
            include_object=include_object,
            compare_type=True,
            compare_server_default=True,
        )
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
