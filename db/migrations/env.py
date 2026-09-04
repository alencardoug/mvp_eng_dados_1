"""Ambiente de execução das migrações (ADR-0010).

A URL do banco é montada aqui, a partir de variáveis de ambiente, e nunca é
lida de arquivo versionado: o `alembic.ini` não contém credencial alguma.
"""

from __future__ import annotations

import os
from logging.config import fileConfig
from urllib.parse import quote_plus

from alembic import context
from sqlalchemy import create_engine, pool

from mvp_ed1.models import SCHEMA, Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

#: Os modelos são a fonte de verdade do schema (ADR-0009).
target_metadata = Base.metadata

_REQUIRED = ("SOURCE_DB_USER", "SOURCE_DB_PASSWORD", "SOURCE_DB_NAME", "SOURCE_DB_PORT")


def database_url() -> str:
    missing = [name for name in _REQUIRED if not os.environ.get(name)]
    if missing:
        raise RuntimeError(
            "variáveis de ambiente ausentes: " + ", ".join(missing) + ". "
            "Rode as migrações por `make migrate`, que carrega o .env."
        )
    user = quote_plus(os.environ["SOURCE_DB_USER"])
    password = quote_plus(os.environ["SOURCE_DB_PASSWORD"])
    host = os.environ.get("SOURCE_DB_HOST", "localhost")
    port = os.environ["SOURCE_DB_PORT"]
    name = os.environ["SOURCE_DB_NAME"]
    return f"postgresql+psycopg://{user}:{password}@{host}:{port}/{name}"


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
