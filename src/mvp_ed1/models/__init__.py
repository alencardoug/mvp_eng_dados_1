"""Modelos da origem transacional — 40 tabelas em 9 domínios.

Importar este pacote registra **todas** as tabelas no `Base.metadata`. É disso
que dependem o `autogenerate` do Alembic (ADR-0010) e a geração do dicionário:
um domínio esquecido aqui vira uma tabela que a migração não cria.
"""

from mvp_ed1.models import (  # noqa: F401  — o import é o registro
    catalog,
    customers,
    inventory,
    logistics,
    marketing,
    payments,
    procurement,
    sales,
    support,
)
from mvp_ed1.models.base import (
    CONFIDENTIAL,
    INTERNAL,
    PERSONAL,
    PUBLIC,
    SCHEMA,
    Base,
    validate_metadata,
)

#: Domínios do modelo, na ordem em que o Modelo de Dados os apresenta.
DOMAINS = (
    "clientes",
    "catalogo",
    "compras",
    "vendas",
    "pagamentos",
    "estoque",
    "logistica",
    "marketing",
    "atendimento",
)

__all__ = [
    "Base",
    "SCHEMA",
    "DOMAINS",
    "PUBLIC",
    "INTERNAL",
    "CONFIDENTIAL",
    "PERSONAL",
    "validate_metadata",
]
