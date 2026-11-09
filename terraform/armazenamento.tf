# Degrau barato: os buckets e os tópicos (G3). Centavos; nascem no sábado (PLANO_etapa_13 §0).
#
# Todo bucket com `force_destroy`: o desmonte (§6.5 passo 6) apaga com o conteúdo. Nenhum
# público: acesso uniforme e prevenção de acesso público forçada. E sem *soft delete*
# (`retention_duration_seconds = 0`, RVPC-1-02): o padrão do Cloud Storage guarda por 7 dias o
# objeto apagado, cobrando armazenamento, e o `force_destroy` esvazia o bucket sem desligar isso
# (https://docs.cloud.google.com/storage/docs/soft-delete). A retenção da D70 é outra política.

locals {
  buckets = {
    # O livro retido do legado (ADR-0050): cada registro é um objeto criado por escrita
    # condicionada (`ifGenerationMatch=0`), o `os.link` que falha da fase local.
    livro = "Livro retido das tentativas de captura do legado (ADR-0050)."
    # O Dataflow pede um lugar para o pacote (`staging_location`) e para os temporários
    # (`temp_location`); um bucket, dois prefixos.
    beam = "Staging e temporários do pipeline Beam no Dataflow (staging/, temp/)."
  }
}

resource "google_storage_bucket" "this" {
  for_each = var.enable_cheap ? local.buckets : {}

  name     = "${var.project_id}-${each.key}"
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true

  soft_delete_policy {
    retention_duration_seconds = 0
  }

  # D70: retenção **sem trava** só no livro. Travar é irreversível e põe um *lien* que
  # impede apagar o projeto; a trava fica como contrapartida de produção, não medida
  # (nota de 07/11/2026 no ADR-0050). No desmonte, `ledger_retention_seconds = 0` tira a
  # política antes do `destroy` — com ela, nenhum objeto sai antes do prazo e o
  # `force_destroy` falha.
  dynamic "retention_policy" {
    for_each = each.key == "livro" && var.ledger_retention_seconds > 0 ? [1] : []
    content {
      retention_period = var.ledger_retention_seconds
      is_locked        = false
    }
  }

  depends_on = [google_project_service.this]
}

# O livro: o `ingestor` (a captura) cria e lê — `objectCreator` não substitui nem apaga,
# que é o "nunca substituído" do ADR-0050 dito também pelo IAM, além da escrita condicionada.
# O `auditor` lê.
resource "google_storage_bucket_iam_member" "livro" {
  for_each = var.enable_cheap ? {
    "ingestor/objectCreator" = ["ingestor", "roles/storage.objectCreator"]
    "ingestor/objectViewer"  = ["ingestor", "roles/storage.objectViewer"]
    "auditor/objectViewer"   = ["auditor", "roles/storage.objectViewer"]
  } : {}

  bucket = google_storage_bucket.this["livro"].name
  role   = each.value[1]
  member = google_service_account.role[each.value[0]].member
}

resource "google_storage_bucket_iam_member" "beam" {
  for_each = var.enable_cheap ? toset(["streamer"]) : toset([])

  bucket = google_storage_bucket.this["beam"].name
  role   = "roles/storage.objectAdmin"
  member = google_service_account.role[each.key].member
}

# ── Pub/Sub: o caminho quente (ADR-0051) ─────────────────────────────────────
# Os nomes são os dos tópicos do Kafka na fase local (`streaming/fluxo.yml`): o Debezium
# Server publica no tópico `<topic.prefix>.<schema>.<tabela>`, o mesmo nome do conector
# declarado em `streaming/connectors/inventory_movements.yml`.

locals {
  topics = {
    eventos = "mvp.oltp.inventory_movements"
    alertas = "mvp.alerts.inventory_low_stock"
    # O *heartbeat* do conector (G2.3): sem ele o slot segura WAL quando a tabela para. O nome
    # padrão `__debezium-heartbeat.mvp` começa com `_`, que o Pub/Sub recusa; o gerador do
    # Debezium Server (`mvp_ed1.streaming.debezium_server`) fixa o prefixo `mvp-heartbeat`.
    # Sem assinatura: ninguém o lê, e mensagem sem assinatura o Pub/Sub não guarda.
    heartbeat = "mvp-heartbeat.mvp"
  }
}

resource "google_pubsub_topic" "this" {
  for_each = var.enable_cheap ? local.topics : {}

  name = each.value

  # Uma semana: a janela inteira; reenvio depois de retorno perdido lê daqui (G2.3).
  message_retention_duration = "604800s"

  depends_on = [google_project_service.this]
}

# A leitura do Beam (`ReadFromPubSub` com *ack* nativo) e a observação dos alertas — a
# fase local lê o tópico de alertas pelo `stream-alerts`; aqui, pela assinatura.
resource "google_pubsub_subscription" "this" {
  for_each = var.enable_cheap ? {
    beam       = "eventos"
    observacao = "alertas"
  } : {}

  name  = "${local.topics[each.value]}.${each.key}"
  topic = google_pubsub_topic.this[each.value].id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"
  retain_acked_messages      = false

  # Sem expiração por inatividade: a padrão (31 dias) não importa numa semana, mas
  # uma assinatura que some sozinha é a surpresa que o rito evita.
  expiration_policy {
    ttl = ""
  }
}

# O `streamer` é o caminho quente inteiro: o Debezium Server publica os eventos, o Beam os
# lê e publica os alertas. Se o *sink* do Debezium precisar ler o tópico (`topics.get`)
# para publicar, a prova da terça (G2.3) diz, e o papel cresce aqui — não antes.
resource "google_pubsub_topic_iam_member" "publica" {
  for_each = var.enable_cheap ? toset(["eventos", "alertas", "heartbeat"]) : toset([])

  topic  = google_pubsub_topic.this[each.key].name
  role   = "roles/pubsub.publisher"
  member = google_service_account.role["streamer"].member
}

resource "google_pubsub_subscription_iam_member" "le" {
  for_each = var.enable_cheap ? toset(["beam", "observacao"]) : toset([])

  subscription = google_pubsub_subscription.this[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = google_service_account.role["streamer"].member
}
