"""As views de consumo respondem quando alguém as consulta.

── Por que este arquivo existe ───────────────────────────────────────────────
Porque `dbt build` verde não prova que uma view funciona. `CREATE VIEW` valida
sintaxe e resolve nomes; **não executa o corpo**. Uma view cuja subconsulta
escalar devolve mais de uma linha é criada sem reclamar e só falha quando
alguém pergunta — e quem pergunta é o usuário do armazém, não a esteira.

Foi exatamente o que aconteceu: 863 objetos passando com `ERROR=0`, e a P11
respondendo `more than one row returned by a subquery used as an expression` na
primeira leitura. A revisão achou; o *build* não tinha como achar.

As views são o produto final do projeto — as 16 perguntas de negócio. Entregar
uma que não se consulta é entregar nada, com aparência de tudo.
"""

from __future__ import annotations

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url


@pytest.fixture(scope="module")
def engine():
    motor = create_engine(database_url(WAREHOUSE))
    try:
        with motor.connect() as conexao:
            existe = conexao.execute(
                text(
                    "select count(*) from information_schema.views"
                    " where table_schema = 'consumption'"
                )
            ).scalar_one()
    except Exception as erro:  # pragma: no cover — depende do ambiente
        motor.dispose()
        pytest.skip(f"armazém indisponível: {erro}")
    if not existe:
        motor.dispose()
        pytest.skip("sem views de consumo; rode `make dbt-build`")
    yield motor
    motor.dispose()


def views(motor) -> list[str]:
    with motor.connect() as conexao:
        return [
            linha[0]
            for linha in conexao.execute(
                text(
                    "select table_name from information_schema.views"
                    " where table_schema = 'consumption' order by table_name"
                )
            )
        ]


def test_toda_view_de_consumo_responde(engine) -> None:
    """Consultar cada view, uma a uma, e nomear a que falhar.

    O erro que interessa nasce na execução, não no planejamento — `limit 0` e
    `explain` não serviriam. Mas `count(*)` também não serve, e a diferença
    custou o achado R27/R28: o Postgres **elimina da projeção** o que a contagem
    não usa, então uma subconsulta escalar que devolve duas linhas passa
    despercebida e a view só quebra quando alguém a lê de verdade.

    `to_jsonb` da linha inteira obriga a avaliar **toda** coluna, e o `md5`
    impede que a serialização seja descartada por sua vez. É a diferença entre
    "a view existe" e "a view responde".

    O teste roda view a view, e não numa consulta só, para que a mensagem diga
    **qual** quebrou. Falha agregada obrigaria a repetir o trabalho à mão.
    """
    quebradas: dict[str, str] = {}
    for view in views(engine):
        try:
            with engine.connect() as conexao:
                conexao.execute(
                    text(
                        "select count(md5(to_jsonb(s)::text))"
                        f' from consumption."{view}" s'
                    )
                )
        except Exception as erro:
            quebradas[view] = str(erro).splitlines()[0]

    assert not quebradas, (
        "views de consumo que não podem ser consultadas: "
        + "; ".join(f"{nome} — {motivo}" for nome, motivo in quebradas.items())
    )


def test_as_dezesseis_perguntas_estao_publicadas(engine) -> None:
    """A contagem é afirmação: view que some não deixa buraco visível sozinha."""
    encontradas = views(engine)
    assert len(encontradas) == 16, (
        f"esperadas 16 views de consumo, encontradas {len(encontradas)}: {encontradas}"
    )
