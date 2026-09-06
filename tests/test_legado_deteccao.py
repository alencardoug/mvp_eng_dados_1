"""As regras de detecção encontram o que o injetor produziu.

Este é o teste que **liga a declaração ao SQL**. O catálogo diz que
`MONEY_LOCALE` é um valor monetário com separadores; o injetor produz
`R$ 1.234,56`; e a regra precisa reconhecê-lo em `raw_legacy`. Se qualquer um
dos três discordar, é aqui que aparece.

Ele lê o **manifesto** — o oráculo — e confronta cada achado com a expressão de
detecção correspondente, executada contra a captura mais recente. A
transformação continua sem acesso ao manifesto: quem o consulta é o teste.

Cinco defeitos reais foram encontrados por esta verificação antes de existir
qualquer modelo dbt, e cada um teria custado caro depois:

* o `to_date` do PostgreSQL 16 **estoura** com data fora de faixa, e a detecção
  por ida e volta derrubava a consulta inteira em vez de rejeitar a linha;
* o corte no limite repetia o valor três vezes, o que não alcançava o limite de
  colunas mais largas — o defeito saía com o comprimento errado;
* a string vazia não sobrevive ao transporte: o destino a entrega como nulo;
* caixa alterada em texto livre não é reconhecível sem convenção declarada;
* e, ao tirar a string vazia da lista de marcadores, o valor só com espaços
  deixou de casar por tabela.
"""

from __future__ import annotations

import collections
import json
import pathlib

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.generator import enums
from mvp_ed1.legacy import schema
from mvp_ed1.legacy.catalogo import carregar
from mvp_ed1.legacy.regras import regra_enum, regra_truncado, regras

pytestmark = pytest.mark.integracao

MANIFESTO = pathlib.Path("data/legacy/manifesto.json")


@pytest.fixture(scope="module")
def manifesto() -> dict:
    if not MANIFESTO.exists():
        pytest.skip(f"sem manifesto em {MANIFESTO}; rode `make seed-legacy`")
    return json.loads(MANIFESTO.read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def engine():
    motor = create_engine(database_url(WAREHOUSE))
    with motor.connect() as conexao:
        existe = conexao.execute(
            text(
                "select count(*) from information_schema.tables where table_schema = 'raw_legacy'"
            )
        ).scalar_one()
    if not existe:
        pytest.skip("sem `raw_legacy`; rode `make sync-legacy`")
    return motor


def _regra(codigo: str, tabela: str, coluna: str, catalogo, limites):
    if codigo == "TEXT_TRUNCATED":
        return regra_truncado(limites[(tabela, coluna)])
    if codigo == "ENUM_UNKNOWN":
        valores = enums.enumeracoes().get(tabela, {}).get(coluna)
        return regra_enum(valores) if valores else None
    return regras(catalogo.nulos_disfarcados, catalogo.delimitador).get(codigo)


def test_toda_falha_injetada_e_detectada_pela_sua_regra(engine, manifesto) -> None:
    catalogo = carregar()
    limites = schema.limites(catalogo.limite_de_texto)
    injetados: collections.Counter[str] = collections.Counter()
    detectados: collections.Counter[str] = collections.Counter()
    escapou: list[str] = []

    for achado in manifesto["achados"]:
        coluna = achado["coluna"]
        if coluna is None:  # falha de linha inteira: não tem expressão de valor
            continue
        regra = _regra(achado["codigo"], achado["tabela"], coluna, catalogo, limites)
        if regra is None:
            continue

        injetados[achado["codigo"]] += 1
        expressao = regra.deteccao.format(v="valor").replace(
            '{{ var("as_of_date") }}', "2026-09-01"
        )
        tabela = achado["tabela"]
        consulta = (
            f"select ({expressao}) from ("
            f'  select "{coluna}" as valor from raw_legacy."{tabela}"'
            f"  where legacy_row_id = :linha"
            f'    and _airbyte_generation_id = ('
            f'      select max(_airbyte_generation_id) from raw_legacy."{tabela}")'
            f") alvo"
        )
        # Uma transação por consulta: uma expressão que estoure não pode
        # contaminar a medição das demais — foi assim que o primeiro defeito
        # apareceu disfarçado de cinco.
        with engine.connect() as conexao:
            resultado = conexao.execute(text(consulta), {"linha": achado["legacy_row_id"]}).scalar()
        if resultado:
            detectados[achado["codigo"]] += 1
        else:
            escapou.append(f"{achado['codigo']} em {tabela}.{coluna} #{achado['legacy_row_id']}")

    assert injetados, "o manifesto não tem achado de valor; a geração falhou antes"
    assert detectados == injetados, "falhas injetadas que a regra não encontra: " + "; ".join(
        escapou[:10]
    )
