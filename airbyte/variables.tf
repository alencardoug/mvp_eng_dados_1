# Nenhum valor de credencial aqui. Todos entram por `TF_VAR_*`, que o Makefile
# preenche a partir do `.env` e do `abctl local credentials` — regra inviolável
# 1 do CLAUDE.md.

variable "airbyte_server_url" {
  description = "URL da API pública do Airbyte local."
  type        = string
  default     = "http://localhost:8000/api/public/v1"
}

variable "airbyte_client_id" {
  description = "Client ID da aplicação Airbyte; vem de `abctl local credentials`."
  type        = string
  sensitive   = true
}

variable "airbyte_client_secret" {
  description = "Client secret da aplicação Airbyte."
  type        = string
  sensitive   = true
}

variable "source_db_host" {
  description = <<-EOT
    Host do `source_db` **visto de dentro do cluster do Airbyte**, que não é o
    mesmo que `localhost`: o Airbyte roda em um cluster Kubernetes próprio, e o
    banco está publicado no host. O gateway da bridge do Docker é o caminho.
  EOT
  type        = string
  default     = "172.17.0.1"
}

variable "source_db_port" {
  type    = number
  default = 5432
}

variable "source_db_name" { type = string }
variable "source_db_user" { type = string }
variable "source_db_password" {
  type      = string
  sensitive = true
}

variable "warehouse_db_host" {
  type    = string
  default = "172.17.0.1"
}
variable "warehouse_db_port" {
  type    = number
  default = 5434
}
variable "warehouse_db_name" { type = string }
variable "warehouse_db_user" { type = string }
variable "warehouse_db_password" {
  type      = string
  sensitive = true
}

variable "airbyte_workspace_id" {
  description = "Workspace padrão criado pelo `abctl`; o Makefile o descobre pela API."
  type        = string
}

# Identificadores dos conectores no catálogo do Airbyte. São estáveis entre
# instalações — estes foram conferidos na tabela `actor_definition` da própria
# instância, e não copiados de documentação. A API pública não lista definições
# (responde 403), então fixá-los aqui é a alternativa honesta a um `curl` que
# não funciona.
variable "postgres_source_definition_id" {
  description = "definition_id do conector de origem PostgreSQL."
  type        = string
  default     = "decd338e-5647-4c0b-adf4-da0e75f5a750"
}

variable "postgres_destination_definition_id" {
  description = "definition_id do conector de destino PostgreSQL."
  type        = string
  default     = "25c5221d-dce2-4163-ade9-739ef790f503"
}
