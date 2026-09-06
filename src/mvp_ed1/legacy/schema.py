"""Estrutura frouxa do legado, derivada dos modelos.

`legacy_db` reproduz os **mesmos 40 nomes de tabela e o mesmo significado de
campos** da origem principal (Origem Legada §2), e nada mais. Não é cópia do DDL
normalizado: é o que sobra dele quando ninguém cuidou.

── Por que tudo é `text` ─────────────────────────────────────────────────────
Uma coluna tipada como número ou data **rejeitaria** o exemplo defeituoso na
carga, antes que a engenharia de limpeza tivesse o que limpar. A tipagem frouxa
não é desleixo simulado: é a condição para o exercício existir.

Pelo mesmo motivo não há `CHECK`, `NOT NULL`, unicidade nem chave estrangeira.
`FK_ORPHAN` e `DUP_EXACT` são falhas do catálogo — declará-las impossíveis no
banco tornaria dois tratamentos inalcançáveis.

── A identidade da ocorrência física ─────────────────────────────────────────
`legacy_row_id` é a única coluna que o legado tem e a origem principal não. Ela
existe porque duas linhas de negócio **idênticas** precisam ser distinguíveis:
sem ela, a duplicata exata do ADR-0038 não teria como ter uma canônica e uma
excedente — seriam a mesma linha contada duas vezes.
"""

from __future__ import annotations

from sqlalchemy import Boolean, Date, DateTime, Integer, Numeric, String, Text

from mvp_ed1.generator import enums
from mvp_ed1.models import Base

#: Schema do banco legado. Nome próprio, não prefixo (ADR-0013).
SCHEMA = "legacy"

#: Coluna de identidade física da ocorrência, exclusiva do legado.
IDENTIDADE = "legacy_row_id"

#: Metadados da captura, escritos na ingestão e não pelo gerador.
COLUNAS_DE_CAPTURA = ("snapshot_id", "snapshot_at", "source_system")


#: Um arquétipo do catálogo pode alcançar mais de um arquétipo de coluna, e a
#: relação não é simétrica. `DATE_FORMAT_KNOWN` vale para **qualquer** coluna
#: temporal — inclusive as de promessa —, enquanto `DATE_FUTURE` vale só para as
#: de fato consumado, porque prazo prometido no futuro não é defeito.
#:
#: Sem esta tabela, um arquétipo do catálogo teria de casar exatamente com um
#: arquétipo de coluna, e a alternativa seria declarar a mesma falha três vezes.
ALCANCE: dict[str, frozenset[str]] = {
    "qualquer": frozenset(
        {
            "qualquer", "texto", "texto_com_limite", "email", "booleano", "enumerado",
            "dinheiro", "quantidade", "data_de_fato_consumado", "momento",
        }
    ),
    "data": frozenset({"data_de_fato_consumado", "momento"}),
    "momento": frozenset({"data_de_fato_consumado", "momento"}),
    "data_de_fato_consumado": frozenset({"data_de_fato_consumado"}),
    "texto": frozenset({"texto", "texto_com_limite", "email"}),
    "texto_com_limite": frozenset({"texto_com_limite"}),
}


def alcanca(arquetipo_da_falha: str, arquetipo_da_coluna: str) -> bool:
    """A falha declarada para este arquétipo atinge esta coluna?"""
    alcance = ALCANCE.get(arquetipo_da_falha)
    if alcance is None:
        return arquetipo_da_falha == arquetipo_da_coluna
    return arquetipo_da_coluna in alcance


def tabelas() -> tuple[str, ...]:
    """Os 40 nomes, na ordem de dependência da origem — que aqui não é imposta."""
    return tuple(t.name for t in Base.metadata.sorted_tables)


def colunas(tabela: str) -> tuple[str, ...]:
    """Colunas gravadas no legado: as do modelo, menos as que o banco gera."""
    t = Base.metadata.tables[f"{Base.metadata.schema}.{tabela}"]
    return tuple(c.name for c in t.columns if not _gerada_pelo_banco(c))


def _gerada_pelo_banco(coluna) -> bool:
    return bool(getattr(coluna, "computed", None)) or (
        coluna.identity is not None and coluna.name != "id"
    )


def limites(largura_do_legado: int | None = None) -> dict[tuple[str, str], int]:
    """Largura de cada coluna textual **no sistema antigo**, por (tabela, coluna).

    Não é o limite do modelo atual. A origem legada é outro sistema, mais velho
    e mais apertado, e o truncamento nasce daí: um `varchar(24)` recebendo um
    endereço de quarenta caracteres. Quando `largura_do_legado` é informada, ela
    limita a do modelo — a coluna antiga nunca é mais larga que a de hoje.

    É o que torna `TEXT_TRUNCATED` detectável: sem uma largura declarada,
    "cortado no limite" não é observável em coluna `text`. A heurística —
    comprimento exatamente igual à largura — é assumida com a sua taxa de falso
    positivo, e o gerador produz de propósito valores legítimos nesse tamanho.
    """
    resultado: dict[tuple[str, str], int] = {}
    for t in Base.metadata.sorted_tables:
        for c in t.columns:
            if isinstance(c.type, String) and c.type.length:
                largura = int(c.type.length)
                if largura_do_legado is not None:
                    largura = min(largura, largura_do_legado)
                resultado[(t.name, c.name)] = largura
    return resultado


def arquetipo(tabela: str, coluna: str, promessas: frozenset[str] = frozenset()) -> str:
    """Arquétipo de falha a que a coluna se sujeita.

    A resolução sai do **tipo declarado no modelo** e das `CHECK` que ele já
    escreve, nunca de uma lista de nomes mantida à mão: acrescentar coluna à
    origem passa a sujeitá-la às falhas do seu arquétipo sem que ninguém precise
    lembrar de anotá-la aqui.

    A única exceção declarada de fora é `promessas` — as colunas de tempo que
    registram compromisso e não fato, e que por isso podem legitimamente cair
    depois do corte. Elas vêm do catálogo, onde cada uma tem nome.
    """
    t = Base.metadata.tables[f"{Base.metadata.schema}.{tabela}"]
    c = t.columns[coluna]
    qualificado = f"{tabela}.{coluna}"

    if c.foreign_keys:
        return "chave_estrangeira"
    if isinstance(c.type, Boolean):
        return "booleano"
    if coluna in enums.enumeracoes().get(tabela, {}):
        return "enumerado"
    if isinstance(c.type, Numeric) and c.type.scale:
        return "dinheiro"
    if isinstance(c.type, Integer):
        return "quantidade" if "quantity" in coluna or "units" in coluna else "qualquer"
    if isinstance(c.type, (Date, DateTime)):
        if qualificado in promessas:
            return "momento"
        return "data_de_fato_consumado"
    if "email" in coluna:
        return "email"
    if isinstance(c.type, String) and c.type.length:
        return "texto_com_limite"
    if isinstance(c.type, (String, Text)):
        return "texto"
    return "qualquer"


def ddl() -> tuple[str, ...]:
    """Comandos que criam o schema legado do zero.

    Idempotente por `if not exists`: aplicar duas vezes não é erro, e é o que
    permite recarregar a origem sem recriar o banco.
    """
    comandos = [f"create schema if not exists {SCHEMA}"]
    for nome in tabelas():
        campos = ", ".join(f'"{c}" text' for c in colunas(nome))
        comandos.append(
            f'create table if not exists {SCHEMA}."{nome}" '
            f"({IDENTIDADE} bigint generated always as identity primary key, {campos})"
        )
    return tuple(comandos)
