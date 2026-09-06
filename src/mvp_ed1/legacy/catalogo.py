"""Carga e validação do catálogo de falhas.

O catálogo é a **declaração**, e a §5 do `CLAUDE.md` manda revisar 100% do que é
declaração. Este módulo existe para que a revisão tenha o que confiar: ele
recusa um catálogo incoerente na carga, e não na hora em que o injetor produzir
um defeito que ninguém sabe tratar.

Três invariantes são verificadas aqui, e cada uma corresponde a um erro real que
o formato permite cometer:

* toda falha declara **conversão ou rejeição**, nunca as duas nem nenhuma — é o
  critério da Origem Legada §3.1, e um catálogo que o viole produziria registro
  sem classificação possível;
* toda falha injetável declara **frequência maior que zero e ao menos uma
  forma** — frequência zero com forma declarada é regra morta;
* falha **derivada** não é injetada, e declara de quais outras ela nasce — é o
  caso do `PARENT_REJECTED`, que emerge do tratamento (ADR-0038).
"""

from __future__ import annotations

import pathlib
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

import yaml

CAMINHO = pathlib.Path(__file__).with_name("catalogo.yml")

#: Arquétipos que o injetor sabe resolver contra os modelos. Um arquétipo novo
#: no YAML sem par aqui é falha de carga, não escolha implícita.
ARQUETIPOS = frozenset(
    {
        "quantidade",
        "dinheiro",
        "data",
        "data_de_fato_consumado",
        "momento",
        "texto",
        "texto_com_limite",
        "booleano",
        "enumerado",
        "email",
        "chave_estrangeira",
        "chave_natural",
        "registro",
        "registro_filho",
        "total_do_pedido",
        "qualquer",
    }
)


class CatalogoInvalido(Exception):
    """O catálogo declara algo que o tratamento não consegue honrar."""


@dataclass(frozen=True)
class Falha:
    codigo: str
    grupo: str
    arquetipo: str
    deteccao: str
    conversao: str | None
    rejeicao: str | None
    frequencia: int
    formas: tuple[str, ...]
    derivado_de: tuple[str, ...]
    tolerance: Decimal | None = None

    @property
    def converte(self) -> bool:
        return self.conversao is not None

    @property
    def e_derivada(self) -> bool:
        return self.frequencia == 0


@dataclass(frozen=True)
class Catalogo:
    versao: int
    semente: int
    fator: float
    limite_de_texto: int
    delimitador: str
    nulos_disfarcados: tuple[str, ...]
    #: Colunas de tempo que registram compromisso, não fato: podem cair depois
    #: do corte sem que isso seja defeito.
    promessas: frozenset[str]
    #: Colunas de quantidade em que o negativo é legítimo.
    quantidades_com_sinal: frozenset[str]
    #: Colunas que o sistema antigo guardava mais estreitas que o atual.
    colunas_estreitadas: frozenset[str]
    falhas: dict[str, Falha]

    def por_arquetipo(self, arquetipo: str) -> tuple[Falha, ...]:
        return tuple(f for f in self.falhas.values() if f.arquetipo == arquetipo)

    @property
    def injetaveis(self) -> tuple[Falha, ...]:
        return tuple(f for f in self.falhas.values() if not f.e_derivada)

    @property
    def registros_falhos_planejados(self) -> int:
        return sum(f.frequencia for f in self.falhas.values())


def carregar(caminho: pathlib.Path | None = None) -> Catalogo:
    bruto: dict[str, Any] = yaml.safe_load((caminho or CAMINHO).read_text(encoding="utf-8"))
    falhas: dict[str, Falha] = {}
    problemas: list[str] = []

    for codigo, spec in bruto["falhas"].items():
        injecao = spec.get("injecao") or {}
        falha = Falha(
            codigo=codigo,
            grupo=spec["grupo"],
            arquetipo=spec["arquetipo"],
            deteccao=spec["deteccao"],
            conversao=spec.get("conversao"),
            rejeicao=spec.get("rejeicao"),
            frequencia=int(injecao.get("frequencia", 0)),
            formas=tuple(injecao.get("formas", ())),
            derivado_de=tuple(injecao.get("derivado_de", ())),
            tolerance=Decimal(str(spec["tolerancia"])) if "tolerancia" in spec else None,
        )
        falhas[codigo] = falha
        if falha.tolerance is not None and (not falha.tolerance.is_finite() or falha.tolerance < 0):
            problemas.append(f"{codigo}: tolerância deve ser decimal finito não negativo")

        if falha.arquetipo not in ARQUETIPOS:
            problemas.append(f"{codigo}: arquétipo {falha.arquetipo!r} não é resolvível")
        if bool(falha.conversao) == bool(falha.rejeicao):
            problemas.append(f"{codigo}: declare conversão **ou** rejeição, nunca ambas nem nenhuma")
        if falha.e_derivada:
            if falha.formas:
                problemas.append(f"{codigo}: falha derivada não é injetada e não tem formas")
            if not falha.derivado_de:
                problemas.append(f"{codigo}: falha derivada precisa dizer de quais outras nasce")
        elif not falha.formas:
            problemas.append(f"{codigo}: falha injetável precisa de ao menos uma forma")

    for codigo, falha in falhas.items():
        for origem in falha.derivado_de:
            if origem not in falhas:
                problemas.append(f"{codigo}: deriva de {origem!r}, que não está no catálogo")

    if problemas:
        raise CatalogoInvalido("; ".join(problemas))

    return Catalogo(
        versao=int(bruto["versao"]),
        semente=int(bruto["geracao"]["semente"]),
        fator=float(bruto["geracao"]["fator"]),
        limite_de_texto=int(bruto["geracao"]["limite_de_texto"]),
        delimitador=bruto["delimitador"],
        nulos_disfarcados=tuple(bruto["nulos_disfarcados"]),
        promessas=frozenset(bruto["promessas"]),
        quantidades_com_sinal=frozenset(bruto["quantidades_com_sinal"]),
        colunas_estreitadas=frozenset(bruto["colunas_estreitadas"]),
        falhas=falhas,
    )
