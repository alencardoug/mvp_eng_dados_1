"""Domínio de catálogo e preços — 6 tabelas.

`unit_price` e `unit_cost` são `confidential`: não são dado pessoal, mas
revelam margem, e por isso ficam fora das views de consumo abertas ao perfil
de análise (Governança §4).
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
    Base,
    SoftDeleteMixin,
    Timestamp,
    TimestampMixin,
    UnitPrice,
    meta,
    pk,
    table_meta,
)

DOMAIN = "catalogo"

PRODUCT_STATUSES = ("draft", "active", "discontinued")


class ProductCategory(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "product_categories"
    __table_args__ = (
        CheckConstraint("depth >= 0 and depth <= 3", name="profundidade_valida"),
        CheckConstraint("parent_id is null or parent_id <> id", name="sem_auto_referencia"),
        table_meta(DOMAIN, "Hierarquia de categorias e subcategorias do catálogo."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(PUBLIC, "Código estável da categoria; chave natural."),
    )
    name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PUBLIC, "Nome comercial da categoria."),
    )
    parent_id: Mapped[int | None] = mapped_column(
        ForeignKey("product_categories.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(PUBLIC, "Categoria imediatamente superior; nulo na raiz."),
    )
    depth: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0"),
        info=meta(PUBLIC, "Profundidade na hierarquia, com a raiz em zero."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se a categoria continua em uso."),
    )


class Brand(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "brands"
    __table_args__ = table_meta(DOMAIN, "Marcas associadas aos produtos.")

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável da marca."),
    )
    name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PUBLIC, "Nome da marca."),
    )
    country: Mapped[str | None] = mapped_column(
        String(2), nullable=True, info=meta(PUBLIC, "País de origem, em código ISO."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se a marca continua ativa no catálogo."),
    )


class Product(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "products"
    __table_args__ = (
        CheckConstraint(f"status in {PRODUCT_STATUSES}", name="status_valido"),
        table_meta(DOMAIN, "Produto conceitual vendido pelo marketplace."),
    )

    id: Mapped[int] = pk()
    product_code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True,
        info=meta(PUBLIC, "Chave natural do produto na origem."),
    )
    category_id: Mapped[int] = mapped_column(
        ForeignKey("product_categories.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Categoria comercial do produto."),
    )
    brand_id: Mapped[int | None] = mapped_column(
        ForeignKey("brands.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(PUBLIC, "Marca do produto."),
    )
    name: Mapped[str] = mapped_column(
        String(200), nullable=False, info=meta(PUBLIC, "Nome comercial do produto."),
    )
    description: Mapped[str | None] = mapped_column(
        Text, nullable=True, info=meta(PUBLIC, "Descrição comercial do produto."),
    )
    status: Mapped[str] = mapped_column(
        String(16), nullable=False, server_default="active",
        info=meta(INTERNAL, "Estado do produto: draft, active ou discontinued."),
    )
    launched_at: Mapped[dt.date | None] = mapped_column(
        Timestamp, nullable=True, info=meta(PUBLIC, "Momento de lançamento comercial."),
    )


class ProductVariant(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "product_variants"
    __table_args__ = (
        CheckConstraint("weight_grams is null or weight_grams > 0", name="peso_positivo"),
        table_meta(DOMAIN, "SKUs e variações de tamanho, cor ou embalagem."),
    )

    id: Mapped[int] = pk()
    product_id: Mapped[int] = mapped_column(
        ForeignKey("products.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "Produto do qual a variante deriva."),
    )
    sku: Mapped[str] = mapped_column(
        String(40), nullable=False, unique=True,
        info=meta(PUBLIC, "Código de estoque da variante; chave natural do SKU."),
    )
    size: Mapped[str | None] = mapped_column(
        String(20), nullable=True, info=meta(PUBLIC, "Tamanho da variante."),
    )
    color: Mapped[str | None] = mapped_column(
        String(40), nullable=True, info=meta(PUBLIC, "Cor da variante."),
    )
    package: Mapped[str | None] = mapped_column(
        String(40), nullable=True, info=meta(PUBLIC, "Embalagem ou unidade de venda."),
    )
    barcode: Mapped[str | None] = mapped_column(
        String(32), nullable=True, unique=True,
        info=meta(PUBLIC, "Código de barras da variante (sintético)."),
    )
    weight_grams: Mapped[int | None] = mapped_column(
        Integer, nullable=True, info=meta(PUBLIC, "Peso em gramas, usado no cálculo de frete."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se o SKU continua disponível para venda."),
    )


class PriceList(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "price_lists"
    __table_args__ = (
        CheckConstraint("valid_to is null or valid_to > valid_from", name="vigencia_coerente"),
        table_meta(DOMAIN, "Listas de preço por canal, moeda e período de vigência."),
    )

    id: Mapped[int] = pk()
    code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, info=meta(PUBLIC, "Código estável da lista."),
    )
    name: Mapped[str] = mapped_column(
        String(120), nullable=False, info=meta(PUBLIC, "Nome comercial da lista de preços."),
    )
    sales_channel_id: Mapped[int | None] = mapped_column(
        ForeignKey("sales_channels.id", ondelete="RESTRICT"), nullable=True, index=True,
        info=meta(PUBLIC, "Canal ao qual a lista se aplica; nulo quando vale para todos."),
    )
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, server_default="BRL",
        info=meta(PUBLIC, "Moeda da lista, em código ISO 4217."),
    )
    valid_from: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(PUBLIC, "Início da vigência da lista."),
    )
    valid_to: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(PUBLIC, "Fim da vigência; nulo enquanto vigente."),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true"),
        info=meta(INTERNAL, "Indica se a lista está em uso."),
    )


class ProductPrice(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "product_prices"
    __table_args__ = (
        CheckConstraint("unit_price >= 0", name="preco_nao_negativo"),
        CheckConstraint("valid_to is null or valid_to > valid_from", name="vigencia_coerente"),
        Index(
            "uq_product_prices_lista_variante_vigencia",
            "price_list_id", "product_variant_id", "valid_from",
            unique=True,
        ),
        table_meta(DOMAIN, "Preço de cada SKU em uma lista e intervalo de vigência."),
    )

    id: Mapped[int] = pk()
    price_list_id: Mapped[int] = mapped_column(
        ForeignKey("price_lists.id", ondelete="RESTRICT"), nullable=False,
        info=meta(PUBLIC, "Lista à qual o preço pertence."),
    )
    product_variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), nullable=False, index=True,
        info=meta(PUBLIC, "SKU precificado."),
    )
    unit_price: Mapped[Decimal] = mapped_column(
        UnitPrice, nullable=False,
        info=meta(CONFIDENTIAL, "Preço unitário de venda na lista e vigência."),
    )
    valid_from: Mapped[dt.datetime] = mapped_column(
        Timestamp, nullable=False, info=meta(PUBLIC, "Início da vigência do preço."),
    )
    valid_to: Mapped[dt.datetime | None] = mapped_column(
        Timestamp, nullable=True, info=meta(PUBLIC, "Fim da vigência; nulo enquanto vigente."),
    )
