# Degrau caro (enable_composer; quarta, 11/11, 07:00–22:00): o Cloud Composer 3 que roda a
# `fluxo_batch` (G2.4; D73; ADR-0024). Preço e dimensionamento: Registro §6 (preset *small*).
#
# **Identidade (D81):** a conta do ambiente, `mvp-composer`, tem só o que o ambiente precisa para
# existir (`composer.worker`), o *bucket* dele e a leitura dos segredos da DAG. Não escreve camada
# nenhuma: as tarefas Python personificam o `ingestor` (`MVP_IMPERSONATE_SA`,
# `mvp_ed1.gcp.credenciais`) e o dbt personifica o `transformer` (`MVP_DBT_IMPERSONATE_SA`, no
# `profiles.yml`) — os cinco papéis do ADR-0011 seguem como estão.
#
# **Segredos (RV13-1-09):** nenhum nas variáveis de ambiente, que qualquer leitor da configuração
# do ambiente vê. O *backend* do Secret Manager lê as *Variables* do Airflow com o prefixo
# `mvp-ed1`: a *Variable* `legacy-db-password` é o segredo `mvp-ed1-legacy-db-password`, que o
# `cloud_sql.tf` já cria; as três do Airbyte nascem aqui vazias, e o `make gcp-composer-segredos`
# as preenche do GKE (o bootloader gera as credenciais; o IP do *load balancer* interno só existe
# depois do Service). A DAG as copia para o ambiente da tarefa (`mvp_ed1.orquestracao.segredos`).
#
# **Rede:** o ambiente se liga à VPC por um *network attachment* que o Composer cria na sub-rede
# (`node_config.network`/`subnetwork`; reserva até 4 IPs), e por ele alcança o IP privado do Cloud
# SQL e o *load balancer* interno do Airbyte. A faixa interna padrão do Composer (100.64.128.0/20)
# não colide com nenhuma da `rede.tf`. **Não provado:** que o tráfego que entra pelo *attachment*
# chega ao Cloud SQL, que está do outro lado do *peering* dos serviços privados — a documentação
# do Composer 3 diz "recursos na sua VPC" e não fala de *peering*. O *smoke test* da janela abre a
# conexão TCP às duas pontas antes de qualquer tarefa (`make gcp-composer-smoke`).
#
# **IP público** no ambiente: os pacotes do PyPI (`airflow/requirements-composer.txt`) se instalam
# sem Cloud NAT na VPC; o tráfego para endereços privados da VPC vai pelo *attachment*.
#
# **Desmonte** (§6.5 passos 1–2): `enable_composer = false` tira o ambiente; o *bucket* dele é
# declarado aqui com `force_destroy` e sai junto, em vez de sobrar como o que o Composer cria
# sozinho.

locals {
  composer = var.enable_composer && var.enable_cloud_sql && var.enable_cheap

  # A imagem provada no G2.4 (`make gcp-composer-prova`, a mesma do `COMPOSER_IMAGEM` do Makefile).
  composer_imagem = "composer-3-airflow-3.2.2-build.9"

  # O que o ambiente instala por cima da imagem, lido do mesmo arquivo da prova local: só as linhas
  # `nome==versão`. O teste confere que o mapa é o de `python -m mvp_ed1.gcp.composer pacotes`.
  composer_pacotes = {
    for linha in split("\n", file("${path.module}/../airflow/requirements-composer.txt")) :
    lower(split("==", trimspace(linha))[0]) => "==${split("==", trimspace(linha))[1]}"
    if can(regex("^[A-Za-z0-9_.-]+==[^ ]+$", trimspace(linha)))
  }

  # Prefixo das *Variables* no Secret Manager; o nome de cada segredo é montado, não escrito
  # literal (a revisão de segredos lê `secret = "…"` como credencial — mesmo cuidado do cloud_sql.tf).
  composer_prefixo = "mvp-ed1"
  composer_segredos_airbyte = {
    for nome in ["airbyte-client-id", "airbyte-client-secret", "airbyte-url"] :
    nome => "${local.composer_prefixo}-${nome}"
  }
}

variable "ledger_prefix" {
  description = "Prefixo da raiz do livro no bucket `<projeto>-livro`: `LEGACY_LEDGER_DIR` é `gs://<bucket>/<prefixo>` (a saída `livro_raiz`)."
  type        = string
  default     = "legado"
}

# A raiz do livro na nuvem, uma vez só: a do Composer e a da época inicial, que o Owner abre desta
# máquina (`make gcp-livro-epoca`).
locals {
  livro_raiz = var.enable_cheap ? "gs://${google_storage_bucket.this["livro"].name}/${var.ledger_prefix}" : null
}

output "livro_raiz" {
  description = "O `LEGACY_LEDGER_DIR` da nuvem: o livro retido no Cloud Storage."
  value       = local.livro_raiz
}

resource "google_service_account" "composer" {
  count = local.composer ? 1 : 0

  account_id   = "mvp-composer"
  display_name = "mvp-ed1 — ambiente do Composer"
  description  = "Conta do ambiente: composer.worker e personificação do ingestor e do transformer (D81)."
}

resource "google_project_iam_member" "composer_worker" {
  count = local.composer ? 1 : 0

  project = var.project_id
  role    = "roles/composer.worker"
  member  = google_service_account.composer[0].member
}

# A personificação: o token de curta duração das duas contas de papel que a DAG usa.
resource "google_service_account_iam_member" "composer_personifica" {
  for_each = local.composer ? toset(["ingestor", "transformer"]) : toset([])

  service_account_id = google_service_account.role[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_service_account.composer[0].member
}

resource "google_storage_bucket" "composer" {
  count = local.composer ? 1 : 0

  name     = "${var.project_id}-composer"
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true

  # Sem *soft delete*, como os do degrau barato (`armazenamento.tf`, RVPC-1-02).
  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

resource "google_storage_bucket_iam_member" "composer" {
  count = local.composer ? 1 : 0

  bucket = google_storage_bucket.composer[0].name
  role   = "roles/storage.objectAdmin"
  member = google_service_account.composer[0].member
}

resource "google_secret_manager_secret" "composer_airbyte" {
  for_each = local.composer ? local.composer_segredos_airbyte : {}

  secret_id = each.value

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Lê só os segredos da DAG — a senha do legado e os três do Airbyte —, um a um, e não o projeto.
resource "google_secret_manager_secret_iam_member" "composer" {
  for_each = local.composer ? merge(
    { for nome, s in google_secret_manager_secret.composer_airbyte : nome => s.secret_id },
    { "legacy-db-password" = google_secret_manager_secret.origem["legacy"].secret_id },
  ) : {}

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.composer[0].member
}

resource "google_composer_environment" "this" {
  count = local.composer ? 1 : 0

  name   = "mvp-ed1"
  region = var.region

  storage_config {
    bucket = google_storage_bucket.composer[0].name
  }

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    # Os componentes declarados, não deixados ao padrão da API (RVPC-1-03): o tamanho do ambiente
    # é só a infraestrutura gerenciada, e os recursos de cada componente são outra coisa
    # (https://docs.cloud.google.com/composer/docs/composer-3/environment-scaling). Os valores são
    # escolha deste projeto, a partir dos exemplos de criação (create-environments), que divergem
    # entre si, conferidos contra a tabela de limites do Airflow 3
    # (scale-environments#resource-limits, RVPC-2-01): `scheduler.cpu` é o do exemplo `gcloud`
    # (o do Terraform, 2,5, passa do teto de 2), `dag_processor.cpu` é o do exemplo Terraform, e o
    # *triggerer* tem 2 GB porque o dos exemplos, 0,5 GB, fica abaixo do mínimo. O exemplo de preços
    # não dá a configuração por componente dos seus 12–15 DCUs, nem a página publica a conversão:
    # os DCUs da Capacidade §2.14 são hipótese para estes valores, a medir na quarta (Registro §46).
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 2.5
        storage_gb = 2
        count      = 1
      }
      triggerer {
        cpu       = 0.5
        memory_gb = 2
        count     = 1
      }
      dag_processor {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 1
        memory_gb  = 2.5
        storage_gb = 2
      }
      worker {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 2
        min_count  = 2
        max_count  = 4
      }
    }

    node_config {
      service_account = google_service_account.composer[0].email
      network         = google_compute_network.this[0].id
      subnetwork      = google_compute_subnetwork.this[0].id
    }

    software_config {
      image_version = local.composer_imagem
      pypi_packages = local.composer_pacotes

      airflow_config_overrides = {
        "secrets-backend" = "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"
        "secrets-backend_kwargs" = jsonencode({
          project_id       = var.project_id
          variables_prefix = local.composer_prefixo
          sep              = "-"
        })
      }

      # Só o que não é segredo. Os nomes reservados do Composer (GCP_PROJECT, SQL_*…) ficam de fora.
      env_variables = {
        GCP_PROJECT_ID  = var.project_id
        GCP_BQ_LOCATION = var.region
        # O layout do G2.4 (`mvp_ed1.gcp.composer.LAYOUT`): o dbt e o glossário em `data/`.
        MVP_PROJECT_DIR  = "/home/airflow/gcs/data"
        DBT_PROFILES_DIR = "/home/airflow/gcs/data/dbt"
        DBT_TARGET       = "gcp"
        MVP_POLICY_TAGS  = jsonencode({ for nivel, tag in google_data_catalog_policy_tag.nivel : nivel => tag.name })
        # D81: quem escreve é a conta do papel.
        MVP_IMPERSONATE_SA     = google_service_account.role["ingestor"].email
        MVP_DBT_IMPERSONATE_SA = google_service_account.role["transformer"].email
        # A captura do legado com o certificado no BigQuery e o livro no Cloud Storage (G2.1).
        LEGACY_WAREHOUSE  = "bigquery"
        LEGACY_LEDGER_DIR = local.livro_raiz
        LEGACY_DB_HOST    = google_sql_database_instance.origens[0].private_ip_address
        LEGACY_DB_PORT    = "5432"
        LEGACY_DB_NAME    = var.cloud_sql_origens["legacy"].database
        LEGACY_DB_USER    = var.cloud_sql_origens["legacy"].user
      }
    }
  }

  # ~25 min para nascer (create-environments); a folga é para não desistir no meio.
  timeouts {
    create = "90m"
    update = "60m"
    delete = "60m"
  }

  depends_on = [
    google_project_iam_member.composer_worker,
    google_storage_bucket_iam_member.composer,
    google_secret_manager_secret_iam_member.composer,
    google_service_account_iam_member.composer_personifica,
  ]
}

output "composer" {
  description = "O ambiente: o bucket (onde o `make gcp-composer-publicar` põe o layout) e a interface do Airflow."
  value = local.composer ? {
    bucket      = google_storage_bucket.composer[0].name
    airflow_uri = google_composer_environment.this[0].config[0].airflow_uri
    nome        = google_composer_environment.this[0].name
  } : null
}
