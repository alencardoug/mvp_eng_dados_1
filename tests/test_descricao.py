"""Cobertura de descrição: uma catraca por camada, sobre o que existe no armazém.

A [Governança §5.1](../docs/governanca_de_dados.md#51-padrão-de-metadados) pede
descrição em toda coluna e `domain` e `owner` em todo modelo, e em 23/10/2026 a
medição (M17 do plano do `bi-como-codigo`) achou 26 de 477 colunas descritas em
`analytics`, 31 de 188 em `consumption` e nenhum dos 41 objetos dessas camadas com
`domain` e `owner`. A v1.1.0 deriva a descrição por transporte
(`models/descriptions.py`); o texto do que é calculado é escrito à mão, depois.

A catraca conta **faltas**, não percentuais (N42): por camada, quantas colunas
materializadas não têm descrição no manifest, e quantos objetos não têm `domain`
e `owner`. O número tem de ser **igual** ao teto: uma coluna nova sem descrição
falha, e uma melhora também falha até o teto baixar no mesmo commit — é isso que
faz a catraca clicar. O inventário é o banco, como na de classificação: contar o
`.yml` deixaria passar a coluna que ninguém declarou.
"""

from __future__ import annotations

import json
import pathlib
from collections import Counter, defaultdict

import pytest
from conftest import CAMADAS

from mvp_ed1.models import descriptions, sensitivity

pytestmark = pytest.mark.integracao

MANIFEST = sensitivity.MANIFEST

#: Colunas materializadas sem descrição, por camada — o medido na entrega da
#: etapa 1.7 (03/11/2026), já com a herança. Só baixa, e no mesmo commit da melhora.
TETO_SEM_DESCRICAO: dict[str, int] = {
    "raw": 0, "raw_legacy": 0, "staging": 7, "trusted": 232, "analytics": 215,
    "consumption": 123, "quarantine": 5, "snapshots": 23, "governance": 0,
}

#: Objetos materializados (modelo, snapshot, seed) sem `domain` ou sem `owner`, por camada.
#: Baixado em 03/11/2026 (etapa 1.8, N46): `owner` por camada e `domain` da tabela conduzida.
TETO_SEM_DOMINIO: dict[str, int] = {
    "raw": 0, "raw_legacy": 0, "staging": 0, "trusted": 0, "analytics": 0,
    "consumption": 0, "quarantine": 0, "snapshots": 0, "governance": 0,
}


@pytest.fixture(scope="module")
def manifest() -> dict:
    if not MANIFEST.exists():
        pytest.skip("sem dbt/target/manifest.json; rode `make dbt-build`")
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def _relacoes(manifest: dict) -> dict[tuple[str, str], dict]:
    saida = {}
    for no in list(manifest["nodes"].values()) + list(manifest["sources"].values()):
        if no["resource_type"] in ("model", "seed", "snapshot", "source"):
            saida[(no["schema"], no.get("alias") or no.get("identifier") or no["name"])] = no
    return saida


def _faltas(medido: dict[str, int], teto: dict[str, int], o_que: str) -> list[str]:
    erros = []
    for camada in CAMADAS:
        if medido.get(camada, 0) > teto[camada]:
            erros.append(f"{camada}: {medido.get(camada, 0)} {o_que}, acima do teto {teto[camada]}")
        elif medido.get(camada, 0) < teto[camada]:
            erros.append(f"{camada}: {medido.get(camada, 0)} {o_que} — melhorou: baixe o teto de {teto[camada]} para {medido.get(camada, 0)}")
    return erros


def test_colunas_sem_descricao_por_camada_no_teto(manifest, colunas_materializadas, record_property) -> None:
    relacoes = _relacoes(manifest)
    sem = Counter()
    exemplos = defaultdict(list)
    for schema, relacao, coluna in sorted(colunas_materializadas):
        no = relacoes.get((schema, relacao))
        texto = ((no or {}).get("columns", {}).get(coluna) or {}).get("description") or ""
        if not texto.strip():
            sem[schema] += 1
            exemplos[schema].append(f"{relacao}.{coluna}")
    for camada in CAMADAS:
        record_property(f"undescribed_{camada}", sem.get(camada, 0))
    erros = _faltas(sem, TETO_SEM_DESCRICAO, "colunas sem descrição")
    assert erros == [], "\n".join(e + (f"; p.ex. {exemplos[e.split(':')[0]][:5]}" if "acima" in e else "") for e in erros)


def test_objetos_sem_dominio_ou_dono_por_camada_no_teto(manifest, colunas_materializadas) -> None:
    """Governança §5.1: `domain` e `owner` em todo modelo. Fontes ficam de fora — a regra é do modelo."""
    existentes = {(s, t) for s, t, _ in colunas_materializadas}
    sem = Counter()
    for (schema, relacao), no in _relacoes(manifest).items():
        if no["resource_type"] == "source" or (schema, relacao) not in existentes:
            continue
        meta = {**(no.get("meta") or {}), **((no.get("config") or {}).get("meta") or {})}
        if not (meta.get("domain") and meta.get("owner")):
            sem[schema] += 1
    erros = _faltas(sem, TETO_SEM_DOMINIO, "objetos sem domain/owner")
    assert erros == [], "\n".join(erros)


def test_herdado_e_escrito_contados_a_parte(manifest, record_property) -> None:
    """O relatório separa o que veio por transporte do que alguém escreveu (N42)."""
    _, derivacao = sensitivity.load()
    textos = descriptions.derive_texts(manifest, derivacao)
    por_camada: dict[str, Counter] = defaultdict(Counter)
    for (schema, _, _), origem in textos.origin.items():
        por_camada[schema][origem] += 1
    for camada, contagem in sorted(por_camada.items()):
        record_property(f"descriptions_{camada}", dict(contagem))
    assert textos.problems == [], textos.problems[:5]
    assert sum(c["inherited"] + c["bridge"] + c["convention"] for c in por_camada.values()) > 0


def test_contraprovas_no_manifest_real(manifest) -> None:
    """A receita somada da P01 não herda; o canal herda pela união com a ponte, pela dimensão e pela view;
    sem a declaração da ponte, a união deixa de herdar."""
    _, derivacao = sensitivity.load()
    textos = descriptions.derive_texts(manifest, derivacao)
    p01 = ("consumption", "monthly_revenue_by_channel_and_category")
    assert p01 + ("net_revenue_amount",) not in textos.texts
    assert textos.undescribed[p01 + ("net_revenue_amount",)] == "sum"
    canal = textos.texts[("staging", "stg_retail__sales_channels", "sales_channel_name")]
    for chave in (("trusted", "sales_channels"), ("analytics", "dim_sales_channel"), p01):
        assert textos.texts[chave + ("sales_channel_name",)] == canal, chave

    disco = descriptions.disk_entries()
    ponte = disco["legado__sales_channels"]
    for coluna in ponte.columns.values():
        (coluna.get("meta") or {}).pop("description_from", None)
    sem_declaracao = descriptions.derive_texts(manifest, derivacao, disco=disco)
    assert ("trusted", "sales_channels", "sales_channel_name") not in sem_declaracao.texts
    assert sem_declaracao.undescribed[("trusted", "sales_channels", "sales_channel_name")] == "upstream_blank"
    assert any("sem `description_from`" in p for p in sem_declaracao.problems)
