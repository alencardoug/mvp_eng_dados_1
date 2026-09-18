"""Fronteira `oltp → raw` (Qualidade §7): contagem por tabela e por lote.

O Airbyte replica cada tabela de `oltp` em `raw` no modo que `airbyte/streams.yml`
declara (ADR-0015). A entrega é *ao menos uma vez*: os fluxos `append` releem a
fronteira do cursor e uma reconexão reextrai tudo, então contar linhas de `raw`
não diz nada — o que tem de fechar é o conjunto de **identidades**: cada `id`
que a origem tinha no instante da extração está em `raw`, e nenhum outro.

O corte é o instante da extração (`max(_airbyte_extracted_at)`): a origem
continua recebendo linhas depois dele — o produtor do caminho quente escreve
em `oltp.inventory_movements` enquanto o fluxo está de pé —, e uma linha
criada depois da extração não é linha perdida. Sem corte o teste acusaria a
diferença de latência como defeito, que é o erro da Qualidade §6.1.

Por lote: toda linha de `raw` pertence a um *job* identificado (`sync_id` no
`_airbyte_meta`, o mesmo vínculo do certificado do legado, ADR-0044). A
contagem por lote é registrada, não igualada — dentro de um lote a releitura
da fronteira repete a linha, e isso é o contrato, não desvio.

Uma tabela que falha aqui está **atrás da origem**: a resposta é sincronizar
(a DAG `fluxo_batch` ou `make sync-airbyte`), não ajustar o teste.
"""

from __future__ import annotations

import os
import pathlib

import pytest
import yaml
from sqlalchemy import create_engine, text

from mvp_ed1.db import SOURCE, WAREHOUSE, database_url
from mvp_ed1.models import Base

pytestmark = pytest.mark.integracao

RAIZ = pathlib.Path(__file__).resolve().parents[1]
STREAMS = RAIZ / "airbyte" / "streams.yml"


@pytest.fixture(scope="module")
def bancos():
    """Origem e armazém, ou `skip` quando o ambiente não está de pé."""
    if not os.environ.get("WAREHOUSE_DB_PASSWORD"):
        pytest.skip("ambiente sem .env carregado; rode por `make test`")
    origem, armazem = create_engine(database_url(SOURCE)), create_engine(database_url(WAREHOUSE))
    try:
        with origem.connect() as o, armazem.connect() as a:
            o.execute(text("select 1"))
            if not a.execute(text("select to_regclass('raw.orders') is not null")).scalar_one():
                pytest.skip("armazém sem `raw`; sincronize o Airbyte antes")
    except Exception as erro:  # pragma: no cover — depende do ambiente
        pytest.skip(f"PostgreSQL indisponível: {erro}")
    yield origem, armazem
    origem.dispose()
    armazem.dispose()


def _tabelas_ingeridas() -> dict[str, str]:
    """`tabela → modo` de tudo o que o Airbyte replica da origem principal."""
    retail = yaml.safe_load(STREAMS.read_text(encoding="utf-8"))["origens"]["retail"]
    return {nome: spec["modo"] for nome, spec in retail["tabelas"].items()}


def _modelo(tabela: str):
    return Base.metadata.tables[f"{Base.metadata.schema}.{tabela}"]


def _carimbo_de_criacao(tabela: str) -> str:
    """A coluna que diz quando a linha nasceu na origem — `created_at`, ou `recorded_at` no livro de movimentos."""
    colunas = {c.name for c in _modelo(tabela).columns}
    return "created_at" if "created_at" in colunas else "recorded_at"


def _identidade(tabela: str) -> str:
    """A chave primária declarada no modelo, como expressão contável — `id` em 39 tabelas, `movement_id` no livro."""
    chave = [c.name for c in _modelo(tabela).primary_key.columns]
    return chave[0] if len(chave) == 1 else "(" + ", ".join(chave) + ")"


def test_toda_tabela_ingerida_tem_as_identidades_da_origem_no_instante_da_extracao(bancos, record_property) -> None:
    origem, armazem = bancos
    divergentes: list[str] = []
    with origem.connect() as o, armazem.connect() as a:
        for tabela, modo in sorted(_tabelas_ingeridas().items()):
            corte, em_raw = a.execute(text(
                f"select max(_airbyte_extracted_at), count(distinct {_identidade(tabela)}) from raw.{tabela}"
            )).one()
            if corte is None:
                divergentes.append(f"{tabela} ({modo}): `raw` vazia")
                continue
            na_origem = o.execute(text(
                f"select count(*) from {Base.metadata.schema}.{tabela} where {_carimbo_de_criacao(tabela)} <= :corte"
            ), {"corte": corte}).scalar_one()
            record_property(f"{tabela}", f"origem={na_origem} raw={em_raw} corte={corte.isoformat()}")
            if na_origem != em_raw:
                divergentes.append(f"{tabela} ({modo}): origem {na_origem} identidades até {corte:%d/%m %H:%M}, raw {em_raw}")
    assert divergentes == [], "raw atrás da origem — sincronize antes de conferir:\n" + "\n".join(divergentes)


def test_toda_linha_de_raw_pertence_a_um_lote_identificado(bancos, record_property) -> None:
    _, armazem = bancos
    sem_lote: list[str] = []
    lotes_por_tabela: dict[str, int] = {}
    with armazem.connect() as a:
        for tabela in sorted(_tabelas_ingeridas()):
            linhas = a.execute(text(
                f"select _airbyte_meta->>'sync_id' as lote, count(*) from raw.{tabela} group by 1"
            )).all()
            lotes_por_tabela[tabela] = len(linhas)
            if any(lote is None for lote, _ in linhas):
                sem_lote.append(tabela)
            record_property(f"{tabela}", "; ".join(f"lote {lote}: {n}" for lote, n in sorted(linhas, key=lambda par: int(par[0] or 0))))
    record_property("tables", len(lotes_por_tabela))
    record_property("batches", sum(lotes_por_tabela.values()))
    assert sem_lote == [], f"linhas sem `sync_id`: {sem_lote}"
