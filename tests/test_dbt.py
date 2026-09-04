"""O projeto dbt confere com o resto do repositório.

São testes de **coerência entre artefatos**, não de dados: o dbt tem os seus
próprios testes, e o banco tem as suas constraints. O que nenhum dos dois vê é
quando dois arquivos do repositório passam a discordar um do outro.
"""

from __future__ import annotations

import pathlib
import re

import pytest
import yaml

RAIZ = pathlib.Path(__file__).resolve().parents[1]
DBT = RAIZ / "dbt"


def _carregar(caminho: pathlib.Path) -> dict:
    return yaml.safe_load(caminho.read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def projeto_dbt() -> dict:
    return _carregar(DBT / "dbt_project.yml")


def test_as_of_date_do_dbt_bate_com_a_do_gerador(config, projeto_dbt) -> None:
    """O dono do valor é o gerador; o dbt tem um espelho que ele consegue ler.

    Se os dois divergirem, "cliente ativo" passa a ser contado em uma janela que
    termina onde o dado não termina — e o erro não aparece como falha, aparece
    como um número menor.
    """
    assert str(projeto_dbt["vars"]["as_of_date"]) == config.as_of_date.isoformat()
    assert str(projeto_dbt["vars"]["period_start"]) == config.period_start.isoformat()


def test_toda_tabela_do_stream_tem_fonte_declarada_no_dbt() -> None:
    """O que o Airbyte ingere é o que o dbt lê — nem mais, nem menos.

    Stream ingerido sem modelo que o leia é volume sem consumidor; fonte
    declarada sem stream que a alimente é modelo que quebra na primeira execução
    limpa.
    """
    streams = _carregar(RAIZ / "airbyte/streams.yml")
    fontes = _carregar(DBT / "models/staging/_retail__sources.yml")

    ingeridas = set(streams["tabelas"])
    declaradas = {t["name"] for t in fontes["sources"][0]["tables"]}
    assert ingeridas == declaradas


def test_todo_stream_tem_modo_e_o_modo_e_conhecido() -> None:
    modos = {"full_refresh", "dedup_history", "append"}
    streams = _carregar(RAIZ / "airbyte/streams.yml")
    for nome, spec in streams["tabelas"].items():
        assert spec.get("modo") in modos, f"{nome}: modo ausente ou desconhecido"
        if spec["modo"] == "dedup_history":
            assert spec.get("cursor"), f"{nome}: dedup_history exige cursor"
            assert spec.get("chave"), f"{nome}: dedup_history exige chave"
        else:
            assert spec.get("motivo"), f"{nome}: carga completa exige motivo escrito"


def test_toda_pergunta_da_etapa_5_tem_a_sua_view() -> None:
    """A view declarada no Glossário existe em `consumption` — e vice-versa.

    O ADR-0018 diz que cada pergunta vira uma view nomeada por ela. Sem este
    teste, a lista de perguntas e o diretório de views divergem em silêncio.
    """
    perguntas = (RAIZ / "docs/glossario_de_negocio/perguntas_de_negocio.md").read_text(
        encoding="utf-8"
    )
    # Só as perguntas da Etapa 5 viram view agora; as demais estão declaradas
    # para as etapas seguintes e não devem existir ainda.
    etapa_5 = perguntas.split("## 3. Financeiro e estoque")[0]
    declaradas = set(re.findall(r"\*\*View\*\* \| `([a-z0-9_]+)`", etapa_5))
    existentes = {p.stem for p in (DBT / "models/consumption").glob("*.sql")}

    assert declaradas == existentes, (
        f"declaradas e não construídas: {sorted(declaradas - existentes)}; "
        f"construídas e não declaradas: {sorted(existentes - declaradas)}"
    )


def test_toda_view_de_consumo_tem_contrato_aplicado() -> None:
    """`contract: enforced` em todas — é o que o ADR-0018 exige das views."""
    modelos = _carregar(DBT / "models/consumption/_consumption__models.yml")["models"]
    com_contrato = {
        m["name"] for m in modelos if m.get("config", {}).get("contract", {}).get("enforced")
    }
    existentes = {p.stem for p in (DBT / "models/consumption").glob("*.sql")}
    assert existentes == com_contrato
