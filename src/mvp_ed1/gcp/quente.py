"""O caminho quente da nuvem conferido de ponta a ponta (Etapa 13, G2.3; terça, D83).

Com o Debezium Server no GKE e o *job* no Dataflow, o que se confere desta máquina:

* **`conferir`** — o livro da origem no Cloud SQL contra o destino no BigQuery, **por chave e por
  conteúdo**: cada `movement_id` com as 16 colunas de negócio (as do `comparar_caminhos` da fase
  local) igual nos dois lados, nenhum faltando, nenhum a mais, nenhum repetido. Contagem e máximo
  iguais não bastam: um movimento perdido e outro indevido não os mudam (RV13J-1-10). O conector faz
  *snapshot* inicial (`snapshot.mode=initial`), então o destino deve ter **todo** movimento da
  origem, uma linha por `movement_id` (a escrita é idempotente, D75). Os alertas da assinatura de observação são lidos e
  confirmados: ela é só do Owner (`terraform/armazenamento.tf`). Volta 1 enquanto o destino não
  alcançou a origem — repetir é esperar;
* **`slot`** — o *slot* de replicação no Cloud SQL: ativo, e quanto WAL ele segura;
* **`latencia`** — a latência de ponta a ponta, **por observação**. O destino não tem coluna de
  gravação, então ela se mede de fora: o corte da origem, o produtor solto em segundo plano, e o
  destino consultado a cada `--intervalo` segundos. Cada evento vivo (`_stream_from_snapshot` falso)
  conta do `recorded_at`, que o produtor grava com o relógio desta máquina, até a primeira consulta
  que o vê, com o relógio do BigQuery. A resolução é o intervalo, e o erro, o desvio entre os dois
  relógios (NTP). É a latência que um leitor do destino vê, não a do *pipeline* por dentro. Só
  conta como medida com o produtor terminado **sem erro** e com pelo menos os `--limite` eventos
  dele na origem, todos vistos no destino (RV13J-1-05).

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


#: As colunas de negócio do movimento, as que o `comparar_caminhos` da fase local compara.
COLUNAS = ("movement_id", "event_sequence", "idempotency_key", "warehouse_id", "product_variant_id",
           "movement_type", "quantity_delta", "unit_cost", "source_type", "source_id", "correlation_id",
           "causation_id", "aggregate_version", "occurred_at", "recorded_at", "schema_version")


def _normal(valor: Any) -> Any:
    """O valor sem a grafia do banco: decimal pelo valor, instante em UTC com microssegundos."""
    import datetime as dt
    import decimal

    if isinstance(valor, decimal.Decimal):
        return format(valor.normalize(), "f") if valor == valor.to_integral_value() else str(valor.normalize())
    if isinstance(valor, dt.datetime):
        return valor.astimezone(dt.timezone.utc).isoformat(timespec="microseconds")
    if isinstance(valor, (int, str)) or valor is None:
        return valor
    return str(valor)


def por_chave(linhas) -> tuple[dict[str, tuple], list[str]]:
    """`movement_id` → as colunas normalizadas; e os `movement_id` repetidos."""
    saida: dict[str, tuple] = {}
    repetidas = []
    for linha in linhas:
        chave = str(linha["movement_id"])
        if chave in saida:
            repetidas.append(chave)
        saida[chave] = tuple(_normal(linha[c]) for c in COLUNAS)
    return saida, sorted(set(repetidas))


def comparar_conteudo(origem_linhas, destino_linhas) -> list[str]:
    o, _ = por_chave(origem_linhas)
    d, repetidas = por_chave(destino_linhas)
    problemas = []
    if repetidas:
        problemas.append(f"destino com movement_id repetido: {repetidas[:5]} ({len(repetidas)})")
    if faltam := sorted(set(o) - set(d)):
        problemas.append(f"destino sem {len(faltam)} movimento(s) da origem: {faltam[:5]}")
    if sobram := sorted(set(d) - set(o)):
        problemas.append(f"destino com {len(sobram)} movimento(s) que a origem não tem: {sobram[:5]}")
    if diferem := sorted(k for k in set(o) & set(d) if o[k] != d[k]):
        k = diferem[0]
        campos = [c for c, a, b in zip(COLUNAS, o[k], d[k]) if a != b]
        problemas.append(f"{len(diferem)} movimento(s) com conteúdo diferente; o primeiro, {k}, em {campos}")
    return problemas


def linhas_da_origem() -> list[dict[str, Any]]:
    import sqlalchemy as sa

    from mvp_ed1 import db
    from mvp_ed1.streaming.espera import SCHEMA_ORIGEM, TABELA_ORIGEM

    motor = sa.create_engine(db.database_url(db.SOURCE), future=True)
    try:
        with motor.connect() as con:
            return [dict(r) for r in con.execute(sa.text(
                f"select {', '.join(COLUNAS)} from {SCHEMA_ORIGEM}.{TABELA_ORIGEM}")).mappings()]
    finally:
        motor.dispose()


def linhas_do_destino(cliente, projeto: str, qualificado: str) -> list[dict[str, Any]]:
    return [dict(r.items()) for r in cliente.query(
        f"select {', '.join(COLUNAS)} from `{projeto}.{qualificado}`").result()]


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
             intervalo: float, minimo: int = 1, relogio=None, pausa=None) -> dict[str, Any]:
    """Consulta o destino até ver todo evento vivo depois de `desde`, ou até o prazo.

    `produtor()` devolve `None` enquanto o produtor roda, e o código de saída dele quando termina;
    `esperados()` conta os eventos da origem depois de `desde`, lido quando ele terminou. A primeira
    vez que um `event_sequence` aparece fixa a latência dele: `agora` do BigQuery menos o
    `recorded_at`. **Completo** pede as três coisas: o produtor saiu com 0, a origem tem ao menos
    `minimo` eventos novos, e o destino mostrou todos — produtor que falha antes de gravar deixaria
    zero esperados e zero vistos, e isso não é medida (RV13J-1-05).
    """
    import time

    if minimo < 1:
        raise ValueError(f"a amostra mínima é de ao menos um evento, e não {minimo}: amostra vazia não é medida")
    relogio = relogio or time.monotonic
    pausa = pausa or time.sleep
    vistos: dict[int, float] = {}
    inicio, total, saida = relogio(), None, None
    sql = (f"select event_sequence, recorded_at, current_timestamp() as agora from `{projeto}.{qualificado}` "
           f"where event_sequence > {int(desde)} and not _stream_from_snapshot")
    while relogio() - inicio < prazo:
        for linha in cliente.query(sql).result():
            seq = int(linha["event_sequence"])
            if seq not in vistos:
                vistos[seq] = (linha["agora"] - linha["recorded_at"]).total_seconds()
        if total is None and (saida := produtor()) is not None:
            if saida != 0:
                break
            total = esperados()
        if total is not None and len(vistos) >= total:
            break
        pausa(intervalo)
    motivo = ("o produtor ainda rodava no fim do prazo" if saida is None
              else f"o produtor saiu com {saida}" if saida != 0
              else f"a origem tem {total} eventos novos, menos que os {minimo} pedidos" if total < minimo
              else f"o destino mostrou {len(vistos)} de {total}" if len(vistos) < total
              else "nenhum evento visto" if not vistos
              else None)
    return {"desde": desde, "esperados": total, "vistos": len(vistos), "intervalo_s": intervalo,
            "produtor_saiu_com": saida, "minimo": minimo, "completo": motivo is None, "motivo": motivo,
            **resumo(list(vistos.values()))}


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
    def positivo(texto: str) -> int:
        valor = int(texto)
        if valor < 1:
            raise argparse.ArgumentTypeError("tem de ser ao menos 1")
        return valor

    ap.add_argument("--limite", type=positivo, default=200, help="latencia: quantos eventos o produtor emite (≥ 1)")
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
                                 produtor=produtor.poll,
                                 esperados=lambda: origem(desde=corte)["movimentos"],
                                 prazo=args.prazo, intervalo=args.intervalo, minimo=args.limite)
        finally:
            if produtor.poll() is None:
                produtor.terminate()
            try:
                produtor.wait(timeout=30)
            except subprocess.TimeoutExpired:
                produtor.kill()
                produtor.wait()
        texto = json.dumps(relatorio, ensure_ascii=False, indent=2)
        print(texto)
        if relatorio["motivo"]:
            print(f"INCOMPLETO — {relatorio['motivo']}: não é medida da latência", file=sys.stderr)
        if args.saida:
            with open(args.saida, "w", encoding="utf-8") as arquivo:
                arquivo.write(texto + "\n")
        return 0 if relatorio["completo"] else 1
    cliente = bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION"))
    o = origem()
    d = destino(cliente, projeto, fluxo.destino.qualificado)
    lidos = alertas(projeto, f"{fluxo.nuvem.topico_de_alertas}.observacao")
    print(f"origem (Cloud SQL): {o['movimentos']} movimentos, seq até {o['max_event_sequence']}")
    print(f"destino (BigQuery): {d['movimentos']} movimentos em {d['linhas']} linhas, seq até {d['max_event_sequence']}")
    print(f"alertas lidos agora: {len(lidos)}")
    for alerta in lidos[:10]:
        print(f"  {json.dumps(alerta, ensure_ascii=False, sort_keys=True)}")
    problemas = comparar(o, d)
    for problema in problemas:
        print(f"PENDENTE — {problema}", file=sys.stderr)
    if problemas:
        return 1
    # Contagem e máximo iguais: aí o conteúdo, chave por chave. Diferença aqui não é espera, é falha.
    falhas = comparar_conteudo(linhas_da_origem(), linhas_do_destino(cliente, projeto, fluxo.destino.qualificado))
    for falha in falhas:
        print(f"FALHOU — {falha}", file=sys.stderr)
    if falhas:
        return 2
    print(f"conteúdo: os {o['movimentos']} movimentos iguais por chave e pelas {len(COLUNAS)} colunas de negócio")
    return 0


if __name__ == "__main__":
    sys.exit(main())
