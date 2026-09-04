"""Aleatoriedade determinística.

O critério de conclusão da Etapa 4 é que a mesma `seed` com a mesma
`as_of_date` produza **exatamente** os mesmos dados. Isso não sobrevive a
`random` global compartilhado: bastaria trocar a ordem de duas chamadas em um
domínio para mudar todos os outros.

Então cada tabela recebe a sua própria fonte, semeada por
`(seed, as_of_date, nome da tabela)`. Domínios ficam independentes: mexer no
gerador de chamados não move um único byte do catálogo.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import random
import uuid
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Sequence

from faker import Faker

_CENTAVO = Decimal("0.01")
_MILESIMO = Decimal("0.0001")


def semente(seed: int, as_of_date: dt.date, nome: str) -> int:
    """Sub-semente estável de 64 bits para um nome, dentro de uma execução."""
    material = f"{seed}|{as_of_date.isoformat()}|{nome}".encode()
    return int.from_bytes(hashlib.blake2b(material, digest_size=8).digest(), "big")


class Fonte:
    """Gerador de valores de uma tabela: números, escolhas, datas e `Faker`.

    O `Faker` é semeado a partir da mesma sub-semente, e não do relógio: sem
    isso o determinismo termina na primeira chamada a um provedor.
    """

    def __init__(self, seed: int, as_of_date: dt.date, nome: str, localidade: str) -> None:
        self.nome = nome
        valor = semente(seed, as_of_date, nome)
        self.rng = random.Random(valor)
        self.faker = Faker(localidade)
        self.faker.seed_instance(valor)

    # ── Números ──────────────────────────────────────────────────────────────
    def inteiro(self, minimo: int, maximo: int) -> int:
        return self.rng.randint(minimo, maximo)

    def decimal(self, minimo: float, maximo: float, casas: int = 2) -> Decimal:
        passo = _CENTAVO if casas == 2 else Decimal(1).scaleb(-casas)
        return Decimal(str(self.rng.uniform(minimo, maximo))).quantize(passo, ROUND_HALF_UP)

    def chance(self, probabilidade: float) -> bool:
        return self.rng.random() < probabilidade

    # ── Escolhas ─────────────────────────────────────────────────────────────
    def escolha(self, opcoes: Sequence[Any]) -> Any:
        return opcoes[self.rng.randrange(len(opcoes))]

    def amostra(self, opcoes: Sequence[Any], k: int) -> list[Any]:
        """`k` elementos distintos; se `k` excede o disponível, devolve tudo."""
        k = min(k, len(opcoes))
        return self.rng.sample(list(opcoes), k)

    def ponderada(self, pesos: dict[Any, float]) -> Any:
        """Escolha por peso relativo.

        Itera sobre `sorted` de propósito: a ordem de inserção de um `dict`
        vindo do YAML é estável, mas ordenar torna o resultado independente da
        ordem em que alguém escreveu as linhas no arquivo.
        """
        itens = sorted(pesos.items(), key=lambda par: str(par[0]))
        valores = [item for item, _ in itens]
        acumulados = []
        total = 0.0
        for _, peso in itens:
            total += float(peso)
            acumulados.append(total)
        alvo = self.rng.random() * total
        for valor, limite in zip(valores, acumulados):
            if alvo < limite:
                return valor
        return valores[-1]

    def indice_ponderado(self, pesos: Sequence[float]) -> int:
        alvo = self.rng.random() * sum(pesos)
        acumulado = 0.0
        for indice, peso in enumerate(pesos):
            acumulado += peso
            if alvo < acumulado:
                return indice
        return len(pesos) - 1

    # ── Identificadores ──────────────────────────────────────────────────────
    def uuid(self) -> uuid.UUID:
        """UUID versão 4 determinístico — derivado da fonte, não do sistema."""
        return uuid.UUID(int=self.rng.getrandbits(128), version=4)


class Relogio:
    """Distribuição temporal dos eventos.

    A sazonalidade não é enfeite: sem ela a dimensão de data não tem o que
    mostrar, e todo teste de tendência do datamart olha para uma reta.
    """

    def __init__(
        self,
        inicio: dt.datetime,
        fim: dt.datetime,
        pesos_por_mes: Sequence[int],
        pesos_por_hora: Sequence[int],
    ) -> None:
        self.inicio = inicio
        self.fim = fim
        self.pesos_por_hora = list(pesos_por_hora)
        self._meses: list[tuple[dt.datetime, dt.datetime]] = []
        self._pesos: list[float] = []

        cursor = inicio.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        while cursor < fim:
            seguinte = (cursor + dt.timedelta(days=32)).replace(day=1)
            janela_inicio = max(cursor, inicio)
            janela_fim = min(seguinte, fim)
            if janela_fim > janela_inicio:
                dias = (janela_fim - janela_inicio).days or 1
                self._meses.append((janela_inicio, janela_fim))
                # Mês parcial pesa proporcionalmente aos dias que tem no período.
                self._pesos.append(pesos_por_mes[cursor.month - 1] * dias / 30.0)
            cursor = seguinte

    def sazonal(self, fonte: Fonte) -> dt.datetime:
        """Momento no período, com peso de mês e de hora do dia."""
        janela_inicio, janela_fim = self._meses[fonte.indice_ponderado(self._pesos)]
        dias = max((janela_fim - janela_inicio).days, 1)
        dia = janela_inicio + dt.timedelta(days=fonte.inteiro(0, dias - 1))
        momento = dia.replace(
            hour=fonte.indice_ponderado(self.pesos_por_hora),
            minute=fonte.inteiro(0, 59),
            second=fonte.inteiro(0, 59),
            microsecond=0,
        )
        return min(max(momento, self.inicio), self.fim)

    def uniforme(self, fonte: Fonte, desde: dt.datetime | None = None) -> dt.datetime:
        """Momento uniforme no período — cadastro, contratação, vigência."""
        desde = desde or self.inicio
        segundos = max(int((self.fim - desde).total_seconds()), 1)
        return desde + dt.timedelta(seconds=fonte.inteiro(0, segundos))

    def depois(
        self, momento: dt.datetime, fonte: Fonte, minimo_h: float, maximo_h: float
    ) -> dt.datetime:
        """Momento posterior, limitado por `as_of_date`.

        O limite não é detalhe: um evento com data futura passa em toda `CHECK`
        de linha e só aparece como absurdo três camadas adiante, no datamart.
        """
        adiante = momento + dt.timedelta(
            seconds=fonte.inteiro(int(minimo_h * 3600), int(maximo_h * 3600))
        )
        return min(adiante, self.fim)


def dinheiro(valor: Decimal | float | int) -> Decimal:
    """Duas casas, meio para cima — o arredondamento comercial do domínio."""
    return Decimal(str(valor)).quantize(_CENTAVO, ROUND_HALF_UP)


def preco(valor: Decimal | float | int) -> Decimal:
    """Quatro casas: preço unitário não é valor transacionado (`CLAUDE.md` §3)."""
    return Decimal(str(valor)).quantize(_MILESIMO, ROUND_HALF_UP)


def repartir(
    total: int, grupos: int, fonte: Fonte, minimo: int = 0, maximo: int | None = None
) -> list[int]:
    """Divide `total` em `grupos` parcelas que somam exatamente `total`.

    É como "110 mil itens em 40 mil carrinhos" vira uma lista de tamanhos sem
    que a soma escorregue: sortear um tamanho por carrinho erra o total por
    construção, e corrigir o erro no fim distorce justamente as últimas linhas.

    Quando o piso não cabe no total — mais grupos do que linhas —, o piso cede:
    a alternativa seria inventar linhas que a configuração não pediu.
    """
    if grupos <= 0:
        return []
    if total <= 0:
        return [0] * grupos
    minimo = min(minimo, total // grupos)
    restante = total - minimo * grupos
    teto = None if maximo is None else max(maximo - minimo, 0)

    pesos = [fonte.rng.random() + 0.15 for _ in range(grupos)]
    soma = sum(pesos)
    parcelas = [int(restante * peso / soma) for peso in pesos]

    # Sobra da divisão inteira, distribuída de forma estável e sem estourar o teto.
    sobra = restante - sum(parcelas)
    indice = 0
    voltas = 0
    while sobra > 0 and voltas < grupos * 4:
        if teto is None or parcelas[indice] < teto:
            parcelas[indice] += 1
            sobra -= 1
        indice = (indice + 1) % grupos
        voltas += 1
    if sobra > 0:  # teto apertado demais: ele cede antes do total.
        parcelas[0] += sobra

    if teto is not None:
        excesso = 0
        for i, parcela in enumerate(parcelas):
            if parcela > teto:
                excesso += parcela - teto
                parcelas[i] = teto
        i = 0
        while excesso > 0 and i < grupos * 4:
            alvo = i % grupos
            if parcelas[alvo] < teto:
                parcelas[alvo] += 1
                excesso -= 1
            i += 1
        if excesso > 0:
            parcelas[0] += excesso
    return [minimo + parcela for parcela in parcelas]


def cobrir(sequencia: list[Any], valores: Sequence[Any]) -> list[Any]:
    """Garante que cada valor apareça ao menos uma vez na sequência.

    O ADR-0014 promete cobertura **em qualquer fator de escala**, e distribuição
    por peso não entrega isso: com 8 linhas e peso 1 em 10, um valor some em
    43% das sementes. Aqui os que faltam entram no lugar dos que sobram — o
    excedente do valor mais frequente —, e a proporção entre os demais fica
    praticamente intacta em qualquer volume que valha a pena medir.
    """
    faltando = [valor for valor in valores if valor not in sequencia]
    if not faltando or len(sequencia) < len(valores):
        return sequencia
    resultado = list(sequencia)
    for posicao, valor in enumerate(faltando):
        frequencias: dict[Any, int] = {}
        for item in resultado:
            frequencias[item] = frequencias.get(item, 0) + 1
        mais_comum = max(sorted(frequencias, key=str), key=lambda k: frequencias[k])
        resultado[resultado.index(mais_comum)] = valor
    return resultado
