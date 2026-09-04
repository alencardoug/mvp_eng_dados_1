"""Cobertura — o que o ADR-0014 pôs no lugar do volume.

O ambiente local não é dimensionado por tamanho, e sim pelo que precisa
exercitar. Estes testes são a forma verificável dessa definição: toda tabela
populada, todo valor de enumeração presente e a proporção entre as tabelas
dentro da tolerância declarada.
"""

from __future__ import annotations

import pytest

from mvp_ed1.generator import enums, pipeline
from mvp_ed1.generator.config import Config
from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor

from conftest import FATOR_REDUZIDO


def test_as_quarenta_tabelas_sao_populadas(dados: Dataset) -> None:
    vazias = [nome for nome in enums.nomes_de_tabelas() if not dados[nome]]
    assert vazias == []
    assert len(list(dados)) == 40


def test_todo_valor_de_enumeracao_aparece(config: Config, dados: Dataset) -> None:
    faltando: list[str] = []
    for tabela, colunas in enums.enumeracoes().items():
        dispensados = config.tabelas[tabela].cobertura_dispensada
        for coluna, aceitos in colunas.items():
            presentes = {linha[coluna] for linha in dados[tabela]}
            ausentes = set(aceitos) - presentes - set(dispensados.get(coluna, []))
            if ausentes:
                faltando.append(f"{tabela}.{coluna}: {sorted(ausentes)}")
    assert faltando == []


def test_cobertura_sobrevive_a_um_fator_menor(config: Config, dados_reduzidos: Dataset) -> None:
    """O piso vale independentemente do fator — é o que o ADR-0014 promete.

    Confere no fator reduzido, vinte vezes menor que o padrão: o que cai aqui é
    cobertura que dependia de volume, não de piso.
    """
    for nome in enums.nomes_de_tabelas():
        assert dados_reduzidos[nome], nome
    for tabela, colunas in enums.enumeracoes().items():
        dispensados = config.tabelas[tabela].cobertura_dispensada
        for coluna, aceitos in colunas.items():
            presentes = {linha[coluna] for linha in dados_reduzidos[tabela]}
            assert set(aceitos) - presentes - set(dispensados.get(coluna, [])) == set(), (
                f"{tabela}.{coluna} no fator {FATOR_REDUZIDO}"
            )


def test_piso_declarado_e_respeitado(config: Config, dados: Dataset) -> None:
    for nome, tabela in config.tabelas.items():
        # `customer_preferences` é 1:1 com `customers`: o piso dela não pode
        # superar o número de clientes sem violar a unicidade do modelo.
        if nome == "customer_preferences":
            continue
        assert len(dados[nome]) >= tabela.piso, nome


def test_proporcao_fica_dentro_da_tolerancia_declarada(config: Config, dados: Dataset) -> None:
    fora: list[str] = []
    for nome, previsto in config.plano().items():
        obtido = len(dados[nome])
        desvio = abs(obtido - previsto) / previsto
        if desvio > config.tolerancia_processo:
            fora.append(f"{nome}: {obtido:,} contra {previsto:,} ({desvio:.0%})")
    assert fora == []


def test_tabela_declarativa_cai_exatamente_na_proporcao(config: Config, dados: Dataset) -> None:
    """Só as de `origem: processo` podem desviar — as declarativas, não."""
    for nome, tabela in config.tabelas.items():
        if tabela.origem != "declarativa":
            continue
        assert len(dados[nome]) == config.linhas(nome), nome


@pytest.mark.parametrize("coluna", ["email", "contact_value", "contact_email"])
def test_nenhum_email_fora_do_dominio_reservado(dados: Dataset, coluna: str) -> None:
    """Governança §7: e-mail sintético mora em `example.com` e em nenhum outro."""
    for tabela in enums.nomes_de_tabelas():
        if coluna not in enums.tabela(tabela).columns:
            continue
        for linha in dados[tabela]:
            valor = linha[coluna]
            if isinstance(valor, str) and "@" in valor:
                assert valor.endswith("@example.com"), f"{tabela}.{coluna} = {valor}"


def test_documento_sintetico_nunca_parece_documento_real(dados: Dataset) -> None:
    """Nenhum documento gerado pode passar por CPF ou CNPJ válido (§7)."""
    for tabela in ("customers", "suppliers"):
        for linha in dados[tabela]:
            assert linha["document"].endswith("-SIN"), linha["document"]


def test_exclusao_logica_existe_e_e_excecao(config: Config, dados: Dataset) -> None:
    """`deleted_at` precisa existir para a Etapa 5 ter o que propagar (ADR-0015).

    E precisa ser exceção: se toda linha estivesse excluída, o teste de
    propagação passaria sobre um banco vazio do ponto de vista de quem lê.
    """
    excluidos = sum(
        1 for linha in dados["customers"] if linha["deleted_at"] is not None
    )
    assert 0 < excluidos < len(dados["customers"]) * 0.1


def test_sazonalidade_concentra_o_fim_do_ano(dados: Dataset) -> None:
    """Novembro pesa mais que fevereiro — sem isso a dimensão de data é uma reta."""
    por_mes: dict[int, int] = {}
    for pedido in dados["orders"]:
        mes = pedido["placed_at"].month
        por_mes[mes] = por_mes.get(mes, 0) + 1
    assert por_mes[11] > por_mes[2]
