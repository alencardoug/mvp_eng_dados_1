"""Domínio de logística — 4 tabelas.

`delivery_events` é a segunda maior tabela do projeto e é *append-only*: um
evento de entrega registrado não é corrigido, é sucedido por outro.

A invariante 5 — remessa não contém quantidade superior à vendida e ainda não
enviada — atravessa `shipment_items`, `order_items` e as remessas anteriores do
mesmo pedido. Não cabe em `CHECK`: é teste de qualidade.
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

DOMAIN = "logistica"

SERVICE_LEVELS = ("standard", "express", "same_day")
SHIPMENT_STATUSES = ("created", "picking", "dispatched", "in_transit", "delivered", "returned", "lost")
DELIVERY_EVENT_TYPES = (
    "picked_up", "in_transit", "out_for_delivery", "delivery_attempt", "delivered", "returned",
)


class Carrier(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "carriers"
    __table_args__ = (
        CheckConstraint(f"service_level in {SERVICE_LEVELS}", name="modalidade_valida"),
        table_meta(DOMAIN, "Transportadoras sintéticas e suas modalidades."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável da transportadora."),
    )
    name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PUBLIC, "Nome da transportadora."),
    )
    service_level: Mapped[str] = mapped_column(
        String(16), nullable=False, info=meta(PUBLIC, "Modalidade: standard, express ou same_day."),
    )
    tracking_url_template: Mapped[str | None] = mapped_column(
        String(255), nullable=True, info=meta(PUBLIC, "Modelo de URL de rastreio, com marcador do código."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), info=meta(INTERNAL, "Indica se a transportadora está em uso."),
    )


class Shipment(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "shipments"
    __table_args__ = (
        CheckConstraint(f"status in {SHIPMENT_STATUSES}", name="status_valido"),
        CheckConstraint("freight_amount >= 0", name="frete_nao_negativo"),
        CheckConstraint(
            "delivered_at is null or shipped_at is null or delivered_at >= shipped_at",
            name="causalidade_temporal",
        ),
        Index("ix_shipments_order_id", "order_id"),
        table_meta(DOMAIN, "Remessas criadas para atender pedidos."),
    )

    id: Mapped[int] = pk()
    shipment_code: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural da remessa."),
    )
    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Pedido que a remessa atende."),
    )
    carrier_id: Mapped[int] = mapped_column(
        ForeignKey("carriers.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Transportadora responsável."),
    )
    warehouse_id: Mapped[int] = mapped_column(
        ForeignKey("warehouses.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Armazém de origem da remessa."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="created",
        info=meta(INTERNAL, "Estado da remessa; transições válidas em Modelo de Dados §4."),
    )
    tracking_code: Mapped[str | None] = mapped_column(
        String(64), nullable=True, info=meta(INTERNAL, "Código de rastreio junto à transportadora."),
    )
    freight_amount: Mapped[Decimal] = mapped_column(
        Money, nullable=False, server_default=text("0"), info=meta(CONFIDENTIAL, "Custo de frete da remessa."),
    )
    shipped_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento do despacho."),
    )
    estimated_delivery_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(PUBLIC, "Prazo de entrega prometido ao cliente."),
    )
    delivered_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento da entrega efetiva."),
    )


class ShipmentItem(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "shipment_items"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="quantidade_positiva"),
        Index("uq_shipment_items_remessa_item", "shipment_id", "order_item_id", unique=True),
        table_meta(DOMAIN, "Quantidades de itens de pedido incluídas em cada remessa."),
    )

    id: Mapped[int] = pk()
    shipment_id: Mapped[int] = mapped_column(
        ForeignKey("shipments.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Remessa à qual o item pertence."),
    )
    order_item_id: Mapped[int] = mapped_column(
        ForeignKey("order_items.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Item de pedido sendo enviado."),
    )
    quantity: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Quantidade enviada nesta remessa."),
    )


class DeliveryEvent(Base, AppendOnlyMixin):
    __tablename__ = "delivery_events"
    __table_args__ = (
        CheckConstraint(f"event_type in {DELIVERY_EVENT_TYPES}", name="tipo_valido"),
        Index("ix_delivery_events_shipment_id_occurred_at", "shipment_id", "occurred_at"),
        table_meta(DOMAIN, "Eventos de coleta, trânsito, tentativa e entrega."),
    )

    id: Mapped[int] = pk()
    shipment_id: Mapped[int] = mapped_column(
        ForeignKey("shipments.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Remessa à qual o evento se refere."),
    )
    event_type: Mapped[str] = mapped_column(
        String(24), nullable=False, info=meta(PUBLIC, "Natureza do evento de entrega."),
    )
    occurred_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de negócio do evento."),
    )
    location: Mapped[str | None] = mapped_column(
        String(120), nullable=True, info=meta(PUBLIC, "Localidade registrada pela transportadora."),
    )
    description: Mapped[str | None] = mapped_column(
        Text, nullable=True, info=meta(PUBLIC, "Descrição textual do evento."),
    )
