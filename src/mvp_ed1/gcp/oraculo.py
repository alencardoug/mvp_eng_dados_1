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

    python -m mvp_ed1.gcp.oraculo contagens   # linhas de toda tabela e view, nas nove camadas;
                                              # a contagem da história não reprova (D85)
    python -m mvp_ed1.gcp.oraculo consumo     # o conteúdo de cada view de consumption

`contagens` sozinha não prova as *views* de consumo: duas com as mesmas quantidades e valores
diferentes passariam (RV13J-1-09). `consumo` compara o **conteúdo** de cada uma — o multiconjunto
das linhas, coluna por coluna e pelo nome, depois de normalizado: número pelo valor com 6 casas
(o `NUMERIC`/`FLOAT64` do BigQuery e o `numeric` do PostgreSQL arredondam a última casa de uma
média de jeitos diferentes), instante em UTC, data em ISO. As colunas de metadado de execução (as
que começam com `_`) saem, **declaradas** no relatório. Coluna de um lado só é divergência.

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


#: O que guarda a história de cada ambiente, e não o estado corrente (D85), declarado por objeto
#: (RV0811-1-02): entre o local e a nuvem as capturas e as execuções são outras, e a contagem disto
#: não diz nada sobre a paridade. Schemas inteiros: o `raw_legacy`, uma cópia por captura
#: (`full_refresh_append`, ADR-0037), e os `snapshots`, uma versão por execução do dbt. Objetos:
#: o registro de capturas e os três modelos do legado que leem as capturas anteriores, além da
#: selecionada. O `governance._versions` (as migrações aplicadas) é estado, e reprova.
HISTORIA_SCHEMAS = frozenset({"raw_legacy", "snapshots"})
HISTORIA_OBJETOS = frozenset({
    ("governance", "legacy_captures"),
    ("trusted", "legacy_presence_by_capture"),
    ("trusted", "legacy_capture_transitions"),
    ("trusted", "legacy_removed_records"),
})


def e_historia(chave: tuple[str, str]) -> bool:
    """A contagem deste objeto é história do ambiente (D85)?"""
    return chave[0] in HISTORIA_SCHEMAS or chave in HISTORIA_OBJETOS


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
    return 1 if comparar_contagens(local, nuvem) else 0


def comparar_contagens(local: dict[tuple, int], nuvem: dict[tuple, int]) -> int:
    """Imprime cada diferença e devolve quantas reprovam (D85).

    A diferença de contagem num objeto de história (`e_historia`) sai no relatório, marcada, e não
    reprova: o que ela conta é a sequência de capturas e de execuções de cada ambiente. Objeto que
    existe num lado só reprova sempre, de história ou não (RV0811-1-01): a presença não depende do
    número de capturas.
    """
    iguais = estado = historia = 0
    for k in sorted(set(local) | set(nuvem)):
        a, b = local.get(k), nuvem.get(k)
        if a == b:
            iguais += 1
            continue
        if a is not None and b is not None and e_historia(k):
            historia += 1
            print(f"  {k[0]}.{k[1]}: local {a}, BigQuery {b} (história do ambiente, não comparável — D85)")
            continue
        estado += 1
        print(f"  {k[0]}.{k[1]}: local {a}, BigQuery {b}")
    print(f"contagens: {iguais} iguais, {estado} diferentes no estado ou de um lado só, "
          f"{historia} só na contagem da história (não comparáveis, D85)")
    return estado


#: Casas decimais da comparação de números entre os dois dialetos.
CASAS = 6


def _valor_normal(valor: object) -> object:
    import datetime as dt
    import decimal

    if isinstance(valor, bool) or valor is None:
        return valor
    if isinstance(valor, (int, float, decimal.Decimal)):
        return str(round(decimal.Decimal(str(valor)), CASAS).normalize() + 0)
    if isinstance(valor, dt.datetime):
        if valor.tzinfo is None:
            raise SystemExit(f"instante sem fuso na comparação: {valor!r}; a view tem de expor timestamptz")
        return valor.astimezone(dt.timezone.utc).isoformat(timespec="microseconds")
    if isinstance(valor, dt.date):
        return valor.isoformat()
    return str(valor)


def conteudo(linhas: list[dict]) -> tuple[list[str], list[str], Counter]:
    """As colunas comparadas, as excluídas (metadado de execução) e o multiconjunto das linhas normalizadas."""
    colunas = sorted({c for linha in linhas for c in linha}) if linhas else []
    excluidas = [c for c in colunas if c.startswith("_")]
    comparadas = [c for c in colunas if not c.startswith("_")]
    return comparadas, excluidas, Counter(tuple(_valor_normal(linha.get(c)) for c in comparadas) for linha in linhas)


def comparar_views(local: dict[str, list[dict]], nuvem: dict[str, list[dict]], exemplos: int = 3) -> list[str]:
    problemas = []
    for view in sorted(set(local) | set(nuvem)):
        if view not in local or view not in nuvem:
            problemas.append(f"{view}: só {'no local' if view in local else 'no BigQuery'}")
            continue
        cl, el, a = conteudo(local[view])
        cn, en, b = conteudo(nuvem[view])
        if local[view] and nuvem[view] and cl != cn:
            problemas.append(f"{view}: colunas diferentes — só local {sorted(set(cl) - set(cn))}, "
                             f"só BigQuery {sorted(set(cn) - set(cl))}")
            continue
        if a != b:
            so_local, so_nuvem = a - b, b - a
            problemas.append(f"{view}: {sum(so_local.values())} linha(s) só no local e {sum(so_nuvem.values())} só no "
                             f"BigQuery; ex. local {list(so_local)[:exemplos]}, BigQuery {list(so_nuvem)[:exemplos]}")
        elif el or en:
            print(f"  {view}: igual, sem as colunas de execução {sorted(set(el) | set(en))}")
    return problemas


def consumo(cliente, projeto: str) -> int:
    """O conteúdo de cada view de `consumption` nos dois alvos (a soma de controle da §7.2)."""
    engine = create_engine(database_url(WAREHOUSE))
    with engine.connect() as conn:
        nomes = [r[0] for r in conn.execute(text(
            "select table_name from information_schema.tables where table_schema = 'consumption' order by 1")).all()]
        local = {n: [dict(r) for r in conn.execute(text(f'select * from consumption."{n}"')).mappings()] for n in nomes}
    nuvem = {t.table_id: [dict(r.items()) for r in cliente.query(f"select * from `{projeto}.consumption.{t.table_id}`").result()]
             for t in cliente.list_tables(f"{projeto}.consumption")}
    problemas = comparar_views(local, nuvem)
    for problema in problemas:
        print(f"  {problema}")
    iguais = len((set(local) & set(nuvem)) - {p.split(":", 1)[0] for p in problemas})
    print(f"consumo: {iguais} views iguais em conteúdo, {len(problemas)} diferentes ou de um lado só")
    return 1 if problemas or not local else 0


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
    if args.modelo == "consumo":
        return consumo(cliente, projeto)
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
