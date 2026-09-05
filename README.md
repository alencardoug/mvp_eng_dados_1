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
| [Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md) | Etapas, marcos, dependências e critérios de conclusão | v2.4 — Etapa 8 |
| [Arquitetura](docs/arquitetura.md) | Topologia, camadas, componentes, paridade local ↔ GCP e organização do repositório | v2.1 |
| [Modelo de Dados](docs/modelo_de_dados.md) | As 40 tabelas transacionais, o modelo dimensional, as invariantes e o contrato do evento de estoque | v1.2 — inventário e diagrama **gerados** |
| [Geração de Dados](docs/geracao_de_dados.md) | Motor de geração, perfis de volume, parâmetros e realismo | v3.0 — motor implementado |
| [Origem Legada](docs/origem_legada.md) | Banco defeituoso, catálogo de 21 falhas intencionais, limpeza, quarentena e empilhamento | v2.0 |
| [Streaming](docs/streaming.md) | CDC, transporte, processamento por tempo de evento, saldo em tempo real e alerta | v2.0 — **em operação** |
| [Qualidade de Dados](docs/qualidade_de_dados.md) | Estratégia de testes e reconciliação por camada | v1.3 |
| [Capacidade e Recuperação](docs/capacidade_e_recuperacao.md) | Dimensionamento por cobertura, medição e ponto único de recuperação | v2.1 — origem transacional **medida** |
| [Governança de Dados](docs/governanca_de_dados.md) | Regras: dados permitidos, classificação, acesso, retenção, segredos e catálogo como código | v2.1 |
| [Dicionário de Dados](docs/dicionario_de_dados.md) | Registro: objetos, campos, classificação aplicada e linhagem | **Gerado** — 40 tabelas, 418 campos |
| [Glossário de Negócio](docs/glossario_de_negocio/) | Conceitos do varejo e as perguntas de negócio, importados pelo dbt | 16 perguntas, 6 conceitos |
| [Glossário Técnico](docs/glossario.md) | Termos de engenharia de dados usados no projeto | Vigente |
| [Pendências do Owner](docs/pendencias.md) | O que está parado esperando decisão sua, em ordem de urgência | **D31** — a remessa que nasce sem item |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e decisões ainda pendentes | 36 aceitos, 1 pendente |
| [Materialização no dbt](docs/materializacao.md) | Materializações, estratégias de incremental e o critério de robustez que escolhe entre elas | Vigente — base do [ADR-0016](docs/adr/0016-materializacao-por-camada.md) |
| [Registro de Riscos](docs/riscos.md) | Riscos **R1**–**R14** e seus tratamentos | Vigente |
| [Execução Local](docs/execucao_local.md) | Pré-requisitos e comandos de operação | v1.6 — Etapas 2 a 7 conferidas |
| [Referências](docs/referencias.md) | Fontes externas que sustentam as decisões | Vigente |

## Decisões já tomadas

**30 decisões registradas.** As que mais definem o projeto: domínio de varejo *omnichannel* ·
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

**Etapa 10 — Corte 6: origem legada.** Termo aprovado (**M0**), decisões em ADR (**M1**), ambiente
subindo do zero com um comando (**M2**), **fluxo completo origem → consumo** em operação (**M3**) e
**streaming em operação com o *batch* intacto** (**M4**).

Cinco cortes verticais entregues — comercial, financeiro e estoque, o caminho quente, entrega e
logística, e relacionamento. **O modelo dimensional está completo: 10 fatos e 15 dimensões, e as 16
perguntas de negócio têm view com `contract: enforced`.** O armazém tem **36 fluxos de ingestão em
lote** mais o **CDC de `inventory_movements`**, e o `dbt build` constrói **485 objetos** — 484
verdes e **um aviso**, que é a D31 mostrando as 91 remessas sem item a cada execução —, dos quais
**371 testes de qualidade**. A DAG `fluxo_batch` roda **nove tarefas** de ponta a ponta em
**3 min 21 s**. Uma decisão [pendente](docs/pendencias.md): a **D31**, sobre a remessa que nasce sem
item.

O mesmo livro de estoque chega por **dois caminhos independentes** — Debezium sobre Kafka Connect e
carga completa do Airbyte —, com sobreposição total e de propósito: **15.446 movimentos distintos,
15.446 linhas na fato**, zero duplicadas e zero perdidas. Duzentas e cinquenta duplicatas injetadas
no transporte não gravaram uma linha, e o saldo reconstruído pelo fluxo bate exatamente com a
projeção da origem — 2.910 pares, 701.851 unidades. Detalhe em
[Streaming §7.1](docs/streaming.md#71-o-que-foi-medido).

Primeira medição real do projeto, em ambiente limpo e fator `dev`: **253.414 linhas** em **54,5 MB**
— 225 bytes por linha —, geradas em 5,1 s e carregadas em 26 s. As doze
[invariantes de negócio](docs/modelo_de_dados.md#4-invariantes-de-negócio) fecham com zero
violações, e as 40 tabelas têm todo valor de enumeração representado. Detalhe em
[Capacidade §2.1](docs/capacidade_e_recuperacao.md#21-medido-na-etapa-4--origem-transacional).

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
