# Degrau médio (enable_gke; terça, 10/11): o GKE que roda o Airbyte e o Debezium Server
# (ADR-0051, D72, D73). Dimensionamento e preço: Capacidade §2.14.
#
# **Standard zonal** (`var.zone`), um *pool* de **2 nós no total** `e2-standard-4` (D73). Nós
# privados, com saída à internet pelo Cloud NAT — as imagens vêm do quay.io e do Docker Hub —, e
# o plano de controle com endpoint público, autenticado pelo IAM (é por ele que o Helm e o
# `kubectl` desta máquina chegam).
#
# **Desmonte** (§6.5 passos 3–5): `deletion_protection = false`; antes do `destroy` deste degrau,
# os *releases* do Helm saem (`enable_gke_apps = false`, plano 21) e o `make gcp-desmonte-kubernetes`
# apaga os *namespaces* — o `helm uninstall` não leva os PVCs dos StatefulSets do Airbyte —, porque o
# GKE **retém** disco persistente ao apagar o *cluster*.

locals {
  # As contas do Kubernetes que agem como contas de papel (Workload Identity): o Airbyte roda os
  # *pods* de *job* com a `airbyte-admin` (`JOB_KUBE_SERVICEACCOUNT` do chart 2.3.0), e é ela que
  # o destino BigQuery usa sem chave (D72); o Debezium Server publica no Pub/Sub pela dele.
  identidades_do_cluster = {
    ingestor = { namespace = "airbyte", conta = "airbyte-admin" }
    streamer = { namespace = "debezium", conta = "debezium-server" }
  }
}

# A conta dos nós: só o que o *kubelet* precisa para mandar log e métrica. A padrão do Compute
# Engine tem papel de Editor no projeto, e nenhum *pod* precisa disso.
resource "google_service_account" "nos" {
  count = var.enable_gke ? 1 : 0

  account_id   = "mvp-nos-gke"
  display_name = "mvp-ed1 — nós do GKE"
}

resource "google_project_iam_member" "nos" {
  for_each = var.enable_gke ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = google_service_account.nos[0].member
}

resource "google_container_cluster" "this" {
  count = var.enable_gke ? 1 : 0

  name     = "mvp-ed1"
  location = var.zone

  network    = google_compute_network.this[0].id
  subnetwork = google_compute_subnetwork.this[0].id

  # O *pool* padrão sai na criação; o declarado abaixo é o único.
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.50.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.this]
}

resource "google_container_node_pool" "this" {
  count = var.enable_gke ? 1 : 0

  name       = "mvp-ed1"
  cluster    = google_container_cluster.this[0].id
  location   = var.zone
  node_count = 2

  node_config {
    machine_type    = "e2-standard-4"
    disk_type       = "pd-balanced"
    disk_size_gb    = 50
    service_account = google_service_account.nos[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # O servidor de metadados do GKE: é o que entrega aos *pods* a identidade da conta de papel.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Saída dos nós privados à internet: só para buscar imagens.
resource "google_compute_router" "this" {
  count = var.enable_gke ? 1 : 0

  name    = "mvp-ed1"
  region  = var.region
  network = google_compute_network.this[0].id
}

resource "google_compute_router_nat" "this" {
  count = var.enable_gke ? 1 : 0

  name                               = "mvp-ed1"
  router                             = google_compute_router.this[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# A conta do Kubernetes age como a conta de papel. O *pool* de identidades só existe depois do
# *cluster*: a ligação espera por ele.
resource "google_service_account_iam_member" "identidade_do_cluster" {
  for_each = var.enable_gke ? local.identidades_do_cluster : {}

  service_account_id = google_service_account.role[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.namespace}/${each.value.conta}]"

  depends_on = [google_container_cluster.this]
}

# O acesso do `kubectl` desta máquina (A30), sem kubeconfig gravado: o `make` monta a chamada com o
# endpoint, a CA e um token da ADC do Owner — o mesmo que o provider do Helm usa.
output "gke_endpoint" {
  description = "O endpoint público do plano de controle, autenticado pelo IAM."
  value       = var.enable_gke ? google_container_cluster.this[0].endpoint : ""
}

output "gke_ca" {
  description = "A CA do plano de controle, em base64."
  value       = var.enable_gke ? google_container_cluster.this[0].master_auth[0].cluster_ca_certificate : ""
}
