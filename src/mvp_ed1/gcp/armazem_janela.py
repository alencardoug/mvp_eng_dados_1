"""O armazém da nuvem antes da primeira captura: zerar, criar a governança e conferir (Etapa 13).

Até a janela, o BigQuery tem o que o desenvolvimento pôs nele: a cópia do bruto e do certificado
**do armazém local** (`gcp-carga-dev`) e o que os `dbt build` de ensaio materializaram em cima dela.
A época inicial do livro é um retrato da memória — capturas, certificado, quarentena, exclusões,
versões. Tirada sobre a cópia, registraria a fase local como a memória da nuvem. A ordem, na terça:

1. `zerar` — apaga toda tabela e *view* dos nove *datasets* (os *datasets*, o IAM e as *policy
   tags* são do Terraform e ficam);
2. `governanca` — as migrações do `governance` no BigQuery (`governance.garantir_bigquery`), que
   até aqui só os testes chamavam;
3. `pronto` — a época inicial só abre com o livro sem época e o armazém sem dado: nenhuma *view* e
   nenhuma linha fora do `governance._versions`.

    python -m mvp_ed1.gcp.armazem_janela zerar --datasets '["raw", …]' --confirmar PROJETO
    python -m mvp_ed1.gcp.armazem_janela governanca
    python -m mvp_ed1.gcp.armazem_janela pronto --datasets '["raw", …]'
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any

#: A única tabela com linhas que a época inicial aceita: o registro das migrações do `governance`.
VERSOES = ("governance", "_versions")


def _tabelas(cliente, projeto: str, datasets: list[str]):
    for dataset in datasets:
        for item in cliente.list_tables(f"{projeto}.{dataset}"):
            yield dataset, item


def zerar(cliente, projeto: str, datasets: list[str]) -> dict[str, int]:
    """Apaga toda tabela e *view* dos *datasets*; devolve quantas por *dataset*."""
    apagadas: dict[str, int] = {}
    for dataset, item in list(_tabelas(cliente, projeto, datasets)):
        cliente.delete_table(f"{projeto}.{dataset}.{item.table_id}", not_found_ok=True)
        apagadas[dataset] = apagadas.get(dataset, 0) + 1
    return apagadas


def residuos(cliente, projeto: str, datasets: list[str]) -> list[str]:
    """O que impede a época inicial: *view*, ou tabela com linha que não seja o `_versions`."""
    achados = []
    for dataset, item in _tabelas(cliente, projeto, datasets):
        nome = f"{dataset}.{item.table_id}"
        if item.table_type != "TABLE":
            achados.append(f"{nome} ({item.table_type.lower()})")
            continue
        if (dataset, item.table_id) == VERSOES:
            continue
        linhas = cliente.get_table(f"{projeto}.{nome}").num_rows or 0
        if linhas:
            achados.append(f"{nome} ({linhas} linhas)")
    return achados


def _cliente(projeto: str):
    from google.cloud import bigquery

    return bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION"))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.gcp.armazem_janela", description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="comando", required=True)
    s = sub.add_parser("zerar")
    s.add_argument("--datasets", required=True, help="a saída `terraform output -json datasets`")
    s.add_argument("--confirmar", required=True, help="o id do projeto, repetido")
    sub.add_parser("governanca")
    s = sub.add_parser("pronto")
    s.add_argument("--datasets", required=True)
    args = ap.parse_args(argv)

    projeto = os.environ["GCP_PROJECT_ID"]
    cliente = _cliente(projeto)
    if args.comando == "governanca":
        from mvp_ed1 import governance

        aplicadas = governance.garantir_bigquery(cliente, projeto)
        print("governance (BigQuery): " + (", ".join(aplicadas) if aplicadas else "nada a aplicar"))
        return 0

    datasets: list[Any] = json.loads(args.datasets)
    if not datasets:
        print("ERRO: nenhum dataset na saída do Terraform (degrau barato não aplicado).", file=sys.stderr)
        return 1
    if args.comando == "zerar":
        if args.confirmar != projeto:
            print(f"ERRO: apaga toda tabela das camadas; repita com CONFIRMA={projeto}.", file=sys.stderr)
            return 1
        apagadas = zerar(cliente, projeto, datasets)
        print(f"armazém zerado: {sum(apagadas.values())} tabelas e views apagadas "
              + json.dumps(apagadas, ensure_ascii=False, sort_keys=True))
        return 0

    from mvp_ed1.recovery import ledger

    raiz = ledger.root()
    epocas = ledger.epochs(raiz)
    problemas = [f"o livro já tem {len(epocas)} época(s) em {raiz}"] if epocas else []
    problemas += [f"no armazém: {r}" for r in residuos(cliente, projeto, datasets)]
    for problema in problemas:
        print(f"RECUSADO — {problema}", file=sys.stderr)
    if problemas:
        return 1
    print(f"pronto para a época inicial: livro vazio em {raiz}, armazém sem dado")
    return 0


if __name__ == "__main__":
    sys.exit(main())
