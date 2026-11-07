"""Oráculo de compilação: o caminho local não muda quando o modelo passa a ter dois alvos.

A Etapa 13 reescreve modelos para o BigQuery por macros com duas metades (`default__` e
`bigquery__`) e por corpos duplos gerados. A garantia de que o PostgreSQL continua o mesmo
é comparar o compilado do alvo local **antes** e **depois** da mudança, arquivo a arquivo:

* **igual** — o texto é o mesmo, caractere a caractere;
* **equivalente** — o texto mudou, a árvore não: o `sqlglot` lê os dois como PostgreSQL e
  escreve a mesma consulta (`x::int` e `cast(x as int)`, um espaço a mais), sem os
  comentários — o `sqlglot` os pendura no nó mais próximo, e um `cast` em volta muda o nó;
* **diferente** — a consulta mudou. Isso é defeito até prova em contrário, e sai listado.

    python -m mvp_ed1.gcp.compilacao <compilado de antes> <compilado de depois> [--rodar]

Com `--rodar`, cada arquivo diferente na árvore é executado nos dois textos contra o armazém
local, e conta como mudança só se as linhas ou os tipos mudam. Sai com código 1 se algum
arquivo muda de resultado, falta ou sobra.
"""

from __future__ import annotations

import sys
from pathlib import Path

import sqlglot
from sqlglot.errors import ParseError


def _arvore(sql: str) -> list[str] | None:
    try:
        return [a.sql(dialect="postgres", comments=False) for a in sqlglot.parse(sql, read="postgres") if a is not None]
    except (ParseError, ValueError):
        return None


def comparar(antes: Path, depois: Path) -> dict[str, list[str]]:
    a = {p.relative_to(antes): p for p in antes.rglob("*.sql") if p.is_file()}
    d = {p.relative_to(depois): p for p in depois.rglob("*.sql") if p.is_file()}
    saida: dict[str, list[str]] = {"igual": [], "equivalente": [], "diferente": [],
                                   "só antes": [], "só depois": []}
    saida["só antes"] = sorted(str(k) for k in set(a) - set(d))
    saida["só depois"] = sorted(str(k) for k in set(d) - set(a))
    for k in sorted(set(a) & set(d)):
        ta, td = a[k].read_text(encoding="utf-8"), d[k].read_text(encoding="utf-8")
        if ta == td:
            saida["igual"].append(str(k))
            continue
        xa, xd = _arvore(ta), _arvore(td)
        saida["equivalente" if xa is not None and xa == xd else "diferente"].append(str(k))
    return saida


def mesmo_resultado(antes: str, depois: str) -> tuple[bool, str]:
    """Roda as duas consultas no armazém local e compara linhas (multiconjunto) e tipos.

    É a prova do que o `sqlglot` não iguala: `100.0` e `cast(100.0 as numeric)` são árvores
    diferentes e o mesmo valor. Só serve para `select` (modelo ou teste compilado).
    """
    from sqlalchemy import create_engine, text

    from mvp_ed1.db import WAREHOUSE, database_url

    a, d = antes.strip().rstrip(";"), depois.strip().rstrip(";")
    engine = create_engine(database_url(WAREHOUSE))
    with engine.connect() as conn:
        tipos = []
        for q in (a, d):
            r = conn.execute(text(f"select * from ({q}) as q limit 0"))
            tipos.append([(c[0], c[1]) for c in r.cursor.description])
        if tipos[0] != tipos[1]:
            return False, f"tipos: {tipos[0]} × {tipos[1]}"
        n = conn.execute(text(
            f"select count(*) from (({a}) except all ({d})) x"
        )).scalar() + conn.execute(text(f"select count(*) from (({d}) except all ({a})) x")).scalar()
        linhas = conn.execute(text(f"select count(*) from ({a}) as q")).scalar()
    return n == 0, f"{linhas} linhas, {n} divergentes"


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    rodar = "--rodar" in args
    args = [a for a in args if a != "--rodar"]
    if len(args) != 2:
        raise SystemExit(__doc__)
    r = comparar(Path(args[0]), Path(args[1]))
    for nome, lista in r.items():
        print(f"{nome}: {len(lista)}")
    falhou = bool(r["só antes"] or r["só depois"])
    for nome in ("só antes", "só depois"):
        for k in r[nome]:
            print(f"  {nome}: {k}")
    for k in r["diferente"]:
        if not rodar:
            print(f"  diferente: {k}")
            falhou = True
            continue
        ok, detalhe = mesmo_resultado((Path(args[0]) / k).read_text(encoding="utf-8"),
                                      (Path(args[1]) / k).read_text(encoding="utf-8"))
        print(f"  diferente na árvore, {'mesmo' if ok else 'OUTRO'} resultado no armazém: {k} ({detalhe})")
        falhou = falhou or not ok
    return 1 if falhou else 0


if __name__ == "__main__":
    sys.exit(main())
