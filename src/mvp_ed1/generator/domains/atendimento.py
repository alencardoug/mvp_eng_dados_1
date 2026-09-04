"""Domínio de atendimento — 3 tabelas.

Chamado não nasce de sorteio: nasce de um fato que já está no banco — a entrega
que atrasou, o pagamento que falhou, o pedido que foi devolvido. É o que torna
`fact_support_ticket_event` da Etapa 9 cruzável com as outras fatos em vez de
ser ruído correlacionado com nada.
"""

from __future__ import annotations

import datetime as dt

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import repartir

#: Categorias na ordem em que o modelo as aceita; as primeiras linhas levam uma
#: cada, e o resto é decidido pelo fato que originou o chamado.
_CATEGORIAS = ("delivery", "payment", "product", "return", "account", "other")
_ESTADOS = ("open", "in_progress", "waiting_customer", "resolved", "closed")
_ENCERRADOS = ("resolved", "closed")


def agentes(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("support_agents")
    dados.guardar("support_agents", motor.preencher("support_agents", [{} for _ in range(n)]))


def chamados(motor: Motor, dados: Dataset) -> None:
    fonte = motor.fonte("support_tickets")
    processo = motor.config.tabelas["support_tickets"].processo
    agentes_linhas = dados["support_agents"]
    total = motor.linhas("support_tickets")

    fatos = _fatos(motor, dados)
    esqueletos: list[dict] = []
    for indice in range(total):
        fato = fatos[indice % len(fatos)] if fatos else None
        sem_pedido = fonte.chance(processo["sem_pedido_associado"]) or fato is None
        categoria = _CATEGORIAS[indice] if indice < len(_CATEGORIAS) else (
            "account" if sem_pedido else fato["categoria"]
        )
        estado = _ESTADOS[indice] if indice < len(_ESTADOS) else fonte.ponderada(
            {"closed": 46, "resolved": 24, "in_progress": 14, "waiting_customer": 10, "open": 6}
        )
        if sem_pedido:
            cliente = fonte.escolha(dados["customers"])
            aberto = motor.relogio.sazonal(fonte)
            pedido_id = remessa_id = None
        else:
            cliente, aberto = fato["cliente_id"], fato["momento"]
            pedido_id, remessa_id = fato["order_id"], fato["shipment_id"]
            cliente = {"id": cliente}
        esqueletos.append(
            {
                "customer_id": cliente["id"],
                "order_id": pedido_id,
                "shipment_id": remessa_id,
                "assigned_agent_id": (
                    fonte.escolha(agentes_linhas)["id"] if estado != "open" else None
                ),
                "category": categoria,
                "status": estado,
                "opened_at": aberto,
                "closed_at": (
                    motor.relogio.depois(aberto, fonte, 2, 400) if estado in _ENCERRADOS else None
                ),
                "deleted_at": None,
            }
        )
    chamados_linhas = dados.guardar("support_tickets", motor.preencher("support_tickets", esqueletos))
    _eventos(motor, dados, chamados_linhas)


def _fatos(motor: Motor, dados: Dataset) -> list[dict]:
    """Os acontecimentos que geram atendimento, na ordem em que ocorreram."""
    fatos: list[dict] = []
    pedidos = {linha["id"]: linha for linha in dados["orders"]}

    for remessa in dados["shipments"]:
        pedido = pedidos[remessa["order_id"]]
        atrasada = (
            remessa["delivered_at"] is not None
            and remessa["estimated_delivery_at"] is not None
            and remessa["delivered_at"] > remessa["estimated_delivery_at"]
        )
        if not atrasada and remessa["status"] not in ("lost", "returned"):
            continue
        fatos.append(
            {
                "categoria": "return" if remessa["status"] == "returned" else "delivery",
                "cliente_id": pedido["customer_id"],
                "order_id": pedido["id"],
                "shipment_id": remessa["id"],
                "momento": remessa["delivered_at"] or remessa["created_at"],
            }
        )

    for pagamento in dados["payments"]:
        if pagamento["status"] not in ("failed", "cancelled"):
            continue
        pedido = pedidos[pagamento["order_id"]]
        fatos.append(
            {
                "categoria": "payment",
                "cliente_id": pedido["customer_id"],
                "order_id": pedido["id"],
                "shipment_id": None,
                "momento": pedido["placed_at"],
            }
        )

    for pedido in dados["orders"]:
        if pedido["status"] == "returned":
            fatos.append(
                {
                    "categoria": "product",
                    "cliente_id": pedido["customer_id"],
                    "order_id": pedido["id"],
                    "shipment_id": None,
                    "momento": pedido["__fim_do_caminho"],
                }
            )
    fatos.sort(key=lambda f: (f["momento"], f["order_id"]))
    return fatos


def _eventos(motor: Motor, dados: Dataset, chamados_linhas: list[dict]) -> None:
    fonte = motor.fonte("ticket_events")
    por_chamado = repartir(
        motor.linhas("ticket_events"), len(chamados_linhas), fonte, minimo=2, maximo=9
    )

    # O primeiro chamado em andamento é sempre reaberto: sem isso `reopened`
    # depende de 25% de 14% dos chamados e desaparece em fator pequeno.
    reabertura_pendente = True

    esqueletos: list[dict] = []
    for chamado, quantidade in zip(chamados_linhas, por_chamado):
        tipos = ["created"]
        if chamado["assigned_agent_id"]:
            tipos.append("assigned")
        while len(tipos) < quantidade - 1:
            tipos.append("message" if fonte.chance(0.7) else "status_changed")
        if chamado["status"] in _ENCERRADOS:
            tipos.append("resolved")
        elif chamado["status"] == "in_progress" and (reabertura_pendente or fonte.chance(0.25)):
            tipos.append("reopened")
            reabertura_pendente = False
        tipos = tipos[:max(quantidade, 1)]

        fim = chamado["closed_at"] or motor.fim
        passo = max((fim - chamado["opened_at"]) / max(len(tipos), 1), dt.timedelta(minutes=15))
        momento = chamado["opened_at"]
        for tipo in tipos:
            esqueletos.append(
                {
                    "ticket_id": chamado["id"],
                    "agent_id": (
                        chamado["assigned_agent_id"] if tipo != "created" and fonte.chance(0.8) else None
                    ),
                    "event_type": tipo,
                    "occurred_at": momento,
                    "created_at": momento,
                }
            )
            momento = min(momento + passo, motor.fim)
    dados.guardar("ticket_events", motor.preencher("ticket_events", esqueletos))
