"""O *smoke test* do Composer: o que a `fluxo_batch` pressupõe, perguntado antes dela (Etapa 13, G2.4).

Só existe no Composer — o `mvp_ed1.gcp.composer.LAYOUT` a põe em `dags/`; o Airflow local não a
vê. **Nenhuma tarefa escreve nada**: cada uma responde a uma pergunta de que a `fluxo_batch`
depende e falha dizendo qual, para que a janela não descubra a falta no meio de uma captura.

| Tarefa | A pergunta |
|---|---|
| `segredos_presentes` | o *backend* do Secret Manager entrega os quatro segredos da DAG? (só os nomes saem no log) |
| `rede` | o *attachment* do Composer alcança o IP privado do Cloud SQL e o *load balancer* interno do Airbyte? |
| `identidade_python` | as tarefas Python agem como o `ingestor` (D81)? |
| `origem_e_livro` | a origem legada responde e o livro tem época gravável, com a conta do `ingestor`? |
| `airbyte_responde` | a API do Airbyte autentica e conhece as duas conexões? |
| `dbt_identidade` | o dbt, no layout de `data/`, consulta o BigQuery como o `transformer` (D81)? |

`rede` vem primeiro porque é a hipótese que a documentação não confirma (`terraform/composer.tf`):
o Cloud SQL está do outro lado do *peering* dos serviços privados.
"""

from __future__ import annotations

import datetime as dt
import os

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task

from mvp_ed1.orquestracao import DBT, SEGREDOS, segredos


@dag(
    dag_id="diagnostico_composer",
    description="Smoke test do Composer: segredos, rede, identidades, origem, livro, Airbyte e dbt — sem escrever",
    schedule=None,
    start_date=dt.datetime(2026, 11, 1),
    catchup=False,
    max_active_runs=1,
    default_args={"owner": "data_custodian", "retries": 0},
    tags=["diagnostico"],
)
def diagnostico_composer():
    @task
    def segredos_presentes() -> list[str]:
        segredos()
        faltam = [env for env in SEGREDOS if not os.environ.get(env)]
        if faltam:
            raise RuntimeError(f"sem {', '.join(faltam)}: nem no ambiente nem no Secret Manager")
        return sorted(SEGREDOS)

    @task
    def rede() -> dict:
        import socket
        import time
        import urllib.parse

        segredos()
        airbyte = urllib.parse.urlsplit(os.environ["AIRBYTE_URL"])
        alvos = {
            "cloud_sql": (os.environ["LEGACY_DB_HOST"], int(os.environ["LEGACY_DB_PORT"])),
            "airbyte": (airbyte.hostname, airbyte.port or 80),
        }
        medido = {}
        for nome, (host, porta) in alvos.items():
            inicio = time.monotonic()
            with socket.create_connection((host, porta), timeout=15):
                pass
            medido[nome] = {"host": host, "porta": porta, "ms": round((time.monotonic() - inicio) * 1000, 1)}
        return medido

    @task
    def identidade_python() -> str:
        from google.cloud import bigquery

        from mvp_ed1.gcp.credenciais import personificada

        esperado = os.environ["MVP_IMPERSONATE_SA"]
        cliente = bigquery.Client(project=os.environ["GCP_PROJECT_ID"], location=os.environ["GCP_BQ_LOCATION"],
                                  credentials=personificada())
        quem = next(iter(cliente.query("select session_user()").result()))[0]
        if quem != esperado:
            raise RuntimeError(f"a tarefa consultou como {quem}, não como {esperado}")
        return quem

    @task
    def origem_e_livro() -> dict:
        segredos()
        from sqlalchemy import create_engine, text

        from mvp_ed1.db import LEGACY, database_url
        from mvp_ed1.recovery import ledger

        with create_engine(database_url(LEGACY)).connect() as cx:
            versao = cx.execute(text("show server_version")).scalar()
            ssl = cx.execute(text("select ssl from pg_stat_ssl where pid = pg_backend_pid()")).scalar()
        # A mesma pergunta da `iniciar_captura_do_legado`: época corrente e gravável — sem gravar.
        epoca = ledger.writable_epoch()
        return {"postgres": versao, "tls": bool(ssl), "epoca": str(epoca)}

    @task
    def airbyte_responde() -> dict:
        segredos()
        from mvp_ed1 import airbyte

        jwt = airbyte.token()
        return {nome: airbyte.conexao(nome, jwt) for nome in ("oltp_para_raw", "legacy_para_raw_legacy")}

    # O dbt pelo mesmo prefixo da `fluxo_batch` — diretório do projeto, temporário, *profile* —, e a
    # identidade conferida na saída: o `grep` falha a tarefa se a conta não é a do `transformer`.
    dbt_identidade = BashOperator(
        task_id="dbt_identidade",
        bash_command=(
            f"{DBT} show --target gcp --inline 'select session_user() as quem' --output json"
            ' | tee /dev/stderr | grep -qF "\\"$MVP_DBT_IMPERSONATE_SA\\""'
        ),
    )

    segredos_presentes() >> rede() >> [identidade_python(), origem_e_livro(), airbyte_responde(), dbt_identidade]


diagnostico_composer()
