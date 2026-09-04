"""Domínio de fornecedores e compras — 5 tabelas.

É aqui que o estoque nasce. A invariante 6 — recebimento não supera o
solicitado — atravessa `goods_receipt_items` e `purchase_order_items`, e por
isso o modelo não a expressa como `CHECK`: ela é garantida na geração e
cobrada por teste.

O estado da ordem **não** é sorteado: é recalculado do que foi efetivamente
recebido. Ordem marcada `received` sem recebimento é o tipo de incoerência que
passa em toda constraint e só aparece na reconciliação.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import cobrir, dinheiro, preco, repartir

_SEM_RECEBIMENTO = ("draft", "placed", "cancelled")


def fornecedores(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("suppliers")
    dados.guardar("suppliers", motor.preencher("suppliers", [{} for _ in range(n)]))


def ordens(motor: Motor, dados: Dataset) -> None:
    ordens_linhas = _ordens(motor, dados)
    itens = _itens(motor, dados, ordens_linhas)
    recebimentos, itens_recebidos = _recebimentos(motor, dados, ordens_linhas, itens)
    _fechar_estado(ordens_linhas, itens, recebimentos, itens_recebidos)


def _ordens(motor: Motor, dados: Dataset) -> list[dict]:
    fornecedores_ids = [linha["id"] for linha in dados["suppliers"] if not linha["deleted_at"]]
    fonte = motor.fonte("purchase_orders")
    processo = motor.config.tabelas["purchase_orders"].processo
    minimo, maximo = processo["prazo_prometido_dias"]

    total = motor.linhas("purchase_orders")
    destinos = cobrir(
        [fonte.ponderada(processo["destino"]) for _ in range(total)],
        tuple(processo["destino"]),
    )

    esqueletos: list[dict] = []
    for indice in range(total):
        emitida = motor.relogio.sazonal(fonte)
        esqueletos.append(
            {
                "supplier_id": fonte.escolha(fornecedores_ids),
                "ordered_at": emitida,
                # Prazo prometido pode cair depois de `as_of_date`: é promessa,
                # não evento — e ordem recente com entrega futura é o normal.
                "expected_at": emitida + _dias(fonte, minimo, maximo),
                "status": "draft",
                "total_amount": Decimal("0"),
                "__destino": destinos[indice],
            }
        )
    return dados.guardar("purchase_orders", motor.preencher("purchase_orders", esqueletos))


def _itens(motor: Motor, dados: Dataset, ordens_linhas: list[dict]) -> list[dict]:
    variantes = dados["product_variants"]
    fonte = motor.fonte("purchase_order_items")
    processo = motor.config.tabelas["purchase_order_items"].processo
    minimo_itens, maximo_itens = processo["itens_por_ordem"]
    minimo_qtd, maximo_qtd = processo["quantidade_por_item"]

    por_ordem = repartir(
        motor.linhas("purchase_order_items"), len(ordens_linhas), fonte,
        minimo=minimo_itens, maximo=maximo_itens,
    )

    esqueletos: list[dict] = []
    for ordem, quantidade in zip(ordens_linhas, por_ordem):
        # Variantes distintas: `uq_purchase_order_items_ordem_variante` recusa
        # o mesmo SKU duas vezes na mesma ordem.
        for variante in fonte.amostra(variantes, quantidade):
            pedida = fonte.inteiro(minimo_qtd, maximo_qtd)
            custo = preco(variante["__custo"] * Decimal(str(fonte.rng.uniform(0.9, 1.08))))
            esqueletos.append(
                {
                    "purchase_order_id": ordem["id"],
                    "product_variant_id": variante["id"],
                    "quantity_ordered": pedida,
                    "unit_cost": custo,
                    "total_cost": dinheiro(custo * pedida),
                    "__momento": ordem["ordered_at"],
                }
            )
    itens = dados.guardar("purchase_order_items", motor.preencher("purchase_order_items", esqueletos))

    # O total da ordem é a soma dos itens — o mesmo padrão de denormalização por
    # imutabilidade do fato que `orders` usa (Modelo de Dados §2.10).
    total_por_ordem: dict[int, Decimal] = {}
    for item in itens:
        chave = item["purchase_order_id"]
        total_por_ordem[chave] = total_por_ordem.get(chave, Decimal("0")) + item["total_cost"]
    for ordem in ordens_linhas:
        ordem["total_amount"] = dinheiro(total_por_ordem.get(ordem["id"], Decimal("0")))
    return itens


def _recebimentos(
    motor: Motor, dados: Dataset, ordens_linhas: list[dict], itens: list[dict]
) -> tuple[list[dict], list[dict]]:
    armazens = dados["warehouses"]
    fonte = motor.fonte("goods_receipts")
    processo = motor.config.tabelas["goods_receipts"].processo
    minimo_dias, maximo_dias = processo["prazo_de_recebimento_dias"]
    fracao_min, fracao_max = motor.config.tabelas["goods_receipt_items"].processo["fracao_parcial"]

    itens_por_ordem: dict[int, list[dict]] = {}
    for item in itens:
        itens_por_ordem.setdefault(item["purchase_order_id"], []).append(item)

    recebiveis = [o for o in ordens_linhas if o["__destino"] not in _SEM_RECEBIMENTO]
    alvo = motor.linhas("goods_receipts")
    # Entregas em duas remessas: é o que leva a contagem de recebimentos acima
    # da de ordens sem inventar ordem nenhuma.
    com_dois = set(fonte.amostra(range(len(recebiveis)), max(alvo - len(recebiveis), 0)))

    recebimentos: list[dict] = []
    itens_recebidos: list[dict] = []
    for indice, ordem in enumerate(recebiveis):
        do_pedido = itens_por_ordem.get(ordem["id"], [])
        if not do_pedido:
            continue
        armazem = fonte.escolha(armazens)
        lotes = 2 if indice in com_dois else 1
        parcial = ordem["__destino"] == "partially_received"

        for lote in range(lotes):
            recebido_em = motor.relogio.depois(
                ordem["ordered_at"], fonte, minimo_dias * 24, maximo_dias * 24
            )
            # Cobertura antes do sorteio: os três primeiros recebimentos levam
            # um estado cada, para que `rejected` exista em qualquer semente.
            estados_possiveis = tuple(processo["estado"])
            estado = (
                estados_possiveis[len(recebimentos)]
                if len(recebimentos) < len(estados_possiveis)
                else fonte.ponderada(processo["estado"])
            )
            recebimento = {
                "id": len(recebimentos) + 1,
                "purchase_order_id": ordem["id"],
                "warehouse_id": armazem["id"],
                "received_at": recebido_em,
                "status": estado,
            }
            recebimentos.append(recebimento)

            for item in do_pedido:
                fatia = Decimal(1) / lotes
                pedida = Decimal(item["quantity_ordered"])
                if parcial:
                    pedida *= Decimal(str(fonte.rng.uniform(fracao_min, fracao_max)))
                quantidade = int(pedida * fatia)
                if quantidade <= 0:
                    continue
                itens_recebidos.append(
                    {
                        "goods_receipt_id": recebimento["id"],
                        "purchase_order_item_id": item["id"],
                        "quantity_received": quantidade,
                        "unit_cost": item["unit_cost"],
                        "__momento": recebido_em,
                        "__warehouse_id": armazem["id"],
                        "__product_variant_id": item["product_variant_id"],
                        "__status": estado,
                    }
                )

    dados.guardar("goods_receipts", motor.preencher("goods_receipts", recebimentos))
    dados.guardar("goods_receipt_items", motor.preencher("goods_receipt_items", itens_recebidos))
    return recebimentos, itens_recebidos


def _fechar_estado(
    ordens_linhas: list[dict],
    itens: list[dict],
    recebimentos: list[dict],
    itens_recebidos: list[dict],
) -> None:
    """Estado da ordem a partir do que foi recebido, e nunca o contrário.

    Só recebimento `completed` conta. Um recebimento `rejected` deixa a ordem
    onde ela estava — que é o comportamento que a operação real tem, e o que a
    reconciliação da Etapa 6 vai cobrar.
    """
    ordem_do_recebimento = {r["id"]: r["purchase_order_id"] for r in recebimentos}
    concluido = {r["id"] for r in recebimentos if r["status"] == "completed"}

    pedido_por_ordem: dict[int, int] = {}
    for item in itens:
        pedido_por_ordem[item["purchase_order_id"]] = (
            pedido_por_ordem.get(item["purchase_order_id"], 0) + item["quantity_ordered"]
        )
    recebido_por_ordem: dict[int, int] = {}
    for item in itens_recebidos:
        if item["goods_receipt_id"] not in concluido:
            continue
        ordem = ordem_do_recebimento[item["goods_receipt_id"]]
        recebido_por_ordem[ordem] = recebido_por_ordem.get(ordem, 0) + item["quantity_received"]

    for ordem in ordens_linhas:
        pedido = pedido_por_ordem.get(ordem["id"], 0)
        recebido = recebido_por_ordem.get(ordem["id"], 0)
        destino = ordem["__destino"]
        if destino == "cancelled":
            ordem["status"] = "cancelled"
        elif recebido <= 0:
            ordem["status"] = "draft" if destino == "draft" else "placed"
        elif recebido >= pedido:
            ordem["status"] = "received"
        else:
            ordem["status"] = "partially_received"


def _dias(fonte, minimo: int, maximo: int) -> dt.timedelta:
    return dt.timedelta(days=fonte.inteiro(minimo, maximo))
