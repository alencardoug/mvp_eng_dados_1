"""Carga no PostgreSQL.

O banco é o teste mais forte que existe aqui: toda `CHECK`, toda unicidade e
toda chave estrangeira do modelo são verificadas pelo próprio `COPY`. O que
sobra para este arquivo é o que o banco não diz sozinho — se as colunas que o
gerador escreve são as que existem, e se a carga se recusa a apagar o que já
está lá.

O teste que **escreve** exige autorização explícita por variável de ambiente:
`make seed-data` recusa destruir estado sem `FORCE=1`, e um teste não pode ser
mais permissivo que o comando que ele testa.
"""

from __future__ import annotations

import os

import pytest
from sqlalchemy import inspect, text

from mvp_ed1.generator import pipeline
from mvp_ed1.generator.config import Config
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.writer import ORDEM, DestinoNaoVazio, contagens, escrever
from mvp_ed1.models import SCHEMA

from conftest import FATOR_REDUZIDO

pytestmark = pytest.mark.integracao

AUTORIZA_ESCRITA = "MVP_TESTE_CARGA"
#: Nome do banco efêmero que `make test-carga` criou. O teste de escrita só
#: roda se for **esse** o banco a que a conexão aponta: a carga reduzida
#: substitui a origem, e já substituiu a de trabalho duas vezes por uma flag
#: que valia para qualquer banco.
BANCO_EFEMERO = "MVP_TESTE_CARGA_DB"


def test_as_colunas_gravaveis_existem_no_banco(engine) -> None:
    """Modelo e banco fora de sincronia dão erro de `COPY` sem dizer por quê."""
    inspetor = inspect(engine)
    for tabela in ORDEM:
        no_banco = {coluna["name"] for coluna in inspetor.get_columns(tabela, schema=SCHEMA)}
        assert set(Motor.colunas_gravaveis(tabela)) <= no_banco, tabela


def test_o_schema_tem_as_quarenta_tabelas(engine) -> None:
    assert len(inspect(engine).get_table_names(schema=SCHEMA)) == 40


@pytest.mark.skipif(
    os.environ.get(AUTORIZA_ESCRITA) != "1",
    reason=f"substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta {AUTORIZA_ESCRITA}=1 num banco efêmero",
)
def test_carga_completa_e_recusa_de_destino_ocupado(engine, config: Config) -> None:
    efemero = os.environ.get(BANCO_EFEMERO)
    assert efemero and efemero.split("_carga_")[0] != efemero, (
        f"{BANCO_EFEMERO} precisa nomear um banco efêmero `<origem>_carga_<n>`; "
        "este teste destrói o conteúdo do banco em que roda"
    )
    assert engine.url.database == efemero, (
        f"a conexão aponta para {engine.url.database!r}, não para o banco efêmero {efemero!r}; "
        "recusado para não substituir a origem de trabalho"
    )
    dados = pipeline.gerar(Motor(config, fator=FATOR_REDUZIDO))

    resultado = escrever(engine, dados, forcar=True)
    assert resultado["total"] == dados.total
    assert contagens(engine) == {nome: len(dados[nome]) for nome in ORDEM}

    with pytest.raises(DestinoNaoVazio):
        escrever(engine, dados)

    # A sequência de identidade precisa ter avançado com o `COPY`: sem
    # `setval`, o primeiro `INSERT` colidiria com a linha 1.
    with engine.begin() as conexao:
        proximo = conexao.execute(
            text(f"select nextval(pg_get_serial_sequence('{SCHEMA}.brands', 'id'))")
        ).scalar_one()
    assert proximo > len(dados["brands"])
