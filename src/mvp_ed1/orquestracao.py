"""O que as DAGs do projeto partilham: o comando do dbt e os segredos da tarefa (Etapa 13, G2.4).

Vive no pacote, e não num arquivo de DAG, porque duas DAGs o usam — a `fluxo_batch` e, só no
Composer, a `diagnostico_composer` do *smoke test* — e importar um arquivo de DAG de outro registraria
a DAG dele duas vezes. É leve de propósito: o processador de DAGs o importa a cada *parse*.
"""

from __future__ import annotations

import os

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
