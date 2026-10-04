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

## Em resumo

| | |
|---|---|
| **Estado** | Fase local concluída: `v1.0.0`, em 04/10/2026. A fase GCP está planejada e não começou |
| **Stack** | PostgreSQL · Airbyte (em Kubernetes local) · dbt · Airflow · Debezium sobre Kafka Connect · Redpanda · Apache Beam · Terraform · Docker · Python com SQLAlchemy e Alembic |
| **Escopo** | 40 tabelas de origem e uma origem legada defeituosa de propósito; nove camadas no armazém; 10 fatos, 15 dimensões e 16 views de consumo, uma por pergunta de negócio |
| **Qualidade** | `make check` com 905 nós do dbt (700 testes de dados) e 637 testes Python; reconciliação em toda fronteira entre camadas; 4.161 de 4.161 colunas classificadas por sensibilidade |
| **Processo** | 48 ADRs; 33 dias e 306 *commits* do primeiro *commit* à `v1.0.0`; as Etapas 10 a 12 revisadas por um segundo agente, em rodadas até não restar achado |
| **Reprodutível** | O ciclo inteiro refeito num clone novo e medido passo a passo, e um ponto único de recuperação restaurado de ponta a ponta |

## Para estudar o projeto

A [trilha de estudo da fase local](CONVERSAS_COM_CHAT/trilha_de_estudo_fase_local.html) segue um
pedido e um movimento de estoque por todas as camadas e traz laboratórios de cada ferramenta, com as
saídas reais de uma execução em 04/10/2026. É um HTML autocontido: baixe o arquivo e abra no
navegador, porque o GitHub mostra o código-fonte em vez da página. **Não é documento do projeto** e
fica fora do mapa abaixo: em divergência, vale o documento.

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
| [Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md) | Etapas, marcos, dependências e critérios de conclusão | v3.8 — Etapa 12 aceita em 04/10/2026: o M5 fechado, a fase local concluída (`v1.0.0`) |
| [Arquitetura](docs/arquitetura.md) | Topologia, camadas, componentes, paridade local ↔ GCP e organização do repositório | v2.5 |
| [Modelo de Dados](docs/modelo_de_dados.md) | As 40 tabelas transacionais, o modelo dimensional, as invariantes e o contrato do evento de estoque | v1.8 — inventário e diagrama **gerados** |
| [Geração de Dados](docs/geracao_de_dados.md) | Motor de geração, perfis de volume, parâmetros e realismo | v3.2 — gerador corrigido na D31 |
| [Origem Legada](docs/origem_legada.md) | Banco defeituoso, catálogo de falhas, limpeza, quarentena e empilhamento | v2.8 |
| [Streaming](docs/streaming.md) | CDC, transporte, processamento por tempo de evento, saldo em tempo real e alerta | v2.1 — revalidado na D31 |
| [Qualidade de Dados](docs/qualidade_de_dados.md) | Estratégia de testes e reconciliação por camada | v1.12 — toda fronteira com teste |
| [Capacidade e Recuperação](docs/capacidade_e_recuperacao.md) | Dimensionamento por cobertura, medição e ponto único de recuperação | v2.14 — o ciclo do zero medido e o ponto de recuperação entregue |
| [Governança de Dados](docs/governanca_de_dados.md) | Regras: dados permitidos, classificação, acesso, retenção, segredos e catálogo como código | v2.6 — acesso por papel implementado e testado; a varredura do histórico na §9, e o tratamento do que ela acha no ADR-0048 |
| [Segredos tratados](docs/segredos_tratados.yml) | Registro: os achados históricos de credencial já tratados, com o tratamento e o motivo (ADR-0048) | 11 achados, todos tratados em 03/10/2026 |
| [Dicionário de Dados](docs/dicionario_de_dados.md) | Registro: objetos, campos, classificação aplicada e linhagem | **Gerado** — 40 tabelas, 418 campos; linhagem por coluna do consumo e travessias fora do dbt |
| [Glossário de Negócio](docs/glossario_de_negocio/) | Conceitos do varejo e as perguntas de negócio, importados pelo dbt | 16 perguntas, 16 conceitos |
| [Glossário Técnico](docs/glossario.md) | Termos de engenharia de dados usados no projeto | Vigente |
| [Pendências do Owner](docs/pendencias.md) | O que está parado esperando decisão sua, em ordem de urgência | 5 pendentes em 04/10/2026: D62 a D65, levantadas pela validação do material de estudo, e a D43 (adiada para a fase GCP) |
| [Registro de Decisões](docs/adr/) | ADRs aceitos e decisões ainda pendentes | 48 aceitos, 1 pendente (D43, adiada) |
| [Materialização no dbt](docs/materializacao.md) | Materializações, estratégias de incremental e o critério de robustez que escolhe entre elas | Vigente — base do [ADR-0016](docs/adr/0016-materializacao-por-camada.md) |
| [Registro de Riscos](docs/riscos.md) | Riscos **R1**–**R14** e seus tratamentos | v1.5 — R7 com a política do ADR-0048; R6 com o *chart* do Airbyte fixado |
| [Execução Local](docs/execucao_local.md) | Pré-requisitos e comandos de operação | v1.17 — o preparo do clone, o ciclo na ordem do B5 e os alvos da Etapa 12, conferidos contra o B5 |
| [Referências](docs/referencias.md) | Fontes externas que sustentam as decisões | Vigente |

## Decisões já tomadas

**48 ADRs aceitos.** As escolhas que mais definem o projeto: domínio de varejo *omnichannel* ·
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
recorta não é construída**, e a recompra pós-atendimento é ancorada no pedido · **nulo obrigatório
após a limpeza é rejeitado**, sem apagar a evidência da conversão · **a captura legada é
reconciliada na fato incremental por `delete+insert`**, com o *streaming* mantendo o filtro por
tempo de evento · **cada captura do legado é certificada por conteúdo, por *stream* e por *job***,
e só captura certificada é elegível · **a exclusão física do legado é detectada no bruto retido**,
entre capturas certificadas, sem marca nas dimensões — a cascata e o `delete+insert` já retiram do
datamart o que dependia do registro · **a fase local é validada por partes**, sem exigir *batch* e
*streaming* simultâneos — a concorrência entre os dois é medida na fase GCP · **o CTE de limpeza do legado é materializado no
PostgreSQL** — o planejador o embutia em cada referência, a 10× o custo · **segredo achado no
histórico é tratado pelo tipo da credencial** — a local se regenera e se registra, sem reescrever
o histórico; a de nuvem se revoga e se reescreve, pela mão do Owner.

Contexto, alternativas e consequências de cada uma em [`docs/adr/`](docs/adr/).

## Status

**A fase local está concluída: o M5 fechou em 04/10/2026, com a *tag* `v1.0.0`.** A Etapa 13 —
replicação no GCP com Terraform, o M6 — não começou; o pré-requisito é a autorização explícita do
Owner.

O fechamento (Etapa 12) refez o ciclo inteiro num clone novo do repositório, com `.env` novo, sobre
bancos, Airbyte e Airflow instalados do zero, cada cenário no seu subconjunto de ambiente — sem
*batch* e *streaming* juntos ([ADR-0046](docs/adr/0046-validar-a-fase-local-por-partes.md)). Cada
passo tem duração, memória e tamanho medidos
([Capacidade §2.12](docs/capacidade_e_recuperacao.md#212-o-ciclo-do-zero-medido--b5-25092026)), e o
ciclo achou oito desvios, todos corrigidos na origem. O **ponto único de recuperação** — as fontes e a
memória do armazém num pacote com manifesto — foi restaurado sobre o ambiente povoado em 17 minutos,
com o *re-snapshot* do CDC ([Capacidade §3](docs/capacidade_e_recuperacao.md#3-ponto-único-de-recuperação)).
No aceite, depois de quatro rodadas de revisão final por outro agente: `make check` verde com
`PASS=905` e 637 testes Python, e o histórico inteiro sem segredo não tratado.

Os marcos de M0 a M5, os critérios de cada etapa e o que foi medido em cada uma estão no
[Plano de Desenvolvimento](docs/plano_de_desenvolvimento.md); o que está aberto, nas
[Pendências do Owner](docs/pendencias.md). O ponto de partida da operação é a
[Execução Local](docs/execucao_local.md).

**Depois do M5 (04/10/2026).** A validação do material de estudo, que rodou cada laboratório na
máquina, levantou quatro decisões para o Owner, registradas nas Pendências: a contagem dupla no saldo
do alerta do *streaming* (D62), o medidor do *streaming* que encerra antes de o ramo de alerta drenar
(D63), a chave Fernet do Airflow gerada inválida (D64) e itens vendidos antes do lançamento do produto
no dado sintético (D65). Nada no código foi alterado.
