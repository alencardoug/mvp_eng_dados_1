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

A comparação é de **conjuntos**, nos dois sentidos, não de contagens: uma
identidade perdida compensada por uma sobra fecharia a contagem e é exatamente
o que uma regeneração da origem sem *reset* do destino deixa para trás
(Qualidade §7). Identidade da origem ausente em `raw` é `raw` **atrás da
origem**: a resposta é sincronizar (a DAG `fluxo_batch` ou `make sync-airbyte`).
Identidade em `raw` sem origem é sobra de uma origem regenerada ou apagada:
a resposta é `make sync-airbyte RESET=1`. Nenhuma das duas se resolve no teste.
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
    """A chave primária declarada no modelo, como expressão selecionável — `id` em 39 tabelas, `movement_id` no livro."""
    chave = [c.name for c in _modelo(tabela).primary_key.columns]
    return chave[0] if len(chave) == 1 else "(" + ", ".join(chave) + ")"


def _identidades(origem, armazem, tabela: str) -> tuple[set, set, object] | None:
    """As identidades da origem até o instante da extração e as de `raw`, ou `None` se `raw` está vazia."""
    corte = armazem.execute(text(f"select max(_airbyte_extracted_at) from raw.{tabela}")).scalar_one()
    if corte is None:
        return None
    # Como texto dos dois lados: o Airbyte grava `uuid` da origem como `varchar`
    # em `raw` (`inventory_movements.movement_id`), e o conjunto tem de casar por valor.
    chave = f"cast({_identidade(tabela)} as text)"
    em_raw = {linha[0] for linha in armazem.execute(text(f"select distinct {chave} from raw.{tabela}"))}
    na_origem = {linha[0] for linha in origem.execute(text(
        f"select {chave} from {Base.metadata.schema}.{tabela} where {_carimbo_de_criacao(tabela)} <= :corte"
    ), {"corte": corte})}
    return na_origem, em_raw, corte


def _divergencia(tabela: str, modo: str, na_origem: set, em_raw: set, corte) -> str | None:
    """A frase de uma tabela que não fecha, com o sentido certo — ou `None` quando os conjuntos são iguais."""
    perdidas, sobras = na_origem - em_raw, em_raw - na_origem
    if not perdidas and not sobras:
        return None
    partes = []
    if perdidas:
        partes.append(f"{len(perdidas)} da origem até {corte:%d/%m %H:%M} ausente(s) em raw — raw atrás da origem, ex.: {sorted(perdidas)[:5]}")
    if sobras:
        partes.append(f"{len(sobras)} em raw sem origem — sobra de regeneração, ex.: {sorted(sobras)[:5]}")
    return f"{tabela} ({modo}): " + "; ".join(partes)


def test_toda_tabela_ingerida_tem_as_identidades_da_origem_no_instante_da_extracao(bancos, record_property) -> None:
    origem, armazem = bancos
    divergentes: list[str] = []
    with origem.connect() as o, armazem.connect() as a:
        for tabela, modo in sorted(_tabelas_ingeridas().items()):
            conjuntos = _identidades(o, a, tabela)
            if conjuntos is None:
                divergentes.append(f"{tabela} ({modo}): `raw` vazia")
                continue
            na_origem, em_raw, corte = conjuntos
            record_property(f"{tabela}", f"origem={len(na_origem)} raw={len(em_raw)} perdidas={len(na_origem - em_raw)} "
                                         f"sobras={len(em_raw - na_origem)} corte={corte.isoformat()}")
            if frase := _divergencia(tabela, modo, na_origem, em_raw, corte):
                divergentes.append(frase)
    assert divergentes == [], "identidades não fecham entre origem e raw:\n" + "\n".join(divergentes)


def test_a_comparacao_acusa_perda_compensada_por_sobra(bancos) -> None:
    """Contraprova: trocar uma identidade de `raw.customers` por uma que a origem não tem mantém a contagem e tem de falhar.

    A troca é feita dentro de uma transação **revertida** — nada fica em `raw`;
    é o mesmo recurso das sondas de acesso. Sem esta prova, o teste acima só
    afirmaria que compara conjuntos.
    """
    origem, armazem = bancos
    with origem.connect() as o, armazem.connect() as a:
        conjuntos = _identidades(o, a, "customers")
        if conjuntos is None:
            pytest.skip("raw.customers vazia; sincronize antes")
        na_origem, em_raw, corte = conjuntos
        assert na_origem == em_raw, "a contraprova exige uma tabela que fecha antes da troca"
        trocada = min(em_raw, key=int)
        a.execute(text("update raw.customers set id = -1 where id = :id"), {"id": int(trocada)})
        try:
            na_origem2, em_raw2, _ = _identidades(o, a, "customers")
        finally:
            a.rollback()
        assert len(em_raw2) == len(em_raw), "a troca não pode alterar a contagem — é o que a contagem deixava passar"
        frase = _divergencia("customers", "dedup", na_origem2, em_raw2, corte)
        assert frase is not None and "1 da origem" in frase and "1 em raw sem origem" in frase, frase
        assert em_raw2 - na_origem2 == {"-1"} and na_origem2 - em_raw2 == {trocada}


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
