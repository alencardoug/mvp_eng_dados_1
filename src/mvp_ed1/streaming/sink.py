"""Destino do caminho quente: uma linha por movimento, imutável e idempotente.

O [ADR-0019](../../../docs/adr/0019-saldo-em-deltas-com-entrega-idempotente.md)
recusou explicitamente a tabela agregada por janela — *"o agregado vira a fonte
da verdade: janela processada errado não tem de onde ser reconstruída"* — e
fixou deltas imutáveis com o saldo como soma. O que se escreve aqui é o evento,
nunca um total.

A garantia é *at-least-once* no transporte e **idempotência no destino**:
`on conflict (movement_id) do nothing`. Reprocessar o mesmo lote não altera uma
linha, e é por isso que refazer o *snapshot* do conector é rotina em vez de
incidente.

O `returning` não é detalhe de implementação. Ele diz **quais** eventos entraram
de fato, e é essa lista que segue para o ramo do saldo — de modo que a
idempotência do destino se torna a fronteira exatamente-uma-vez de tudo que vem
depois, exatamente como o `staging` faz para o caminho frio. Sem ele, uma
duplicata que chegasse fora da janela de deduplicação seria descartada na
tabela e ainda assim somada duas vezes no saldo.

Os tipos espelham os que o Airbyte aterrissa em `raw.inventory_movements`: as
duas tabelas se encontram em `union all` no `staging` (ADR-0031), e união de
tipos divergentes exige conversão em toda consulta ou falha na primeira.
"""

from __future__ import annotations

import datetime as dt
import logging
from typing import Any, Iterable

import apache_beam as beam
import sqlalchemy as sa
from apache_beam.transforms.window import GlobalWindows, TimestampedValue
from apache_beam.utils.timestamp import Timestamp
from sqlalchemy.dialects.postgresql import insert as insert_pg

from mvp_ed1.db import WAREHOUSE, database_url
from mvp_ed1.streaming.config import Destino

LOG = logging.getLogger(__name__)

#: Colunas do contrato do evento (Modelo de Dados §5.1).
COLUNAS_DO_EVENTO = (
    "movement_id", "event_sequence", "idempotency_key", "warehouse_id",
    "product_variant_id", "movement_type", "quantity_delta", "unit_cost",
    "source_type", "source_id", "correlation_id", "causation_id",
    "aggregate_version", "occurred_at", "recorded_at", "schema_version", "metadata",
)


_COMENTARIO = (
    "Caminho quente de inventory_movements: uma linha por movimento, escrita pelo "
    "pipeline Beam. Imutável e idempotente por movement_id (ADR-0019). Aterrissa em "
    "raw porque é ingestão, ao lado da tabela do Airbyte, e as duas se encontram em "
    "staging (ADR-0031)."
)


def tabela(destino: Destino) -> sa.Table:
    """Definição da tabela de deltas, para uso do Core do SQLAlchemy."""
    metadados = sa.MetaData(schema=destino.schema)
    return sa.Table(
        destino.tabela,
        metadados,
        sa.Column("movement_id", sa.String, primary_key=True),
        sa.Column("event_sequence", sa.BigInteger),
        sa.Column("idempotency_key", sa.String),
        sa.Column("warehouse_id", sa.BigInteger),
        sa.Column("product_variant_id", sa.BigInteger),
        sa.Column("movement_type", sa.String),
        sa.Column("quantity_delta", sa.BigInteger),
        sa.Column("unit_cost", sa.Numeric),
        sa.Column("source_type", sa.String),
        sa.Column("source_id", sa.String),
        sa.Column("correlation_id", sa.String),
        sa.Column("causation_id", sa.String),
        sa.Column("aggregate_version", sa.BigInteger),
        sa.Column("occurred_at", sa.DateTime(timezone=True)),
        sa.Column("recorded_at", sa.DateTime(timezone=True)),
        sa.Column("schema_version", sa.BigInteger),
        sa.Column("metadata", sa.String),
        # ── Procedência da entrega ────────────────────────────────────────
        # Prefixo `_stream_` pelo mesmo motivo que o Airbyte usa `_airbyte_`:
        # separar o dado do carimbo de quem o carregou.
        sa.Column("_stream_partition", sa.Integer, nullable=False),
        sa.Column("_stream_offset", sa.BigInteger, nullable=False),
        sa.Column("_stream_lsn", sa.BigInteger),
        sa.Column("_stream_from_snapshot", sa.Boolean, nullable=False),
        sa.Column("_stream_extracted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Index(f"{destino.tabela}_occurred_at_idx", "occurred_at"),
        comment=_COMENTARIO,
    )


def engine() -> sa.Engine:
    return sa.create_engine(database_url(WAREHOUSE), future=True)


def garantir_tabela(destino: Destino, motor: sa.Engine | None = None) -> sa.Table:
    """Cria schema e tabela do caminho quente, se ainda não existirem.

    O `raw` é criado pelo Airbyte, e esta tabela convive com as dele sem
    colisão: o modo `full_refresh_overwrite` derruba as tabelas **do próprio
    Airbyte**, e esta não é uma delas.
    """
    motor = motor or engine()
    alvo = tabela(destino)
    with motor.begin() as conexao:
        conexao.execute(sa.schema.CreateSchema(destino.schema, if_not_exists=True))
        alvo.create(conexao, checkfirst=True)
    return alvo


class GravarEventos(beam.DoFn):
    """Escrita idempotente em lote. Emite só o que **entrou de fato**.

    A diferença entre o que foi tentado e o que entrou é a duplicata, contada em
    métrica. Sem essa contagem a idempotência seria afirmação — e o ADR-0019 já
    avisou que garantia sem teste que injeta duplicata é apenas intenção.
    """

    def __init__(self, destino: Destino, transporte=None):
        self._destino = destino
        self._transporte = transporte
        self._motor: sa.Engine | None = None
        self._tabela: sa.Table | None = None
        self._lote: list[dict[str, Any]] = []
        self._confirmador = None
        # Prefixo contíguo já durável, por partição: o maior offset tal que
        # todos abaixo dele estão gravados. Ver `_confirmar_offsets`.
        self._proximo: dict[int, int] = {}
        self._pendentes: dict[int, set[int]] = {}
        self.gravados = beam.metrics.Metrics.counter("streaming", "eventos_gravados")
        self.duplicados = beam.metrics.Metrics.counter("streaming", "eventos_duplicados")

    def setup(self):
        self._motor = engine()
        self._tabela = garantir_tabela(self._destino, self._motor)
        if self._transporte is not None:
            from mvp_ed1.streaming.transport import consumidor

            self._confirmador = consumidor(self._transporte)

    def process(self, evento: dict[str, Any]) -> Iterable[TimestampedValue]:
        self._lote.append(evento)
        if len(self._lote) >= self._destino.lote_de_escrita:
            for gravado in self._descarregar():
                yield TimestampedValue(gravado, _instante(gravado))

    def finish_bundle(self):
        # ── O tempo de evento precisa sobreviver ao lote ─────────────────────
        # Escrever em lote quebra a correspondência entre elemento de entrada e
        # elemento de saída: o que sai daqui foi acumulado de várias entradas, e
        # herdaria o carimbo de qualquer uma delas. Pior, o que sai de
        # `finish_bundle` não herda carimbo nenhum e vale `MIN_TIMESTAMP`.
        #
        # A consequência era invisível e total: a janela recebia todo evento em
        # 1970, o *watermark* de 2026 já tinha passado dela havia décadas, e a
        # janela inteira era descartada por atraso além do tolerado. Sem erro,
        # sem log, sem alerta — só um ramo do pipeline que não produzia nada.
        #
        # O carimbo é reconstruído do próprio evento, que é onde ele sempre
        # esteve: `occurred_at` é o tempo de negócio, e é por ele que se janela.
        for gravado in self._descarregar():
            yield GlobalWindows.windowed_value(gravado, timestamp=_instante(gravado))

    def teardown(self):
        if self._confirmador is not None:
            self._confirmador.close()
        if self._motor is not None:
            self._motor.dispose()

    def _descarregar(self) -> list[dict[str, Any]]:
        if not self._lote:
            return []
        lote, self._lote = self._lote, []
        agora = dt.datetime.now(dt.timezone.utc)
        linhas = [_linha(evento, agora) for evento in lote]

        comando = (
            insert_pg(self._tabela)
            .on_conflict_do_nothing(index_elements=["movement_id"])
            .returning(self._tabela.c.movement_id)
        )
        with self._motor.begin() as conexao:
            entraram = {chave for (chave,) in conexao.execute(comando, linhas)}

        self._confirmar_offsets(lote)
        self.gravados.inc(len(entraram))
        self.duplicados.inc(len(lote) - len(entraram))
        if len(entraram) != len(lote):
            LOG.info(
                "lote de %s: %s gravados, %s já existiam", len(lote), len(entraram),
                len(lote) - len(entraram),
            )
        return [e for e in lote if e["movement_id"] in entraram]


    def _confirmar_offsets(self, lote: list[dict[str, Any]]) -> None:
        """Confirma no transporte o que já está durável no destino.

        Confirmar o maior offset do lote seria errado: o Beam pode entregar
        pacotes fora de ordem, e um offset alto confirmado antes de um baixo ser
        gravado **pularia** o baixo em um reinício — perda silenciosa, que a
        regra 4 do `CLAUDE.md` proíbe. O que se confirma é o **prefixo
        contíguo**: o maior offset tal que todos abaixo dele já foram gravados.

        Confirmar de menos custa reprocessamento, e reprocessamento aqui não
        custa nada — o destino é idempotente (ADR-0019). Confirmar de mais custa
        um evento perdido. A assimetria decide o desenho.
        """
        if self._confirmador is None:
            return
        from confluent_kafka import TopicPartition

        for evento in lote:
            particao, offset = evento.get("_particao"), evento.get("_offset")
            if particao is None or offset is None or offset < 0:
                continue
            self._pendentes.setdefault(particao, set()).add(offset)
            self._proximo.setdefault(particao, offset)

        posicoes = []
        for particao, pendentes in self._pendentes.items():
            proximo = self._proximo[particao]
            while proximo in pendentes:
                pendentes.discard(proximo)
                proximo += 1
            if proximo != self._proximo[particao]:
                self._proximo[particao] = proximo
                posicoes.append(
                    TopicPartition(self._transporte.topico_de_eventos, particao, proximo)
                )
        if posicoes:
            self._confirmador.commit(offsets=posicoes, asynchronous=False)


def _instante(evento: dict[str, Any]) -> Timestamp:
    """Tempo de evento do movimento — `occurred_at`, nunca o de chegada."""
    return Timestamp.from_utc_datetime(evento["occurred_at"])


def _linha(evento: dict[str, Any], agora: dt.datetime) -> dict[str, Any]:
    linha = {coluna: evento.get(coluna) for coluna in COLUNAS_DO_EVENTO}
    linha.update(
        _stream_partition=evento.get("_particao", 0),
        _stream_offset=evento.get("_offset", -1),
        _stream_lsn=evento.get("_lsn"),
        _stream_from_snapshot=bool(evento.get("_do_snapshot", False)),
        _stream_extracted_at=agora,
    )
    return linha
