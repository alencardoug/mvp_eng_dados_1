"""O caminho quente na fase GCP (Etapa 13, G2.3): Pub/Sub na entrada e no alerta, BigQuery no destino.

O grafo é o mesmo do `pipeline.construir` — deduplicação, janela por tempo de
evento, saldo e alerta —, e só três pontos trocam de meio: a **leitura** (o
Pub/Sub, com o tempo de evento no atributo `occurred_at` — D78), a **escrita**
dos deltas e a **publicação** do alerta. A semente do saldo lê o BigQuery.

**A idempotência do destino (D75).** O PostgreSQL decide numa instrução só o que
entrou (`on conflict do nothing returning`). O BigQuery não tem `returning`, e
duas transações que só acrescentam rodam em paralelo — a transação sozinha não é
exclusão mútua. O contrato da D75 se cumpre assim:

* **(i) uma chave, um escritor de cada vez.** Cada evento vai para um fragmento
  fixo pelo `crc32` do `movement_id`, e a escrita de um fragmento é um lote por
  vez (`GroupIntoBatches` é um passo com estado por chave, e o Beam processa uma
  chave de cada vez). Duas decisões de inserir o mesmo movimento nunca correm
  juntas; fragmentos diferentes nunca disputam a mesma chave.
* **o que entrou é lido, não suposto.** O lote vai num `MERGE` só (inserir onde
  não casa), com o mesmo `_stream_extracted_at` em todas as linhas; o que entrou
  são as chaves do lote com esse instante. Tem de bater com as linhas afetadas
  pelo *job*, ou a escrita para.
* **(ii) reexecução não alerta duas vezes.** Um lote reexecutado acha as linhas
  gravadas da primeira vez e não as devolve: o alerta sai, no máximo, uma vez — a
  mesma propriedade do `returning` local.
* **(iii) resposta perdida.** A DML passa por `legacy.armazem.BigQuery.dml`: o
  *job* é procurado pelo id, nunca reenviado às cegas.

`insertId` e a deduplicação do Dataflow **não** são a garantia (ADR-0051).
"""

from __future__ import annotations

import datetime as dt
import json
import logging
import os
import zlib
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any, Iterable

import apache_beam as beam
from apache_beam.transforms.window import TimestampedValue

from mvp_ed1.legacy.armazem import BigQuery, ErroDoJob, Struct
from mvp_ed1.streaming.config import Destino, Fluxo, Nuvem
from mvp_ed1.streaming.envelope import decodificar
from mvp_ed1.streaming.sink import _instante

LOG = logging.getLogger(__name__)

#: Tentativas de um lote cujo *job* terminou com erro (nada gravado): o `MERGE` é
#: idempotente, e o mesmo instante faz a releitura ver só o que este lote gravou.
TENTATIVAS_DO_LOTE = 3

#: As colunas do destino e o tipo de cada uma no BigQuery — as de `sink.tabela`.
COLUNAS: tuple[tuple[str, str], ...] = (
    ("movement_id", "STRING"), ("event_sequence", "INT64"), ("idempotency_key", "STRING"),
    ("warehouse_id", "INT64"), ("product_variant_id", "INT64"), ("movement_type", "STRING"),
    ("quantity_delta", "INT64"), ("unit_cost", "NUMERIC"), ("source_type", "STRING"),
    ("source_id", "STRING"), ("correlation_id", "STRING"), ("causation_id", "STRING"),
    ("aggregate_version", "INT64"), ("occurred_at", "TIMESTAMP"), ("recorded_at", "TIMESTAMP"),
    ("schema_version", "INT64"), ("metadata", "STRING"),
    # Procedência. O Pub/Sub não tem partição nem posição: as duas ficam nulas na nuvem.
    ("_stream_partition", "INT64"), ("_stream_offset", "INT64"), ("_stream_lsn", "INT64"),
    ("_stream_from_snapshot", "BOOL"), ("_stream_extracted_at", "TIMESTAMP"),
)

_OBRIGATORIAS = {"movement_id", "_stream_from_snapshot", "_stream_extracted_at"}


@dataclass(frozen=True)
class Projeto:
    """O projeto e a região, lidos **de quem constrói** o *pipeline* e levados dentro das peças.

    No Dataflow as peças rodam no *worker*, que não tem o `.env` nem variável nenhuma do
    lançador: lê-las do ambiente lá derrubaria o *pipeline* no primeiro evento. A prova local
    (§19 do registro) não podia mostrar isso — o executor local roda no processo que as tem.
    """

    projeto: str
    local: str

    @classmethod
    def do_ambiente(cls, environ: Mapping[str, str] | None = None) -> "Projeto":
        env = os.environ if environ is None else environ
        return cls(env["GCP_PROJECT_ID"], env["GCP_BQ_LOCATION"])


def armazem(projeto: Projeto | None = None) -> BigQuery:
    """O BigQuery do projeto (o do `.env`, sem argumento). Sem coordenador: a escrita aqui não toma *lock*."""
    from google.cloud import bigquery

    p = projeto or Projeto.do_ambiente()
    return BigQuery(bigquery.Client(project=p.projeto, location=p.local), p.projeto, coordenador=None, local=p.local)


def ddl(bq: BigQuery, destino: Destino) -> str:
    colunas = ",\n    ".join(
        f"{nome} {tipo}{' not null' if nome in _OBRIGATORIAS else ''}" for nome, tipo in COLUNAS
    )
    return (
        f"create table if not exists {bq.tabela(destino.qualificado)} (\n    {colunas}\n)\n"
        "cluster by movement_id\n"
        "options (description = 'Caminho quente de inventory_movements na fase GCP: uma linha por "
        "movimento, escrita pelo pipeline Beam. Imutável e idempotente por movement_id (ADR-0019, D75).')"
    )


def garantir_tabela(bq: BigQuery, destino: Destino) -> None:
    """Cria a tabela se ela não existe — e só pergunta, se existe.

    No Dataflow quem chega aqui é o `streamer`, que tem IAM **da tabela**, não do *dataset*
    (`terraform/dataflow.tf`: ele escreve uma tabela só, "nada mais"): ler os metadados ele pode,
    criar no *dataset* não. Por isso o lançador a cria antes, com a ADC do Owner
    (`mvp_ed1.streaming.dataflow`), e aqui o `get_table` basta.
    """
    from google.api_core.exceptions import NotFound

    try:
        # O mesmo nome do DDL, com o `renomear` do armazém (o *dataset* temporário das provas).
        bq.cliente.get_table(bq.tabela(destino.qualificado).split("`")[1])
        return
    except NotFound:
        pass
    bq.cliente.query(ddl(bq, destino), location=bq.local).result()


def fragmento(movement_id: str, fragmentos: int) -> int:
    """Estável entre processos — o `hash` do Python não é (muda a cada interpretador)."""
    return zlib.crc32(movement_id.encode("utf-8")) % fragmentos


def _linha(evento: dict[str, Any], agora: dt.datetime) -> Struct:
    valores = {nome: evento.get(nome) for nome, _ in COLUNAS[:17]}
    valores.update({
        "_stream_partition": None, "_stream_offset": None, "_stream_lsn": evento.get("_lsn"),
        "_stream_from_snapshot": bool(evento.get("_do_snapshot")), "_stream_extracted_at": agora,
    })
    return Struct({nome: (tipo, valores[nome]) for nome, tipo in COLUNAS})


def escrever_lote(bq: BigQuery, destino: Destino, eventos: list[dict[str, Any]],
                  agora: dt.datetime | None = None) -> tuple[list[dict[str, Any]], int]:
    """Grava o lote e devolve `(o que entrou, duplicatas)` — a regra da D75 sem o Beam em volta."""
    unicos: dict[str, dict[str, Any]] = {}
    for evento in eventos:
        unicos.setdefault(evento["movement_id"], evento)
    if not unicos:
        return [], 0
    agora = agora or dt.datetime.now(dt.timezone.utc)
    nomes = ", ".join(nome for nome, _ in COLUNAS)
    alvo = bq.tabela(destino.qualificado)
    sql = (
        f"merge {alvo} t using unnest(:linhas) n on t.movement_id = n.movement_id "
        f"when not matched then insert ({nomes}) values ({', '.join('n.' + n for n, _ in COLUNAS)})"
    )
    parametros = {"linhas": [_linha(e, agora) for e in unicos.values()]}
    for tentativa in range(1, TENTATIVAS_DO_LOTE + 1):
        try:
            afetadas = bq.dml(sql, parametros, rotulo="caminho_quente")
            break
        except ErroDoJob:
            if tentativa == TENTATIVAS_DO_LOTE:
                raise
            LOG.warning("lote de %s: job com erro, tentativa %s de %s", len(unicos), tentativa, TENTATIVAS_DO_LOTE)
    entraram = {linha["movement_id"] for linha in bq.linhas(
        f"select movement_id from {alvo} where _stream_extracted_at = :agora and movement_id in unnest(:ids)",
        {"agora": agora, "ids": list(unicos)},
    )}
    if len(entraram) != afetadas:
        # Ou o job disse uma coisa e a tabela outra, ou alguém gravou com o mesmo instante.
        raise RuntimeError(f"lote de {len(unicos)}: o job afetou {afetadas} linhas e a releitura achou "
                           f"{len(entraram)} — o que entrou não se sabe, e o alerta não sai")
    return [e for chave, e in unicos.items() if chave in entraram], len(eventos) - len(entraram)


class GravarEventos(beam.DoFn):
    """O ramo 1 na nuvem: recebe `(fragmento, lote)` e emite só o que entrou, no tempo do evento."""

    def __init__(self, destino: Destino, projeto: Projeto):
        self._destino = destino
        self._projeto = projeto
        self._bq: BigQuery | None = None
        self.gravados = beam.metrics.Metrics.counter("streaming", "eventos_gravados")
        self.duplicados = beam.metrics.Metrics.counter("streaming", "eventos_duplicados")

    def setup(self):
        self._bq = armazem(self._projeto)
        garantir_tabela(self._bq, self._destino)

    def teardown(self):
        if self._bq is not None:
            self._bq.dispose()

    def process(self, elemento: tuple[int, Iterable[dict[str, Any]]]) -> Iterable[TimestampedValue]:
        _, lote = elemento
        entraram, duplicados = escrever_lote(self._bq, self._destino, list(lote))
        self.gravados.inc(len(entraram))
        self.duplicados.inc(duplicados)
        for evento in entraram:
            yield TimestampedValue(evento, _instante(evento))


def semente(bq: BigQuery, destino: Destino, inicio: dt.datetime) -> list[tuple[int, int, int]]:
    """O saldo durável antes de `inicio` — o instante em que o *pipeline* foi construído (D62)."""
    linhas = bq.linhas(
        f"select warehouse_id, product_variant_id, sum(quantity_delta) as s from {bq.tabela(destino.qualificado)} "
        "where _stream_extracted_at < :inicio group by 1, 2",
        {"inicio": inicio},
    )
    return [(l["warehouse_id"], l["product_variant_id"], l["s"]) for l in linhas]


class Semear:
    """A semente como chamável serializável, para o `AcumularSaldoEAlertar` rodar no *worker*."""

    def __init__(self, destino: Destino, projeto: Projeto):
        self._destino = destino
        self._projeto = projeto

    def __call__(self, inicio: dt.datetime):
        bq = armazem(self._projeto)
        try:
            garantir_tabela(bq, self._destino)
            return semente(bq, self._destino, inicio)
        finally:
            bq.dispose()


class PublicarAlerta(beam.DoFn):
    """O alerta no tópico do Pub/Sub, com a mesma forma do Kafka local; confirmado antes do fim do pacote."""

    def __init__(self, nuvem: Nuvem, projeto: Projeto):
        self._nuvem = nuvem
        self._projeto = projeto
        self._editor = None
        self._topico = None
        self._pendentes: list = []

    def setup(self):
        from google.cloud import pubsub_v1

        self._editor = pubsub_v1.PublisherClient()
        self._topico = self._editor.topic_path(self._projeto.projeto, self._nuvem.topico_de_alertas)

    def process(self, alerta: dict[str, Any]):
        self._pendentes.append(self._editor.publish(
            self._topico,
            json.dumps(alerta, ensure_ascii=False, default=str).encode(),
            chave=f"{alerta['warehouse_id']}:{alerta['product_variant_id']}",
        ))
        yield alerta

    def finish_bundle(self):
        # O pacote só termina com cada alerta aceito pelo Pub/Sub: um alerta perdido
        # aqui seria silencioso, e o ramo de alerta existe para não ser.
        pendentes, self._pendentes = self._pendentes, []
        for futuro in pendentes:
            futuro.result(timeout=60)


def decodificar_mensagem(mensagem) -> dict[str, Any]:
    """`PubsubMessage` → evento; sem partição nem posição, que o Pub/Sub não tem."""
    evento = decodificar(mensagem.data)
    evento["_particao"], evento["_offset"] = None, None
    return evento


class LerDoPubSub(beam.PTransform):
    """A assinatura `beam`, com o tempo de evento lido do atributo declarado (D78)."""

    def __init__(self, nuvem: Nuvem, projeto: str):
        super().__init__()
        self._nuvem = nuvem
        self._projeto = projeto

    def expand(self, inicio):
        return (
            inicio
            | "LerPubSub" >> beam.io.ReadFromPubSub(
                subscription=f"projects/{self._projeto}/subscriptions/{self._nuvem.assinatura_de_eventos}",
                with_attributes=True,
                timestamp_attribute=self._nuvem.atributo_de_tempo,
            )
            | "Decodificar" >> beam.Map(decodificar_mensagem)
        )


class GravarNaNuvem(beam.PTransform):
    """Fragmento fixo por `movement_id`, lote por fragmento, `MERGE` por lote (D75)."""

    def __init__(self, fluxo: Fluxo, projeto: Projeto):
        super().__init__()
        self._fluxo = fluxo
        self._projeto = projeto

    def expand(self, eventos):
        nuvem = self._fluxo.nuvem
        return (
            eventos
            | "Fragmentar" >> beam.Map(
                lambda e, n=nuvem.fragmentos_de_escrita: (fragmento(e["movement_id"], n), e)
            ).with_output_types(tuple[int, dict[str, Any]])
            | "LotePorFragmento" >> beam.GroupIntoBatches(
                self._fluxo.destino.lote_de_escrita,
                max_buffering_duration_secs=nuvem.espera_maxima_do_lote_segundos,
            )
            | "GravarNoBigQuery" >> beam.ParDo(GravarEventos(self._fluxo.destino, self._projeto))
        )
