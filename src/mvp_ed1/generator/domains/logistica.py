"""Domínio de logística — 4 tabelas.

A remessa só existe para pedido que chegou à separação: remessa de pedido
cancelado em `pending` é dado que nenhuma operação produz.

A invariante 5 — a soma enviada de um item nunca supera a quantidade vendida —
é garantida na divisão da remessa: o item é **repartido** entre as remessas,
não copiado para cada uma.
"""

from __future__ import annotations

import datetime as dt

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import dinheiro

#: Estado da remessa conforme o ponto em que o pedido parou.
_ESTADO_POR_PEDIDO = {
    "picking": ("created", "picking"),
    "shipped": ("dispatched", "in_transit"),
    "delivered": ("delivered",),
    "returned": ("returned",),
}

#: Remessa que saiu do armazém — é o que baixa estoque.
DESPACHADAS = ("dispatched", "in_transit", "delivered", "returned", "lost")


def transportadoras(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("carriers")
    dados.guardar("carriers", motor.preencher("carriers", [{} for _ in range(n)]))


def remessas(motor: Motor, dados: Dataset) -> None:
    transportadoras_linhas = dados["carriers"]
    armazens = dados["warehouses"]
    fonte = motor.fonte("shipments")
    processo = motor.config.tabelas["shipments"].processo

    itens_por_pedido: dict[int, list[dict]] = {}
    for item in dados["order_items"]:
        itens_por_pedido.setdefault(item["order_id"], []).append(item)

    remessas_linhas: list[dict] = []
    itens_de_remessa: list[dict] = []

    for pedido in dados["orders"]:
        estados = _ESTADO_POR_PEDIDO.get(pedido["status"])
        if not estados:
            continue
        itens = itens_por_pedido.get(pedido["id"], [])
        if not itens:
            continue

        transportadora = fonte.escolha(transportadoras_linhas)
        armazem = fonte.escolha(armazens)
        lotes = 2 if fonte.chance(processo["remessa_dividida"]) and len(itens) >= 1 else 1
        frete_por_lote = dinheiro(pedido["shipping_amount"] / lotes)

        for lote in range(lotes):
            estado = fonte.escolha(estados)
            if estado == "delivered" and fonte.chance(processo["extravio"]):
                estado = "lost"
            remessa = _remessa(
                motor, fonte, pedido, transportadora, armazem, estado, frete_por_lote, processo
            )
            remessa["id"] = len(remessas_linhas) + 1
            remessas_linhas.append(remessa)

            for item in itens:
                quantidade = _fatia(item["quantity"], lote, lotes)
                if quantidade <= 0:
                    continue
                itens_de_remessa.append(
                    {
                        "shipment_id": remessa["id"],
                        "order_item_id": item["id"],
                        "quantity": quantidade,
                        "deleted_at": None,
                        "__momento": remessa["shipped_at"] or remessa["created_at"],
                        "__product_variant_id": item["product_variant_id"],
                        "__warehouse_id": armazem["id"],
                        "__remessa": remessa,
                    }
                )

    _garantir_extravio(remessas_linhas)
    dados.guardar("shipments", motor.preencher("shipments", remessas_linhas))
    dados.guardar("shipment_items", motor.preencher("shipment_items", itens_de_remessa))
    _eventos(motor, dados, remessas_linhas)


def _garantir_extravio(remessas_linhas: list[dict]) -> None:
    """`lost` é 0,4% das remessas: em fator pequeno, some.

    A remessa extraviada vira `lost` a partir de uma que estava em trânsito —
    não de uma entregue, que seria contradição com o estado do pedido.
    """
    if any(remessa["status"] == "lost" for remessa in remessas_linhas):
        return
    for remessa in remessas_linhas:
        if remessa["status"] in ("dispatched", "in_transit"):
            remessa["status"] = "lost"
            return


def _remessa(motor, fonte, pedido, transportadora, armazem, estado, frete, processo) -> dict:
    momentos = pedido["__momentos"]
    criada = momentos.get("picking", pedido["placed_at"])
    despachada = momentos.get("shipped") if estado in DESPACHADAS else None
    prazo = processo["prazo_prometido_dias"][transportadora["service_level"]]
    prometida = (
        (despachada or criada) + dt.timedelta(days=fonte.inteiro(*prazo))
    )
    entregue = None
    if estado in ("delivered", "returned"):
        entregue = momentos.get("delivered")
        if entregue and fonte.chance(processo["atraso_na_entrega"]):
            entregue = motor.relogio.depois(prometida, fonte, 12, 120)
    return {
        "order_id": pedido["id"],
        "carrier_id": transportadora["id"],
        "warehouse_id": armazem["id"],
        "status": estado,
        "freight_amount": frete,
        "shipped_at": despachada,
        # Prazo prometido é promessa, não evento: pode cair depois de
        # `as_of_date` sem que isso seja data no futuro.
        "estimated_delivery_at": prometida,
        "delivered_at": entregue if not despachada or not entregue or entregue >= despachada else despachada,
        "created_at": criada,
        "deleted_at": None,
    }


def _fatia(quantidade: int, lote: int, lotes: int) -> int:
    """Reparte a quantidade vendida entre as remessas, sem sobra nem excesso."""
    if lotes == 1:
        return quantidade
    metade = quantidade // 2
    return metade if lote == 0 else quantidade - metade


def _eventos(motor: Motor, dados: Dataset, remessas_linhas: list[dict]) -> None:
    """Rastro de eventos coerente com o estado em que a remessa parou."""
    fonte = motor.fonte("delivery_events")
    processo = motor.config.tabelas["delivery_events"].processo
    cidades = {linha["id"]: linha["city"] for linha in dados["warehouses"]}

    esqueletos: list[dict] = []
    for remessa in remessas_linhas:
        if remessa["status"] in ("created", "picking"):
            continue
        # Trânsito é multi-trecho: um pacote passa por mais de um centro antes
        # de sair para entrega, e cada passagem é um evento.
        tipos = ["picked_up"] + ["in_transit"] * fonte.inteiro(1, 3)
        if remessa["status"] in ("in_transit", "delivered", "returned", "lost"):
            tipos.append("out_for_delivery")
        if fonte.chance(processo["tentativa_frustrada"]):
            tipos.append("delivery_attempt")
        if remessa["status"] == "delivered":
            tipos.append("delivered")
        elif remessa["status"] == "returned":
            tipos += ["delivered", "returned"]

        momento = remessa["shipped_at"] or remessa["created_at"]
        fim = remessa["delivered_at"] or motor.fim
        passo = max((fim - momento) / max(len(tipos), 1), dt.timedelta(minutes=30))
        for tipo in tipos:
            esqueletos.append(
                {
                    "shipment_id": remessa["id"],
                    "event_type": tipo,
                    "occurred_at": momento,
                    "location": cidades.get(remessa["warehouse_id"]),
                    "created_at": momento,
                }
            )
            momento = min(momento + passo, motor.fim)
    dados.guardar("delivery_events", motor.preencher("delivery_events", esqueletos))
