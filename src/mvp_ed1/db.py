"""Montagem da URL de conexão a partir do ambiente.

A credencial vive só no `.env` (regra inviolável 1 do `CLAUDE.md`): nenhum
arquivo versionado a contém, e nenhum módulo a recebe por argumento. Quem
precisa de conexão pede a URL aqui, e quem esquece de carregar o `.env` recebe
uma mensagem que diz o que fazer — não um `KeyError`.
"""

from __future__ import annotations

import os
from urllib.parse import quote_plus

#: Prefixo das variáveis de cada banco declarado no `.env.example`.
SOURCE = "SOURCE_DB"
LEGACY = "LEGACY_DB"
WAREHOUSE = "WAREHOUSE_DB"

BANCOS = (SOURCE, LEGACY, WAREHOUSE)

_CAMPOS = ("USER", "PASSWORD", "NAME", "PORT")


def database_url(prefix: str = SOURCE) -> str:
    """URL SQLAlchemy do banco indicado, montada do ambiente.

    O `host` tem padrão `localhost` porque o Python roda fora dos contêineres;
    dentro da composição ele é sobrescrito pelo nome do serviço.
    """
    ausentes = [f"{prefix}_{campo}" for campo in _CAMPOS if not os.environ.get(f"{prefix}_{campo}")]
    if ausentes:
        raise RuntimeError(
            "variáveis de ambiente ausentes: " + ", ".join(ausentes) + ". "
            "Use os alvos do Makefile, que carregam o .env antes de executar."
        )
    user = quote_plus(os.environ[f"{prefix}_USER"])
    password = quote_plus(os.environ[f"{prefix}_PASSWORD"])
    host = os.environ.get(f"{prefix}_HOST", "localhost")
    port = os.environ[f"{prefix}_PORT"]
    name = os.environ[f"{prefix}_NAME"]
    return f"postgresql+psycopg://{user}:{password}@{host}:{port}/{name}"
