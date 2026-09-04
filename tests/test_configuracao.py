"""A configuração é conferida contra os modelos, não contra si mesma.

O `CLAUDE.md` §5 diz que erro em declaração é bloqueante. Estes testes são o
que impede que ele seja apenas uma frase: uma tabela nova no modelo sem entrada
no YAML, um peso que esquece um valor de enumeração ou um piso sem motivo
quebram aqui, antes de qualquer linha ser gerada.
"""

from __future__ import annotations

import pytest

from mvp_ed1.generator import enums
from mvp_ed1.generator.config import ARQUIVO, Config, ConfiguracaoInvalida, carregar, validar


def test_configuracao_do_repositorio_e_valida(config: Config) -> None:
    assert validar(config) == []


def test_declara_exatamente_as_tabelas_do_modelo(config: Config) -> None:
    assert set(config.tabelas) == set(enums.nomes_de_tabelas())
    assert len(config.tabelas) == 40


def test_todo_piso_estrutural_tem_motivo_escrito(config: Config) -> None:
    sem_motivo = [
        nome for nome, tabela in config.tabelas.items()
        if tabela.min_rows is not None and not (tabela.motivo or "").strip()
    ]
    assert sem_motivo == []


def test_piso_nunca_deixa_tabela_vazia(config: Config) -> None:
    """Primeira linha do piso do ADR-0014: nenhuma das 40 vazia."""
    assert all(tabela.piso >= 1 for tabela in config.tabelas.values())


def test_piso_cobre_as_enumeracoes_do_modelo(config: Config) -> None:
    for nome, tabela in config.tabelas.items():
        assert tabela.piso >= enums.piso_por_enumeracao(nome), nome


def test_peso_que_esquece_um_valor_da_enumeracao_e_recusado(tmp_path) -> None:
    texto = ARQUIVO.read_text(encoding="utf-8")
    quebrado = texto.replace(
        "status: {pesos: {active: 76, inactive: 15, blocked: 4, pending: 5}}",
        "status: {pesos: {active: 76, inactive: 15, blocked: 9}}",
    )
    assert quebrado != texto, "o alvo do teste mudou no YAML"
    arquivo = tmp_path / "quebrado.yml"
    arquivo.write_text(quebrado, encoding="utf-8")

    with pytest.raises(ConfiguracaoInvalida, match="não cobre"):
        carregar(arquivo)


def test_coluna_inexistente_no_modelo_e_recusada(tmp_path) -> None:
    texto = ARQUIVO.read_text(encoding="utf-8")
    quebrado = texto.replace(
        '      customer_code: {sequencia: "CUS-{n:07d}"}',
        '      customer_code: {sequencia: "CUS-{n:07d}"}\n      nome_do_cliente: {faker: name}',
    )
    arquivo = tmp_path / "quebrado.yml"
    arquivo.write_text(quebrado, encoding="utf-8")

    with pytest.raises(ConfiguracaoInvalida, match="não existe no modelo"):
        carregar(arquivo)


def test_dispensa_de_cobertura_so_vale_para_valor_que_o_modelo_aceita(config: Config) -> None:
    for nome, tabela in config.tabelas.items():
        for coluna, dispensados in tabela.cobertura_dispensada.items():
            aceitos = set(enums.valores(nome, coluna))
            assert set(dispensados) <= aceitos, f"{nome}.{coluna}"
