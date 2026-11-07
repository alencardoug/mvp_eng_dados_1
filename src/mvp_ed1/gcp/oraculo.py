"""Oráculo semântico: o mesmo modelo nos dois alvos, comparado linha a linha (Etapa 13, G1).

O corpo BigQuery dos modelos é derivado (tradução do `sqlglot`) ou reescrito à mão (a
classificação do legado). Nenhum dos dois se prova por inspeção: a prova é rodar o mesmo
bruto nos dois alvos e comparar o resultado. Este módulo lê o modelo do armazém local e do
BigQuery, casa as linhas pela chave declarada e conta o que diverge.

O que se compara é o **significado**, não a grafia. Uma coluna JSON entra como a lista dos
campos escolhidos de cada elemento (`findings:code,column`): o texto do valor muda entre os
dialetos (`2026-09-02T00:00:00+00:00` × `2026-09-02T00:00:00Z`) sem que nada mude no
veredito.

    python -m mvp_ed1.gcp.oraculo trusted.legacy_classifications \\
        --chave source_system,snapshot_id,source_table,legacy_row_id \\
        --colunas classification,rejection_origin --json findings:code,column

    python -m mvp_ed1.gcp.oraculo contagens   # linhas de toda tabela e view, nas nove camadas

Sai com código 1 se alguma linha falta num lado ou diverge.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter

from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url


def _normaliza(valor: object) -> object:
    if isinstance(valor, str):
        try:
            return json.loads(valor)
        except ValueError:
            return valor
    return valor


def _campos_json(valor: object, campos: list[str]) -> tuple:
    """Os campos escolhidos de cada elemento de uma lista JSON, em ordem."""
    lista = _normaliza(valor) or []
    return tuple(tuple(item.get(c) for c in campos) for item in lista)


def _linhas(registros, chave, colunas, jsons) -> dict[tuple, tuple]:
    saida = {}
    for r in registros:
        k = tuple(str(r[c]) for c in chave)
        if k in saida:
            raise SystemExit(f"chave repetida {k}: a chave declarada não identifica a linha")
        saida[k] = tuple(r[c] for c in colunas) + tuple(_campos_json(r[n], cs) for n, cs in jsons)
    return saida


CAMADAS = ("raw", "raw_legacy", "governance", "staging", "trusted", "analytics",
           "consumption", "quarantine", "snapshots")


#: A quarentena é destino permanente (ADR-0037): o armazém local guarda as auditorias de
#: todas as capturas e tratamentos, e o BigQuery só as que rodaram lá. O que tem de ser igual
#: é o recorte da captura e do tratamento correntes — os de `legacy_classifications`.
RECORTE = {
    ("quarantine", "rejected_legacy_records"): (
        "where exists (select 1 from {classificacoes} c where c.source_system = q.source_system "
        "and c.snapshot_id = q.snapshot_id and c.catalog_version = q.catalog_version "
        "and c.treatment_fingerprint = q.treatment_fingerprint)"
    ),
}


def contagens(cliente, projeto: str) -> int:
    """Linhas de cada tabela e view das nove camadas, nos dois alvos (a quarentena, no recorte corrente)."""
    engine = create_engine(database_url(WAREHOUSE))
    with engine.connect() as conn:
        nomes = conn.execute(text(
            "select table_schema, table_name from information_schema.tables "
            "where table_schema = any(:s) order by 1, 2"), {"s": list(CAMADAS)}).all()
        local = {(a, b): conn.execute(text(
            f'select count(*) from "{a}"."{b}" q '
            + RECORTE.get((a, b), "").format(classificacoes="trusted.legacy_classifications"))).scalar()
            for a, b in nomes}
    nuvem = {}
    for camada in CAMADAS:
        for t in cliente.list_tables(f"{projeto}.{camada}"):
            recorte = RECORTE.get((camada, t.table_id), "").format(
                classificacoes=f"`{projeto}.trusted.legacy_classifications`")
            nuvem[(camada, t.table_id)] = next(iter(cliente.query(
                f"select count(*) from `{projeto}.{camada}.{t.table_id}` q {recorte}").result()))[0]
    iguais = divergem = 0
    for k in sorted(set(local) | set(nuvem)):
        a, b = local.get(k), nuvem.get(k)
        if a == b:
            iguais += 1
            continue
        divergem += 1
        print(f"  {k[0]}.{k[1]}: local {a}, BigQuery {b}")
    print(f"contagens: {iguais} iguais, {divergem} diferentes ou de um lado só")
    return 1 if divergem else 0


def main(argv: list[str] | None = None) -> int:
    from google.cloud import bigquery

    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("modelo", help="schema.tabela, igual nos dois alvos; `contagens` para todas")
    ap.add_argument("--chave")
    ap.add_argument("--colunas", default="")
    ap.add_argument("--json", action="append", default=[], help="coluna:campo1,campo2")
    ap.add_argument("--exemplos", type=int, default=5)
    args = ap.parse_args(argv)

    projeto = os.environ.get("GCP_PROJECT_ID")
    if not projeto:
        raise SystemExit("GCP_PROJECT_ID ausente no ambiente (.env).")
    cliente = bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION", "us-central1"))
    if args.modelo == "contagens":
        return contagens(cliente, projeto)
    if not args.chave:
        raise SystemExit("--chave é obrigatória para comparar um modelo")

    chave = args.chave.split(",")
    colunas = [c for c in args.colunas.split(",") if c]
    jsons = [(j.split(":")[0], j.split(":")[1].split(",")) for j in args.json]
    nomes = chave + colunas + [n for n, _ in jsons]
    schema, tabela = args.modelo.split(".")

    engine = create_engine(database_url(WAREHOUSE))
    with engine.connect() as conn:
        lista = ", ".join(f'"{n}"' + ("::text" if n in dict(jsons) else "") for n in nomes)
        local = _linhas(conn.execute(text(f'select {lista} from "{schema}"."{tabela}"')).mappings(),
                        chave, colunas, jsons)

    lista = ", ".join(f"to_json_string({n}) as {n}" if n in dict(jsons) else n for n in nomes)
    nuvem = _linhas(cliente.query(f"select {lista} from `{projeto}.{schema}.{tabela}`").result(),
                    chave, colunas, jsons)

    so_local = sorted(set(local) - set(nuvem))
    so_nuvem = sorted(set(nuvem) - set(local))
    divergentes = sorted(k for k in set(local) & set(nuvem) if local[k] != nuvem[k])

    print(f"{args.modelo}: local {len(local)} linhas, BigQuery {len(nuvem)}")
    for c in colunas:
        i = colunas.index(c)
        print(f"  {c}: local {dict(Counter(v[i] for v in local.values()))}")
        print(f"  {c}: BigQuery {dict(Counter(v[i] for v in nuvem.values()))}")
    print(f"  só no local: {len(so_local)}; só no BigQuery: {len(so_nuvem)}; divergentes: {len(divergentes)}")
    for k in divergentes[: args.exemplos]:
        print(f"    {k}\n      local    {local[k]}\n      BigQuery {nuvem[k]}")
    for k in so_local[: args.exemplos]:
        print(f"    só no local: {k}")
    for k in so_nuvem[: args.exemplos]:
        print(f"    só no BigQuery: {k}")
    return 1 if so_local or so_nuvem or divergentes else 0


if __name__ == "__main__":
    sys.exit(main())
