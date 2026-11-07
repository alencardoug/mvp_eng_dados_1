# Rede (G3): uma VPC, uma sub-rede na região e o acesso a serviços privados — o Cloud SQL
# só com IP privado (PLANO_etapa_13 G3). Nada disso cobra por existir; nasce com o degrau
# barato para o Cloud SQL da segunda e o GKE da terça acharem o caminho pronto.
#
# Faixas privadas que não colidem entre si nem com a rede do Docker local
# (`mvp_ed1_net`, 172.x): nós em 10.10/20, *pods* em 10.20/16, *services* em 10.30/20 (as
# secundárias do GKE nativo de VPC) e os serviços gerenciados em 10.40/20.
#
# Ordem do desmonte (§6.5 passo 8): a rede sai por último, depois do Cloud SQL e do GKE; a
# conexão de serviços privados só sai quando nenhum produtor (o Cloud SQL) a usa.

resource "google_compute_network" "this" {
  count = var.enable_cheap ? 1 : 0

  name                    = "mvp-ed1"
  auto_create_subnetworks = false

  depends_on = [google_project_service.this]
}

resource "google_compute_subnetwork" "this" {
  count = var.enable_cheap ? 1 : 0

  name          = "mvp-ed1-${var.region}"
  network       = google_compute_network.this[0].id
  region        = var.region
  ip_cidr_range = "10.10.0.0/20"

  # Os nós do GKE e os *workers* do Dataflow sem IP público chegam às APIs do Google.
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_global_address" "servicos_privados" {
  count = var.enable_cheap ? 1 : 0

  name          = "mvp-ed1-servicos-privados"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.40.0.0"
  prefix_length = 20
  network       = google_compute_network.this[0].id
}

resource "google_service_networking_connection" "this" {
  count = var.enable_cheap ? 1 : 0

  network                 = google_compute_network.this[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.servicos_privados[0].name]
}
