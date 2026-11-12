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

from mvp_ed1.orquestracao import DBT, RETENTAR_SE_TRANSITORIO, segredos

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
        recuperável a partir do que já está gravado. A associação é
        idempotente para o mesmo job e **recusa** outro job numa tentativa já
        associada ou fechada (`TentativaIndisponivel`): reexecutar esta tarefa
        depois de a fase 2 ter corrido exige uma execução nova da DAG, com a
        sua própria fase 1 — nunca a mistura de dois jobs num certificado.
        """
        segredos()
        from mvp_ed1 import airbyte

        if not os.environ.get("AIRBYTE_CLIENT_ID"):
            raise airbyte.AirbyteIndisponivel(
                "credenciais do Airbyte ausentes no ambiente do Airflow. "
                "O `make airflow-up` as obtém de `abctl local credentials`."
            )

        import contextlib

        bloqueio = contextlib.nullcontext()
        armazem = None
        if tentativa is not None:
            from sqlalchemy import create_engine

            from mvp_ed1.db import LEGACY, database_url
            from mvp_ed1.legacy import armazem as armazens
            from mvp_ed1.legacy import captura

            # O lock da tentativa antes de tudo, esperando, e até o job estar
            # associado (H7, RR-39): enquanto ele está tomado, a recuperação de
            # outro chamador não abandona esta tentativa, por mais velha que seja.
            # O armazém é o do `.env` (`LEGACY_WAREHOUSE`); no GCP, o lock mora no Cloud SQL.
            armazem = armazens.do_ambiente(create_engine(database_url(LEGACY)))
            bloqueio = captura.bloqueio_da_tentativa(armazem, tentativa)
        with bloqueio:
            jwt = airbyte.token()
            connection_id = airbyte.conexao(conexao, jwt)
            if tentativa is not None:
                # Ainda pendente sem job, ou a recuperação já a resolveu: aí nenhum POST.
                captura.conferir_antes_do_disparo(armazem, tentativa)
            # `disparar`, não `sincronizar`: a pré-condição de identidade roda na
            # tarefa que **efetivamente dispara** (RV12-4-03). Pô-la só na fase 1
            # deixava de fora a reexecução desta tarefa sozinha — são tarefas
            # distintas, e reexecutar a segunda não repete a primeira.
            criado = airbyte.disparar(conexao, connection_id, jwt)
            if tentativa is not None:
                captura.registrar_job(armazem, tentativa, criado["jobId"])
        job = airbyte.acompanhar(criado["jobId"], jwt)

        if job.get("status") != "succeeded":
            raise RuntimeError(f"{conexao}: sincronização terminou como {job.get('status')}")
        return {"linhas": job.get("rowsSynced", 0), "job": job.get("jobId")}

    @task
    def retomar_capturas_do_legado() -> dict:
        """A fase de recuperação (H7): as tentativas que ficaram para trás, resolvidas e registradas.

        Antes de abrir a sua, a execução resolve as pendentes de antes — só a de
        job final, ou a sem job passada a carência e sem chamador vivo —, com o
        registro de tentativa e o de transição de cada uma no livro retido, e
        passa a barreira: o inventário inteiro desde a linha de base da época,
        nenhuma pendente. Qualquer diferença para a execução aqui, antes de a
        fase 1 abrir tentativa ou um job nascer (decisões N30, N32 e N34 do
        Owner no plano do `bi-como-codigo`).
        """
        segredos()
        from sqlalchemy import create_engine

        from mvp_ed1 import airbyte
        from mvp_ed1.db import LEGACY, database_url
        from mvp_ed1.legacy import armazem as armazens
        from mvp_ed1.recovery import capture_recovery

        if not os.environ.get("AIRBYTE_CLIENT_ID"):
            raise airbyte.AirbyteIndisponivel(
                "credenciais do Airbyte ausentes no ambiente do Airflow: a recuperação pergunta o "
                "estado dos jobs e lista os da conexão legada. O `make airflow-up` as obtém."
            )
        jwt = airbyte.token()
        conexao_legada = airbyte.conexao("legacy_para_raw_legacy", jwt)
        legado = create_engine(database_url(LEGACY))
        return capture_recovery.recover(
            legado,
            armazens.do_ambiente(legado),
            job_state=airbyte.estado_do_job(jwt),
            listar=lambda: capture_recovery.airbyte_listing(jwt, conexao_legada),
            caller={"kind": "dag", "task_id": "retomar_capturas_do_legado"},
        )

    @task
    def iniciar_captura_do_legado() -> str:
        """Fase 1 do certificado (ADR-0044): mede a origem **antes** de o job nascer.

        Contagem e hash de conteúdo de cada uma das 40 tabelas do `legacy_db`,
        gravados como `pending` em `governance.legacy_captures`. É a medição que
        não pode ser refeita depois — a origem de hoje não é a origem de antes.

        Desde a v1.1.0 (H7) ela **não finaliza** tentativa nenhuma — é a tarefa
        anterior que o faz, registrando — e só abre a sua **dentro do lock de
        abertura, se a barreira passar** de novo ali: a decisão de abrir é a
        própria barreira. O lock da tentativa é tomado antes do *insert*
        confirmar e segurado até ele; a sincronização o retoma em seguida.
        """
        segredos()
        import uuid

        from sqlalchemy import create_engine

        from mvp_ed1 import airbyte
        from mvp_ed1.db import LEGACY, database_url
        from mvp_ed1.legacy import armazem as armazens
        from mvp_ed1.legacy import captura
        from mvp_ed1.recovery import capture_recovery, ledger

        # Sem época corrente gravável, a captura terminaria sem registro
        # possível (H6): falha antes de abrir a tentativa e de disparar o job.
        ledger.writable_epoch()
        jwt = airbyte.token()
        conexao_legada = airbyte.conexao("legacy_para_raw_legacy", jwt)
        legado = create_engine(database_url(LEGACY))
        armazem = armazens.do_ambiente(legado)
        tentativa = uuid.uuid4().hex
        with captura.bloqueio_da_tentativa(armazem, tentativa):
            return captura.iniciar(
                legado,
                armazem,
                "legacy_para_raw_legacy",
                tentativa=tentativa,
                barreira=capture_recovery.opening_barrier(
                    lambda: capture_recovery.airbyte_listing(jwt, conexao_legada)
                ),
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
        segredos()
        from sqlalchemy import create_engine

        from mvp_ed1.db import LEGACY, database_url
        from mvp_ed1.legacy import armazem as armazens
        from mvp_ed1.legacy import captura

        legado = create_engine(database_url(LEGACY))
        certificado = captura.concluir(legado, armazens.do_ambiente(legado), tentativa)
        if certificado["status"] != "complete" or certificado["snapshot_id"] is None:
            raise RuntimeError(
                f"captura do job {sincronizacao.get('job')} não é elegível: "
                f"{certificado['status']} · tabelas {certificado['tabelas']}"
            )
        return int(certificado["snapshot_id"])

    @task(trigger_rule="all_done")
    def registrar_captura_do_legado() -> str:
        """O portão: o registro da tentativa desta execução no livro retido, antes de qualquer build (H6).

        A regeneração da v1.1.0 prova que a memória do legado ficou contida
        comparando-a com registros tirados antes (`mvp_ed1.recovery.ledger`).
        Esta DAG captura **e** constrói na mesma execução, e um registro tirado
        depois dela adotaria o que tivesse mudado a captura no meio-tempo: o
        registro tem de preceder o primeiro build, e só a DAG o põe aí
        (decisão N29 do Owner no plano do `bi-como-codigo`).

        Roda depois de `concluir_captura_do_legado` **seja qual for o desfecho
        dela** (`all_done`): o certificado é registrado como estiver, e é só
        depois de publicado que a tarefa falha se ele não é `complete` — o
        registro fica. Uma tentativa ainda sem job, ou com o job em curso, não é
        registrável: a tarefa falha e ela fica para a recuperação do próximo
        chamador (H7).

        **Nunca repetida sozinha** (N31): fora da primeira tentativa desta
        tarefa ela falha sem escrever. Execução que falhou não continua — o §5
        do runbook, depois a DAG inteira de novo, uma captura nova. Sem
        `LEGACY_LEDGER_DIR`, sem época corrente, sem escrita ou com o registro
        já existente, ela falha: o portão nunca é pulado.
        """
        segredos()
        from airflow.sdk import get_current_context
        from sqlalchemy import create_engine

        from mvp_ed1 import airbyte
        from mvp_ed1.db import LEGACY, database_url
        from mvp_ed1.legacy import armazem as armazens
        from mvp_ed1.recovery import ledger

        contexto = get_current_context()
        ti = contexto["ti"]
        tentativa = ti.xcom_pull(task_ids="iniciar_captura_do_legado")
        observador = airbyte.estado_do_job(airbyte.token()) if os.environ.get("AIRBYTE_CLIENT_ID") else None
        publicado, registro = ledger.gate(
            armazens.do_ambiente(create_engine(database_url(LEGACY))),
            tentativa,
            caller={"kind": "dag", "dag_id": ti.dag_id, "task_id": ti.task_id},
            run_id=contexto["run_id"],
            try_number=ti.try_number,
            job_state=observador,
        )
        print(f"registro da tentativa {tentativa}: {publicado.path} · sha256 {publicado.sha256}")
        estado = ledger.certificate_status(registro)
        if estado != "complete":
            raise RuntimeError(f"tentativa {tentativa} registrada como {estado}: não é elegível para o build")
        return publicado.sha256

    recuperacao = retomar_capturas_do_legado()
    tentativa = iniciar_captura_do_legado()
    recuperacao >> tentativa
    captura_principal = sincronizar.override(task_id="sincronizar_oltp_para_raw")(
        conexao="oltp_para_raw"
    )
    captura_legada_sync = sincronizar.override(task_id="sincronizar_legado_para_raw_legacy")(
        conexao="legacy_para_raw_legacy", tentativa=tentativa
    )
    captura_legada = concluir_captura_do_legado(tentativa, captura_legada_sync)
    registro = registrar_captura_do_legado()
    captura_legada >> registro

    def camada(nome: str, selecao: str, comando: str = "build") -> BashOperator:
        # `--vars` em todas as tarefas, e não só nas do legado: as tarefas são
        # por camada (não por origem), e uma variável que só valesse em algumas
        # faria a camada seguinte reabrir a escolha que a anterior já fechou.
        vars_ = (
            """--vars '{legacy_snapshot_id: """
            "{{ ti.xcom_pull(task_ids='concluir_captura_do_legado') }}}'"
        )
        # Falha de infraestrutura transitória (uma 503 do IAM, em 11/11) refaz os nós que falharam,
        # uma vez, por `dbt retry`; teste de dado vermelho, não (`orquestracao.falha_transitoria`).
        return BashOperator(
            task_id=f"dbt_{nome}",
            bash_command=f"{DBT} {comando} {selecao} {vars_}".strip() + RETENTAR_SE_TRANSITORIO,
        )

    # ── Testes de fronteira ficam para o fim ─────────────────────────────────
    # A seleção indireta do dbt (`eager`) traz para uma tarefa todo teste que
    # cite **qualquer** modelo dela — inclusive os que comparam esta camada com
    # a seguinte, que ainda não foi construída. Esses comparariam o novo com o
    # velho da execução anterior e acusariam diferença que é só ordem de
    # execução. Todo teste que atravessa camadas leva a etiqueta `fronteira`
    # (Qualidade §7), sai das tarefas por camada e roda em `dbt_fronteiras`,
    # depois da última camada. É o mesmo remédio de `legado_reconciliacao`,
    # que compara `trusted` com a quarentena.
    fronteira = "--exclude tag:fronteira"
    # `seed` antes de tudo: `brazilian_states` é dado de referência que
    # `trusted.geographies` lê, e ele não vem da origem.
    semear = camada("seed", "", comando="seed")
    staging = camada("staging", f"--select staging {fronteira}")
    # O teste que compara `trusted` com a quarentena sai daqui: os dois lados
    # dele só existem depois da tarefa seguinte. Sem o `--exclude`, a seleção
    # indireta do dbt o traz de volta e ele compara a captura nova com a
    # quarentena da anterior.
    trusted = camada("trusted", f"--select trusted --exclude tag:legado_reconciliacao tag:fronteira")
    # A quarentena sai de `trusted` e não alimenta ninguém — é destino, não
    # passagem (ADR-0008). Roda aqui porque o teste que a confere só tem o que
    # ler depois que ela existe, e porque uma rejeição descoberta tarde é uma
    # rejeição que já contaminou o relatório.
    quarentena = camada("quarantine", "--select quarantine tag:legado_reconciliacao")
    # `snapshot` no meio: lê `trusted`, é lido por `analytics`.
    snapshots = camada("snapshots", "", comando="snapshot")
    analytics = camada("analytics", f"--select analytics {fronteira}")
    consumption = camada("consumption", f"--select consumption {fronteira}")
    # Todas as camadas construídas: as fronteiras entre elas têm os dois lados.
    fronteiras = camada("fronteiras", "--select tag:fronteira", comando="test")
    # O catálogo é a última coisa: ele descreve o que acabou de ser construído. Desde o G2.4
    # o arquivo some com o diretório temporário da tarefa, e o que ela prova é que o catálogo
    # se gera sobre o que está construído. Para servi-lo, o `make docs-serve` gera o seu.
    catalogo = camada("docs", "generate", comando="docs")

    # As duas capturas são **independentes** e correm em paralelo: lêem bancos
    # diferentes e escrevem schemas diferentes. O que não é paralelizável é o
    # que vem depois — a transformação precisa das duas completas, porque o
    # empilhamento do legado se junta ao dado da origem principal.
    #
    # O portão (`registro`) entra entre a captura certificada e o primeiro
    # build: `dbt_seed` só começa com a tentativa registrada (H6).
    #
    # O legado não entra em nenhuma tarefa nova de transformação: as tarefas da
    # DAG são por **camada**, e os modelos dele vivem nas camadas que já existem.
    # É a propriedade que o cabeçalho desta DAG anuncia — acrescentar domínio
    # não acrescenta tarefa —, e a Etapa 10 é o teste dela.
    (
        [captura_principal, captura_legada, registro]
        >> semear
        >> staging
        >> trusted
        >> quarentena
        >> snapshots
        >> analytics
        >> consumption
        >> fronteiras
        >> catalogo
    )


fluxo_batch()
