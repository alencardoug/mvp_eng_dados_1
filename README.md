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
| [Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md) | Etapas, marcos, dependências e critérios de conclusão | v2.9 — Etapa 10 ainda não iniciada |
| [Arquitetura](docs/arquitetura.md) | Topologia, camadas, componentes, paridade local ↔ GCP e organização do repositório | v2.1 |
| [Modelo de Dados](docs/modelo_de_dados.md) | As 40 tabelas transacionais, o modelo dimensional, as invariantes e o contrato do evento de estoque | v1.6 — inventário e diagrama **gerados** |
| [Geração de Dados](docs/geracao_de_dados.md) | Motor de geração, perfis de volume, parâmetros e realismo | v3.2 — gerador corrigido na D31 |
| [Origem Legada](docs/origem_legada.md) | Banco defeituoso, catálogo de 21 falhas intencionais, limpeza, quarentena e empilhamento | v2.0 |
| [Streaming](docs/streaming.md) | CDC, transporte, processamento por tempo de evento, saldo em tempo real e alerta | v2.1 — revalidado na D31 |
| [Qualidade de Dados](docs/qualidade_de_dados.md) | Estratégia de testes e reconciliação por camada | v1.9 |
| [Capacidade e Recuperação](docs/capacidade_e_recuperacao.md) | Dimensionamento por cobertura, medição e ponto único de recuperação | v2.8 — medições da D31 separadas das históricas |
| [Governança de Dados](docs/governanca_de_dados.md) | Regras: dados permitidos, classificação, acesso, retenção, segredos e catálogo como código | v2.1 |
| [Dicionário de Dados](docs/dicionario_de_dados.md) | Registro: objetos, campos, classificação aplicada e linhagem | **Gerado** — 40 tabelas, 418 campos |
| [Glossário de Negócio](docs/glossario_de_negocio/) | Conceitos do varejo e as perguntas de negócio, importados pelo dbt | 16 perguntas, 16 conceitos |
| [Glossário Técnico](docs/glossario.md) | Termos de engenharia de dados usados no projeto | Vigente |
| [Pendências do Owner](docs/pendencias.md) | O que está parado esperando decisão sua, em ordem de urgência | Nada pendente |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e decisões ainda pendentes | 36 aceitos, 0 pendentes |
| [Materialização no dbt](docs/materializacao.md) | Materializações, estratégias de incremental e o critério de robustez que escolhe entre elas | Vigente — base do [ADR-0016](docs/adr/0016-materializacao-por-camada.md) |
| [Registro de Riscos](docs/riscos.md) | Riscos **R1**–**R14** e seus tratamentos | Vigente |
| [Execução Local](docs/execucao_local.md) | Pré-requisitos e comandos de operação | v1.7 — reconstrução dos dois caminhos conferida |
| [Referências](docs/referencias.md) | Fontes externas que sustentam as decisões | Vigente |

## Decisões já tomadas

**36 ADRs aceitos.** As escolhas que mais definem o projeto: domínio de varejo *omnichannel* ·
Airbyte, dbt e Airflow desde a fase local · Terraform como infraestrutura como código · geração com
Faker orientada a configuração · streaming de estoque com Debezium sobre Kafka Connect, Redpanda e
Apache Beam · catálogo como código · **nove schemas no armazém**, com `governance` restrito a
controle e auditoria · **SQLAlchemy e Alembic** · quatro níveis de classificação e cinco papéis de
acesso · `src/` como pacote Python instalável · prefixo por tipo nos objetos de banco ·
**volume por proporções e fator de escala**, com o alto volume reservado à fase GCP · views e
tabelas por camada, com incremental como exceção justificada · chaves substitutas por *hash* e
SCD tipo 2 por *snapshot* · Cloud Composer e Airbyte em contêiner na nuvem, em janela curta ·
**`uv` e Python 3.11** · configuração do gerador em YAML, com o piso de cobertura derivado dos
modelos · **entrega medida em dois grãos** — no prazo pela remessa, ciclo pelo pedido — com a data
realizada tirada do livro de eventos, e não da coluna da remessa · **dimensão que nenhuma pergunta
recorta não é construída**, e a recompra pós-atendimento é ancorada no pedido.

Contexto, alternativas e consequências de cada uma em [`docs/adr/`](docs/adr/).

## Status

**Próxima: Etapa 10 — Corte 6: origem legada, ainda não iniciada.** A D31 foi corrigida,
revalidada e [aceita](docs/pendencias.md#d31--encerrada); nada [pendente](docs/pendencias.md) do
lado do Owner. Termo aprovado (**M0**), decisões em ADR (**M1**), ambiente
subindo do zero com um comando (**M2**), **fluxo completo origem → consumo** em operação (**M3**) e
**streaming em operação com o *batch* intacto** (**M4**).

Cinco cortes verticais entregues — comercial, financeiro e estoque, o caminho quente, entrega e
logística, e relacionamento. **O modelo dimensional está completo: 10 fatos e 15 dimensões, e as 16
perguntas de negócio têm view com `contract: enforced`.** O armazém tem **36 fluxos de ingestão em
lote** mais o **CDC de `inventory_movements`**. Após a reconstrução da D31, o `dbt build` passou
com **485 objetos, 371 testes de qualidade, `WARN=0` e `ERROR=0`**; o teste de remessa sem item
é bloqueante. A DAG `fluxo_batch` terminou com as **nove tarefas em sucesso**. Resultados e
distinção entre avisos de dados e de compilação em [Qualidade](docs/qualidade_de_dados.md).

O mesmo livro de estoque chega por **dois caminhos independentes** — Debezium sobre Kafka Connect e
carga completa do Airbyte —, com sobreposição total e de propósito. A revalidação comparou
**chaves e payloads**, saldo por armazém/SKU, duplicatas no transporte, alertas e fato incremental
contra reconstrução completa. Detalhes do corte atual em
[Streaming §7.2](docs/streaming.md#72-revalidação-da-d31).

A geração corrigida preservou a cobertura das 40 tabelas e dos pedidos divididos. A nova
[invariante 13](docs/modelo_de_dados.md#4-invariantes-de-negócio) impede caixas vazias, e P13
reconcilia com as remessas entregues em `trusted`. Volumes, tempos e comparação anterior/posterior
em [Capacidade §2.7](docs/capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026), sem substituir
as medições históricas.

O ponto de partida da operação é [Execução Local](docs/execucao_local.md):

```bash
make env && make install && make up && make migrate && make seed-data
make tools && make airbyte-up && make airbyte-config && make airflow-up && make dag-run
```

E o caminho quente, que sobe separado do frio de propósito — os dois não precisam conviver fora da
validação final (risco **R11**):

```bash
make stream-up && make stream-run          # o pipeline fica em primeiro plano
make stream-produce && make stream-alerts  # em outro terminal
```
