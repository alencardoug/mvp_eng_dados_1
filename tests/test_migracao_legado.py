"""O schema legado no ciclo Alembic — provado em bancos isolados, nunca no de trabalho.

R12 da terceira revisão: o `legacy_db` nascia de DDL emitido na carga, fora de
qualquer ciclo de evolução e reversão. A migração que o substitui só vale se
três coisas forem medidas, e é isso que este arquivo faz, em bancos efêmeros
criados ao lado do `legacy_db` e derrubados no fim:

* **do zero e de volta**: `upgrade head` num banco vazio, carga representativa,
  `downgrade base` sem sobra, `upgrade head` de novo;
* **equivalência física tripla**: o banco migrado, um banco criado pelo
  `schema.ddl()` de referência e o `legacy_db` de trabalho têm o mesmo
  catálogo — tabelas, colunas na ordem, tipos, nulabilidade, identidade,
  *constraints*, índices. Foi essa igualdade que autorizou o `stamp` do banco
  existente, e continua sendo conferida a cada execução;
* **a carga recusa banco não migrado**: `writer.escrever` não emite DDL.

`alembic check` sozinho não bastaria: ele compara o banco com a declaração
Python, não com o que o caminho de referência produz de fato no PostgreSQL.
"""

from __future__ import annotations

import os
import uuid

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

from mvp_ed1.db import LEGACY, database_url
from mvp_ed1.legacy import estrutura, schema, writer

pytestmark = pytest.mark.integracao


def _config() -> Config:
    return Config("alembic.ini", ini_section="legacy")


@pytest.fixture(scope="module")
def administrador():
    """Conexão ao `legacy_db` de trabalho, usada só para criar e derrubar bancos efêmeros."""
    if not os.environ.get("LEGACY_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    motor = create_engine(database_url(LEGACY), isolation_level="AUTOCOMMIT")
    try:
        with motor.connect() as conexao:
            conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover — depende do ambiente
        pytest.skip(f"legacy_db indisponível: {erro}")
    yield motor
    motor.dispose()


@pytest.fixture
def banco_efemero(administrador):
    """Um banco vazio ao lado do `legacy_db`, com nome que denuncia a origem."""
    criados = []

    def criar(rotulo: str):
        nome = f"legacy_teste_{rotulo}_{uuid.uuid4().hex[:8]}"
        with administrador.connect() as conexao:
            conexao.execute(text(f'create database "{nome}"'))
        criados.append(nome)
        return nome

    yield criar
    for nome in criados:
        with administrador.connect() as conexao:
            conexao.execute(text(f'drop database if exists "{nome}" with (force)'))


def _com_banco(nome: str):
    """Aponta `LEGACY_DB_NAME` para o efêmero enquanto o bloco roda."""
    class _Contexto:
        def __enter__(self):
            self.anterior = os.environ["LEGACY_DB_NAME"]
            os.environ["LEGACY_DB_NAME"] = nome
            return create_engine(database_url(LEGACY))

        def __exit__(self, *_):
            os.environ["LEGACY_DB_NAME"] = self.anterior

    return _Contexto()


def _tabelas(engine) -> int:
    with engine.connect() as conexao:
        return conexao.execute(
            text("select count(*) from information_schema.tables where table_schema = :s"),
            {"s": schema.SCHEMA},
        ).scalar_one()


def test_migracao_sobe_do_zero_desce_sem_sobra_e_sobe_de_novo(banco_efemero) -> None:
    nome = banco_efemero("ciclo")
    with _com_banco(nome) as engine:
        command.upgrade(_config(), "head")
        assert _tabelas(engine) == 40
        # Carga representativa: o downgrade precisa derrubar tabela com dado,
        # e a identidade precisa estar viva para o COPY.
        with engine.begin() as conexao:
            conexao.execute(text(f'insert into {schema.SCHEMA}.brands (id, code, name) values (\'1\', \'b1\', \'Acme\')'))
            assert conexao.execute(text(f"select legacy_row_id from {schema.SCHEMA}.brands")).scalar_one() == 1
        command.downgrade(_config(), "base")
        assert _tabelas(engine) == 0
        with engine.connect() as conexao:
            assert conexao.execute(
                text("select count(*) from information_schema.schemata where schema_name = :s"),
                {"s": schema.SCHEMA},
            ).scalar_one() == 0, "o downgrade deixou o schema vazio para trás"
        command.upgrade(_config(), "head")
        assert _tabelas(engine) == 40
        engine.dispose()


def test_migracao_referencia_e_banco_de_trabalho_tem_o_mesmo_catalogo_fisico(banco_efemero, administrador) -> None:
    migrado, referencia = banco_efemero("migrado"), banco_efemero("referencia")
    with _com_banco(migrado) as engine_migrado:
        command.upgrade(_config(), "head")
        catalogo_migrado = estrutura.catalogo_fisico(engine_migrado)
        engine_migrado.dispose()
    with _com_banco(referencia) as engine_referencia:
        with engine_referencia.begin() as conexao:
            for comando in schema.ddl():
                conexao.execute(text(comando))
        catalogo_referencia = estrutura.catalogo_fisico(engine_referencia)
        engine_referencia.dispose()
    catalogo_trabalho = estrutura.catalogo_fisico(administrador)

    assert len(catalogo_migrado["tabelas"]) == 40
    assert estrutura.diferencas(catalogo_migrado, catalogo_referencia) == [], "migração ≠ ddl() de referência"
    assert estrutura.diferencas(catalogo_migrado, catalogo_trabalho) == [], "migração ≠ legacy_db de trabalho"


def test_o_banco_de_trabalho_esta_na_cabeca_e_a_declaracao_nao_divergiu(administrador) -> None:
    """`stamp` só valeu porque o catálogo era igual; daqui em diante, `check` vigia a declaração."""
    assert writer.exigir_migracao(administrador)
    command.check(_config())


def test_a_carga_recusa_banco_nao_migrado(banco_efemero) -> None:
    nome = banco_efemero("semmigracao")
    with _com_banco(nome) as engine:
        with pytest.raises(writer.SchemaNaoMigrado, match="make migrate-legacy"):
            writer.exigir_migracao(engine)
        engine.dispose()
