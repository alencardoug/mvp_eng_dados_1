"""Recursos compartilhados dos testes.

A geração completa em fator 1 leva alguns segundos, e quase todo teste precisa
dela: por isso ela roda **uma vez** por sessão. O fator reduzido existe para os
testes que precisam gerar mais de uma vez — determinismo, principalmente — sem
pagar o preço da geração inteira a cada asserção.
"""

from __future__ import annotations

import os

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.generator import pipeline
from mvp_ed1.generator.config import Config, carregar
from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor

#: Fator reduzido dos testes rápidos. Não é fator declarado no YAML — é um
#: número de teste, e por isso mora aqui e não na configuração do projeto.
FATOR_REDUZIDO = 0.05


@pytest.fixture(scope="session")
def config() -> Config:
    return carregar()


@pytest.fixture(scope="session")
def dados(config: Config) -> Dataset:
    """Conjunto completo no fator `dev` — o padrão de todas as etapas locais."""
    return pipeline.gerar(Motor(config))


@pytest.fixture(scope="session")
def dados_reduzidos(config: Config) -> Dataset:
    return pipeline.gerar(Motor(config, fator=FATOR_REDUZIDO))


@pytest.fixture(scope="session")
def engine():
    """Conexão com o `source_db`, ou `skip` quando o ambiente não está de pé."""
    from mvp_ed1.db import database_url

    if not os.environ.get("SOURCE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    motor = create_engine(database_url(), future=True)
    try:
        with motor.connect() as conexao:
            conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover — depende do ambiente
        motor.dispose()
        pytest.skip(f"PostgreSQL indisponível: {erro}")
    yield motor
    motor.dispose()
