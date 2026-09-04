"""Domínio de clientes — 5 tabelas.

Concentra a maior parte dos campos `personal` do projeto. Eles são sintéticos,
mas classificados como se fossem reais: o objetivo é exercitar o controle, não
presumir que dado simulado dispensa governança (Governança §4).
"""

from __future__ import annotations

import datetime as dt

from sqlalchemy import Boolean, CheckConstraint, Date, ForeignKey, Index, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from mvp_ed1.models.base import (
    CONFIDENTIAL,
    INTERNAL,
    PERSONAL,
    PUBLIC,
    Base,
    SoftDeleteMixin,
    Timestamp,
    TimestampMixin,
    meta,
    pk,
    table_meta,
)

DOMAIN = "clientes"

CUSTOMER_STATUSES = ("active", "inactive", "blocked", "pending")
ADDRESS_TYPES = ("billing", "shipping")
CONTACT_TYPES = ("email", "phone", "mobile")


class CustomerSegment(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "customer_segments"
    __table_args__ = table_meta(DOMAIN, "Segmentos comerciais associáveis ao cadastro do cliente.")

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(PUBLIC, "Código estável do segmento, usado como chave natural."),
    )
    name: Mapped[str] = mapped_column(
        String(80), nullable=False,
        info=meta(PUBLIC, "Nome comercial do segmento."),
    )
    description: Mapped[str | None] = mapped_column(
        Text, nullable=True,
        info=meta(PUBLIC, "Critério de enquadramento do segmento."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se o segmento continua em uso."),
    )


class Customer(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "customers"
    __table_args__ = (
        CheckConstraint(
            f"status in {CUSTOMER_STATUSES}", name="status_valido",
        ),
        Index("ix_customers_segment_id", "segment_id"),
        table_meta(DOMAIN, "Cadastro principal do cliente e estado do relacionamento."),
    )

    id: Mapped[int] = pk()
    customer_code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(INTERNAL, "Chave natural do cliente na origem; estável entre cargas."),
    )
    segment_id: Mapped[int | None] = mapped_column(
        ForeignKey("customer_segments.id", ondelete="RESTRICT"), nullable=True,
        info=meta(INTERNAL, "Segmento comercial ao qual o cliente pertence."),
    )
    first_name: Mapped[str] = mapped_column(
        String(80), nullable=False,
        info=meta(PERSONAL, "Primeiro nome do cliente (sintético)."),
    )
    last_name: Mapped[str] = mapped_column(
        String(120), nullable=False,
        info=meta(PERSONAL, "Sobrenome do cliente (sintético)."),
    )
    document: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(PERSONAL, "Documento de identificação do cliente (sintético)."),
    )
    birth_date: Mapped[dt.date | None] = mapped_column(
        Date, nullable=True,
        info=meta(PERSONAL, "Data de nascimento do cliente (sintética)."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="active",
        info=meta(INTERNAL, "Estado do relacionamento: active, inactive, blocked ou pending."),
    )
    registered_at: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False,
        info=meta(INTERNAL, "Momento de negócio do cadastro, distinto de `created_at`."),
    )


class CustomerAddress(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "customer_addresses"
    __table_args__ = (
        CheckConstraint(f"address_type in {ADDRESS_TYPES}", name="tipo_valido"),
        CheckConstraint(
            "valid_to is null or valid_to > valid_from", name="vigencia_coerente",
        ),
        Index(
            "ix_customer_addresses_principal_unico",
            "customer_id", "address_type",
            unique=True,
            postgresql_where="is_primary and deleted_at is null",
        ),
        table_meta(DOMAIN, "Endereços de cobrança e entrega, com vigência e indicação de principal."),
    )

    id: Mapped[int] = pk()
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Cliente dono do endereço."),
    )
    address_type: Mapped[str] = mapped_column(
        String(16), nullable=False,
        info=meta(INTERNAL, "Finalidade do endereço: billing ou shipping."),
    )
    street: Mapped[str] = mapped_column(
        String(160), nullable=False, info=meta(PERSONAL, "Logradouro (sintético)."),
    )
    number: Mapped[str | None] = mapped_column(
        String(20), nullable=True, info=meta(PERSONAL, "Número do endereço (sintético)."),
    )
    complement: Mapped[str | None] = mapped_column(
        String(80), nullable=True, info=meta(PERSONAL, "Complemento do endereço (sintético)."),
    )
    district: Mapped[str | None] = mapped_column(
        String(80), nullable=True, info=meta(PERSONAL, "Bairro (sintético)."),
    )
    city: Mapped[str] = mapped_column(
        String(80), nullable=False, info=meta(PUBLIC, "Cidade; alimenta a dimensão de geografia."),
    )
    state: Mapped[str] = mapped_column(
        String(2), nullable=False, info=meta(PUBLIC, "Unidade federativa em sigla de duas letras."),
    )
    postal_code: Mapped[str] = mapped_column(
        String(16), nullable=False, info=meta(PERSONAL, "Código postal (sintético)."),
    )
    country: Mapped[str] = mapped_column(
        String(2), nullable=False, server_default="BR",
        info=meta(PUBLIC, "País em código ISO de duas letras."),
    )
    is_primary: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"),
        info=meta(INTERNAL, "Endereço principal do cliente para o tipo indicado."),
    )
    valid_from: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False,
        info=meta(INTERNAL, "Início da vigência do endereço."),
    )
    valid_to: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True,
        info=meta(INTERNAL, "Fim da vigência; nulo enquanto vigente."),
    )


class CustomerContact(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "customer_contacts"
    __table_args__ = (
        CheckConstraint(f"contact_type in {CONTACT_TYPES}", name="tipo_valido"),
        Index(
            "ix_customer_contacts_principal_unico",
            "customer_id", "contact_type",
            unique=True,
            postgresql_where="is_primary and deleted_at is null",
        ),
        table_meta(DOMAIN, "E-mails e telefones sintéticos associados ao cliente."),
    )

    id: Mapped[int] = pk()
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(INTERNAL, "Cliente dono do contato."),
    )
    contact_type: Mapped[str] = mapped_column(
        String(16), nullable=False,
        info=meta(INTERNAL, "Natureza do contato: email, phone ou mobile."),
    )
    contact_value: Mapped[str] = mapped_column(
        String(160), nullable=False,
        info=meta(PERSONAL, "Endereço de e-mail ou número de telefone (sintético)."),
    )
    is_primary: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"),
        info=meta(INTERNAL, "Contato principal do cliente para o tipo indicado."),
    )
    is_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"),
        info=meta(INTERNAL, "Indica se o contato passou por verificação simulada."),
    )


class CustomerPreference(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "customer_preferences"
    __table_args__ = table_meta(
        DOMAIN, "Preferências de comunicação, idioma e consentimentos simulados."
    )

    id: Mapped[int] = pk()
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, unique=True,
        info=meta(INTERNAL, "Cliente dono das preferências; uma linha por cliente."),
    )
    language: Mapped[str] = mapped_column(
        String(10), nullable=False, server_default="pt-BR",
        info=meta(INTERNAL, "Idioma preferido, em código BCP 47."),
    )
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, server_default="BRL",
        info=meta(PUBLIC, "Moeda preferida, em código ISO 4217."),
    )
    marketing_opt_in: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"),
        info=meta(CONFIDENTIAL, "Consentimento simulado para comunicações de marketing."),
    )
    newsletter_opt_in: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"),
        info=meta(CONFIDENTIAL, "Consentimento simulado para a newsletter."),
    )
    consent_updated_at: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True,
        info=meta(CONFIDENTIAL, "Momento da última alteração de consentimento."),
    )
