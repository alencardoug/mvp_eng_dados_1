"""O que as DAGs do projeto partilham: o comando do dbt e os segredos da tarefa (Etapa 13, G2.4).

Vive no pacote, e não num arquivo de DAG, porque duas DAGs o usam — a `fluxo_batch` e, só no
Composer, a `diagnostico_composer` do *smoke test* — e importar um arquivo de DAG de outro registraria
a DAG dele duas vezes. É leve de propósito: o processador de DAGs o importa a cada *parse*.
"""

from __future__ import annotations

import os
import re

#: Onde está o projeto dbt — e, ao lado dele, o glossário que os `docs-paths` leem — vem do
#: ambiente (Etapa 13, G2.4): `/opt/mvp_ed1` no contêiner local, que o compose monta somente
#: leitura; `/home/airflow/gcs/data` no Composer, a pasta do *bucket* que o ambiente sincroniza.
#: É lido pelo `bash` na hora da tarefa, não pelo Python no *parse*: sem a variável a tarefa falha
#: dizendo qual falta, e a DAG continua importável.
#:
#: *Target* e *logs* do dbt num diretório temporário **por tarefa**, apagado ao fim: o projeto fica
#: só para leitura nos dois ambientes — no Composer a pasta `data/` é um sistema de arquivos sobre o
#: GCS, onde escrever o *target* a cada tarefa seria lento e misturaria execuções. O que a tarefa
#: fez fica no log dela, que o dbt escreve também na saída padrão. O custo aceito é o *parse*
#: inteiro em cada tarefa, sem o parcial do *target* anterior.
DBT = (
    'cd "${MVP_PROJECT_DIR:?defina MVP_PROJECT_DIR, a pasta que contém dbt/}/dbt"'
    ' && ARTEFATOS="$(mktemp -d)" && trap \'rm -rf "$ARTEFATOS"\' EXIT'
    ' && DBT_TARGET_PATH="$ARTEFATOS/target" DBT_LOG_PATH="$ARTEFATOS/logs" dbt'
)

#: O que as tarefas Python leem do ambiente e que, no Composer, é segredo (RV13-1-09): no contêiner
#: local o compose passa tudo do `.env`; no Composer nenhum segredo vai nas variáveis de ambiente —
#: que qualquer leitor da configuração vê —, e sim no Secret Manager, lido pelo *backend* de
#: segredos do Airflow como *Variable*. O nome da *Variable* com o prefixo do *backend*
#: (`mvp-ed1`, `terraform/composer.tf`) é o nome do segredo: `legacy-db-password` é
#: `mvp-ed1-legacy-db-password`, o que o `cloud_sql.tf` já cria. O endereço do Airbyte entra junto
#: porque o IP do *load balancer* interno só existe depois de o Service nascer no GKE.
SEGREDOS = {
    "LEGACY_DB_PASSWORD": "legacy-db-password",
    "AIRBYTE_CLIENT_ID": "airbyte-client-id",
    "AIRBYTE_CLIENT_SECRET": "airbyte-client-secret",
    "AIRBYTE_URL": "airbyte-url",
}


def segredos() -> None:
    """Preenche no ambiente da tarefa o que falta dele, a partir das *Variables* do Airflow.

    Só o que **falta**: no local tudo vem do `.env` e nada é consultado além do que estiver vazio;
    o que não existir em lugar nenhum fica faltando, e a tarefa falha adiante dizendo o quê, como
    antes. Roda no início de cada tarefa Python, antes de qualquer `import` do projeto.
    """
    faltam = {env: nome for env, nome in SEGREDOS.items() if not os.environ.get(env)}
    if not faltam:
        return
    from airflow.sdk import Variable

    for env, nome in faltam.items():
        valor = Variable.get(nome, default=None)
        if valor:
            os.environ[env] = valor


# ── Re-tentativa só de infraestrutura (Registro §55, passo 9; decisão do Owner em 11/11) ─────────
#: A DAG tem `retries: 0`: teste de dado vermelho não se resolve tentando de novo (Qualidade §1).
#: Mas em 11/11 uma 503 da API de credenciais do IAM derrubou o `dbt_staging` inteiro (1 de 455
#: nós). A saída: quando o dbt falha, o `run_results.json` da tarefa diz se **toda** falha foi de
#: infraestrutura transitória — então, e só então, um `dbt retry` refaz os nós que falharam, uma
#: vez. Teste com `status: fail` (dado errado) nunca re-tenta; erro sem marca de transitório
#: (permissão, SQL, compilação) também não; `run_results.json` ausente, também não.
TRANSITORIO = r"\b(?:429|500|502|503|504)\b|UNAVAILABLE|DEADLINE_EXCEEDED|backendError|rateLimitExceeded|internalError"

#: O classificador que o `bash` da tarefa roda, autocontido: no Composer o pacote está na pasta
#: `dags/`, que o Airflow põe no `sys.path` dele, e não necessariamente no do subprocesso. Sem
#: aspas simples (vai entre elas no `bash`) e sem `{{` (o `bash_command` passa pelo Jinja).
CLASSIFICADOR = (
    "import json, os, re, sys\n"
    "p = sys.argv[1]\n"
    "if not os.path.exists(p):\n"
    "    sys.exit(1)\n"
    "falhas = [r for r in json.load(open(p)).get(\"results\", [])"
    " if r.get(\"status\") not in (\"success\", \"pass\", \"skipped\", \"warn\")]\n"
    f"t = re.compile(r\"{TRANSITORIO}\")\n"
    "sys.exit(0 if falhas and all(r.get(\"status\") == \"error\" and t.search(r.get(\"message\") or \"\")"
    " for r in falhas) else 1)\n"
)


def falha_transitoria(run_results: dict) -> bool:
    """O mesmo critério do `CLASSIFICADOR`, no processo: toda falha é transitória, e há uma."""
    falhas = [r for r in run_results.get("results", []) if r.get("status") not in ("success", "pass", "skipped", "warn")]
    return bool(falhas) and all(
        r.get("status") == "error" and re.search(TRANSITORIO, r.get("message") or "") for r in falhas
    )


#: O que a `camada()` da DAG acrescenta ao comando do dbt: se ele falhar e a falha for transitória,
#: um `dbt retry` no mesmo diretório de artefatos (é de lá que ele lê o que falhou e com que
#: argumentos — os `--vars` inclusive). Falha que não é transitória devolve o erro como antes.
RETENTAR_SE_TRANSITORIO = (
    " || { python3 -c '" + CLASSIFICADOR + "' \"$ARTEFATOS/target/run_results.json\""
    ' && echo "falha transitória de infraestrutura: dbt retry, uma vez"'
    ' && DBT_TARGET_PATH="$ARTEFATOS/target" DBT_LOG_PATH="$ARTEFATOS/logs" dbt retry; }'
)
