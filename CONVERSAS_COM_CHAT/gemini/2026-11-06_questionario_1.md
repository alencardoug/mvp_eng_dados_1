# Questionário factual sobre o GCP — rodada 1 (06/11/2026)

Você é consultado como verificador de fatos sobre o Google Cloud, **não** como revisor de opinião.
Responda em português brasileiro.

## Regras de resposta

1. Para cada pergunta, **pesquise na documentação oficial atual** (cloud.google.com, docs.cloud.google.com,
   registry.terraform.io/providers/hashicorp/google, docs.airbyte.com, beam.apache.org, docs.getdbt.com)
   usando busca na web. Não responda de memória.
2. Cada resposta traz: **(a)** a resposta direta, curta; **(b)** a URL exata da página oficial que a sustenta;
   **(c)** a data de última atualização da página, se ela mostrar; **(d)** um grau: `CONFIRMADO` (a página
   diz isso literalmente), `INFERIDO` (deduzido de páginas, explique de quais) ou `NÃO ENCONTRADO`.
3. Nunca invente preço, versão ou limite. Se não achou, diga `NÃO ENCONTRADO`.
4. Não escreva nem altere arquivo nenhum. Só pesquise e responda.
5. Formato: um título `## Qn` por pergunta, na ordem.

## Contexto (o que existe na fase local)

Pipeline sintético: PostgreSQL 16 (dois bancos de origem) → Airbyte (abctl, Helm) → PostgreSQL de armazém com
nove schemas → dbt-core 1.1x (dbt-postgres) → views. Orquestração Airflow **3.2** (DAG usa `airflow.sdk`,
`BashOperator` do `apache-airflow-providers-standard`, Python 3.11). Streaming: Debezium 3.x (Kafka Connect)
sobre a tabela `oltp.inventory_movements` → Redpanda → Apache Beam Python 2.76 (executor Prism), que lê o
envelope JSON do Debezium e grava numa tabela `raw`. Destino GCP planejado: Cloud SQL for PostgreSQL,
BigQuery, Airbyte no GKE, Cloud Composer, Datastream, Pub/Sub, Dataflow, Dataplex, *policy tags*, tudo por
Terraform, numa **janela de poucos dias** paga pelo **crédito de avaliação gratuita (Free Trial) de US$ 300**,
que termina em 7 dias.

## Perguntas

### Q1 — Datastream: destinos e formato
Quais são os destinos suportados hoje pelo Datastream? Ele publica eventos de mudança diretamente num tópico
Pub/Sub? Se não, qual é o padrão documentado pela Google para levar mudanças do Datastream até um pipeline
Dataflow de streaming (ex.: Cloud Storage + notificações Pub/Sub, template "Datastream to BigQuery")?
Qual é o formato dos eventos/arquivos (Avro, JSON) e quais campos de metadados trazem? É compatível com o
envelope do Debezium?

### Q2 — Datastream e Cloud SQL for PostgreSQL
Quais versões do Cloud SQL for PostgreSQL o Datastream suporta como origem? Que flags e privilégios exige
(`cloudsql.logical_decoding`, publication, replication slot, usuário com REPLICATION)? Quais opções de
conectividade (IP allowlist, proxy reverso, Private Connectivity / Private Service Connect) e qual é a mais
simples para um ambiente de poucos dias?

### Q3 — Debezium Server com Pub/Sub
O Debezium Server tem *sink* oficial para Google Cloud Pub/Sub? Em que versão está, e há imagem de contêiner
oficial? Ele preserva o mesmo envelope JSON do Debezium/Kafka Connect?

### Q4 — Cloud Composer e Airflow 3
O Cloud Composer 3 suporta Airflow 3 (3.0, 3.1, 3.2...)? Em GA ou Preview? Quais as versões de imagem
disponíveis hoje? O pacote `apache-airflow-providers-standard` e a API `airflow.sdk` estão disponíveis?
Ainda é possível **criar** ambientes Composer 2? Qual o tempo típico documentado de criação de um ambiente?

### Q5 — Cloud Composer: preço e Free Trial
Qual o modelo de preço do Composer 3 (DCU, armazenamento, etc.) e quanto custa por hora, aproximadamente, o
menor ambiente (*small*) em `us-central1` e em `southamerica-east1`? É possível criar ambiente Composer numa
conta de **Free Trial** (sem upgrade para conta paga)? Há restrição documentada?

### Q6 — Free Trial: restrições e cotas
Quais as restrições documentadas do Free Trial de US$ 300 (ex.: limite de vCPUs simultâneas, GPUs, Windows,
serviços bloqueados, cotas)? O que acontece com os recursos quando o crédito ou o prazo de 90 dias acaba
(são parados? apagados? em quanto tempo?) se a conta **não** foi convertida em paga? E se foi convertida?

### Q7 — Airbyte no GKE
Qual é o método oficial atual para implantar o Airbyte (OSS / Self-Managed Community) no Kubernetes: Helm
chart v1 ou v2, versão atual do chart, requisitos mínimos de CPU/memória? Funciona em **GKE Autopilot**, ou a
documentação recomenda GKE Standard? Há guia oficial para GKE?

### Q8 — Dataflow com Beam Python
Qual a versão do Apache Beam Python SDK suportada hoje pelo Dataflow, e qual a política de suporte
(versões descontinuadas)? Para um *job* de streaming mínimo lendo `ReadFromPubSub` e gravando no BigQuery
(Storage Write API ou streaming inserts), qual o tipo de máquina padrão e o custo-hora aproximado de um
*worker* com Streaming Engine em `us-central1`?

### Q9 — Policy tags e o fim do Data Catalog
O Data Catalog foi descontinuado em favor do Dataplex Universal Catalog? Qual a data de desligamento? As
*policy tags* (taxonomias, `datacatalog.googleapis.com` / Policy Tag Manager API) continuam funcionando, e qual
API e recursos Terraform (`google_data_catalog_taxonomy`, `google_data_catalog_policy_tag`, ou outros) se usam
hoje? Quais papéis IAM são necessários para (a) criar taxonomias e vincular tags a colunas e (b) ler coluna
protegida (`roles/datacatalog.categoryFineGrainedReader`)? O controle de acesso por coluna exige alguma
edição/edição paga do BigQuery?

### Q10 — Linhagem no Dataplex
Como publicar linhagem **customizada** (por coluna) na Data Lineage API — eventos OpenLineage via
`ProcessOpenLineageRunEvent`? A linhagem por coluna é suportada para eventos customizados? O dbt no BigQuery
gera linhagem automática no Dataplex?

### Q11 — dbt no BigQuery
Qual a versão atual do adaptador `dbt-bigquery` compatível com dbt-core 1.10/1.11? Suporta `contract: enforced`
em views e tabelas, `grants` (`+grants`), `partition_by`/`cluster_by` e materialização incremental com
`merge`? Que métodos de autenticação suporta (OAuth/ADC, impersonação de conta de serviço, keyfile)?

### Q12 — Workload Identity Federation com GitHub Actions
Qual a configuração atual recomendada para GitHub Actions autenticar no GCP por Workload Identity Federation
(ação `google-github-actions/auth`, versão)? A *attribute condition* passou a ser obrigatória para provedores
GitHub? Qual o recurso Terraform correspondente?

### Q13 — BigQuery: authorized views e custo
*Authorized views* entre datasets continuam sendo o mecanismo recomendado (ou *authorized datasets*)? Qual o
nível gratuito mensal do BigQuery hoje (consulta e armazenamento) e o preço on-demand por TiB?

### Q14 — Região
Para Cloud SQL, Composer 3, Datastream, Dataflow, BigQuery e GKE, há diferença de preço relevante entre
`us-central1` e `southamerica-east1`? Todos esses serviços estão disponíveis em `southamerica-east1`?

### Q15 — Terraform provider google
Qual a versão atual do provider `hashicorp/google` (e `google-beta`)? Composer 3 e Datastream são
provisionáveis no provider estável ou só no beta? Há armadilhas documentadas de `terraform destroy` em
Composer (bucket que sobra), Cloud SQL (`deletion_protection`) e Datastream?

### Q16 — `CREATE OR REPLACE TABLE` e *policy tags*
Quando uma tabela do BigQuery é substituída por `CREATE OR REPLACE TABLE ... AS SELECT` (como o dbt faz
na materialização `table`), as *policy tags* das colunas se mantêm ou se perdem? O `dbt-bigquery` tem a
propriedade de coluna `policy_tags`, e ela é aplicada a cada *build*?

### Q17 — Destino BigQuery do Airbyte com Workload Identity
O conector de destino BigQuery do Airbyte, rodando no GKE, autentica pela identidade do *pod*
(Workload Identity / ADC) sem `credentials_json`? No modo *Batched Standard Inserts*, há limite de volume
ou recomendação contra uso fora de teste?
