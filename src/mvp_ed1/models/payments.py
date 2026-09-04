"""Domínio de pagamentos — 4 tabelas.

Nenhuma credencial de pagamento é armazenada, nem sintética: o projeto guarda
o **tipo** de meio de pagamento e o resultado da operação, nunca número de
cartão. As invariantes 3 e 4 — captura não excede autorização, reembolso não
excede captura — atravessam linhas e por isso são teste, não `CHECK`.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Integer, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from mvp_ed1.models.base import (
    CONFIDENTIAL,
    INTERNAL,
    PUBLIC,
    AppendOnlyMixin,
    Base,
    Money,
    SoftDeleteMixin,
    Timestamp,
    TimestampMixin,
    meta,
    pk,
    table_meta,
)

DOMAIN = "pagamentos"

PAYMENT_METHOD_TYPES = ("credit_card", "debit_card", "pix", "boleto", "wallet", "voucher")
PAYMENT_STATUSES = ("pending", "authorized", "captured", "failed", "refunded", "cancelled")
TRANSACTION_TYPES = ("authorization", "capture", "void", "refund")
TRANSACTION_RESULTS = ("succeeded", "failed", "pending")
REFUND_STATUSES = ("requested", "completed", "rejected")


class PaymentMethod(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "payment_methods"
    __table_args__ = (
        CheckConstraint(f"method_type in {PAYMENT_METHOD_TYPES}", name="tipo_valido"),
        table_meta(DOMAIN, "Tipos de pagamento aceitos, sem armazenar credenciais."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável do meio de pagamento."),
    )
    name: Mapped[str] = mapped_column(
        String(80), nullable=False, info=meta(PUBLIC, "Nome do meio de pagamento."),
    )
    method_type: Mapped[str] = mapped_column(
        String(20), nullable=False, info=meta(PUBLIC, "Natureza do meio: cartão, pix, boleto, carteira ou vale."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), info=meta(INTERNAL, "Indica se o meio continua aceito."),
    )


class Payment(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "payments"
    __table_args__ = (
        CheckConstraint(f"status in {PAYMENT_STATUSES}", name="status_valido"),
        CheckConstraint("amount > 0", name="valor_positivo"),
        CheckConstraint("installments >= 1", name="parcelas_validas"),
        CheckConstraint(
            "captured_at is null or authorized_at is not null", name="captura_exige_autorizacao",
        ),
        CheckConstraint(
            "captured_at is null or authorized_at is null or captured_at >= authorized_at",
            name="causalidade_temporal",
        ),
        Index("ix_payments_order_id", "order_id"),
        table_meta(DOMAIN, "Intenção de pagamento associada ao pedido."),
    )

    id: Mapped[int] = pk()
    payment_code: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural do pagamento."),
    )
    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Pedido que o pagamento quita."),
    )
    payment_method_id: Mapped[int] = mapped_column(
        ForeignKey("payment_methods.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Meio de pagamento utilizado."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="pending",
        info=meta(INTERNAL, "Estado do pagamento; transições válidas em Modelo de Dados §4."),
    )
    amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Valor pretendido do pagamento."),
    )
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, server_default="BRL", info=meta(PUBLIC, "Moeda, em código ISO 4217."),
    )
    installments: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("1"),
        info=meta(PUBLIC, "Número de parcelas acordadas."),
    )
    authorized_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento da autorização pelo emissor simulado."),
    )
    captured_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento da captura efetiva do valor."),
    )


class PaymentTransaction(Base, AppendOnlyMixin):
    __tablename__ = "payment_transactions"
    __table_args__ = (
        CheckConstraint(f"transaction_type in {TRANSACTION_TYPES}", name="tipo_valido"),
        CheckConstraint(f"result in {TRANSACTION_RESULTS}", name="resultado_valido"),
        CheckConstraint("amount > 0", name="valor_positivo"),
        Index("ix_payment_transactions_payment_id_occurred_at", "payment_id", "occurred_at"),
        table_meta(DOMAIN, "Tentativas, autorizações, capturas e falhas do pagamento."),
    )

    id: Mapped[int] = pk()
    transaction_code: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural da transação."),
    )
    payment_id: Mapped[int] = mapped_column(
        ForeignKey("payments.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Pagamento ao qual a transação pertence."),
    )
    transaction_type: Mapped[str] = mapped_column(
        String(20), nullable=False,
        info=meta(INTERNAL, "Operação financeira: authorization, capture, void ou refund."),
    )
    result: Mapped[str] = mapped_column(
        String(16), nullable=False, info=meta(INTERNAL, "Desfecho da operação: succeeded, failed ou pending."),
    )
    amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Valor movimentado nesta operação."),
    )
    gateway_response_code: Mapped[str | None] = mapped_column(
        String(32), nullable=True, info=meta(INTERNAL, "Código de retorno do adquirente simulado."),
    )
    occurred_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de negócio da operação."),
    )


class Refund(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "refunds"
    __table_args__ = (
        CheckConstraint(f"status in {REFUND_STATUSES}", name="status_valido"),
        CheckConstraint("amount > 0", name="valor_positivo"),
        Index("ix_refunds_payment_transaction_id", "payment_transaction_id"),
        table_meta(DOMAIN, "Reembolsos totais ou parciais de transações capturadas."),
    )

    id: Mapped[int] = pk()
    refund_code: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural do reembolso."),
    )
    payment_transaction_id: Mapped[int] = mapped_column(
        ForeignKey("payment_transactions.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Transação de captura que está sendo revertida."),
    )
    amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Valor reembolsado."),
    )
    reason: Mapped[str | None] = mapped_column(
        Text, nullable=True, info=meta(INTERNAL, "Motivo comercial do reembolso."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="requested",
        info=meta(INTERNAL, "Estado do reembolso: requested, completed ou rejected."),
    )
    refunded_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento em que o reembolso foi concluído."),
    )
