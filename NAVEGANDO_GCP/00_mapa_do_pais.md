# 00 — O mapa do país

> Leia este capítulo inteiro antes dos outros. Ele dá a gramática comum a toda a consola — o que
> muda de produto para produto é só o vocabulário.

---

## 1. O desenho inteiro, em uma tela

```
                         ┌──────────────── Terraform (cap. 11) provisiona tudo ────────────────┐
                         │                                                                      │
  Cloud SQL (cap. 03)    │   Airbyte no GKE (05)        BigQuery (04)            Dataplex (09)  │
  ┌────────────────┐     │   ┌──────────────┐     ┌──────────────────────┐   ┌───────────────┐  │
  │ oltp (40 tab.) │──batch──▶ retail sync ──────▶│ raw ─┐               │   │ catálogo      │  │
  │ legacy         │─────────▶ legacy sync ──────▶│ raw_legacy           │   │ linhagem      │  │
  └───────┬────────┘     │   └──────────────┘     │  ▼ dbt (Composer)    │   │ policy tags ──┼──▶ nega coluna
          │              │                        │ staging → trusted    │   └───────────────┘  │
          │ CDC          │                        │ → snapshots →        │                      │
          ▼              │                        │ analytics → consump. │◀── authorized views  │
  Datastream (07) ──▶ Pub/Sub (07) ──▶ Dataflow (08) ──▶ raw.inventory_movements_stream          │
                                          │                                                     │
                                          └──▶ tópico de alerta (estoque baixo)                 │
                                                                                                │
  Cloud Composer (06): a DAG `fluxo_batch` aciona o Airbyte, o dbt camada a camada, os testes    │
  de fronteira e o `dbt docs`. IAM + Secret Manager (02) por baixo de tudo; Logging/Monitoring   │
  (10) recebem de todos; Billing (01) cobra de todos.                                            │
```

É o mesmo desenho da [Arquitetura §5](../docs/arquitetura.md#5-mapa-de-paridade-local--gcp), peça
por peça. O que muda na nuvem não é o fluxo — é que **cada caixa é um produto com consola, IAM,
*logs*, cota e fatura próprios**, e é isso que você vai visitar.

---

## 2. A gramática de toda consola

Seis coisas existem em **todo** produto do GCP. Quem as reconhece anda em qualquer tela.

| Conceito | O que é | Onde aparece | Por que importa na viagem |
|---|---|---|---|
| **Projeto** | A unidade de tudo: recursos, IAM, fatura, cotas. Tem um *ID* (imutável) e um nome | Seletor no topo da consola, em toda página | Tudo o que o Terraform criar está num projeto só; a fatura é por projeto |
| **Região / zona** | Onde o recurso fisicamente está (`southamerica-east1` = São Paulo; `us-central1` = Iowa, o mais barato) | Campo de todo recurso; filtro de toda lista | Recurso em região errada não aparece na lista filtrada e **cobra do mesmo jeito** |
| **API ativada** | Cada produto precisa da própria API ligada no projeto (*APIs & Services → Enabled APIs*) | Erro "API not enabled" ao abrir a página do produto | O Terraform ativa; se um produto "não existe", a API está desligada |
| **IAM** | Quem (principal: usuário, grupo, conta de serviço) pode o quê (papel) em qual recurso | *IAM & Admin*, e uma aba "Permissions" em quase todo recurso | É o equivalente dos cinco papéis do ADR-0011 — cap. 02 |
| **Logs** | Todo produto escreve no Cloud Logging, com `resource.type` próprio | Botão "Logs" na página do recurso → abre o Logs Explorer já filtrado | É onde "onde registra" mora — cap. 10 |
| **Cota e fatura** | Limite por projeto por API; custo por recurso, por SKU, por hora ou por uso | *IAM & Admin → Quotas*; *Billing → Reports* | Cota estourada parece bug; fatura atrasa 24–48 h — cap. 01 |

Mais três hábitos que economizam a viagem:

- **Barra de busca** (tecla `/`): acha produto ("Composer"), recurso ("fluxo_batch") e até
  documentação. Quando o menu mudou de lugar, é o caminho.
- **`gcloud` ao lado da consola.** O Cloud Shell (ícone `>_` no topo) abre um terminal autenticado
  no projeto. Quase toda tela tem "equivalent command line" ou "REST" no rodapé de um formulário —
  copie: é a forma de reproduzir o que a tela fez, e reproduzível é o que vale como evidência.
- **Etiquetas (*labels*)**: par chave/valor em qualquer recurso. Se o Terraform etiquetar tudo com
  `projeto=mvp_ed1` e `etapa=13`, a fatura filtra por etiqueta e o *Asset Inventory* lista por
  etiqueta. Confira no dia se as etiquetas existem — é o que torna "custo real da janela" uma
  consulta, não uma soma à mão.

---

## 3. A tríade: onde aciona, onde registra, o que controla

É a pergunta que o guia faz em cada capítulo. Resumida aqui para o mapa inteiro:

| Produto | Onde aciona | Onde registra | O que controla |
|---|---|---|---|
| Cloud SQL | Não "roda": recebe conexão. Operações (backup, restart, import) na aba *Operations* | *Operations*, *Logs* (`postgres.log`), *Query Insights* | Flags do PostgreSQL, usuários, redes autorizadas, backups |
| BigQuery | Editor de consulta, `bq`, jobs do dbt via Composer, *scheduled queries* | *Job history* (pessoal e do projeto), `INFORMATION_SCHEMA.JOBS`, *audit logs* | IAM por *dataset*, *policy tags* por coluna, partição/expiração por tabela, cota de consulta |
| Airbyte (GKE) | UI do Airbyte → *Sync now*; ou a API que a DAG chama | UI → *Job history* de cada conexão; *logs* dos *pods* no GKE | Conexões, modo por *stream*, agenda, *reset* |
| Composer | UI do Airflow → *Trigger DAG*; `gcloud composer environments run`; agenda da DAG | UI: *Grid*, *task logs*; Logs Explorer `cloud_composer_environment`; aba *Monitoring* | Tamanho do ambiente, *overrides* do Airflow, variáveis, conexões, pacotes PyPI |
| Datastream | Criar/iniciar/pausar o *stream* | Página do *stream*: estado, objetos, *backlog*; *logs* | Perfis de conexão, objetos incluídos, *backfill* |
| Pub/Sub | Publicação (Datastream, ou você, em *Messages → Publish*) | Métricas do tópico/assinatura (*unacked*, *oldest unacked age*); *Messages → Pull* | Retenção, *ack deadline*, *dead letter*, *schema* |
| Dataflow | `python pipeline.py --runner DataflowRunner` ou *Templates*; *Cancel/Drain* na consola | Página do *job*: grafo, métricas por etapa, *logs* de *worker*, *autoscaling* | *Workers*, máquina, *streaming engine*, região |
| Dataplex | Não "roda": indexa. *Scans* de qualidade/perfil são acionados na aba própria | Busca do catálogo; aba *Lineage* da tabela | Taxonomias de *policy tags*, *aspects*/metadados, *scans* |
| Logging/Monitoring | Sempre ligado | Logs Explorer; painéis; *alerting* | Retenção por *bucket* de *logs*; políticas de alerta; *sinks* |
| Terraform | `terraform apply/destroy` no seu terminal | Estado (*bucket* GCS), `terraform show`, *Asset Inventory* | Tudo o que está no HCL — e **só** o que está no HCL |

---

## 4. Vocabulário de viagem — o que o nome significa quando aparece

- ***Dataset*** (BigQuery) = schema do PostgreSQL. As nove camadas viram nove *datasets*.
- ***Authorized view*** = view em *dataset* próprio (`consumption`) autorizada a ler *datasets* que
  o leitor não pode ler diretamente. É como a `analyst` lê `consumption` sem alcançar `trusted`.
- ***Policy tag*** = etiqueta numa coluna que exige um papel IAM (`Fine-Grained Reader`) para ler.
  É o equivalente na nuvem de `sensitivity: personal` — só que **nega de verdade**.
- ***Service account*** (conta de serviço) = identidade de um componente, não de uma pessoa. Cada
  papel do ADR-0011 vira uma.
- ***Workload Identity Federation*** = deixar uma identidade externa (o CI, o GitHub) agir como
  uma conta de serviço **sem chave** — credencial de curta duração emitida na hora (ADR-0025).
- ***Environment*** (Composer) = um Airflow inteiro: *scheduler*, *workers*, *web server*, banco
  de metadados, e um *bucket* onde as DAGs moram.
- ***Stream*** (Datastream) = a captura de mudanças de um banco para um destino; tem *backfill*
  (o *snapshot* inicial — o mesmo conceito do re-*snapshot* do Debezium) e o CDC contínuo.
- ***Topic* / *subscription*** (Pub/Sub) = tópico e grupo de consumo do Redpanda; a assinatura é
  quem guarda o que ainda não foi lido.
- ***Job*** (Dataflow) = uma execução do *pipeline* Beam; *streaming job* fica de pé e cobra por
  hora; *drain* encerra sem perder o que está em voo.
- ***Lineage*** (Dataplex/Data Lineage API) = o grafo de origem → destino por tabela (e por coluna
  quando publicado) — é o que o [Dicionário §3](../docs/dicionario_de_dados.md#3-linhagem) alimenta.
- ***Audit log*** = o registro de **quem** fez **o quê** em **qual** recurso, escrito pelo próprio
  GCP. É a prova mais forte de que você trabalhou ali: não é captura de tela, é registro do
  sistema.
