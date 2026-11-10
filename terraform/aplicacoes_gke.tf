# Os *releases* do Helm no GKE (enable_gke_apps; terça, 10/11, depois do `apply` do *cluster*).
#
# **Interruptor próprio** porque o provider do Helm se conecta ao *cluster* para planejar: com o
# *cluster* nascendo no mesmo `apply`, o endereço dele ainda não existe na hora do plano. A ordem
# é o rito duas vezes — `enable_gke`, depois `enable_gke_apps` —, e o desmonte é a ordem inversa
# (§6.5 passos 3–5): os *releases* saem primeiro. O PVC do Debezium Server é do *release* e sai com
# ele; os do banco interno e do MinIO do Airbyte nascem de `volumeClaimTemplates` e ficam — quem os
# leva é o `make gcp-desmonte-kubernetes`, antes do `destroy` do *cluster*.

locals {
  aplicacoes = var.enable_gke && var.enable_gke_apps && var.enable_cloud_sql
}

data "google_client_config" "atual" {}

provider "helm" {
  kubernetes = {
    host                   = var.enable_gke ? "https://${google_container_cluster.this[0].endpoint}" : ""
    token                  = data.google_client_config.atual.access_token
    cluster_ca_certificate = var.enable_gke ? base64decode(google_container_cluster.this[0].master_auth[0].cluster_ca_certificate) : ""
  }
}

# ── Debezium Server (ADR-0051, D78) ──────────────────────────────────────────
resource "helm_release" "debezium" {
  count = local.aplicacoes ? 1 : 0

  name             = "debezium-server"
  chart            = "${path.module}/charts/debezium-server"
  namespace        = local.identidades_do_cluster.streamer.namespace
  create_namespace = true

  values = [yamlencode({
    contaDePapel = google_service_account.role["streamer"].email
    # Gerado de streaming/connectors/inventory_movements.yml; o teste confere que está em dia.
    propriedades = file("${path.module}/../streaming/debezium_server/application.properties")
    projeto      = var.project_id
    origem = {
      host    = google_sql_database_instance.origens[0].private_ip_address
      porta   = "5432"
      usuario = var.cloud_sql_origens["source"].user
      banco   = var.cloud_sql_origens["source"].database
    }
  })]

  set_sensitive = [{
    name  = "origem.senha"
    value = random_password.origem["source"].result
  }]

  depends_on = [google_container_node_pool.this, google_service_account_iam_member.identidade_do_cluster]
}

# ── Airbyte (chart 2.3.0, o mesmo do `AIRBYTE_CHART_VERSION` local; D72, D73) ──
resource "helm_release" "airbyte" {
  count = local.aplicacoes ? 1 : 0

  name             = "airbyte"
  repository       = "https://airbytehq.github.io/charts"
  chart            = "airbyte"
  version          = "2.3.0"
  namespace        = local.identidades_do_cluster.ingestor.namespace
  create_namespace = true
  # A instalação inteira leva minutos: o bootloader migra o banco antes de os serviços subirem.
  timeout = 1200

  values = [
    file("${path.module}/../airbyte/values.yaml"),
    file("${path.module}/helm/airbyte_gke.yaml"),
    # A conta dos pods — e dos pods de job, pelo `JOB_KUBE_SERVICEACCOUNT` — age como `mvp-ingestor`:
    # é assim que o destino BigQuery escreve sem `credentials_json` (D72).
    yamlencode({
      serviceAccount = {
        annotations = { "iam.gke.io/gcp-service-account" = google_service_account.role["ingestor"].email }
      }
    }),
  ]

  depends_on = [google_container_node_pool.this, google_service_account_iam_member.identidade_do_cluster]
}

# ── O destino BigQuery do Airbyte (D72; Registro §49) ────────────────────────────────────
# O conector (`destination-bigquery` 3.1.0) faz, no *check* e em cada sincronização, um `POST` de
# criação para cada *dataset* que usa (`BigQueryUtils.getOrCreateDataset`) — o da camada e o
# `airbyte_internal`, onde guarda as tabelas brutas da tipagem e deduplicação. O `POST` exige
# `bigquery.datasets.create` no projeto **mesmo quando o *dataset* já existe** (a resposta seria
# 409); sem ele, "User does not have bigquery.datasets.create permission", e a sincronização falha
# antes de ler a origem. O papel próprio tem só essa permissão. O `airbyte_internal` nasce aqui, e
# não pelo conector: fica no desmonte e não nasce fora do Terraform com cópia bruta da origem; só o
# `ingestor` o acessa.
resource "google_project_iam_custom_role" "criar_dataset" {
  count = local.aplicacoes ? 1 : 0

  role_id     = "mvpCriarDatasetAirbyte"
  title       = "mvp-ed1 — o POST de dataset do destino BigQuery do Airbyte"
  description = "Só bigquery.datasets.create: o conector pede a criação de todo dataset que usa (Registro §49)."
  permissions = ["bigquery.datasets.create"]
}

resource "google_project_iam_member" "ingestor_criar_dataset" {
  count = local.aplicacoes ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.criar_dataset[0].id
  member  = google_service_account.role["ingestor"].member
}

resource "google_bigquery_dataset" "airbyte_internal" {
  count = local.aplicacoes ? 1 : 0

  dataset_id                 = "airbyte_internal"
  location                   = var.region
  description                = "Tabelas brutas do destino BigQuery do Airbyte (tipagem e deduplicação); só o ingestor."
  delete_contents_on_destroy = true
}

resource "google_bigquery_dataset_access" "airbyte_internal" {
  count = local.aplicacoes ? 1 : 0

  dataset_id    = google_bigquery_dataset.airbyte_internal[0].dataset_id
  role          = "roles/bigquery.dataEditor"
  user_by_email = google_service_account.role["ingestor"].email
}
