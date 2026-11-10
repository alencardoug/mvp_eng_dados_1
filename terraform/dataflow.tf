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

# **O *watermark* pelo atributo (Registro §49):** com `timestamp_attribute`, o Dataflow cria no
# tópico uma assinatura própria de acompanhamento (`<assinatura>__df_internal…`) e a apaga quando o
# *job* sai. Sem permissão, ele repete "Creating watermark tracking pubsub subscription … failed
# with error: User not authorized" e não lê nada. Criar assinatura é permissão de projeto; um papel
# só com o que a assinatura de acompanhamento pede, em vez do `pubsub.editor`, que apagaria tópicos.
# O `attachSubscription` vem do `subscriber` **no tópico** de eventos. Os dois saem com o degrau.
#
# **O `.get` no projeto (RVT-1-05, decisão do Owner em 10/11/2026):** a página do Dataflow com Pub/Sub
# pede "ao menos" `create`, `consume` e `delete` no projeto da assinatura de acompanhamento; o `.get`
# está a mais e **não foi demonstrado necessário** — a consulta que faltava era a da `beam`, que o
# `viewer` dela resolve (`armazenamento.tf`). Fica porque foi com ele que o *job* de 10/11 leu, e
# tirá-lo só se provaria no lançamento da quarta, dentro da janela. Menor privilégio não provado.
resource "google_project_iam_custom_role" "rastreio_watermark" {
  count = local.dataflow ? 1 : 0

  role_id     = "mvpRastreioWatermark"
  title       = "mvp-ed1 — assinatura de acompanhamento do Dataflow"
  description = "Criar, ler, consumir e apagar a assinatura de watermark que o Dataflow cria no tópico (Registro §49)."
  permissions = [
    "pubsub.subscriptions.create",
    "pubsub.subscriptions.get",
    "pubsub.subscriptions.consume",
    "pubsub.subscriptions.delete",
  ]
}

resource "google_project_iam_member" "streamer_rastreio_watermark" {
  count = local.dataflow ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.rastreio_watermark[0].id
  member  = google_service_account.role["streamer"].member
}

resource "google_pubsub_topic_iam_member" "streamer_anexa_rastreio" {
  count = local.dataflow ? 1 : 0

  topic  = google_pubsub_topic.this["eventos"].name
  role   = "roles/pubsub.subscriber"
  member = google_service_account.role["streamer"].member
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
