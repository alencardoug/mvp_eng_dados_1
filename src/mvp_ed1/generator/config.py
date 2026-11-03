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

from mvp_ed1.generator import enums, pricing

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

    @property
    def arvore(self) -> dict[str, dict[str, list[str]]] | None:
        """A árvore declarada — raiz › intermediária › folhas —, quando a tabela é uma."""
        return self.processo.get("arvore")


def nos_da_arvore(arvore: dict[str, dict[str, list[str]]]) -> list[tuple[str, int, str | None]]:
    """`(nome, profundidade, pai)` de cada nó, nível a nível e na ordem declarada.

    Nível a nível, e não em profundidade, para que os identificadores sigam a
    ordem de sempre: as raízes primeiro, depois as intermediárias, as folhas
    por último.
    """
    raizes = [(raiz, 0, None) for raiz in arvore]
    meios = [(meio, 1, raiz) for raiz, filhos in arvore.items() for meio in filhos]
    folhas = [
        (folha, 2, meio) for filhos in arvore.values() for meio, netas in filhos.items() for folha in netas
    ]
    return raizes + meios + folhas


def folhas_da_arvore(arvore: dict[str, dict[str, list[str]]]) -> list[str]:
    return [nome for nome, profundidade, _ in nos_da_arvore(arvore) if profundidade == 2]


def _validar_arvore(t: Tabela) -> list[str]:
    """Três níveis, nomes únicos, e o piso igual ao tamanho — a contagem é a árvore."""
    arvore = t.arvore
    if not isinstance(arvore, dict) or not arvore:
        return [f"{t.nome}: `arvore` precisa ser um mapa não vazio de raízes"]
    problemas: list[str] = []
    for raiz, filhos in arvore.items():
        if not isinstance(filhos, dict) or not filhos:
            problemas.append(f"{t.nome}: a raiz {raiz!r} precisa de intermediárias")
            continue
        for meio, folhas in filhos.items():
            if not isinstance(folhas, list) or not folhas or not all(isinstance(f, str) and f.strip() for f in folhas):
                problemas.append(f"{t.nome}: a intermediária {meio!r} precisa de uma lista de folhas com nome")
    if problemas:
        return problemas
    nomes = [nome for nome, _, _ in nos_da_arvore(arvore)]
    repetidos = sorted({nome for nome in nomes if nomes.count(nome) > 1})
    if repetidos:
        problemas.append(f"{t.nome}: nomes repetidos na árvore: {repetidos}")
    if t.min_rows != len(nomes):
        problemas.append(
            f"{t.nome}: `min_rows` é {t.min_rows}, e a árvore tem {len(nomes)} nós — a contagem é a árvore"
        )
    return problemas


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
        if t.arvore is not None:
            # A árvore não escala: crescer o catálogo seria inventar categorias
            # que ninguém declarou, ou repetir nomes com sufixo.
            return len(nos_da_arvore(t.arvore))
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
    if t.arvore is not None:
        problemas.extend(_validar_arvore(t))

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


def _validar_faixas_por_folha(config: Config) -> list[str]:
    """Uma faixa de preço por folha da árvore, nem mais nem menos, e larga o bastante."""
    categorias = config.tabelas.get("product_categories")
    variantes = config.tabelas.get("product_variants")
    if categorias is None or variantes is None or categorias.arvore is None:
        return []
    faixas = variantes.processo.get("faixa_de_preco_por_folha")
    if not isinstance(faixas, dict):
        return ["product_variants: `faixa_de_preco_por_folha` precisa declarar a faixa de cada folha"]
    folhas = folhas_da_arvore(categorias.arvore)
    problemas: list[str] = []
    if sem_faixa := sorted(set(folhas) - set(faixas)):
        problemas.append(f"product_variants: folhas sem faixa de preço: {sem_faixa}")
    if sem_folha := sorted(set(faixas) - set(folhas)):
        problemas.append(f"product_variants: faixa de preço para o que não é folha da árvore: {sem_folha}")
    for folha, faixa in faixas.items():
        if not (isinstance(faixa, list) and len(faixa) == 2 and all(isinstance(v, (int, float)) for v in faixa)):
            problemas.append(f"product_variants: a faixa de {folha!r} precisa ser [mínimo, máximo]")
            continue
        try:
            pricing.base_range(float(faixa[0]), float(faixa[1]))
        except ValueError as erro:
            problemas.append(f"product_variants: {folha!r}: {erro}")
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
    problemas.extend(_validar_faixas_por_folha(config))

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
