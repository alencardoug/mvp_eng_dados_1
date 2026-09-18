# 05 — Airbyte no GKE: a carga

**Em uma frase.** O mesmo Airbyte do `abctl` local, agora como *pods* num cluster Kubernetes
gerenciado (GKE Autopilot), criado pelo Terraform ([ADR-0024](../docs/adr/0024-airbyte-e-airflow-no-gcp.md)).
As conexões `retail` e `legacy` de `airbyte/streams.yml` são as mesmas; a UI é a mesma; o que muda
é onde os *pods* moram e quem os cobra.

**Quanto custa e por quê.** Taxa do cluster (~US$ 73/mês, com crédito para um zonal) mais os
*pods* por vCPU/GB-hora — casa de US$ 80–150/mês ligado
([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)). Sobe pouco depois do
Cloud SQL e **antes** do Composer: a DAG chama o Airbyte, não o contrário.

**Onde fica.** Duas consolas: **GKE** (☰ → *Kubernetes Engine* → *Clusters*, *Workloads*,
*Services & Ingress*) e a **UI do Airbyte**, que não é da Google — chega-se por um *Service* do tipo
*LoadBalancer*/*Ingress* (IP na aba *Services & Ingress*) ou por
`kubectl port-forward svc/airbyte-webapp 8000:80` no Cloud Shell.

**O que é deste projeto aqui.** O *namespace* do Airbyte com os *deployments* `server`, `webapp`,
`worker`, `temporal`, o banco de metadados; as duas conexões (origem Cloud SQL → destino
BigQuery) com o modo por *stream* do [ADR-0015](../docs/adr/0015-sincronizacao-e-exclusoes.md)
(`full_refresh`, `append`, `dedup_history`); o teto de memória do
[ADR-0041](../docs/adr/0041-teto-de-memoria-nos-servicos-do-airbyte.md) como `resources.limits` dos
*pods*. O destino BigQuery escreve `_airbyte_*` como o Postgres local — a reconciliação
`oltp → raw` por identidade continua valendo.

## Roteiro guiado

1. **GKE → Clusters.** O cluster: modo (Autopilot), região, versão, estado. *Por quê:* Autopilot
   cobra por *pod* pedido, não por nó — é o que torna o custo previsível.
2. **Workloads.** Filtre pelo *namespace* do Airbyte. *O que olhar:* cada *deployment* com
   *pods* `Running`, reinícios (**restarts**), CPU/memória pedidas vs. usadas. *Por quê:*
   reinícios = OOM = o ADR-0041 na prática; aqui está o número.
3. **Um *pod* de sincronização.** Durante um *sync*, aparece um *pod* efêmero por *job*
   (`source-…`, `destination-…`, ou `replication-…`). Clique → *Logs* (abre o Logs Explorer com
   `resource.type="k8s_container"`). *Por quê:* é o `docker logs` da fase local; o registro fica no
   Cloud Logging mesmo depois de o *pod* morrer.
4. **Services & Ingress.** O endereço da UI. Abra.
5. **UI do Airbyte → Connections.** As duas conexões. Abra `retail`: *Status* (última execução,
   próxima), **Streams** (tabela a tabela: modo, cursor, chave primária — compare com
   `airbyte/streams.yml`), *Settings* (agenda: **manual**, porque quem dispara é a DAG),
   *Job history*. *Por quê:* a declaração e a tela têm de dizer o mesmo — é a revisão integral do
   declarativo, na nuvem.
6. **Job history → um *job*.** *Logs* completos, linhas por *stream*, bytes, duração, tentativas.
   *Por quê:* é o `sync_id` que a reconciliação por lote lê em `_airbyte_meta` — o mesmo número
   que você vê em `raw` no BigQuery: `select distinct json_value(_airbyte_meta, '$.sync_id') from raw.orders`.
7. **Sync now** numa conexão pequena (ou espere a DAG do cap. 06 disparar — melhor: é a evidência
   de orquestração). Acompanhe no *Job history* e nos *Workloads* do GKE ao mesmo tempo: o *pod*
   nasce, roda, some. *Por quê:* onde aciona (UI/API) e onde executa (GKE) são lugares diferentes;
   saber os dois é o que "operar" quer dizer.
8. **Settings → Sources/Destinations.** O destino BigQuery: *dataset* de destino, método de
   carga (*GCS staging* vs *standard inserts*), a conta de serviço usada (deve ser `ingestor` —
   sem chave? Airbyte pede JSON de credencial no destino BigQuery: é o ponto onde a regra 1 mais
   aperta; veja como o Terraform resolveu — *Workload Identity* no *pod* é o caminho sem chave).

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
- *LoadBalancer* público expõe a UI do Airbyte à internet com a senha padrão. Confira que há
  autenticação ou que o acesso é por `port-forward`.
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

- "O Airbyte rodou em GKE Autopilot com limite de memória por *pod*; li reinícios em *Workloads*."
- "A conexão é disparada pela DAG via API, não por agenda; acompanhei o *pod* de replicação nascer
  e morrer."
- "O `sync_id` de cada lote está em `_airbyte_meta` no BigQuery e é o vínculo com o *job* da UI."
