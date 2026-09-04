"""Domínio de marketing — 3 tabelas.

A invariante 12 — cupom usado dentro da vigência e segundo suas regras de
elegibilidade — depende da vigência do cupom e do valor do pedido, em outra
tabela. Fica como teste de qualidade; o que cabe em `CHECK` é a coerência
interna da regra de desconto.
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

DOMAIN = "marketing"

CAMPAIGN_OBJECTIVES = ("acquisition", "retention", "reactivation", "clearance")
DISCOUNT_TYPES = ("percentage", "fixed")


class Campaign(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "campaigns"
    __table_args__ = (
        CheckConstraint(f"objective in {CAMPAIGN_OBJECTIVES}", name="objetivo_valido"),
        CheckConstraint("valid_to > valid_from", name="vigencia_coerente"),
        CheckConstraint("budget_amount is null or budget_amount >= 0", name="orcamento_nao_negativo"),
        table_meta(DOMAIN, "Campanhas de marketing e seus períodos de vigência."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável da campanha."),
    )
    name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PUBLIC, "Nome da campanha."),
    )
    objective: Mapped[str] = mapped_column(
        String(20), nullable=False, info=meta(PUBLIC, "Objetivo comercial da campanha."),
    )
    valid_from: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(PUBLIC, "Início da vigência da campanha."),
    )
    valid_to: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(PUBLIC, "Fim da vigência da campanha."),
    )
    budget_amount: Mapped[Decimal | None] = mapped_column(
        Money, nullable=True, info=meta(CONFIDENTIAL, "Orçamento previsto da campanha."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), info=meta(INTERNAL, "Indica se a campanha está ativa."),
    )


class Coupon(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "coupons"
    __table_args__ = (
        CheckConstraint(f"discount_type in {DISCOUNT_TYPES}", name="tipo_de_desconto_valido"),
        CheckConstraint("discount_value > 0", name="desconto_positivo"),
        # Percentual acima de 100 significaria devolver dinheiro ao cliente por
        # comprar: erro de cadastro que o banco consegue impedir.
        CheckConstraint(
            "discount_type <> 'percentage' or discount_value <= 100", name="percentual_limitado",
        ),
        CheckConstraint("valid_to > valid_from", name="vigencia_coerente"),
        CheckConstraint("max_redemptions is null or max_redemptions > 0", name="limite_positivo"),
        table_meta(DOMAIN, "Cupons, regras de desconto e limites de utilização."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código digitado pelo cliente."),
    )
    campaign_id: Mapped[int] = mapped_column(
        ForeignKey("campaigns.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Campanha à qual o cupom pertence."),
    )
    discount_type: Mapped[str] = mapped_column(
        String(16), nullable=False, info=meta(PUBLIC, "Natureza do desconto: percentage ou fixed."),
    )
    discount_value: Mapped[Decimal] = mapped_column(
        Money, nullable=False,
        info=meta(CONFIDENTIAL, "Valor do desconto: percentual quando `percentage`, moeda quando `fixed`."),
    )
    min_order_amount: Mapped[Decimal | None] = mapped_column(
        Money, nullable=True, info=meta(PUBLIC, "Valor mínimo de pedido para o cupom ser elegível."),
    )
    max_redemptions: Mapped[int | None] = mapped_column(
        Integer, nullable=True, info=meta(INTERNAL, "Limite total de utilizações; nulo quando ilimitado."),
    )
    valid_from: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(PUBLIC, "Início da vigência do cupom."),
    )
    valid_to: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(PUBLIC, "Fim da vigência do cupom."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), info=meta(INTERNAL, "Indica se o cupom continua aceito."),
    )


class CouponRedemption(Base, AppendOnlyMixin):
    __tablename__ = "coupon_redemptions"
    __table_args__ = (
        CheckConstraint("discount_amount >= 0", name="desconto_nao_negativo"),
        # Um cupom por pedido: dois cupons no mesmo pedido tornariam o
        # rateio do desconto ambíguo na fato de vendas.
        Index("uq_coupon_redemptions_pedido", "order_id", unique=True),
        Index("ix_coupon_redemptions_coupon_id", "coupon_id"),
        table_meta(DOMAIN, "Uso efetivo de cupons por cliente e pedido."),
    )

    id: Mapped[int] = pk()
    coupon_id: Mapped[int] = mapped_column(
        ForeignKey("coupons.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Cupom utilizado."),
    )
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Cliente que utilizou o cupom."),
    )
    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Pedido em que o cupom foi aplicado."),
    )
    discount_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Desconto efetivamente concedido."),
    )
    redeemed_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de negócio da utilização."),
    )
