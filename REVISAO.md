# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `0dca0f9~1..339f09b` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
0dca0f9 feat: declara o GKE zonal com Workload Identity para Airbyte e Debezium
b24a356 feat: instala Airbyte e Debezium Server no GKE pelo Helm
60fbcee feat: acrescenta o destino BigQuery sem chave à declaração do Airbyte
e55d550 docs: registra o G3 em planos e os fatos conferidos do GKE e do Airbyte
9fbcd6b feat: fixa o Helm nas ferramentas para renderizar e desinstalar os releases
bab9055 docs: registra os charts renderizados e o cuidado com a conta do Airbyte
7933444 feat: cria a taxonomia, as policy tags e a leitura fina por papel
6ec7345 feat: declara o fluxo das policy tags com federação de identidade
b1e469d feat: deriva a policy tag de cada coluna da classificação no dbt
68c6f1d feat: converge, inventaria e prova a negação das policy tags
af1251e docs: registra a D79 e corrige a nota do ADR-0025
5fb5608 docs: registra o G4 escrito e o plano das policy tags
389d7c3 docs: acrescenta o desligamento do fluxo das policy tags ao desmonte
9606167 docs: registra a prova das policy tags com negação e auditoria
7ef0431 feat: grava domínio, dono e retenção como labels do BigQuery pelo dbt
91196c9 feat: mede a paridade da linhagem nativa e publica as travessias
7676b98 docs: registra a D80 e revê o G5 no plano e no mapa
3e93a38 docs: registra a paridade da linhagem e a coluna rastreada até a origem
6e9f1bf feat: prepara a DAG para o layout do Composer e a prova na imagem dele
be660de docs: registra a DAG provada no layout e na imagem do Composer
7c7bc2d docs: registra os labels de todas as relações e a reclassificação de ida e volta
03bd66e feat: acrescenta o airbyte-plan, que planeja a raiz airbyte/ sem aplicar
26e4be2 docs: registra a D62 provada no caminho quente local
1e5616f fix: faz o airbyte-plan dizer se não há mudança, se há ou se falhou
b64b1fb docs: registra a raiz airbyte/ sem mudança no plan local
891bd86 feat: personifica as contas de papel nos clientes do GCP e no dbt (D81)
507f6f7 feat: lê os segredos da DAG do Secret Manager pelas Variables do Airflow
7597179 feat: acrescenta ao layout do Composer a DAG de diagnóstico do smoke test
cff87f4 feat: declara o Composer 3 em Terraform
cdbdeb3 feat: acrescenta os alvos do Composer na janela e o kubectl
6a4a8e2 docs: registra o Composer em Terraform e a D81
9ee495b fix: faz o caminho quente da nuvem rodar no worker do Dataflow
0d8c555 feat: acrescenta o lançamento do caminho quente no Dataflow
e09b08b feat: declara o degrau do Dataflow em Terraform (D82)
4e0dea2 docs: registra o lançamento no Dataflow, a D82 e a D83
f6c45a5 fix: impede que o desmonte deixe peering, backup ou disco do Airbyte
d9b8dc3 feat: acrescenta o desmonte da §6.5 em alvos do make
75fb375 docs: registra o desmonte em alvos do make e o inventário padrão
8a82c8a feat: deixa as cargas das origens gravarem os registros fora do data/ local
d73a771 feat: acrescenta os alvos das origens no Cloud SQL pelo proxy
9b22a76 docs: escreve o roteiro de segunda e registra as origens no Cloud SQL
f7c2d42 feat: expõe a raiz do livro, o IP privado do Cloud SQL e os datasets
675f201 feat: acrescenta a época inicial da nuvem e o que ela pede antes
c8f8dd3 docs: escreve a parte 1 do roteiro de terça e registra a época inicial
be5dbc0 feat: acrescenta as capturas e o caminho quente da nuvem em alvos
b8eae8a docs: escreve a parte 2 do roteiro de terça e registra o que a P3 ainda não prova
3b703e6 feat: faz o oráculo da memória ler o BigQuery
7fadef3 feat: audita os jobs da conexão legada contra o livro
f9399b5 feat: acrescenta os alvos do oráculo da memória e da auditoria na nuvem
132edf2 docs: põe a memória e os jobs no roteiro de terça e registra o G2.1 inteiro
6f83fda refactor: tira dos testes a matriz do diário de mutações para o código
1bfceae fix: grava o diário das mutações no manifesto do legado do ambiente
b714d3c feat: acrescenta a fluxo_batch, as mutações e a matriz da quarta em alvos
633878c docs: escreve o roteiro de quarta e registra a matriz das duas capturas
c117f8e feat: mede a latência do caminho quente e o tamanho por dataset
b9e9c04 docs: põe a latência e o tamanho nos roteiros e registra a medida de hoje
f1c1c2c docs: passa os roteiros da janela da Etapa 13 (4e0dea2..b9e9c04) para revisão
1a211e4 fix: faz as provas da janela recusarem o que não provaram
b350c68 docs: reordena a terça e completa os roteiros com a regra de falha
069e1bb docs: responde à rodada 1 do lote janela
6739d58 fix: prova a resposta perdida da escrita quente e o reinício do Debezium pelo log
a17b994 docs: diz no roteiro o que o G2.3 prova e o que não
5328b10 docs: responde à rodada 2 do lote janela
b2792ce fix: decide o reinício do Debezium pelas frases do conector e confere o alerta da prova
fbd7986 docs: ajusta o mapa do G2.3 ao que as provas conferem
4fa0fdc docs: responde à rodada 3 do lote janela
f66ea9f fix: confere a listagem dos pods e só aceita as travessias possíveis do alerta
91278aa docs: responde à rodada 4 do lote janela
c7c0068 docs: registra a rodada 5 do lote janela, sem achados
79ab2b1 docs: fecha a revisão do lote janela da Etapa 13
623fbf1 feat: compara só o estado corrente na paridade local × nuvem (D85)
8472faa docs: registra as decisões D84 a D87 e a passagem da P1
9295f1e fix: corrige no registro a data da P1, que passou em 07/11
28c73a1 docs: registra a aprovação da estimativa da janela da Etapa 13
cbe69ee docs: registra o projeto de estudo e o põe no relógio de quinta
4888126 docs: registra o laboratório de estudo e os três achados dele
1f85574 docs: passa a sessão de 08/11 (79ab2b1..4888126) e o laboratório para revisão
31676ad fix: declara por objeto a história que a paridade não compara (RV0811-1-01, -02)
8fc7185 docs: responde à rodada 1 da revisão da sessão de 08/11
c73f863 docs: registra a rodada 2 da revisão da sessão de 08/11, só com uma observação
adcc657 docs: fecha a revisão da sessão de 08/11
cfd529e fix: restringe ao dono o estado local do Terraform, que guarda as senhas do Cloud SQL
339f09b docs: registra o roteiro de segunda, com o Cloud SQL de pé, povoado e provado
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 88 arquivos

- `.github/workflows/policy-tags.yml`
- `Makefile`
- `PLANO_etapa_13.md`
- `airbyte/main.tf`
- `airbyte/variables.tf`
- `airflow/composer/diagnostico_composer.py`
- `airflow/dags/fluxo_batch.py`
- `airflow/requirements-composer.txt`
- `dbt/dbt_project.yml`
- `dbt/macros/descricao_no_bigquery.sql`
- `dbt/macros/rotulos_no_bigquery.sql`
- `dbt/profiles.yml`
- `docker/docker-compose.airflow.yml`
- `docs/adr/0025-policy-tags-por-fluxo-automatizado.md`
- `docs/arquitetura.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/execucao_local.md`
- `docs/pendencias.md`
- `docs/registro_fase_gcp.md`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/gcp/acesso.py`
- `src/mvp_ed1/gcp/armazem_janela.py`
- `src/mvp_ed1/gcp/composer.py`
- `src/mvp_ed1/gcp/composer_cli.py`
- `src/mvp_ed1/gcp/credenciais.py`
- `src/mvp_ed1/gcp/debezium_log.py`
- `src/mvp_ed1/gcp/desmonte.py`
- `src/mvp_ed1/gcp/linhagem.py`
- `src/mvp_ed1/gcp/mutacoes_da_janela.yml`
- `src/mvp_ed1/gcp/mutacoes_janela.py`
- `src/mvp_ed1/gcp/oraculo.py`
- `src/mvp_ed1/gcp/origens.py`
- `src/mvp_ed1/gcp/politicas.py`
- `src/mvp_ed1/gcp/prova_composer.py`
- `src/mvp_ed1/gcp/prova_quente.py`
- `src/mvp_ed1/gcp/prova_tags.py`
- `src/mvp_ed1/gcp/quente.py`
- `src/mvp_ed1/gcp/residuos_esperados.yml`
- `src/mvp_ed1/generator/cli.py`
- `src/mvp_ed1/legacy/armazem.py`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/diario.py`
- `src/mvp_ed1/orquestracao.py`
- `src/mvp_ed1/recovery/job_audit.py`
- `src/mvp_ed1/recovery/livro_gcs.py`
- `src/mvp_ed1/recovery/memory_oracle.py`
- `src/mvp_ed1/recovery/sources.py`
- `src/mvp_ed1/registros.py`
- `src/mvp_ed1/streaming/dataflow.py`
- `src/mvp_ed1/streaming/nuvem.py`
- `src/mvp_ed1/streaming/pipeline.py`
- `streaming/dataflow/pyproject.toml`
- `terraform/.terraform.lock.hcl`
- `terraform/aplicacoes_gke.tf`
- `terraform/bigquery.tf`
- `terraform/charts/debezium-server/Chart.yaml`
- `terraform/charts/debezium-server/templates/configuracao.yaml`
- `terraform/charts/debezium-server/templates/conta.yaml`
- `terraform/charts/debezium-server/templates/disco.yaml`
- `terraform/charts/debezium-server/templates/implantacao.yaml`
- `terraform/charts/debezium-server/values.yaml`
- `terraform/cloud_sql.tf`
- `terraform/composer.tf`
- `terraform/dataflow.tf`
- `terraform/gke.tf`
- `terraform/helm/airbyte_gke.yaml`
- `terraform/papeis.tf`
- `terraform/politicas.tf`
- `terraform/rede.tf`
- `terraform/variables.tf`
- `terraform/versions.tf`
- `tests/test_armazem_janela.py`
- `tests/test_caminho_quente_nuvem.py`
- `tests/test_composer_ambiente.py`
- `tests/test_composer_cli.py`
- `tests/test_composer_layout.py`
- `tests/test_dataflow.py`
- `tests/test_desmonte.py`
- `tests/test_janela_legado.py`
- `tests/test_job_audit.py`
- `tests/test_legado_remocao.py`
- `tests/test_linhagem_gcp.py`
- `tests/test_memoria_bigquery.py`
- `tests/test_oraculo_consumo.py`
- `tests/test_oraculo_da_memoria.py`
- `tests/test_origens_gcp.py`
- `tests/test_politicas.py`
- `tests/test_prova_quente.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega.** Esta rodada é a do `plan` caro (PLANO §2.1, §6.2 P4, G3): o objeto
principal está **fora do Git** — os três planos regerados em 09/11 sem `apply`, em
`data/medicoes/etapa_13/planos/` (gitignored, só texto; os binários foram apagados porque levam o
estado com as senhas do Cloud SQL, §6.3):

- `08_gke_revisao.txt` — `VARS="enable_cloud_sql=true enable_gke=true"`;
- `11_dataflow_revisao.txt` — o anterior mais `enable_dataflow=true`;
- `10_composer_revisao.txt` — o anterior mais `enable_composer=true`.

A declaração de que nascem, no Git, revisão integral: `terraform/gke.tf`, `terraform/rede.tf`
(roteador e NAT), `terraform/iam.tf` e `terraform/papeis.tf` (conta dos nós, Workload Identity),
`terraform/dataflow.tf`, `terraform/composer.tf`, `terraform/variables.tf`, `terraform/versions.tf`,
e — não planejável hoje, só código — `terraform/aplicacoes_gke.tf` com `terraform/helm/airbyte_gke.yaml`,
`terraform/charts/debezium-server/` e `streaming/debezium_server/application.properties`. Derivado,
por amostragem: `terraform/acesso.auto.tfvars.json` (de `src/mvp_ed1/gcp/acesso.py`), que dá o IAM
por tabela do degrau do Dataflow. Contra o quê: a estimativa aprovada (`docs/capacidade_e_recuperacao.md`
§2.14), as contagens dos roteiros (`PLANO_etapa_13.md` §6.7–§6.9), a ordem do desmonte (§6.5,
`src/mvp_ed1/gcp/desmonte.py`) e o relógio (§6.4). O resto do intervalo `0dca0f9~1..` já passou
pelas revisões dos roteiros e da sessão de 08/11; entra só como contexto.

O que o Cloud SQL de hoje mudou (Registro §44): o estado tem agora a instância `mvp-ed1-origens`
(IP privado `10.40.0.3`, que o Composer recebe em `LEGACY_DB_HOST`), e o `gcp-apply` passou a
deixar o estado com `600` (`cfd529e`).

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
SKIPPED [1] tests/test_carga.py:52: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [4] tests/test_gcp_dialetos.py:94: só com GCP_TESTES=1 (BigQuery real)
SKIPPED [1] tests/test_governanca_bigquery.py:63: só com GCP_TESTES=1 (BigQuery real)
SKIPPED [1] tests/test_legado_remocao.py:563: sem mutações no diário: a prova entre capturas ainda não aconteceu
SKIPPED [1] tests/test_livro_gcs.py:170: só com GCP_TESTES=1 (Cloud Storage real)
SKIPPED [1] tests/test_memoria_bigquery.py:50: só com GCP_TESTES=1 (BigQuery real)
1286 passed, 19 skipped in 433.50s (0:07:13)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

### Medido nesta passagem (09/11, 12:20–12:40), fora do `make check`

Os três planos, pela guarda do `gcp-plan` (`mvp_ed1.gcp.desmonte conferir-plano`):

```
gcp-plan: 08_gke_revisao (construcao)  enable_cloud_sql=true enable_gke=true
Plan: 11 to add, 0 to change, 0 to destroy.
conferir-plano: construção: 11 a criar, 0 a alterar, 0 a destruir
gcp-plan: 11_dataflow_revisao (construcao)  enable_cloud_sql=true enable_gke=true enable_dataflow=true
Plan: 15 to add, 0 to change, 0 to destroy.
conferir-plano: construção: 15 a criar, 0 a alterar, 0 a destruir
gcp-plan: 10_composer_revisao (construcao)  enable_cloud_sql=true enable_gke=true enable_dataflow=true enable_composer=true
Plan: 29 to add, 0 to change, 0 to destroy.
conferir-plano: construção: 29 a criar, 0 a alterar, 0 a destruir
```

Por degrau (diferença de endereços entre planos sucessivos): GKE 11, Dataflow **4**, Composer **14** —
os números que os roteiros mandam esperar (§6.7 "11 a criar", §6.8 "4 a criar", §6.9 "14 a criar").
Contra o `10_composer.txt` de 07/11 (36): saem os 11 do Cloud SQL, já aplicados, e entram os 4 do
Dataflow, que o de 07/11 não ligava.

```
== GKE
google_compute_router_nat.this[0]
google_compute_router.this[0]
google_container_cluster.this[0]
google_container_node_pool.this[0]
google_project_iam_member.nos["roles/logging.logWriter"]
google_project_iam_member.nos["roles/monitoring.metricWriter"]
google_project_iam_member.nos["roles/monitoring.viewer"]
google_project_iam_member.nos["roles/stackdriver.resourceMetadata.writer"]
google_service_account_iam_member.identidade_do_cluster["ingestor"]
google_service_account_iam_member.identidade_do_cluster["streamer"]
google_service_account.nos[0]
== +Dataflow
google_bigquery_table_iam_member.papel["raw.inventory_movements_stream/insert/streamer"]
google_bigquery_table_iam_member.papel["raw.inventory_movements_stream/select/streamer"]
google_bigquery_table_iam_member.papel["raw.inventory_movements_stream/select/transformer"]
google_project_iam_member.streamer_dataflow_worker[0]
== +Composer
google_composer_environment.this[0]
google_project_iam_member.composer_worker[0]
google_secret_manager_secret.composer_airbyte["airbyte-client-id"]
google_secret_manager_secret.composer_airbyte["airbyte-client-secret"]
google_secret_manager_secret.composer_airbyte["airbyte-url"]
google_secret_manager_secret_iam_member.composer["airbyte-client-id"]
google_secret_manager_secret_iam_member.composer["airbyte-client-secret"]
google_secret_manager_secret_iam_member.composer["airbyte-url"]
google_secret_manager_secret_iam_member.composer["legacy-db-password"]
google_service_account.composer[0]
google_service_account_iam_member.composer_personifica["ingestor"]
google_service_account_iam_member.composer_personifica["transformer"]
google_storage_bucket.composer[0]
google_storage_bucket_iam_member.composer[0]
```

Configuração lida nos planos contra a Capacidade §2.14: nós `e2-standard-4`, `node_count = 2`,
`pd-balanced` de 50 GB, zonal `us-central1-a`, sem *spot*; *cluster* com `deletion_protection =
false`, nós privados, `REGULAR`, `workload_pool = "mvp-ed1-gcp.svc.id.goog"`; Composer
`ENVIRONMENT_SIZE_SMALL`, `composer-3-airflow-3.2.2-build.9`, `pypi_packages` `dbt-bigquery==1.12.2`,
`dbt-core==1.12.3`, `google-api-core==2.44.0`, *backend* de segredos do Secret Manager.

Os três planos trazem o mesmo aviso (também no `08_gke.txt` de 07/11):

```
Warning: Argument is deprecated

  with google_container_cluster.this,
  on gke.tf line 56, in resource "google_container_cluster" "this":
  56:   remove_default_node_pool = true

On newer cluster versions (1.36.4-gke.1469000+) omit initial_node_count and
node_config (or set initial_node_count = 0) instead.
```

A versão que o canal entregaria hoje (o `gke.tf` não fixa versão):

```
$ gcloud container get-server-config --zone us-central1-a --format="yaml(channels)"
- channel: REGULAR
  defaultVersion: 1.36.4-gke.2377000
  upgradeTargetVersion: 1.35.8-gke.1796000
```

A imagem do Composer existe na região (`gcloud composer image-versions` não existe nesta versão do
`gcloud`: `Invalid choice: 'image-versions'`; lida pela API REST,
`GET composer.googleapis.com/v1/projects/mvp-ed1-gcp/locations/us-central1/imageVersions`):

```
3
['composer-3-airflow-3.3.1-build.5', 'composer-3-airflow-3.2.2-build.9']
```

Cotas regionais de `us-central1` (`gcloud compute regions describe`), como `(uso, limite)`:

```
CPUS (0.0, 200.0)
E2_CPUS (0.0, 24.0)
SSD_TOTAL_GB (0.0, 500.0)
DISKS_TOTAL_GB (0.0, 4096.0)
IN_USE_ADDRESSES (0.0, 8.0)
INSTANCES (0.0, 24.0)
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **O `09_aplicacoes` não foi planejado** (os dois `helm_release`): o *provider* do Helm precisa do
  *cluster* para planejar (A27). Só o código foi lido; o roteiro espera "2 a criar" (§6.7).
- **Os planos do Dataflow e do Composer foram feitos com `enable_gke_apps=false`**; os de verdade
  (terça e quarta) levam `enable_gke_apps=true`. A premissa é que a única diferença sejam os dois
  `helm_release` — que nada do Composer nem do Dataflow dependa deles. Não provado por plano.
- **O aviso de depreciação do `remove_default_node_pool`** com a versão padrão de hoje
  (`1.36.4-gke.2377000`, acima de `1.36.4-gke.1469000`): não sei se o `apply` falha, se o *pool*
  padrão deixa de ser removido, ou se é só aviso. Não li a página do *provider* `google ~> 8.10`
  sobre isso nem a nota de versão do GKE.
- **Nada do que a API só valida no `apply`**: disponibilidade de `e2-standard-4` na zona no momento;
  a cota do projeto-inquilino do Composer; os intervalos de IP do Composer 3 na subrede `mvp-ed1`;
  a instalação dos `pypi_packages` contra as restrições da imagem `3.2.2-build.9` (`dbt-core 1.12.3`
  e `google-api-core 2.44.0` podem conflitar com o que a imagem fixa; o erro só aparece na criação,
  depois de ~25 min).
- **O caminho de rede do Composer 3 até o Cloud SQL** (`LEGACY_DB_HOST = 10.40.0.3`): o IP privado
  está do outro lado do *peering* dos serviços privados; o Composer 3 entra na VPC pela subrede.
  Não conferi na documentação oficial que esse tráfego atravessa o *peering* (*peering* não é
  transitivo).
- **Os preços**: não foram relidos; a estimativa é a de 07/11 (aprovada em 08/11). A configuração
  dos planos bate com ela; o preço-hora não foi conferido de novo.
- **O Dataflow nesta raiz é só IAM**: o *worker* (`n1-standard-2`, Streaming Engine) vem do comando
  que lança o *job*, não do plano; esta rodada não o mede.
- **O desmonte desses degraus não foi ensaiado**: os planos 20–22 (§6.5) só existem com os recursos
  de pé.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- A imagem listada pela API como disponível (`composer-3-airflow-3.2.2-build.9`) é criável na
  quarta; a lista pode mudar até lá.
- O canal `REGULAR` entrega na terça a mesma versão de hoje (ou uma com o mesmo comportamento do
  `remove_default_node_pool`).
- O crédito mensal de gerenciamento cobre um *cluster* zonal (a §2.14 conta como custo, no pior
  caso).
- Os *providers* resolvem as mesmas versões do `.terraform.lock.hcl` na terça e na quarta.
- O estado local é a verdade do projeto: ninguém criou recurso pela consola desde 08/11.

## 6. Ambiente que a revisão precisa

O que precisa estar de pé para as sondas, e como pôr de pé. **Subir é permitido;
alterar dado não.** A regra "deixar o ambiente como o encontrou" vale para o conteúdo
dos bancos e dos volumes — não para contêiner parado ou ausente, que o revisor sobe.

| Precisa de | Como subir | Como conferir |
|---|---|---|
| Os três bancos (`source_db`, `legacy_db`, `warehouse_db`) | `make up` — recria os contêineres sobre os volumes existentes; nada é regerado | `make ps`; portas no `.env` |
| Airbyte, Airflow ou streaming | `make airbyte-up` · `make airflow-up` · `make stream-up` — a troca é automática: pausa o conflitante, retoma depois | `make preflight ALVO=…` responde sem efeito |

Contêiner que não aparece em `docker ps -a` não está em outro contexto Docker: foi
derrubado por `make down`, que preserva os volumes. `make up` o traz de volta.

**Nunca** na revisão: `make reset`, `seed-*` ou `*-down` com `FORCE=1`, ou qualquer alvo que
reescreva dado — isso é execução, não revisão. Se o ambiente não puder ser preparado, a
indisponibilidade entra nos achados e o que dependia dela fica **não medido** — nunca inferido.

Nada além do mínimo, e **nada no GCP**: os três planos estão em texto em
`data/medicoes/etapa_13/planos/`; o código no Git. O Cloud SQL `mvp-ed1-origens` está de pé e
cobrando desde as 11:30 (até quinta) — a revisão não precisa dele e não deve tocá-lo. Proibido:
qualquer `make gcp-*` que não seja de leitura, `terraform plan`/`apply`, e qualquer chamada que crie
recurso. Leitura de documentação oficial na rede, sim. O Airbyte local está pausado; não é preciso.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Planejar hoje, sem o *cluster*, em vez de esperar terça.** A rodada estava prevista para a
  terça, com o GKE de pé (o que daria o `09_aplicacoes` real). Adiantar dá um dia para corrigir um
  bloqueante antes da P4 (ter 20:00), ao preço de revisar o Dataflow e o Composer com
  `enable_gke_apps=false` e o Helm só como código. Se o Codex julgar que isso não basta como "`plan`
  caro revisado", a proposta é um complemento curto na terça, só com o `09_aplicacoes`.
- **Nomes `_revisao`**, como o `06_cloud_sql_revisao` de 07/11: para que nenhum `gcp-apply` aplique
  um plano de revisão. Os oficiais são regerados nos roteiros.
- **Não mexi no `remove_default_node_pool`** antes da revisão: a correção (tirar o argumento,
  `initial_node_count = 0`) muda o plano do *cluster*, e prefiro o parecer antes de mudar a
  declaração que vai custar dinheiro.
- **O intervalo `0dca0f9~1..`** pega commits de documentação e de outras peças; filtrei no mapa
  o que é do degrau caro.

---

## Achados da revisão

### 1. Conclusão

**Mudanças necessárias.** A revisão antecipada dos três planos foi realizada, mas não encerra o
pré-requisito de revisão do degrau das aplicações: falta o complemento sobre o `09_aplicacoes`
real, antes do seu `apply` de terça. Esse bloqueio se restringe àquele degrau; não exige esperar
pelas aplicações para revisar o GKE. Há dois ajustes de declaração a resolver: a exclusão dos
objetos dos buckets e a correspondência entre o dimensionamento do Composer e a estimativa.

Não encontrei conflito demonstrado nos três pacotes do Composer nem impedimento arquitetural
de rede para chegar ao IP privado do Cloud SQL.
Isso não é prova de um `apply` bem-sucedido nem aceite do Owner.

### 2. Escopo e versão revisados

Rodada 1 do `plan` caro, sobre `b092841e153597bda84d7162d6244b776d7ec274`, em 09/11/2026.
Leitura integral da declaração indicada no pedido: GKE, rede, IAM, papéis, Dataflow, Composer,
variáveis, providers e lock; aplicações Helm, valores locais e do GKE, chart do Debezium Server
e suas propriedades. O derivado `acesso.auto.tfvars.json` foi confrontado com o gerador e o
manifest local. Foram lidos os três textos de revisão completos, comparados com os de 07/11,
contra Capacidade §2.14, PLANO §6.2–§6.9, Registro §44 e decisões vigentes. Nenhuma delas foi
reaberta.

Identificação dos textos fora do Git, por SHA-256 calculado nesta revisão:

| Arquivo em `data/medicoes/etapa_13/planos/` | SHA-256 |
|---|---|
| `08_gke_revisao.txt` | `17d2fc8e3ae95bc9674897d67f725c452cae011c8b6cfa3abd0701214bde5514` |
| `11_dataflow_revisao.txt` | `047094476abd7796f22525aa8adb917ffe1c150452fa8b37165fc6290b215128` |
| `10_composer_revisao.txt` | `e9920d9ea103d57d78d5d7d502fb603e50e652c2f5e7d57bc7557b9ad66f4f3f` |

A declaração examinada não tinha diferenças contra `b092841`. Foi observada uma alteração
externa em `docs/registro_fase_gcp.md`, acrescentando a §45; não foi feita nem alterada pelo
revisor e não integra a versão do declarativo aqui identificada.

### 3. Evidências dos achados

**RVPC-1-01 — complemento obrigatório do plano Helm (alta, pré-requisito de execução).**
`REVISAO.md` §4 declara que `09_aplicacoes` não foi planejado. `terraform/aplicacoes_gke.tf:11`,
`:25` e `:55` condicionam somente os dois releases a `enable_gke_apps`; a busca
`rg -n 'enable_gke_apps|helm_release|local\.aplicacoes' terraform -g '*.tf' -g '!**/.terraform/**'`
não encontrou dependência dessas aplicações em `composer.tf` ou `dataflow.tf`. A inspeção dos
demais recursos e referências também não revelou dependência indireta que alterasse aqueles
degraus. Assim, ligar a variável acrescenta os dois releases no declarativo atual; depois de
aplicados, eles devem estar sem alteração nos planos seguintes. Isso não prova ausência de
drift ou mudanças de valores que só o provider Helm revelará com o cluster de pé.

O PLANO `:470` exige plano revisado antes de nascer qualquer recurso daquele degrau; `:474`
exige leitura integral e aprovação do plano salvo. A leitura do código nesta rodada é válida
como revisão antecipada, mas não substitui o plano. O complemento deve ocorrer entre os passos
4 e 5 da §6.7, **antes do apply dos releases**, sem esperar a P4 das 20:00: revisar o texto real
de `09_aplicacoes`, conferir `2/0/0`, valores, versões e sensíveis, e registrar o parecer. Os
planos reais seguintes continuam sujeitos ao rito e às contagens incrementais `4/0/0` e
`14/0/0`; divergência substantiva exige revisão antes de aplicar.

**RVPC-1-02 — `force_destroy` deixa a política de soft delete em aberto (média).**
`terraform/composer.tf:97` declara o bucket com `force_destroy = true`, sem
`soft_delete_policy`; o plano `10_composer_revisao.txt:836` a deixa como
`soft_delete_policy (known after apply)`. A mesma omissão está em
`terraform/armazenamento.tf:17`, dono do bucket `beam` que o Dataflow usa para staging e
temporários (`src/mvp_ed1/streaming/dataflow.py:50`). O desligamento do Composer leva seu bucket
no passo 2; o bucket Beam fica até o passo 8 (`src/mvp_ed1/gcp/desmonte.py:62` e `:69`).

A [documentação de soft delete](https://docs.cloud.google.com/storage/docs/soft-delete)
informa o padrão de sete dias — “default retention duration of 7 days” — e afirma:
“Soft-deleted objects continue to accrue storage charges until their retention period expires
and they're permanently deleted.” O `force_destroy` esvazia o bucket, mas não desliga essa
política. Portanto, a declaração não sustenta a promessa de eliminação dos objetos no destroy;
listagem comum vazia tampouco prova ausência das cópias retidas. Não foi medido o valor dessa
cobrança, e não afirmo que ultrapasse US$ 70. O relógio de desvinculação do faturamento continua
obrigatório, mas não substitui o caminho de exclusão dos objetos.

Proposta: declarar explicitamente `soft_delete_policy { retention_duration_seconds = 0 }` no
bucket novo do Composer e tratar a mesma política dos buckets existentes antes de suas próximas
exclusões. Conferir a política efetiva e possíveis versões já retidas no desmonte. Desativar
agora não reduz o prazo de objetos anteriormente excluídos sob a política antiga. O livro usa
a mesma declaração de buckets; a retenção da D70 é outra política e permanece regida pela
decisão existente.

**RVPC-1-03 — tamanho da infraestrutura não declara o preset do Composer (média).**
`terraform/composer.tf:153` fixa apenas `environment_size = "ENVIRONMENT_SIZE_SMALL"` e não
declara `workloads_config`; `10_composer_revisao.txt:273` deixa o bloco inteiro conhecido só
depois do apply. O Registro `:171` fundamenta o custo no preset com scheduler 0,5 vCPU/2,5 GB,
triggerer 0,5/0,5, DAG processor 1/2, web server 1/2,5 e workers 1/2, entre 2 e 4. Capacidade
`:584` usa a hipótese de 12–15 DCUs para a estimativa aprovada.

A [documentação de escala](https://docs.cloud.google.com/composer/docs/composer-3/environment-scaling)
afirma: “Environment size is different from environment presets.” O tamanho controla a
infraestrutura gerenciada; recursos dos componentes e limites de workers são parâmetros
distintos. Logo, o plano não demonstra o dimensionamento que o dossiê diz corresponder à
estimativa. Não há evidência nesta revisão de que os defaults efetivos sejam maiores, nem de
estouro de custo; a lacuna é depender deles sem identificá-los. Proposta: declarar os recursos,
quantidades e limites de autoscaling correspondentes à configuração já estimada, ou apresentar
evidência dos defaults da API para essa imagem que demonstre a equivalência. Não se propõe
reaprovar o escopo nem substituir a estimativa aceita.

**RVPC-1-04 — pool padrão transitório desnecessário na versão informada (baixa).**
`terraform/gke.tf:56` combina `remove_default_node_pool = true` com `initial_node_count = 1`;
o plano GKE `:200` e `:214` confirma ambos. O dossiê §3 informa REGULAR
`1.36.4-gke.2377000`; essa consulta não foi refeita pelo revisor.

A [documentação do provider na tag v8.10.0](https://github.com/hashicorp/terraform-provider-google/blob/v8.10.0/website/docs/r/container_cluster.html.markdown),
no argumento `remove_default_node_pool`, mantém: “If `true`, deletes the default node pool upon
cluster creation.” Para `1.36.4-gke.1469000+`, documenta cluster sem pool padrão ao omitir
contagem e configuração inline. A leitura é aviso com criação/remoção transitória, não falha
ou retenção permanente causada pela depreciação. A declaração mínima omite **as duas** linhas
56–57 (ou omite `remove_default_node_pool` e usa `initial_node_count = 0`), mantendo o pool
separado. Retirar só a flag mantendo contagem um deixaria um pool adicional. Mudança exige novo
plano revisado e versão efetiva compatível na terça.

### 4. Verificações executadas

Somente leituras locais, consultas à documentação oficial e o comando de testes expressamente
autorizado. Os resultados abaixo são desta revisão; as provas anteriores permanecem atribuídas
ao autor.

```text
$ git rev-parse HEAD
b092841e153597bda84d7162d6244b776d7ec274

$ .venv/bin/python -m pytest -q tests/test_desmonte.py tests/test_origens_gcp.py tests/test_makefile.py
125 passed in 10.95s
```

Um script Python de leitura extraiu os blocos entre `Terraform will perform` e `Plan:`, comparou
os endereços e os corpos entre os seis textos e calculou seus hashes. Resultado:

```text
08_gke_revisao.txt       11 recursos   Plan: 11 to add, 0 to change, 0 to destroy.
11_dataflow_revisao.txt  15 recursos   Plan: 15 to add, 0 to change, 0 to destroy.
10_composer_revisao.txt  29 recursos   Plan: 29 to add, 0 to change, 0 to destroy.
08_gke.txt              11 recursos   Plan: 11 to add, 0 to change, 0 to destroy.
11_dataflow.txt          4 recursos   Plan: 4 to add, 0 to change, 0 to destroy.
10_composer.txt         36 recursos   Plan: 36 to add, 0 to change, 0 to destroy.
```

Os blocos comuns dos planos novos coincidem, salvo linhas em branco; os incrementos são 4 e
14. As diferenças contra 07/11 correspondem ao estado já aplicado e às variáveis agora
conhecidas. Não foram encontrados recursos de alteração ou destruição nessas comparações.

Outro script Python carregou `src/mvp_ed1/gcp/acesso.py` sem executar seu `main`, chamou
`derivar` sobre `dbt/target/manifest.json` e comparou com o JSON existente:

```text
acesso derivado confere: True
pendentes_por_tabela: [{"tabela": "raw.inventory_movements_stream", "grants": {"insert": ["streamer"], "select": ["streamer", "transformer"]}}]
terraform/composer.tf referencias a enable_gke_apps/helm_release/local.aplicacoes: []
terraform/dataflow.tf referencias a enable_gke_apps/helm_release/local.aplicacoes: []
```

Conferências sem novo achado, para delimitar o que foi efetivamente examinado:

- **Rede Composer → SQL:** a [página de interfaces PSC](https://docs.cloud.google.com/vpc/docs/about-private-service-connect-interfaces)
  afirma: “A Private Service Connect interface connection is transitive.” Inclui destinos em
  redes ligadas ao consumidor por VPC Network Peering. A [página de conexão do Composer 3](https://docs.cloud.google.com/composer/docs/composer-3/connect-vpc-network)
  descreve o attachment criado por `network`/`subnetwork` e exige: “Make sure that four IP
  addresses per environment are available in your VPC subnetwork.” A sub-rede `10.10.0.0/20`
  (`rede.tf:27`) comporta os quatro IPs e não conflita com a faixa interna padrão
  `100.64.128.0/20`, nem com `10.40.0.0/20` do PSA. O caminho declarado não é uma cadeia de dois
  peerings. O attachment automático sai com o ambiente segundo essa mesma documentação.
  Conectividade TCP efetiva fica para a tarefa `rede`; sua falha, isoladamente, não demonstra
  necessidade de trocar a arquitetura para PSC no Cloud SQL.
- **Pacotes Composer:** foram lidos `airflow/requirements-composer.txt`,
  `g2_4/resolucao_com_a_imagem.txt` e os dois relatórios de prova em `g2_4/`. O relatório
  `prova_composer_dbt_seed_20261108T003051Z.json` registra as três versões exatas,
  `falhas: []`, importação sem erro e dbt `codigo: 0`, `PASS=4`; a prova anterior registra
  `PASS=455`. São evidências anteriores de instalação e execução na imagem, não uma nova prova
  do serviço gerenciado. Não há base para condenar essas versões por serem diferentes das
  pré-instaladas. Havendo conflito no builder gerenciado, a falha será na instalação de
  dependências da criação, não no plan; o limite de criação de 90 minutos não é falha barata.
- **Identidades e segredos:** namespaces e nomes do Workload Identity coincidem com
  `debezium/debezium-server` do chart e `airbyte/airbyte-admin` da declaração e da renderização
  registrada na §21. O chart remoto não foi baixado/renderizado novamente. Prefixo `mvp-ed1`,
  separador `-`, quatro nomes em `orquestracao.SEGREDOS`, IAM por segredo e preenchimento no
  runbook coincidem. A conta do Composer personifica somente ingestor/transformer, como D81.
  Não foi encontrado valor de credencial no declarativo versionado examinado; senhas e token
  são referências sensíveis. Isso não equivale a varredura de todo o histórico do Git.
- **IAM Dataflow:** os quatro recursos são incrementais sobre concessões existentes:
  `papeis.tf:43` já dá `bigquery.jobUser`; `armazenamento.tf:58`, acesso aos objetos do bucket
  Beam; `:119` e `:127`, publicação e consumo Pub/Sub. A tabela é criada antes do IAM pelo
  roteiro §6.8. O job usa `mvp-streamer`, uma VM privada `n1-standard-2`, Streaming Engine e
  um worker fixo (`streaming/dataflow.py:45`). Não identifiquei concessão faltante no caminho
  lido. A [documentação de permissões do Dataflow](https://docs.cloud.google.com/dataflow/docs/concepts/security-and-permissions)
  exige worker com `dataflow.worker` e acesso aos recursos usados; a tabela pode receber
  `dataEditor` no próprio objeto. Não é preciso conceder `dataflow.admin` ao worker só para
  consumir e escrever; o lançador é o Owner. A execução e os service agents não foram sondados.
- **Custo e desmonte:** LB interno e NAT estão previstos na estimativa. Nenhum LB externo foi
  declarado. NAT automático atende as faixas primária e secundárias; não há limite explícito
  de um IP/porta a impedir os dois nós, mas carga e portas não foram medidas. Os discos de boot
  são os dois de 50 GB previstos; os PVCs das aplicações são adicionais, com saída pelos passos
  3–4. Passo 2 desliga Composer e IAM Dataflow; passo 3 leva releases; passo 5 leva cluster,
  pool, IAM dos nós, router e NAT. Namespace/PVs/LB são conferidos antes do cluster, e discos,
  instâncias, forwarding rules e attachment depois (`Makefile:1526` e `:1541`). O bucket Beam
  fica até o passo 8. Há caminhos declarados para esses recursos; a ressalva sobre retenção de
  objetos é RVPC-1-02. Os valores reais de DCUs, logs, tráfego, discos PVC e Streaming Engine
  não foram medidos, portanto não se certifica consumo dentro de US$ 40–70 por estes planos.

### 5. Limites

Nenhum comando de infraestrutura, serviço, banco ou aplicação foi executado. Não foram lidos
`.env`, estados Terraform ou backups de estado. Não foram feitos apply, novo plan, renderização
Helm, instalação de pacotes, acesso ao Cloud SQL, consulta de IAM/cota/preço na API nem ensaio de
desmonte. Os testes autorizados verificam comportamento local e guardas; não certificam APIs GCP.

Foram lidas oito páginas oficiais distintas com conteúdo disponível; três outras tentativas
de abertura falharam. As consultas não foram usadas para reabrir decisões do Owner. A
[página de contas do GKE](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/service-accounts)
exige o mínimo de `roles/container.defaultNodeServiceAccount`; a declaração
usa quatro papéis de logging/monitoring/metadata. Não foi comparada a expansão atual de todas
essas permissões, portanto não se afirma aqui que falte uma permissão específica nem se
certifica equivalência integral. Capacidade zonal no instante do apply, cotas do tenant do
Composer, propagação de IAM, defaults efetivos de workloads, limites/portas do NAT, saúde dos
pods e ausência real de resíduos continuam não medidos. Os planos de desmonte 20–22 ainda não
existem para os recursos criados. O rito §6.3 e o relógio §6.4 permanecem condições de execução.

## Rodada 2

### 1. Conclusão

**Mudanças necessárias.** Um achado novo, **RVPC-2-01 (alta, bloqueante)**: a correção de
RVPC-1-03 declara 0,5 GB de memória para o triggerer, abaixo do mínimo documentado para a imagem
Airflow 3 escolhida. O bloqueio é do degrau Composer, antes do seu `apply`; não impede os
degraus independentes já revisados. Os testes locais passam sem detectar esse valor inválido.

### 2. Escopo

Revisão **somente de regressões e itens pendentes**, em 09/11/2026, sobre
`b092841..886e942` (HEAD `886e94269b83f206941df833a07531a14303c4ae`): `6c593b0`,
`e590c64` e `886e942`. Foram confrontados os diffs, as respostas da coluna Situação, os textos
locais de planos/aplicação indicados pelo Owner e a medição literal fornecida na conversa.
As decisões do Owner e a estimativa aprovada não foram reabertas.

- **RVPC-1-01:** a correção documental atende ao achado. O passo 4a fica entre planejar e
  aplicar os releases, exige o texto real e preserva as contagens e a revisão das divergências
  dos planos seguintes. Cabe na terça da §6.1: a integração continua devida às 18:00 (P3), e
  a P4 das 20:00 não autoriza antecipar um apply sem revisão. A §6.3 mantém leitura integral
  e aprovação do Owner; a regra de falha da §6.6 mantém dependências suspensas e o relógio
  inalterado. **A revisão efetiva de `09_aplicacoes` continua pendente para terça**, antes do
  passo 5, com resolução de eventuais bloqueantes; esta rodada não a substitui.
- **RVPC-1-02:** correção da política confirmada pelas evidências fornecidas. O plano barato
  altera somente soft delete de 604800 para 0 nos buckets `beam` e `livro`, sem recriação;
  seu log registra `0 added, 2 changed, 0 destroyed`. A medição do autor informa 0 nos dois,
  e o plano regenerado declara 0 no bucket novo do Composer. A `retention_policy` do livro
  permanece separada, condicional e sem trava, com `ledger_retention_seconds` padrão 604800;
  o passo 7 de `desmonte.py` continua removendo-a com valor 0 antes do passo 8. Portanto,
  desligar soft delete não elimina a proteção D70 nem quebra a §6.5 passo 6. A guarda alcança
  os dois blocos de buckets atuais, incluindo o `for_each` de livro/Beam. Cópias anteriormente
  retidas permanecem uma limitação, descrita abaixo.
- **RVPC-1-03:** o bloco deixou de depender de defaults e o plano mostra os cinco componentes,
  suas quantidades e workers de 2 a 4. Porém, a solução introduziu a configuração inválida
  detalhada em RVPC-2-01; o item não pode ser considerado tecnicamente encerrado.
- **RVPC-1-04:** não encontrei erro factual que obrigue mudar a decisão de manter. As linhas
  do GKE e o hash do plano são os mesmos da rodada 1; a resposta conserva o comportamento
  transitório já descrito. Esta rodada não transforma a escolha em prova de apply, nem
  reabre a observação por preferência por outra configuração.

### 3. Evidência de cada achado novo

**RVPC-2-01 — triggerer com memória abaixo do mínimo do Airflow 3 (alta).**
O commit `e590c64` acrescenta `triggerer { cpu = 0.5, memory_gb = 0.5, count = 1 }`
em `terraform/composer.tf:172–175`. A imagem continua sendo
`composer-3-airflow-3.2.2-build.9` (`composer.tf:36`), conforme D73. O texto regenerado
`10_composer_revisao.txt:256` confirma a imagem e `:286–289` confirma o triggerer com 0,5 GB.

A [tabela oficial de limites do Composer 3](https://docs.cloud.google.com/composer/docs/composer-3/scale-environments#resource-limits)
estabelece memória mínima de **2 GB para triggerers no Airflow 3**. Assim, copiar 0,5 GB do
exemplo usado como referência não produz uma declaração válida para a imagem escolhida.
Os demais componentes declarados atendem aos pisos, passos e proporções de CPU/memória e aos
limites de armazenamento/quantidade da tabela; o problema identificado é o triggerer.

O plano com `29/0/0`, produzido com o provider travado em 8.10.0, evidencia que o bloco foi
aceito no planejamento; não comprova validade perante os limites do serviço. A criação do
Composer fica exposta à rejeição no apply. Não foi executada uma chamada à API para observar
essa rejeição. É erro no declarativo de um recurso cobrável e deve ser resolvido antes de
criá-lo.

A guarda `test_o_composer_declara_os_componentes_da_estimativa`
(`tests/test_composer_ambiente.py:152–157`) só exige os nomes dos componentes e os limites
2/4 dos workers: não confere CPU, memória, armazenamento nem as demais quantidades. Por isso,
passa com a memória inválida. Essa lacuna faz parte do mesmo achado, não de uma segunda causa.

**Ajuste proposto:** declarar pelo menos 2 GB para esse triggerer, preservando a imagem D73;
conferir os valores efetivos de cada componente na guarda, incluindo os limites aplicáveis
ao Airflow 3, e regerar/revisar o texto do plano. Corrigir a correspondência documental do
dimensionamento onde necessário, sem apresentar DCUs ou custo real como medidos nem reabrir
a aprovação da estimativa nesta revisão.

### 4. Verificações executadas

Leituras locais de Git, declarativo, testes, runbook, decisões e evidências textuais; nenhuma
operação de infraestrutura. O único comando de testes executado foi o autorizado:

```text
$ .venv/bin/python -m pytest -q tests/test_composer_ambiente.py tests/test_desmonte.py tests/test_origens_gcp.py tests/test_makefile.py
136 passed in 11.15s
```

Um script Python somente de leitura calculou hashes, extraiu os blocos de ações dos planos e
comparou os recursos comuns. Saída:

```text
08_gke_revisao.txt       Plan: 11 to add, 0 to change, 0 to destroy.
11_dataflow_revisao.txt  Plan: 15 to add, 0 to change, 0 to destroy.
10_composer_revisao.txt  Plan: 29 to add, 0 to change, 0 to destroy.
12_soft_delete.txt      Plan: 0 to add, 2 to change, 0 to destroy.
12_soft_delete_apply.txt Apply complete! Resources: 0 added, 2 changed, 0 destroyed.
Incrementos: 11 4 14
Blocos GKE que mudam no Dataflow: []
Blocos Dataflow que mudam no Composer: []
```

Os hashes de `08_gke_revisao.txt` e `11_dataflow_revisao.txt` conferem com a rodada 1.
Identificação dos textos novos ou regenerados, em `data/medicoes/etapa_13/planos/`:

| Arquivo | SHA-256 |
|---|---|
| `10_composer_revisao.txt` | `a95d486257420619b528feea37a0fcdd3c6316143eb96d988bdec2a2488efca6` |
| `12_soft_delete.txt` | `871553a3e89b26df322d8b86d044747cf5a45b3c84e67da1627a1d3676f4eeaf` |
| `12_soft_delete_apply.txt` | `9af815fe2f96ce59ca2363fd7fc17d1c64515a5f46b336e50ae6efe8d01e206e` |

Outro script somente de leitura conferiu que a guarda de soft delete alcança
`armazenamento.tf/this` e `composer.tf/composer`, ambos com política 0, e comparou a memória
dos cinco componentes com os mínimos documentados para Airflow 3: só o triggerer ficou abaixo.

### 5. Limites

O apply barato e a leitura das políticas efetivas são evidências do autor/Owner, não operações
repetidas pelo revisor. A medição recebida na conversa foi:

```text
mvp-ed1-gcp-livro  0
mvp-ed1-gcp-beam   0
```

Não foi fornecido inventário das cópias já soft-deleted, nem foi medido seu volume ou custo;
não certifico a expressão “centavos” da Situação. Segundo a
[documentação de soft delete](https://docs.cloud.google.com/storage/docs/soft-delete), a mudança
vale para exclusões posteriores à vigência da política; as anteriores conservam o prazo
original. Política 0 e listagem comum vazia não comprovam eliminação dessas cópias. A resposta
do autor reconhece essa permanência; ausência real de resíduos segue não provada, e o relógio
de faturamento permanece obrigatório.

Foram feitas quatro tentativas de leitura de páginas oficiais: três tiveram conteúdo
(limites do Composer 3, soft delete e documentação do GKE no provider v8.10.0); a página de
`composer_environment` nessa tag falhou com `Cache miss`. A aceitação do bloco pelo provider
foi avaliada pela evidência do plano, sem executar Terraform nem certificar todos os caminhos
do schema. Não houve consultas adicionais de rede.

Não foram lidos `.env`, estados Terraform ou bancos. Não foram executados comandos de
infraestrutura, serviços, novo plan/apply ou desmonte. As limitações operacionais da rodada 1
continuam válidas fora das correções aqui verificadas. Não há aceite formal do Owner nem
autorização de execução decorrente deste parecer.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVPC-1-01 | PLANO §6.2 e §6.7 passos 4–5; `aplicacoes_gke.tf:25` | **Alta — falta revisão do plano real das aplicações.** Exigir complemento de terça sobre `09_aplicacoes` antes do apply dos releases. Revisão de código antecipada não encerra esse pré-requisito. Os planos reais seguintes devem manter os releases sem alteração e os incrementos previstos. | bloqueante || **Aceito.** `PLANO_etapa_13.md` §6.7 ganhou o **passo 4a**: o texto real de `09_aplicacoes.txt` vai ao Codex antes do passo 5 (contagem `2/0/0`, valores, versões dos *charts*, sensíveis), e sem o parecer o passo 5 não roda; os planos reais da §6.8 e §6.9 seguem as contagens incrementais, e divergência dos `_revisao` volta ao Codex. |
| RVPC-1-02 | `composer.tf:97`; `armazenamento.tf:17`; plano Composer `:836` | **Média — soft delete não declarado pode reter e cobrar objetos após destroy.** `force_destroy` não desativa a política padrão de sete dias. Explicitar a política no Composer e tratar os buckets existentes e cópias já retidas antes de afirmar eliminação completa. | ajuste || **Corrigido e medido.** Reproduzido: o `12_soft_delete.txt` mostrou `retention_duration_seconds = 604800 -> 0` nos dois *buckets* existentes. `soft_delete_policy { retention_duration_seconds = 0 }` em `armazenamento.tf` e no *bucket* do Composer; guarda `test_todo_bucket_sai_sem_soft_delete` (que recusou o `composer.tf` sem a política: `google_storage_bucket.composer sem soft_delete_policy de 0 s`). Aplicado com o Owner às 12:50 (`0 added, 2 changed, 0 destroyed`); `gcloud storage buckets describe` deu `0` no `livro` e no `beam`. O `10_composer_revisao` regerado mostra `retention_duration_seconds = 0` no *bucket* novo. Objetos apagados antes (provas `GCP_TESTES` no livro) seguem a política antiga até 7 dias: centavos, e o faturamento sai na quinta às 12:00. |
| RVPC-1-03 | `composer.tf:153`; plano Composer `:273`; Capacidade §2.14 | **Média — `ENVIRONMENT_SIZE_SMALL` não declara o preset usado na estimativa.** Fixar workloads e limites correspondentes ou demonstrar equivalência dos defaults da API; o plano atual não prova essa correspondência. | ajuste || **Corrigido.** As páginas oficiais não publicam os valores por componente dos *presets* (`environment-scaling` e `scale-environments` só dão DAGs e tarefas por *preset*); a estimativa se apoia no exemplo oficial de `create-environments` (Registro §6). `workloads_config` declarado com esses valores (*scheduler* 0,5/2,5/2, *triggerer* 0,5/0,5, *DAG processor* 1/2/1, *web server* 1/2,5/2, *workers* 1/2/2 de 2 a 4); guarda `test_o_composer_declara_os_componentes_da_estimativa`. `10_composer_revisao` regerado: `29 a criar, 0 a alterar, 0 a destruir`, com o bloco no plano. |
| RVPC-1-04 | `gke.tf:56–57`; plano GKE `:200`, `:214`, `:471` | **Baixa — criação/remoção transitória de pool padrão evitável.** O argumento depreciado continua documentado como funcional. Na versão informada, omitir ambas as atribuições ou usar contagem zero sem o argumento; não deixar contagem um ao retirar só a flag. | observação || **Mantido, por recomendação do autor.** O argumento segue documentado como funcional no *provider* 8.10.0 (travado no `.terraform.lock.hcl`); o custo é um nó transitório por minutos na criação. Trocar agora levaria o `apply` de terça para um caminho não ensaiado (sem *pool* padrão, dependente da versão do canal). Nota no Registro §45. |
| RVPC-2-01 | `terraform/composer.tf:172–175`; `10_composer_revisao.txt:256`, `:286–289`; `tests/test_composer_ambiente.py:152–157` | **Alta — memória do triggerer inválida para Airflow 3.** A correção de RVPC-1-03 fixa 0,5 GB, mas o serviço exige no mínimo 2 GB nessa versão. O plano incorpora o valor e a guarda não o verifica. Corrigir a memória, proteger os valores por componente e regerar/revisar o plano antes do apply do Composer. | bloqueante || **Corrigido.** Confirmado na tabela oficial (scale-environments#resource-limits): *Triggerers* `1 (2 in Airflow 3)` GB de memória mínima, o mesmo piso de *schedulers*, *workers* e *DAG processors*. O exemplo oficial copiado traz 0,5 GB; o `composer.tf` passou a 2 GB, com a exceção comentada. A guarda nova `test_cada_componente_cabe_nos_limites_do_airflow_3` confere, por componente, vCPU, memória mínima do Airflow 3, memória por vCPU (1–8), armazenamento (≤100) e quantidades; com o 0,5 GB de volta ela falhou só em `[triggerer]`. `10_composer_revisao` regerado (13:02): `29 a criar, 0 a alterar, 0 a destruir`, `triggerer` com `memory_gb = 2`. Efeito no custo: +1,5 GB num componente; não calculado em DCU, fica para a fatura. |

