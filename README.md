# mvp_eng_dados_1

MVP que visa criar engenharia e governança de dados de referência com Claude Code — iniciando no banco transacional PostgreSQL até o datamart, refinando em infraestrutura local e, quando em estado da arte, migrando para o GCP.

## Fases

1. **Local (pré-GCP)** — banco transacional PostgreSQL seguindo boas práticas de banco estruturado; pipelines em Python até o datamart/DW local, com camada de governança e views.
2. **GCP** — replicar o fluxo com Cloud SQL → BigQuery, aplicando boas práticas de Data Warehouse e Governança até as views de consumo.

## Estrutura

Repositório em estágio inicial de configuração.
