"""A medição da D43: as três noções de "mesma chave", nos dois armazéns (Etapa 13, G1.6).

A [D43](../../../docs/pendencias.md) pergunta como a guarda de identidade do legado deve ser
escrita, e o plano da Etapa 13 (§2.3) manda medi-la antes de o Owner decidir: **até lá, não se
declara paridade de identidade**. Há três noções de "mesma chave" no código:

- **texto** — a igualdade textual da resolução do pai (`classification.sql`, CTE `edges`);
- **identidade** — `identidade_canonica` (decimal por extenso, R29), a da reconciliação da
  quarentena;
- **chave** — `chave_canonica` (a gramática do `cast` do tipo, ADR-0045), a da remoção física.

Este módulo roda cada noção, **pela macro real** renderizada na metade de cada alvo, sobre as
formas que provam a canonização (`tests/test_legado_remocao.py::FORMAS`), uma forma por consulta —
um erro numa forma não derruba as outras e vira o resultado dela (`ERRO: …`). Mede duas coisas:

1. **paridade** — cada noção devolve o mesmo nos dois armazéns, forma a forma;
2. **divergência entre noções** — os pares de formas que uma noção diz serem a mesma chave e outra
   não; é o caso do cliente `'8'` → `'0x8'` da pendência.

    python -m mvp_ed1.gcp.identidades            # os dois armazéns; precisa de GCP_PROJECT_ID
    python -m mvp_ed1.gcp.identidades --saida data/medicoes/etapa_13/d43/medicao.json
"""

from __future__ import annotations

import argparse
import itertools
import json
import os
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]
MACROS = RAIZ / "dbt" / "macros"

#: A chave de negócio do legado em todas as tabelas inteiras é `bigint`; as formas de `integer`
#: e `smallint` entram na mesma conta, lidas como `bigint`, que é o que a ponte faz.
TIPOS = ("bigint", "integer", "smallint", "uuid")


class _Excecoes:
    def raise_compiler_error(self, mensagem):  # noqa: D401 — a interface do dbt
        raise RuntimeError(mensagem)


def _macros(alvo: str) -> dict:
    """As metades `default__` (PostgreSQL) ou `bigquery__` das duas macros, como funções."""
    import jinja2

    prefixo = "default__" if alvo == "postgres" else "bigquery__"
    saida = {}
    for arquivo, nome in (("identidade_do_vinculo.sql", "identidade_canonica"), ("chave_canonica.sql", "chave_canonica")):
        fonte = (MACROS / arquivo).read_text(encoding="utf-8")
        modulo = jinja2.Environment().from_string(fonte, globals={"exceptions": _Excecoes()}).module
        saida[nome] = getattr(modulo, prefixo + nome)
    return saida


def formas() -> list[tuple[str, str]]:
    """(tipo, forma) de cada forma da prova da canonização, sem repetir a mesma forma no mesmo tipo."""
    # O módulo de teste importa as *fixtures* dos vizinhos pelo nome curto, como o pytest os põe no
    # caminho; aqui, o mesmo caminho.
    for pasta in (RAIZ, RAIZ / "tests"):
        if str(pasta) not in sys.path:
            sys.path.insert(0, str(pasta))
    from tests.test_legado_remocao import FORMAS

    vistas, saida = set(), []
    for tipo in TIPOS:
        for f in FORMAS[tipo]:
            if (tipo, f) not in vistas:
                vistas.add((tipo, f))
                saida.append((tipo, f))
    return saida


def _expressoes(alvo: str, tipo: str) -> dict[str, str]:
    m = _macros(alvo)
    tipo_da_chave = "bigint" if tipo in ("integer", "smallint") else tipo
    return {"identidade": str(m["identidade_canonica"]("v")), "chave": str(m["chave_canonica"]("v", tipo_da_chave))}


def _erro(e: Exception) -> str:
    return "ERRO: " + str(e).strip().splitlines()[0][:120]


def no_postgres(lista: list[tuple[str, str]]) -> list[dict]:
    from sqlalchemy import create_engine, text

    from mvp_ed1.db import WAREHOUSE, database_url

    saida = []
    with create_engine(database_url(WAREHOUSE)).connect() as conn:
        for tipo, f in lista:
            linha = {}
            for nocao, expr in _expressoes("postgres", tipo).items():
                sql = text(f"select {expr} from (select cast(:v as text) as v) s")
                try:
                    with conn.begin_nested():
                        linha[nocao] = conn.execute(sql, {"v": f}).scalar()
                except Exception as e:  # noqa: BLE001 — o erro é a medida
                    linha[nocao] = _erro(e)
            saida.append(linha)
    return saida


def no_bigquery(lista: list[tuple[str, str]], projeto: str) -> list[dict]:
    from google.cloud import bigquery

    cliente = bigquery.Client(project=projeto)
    saida = []
    for tipo, f in lista:
        linha = {}
        for nocao, expr in _expressoes("bigquery", tipo).items():
            sql = f"select {expr} from (select @v as v)"
            config = bigquery.QueryJobConfig(query_parameters=[bigquery.ScalarQueryParameter("v", "STRING", f)])
            try:
                linha[nocao] = next(iter(cliente.query(sql, job_config=config).result()))[0]
            except Exception as e:  # noqa: BLE001 — o erro é a medida
                linha[nocao] = _erro(e)
        saida.append(linha)
    return saida


def _curta(f: str) -> str:
    """A forma legível num relatório: as longas viram o começo e o tamanho."""
    r = repr(f)
    return r if len(r) <= 40 else f"{r[:30]}…' ({len(f)} caracteres)"


def _recusa(valor) -> bool:
    return isinstance(valor, str) and valor.startswith("ERRO")


def _mesmo(a, b) -> bool:
    """O mesmo resultado nos dois armazéns: o mesmo valor, ou os dois recusam a forma — a mensagem
    de erro é de cada motor e não entra na conta."""
    return (_recusa(a) and _recusa(b)) or (not _recusa(a) and not _recusa(b) and str(a) == str(b))


def comparar(lista, pg, bq) -> dict:
    paridade = {}
    for nocao in ("identidade", "chave"):
        diverge = [{"tipo": t, "forma": _curta(f), "postgres": p[nocao], "bigquery": b[nocao]}
                   for (t, f), p, b in zip(lista, pg, bq) if not _mesmo(p[nocao], b[nocao])]
        recusam = sum(_recusa(p[nocao]) and _recusa(b[nocao]) for p, b in zip(pg, bq))
        paridade[nocao] = {"formas": len(lista), "divergentes": len(diverge), "recusadas_nos_dois": recusam,
                           "casos": diverge}

    # Divergência entre noções, no PostgreSQL (o alvo de referência), por tipo: um par de formas
    # que convertem é "a mesma chave" para uma noção quando ela devolve o mesmo valor às duas.
    pares = {}
    for tipo in TIPOS:
        idx = [i for i, (t, _) in enumerate(lista) if t == tipo]
        conta = {"pares": 0, "chave_sim_identidade_nao": [], "identidade_sim_chave_nao": [], "texto_nao_chave_sim": 0}
        for i, j in itertools.combinations(idx, 2):
            ci, cj, ii, ij = pg[i]["chave"], pg[j]["chave"], pg[i]["identidade"], pg[j]["identidade"]
            if any(isinstance(x, str) and x.startswith("ERRO") for x in (ci, cj, ii, ij)):
                continue
            conta["pares"] += 1
            mesma_chave = ci is not None and ci == cj
            mesma_identidade = ii is not None and ii == ij
            par = [_curta(lista[i][1]), _curta(lista[j][1])]
            if mesma_chave and not mesma_identidade:
                conta["chave_sim_identidade_nao"].append(par)
            if mesma_identidade and not mesma_chave:
                conta["identidade_sim_chave_nao"].append(par)
            if mesma_chave:
                conta["texto_nao_chave_sim"] += 1  # formas distintas por construção: o texto diz "outra chave"
        pares[tipo] = conta
    return {"paridade": paridade, "entre_nocoes": pares}


def main(argv: list[str] | None = None) -> int:
    args = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    args.add_argument("--saida", type=Path)
    opcoes = args.parse_args(argv)
    projeto = os.environ.get("GCP_PROJECT_ID")
    if not projeto:
        print("GCP_PROJECT_ID ausente no ambiente", file=sys.stderr)
        return 2
    lista = formas()
    pg, bq = no_postgres(lista), no_bigquery(lista, projeto)
    resultado = comparar(lista, pg, bq)
    resultado["formas"] = [{"tipo": t, "forma": _curta(f), "postgres": p, "bigquery": b}
                           for (t, f), p, b in zip(lista, pg, bq)]
    for nocao, r in resultado["paridade"].items():
        print(f"paridade {nocao}: {r['formas'] - r['divergentes']} de {r['formas']} formas com o mesmo resultado "
              f"nos dois armazéns ({r['recusadas_nos_dois']} recusadas pelos dois)")
        for c in r["casos"]:
            print(f"  {c['tipo']:8} {c['forma']:45} PG={str(c['postgres'])[:50]!s:52} BQ={str(c['bigquery'])[:50]}")
    for tipo, c in resultado["entre_nocoes"].items():
        print(f"{tipo}: {c['pares']} pares; a chave casa e a identidade não: {len(c['chave_sim_identidade_nao'])}; "
              f"a identidade casa e a chave não: {len(c['identidade_sim_chave_nao'])}; "
              f"o texto separa o que a chave junta: {c['texto_nao_chave_sim']}")
    if opcoes.saida:
        opcoes.saida.parent.mkdir(parents=True, exist_ok=True)
        opcoes.saida.write_text(json.dumps(resultado, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
