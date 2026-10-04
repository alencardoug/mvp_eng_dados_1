# Plano — material de estudo da fase local, em HTML

> **O que este arquivo é:** o plano do material didático que o Owner pediu em 04/10/2026, escrito
> **antes** de o material existir, para o Codex revisar. É transitório: sai da árvore quando o
> material for entregue, como saíram os `PLANO_etapa_12.md` e `REVISAO.md`.
>
> **O que este arquivo não é:** documento do projeto. Não entra no mapa do README, não decide nada
> sobre o projeto e não altera código, configuração ou camada nenhuma. O material que ele planeja
> também não é documento do projeto (§3).

| Campo | Informação |
|---|---|
| Revisão | 2 — responde à primeira rodada do Codex (achados na §13, respostas às sugestões na §14) |
| Data | 04/10/2026 |
| Base | `main` em `23a4ee0` (`v1.0.0`), árvore limpa antes deste arquivo |
| Situação | Execução **concluída** em 04/10/2026 (§15). Material entregue em `CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html`, com cópia privada no claude.ai (https://claude.ai/artifact/SigkpJDk5jtpS1W3DUPCWS). Nada commitado: H6 com o Owner |
| Destino do material | `CONVERSAS_COM_CHAT/` — um arquivo HTML único |

---

## 1. O pedido

Nas palavras do Owner: *"um arquivo html que explica todo o projeto. Quero aprender sobre tudo que
ocorre localmente. Meu objetivo é entender as diversas ferramentas, usá-las, ver o dado migrando, e
principalmente dizer que usei e sei usar o airflow, airbyte, etcetera. Controlar execuções, agendar,
simular, testar."*

O momento é o previsto no `CLAUDE.md` §1: *"o estudo do resultado é atividade posterior à entrega"*
— a fase local fechou em 04/10/2026 (M5, `v1.0.0`).

## 2. As escolhas do Owner

Feitas em duas rodadas de perguntas, com alternativas e recomendação. Os rótulos E1–E8 existem só
neste plano.

| # | Pergunta | Escolha |
|---|---|---|
| E1 | Fio condutor | **Jornada do dado + laboratórios por ferramenta**: primeiro seguir um pedido e um movimento de estoque por todas as camadas; depois um laboratório por ferramenta; por fim, operação |
| E2 | Ponto de partida | **"Quero aprender tudo"** — nenhuma base suposta: Docker, SQL e Python explicados do início |
| E3 | Exercícios que exigem mudar código | **Alvos existentes primeiro, depois uma branch `estudo`** que nunca vai para a `main` e se desfaz com `git` |
| E4 | Validação | **Executar cada laboratório na máquina e capturar a saída real, com data**, pelos alvos guardados, sem `FORCE`, devolvendo o estado encontrado |
| E5 | Laboratórios destrutivos (`reset`, `recovery-restore`) | **Escritos a partir do registro do B5** (25/09/2026, `data/medicoes/diario_b5.md`), sem destruir o ambiente atual; o roteiro fica pronto para o Owner executar como laboratório final |
| E6 | Profundidade | **O projeto + o essencial de mercado**. Cada recurso é classificado como **implementado neste projeto**, **aprofundamento** (o projeto usa; o laboratório vai além do uso dele) ou **experimento adicional** (o projeto não usa: agendamento, *retries* com espera, sensores, *backfill*, Variables e Connections no Airflow; agendamento de conexão no Airbyte; *exposures* no dbt), este último praticado só na branch `estudo` (EST-05) |
| E7 | Telas | **Capturas reais embutidas no HTML**, feitas pelo Chrome durante a validação; sem a extensão conectada, descrição em texto |
| E8 | Extras | Os quatro: **autoavaliação** com resposta escondida, **"como falar disso"** por ferramenta, **checklist de progresso** salvo no navegador, **glossário** ligado ao ponto onde o termo aparece |

## 3. O que o material é, e como ele convive com a regra de não duplicar

- **Um arquivo HTML autocontido**: CSS, JavaScript, diagramas SVG e imagens embutidos; abre
  *offline*, sem dependência externa. Tema claro e escuro. O checklist usa `localStorage` dentro de
  `try/catch` e o material funciona sem ele.
- **Fora do mapa do README**, como o `ARQUITETURA_E_CUSTOS_GCP.md` da mesma pasta, com o mesmo
  aviso no topo: não é documento do projeto.
- **A regra "cada assunto tem um dono documental"** (`CLAUDE.md` §5) é tensionada por qualquer
  material didático, que precisa recontar. O tratamento proposto:
  1. o material é **trilha**, não fonte: cada seção termina com o link para o dono documental
     (Execução Local, Arquitetura, ADR, Streaming…), e o aviso do topo diz que, em divergência,
     vale o documento;
  2. **nenhum fato novo sobre o projeto** nasce no material: o que ele afirma está num documento,
     no código ou numa saída capturada nesta validação;
  3. **todo número leva data e procedência** — "medido em 04/10/2026 nesta validação" ou
     "registro do B5, 25/09/2026" —, e o que não foi medido é rotulado pendente (P5);
  4. as três classes do E6 — **implementado**, **aprofundamento**, **experimento adicional** — vêm
     marcadas visualmente, para que o leitor nunca confunda o que o projeto faz com o que o mercado
     costuma fazer (EST-05).

## 4. Estrutura do material

```
0. Como usar este material          — ordem, tempo estimado, convenções, checklist em três níveis
1. Mapa                              — o que existe, por quê, e o que cabe na máquina (R11)
2. Fundamentos                       — §4.0 (13.1)
3. Jornada do dado                   — §4.1
4. Laboratórios                      — L0 a L8, o L5 em três etapas (§4.2)
5. Operar                            — falhas, quarentena, recuperação (registro do B5)
6. Desafio final, sem receita        — §4.3 (13.1)
7. Glossário                         — termos ligados aos pontos de uso
```

O checklist distingue três níveis por exercício — **li**, **executei com roteiro**, **repito e
explico sozinho** (13.1). A validação feita pelo agente prova que o roteiro funciona; a prática do
Owner é o que prova o aprendizado.

### 4.0 Fundamentos

Só o que o projeto exige, com exemplos tirados dele (13.1):

- **terminal**: diretório, `ls`/`cd`, *pipe*, variável de ambiente, código de saída — e por que um
  `| tee` esconde o código do comando (a lição da fase A, §8);
- **Git**: `status`, `branch`, `switch`, `diff` — o necessário para a branch `estudo` e a saída dela;
- **Docker**: imagem, contêiner, volume, rede, `docker ps`, `docker logs`, `docker exec`;
- **Python**: `uv` e o `.venv`, pacote e módulo (`src/mvp_ed1/`), função, `python -m mvp_ed1.airbyte`;
- **SQL**: banco × schema × tabela; `SELECT`, `WHERE`, `JOIN`, `GROUP BY`; as consultas da
  jornada servem de exercício.

### 4.1 A jornada do dado

**Caminho frio — o pedido `ORD-0000037`**, escolhido por ter 3 itens, 2 remessas e 1 cupom, e
porque o mesmo `order_id` 37 existe nas duas origens, o que mostra o empilhamento por
`source_system`. Paradas, todas já capturadas (§8): `source_db.oltp.orders` e `order_items` →
`raw.orders` (colunas `_airbyte_*`) → `staging.stg_retail__orders` (tipado e renomeado) →
`trusted.orders` (regras de negócio; a linha `legacy` ao lado) → `trusted.order_status_events` →
`analytics.fact_sales_order_item` (chaves substitutas por *hash*) e as dimensões →
`consumption.monthly_revenue_by_channel_and_category` (as linhas de 2025-07 que o pedido compõe).

**Caminho quente — um movimento de estoque produzido na validação** (`make stream-produce`):
`source_db.oltp.inventory_movements` → WAL → Debezium → tópico `mvp.oltp.inventory_movements` no
Redpanda (lido com `rpk`) → Beam → `raw.inventory_movements_stream` → e, depois da
sincronização e do `dbt-build`, `staging` (`arrived_by_stream`/`arrived_by_batch`) →
`fact_inventory_movement` → `consumption.skus_below_reorder_point` (`quantity_from_stream` ×
`quantity_from_batch`). **Ainda não capturado** (fase C).

**SCD tipo 2 — uma linha do tempo com o caso real do legado** (H1, aceito pelo revisor na §13.2):
o cliente 18, com uma versão fechada em `snapshots.scd_customer` (válida de 2026-09-07 a
2026-09-15), nascida do lote mutado da D44. No varejo não há histórico para mostrar (0 de 1.500).

### 4.2 Os laboratórios

Cada exercício declara **uma competência verificável** — por exemplo, "consigo localizar uma
execução do Airbyte, explicar o modo de sincronização dela e comprovar quais registros chegaram" —
e segue o molde **previsão → execução → evidência → explicação** (13.1). Em volta dos exercícios, o
laboratório traz o conceito do zero, o que observar (terminal, tela ou banco), o que muda de estado,
a autoavaliação e o "como falar disso". No L3 e no L5, uma tabela **tela ↔ comando ↔ código** liga
o que se clica na interface ao alvo do `make` e ao arquivo que o define (13.1).

As três colunas da direita são as classes do E6 (EST-05): **I** implementado neste projeto,
**A** aprofundamento, **X** experimento adicional — este só na branch `estudo`.

| Lab | Assunto | Comandos e telas principais | I · implementado | A · aprofundamento | X · experimento |
|---|---|---|---|---|---|
| L0 | A máquina e o Makefile | `make help`, `make ps`, `docker stats`, `make preflight ALVO=…` (consulta), as famílias que não convivem | preflight e troca de ambientes | — | — |
| L1 | Docker e Compose | as três composições + o *cluster* kind do Airbyte; rede externa (D55); volumes; `make logs`; `docker exec`; `kubectl get pods` dentro do kind. **Aviso explícito: nunca `make -n`** neste repositório | *healthchecks*, `mem_limit`, imagem por *digest*, rede externa | `kubectl` dentro do kind | *profiles* do Compose |
| L2 | PostgreSQL, Alembic e o gerador | `make psql-*`, `\dn`, `\dt`, `\d`; os `CHECK` que reconciliam totais; `make migrate-status`; modelos SQLAlchemy como fonte do schema; `make seed-plan` e `make legacy-plan` (sem tocar no banco); determinismo por `SEED`/`AS_OF` | índices, `CHECK`, `auto_explain` no armazém | `EXPLAIN` de uma consulta da jornada | — |
| L3 | Airbyte | interface (conexões, *streams*, modos, histórico de *jobs*, *logs*); `make sync-airbyte`; colunas `_airbyte_*`; incremental × *full refresh* (o pedido 37 não foi reextraído pelo *job* 50; as 8 views de `staging` derrubadas pela carga completa, §8); conexões como código — `airbyte/streams.yml` + Terraform | modos por tabela, Terraform, `drop_cascade` | `terraform plan` (só leitura) | agendamento de conexão, visto num `terraform plan` com `schedule_type = "cron"`, sem aplicar; fonte em modo CDC |
| L4 | dbt | camadas = schemas; `ref`/`source`; materializações; testes genéricos, singulares e `dbt_expectations`; *seeds*, *snapshots*, macros, `--vars`; seletores (`staging`, `+modelo`, `tag:fronteira`); `dbt ls`, `dbt compile`, **`dbt show`** (consulta sem materializar); `make dbt-build`, `make dbt-test`; `make dbt-docs` e o grafo de linhagem | Jinja, macros, *snapshots*, pacotes (`dbt_utils`, `dbt_expectations`, `dbt_date`), incremental `merge` (`fact_inventory_movement`), *seeds*, `+grants` | seletores, `dbt show`, `compile` | um modelo novo conferido por `dbt show`; um teste quebrado de propósito; *exposures* |
| L5a | Airflow — disparo, estados e *logs* | interface (lista, *Graph*, *Grid*, *log* da tarefa, XCom com o `legacy_snapshot_id`); CLI por `docker compose exec`; `make dag-run`/`dag-wait`/`dag-status`; pausar e despausar | TaskFlow, `BashOperator`, XCom, `override`, paralelismo, `max_active_runs=1` | a tabela tela ↔ comando ↔ código | — |
| L5b | Airflow — falha, *retry* e reexecução parcial | **reexecução parcial** com `airflow tasks clear` numa tarefa final da `fluxo_batch`; falha proposital e *retry* na DAG de estudo | `retries=0` por decisão (falha de dado não se resolve repetindo) | `tasks clear` na DAG real | *retries* com espera, *trigger rules*, sensor |
| L5c | Airflow — agendamento | agendamento, fuso horário, intervalo de dados, `catchup` e *backfill* na DAG de estudo, com a **concorrência do *backfill* limitada à parte** (13.1); como se agendaria a `fluxo_batch` (`schedule=None` → *cron*), **explicado e não aplicado** | `schedule=None`, `catchup=False` e o porquê | — | *cron*, *backfill*, `params`, Variables, Connections, *pools* |
| L6 | *Streaming* | `make stream-up` (o preflight pausa Airbyte e Airflow); API REST do Kafka Connect (`curl …/connectors/…/status`); `rpk topic list/consume` e `rpk group describe` dentro do Redpanda; `make stream-run`; `make stream-produce LIMITE=2200`; `make stream-duplicate`; `make stream-alerts`; `stream-corte`/`stream-wait`; a volta ao lote para reconciliar — oráculos na §5.4 | grupo de consumo com *commit* manual depois da escrita, *offsets*, janela, *watermark*, *allowed lateness* | *lag* do grupo pelo `rpk` | partições além de uma, *schema registry* |
| L7 | Governança e qualidade | papéis: `set role analyst` e a recusa em `raw`; classificação no `meta` dos `.yml`; linhagem no Dicionário §3; quarentena com motivo; `make legacy-catalogo`; `governance.legacy_captures`; testes de fronteira; `make check-offline`, `make check`; `secrets_review` | tudo o que a coluna ao lado lista | — | — |
| L8 | Operar — destrutivos e falhas | **escrito do registro do B5 (E5)**: ciclo do zero, `reset`, pacote de recuperação, `recovery-verify`, `recovery-restore`; os oito desvios do B5 como estudos de caso; a §6 da Execução Local como guia de diagnóstico | — | — | — |

### 4.3 Desafio final, sem receita

Três tarefas sem roteiro (13.1): seguir **outro** pedido da origem até o consumo; explicar **uma
rejeição** do legado, da quarentena até a regra do catálogo; diagnosticar **uma falha didática**
da DAG de estudo pelo *log*. O material dá só o enunciado e, escondido, o caminho de conferência.

## 5. A validação na máquina (E4)

Ordem escolhida para trocar de ambiente o menor número de vezes. Em toda fase: alvos guardados,
nenhum `FORCE`, nenhum `make -n`, nenhum alvo destrutivo, nada de `make test CARGA=1` nem
`FATO=1`; recusa do preflight **para a validação e volta ao Owner**; saída com segredo é redigida
antes de ser gravada (já feito em `airbyte-credentials`, §8).

Cada comando da retomada roda por um registrador que grava início, fim, **código de saída real**,
*commit* e a saída já redigida no `indice.tsv` da fase, em `data/medicoes/material_estudo/` (EST-06,
§8).

| Fase | De pé | O que roda | Estado |
|---|---|---|---|
| A | bancos + Airbyte (o estado encontrado) | L0–L4 e L7; as três consultas sem saída preservada (§8); telas do Airbyte e do catálogo do dbt; `terraform plan` na branch `estudo` (§5.3); `make dbt-build`, que também devolve as 8 views de `staging` derrubadas pelo *job* 50 | **parcial** (§8) |
| B | + Airflow (o par permitido) | `airflow-up`; **as provas do mecanismo de interrupção** (§5.2, item 5); a DAG de estudo na branch `estudo` (L5b, L5c) e a saída dela (§5.3); depois o portão de memória e **uma** execução completa da `fluxo_batch` (~7 min) sob o vigia (§5.2); `dag-status`; telas; `tasks clear` de uma tarefa final; `airflow-pause` | não começou |
| C | *streaming* (o preflight pausa os outros) | `stream-up`; produção, alertas e duplicatas pelos oráculos da §5.4; `stream-pause` | não começou |
| D | bancos + Airbyte | `airbyte-up` (pausa o *streaming*); `sync-airbyte`; `dbt-build`; o movimento na fato e na view; **`make check` como prova final** de que a validação deixou o armazém coerente | não começou |

**Estado a devolver**, o encontrado em 04/10/2026 às 04:08Z: os três bancos e o Airbyte de pé; os
contêineres do Airflow e do *streaming* existentes e parados.

**Estado agora, depois da fase A parcial:** o mesmo, com uma diferença — o *job* 50 derrubou
**8 das 36 views de `staging`**, as das tabelas em carga completa (`stg_retail__brands`,
`__carriers`, `__customer_segments`, `__inventory_movements`, `__payment_methods`,
`__product_categories`, `__sales_channels`, `__warehouses`). É o comportamento documentado — o
destino do Airbyte troca a tabela com `drop_cascade`, e as views só voltam no próximo `dbt` (cabeçalho
da `fluxo_batch`, Execução Local §6) —, mas até lá `staging` está incompleto. As 16 views de consumo
continuam de pé. O primeiro `make dbt-build` da retomada as devolve.

### 5.1 Mudanças de estado que a validação causa, e que não se desfazem sozinhas

| Ação | Efeito | Reversível? |
|---|---|---|
| `make sync-airbyte` (já feito, *job* 50) | `raw` atualizado; o contador de *jobs* avança; **8 views de `staging` derrubadas** até o próximo `dbt` | As views voltam no `make dbt-build`; o resto é operação normal |
| Uma execução da `fluxo_batch` (fase B) | **+1 captura legada certificada** retida em `raw_legacy` (hoje 213 MB em 29 capturas; *estimativa*, não medida: ~7 MB por captura), +1 fatia de quarentena, +2 *jobs* do Airbyte, histórico no Airflow | Só por restauração do pacote. É o que toda execução da DAG faz por desenho (ADR-0037, ADR-0044) |
| `make stream-produce LIMITE=2200` (fase C) | **+2.200 eventos no livro da origem**; a origem deixa de ser exatamente o que `SEED`/`AS_OF` geram; `.stream/producer_state.json` avança; o tópico de alertas cresce | Só por `seed-data FORCE=1` ou restauração. É a simulação desenhada (o B5 fez o mesmo, linha 6) |
| A branch `estudo` e a DAG de estudo (fases A e B) | Arquivos versionados na branch; registro, execuções, *backfills*, Variables e Connections no banco de metadados do Airflow; compilados em `dbt/target/` | Pelo procedimento da §5.3, com oráculo por artefato |
| `make dbt-docs`, `dbt compile` | `dbt/target/` regerado | Ignorado pelo Git |
| O pacote de recuperação aprovado (corte de 25/09) | Fica mais distante do estado atual — já estava: captura 49 e *job* 50 vieram depois dele | Um pacote novo só com decisão do Owner; **não está neste plano** |

### 5.2 Interrupção por falta de memória na fase B (EST-01)

O revisor tem razão: `make medir` só registra, e encerrar o `dag-wait` não cancela a DAG nem os
*jobs* já disparados — conferido em `docker/medir.sh` e `docker/airflow_cli.sh`
(`airflow_aguardar_run` só consulta). O projeto também não tem caminho de cancelamento de *job* do
Airbyte: `src/mvp_ed1/airbyte.py` dispara e acompanha, e nada mais. Três camadas, então: não
começar sem folga, vigiar durante, interromper pelo caminho que deixa estado terminal.

1. **Portão antes do disparo.** Com Airbyte e Airflow de pé e nada rodando, `MemAvailable` de pelo
   menos **3,0 GB**: a folga mínima do preflight (`FOLGA_MINIMA`, 1,5 GB) mais o acréscimo da DAG
   no B5 (de 2,3 GB previstos depois do `airflow-up` a 1,1 GB no pico, ~1,2 GB), arredondado para
   cima. Abaixo disso a DAG não é disparada, e a validação volta ao Owner (liberar a estação ou
   adiar).
2. **Vigia.** Um laço em segundo plano lê `MemAvailable` a cada 2 s enquanto a execução existe e
   grava cada amostra. **Gatilho: três leituras seguidas abaixo de 1,0 GB.** O número fica abaixo do
   mínimo que o B5 atravessou sem incidente (1,1 GB), para não interromper uma execução igual à
   dele, e deixa margem para a interrupção correr. O 0,5 GB da revisão 1 não tinha fundamento. O
   vigia é ferramenta da validação e vive em `data/medicoes/material_estudo/`, fora do repositório;
   não é componente do projeto.
3. **Interrupção, nesta ordem**, cada passo com prazo e registro, disparada pelo próprio vigia:
   1. `airflow dags pause fluxo_batch` — nenhuma tarefa nova começa (o comando que a Execução
      Local §3.2 já usa);
   2. **cancelar os *jobs* do Airbyte em curso**: listá-los pela API pública, com a autenticação de
      `mvp_ed1.airbyte`, e cancelar cada um (`DELETE /api/public/v1/jobs/{jobId}`). A tarefa
      `sincronizar` levanta erro quando o *job* não termina em `succeeded`, as seguintes ficam
      `upstream_failed`, e a execução falha por si;
   3. se a execução continuar `running` — a falta de memória veio numa tarefa de dbt —, marcá-la
      `failed` pela API REST do Airflow 3 (`PATCH /api/v2/dags/fluxo_batch/dagRuns/{run_id}` com
      `{"state": "failed"}`, token do SimpleAuthManager); o Airflow encerra as tarefas em curso dela;
   4. **confirmar o estado terminal com o oráculo do próprio projeto**: `make preflight
      ALVO=trabalho` até "nenhum trabalho em andamento — janela parada". Ele confere os *pods* de
      replicação do Airbyte e as execuções `queued`/`running` de toda DAG (`docker/preflight.sh`,
      `_trabalho_ativo`). Prazo de 5 min; vencido, a validação para e chama o Owner. **Nunca
      `docker stop`** sobre trabalho em curso — é o que o preflight existe para impedir.
4. **Devolver coerência**, depois do terminal:
   - a tentativa de captura legada que ficou `pending` é resolvida por `captura.retomar`, com o
     observador do Airbyte: o *job* terminou (cancelado), então ela é concluída e **não** fica
     elegível, e nenhuma captura nova nasce (`src/mvp_ed1/legacy/captura.py`, `retomar`). Oráculo:
     nenhuma linha `pending` em `governance.legacy_captures`;
   - `raw` e `staging`: `make sync-airbyte` e `make dbt-build`, os mesmos da fase D, refazem o que
     a sincronização cancelada ou o *build* interrompido deixaram pela metade;
   - `make check` verde como oráculo final, como na fase D.
5. **O mecanismo é provado antes da execução pesada**, ainda na fase B:
   - o `PATCH` de estado, numa execução da DAG de estudo com uma tarefa que dorme: marcá-la `failed`,
     conferir que a tarefa foi encerrada e que o `preflight ALVO=trabalho` volta a "janela parada";
   - a rota de cancelamento do Airbyte, sem efeito: um `DELETE` de `jobId` inexistente deve
     responder 404 e não 405. Se a rota não existir nesta versão, a execução completa não começa e
     a validação volta ao Owner. **O cancelamento real não é ensaiado**: ensaiá-lo custaria uma
     sincronização cancelada no `raw` de trabalho;
   - o vigia, com um limiar artificialmente alto e uma ação que só registra, para provar que
     dispara e grava.

### 5.3 A saída da branch `estudo` (EST-04)

Voltar à `main` só desfaz arquivos versionados, e o Compose do Airflow monta o diretório do
*checkout* (`../airflow:/opt/mvp_ed1/airflow:ro`). Cada artefato da branch tem saída e oráculo
próprios:

| Artefato | Onde vive | Como sai | Oráculo |
|---|---|---|---|
| DAG de estudo, modelo e teste dbt de estudo, a mudança no `airbyte/main.tf` | *commits* locais na branch `estudo`, nunca publicados | `git switch main` | `git status --porcelain` vazio; `ls airflow/dags` só com `fluxo_batch.py`; `git diff 23a4ee0 -- airflow dbt airbyte` vazio |
| Registro, execuções, *backfills* e XCom da DAG de estudo | banco de metadados do Airflow | a sequência abaixo | `airflow dags list` sem ela; nenhuma execução dela; não reaparece depois de ≥ 60 s |
| Variables e Connections de estudo, todas com prefixo `estudo_` | banco de metadados do Airflow | `airflow variables delete`, `airflow connections delete` | `variables list` e `connections list` sem `estudo_` |
| Compilados do modelo de estudo | `dbt/target/`, ignorado pelo Git | apagados os caminhos `*estudo*`; o `dbt-build` da fase D regera o resto a partir da `main` | `find dbt/target -path '*estudo*'` vazio |
| `terraform plan` | nada persiste (sem `-out`) | — | `sha256sum airbyte/terraform.tfstate` igual antes e depois |
| A branch | Git local | `git branch -D estudo` | `git branch` sem `estudo` |

Regras de construção que diminuem o que sai: a DAG de estudo **nunca escreve no armazém nem dispara
o Airbyte** — no máximo lê uma contagem, que é o pretexto para ensinar Connections; os modelos de
estudo **nunca** passam por `dbt build` ou `dbt run`, só por `compile` e `show`.

Sequência da DAG de estudo, nesta ordem, porque `airflow dags delete` com o arquivo ainda presente
deixa a DAG ser registrada de novo (linha 5 do diário do B5):

1. `airflow dags pause <dag de estudo>`;
2. execuções `queued` ou `running` e *backfills* em curso: esperar o terminal, com prazo, ou
   marcá-los `failed` pela API; oráculo: nenhuma execução `queued`/`running` dela;
3. `git switch main` — o arquivo sai do diretório montado;
4. esperar o *dag-processor* deixar de ver o arquivo;
5. `airflow dags delete <dag de estudo> -y`;
6. depois de ≥ 60 s, conferir que ela não voltou;
7. Variables, Connections, compilados e a branch, pela tabela.

### 5.4 Os oráculos da fase C (EST-02)

O revisor tem razão nas duas pontas: contagem estável também acontece com o consumidor parado, e
`comando_alertas` (`src/mvp_ed1/streaming/cli.py`) lê o tópico de alertas **desde o *offset* 0**,
com o histórico junto. A fase C fica assim:

1. **Linha de base.** `make stream-alerts` → N₀ alertas (com o histórico) e o *high watermark* do
   tópico de alertas pelo `rpk`; `make stream-corte` → S₀.
2. **Produção, pelo mecanismo do medidor:** `make medir CENARIO=streaming LIMITE=2200`. Ele já faz o
   que o achado pede, e o B5 o exercitou: preflight; Beam sob `setsid`; produtor; **o corte S₁ lido
   depois do produtor**; `stream-wait ATE_SEQ=S₁ PID=<beam>`; SIGINT no grupo de processos do Beam,
   com prazo e KILL de reserva (`docker/medir.sh`, linhas 286–295). Depois, `pgrep -f
   'mvp_ed1[.]streaming'` vazio — Prism incluído.
3. **Os alertas do intervalo:** `make stream-alerts` → N₁; os novos são **N₁ − N₀**, e o
   `rpk topic consume` a partir do *high watermark* de antes os mostra um a um. Zero é resultado
   registrado, não falha: o estado do produtor não é o do B5.
4. **O movimento seguido:** um `movement_id` com `event_sequence` em (S₀, S₁], lido na origem, no
   tópico e em `raw.inventory_movements_stream`.
5. **Duplicatas, com o Beam de pé de novo**, na mesma disciplina do medidor, à mão (`setsid`, grupo
   de processos, SIGINT, prazo):
   1. esperar o grupo `mvp_ed1_beam` sem atraso (`rpk group describe`). O *pipeline* confirma o
      *offset* **depois** da escrita (`src/mvp_ed1/streaming/transport.py`, `enable.auto.commit`
      falso), então *offset* confirmado é evento escrito;
   2. linha de base do destino: contagem, soma de `quantity`, *digest* ordenado de chave + colunas
      de negócio (`COLUNAS_DO_EVENTO`, `streaming/sink.py`) e *digest* do saldo por armazém/SKU — o
      precedente da Streaming §7.2;
   3. `make stream-duplicate QUANTAS=250`, o número da Streaming §7.2, e o *high watermark* H do
      tópico de eventos lido logo depois;
   4. esperar o *offset* confirmado de `mvp_ed1_beam` alcançar H — **a prova de que as duplicatas
      foram consumidas**, e não só de que a contagem parou; prazo vencido é falha registrada;
   5. repetir o item 2: os quatro iguais provam a idempotência; SIGINT no Beam; `pgrep` vazio.
6. `make stream-pause`.

## 6. Telas (E7)

- Captura pelo Chrome, com a extensão, nas interfaces do Airbyte (`:8000`), do Airflow (`:8081`) e
  do catálogo do dbt (`:8080`). O método de gravar a imagem em disco **ainda não foi verificado**
  (§9).
- **Nenhuma credencial na tela**: as telas de *login* não são capturadas; a senha do Airflow
  (arquivo gerado no api-server) e a do Airbyte (`make airbyte-credentials`) são lidas pelo Owner,
  e o material ensina **onde** lê-las, nunca o valor.
- Imagens em JPEG ou WebP, alvo de **até 8 MB** no arquivo final.
- **Verificação de segredos, arquivo a arquivo (EST-03).** A revisão 1 prometia "`secrets_review`
  sobre o HTML", e o revisor mostrou que isso não existe: `review` percorre só o `git ls-files`, e
  o argumento é a raiz. O procedimento passa a ter duas partes:
  1. **cada captura é inspecionada visualmente** antes de entrar no HTML, e de novo depois de
     comprimida — uma varredura de texto não lê pixels. O índice das evidências registra, por
     imagem: arquivo, URL, o que mostra e "nenhuma credencial, *token*, chave ou ID secreto
     visível". Imagem com algo sensível é refeita ou recortada, nunca borrada;
  2. **o HTML final e a pasta de evidências** passam por
     `data/medicoes/material_estudo/varrer_segredos.py`, que aplica as mesmas declarações de
     `mvp_ed1.secrets_review` — os valores secretos do `.env` e os detectores por forma — a cada
     caminho dado, rastreado ou não; código 0 exigido, e **controle positivo a cada uso** (um valor
     do `.env` plantado num arquivo temporário tem de ser achado). Exercitado em 04/10/2026 na pasta
     da fase A: achou um falso positivo, os códigos de cor ANSI do `abctl` lidos como atribuição;
     limpos os códigos, zero achados, e o controle positivo achado.
  Se o HTML for para o Git (H6), o `make check` passa a cobri-lo também.

## 7. Onde hesitei — pontos para o revisor e para o Owner

**H1 — SCD tipo 2 não tem exemplo no varejo.** Medido: 0 de 1.500 clientes `retail` com mais de
uma versão em `dim_customer`; a única versão fechada em `snapshots.scd_customer` é do **legado**
(cliente 18, `dbt_valid_to` 2026-09-15, nascida do lote mutado da D44). Mostrar o mecanismo ao vivo
exigiria um `UPDATE` manual em `source_db.oltp.customers` — mudança fora do gerador, que quebra o
determinismo da origem e entra para sempre nos *snapshots*, que são memória do armazém e conteúdo
do pacote de recuperação. **Proposta:** explicar com o caso real do legado e deixar o `UPDATE` como
laboratório opcional do Owner, marcado "não validado", com o aviso do que ele deixa para trás.
Alternativa: executar, se o Owner aceitar a marca permanente. *Revisão 2:* o revisor concorda com a
proposta e pede uma linha do tempo (§13.2) — incorporada na §4.1. A alternativa continua sendo
decisão do Owner.

**H2 — `stream-produce` altera a origem para sempre** (§5.1). Tratado como a simulação que o
projeto desenhou para isso. Pede o aceite do Owner porque a validação, e não o projeto, é que vai
rodá-lo agora.

**H3 — a execução da DAG retém mais uma captura legada.** Mesma natureza de H2.

**H4 — risco de memória na fase B.** No B5 a DAG foi o pico do ciclo: 6,5 GB nos contêineres e
**1,1 GB livres**, partindo de 3,7 GB livres antes do `airflow-up`. Agora há 4,7 GB livres com o
Airbyte de pé (§8), mas a estação roda outras coisas que o B5 não controlou. O preflight só confere
na subida, e a sincronização dentro da DAG nunca passou por ele (Execução Local §5). *Revisão 2:*
a revisão 1 dizia "interromper abaixo de 0,5 GB" sem dizer como — EST-01, bloqueante. O tratamento
está na §5.2: portão de 3,0 GB antes do disparo, vigia com gatilho em 1,0 GB e uma sequência de
interrupção que termina num estado conferido pelo preflight.

**H5 — a regra de não duplicar** (§3). A proposta é trilha com links e procedência em todo número.
O revisor pode achar que mesmo isso é duplicação e propor outro desenho (por exemplo, o material
só com roteiro e saídas, e todo conceito por link).

**H6 — o que entra no Git.** A pasta `CONVERSAS_COM_CHAT/` é rastreada. Um HTML com imagens em
base64 pesa alguns MB por versão no histórico. Decisão do Owner: versionar só a entrega final, não
versionar, ou separar as imagens.

**H7 — ensinar o "fora do projeto" sem ensinar errado.** Airflow 3 mudou CLI e API (api-server,
dag-processor, SimpleAuthManager, `airflow backfill create`). Todo exemplo de mercado roda na DAG
de estudo antes de entrar no material; o que não rodar sai ou fica marcado "não validado".

## 8. O que já foi executado, com a saída

Fase A, entre 04:08Z e 04:13Z de 04/10/2026, a partir do estado encontrado.

**Onde estão as saídas inteiras (EST-06):** `data/medicoes/material_estudo/20261004_fase_a/`, fora
do Git como o `data/medicoes/b5/` — 17 arquivos de saída, `indice.tsv` no formato do B5 (início,
fim, código, diretório, comando, arquivo), `consultas.sql` com o SQL exato de cada arquivo e
`LEIAME.md` com o *commit*, as versões das ferramentas e o estado no início e no fim. A pasta passou
pela varredura de segredos da §6. Até a revisão 1 elas só existiam no *scratchpad* da sessão.

O que essas evidências **não** têm, e o `LEIAME.md` diz: o **código de saída** — os comandos
rodaram encadeados em `tee`, que devolve o código dele; a **hora de início**, salvo na
sincronização (a hora gravada é o `mtime`, fim da escrita); e a saída de **três consultas** — a
escolha do pedido e as duas do histórico SCD, cujos números a H1 cita —, que só existem na conversa
e são reexecutadas na retomada. Da retomada em diante o registrador grava o código de verdade
(§5).

`make ps` e `make preflight`:

```text
mvp_ed1_legacy_db      Up 2 hours (healthy)   0.0.0.0:5433->5432/tcp
mvp_ed1_source_db      Up 2 hours (healthy)   0.0.0.0:5432->5432/tcp
mvp_ed1_warehouse_db   Up 2 hours (healthy)   0.0.0.0:5434->5432/tcp
[preflight] RAM disponível agora: 4,7 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 3,3 GB
[preflight] OK
…
[preflight] 'streaming' custa ~0,5 GB — sobraria 4,2 GB
RECUSADO — batch e streaming não sobem juntos (R11; a validação é por partes, ADR-0046).
```

`make airbyte-up` sobre o *cluster* de pé (D53) e `make airbyte-credentials`, redigido:

```text
[preflight] 'airbyte' já está de pé — nada a cobrar
cluster de pé — conferindo a API
aguardando a API do Airbyte pronta.
  Email: [not set]
  Password: <omitida>
```

Os *pods* do Airbyte dentro do kind (`kubectl get pods -n airbyte-abctl`): `server`, `worker`,
`temporal`, `workload-launcher`, `workload-api-server`, `cron`, `manifest-server` e `airbyte-db-0`
`Running`; `bootloader` `Completed`. `docker stats`: o nó do kind com 3,4 GiB.

A jornada do pedido, resumida (as saídas completas têm todas as colunas):

```text
source_db.oltp.orders   id 37 · ORD-0000037 · customer 1279 · delivered · total 10804.64
source_db.oltp.order_items   92, 93, 94 (variantes 87, 478, 48)
raw.orders   _airbyte_extracted_at 2026-09-25 15:53:56.73+00 · generation 2 · {"sync_id": 48}
staging.stg_retail__orders   order_status, order_total_amount, ingested_at …
trusted.orders   duas linhas com order_id 37: retail (10804.64) e legacy (7577.38)
analytics.fact_sales_order_item   3 linhas retail, chaves por hash; dim_customer: Julia Sousa, Campinas/SP
consumption.monthly_revenue_by_channel_and_category   2025-07 · Loja online · Fones de ouvido, Notebooks, Tênis
```

`make sync-airbyte`, das 04:10:27Z às 04:12:33Z:

```text
sync de oltp_para_raw (0ad04921-2da8-4319-b219-5e628399052e)
  job 50: running · 0 linhas
  …
  job 50: succeeded · 23.891 linhas
concluída: 23.891 linhas
real	2m6,702s
```

Antes e depois, em `raw`: `inventory_movements` com 13.700 linhas nos dois (carga completa, o
`max(_airbyte_extracted_at)` passou de 2026-09-25 15:53 para 2026-10-04 04:11); `orders` com 3.500
linhas nos dois, **3.443 ainda do `sync_id` 48 e 57 do 50** — o pedido 37 não foi reextraído.

## 9. Não verificado

- **A gravação das telas em disco** pela extensão do Chrome, e se ela está conectada.
- **O *login* da interface do Airbyte** com `Email: [not set]`.
- **Por que 57 pedidos foram reextraídos** num incremental sem mudança na origem. Hipótese, não
  conferida: o cursor do Airbyte compara com `>=`, e os 57 têm o `updated_at` igual ao maior valor
  do cursor. Precisa de uma consulta antes de entrar no material.
- **`dbt show`** neste projeto e nesta versão (dbt-core 1.12.3).
- **A CLI de *backfill* do Airflow 3.2.2** e o comportamento da DAG de estudo (agendamento,
  *retries*, sensor).
- **Se a DAG cabe na memória agora** (H4).
- **Se `LIMITE=2200` ainda gera alertas**: o produtor retoma do estado gravado, e o estado de hoje
  não é o do B5.
- **Se o `make check` da fase D passa** depois de tudo — esperado, não medido.
- **O tamanho por captura legada** (~7 MB) é divisão de 213 MB por 29, não medição.

Acrescentados na revisão 2:

- **A rota de cancelamento de *job*** (`DELETE /api/public/v1/jobs/{jobId}`) no Airbyte do *chart*
  2.3.0 — provada sem efeito antes da fase B (§5.2, item 5).
- **O `PATCH` de estado de execução** na API do Airflow 3.2.2 e o *token* do SimpleAuthManager —
  provados na DAG de estudo (§5.2, item 5).
- **O que `captura.retomar` grava** para uma tentativa cujo *job* foi cancelado. Lido no código,
  não exercitado: ela é concluída e não fica elegível.
- **Se uma sincronização cancelada deixa `raw` pela metade.** Premissa não conferida: o destino troca
  a tabela só no sucesso. A coerência não depende dela, porque a fase D sincroniza e reconstrói de
  qualquer jeito.
- **`airflow backfill create`, o limite de concorrência próprio do *backfill*** (13.1) e o
  cancelamento de *backfill* pela CLI do Airflow 3.2.2.
- **Quanto tempo o *dag-processor* leva** para deixar de ver uma DAG cujo arquivo sumiu.
- **Se `rpk group describe` mostra o *offset* confirmado** do grupo `mvp_ed1_beam`.
- **O gatilho de 1,0 GB do vigia** é escolha de número com fundamento (o mínimo do B5), não
  medição de onde a estação trava.

## 10. Premissas

- O `Exited (1)` do *scheduler* e do *dag-processor* do Airflow vem da pausa (`docker stop`) e não
  impede a retomada — não conferido; a fase B começa por `make airflow-up`, que passa pela troca do
  preflight.
- Os contêineres do *streaming*, parados há 8 dias, retomam por `make stream-up` com o conector e
  os *offsets* preservados.
- O Owner tem o Chrome com a extensão disponível durante a fase de telas.

## 11. Ambiente para a revisão

A revisão é de **plano**: nada precisa estar de pé. Estado atual: os três bancos e o Airbyte de pé
(o *job* 50 terminou, e 8 views de `staging` estão derrubadas até o próximo `dbt`, §5); Airflow e
*streaming* parados. Sondas de leitura no armazém são bem-vindas;
**nenhum alvo que suba, pause ou sincronize**, e nada no repositório enquanto a revisão corre.

## 12. Achado lateral, fora do escopo

Medido em 04/10/2026, em `analytics.fact_sales_order_item` × `dim_product`: **3.130 de 7.500**
itens do varejo foram vendidos **antes** do `launched_at` do produto (o pedido 37 é um deles: vendido
em 2025-07-01, produto `SKU-0000048` lançado em 2026-08-20). Nenhuma das 13 invariantes do
[Modelo de Dados §4](../docs/modelo_de_dados.md#4-invariantes-de-negócio) cobre lançamento × venda —
a 10 trata da causalidade do ciclo do pedido, não do catálogo. Não é assunto deste plano e nada foi alterado. Fica registrado para o Owner
decidir se vira pendência.

## 13. Achados da revisão

**Parecer do Codex — 04/10/2026, primeira rodada.** Base conferida: `23a4ee0`,
`main`, tag `v1.0.0`. A proposta é viável e atende ao objetivo do Owner: manter a
jornada do dado, os laboratórios por ferramenta e o HTML autocontido. Os pontos
abaixo ajustam a execução e a qualidade didática do material.

A revisão confrontou este plano com o código, os ADRs, os donos documentais e o
diário do B5. Nenhum laboratório foi executado e nenhum estado operacional foi
alterado pelo revisor. As evidências históricas consultadas não são medições novas.
Este registro do parecer, solicitado pelo Owner depois da revisão na conversa,
não retoma a execução suspensa na §11.

**Para o Claude:** responder a cada achado na coluna *Situação*, indicando a
alteração e onde ela foi feita, ou o motivo da discordância. Os bloqueantes têm
o alcance indicado na própria linha. Responder também às sugestões didáticas
abaixo; elas são recomendações para o material, não decisões de arquitetura.

| ID | Veredito | Achado | Situação |
|---|---|---|---|
| EST-01 | **bloqueante — fase B** | **H4 não define uma interrupção efetiva por falta de memória.** `make medir` registra recursos, mas não implementa o aborto abaixo de 0,5 GB. Encerrar `dag-wait` não cancela a DAG nem os jobs já disparados no Airbyte. Definir como identificar e interromper o trabalho ativo, confirmar seu estado terminal e devolver o ambiente coerente. Conferido em [medir.sh](../docker/medir.sh), caminho `ALVO`/`ATE`, e [airflow_cli.sh](../docker/airflow_cli.sh), `airflow_aguardar_run`. | **Aceito; reproduzido.** Conferi os dois arquivos e mais um fato: o projeto não tem caminho de cancelamento de *job* do Airbyte (`src/mvp_ed1/airbyte.py` só dispara e acompanha). Nova **§5.2**: portão de 3,0 GB antes do disparo; vigia com gatilho em três leituras abaixo de 1,0 GB; interrupção pausar → cancelar os *jobs* pela API pública → `PATCH` da execução para `failed` se ainda `running` → `make preflight ALVO=trabalho` até "janela parada", com prazo, e nunca `docker stop`; coerência devolvida por `captura.retomar` (nenhuma tentativa `pending`), `sync-airbyte`, `dbt-build` e `make check`. O mecanismo é provado antes da DAG pesada (item 5); o cancelamento real não é ensaiado, e o motivo está escrito. H4 aponta para a §5.2; os pontos não verificados entraram na §9. |
| EST-02 | **ajuste** | **O oráculo do L6 pode aprovar sem consumir as duplicatas.** Contagem estável também ocorre com consumidor parado. Confirmar o consumo até o offset das mensagens republicadas e comparar chaves, conteúdo e saldos antes/depois; há precedente em [Streaming §7.2](../docs/streaming.md#72-revalidação-da-d31). Explicitar na fase C o corte depois do produtor, a espera pelo corte e o encerramento de Beam/Prism, aproveitando o mecanismo existente no medidor. Medir os alertas novos daquele intervalo: `comando_alertas`, em [cli.py](../src/mvp_ed1/streaming/cli.py), lê o tópico desde o início, incluindo alertas históricos. | **Aceito; reproduzido.** Conferi `comando_alertas` (atribui a partição no *offset* 0) e `transport.py` (*commit* manual depois da escrita, o que faz do *offset* confirmado a prova de consumo). Nova **§5.4**: produção por `make medir CENARIO=streaming LIMITE=2200` (corte lido depois do produtor, `stream-wait` com `PID`, SIGINT no grupo de processos com prazo e KILL de reserva, `pgrep` vazio no fim); alertas do intervalo = N₁ − N₀, com os novos lidos pelo `rpk` a partir do *high watermark* de antes; duplicatas com o Beam de pé, *digests* de chave + colunas de negócio e de saldo antes e depois, e a espera pelo *offset* confirmado de `mvp_ed1_beam` alcançar o *high watermark* pós-duplicação. Tabela da §4.2 (L6) atualizada. |
| EST-03 | **bloqueante — entrega do HTML** | **A verificação prometida na §6 não cobre o arquivo fora do Git.** `review`, em [secrets_review.py](../src/mvp_ed1/secrets_review.py), percorre somente os arquivos de `git ls-files`; passar um HTML como argumento não o transforma numa varredura por arquivo, pois o argumento é a raiz do repositório. Definir a verificação explícita do HTML final e inspecionar visualmente cada captura antes de embuti-la: uma varredura textual não identifica uma senha visível nos pixels da imagem. | **Aceito; reproduzido.** `review` lê o conteúdo da árvore de trabalho, mas só dos caminhos do `git ls-files`. (A conferência do plano na revisão 1 valeu porque o plano entrou no índice como *intent-to-add* — `git add -N` — e saiu dele em seguida; isso não estava dito.) Nova parte da **§6**: inspeção visual de cada imagem antes e depois de comprimir, registrada por imagem; e `data/medicoes/material_estudo/varrer_segredos.py`, que aplica as declarações de `mvp_ed1.secrets_review` arquivo a arquivo, com controle positivo a cada uso. Exercitado na pasta da fase A: um falso positivo (códigos ANSI do `abctl`), zero depois da limpeza, controle positivo achado. |
| EST-04 | **ajuste** | **A saída da branch `estudo` precisa de procedimento próprio.** Voltar à `main` recupera arquivos versionados, mas não desfaz banco, histórico, agendamento nem arquivos novos não rastreados. O [Compose do Airflow](../docker/docker-compose.airflow.yml) monta o diretório do checkout. Prever pausa da DAG didática, resolução das execuções pendentes, retirada do arquivo e conferência da limpeza dos metadados. `dags delete` com o arquivo ainda presente permite o registro da DAG novamente, comportamento observado na linha 5 do [diário do B5](../data/medicoes/diario_b5.md). | **Aceito; reproduzido** no Compose (montagem `../airflow:/opt/mvp_ed1/airflow:ro`) e no diário (linha 5: "Removed 18 record(s)… a DAG registrada de novo"). Nova **§5.3**: tabela artefato → onde vive → como sai → oráculo, cobrindo arquivos da branch, metadados do Airflow, Variables e Connections com prefixo `estudo_`, compilados em `dbt/target/`, o `terraform plan` (`sha256` do estado igual) e a branch; sequência da DAG de estudo com pausa, execuções e *backfills* resolvidos, `git switch main` **antes** do `dags delete`, e conferência depois de ≥ 60 s. Duas regras de construção reduzem o que sai: a DAG de estudo não escreve no armazém nem dispara o Airbyte, e os modelos de estudo nunca passam por `build`/`run`. |
| EST-05 | **ajuste** | **E6 e a tabela dos laboratórios classificam como externos recursos já usados.** Jinja, macros, snapshots, pacotes dbt, estratégias incrementais, healthchecks e grupos de consumo fazem parte do projeto. Distinguir “implementado neste projeto”, “aprofundamento” e “experimento adicional”. Exemplos: [snapshot de cliente](../dbt/snapshots/scd_customer.sql), [pacotes](../dbt/packages.yml), [fato incremental](../dbt/models/analytics/fact_inventory_movement.sql), [Compose do Airflow](../docker/docker-compose.airflow.yml) e [transporte](../src/mvp_ed1/streaming/transport.py). | **Aceito; reproduzido**, e o erro era maior que o apontado: "índices e `EXPLAIN`" também estavam como externos, e o armazém tem 59 índices e `auto_explain` ligado. Confirmado do outro lado: o projeto não usa *profiles* do Compose, *exposures*, nem Variables, Connections ou *pools* na DAG. E6 (§2) e §3 reescritos com as três classes; a tabela da §4.2 ganhou as colunas **I · implementado**, **A · aprofundamento** e **X · experimento**, laboratório a laboratório. |
| EST-06 | **ajuste** | **As evidências completas da fase A precisam sobreviver à sessão.** A §8 aponta para um scratchpad, sem localização acessível ao próximo agente. Preservar as saídas completas em local persistente e identificado, com comando, data, versão e resultado, já sem segredos, antes da retomada. Isso permite conferir o HTML sem depender da memória da conversa que o gerou. | **Aceito; feito antes da retomada.** As 17 saídas estão em `data/medicoes/material_estudo/20261004_fase_a/`, fora do Git como o `data/medicoes/b5/`, com `indice.tsv` no formato do B5, `consultas.sql` com o SQL exato e `LEIAME.md` com o *commit* e as versões. A pasta passou pela varredura da §6. As lacunas estão declaradas, não preenchidas por suposição: código de saída não capturado (`tee`), hora de início só na sincronização e três consultas sem saída preservada, reexecutadas na retomada (§8). Da retomada em diante, um registrador grava o código de saída real (§5). |

### 13.1 Sugestões didáticas

- **Fundamentos antes dos laboratórios.** E2 promete começar do zero, mas Python
  quase não aparece na trilha. Incluir terminal, ambiente virtual, módulos e
  funções; em SQL, `SELECT`, filtros, `JOIN`, agregação e a diferença entre banco,
  schema e tabela. Limitar o conteúdo ao necessário para compreender o projeto.
- **Uma competência verificável por exercício.** Exemplo: “consigo localizar uma
  execução do Airbyte, explicar seu modo de sincronização e comprovar quais
  registros chegaram”. Cada exercício deve pedir uma previsão do resultado,
  execução, evidência e explicação do aluno.
- **Operação pela interface.** Para Airflow e Airbyte, mostrar o caminho na tela e
  relacioná-lo ao comando e ao código. O aluno precisa reconhecer o que o `make`
  automatiza e conseguir localizar execução, estado, logs e configuração.
- **Dividir o L5 em etapas.** Primeiro disparo, estados e logs; depois falha,
  retry e reexecução parcial; finalmente agendamento, fuso horário, intervalo de
  dados, catchup e backfill. Na DAG didática, limitar também a concorrência do
  backfill: no Airflow 3.2.2 esse limite é independente do limite da DAG, conforme
  a [documentação oficial](https://airflow.apache.org/docs/apache-airflow/3.2.2/core-concepts/backfill.html).
- **Desafio final sem receita.** Seguir outro pedido até o consumo, explicar uma
  rejeição do legado e diagnosticar uma falha didática. O checklist pode distinguir
  “li”, “executei com roteiro” e “consigo repetir e explicar sozinho”. A validação
  executada pelo agente comprova o roteiro; a prática do Owner comprova o aprendizado.

### 13.2 Parecer sobre as hesitações e limites da revisão

- **H1:** usar o histórico existente do legado para ensinar SCD, com uma linha do
  tempo. A ausência de várias versões no varejo não impede explicar o mecanismo.
- **H5:** manter as explicações dentro do HTML, com procedência, versão de referência
  e links aos donos documentais. Transformar todo conceito em link prejudicaria o
  material autocontido pedido pelo Owner.
- **E5:** manter os exercícios destrutivos apoiados no registro do B5, conforme a
  escolha já registrada.

Memória disponível para a execução, telas, `dbt show`, comportamento da DAG
didática e resultado final de `make check` continuam pendentes de validação.
Esta rodada não resolve as hipóteses da §9 nem representa aceite da implementação.

## 14. Resposta à primeira rodada — sugestões e parecer

**Às sugestões didáticas (§13.1)** — todas aceitas:

| Sugestão | Onde entrou |
|---|---|
| Fundamentos antes dos laboratórios | §4, item 2 da estrutura, e §4.0 — terminal, Git, Docker, Python e SQL, só o que o projeto exige e com exemplos dele |
| Uma competência verificável por exercício | §4.2: cada exercício declara a competência e segue previsão → execução → evidência → explicação |
| Operação pela interface | §4.2: tabela tela ↔ comando ↔ código no L3 e no L5 |
| Dividir o L5 | L5a (disparo, estados, *logs*), L5b (falha, *retry*, reexecução parcial), L5c (agendamento, fuso, intervalo de dados, `catchup`, *backfill* com a concorrência limitada à parte). O limite próprio do *backfill* ainda não foi visto rodando (§9) |
| Desafio final sem receita; checklist em três níveis | §4.3 e §4, abaixo da estrutura |

**Ao parecer sobre as hesitações (§13.2):**

- **H1:** a proposta e o parecer coincidem — a linha do tempo do cliente 18 do legado está na §4.1.
  Executar o `UPDATE` na origem continua sendo alternativa que só o Owner pode escolher.
- **H5:** mantido. As explicações ficam no HTML, com procedência e link ao dono documental (§3).
- **E5:** mantido.

**O que esta revisão não resolve**, e continua com o Owner: H2 e H3 (as marcas permanentes da DAG
e do produtor, §5.1), H6 (o que entra no Git) e a autorização para retomar a execução.

## 15. A execução, depois da revisão 2

Retomada pelo Owner em 04/10/2026 ("continue"), com os padrões da revisão 2: H1 pela linha do tempo
do legado, H2 e H3 executados, H6 para a entrega. Fases A a D entre 04:47Z e 05:56Z. Toda saída está
em `data/medicoes/material_estudo/20261004_fase_{a,b,c,d}/`, com `indice.tsv` e código de saída real
(registrador da §5), e as telas em `data/medicoes/material_estudo/telas/`, com `inspecao.tsv`.

**Resultados principais:** `make dbt-build` com `PASS=905` (fases A e D); a `fluxo_batch` com as 13
tarefas `success` em 6m 56s, `MemAvailable` mínimo 1,9 GB, contêineres 7,1 GB, captura **52**
certificada, e o vigia sem gatilho (mínimo 1.938 MB); a reexecução parcial pela API (`dbt_docs`, só
ela na tentativa 2); a DAG de estudo com agendamento, *retry*, sensor, falha proposital, `PATCH` para
`failed` e *backfill*, e a saída dela pelos oráculos da §5.3; o *streaming* com um movimento seguido
da origem ao destino quente em ~7 s, as duplicatas consumidas e os quatro *digests* iguais; e o
`make check` final com `PASS=905`, **637 passed, 8 skipped**. Estado devolvido igual ao encontrado.

**Desvios, todos registrados nos logs:**

| # | Onde | Desvio | Tratamento |
|---|---|---|---|
| 1 | §5.2, item 5 | A sonda de cancelamento respondeu **409** ("Job is not currently running"), não 404 | Rota existente — o 409 vem da lógica de cancelamento; o oráculo previsto estava errado |
| 2 | L5 | Variables e Connections **não gravam**: a `AIRFLOW_FERNET_KEY` não é chave Fernet (achado A) | DAG de estudo adaptada — sensor por arquivo-sinal, leitura por `mvp_ed1.db`; Variables e Connections no material como "não validado" |
| 3 | L5 | `ctx["logical_date"]` dá `KeyError` em execução manual no Airflow 3 | Corrigido na DAG de estudo (`ctx.get`); vira o desafio de diagnóstico |
| 4 | §5.3, passo 4 | Meu oráculo de `is_stale` procurava `true`; a CLI escreve `"True"` | Prazo vencido no laço; a DAG já estava obsoleta; conferido e seguido |
| 5 | §5.4, item 1 | O tópico de alertas **não existia** (N₀ = 0) | Registrado; o Redpanda cria tópicos sozinho |
| 6 | §5.4, item 3 | **0 alertas** com `LIMITE=2200`, contra ~60 aberturas no oráculo por janela | Teste extra com `LIMITE=200` (**+200 eventos na origem, fora do plano**) e espera de drenagem: 8 alertas, depois 14 (achado C) |
| 7 | — | Meus erros de execução: `| head` sob `pipefail` (código 255) e `pkill -f` casando com o próprio shell | Refeitos sem efeito colateral |
| 8 | §6 | A configuração inicial da interface do Airbyte nunca tinha sido feita | Concluída com dados fictícios, autorizada pelo Owner na conversa |
| 9 | L6 | A parcela quente da view `skus_below_reorder_point` não foi capturada: o `dbt-build` já a tinha absorvido | Explicada no material, marcada "não capturado" |

**Achados para o Owner** (nada foi alterado no projeto):

- **A — chave Fernet inválida.** `make env` (linha 172) e `airflow-up` (linha 466) geram a
  `AIRFLOW_FERNET_KEY` com 32 caracteres alfanuméricos; o Airflow exige 32 bytes em base64. Gravar
  Variable ou Connection falha com `Could not create Fernet object`. Nunca apareceu porque o projeto
  não grava nenhuma.
- **B — contagem dupla no ramo de alerta do *streaming*.** `AcumularSaldoEAlertar.setup` semeia o
  saldo com o que está no destino "antes de esta instância começar", mas no executor local o
  `setup` só roda quando o primeiro painel chega — e o estágio de gravação já escreveu eventos dessa
  mesma execução. Evidência: o evento 15930 (−29, par armazém 1 / variante 79) gravado às
  05:42:06.282; a semente às 05:42:06.547; o livro vai de 56 a 27; o alerta foi de **27 a −2**. O
  destino, a fato e a view não são afetados; o saldo do alerta é.
- **C — o medidor do *streaming* encerra o Beam antes de o ramo de alerta drenar.** `stream-wait`
  espera o destino (ramo 1), e o SIGINT vem em seguida. Com o offset confirmado defasado (6009, num
  log que começa em 13700, estado deixado pela restauração de 25/09), o Beam releu 13.700 mensagens
  e o ramo de alerta não recebeu nenhum painel antes do SIGINT. O "11 alertas" do B5 também dependeu
  de tempo.
- **D — o achado lateral da §12** (vendas antes do lançamento do produto) continua de pé.
- **E — observação:** 4 tabelas da origem (`customer_contacts`, `customer_preferences`,
  `price_lists`, `product_prices`) não estão no `airbyte/streams.yml`, e nenhum documento diz por quê.
