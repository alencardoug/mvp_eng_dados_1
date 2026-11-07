"""Carga de desenvolvimento: o bruto do armazém local copiado para o BigQuery.

**Ferramenta de desenvolvimento, não é evidência** (PLANO_etapa_13.md, G1). Enquanto o
Airbyte do GKE não existe, o dbt precisa de um `raw` e de um `raw_legacy` no BigQuery para
transformar. A janela carrega pelo caminho real; antes dela, as tabelas copiadas daqui são
apagadas (`--apagar`).

Cada tabela sai do PostgreSQL por `COPY (select row_to_json(t) …) TO STDOUT` — JSON por linha,
com `timestamptz` em ISO com deslocamento e `jsonb` como objeto — e entra no BigQuery por um
*load job* com o esquema **declarado** a partir do `information_schema`, nunca inferido: um tipo
inferido muda conforme a amostra, e o dbt quebraria de um dia para o outro sem que o código
mudasse.
"""

from __future__ import annotations

import argparse
import io
import os
import sys

from sqlalchemy import create_engine, text

from mvp_ed1.db import WAREHOUSE, database_url

# `governance` entra como *fixture*: o certificado do legado que o G2.1 vai escrever no
# BigQuery; até lá, a cópia local dá ao `staging` do legado o que ler.
SCHEMAS = ("raw", "raw_legacy", "governance")

# PostgreSQL → BigQuery. O que não está aqui é recusado: tipo novo pede decisão, não palpite.
TYPES = {
    "character varying": "STRING",
    "text": "STRING",
    "bigint": "INT64",
    "integer": "INT64",
    "smallint": "INT64",
    "boolean": "BOOL",
    "date": "DATE",
    "timestamp with time zone": "TIMESTAMP",
    "jsonb": "JSON",
    "json": "JSON",
}


def bq_type(data_type: str, precision: int | None, scale: int | None) -> str:
    """O tipo do BigQuery para uma coluna do PostgreSQL; `numeric` vira NUMERIC só se couber."""
    if data_type == "numeric":
        # NUMERIC do BigQuery: até 38 dígitos, 9 depois da vírgula. Fora disso, BIGNUMERIC.
        if scale is not None and scale > 9 or precision is not None and precision > 38:
            return "BIGNUMERIC"
        return "NUMERIC"
    try:
        return TYPES[data_type]
    except KeyError:
        raise SystemExit(f"tipo sem mapeamento para o BigQuery: {data_type!r}") from None


def columns(conn, schema: str, table: str) -> list[tuple[str, str]]:
    rows = conn.execute(
        text(
            "select column_name, data_type, numeric_precision, numeric_scale, is_nullable "
            "from information_schema.columns where table_schema = :s and table_name = :t "
            "order by ordinal_position"
        ),
        {"s": schema, "t": table},
    ).all()
    return [(r[0], bq_type(r[1], r[2], r[3]), r[4]) for r in rows]


def tables(conn, schema: str) -> list[str]:
    return list(
        conn.execute(
            text(
                "select table_name from information_schema.tables "
                "where table_schema = :s and table_type = 'BASE TABLE' order by table_name"
            ),
            {"s": schema},
        ).scalars()
    )


def main(argv: list[str] | None = None) -> int:
    from google.cloud import bigquery

    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--apagar", action="store_true", help="apaga as tabelas copiadas e sai")
    args = ap.parse_args(argv)

    project = os.environ.get("GCP_PROJECT_ID")
    if not project:
        raise SystemExit("GCP_PROJECT_ID ausente no ambiente (.env).")
    client = bigquery.Client(project=project, location=os.environ.get("GCP_BQ_LOCATION", "us-central1"))
    engine = create_engine(database_url(WAREHOUSE))

    with engine.connect() as conn:
        plano = [(s, t) for s in SCHEMAS for t in tables(conn, s)]

    if args.apagar:
        for schema, table in plano:
            client.delete_table(f"{project}.{schema}.{table}", not_found_ok=True)
        print(f"apagadas {len(plano)} tabelas de desenvolvimento em {project}")
        return 0

    total = 0
    raw = engine.raw_connection()
    try:
        for schema, table in plano:
            with engine.connect() as conn:
                cols = columns(conn, schema, table)
            buf = io.BytesIO()
            # Cursor, não `COPY … TO STDOUT`: o formato texto do COPY escapa as barras
            # invertidas, e o JSON de uma linha com `\"` chegava quebrado ao BigQuery
            # ("Parser terminated before end of string", medido em 07/11/2026).
            with raw.cursor() as cur:
                cur.execute(f'select row_to_json(t)::text from "{schema}"."{table}" t')
                while rows := cur.fetchmany(5000):
                    for (line,) in rows:
                        buf.write(line.encode())
                        buf.write(b"\n")
            buf.seek(0)
            config = bigquery.LoadJobConfig(
                source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
                schema=[
                    bigquery.SchemaField(n, t, mode="NULLABLE" if nul == "YES" else "REQUIRED")
                    for n, t, nul in cols
                ],
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            )
            job = client.load_table_from_file(buf, f"{project}.{schema}.{table}", job_config=config)
            job.result()
            loaded = client.get_table(f"{project}.{schema}.{table}").num_rows
            total += loaded
            print(f"{schema}.{table}: {loaded} linhas")
    finally:
        raw.close()
    print(f"total: {len(plano)} tabelas, {total} linhas em {project}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
