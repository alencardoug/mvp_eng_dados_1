"""Os multiplicadores que levam o preço de um SKU a todo preço derivado dele — num lugar só.

Todo preço do catálogo nasce do preço de tabela de um SKU e é movido por um
destes fatores, sorteado uniforme entre os dois limites: a lista de um canal, o
reajuste da tabela geral, o carrinho e a venda. Estavam espalhados pelos
construtores de catálogo e de vendas; aqui ficam juntos porque quem promete um
limite para **todo** preço de uma categoria precisa saber o quanto cada um
pode mover.
"""

from __future__ import annotations

from decimal import Decimal

#: O preço de cada SKU em torno do preço-base do produto.
SKU_VARIATION = (0.92, 1.12)
#: O reajuste da tabela geral: fecha a vigência anterior e abre outra, mais cara.
READJUSTMENT = (1.02, 1.35)
#: O preço numa lista de canal sobre o vigente na geral.
CHANNEL = (0.88, 1.06)
#: O preço no carrinho sobre o vigente.
CART = (0.97, 1.03)
#: O preço de venda do item sobre o vigente.
SALE = (0.95, 1.05)

#: Folga relativa nas duas bordas da faixa interna: cobre os arredondamentos a
#: quatro casas de cada passo — o do preço-base, o do SKU, o do reajuste, o do
#: preço final —, que somados não chegam a R$ 0,0003, enquanto a folga, na menor
#: faixa declarada, passa de R$ 0,001.
MARGIN = 1e-4


def envelope() -> tuple[float, float]:
    """O menor e o maior fator entre o preço-base de um produto e qualquer preço derivado dele.

    Para baixo: a variação do SKU e o menor desconto entre canal, carrinho e
    venda — o reajuste só sobe. Para cima: a variação, o reajuste (no máximo um
    por SKU) e o maior acréscimo entre os três.
    """
    derivados = (CHANNEL, CART, SALE)
    baixo = SKU_VARIATION[0] * min(1.0, READJUSTMENT[0]) * min(1.0, *(d[0] for d in derivados))
    alto = SKU_VARIATION[1] * max(1.0, READJUSTMENT[1]) * max(1.0, *(d[1] for d in derivados))
    return baixo, alto


def base_range(minimo: float, maximo: float) -> tuple[float, float]:
    """A faixa interna do preço-base: dentro dela, nenhum preço derivado sai de `[minimo, maximo]`."""
    baixo, alto = envelope()
    interno = (minimo / baixo * (1 + MARGIN), maximo / alto * (1 - MARGIN))
    if not 0 < interno[0] < interno[1]:
        raise ValueError(
            f"faixa [{minimo}, {maximo}] estreita demais: os multiplicadores movem o preço "
            f"de ×{baixo:.4f} a ×{alto:.4f}, e a razão entre as bordas precisa passar de "
            f"{alto / baixo * (1 + MARGIN) / (1 - MARGIN):.3f}"
        )
    return interno


def within(valor: Decimal, faixa: tuple[float, float]) -> bool:
    return Decimal(str(faixa[0])) <= valor <= Decimal(str(faixa[1]))
