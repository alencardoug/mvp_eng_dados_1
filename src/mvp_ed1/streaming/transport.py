"""A ponta de leitura e a de alerta — o que troca entre a fase local e o GCP.

O [Streaming §2](../../../docs/streaming.md) declara o critério: *"trocam-se as
pontas — origem e destino —, não a lógica"*. Este módulo é a ponta de origem
local. No Dataflow ele é substituído por `ReadFromPubSub`, e o `pipeline.py`
não muda uma linha.

**Limite honesto.** O `ReadFromKafka` que o Beam oferece é transformação
*cross-language*: exige serviço de expansão Java na construção e um *harness*
Java em contêiner na execução. A máquina da fase local não tem Java, e somar
dois contêineres Java ao Redpanda e ao Kafka Connect não cabe em 4 CPUs. A
leitura aqui é, então, um `DoFn` divisível não-limitado escrito em Python sobre
o cliente Kafka — mesma semântica (restrição por partição, avanço por *offset*,
*watermark* estimado), outra implementação. Está registrado no
[ADR-0031](../../../docs/adr/0031-aterrissagem-do-caminho-quente-em-raw.md).
"""

from __future__ import annotations

import logging
from typing import Any, Iterable

import apache_beam as beam
from apache_beam.io.restriction_trackers import OffsetRange, OffsetRestrictionTracker
from apache_beam.io.watermark_estimators import ManualWatermarkEstimator
from apache_beam.transforms.core import RestrictionProvider
from apache_beam.transforms.window import TimestampedValue
from apache_beam.utils.timestamp import Duration, Timestamp

from mvp_ed1.streaming import envelope
from mvp_ed1.streaming.config import Transporte

LOG = logging.getLogger(__name__)

#: Fim aberto da restrição. Fluxo não tem última mensagem; o número existe só
#: porque `OffsetRange` exige um limite superior.
_SEM_FIM = 2**53


def consumidor(transporte: Transporte, *, grupo: str | None = None, **extras: Any):
    """Cria um consumidor do transporte com a configuração do fluxo."""
    from confluent_kafka import Consumer

    return Consumer(
        {
            "bootstrap.servers": transporte.bootstrap,
            "group.id": grupo or transporte.grupo_de_consumo,
            # O pipeline **não** confia no offset do grupo para garantir
            # entrega: quem garante é a idempotência do destino (ADR-0019). O
            # offset é otimização — evita reler o que já foi lido —, e por isso
            # o commit é manual, depois da escrita.
            "enable.auto.commit": False,
            "auto.offset.reset": "earliest",
            **extras,
        }
    )


def particoes(transporte: Transporte) -> list[int]:
    """Partições do tópico de eventos, descobertas no transporte."""
    c = consumidor(transporte, grupo=f"{transporte.grupo_de_consumo}_metadados")
    try:
        metadados = c.list_topics(transporte.topico_de_eventos, timeout=15.0)
        topico = metadados.topics.get(transporte.topico_de_eventos)
        if topico is None or topico.error is not None:
            raise RuntimeError(
                f"tópico {transporte.topico_de_eventos!r} não existe no transporte. "
                "O conector Debezium o cria na primeira captura: rode 'make stream-connector'."
            )
        return sorted(topico.partitions)
    finally:
        c.close()


class _PosicaoNaParticao(OffsetRestrictionTracker):
    """Rastreador de offset que aceita autocheckpoint, mas recusa divisão.

    O runner tentou dividir a partição ao meio para paralelizar, e o meio de um
    intervalo aberto é um número sem significado: o offset 4.503.599.627.377.368
    não existe, e o leitor foi mandado reivindicar a posição 0 dentro dele.

    Partição de log não se divide — quem lê o offset 10 precisa ter lido o 9. A
    única divisão legítima é a de fração zero, que não é paralelismo e sim o
    autocheckpoint: "parei aqui, o resto fica para a próxima invocação". É ela
    que `defer_remainder` usa para devolver o controle ao runner entre rajadas.
    """

    def try_split(self, fracao_do_restante):
        if fracao_do_restante != 0:
            return None
        return super().try_split(0)

    def is_bounded(self) -> bool:
        return False


def _elevar(estimador, alvo: Timestamp) -> None:
    """Move o *watermark* para frente, nunca para trás.

    O estimador nasce sem marca — `current_watermark()` devolve `None` até a
    primeira chamada —, e um *watermark* que retrocedesse reabriria janela já
    fechada fora do caminho de atraso, que é justamente o que o *allowed
    lateness* existe para controlar.
    """
    atual = estimador.current_watermark()
    if atual is None or alvo > atual:
        estimador.set_watermark(alvo)


class _LerParticao(beam.DoFn, RestrictionProvider):
    """`DoFn` divisível não-limitado: uma partição, avançando por offset.

    O *watermark* é estimado por atraso limitado: o maior tempo de evento já
    visto, menos a folga declarada. É a afirmação "não espero mais nada
    anterior a isto" — e é ela, não o relógio, que fecha as janelas.

    O provedor de restrição vive na própria classe, e não em um objeto à parte,
    porque o Beam avalia os parâmetros de `process` na definição da classe: um
    provedor separado não teria como receber o endereço do transporte.
    """

    #: Sondagens vazias seguidas antes de declarar a partição ociosa. Adiar na
    #: primeira faria uma invocação por segundo mesmo com fila cheia: logo
    #: depois de `assign` o consumidor ainda está buscando, e a primeira
    #: sondagem volta vazia por latência, não por falta de dado.
    SONDAGENS_ATE_OCIOSO = 3

    def __init__(self, transporte: Transporte, folga_segundos: int):
        self._transporte = transporte
        self._folga = folga_segundos

    # ── Restrição: do offset confirmado ao infinito ─────────────────────────
    def initial_restriction(self, particao: int) -> OffsetRange:
        from confluent_kafka import OFFSET_INVALID, TopicPartition

        c = consumidor(self._transporte)
        try:
            alvo = TopicPartition(self._transporte.topico_de_eventos, particao)
            (confirmado,) = c.committed([alvo], timeout=15.0)
            offset = confirmado.offset
            inicio = 0 if offset is None or offset == OFFSET_INVALID or offset < 0 else offset
        finally:
            c.close()
        LOG.info("partição %s: retomando do offset %s", particao, inicio)
        return OffsetRange(inicio, _SEM_FIM)

    def create_tracker(self, restricao: OffsetRange) -> _PosicaoNaParticao:
        return _PosicaoNaParticao(restricao)

    def restriction_size(self, particao: int, restricao: OffsetRange) -> int:
        # Fluxo aberto não tem tamanho. Devolver a distância até `_SEM_FIM`
        # faria o runner acreditar em quatrilhões de elementos pendentes.
        return 1

    def split(self, particao: int, restricao: OffsetRange):
        # Uma partição, um leitor. Devolver a restrição inteira é o que diz ao
        # runner que não há divisão inicial a fazer.
        yield restricao

    def truncate(self, particao: int, restricao: OffsetRange):
        # Drenagem: fluxo aberto não drena, prossegue. Devolver `None` diria ao
        # runner que a partição acabou — e ela não acaba.
        return restricao

    @beam.DoFn.unbounded_per_element()
    def process(
        self,
        particao: int,
        tracker=beam.DoFn.RestrictionParam(),
        estimador=beam.DoFn.WatermarkEstimatorParam(
            ManualWatermarkEstimator.default_provider()
        ),
    ) -> Iterable[TimestampedValue]:
        from confluent_kafka import TopicPartition

        restricao = tracker.current_restriction()
        # ── Um leitor por restrição, nunca um por `DoFn` ────────────────────
        # O runner executa pacotes em paralelo sobre a **mesma instância** do
        # `DoFn`. Um consumidor criado em `setup` seria compartilhado por
        # invocações concorrentes, e o `assign` de uma reposicionaria a outra:
        # o leitor saltava de offset sem que nada acusasse. O leitor pertence à
        # restrição, e vive o tempo dela.
        leitor = consumidor(self._transporte)
        try:
            leitor.assign(
                [TopicPartition(self._transporte.topico_de_eventos, particao, restricao.start)]
            )
            yield from self._consumir(leitor, particao, tracker, estimador)
        finally:
            leitor.close()

    def _consumir(self, leitor, particao, tracker, estimador):
        maior_tempo_de_evento = None
        vazias = 0
        while True:
            mensagem = leitor.poll(self._transporte.espera_por_mensagem_segundos)

            if mensagem is None:
                vazias += 1
                if vazias < self.SONDAGENS_ATE_OCIOSO:
                    continue
                # Partição ociosa. Sem isto o *watermark* congela no último
                # evento e a janela final nunca fecha — o alerta de um SKU
                # ficaria preso esperando um evento que não vem. Avançar até
                # "agora menos a folga" é o tratamento padrão de partição
                # ociosa, e é o que torna o fim de uma rajada observável.
                self._avancar_por_ociosidade(estimador)
                tracker.defer_remainder(Duration(seconds=1))
                return

            vazias = 0
            if mensagem.error():
                raise RuntimeError(f"erro do transporte na partição {particao}: {mensagem.error()}")

            if not tracker.try_claim(mensagem.offset()):
                # O runner fez checkpoint: o resto da partição volta em outra
                # invocação, a partir do offset seguinte.
                return

            valor = mensagem.value()
            if valor is None:
                # Lápide de `DELETE`. O conector é configurado com
                # `tombstones.on.delete=false`, então isto não deveria existir;
                # se existe, a configuração do conector divergiu do versionado.
                raise envelope.ContratoViolado(
                    f"lápide recebida no offset {mensagem.offset()}: o conector foi "
                    "reconfigurado fora do arquivo versionado."
                )

            evento = envelope.decodificar(valor)
            evento["_offset"] = mensagem.offset()
            evento["_particao"] = particao

            instante = Timestamp.from_utc_datetime(evento["occurred_at"])
            if maior_tempo_de_evento is None or instante > maior_tempo_de_evento:
                maior_tempo_de_evento = instante
                _elevar(estimador, instante - Duration(seconds=self._folga))

            yield TimestampedValue(evento, instante)

    def _avancar_por_ociosidade(self, estimador) -> None:
        _elevar(estimador, Timestamp.now() - Duration(seconds=self._folga))


class LerDoTransporte(beam.PTransform):
    """Lê o tópico de eventos como coleção não-limitada, com tempo de evento."""

    def __init__(self, transporte: Transporte, folga_do_watermark_segundos: int):
        super().__init__()
        self._transporte = transporte
        self._folga = folga_do_watermark_segundos

    def expand(self, inicio):
        return (
            inicio
            | "Particoes" >> beam.Create(particoes(self._transporte))
            | "Ler" >> beam.ParDo(_LerParticao(self._transporte, self._folga))
        )


class PublicarAlerta(beam.DoFn):
    """Emite o alerta no tópico separado (Streaming §5).

    Publicar e não gravar: alerta é sinal para outro sistema — um webhook, um
    painel, uma reposição —, não linha de dado. O ponto de extensão fica no
    tópico, e o MVP só precisa que o evento seja emitido, registrado e testado.
    """

    def __init__(self, transporte: Transporte):
        self._transporte = transporte
        self._produtor = None

    def setup(self):
        from confluent_kafka import Producer

        self._produtor = Producer({"bootstrap.servers": self._transporte.bootstrap})

    def teardown(self):
        if self._produtor is not None:
            self._produtor.flush(10)

    def process(self, alerta: dict[str, Any]):
        import json

        self._produtor.produce(
            self._transporte.topico_de_alertas,
            key=f"{alerta['warehouse_id']}:{alerta['product_variant_id']}".encode(),
            value=json.dumps(alerta, ensure_ascii=False, default=str).encode(),
        )
        self._produtor.poll(0)
        yield alerta
