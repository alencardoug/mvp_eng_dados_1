"""Domínio de marketing — 3 tabelas.

Campanhas cobrem o período em janelas sucessivas para que sempre exista cupom
vigente na data de qualquer pedido — e também cupom já encerrado, que é o caso
que a invariante 12 precisa poder reprovar.

O resgate não decide nada: ele registra o cupom que o pedido já aplicou, em
`vendas`. Decidir de novo aqui produziria um desconto na tabela de resgate que
não bate com o desconto do pedido.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import cobrir, dinheiro


def campanhas(motor: Motor, dados: Dataset) -> None:
    _campanhas(motor, dados)
    _cupons(motor, dados)


def _campanhas(motor: Motor, dados: Dataset) -> None:
    fonte = motor.fonte("campaigns")
    total = motor.linhas("campaigns")
    duracao = (motor.fim - motor.inicio) / total

    esqueletos: list[dict] = []
    for indice in range(total):
        inicio = motor.inicio + duracao * indice
        esqueletos.append(
            {
                "valid_from": inicio,
                # Sobreposição de propósito: campanhas encavaladas garantem que
                # nenhuma data do período fique sem campanha vigente.
                "valid_to": min(inicio + duracao * 2, motor.fim),
                "is_active": inicio + duracao * 2 >= motor.fim,
            }
        )
    dados.guardar("campaigns", motor.preencher("campaigns", esqueletos))


def _cupons(motor: Motor, dados: Dataset) -> None:
    campanhas_linhas = dados["campaigns"]
    fonte = motor.fonte("coupons")
    total = motor.linhas("coupons")

    tipos = cobrir(
        ["percentage" if indice % 10 < 7 else "fixed" for indice in range(total)],
        ("percentage", "fixed"),
    )

    esqueletos: list[dict] = []
    for indice in range(total):
        campanha = campanhas_linhas[indice % len(campanhas_linhas)]
        tipo = tipos[indice]
        esqueletos.append(
            {
                "campaign_id": campanha["id"],
                "discount_type": tipo,
                "discount_value": (
                    dinheiro(fonte.inteiro(5, 40)) if tipo == "percentage"
                    else dinheiro(fonte.inteiro(10, 200))
                ),
                "min_order_amount": (
                    dinheiro(fonte.inteiro(50, 400)) if fonte.chance(0.45) else None
                ),
                "valid_from": campanha["valid_from"],
                "valid_to": campanha["valid_to"],
                "is_active": campanha["is_active"],
            }
        )
    dados.guardar("coupons", motor.preencher("coupons", esqueletos))


def resgates(motor: Motor, dados: Dataset) -> None:
    esqueletos = [
        {
            "coupon_id": pedido["__cupom"]["coupon_id"],
            "customer_id": pedido["customer_id"],
            "order_id": pedido["id"],
            "discount_amount": pedido["__cupom"]["discount_amount"],
            "redeemed_at": pedido["placed_at"],
            "created_at": pedido["placed_at"],
        }
        for pedido in dados["orders"]
        if "__cupom" in pedido
    ]
    dados.guardar("coupon_redemptions", motor.preencher("coupon_redemptions", esqueletos))
