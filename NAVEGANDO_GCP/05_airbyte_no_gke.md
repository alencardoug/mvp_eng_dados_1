# 05 — Airbyte no GKE: a carga

> **Quando fazer.** **Ter 10**, depois do passo 6 do §6.7. Para ver um *pod* de sincronização, acompanhe os passos 10 a 13 da §6.8.

**Em uma frase.** O mesmo Airbyte do `abctl` local, agora como *pods* num cluster Kubernetes
gerenciado (GKE Standard zonal, D73), criado pelo Terraform ([ADR-0024](../docs/adr/0024-airbyte-e-airflow-no-gcp.md)).
As conexões `retail` e `legacy` de `airbyte/streams.yml` são as mesmas; a UI é a mesma; o que muda
é onde os *pods* moram e quem os cobra.

**Quanto custa e por quê.** Taxa do cluster mais **dois nós `e2-standard-4`**, que cobram por
hora de nó, com ou sem *pod* rodando ([Capacidade §2.14](../docs/capacidade_e_recuperacao.md#214-a-estimativa-da-janela-da-etapa-13--07112026)). Sobe pouco depois do
Cloud SQL e **antes** do Composer: a DAG chama o Airbyte, não o contrário.

**Onde fica.** Duas consolas: **GKE** (☰ → *Kubernetes Engine* → *Clusters*, *Workloads*,
*Services & Ingress*) e a **UI do Airbyte**, que não é da Google e não tem endereço público. No
Cloud Shell: `gcloud container clusters get-credentials mvp-ed1 --zone us-central1-a --project mvp-ed1-gcp`;
a porta sai de `kubectl -n airbyte get service airbyte-airbyte-server-svc`; e
`kubectl -n airbyte port-forward service/airbyte-airbyte-server-svc 8080:<porta>`, com *Web Preview*
na 8080 [não exercitado: a UI por esse caminho só se confirma com o GKE de pé].

**O que é deste projeto aqui.** O *namespace* `airbyte`, com os *deployments* do *chart* 2.3.0 e o
banco de metadados; as duas conexões (origem Cloud SQL → destino
BigQuery) com o modo por *stream* do [ADR-0015](../docs/adr/0015-sincronizacao-e-exclusoes.md)
(`full_refresh`, `append`, `dedup_history`); o teto de memória do
[ADR-0041](../docs/adr/0041-teto-de-memoria-nos-servicos-do-airbyte.md) como `resources.limits` dos
*pods*. O destino BigQuery escreve `_airbyte_*` como o Postgres local — a reconciliação
`oltp → raw` por identidade continua valendo.

## Roteiro guiado

1. **GKE → Clusters.** O cluster `mvp-ed1`: modo (Standard), zona, versão, estado. *Por quê:*
   Standard cobra por nó, com ou sem carga — é o que torna o custo previsível, e o ocioso caro.
2. **Workloads.** Filtre pelo *namespace* do Airbyte. *O que olhar:* cada *deployment* com
   *pods* `Running`, reinícios (**restarts**), CPU/memória pedidas vs. usadas. *Por quê:*
   reinícios = OOM = o ADR-0041 na prática; aqui está o número.
3. **Um *pod* de sincronização.** Durante um *sync*, aparece um *pod* efêmero por *job*
   (`source-…`, `destination-…`, ou `replication-…`). Clique → *Logs* (abre o Logs Explorer com
   `resource.type="k8s_container"`). *Por quê:* é o `docker logs` da fase local; o registro fica no
   Cloud Logging mesmo depois de o *pod* morrer.
4. **Services & Ingress.** O `airbyte-airbyte-server-svc` e o balanceador **interno** que o Composer usa.
5. **UI do Airbyte → Connections.** As duas conexões. Abra `retail`: *Status* (última execução,
   próxima), **Streams** (tabela a tabela: modo, cursor, chave primária — compare com
   `airbyte/streams.yml`), *Settings* (agenda: **manual**, porque quem dispara é a DAG),
   *Job history*. *Por quê:* a declaração e a tela têm de dizer o mesmo — é a revisão integral do
   declarativo, na nuvem.
6. **Job history → um *job*.** *Logs* completos, linhas por *stream*, bytes, duração, tentativas.
   *Por quê:* é o `sync_id` que a reconciliação por lote lê em `_airbyte_meta` — o mesmo número
   que você vê em `raw` no BigQuery: `select distinct json_value(_airbyte_meta, '$.sync_id') from raw.orders`.
7. **Não use *Sync now*:** o `make gcp-jobs-auditoria` (§6.8, passo 20) reprova *job* fora do
   livro. Acompanhe as sincronizações do roteiro (§6.8, passos 10 a 13) no *Job history* e nos
   *Workloads* do GKE ao mesmo tempo: o *pod* nasce, roda, some. *Por quê:* onde aciona (UI/API) e onde executa (GKE) são lugares diferentes;
   saber os dois é o que "operar" quer dizer.
8. **Settings → Sources/Destinations.** O destino BigQuery: *dataset* de destino, método de
   carga (*Standard Inserts*, D72) e **nenhum JSON de credencial**: os *pods* de *job* rodam com a
   conta `airbyte-admin`, que age como `mvp-ingestor` por *Workload Identity*. *Por quê:* é onde a
   regra 1 mais aperta, e foi resolvida sem chave.

## Onde aciona, onde registra, o que controla

- **Aciona:** UI (*Sync now*), API (`POST /v1/jobs` — é o que o `AirbyteTriggerSyncOperator` da
  DAG faz), agenda da conexão (desligada aqui).
- **Registra:** *Job history* da conexão (Airbyte); *logs* dos *pods* (Cloud Logging, mesmo após
  o *pod* sumir); `_airbyte_meta.sync_id` nas próprias linhas de `raw`.
- **Controla:** modo por *stream*, cursor, chave; *reset* de conexão (o `RESET=1` local);
  `resources.limits` dos *pods* (memória); número de *workers* paralelos.

## Armadilhas

- *Reset* no Airbyte v2 **não limpa lotes antigos das tabelas `append`** — observado localmente
  (dossiê da Etapa 11). Vale confirmar no destino BigQuery: se sobrarem, a reconciliação por
  conjunto (RV11-02) acusa "sobra de regeneração".
- Um `port-forward` esquecido na porta 18001 faz o `make gcp-airbyte-config` recusar. Use outra
  porta e feche ao sair.
- *Pods* efêmeros somem, os *logs* não — mas o Logs Explorer filtra por `labels.k8s-pod/...`;
  anote o nome do *pod* na hora.
- O cluster cobra mesmo com Airbyte ocioso. É o segundo item a derrubar (cap. 11), logo depois do
  Composer.

## Evidência a levar

- Captura de *Workloads* com os *pods* do Airbyte `Running` e a coluna *restarts*.
- Captura de *Streams* da conexão `retail` (modo por tabela) lado a lado com `airbyte/streams.yml`.
- Um *job* do *Job history* com linhas por *stream* e duração; o *log* do *pod* correspondente no
  Logs Explorer (a consulta usada).
- A consulta dos `sync_id` em `raw` no BigQuery.

## O que você saberá dizer depois

- "O Airbyte rodou em GKE Standard com limite de memória por *pod*; li reinícios em *Workloads*."
- "A conexão é disparada pela DAG via API, não por agenda; acompanhei o *pod* de replicação nascer
  e morrer."
- "O `sync_id` de cada lote está em `_airbyte_meta` no BigQuery e é o vínculo com o *job* da UI."
