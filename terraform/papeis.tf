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
  description = "Concessões por tabela que o dbt declara: a tabela nasce fora do Terraform, e o IAM dela vai no degrau que a usa (`dataflow.tf`). Derivado; não editar à mão."
  type        = any
  default     = []
}

resource "google_bigquery_dataset_access" "papel" {
  for_each = var.enable_cheap ? { for a in var.acesso_por_dataset : "${a.dataset}/${a.role}/${a.papel}" => a } : {}

  dataset_id = google_bigquery_dataset.layer[each.value.dataset].dataset_id
  # Papel predefinido vai como está; o próprio (`mvpAutorizarViews`) vira o id do papel do projeto.
  role          = startswith(each.value.role, "roles/") ? each.value.role : google_project_iam_custom_role.autorizar_views[0].id
  user_by_email = google_service_account.role[each.value.papel].email
}

# Recriar uma *authorized view* pede `bigquery.datasets.update` em cada dataset que ela lê
# (`mvp_ed1.gcp.acesso.AUTORIZAR`). Só isso: nada de ler, escrever ou apagar tabela. Vai por
# `google_bigquery_dataset_access`, como o resto, para não reescrever a lista de acesso do dataset.
resource "google_project_iam_custom_role" "autorizar_views" {
  count = var.enable_cheap ? 1 : 0

  role_id     = "mvpAutorizarViews"
  title       = "mvp-ed1 — autorizar views"
  description = "Gravar a autorização de uma view na lista de acesso do dataset que ela lê (G1.5)."
  permissions = [
    "bigquery.datasets.get",
    "bigquery.datasets.update",
  ]
}

resource "google_project_iam_member" "job_user" {
  for_each = var.enable_cheap ? local.roles : {}

  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = google_service_account.role[each.key].member
}
