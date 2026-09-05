"""Interface de linha de comando do caminho quente.

Os verbos que o `Makefile` chama. Nenhum deles decide nada: janela, atraso,
limiar e modo de *snapshot* estão nos arquivos declarativos de `streaming/`, e
mudá-los é editar a declaração, que é o que se revisa.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import logging
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

import yaml

from mvp_ed1.streaming import config as cfg

LOG = logging.getLogger("streaming")

CONNECT_URL = os.environ.get("KAFKA_CONNECT_URL", "http://localhost:8083")

_VARIAVEL = re.compile(r"\$\{([A-Z_][A-Z0-9_]*)\}")


# ── Conector ────────────────────────────────────────────────────────────────
def _resolver(valor: Any) -> Any:
    """Substitui `${VAR}` pelo ambiente. Falta de variável é erro, não vazio."""
    if not isinstance(valor, str):
        return valor

    def troca(m: re.Match) -> str:
        nome = m.group(1)
        if nome not in os.environ:
            raise SystemExit(
                f"ERRO: variável {nome} ausente do ambiente, exigida por "
                "streaming/connectors/. Use os alvos do Makefile, que carregam o .env."
            )
        return os.environ[nome]

    return _VARIAVEL.sub(troca, valor)


def declaracao_do_conector(caminho: Path) -> dict[str, Any]:
    bruto = yaml.safe_load(caminho.read_text(encoding="utf-8"))
    return {"name": bruto["name"], "config": {k: _resolver(v) for k, v in bruto["config"].items()}}


def _connect(metodo: str, rota: str, corpo: Any = None) -> Any:
    dados = json.dumps(corpo).encode() if corpo is not None else None
    req = urllib.request.Request(
        f"{CONNECT_URL}{rota}", data=dados, method=metodo,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            texto = r.read().decode()
            return json.loads(texto) if texto else None
    except urllib.error.HTTPError as e:
        detalhe = e.read().decode()
        raise SystemExit(f"ERRO {e.code} do Kafka Connect em {metodo} {rota}: {detalhe}") from None
    except urllib.error.URLError as e:
        raise SystemExit(
            f"ERRO: Kafka Connect não responde em {CONNECT_URL} ({e.reason}). "
            "Rode 'make stream-up'."
        ) from None


def comando_conector(args) -> int:
    """Aplica todas as declarações de `streaming/connectors/`.

    `PUT .../config` é criar-ou-atualizar: aplicar duas vezes não duplica nem
    reinicia o que já está correto. É o que o ADR-0020 foi buscar no Kafka
    Connect — reconfigurar sem derrubar.
    """
    for caminho in sorted(cfg.CONECTORES.glob("*.yml")):
        declaracao = declaracao_do_conector(caminho)
        nome = declaracao["name"]
        _connect("PUT", f"/connectors/{nome}/config", declaracao["config"])
        print(f"conector {nome!r} aplicado a partir de {caminho.name}")
    return 0


def comando_status(args) -> int:
    conectores = _connect("GET", "/connectors") or []
    if not conectores:
        print("nenhum conector registrado. Rode 'make stream-connector'.")
        return 1
    falhou = False
    for nome in conectores:
        estado = _connect("GET", f"/connectors/{nome}/status")
        conector = estado["connector"]["state"]
        print(f"{nome}: conector={conector}")
        for tarefa in estado.get("tasks", []):
            print(f"  tarefa {tarefa['id']}: {tarefa['state']}")
            if tarefa["state"] == "FAILED":
                falhou = True
                print("    " + (tarefa.get("trace") or "").strip().splitlines()[0])
        falhou = falhou or conector == "FAILED"
    return 1 if falhou else 0


def comando_remover_conector(args) -> int:
    for nome in _connect("GET", "/connectors") or []:
        _connect("DELETE", f"/connectors/{nome}")
        print(f"conector {nome!r} removido")
    return 0


# ── Transporte ──────────────────────────────────────────────────────────────
def comando_duplicar(args) -> int:
    """Injeta duplicatas **no transporte**, republicando mensagens já entregues.

    O ADR-0019 foi explícito: idempotência sem teste que injeta duplicata é
    apenas intenção. Isto é o teste. A origem não é tocada — a duplicata real
    nasce no caminho, e é lá que ela é simulada (Geração §6).
    """
    from confluent_kafka import Producer

    from mvp_ed1.streaming.transport import consumidor

    fluxo = cfg.carregar()
    c = consumidor(fluxo.transporte, grupo=f"{fluxo.transporte.grupo_de_consumo}_duplicador",
                   **{"auto.offset.reset": "earliest"})
    p = Producer({"bootstrap.servers": fluxo.transporte.bootstrap})
    c.subscribe([fluxo.transporte.topico_de_eventos])

    repetidas = 0
    try:
        while repetidas < args.quantas:
            m = c.poll(5.0)
            if m is None:
                break
            if m.error() or m.value() is None:
                continue
            p.produce(fluxo.transporte.topico_de_eventos, key=m.key(), value=m.value())
            repetidas += 1
        p.flush(30)
    finally:
        c.close()
    print(f"{repetidas} mensagens republicadas em {fluxo.transporte.topico_de_eventos}")
    return 0


def comando_alertas(args) -> int:
    """Lê o tópico de alerta desde o início e resume o que foi emitido."""
    from mvp_ed1.streaming.transport import consumidor

    fluxo = cfg.carregar()
    c = consumidor(fluxo.transporte, grupo=f"{fluxo.transporte.grupo_de_consumo}_alertas_{args.grupo}")
    from confluent_kafka import TopicPartition

    c.assign([TopicPartition(fluxo.transporte.topico_de_alertas, 0, 0)])
    alertas: list[dict] = []
    while True:
        m = c.poll(3.0)
        if m is None:
            break
        if m.error() or m.value() is None:
            continue
        alertas.append(json.loads(m.value()))
    c.close()

    aberturas = [a for a in alertas if a["motivo"] == "abertura"]
    correcoes = [a for a in alertas if a.get("correcao_de_evento_atrasado")]
    print(f"tópico {fluxo.transporte.topico_de_alertas}: {len(alertas)} alertas")
    print(f"  aberturas (cruzaram o limiar de {fluxo.limiar_de_unidades} para baixo): {len(aberturas)}")
    print(f"  normalizações (voltaram acima): {len(alertas) - len(aberturas)}")
    print(f"  correções de evento atrasado: {len(correcoes)}")
    for a in alertas[: args.mostrar]:
        marca = " [correção de atraso]" if a.get("correcao_de_evento_atrasado") else ""
        print(
            f"  {a['motivo']:13} armazém {a['warehouse_id']} SKU {a['product_variant_id']:4} "
            f"saldo {a['quantity_before']} -> {a['quantity_on_hand']}{marca}"
        )
    return 0


# ── Produtor e pipeline ─────────────────────────────────────────────────────
def comando_produzir(args) -> int:
    from mvp_ed1.streaming.producer import ProdutorDeEventos

    fluxo = cfg.carregar()
    produtor = ProdutorDeEventos(fluxo.produtor, semente=args.semente, teto=args.limite)
    inicio = dt.datetime.now(dt.timezone.utc)
    relatorio = produtor.executar()
    duracao = (dt.datetime.now(dt.timezone.utc) - inicio).total_seconds()

    print(f"{relatorio.emitidos} eventos emitidos em {duracao:.1f}s "
          f"({relatorio.emitidos / max(duracao, 0.001):.0f}/s)")
    print(f"  atrasados de propósito: {relatorio.atrasados}")
    print(f"  transferências (pares):  {relatorio.transferencias}")
    for tipo, quantos in sorted(relatorio.por_tipo.items()):
        print(f"  {tipo:18} {quantos}")
    return 0


def comando_pipeline(args) -> int:
    from mvp_ed1.streaming.pipeline import executar

    fluxo = cfg.carregar()
    try:
        executar(fluxo)
    except KeyboardInterrupt:
        print("\npipeline interrompido. O offset confirmado retoma de onde parou.")
    return 0


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    p = argparse.ArgumentParser(prog="mvp_ed1.streaming", description=__doc__)
    sub = p.add_subparsers(dest="comando", required=True)

    sub.add_parser("connector", help="aplica as declarações de streaming/connectors/").set_defaults(
        func=comando_conector
    )
    sub.add_parser("status", help="estado do conector e das tarefas").set_defaults(func=comando_status)
    sub.add_parser("connector-rm", help="remove os conectores registrados").set_defaults(
        func=comando_remover_conector
    )

    d = sub.add_parser("duplicar", help="republica mensagens no transporte (teste de idempotência)")
    d.add_argument("--quantas", type=int, default=50)
    d.set_defaults(func=comando_duplicar)

    a = sub.add_parser("alertas", help="lê e resume o tópico de alerta")
    a.add_argument("--mostrar", type=int, default=10)
    a.add_argument("--grupo", default="1")
    a.set_defaults(func=comando_alertas)

    pr = sub.add_parser("produzir", help="emite eventos novos no livro da origem")
    pr.add_argument("--semente", type=int, default=20260904)
    pr.add_argument("--limite", type=int, default=None)
    pr.set_defaults(func=comando_produzir)

    sub.add_parser("pipeline", help="sobe o pipeline Beam").set_defaults(func=comando_pipeline)

    args = p.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
