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
from mvp_ed1.legacy import dbt, schema
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


#: Teto de falso positivo aceito, em fração das linhas capturadas.
#
# Não é zero de propósito. `TEXT_TRUNCATED` é heurística declarada — comprimento
# igual à largura da coluna antiga —, e um valor legítimo desse tamanho é
# indistinguível de um cortado. O que não se aceita é que a heurística deixe de
# ser marginal: quando ela era aplicada a todas as colunas de texto, produzia
# 1.508 rejeições falsas, e foi essa medição que criou a lista de colunas
# estreitadas no catálogo.
TETO_DE_FALSO_POSITIVO = 0.005

#: Falhas que **não** são achados de valor, e por isso não aparecem no `achados`
#: dos modelos de limpeza. Três precisam de outras linhas ou de outra tabela; a
#: quarta, `NULL_REQUIRED`, nasce do contrato do registro **depois** da
#: conversão — reconhecer a ausência não torna a ocorrência válida (ADR-0040).
DE_CONTEXTO = frozenset(
    {"FK_ORPHAN", "DUP_EXACT", "DUP_PARTIAL", "TOTAL_MISMATCH", "NULL_REQUIRED"}
)


def _achados_dos_modelos(engine) -> set[tuple[str, int, str, str]]:
    uniao = "\nunion all\n".join(
        f"select '{tabela}' as tabela, legacy_row_id, chave as coluna, valor as codigo "
        f"from staging.stg_legacy__{tabela}, jsonb_each_text(achados) as e(chave, valor)"
        for tabela in schema.tabelas()
    )
    with engine.connect() as conexao:
        return {tuple(linha) for linha in conexao.execute(text(uniao))}


def test_os_modelos_encontram_tudo_que_o_injetor_produziu(
    engine, manifesto, record_property
) -> None:
    """A ponta final: o SQL gerado acha no banco o que o manifesto declara.

    O teste anterior confere **regra a regra**, isolada. Este confere o
    resultado do modelo inteiro, onde a precedência entre falhas passa a
    valer — e é ela que erra em silêncio. Três defeitos apareceram só aqui:

    * a ordem do catálogo punha `DATE_FORMAT_KNOWN` antes de `DATE_IMPOSSIBLE`,
      e uma data que não existe era **convertida** em vez de rejeitada;
    * duas falhas caíam na mesma célula, e a segunda apagava o valor da
      primeira — o manifesto declarava um achado que já não existia;
    * o `TEXT_DELIMITER` esvaziava as colunas vizinhas, apagando defeitos que
      já estavam nelas.
    """
    with engine.connect() as conexao:
        existe = conexao.execute(
            text(
                "select count(*) from information_schema.views "
                "where table_schema = 'staging' and table_name like 'stg_legacy__%'"
            )
        ).scalar_one()
    if not existe:
        pytest.skip("modelos de limpeza não construídos; rode `make dbt-build`")

    de_contexto = DE_CONTEXTO
    esperados = {
        (a["tabela"], a["legacy_row_id"], a["coluna"], a["codigo"])
        for a in manifesto["achados"]
        if a["coluna"] is not None and a["codigo"] not in de_contexto
    }
    encontrados = _achados_dos_modelos(engine)

    perdidos = sorted(esperados - encontrados)
    record_property("injected_value_findings", len(esperados))
    record_property("detected_value_findings", len(esperados & encontrados))
    record_property("missed_value_findings", len(perdidos))
    assert not perdidos, f"injetados e não detectados pelos modelos: {perdidos[:8]}"


def test_o_falso_positivo_da_heuristica_continua_marginal(
    engine, manifesto, record_property
) -> None:
    """A heurística é aceita; deixar de ser marginal, não."""
    de_contexto = DE_CONTEXTO
    esperados = {
        (a["tabela"], a["legacy_row_id"], a["coluna"], a["codigo"])
        for a in manifesto["achados"]
        if a["coluna"] is not None and a["codigo"] not in de_contexto
    }
    encontrados = _achados_dos_modelos(engine)
    if not encontrados:
        pytest.skip("modelos de limpeza não construídos")

    with engine.connect() as conexao:
        linhas = sum(
            conexao.execute(
                text(
                    f"select count(*) from raw_legacy.\"{tabela}\" where _airbyte_generation_id = "
                    f"(select max(_airbyte_generation_id) from raw_legacy.\"{tabela}\")"
                )
            ).scalar_one()
            for tabela in schema.tabelas()
        )

    falsos = len(encontrados - esperados)
    record_property("false_positive_findings", falsos)
    record_property("captured_rows", linhas)
    assert falsos / linhas <= TETO_DE_FALSO_POSITIVO, (
        f"{falsos} falsos positivos em {linhas} linhas "
        f"({falsos / linhas:.2%}), acima do teto declarado"
    )


@pytest.mark.parametrize(
    "table,column,value,expected_code,expected_value",
    [
        ("orders", "placed_at", "31/02/2024", "DATE_IMPOSSIBLE", "31/02/2024"),
        ("orders", "placed_at", "29/02/2025", "DATE_IMPOSSIBLE", "29/02/2025"),
        ("orders", "placed_at", "29/02/2024", "DATE_FORMAT_KNOWN", "2024-02-29"),
        ("orders", "placed_at", "   ", "NULL_DISGUISED", None),
        ("support_agents", "email", " a @example.com ", "EMAIL_MALFORMED", " a @example.com "),
        ("cart_items", "quantity", "8,0", "NUM_TEXT_EQUIV", "8"),
        ("cart_items", "quantity", "8.5", "NUM_AMBIGUOUS", "8.5"),
        ("cart_items", "quantity", "8", None, "8"),
    ],
)
def test_detection_and_cleaning_share_precedence(
    engine, table, column, value, expected_code, expected_value
) -> None:
    """Detectar rejeição não basta: a coluna tratada não pode tentar convertê-la.

    Valores dirigidos, independentes do injetor. Consultar apenas `achados`
    permite ao PostgreSQL eliminar a avaliação das demais expressões da view;
    uma conversão que estoura ficava invisível na medição dos 74 achados.
    """
    catalog = carregar()
    limits = schema.limites(catalog.limite_de_texto, catalog.colunas_estreitadas)
    rules = dbt._aplicaveis(catalog, table, column, catalog.promessas, limits)

    # O arranjo espelha o modelo gerado, e precisa disso por duas razões que
    # apareceram consertando a revisão:
    #
    # * o achado de rejeição é conferido contra o valor **já convertido**, que
    #   no modelo vive numa CTE `l`. Sem ela, `-1.0` voltaria a sair corrigido;
    # * `TEXT_DELIMITER` olha as colunas **vizinhas** — o deslocamento de uma
    #   linha importada só é observável se os campos seguintes estiverem
    #   vazios. Um `c` de coluna única falharia com `UndefinedColumn`.
    #
    # Por isso `c` traz todas as colunas da tabela, com a alvo recebendo o valor
    # dirigido e as demais nulas.
    vizinhas = ",\n            ".join(
        f'null::text as "{outra}"' for outra in schema.colunas(table) if outra != column
    )
    query = (
        f"""
        with c as (
            select cast(:value as text) as "{column}",
            {vizinhas}
        ),
        l as (
            select {dbt._limpo(column, rules)} as "{column}" from c
        )
        select {dbt._achado(column, rules)} as code, l."{column}" as cleaned
        from c cross join l
        """
    ).replace('{{ var("as_of_date") }}', "2026-09-01")
    with engine.connect() as connection:
        actual = connection.execute(text(query), {"value": value}).one()
    assert tuple(actual) == (expected_code, expected_value)


def test_cleaned_models_materialize_every_column(engine) -> None:
    """Ler efetivamente todas as colunas, não só contar linhas ou achados.

    O hash não sai do banco e o teste não imprime payloads pessoais. A consulta
    é somente leitura: nem a captura nem os modelos são alterados.
    """
    for table in schema.tabelas():
        with engine.connect() as connection:
            count = connection.execute(text(
                f"select count(md5(to_jsonb(c)::text))"
                f" from staging.stg_legacy__{table} c"
            )).scalar_one()
        assert count > 0, f"{table}: o cenário gerado exige cobertura"
