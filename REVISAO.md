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

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

