output "streams_declarados" {
  description = "Origem → tabela → modo, como declarado em streams.yml. É o que o teste de conferência compara contra as conexões reais."
  value = {
    for origem, fluxos in local.fluxos : origem => { for nome, spec in fluxos : nome => spec.modo }
  }
}

output "connection_ids" {
  description = "Nome da conexão → identificador, para o cliente Python resolver sem consultar a API."
  value       = { for origem, conexao in airbyte_connection.ingestao : conexao.name => conexao.connection_id }
}
