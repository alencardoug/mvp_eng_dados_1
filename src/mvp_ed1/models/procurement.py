"""Domínio de fornecedores e compras — 5 tabelas.

Custos de aquisição são `confidential`: revelam margem quando cruzados com o
preço de venda, e por isso não chegam ao perfil de análise sem mediação.

A invariante 6 do Modelo de Dados — recebimento não supera o solicitado —
atravessa duas tabelas e por isso **não** é `CHECK`: é teste de qualidade,
declarado em Qualidade de Dados.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Integer, String, text
from sqlalchemy.orm import Mapped, mapped_column

from mvp_ed1.models.base import (
    CONFIDENTIAL,
    INTERNAL,
    PERSONAL,
    PUBLIC,
    Base,
    Money,
    SoftDeleteMixin,
    Timestamp,
    TimestampMixin,
    UnitPrice,
    meta,
    pk,
    table_meta,
)

DOMAIN = "compras"

PURCHASE_ORDER_STATUSES = ("draft", "placed", "partially_received", "received", "cancelled")
GOODS_RECEIPT_STATUSES = ("pending", "completed", "rejected")


class Supplier(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "suppliers"
    __table_args__ = (
        CheckConstraint("payment_terms_days >= 0", name="prazo_nao_negativo"),
        table_meta(DOMAIN, "Cadastro sintético dos fornecedores."),
    )

    id: Mapped[int] = pk()
    supplier_code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(INTERNAL, "Chave natural do fornecedor na origem."),
    )
    legal_name: Mapped[str] = mapped_column(
        String(200), nullable=False, info=meta(CONFIDENTIAL, "Razão social do fornecedor (sintética)."),
    )
    trade_name: Mapped[str | None] = mapped_column(
        String(200), nullable=True, info=meta(PUBLIC, "Nome fantasia do fornecedor."),
    )
    document: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(CONFIDENTIAL, "Documento de identificação do fornecedor (sintético)."),
    )
    contact_email: Mapped[str | None] = mapped_column(
        String(160), nullable=True, info=meta(PERSONAL, "E-mail de contato comercial (sintético)."),
    )
    country: Mapped[str] = mapped_column(
        String(2), nullable=False, server_default="BR", info=meta(PUBLIC, "País do fornecedor, em código ISO."),
    )
    payment_terms_days: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("30"),
        info=meta(CONFIDENTIAL, "Prazo de pagamento negociado, em dias."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se o fornecedor continua ativo."),
    )


class PurchaseOrder(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "purchase_orders"
    __table_args__ = (
        CheckConstraint(f"status in {PURCHASE_ORDER_STATUSES}", name="status_valido"),
        CheckConstraint("total_amount >= 0", name="total_nao_negativo"),
        CheckConstraint("expected_at is null or expected_at >= ordered_at", name="prazo_coerente"),
        table_meta(DOMAIN, "Cabeçalho das ordens de compra enviadas a fornecedores."),
    )

    id: Mapped[int] = pk()
    po_number: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(INTERNAL, "Número da ordem de compra; chave natural."),
    )
    supplier_id: Mapped[int] = mapped_column(
        ForeignKey("suppliers.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Fornecedor da ordem."),
    )
    status: Mapped[str] = mapped_column(
        String(24), nullable=False, server_default="draft",
        info=meta(INTERNAL, "Estado da ordem; transições válidas em Modelo de Dados §4."),
    )
    ordered_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de emissão da ordem."),
    )
    expected_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Data prometida de entrega pelo fornecedor."),
    )
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, server_default="BRL", info=meta(PUBLIC, "Moeda da ordem, em código ISO 4217."),
    )
    total_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"),
        info=meta(CONFIDENTIAL, "Valor total da ordem, somando os itens."),
    )


class PurchaseOrderItem(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "purchase_order_items"
    __table_args__ = (
        CheckConstraint("quantity_ordered > 0", name="quantidade_positiva"),
        CheckConstraint("unit_cost >= 0", name="custo_nao_negativo"),
        Index(
            "uq_purchase_order_items_ordem_variante",
            "purchase_order_id", "product_variant_id", unique=True,
        ),
        table_meta(DOMAIN, "Produtos, quantidades e custos solicitados ao fornecedor."),
    )

    id: Mapped[int] = pk()
    purchase_order_id: Mapped[int] = mapped_column(
        ForeignKey("purchase_orders.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Ordem de compra à qual o item pertence."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "SKU solicitado."),
    )
    quantity_ordered: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Quantidade solicitada ao fornecedor."),
    )
    unit_cost: Mapped[Decimal] = mapped_column(
        UnitPrice, nullable=False, info=meta(CONFIDENTIAL, "Custo unitário negociado."),
    )
    total_cost: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Custo total do item, já arredondado."),
    )


class GoodsReceipt(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "goods_receipts"
    __table_args__ = (
        CheckConstraint(f"status in {GOODS_RECEIPT_STATUSES}", name="status_valido"),
        table_meta(DOMAIN, "Registro do recebimento físico de uma ordem de compra."),
    )

    id: Mapped[int] = pk()
    receipt_number: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(INTERNAL, "Número do recebimento; chave natural."),
    )
    purchase_order_id: Mapped[int] = mapped_column(
        ForeignKey("purchase_orders.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Ordem de compra recebida."),
    )
    warehouse_id: Mapped[int] = mapped_column(
        ForeignKey("warehouses.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Armazém que recebeu a mercadoria."),
    )
    received_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento do recebimento físico."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="pending",
        info=meta(INTERNAL, "Estado do recebimento: pending, completed ou rejected."),
    )


class GoodsReceiptItem(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "goods_receipt_items"
    __table_args__ = (
        CheckConstraint("quantity_received >= 0", name="quantidade_nao_negativa"),
        CheckConstraint("unit_cost >= 0", name="custo_nao_negativo"),
        Index(
            "uq_goods_receipt_items_recebimento_item",
            "goods_receipt_id", "purchase_order_item_id", unique=True,
        ),
        table_meta(DOMAIN, "Quantidades efetivamente recebidas por item da ordem de compra."),
    )

    id: Mapped[int] = pk()
    goods_receipt_id: Mapped[int] = mapped_column(
        ForeignKey("goods_receipts.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Recebimento ao qual o item pertence."),
    )
    purchase_order_item_id: Mapped[int] = mapped_column(
        ForeignKey("purchase_order_items.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Item da ordem de compra correspondente."),
    )
    quantity_received: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Quantidade efetivamente recebida."),
    )
    unit_cost: Mapped[Decimal] = mapped_column(
        UnitPrice, nullable=False, info=meta(CONFIDENTIAL, "Custo unitário no recebimento."),
    )
