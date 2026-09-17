"""Retenção aplicável a cada objeto: todo objeto materializado declara a sua, e ela segue a política.

[Governança §8](../docs/governanca_de_dados.md) fixa a retenção por categoria;
a declaração por objeto é `meta.retention` no dbt — por camada no
`dbt_project.yml`, por fonte nos `_sources.yml` (Governança §5.1). Este teste
compara, como o de classificação, o que **existe** no armazém com o que está
**declarado**, e cobra que o declarado seja o que a política manda: o que é
evidência ou histórico é `permanent`; o que se reconstrói é `rebuildable`;
um inteiro é prazo em dias.
"""

from __future__ import annotations

import json
import os
import pathlib

import pytest
from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url

pytestmark = pytest.mark.integracao

RAIZ = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = RAIZ / "dbt" / "target" / "manifest.json"

CAMADAS = ("raw", "raw_legacy", "staging", "trusted", "analytics", "consumption", "quarantine", "snapshots", "governance")
VOCABULARIO = ("permanent", "rebuildable")

#: Governança §8, por camada: o que cada objeto **tem** de declarar.
POLITICA: dict[str, str] = {
    "raw": "permanent",          # os lotes necessários à reconciliação; retidos pelo modo de sincronização
    "raw_legacy": "permanent",   # capturas por acréscimo (ADR-0037)
    "staging": "rebuildable",
    "trusted": "rebuildable",    # inclui as seeds, versionadas no Git
    "analytics": "rebuildable",
    "consumption": "rebuildable",
    "quarantine": "permanent",   # evidência de auditoria
    "snapshots": "permanent",    # histórico SCD não se reconstrói (ADR-0017)
    "governance": "permanent",   # log de execução e controle (ADR-0023)
}


@pytest.fixture(scope="module")
def declaradas() -> dict[tuple[str, str], object]:
    """`(schema, relação) → retention` de tudo o que o dbt declara."""
    if not MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    saida: dict[tuple[str, str], object] = {}
    for no in manifest["nodes"].values():
        if no["resource_type"] in ("model", "seed", "snapshot"):
            saida[(no["schema"], no.get("alias") or no["name"])] = (no.get("meta") or {}).get("retention")
    for fonte in manifest["sources"].values():
        meta = (fonte.get("meta") or {}) | (fonte.get("source_meta") or {})
        saida[(fonte["schema"], fonte["identifier"])] = meta.get("retention")
    return saida


@pytest.fixture(scope="module")
def materializadas() -> set[tuple[str, str]]:
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    motor = create_engine(database_url(WAREHOUSE))
    try:
        with motor.connect() as conexao:
            linhas = conexao.execute(text(
                "select table_schema, table_name from information_schema.tables "
                "where table_schema = any(:camadas) and table_name not like '%\\_\\_dbt\\_%'"
            ), {"camadas": list(CAMADAS)}).all()
    finally:
        motor.dispose()
    if not linhas:
        pytest.skip("armazém sem camadas materializadas; rode `make dbt-build`")
    return set(linhas)


def test_todo_objeto_materializado_declara_retencao_no_vocabulario(declaradas, materializadas, record_property) -> None:
    sem = sorted(f"{s}.{t}" for (s, t) in materializadas if not declaradas.get((s, t)))
    fora = sorted(f"{s}.{t}: {v!r}" for (s, t), v in declaradas.items()
                  if v is not None and v not in VOCABULARIO and not (isinstance(v, int) and v > 0))
    record_property("objects", len(materializadas))
    assert sem == [], f"{len(sem)} objetos sem `meta.retention`: {sem[:10]}"
    assert fora == []


def test_a_retencao_declarada_e_a_da_politica(declaradas, materializadas) -> None:
    """Objeto declarado com retenção diferente da que a Governança §8 fixa para a camada dele."""
    divergentes = sorted(
        f"{s}.{t}: declarado {declaradas[(s, t)]!r}, política {POLITICA[s]!r}"
        for (s, t) in materializadas
        if declaradas.get((s, t)) is not None and declaradas[(s, t)] != POLITICA[s]
    )
    assert divergentes == []
