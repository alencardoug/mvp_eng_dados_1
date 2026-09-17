"""Cobertura de classificação: toda coluna materializada no armazém tem `sensitivity`.

A política ([Governança §4](../docs/governanca_de_dados.md)) diz que **todo campo de
todas as camadas** recebe exatamente um nível, e a Etapa 11 fecha com "nenhum
campo sem classificação". Contar ocorrências de `sensitivity:` nos `.yml` não
mede isso — mede quantas vezes a palavra foi escrita. O que mede é a comparação
entre o que **existe** no banco (`information_schema.columns`, nas nove camadas)
e o que está **declarado** no `manifest.json` do dbt, coluna a coluna.

Na manhã de 17/09/2026 a cobertura era 738 de 4.161 (17,7 %); à tarde, com a
classificação **derivada** dos modelos SQLAlchemy (`models/sensitivity.py`),
4.161 de 4.161. O teste é uma **catraca** por camada: o piso é o medido na
última entrega; regredir falha, e com todos os pisos em 100 a asserção é
igualdade — coluna nova sem classificação derivada ou declarada falha aqui.
"""

from __future__ import annotations

import json
import os
import pathlib
from collections import defaultdict

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.models.base import SENSITIVITY_LEVELS

pytestmark = pytest.mark.integracao

RAIZ = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"

#: As nove camadas do armazém (ADR-0008 e ADR-0023). Nada fora delas é campo do projeto.
CAMADAS = ("raw", "raw_legacy", "staging", "trusted", "analytics", "consumption", "quarantine", "snapshots", "governance")

#: Piso de cobertura por camada, em % de colunas materializadas com `sensitivity`
#: declarada, medido na última entrega que classificou a camada. Levantar é
#: obrigação de quem classifica; baixar não existe.
PISO_POR_CAMADA: dict[str, int] = {          # 100 em todas desde 17/09/2026: classificação derivada dos modelos
    "raw": 100, "raw_legacy": 100, "staging": 100, "trusted": 100, "analytics": 100,
    "consumption": 100, "quarantine": 100, "snapshots": 100, "governance": 100,
}


@pytest.fixture(scope="module")
def manifest() -> dict:
    if not MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def declaradas(manifest: dict) -> dict[tuple[str, str, str], str | None]:
    """`(schema, relação, coluna) → sensitivity` de tudo o que o dbt declara: modelos, seeds, snapshots e fontes."""
    saida: dict[tuple[str, str, str], str | None] = {}
    for no in list(manifest["nodes"].values()) + list(manifest["sources"].values()):
        if no["resource_type"] not in ("model", "seed", "snapshot", "source"):
            continue
        relacao = no.get("alias") or no.get("identifier") or no["name"]
        for coluna in no.get("columns", {}).values():
            saida[(no["schema"], relacao, coluna["name"].lower())] = (coluna.get("meta") or {}).get("sensitivity")
    return saida


@pytest.fixture(scope="module")
def materializadas() -> set[tuple[str, str, str]]:
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    motor = create_engine(database_url(WAREHOUSE))
    try:
        with motor.connect() as conexao:
            linhas = conexao.execute(text(
                "select table_schema, table_name, column_name from information_schema.columns "
                "where table_schema = any(:camadas) and table_name not like '%\\_\\_dbt\\_%' "
                "order by 1, 2, ordinal_position"
            ), {"camadas": list(CAMADAS)}).all()
    finally:
        motor.dispose()
    if not linhas:
        pytest.skip("armazém sem camadas materializadas; rode `make dbt-build`")
    return {(s, t, c.lower()) for s, t, c in linhas}


def test_toda_sensibilidade_declarada_usa_o_vocabulario_do_adr_0011(declaradas) -> None:
    """Valor fora do vocabulário viraria coluna sem policy tag na fase GCP."""
    invalidas = sorted(f"{s}.{t}.{c}: {v!r}" for (s, t, c), v in declaradas.items() if v is not None and v not in SENSITIVITY_LEVELS)
    assert invalidas == []


def test_nenhuma_coluna_declarada_sem_coluna_materializada(declaradas, materializadas) -> None:
    """Declaração de coluna que não existe é catálogo mentindo — e é o que este teste também vigia."""
    fantasmas = sorted(f"{s}.{t}.{c}" for (s, t, c) in declaradas if s in CAMADAS and (s, t, c) not in materializadas)
    assert fantasmas == [], f"{len(fantasmas)} colunas declaradas que não existem no armazém: {fantasmas[:10]}"


def test_cobertura_de_classificacao_por_camada_nao_regride(declaradas, materializadas, record_property) -> None:
    """Cada camada no piso ou acima; piso 100 exige toda coluna classificada."""
    por_camada: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    faltando: dict[str, list[str]] = defaultdict(list)
    for chave in sorted(materializadas):
        camada = chave[0]
        por_camada[camada][0] += 1
        if declaradas.get(chave):
            por_camada[camada][1] += 1
        else:
            faltando[camada].append(f"{chave[1]}.{chave[2]}")

    total = sum(v[0] for v in por_camada.values())
    classificadas = sum(v[1] for v in por_camada.values())
    record_property("materialized_columns", total)
    record_property("classified_columns", classificadas)

    abaixo = []
    for camada in CAMADAS:
        existentes, cobertas = por_camada.get(camada, [0, 0])
        if not existentes:
            continue
        cobertura = 100 * cobertas // existentes
        record_property(f"coverage_{camada}", f"{cobertas}/{existentes} ({cobertura}%)")
        piso = PISO_POR_CAMADA[camada]
        if (piso == 100 and cobertas != existentes) or cobertura < piso:
            abaixo.append(f"{camada}: {cobertas}/{existentes} = {cobertura}% < piso {piso}%; faltam p.ex. {faltando[camada][:5]}")
    assert abaixo == [], "\n".join(abaixo)

    if all(PISO_POR_CAMADA[c] == 100 for c in CAMADAS):
        assert classificadas == total, "todos os pisos são 100: a asserção é igualdade"
