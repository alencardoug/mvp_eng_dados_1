# Infraestrutura da fase GCP (Etapa 13, ADR-0004 e ADR-0024).
#
# Uma raiz só, com um interruptor por degrau de preço (variables.tf). Ligar um
# degrau é `apply` com a variável em true; desmontá-lo é o mesmo `apply` com ela
# em false — a ordem do desmonte do PLANO_etapa_13.md §6.5 é a ordem em que os
# interruptores são desligados, e não uma lista de `-target` lembrada à mão.
#
# O estado fica local, neste diretório (D74): `terraform.tfstate*` e `.terraform/`
# estão no .gitignore, e o estado contém as senhas geradas para o Cloud SQL.

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Credencial: a ADC do Owner (`gcloud auth application-default login`), de curta
# duração. Nenhuma chave de conta de serviço existe neste projeto (ADR-0025).
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # As APIs de orçamento e de catálogo cobram a cota do projeto que chama; com
  # credencial de usuário, é preciso dizer qual.
  billing_project       = var.project_id
  user_project_override = true

  default_labels = {
    projeto       = "mvp-ed1"
    etapa         = "13"
    desmontar-ate = "2026-11-12"
  }
}
