"""As doze invariantes de negócio do Modelo de Dados §4.

Elas são simultaneamente regra de geração e critério de teste — é o que o
próprio documento diz. Aqui elas são cobradas do conjunto **em memória**, antes
do banco: as que o banco garante por `CHECK` falhariam na carga, mas as sete
que atravessam linhas passariam despercebidas até a reconciliação da Etapa 6.
"""

from __future__ import annotations

from collections import defaultdict
from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset


def _por(chave: str, linhas: list[dict]) -> dict:
    agrupado = defaultdict(list)
    for linha in linhas:
        agrupado[linha[chave]].append(linha)
    return agrupado


def test_1_item_referencia_pedido_e_sku_existentes(dados: Dataset) -> None:
    pedidos = {p["id"] for p in dados["orders"]}
    variantes = {v["id"] for v in dados["product_variants"]}
    for item in dados["order_items"]:
        assert item["order_id"] in pedidos
        assert item["product_variant_id"] in variantes


def test_2_total_do_pedido_reconcilia(dados: Dataset) -> None:
    itens = _por("order_id", dados["order_items"])
    for pedido in dados["orders"]:
        esperado = (
            pedido["subtotal_amount"]
            - pedido["discount_amount"]
            + pedido["shipping_amount"]
            + pedido["tax_amount"]
        )
        assert pedido["total_amount"] == esperado
        bruto = sum(i["quantity"] * i["unit_price"] for i in itens[pedido["id"]])
        assert abs(pedido["subtotal_amount"] - bruto) <= Decimal("0.02")
        assert pedido["discount_amount"] <= pedido["subtotal_amount"]


def test_3_captura_nunca_excede_a_autorizacao(dados: Dataset) -> None:
    por_pagamento = _por("payment_id", dados["payment_transactions"])
    for transacoes in por_pagamento.values():
        autorizado = sum(
            t["amount"] for t in transacoes
            if t["transaction_type"] == "authorization" and t["result"] == "succeeded"
        )
        capturado = sum(
            t["amount"] for t in transacoes
            if t["transaction_type"] == "capture" and t["result"] == "succeeded"
        )
        assert capturado <= autorizado


def test_4_reembolso_nunca_excede_a_captura(dados: Dataset) -> None:
    capturas = {t["id"]: t for t in dados["payment_transactions"]}
    devolvido: dict[int, Decimal] = defaultdict(lambda: Decimal("0"))
    for reembolso in dados["refunds"]:
        devolvido[reembolso["payment_transaction_id"]] += reembolso["amount"]
    for transacao_id, valor in devolvido.items():
        assert valor <= capturas[transacao_id]["amount"]


def test_5_remessa_nao_envia_mais_do_que_foi_vendido(dados: Dataset) -> None:
    vendido = {i["id"]: i["quantity"] for i in dados["order_items"]}
    enviado: dict[int, int] = defaultdict(int)
    for item in dados["shipment_items"]:
        enviado[item["order_item_id"]] += item["quantity"]
    for item_id, quantidade in enviado.items():
        assert quantidade <= vendido[item_id]


def test_6_recebimento_nao_supera_o_solicitado(dados: Dataset) -> None:
    pedido = {i["id"]: i["quantity_ordered"] for i in dados["purchase_order_items"]}
    recebido: dict[int, int] = defaultdict(int)
    for item in dados["goods_receipt_items"]:
        recebido[item["purchase_order_item_id"]] += item["quantity_received"]
    for item_id, quantidade in recebido.items():
        assert quantidade <= pedido[item_id]


def test_7_todo_movimento_tem_origem_de_negocio(dados: Dataset) -> None:
    for movimento in dados["inventory_movements"]:
        assert movimento["source_type"]
        assert movimento["source_id"]
        assert movimento["quantity_delta"] != 0


def test_8_reserva_encerrada_nao_ocupa_saldo(dados: Dataset) -> None:
    ativo: dict[tuple[int, int], int] = defaultdict(int)
    for reserva in dados["stock_reservations"]:
        if reserva["status"] == "active":
            ativo[(reserva["warehouse_id"], reserva["product_variant_id"])] += reserva["quantity"]
    for saldo in dados["inventory_balances"]:
        chave = (saldo["warehouse_id"], saldo["product_variant_id"])
        assert saldo["quantity_reserved"] <= ativo[chave]
        assert saldo["quantity_reserved"] <= saldo["quantity_on_hand"]


def test_9_transicoes_de_estado_sao_validas(dados: Dataset) -> None:
    from mvp_ed1.generator.domains.vendas import CAMINHOS

    validas = {(None, "pending")}
    for caminho in list(CAMINHOS.values()) + [("pending", "paid", "picking", "cancelled")]:
        validas |= set(zip(caminho, caminho[1:]))
    validas |= {("pending", "cancelled"), ("paid", "cancelled"), ("picking", "cancelled")}

    historico = _por("order_id", dados["order_status_history"])
    estados = {p["id"]: p["status"] for p in dados["orders"]}
    for pedido_id, eventos in historico.items():
        eventos = sorted(eventos, key=lambda e: e["changed_at"])
        for evento in eventos:
            assert evento["from_status"] != evento["to_status"]
            assert (evento["from_status"], evento["to_status"]) in validas
        assert eventos[-1]["to_status"] == estados[pedido_id]


def test_10_datas_respeitam_a_causalidade(dados: Dataset) -> None:
    for pagamento in dados["payments"]:
        if pagamento["captured_at"]:
            assert pagamento["authorized_at"] is not None
            assert pagamento["captured_at"] >= pagamento["authorized_at"]
    for remessa in dados["shipments"]:
        if remessa["delivered_at"] and remessa["shipped_at"]:
            assert remessa["delivered_at"] >= remessa["shipped_at"]
    for movimento in dados["inventory_movements"]:
        assert movimento["recorded_at"] >= movimento["occurred_at"]
    for chamado in dados["support_tickets"]:
        if chamado["closed_at"]:
            assert chamado["closed_at"] >= chamado["opened_at"]


def test_11_vigencias_do_mesmo_par_nao_se_sobrepoem(dados: Dataset) -> None:
    por_par: dict[tuple[int, int], list[dict]] = defaultdict(list)
    for preco in dados["product_prices"]:
        por_par[(preco["price_list_id"], preco["product_variant_id"])].append(preco)
    for vigencias in por_par.values():
        vigencias.sort(key=lambda p: p["valid_from"])
        for anterior, seguinte in zip(vigencias, vigencias[1:]):
            assert anterior["valid_to"] is not None
            assert anterior["valid_to"] <= seguinte["valid_from"]


def test_12_cupom_usado_dentro_da_vigencia_e_das_regras(dados: Dataset) -> None:
    cupons = {c["id"]: c for c in dados["coupons"]}
    pedidos = {p["id"]: p for p in dados["orders"]}
    usos: dict[int, int] = defaultdict(int)
    for resgate in dados["coupon_redemptions"]:
        cupom = cupons[resgate["coupon_id"]]
        pedido = pedidos[resgate["order_id"]]
        assert cupom["valid_from"] <= resgate["redeemed_at"] <= cupom["valid_to"]
        assert pedido["subtotal_amount"] >= (cupom["min_order_amount"] or 0)
        assert resgate["discount_amount"] <= pedido["discount_amount"]
        usos[cupom["id"]] += 1
    for cupom_id, quantidade in usos.items():
        limite = cupons[cupom_id]["max_redemptions"]
        assert limite is None or quantidade <= limite


def test_livro_de_estoque_e_integro(dados: Dataset) -> None:
    """O saldo é a soma dos deltas, a versão não tem lacuna e a transferência fecha."""
    saldo: dict[tuple[int, int], int] = defaultdict(int)
    versoes: dict[tuple[int, int], list[int]] = defaultdict(list)
    correlacoes: dict[object, int] = defaultdict(int)
    chaves: set[str] = set()

    for movimento in sorted(dados["inventory_movements"], key=lambda m: m["occurred_at"]):
        chave = (movimento["warehouse_id"], movimento["product_variant_id"])
        saldo[chave] += movimento["quantity_delta"]
        assert saldo[chave] >= 0, f"saldo negativo em {chave}"
        versoes[chave].append(movimento["aggregate_version"])
        if movimento["correlation_id"]:
            correlacoes[movimento["correlation_id"]] += movimento["quantity_delta"]
        assert movimento["idempotency_key"] not in chaves
        chaves.add(movimento["idempotency_key"])

    for chave, lista in versoes.items():
        assert sorted(lista) == list(range(1, len(lista) + 1)), chave
    for total in correlacoes.values():
        assert total == 0, "transferência que não fecha dos dois lados"

    projetado = {
        (s["warehouse_id"], s["product_variant_id"]): s["quantity_on_hand"]
        for s in dados["inventory_balances"]
    }
    assert projetado == dict(saldo)
