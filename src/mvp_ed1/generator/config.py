"""Carga e validação do artefato declarativo do gerador.

A configuração não é lida e usada: é lida e **conferida contra os modelos**
antes de qualquer linha ser gerada (ADR-0009). Coluna que não existe, peso que
esquece um valor da enumeração, piso sem motivo — tudo isso para aqui, e não
oito minutos depois com um `COPY` recusado pelo banco.

O corolário do `CLAUDE.md` §5 é que **erro em declaração é bloqueante**. Este
módulo é onde esse corolário vira código.
"""

from __future__ import annotations

import datetime as dt
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml

from mvp_ed1.generator import enums

ARQUIVO = Path(__file__).with_name("geracao.yml")

DECLARATIVA = "declarativa"
PROCESSO = "processo"

#: Chaves aceitas em `colunas` — o vocabulário documentado no topo do YAML.
_CHAVES_DE_COLUNA = frozenset(
    {
        "faker", "provedor", "sequencia", "pesos", "valores", "ciclo", "faixa",
        "casas", "nulo", "constante",
    }
)


class ConfiguracaoInvalida(Exception):
    """Erro de declaração. Bloqueia a geração inteira, por desenho."""


@dataclass(frozen=True)
class Tabela:
    nome: str
    referencia: int
    origem: str
    min_rows: int | None = None
    motivo: str | None = None
    nota: str | None = None
    momento: str | None = None
    cobertura_dispensada: dict[str, list[str]] = field(default_factory=dict)
    colunas: dict[str, dict[str, Any]] = field(default_factory=dict)
    processo: dict[str, Any] = field(default_factory=dict)

    @property
    def piso(self) -> int:
        """Piso efetivo: o estrutural declarado ou o que as enumerações exigem.

        O segundo é lido dos modelos (ADR-0014, piso de cobertura); o primeiro
        só existe onde a cobertura precisa de mais do que enumeração. Nunca
        menor que 1: a primeira linha do piso do ADR-0014 é "toda tabela
        populada — nenhuma das 40 vazia", e em fator pequeno o arredondamento
        levaria `brands` a zero sem que nada reclamasse.
        """
        return max(1, self.min_rows or 0, enums.piso_por_enumeracao(self.nome))

    def coluna(self, nome: str) -> dict[str, Any]:
        return self.colunas.get(nome, {})


@dataclass(frozen=True)
class Config:
    versao: int
    localidade: str
    seed: int
    as_of_date: dt.date
    period_start: dt.date
    utc_offset_horas: int
    exclusao_logica: float
    tolerancia_processo: float
    divisor_da_referencia: int
    fator_padrao: str
    fatores: dict[str, float]
    pesos_por_mes: tuple[int, ...]
    pesos_por_hora: tuple[int, ...]
    tabelas: dict[str, Tabela]

    @property
    def fuso(self) -> dt.timezone:
        return dt.timezone(dt.timedelta(hours=self.utc_offset_horas))

    @property
    def inicio(self) -> dt.datetime:
        return dt.datetime.combine(self.period_start, dt.time(0, 0), self.fuso)

    @property
    def fim(self) -> dt.datetime:
        return dt.datetime.combine(self.as_of_date, dt.time(0, 0), self.fuso)

    def fator(self, nome: str | None = None) -> float:
        nome = nome or self.fator_padrao
        if nome not in self.fatores:
            disponiveis = ", ".join(sorted(self.fatores))
            raise ConfiguracaoInvalida(f"fator de escala {nome!r} não declarado. Há: {disponiveis}")
        return self.fatores[nome]

    def linhas(self, tabela: str, fator: str | float | None = None) -> int:
        """Linhas previstas para a tabela: proporção × fator, nunca abaixo do piso."""
        f = fator if isinstance(fator, (int, float)) else self.fator(fator)
        t = self.tabelas[tabela]
        alvo = round(t.referencia / self.divisor_da_referencia * f)
        return max(t.piso, alvo)

    def plano(self, fator: str | float | None = None) -> dict[str, int]:
        """Linhas previstas para as 40 tabelas, na ordem de dependência."""
        return {nome: self.linhas(nome, fator) for nome in enums.nomes_de_tabelas()}


def _exigir(condicao: bool, mensagem: str) -> None:
    if not condicao:
        raise ConfiguracaoInvalida(mensagem)


def _validar_tabela(t: Tabela) -> list[str]:
    """Confere uma tabela declarada contra o modelo. Devolve os problemas."""
    problemas: list[str] = []
    modelo = enums.tabela(t.nome)
    enumeradas = enums.enumeracoes().get(t.nome, {})

    if t.origem not in (DECLARATIVA, PROCESSO):
        problemas.append(f"{t.nome}: `origem` deve ser {DECLARATIVA!r} ou {PROCESSO!r}")
    if t.referencia <= 0:
        problemas.append(f"{t.nome}: `referencia` precisa ser positiva")
    if t.min_rows is not None and not (t.motivo or "").strip():
        problemas.append(f"{t.nome}: `min_rows` sem `motivo` — piso sem justificativa é número mágico")
    if t.motivo and t.min_rows is None:
        problemas.append(f"{t.nome}: `motivo` sem `min_rows`")
    if t.momento and t.momento not in modelo.columns:
        problemas.append(f"{t.nome}: `momento` aponta para {t.momento!r}, que não existe no modelo")

    for coluna, dispensados in t.cobertura_dispensada.items():
        if coluna not in enumeradas:
            problemas.append(f"{t.nome}.{coluna}: dispensa de cobertura em coluna não enumerada")
            continue
        desconhecidos = sorted(set(dispensados) - set(enumeradas[coluna]))
        if desconhecidos:
            problemas.append(f"{t.nome}.{coluna}: dispensa valores que o modelo não aceita: {desconhecidos}")

    for coluna, spec in t.colunas.items():
        if coluna not in modelo.columns:
            problemas.append(f"{t.nome}.{coluna}: coluna não existe no modelo")
            continue
        desconhecidas = set(spec) - _CHAVES_DE_COLUNA
        if desconhecidas:
            problemas.append(f"{t.nome}.{coluna}: chaves desconhecidas {sorted(desconhecidas)}")
        if "nulo" in spec and not modelo.columns[coluna].nullable:
            problemas.append(f"{t.nome}.{coluna}: `nulo` declarado em coluna obrigatória")
        if spec.get("ciclo") and not spec.get("valores"):
            problemas.append(f"{t.nome}.{coluna}: `ciclo` exige `valores`")
        if coluna in enumeradas:
            aceitos = set(enumeradas[coluna])
            declarados = set(spec.get("pesos") or spec.get("valores") or ())
            if declarados and declarados != aceitos:
                faltando = sorted(aceitos - declarados)
                sobrando = sorted(declarados - aceitos)
                detalhe = []
                if faltando:
                    detalhe.append(f"não cobre {faltando}")
                if sobrando:
                    detalhe.append(f"declara o que o modelo recusa: {sobrando}")
                problemas.append(f"{t.nome}.{coluna}: " + "; ".join(detalhe))
    return problemas


def validar(config: Config) -> list[str]:
    """Todos os problemas da configuração, para corrigir de uma vez só."""
    problemas: list[str] = []
    do_modelo = set(enums.nomes_de_tabelas())
    declaradas = set(config.tabelas)

    for ausente in sorted(do_modelo - declaradas):
        problemas.append(f"{ausente}: tabela do modelo ausente na configuração")
    for extra in sorted(declaradas - do_modelo):
        problemas.append(f"{extra}: declarada na configuração e inexistente no modelo")

    for nome in sorted(declaradas & do_modelo):
        problemas.extend(_validar_tabela(config.tabelas[nome]))

    if config.period_start >= config.as_of_date:
        problemas.append("`period_start` precisa ser anterior a `as_of_date`")
    if len(config.pesos_por_mes) != 12:
        problemas.append("`sazonalidade.pesos_por_mes` precisa ter 12 valores")
    if len(config.pesos_por_hora) != 24:
        problemas.append("`sazonalidade.pesos_por_hora` precisa ter 24 valores")
    return problemas


def carregar(caminho: Path | None = None, *, validando: bool = True) -> Config:
    bruto = yaml.safe_load((caminho or ARQUIVO).read_text(encoding="utf-8"))
    periodo = bruto["periodo"]
    escala = bruto["escala"]
    sazonalidade = bruto["sazonalidade"]

    tabelas = {
        nome: Tabela(
            nome=nome,
            referencia=int(spec["referencia"]),
            origem=spec.get("origem", DECLARATIVA),
            min_rows=spec.get("min_rows"),
            motivo=spec.get("motivo"),
            nota=spec.get("nota"),
            momento=spec.get("momento"),
            cobertura_dispensada=spec.get("cobertura_dispensada") or {},
            colunas=spec.get("colunas") or {},
            processo=spec.get("processo") or {},
        )
        for nome, spec in bruto["tabelas"].items()
    }

    config = Config(
        versao=int(bruto["versao"]),
        localidade=bruto["localidade"],
        seed=int(bruto["seed"]),
        as_of_date=periodo["as_of_date"],
        period_start=periodo["period_start"],
        utc_offset_horas=int(periodo["utc_offset_horas"]),
        exclusao_logica=float(bruto["exclusao_logica"]),
        tolerancia_processo=float(bruto["tolerancia_processo"]),
        divisor_da_referencia=int(escala["divisor_da_referencia"]),
        fator_padrao=escala["padrao"],
        fatores={k: float(v) for k, v in escala["fatores"].items()},
        pesos_por_mes=tuple(sazonalidade["pesos_por_mes"]),
        pesos_por_hora=tuple(sazonalidade["pesos_por_hora"]),
        tabelas=tabelas,
    )

    if validando:
        problemas = validar(config)
        _exigir(
            not problemas,
            "configuração inválida — nada foi gerado:\n  - " + "\n  - ".join(problemas),
        )
    return config


@lru_cache(maxsize=1)
def padrao() -> Config:
    """A configuração do repositório, carregada e validada uma vez."""
    return carregar()
