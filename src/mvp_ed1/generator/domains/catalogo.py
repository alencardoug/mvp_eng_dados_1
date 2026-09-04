"""Domínio de catálogo e preços — 6 tabelas.

Duas regras que não cabem em declaração de coluna moram aqui: a hierarquia de
categorias, que precisa de pai coerente e `depth` correto, e a vigência de
preço, que não pode se sobrepor para o mesmo par lista/SKU — a mesma regra que
a Etapa 5 vai cobrar das dimensões SCD.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.providers import ARVORE_DE_CATEGORIAS
from mvp_ed1.generator.rng import preco, repartir

def categorias(motor: Motor, dados: Dataset) -> None:
    """Árvore de três níveis: `depth` é derivado do pai, nunca sorteado."""
    fonte = motor.fonte("product_categories")
    total = motor.linhas("product_categories")
    raizes, meio, folhas = ARVORE_DE_CATEGORIAS

    quantidades = [max(1, round(total * fracao)) for fracao in (1 / 6, 2 / 6)]
    quantidades.append(max(1, total - sum(quantidades)))

    linhas: list[dict] = []
    por_nivel: list[list[int]] = []
    for nivel, (quantidade, nomes) in enumerate(zip(quantidades, (raizes, meio, folhas))):
        ids_do_nivel: list[int] = []
        for i in range(quantidade):
            identificador = len(linhas) + 1
            sufixo = f" {i // len(nomes) + 1}" if i >= len(nomes) else ""
            linhas.append(
                {
                    "id": identificador,
                    "code": f"CAT-{identificador:04d}",
                    "name": f"{nomes[i % len(nomes)]}{sufixo}",
                    "parent_id": fonte.escolha(por_nivel[nivel - 1]) if nivel else None,
                    "depth": nivel,
                    "is_active": True,
                }
            )
            ids_do_nivel.append(identificador)
        por_nivel.append(ids_do_nivel)

    dados.guardar("product_categories", motor.preencher("product_categories", linhas))


def marcas(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("brands")
    dados.guardar("brands", motor.preencher("brands", [{} for _ in range(n)]))


def produtos(motor: Motor, dados: Dataset) -> None:
    """Produtos nas categorias-folha, e SKUs pendurados nos produtos.

    Cada SKU carrega um custo e um preço de referência em campos auxiliares:
    é deles que saem preço de tabela, preço de carrinho, preço de venda e custo
    de compra. Sem essa âncora, o mesmo SKU custaria R$ 30 numa tabela e
    R$ 900 num pedido.
    """
    categorias_linhas = dados["product_categories"]
    profundidade_maxima = max(linha["depth"] for linha in categorias_linhas)
    folhas = [linha["id"] for linha in categorias_linhas if linha["depth"] == profundidade_maxima]
    marcas_ids = [linha["id"] for linha in dados["brands"]]

    nome_da_categoria = {linha["id"]: linha["name"] for linha in categorias_linhas}

    fonte = motor.fonte("products")
    n = motor.linhas("products")
    esqueletos = []
    for _ in range(n):
        categoria = fonte.escolha(folhas)
        esqueletos.append(
            {
                "category_id": categoria,
                "brand_id": fonte.escolha(marcas_ids),
                # O nome do produto sai da categoria dele (Geração §5).
                "__categoria": nome_da_categoria[categoria],
            }
        )
    produtos_linhas = dados.guardar("products", motor.preencher("products", esqueletos))

    processo = motor.config.tabelas["product_variants"].processo
    preco_min, preco_max = processo["faixa_de_preco"]
    margem_min, margem_max = processo["margem_sobre_o_custo"]

    fonte_v = motor.fonte("product_variants")
    total = motor.linhas("product_variants")
    por_produto = repartir(total, len(produtos_linhas), fonte_v, minimo=1, maximo=5)

    variantes: list[dict] = []
    for produto, quantidade in zip(produtos_linhas, por_produto):
        base = fonte_v.decimal(preco_min, preco_max, 4)
        for _ in range(quantidade):
            valor = preco(base * Decimal(str(fonte_v.rng.uniform(0.92, 1.12))))
            variantes.append(
                {
                    "product_id": produto["id"],
                    "is_active": produto["status"] == "active" and fonte_v.chance(0.94),
                    "__preco": valor,
                    "__custo": preco(valor / Decimal(str(fonte_v.rng.uniform(margem_min, margem_max)))),
                }
            )
    dados.guardar("product_variants", motor.preencher("product_variants", variantes))


def precos(motor: Motor, dados: Dataset) -> None:
    _listas(motor, dados)
    _tabela_de_precos(motor, dados)


def _listas(motor: Motor, dados: Dataset) -> None:
    """Uma lista por canal, uma geral e uma encerrada.

    A encerrada existe para que `valid_to` preenchido apareça no dado: vigência
    que nunca fecha é vigência que nenhuma consulta precisa tratar.
    """
    canais = dados["sales_channels"]
    fonte = motor.fonte("price_lists")
    total = motor.linhas("price_lists")

    linhas: list[dict] = [
        {
            "code": "PL-GERAL",
            "name": "Tabela geral",
            "sales_channel_id": None,
            "valid_from": motor.inicio,
            "valid_to": None,
            "is_active": True,
        }
    ]
    for canal in canais[: max(total - 2, 0)]:
        linhas.append(
            {
                "code": f"PL-{canal['code']}",
                "name": f"Tabela {canal['name']}",
                "sales_channel_id": canal["id"],
                "valid_from": motor.inicio,
                "valid_to": None,
                "is_active": True,
            }
        )
    encerrada = motor.relogio.depois(motor.inicio, fonte, 24 * 200, 24 * 400)
    linhas.append(
        {
            "code": "PL-PROMO-ENCERRADA",
            "name": "Tabela promocional encerrada",
            "sales_channel_id": None,
            "valid_from": motor.inicio,
            "valid_to": encerrada,
            "is_active": False,
        }
    )
    dados.guardar("price_lists", motor.preencher("price_lists", linhas[:total]))


def _tabela_de_precos(motor: Motor, dados: Dataset) -> None:
    """Preço por SKU e vigência, sem sobreposição no mesmo par lista/SKU."""
    variantes = dados["product_variants"]
    listas = dados["price_lists"]
    geral = listas[0]
    outras = listas[1:]

    fonte = motor.fonte("product_prices")
    total = motor.linhas("product_prices")
    linhas: list[dict] = []

    # 1. Toda variante tem preço vigente na lista geral: SKU sem preço é SKU
    #    que não pode ser vendido, e a venda é o que a etapa seguinte precisa.
    for variante in variantes:
        linhas.append(
            {
                "price_list_id": geral["id"],
                "product_variant_id": variante["id"],
                "unit_price": variante["__preco"],
                "valid_from": motor.inicio,
                "valid_to": None,
            }
        )

    # 2. Reajuste: fecha a vigência anterior e abre a seguinte, no mesmo par.
    #    É o caso que prova que "sem sobreposição" não é vacuidade.
    reajustaveis = fonte.amostra(range(len(variantes)), max(0, (total - len(linhas)) // 3))
    for indice in sorted(reajustaveis):
        anterior = linhas[indice]
        virada = motor.relogio.uniforme(fonte, motor.inicio + dt.timedelta(days=60))
        anterior["valid_to"] = virada
        novo = preco(anterior["unit_price"] * Decimal(str(fonte.rng.uniform(1.02, 1.35))))
        variantes[indice]["__preco"] = novo
        linhas.append(
            {
                "price_list_id": geral["id"],
                "product_variant_id": variantes[indice]["id"],
                "unit_price": novo,
                "valid_from": virada,
                "valid_to": None,
            }
        )

    # 3. Preço por canal, em pares ainda não usados naquela lista.
    faltam = max(total - len(linhas), 0)
    if outras and faltam:
        usados: set[tuple[int, int]] = set()
        tentativas = 0
        while faltam and tentativas < faltam * 20:
            tentativas += 1
            lista = fonte.escolha(outras)
            variante = fonte.escolha(variantes)
            chave = (lista["id"], variante["id"])
            if chave in usados:
                continue
            usados.add(chave)
            linhas.append(
                {
                    "price_list_id": lista["id"],
                    "product_variant_id": variante["id"],
                    "unit_price": preco(
                        variante["__preco"] * Decimal(str(fonte.rng.uniform(0.88, 1.06)))
                    ),
                    "valid_from": motor.inicio,
                    "valid_to": lista["valid_to"],
                }
            )
            faltam -= 1

    dados.guardar("product_prices", motor.preencher("product_prices", linhas))
