# Degrau barato: o que cada conta de papel pode fazer (G3; ADR-0011, Governança §7).
#
# Três camadas de concessão, cada uma com um dono:
#
# 1. **Objeto** — o `+grants` do dbt, aplicado por ele a cada tabela e view que materializa
#    (`dbt/macros/grants_no_bigquery.sql`). Não passa por aqui.
# 2. **Dataset** — quem escreve cada camada (`meta.writers`) e quem lê as tabelas das fontes
#    (`grants` da fonte), que no PostgreSQL o `on-run-end` concede e no BigQuery é IAM. A lista
#    é **derivada** da declaração do dbt para `acesso.auto.tfvars.json`
#    (`python -m mvp_ed1.gcp.acesso`); este arquivo só a aplica.
# 3. **Projeto** — rodar *jobs*. Não tem equivalente no PostgreSQL, onde a consulta é da
#    sessão; no BigQuery toda consulta, carga e DML é um *job* do projeto, e sem
#    `bigquery.jobUser` nenhuma conta de papel consulta nada, nem o que pode ler.
#
# `google_bigquery_dataset_access`, e não `google_bigquery_dataset_iam_member`: o segundo
# reescreve a lista de acesso do dataset e **apaga as *authorized views*** que o dbt grava
# nela (`grant_access_to`, G1.5) — o aviso está na página do recurso no registro do provider.

variable "acesso_por_dataset" {
  description = "Derivado do dbt por `python -m mvp_ed1.gcp.acesso` (acesso.auto.tfvars.json). Não editar à mão."
  type = list(object({
    dataset = string
    role    = string
    papel   = string
  }))
  default = []
}

variable "pendentes_por_tabela" {
  description = "Concessões por tabela que o dbt declara e o Terraform ainda não aplica (a tabela nasce depois). Só registro."
  type        = any
  default     = []
}

resource "google_bigquery_dataset_access" "papel" {
  for_each = var.enable_cheap ? { for a in var.acesso_por_dataset : "${a.dataset}/${a.role}/${a.papel}" => a } : {}

  dataset_id    = google_bigquery_dataset.layer[each.value.dataset].dataset_id
  role          = each.value.role
  user_by_email = google_service_account.role[each.value.papel].email
}

resource "google_project_iam_member" "job_user" {
  for_each = var.enable_cheap ? local.roles : {}

  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = google_service_account.role[each.key].member
}
