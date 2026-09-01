# Referências

> **O que vive aqui:** as fontes externas que sustentam as decisões do projeto e apoiam o objetivo
> de aprendizado.
>
> **O que não vive aqui:** as decisões em si (ver [Registro de Decisões](adr/README.md)); a
> definição dos termos (ver [Glossário Técnico](glossario.md)).

Esta lista é curta de propósito: são as fontes efetivamente usadas, não um levantamento
bibliográfico.

---

## 1. Modelagem e arquitetura de dados

| Obra | Por que está aqui |
|---|---|
| Ralph Kimball e Margy Ross, *The Data Warehouse Toolkit* | Base da modelagem dimensional adotada: grão, esquema estrela, dimensões conformadas e SCD |
| Bill Inmon, *Building the Data Warehouse* | Referência da visão de armazém corporativo, útil para entender por que as camadas existem |
| Martin Kleppmann, *Designing Data-Intensive Applications* | Fundamento do fluxo de streaming: log de eventos, CDC, ordenação, garantias de entrega |
| Joe Reis e Matt Housley, *Fundamentals of Data Engineering* | Visão do ciclo de vida da engenharia de dados, do qual este MVP percorre uma volta completa |
| DAMA-DMBOK, *Data Management Body of Knowledge* | Vocabulário e escopo da governança: catálogo, qualidade, metadados, papéis |

## 2. Prática e convenções

| Fonte | Uso no projeto |
|---|---|
| [Architecture Decision Records](https://adr.github.io/) | Formato dos ADRs |
| [Conventional Commits](https://www.conventionalcommits.org/) | Padrão das mensagens de *commit* |
| [Semantic Versioning](https://semver.org/) | Versionamento das entregas da fase local |

## 3. Documentação das ferramentas

| Ferramenta | Documentação |
|---|---|
| PostgreSQL | https://www.postgresql.org/docs/ |
| Faker | https://faker.readthedocs.io/ |
| Airbyte | https://docs.airbyte.com/ |
| dbt | https://docs.getdbt.com/ |
| Airflow | https://airflow.apache.org/docs/ |
| Apache Beam | https://beam.apache.org/documentation/ |
| Debezium | https://debezium.io/documentation/ |
| Redpanda | https://docs.redpanda.com/ |
| Terraform | https://developer.hashicorp.com/terraform/docs |

## 4. Google Cloud — fase GCP

| Serviço | Documentação |
|---|---|
| BigQuery | https://cloud.google.com/bigquery/docs |
| Cloud SQL | https://cloud.google.com/sql/docs |
| Datastream | https://cloud.google.com/datastream/docs |
| Dataflow | https://cloud.google.com/dataflow/docs |
| Pub/Sub | https://cloud.google.com/pubsub/docs |
| Dataplex | https://cloud.google.com/dataplex/docs |

---

Ao acrescentar uma referência, diga **para que ela serve neste projeto**. Uma lista de links sem
justificativa envelhece rápido e não ajuda ninguém a estudar.
