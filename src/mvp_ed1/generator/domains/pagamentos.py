"""Domínio de pagamentos — 4 tabelas.

As invariantes 3 e 4 — captura não excede a autorização, reembolso não excede a
captura — atravessam linhas e por isso o modelo não as expressa como `CHECK`.
Aqui elas são garantidas por construção: a captura é derivada do valor
autorizado, e o reembolso, do valor capturado. Nenhum dos dois é sorteado
livremente.

O estado do pagamento acompanha o do pedido. Pedido entregue com pagamento
`failed` passa em toda constraint do banco e é absurdo comercial — o tipo de
incoerência que só a reconciliação da Etapa 6 encontraria.
"""

from __future__ import annotations

from decimal import Decimal

from mvp_ed1.generator.dataset import Dataset
from mvp_ed1.generator.engine import Motor
from mvp_ed1.generator.rng import dinheiro

#: Meios em que parcelamento não existe.
_A_VISTA = ("pix", "boleto", "debit_card")


def meios(motor: Motor, dados: Dataset) -> None:
    n = motor.linhas("payment_methods")
    dados.guardar("payment_methods", motor.preencher("payment_methods", [{} for _ in range(n)]))


def fluxo(motor: Motor, dados: Dataset) -> None:
    metodos = dados["payment_methods"]
    fonte = motor.fonte("payments")
    processo = motor.config.tabelas["payments"].processo
    parcelas_pesos = {int(k): v for k, v in processo["parcelas_pesos"].items()}

    pagamentos: list[dict] = []
    transacoes: list[dict] = []
    reembolsos: list[dict] = []

    for pedido in dados["orders"]:
        caminho = pedido["__caminho"]
        momentos = pedido["__momentos"]
        pago = "paid" in caminho
        valor = pedido["total_amount"]
        metodo = fonte.escolha(metodos)
        parcelas = 1 if metodo["method_type"] in _A_VISTA else fonte.ponderada(parcelas_pesos)

        # Tentativa recusada antes da que deu certo: é a origem das 1,05
        # intenções de pagamento por pedido da proporção de referência.
        if pago and fonte.chance(processo["nova_tentativa_apos_falha"]):
            recusada = _pagamento(pedido, metodo, valor, parcelas, "failed", None, None)
            pagamentos.append(recusada)
            transacoes.append(
                _transacao(recusada, "authorization", "failed", valor, momentos["pending"], fonte)
            )

        estado, autorizado_em, capturado_em = _desfecho(pedido, caminho, momentos, fonte)
        pagamento = _pagamento(pedido, metodo, valor, parcelas, estado, autorizado_em, capturado_em)
        pagamentos.append(pagamento)

        if estado == "failed":
            transacoes.append(
                _transacao(pagamento, "authorization", "failed", valor, momentos["pending"], fonte)
            )
            continue
        if estado == "pending":
            transacoes.append(
                _transacao(pagamento, "authorization", "pending", valor, momentos["pending"], fonte)
            )
            continue

        autorizado = valor
        transacoes.append(
            _transacao(pagamento, "authorization", "succeeded", autorizado, autorizado_em, fonte)
        )
        if estado == "cancelled":
            # Autorização sem captura é desfeita, não capturada: é o que o tipo
            # `void` existe para registrar.
            transacoes.append(
                _transacao(pagamento, "void", "succeeded", autorizado, momentos["cancelled"], fonte)
            )
            continue
        if estado == "authorized":
            continue

        # Invariante 3: a captura nunca excede o autorizado.
        capturado = (
            dinheiro(autorizado * Decimal(str(fonte.rng.uniform(0.85, 0.99))))
            if fonte.chance(0.03)
            else autorizado
        )
        captura = _transacao(pagamento, "capture", "succeeded", capturado, capturado_em, fonte)
        transacoes.append(captura)

        if estado == "refunded":
            _reembolsar(motor, fonte, pedido, captura, capturado, transacoes, reembolsos)

    dados.guardar("payments", motor.preencher("payments", pagamentos))
    for transacao in transacoes:
        transacao["payment_id"] = transacao.pop("__pagamento")["id"]
    dados.guardar("payment_transactions", motor.preencher("payment_transactions", transacoes))
    for reembolso in reembolsos:
        reembolso["payment_transaction_id"] = reembolso.pop("__transacao")["id"]
    dados.guardar("refunds", motor.preencher("refunds", reembolsos))


def _desfecho(pedido: dict, caminho: tuple[str, ...], momentos: dict, fonte):
    """Estado do pagamento e as duas datas que a `CHECK` do modelo relaciona."""
    final = pedido["status"]
    if final == "returned":
        return "refunded", momentos["pending"], momentos["paid"]
    if "paid" in caminho and final != "cancelled":
        return "captured", momentos["pending"], momentos["paid"]
    if final == "cancelled":
        if "paid" in caminho:
            return "cancelled", momentos["pending"], None
        return ("cancelled" if fonte.chance(0.5) else "failed"), momentos["pending"], None
    return ("pending" if fonte.chance(0.5) else "authorized"), momentos["pending"], None


def _pagamento(pedido, metodo, valor, parcelas, estado, autorizado_em, capturado_em) -> dict:
    return {
        "order_id": pedido["id"],
        "payment_method_id": metodo["id"],
        "status": estado,
        "amount": valor,
        "installments": parcelas,
        # `CHECK captura_exige_autorizacao`: capturar sem autorizar é impossível.
        "authorized_at": autorizado_em if estado != "failed" else None,
        "captured_at": capturado_em,
        "created_at": pedido["placed_at"],
        "deleted_at": None,
    }


def _transacao(pagamento, tipo, resultado, valor, momento, fonte) -> dict:
    return {
        "__pagamento": pagamento,
        "transaction_type": tipo,
        "result": resultado,
        "amount": valor,
        "occurred_at": momento,
        "created_at": momento,
    }


def _reembolsar(motor, fonte, pedido, captura, capturado, transacoes, reembolsos) -> None:
    """Reembolso total ou em duas parcelas — invariante 4 respeitada nas duas."""
    processo = motor.config.tabelas["refunds"].processo
    momento = pedido["__momentos"].get("returned", pedido["__fim_do_caminho"])
    if fonte.chance(processo["reembolso_parcial"]):
        primeira = dinheiro(capturado * Decimal(str(fonte.rng.uniform(0.3, 0.6))))
        valores = [primeira, dinheiro(capturado - primeira)]
    else:
        valores = [capturado]

    for parcela in valores:
        if parcela <= 0:
            continue
        transacoes.append(
            _transacao(captura["__pagamento"], "refund", "succeeded", parcela, momento, fonte)
        )
        reembolsos.append(
            {
                "__transacao": captura,
                "amount": parcela,
                "refunded_at": momento,
                "created_at": momento,
                "deleted_at": None,
            }
        )
