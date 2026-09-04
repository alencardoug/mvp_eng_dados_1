"""Domínio de estoque — 4 tabelas.

`inventory_movements` é a única tabela do projeto tratada como **livro de
eventos**: aceita somente inserções, e correções são eventos compensatórios.
É esse contrato que torna possível o fluxo de streaming (ADR-0006), e ele está
implementado aqui exatamente como o Modelo de Dados §5 o especifica.

O atributo Python do campo `metadata` é `event_metadata`: `metadata` é nome
reservado pelo SQLAlchemy declarativo. A coluna no banco continua `metadata`.
"""

from __future__ import annotations

import datetime as dt
import uuid
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Computed,
    ForeignKey,
    Identity,
    Index,
    Integer,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    Uuid,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from mvp_ed1.models.base import (
    CONFIDENTIAL,
    INTERNAL,
    PUBLIC,
    Base,
    SoftDeleteMixin,
    Timestamp,
    TimestampMixin,
    UnitPrice,
    meta,
    pk,
    table_meta,
)

DOMAIN = "estoque"

#: Tipos de evento e o sinal obrigatório de cada um (Modelo de Dados §5.3).
INBOUND_TYPES = ("purchase_receipt", "customer_return", "transfer_in", "adjustment_in")
OUTBOUND_TYPES = ("sale_dispatch", "supplier_return", "transfer_out", "adjustment_out")
SOURCE_TYPES = ("purchase", "sale", "return", "transfer", "adjustment")
RESERVATION_STATUSES = ("active", "released", "expired", "consumed")

#: Versão corrente do contrato do evento de estoque.
EVENT_SCHEMA_VERSION = 1


class Warehouse(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "warehouses"
    __table_args__ = (
        CheckConstraint("capacity_units is null or capacity_units > 0", name="capacidade_positiva"),
        table_meta(DOMAIN, "Centros de distribuição ou locais de estoque."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável do armazém."),
    )
    name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PUBLIC, "Nome do armazém."),
    )
    city: Mapped[str] = mapped_column(
        String(80), nullable=False, info=meta(PUBLIC, "Cidade do armazém."),
    )
    state: Mapped[str] = mapped_column(
        String(2), nullable=False, info=meta(PUBLIC, "Unidade federativa do armazém."),
    )
    country: Mapped[str] = mapped_column(
        String(2), nullable=False, server_default="BR", info=meta(PUBLIC, "País, em código ISO."),
    )
    capacity_units: Mapped[int | None] = mapped_column(
        Integer, nullable=True, info=meta(CONFIDENTIAL, "Capacidade máxima em unidades."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"), info=meta(INTERNAL, "Indica se o armazém está operando."),
    )


class InventoryBalance(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "inventory_balances"
    __table_args__ = (
        CheckConstraint("quantity_on_hand >= 0", name="saldo_nao_negativo"),
        CheckConstraint("quantity_reserved >= 0", name="reserva_nao_negativa"),
        CheckConstraint("quantity_reserved <= quantity_on_hand", name="reserva_limitada_ao_saldo"),
        UniqueConstraint("warehouse_id", "product_variant_id", name="uq_saldo_por_armazem_sku"),
        table_meta(DOMAIN, "Saldo atual de cada SKU por armazém."),
    )

    id: Mapped[int] = pk()
    warehouse_id: Mapped[int] = mapped_column(
        ForeignKey("warehouses.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Armazém do saldo."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "SKU do saldo."),
    )
    quantity_on_hand: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"), info=meta(INTERNAL, "Quantidade fisicamente disponível."),
    )
    quantity_reserved: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"), info=meta(INTERNAL, "Quantidade reservada para carrinhos e pedidos."),
    )
    # Coluna derivada mantida pelo banco: disponível nunca diverge do saldo
    # menos a reserva, porque não há caminho de escrita que permita divergir.
    quantity_available: Mapped[int] = mapped_column(
        Integer,
        Computed("quantity_on_hand - quantity_reserved", persisted=True),
        nullable=False,
        info=meta(INTERNAL, "Quantidade livre para venda; derivada pelo banco."),
    )
    last_movement_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento do último movimento aplicado ao saldo."),
    )


class InventoryMovement(Base):
    """Livro de eventos de estoque — somente inserções.

    Sem `updated_at` e sem `deleted_at` de propósito: alterar um evento
    publicado quebraria o CDC, que lê o log de transações e não sabe desfazer
    o que já entregou.
    """

    __tablename__ = "inventory_movements"
    __table_args__ = (
        CheckConstraint("quantity_delta <> 0", name="delta_nao_nulo"),
        CheckConstraint(
            f"(movement_type in {INBOUND_TYPES} and quantity_delta > 0) or "
            f"(movement_type in {OUTBOUND_TYPES} and quantity_delta < 0)",
            name="tipo_coerente_com_sinal",
        ),
        CheckConstraint(f"source_type in {SOURCE_TYPES}", name="origem_valida"),
        CheckConstraint("unit_cost is null or unit_cost >= 0", name="custo_nao_negativo"),
        CheckConstraint("aggregate_version > 0", name="versao_positiva"),
        CheckConstraint("schema_version > 0", name="versao_de_contrato_positiva"),
        CheckConstraint("recorded_at >= occurred_at", name="causalidade_temporal"),
        # Limite de tamanho do JSON: sem ele, `metadata` vira depósito de
        # qualquer coisa e o custo de replicação do CDC cresce sem controle.
        CheckConstraint(
            "metadata is null or octet_length(metadata::text) <= 4096", name="metadata_limitado",
        ),
        UniqueConstraint("idempotency_key", name="uq_movimento_idempotencia"),
        UniqueConstraint(
            "warehouse_id", "product_variant_id", "aggregate_version",
            name="uq_movimento_versao_por_agregado",
        ),
        Index("ix_inventory_movements_leitura_incremental", "recorded_at", "event_sequence"),
        Index("ix_inventory_movements_linhagem", "source_type", "source_id"),
        Index(
            "ix_inventory_movements_correlation_id", "correlation_id",
            postgresql_where="correlation_id is not null",
        ),
        table_meta(DOMAIN, "Livro append-only de entradas, saídas, ajustes e transferências."),
    )

    movement_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, info=meta(INTERNAL, "Chave primária estável do evento."),
    )
    event_sequence: Mapped[int] = mapped_column(
        BigInteger, Identity(always=True), nullable=False, unique=True,
        info=meta(INTERNAL, "Ordenação técnica local e paginação; atribuída pelo banco."),
    )
    idempotency_key: Mapped[str] = mapped_column(
        String(100), nullable=False,
        info=meta(INTERNAL, "Chave que impede aplicação duplicada pelo consumidor (ADR-0019)."),
    )
    warehouse_id: Mapped[int] = mapped_column(
        ForeignKey("warehouses.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Armazém afetado pelo movimento."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "SKU afetado pelo movimento."),
    )
    movement_type: Mapped[str] = mapped_column(
        String(32), nullable=False,
        info=meta(INTERNAL, "Tipo controlado do movimento; determina o sinal da quantidade."),
    )
    quantity_delta: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Variação assinada da quantidade; nunca zero."),
    )
    unit_cost: Mapped[Decimal | None] = mapped_column(
        UnitPrice, nullable=True, info=meta(CONFIDENTIAL, "Custo unitário, quando aplicável ao tipo."),
    )
    source_type: Mapped[str] = mapped_column(
        String(32), nullable=False, info=meta(INTERNAL, "Processo de negócio que originou o movimento."),
    )
    source_id: Mapped[str] = mapped_column(
        String(64), nullable=False, info=meta(INTERNAL, "Identificador do registro que causou o movimento."),
    )
    correlation_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, nullable=True,
        info=meta(INTERNAL, "Agrupa eventos relacionados; obrigatório nos pares de transferência."),
    )
    causation_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, nullable=True, info=meta(INTERNAL, "Evento ou comando que causou este movimento."),
    )
    aggregate_version: Mapped[int] = mapped_column(
        BigInteger, nullable=False,
        info=meta(INTERNAL, "Ordem do evento dentro do par armazém/SKU; sem lacuna nem repetição."),
    )
    occurred_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False,
        info=meta(INTERNAL, "Momento de negócio do movimento; é por ele que o Beam janela (ADR-0019)."),
    )
    recorded_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False,
        info=meta(INTERNAL, "Momento em que a origem registrou o evento; base da leitura incremental."),
    )
    schema_version: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, server_default=text(str(EVENT_SCHEMA_VERSION)),
        info=meta(INTERNAL, "Versão do contrato do evento, para evolução sem quebrar consumidor."),
    )
    event_metadata: Mapped[dict[str, Any] | None] = mapped_column(
        "metadata", JSONB, nullable=True,
        info=meta(INTERNAL, "Contexto adicional do evento, opcional e limitado a 4 KB."),
    )


class StockReservation(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "stock_reservations"
    __table_args__ = (
        CheckConstraint(f"status in {RESERVATION_STATUSES}", name="status_valido"),
        CheckConstraint("quantity > 0", name="quantidade_positiva"),
        # A reserva pertence a um carrinho ou a um pedido, nunca aos dois nem a
        # nenhum: reserva órfã é o caminho clássico para saldo travado.
        CheckConstraint("num_nonnulls(cart_id, order_id) = 1", name="origem_unica"),
        Index("ix_stock_reservations_saldo", "warehouse_id", "product_variant_id"),
        Index(
            "ix_stock_reservations_ativas", "expires_at",
            postgresql_where="status = 'active'",
        ),
        table_meta(DOMAIN, "Reserva de quantidade para carrinhos ou pedidos."),
    )

    id: Mapped[int] = pk()
    reservation_code: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True, info=meta(INTERNAL, "Chave natural da reserva."),
    )
    warehouse_id: Mapped[int] = mapped_column(
        ForeignKey("warehouses.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "Armazém em que a quantidade está reservada."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False,
        info=meta(INTERNAL, "SKU reservado."),
    )
    cart_id: Mapped[int | None] = mapped_column(
        ForeignKey("carts.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Carrinho que originou a reserva; nulo quando a origem é um pedido."),
    )
    order_id: Mapped[int | None] = mapped_column(
        ForeignKey("orders.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(INTERNAL, "Pedido que originou a reserva; nulo quando a origem é um carrinho."),
    )
    quantity: Mapped[int] = mapped_column(
        Integer, nullable=False, info=meta(INTERNAL, "Quantidade reservada."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="active",
        info=meta(INTERNAL, "Estado da reserva: active, released, expired ou consumed."),
    )
    expires_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(INTERNAL, "Momento em que a reserva expira se não for consumida."),
    )
    released_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(INTERNAL, "Momento em que a reserva deixou de ocupar saldo."),
    )
