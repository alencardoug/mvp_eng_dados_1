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
    @task
    def sincronizar(conexao: str) -> dict:
        """Executa uma sincronização do Airbyte e **espera** o resultado.

        Importa o cliente do próprio pacote do projeto em vez de reimplementar
        a chamada: uma segunda implementação divergiria da do `Makefile` na
        primeira alteração, e as duas responderiam coisas diferentes sobre a
        mesma sincronização.

        Recebe o nome da conexão porque desde a Etapa 10 há **duas** origens, e
        a tarefa é a mesma para as duas — o que muda é de onde se lê, e isso
        está declarado em `airbyte/streams.yml`, não aqui.
        """
        from mvp_ed1 import airbyte

        if not os.environ.get("AIRBYTE_CLIENT_ID"):
            raise airbyte.AirbyteIndisponivel(
                "credenciais do Airbyte ausentes no ambiente do Airflow. "
                "O `make airflow-up` as obtém de `abctl local credentials`."
            )

        jwt = airbyte.token()
        connection_id = airbyte.conexao(conexao, jwt)
        job = airbyte.acompanhar(airbyte.sincronizar(connection_id, jwt)["jobId"], jwt)

        if job.get("status") != "succeeded":
            raise RuntimeError(f"{conexao}: sincronização terminou como {job.get('status')}")
        return {"linhas": job.get("rowsSynced", 0), "job": job.get("jobId")}

    @task
    def geracao_do_legado() -> int:
        """A captura que esta execução acabou de produzir, observada no bruto.

        ── Por que a DAG precisa dizer isto ao dbt ───────────────────────────
        Sem esta tarefa, cada invocação do dbt escolhia a captura mais recente
        que encontrasse. Numa DAG de sete tarefas de dbt, "mais recente" pode
        mudar entre a primeira e a última — basta uma carga chegar no meio —, e
        as camadas passariam a ler capturas diferentes sem que nada acusasse.

        Aqui a escolha é feita **uma vez**, logo depois da sincronização, e
        viaja para todas as tarefas como `legacy_snapshot_id`. O que o dbt lê
        deixa de ser um palpite recalculado sete vezes.

        ── O que esta tarefa não prova ──────────────────────────────────────
        Que a geração observada seja a que **esta** sincronização escreveu. O
        Airbyte não expõe a correspondência entre o `jobId` e o
        `_airbyte_generation_id`, e inventá-la seria pior do que não tê-la. O
        que sustenta a afirmação é o par de testes do dbt: a captura existe em
        `raw_legacy` e traz todas as 40 tabelas. Uma sincronização que não
        tivesse escrito nada cairia num deles.
        """
        from sqlalchemy import create_engine, text

        from mvp_ed1.db import WAREHOUSE, database_url
        from mvp_ed1.legacy import schema

        consulta = " union all ".join(
            f'select max(_airbyte_generation_id) as g from raw_legacy."{tabela}"'
            for tabela in schema.tabelas()
        )
        with create_engine(database_url(WAREHOUSE)).connect() as conexao:
            geracao = conexao.execute(
                text(f"select max(g) from ({consulta}) t")
            ).scalar_one_or_none()

        if geracao is None:
            raise RuntimeError(
                "nenhuma captura do legado em raw_legacy depois da sincronização"
            )
        return int(geracao)

    captura_legada = geracao_do_legado()

    def camada(nome: str, selecao: str, comando: str = "build") -> BashOperator:
        # `--vars` em todas as tarefas, e não só nas do legado: as tarefas são
        # por camada (não por origem), e uma variável que só valesse em algumas
        # faria a camada seguinte reabrir a escolha que a anterior já fechou.
        vars_ = (
            """--vars '{legacy_snapshot_id: """
            "{{ ti.xcom_pull(task_ids='geracao_do_legado') }}}'"
        )
        return BashOperator(
            task_id=f"dbt_{nome}",
            bash_command=f"{DBT} {comando} {selecao} {vars_}".strip(),
        )

    # `seed` antes de tudo: `brazilian_states` é dado de referência que
    # `trusted.geographies` lê, e ele não vem da origem.
    semear = camada("seed", "", comando="seed")
    staging = camada("staging", "--select staging")
    # O teste que compara `trusted` com a quarentena sai daqui: os dois lados
    # dele só existem depois da tarefa seguinte. Sem o `--exclude`, a seleção
    # indireta do dbt o traz de volta e ele compara a captura nova com a
    # quarentena da anterior.
    trusted = camada("trusted", "--select trusted --exclude tag:legado_reconciliacao")
    # A quarentena sai de `trusted` e não alimenta ninguém — é destino, não
    # passagem (ADR-0008). Roda aqui porque o teste que a confere só tem o que
    # ler depois que ela existe, e porque uma rejeição descoberta tarde é uma
    # rejeição que já contaminou o relatório.
    quarentena = camada("quarantine", "--select quarantine tag:legado_reconciliacao")
    # `snapshot` no meio: lê `trusted`, é lido por `analytics`.
    snapshots = camada("snapshots", "", comando="snapshot")
    analytics = camada("analytics", "--select analytics")
    consumption = camada("consumption", "--select consumption")
    # O catálogo é a última coisa: ele descreve o que acabou de ser construído.
    catalogo = camada("docs", "generate", comando="docs")

    # As duas capturas são **independentes** e correm em paralelo: lêem bancos
    # diferentes e escrevem schemas diferentes. O que não é paralelizável é o
    # que vem depois — a transformação precisa das duas completas, porque o
    # empilhamento do legado se junta ao dado da origem principal.
    #
    # O legado não entra em nenhuma tarefa nova de transformação: as tarefas da
    # DAG são por **camada**, e os modelos dele vivem nas camadas que já existem.
    # É a propriedade que o cabeçalho desta DAG anuncia — acrescentar domínio
    # não acrescenta tarefa —, e a Etapa 10 é o teste dela.
    capturas = [
        sincronizar.override(task_id="sincronizar_oltp_para_raw")(conexao="oltp_para_raw"),
        sincronizar.override(task_id="sincronizar_legado_para_raw_legacy")(
            conexao="legacy_para_raw_legacy"
        ),
    ]

    (
        capturas
        >> captura_legada
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
