"""DAG do caminho frio — `oltp` até as views de consumo.

Nasceu como `corte_comercial` na Etapa 5 e foi renomeada na Etapa 6, quando
passou a construir também o financeiro e o estoque. O nome novo é o que ela vai
continuar sendo: **o caminho de lote**, em oposição ao caminho quente do
*streaming* que a Etapa 7 acrescenta. Cada corte vertical novo entra aqui sem
mudar a forma da DAG — as tarefas são por camada, não por domínio, e é por isso
que acrescentar domínio não acrescenta tarefa.

O ADR-0003 foi buscar no Airflow três coisas: **dependência explícita,
reexecução parcial e histórico**. Por isso esta DAG não é uma tarefa só
chamando `dbt build`.

Um `dbt build` único funcionaria e seria mais curto — e esconderia exatamente o
que o orquestrador existe para mostrar. Com uma tarefa por camada, uma falha em
`analytics` é reexecutável sem repetir a ingestão de 165 mil linhas, e o
histórico registra *onde* o fluxo quebrou, não apenas que quebrou.

A ordem não é preferência. Ela é imposta por duas coisas descobertas
construindo, e ambas estão em `docs/execucao_local.md` §6:

* o destino do Airbyte **derruba** a tabela de `raw` a cada carga completa, e as
  views de `staging` dependem dela — entre a sincronização e o `dbt`, elas não
  existem;
* os `snapshots` leem `trusted` e são lidos por `analytics`, então precisam
  correr no meio, e não junto.
"""

from __future__ import annotations

import datetime as dt
import os

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task

#: O repositório é montado somente leitura no contêiner (ver o compose).
PROJETO = "/opt/mvp_ed1"
DBT = f"cd {PROJETO}/dbt && dbt"

#: Sem `retries` nas tarefas de dbt: falha de teste de dados **não** se resolve
#: tentando de novo. Repetir só atrasaria a notícia (Qualidade de Dados §1).
PADRAO = {
    "owner": "data_custodian",
    "retries": 0,
}


@dag(
    dag_id="fluxo_batch",
    description="Caminho frio: oltp → raw → staging → trusted → analytics → consumption",
    # Disparo explícito, não agendado: na fase local a origem é regerada à mão,
    # e uma DAG que roda sozinha sincronizaria dado que ninguém pediu. O
    # agendamento entra na Etapa 12, quando o fluxo inteiro for validado junto.
    schedule=None,
    start_date=dt.datetime(2026, 9, 1),
    catchup=False,
    max_active_runs=1,
    default_args=PADRAO,
    tags=["batch", "armazem"],
)
def fluxo_batch():
    @task(task_id="sincronizar_oltp_para_raw")
    def sincronizar() -> dict:
        """Executa a sincronização do Airbyte e **espera** o resultado.

        Importa o cliente do próprio pacote do projeto em vez de reimplementar
        a chamada: uma segunda implementação divergiria da do `Makefile` na
        primeira alteração, e as duas responderiam coisas diferentes sobre a
        mesma sincronização.
        """
        from mvp_ed1 import airbyte

        if not os.environ.get("AIRBYTE_CLIENT_ID"):
            raise airbyte.AirbyteIndisponivel(
                "credenciais do Airbyte ausentes no ambiente do Airflow. "
                "O `make airflow-up` as obtém de `abctl local credentials`."
            )

        jwt = airbyte.token()
        connection_id = airbyte.conexao("oltp_para_raw", jwt)
        job = airbyte.acompanhar(airbyte.sincronizar(connection_id, jwt)["jobId"], jwt)

        if job.get("status") != "succeeded":
            raise RuntimeError(f"sincronização terminou como {job.get('status')}")
        return {"linhas": job.get("rowsSynced", 0), "job": job.get("jobId")}

    def camada(nome: str, selecao: str, comando: str = "build") -> BashOperator:
        return BashOperator(
            task_id=f"dbt_{nome}",
            bash_command=f"{DBT} {comando} {selecao}".strip(),
        )

    # `seed` antes de tudo: `brazilian_states` é dado de referência que
    # `trusted.geographies` lê, e ele não vem da origem.
    semear = camada("seed", "", comando="seed")
    staging = camada("staging", "--select staging")
    trusted = camada("trusted", "--select trusted")
    # A quarentena sai de `trusted` e não alimenta ninguém — é destino, não
    # passagem (ADR-0008). Roda aqui porque o teste que a confere só tem o que
    # ler depois que ela existe, e porque uma rejeição descoberta tarde é uma
    # rejeição que já contaminou o relatório.
    quarentena = camada("quarantine", "--select quarantine")
    # `snapshot` no meio: lê `trusted`, é lido por `analytics`.
    snapshots = camada("snapshots", "", comando="snapshot")
    analytics = camada("analytics", "--select analytics")
    consumption = camada("consumption", "--select consumption")
    # O catálogo é a última coisa: ele descreve o que acabou de ser construído.
    catalogo = camada("docs", "generate", comando="docs")

    (
        sincronizar()
        >> semear
        >> staging
        >> trusted
        >> quarentena
        >> snapshots
        >> analytics
        >> consumption
        >> catalogo
    )


fluxo_batch()
