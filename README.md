# mvp_eng_dados_1 — Engenharia e Governança de Dados de Referência

MVP que constrói, de ponta a ponta, um fluxo de dados que parte de um **banco transacional
estruturado** e alcança um **datamart analítico** com camada de **governança**, views de consumo
e documentação. O projeto é conduzido primeiro em **infraestrutura local** (PostgreSQL + Python)
e, quando maduro, **replicado no Google Cloud Platform** (Cloud SQL + BigQuery), preservando as
mesmas boas práticas de modelagem, Data Warehouse e governança.

> **Governança:** este README acompanha o [`Abertura_de_projeto.md`](./Abertura_de_projeto.md),
> que é a fonte de verdade do projeto (objetivo, escopo, princípios, arquitetura, riscos,
> governança de dados e critérios de sucesso). Em caso de divergência, prevalece o Termo de
> Abertura.

## Fases

1. **Local (pré-GCP)** — banco transacional PostgreSQL aderente a boas práticas de modelagem
   relacional; simulação controlada de dados de origem; ingestão e transformação em Python até
   um datamart dimensional; governança (dicionário, catálogo, linhagem, classificação) e views
   de consumo; testes de qualidade de dados. Tudo reproduzível a partir do repositório.
2. **GCP** — replicação do fluxo com Cloud SQL → BigQuery, aplicando boas práticas de Data
   Warehouse e Governança (datasets, particionamento, políticas de acesso) até as views de
   consumo equivalentes.

## Escopo detalhado

Ver seções 6 a 8 do [`Abertura_de_projeto.md`](./Abertura_de_projeto.md).

## Convenção de idioma

- **Documentação, comentários de governança, ADRs, dicionário de dados e mensagens de commit:**
  português brasileiro.
- **Código Python e identificadores técnicos** (variáveis, funções, módulos, schemas, tabelas,
  colunas, views): inglês.
- Detalhes e exceções na seção 20 do Termo de Abertura.

## Status

Repositório em iniciação. Termo de Abertura em rascunho para aprovação.

## Estrutura de referência (a construir)

| Artefato | Situação |
|---|---|
| `Abertura_de_projeto.md` | Criado (v1.0, rascunho para aprovação) |
| `CLAUDE.md` | A criar |
| Documento de arquitetura | A criar |
| Registro de decisões (ADR) | A criar |
| Dicionário de dados e catálogo | A criar |
| Instruções de execução local | A criar |
