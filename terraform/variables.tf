variable "project_id" {
  description = "Projeto dedicado da Etapa 13 (D74)."
  type        = string
}

variable "billing_account_id" {
  description = "Conta de faturamento da avaliação; só o orçamento a usa."
  type        = string
}

variable "region" {
  description = "D73: us-central1."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "D73: o GKE é zonal, com dois nós no total (RV13-2-05)."
  type        = string
  default     = "us-central1-a"
}

# ── Orçamento ────────────────────────────────────────────────────────────────
# Na moeda da conta de faturamento. Os créditos da avaliação são EXCLUÍDOS do
# cálculo: com eles incluídos o gasto líquido é zero e nenhum alerta dispara.

variable "budget_currency" {
  type    = string
  default = "BRL"
}

variable "budget_amount_units" {
  description = "Teto de referência do orçamento; os alertas são frações dele."
  type        = number
  default     = 400
}

variable "budget_thresholds" {
  type    = list(number)
  default = [0.3, 0.6, 0.9]
}

# ── Interruptores por degrau de preço (PLANO_etapa_13.md §0, regra 4) ────────

variable "enable_cheap" {
  description = "BigQuery, Cloud Storage, Pub/Sub, IAM, Secret Manager, taxonomias."
  type        = bool
  default     = false
}

variable "enable_cloud_sql" {
  description = "Cloud SQL for PostgreSQL com as duas origens (segunda, 09/11)."
  type        = bool
  default     = false
}

variable "enable_gke" {
  description = "GKE zonal com Airbyte e Debezium Server (terça, 10/11)."
  type        = bool
  default     = false
}

variable "enable_composer" {
  description = "Cloud Composer 3 — só na parte cara da janela (quarta, 11/11, 07:00–22:00)."
  type        = bool
  default     = false
}
