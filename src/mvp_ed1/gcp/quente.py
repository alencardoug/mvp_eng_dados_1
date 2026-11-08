"""O caminho quente da nuvem conferido de ponta a ponta (Etapa 13, G2.3; terça, D83).

Com o Debezium Server no GKE e o *job* no Dataflow, o que se confere desta máquina:

* **`conferir`** — o livro da origem no Cloud SQL contra o destino no BigQuery: quantos movimentos
  e o maior `event_sequence` de cada lado. O conector faz *snapshot* inicial
  (`snapshot.mode=initial`), então o destino deve ter **todo** movimento da origem, uma linha por
  `movement_id` (a escrita é idempotente, D75). Os alertas da assinatura de observação são lidos e
  confirmados: ela é só do Owner (`terraform/armazenamento.tf`). Volta 1 enquanto o destino não
  alcançou a origem — repetir é esperar;
* **`slot`** — o *slot* de replicação no Cloud SQL: ativo, e quanto WAL ele segura;
* **`latencia`** — a latência de ponta a ponta, **por observação**. O destino não tem coluna de
  gravação, então ela se mede de fora: o corte da origem, o produtor solto em segundo plano, e o
  destino consultado a cada `--intervalo` segundos. Cada evento vivo (`_stream_from_snapshot` falso)
  conta do `recorded_at`, que o produtor grava com o relógio desta máquina, até a primeira consulta
  que o vê, com o relógio do BigQuery. A resolução é o intervalo, e o erro, o desvio entre os dois
  relógios (NTP). É a latência que um leitor do destino vê, não a do *pipeline* por dentro.

    python -m mvp_ed1.gcp.quente conferir
    python -m mvp_ed1.gcp.quente slot
    python -m mvp_ed1.gcp.quente latencia --limite 200 --saida LATENCIA.json
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any

#: Quantas mensagens de alerta uma leitura puxa no máximo; o resto fica para a próxima.
ALERTAS_POR_LEITURA = 100


def origem(desde: int | None = None) -> dict[str, int]:
    """O livro da origem: movimentos e o maior `event_sequence` (só os depois de `desde`, se dado)."""
    import sqlalchemy as sa

    from mvp_ed1 import db
    from mvp_ed1.streaming.espera import SCHEMA_ORIGEM, TABELA_ORIGEM

    motor = sa.create_engine(db.database_url(db.SOURCE), future=True)
    try:
        with motor.connect() as con:
            n, maximo = con.execute(sa.text(
                f"select count(*), coalesce(max(event_sequence), 0) from {SCHEMA_ORIGEM}.{TABELA_ORIGEM} "
                "where event_sequence > :desde"
            ), {"desde": -1 if desde is None else int(desde)}).one()
    finally:
        motor.dispose()
    return {"movimentos": int(n), "max_event_sequence": int(maximo)}


def destino(cliente, projeto: str, qualificado: str) -> dict[str, int]:
    """O destino no BigQuery: `movement_id` distintos, linhas e o maior `event_sequence`."""
    linha = next(iter(cliente.query(
        f"select count(distinct movement_id) as d, count(*) as n, coalesce(max(event_sequence), 0) as m "
        f"from `{projeto}.{qualificado}`"
    ).result()))
    return {"movimentos": int(linha["d"]), "linhas": int(linha["n"]), "max_event_sequence": int(linha["m"])}


def comparar(o: dict[str, int], d: dict[str, int]) -> list[str]:
    problemas = []
    if d["linhas"] != d["movimentos"]:
        problemas.append(f"destino com {d['linhas'] - d['movimentos']} linhas repetidas por movement_id")
    if d["movimentos"] != o["movimentos"] or d["max_event_sequence"] != o["max_event_sequence"]:
        problemas.append(f"destino ainda não alcançou a origem: {d['movimentos']} de {o['movimentos']} movimentos, "
                         f"seq {d['max_event_sequence']} de {o['max_event_sequence']}")
    return problemas


def alertas(projeto: str, assinatura: str) -> list[dict[str, Any]]:
    """Puxa e confirma os alertas da assinatura de observação."""
    from google.cloud import pubsub_v1

    assinante = pubsub_v1.SubscriberClient()
    caminho = assinante.subscription_path(projeto, assinatura)
    with assinante:
        resposta = assinante.pull(request={"subscription": caminho, "max_messages": ALERTAS_POR_LEITURA}, timeout=30)
        recebidas = list(resposta.received_messages)
        if recebidas:
            assinante.acknowledge(request={"subscription": caminho, "ack_ids": [m.ack_id for m in recebidas]})
    return [json.loads(m.message.data) for m in recebidas]


def _percentil(valores: list[float], p: float) -> float:
    ordenados = sorted(valores)
    return ordenados[min(len(ordenados) - 1, max(0, round(p * (len(ordenados) - 1))))]


def resumo(latencias: list[float]) -> dict[str, Any]:
    if not latencias:
        return {"eventos": 0}
    return {"eventos": len(latencias), "min_s": round(min(latencias), 1), "p50_s": round(_percentil(latencias, 0.5), 1),
            "p95_s": round(_percentil(latencias, 0.95), 1), "max_s": round(max(latencias), 1)}


def latencia(cliente, projeto: str, qualificado: str, desde: int, *, produtor, esperados, prazo: float,
             intervalo: float, relogio=None, pausa=None) -> dict[str, Any]:
    """Consulta o destino até ver todo evento vivo depois de `desde`, ou até o prazo.

    `produtor` diz se o produtor ainda roda; `esperados()` conta os eventos da origem depois de
    `desde`, lido quando ele terminou. A primeira vez que um `event_sequence` aparece fixa a
    latência dele: `agora` do BigQuery menos o `recorded_at`.
    """
    import time

    relogio = relogio or time.monotonic
    pausa = pausa or time.sleep
    vistos: dict[int, float] = {}
    inicio, total = relogio(), None
    sql = (f"select event_sequence, recorded_at, current_timestamp() as agora from `{projeto}.{qualificado}` "
           f"where event_sequence > {int(desde)} and not _stream_from_snapshot")
    while relogio() - inicio < prazo:
        for linha in cliente.query(sql).result():
            seq = int(linha["event_sequence"])
            if seq not in vistos:
                vistos[seq] = (linha["agora"] - linha["recorded_at"]).total_seconds()
        if total is None and not produtor():
            total = esperados()
        if total is not None and len(vistos) >= total:
            break
        pausa(intervalo)
    return {"desde": desde, "esperados": total, "vistos": len(vistos), "intervalo_s": intervalo,
            "completo": total is not None and len(vistos) >= total, **resumo(list(vistos.values()))}


SLOT = ("select slot_name, active, "
        "pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as wal_retido "
        "from pg_replication_slots where slot_name = :slot")


def slot() -> dict[str, Any] | None:
    import sqlalchemy as sa

    from mvp_ed1 import db
    from mvp_ed1.streaming.maintenance import declared_slots

    motor = sa.create_engine(db.database_url(db.SOURCE), future=True)
    try:
        with motor.connect() as con:
            linha = con.execute(sa.text(SLOT), {"slot": declared_slots()[0]}).mappings().one_or_none()
    finally:
        motor.dispose()
    return None if linha is None else dict(linha)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.gcp.quente", description=__doc__.split("\n")[0])
    ap.add_argument("comando", choices=["conferir", "slot", "latencia"])
    ap.add_argument("--limite", type=int, default=200, help="latencia: quantos eventos o produtor emite")
    ap.add_argument("--prazo", type=float, default=900, help="latencia: segundos até desistir")
    ap.add_argument("--intervalo", type=float, default=5, help="latencia: segundos entre consultas")
    ap.add_argument("--saida", type=str, help="latencia: o relatório em JSON")
    args = ap.parse_args(argv)

    if args.comando == "slot":
        estado = slot()
        if estado is None:
            print("slot: ausente no Cloud SQL — o Debezium Server ainda não o criou", file=sys.stderr)
            return 1
        print(f"slot {estado['slot_name']}: {'ativo' if estado['active'] else 'INATIVO'}, WAL retido {estado['wal_retido']}")
        return 0 if estado["active"] else 1

    from google.cloud import bigquery

    from mvp_ed1.streaming import config as cfg

    projeto = os.environ["GCP_PROJECT_ID"]
    fluxo = cfg.carregar()
    if args.comando == "latencia":
        import subprocess

        cliente = bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION"))
        corte = origem()["max_event_sequence"]
        produtor = subprocess.Popen([sys.executable, "-m", "mvp_ed1.streaming.cli", "produzir",
                                     "--limite", str(args.limite)])
        try:
            relatorio = latencia(cliente, projeto, fluxo.destino.qualificado, corte,
                                 produtor=lambda: produtor.poll() is None,
                                 esperados=lambda: origem(desde=corte)["movimentos"],
                                 prazo=args.prazo, intervalo=args.intervalo)
        finally:
            if produtor.poll() is None:
                produtor.terminate()
        texto = json.dumps(relatorio, ensure_ascii=False, indent=2)
        print(texto)
        if args.saida:
            with open(args.saida, "w", encoding="utf-8") as arquivo:
                arquivo.write(texto + "\n")
        return 0 if relatorio["completo"] else 1
    o = origem()
    d = destino(bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION")),
                projeto, fluxo.destino.qualificado)
    lidos = alertas(projeto, f"{fluxo.nuvem.topico_de_alertas}.observacao")
    print(f"origem (Cloud SQL): {o['movimentos']} movimentos, seq até {o['max_event_sequence']}")
    print(f"destino (BigQuery): {d['movimentos']} movimentos em {d['linhas']} linhas, seq até {d['max_event_sequence']}")
    print(f"alertas lidos agora: {len(lidos)}")
    for alerta in lidos[:10]:
        print(f"  {json.dumps(alerta, ensure_ascii=False, sort_keys=True)}")
    problemas = comparar(o, d)
    for problema in problemas:
        print(f"PENDENTE — {problema}", file=sys.stderr)
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main())
