"""Enumerações e mínimos estruturais lidos dos modelos.

O piso de cobertura do ADR-0014 exige que **todo valor de enumeração** apareça
ao menos uma vez, em qualquer fator de escala. Reescrever essas listas na
configuração as duplicaria, e a duplicata divergiria na primeira enumeração
nova — o mesmo argumento com que o ADR-0009 fez a configuração ser *validada*
contra os modelos em vez de repeti-los.

Então elas não são reescritas: são lidas das `CHECK` que os modelos já
declaram. Uma enumeração nova no modelo levanta o piso da tabela sozinha, e
"todo valor presente" passa a ser verdade por construção, não teste que
descobre depois.
"""

from __future__ import annotations

import re
from functools import lru_cache

from sqlalchemy import CheckConstraint, Table

from mvp_ed1.models import Base

#: `status in ('active', 'inactive')` — a forma que `f"col in {TUPLA}"` gera.
#: Só casa lista inteiramente de literais: `num_nonnulls(a, b) = 1` não entra.
_ENUM = re.compile(r"\b([a-z_][a-z0-9_]*)\s+in\s+\((\s*'[^']*'\s*(?:,\s*'[^']*'\s*)*)\)")
_LITERAL = re.compile(r"'([^']*)'")


def _texto(constraint: CheckConstraint) -> str:
    return str(constraint.sqltext)


@lru_cache(maxsize=1)
def enumeracoes() -> dict[str, dict[str, tuple[str, ...]]]:
    """Valores aceitos por coluna, por tabela, extraídos das `CHECK`.

    Uma coluna pode aparecer em mais de uma `CHECK` — `movement_type` está em
    duas, uma por sinal da quantidade. Os valores das duas são unidos, na
    ordem em que o modelo os declara.
    """
    encontrado: dict[str, dict[str, list[str]]] = {}
    for table in Base.metadata.sorted_tables:
        por_coluna = encontrado.setdefault(table.name, {})
        for constraint in table.constraints:
            if not isinstance(constraint, CheckConstraint):
                continue
            for coluna, lista in _ENUM.findall(_texto(constraint)):
                if coluna not in table.columns:
                    continue
                valores = por_coluna.setdefault(coluna, [])
                for valor in _LITERAL.findall(lista):
                    if valor not in valores:
                        valores.append(valor)
    return {
        tabela: {coluna: tuple(valores) for coluna, valores in sorted(colunas.items())}
        for tabela, colunas in encontrado.items()
    }


def valores(tabela: str, coluna: str) -> tuple[str, ...]:
    """Valores aceitos por uma coluna; falha alto se ela não for enumerada.

    Erro de digitação no nome da coluna produziria uma tupla vazia e uma
    tabela silenciosamente sem cobertura — é preferível parar aqui.
    """
    try:
        return enumeracoes()[tabela][coluna]
    except KeyError as erro:
        raise KeyError(f"{tabela}.{coluna} não tem enumeração declarada no modelo") from erro


def piso_por_enumeracao(tabela: str) -> int:
    """Menor número de linhas capaz de conter todo valor enumerado da tabela.

    É o maior número de valores entre as colunas enumeradas: com `n` linhas
    dá para cobrir uma coluna de `n` valores, e as demais cabem dentro.
    """
    colunas = enumeracoes().get(tabela, {})
    return max((len(v) for v in colunas.values()), default=0)


def tabela(nome: str) -> Table:
    return Base.metadata.tables[f"{Base.metadata.schema}.{nome}"]


def nomes_de_tabelas() -> tuple[str, ...]:
    """Tabelas na ordem de dependência referencial, dada pelo mapeamento.

    A ordem sai de `sorted_tables`, não de lista mantida à mão: as chaves
    estrangeiras já a resolvem (ADR-0009).
    """
    return tuple(t.name for t in Base.metadata.sorted_tables)
