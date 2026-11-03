"""Os multiplicadores que levam o preço de um SKU a todo preço derivado dele — num lugar só.

Todo preço do catálogo nasce do preço de tabela de um SKU e é movido por um
destes fatores, sorteado uniforme entre os dois limites: a lista de um canal, o
reajuste da tabela geral, o carrinho e a venda. Estavam espalhados pelos
construtores de catálogo e de vendas; aqui ficam juntos porque quem promete um
limite para **todo** preço de uma categoria precisa saber o quanto cada um
pode mover.
"""

from __future__ import annotations

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
