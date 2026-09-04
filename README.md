# mvp_eng_dados_1 — Engenharia e Governança de Dados de Referência

MVP que constrói, de ponta a ponta, um fluxo de dados sobre um **marketplace de varejo
*omnichannel* sintético**: de um banco transacional PostgreSQL até um **datamart dimensional** com
**governança**, views de consumo e documentação. O projeto é conduzido primeiro em **infraestrutura
local** e, quando maduro, **replicado no Google Cloud Platform** com Terraform, preservando as
mesmas boas práticas.

Todos os dados são **sintéticos**. Nenhum dado pessoal real é usado em nenhuma fase.

```text
Faker → PostgreSQL → Airbyte → dbt → datamart → consumption     (batch, orquestrado por Airflow)
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
| [Termo de Abertura](Abertura_de_projeto.md) | Justificativa, objetivo, escopo, entregas, critérios de sucesso, premissas, restrições, papéis e aprovação | v1.2 — **aprovado** |
| [`CLAUDE.md`](CLAUDE.md) | Idioma, nomenclatura, *commits*, modo de desenvolvimento assistido e definição de pronto | Vigente |
| [Princípios](docs/principios.md) | As dez regras **P1**–**P10** que governam as decisões | Vigente |
| [Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md) | Etapas, marcos, dependências e critérios de conclusão | v2.1 — Etapa 0 |
| [Arquitetura](docs/arquitetura.md) | Topologia, camadas, componentes, paridade local ↔ GCP e organização do repositório | v2.1 |
| [Modelo de Dados](docs/modelo_de_dados.md) | As 40 tabelas transacionais, o modelo dimensional, as invariantes e o contrato do evento de estoque | v1.1 |
| [Geração de Dados](docs/geracao_de_dados.md) | Motor de geração, perfis de volume, parâmetros e realismo | v1.1 |
| [Origem Legada](docs/origem_legada.md) | Banco defeituoso, catálogo de 21 falhas intencionais, limpeza, quarentena e empilhamento | v2.0 |
| [Streaming](docs/streaming.md) | CDC, transporte, processamento por tempo de evento, saldo em tempo real e alerta | v1.1 |
| [Qualidade de Dados](docs/qualidade_de_dados.md) | Estratégia de testes e reconciliação por camada | v1.1 |
| [Capacidade e Recuperação](docs/capacidade_e_recuperacao.md) | Dimensionamento por cobertura, medição e ponto único de recuperação | v2.0 |
| [Governança de Dados](docs/governanca_de_dados.md) | Regras: dados permitidos, classificação, acesso, retenção, segredos e catálogo como código | v2.1 |
| [Dicionário de Dados](docs/dicionario_de_dados.md) | Registro: objetos, campos, classificação aplicada e linhagem | Vazio — a partir da Etapa 3 |
| [Glossário de Negócio](docs/glossario_de_negocio/) | Conceitos do varejo, importados pelo dbt | Vazio — a partir da Etapa 5 |
| [Glossário Técnico](docs/glossario.md) | Termos de engenharia de dados usados no projeto | Vigente |
| [Pendências do Owner](docs/pendencias.md) | O que está parado esperando decisão sua, em ordem de urgência | Nada pendente |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e decisões ainda pendentes | 26 aceitos, 0 pendentes |
| [Materialização no dbt](docs/materializacao.md) | Materializações, estratégias de incremental e o critério de robustez que escolhe entre elas | Vigente — base do [ADR-0016](docs/adr/0016-materializacao-por-camada.md) |
| [Registro de Riscos](docs/riscos.md) | Riscos **R1**–**R14** e seus tratamentos | Vigente |
| [Execução Local](docs/execucao_local.md) | Pré-requisitos e comandos de operação | v1.1 — contrato, nada implementado |
| [Referências](docs/referencias.md) | Fontes externas que sustentam as decisões | Vigente |

## Decisões já tomadas

**26 decisões registradas.** As que mais definem o projeto: domínio de varejo *omnichannel* ·
Airbyte, dbt e Airflow desde a fase local · Terraform como infraestrutura como código · geração com
Faker orientada a configuração · streaming de estoque com Debezium sobre Kafka Connect, Redpanda e
Apache Beam · catálogo como código · **nove schemas no armazém**, com `governance` restrito a
controle e auditoria · **SQLAlchemy e Alembic** · quatro níveis de classificação e cinco papéis de
acesso · `src/` como pacote Python instalável · prefixo por tipo nos objetos de banco ·
**volume por proporções e fator de escala**, com o alto volume reservado à fase GCP · views e
tabelas por camada, com incremental como exceção justificada · chaves substitutas por *hash* e
SCD tipo 2 por *snapshot* · Cloud Composer e Airbyte em contêiner na nuvem, em janela curta · **`uv` e Python 3.11**.

Contexto, alternativas e consequências de cada uma em [`docs/adr/`](docs/adr/).

## Status

**Etapa 3 — Modelo e banco transacional.** Termo aprovado (**M0**), decisões registradas em ADR
(**M1**) e o ambiente local subindo do zero com um comando (**M2**). Nada
[pendente](docs/pendencias.md) do lado do Owner.

O ponto de partida da operação é [Execução Local](docs/execucao_local.md):

```bash
make env && make install && make up
```
