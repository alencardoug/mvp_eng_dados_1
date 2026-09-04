"""Determinismo — o critério de conclusão da Etapa 4.

"A mesma `seed` e a mesma `as_of_date` produzem exatamente os mesmos dados" só
é verificável se houver como comparar duas execuções inteiras. A impressão
digital do conjunto é essa comparação: 64 caracteres sobre tudo que vai ao
banco, na ordem em que vai.
"""

from __future__ import annotations

import datetime as dt

from mvp_ed1.generator import pipeline
from mvp_ed1.generator.config import Config
from mvp_ed1.generator.engine import Motor

from conftest import FATOR_REDUZIDO


def _digital(config: Config, **kwargs) -> str:
    return pipeline.gerar(Motor(config, fator=FATOR_REDUZIDO, **kwargs)).impressao_digital()


def test_mesma_semente_e_mesma_data_produzem_os_mesmos_dados(config: Config) -> None:
    assert _digital(config) == _digital(config)


def test_semente_diferente_produz_dados_diferentes(config: Config) -> None:
    assert _digital(config, seed=1) != _digital(config, seed=2)


def test_as_of_date_diferente_produz_dados_diferentes(config: Config) -> None:
    assert _digital(config, as_of_date=dt.date(2026, 8, 1)) != _digital(
        config, as_of_date=dt.date(2026, 9, 1)
    )


def test_determinismo_vale_no_fator_padrao(config: Config, dados) -> None:
    """A garantia é sobre o fator `dev`, que é o que roda em todas as etapas."""
    assert pipeline.gerar(Motor(config)).impressao_digital() == dados.impressao_digital()


def test_dominios_sao_independentes_entre_si(config: Config) -> None:
    """Cada tabela tem a sua própria fonte, semeada pelo nome.

    É o que garante que mexer em um domínio não mova os outros — sem isso,
    acrescentar uma chamada a `random` no gerador de chamados mudaria todo o
    catálogo, e nenhuma comparação entre execuções significaria coisa alguma.
    """
    motor = Motor(config)
    assert motor.fonte("customers").rng.random() != motor.fonte("products").rng.random()
    outro = Motor(config)
    assert motor.fonte("orders").nome == outro.fonte("orders").nome
    assert Motor(config).fonte("orders").rng.random() == outro.fonte("orders").rng.random()
