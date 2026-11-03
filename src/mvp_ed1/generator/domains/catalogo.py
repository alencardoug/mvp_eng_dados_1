"""Domínio de catálogo e preços — 6 tabelas.

Duas regras que não cabem em declaração de coluna moram aqui: a hierarquia de
categorias, montada da árvore declarada com pai coerente e `depth` correto, e a
vigência de preço, que não pode se sobrepor para o mesmo par lista/SKU — a mesma
regra que a Etapa 5 vai cobrar das dimensões SCD.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import MARCAS_DE_TEMPO, Motor
from mvp_ed1.generator.pricing import CHANNEL, READJUSTMENT, SKU_VARIATION, base_range
from mvp_ed1.generator.config import nos_da_arvore
from mvp_ed1.generator.rng import preco, repartir

def categorias(motor: Motor, dados: Dataset) -> None:
    """A árvore declarada em `geracao.yml`: `depth` e `parent_id` saem dela, nunca de sorteio."""
    arvore = motor.config.tabelas["product_categories"].arvore
    identificador: dict[str, int] = {}
    linhas: list[dict] = []
    for nome, profundidade, pai in nos_da_arvore(arvore):
        identificador[nome] = len(linhas) + 1
        linhas.append(
            {
                "id": identificador[nome],
                "code": f"CAT-{identificador[nome]:04d}",
                "name": nome,
                "parent_id": identificador[pai] if pai else None,
                "depth": profundidade,
                "is_active": True,
            }
        )
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
    faixa_interna = {
        folha: base_range(float(minimo), float(maximo))
        for folha, (minimo, maximo) in processo["faixa_de_preco_por_folha"].items()
    }
    margem_min, margem_max = processo["margem_sobre_o_custo"]

    fonte_v = motor.fonte("product_variants")
    total = motor.linhas("product_variants")
    por_produto = repartir(total, len(produtos_linhas), fonte_v, minimo=1, maximo=5)

    variantes: list[dict] = []
    for produto, quantidade in zip(produtos_linhas, por_produto):
        # A faixa é da folha do produto, e o sorteio é log-uniforme (N38).
        base = fonte_v.log_uniforme(*faixa_interna[nome_da_categoria[produto["category_id"]]], 4)
        for _ in range(quantidade):
            valor = preco(base * Decimal(str(fonte_v.rng.uniform(*SKU_VARIATION))))
            variantes.append(
                {
                    "product_id": produto["id"],
                    "is_active": produto["status"] == "active" and fonte_v.chance(0.94),
                    "__preco": valor,
                    "__custo": preco(valor / Decimal(str(fonte_v.rng.uniform(margem_min, margem_max)))),
                }
            )
    dados.guardar("product_variants", motor.preencher("product_variants", variantes))


def lancamento(motor: Motor, dados: Dataset) -> None:
    """O lançamento de um produto vendido cai entre o início do período e a primeira venda dele.

    É a invariante 14 do Modelo de Dados §4 — `launched_at` nulo, ou anterior ou
    igual ao `placed_at` de todo pedido que contém o produto — e a resposta à
    D65: 3.130 de 7.500 itens do varejo eram vendidos antes do lançamento (N39
    do plano do `bi-como-codigo`). Por isso este passo roda depois dos pedidos.

    **Nenhum sorteio novo.** O instante que o provedor sorteou no período inteiro
    é reescalado para a janela entre o início e a primeira venda: um uniforme no
    período vira um uniforme na janela, e as outras tabelas não mudam por causa
    deste passo. Produto sem venda mantém o sorteio do período; nulo segue nulo
    — quer dizer lançamento desconhecido. As marcas de tempo do produto nasceram
    do lançamento (`momento: launched_at`) e andam junto com ele, pelo mesmo
    deslocamento.
    """
    produto_da_variante = {linha["id"]: linha["product_id"] for linha in dados["product_variants"]}
    feito_em = {linha["id"]: linha["placed_at"] for linha in dados["orders"]}
    primeira_venda: dict[int, dt.datetime] = {}
    for item in dados["order_items"]:
        produto = produto_da_variante[item["product_variant_id"]]
        momento = feito_em[item["order_id"]]
        if produto not in primeira_venda or momento < primeira_venda[produto]:
            primeira_venda[produto] = momento

    periodo = int((motor.fim - motor.inicio).total_seconds())
    for produto in dados["products"]:
        lancado, venda = produto["launched_at"], primeira_venda.get(produto["id"])
        if lancado is None or venda is None:
            continue
        sorteado = int((lancado - motor.inicio).total_seconds())
        janela = int((venda - motor.inicio).total_seconds())
        # Inteiro e para baixo: nunca passa da primeira venda.
        novo = motor.inicio + dt.timedelta(seconds=sorteado * janela // periodo)
        deslocamento = novo - lancado
        produto["launched_at"] = novo
        for coluna in MARCAS_DE_TEMPO:
            if produto.get(coluna) is not None:
                produto[coluna] += deslocamento


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
        novo = preco(anterior["unit_price"] * Decimal(str(fonte.rng.uniform(*READJUSTMENT))))
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
                        variante["__preco"] * Decimal(str(fonte.rng.uniform(*CHANNEL)))
                    ),
                    "valid_from": motor.inicio,
                    "valid_to": lista["valid_to"],
                }
            )
            faltam -= 1

    dados.guardar("product_prices", motor.preencher("product_prices", linhas))
