"""As três contraprovas do esperado independente (plano da Etapa 10, §2 item 8; RV10-09).

Dois algoritmos do mesmo autor concordando não provam nada. O que prova é a
comparação **acusar** quando um dos lados está errado, e isto tem de ser
exercitado nos caminhos que ela protege — não copiando o esperado para o
obtido:

* **(a) defeito deliberado no oráculo** — a semântica é mutada no algoritmo
  (cascata, precedência) e o esperado recomputado diverge do manifesto do
  mesmo lote;
* **(b) defeito deliberado no SQL compilado** — os modelos de limpeza gerados
  são executados no PostgreSQL sobre o **próprio lote**, carregado num armazém
  efêmero como o Airbyte o entregaria; concordam com o oráculo achado a achado
  e valor a valor, e um rótulo trocado ou uma conversão mutilada no SQL é
  acusado;
* **(c) lote com as mesmas identidades e conteúdo diferente** — a recusa de
  comparar é executada, não só o hash conferido.

Tudo roda em `make test`, sem Airbyte, sem dbt e sem tocar o armazém de
trabalho: o lote é compatível com o manifesto **por construção**, e por isso
nada aqui depende da captura selecionada. A classificação completa (contexto,
cascata) continua coberta por `test_legado_deteccao.py`, quando a captura
selecionada é o lote do manifesto.
"""

from __future__ import annotations

import collections
import json
import os
import uuid
from typing import Any

import jinja2
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.legacy import cli, conteudo, dbt, oraculo, schema, writer
from mvp_ed1.models import Base

pytestmark = pytest.mark.integracao

JOB = 4242


@pytest.fixture(scope="module")
def lote():
    return cli._gerar()


@pytest.fixture(scope="module")
def manifesto(lote) -> dict[str, Any]:
    catalogo, resultado, parametros = lote
    return writer.manifesto(catalogo, resultado, parametros)


@pytest.fixture(scope="module")
def armazem(lote):
    """Um armazém efêmero com `raw_legacy` carregado como o Airbyte carregaria o lote."""
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    administrador = create_engine(database_url(WAREHOUSE), isolation_level="AUTOCOMMIT")
    try:
        with administrador.connect() as conexao:
            conexao.execute(text("select 1"))
    except Exception as erro:  # pragma: no cover
        pytest.skip(f"armazém indisponível: {erro}")
    nome = f"warehouse_teste_contraprovas_{uuid.uuid4().hex[:8]}"
    with administrador.connect() as conexao:
        conexao.execute(text(f'create database "{nome}"'))
    anterior = os.environ["WAREHOUSE_DB_NAME"]
    os.environ["WAREHOUSE_DB_NAME"] = nome
    try:
        # `NullPool`: um `backend` novo por consulta — cada view de limpeza é
        # código gerado pesado, e o pico de memória não pode somar quarenta.
        motor = create_engine(database_url(WAREHOUSE), poolclass=NullPool)
    finally:
        os.environ["WAREHOUSE_DB_NAME"] = anterior

    _, resultado, _ = lote
    with motor.begin() as conexao:
        conexao.execute(text("create schema raw_legacy"))
        for tabela in schema.tabelas():
            colunas = list(schema.colunas(tabela))
            definicao = ", ".join(f'"{c}" varchar' for c in colunas)
            conexao.execute(
                text(
                    f'create table raw_legacy."{tabela}" (_airbyte_raw_id varchar, '
                    "_airbyte_extracted_at timestamptz default now(), _airbyte_meta jsonb, "
                    f"_airbyte_generation_id bigint, {definicao}, legacy_row_id bigint)"
                )
            )
            linhas = resultado.linhas.get(tabela, [])
            if not linhas:
                continue
            nomes = ", ".join(f'"{c}"' for c in colunas)
            marcadores = ", ".join(f":{c}" for c in colunas)
            conexao.execute(
                text(
                    f'insert into raw_legacy."{tabela}" (_airbyte_raw_id, _airbyte_meta, '
                    f"_airbyte_generation_id, legacy_row_id, {nomes}) values "
                    f"(:raw, cast(:meta as jsonb), :g, :rid, {marcadores})"
                ),
                [
                    {"raw": uuid.uuid4().hex, "meta": json.dumps({"sync_id": JOB, "changes": []}),
                     "g": 1, "rid": linha[schema.IDENTIDADE],
                     # A normalização de transporte: o destino entrega `''` como nulo.
                     **{c: (None if linha.get(c) in (None, "") else str(linha[c])) for c in colunas}}
                    for linha in linhas
                ],
            )
            # Sem estatísticas o planejador junta `captura` a `limpo` por laço
            # aninhado, e a maior tabela (5.500 linhas) passa de três minutos.
            conexao.execute(text(f'create index on raw_legacy."{tabela}" (legacy_row_id)'))
            conexao.execute(text(f'analyze raw_legacy."{tabela}"'))
    yield motor
    motor.dispose()
    with administrador.connect() as conexao:
        conexao.execute(text(f'drop database if exists "{nome}" with (force)'))
    administrador.dispose()


# ── (c) a recusa de comparar é executada ─────────────────────────────────────

def test_c_conteudo_diferente_com_as_mesmas_identidades_recusa_a_comparacao(armazem, manifesto) -> None:
    filtro, parametros = f"{schema.CAPTURA_SQL} = :g", {"g": JOB}
    with armazem.connect() as conexao:
        assert conteudo.tabelas_divergentes(conexao, "raw_legacy", manifesto["lote"]["tabelas"], filtro, parametros) == []

    # Um valor que não é achado muda; contagem e identidades ficam iguais.
    with armazem.begin() as conexao:
        conexao.execute(
            text("update raw_legacy.brands set name = name || ' ' where legacy_row_id = "
                 "(select min(legacy_row_id) from raw_legacy.brands where name is not null)")
        )
    try:
        with armazem.connect() as conexao:
            divergentes = conteudo.tabelas_divergentes(conexao, "raw_legacy", manifesto["lote"]["tabelas"], filtro, parametros)
            contagem = conexao.execute(text("select count(*) from raw_legacy.brands")).scalar_one()
        assert divergentes == ["brands"], "a recusa nomeia a tabela que não é o lote"
        assert contagem == manifesto["lote"]["tabelas"]["brands"]["linhas"], "contagem igual não basta para reconhecer o lote"
    finally:
        with armazem.begin() as conexao:
            conexao.execute(text("update raw_legacy.brands set name = left(name, -1) where name like '% '"))
    with armazem.connect() as conexao:
        assert conteudo.tabelas_divergentes(conexao, "raw_legacy", manifesto["lote"]["tabelas"], filtro, parametros) == []


# ── (a) defeito deliberado no oráculo ────────────────────────────────────────

def _esperados_do_manifesto(manifesto: dict[str, Any]) -> dict[oraculo.Chave, oraculo.Veredito]:
    return {
        (tabela, identidade): oraculo.Veredito(
            saida, origem,
            [oraculo.AchadoEsperado(c, col, tuple(v) if v is not None else None) for c, col, v in achados],
            valores,
        )
        for tabela, identidade, saida, origem, achados, valores in manifesto["veredito"]
    }


def test_a_defeito_deliberado_no_oraculo_diverge_do_manifesto(lote, manifesto, monkeypatch) -> None:
    catalogo, resultado, _ = lote
    gravado = _esperados_do_manifesto(manifesto)
    assert oraculo.comparar(oraculo.esperar(catalogo, resultado), gravado) == [], "o oráculo íntegro reproduz o manifesto"

    # Defeito 1: a cascata deixa de existir — o contrato perde as referências.
    integro = oraculo.contrato

    def sem_referencias(tabela: str) -> oraculo.Contrato:
        c = integro(tabela)
        return oraculo.Contrato(c.obrigatorias, c.unicidades, ())

    monkeypatch.setattr(oraculo, "contrato", sem_referencias)
    divergencias = oraculo.comparar(oraculo.esperar(catalogo, resultado), gravado)
    campos = collections.Counter(d.campo for d in divergencias)
    assert campos["classification"] > 0 and campos["achados"] > 0, campos
    monkeypatch.setattr(oraculo, "contrato", integro)

    # Defeito 2: a precedência do catálogo invertida — a última regra declarada vence.
    invertido = list(catalogo.falhas.items())[::-1]
    catalogo_mutado = type(catalogo)(**{**catalogo.__dict__, "falhas": dict(invertido)})
    divergencias = oraculo.comparar(oraculo.esperar(catalogo_mutado, resultado), gravado)
    assert any(d.campo == "achados" for d in divergencias) or divergencias == [], (
        "com precedência invertida o lote sem sobreposição pode não mudar; o que não pode é mudar sem acusar"
    )

    # Defeito 3: o defeito próprio deixa de vencer o excedente na origem da rejeição.
    monkeypatch.setattr(oraculo, "OWN_INVALID", oraculo.DUPLICATE_EXCESS)
    divergencias = oraculo.comparar(oraculo.esperar(catalogo, resultado), gravado)
    assert collections.Counter(d.campo for d in divergencias)["rejection_origin"] > 0


# ── (b) defeito deliberado no SQL compilado ──────────────────────────────────

def _sql_de_limpeza(catalogo, promessas, parametros, tabela: str) -> str:
    """O modelo gerado, com `source`/`ref`/`var` resolvidos para o armazém efêmero."""
    limites = schema.limites(catalogo.limite_de_texto, catalogo.colunas_estreitadas)
    fonte = dbt.modelo(catalogo, tabela, promessas, limites)
    ambiente = jinja2.Environment()
    return ambiente.from_string(fonte).render(
        source=lambda origem, nome: f'raw_legacy."{nome}"',
        ref=lambda nome: f"(select {JOB}::bigint as snapshot_id) as {nome}",
        var=lambda nome: {"as_of_date": parametros["as_of"]}[nome],
        config=lambda **kwargs: "",
        target=type("Alvo", (), {"type": "postgres"})(),
    )


def _obtido(armazem, sql: str, tabela: str) -> dict[int, tuple[set[tuple[str, str]], dict[str, Any]]]:
    """Por linha: os achados de valor `(coluna, código)` e o payload limpo."""
    colunas = list(schema.colunas(tabela))
    limpos = ", ".join(f'"{c}"' for c in colunas)
    with armazem.connect() as conexao:
        # Sessão a sessão, não globalmente: o JIT sobre estas views passa de
        # 2 GB (medido em 08/09/2026), e a decisão global é do Owner (D36).
        conexao.execute(text("set jit = off"))
        linhas = conexao.execute(text(f"select legacy_row_id, achados, {limpos} from ({sql}) modelo")).all()
    return {
        identidade: ({(coluna, codigo) for coluna, codigo in (achados or {}).items()}, dict(zip(colunas, valores)))
        for identidade, achados, *valores in linhas
    }


def _esperado(vereditos: dict[oraculo.Chave, oraculo.Veredito], tabela: str) -> dict[int, tuple[set[tuple[str, str]], dict[str, Any]]]:
    """Os achados **de valor** e os valores recuperados que a limpeza tem de produzir."""
    return {
        identidade: (
            {(a.coluna, a.codigo) for a in v.achados if a.codigo not in oraculo.DE_CONTEXTO and a.codigo != oraculo.CASCATA},
            v.valores_esperados,
        )
        for (t, identidade), v in vereditos.items()
        if t == tabela
    }


def _divergencias(esperado, obtido, tabela: str) -> list[tuple]:
    modelo = Base.metadata.tables[f"oltp.{tabela}"]
    saida = []
    for identidade in sorted(set(esperado) | set(obtido)):
        if identidade not in esperado or identidade not in obtido:
            saida.append((identidade, "ocorrencia", identidade in esperado, identidade in obtido))
            continue
        achados_esperados, valores_esperados = esperado[identidade]
        achados_obtidos, limpo = obtido[identidade]
        if achados_esperados != achados_obtidos:
            saida.append((identidade, "achados", sorted(achados_esperados - achados_obtidos), sorted(achados_obtidos - achados_esperados)))
        for coluna, valor in valores_esperados.items():
            if not oraculo.mesmo_valor(valor, limpo.get(coluna), modelo.c[coluna].type.python_type):
                saida.append((identidade, "valor", coluna, valor, limpo.get(coluna)))
    return saida


def test_b_a_limpeza_compilada_concorda_com_o_oraculo(armazem, lote, manifesto, record_property) -> None:
    catalogo, resultado, parametros = lote
    promessas = cli._promessas()
    vereditos = _esperados_do_manifesto(manifesto)
    divergencias: dict[str, list] = {}
    ocorrencias = achados = valores = 0
    # As 40 tabelas: 47 s com o CTE `limpo` materializado (ADR-0047); eram
    # 656 s antes, quando o planejador reavaliava a limpeza a cada referência.
    tabelas = list(schema.tabelas())
    for tabela in tabelas:
        esperado = _esperado(vereditos, tabela)
        obtido = _obtido(armazem, _sql_de_limpeza(catalogo, promessas, parametros, tabela), tabela)
        ocorrencias += len(obtido)
        achados += sum(len(a) for a, _ in esperado.values())
        valores += sum(len(v) for _, v in esperado.values())
        faltas = _divergencias(esperado, obtido, tabela)
        if faltas:
            divergencias[tabela] = faltas[:5]
    record_property("occurrences_compared", ocorrencias)
    record_property("value_findings_compared", achados)
    record_property("recovered_values_compared", valores)
    assert ocorrencias == sum(1 for t, _ in vereditos if t in tabelas) and achados > 0 and valores > 0
    assert not divergencias, divergencias


@pytest.mark.parametrize(
    "tabela,mutacao,campo",
    [
        ("customers", ("then 'TEXT_WHITESPACE_CASE'", "then 'TEXT_ENCODING'"), "achados"),
        ("customers", ("regexp_replace(btrim(", "regexp_replace(("), "valor"),
        ("orders", ("then 'MONEY_NEGATIVE'", "then null"), "achados"),
    ],
)
def test_b_defeito_deliberado_no_sql_compilado_e_acusado(armazem, lote, manifesto, tabela, mutacao, campo) -> None:
    catalogo, resultado, parametros = lote
    sql = _sql_de_limpeza(catalogo, cli._promessas(), parametros, tabela)
    antes, depois = mutacao
    assert antes in sql, f"a mutação não alcança o SQL de {tabela}"
    esperado = _esperado(_esperados_do_manifesto(manifesto), tabela)
    assert _divergencias(esperado, _obtido(armazem, sql, tabela), tabela) == []

    mutado = sql.replace(antes, depois)
    acusadas = _divergencias(esperado, _obtido(armazem, mutado, tabela), tabela)
    assert acusadas and all(d[1] == campo for d in acusadas), acusadas[:5]
