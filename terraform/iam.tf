# Degrau barato: uma conta de serviço por papel do ADR-0011 (mapa de paridade,
# "Controle de acesso": "uma conta de serviço ou grupo por papel"). A lista é a de
# `mvp_ed1.governance.PAPEIS`, e o nome é o que a macro `bigquery__apply_grants`
# do dbt monta: mvp-<papel>@<projeto>.iam.gserviceaccount.com.
#
# Nenhuma chave é criada para nenhuma delas (ADR-0025): quem roda como uma conta o
# faz por Workload Identity (GKE), pela conta do ambiente (Composer, Dataflow) ou
# por personificação de curta duração.

locals {
  roles = {
    ingestor    = "Airbyte: escreve raw e raw_legacy."
    transformer = "dbt: escreve staging, trusted, analytics, consumption, quarantine e snapshots."
    streamer    = "Caminho quente: escreve o destino em raw."
    analyst     = "Lê consumption, e só consumption."
    auditor     = "Lê quarantine e governance; não escreve."
  }
}

resource "google_service_account" "role" {
  for_each = var.enable_cheap ? local.roles : {}

  account_id   = "mvp-${each.key}"
  display_name = "mvp-ed1 — ${each.key}"
  description  = each.value

  depends_on = [google_project_service.this]
}

# Prova de acesso por papel (G1, "o analista lê consumption e é negado em analytics"):
# o Owner roda a consulta **como** a conta do papel, por personificação de curta duração
# (`gcloud … --impersonate-service-account`), sem chave nenhuma. O papel de Owner do
# projeto não inclui criar token de outra conta; este vínculo dá isso, só nas duas contas
# cujas negações o plano prova, e some com o projeto.
resource "google_service_account_iam_member" "owner_personifica" {
  for_each = var.enable_cheap && var.owner_member != "" ? toset(["analyst", "auditor"]) : toset([])

  service_account_id = google_service_account.role[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.owner_member
}
