"""A prova do layout da DAG antes da janela (Etapa 13, G2.4).

Roda **dentro** da imagem do Composer (`composer-3-airflow-3.2.2-build.9`), com o layout de
`mvp_ed1.gcp.composer` montado somente leitura em `/home/airflow/gcs` e os pacotes de
`airflow/requirements-composer.txt` instalados por cima, como o ambiente faz. Este módulo é
importado de `dags/mvp_ed1`, não do repositório — é a primeira coisa que ele prova. Depois:

1. a DAG importa pelo processador de DAGs do Airflow, sem erro, com as 15 tarefas, e o
   `.airflowignore` tira o pacote da varredura;
2. o comando **da própria tarefa** de dbt pedida, renderizado como o Airflow renderiza, roda no
   layout contra o BigQuery: `cd` pela variável do ambiente, *target* e *logs* num temporário que
   some no fim, e nada escrito em `data/`.

O `legacy_snapshot_id` que a tarefa receberia da fase 2 do certificado é o da captura certificada
mais recente no BigQuery — a mesma regra que o modelo usa quando a variável falta.

    python -m mvp_ed1.gcp.prova_composer --tarefa dbt_staging --saida /saida/prova.json
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

PASTA = Path("/home/airflow/gcs")
TAREFAS_DA_DAG = 15


def _dagbag(pasta: Path):
    try:
        from airflow.dag_processing.dagbag import DagBag
    except ImportError:  # o caminho antigo, ainda exportado no 3.2
        from airflow.models.dagbag import DagBag
    return DagBag(dag_folder=str(pasta), include_examples=False)


def _snapshot_certificado(projeto: str) -> int:
    from google.cloud import bigquery

    sql = f"""
        with certificadas as (
          select snapshot_id from `{projeto}.governance.legacy_captures`
          where status = 'complete' group by snapshot_id having count(distinct source_table) = 40)
        select max(snapshot_id) from certificadas"""
    cliente = bigquery.Client(project=projeto, location=os.environ.get("GCP_BQ_LOCATION"))
    return int(next(iter(cliente.query(sql).result()))[0])


class _Instancia:
    """O `ti` do *template*: só o `xcom_pull` que as tarefas de dbt usam."""

    def __init__(self, snapshot: int):
        self.snapshot = snapshot

    def xcom_pull(self, task_ids: str):
        assert task_ids == "concluir_captura_do_legado", task_ids
        return self.snapshot


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m mvp_ed1.gcp.prova_composer")
    parser.add_argument("--tarefa", default="dbt_staging")
    parser.add_argument("--saida")
    args = parser.parse_args(argv)

    import jinja2

    import mvp_ed1

    relatorio: dict[str, Any] = {"pacote_importado_de": str(Path(mvp_ed1.__file__).parent), "falhas": []}
    if not relatorio["pacote_importado_de"].startswith(str(PASTA / "dags")):
        relatorio["falhas"].append("o pacote não veio de dags/")

    from importlib import metadata

    relatorio["versoes"] = {p: metadata.version(p) for p in (
        "apache-airflow", "dbt-core", "dbt-bigquery", "google-api-core", "google-cloud-bigquery",
        "SQLAlchemy", "psycopg", "PyYAML")}

    inicio = time.monotonic()
    bag = _dagbag(PASTA / "dags")
    relatorio["importacao"] = {
        "segundos": round(time.monotonic() - inicio, 1),
        "erros": {str(k): str(v)[:500] for k, v in bag.import_errors.items()},
        "arquivos_varridos": sorted(str(Path(f).relative_to(PASTA)) for f in bag.file_last_changed),
    }
    if bag.import_errors:
        relatorio["falhas"].append("erro de importação")
    if relatorio["importacao"]["arquivos_varridos"] != ["dags/fluxo_batch.py"]:
        relatorio["falhas"].append("a varredura não ficou só na DAG")
    dag = bag.dags.get("fluxo_batch")
    if dag is None:
        relatorio["falhas"].append("fluxo_batch não carregou")
        return _fim(relatorio, args.saida)
    relatorio["tarefas"] = sorted(dag.task_ids)
    if len(dag.task_ids) != TAREFAS_DA_DAG:
        relatorio["falhas"].append(f"esperadas {TAREFAS_DA_DAG} tarefas")

    tarefa = dag.get_task(args.tarefa)
    snapshot = _snapshot_certificado(os.environ["GCP_PROJECT_ID"])
    comando = jinja2.Template(tarefa.bash_command).render(ti=_Instancia(snapshot))
    temporarios_antes = set(glob.glob(os.path.join(tempfile.gettempdir(), "tmp.*")))
    inicio = time.monotonic()
    execucao = subprocess.run(["bash", "-c", comando], capture_output=True, text=True)
    sobras = set(glob.glob(os.path.join(tempfile.gettempdir(), "tmp.*"))) - temporarios_antes
    saida = re.sub(r"\x1b\[[0-9;]*m", "", execucao.stdout)  # sem as cores do terminal
    resumo = [linha for linha in saida.splitlines() if "Done. PASS=" in linha or "ERROR" in linha]
    relatorio["dbt"] = {
        "tarefa": args.tarefa,
        "legacy_snapshot_id": snapshot,
        "comando": comando,
        "codigo": execucao.returncode,
        "segundos": round(time.monotonic() - inicio, 1),
        "resumo": resumo[-5:],
        "temporarios_que_sobraram": sorted(sobras),
        "stderr": execucao.stderr[-1500:],
    }
    if execucao.returncode != 0:
        relatorio["falhas"].append(f"{args.tarefa} terminou com {execucao.returncode}")
    if sobras:
        relatorio["falhas"].append("o temporário da tarefa ficou para trás")
    gerados = [p for p in ("target", "target_gcp", "logs") if (PASTA / "data/dbt" / p).exists()]
    if gerados:
        relatorio["falhas"].append(f"o layout ganhou {gerados}")
    return _fim(relatorio, args.saida)


def _fim(relatorio: dict[str, Any], saida: str | None) -> int:
    texto = json.dumps(relatorio, ensure_ascii=False, indent=2)
    sys.stdout.write(texto + "\n")
    if saida:
        Path(saida).parent.mkdir(parents=True, exist_ok=True)
        Path(saida).write_text(texto + "\n", encoding="utf-8")
    return 1 if relatorio["falhas"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
