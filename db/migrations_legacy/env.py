"""Ambiente de execução das migrações do **legado** (ADR-0010, segunda origem).

Mesma regra da origem principal: a URL sai de `mvp_ed1.db` a partir do
ambiente, e nenhuma credencial vive no `alembic.ini`. A declaração migrada é
`legacy.schema.metadata()` — as quarenta tabelas frouxas —, e o filtro de
objetos restringe o `autogenerate` ao schema `legacy`, para que ele nunca
proponha derrubar o que não é do projeto.
"""

from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

from mvp_ed1.db import LEGACY, database_url
from mvp_ed1.legacy import schema

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = schema.metadata()


def include_object(obj, name, type_, reflected, compare_to) -> bool:
    if type_ == "table":
        return obj.schema == schema.SCHEMA
    return True


def run_migrations_offline() -> None:
    context.configure(
        url=database_url(LEGACY),
        target_metadata=target_metadata,
        literal_binds=True,
        include_schemas=True,
        include_object=include_object,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    engine = create_engine(database_url(LEGACY), poolclass=pool.NullPool)
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
