"""Domínio de vendas — 6 tabelas.

`cart_items` é a maior tabela do projeto e a razão pela qual o ADR-0009
declarou que a carga em massa não passa pelo *unit of work*: ela é escrita por
`COPY`, não objeto a objeto.

A invariante 2 do Modelo de Dados — o total do pedido reconcilia itens,
descontos, frete e impostos — é expressável **dentro da linha** e por isso vira
`CHECK`, não teste. Invariante que o banco consegue garantir não deveria
depender de teste rodando depois.
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
    UnitPrice,
    meta,
    pk,
    table_meta,
)

DOMAIN = "vendas"

CHANNEL_TYPES = ("web", "app", "store")
CART_STATUSES = ("open", "converted", "abandoned", "expired")
ORDER_STATUSES = (
    "pending", "paid", "picking", "shipped", "delivered", "cancelled", "returned",
)


class SalesChannel(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "sales_channels"
    __table_args__ = (
        CheckConstraint(f"channel_type in {CHANNEL_TYPES}", name="tipo_valido"),
        table_meta(DOMAIN, "Canais de venda como web, aplicativo e loja física."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável do canal."),
    )
    name: Mapped[str] = mapped_column(
        String(80), nullable=False, info=meta(PUBLIC, "Nome do canal de venda."),
    )
    channel_type: Mapped[str] = mapped_column(
        String(16), nullable=False, info=meta(PUBLIC, "Natureza do canal: web, app ou store."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se o canal continua operando."),
    )


class Cart(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "carts"
    __table_args__ = (
        CheckConstraint(f"status in {CART_STATUSES}", name="status_valido"),
        CheckConstraint(
            "(status = 'converted') = (converted_at is not null)", name="conversao_coerente",
        ),
        Index("ix_carts_status_updated_at", "status", "updated_at"),
        table_meta(DOMAIN, "Carrinhos abertos, convertidos, abandonados ou expirados."),
    )

    id: Mapped[int] = pk()
    cart_code: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural do carrinho."),
    )
    customer_id: Mapped[int | None] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Cliente dono do carrinho; nulo em sessão anônima."),
    )
    sales_channel_id: Mapped[int] = mapped_column(
        ForeignKey("sales_channels.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Canal em que o carrinho foi aberto."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="open",
        info=meta(INTERNAL, "Estado do carrinho: open, converted, abandoned ou expired."),
    )
    expires_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento previsto de expiração."),
    )
    converted_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento da conversão em pedido."),
    )


class CartItem(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "cart_items"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="quantidade_positiva"),
        CheckConstraint("unit_price >= 0", name="preco_nao_negativo"),
        Index("ix_cart_items_cart_id", "cart_id"),
        table_meta(DOMAIN, "Produtos e quantidades incluídos nos carrinhos; maior tabela do projeto."),
    )

    id: Mapped[int] = pk()
    cart_id: Mapped[int] = mapped_column(
        ForeignKey("carts.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Carrinho ao qual o item pertence."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "SKU adicionado ao carrinho."),
    )
    quantity: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Quantidade do SKU no carrinho."),
    )
    unit_price: Mapped[Decimal] = mapped_column(
        UnitPrice, nullable=False,
        info=meta(CONFIDENTIAL, "Preço unitário vigente no momento em que o item foi adicionado."),
    )
    added_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento em que o item entrou no carrinho."),
    )


class Order(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "orders"
    __table_args__ = (
        CheckConstraint(f"status in {ORDER_STATUSES}", name="status_valido"),
        CheckConstraint(
            "subtotal_amount >= 0 and discount_amount >= 0 "
            "and shipping_amount >= 0 and tax_amount >= 0 and total_amount >= 0",
            name="valores_nao_negativos",
        ),
        # Invariante 2 do Modelo de Dados, garantida pelo banco. Os cinco campos
        # são `numeric(14,2)`, então a aritmética é exata e a igualdade é segura.
        CheckConstraint(
            "total_amount = subtotal_amount - discount_amount + shipping_amount + tax_amount",
            name="total_reconcilia",
        ),
        CheckConstraint("discount_amount <= subtotal_amount", name="desconto_limitado"),
        Index("ix_orders_placed_at", "placed_at"),
        table_meta(DOMAIN, "Cabeçalho do pedido: cliente, canal, valores e estado atual."),
    )

    id: Mapped[int] = pk()
    order_number: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(INTERNAL, "Número do pedido; chave natural."),
    )
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Cliente que fez o pedido."),
    )
    sales_channel_id: Mapped[int] = mapped_column(
        ForeignKey("sales_channels.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Canal em que o pedido foi feito."),
    )
    cart_id: Mapped[int | None] = mapped_column(
        ForeignKey("carts.id", ondelete="RESTRICT"), nullable=True, unique=True,
        info=meta(INTERNAL, "Carrinho que originou o pedido; nulo em venda direta."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="pending",
        info=meta(INTERNAL, "Estado atual do pedido; o histórico vive em `order_status_history`."),
    )
    placed_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de negócio em que o pedido foi feito."),
    )
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, server_default="BRL", info=meta(PUBLIC, "Moeda do pedido, em código ISO 4217."),
    )
    subtotal_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Soma dos itens antes de desconto, frete e imposto."),
    )
    discount_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"), info=meta(CONFIDENTIAL, "Desconto total aplicado ao pedido."),
    )
    shipping_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"), info=meta(CONFIDENTIAL, "Valor de frete cobrado."),
    )
    tax_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"), info=meta(CONFIDENTIAL, "Imposto simulado sobre o pedido."),
    )
    total_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Valor total do pedido; reconcilia os demais campos."),
    )


class OrderItem(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "order_items"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="quantidade_positiva"),
        CheckConstraint("unit_price >= 0 and discount_amount >= 0 and tax_amount >= 0",
                        name="valores_nao_negativos"),
        # Tolerância de um centavo: `unit_price` tem quatro casas e o total tem
        # duas, então o arredondamento é legítimo e a igualdade exata seria
        # falsa por construção.
        CheckConstraint(
            "abs(total_amount - (quantity * unit_price - discount_amount + tax_amount)) <= 0.01",
            name="total_reconcilia",
        ),
        Index("uq_order_items_pedido_variante", "order_id", "product_variant_id", unique=True),
        table_meta(DOMAIN, "Grão comercial do pedido: um SKU comprado em uma linha."),
    )

    id: Mapped[int] = pk()
    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Pedido ao qual o item pertence."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "SKU comprado."),
    )
    quantity: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Quantidade comprada do SKU."),
    )
    unit_price: Mapped[Decimal] = mapped_column(
        UnitPrice, nullable=False, info=meta(CONFIDENTIAL, "Preço unitário praticado na venda."),
    )
    discount_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"), info=meta(CONFIDENTIAL, "Desconto aplicado a este item."),
    )
    tax_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"), info=meta(CONFIDENTIAL, "Imposto simulado sobre este item."),
    )
    total_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, info=meta(CONFIDENTIAL, "Valor total da linha, já arredondado."),
    )


class OrderStatusHistory(Base, AppendOnlyMixin):
    __tablename__ = "order_status_history"
    __table_args__ = (
        CheckConstraint(f"to_status in {ORDER_STATUSES}", name="status_destino_valido"),
        CheckConstraint(
            f"from_status is null or from_status in {ORDER_STATUSES}", name="status_origem_valido",
        ),
        CheckConstraint("from_status is distinct from to_status", name="transicao_efetiva"),
        Index("ix_order_status_history_order_id_changed_at", "order_id", "changed_at"),
        table_meta(DOMAIN, "Histórico temporal das mudanças de estado do pedido."),
    )

    id: Mapped[int] = pk()
    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Pedido cujo estado mudou."),
    )
    from_status: Mapped[str | None] = mapped_column(
        String(16), nullable=True, info=meta(INTERNAL, "Estado anterior; nulo na criação do pedido."),
    )
    to_status: Mapped[str] = mapped_column(
        String(16), nullable=False, info=meta(INTERNAL, "Estado resultante da transição."),
    )
    changed_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de negócio da transição."),
    )
    reason: Mapped[str | None] = mapped_column(
        Text, nullable=True, info=meta(INTERNAL, "Motivo registrado para a transição."),
    )
