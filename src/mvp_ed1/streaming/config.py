"""Carga do artefato declarativo do fluxo de streaming.

Mesmo contrato do gerador: a declaração é lida e **conferida** antes de o
pipeline subir. Janela maior que o atraso tolerado, limiar negativo, tópico sem
nome — tudo isso para aqui, e não trinta segundos depois com um pipeline que já
consumiu offset e não pode voltar atrás.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml

#: A declaração vive fora do pacote, ao lado da do conector: as duas descrevem
#: o mesmo fluxo, e separá-las faria o leitor procurar em dois lugares.
RAIZ = Path(__file__).resolve().parents[3] / "streaming"
ARQUIVO = RAIZ / "fluxo.yml"
CONECTORES = RAIZ / "connectors"


class DeclaracaoInvalida(Exception):
    """Erro na declaração do fluxo. Bloqueia a subida, por desenho."""


@dataclass(frozen=True)
class Transporte:
    bootstrap: str
    topico_de_eventos: str
    topico_de_alertas: str
    grupo_de_consumo: str
    espera_por_mensagem_segundos: float


@dataclass(frozen=True)
class Processamento:
    janela_segundos: int
    atraso_tolerado_segundos: int
    folga_do_watermark_segundos: int


@dataclass(frozen=True)
class Destino:
    schema: str
    tabela: str
    lote_de_escrita: int

    @property
    def qualificado(self) -> str:
        return f"{self.schema}.{self.tabela}"


@dataclass(frozen=True)
class Produtor:
    teto_de_eventos: int
    eventos_por_rajada: tuple[int, int]
    pausa_entre_rajadas_segundos: tuple[float, float]
    fracao_de_eventos_atrasados: float
    atraso_dos_eventos_segundos: tuple[int, int]
    fracao_de_transferencias: float
    fracao_de_duplicatas_no_transporte: float


@dataclass(frozen=True)
class Fluxo:
    transporte: Transporte
    processamento: Processamento
    limiar_de_unidades: int
    destino: Destino
    produtor: Produtor


def _faixa(valor: Any, campo: str) -> tuple[Any, Any]:
    if not isinstance(valor, list) or len(valor) != 2 or valor[0] > valor[1]:
        raise DeclaracaoInvalida(f"{campo}: esperado [minimo, maximo] com minimo <= maximo")
    return (valor[0], valor[1])


def _fracao(valor: Any, campo: str) -> float:
    if not isinstance(valor, (int, float)) or not 0.0 <= valor <= 1.0:
        raise DeclaracaoInvalida(f"{campo}: esperado número entre 0 e 1, veio {valor!r}")
    return float(valor)


@lru_cache(maxsize=1)
def carregar(arquivo: Path = ARQUIVO) -> Fluxo:
    """Lê `streaming/fluxo.yml`, valida e devolve o fluxo declarado."""
    if not arquivo.exists():
        raise DeclaracaoInvalida(f"declaração do fluxo ausente: {arquivo}")
    bruto = yaml.safe_load(arquivo.read_text(encoding="utf-8"))

    faltando = {"transporte", "processamento", "alerta", "destino", "produtor"} - set(bruto)
    if faltando:
        raise DeclaracaoInvalida("seções ausentes em fluxo.yml: " + ", ".join(sorted(faltando)))

    t, p, d, pr = bruto["transporte"], bruto["processamento"], bruto["destino"], bruto["produtor"]

    # O ambiente sobrepõe o endereço do transporte, e só ele: dentro de um
    # contêiner o Redpanda não atende em `localhost`. Janela, atraso e limiar
    # **não** são sobreponíveis por variável — são decisão declarada, e
    # decisão que se muda por variável de ambiente não se revisa.
    bootstrap = os.environ.get("REDPANDA_BOOTSTRAP", t["bootstrap"])

    processamento = Processamento(
        janela_segundos=int(p["janela_segundos"]),
        atraso_tolerado_segundos=int(p["atraso_tolerado_segundos"]),
        folga_do_watermark_segundos=int(p["folga_do_watermark_segundos"]),
    )
    if processamento.janela_segundos <= 0:
        raise DeclaracaoInvalida("processamento.janela_segundos: precisa ser positivo")
    if processamento.atraso_tolerado_segundos < processamento.janela_segundos:
        # Tolerar menos atraso que a própria janela é declarar que evento
        # atrasado nunca reabre janela nenhuma — o caminho que o fluxo existe
        # para exercitar deixaria de ter efeito, em silêncio.
        raise DeclaracaoInvalida(
            "processamento.atraso_tolerado_segundos menor que a janela: "
            "nenhum evento atrasado reabriria janela alguma"
        )

    limiar = int(bruto["alerta"]["limiar_de_unidades"])
    if limiar < 0:
        raise DeclaracaoInvalida("alerta.limiar_de_unidades: não pode ser negativo")

    return Fluxo(
        transporte=Transporte(
            bootstrap=bootstrap,
            topico_de_eventos=t["topico_de_eventos"],
            topico_de_alertas=t["topico_de_alertas"],
            grupo_de_consumo=t["grupo_de_consumo"],
            espera_por_mensagem_segundos=float(t["espera_por_mensagem_segundos"]),
        ),
        processamento=processamento,
        limiar_de_unidades=limiar,
        destino=Destino(
            schema=d["schema"], tabela=d["tabela"], lote_de_escrita=int(d["lote_de_escrita"]),
        ),
        produtor=Produtor(
            teto_de_eventos=int(pr["teto_de_eventos"]),
            eventos_por_rajada=_faixa(pr["eventos_por_rajada"], "produtor.eventos_por_rajada"),
            pausa_entre_rajadas_segundos=_faixa(
                pr["pausa_entre_rajadas_segundos"], "produtor.pausa_entre_rajadas_segundos",
            ),
            fracao_de_eventos_atrasados=_fracao(
                pr["fracao_de_eventos_atrasados"], "produtor.fracao_de_eventos_atrasados",
            ),
            atraso_dos_eventos_segundos=_faixa(
                pr["atraso_dos_eventos_segundos"], "produtor.atraso_dos_eventos_segundos",
            ),
            fracao_de_transferencias=_fracao(
                pr["fracao_de_transferencias"], "produtor.fracao_de_transferencias",
            ),
            fracao_de_duplicatas_no_transporte=_fracao(
                pr["fracao_de_duplicatas_no_transporte"],
                "produtor.fracao_de_duplicatas_no_transporte",
            ),
        ),
    )
