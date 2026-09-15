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
    def sincronizar(conexao: str, tentativa: str | None = None) -> dict:
        """Executa uma sincronização do Airbyte e **espera** o resultado.

        Importa o cliente do próprio pacote do projeto em vez de reimplementar
        a chamada: uma segunda implementação divergiria da do `Makefile` na
        primeira alteração, e as duas responderiam coisas diferentes sobre a
        mesma sincronização.

        Recebe o nome da conexão porque desde a Etapa 10 há **duas** origens, e
        a tarefa é a mesma para as duas — o que muda é de onde se lê, e isso
        está declarado em `airbyte/streams.yml`, não aqui. Para o legado recebe
        também a `tentativa` aberta pela fase 1 do certificado (ADR-0044), e
        grava nela o `job_id` **assim que o job nasce** — antes de esperar por
        ele —, para que uma falha entre a sincronização e a fase 2 seja
        recuperável a partir do que já está gravado.
        """
        from mvp_ed1 import airbyte

        if not os.environ.get("AIRBYTE_CLIENT_ID"):
            raise airbyte.AirbyteIndisponivel(
                "credenciais do Airbyte ausentes no ambiente do Airflow. "
                "O `make airflow-up` as obtém de `abctl local credentials`."
            )

        jwt = airbyte.token()
        connection_id = airbyte.conexao(conexao, jwt)
        criado = airbyte.sincronizar(connection_id, jwt)
        if tentativa is not None:
            from sqlalchemy import create_engine

            from mvp_ed1.db import WAREHOUSE, database_url
            from mvp_ed1.legacy import captura

            captura.registrar_job(create_engine(database_url(WAREHOUSE)), tentativa, criado["jobId"])
        job = airbyte.acompanhar(criado["jobId"], jwt)

        if job.get("status") != "succeeded":
            raise RuntimeError(f"{conexao}: sincronização terminou como {job.get('status')}")
        return {"linhas": job.get("rowsSynced", 0), "job": job.get("jobId")}

    @task
    def iniciar_captura_do_legado() -> str:
        """Fase 1 do certificado (ADR-0044): mede a origem **antes** de o job nascer.

        Contagem e hash de conteúdo de cada uma das 40 tabelas do `legacy_db`,
        gravados como `pending` em `governance.legacy_captures`. É a medição que
        não pode ser refeita depois — a origem de hoje não é a origem de antes.
        Tentativas pendentes de execuções anteriores são concluídas ou marcadas
        `abandoned` aqui, nunca reaproveitadas em silêncio.
        """
        from sqlalchemy import create_engine

        from mvp_ed1.db import LEGACY, WAREHOUSE, database_url
        from mvp_ed1.legacy import captura

        return captura.iniciar(
            create_engine(database_url(LEGACY)),
            create_engine(database_url(WAREHOUSE)),
            "legacy_para_raw_legacy",
        )

    @task
    def concluir_captura_do_legado(tentativa: str, sincronizacao: dict) -> int:
        """Fase 2 do certificado: a captura que **este** job escreveu, íntegra por conteúdo.

        ── O que esta tarefa prova, e com quê ────────────────────────────────
        Até 14/09/2026 ela lia o máximo de `_airbyte_generation_id` depois da
        sincronização, e a docstring admitia: nada distinguia carga nova de
        captura anterior reutilizada. Agora o certificado responde, por tabela:
        a origem ficou parada durante o job (hash antes = hash depois); o que
        chegou é o que a origem tinha, linha a linha e com multiplicidade
        (hash e contagem do bruto = origem); e as linhas são deste job
        (`_airbyte_meta.sync_id` = `jobId`, sem intrusas na geração). Só com
        `complete` nas 40 tabelas a captura é elegível, e é o `snapshot_id` dela
        que viaja para todas as tarefas de dbt como `legacy_snapshot_id`.

        Sem certificado `complete` a tarefa **falha** — uma captura incompleta
        com job `succeeded` (a geração 15 retida é uma) não chega ao dbt.
        """
        from sqlalchemy import create_engine

        from mvp_ed1.db import LEGACY, WAREHOUSE, database_url
        from mvp_ed1.legacy import captura

        certificado = captura.concluir(
            create_engine(database_url(LEGACY)), create_engine(database_url(WAREHOUSE)), tentativa
        )
        if certificado["status"] != "complete" or certificado["snapshot_id"] is None:
            raise RuntimeError(
                f"captura do job {sincronizacao.get('job')} não é elegível: "
                f"{certificado['status']} · tabelas {certificado['tabelas']}"
            )
        return int(certificado["snapshot_id"])

    tentativa = iniciar_captura_do_legado()
    captura_principal = sincronizar.override(task_id="sincronizar_oltp_para_raw")(
        conexao="oltp_para_raw"
    )
    captura_legada_sync = sincronizar.override(task_id="sincronizar_legado_para_raw_legacy")(
        conexao="legacy_para_raw_legacy", tentativa=tentativa
    )
    captura_legada = concluir_captura_do_legado(tentativa, captura_legada_sync)

    def camada(nome: str, selecao: str, comando: str = "build") -> BashOperator:
        # `--vars` em todas as tarefas, e não só nas do legado: as tarefas são
        # por camada (não por origem), e uma variável que só valesse em algumas
        # faria a camada seguinte reabrir a escolha que a anterior já fechou.
        vars_ = (
            """--vars '{legacy_snapshot_id: """
            "{{ ti.xcom_pull(task_ids='concluir_captura_do_legado') }}}'"
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
    (
        [captura_principal, captura_legada]
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
