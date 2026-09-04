"""Domínio de atendimento — 3 tabelas.

Agentes carregam dados `personal` como qualquer pessoa: o fato de serem
funcionários simulados não muda a classificação (Governança §4).
"""

from __future__ import annotations

import datetime as dt

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from mvp_ed1.models.base import (
    INTERNAL,
    PERSONAL,
    PUBLIC,
    AppendOnlyMixin,
    Base,
    SoftDeleteMixin,
    Timestamp,
    TimestampMixin,
    meta,
    pk,
    table_meta,
)

DOMAIN = "atendimento"

TICKET_CATEGORIES = ("delivery", "payment", "product", "return", "account", "other")
TICKET_PRIORITIES = ("low", "normal", "high", "urgent")
TICKET_STATUSES = ("open", "in_progress", "waiting_customer", "resolved", "closed")
TICKET_EVENT_TYPES = ("created", "assigned", "message", "status_changed", "resolved", "reopened")


class SupportAgent(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "support_agents"
    __table_args__ = table_meta(DOMAIN, "Agentes sintéticos e suas equipes de atendimento.")

    id: Mapped[int] = pk()
    agent_code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural do agente."),
    )
    first_name: Mapped[str] = mapped_column(
        String(80), nullable=False, info=meta(PERSONAL, "Primeiro nome do agente (sintético)."),
    )
    last_name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PERSONAL, "Sobrenome do agente (sintético)."),
    )
    email: Mapped[str] = mapped_column(
        String(160), nullable=False, unique=True,
        info=meta(PERSONAL, "E-mail corporativo do agente (sintético)."),
    )
    team: Mapped[str] = mapped_column(
        String(60), nullable=False, info=meta(PUBLIC, "Equipe de atendimento à qual o agente pertence."),
    )
    hired_at: Mapped[dt.date] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Início do período de atuação do agente."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), info=meta(INTERNAL, "Indica se o agente continua atuando."),
    )


class SupportTicket(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "support_tickets"
    __table_args__ = (
        CheckConstraint(f"category in {TICKET_CATEGORIES}", name="categoria_valida"),
        CheckConstraint(f"priority in {TICKET_PRIORITIES}", name="prioridade_valida"),
        CheckConstraint(f"status in {TICKET_STATUSES}", name="status_valido"),
        CheckConstraint("closed_at is null or closed_at >= opened_at", name="causalidade_temporal"),
        Index("ix_support_tickets_customer_id", "customer_id"),
        Index("ix_support_tickets_status_opened_at", "status", "opened_at"),
        table_meta(DOMAIN, "Solicitações associadas a clientes, pedidos ou entregas."),
    )

    id: Mapped[int] = pk()
    ticket_number: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(INTERNAL, "Número do chamado; chave natural."),
    )
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Cliente que abriu o chamado."),
    )
    order_id: Mapped[int | None] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Pedido relacionado ao chamado, quando houver."),
    )
    shipment_id: Mapped[int | None] = mapped_column(
        ForeignKey("shipments.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Remessa relacionada ao chamado, quando houver."),
    )
    assigned_agent_id: Mapped[int | None] = mapped_column(
        ForeignKey("support_agents.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Agente responsável pelo chamado no momento."),
    )
    category: Mapped[str] = mapped_column(
        String(20), nullable=False, info=meta(PUBLIC, "Motivo do chamado."),
    )
    priority: Mapped[str] = mapped_column(
        String(10), nullable=False, server_default="normal", info=meta(INTERNAL, "Prioridade atribuída ao chamado."),
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, server_default="open", info=meta(INTERNAL, "Estado atual do chamado."),
    )
    subject: Mapped[str] = mapped_column(
        String(200), nullable=False, info=meta(PERSONAL, "Assunto escrito pelo cliente (sintético)."),
    )
    opened_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de abertura do chamado."),
    )
    closed_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento de encerramento do chamado."),
    )


class TicketEvent(Base, AppendOnlyMixin):
    __tablename__ = "ticket_events"
    __table_args__ = (
        CheckConstraint(f"event_type in {TICKET_EVENT_TYPES}", name="tipo_valido"),
        Index("ix_ticket_events_ticket_id_occurred_at", "ticket_id", "occurred_at"),
        table_meta(DOMAIN, "Interações, atribuições e mudanças de estado do chamado."),
    )

    id: Mapped[int] = pk()
    ticket_id: Mapped[int] = mapped_column(
        ForeignKey("support_tickets.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Chamado ao qual o evento pertence."),
    )
    agent_id: Mapped[int | None] = mapped_column(
        ForeignKey("support_agents.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Agente autor do evento; nulo quando o autor é o cliente."),
    )
    event_type: Mapped[str] = mapped_column(
        String(20), nullable=False, info=meta(INTERNAL, "Natureza do evento no chamado."),
    )
    occurred_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento de negócio do evento."),
    )
    message: Mapped[str | None] = mapped_column(
        Text, nullable=True, info=meta(PERSONAL, "Conteúdo da interação (sintético)."),
    )
