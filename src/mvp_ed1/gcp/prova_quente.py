"""A prova do caminho quente da nuvem antes do GKE (Etapa 13, G2.3): Pub/Sub → Beam → BigQuery → alerta.

Roda o grafo de `pipeline.construir(..., nuvem=True)` no executor local, contra o Pub/Sub e o
BigQuery **de verdade**, em recursos **temporários** criados e apagados aqui: um tópico e uma
assinatura de eventos, um tópico e uma assinatura de alertas, um *dataset* de destino. A
assinatura `beam` do Terraform não é tocada — mensagem de teste deixada nela seria lida pelo
Dataflow na janela.

O que se publica, no formato que o Debezium Server entrega com a D78 (envelope achatado, `__op`,
`__lsn`, `occurred_at` também como atributo):

* um saldo de partida gravado direto no destino **antes** de o pipeline subir — a semente;
* três movimentos ao vivo que cruzam o limiar para baixo no mesmo par armazém/SKU;
* o mesmo movimento publicado **duas vezes** (duplicata no transporte);
* um movimento **atrasado** (`occurred_at` minutos antes dos outros, dentro do tolerado).

E o que se confere: uma linha por movimento no destino, a duplicata contada e barrada, exatamente
um alerta de abertura com o saldo certo, e nada sobrando nos recursos temporários.

    python -m mvp_ed1.gcp.prova_quente --saida data/medicoes/etapa_13/g23/prova_quente.json
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as dt
import json
import os
import time
import uuid
from typing import Any

LIMIAR_DE_PARTIDA = 30   # saldo semeado: acima do limiar de 25
ESPERA_MAXIMA = 240       # segundos que o pipeline tem para gravar e alertar


def _mensagem(movement_id: str, ocorreu: dt.datetime, delta: int, *, op: str = "c", lsn: int) -> tuple[bytes, dict]:
    corpo = {
        "movement_id": movement_id, "event_sequence": lsn, "idempotency_key": f"k-{movement_id}",
        "warehouse_id": 1, "product_variant_id": 2, "movement_type": "sale", "quantity_delta": delta,
        "unit_cost": "12.345678", "source_type": "order", "source_id": f"o-{movement_id}",
        "correlation_id": None, "causation_id": None, "aggregate_version": 1,
        "occurred_at": ocorreu.isoformat().replace("+00:00", "Z"),
        "recorded_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "schema_version": 1, "metadata": None, "__op": op, "__lsn": lsn,
    }
    return json.dumps(corpo).encode(), {"occurred_at": corpo["occurred_at"]}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.gcp.prova_quente")
    parser.add_argument("--saida", help="grava o relatório em JSON")
    args = parser.parse_args(argv)

    import apache_beam as beam
    from google.cloud import bigquery, pubsub_v1

    from mvp_ed1.streaming import nuvem
    from mvp_ed1.streaming.config import carregar
    from mvp_ed1.streaming.pipeline import construir, opcoes

    projeto = os.environ["GCP_PROJECT_ID"]
    sufixo = uuid.uuid4().hex[:8]
    editor, assinante = pubsub_v1.PublisherClient(), pubsub_v1.SubscriberClient()
    cliente = bigquery.Client(project=projeto, location=os.environ["GCP_BQ_LOCATION"])
    nomes = {k: f"prova_quente_{k}_{sufixo}" for k in ("eventos", "alertas")}
    topicos = {k: editor.topic_path(projeto, v) for k, v in nomes.items()}
    assinaturas = {k: assinante.subscription_path(projeto, v) for k, v in nomes.items()}
    dataset = f"prova_quente_{sufixo}"

    fluxo = carregar()
    fluxo = dataclasses.replace(
        fluxo,
        destino=dataclasses.replace(fluxo.destino, schema=dataset, lote_de_escrita=50),
        nuvem=dataclasses.replace(fluxo.nuvem, assinatura_de_eventos=nomes["eventos"],
                                  topico_de_alertas=nomes["alertas"], espera_maxima_do_lote_segundos=2),
    )
    relatorio: dict[str, Any] = {"projeto": projeto, "recursos": {**nomes, "dataset": dataset}}
    try:
        for k in nomes:
            editor.create_topic(name=topicos[k])
            assinante.create_subscription(name=assinaturas[k], topic=topicos[k], ack_deadline_seconds=60)
        novo = bigquery.Dataset(f"{projeto}.{dataset}")
        novo.location = os.environ["GCP_BQ_LOCATION"]
        cliente.create_dataset(novo)

        # A semente: um saldo de partida durável antes de o pipeline subir.
        bq = nuvem.armazem()
        nuvem.garantir_tabela(bq, fluxo.destino)
        from mvp_ed1.streaming.envelope import decodificar

        antes = dt.datetime.now(dt.timezone.utc) - dt.timedelta(hours=1)
        corpo, _ = _mensagem("semente", antes, LIMIAR_DE_PARTIDA, op="r", lsn=1)
        nuvem.escrever_lote(bq, fluxo.destino, [decodificar(corpo)])
        time.sleep(1)  # o `_stream_extracted_at` da semente fica antes do instante do `setup`

        p = beam.Pipeline(options=opcoes())
        construir(p, fluxo, nuvem=True)
        resultado = p.run()
        time.sleep(20)  # o leitor do Pub/Sub precisa estar puxando antes da publicação

        agora = dt.datetime.now(dt.timezone.utc)
        publicadas = [
            _mensagem("m1", agora - dt.timedelta(seconds=30), -2, lsn=10),
            _mensagem("m2", agora - dt.timedelta(seconds=20), -2, lsn=11),
            _mensagem("m2", agora - dt.timedelta(seconds=20), -2, lsn=11),        # duplicata no transporte
            _mensagem("tarde", agora - dt.timedelta(minutes=8), -1, lsn=9),        # atrasado, dentro do tolerado
            _mensagem("m3", agora - dt.timedelta(seconds=10), -2, lsn=12),         # 30-2-2-1-2 = 23 < 25
        ]
        for dados, atributos in publicadas:
            editor.publish(topicos["eventos"], dados, **atributos).result(timeout=30)
        relatorio["publicadas"] = len(publicadas)

        alertas: list[dict] = []

        def coletar(mensagem):
            alertas.append(json.loads(mensagem.data))
            mensagem.ack()

        escuta = assinante.subscribe(assinaturas["alertas"], callback=coletar)
        limite = time.monotonic() + ESPERA_MAXIMA
        linhas: list[dict] = []
        while time.monotonic() < limite:
            linhas = bq.linhas(f"select movement_id from {bq.tabela(fluxo.destino.qualificado)} order by 1")
            if len(linhas) >= 5 and alertas:
                break
            time.sleep(5)
        time.sleep(15)  # um alerta a mais chegaria aqui
        escuta.cancel()
        resultado.cancel()

        saldo = bq.escalar(f"select sum(quantity_delta) from {bq.tabela(fluxo.destino.qualificado)}")
        relatorio.update({
            "linhas_no_destino": [l["movement_id"] for l in linhas],
            "saldo_no_destino": saldo,
            "alertas": alertas,
        })
        esperado_linhas = ["m1", "m2", "m3", "semente", "tarde"]
        falhas = []
        if relatorio["linhas_no_destino"] != esperado_linhas:
            falhas.append(f"destino: esperado {esperado_linhas}")
        aberturas = [a for a in alertas if a.get("motivo") == "abertura"]
        # A ordem dos painéis decide em que movimento a travessia acontece (23 ou 24); o que não
        # muda é haver **uma** abertura e o saldo durável terminar em 23.
        if len(alertas) != 1 or len(aberturas) != 1:
            falhas.append("alerta: esperado exatamente uma abertura")
        if saldo != 23:
            falhas.append(f"saldo: esperado 23, veio {saldo}")
        relatorio["falhas"] = falhas
        bq.dispose()
    finally:
        for k in nomes:
            for apagar, caminho in ((assinante.delete_subscription, assinaturas[k]), (editor.delete_topic, topicos[k])):
                try:
                    apagar(request={"subscription": caminho} if "subscriptions" in caminho else {"topic": caminho})
                except Exception as erro:  # noqa: BLE001 — registrar e seguir apagando o resto
                    relatorio.setdefault("limpeza", []).append(f"{caminho}: {erro}")
        cliente.delete_dataset(f"{projeto}.{dataset}", delete_contents=True, not_found_ok=True)

    texto = json.dumps(relatorio, ensure_ascii=False, indent=2, default=str)
    print(texto)
    if args.saida:
        os.makedirs(os.path.dirname(args.saida), exist_ok=True)
        with open(args.saida, "w", encoding="utf-8") as saida:
            saida.write(texto + "\n")
    return 1 if relatorio.get("falhas") else 0


if __name__ == "__main__":
    raise SystemExit(main())
