"""Re-execução de tarefas de uma execução da DAG no Composer, pela API REST do Airflow (Etapa 13).

Em 11/11/2026 a `fluxo_batch` parou três vezes depois da ingestão (IAM do `dbt seed`, corrida no
teste de saldo, `create or replace view` no `raw`) e foi retomada **na mesma execução**, sem
refazer a captura certificada, por `POST /api/v2/dags/{dag}/clearTaskInstances` com `curl`
(Registro §55, passo 9). A CLI do Airflow (`tasks clear`) não serviu: ela seleciona por data, e uma
execução manual do Airflow 3 nasce sem `logical_date`. Este módulo é aquele `curl`, versionado.

    python -m mvp_ed1.gcp.composer_api limpar --uri URI --dag fluxo_batch --run RUN [--tarefas a,b] [--aplicar]

Sem `--tarefas`, só as falhas (`failed` e `upstream_failed`); com elas, exatamente as nomeadas. O
**ensaio** (`dry_run`) roda sempre antes e lista o que seria limpo; sem `--aplicar`, para aí.
Uma lista vazia no ensaio é erro: limpar nada não é sucesso.
"""

from __future__ import annotations

import argparse
import sys
from typing import Any


class ErroDaApi(RuntimeError):
    pass


def _sessao():
    import google.auth
    import google.auth.transport.requests as transporte

    cred, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    return transporte.AuthorizedSession(cred)


def corpo(run: str, tarefas: list[str] | None, *, ensaio: bool) -> dict[str, Any]:
    """O pedido de `clearTaskInstances`: as nomeadas, ou só as falhas; nunca as de cima ou de baixo."""
    pedido: dict[str, Any] = {
        "dag_run_id": run,
        "dry_run": ensaio,
        "reset_dag_runs": True,
        "include_upstream": False,
        "include_downstream": False,
    }
    if tarefas:
        pedido.update(task_ids=list(tarefas), only_failed=False)
    else:
        pedido.update(only_failed=True)
    return pedido


def limpar(sessao, uri: str, dag: str, run: str, tarefas: list[str] | None, *, ensaio: bool) -> list[tuple[str, str]]:
    """As tarefas `(task_id, estado)` que o pedido limpa (ou limparia, no ensaio)."""
    resposta = sessao.post(f"{uri.rstrip('/')}/api/v2/dags/{dag}/clearTaskInstances", json=corpo(run, tarefas, ensaio=ensaio))
    if resposta.status_code != 200:
        raise ErroDaApi(f"clearTaskInstances respondeu {resposta.status_code}: {resposta.text[:300]}")
    dados = resposta.json()
    return [(t["task_id"], str(t.get("state"))) for t in dados.get("task_instances", [])]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="mvp_ed1.gcp.composer_api", description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="comando", required=True)
    s = sub.add_parser("limpar")
    s.add_argument("--uri", required=True, help="config.airflowUri do ambiente")
    s.add_argument("--dag", required=True)
    s.add_argument("--run", required=True)
    s.add_argument("--tarefas", default="", help="task_ids separados por vírgula; vazio = só as falhas")
    s.add_argument("--aplicar", action="store_true", help="sem isto, só o ensaio")
    args = ap.parse_args(argv)
    tarefas = [t.strip() for t in args.tarefas.split(",") if t.strip()] or None
    sessao = _sessao()
    try:
        previstas = limpar(sessao, args.uri, args.dag, args.run, tarefas, ensaio=True)
        if not previstas:
            print(f"ERRO: o ensaio não achou nada a limpar em {args.run}", file=sys.stderr)
            return 1
        print(f"ensaio: {len(previstas)} tarefa(s) de {args.run}")
        for tarefa, estado in previstas:
            print(f"  {tarefa:<40} {estado}")
        if not args.aplicar:
            print("nada foi limpo: repita com APLICAR=1 para re-executar estas tarefas")
            return 0
        limpas = limpar(sessao, args.uri, args.dag, args.run, tarefas, ensaio=False)
        print(f"limpas: {len(limpas)}; acompanhe com make gcp-composer-tarefas DAG={args.dag} RUN={args.run}")
    except ErroDaApi as erro:
        print(f"ERRO: {erro}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
