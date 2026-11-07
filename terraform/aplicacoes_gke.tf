# Os *releases* do Helm no GKE (enable_gke_apps; terça, 10/11, depois do `apply` do *cluster*).
#
# **Interruptor próprio** porque o provider do Helm se conecta ao *cluster* para planejar: com o
# *cluster* nascendo no mesmo `apply`, o endereço dele ainda não existe na hora do plano. A ordem
# é o rito duas vezes — `enable_gke`, depois `enable_gke_apps` —, e o desmonte é a ordem inversa
# (§6.5 passos 3–5): os *releases* saem primeiro, levando PVCs e discos.

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
