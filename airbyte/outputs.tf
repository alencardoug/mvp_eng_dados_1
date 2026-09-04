output "streams_declarados" {
  description = "Tabela → modo, como declarado em streams.yml. É o que o teste de conferência compara contra a conexão real."
  value       = { for nome, spec in local.streams.tabelas : nome => spec.modo }
}

output "connection_id" {
  value = airbyte_connection.oltp_para_raw.connection_id
}
