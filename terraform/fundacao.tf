# Fundação (G0): APIs e orçamento. Não cobra nada por si.

locals {
  services = [
    "bigquery.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerystorage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudasset.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
}

resource "google_project_service" "this" {
  for_each = toset(local.services)

  service = each.value

  # Desligar API no `destroy` falha quando outro recurso ainda a usa e não
  # economiza nada: quem as apaga é a exclusão do projeto (§6.4, camada 3).
  disable_on_destroy = false
}

data "google_project" "this" {}

# O orçamento é recurso da CONTA de faturamento: a exclusão do projeto não o
# remove (RV13-1-02). Ele sai no `destroy` desta raiz, §6.5 passo 10.
resource "google_billing_budget" "etapa_13" {
  billing_account = var.billing_account_id
  display_name    = "mvp-ed1 Etapa 13"

  # Explícito, para não depender do padrão: ABANDON ou PREVENT deixariam o
  # orçamento na conta depois do `destroy`.
  deletion_policy = "DELETE"

  budget_filter {
    projects               = ["projects/${data.google_project.this.number}"]
    credit_types_treatment = "EXCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount_units)
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget_thresholds
    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  depends_on = [google_project_service.this]
}
