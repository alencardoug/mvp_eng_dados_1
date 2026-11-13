"""Atribuição da diferença de paridade: o `analytics` exportado do BigQuery contra o local (G8).

Na quarta, 11/11/2026, o `gcp-oraculos` deu 0 de 16 views de `consumption` iguais, e o conteúdo
delas no BigQuery não foi guardado (Registro §55, passo 15; `PLANO_etapa_13.md` §11.4). O que
sobrou da nuvem são as 25 tabelas de `analytics` que o banco de provas `nl_sql` exportou em Parquet
às 17:22 de quarta — o `analytics` do `gcp-dbt-build` de terça, porque a `dbt_analytics` daquela
execução só rodou depois. As views leem delas; a atribuição se mede ali.

Cada tabela é casada pela **chave substituta** (a primeira coluna, `*_key`) e separada por
`source_system` quando a tabela tem a coluna. A chave das dimensões SCD tipo 2 (as que têm
`valid_from` e `<entidade>_natural_key`) **não é a mesma nos dois dialetos** — o *hash* que a gera
difere —, então ela é trocada, nos dois lados, pela identidade da versão: `source_system`, chave
natural e a ordem da versão por `valid_from`. A troca alcança as chaves estrangeiras das fatos.

Para cada grupo: linhas de um lado só, linhas iguais e linhas diferentes, e, nas diferentes, quantas
vezes cada coluna diverge. A normalização é a do oráculo de consumo (`oraculo._valor_normal`):
número com 6 casas, instante em UTC, data em ISO. Colunas de metadado de execução (as que começam
com `_`) saem, declaradas.

**Limites** (RVG8-1-05): "igual" é igualdade da projeção normalizada, não de tipo — número e texto
com a mesma grafia, ou dois decimais que só diferem depois da sexta casa, saem iguais; coluna
presente num lado só sai da comparação e vai listada no relatório; a chave é a primeira coluna
`*_key`, sem conferir a PK declarada; o inventário é o dos arquivos da pasta, então tabela que
falta no Parquet não é acusada. Basta para atribuir uma diferença; não certifica paridade sozinho.

É medida, não asserção: sai com 0 quando mede, e o relatório diz o que achou. Sai com 1 se uma
tabela do Parquet não existe no armazém local, ou se a primeira coluna não é chave.

    python -m mvp_ed1.gcp.atribuicao --parquet ~/Projetos/data/nl_sql/dados \\
        --saida data/medicoes/etapa_13/g8/atribuicao.json
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

from mvp_ed1.gcp.oraculo import _valor_normal

#: O grupo de quem não tem `source_system` (as dimensões conformadas, como `dim_date`).
SEM_ORIGEM = "(sem source_system)"


def _grupo(linha: dict) -> str:
    return str(linha["source_system"]) if "source_system" in linha else SEM_ORIGEM


def comparar_tabela(local: list[dict], nuvem: list[dict], exemplos: int = 3) -> dict:
    """O relatório de uma tabela: por grupo, o que é de um lado só, igual ou diferente, e por coluna."""
    colunas = list(dict.fromkeys(c for linha in (local[:1] + nuvem[:1]) for c in linha))
    if not colunas or not colunas[0].endswith("_key"):
        raise ValueError(f"a primeira coluna não é chave substituta: {colunas[:1]}")
    chave = colunas[0]
    so_local_cols = sorted(set(local[0]) - set(nuvem[0])) if local and nuvem else []
    so_nuvem_cols = sorted(set(nuvem[0]) - set(local[0])) if local and nuvem else []
    excluidas = sorted(c for c in colunas if c.startswith("_"))
    comparadas = [c for c in colunas if not c.startswith("_") and c not in so_local_cols + so_nuvem_cols]

    def indexa(linhas: list[dict]) -> dict[str, dict[object, dict]]:
        saida: dict[str, dict[object, dict]] = {}
        for linha in linhas:
            k = linha[chave]
            grupo = saida.setdefault(_grupo(linha), {})
            if k in grupo:
                raise ValueError(f"chave {chave}={k!r} repetida")
            grupo[k] = {c: _valor_normal(linha.get(c)) for c in comparadas}
        return saida

    a, b = indexa(local), indexa(nuvem)
    grupos = {}
    for g in sorted(set(a) | set(b)):
        la, lb = a.get(g, {}), b.get(g, {})
        so_local = sorted(set(la) - set(lb), key=str)
        so_nuvem = sorted(set(lb) - set(la), key=str)
        comuns = set(la) & set(lb)
        por_coluna: Counter = Counter()
        diferentes = []
        for k in comuns:
            divergem = [c for c in comparadas if la[k][c] != lb[k][c]]
            if divergem:
                diferentes.append(k)
                por_coluna.update(divergem)
        grupos[g] = {
            "local": len(la), "nuvem": len(lb),
            "so_local": len(so_local), "so_nuvem": len(so_nuvem),
            "iguais": len(comuns) - len(diferentes), "diferentes": len(diferentes),
            "colunas_que_divergem": dict(por_coluna.most_common()),
            "exemplos_so_local": [str(k) for k in so_local[:exemplos]],
            "exemplos_so_nuvem": [str(k) for k in so_nuvem[:exemplos]],
            "exemplos_diferentes": [
                {"chave": str(k), **{c: [la[k][c], lb[k][c]] for c in comparadas if la[k][c] != lb[k][c]}}
                for k in sorted(diferentes, key=str)[:exemplos]
            ],
        }
    return {"chave": chave, "colunas_excluidas": excluidas,
            "colunas_so_local": so_local_cols, "colunas_so_nuvem": so_nuvem_cols, "grupos": grupos}


def identidades_scd(tabela: str, linhas: list[dict]) -> dict[object, tuple] | None:
    """A chave de cada versão de uma dimensão SCD tipo 2 → (`source_system`, chave natural, ordem da versão).

    `None` se a tabela não é SCD tipo 2 (sem `valid_from` ou sem `<entidade>_natural_key`).
    """
    entidade = tabela.removeprefix("dim_")
    chave, natural = f"{entidade}_key", f"{entidade}_natural_key"
    if not linhas or not {chave, natural, "valid_from", "source_system"} <= set(linhas[0]):
        return None
    ordem: Counter = Counter()
    saida = {}
    for linha in sorted(linhas, key=lambda r: (str(r["source_system"]), str(r[natural]), r["valid_from"])):
        entidade_id = (str(linha["source_system"]), str(linha[natural]))
        ordem[entidade_id] += 1
        saida[linha[chave]] = (*entidade_id, ordem[entidade_id])
    return saida


def resolver(linhas: list[dict], mapas: dict[str, dict[object, tuple]], lado: str) -> list[dict]:
    """As linhas com cada coluna de `mapas` (a chave SCD ou a estrangeira para ela) trocada pela identidade.

    Chave sem versão conhecida vira `?<lado>|valor`: aparece como divergência, não some — nem quando
    o mesmo valor desconhecido está dos dois lados (RVG8-1-05).
    """
    return [{c: (("|".join(map(str, mapas[c][v])) if v in mapas[c] else f"?{lado}|{v}")
                 if c in mapas and v is not None else v)
             for c, v in linha.items()} for linha in linhas]


def _linha_resumo(tabela: str, relatorio: dict) -> list[str]:
    linhas = []
    for g, r in relatorio["grupos"].items():
        cols = ", ".join(f"{c} {n}" for c, n in list(r["colunas_que_divergem"].items())[:4])
        linhas.append(f"  {tabela} [{g}]: local {r['local']}, nuvem {r['nuvem']} · só local {r['so_local']}, "
                      f"só nuvem {r['so_nuvem']}, iguais {r['iguais']}, diferentes {r['diferentes']}"
                      + (f" ({cols})" if cols else ""))
    if relatorio["colunas_so_local"] or relatorio["colunas_so_nuvem"]:
        linhas.append(f"  {tabela}: colunas só local {relatorio['colunas_so_local']}, "
                      f"só nuvem {relatorio['colunas_so_nuvem']}")
    return linhas


def main(argv: list[str] | None = None) -> int:
    import pyarrow.parquet as pq
    from sqlalchemy import create_engine, text

    from mvp_ed1.db import WAREHOUSE, database_url

    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    # `expanduser`: o `make` passa o caminho entre aspas simples, e o `~` não se expande no shell.
    ap.add_argument("--parquet", required=True, type=lambda p: Path(p).expanduser(),
                    help="pasta com um <tabela>.parquet por tabela de analytics")
    ap.add_argument("--saida", required=True, type=lambda p: Path(p).expanduser(), help="o relatório em JSON")
    args = ap.parse_args(argv)

    arquivos = sorted(args.parquet.glob("*.parquet"))
    if not arquivos:
        print(f"atribuicao: nenhum .parquet em {args.parquet}", file=sys.stderr)
        return 1
    engine = create_engine(database_url(WAREHOUSE))
    relatorio: dict[str, dict] = {}
    rc = 0
    with engine.connect() as conn:
        existentes = {r[0] for r in conn.execute(text(
            "select table_name from information_schema.tables where table_schema = 'analytics'"))}
        dados = {}
        for arquivo in arquivos:
            tabela = arquivo.stem
            if tabela not in existentes:
                print(f"  {tabela}: não existe em analytics no armazém local")
                rc = 1
                continue
            dados[tabela] = ([dict(r) for r in conn.execute(text(f'select * from analytics."{tabela}"')).mappings()],
                             pq.read_table(arquivo).to_pylist())
        # As chaves SCD de cada lado, pela identidade da versão; a mesma coluna nas fatos é estrangeira.
        mapas_local, mapas_nuvem = {}, {}
        for tabela, (local, nuvem) in dados.items():
            a, b = identidades_scd(tabela, local), identidades_scd(tabela, nuvem)
            if a is not None and b is not None:
                coluna = f"{tabela.removeprefix('dim_')}_key"
                mapas_local[coluna], mapas_nuvem[coluna] = a, b
        if mapas_local:
            print(f"atribuicao: chaves SCD resolvidas pela versão: {', '.join(sorted(mapas_local))}")
        for tabela, (local, nuvem) in dados.items():
            try:
                relatorio[tabela] = comparar_tabela(resolver(local, mapas_local, "local"),
                                                   resolver(nuvem, mapas_nuvem, "nuvem"))
            except ValueError as erro:
                print(f"  {tabela}: {erro}")
                rc = 1
                continue
            for linha in _linha_resumo(tabela, relatorio[tabela]):
                print(linha)
    args.saida.parent.mkdir(parents=True, exist_ok=True)
    args.saida.write_text(json.dumps(relatorio, ensure_ascii=False, indent=2, default=str) + "\n")
    print(f"atribuicao: {len(relatorio)} tabelas comparadas · {args.saida}")
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
