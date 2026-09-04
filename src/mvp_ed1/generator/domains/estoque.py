"""Domínio de estoque — 4 tabelas.

A parte mais delicada da geração. `inventory_movements` é livro de eventos:
não se sorteia um movimento, **monta-se** a partir do que já aconteceu — o
recebimento que entrou, a remessa que saiu, a devolução que voltou. Depois o
livro é percorrido em ordem de acontecimento, e só então o saldo existe.

Duas coisas que essa ordem garante e que sorteio nenhum garantiria:

* o saldo **nunca fica negativo** — quando a expedição não tem lastro, entra um
  ajuste de entrada antes dela, que é exatamente o que uma operação real faz ao
  descobrir divergência de inventário;
* `aggregate_version` é sequencial e sem lacuna dentro de cada par armazém/SKU,
  que é o que a `UNIQUE (warehouse_id, product_variant_id, aggregate_version)`
  do modelo exige e o que o consumidor do streaming vai usar para ordenar.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.domains.logistica import DESPACHADAS
from mvp_ed1.generator.engine import Motor

_MOTIVOS_DE_AJUSTE = (
    "Inventário cíclico", "Avaria em armazém", "Divergência de conferência",
    "Perda por validade", "Correção de lançamento",
)


def armazens(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("warehouses")
    dados.guardar("warehouses", motor.preencher("warehouses", [{} for _ in range(n)]))


def livro(motor: Motor, dados: Dataset) -> None:
    """Livro de eventos, reservas e saldo — nesta ordem, que não é arbitrária.

    O saldo é projeção do livro (Modelo de Dados §2.10) e a reserva ocupa parte
    dele; inverter a ordem obrigaria a inventar um saldo e depois torcer para o
    livro bater com ele.
    """
    movimentos = _montar(motor, dados)
    movimentos = _ordenar_e_versionar(motor, movimentos)
    dados.guardar("inventory_movements", motor.preencher("inventory_movements", movimentos))
    reservas = _reservas(motor, dados, movimentos)
    _saldos(motor, dados, movimentos, reservas)


# ── Montagem ─────────────────────────────────────────────────────────────────
def _montar(motor: Motor, dados: Dataset) -> list[dict]:
    fonte = motor.fonte("inventory_movements")
    processo = motor.config.tabelas["inventory_movements"].processo
    alvo = motor.linhas("inventory_movements")
    armazens_ids = [linha["id"] for linha in dados["warehouses"]]
    variantes = dados["product_variants"]

    movimentos: list[dict] = []
    movimentos += _estoque_inicial(motor, fonte, processo, armazens_ids, variantes)
    movimentos += _entradas_de_compra(motor, dados)
    movimentos += _saidas_de_venda(motor, dados)
    movimentos += _devolucoes_de_cliente(motor, dados)
    # `max(…, 1)` e `max(…, 2)`: em fator pequeno o arredondamento zeraria a
    # transferência e o ajuste, e com eles sumiriam quatro dos oito tipos de
    # movimento que o modelo aceita. O piso do ADR-0014 vale aqui também.
    movimentos += _devolucoes_a_fornecedor(
        motor, fonte, dados, max(round(alvo * processo["devolucao_a_fornecedor"]), 1)
    )
    movimentos += _transferencias(
        motor, fonte, armazens_ids, variantes, max(round(alvo * processo["transferencias"]) // 2, 1)
    )
    movimentos += _ajustes(
        motor, fonte, armazens_ids, variantes, max(round(alvo * processo["ajustes"]), 2)
    )
    return movimentos


def _evento(
    tipo: str,
    origem: str,
    origem_id: str,
    armazem: int,
    variante: int,
    delta: int,
    momento: dt.datetime,
    *,
    custo: Decimal | None = None,
    correlacao=None,
    causacao=None,
    metadados: dict | None = None,
) -> dict:
    return {
        "movement_type": tipo,
        "source_type": origem,
        "source_id": origem_id,
        "warehouse_id": armazem,
        "product_variant_id": variante,
        "quantity_delta": delta,
        "unit_cost": custo,
        "occurred_at": momento,
        "correlation_id": correlacao,
        "causation_id": causacao,
        "metadata": metadados,
    }


def _estoque_inicial(motor, fonte, processo, armazens_ids, variantes) -> list[dict]:
    """Formação do estoque inicial — Geração de Dados §3, passo 4.

    Sem ele o saldo cobriria só os pares que passaram por recebimento de
    compra, e a cobertura de `inventory_balances` ficaria na metade da
    proporção declarada: 1.520 itens recebidos não estocam 2.500 pares.
    """
    pares = [(a, v["id"], v) for a in armazens_ids for v in variantes]
    quantos = round(len(pares) * processo["cobertura_de_saldo"])
    escolhidos = sorted(fonte.amostra(range(len(pares)), quantos))
    return [
        _evento(
            "adjustment_in", "adjustment", "ESTOQUE-INICIAL",
            pares[i][0], pares[i][1], fonte.inteiro(10, 400), motor.inicio,
            custo=pares[i][2]["__custo"],
            metadados={"motivo": "Carga inicial de estoque", "origem": "abertura"},
        )
        for i in escolhidos
    ]


def _entradas_de_compra(motor: Motor, dados: Dataset) -> list[dict]:
    """Uma entrada por item recebido — e só de recebimento concluído.

    Recebimento `pending` ou `rejected` não move estoque: é essa distinção que
    faz o estado da ordem de compra ter consequência física.
    """
    numeros = {linha["id"]: linha["receipt_number"] for linha in dados["goods_receipts"]}
    return [
        _evento(
            "purchase_receipt", "purchase", numeros[item["goods_receipt_id"]],
            item["__warehouse_id"], item["__product_variant_id"],
            item["quantity_received"], item["created_at"], custo=item["unit_cost"],
        )
        for item in dados["goods_receipt_items"]
        if item["__status"] == "completed" and item["quantity_received"] > 0
    ]


def _saidas_de_venda(motor: Motor, dados: Dataset) -> list[dict]:
    custos = {linha["id"]: linha["__custo"] for linha in dados["product_variants"]}
    return [
        _evento(
            "sale_dispatch", "sale", item["__remessa"]["shipment_code"],
            item["__warehouse_id"], item["__product_variant_id"],
            -item["quantity"], item["created_at"],
            custo=custos[item["__product_variant_id"]],
        )
        for item in dados["shipment_items"]
        if item["__remessa"]["status"] in DESPACHADAS
    ]


def _devolucoes_de_cliente(motor: Motor, dados: Dataset) -> list[dict]:
    custos = {linha["id"]: linha["__custo"] for linha in dados["product_variants"]}
    movimentos = []
    for item in dados["shipment_items"]:
        remessa = item["__remessa"]
        if remessa["status"] != "returned":
            continue
        momento = remessa["delivered_at"] or remessa["created_at"]
        movimentos.append(
            _evento(
                "customer_return", "return", remessa["shipment_code"],
                item["__warehouse_id"], item["__product_variant_id"],
                item["quantity"], min(momento + dt.timedelta(days=3), motor.fim),
                custo=custos[item["__product_variant_id"]],
            )
        )
    return movimentos


def _devolucoes_a_fornecedor(motor, fonte, dados: Dataset, quantos: int) -> list[dict]:
    recebidos = [i for i in dados["goods_receipt_items"] if i["__status"] == "completed"]
    if not recebidos or quantos <= 0:
        return []
    numeros = {linha["id"]: linha["receipt_number"] for linha in dados["goods_receipts"]}
    movimentos = []
    for item in fonte.amostra(recebidos, quantos):
        quantidade = max(1, item["quantity_received"] // 20)
        movimentos.append(
            _evento(
                "supplier_return", "return", numeros[item["goods_receipt_id"]],
                item["__warehouse_id"], item["__product_variant_id"],
                -quantidade,
                motor.relogio.depois(item["created_at"], fonte, 24, 720),
                custo=item["unit_cost"],
            )
        )
    return movimentos


def _transferencias(motor, fonte, armazens_ids, variantes, pares: int) -> list[dict]:
    """Saída e entrada com o mesmo `correlation_id` e a mesma quantidade.

    Transferência que não fecha dos dois lados some do saldo consolidado sem
    deixar rastro — é o caso que a Etapa 7 vai testar nos dois armazéns.
    """
    if len(armazens_ids) < 2 or pares <= 0:
        return []
    movimentos: list[dict] = []
    for _ in range(pares):
        origem, destino = fonte.amostra(armazens_ids, 2)
        variante = fonte.escolha(variantes)
        quantidade = fonte.inteiro(1, 40)
        momento = motor.relogio.sazonal(fonte)
        correlacao = fonte.uuid()
        codigo = f"TRF-{str(correlacao)[:8].upper()}"
        movimentos.append(
            _evento("transfer_out", "transfer", codigo, origem, variante["id"],
                    -quantidade, momento, custo=variante["__custo"], correlacao=correlacao)
        )
        movimentos.append(
            _evento("transfer_in", "transfer", codigo, destino, variante["id"],
                    quantidade, min(momento + dt.timedelta(days=2), motor.fim),
                    custo=variante["__custo"], correlacao=correlacao)
        )
    return movimentos


def _ajustes(motor, fonte, armazens_ids, variantes, quantos: int) -> list[dict]:
    movimentos = []
    for indice in range(max(quantos, 0)):
        entrada = indice % 2 == 0
        variante = fonte.escolha(variantes)
        quantidade = fonte.inteiro(1, 30)
        movimentos.append(
            _evento(
                "adjustment_in" if entrada else "adjustment_out",
                "adjustment",
                f"AJU-{indice + 1:06d}",
                fonte.escolha(armazens_ids),
                variante["id"],
                quantidade if entrada else -quantidade,
                motor.relogio.sazonal(fonte),
                custo=variante["__custo"],
                # O modelo pede motivo documentado no ajuste; é também o que dá
                # ao `metadata` jsonb conteúdo real para o CDC transportar.
                metadados={"motivo": fonte.escolha(_MOTIVOS_DE_AJUSTE)},
            )
        )
    return movimentos


# ── Ordenação, correção e versionamento ──────────────────────────────────────
def _ordenar_e_versionar(motor: Motor, movimentos: list[dict]) -> list[dict]:
    fonte = motor.fonte("inventory_movements")
    atraso_min, atraso_max = motor.config.tabelas["inventory_movements"].processo[
        "atraso_de_registro_segundos"
    ]

    por_agregado: dict[tuple[int, int], list[dict]] = {}
    for movimento in movimentos:
        chave = (movimento["warehouse_id"], movimento["product_variant_id"])
        por_agregado.setdefault(chave, []).append(movimento)

    final: list[dict] = []
    for chave in sorted(por_agregado):
        eventos = sorted(por_agregado[chave], key=lambda m: m["occurred_at"])
        saldo = 0
        versionados: list[dict] = []
        for evento in eventos:
            if saldo + evento["quantity_delta"] < 0:
                # Sem lastro para a saída: entra a correção de inventário que a
                # operação real faria, um minuto antes, e o livro segue íntegro.
                falta = -(saldo + evento["quantity_delta"])
                correcao = _evento(
                    "adjustment_in", "adjustment", "AJU-CONFERENCIA",
                    chave[0], chave[1], falta,
                    evento["occurred_at"] - dt.timedelta(minutes=1),
                    custo=evento["unit_cost"],
                    metadados={"motivo": "Divergência de conferência", "corrige": evento["source_id"]},
                )
                versionados.append(correcao)
                saldo += falta
            versionados.append(evento)
            saldo += evento["quantity_delta"]

        for versao, evento in enumerate(versionados, start=1):
            evento["aggregate_version"] = versao
            evento["movement_id"] = fonte.uuid()
            evento["causation_id"] = fonte.uuid()
            evento["recorded_at"] = evento["occurred_at"] + dt.timedelta(
                seconds=fonte.inteiro(atraso_min, atraso_max)
            )
            evento["idempotency_key"] = (
                f"{evento['source_type']}:{evento['source_id']}:"
                f"{chave[0]}:{chave[1]}:{versao}"
            )[:100]
            final.append(evento)
    return final


# ── Reservas e saldo ─────────────────────────────────────────────────────────
def _reservas(motor: Motor, dados: Dataset, movimentos: list[dict]) -> list[dict]:
    """Reserva pendurada em um carrinho **ou** em um pedido, nunca nos dois.

    A `CHECK num_nonnulls(cart_id, order_id) = 1` do modelo é a tradução da
    invariante 8: reserva órfã é saldo travado que ninguém libera.
    """
    fonte = motor.fonte("stock_reservations")
    processo = motor.config.tabelas["stock_reservations"].processo
    validade = dt.timedelta(hours=processo["validade_horas"])
    pares = sorted({(m["warehouse_id"], m["product_variant_id"]) for m in movimentos})

    carrinhos = [c for c in dados["carts"] if c["status"] != "converted"]
    pedidos = [p for p in dados["orders"] if p["status"] in ("pending", "paid", "picking")]
    estados_de_carrinho = {"open": "active", "abandoned": "released", "expired": "expired"}

    esqueletos: list[dict] = []
    for indice in range(motor.linhas("stock_reservations")):
        armazem, variante = pares[fonte.inteiro(0, len(pares) - 1)]
        de_carrinho = fonte.chance(processo["origem_carrinho"]) and carrinhos
        if de_carrinho:
            carrinho = fonte.escolha(carrinhos)
            criada, estado = carrinho["created_at"], estados_de_carrinho[carrinho["status"]]
            cart_id, order_id = carrinho["id"], None
        elif pedidos:
            pedido = fonte.escolha(pedidos)
            criada, estado = pedido["placed_at"], "consumed" if pedido["status"] != "pending" else "active"
            cart_id, order_id = None, pedido["id"]
        else:
            continue
        esqueletos.append(
            {
                "warehouse_id": armazem,
                "product_variant_id": variante,
                "cart_id": cart_id,
                "order_id": order_id,
                "quantity": fonte.inteiro(1, 5),
                "status": estado,
                "expires_at": criada + validade,
                "released_at": None if estado == "active" else min(criada + validade, motor.fim),
                "created_at": criada,
                "deleted_at": None,
            }
        )
    return dados.guardar("stock_reservations", motor.preencher("stock_reservations", esqueletos))


def _saldos(motor: Motor, dados: Dataset, movimentos: list[dict], reservas: list[dict]) -> None:
    """Projeção do livro: soma dos deltas, e a reserva ativa em cima dela."""
    saldo: dict[tuple[int, int], int] = {}
    ultimo: dict[tuple[int, int], dt.datetime] = {}
    for movimento in movimentos:
        chave = (movimento["warehouse_id"], movimento["product_variant_id"])
        saldo[chave] = saldo.get(chave, 0) + movimento["quantity_delta"]
        anterior = ultimo.get(chave)
        if anterior is None or movimento["occurred_at"] > anterior:
            ultimo[chave] = movimento["occurred_at"]

    reservado: dict[tuple[int, int], int] = {}
    for reserva in reservas:
        if reserva["status"] != "active":
            continue  # Invariante 8: liberada, expirada ou consumida não ocupa saldo.
        chave = (reserva["warehouse_id"], reserva["product_variant_id"])
        reservado[chave] = reservado.get(chave, 0) + reserva["quantity"]

    esqueletos = [
        {
            "warehouse_id": armazem,
            "product_variant_id": variante,
            "quantity_on_hand": quantidade,
            # `CHECK reserva_limitada_ao_saldo`: não se reserva o que não há.
            "quantity_reserved": min(reservado.get((armazem, variante), 0), quantidade),
            "last_movement_at": ultimo[(armazem, variante)],
            "created_at": motor.inicio,
            "deleted_at": None,
        }
        for (armazem, variante), quantidade in sorted(saldo.items())
    ]
    dados.guardar("inventory_balances", motor.preencher("inventory_balances", esqueletos))
