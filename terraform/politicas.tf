# G4 — *policy tags* (ADR-0025, D71, D79). Degrau barato: taxonomia e IAM não cobram.
#
# **O que é de quem** (D79, decidida pelo Owner em 07/11/2026):
#
# * aqui, o Terraform: a taxonomia, as *tags* e **quem lê** coluna marcada — IAM é do Terraform,
#   como todo o resto;
# * o dbt **aplica** as *tags* nas tabelas que materializa, derivadas de `meta.sensitivity` pela
#   macro `bigquery__alter_column_comment` (D71) — substituir uma tabela apaga as *tags* dela;
# * o fluxo do ADR-0025 (`.github/workflows/policy-tags.yml`) **converge** as tabelas que o dbt
#   não materializa (`raw`, `raw_legacy`, o destino do caminho quente, `governance`), com uma
#   conta que só vincula *tag* a coluna, pela federação de identidade — sem chave.
#
# Só `confidential` e `personal` viram *tag* com controle ligado (D79): em `public` e `internal`
# não há o que negar, e cada *tag* ligada exige concessão a todo papel que lê a coluna.

locals {
  niveis_marcados = var.enable_cheap ? toset(["confidential", "personal"]) : toset([])

  # Quem lê coluna marcada (D79): os cinco papéis leem no seu trabalho, e o dado é sintético —
  # a exposição é livre (ADR-0049). A negação se prova com `mvp-prova-sem-leitura`, que tem o
  # mesmo acesso de dataset do `analyst` e nenhuma destas concessões.
  leitores_marcados = var.enable_cheap ? merge(
    { for papel in keys(local.roles) : papel => google_service_account.role[papel].member },
    var.owner_member != "" ? { owner = var.owner_member } : {},
  ) : {}

  leitura_por_tag = { for par in setproduct(tolist(local.niveis_marcados), keys(local.leitores_marcados)) :
  "${par[0]}/${par[1]}" => { nivel = par[0], leitor = par[1] } }

  # O repositório que o fluxo do ADR-0025 representa, e só ele, só da `main`.
  repositorio_do_fluxo = "alencardoug/mvp_eng_dados_1"
  # Quem vincula *tag* a coluna, e onde: o fluxo nas tabelas que o dbt não materializa; o
  # `transformer` — o dbt no Composer — nas que ele materializa (D71).
  vinculadores = var.enable_cheap ? {
    politicas   = { membro = google_service_account.politicas[0].member, datasets = ["raw", "raw_legacy", "governance"] }
    transformer = { membro = google_service_account.role["transformer"].member, datasets = ["staging", "trusted", "analytics", "snapshots", "quarantine", "consumption"] }
  } : {}
  vinculo_por_dataset = { for par in flatten([for quem, v in local.vinculadores : [for d in v.datasets : { quem = quem, dataset = d }]]) :
  "${par.quem}/${par.dataset}" => par }
}

resource "google_data_catalog_taxonomy" "classificacao" {
  count = var.enable_cheap ? 1 : 0

  display_name           = "mvp-ed1-classificacao"
  description            = "Os níveis de sensibilidade do ADR-0011 com controle de acesso por coluna (D79)."
  region                 = var.region
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

  depends_on = [google_project_service.this]
}

resource "google_data_catalog_policy_tag" "nivel" {
  for_each = local.niveis_marcados

  taxonomy     = google_data_catalog_taxonomy.classificacao[0].id
  display_name = each.value
  description  = "Coluna classificada como `${each.value}` (ADR-0011); só lê quem tem a concessão desta tag."
}

resource "google_data_catalog_policy_tag_iam_member" "leitor" {
  for_each = local.leitura_por_tag

  policy_tag = google_data_catalog_policy_tag.nivel[each.value.nivel].name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = local.leitores_marcados[each.value.leitor]
}

# ── A prova da negação ───────────────────────────────────────────────────────
resource "google_service_account" "prova_sem_leitura" {
  count = var.enable_cheap ? 1 : 0

  account_id   = "mvp-prova-sem-leitura"
  display_name = "mvp-ed1 — prova sem leitura de tag"
  description  = "O acesso de dataset do analyst sem a concessão das policy tags: é quem prova a negação (G4)."
}

resource "google_bigquery_dataset_access" "prova_sem_leitura" {
  count = var.enable_cheap ? 1 : 0

  dataset_id    = google_bigquery_dataset.layer["consumption"].dataset_id
  role          = "roles/bigquery.dataViewer"
  user_by_email = google_service_account.prova_sem_leitura[0].email
}

resource "google_project_iam_member" "prova_sem_leitura" {
  count = var.enable_cheap ? 1 : 0

  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = google_service_account.prova_sem_leitura[0].member
}

resource "google_service_account_iam_member" "owner_personifica_prova" {
  count = var.enable_cheap && var.owner_member != "" ? 1 : 0

  service_account_id = google_service_account.prova_sem_leitura[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.owner_member
}

# ── O fluxo do ADR-0025: federação de identidade do GitHub, sem chave ────────
resource "google_iam_workload_identity_pool" "github" {
  count = var.enable_cheap ? 1 : 0

  workload_identity_pool_id = "mvp-ed1-github"
  display_name              = "GitHub — fluxo das policy tags"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count = var.enable_cheap ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  # A condição é a fronteira: só este repositório, só a `main` (ADR-0025, "porta estreita").
  attribute_condition = "assertion.repository == '${local.repositorio_do_fluxo}' && assertion.ref == 'refs/heads/main'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "politicas" {
  count = var.enable_cheap ? 1 : 0

  account_id   = "mvp-politicas"
  display_name = "mvp-ed1 — fluxo das policy tags"
  description  = "Vincula policy tags a colunas das tabelas que o dbt não materializa (ADR-0025). Não lê dado."
}

resource "google_service_account_iam_member" "github_age_como_politicas" {
  count = var.enable_cheap ? 1 : 0

  service_account_id = google_service_account.politicas[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${local.repositorio_do_fluxo}"
}

# Vincular *tag* a coluna é trocar o *schema* da tabela: ler a tabela, atualizá-la e o
# `setCategory` — e ler a taxonomia (`datacatalog.taxonomies.get`), que vai num papel à parte,
# no projeto. O `setCategory` está no Data Owner, não no Data Editor que o `transformer` tem.
# Nada de `getData`: o papel não lê linha nenhuma.
resource "google_project_iam_custom_role" "vincular_tags" {
  count = var.enable_cheap ? 1 : 0

  role_id     = "mvpVincularPolicyTags"
  title       = "mvp-ed1 — vincular policy tags"
  description = "Ler metadado de tabela e trocar a policy tag das colunas; sem acesso a dado (ADR-0025)."
  permissions = [
    "bigquery.datasets.get",
    "bigquery.tables.get",
    "bigquery.tables.list",
    "bigquery.tables.update",
    "bigquery.tables.setCategory",
  ]
}

resource "google_bigquery_dataset_iam_member" "vincular_tags" {
  for_each = local.vinculo_por_dataset

  dataset_id = google_bigquery_dataset.layer[each.value.dataset].dataset_id
  role       = google_project_iam_custom_role.vincular_tags[0].id
  member     = local.vinculadores[each.value.quem].membro
}

resource "google_project_iam_custom_role" "ler_taxonomia" {
  count = var.enable_cheap ? 1 : 0

  role_id     = "mvpLerTaxonomia"
  title       = "mvp-ed1 — ler a taxonomia"
  description = "Ler taxonomia e policy tags, o que vincular uma tag a coluna exige; não dá leitura de dado."
  permissions = ["datacatalog.taxonomies.get", "datacatalog.taxonomies.list"]
}

resource "google_project_iam_member" "ler_taxonomia" {
  for_each = local.vinculadores

  project = var.project_id
  role    = google_project_iam_custom_role.ler_taxonomia[0].id
  member  = each.value.membro
}

# Os nomes das *tags* para quem precisa delas sem ler a taxonomia: o dbt (`MVP_POLICY_TAGS`) e o fluxo.
output "policy_tags" {
  description = "Nível → nome completo da policy tag."
  value       = { for nivel, tag in google_data_catalog_policy_tag.nivel : nivel => tag.name }
}

output "fluxo_politicas" {
  description = "O que o workflow do GitHub recebe como variáveis do repositório (não são segredos)."
  value = var.enable_cheap ? {
    workload_identity_provider = google_iam_workload_identity_pool_provider.github[0].name
    service_account            = google_service_account.politicas[0].email
  } : null
}
