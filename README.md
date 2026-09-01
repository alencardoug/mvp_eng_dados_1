# mvp_eng_dados_1 — Engenharia e Governança de Dados de Referência

MVP que constrói, de ponta a ponta, um fluxo de dados sobre um **marketplace de varejo
*omnichannel* sintético**: de um banco transacional PostgreSQL até um **datamart dimensional** com
**governança**, views de consumo e documentação. O projeto é conduzido primeiro em **infraestrutura
local** e, quando maduro, **replicado no Google Cloud Platform** com Terraform, preservando as
mesmas boas práticas.

Todos os dados são **sintéticos**. Nenhum dado pessoal real é usado em nenhuma fase.

```text
Faker → PostgreSQL → Airbyte → dbt → datamart → views          (batch, orquestrado por Airflow)
                  ↘ Debezium → Redpanda → Apache Beam ↗        (streaming de estoque)
        legado defeituoso → snapshot → limpeza → quarentena     (segunda origem)
```

## Fases

1. **Local (pré-GCP)** — duas origens transacionais, geração determinística de dados, ingestão,
   transformação em camadas, datamart dimensional, um fluxo contínuo restrito ao estoque,
   governança e testes. Tudo reproduzível a partir do repositório.
2. **GCP** — replicação do fluxo com Cloud SQL, BigQuery, Datastream, Pub/Sub e Dataflow,
   provisionado por Terraform, com a mesma governança materializada em *policy tags*.

## Mapa da documentação

Cada assunto tem **um único dono documental**. Se a informação está em dois lugares, é defeito.

| Artefato | O que só existe ali | Situação |
|---|---|---|
| [Termo de Abertura](Abertura_de_projeto.md) | Justificativa, objetivo, escopo, entregas, critérios de sucesso, premissas, restrições, papéis e aprovação | v1.1 — rascunho para aprovação |
| [`CLAUDE.md`](CLAUDE.md) | Idioma, nomenclatura, *commits*, modo de desenvolvimento assistido e definição de pronto | Vigente |
| [Princípios](docs/principios.md) | As nove regras **P1**–**P9** que governam as decisões | Vigente |
| [Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md) | Etapas, marcos, dependências e critérios de conclusão | v2.0 — Etapa 0 |
| [Arquitetura](docs/arquitetura.md) | Topologia, camadas, componentes, paridade local ↔ GCP e organização do repositório | v2.0 |
| [Modelo de Dados](docs/modelo_de_dados.md) | As 40 tabelas transacionais, o modelo dimensional, as invariantes e o contrato do evento de estoque | Proposta |
| [Geração de Dados](docs/geracao_de_dados.md) | Motor de geração, perfis de volume, parâmetros e realismo | Proposta |
| [Origem Legada](docs/origem_legada.md) | Banco defeituoso, falhas intencionais, limpeza, quarentena e empilhamento | Proposta |
| [Streaming](docs/streaming.md) | CDC, transporte, processamento por tempo de evento, saldo em tempo real e alerta | Proposta |
| [Qualidade de Dados](docs/qualidade_de_dados.md) | Estratégia de testes e reconciliação por camada | Proposta |
| [Capacidade e Recuperação](docs/capacidade_e_recuperacao.md) | Orçamento de 4 GB, medição e ponto único de recuperação | Proposta |
| [Governança de Dados](docs/governanca_de_dados.md) | Regras: dados permitidos, classificação, acesso, retenção, segredos e catálogo como código | v2.0 |
| [Dicionário de Dados](docs/dicionario_de_dados.md) | Registro: objetos, campos, classificação aplicada e linhagem | Vazio — a partir da Etapa 3 |
| [Glossário de Negócio](docs/glossario_de_negocio/) | Conceitos do varejo, importados pelo dbt | Vazio — a partir da Etapa 5 |
| [Glossário Técnico](docs/glossario.md) | Termos de engenharia de dados usados no projeto | Vigente |
| [Pendências do Owner](docs/pendencias.md) | O que está parado esperando decisão sua, em ordem de urgência | 1 aprovação, 22 decisões |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e decisões ainda pendentes | 7 aceitos, 22 pendentes |
| [Registro de Riscos](docs/riscos.md) | Riscos **R1**–**R14** e seus tratamentos | Vigente |
| [Execução Local](docs/execucao_local.md) | Pré-requisitos e comandos de operação | Contrato — nada implementado |
| [Referências](docs/referencias.md) | Fontes externas que sustentam as decisões | Vigente |

## Decisões já tomadas

Domínio de varejo *omnichannel* · Airbyte, dbt e Airflow desde a fase local · Terraform como
infraestrutura como código · geração com Faker orientada a configuração · streaming de estoque com
Debezium, Redpanda e Apache Beam · catálogo como código. Contexto e alternativas de cada uma em
[`docs/adr/`](docs/adr/).

## Status

**Etapa 0 — Fundação documental.** Nenhum código escrito ainda; o Termo de Abertura aguarda
aprovação e as decisões da Etapa 1 seguem pendentes — a lista do que depende do Owner está em
[Pendências](docs/pendencias.md).

Quando houver o que executar, o ponto de partida será
[Execução Local](docs/execucao_local.md).
