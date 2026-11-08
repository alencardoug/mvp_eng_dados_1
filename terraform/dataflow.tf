# O degrau do Dataflow (enable_dataflow; ensaio de ~1 h na terça, D83, e a parte cara da quarta):
# o que o *job* do caminho quente precisa para rodar como a conta do papel. O *job* não é recurso
# do Terraform — é lançado e drenado pelo `make gcp-dataflow-lancar`/`gcp-dataflow-parar` —, porque
# um *job* de *streaming* não se "aplica": sobe com o grafo do código e sai drenado (§6.5 passo 1).
#
# **Identidade (D82):** os *workers* rodam como `mvp-streamer`, que ganha `dataflow.worker` só
# enquanto este degrau está ligado. Quem lança é o Owner, cujo papel já permite agir como a conta.
#
# **A tabela do destino:** o `streamer` escreve `raw.inventory_movements_stream` e nada mais
# (`mvp_ed1.governance.PAPEIS`). No PostgreSQL é um `grant` na tabela; aqui, IAM **da tabela**, lido
# da mesma declaração do dbt (`pendentes_por_tabela`, derivado por `python -m mvp_ed1.gcp.acesso`):
# `insert` → `dataEditor`, `select` → `dataViewer`. A tabela precisa existir antes do `apply`; o
# lançador a cria com a ADC do Owner (`make gcp-dataflow-tabela`), pelo DDL do código.
#
# **Rede:** sem IP público nos *workers* (`--no_use_public_ips`), na sub-rede do projeto, que tem o
# Private Google Access. Com o Streaming Engine, nenhuma regra de *firewall* entre *workers* é
# precisa ([routes-firewall](https://docs.cloud.google.com/dataflow/docs/guides/routes-firewall)).

locals {
  dataflow = var.enable_dataflow && var.enable_cheap

  # O privilégio do PostgreSQL e o papel do BigQuery que faz a mesma coisa na tabela.
  papel_por_privilegio = {
    insert = "roles/bigquery.dataEditor"
    select = "roles/bigquery.dataViewer"
  }
  concessao_por_tabela = {
    for c in flatten([
      for t in var.pendentes_por_tabela : [
        for privilegio, papeis in t.grants : [
          for papel in papeis : { tabela = t.tabela, privilegio = privilegio, papel = papel }
        ]
      ]
    ]) : "${c.tabela}/${c.privilegio}/${c.papel}" => c
  }
}

resource "google_project_iam_member" "streamer_dataflow_worker" {
  count = local.dataflow ? 1 : 0

  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = google_service_account.role["streamer"].member
}

resource "google_bigquery_table_iam_member" "papel" {
  for_each = local.dataflow ? local.concessao_por_tabela : {}

  project    = var.project_id
  dataset_id = split(".", each.value.tabela)[0]
  table_id   = split(".", each.value.tabela)[1]
  role       = local.papel_por_privilegio[each.value.privilegio]
  member     = google_service_account.role[each.value.papel].member

  depends_on = [google_bigquery_dataset.layer]
}

output "dataflow" {
  description = "O que o lançador do *job* lê (`mvp_ed1.streaming.dataflow`): conta dos *workers*, sub-rede e o bucket de staging e temporários."
  value = var.enable_cheap ? {
    conta   = google_service_account.role["streamer"].email
    subrede = google_compute_subnetwork.this[0].self_link
    bucket  = google_storage_bucket.this["beam"].name
    regiao  = var.region
    projeto = var.project_id
  } : null
}
