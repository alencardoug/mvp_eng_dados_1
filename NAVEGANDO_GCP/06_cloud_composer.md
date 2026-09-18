# 06 — Cloud Composer: a peça cara

**Em uma frase.** O Airflow local (`airflow-apiserver`, `scheduler`, `dag_processor`, o banco de
metadados) como serviço: a Google opera o *scheduler*, os *workers*, o *web server* e o banco; você
entrega a DAG num *bucket* e ela aparece. `fluxo_batch` sobe com as mesmas 13 tarefas — o que muda é
**como o dbt e o Airbyte são alcançados** (rede, contas de serviço, dependências) e que cada hora
de ambiente ligado é cobrada, com ou sem DAG rodando.

**Quanto custa e por quê.** Cobra por **hora de ambiente de pé**, em componentes: taxa do
ambiente por tamanho (*small/medium/large*), vCPU/GB dos *workers* (escalam com a fila), banco de
metadados, *web server*, armazenamento. Ambiente *small* fica na casa de US$ 350–450/mês
([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)) — **é a peça que domina a
conta**, e ociosa cobra quase o mesmo. Leva 25–40 min para nascer e 10–20 para morrer. Por isso:
sobe por último, desce primeiro, e este é o bloco de horário fixo do dia.

**Onde fica.** ☰ → *Composer* → *Environments* (`console.cloud.google.com/composer/environments`).
Página do ambiente: botões **Open Airflow UI** e **Open DAGs folder**; abas *Monitoring*, *Logs*,
*DAGs*, *Environment configuration* (ou *Environment details*), *Airflow configuration overrides*,
*Environment variables*, *PyPI packages*, *Labels*. Duas versões coexistem: **Composer 2** roda
num cluster GKE Autopilot que aparece na sua lista de clusters; **Composer 3** não expõe cluster e
tem tamanhos predefinidos. Confira qual o Terraform criou — muda onde os *workers* aparecem e o que
cobra.

**O que é deste projeto aqui.** Um ambiente; o *bucket* dele (`<região>-<ambiente>-<hash>-bucket`)
com `dags/fluxo_batch.py`; o projeto dbt acessível às tarefas (o `PROJETO=/opt/mvp_ed1` local vira
ou o próprio *bucket* `data/`, ou um pacote instalado, ou um `KubernetesPodOperator` — veja o que a
Etapa 13 escolher); a conexão HTTP ao Airbyte (cap. 05) e as variáveis do ambiente; a conta de
serviço do ambiente (idealmente `transformer` para o dbt); o `dbt` e o `mvp_ed1` em *PyPI packages*.

## Roteiro guiado

### A. O ambiente (consola do GCP)

1. **Environments.** Estado, versão do Composer e do Airflow, região, data de criação. *Por quê:*
   a data de criação é o início do taxímetro; região igual à do BigQuery/Cloud SQL.
2. **Environment configuration.** *O que olhar:* tamanho (*small*), *scheduler*/*web server*/
   *workers* (vCPU, memória, **min/max workers**), banco de metadados, conta de serviço, rede
   (IP privado?), *bucket*. *Por quê:* *max workers* é o teto de custo por rajada; conta de
   serviço é quem o dbt será no BigQuery.
3. **Airflow configuration overrides.** O `airflow.cfg` sobrescrito: `core.parallelism`,
   `scheduler.dag_dir_list_interval`, `webserver.*`. *Por quê:* onde a diferença entre o Airflow
   local e este mora.
4. **Environment variables** e **PyPI packages.** Variáveis (o `.env` que a DAG lê; **segredos
   aqui não** — devem vir do Secret Manager via *secrets backend*, veja em *overrides*
   `secrets.backend`); pacotes: `dbt-bigquery`, `mvp_ed1`. *Por quê:* mudar pacote **reinicia
   os *workers*** e leva 10–20 min — é o tipo de coisa que se faz antes da janela, não durante.
5. **Open DAGs folder.** Abre o *bucket* no Cloud Storage: `dags/` (o que o *scheduler* lê),
   `data/` (compartilhado com os *workers*), `logs/` (**os *logs* de tarefa, por
   DAG/tarefa/execução**), `plugins/`. *Por quê:* implantar uma DAG **é copiar um arquivo para
   `dags/`** — `gcloud composer environments storage dags import --environment <env>
   --location <região> --source airflow/dags/fluxo_batch.py`. Faça (ou refaça) e veja a DAG
   aparecer na UI em 1–2 min.
6. **Monitoring.** Painéis prontos: *Environment health* (o *heartbeat*), *Database health*,
   *Scheduler heartbeat*, *Workers* (CPU/memória, *queued tasks*), *DAG parse time*, *Task
   failures*. *Por quê:* é o que um operador olha antes de dizer "o Airflow está bem"; e
   *queued tasks* crescendo com *workers* no máximo é a resposta a "por que demora".
7. **Logs.** Abre o Logs Explorer filtrado em `resource.type="cloud_composer_environment"`.
   Troque o *log name*: `airflow-scheduler`, `airflow-worker`, `dag-processor-manager`,
   `airflow-webserver`. *Por quê:* *log* de tarefa é um; *log* de **por que a tarefa não foi
   agendada** é outro, e mora no *scheduler*.

### B. O Airflow (Open Airflow UI)

8. **DAGs.** `fluxo_batch` com as etiquetas `batch`, `armazem`; a chave *pause/unpause*; a
   coluna de execuções recentes. *Por quê:* DAG pausada não roda nem disparada à mão — é a
   primeira coisa a conferir. Compare com o Airflow local: a UI é a mesma versão de Airflow?
   (A DAG local usa `airflow.sdk` — Airflow 3; o Composer precisa suportar a mesma versão, ou a
   DAG precisa da forma compatível. É decisão da Etapa 13; confira qual valeu.)
9. **Trigger DAG** (o botão ▶). Sem parâmetros. Anote o `run_id` (`manual__2026-09-…`). *Por quê:*
   **é o "onde aciona"**. Alternativa reproduzível, no Cloud Shell:
   `gcloud composer environments run <env> --location <região> dags trigger -- fluxo_batch`.
10. **Grid.** A grade execução × tarefa, com estado por cor. Clique na execução: duração total;
    clique numa tarefa: **Logs**, **XCom** (a captura do legado passa o `snapshot_id` por XCom —
    veja `concluir_captura_do_legado` → *XCom*), *Rendered template* (o `bash_command` do dbt
    com o `--vars` resolvido), *Task details* (tentativas, `retries=0` de propósito). *Por quê:*
    é a tríade inteira numa tela: o *log* da tarefa é o `dbt build` daquela camada, com
    `PASS=… WARN=… ERROR=…` no fim — o mesmo que você lia no contêiner.
11. **Graph.** As 13 tarefas na ordem imposta (sincronizações em paralelo → `concluir_captura`
    → `dbt_seed` → camadas → `dbt_fronteiras` → `dbt_docs`). *Por quê:* a forma da DAG é a
    explicação do docstring dela; mostre-a.
12. **Acompanhe ao vivo, em três lugares ao mesmo tempo:** o *Grid* (tarefa corrente), o
    Airbyte (*Job history* — cap. 05: a tarefa `sincronizar_oltp_para_raw` é um *job* lá) e o
    BigQuery (*Job history* do projeto — cap. 04: cada `dbt_<camada>` vira dezenas de *jobs* da
    conta `transformer`). *Por quê:* orquestração é isto — um lugar aciona, dois executam, os
    três registram. Se fizer uma coisa só neste dia, faça esta.
13. **Uma reexecução parcial.** Quando terminar, *Clear* a tarefa `dbt_analytics` (com
    *downstream*) e veja só ela e as seguintes rodarem — sem repetir a ingestão. *Por quê:* é o
    motivo declarado do ADR-0003 para ter Airflow ("reexecução parcial"); provar na nuvem é a
    paridade **P4** demonstrada.
14. **Browse → Audit Logs / DAG Runs / Task Instances.** Sua ação de *trigger* e de *clear* com
    usuário e hora. *Por quê:* registro do sistema de que **você** operou.
15. **Admin → Connections / Variables.** A conexão do Airbyte (host, porta, sem senha visível) e
    as variáveis. *Por quê:* onde se muda o alvo sem mudar código; e onde **não** deve haver
    segredo em texto claro (se houver, achado).
16. **Logs de tarefa fora da UI.** No *bucket* `logs/fluxo_batch/dbt_trusted/<run_id>/1.log`
    e no Logs Explorer:
    ```
    resource.type="cloud_composer_environment"
    labels.workflow="fluxo_batch"
    labels.task-id="dbt_trusted"
    ```
    *Por quê:* o *log* sobrevive ao ambiente **só no *bucket*** e no Logging — é o que fica
    depois do `destroy` (cap. 11).

## Onde aciona, onde registra, o que controla

- **Aciona:** UI (*Trigger*), `gcloud composer environments run … dags trigger`, a REST API do
  Airflow, a agenda (`schedule=None` aqui: manual de propósito); *Clear* para reexecutar.
- **Registra:** *Grid*/*DAG Runs*/*Task Instances* (banco de metadados do Airflow), *logs* de
  tarefa (*bucket* `logs/` + Logging), *logs* de *scheduler*/*worker* (Logging), aba
  *Monitoring*, *Browse → Audit Logs*, e os *audit logs* do GCP (`composer.googleapis.com`).
- **Controla:** tamanho e *min/max workers*, *overrides* do `airflow.cfg`, variáveis e conexões,
  pacotes PyPI, conta de serviço do ambiente, rede, *labels*; pausar DAG; `max_active_runs=1`.

## Armadilhas

- **Ambiente ocioso cobra quase o mesmo que ocupado.** Pausa não existe; só *delete*. A
  conversa §8 fixou: quarta meio-dia é o ponto de decisão.
- **O *bucket* não morre com o ambiente.** Apagar o ambiente deixa o *bucket* (e os *logs*) —
  bom para evidência, ruim para a fatura se esquecido. Cap. 11 lista.
- Mudar pacote PyPI ou *override* = *workers* reiniciam = 10–20 min sem tarefa. Faça antes.
- Conta de serviço do ambiente sem `bigquery.jobUser` no projeto = todo `dbt` falha com
  `Access Denied: … jobs.create`. Cap. 02.
- DAG que importa `mvp_ed1` precisa do pacote instalado nos *workers*; `dbt` precisa do projeto
  acessível (o *bucket* `data/` é montado em `/home/airflow/gcs/data/`). Onde o Terraform pôs o
  projeto dbt é a primeira coisa a saber quando `dbt_seed` falhar com "no dbt_project.yml".
- Airflow 3 vs 2: a DAG local usa `airflow.sdk`; se o Composer da janela for Airflow 2, a DAG
  precisa da forma compatível. Não é decisão de dia de viagem.

## Evidência a levar

- Captura de *Environment configuration* (tamanho, *workers* min/max, conta de serviço, versão).
- Captura do *Grid* com o `fluxo_batch` inteiro verde e a duração; o `run_id`.
- O *log* da tarefa `dbt_fronteiras` com `Done. PASS=… TOTAL=…` (o mesmo formato do dossiê da
  Etapa 11: 14 testes de fronteira e o hook).
- Captura do *XCom* de `concluir_captura_do_legado` (o `snapshot_id` certificado).
- *Browse → Audit Logs* com o seu *trigger* e o *clear*.
- Captura de *Monitoring* durante a execução (*workers*, *queued tasks*).
- A consulta do Logs Explorer para os *logs* de uma tarefa.
- Duração da execução e hora de criação do ambiente → horas de Composer da janela (para o custo).

## O que você saberá dizer depois

- "Implantei a DAG copiando para o *bucket* do ambiente, disparei pela UI e por `gcloud`, e
  acompanhei a execução no *Grid* enquanto os *jobs* apareciam no Airbyte e no BigQuery."
- "Reexecutei só `analytics` para baixo com *Clear*, sem repetir a ingestão — a reexecução
  parcial que justificou o Airflow."
- "Composer cobra por hora de ambiente, ocioso ou não, e o *bucket* sobrevive ao ambiente; o
  ambiente subiu por último e desceu primeiro, e as horas estão no registro de custo."
