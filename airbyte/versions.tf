# Conexões do Airbyte como código (ADR-0004: nada é criado fora do Terraform).
#
# O provider é o mesmo que a Etapa 13 usará na nuvem — é o que torna a
# ingestão local e a de produção o mesmo artefato, e não duas configurações
# parecidas mantidas em paralelo (P4).

terraform {
  required_version = ">= 1.9"

  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "~> 1.3"
    }
  }
}

provider "airbyte" {
  server_url = var.airbyte_server_url

  # `token_url` explícito: sem ele o provider procura o token na API da nuvem do
  # Airbyte e recebe HTML de volta. O erro que aparece é "JSON malformado", e
  # não "estou falando com o servidor errado" — meia hora de diagnóstico que
  # este comentário existe para poupar.
  token_url     = "${trimsuffix(var.airbyte_server_url, "/")}/applications/token"
  client_id     = var.airbyte_client_id
  client_secret = var.airbyte_client_secret
}
