# Degrau barato (enable_cheap): os nove schemas do armazém como nove datasets
# (Arquitetura §2; mapa de paridade, "Camada de dados"). Os nomes são os mesmos
# — a macro generate_schema_name do dbt não acrescenta prefixo, aqui nem lá.

locals {
  datasets = {
    raw         = "Cópia fiel da origem principal, escrita pelo Airbyte e pelo caminho quente."
    raw_legacy  = "Snapshot imutável da origem legada, capturas retidas por acréscimo (ADR-0037)."
    staging     = "Dados tipados, padronizados e deduplicados."
    trusted     = "Regras de negócio aplicadas; legado tratado e empilhado."
    quarantine  = "O que não passou, com motivo — nenhum registro é descartado em silêncio."
    snapshots   = "Histórico SCD tipo 2 por snapshot do dbt (ADR-0017)."
    analytics   = "Datamart dimensional: fatos particionadas e clusterizadas, dimensões."
    consumption = "Views de consumo, autorizadas nos datasets que leem (G1.5)."
    governance  = "Controle e auditoria: certificado de captura do legado (ADR-0023, ADR-0044)."
  }
}

resource "google_bigquery_dataset" "layer" {
  for_each = var.enable_cheap ? local.datasets : {}

  dataset_id  = each.key
  location    = var.region
  description = each.value

  # O desmonte apaga o dataset com o conteúdo: sem isso o `destroy` recusa
  # dataset não vazio e o degrau não sai (PLANO_etapa_13.md §6.5).
  delete_contents_on_destroy = true

  depends_on = [google_project_service.this]
}

output "datasets" {
  description = "Os nove datasets das camadas: o que o `make gcp-armazem-zerar` esvazia e a época inicial confere vazio."
  value       = var.enable_cheap ? sort(keys(local.datasets)) : []
}
