# Degrau do Cloud SQL (enable_cloud_sql; segunda, 09/11): as duas origens num só PostgreSQL
# gerenciado, a versão maior da fase local (16), com IP privado e decodificação lógica para
# o Debezium Server (ADR-0051). Dimensionamento e preço: Capacidade §2.14.
#
# **Desmonte** (§6.5 passo 7): `deletion_protection = false` no estado, sem *backup* retido e
# sem PITR — nada sobrevive à instância. As senhas são geradas aqui, guardadas no Secret
# Manager e, por isso, também no estado local (`terraform.tfstate`, fora do Git).

variable "cloud_sql_origens" {
  description = "As duas origens: o banco e o usuário de cada uma, os mesmos nomes do `.env` local. No terraform.tfvars."
  type = map(object({
    database = string
    user     = string
  }))
  default = {}
}

resource "google_sql_database_instance" "origens" {
  count = var.enable_cloud_sql ? 1 : 0

  name             = "mvp-ed1-origens"
  database_version = "POSTGRES_16"
  region           = var.region

  # O atributo do Terraform (o `destroy` não recusa) e o da API (a instância não recusa).
  deletion_protection = false

  settings {
    edition           = "ENTERPRISE"
    tier              = "db-custom-2-7680"
    availability_type = "ZONAL"

    location_preference {
      zone = var.zone
    }

    disk_type       = "PD_SSD"
    disk_size       = 20
    disk_autoresize = false

    deletion_protection_enabled = false

    backup_configuration {
      enabled                        = false
      point_in_time_recovery_enabled = false
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.this[0].id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    # O `pgoutput` do conector (`streaming/connectors/inventory_movements.yml`) precisa do
    # nível lógico do WAL; no Cloud SQL ele se liga por esta *flag*.
    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }
  }

  depends_on = [google_service_networking_connection.this]
}

resource "google_sql_database" "origem" {
  for_each = var.enable_cloud_sql ? var.cloud_sql_origens : {}

  name     = each.value.database
  instance = google_sql_database_instance.origens[0].name
}

resource "random_password" "origem" {
  for_each = var.enable_cloud_sql ? var.cloud_sql_origens : {}

  length  = 32
  special = false
}

resource "google_sql_user" "origem" {
  for_each = var.enable_cloud_sql ? var.cloud_sql_origens : {}

  name     = each.value.user
  instance = google_sql_database_instance.origens[0].name
  password = random_password.origem[each.key].result

  # Usuário dono de objetos não sai por `DROP ROLE`; quem o leva é a instância, no mesmo
  # `destroy`. Sem isto o desmonte para no primeiro usuário.
  deletion_policy = "ABANDON"
}

# ── Secret Manager (RV13-1-09) ───────────────────────────────────────────────
# Uma senha por origem; o Composer as lê em execução (backend de segredos) e o Airbyte as
# recebe no `apply` do provider dele. Quem pode ler é concedido quando o leitor existe (G2.4,
# GKE) — aqui nasce só o segredo.

resource "google_secret_manager_secret" "origem" {
  for_each = var.enable_cloud_sql ? var.cloud_sql_origens : {}

  secret_id = "mvp-ed1-${each.key}-db-password"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.this]
}

resource "google_secret_manager_secret_version" "origem" {
  for_each = var.enable_cloud_sql ? var.cloud_sql_origens : {}

  secret      = google_secret_manager_secret.origem[each.key].id
  secret_data = random_password.origem[each.key].result
}
