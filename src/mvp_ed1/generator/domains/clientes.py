"""Domínio de clientes — 5 tabelas.

Endereço e contato são filhos: quantos cada cliente tem sai da proporção
declarada, e o "principal" de cada tipo é único por índice parcial no modelo —
por isso ele é decidido aqui, uma vez por grupo, e nunca sorteado por linha.
"""

from __future__ import annotations

import datetime as dt

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import cobrir, repartir


def segmentos(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("customer_segments")
    dados.guardar("customer_segments", motor.preencher("customer_segments", [{} for _ in range(n)]))


def cadastro(motor: Motor, dados: Dataset) -> None:
    segmentos_ids = [linha["id"] for linha in dados["customer_segments"]]
    fonte = motor.fonte("customers")

    n = motor.linhas("customers")
    esqueletos = [{"segment_id": fonte.escolha(segmentos_ids)} for _ in range(n)]
    clientes = dados.guardar("customers", motor.preencher("customers", esqueletos))

    _enderecos(motor, dados, clientes)
    _contatos(motor, dados, clientes)
    _preferencias(motor, dados, clientes)


def _enderecos(motor: Motor, dados: Dataset, clientes: list[dict]) -> None:
    fonte = motor.fonte("customer_addresses")
    total = motor.linhas("customer_addresses")
    por_cliente = repartir(total, len(clientes), fonte, minimo=1, maximo=4)

    tipos = cobrir(
        [fonte.ponderada({"shipping": 7, "billing": 3}) for _ in range(total)],
        ("billing", "shipping"),
    )

    esqueletos: list[dict] = []
    for cliente, quantidade in zip(clientes, por_cliente):
        principais: set[str] = set()
        for ordem in range(quantidade):
            # O primeiro endereço é sempre de entrega. Cliente de varejo que fez
            # pedido tem para onde receber: sem esta regra, ~30% dos clientes
            # ficavam só com endereço de cobrança e a chave de geografia da fato
            # de venda saía nula para um quinto das linhas.
            tipo = "shipping" if ordem == 0 else tipos[len(esqueletos)]
            # Um principal por tipo, e nunca excluído: é o que o índice parcial
            # `is_primary and deleted_at is null` exige do dado.
            primeiro = tipo not in principais
            principais.add(tipo)
            inicio = motor.relogio.uniforme(fonte, cliente["registered_at"])
            esqueletos.append(
                {
                    "customer_id": cliente["id"],
                    "address_type": tipo,
                    "is_primary": primeiro,
                    "deleted_at": None if primeiro else _talvez_excluido(motor, fonte, inicio),
                    "valid_from": inicio,
                    "valid_to": None if primeiro or fonte.chance(0.7) else motor.relogio.depois(
                        inicio, fonte, 24, 8000
                    ),
                }
            )
    dados.guardar("customer_addresses", motor.preencher("customer_addresses", esqueletos))


def _contatos(motor: Motor, dados: Dataset, clientes: list[dict]) -> None:
    fonte = motor.fonte("customer_contacts")
    total = motor.linhas("customer_contacts")
    por_cliente = repartir(total, len(clientes), fonte, minimo=1, maximo=4)

    tipos = cobrir(
        [fonte.ponderada({"email": 5, "mobile": 4, "phone": 1}) for _ in range(total)],
        ("email", "phone", "mobile"),
    )

    esqueletos: list[dict] = []
    for cliente, quantidade in zip(clientes, por_cliente):
        principais: set[str] = set()
        for _ in range(quantidade):
            tipo = tipos[len(esqueletos)]
            primeiro = tipo not in principais
            principais.add(tipo)
            esqueletos.append(
                {
                    "customer_id": cliente["id"],
                    "contact_type": tipo,
                    "is_primary": primeiro,
                    "deleted_at": None if primeiro else _talvez_excluido(
                        motor, fonte, cliente["registered_at"]
                    ),
                    "__momento": motor.relogio.uniforme(fonte, cliente["registered_at"]),
                }
            )
    dados.guardar("customer_contacts", motor.preencher("customer_contacts", esqueletos))


def _preferencias(motor: Motor, dados: Dataset, clientes: list[dict]) -> None:
    """Uma linha por cliente — `customer_id` é único no modelo.

    Se a proporção pedir menos linhas do que há clientes, os primeiros levam;
    inventar um segundo registro para o mesmo cliente violaria a unicidade.
    """
    total = min(motor.linhas("customer_preferences"), len(clientes))
    esqueletos = [
        {"customer_id": cliente["id"], "__momento": cliente["registered_at"]}
        for cliente in clientes[:total]
    ]
    dados.guardar("customer_preferences", motor.preencher("customer_preferences", esqueletos))


def _talvez_excluido(motor: Motor, fonte, desde: dt.datetime) -> dt.datetime | None:
    if fonte.chance(motor.config.exclusao_logica):
        return motor.relogio.depois(desde, fonte, 1, 4000)
    return None
