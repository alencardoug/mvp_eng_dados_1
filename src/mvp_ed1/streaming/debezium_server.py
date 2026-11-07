"""O `application.properties` do Debezium Server da fase GCP, **gerado** da declaração do conector.

A fase local registra `streaming/connectors/inventory_movements.yml` no Kafka Connect; a fase GCP
roda o mesmo conector dentro do Debezium Server com *sink* Pub/Sub (ADR-0051). Duas declarações do
mesmo conector divergiriam — por isso a segunda **não existe**: este módulo lê a primeira e escreve
`streaming/debezium_server/application.properties`, e o teste confere que o arquivo está em dia.

O que muda, e só isto (cada item com o porquê ao lado, no arquivo gerado):

* `debezium.source.` na frente de cada chave do conector; as de criação de tópico do Kafka saem;
* a origem é o Cloud SQL, por IP privado e com SSL obrigatório;
* *offsets* num arquivo do disco persistente do *pod*;
* o *sink* Pub/Sub, com JSON sem *schema* no valor, na chave e nos cabeçalhos;
* o envelope achatado e o `occurred_at` como cabeçalho, que o *sink* passa a atributo (D78);
* o tópico de *heartbeat* com nome que o Pub/Sub aceita.

    python -m mvp_ed1.streaming.debezium_server            # reescreve o arquivo
    python -m mvp_ed1.streaming.debezium_server --conferir # sai com erro se estiver desatualizado
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

RAIZ = Path(__file__).resolve().parents[3]
DECLARACAO = RAIZ / "streaming" / "connectors" / "inventory_movements.yml"
ARQUIVO = RAIZ / "streaming" / "debezium_server" / "application.properties"

#: Chaves do conector que só existem para o Kafka Connect criar tópicos.
SO_DO_KAFKA = ("topic.creation.",)

#: O que a fase GCP sobrepõe na declaração do conector, com o motivo.
SOBREPOSTO = {
    "database.hostname": ("${SOURCE_DB_HOST}",
                          "o IP privado do Cloud SQL, entregue ao pod pelo ambiente"),
    "database.sslmode": ("require", "o Cloud SQL exige SSL (A16); o local não usa"),
    # `__debezium-heartbeat` começa com `_`, e nome de tópico do Pub/Sub começa com letra.
    "topic.heartbeat.prefix": ("mvp-heartbeat", "o tópico vira `mvp-heartbeat.mvp`, que o Pub/Sub aceita"),
}

#: O que só o Debezium Server tem: *offsets*, *sink*, formato e transformações (D78).
PROPRIAS: tuple[tuple[str, str, str], ...] = (
    ("debezium.source.offset.storage", "org.apache.kafka.connect.storage.FileOffsetBackingStore",
     "offsets num arquivo: o disco persistente do pod, apagado no desmonte"),
    ("debezium.source.offset.storage.file.filename", "/debezium/data/offsets.dat", ""),
    ("debezium.source.offset.flush.interval.ms", "0", "grava o offset a cada lote confirmado pelo sink"),
    ("debezium.sink.type", "pubsub", "ADR-0051"),
    ("debezium.sink.pubsub.project.id", "${GCP_PROJECT_ID}", ""),
    ("debezium.format.value", "json", ""),
    ("debezium.format.value.schemas.enable", "false", "o evento chega sem o schema do Connect"),
    ("debezium.format.key", "json", ""),
    ("debezium.format.key.schemas.enable", "false", ""),
    ("debezium.format.header.schemas.enable", "false",
     "atributo com o valor cru do cabeçalho, sem aspas de JSON (dbz#2783, 3.7.1.Final)"),
    ("debezium.transforms", "unwrap,tempo", "D78"),
    ("debezium.transforms.unwrap.type", "io.debezium.transforms.ExtractNewRecordState",
     "envelope achatado: o evento no topo"),
    ("debezium.transforms.unwrap.add.fields", "op,lsn",
     "a operação e a posição no WAL ficam como __op e __lsn — o envelope.py recusa u/d por elas"),
    ("debezium.transforms.unwrap.delete.tombstone.handling.mode", "rewrite",
     "um DELETE chega como registro com __deleted, e o pipeline falha nele em vez de não vê-lo"),
    ("debezium.transforms.tempo.type", "org.apache.kafka.connect.transforms.HeaderFrom$Value",
     "o tempo de evento como cabeçalho, que o sink Pub/Sub passa a atributo"),
    ("debezium.transforms.tempo.fields", "occurred_at", ""),
    ("debezium.transforms.tempo.headers", "occurred_at", "o atributo que o Beam lê (fluxo.yml, nuvem)"),
    ("debezium.transforms.tempo.operation", "copy", "o campo continua no evento"),
    ("debezium.transforms.tempo.predicate", "eventos", "só no tópico de eventos: o heartbeat não tem occurred_at"),
    ("debezium.predicates", "eventos", ""),
    ("debezium.predicates.eventos.type", "org.apache.kafka.connect.transforms.predicates.TopicNameMatches", ""),
    ("debezium.predicates.eventos.pattern", r"mvp\\.oltp\\.inventory_movements", ""),
)


def gerar(declaracao: Path = DECLARACAO) -> str:
    bruto = yaml.safe_load(declaracao.read_text(encoding="utf-8"))
    linhas = [
        "# GERADO por `python -m mvp_ed1.streaming.debezium_server` a partir de",
        f"# streaming/connectors/{declaracao.name} — não edite: corrija a declaração ou o gerador.",
        "# `${VAR}` é resolvido do ambiente do pod pelo próprio Debezium Server (MicroProfile Config).",
        "",
        "# ── O conector, como declarado para a fase local ──",
    ]
    config = {k: v for k, v in bruto["config"].items() if not k.startswith(SO_DO_KAFKA)}
    for chave in (*config, *(k for k in SOBREPOSTO if k not in config)):
        if chave in SOBREPOSTO:
            valor, motivo = SOBREPOSTO[chave]
            linhas.append(f"# fase GCP: {motivo}")
        else:
            valor = config[chave]
        linhas.append(f"debezium.source.{chave}={valor}")
    linhas += ["", "# ── O que só o Debezium Server tem (ADR-0051, D78) ──"]
    for chave, valor, motivo in PROPRIAS:
        if motivo:
            linhas.append(f"# {motivo}")
        linhas.append(f"{chave}={valor}")
    return "\n".join(linhas) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.streaming.debezium_server")
    parser.add_argument("--conferir", action="store_true", help="falha se o arquivo estiver desatualizado")
    args = parser.parse_args(argv)
    texto = gerar()
    if args.conferir:
        if not ARQUIVO.exists() or ARQUIVO.read_text(encoding="utf-8") != texto:
            print(f"{ARQUIVO.relative_to(RAIZ)} desatualizado: rode python -m mvp_ed1.streaming.debezium_server",
                  file=sys.stderr)
            return 1
        return 0
    ARQUIVO.parent.mkdir(parents=True, exist_ok=True)
    ARQUIVO.write_text(texto, encoding="utf-8")
    print(f"escrito: {ARQUIVO.relative_to(RAIZ)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
