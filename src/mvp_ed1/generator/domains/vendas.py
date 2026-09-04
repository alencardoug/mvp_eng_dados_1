"""Domínio de vendas — 6 tabelas.

O caminho comercial inteiro: o carrinho abre, quase sempre é abandonado, e
quando converte vira pedido com itens, valores e histórico de estado.

Três invariantes do Modelo de Dados §4 nascem aqui, e não em teste posterior:
a 2 — o total do pedido reconcilia itens, desconto, frete e imposto —, a 9 —
transições de estado válidas — e a 10 — causalidade das datas.

A **taxa de conversão não é parâmetro**: ela é a razão entre `carts` e `orders`
na proporção declarada. Quantos carrinhos convertem sai do número de pedidos,
para que os dois números não possam divergir.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import cobrir, dinheiro, preco, repartir

#: Máquina de estados do pedido (invariante 9). Cada estado final é o fim de um
#: caminho, e o histórico é o caminho percorrido — não uma sequência sorteada.
CAMINHOS: dict[str, tuple[str, ...]] = {
    "pending": ("pending",),
    "paid": ("pending", "paid"),
    "picking": ("pending", "paid", "picking"),
    "shipped": ("pending", "paid", "picking", "shipped"),
    "delivered": ("pending", "paid", "picking", "shipped", "delivered"),
    "returned": ("pending", "paid", "picking", "shipped", "delivered", "returned"),
}

#: Cancelamento interrompe o caminho em qualquer ponto antes do envio.
_CANCELAMENTO = (("pending",), ("pending", "paid"), ("pending", "paid", "picking"))

_MOTIVOS = {
    "cancelled": "Cancelado a pedido do cliente",
    "returned": "Devolução dentro do prazo de arrependimento",
}


def canais(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("sales_channels")
    dados.guardar("sales_channels", motor.preencher("sales_channels", [{} for _ in range(n)]))


# ── Carrinhos ────────────────────────────────────────────────────────────────
def carrinhos(motor: Motor, dados: Dataset) -> None:
    canais_linhas = dados["sales_channels"]
    clientes = dados["customers"]
    fonte = motor.fonte("carts")
    processo = motor.config.tabelas["carts"].processo
    validade = dt.timedelta(days=processo["validade_dias"])

    total = motor.linhas("carts")
    convertidos = min(
        total,
        round(motor.linhas("orders") * (1 - motor.config.tabelas["orders"].processo["venda_direta"])),
    )
    restantes = total - convertidos
    abandonados = round(restantes * processo["taxa_de_abandono"])
    abertos = round(restantes * processo["taxa_em_aberto"])
    estados = (
        ["converted"] * convertidos
        + ["abandoned"] * abandonados
        + ["open"] * abertos
        + ["expired"] * (restantes - abandonados - abertos)
    )
    fonte.rng.shuffle(estados)
    estados = cobrir(estados, ("converted", "abandoned", "open", "expired"))

    esqueletos: list[dict] = []
    for estado in estados:
        if estado == "open":
            # Carrinho aberto com data de 2024 seria carrinho expirado: o que
            # define "aberto" é caber dentro da própria validade.
            aberto_em = motor.relogio.uniforme(fonte, motor.fim - validade)
        else:
            aberto_em = motor.relogio.sazonal(fonte)
        cliente = None if estado != "converted" and fonte.chance(processo["sessao_anonima"]) else fonte.escolha(clientes)
        esqueletos.append(
            {
                "customer_id": cliente["id"] if cliente else None,
                "sales_channel_id": fonte.escolha(canais_linhas)["id"],
                "status": estado,
                "expires_at": aberto_em + validade,
                "converted_at": (
                    motor.relogio.depois(aberto_em, fonte, 0.05, 48) if estado == "converted" else None
                ),
                "created_at": aberto_em,
                "deleted_at": None,
            }
        )
    carrinhos_linhas = dados.guardar("carts", motor.preencher("carts", esqueletos))
    _itens_de_carrinho(motor, dados, carrinhos_linhas)


def _itens_de_carrinho(motor: Motor, dados: Dataset, carrinhos_linhas: list[dict]) -> None:
    variantes = [v for v in dados["product_variants"] if v["is_active"]] or dados["product_variants"]
    fonte = motor.fonte("cart_items")
    processo = motor.config.tabelas["cart_items"].processo
    minimo, maximo = processo["itens_por_carrinho"]
    qtd_min, qtd_max = processo["quantidade_por_item"]

    por_carrinho = repartir(
        motor.linhas("cart_items"), len(carrinhos_linhas), fonte, minimo=minimo, maximo=maximo
    )

    esqueletos: list[dict] = []
    for carrinho, quantidade in zip(carrinhos_linhas, por_carrinho):
        limite = min(carrinho["expires_at"], motor.fim)
        escolhidas = fonte.amostra(variantes, quantidade)
        for variante in escolhidas:
            adicionado = min(
                motor.relogio.depois(carrinho["created_at"], fonte, 0, 24), limite
            )
            esqueletos.append(
                {
                    "cart_id": carrinho["id"],
                    "product_variant_id": variante["id"],
                    "quantity": fonte.inteiro(qtd_min, qtd_max),
                    "unit_price": preco(
                        variante["__preco"] * Decimal(str(fonte.rng.uniform(0.97, 1.03)))
                    ),
                    "added_at": adicionado,
                    "deleted_at": None,
                    "__variante": variante,
                }
            )
        carrinho["__itens"] = esqueletos[len(esqueletos) - len(escolhidas):]
    dados.guardar("cart_items", motor.preencher("cart_items", esqueletos))


# ── Pedidos ──────────────────────────────────────────────────────────────────
def pedidos(motor: Motor, dados: Dataset) -> None:
    fonte = motor.fonte("orders")
    processo = motor.config.tabelas["orders"].processo
    clientes = dados["customers"]
    canais_linhas = dados["sales_channels"]
    variantes = dados["product_variants"]

    convertidos = [c for c in dados["carts"] if c["status"] == "converted"]
    total = motor.linhas("orders")
    esqueletos: list[dict] = []
    itens_por_pedido: list[list[dict]] = []

    fonte_itens = motor.fonte("order_items")
    minimo, maximo = motor.config.tabelas["order_items"].processo["itens_por_pedido"]
    tamanhos = repartir(motor.linhas("order_items"), total, fonte_itens, minimo=minimo, maximo=maximo)

    # Estado final sorteado de uma vez, com cobertura garantida: um estado que
    # some da amostra some também de `order_status_history`, de `payments` e de
    # `shipments`, que derivam dele.
    finais = cobrir(
        [fonte.ponderada(processo["estado_final"]) for _ in range(total)],
        tuple(processo["estado_final"]),
    )

    for indice in range(total):
        carrinho = convertidos[indice] if indice < len(convertidos) else None
        if carrinho is not None:
            feito_em = carrinho["converted_at"]
            cliente_id = carrinho["customer_id"]
            canal_id = carrinho["sales_channel_id"]
            candidatas = [item["__variante"] for item in carrinho.get("__itens", [])]
        else:
            feito_em = motor.relogio.sazonal(fonte)
            cliente_id = fonte.escolha(clientes)["id"]
            canal_id = fonte.escolha(canais_linhas)["id"]
            candidatas = []

        if len(candidatas) < tamanhos[indice]:
            candidatas = candidatas + fonte_itens.amostra(variantes, tamanhos[indice])
        # SKUs distintos: `uq_order_items_pedido_variante` recusa repetição.
        unicas: dict[int, dict] = {}
        for variante in candidatas:
            unicas.setdefault(variante["id"], variante)
            if len(unicas) >= tamanhos[indice]:
                break

        itens = _montar_itens(motor, fonte_itens, indice + 1, list(unicas.values()), feito_em, processo)
        itens_por_pedido.append(itens)
        esqueletos.append(
            _montar_pedido(
                motor, fonte, carrinho, cliente_id, canal_id, feito_em, itens, processo,
                finais[indice],
            )
        )

    pedidos_linhas = dados.guardar("orders", motor.preencher("orders", esqueletos))
    _aplicar_cupons(motor, dados, pedidos_linhas)

    achatados = [item for grupo in itens_por_pedido for item in grupo]
    dados.guardar("order_items", motor.preencher("order_items", achatados))
    _historico(motor, dados, pedidos_linhas)


def _montar_itens(
    motor: Motor,
    fonte,
    pedido_id: int,
    variantes: list[dict],
    feito_em: dt.datetime,
    processo: dict,
) -> list[dict]:
    itens: list[dict] = []
    for variante in variantes:
        quantidade = fonte.inteiro(1, 3)
        unitario = preco(variante["__preco"] * Decimal(str(fonte.rng.uniform(0.95, 1.05))))
        bruto = dinheiro(unitario * quantidade)
        desconto = (
            dinheiro(bruto * Decimal(str(fonte.rng.uniform(0.05, 0.3))))
            if fonte.chance(processo["desconto_de_item"])
            else Decimal("0.00")
        )
        imposto = dinheiro((bruto - desconto) * Decimal(str(processo["aliquota_de_imposto"])))
        itens.append(
            {
                "order_id": pedido_id,
                "product_variant_id": variante["id"],
                "quantity": quantidade,
                "unit_price": unitario,
                "discount_amount": desconto,
                "tax_amount": imposto,
                # Tolerância de um centavo na `CHECK`: `unit_price` tem quatro
                # casas e o total tem duas, então arredondar é obrigatório.
                "total_amount": dinheiro(bruto - desconto + imposto),
                # Item de pedido é imutável depois de emitido: apagá-lo
                # logicamente faria `orders.subtotal_amount` deixar de bater com
                # a soma dos itens que ainda existem.
                "deleted_at": None,
                "__momento": feito_em,
                "__bruto": bruto,
                "__variante": variante,
            }
        )
    return itens


def _montar_pedido(
    motor: Motor,
    fonte,
    carrinho: dict | None,
    cliente_id: int,
    canal_id: int,
    feito_em: dt.datetime,
    itens: list[dict],
    processo: dict,
    estado_final: str,
) -> dict:
    subtotal = dinheiro(sum(item["__bruto"] for item in itens))
    desconto = dinheiro(sum(item["discount_amount"] for item in itens))
    imposto = dinheiro(sum(item["tax_amount"] for item in itens))
    frete = (
        Decimal("0.00")
        if fonte.chance(processo["frete_gratis"])
        else fonte.decimal(*processo["frete_faixa"])
    )
    return {
        "customer_id": cliente_id,
        "sales_channel_id": canal_id,
        "cart_id": carrinho["id"] if carrinho else None,
        "status": estado_final,
        "placed_at": feito_em,
        "subtotal_amount": subtotal,
        "discount_amount": desconto,
        "shipping_amount": frete,
        "tax_amount": imposto,
        # Invariante 2, e `CHECK total_reconcilia`: os cinco campos são
        # `numeric(14,2)`, então a igualdade é exata e não aproximada.
        "total_amount": dinheiro(subtotal - desconto + frete + imposto),
        "deleted_at": None,
    }


def _aplicar_cupons(motor: Motor, dados: Dataset, pedidos_linhas: list[dict]) -> None:
    """Escolhe o cupom de cada pedido respeitando vigência, mínimo e limite.

    Invariante 12. O desconto entra no pedido **e** vira resgate depois: se o
    cupom coubesse só na tabela de resgate, o total do pedido não fecharia com
    o que o cliente pagou.
    """
    # Sem filtrar por `is_active`: esse campo é o estado *hoje*, e o pedido é de
    # ontem. Quem decide elegibilidade é a vigência na data do pedido — filtrar
    # pelo estado atual deixaria dois anos de pedidos sem cupom nenhum.
    cupons = dados["coupons"]
    if not cupons:
        return
    fonte = motor.fonte("coupon_redemptions")
    alvo = motor.linhas("coupon_redemptions")
    usos: dict[int, int] = {}

    escolhidos = sorted(fonte.amostra(range(len(pedidos_linhas)), alvo))
    for indice in escolhidos:
        pedido = pedidos_linhas[indice]
        elegiveis = [
            cupom
            for cupom in cupons
            if cupom["valid_from"] <= pedido["placed_at"] <= cupom["valid_to"]
            and (cupom["min_order_amount"] or 0) <= pedido["subtotal_amount"]
            and (cupom["max_redemptions"] is None or usos.get(cupom["id"], 0) < cupom["max_redemptions"])
        ]
        if not elegiveis:
            continue
        cupom = fonte.escolha(elegiveis)
        if cupom["discount_type"] == "percentage":
            valor = dinheiro(pedido["subtotal_amount"] * cupom["discount_value"] / 100)
        else:
            valor = dinheiro(cupom["discount_value"])
        # `CHECK desconto_limitado`: desconto nunca ultrapassa o subtotal.
        teto = pedido["subtotal_amount"] - pedido["discount_amount"]
        # E o pagamento exige `amount > 0`: um pedido zerado por cupom criaria
        # uma intenção de pagamento de zero reais, que o modelo recusa.
        valor = min(valor, teto, pedido["total_amount"] - Decimal("0.01"))
        if valor <= 0:
            continue
        usos[cupom["id"]] = usos.get(cupom["id"], 0) + 1
        pedido["discount_amount"] = dinheiro(pedido["discount_amount"] + valor)
        pedido["total_amount"] = dinheiro(
            pedido["subtotal_amount"]
            - pedido["discount_amount"]
            + pedido["shipping_amount"]
            + pedido["tax_amount"]
        )
        pedido["__cupom"] = {"coupon_id": cupom["id"], "discount_amount": valor}


def _historico(motor: Motor, dados: Dataset, pedidos_linhas: list[dict]) -> None:
    fonte = motor.fonte("order_status_history")
    esqueletos: list[dict] = []

    for pedido in pedidos_linhas:
        final = pedido["status"]
        caminho = (
            fonte.escolha(_CANCELAMENTO) + ("cancelled",)
            if final == "cancelled"
            else CAMINHOS[final]
        )
        pedido["__caminho"] = caminho
        momento = pedido["placed_at"]
        anterior: str | None = None
        # Quando cada estado aconteceu: é daqui que remessa e pagamento tiram
        # as suas datas, para que a causalidade da invariante 10 seja uma só.
        pedido["__momentos"] = {}
        for estado in caminho:
            pedido["__momentos"][estado] = momento
            esqueletos.append(
                {
                    "order_id": pedido["id"],
                    "from_status": anterior,
                    "to_status": estado,
                    "changed_at": momento,
                    "reason": _MOTIVOS.get(estado),
                    "created_at": momento,
                }
            )
            anterior = estado
            momento = motor.relogio.depois(momento, fonte, 1, 96)
        pedido["__fim_do_caminho"] = momento

    dados.guardar("order_status_history", motor.preencher("order_status_history", esqueletos))
