# Texto para o portfólio — dois projetos de engenharia de dados

> **O que este arquivo é:** o texto pronto para atualizar o portfólio (`~/Projetos/portfolio`,
> publicado em portfolio-douglas-alencar.web.app), montado em 04/10/2026 a pedido do Owner, para
> publicar depois. **Nada foi alterado nem publicado no portfólio.** Cada bloco diz em que arquivo de
> lá ele entra. Não é documento deste projeto e não entra no mapa do README.
>
> **Os dois projetos:**
>
> - **A — Engenharia e Governança de Dados**: este repositório até a fase local. **Concluído** em
>   04/10/2026 (`v1.0.0`).
> - **B — Engenharia de Dados no GCP**: a replicação do projeto A na nuvem, com Terraform. **A
>   iniciar**: é a Etapa 13 do plano deste repositório, e depende da autorização do Owner.
>
> **Regra do portfólio que este texto respeita** (`portfolio/CLAUDE.md`): nenhuma data, métrica ou URL
> inventada. Todo número vem da §1, com a fonte neste repositório. O projeto B não tem métricas porque
> ainda não começou, e nenhum custo de nuvem foi medido. Revalidar antes de publicar.

---

## 1. Fatos verificados

### Projeto A

| Fato | Valor | Fonte neste repositório | Medido em |
|---|---|---|---|
| Estado | Concluído: fase local, `v1.0.0` (M5) | README, Plano §Etapa 12, `git tag` | 04/10/2026 |
| Primeira versão | 33 dias: primeiro *commit* em 01/09/2026, `v1.0.0` em 04/10/2026 | `git log` | 04/10/2026 |
| *Commits* até a `v1.0.0` | 306 | `git rev-list --count v1.0.0` | 04/10/2026 |
| ADRs aceitos | 48, cada um com a contrapartida na fase GCP declarada | `docs/adr/` (0001–0048; 0000 é o modelo); Plano, Etapa 1 | 04/10/2026 |
| Testes Python | 637 (mais 8 pulados, cada um com motivo) | `make check` | 04/10/2026 |
| Testes de dados (dbt) | 700, num *build* de 905 nós com 5 testes unitários | `make dbt-build` | 04/10/2026 |
| Testes, somados | 1.337 = 637 Python + 700 de dados | soma das duas linhas acima | 04/10/2026 |
| Origem | 40 tabelas transacionais (36 ingeridas) e uma origem legada defeituosa de propósito | Modelo de Dados, `airbyte/streams.yml` | — |
| Armazém | 9 camadas, 10 fatos, 15 dimensões, 16 views de consumo | Arquitetura §2, Modelo de Dados §3 | — |
| Classificação | 4.161 de 4.161 colunas com nível de sensibilidade | Plano, Etapa 11 | 17/09/2026 |
| Acesso | 5 papéis sem login; o de análise lê só as views (1.390 leituras testadas) | Governança §7 | 18/09/2026 |
| Ciclo do zero | refeito num clone novo e medido passo a passo; 8 defeitos achados e corrigidos | Capacidade §2.12 | 25/09/2026 |
| Recuperação | pacote restaurado de ponta a ponta em 16 min 59 s | Capacidade §3 | 25/09/2026 |
| Orquestração | DAG de 13 tarefas, 6 min 56 s de ponta a ponta | `data/medicoes/material_estudo/` | 04/10/2026 |
| CDC | ~7 s da origem ao destino do caminho quente | idem | 04/10/2026 |
| Revisão | Etapas 10 a 12 revisadas por um segundo agente, em rodadas até não restar achado | Plano, README | — |
| Abertos | quatro decisões levantadas na validação final (D62 a D65) | `docs/pendencias.md` | 04/10/2026 |

### Projeto B

| Fato | Valor | Fonte neste repositório |
|---|---|---|
| Estado | Não iniciado; pré-requisitos: o M5 (cumprido) e a autorização explícita do Owner | Plano, Etapa 13 |
| Peças | Cloud SQL, BigQuery, Datastream, Pub/Sub, Dataflow com o mesmo código Beam, Cloud Composer e Airbyte em contêiner em janela curta, Dataplex, Secret Manager, IAM e *policy tags*, tudo por Terraform | Arquitetura §4 e §5 |
| Já decidido | Composer e Airbyte em contêiner, criados e destruídos na mesma janela (ADR-0024); *policy tags* aplicadas por fluxo automatizado (ADR-0025); a concorrência entre lote e contínuo medida na nuvem (ADR-0046) | ADRs citados |
| Critérios de conclusão | todo item do mapa de paridade provisionado; `terraform plan` revisado antes de cada `apply`; particionamento, *clustering*, retenção e políticas definidos antes de provisionar; acesso negado comprovado, sem credencial longeva; custo estimado e real registrados; lote e contínuo juntos, com a reconciliação passando; paridade funcional demonstrada | Plano, Etapa 13 |

---

## 2. Onde cada projeto mora no portfólio

Hoje existe um *card* só, `slug: "engenharia-dados-gcp"`, com página em `/projects/engenharia-dados-gcp/`.
A proposta:

- **o projeto B fica com o *slug* e a página atuais.** O nome "Engenharia de Dados no GCP" e o endereço
  já dizem nuvem, e quem tiver o link chega ao projeto certo;
- **o projeto A ganha *slug* e página novos**, `engenharia-governanca-dados`, em
  `/projects/engenharia-governanca-dados/` e `/en/projects/engenharia-governanca-dados/`. As duas
  páginas novas são cópia das atuais do GCP, trocando *slug*, caminho, título e descrição (§7);
- na lista `projects`, o A entra no lugar do *card* atual e o B logo depois.

---

## 3. Projeto A — *cards*

### `src/content/pt.ts`, lista `projects`

```ts
  {
    slug: "engenharia-governanca-dados",
    title: "Engenharia e Governança de Dados",
    status: "case-study",
    statusLabel: "Concluído",
    description:
      "Fluxo de dados de ponta a ponta sobre um varejo omnichannel sintético: do PostgreSQL ao modelo dimensional e às views de consumo, com Airbyte, dbt e Airflow no lote, CDC com Debezium, Redpanda e Apache Beam no estoque, e governança desde a primeira camada. Concluído e reproduzível a partir do repositório.",
    technologies: [
      "PostgreSQL",
      "Airbyte",
      "dbt",
      "Airflow",
      "Debezium",
      "Redpanda",
      "Apache Beam",
      "Python",
      "Terraform",
      "Docker",
    ],
    appUrl: null,
    githubUrl: "https://github.com/alencardoug/mvp_eng_dados_1",
    caseStudyUrl: "/projects/engenharia-governanca-dados/",
    metrics: [
      { label: "Primeira versão", value: "33 dias" },
      { label: "Testes", value: "1.337" },
      { label: "Commits", value: "306" },
      { label: "ADRs", value: "48" },
    ],
  },
```

Se preferir contar só os testes de código, como no *card* da Plataforma: `{ label: "Testes", value: "637" }`.
Sobre o status: o tipo do portfólio tem `production`, `development` e `case-study`. Um projeto local
concluído não está "em produção"; `case-study`, com o rótulo "Concluído", é o mais fiel.

### `src/content/en.ts`, lista `projects`

```ts
  {
    slug: "engenharia-governanca-dados",
    title: "Data Engineering and Governance",
    status: "case-study",
    statusLabel: "Completed",
    description:
      "An end-to-end data flow over a synthetic omnichannel retailer: from PostgreSQL to a dimensional model and consumption views, with Airbyte, dbt and Airflow for batch, CDC with Debezium, Redpanda and Apache Beam for inventory, and governance from the first layer. Completed and reproducible from the repository.",
    technologies: [
      "PostgreSQL",
      "Airbyte",
      "dbt",
      "Airflow",
      "Debezium",
      "Redpanda",
      "Apache Beam",
      "Python",
      "Terraform",
      "Docker",
    ],
    appUrl: null,
    githubUrl: "https://github.com/alencardoug/mvp_eng_dados_1",
    caseStudyUrl: "/en/projects/engenharia-governanca-dados/",
    metrics: [
      { label: "First version", value: "33 days" },
      { label: "Tests", value: "1,337" },
      { label: "Commits", value: "306" },
      { label: "ADRs", value: "48" },
    ],
  },
```

## 4. Projeto A — estudo de caso

### `src/content/pt.ts`, objeto `simpleCases["engenharia-governanca-dados"]` (entrada nova)

```ts
  "engenharia-governanca-dados": {
    eyebrow: "// concluído · v1.0.0",
    title: "Engenharia e Governança de Dados",
    lead: "Um fluxo de dados completo sobre um varejo omnichannel sintético, do banco da aplicação às views que um analista consulta, construído com o padrão de um ambiente corporativo: o dado é simulado, a engenharia não. Concluído em 04/10/2026 e reproduzível a partir do repositório.",
    sections: [
      {
        heading: "O que é",
        body: "Um projeto de referência em engenharia e governança de dados. Duas origens transacionais, uma delas um sistema legado defeituoso de propósito, alimentam um armazém em camadas, um modelo dimensional e views de consumo, com testes, linhagem, classificação de sensibilidade e controle de acesso desde a primeira camada. Todos os dados são sintéticos e gerados de forma determinística: a mesma semente produz exatamente os mesmos dados.",
      },
      {
        heading: "Fluxo de dados",
        list: [
          "Lote, orquestrado por Airflow: PostgreSQL → Airbyte → dbt, uma tarefa por camada, até as views de consumo. A DAG completa roda em cerca de 7 minutos.",
          "Contínuo, para o estoque: o Debezium lê o log de transações do PostgreSQL, o Redpanda transporta e o Apache Beam grava cada evento uma única vez e emite alertas de estoque baixo. Da origem ao destino, cerca de 7 segundos.",
          "Os dois caminhos carregam o mesmo livro de estoque, de propósito: um teste reconcilia um contra o outro a cada build.",
          "Segunda origem: o legado é capturado inteiro, certificado por conteúdo, limpo por um catálogo de falhas e empilhado ao lado da origem principal; o que não passa vai para quarentena, com o motivo.",
        ],
      },
      {
        heading: "Como os dados se organizam",
        list: [
          "Nove camadas, cada uma um schema próprio: raw, raw_legacy, staging, trusted, analytics, consumption, quarantine, governance e snapshots.",
          "Modelo dimensional com 10 fatos e 15 dimensões, chaves substitutas por hash e histórico SCD tipo 2 por snapshot.",
          "16 views de consumo, uma por pergunta de negócio, com contrato de colunas: é o único lugar que o papel de análise consegue ler.",
        ],
      },
      {
        heading: "Decisões de arquitetura",
        body: "48 ADRs aceitos, cada um com a contrapartida na nuvem já declarada. Entre as escolhas que mais definem o projeto: Airbyte, dbt e Airflow desde a fase local; conexões de ingestão declaradas como código em YAML e Terraform; schema das origens em SQLAlchemy e Alembic; camada como schema, nunca como prefixo de tabela; CDC e lote sobre o mesmo livro, reconciliados; nenhum registro descartado em silêncio; cada captura do legado certificada por conteúdo antes de ser usada; e a validação local feita por partes, porque o ambiente inteiro não cabe de uma vez na máquina.",
      },
      {
        heading: "Qualidade e governança",
        list: [
          "Um comando, make check, para na primeira falha: revisão de segredos, build do dbt com 700 testes de dados, classificação e linhagem em dia com os modelos, e 637 testes Python.",
          "Reconciliação automática em toda fronteira entre camadas, das origens às fatos.",
          "4.161 de 4.161 colunas classificadas por sensibilidade, derivadas por linhagem a partir dos modelos.",
          "Cinco papéis de acesso sem login, com as permissões declaradas no dbt e testadas assumindo cada papel: o de análise lê as views e nada mais.",
          "O histórico inteiro do Git varrido por credenciais, com o tratamento de cada achado registrado.",
        ],
      },
      {
        heading: "Reprodutível e recuperável",
        body: "O fechamento refez o ciclo inteiro num clone novo do repositório, com bancos, Airbyte e Airflow instalados do zero, e mediu duração, memória e tamanho em cada passo. O ciclo achou oito defeitos que um ambiente já povoado escondia, todos corrigidos na origem. Um pacote único de recuperação, com as origens e a memória do armazém, foi restaurado de ponta a ponta em 17 minutos, incluindo o novo snapshot do CDC.",
      },
      {
        heading: "Como foi construído",
        body: "Desenvolvido por github.com/alencardoug com suporte de Claude Code, que implementa, e de OpenAI Codex, que revisa: as três etapas finais passaram por rodadas de revisão independente, até a última rodada não trazer nenhum achado. A arquitetura e cada decisão ficaram com o autor, registradas em ADR; o trabalho seguiu um plano com critérios de conclusão por etapa, revisão integral do que é declaração (configuração, modelos, YAML) e por amostragem do que é gerado.",
      },
      {
        heading: "Resultado",
        list: [
          "Concluído em 04/10/2026, com a tag v1.0.0: 33 dias e 306 commits desde o primeiro commit.",
          "Uma validação final, que executou cada passo do material de estudo na máquina, levantou quatro decisões registradas no repositório, entre elas uma contagem dupla no saldo dos alertas do caminho contínuo.",
          "A continuação é o projeto Engenharia de Dados no GCP, que replica este fluxo na nuvem com Terraform.",
        ],
      },
    ],
    screenshotsHeading: "Evidência visual",
    screenshots: [
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-1-airflow-dag",
        alt: "Interface do Airflow com a DAG fluxo_batch: as 13 tarefas concluídas com sucesso em duas execuções.",
        caption: "Airflow: a DAG do caminho em lote, uma tarefa por camada, concluída de ponta a ponta.",
      },
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-2-dbt-linhagem",
        alt: "Grafo de linhagem do dbt: dimensões e tabelas da camada trusted alimentando a fato de vendas, que alimenta dez views de consumo.",
        caption: "dbt: a linhagem da fato de vendas, das dimensões às views de consumo.",
      },
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-3-airbyte-modos",
        alt: "Aba Schema de uma conexão do Airbyte: o modo de sincronização, a chave e o cursor de cada tabela.",
        caption: "Airbyte: o modo de cada tabela, exatamente como o YAML do repositório declara.",
      },
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-4-airflow-log",
        alt: "Log da tarefa dbt_staging na interface do Airflow: a saída do dbt, teste a teste, terminando em PASS=453 e código de saída 0.",
        caption: "Airflow: o log de uma tarefa de camada, com a saída inteira do dbt até o PASS=453.",
      },
    ],
  },
```

### `src/content/en.ts`, objeto `simpleCases["engenharia-governanca-dados"]` (entrada nova)

```ts
  "engenharia-governanca-dados": {
    eyebrow: "// completed · v1.0.0",
    title: "Data Engineering and Governance",
    lead: "A complete data flow over a synthetic omnichannel retailer, from the application database to the views an analyst queries, built to the standard of a corporate environment: the data is simulated, the engineering is not. Completed on 2026-10-04 and reproducible from the repository.",
    sections: [
      {
        heading: "What it is",
        body: "A reference project in data engineering and governance. Two transactional sources, one of them a deliberately faulty legacy system, feed a layered warehouse, a dimensional model and consumption views, with tests, lineage, sensitivity classification and access control from the first layer. All data is synthetic and generated deterministically: the same seed produces exactly the same data.",
      },
      {
        heading: "Data flow",
        list: [
          "Batch, orchestrated by Airflow: PostgreSQL → Airbyte → dbt, one task per layer, up to the consumption views. The full DAG runs in about 7 minutes.",
          "Streaming, for inventory: Debezium reads the PostgreSQL transaction log, Redpanda carries the events and Apache Beam writes each one exactly once and raises low-stock alerts. About 7 seconds from source to destination.",
          "Both paths load the same inventory ledger on purpose: a test reconciles one against the other on every build.",
          "Second source: the legacy system is captured whole, certified by content, cleaned by a catalog of known faults and stacked next to the main source; whatever fails goes to quarantine with its reason.",
        ],
      },
      {
        heading: "How the data is organized",
        list: [
          "Nine layers, each its own schema: raw, raw_legacy, staging, trusted, analytics, consumption, quarantine, governance and snapshots.",
          "A dimensional model with 10 facts and 15 dimensions, hash-based surrogate keys and SCD type 2 history through snapshots.",
          "16 consumption views, one per business question, with column contracts: the only place the analyst role can read.",
        ],
      },
      {
        heading: "Architecture decisions",
        body: "48 accepted ADRs, each one already stating its cloud counterpart. Among the choices that define the project: Airbyte, dbt and Airflow from the local phase; ingestion connections declared as code in YAML and Terraform; source schemas in SQLAlchemy and Alembic; each layer as a schema, never a table prefix; CDC and batch over the same ledger, reconciled; no record silently discarded; every legacy capture certified by content before use; and local validation done in parts, because the full environment does not fit on the machine at once.",
      },
      {
        heading: "Quality and governance",
        list: [
          "One command, make check, stops at the first failure: secret scanning, a dbt build with 700 data tests, classification and lineage in sync with the models, and 637 Python tests.",
          "Automatic reconciliation at every boundary between layers, from the sources to the facts.",
          "4,161 of 4,161 columns classified by sensitivity, derived through lineage from the models.",
          "Five login-less access roles, with permissions declared in dbt and tested by assuming each role: the analyst role reads the views and nothing else.",
          "The entire Git history scanned for credentials, with the handling of each finding recorded.",
        ],
      },
      {
        heading: "Reproducible and recoverable",
        body: "The closing stage rebuilt the whole cycle from a fresh clone, with databases, Airbyte and Airflow installed from scratch, measuring duration, memory and size at every step. The cycle found eight defects that an already-populated environment had hidden, all fixed at the source. A single recovery package, with the sources and the warehouse memory, was restored end to end in 17 minutes, including a new CDC snapshot.",
      },
      {
        heading: "How it was built",
        body: "Developed by github.com/alencardoug with Claude Code implementing and OpenAI Codex reviewing: the three final stages went through rounds of independent review, until the last round raised no findings. The architecture and every decision stayed with the author, recorded as ADRs; the work followed a plan with completion criteria per stage, full review of everything declarative (configuration, models, YAML) and sampled review of what is generated.",
      },
      {
        heading: "Outcome",
        list: [
          "Completed on 2026-10-04, tagged v1.0.0: 33 days and 306 commits since the first commit.",
          "A final validation, which ran every step of the study material on the machine, raised four decisions recorded in the repository, among them a double count in the balance behind the streaming alerts.",
          "It continues as the Data Engineering on GCP project, which replicates this flow in the cloud with Terraform.",
        ],
      },
    ],
    screenshotsHeading: "Visual evidence",
    screenshots: [
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-1-airflow-dag",
        alt: "Airflow interface showing the fluxo_batch DAG: all 13 tasks succeeded in two runs.",
        caption: "Airflow: the batch DAG, one task per layer, completed end to end.",
      },
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-2-dbt-linhagem",
        alt: "dbt lineage graph: dimensions and trusted-layer tables feed the sales fact, which feeds ten consumption views.",
        caption: "dbt: lineage of the sales fact, from dimensions to consumption views.",
      },
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-3-airbyte-modos",
        alt: "Schema tab of an Airbyte connection: sync mode, primary key and cursor for each table.",
        caption: "Airbyte: each table's sync mode, exactly as the repository's YAML declares it.",
      },
      {
        src: "/assets/projects/engenharia-governanca-dados/ss-4-airflow-log",
        alt: "Log of the dbt_staging task in the Airflow interface: dbt output test by test, ending in PASS=453 and exit code 0.",
        caption: "Airflow: the log of a layer task, with the full dbt output down to PASS=453.",
      },
    ],
  },
```

---

## 5. Projeto B — *cards*

### `src/content/pt.ts`, lista `projects` (substitui a entrada atual de `"engenharia-dados-gcp"`)

```ts
  {
    slug: "engenharia-dados-gcp",
    title: "Engenharia de Dados no GCP",
    status: "development",
    statusLabel: "A iniciar",
    description:
      "Replicação no Google Cloud, por Terraform, do projeto Engenharia e Governança de Dados: Cloud SQL, BigQuery, Datastream, Pub/Sub, Dataflow com o mesmo código Apache Beam e Cloud Composer, com a mesma governança aplicada como policy tags e custo estimado e medido.",
    technologies: [
      "Terraform",
      "GCP",
      "BigQuery",
      "Cloud SQL",
      "Datastream",
      "Pub/Sub",
      "Dataflow",
      "Cloud Composer",
      "dbt",
    ],
    appUrl: null,
    githubUrl: "https://github.com/alencardoug/mvp_eng_dados_1",
    caseStudyUrl: "/projects/engenharia-dados-gcp/",
  },
```

Sem `metrics`: o campo é opcional, e o projeto ainda não tem número medido. O `githubUrl` aponta para o
mesmo repositório, porque o plano faz a replicação nele (Etapa 13, pasta `terraform/`); troque se um
repositório próprio for criado.

### `src/content/en.ts`, lista `projects`

```ts
  {
    slug: "engenharia-dados-gcp",
    title: "Data Engineering on GCP",
    status: "development",
    statusLabel: "Upcoming",
    description:
      "Replicating the Data Engineering and Governance project on Google Cloud with Terraform: Cloud SQL, BigQuery, Datastream, Pub/Sub, Dataflow running the same Apache Beam code and Cloud Composer, with the same governance applied as policy tags and cost both estimated and measured.",
    technologies: [
      "Terraform",
      "GCP",
      "BigQuery",
      "Cloud SQL",
      "Datastream",
      "Pub/Sub",
      "Dataflow",
      "Cloud Composer",
      "dbt",
    ],
    appUrl: null,
    githubUrl: "https://github.com/alencardoug/mvp_eng_dados_1",
    caseStudyUrl: "/en/projects/engenharia-dados-gcp/",
  },
```

## 6. Projeto B — estudo de caso

### `src/content/pt.ts`, objeto `simpleCases["engenharia-dados-gcp"]` (substitui a entrada atual)

```ts
  "engenharia-dados-gcp": {
    eyebrow: "// a iniciar",
    title: "Engenharia de Dados no GCP",
    lead: "A continuação do projeto Engenharia e Governança de Dados: levar para o Google Cloud, por Terraform, o fluxo que já roda e foi validado localmente, preservando o desenho, os testes e a governança. O ponto de partida é um projeto concluído, com cada decisão já acompanhada da sua contrapartida na nuvem.",
    sections: [
      {
        heading: "O que é",
        body: "Replicar na nuvem um fluxo de dados completo: duas origens transacionais, ingestão em lote e contínua, transformação em camadas, modelo dimensional e views de consumo. O objetivo não é reescrever, e sim trocar as pontas: o mesmo dbt, o mesmo código Apache Beam e a mesma classificação de sensibilidade, agora sobre serviços gerenciados.",
      },
      {
        heading: "Do local para a nuvem",
        list: [
          "PostgreSQL em contêiner → Cloud SQL for PostgreSQL.",
          "Armazém em nove schemas → BigQuery, um dataset por camada, com particionamento e clustering nas fatos.",
          "Debezium sobre Kafka Connect → Datastream; Redpanda → Pub/Sub; Beam local → o mesmo pipeline no Dataflow.",
          "Airflow local → Cloud Composer; Airbyte local → Airbyte em contêiner, os dois criados e destruídos na mesma janela de uso.",
          "Papéis do PostgreSQL → IAM por dataset e policy tags aplicadas a partir da classificação declarada no dbt.",
          "Catálogo e linhagem do dbt → publicados no Dataplex; .env → Secret Manager; Docker Compose → Terraform.",
        ],
      },
      {
        heading: "Ponto de partida",
        body: "O projeto local está concluído (v1.0.0) e reproduzível a partir do repositório, com 48 ADRs que já declaram a contrapartida na nuvem de cada escolha e um mapa de paridade item a item. Três decisões da fase já estão tomadas: Composer e Airbyte vivem só durante a janela de uso, para conter custo; as policy tags são aplicadas por um fluxo automatizado, a partir do YAML do dbt; e a concorrência entre lote e contínuo, que não cabia na máquina local, é medida aqui.",
      },
      {
        heading: "Critérios de conclusão",
        list: [
          "Todo item do mapa de paridade com o equivalente provisionado por Terraform, e cada terraform plan revisado antes do apply.",
          "Particionamento, clustering, retenção e políticas definidos antes de provisionar.",
          "Policy tag em cada coluna sensível, com acesso negado comprovado e sem credencial de longa duração.",
          "Custo estimado e custo real registrados para cada janela de uso.",
          "Lote e contínuo de pé ao mesmo tempo, com tamanho, tempo e custo medidos e a reconciliação entre os dois caminhos passando.",
          "Paridade funcional com a fase local demonstrada.",
        ],
      },
      {
        heading: "Estado",
        body: "A iniciar. O projeto local que serve de base foi concluído em 04/10/2026; a fase de nuvem começa com a autorização do autor e com as quatro decisões que a validação final da fase local deixou abertas.",
      },
    ],
  },
```

### `src/content/en.ts`, objeto `simpleCases["engenharia-dados-gcp"]` (substitui a entrada atual)

```ts
  "engenharia-dados-gcp": {
    eyebrow: "// upcoming",
    title: "Data Engineering on GCP",
    lead: "The continuation of the Data Engineering and Governance project: taking to Google Cloud, with Terraform, the flow that already runs and was validated locally, while keeping its design, tests and governance. The starting point is a completed project in which every decision already states its cloud counterpart.",
    sections: [
      {
        heading: "What it is",
        body: "Replicating a complete data flow in the cloud: two transactional sources, batch and streaming ingestion, layered transformation, a dimensional model and consumption views. The goal is not a rewrite but a change of endpoints: the same dbt project, the same Apache Beam code and the same sensitivity classification, now on managed services.",
      },
      {
        heading: "From local to cloud",
        list: [
          "PostgreSQL in a container → Cloud SQL for PostgreSQL.",
          "A nine-schema warehouse → BigQuery, one dataset per layer, with partitioning and clustering on the facts.",
          "Debezium on Kafka Connect → Datastream; Redpanda → Pub/Sub; local Beam → the same pipeline on Dataflow.",
          "Local Airflow → Cloud Composer; local Airbyte → Airbyte in a container, both created and destroyed within the same usage window.",
          "PostgreSQL roles → IAM per dataset and policy tags applied from the classification declared in dbt.",
          "dbt catalog and lineage → published to Dataplex; .env → Secret Manager; Docker Compose → Terraform.",
        ],
      },
      {
        heading: "Starting point",
        body: "The local project is complete (v1.0.0) and reproducible from the repository, with 48 ADRs that already state the cloud counterpart of each choice and an item-by-item parity map. Three decisions for this phase are already made: Composer and Airbyte live only during the usage window, to keep cost down; policy tags are applied by an automated flow from the dbt YAML; and the concurrency between batch and streaming, which did not fit on the local machine, is measured here.",
      },
      {
        heading: "Completion criteria",
        list: [
          "Every item of the parity map provisioned with Terraform, with each terraform plan reviewed before apply.",
          "Partitioning, clustering, retention and policies defined before provisioning.",
          "A policy tag on every sensitive column, with denied access proven and no long-lived credentials.",
          "Estimated and actual cost recorded for each usage window.",
          "Batch and streaming running at the same time, with size, time and cost measured and the reconciliation between both paths passing.",
          "Functional parity with the local phase demonstrated.",
        ],
      },
      {
        heading: "Status",
        body: "Upcoming. The local project it builds on was completed on 2026-10-04; the cloud phase starts with the author's go-ahead and with the four decisions the local phase's final validation left open.",
      },
    ],
  },
```

---

## 7. Páginas

**Projeto A, páginas novas.** Copie `src/app/projects/engenharia-dados-gcp/page.tsx` para
`src/app/projects/engenharia-governanca-dados/page.tsx` (e o mesmo em `src/app/en/projects/`), trocando
o nome da função, `slug`, `ptPath` e os metadados:

```ts
// src/app/projects/engenharia-governanca-dados/page.tsx
  ptPath: "/projects/engenharia-governanca-dados",
  title: "Engenharia e Governança de Dados",
  description:
    "Estudo de caso: fluxo de dados de ponta a ponta com Airbyte, dbt, Airflow e CDC com Debezium, Redpanda e Apache Beam, governança desde a primeira camada, concluído e reproduzível (v1.0.0).",
// e no componente: slug="engenharia-governanca-dados" ptPath="/projects/engenharia-governanca-dados"
```

```ts
// src/app/en/projects/engenharia-governanca-dados/page.tsx
  title: "Data Engineering and Governance",
  description:
    "Case study: an end-to-end data flow with Airbyte, dbt, Airflow and CDC with Debezium, Redpanda and Apache Beam, governance from the first layer, completed and reproducible (v1.0.0).",
```

Confira na página EN atual como ela passa o `locale` e o caminho, e repita.

**Projeto B, páginas atuais.** Só os metadados mudam:

```ts
// src/app/projects/engenharia-dados-gcp/page.tsx
  title: "Engenharia de Dados no GCP",
  description:
    "Projeto a iniciar: replicação no Google Cloud, por Terraform, de um fluxo de dados local já concluído, com BigQuery, Datastream, Pub/Sub, Dataflow e Cloud Composer e a mesma governança como policy tags.",
```

```ts
// src/app/en/projects/engenharia-dados-gcp/page.tsx
  title: "Data Engineering on GCP",
  description:
    "Upcoming project: replicating a completed local data flow on Google Cloud with Terraform, using BigQuery, Datastream, Pub/Sub, Dataflow and Cloud Composer, with the same governance as policy tags.",
```

Se o site tiver *sitemap* ou lista de rotas, inclua as duas páginas novas do projeto A.

---

## 8. `docs/copy-deck.md` — substitui a seção "Projeto 02"

```markdown
## Projeto 02 — Engenharia e Governança de Dados

**Status:** Concluído — fase local, `v1.0.0`, 04/10/2026.

### Resumo
Fluxo de dados de ponta a ponta sobre um varejo omnichannel sintético: do PostgreSQL ao modelo
dimensional e às views de consumo, com Airbyte, dbt e Airflow no lote, CDC com Debezium, Redpanda e
Apache Beam no estoque, e governança desde a primeira camada.

### Natureza do projeto
Desenvolvido por `github.com/alencardoug` com suporte de Claude Code (implementação) e OpenAI Codex
(revisão independente das Etapas 10 a 12). Dados 100% sintéticos.

### Evidências informadas (fonte: repositório mvp_eng_dados_1, 04/10/2026)
- Primeira versão em 33 dias (01/09/2026 → 04/10/2026).
- 306 commits até a v1.0.0.
- 48 ADRs aceitos, cada um com a contrapartida na nuvem declarada.
- 637 testes Python e 700 testes de dados no dbt (build de 905 nós).
- 40 tabelas de origem, 9 camadas, 10 fatos, 15 dimensões, 16 views de consumo.
- 4.161 de 4.161 colunas classificadas por sensibilidade.
- Ciclo do zero refeito e medido num clone novo (25/09/2026); restauração completa em 17 minutos.

### Stack
PostgreSQL, Airbyte (em Kubernetes local), dbt, Airflow, Debezium sobre Kafka Connect, Redpanda,
Apache Beam, Terraform, Docker, Python (SQLAlchemy, Alembic, uv).

### Links
- GitHub: https://github.com/alencardoug/mvp_eng_dados_1
- Aplicação: não há (projeto de dados; manter `appUrl: null`).

---

## Projeto 02b — Engenharia de Dados no GCP

**Status:** A iniciar. Pré-requisito: autorização do autor (Etapa 13 do plano do mvp_eng_dados_1).

### Resumo
Replicação no Google Cloud, por Terraform, do Projeto 02: Cloud SQL, BigQuery, Datastream, Pub/Sub,
Dataflow com o mesmo código Apache Beam e Cloud Composer, com a mesma governança aplicada como policy
tags.

### Já decidido (fonte: ADR-0024, ADR-0025, ADR-0046 do mvp_eng_dados_1)
- Composer e Airbyte em contêiner, criados e destruídos na mesma janela de uso.
- Policy tags aplicadas por fluxo automatizado, a partir do YAML do dbt.
- A concorrência entre lote e contínuo é medida na nuvem.

### Evidências
Nenhuma ainda. Não publicar custo, prazo ou número antes de medidos.

### Links
- GitHub: https://github.com/alencardoug/mvp_eng_dados_1 (mesmo repositório, salvo se um próprio for criado)
- Aplicação: não há.
```

## 9. `docs/content-backlog.md`

A seção "Projeto Engenharia de Dados GCP" passa a ser do projeto B, e todos os itens dela continuam em
aberto, exceto "Criar repositório" (o plano usa o mesmo). Para o projeto A, uma seção nova com tudo
marcado: nome, escopo, repositório, stack, arquitetura, primeira versão demonstrável (`v1.0.0`) e,
quando as telas forem copiadas, evidências e *screenshots*.

## 10. Telas do projeto A

Saem da validação de 04/10/2026, já inspecionadas uma a uma (nenhuma credencial visível), em
`data/medicoes/material_estudo/telas/` neste repositório, fora do Git. O componente do portfólio espera,
para cada `src`, um `.jpg` e um `.webp` em `public/assets/projects/engenharia-governanca-dados/`, com 1366
px de largura (as originais têm 1440 × 900; basta redimensionar).

| Destino (sem extensão) | Origem |
|---|---|
| `ss-1-airflow-dag` | `telas/airflow_02_fluxo_batch_grid.png` |
| `ss-2-dbt-linhagem` | `telas/dbt_docs_linhagem_vizinhos_fato_vendas.png` |
| `ss-3-airbyte-modos` | `telas/airbyte_03_schema_modos.png` |
| `ss-4-airflow-log` | `telas/airflow_06_log_dbt_staging.png` |

O projeto B não tem tela, porque ainda não existe nada provisionado.

## 11. Opcional — a capacidade "Engenharia de Dados"

A seção "Capacidades" do portfólio lista hoje, como evidência de Engenharia de Dados, "Python, SQL,
PostgreSQL, BigQuery, GCP, Azure". Com o projeto A, Airflow, dbt, Airbyte e CDC (Debezium, Apache Beam)
passam a ter evidência pública. A mudança está em `docs/copy-deck.md` e no conteúdo da seção em
`pt.ts`/`en.ts`; pela regra do portfólio, mexer em capacidades é decisão sua.
