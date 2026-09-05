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


#: Fontes de `raw` que **não** vêm do Airbyte. Desde a Etapa 7 há uma: o
#: caminho quente escreve os próprios deltas em `raw` (ADR-0031), e o `staging`
#: os lê como qualquer outra fonte da camada. A lista é explícita de propósito —
#: acrescentar uma fonte sem alimentador é o defeito que este teste pega, e uma
#: exceção genérica o desligaria.
FONTES_DO_CAMINHO_QUENTE = {"inventory_movements_stream"}


def test_toda_tabela_do_stream_tem_fonte_declarada_no_dbt() -> None:
    """O que se ingere é o que o dbt lê — nem mais, nem menos.

    Stream ingerido sem modelo que o leia é volume sem consumidor; fonte
    declarada sem quem a alimente é modelo que quebra na primeira execução
    limpa. Desde a Etapa 7 há dois alimentadores, não um: o Airbyte e o pipeline
    Beam. A conta continua fechando, com as duas parcelas nomeadas.
    """
    streams = _carregar(RAIZ / "airbyte/streams.yml")
    fontes = _carregar(DBT / "models/staging/_retail__sources.yml")

    ingeridas = set(streams["tabelas"])
    declaradas = {t["name"] for t in fontes["sources"][0]["tables"]}
    assert ingeridas | FONTES_DO_CAMINHO_QUENTE == declaradas


def test_todo_stream_tem_modo_e_o_modo_e_conhecido() -> None:
    streams = _carregar(RAIZ / "airbyte/streams.yml")
    for nome, spec in streams["tabelas"].items():
        modo = spec.get("modo")
        if modo == "dedup_history":
            # Precisa saber o que mudou e a quem a mudança pertence.
            assert spec.get("cursor"), f"{nome}: dedup_history exige cursor"
            assert spec.get("chave"), f"{nome}: dedup_history exige chave"
        elif modo == "append":
            # Livro de eventos: só cresce, então basta saber por onde parou.
            assert spec.get("cursor"), f"{nome}: append exige cursor"
            assert not spec.get("chave"), f"{nome}: append não deduplica, e não usa chave"
        elif modo == "full_refresh":
            # Não ter cursor é a escolha, e escolha precisa de justificativa.
            assert spec.get("motivo"), f"{nome}: carga completa exige motivo escrito"
        else:
            raise AssertionError(f"{nome}: modo ausente ou desconhecido ({modo!r})")


def test_ponto_de_reposicao_do_dbt_bate_com_o_do_fluxo(projeto_dbt) -> None:
    """O dono do valor é `streaming/fluxo.yml`; o dbt tem o espelho que ele lê.

    Mesmo arranjo de `as_of_date`, pelo mesmo motivo: dois runtimes precisam do
    número e só um pode ser o dono. Se divergirem, o pipeline alerta em um
    limiar e a view P12 lista SKUs por outro — e as duas telas discordam sem que
    nada falhe.
    """
    fluxo = _carregar(RAIZ / "streaming/fluxo.yml")
    assert int(projeto_dbt["vars"]["reorder_point_units"]) == int(
        fluxo["alerta"]["limiar_de_unidades"]
    )


def test_toda_pergunta_com_view_construida_existe_como_modelo() -> None:
    """A view declarada no Glossário existe em `consumption` — e vice-versa.

    O ADR-0018 diz que cada pergunta vira uma view nomeada por ela. Sem este
    teste, a lista de perguntas e o diretório de views divergem em silêncio.
    """
    perguntas = (RAIZ / "docs/glossario_de_negocio/perguntas_de_negocio.md").read_text(
        encoding="utf-8"
    )
    # As perguntas até a Etapa 8 já viraram view; as da Etapa 9 estão
    # declaradas e não devem existir ainda. A fronteira anda uma seção por
    # etapa, e mover esta linha é parte de entregar a etapa.
    construidas = perguntas.split("## 6. Relacionamento e atendimento")[0]
    declaradas = set(re.findall(r"\*\*View\*\* \| `([a-z0-9_]+)`", construidas))
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


def test_transicoes_declaradas_batem_com_os_caminhos_do_gerador() -> None:
    """A *seed* e o gerador declaram a mesma máquina de estados.

    A regra do que é transição legal vive na *seed* `order_status_transitions`,
    porque é lá que ela é revisável. Quem **produz** as transições é o gerador,
    a partir de `CAMINHOS` e `_CANCELAMENTO`. São dois artefatos dizendo a mesma
    coisa, e é o par que precisa concordar: uma regra que o gerador nunca produz
    é regra morta, e um caminho que a regra não permite quebraria a invariante 9
    no primeiro `dbt build`.

    Mesmo arranjo do espelho de `as_of_date` e do ponto de reposição, pelo mesmo
    motivo: dois lugares precisam do valor e só um pode ser o dono.
    """
    from mvp_ed1.generator.domains.vendas import _CANCELAMENTO, CAMINHOS

    linhas = (DBT / "seeds/order_status_transitions.csv").read_text(encoding="utf-8")
    declaradas = {
        (linha.split(",")[0] or None, linha.split(",")[1])
        for linha in linhas.strip().splitlines()[1:]
    }

    produzidas = set()
    for caminho in list(CAMINHOS.values()) + [c + ("cancelled",) for c in _CANCELAMENTO]:
        anterior = None
        for estado in caminho:
            produzidas.add((anterior, estado))
            anterior = estado

    assert declaradas == produzidas, (
        f"declaradas e nunca produzidas: {sorted(declaradas - produzidas)}; "
        f"produzidas e não declaradas: {sorted(produzidas - declaradas)}"
    )
