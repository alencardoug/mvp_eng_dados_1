# Plano — Etapa 13: replicação no GCP com Terraform (M6)

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item, como o plano da Etapa 12 saiu. Escrito em 06/11/2026 sobre `8309b66`
> (`main`, `v1.1.0` aceita), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: **[medido]** tem saída de comando ou página oficial lida por trás;
> **[planejado]** é intenção; **[estimado]** é número que ninguém mediu. Não se misturam (P5).
>
> **Revisão 1 — 06/11/2026.** Primeira versão, com as decisões do Owner de 06/11 (§2) e as
> perguntas abertas (§4). Ainda não revisada.

---

## 0. O prazo manda

A Etapa 13 foi **autorizada pelo Owner em 06/11/2026**. A conta GCP está em **Free Trial, não
convertida**, e o prazo da avaliação termina em **sete dias** — tudo tem de ser **ativado e
desativado** antes disso. Falhar no desmonte é falhar no projeto (palavras do Owner).

Daí as três regras que se sobrepõem a qualquer outra coisa neste plano:

1. **O desmonte conferido não se negocia.** Nenhum recurso cobrável de pé depois de
   **quinta-feira, 12/11/2026, 18:00**. Sexta, 13/11, é folga — não é janela.
2. **Encurta-se o escopo, nunca a margem.** Se um bloco atrasar, o que falta vira pendência
   registrada (P5); a janela cara não se estende.
3. **Só o barato se desenvolve com o taxímetro ligado.** BigQuery, Cloud Storage, IAM e
   taxonomias custam centavos e podem nascer cedo para o desenvolvimento. Cloud SQL, GKE, Composer
   e Dataflow nascem só na janela (§6).

O que a Free Trial muda **[medido, 06/11/2026]**:

| Fato | Fonte | Efeito no plano |
|---|---|---|
| Sem aumento de cota; sem GPU, Windows, Marketplace | [free-cloud-features](https://docs.cloud.google.com/free/docs/free-cloud-features) | o Airbyte entra por Helm, não pelo Marketplace; o dimensionamento cabe na cota que existe |
| Cota `CPUS_ALL_REGIONS` = **32**; `IN_USE_ADDRESSES` = 8 por região | `gcloud compute project-info describe` no projeto `analisador-de-risco` (o projeto novo herda a da conta — a conferir no G0) | GKE + Dataflow + Debezium cabem com folga; o Composer 3 roda no projeto da Google |
| Fim da avaliação: recursos **parados**, 30 dias de carência, depois **apagados** | idem | é rede de segurança contra cobrança, **não** é o desmonte — o critério da etapa exige o nosso |
| O crédito não paga a API do Gemini | idem | o Gemini usado como verificador não consome o crédito |
| Nove projetos dividem a mesma conta de faturamento | `gcloud billing accounts list`, `gcloud projects list` | o crédito restante é da conta, não do projeto — **conferir no G0** |

---

## 1. Escopo

**Todos os critérios de conclusão da Etapa 13** no
[plano](docs/plano_de_desenvolvimento.md#etapa-13--replicação-no-gcp-com-terraform--m6) — decisão do
Owner de 06/11/2026, que recusou o corte de escopo preventivo. O mapa critério → bloco:

| Critério | Bloco |
|---|---|
| Todo item do [mapa de paridade](docs/arquitetura.md#5-mapa-de-paridade-local--gcp) com equivalente provisionado | G0–G5, conferido no G6 |
| `terraform plan` revisado antes de cada `apply` | G3 (rito do §6.2) |
| Particionamento, *clustering*, retenção e políticas definidos antes do provisionamento | G1 (fatos), G3 (*datasets*, *buckets*) |
| *Policy tag* em cada coluna sensível pelo fluxo do ADR-0025, acesso negado comprovado, sem credencial longeva | G4 |
| Composer e Airbyte criados e **destruídos** na mesma janela, custo estimado e real | G3, G6, G7 |
| *Batch* e *streaming* de pé ao mesmo tempo, tamanho/tempo/custo, `caminhos_de_ingestao_reconciliam` | G2, G6 |
| Paridade funcional com a fase local demonstrada | G6 (§7) |
| Artefato: publicação dos metadados no Dataplex | G5 |
| Artefato: estimativa de custo por serviço | G6, registrado na Capacidade |

**Fora:** o alto volume (D68, §2), a operação continuada e o CI/CD além do fluxo das *policy tags*
([Termo](Abertura_de_projeto.md) §4), e a recuperação pelo pacote (a [Capacidade
§3](docs/capacidade_e_recuperacao.md#3-ponto-único-de-recuperação) não tem linha no mapa de paridade).

---

## 2. Decisões já tomadas (06/11/2026)

- **Autorização da Etapa 13.** Registrada no Termo (versão 1.3, §11), no plano e nas Pendências.
- **D68 — a fase GCP roda no fator `dev`.** Nenhum critério da Etapa 13 nem do Termo §6 exige
  volume alto; a premissa existia no Termo §7, no ADR-0014 e no ADR-0016. Sai do M6 e fica para a
  operação continuada. Efeitos: emenda curta no Termo §7; nota datada no ADR-0014 e no ADR-0016
  ("a revisão sob volume não aconteceu na Etapa 13"); o fator `cloud` do `geracao.yml` continua
  sem número. As medições da janela são no `dev` e dizem isso.
- **Escopo inteiro** (§1), com revisões em **rodadas com prazo**: o plano fecha a revisão até
  domingo, 08/11 (meta: sábado, 07/11); o Terraform tem uma rodada no `plan` antes do primeiro
  `apply` caro. Achado bloqueante sempre para tudo.
- **Gemini como verificador de fatos do GCP**, chamado pelo Claude Code; **Codex como revisor do
  plano contra o repositório**. As respostas do Gemini entram com URL oficial e grau
  (`CONFIRMADO`/`INFERIDO`/`NÃO ENCONTRADO`); nenhuma vira fato no plano sem conferência.

---

## 3. Achados de abertura — o que o mapa de paridade não aguenta

Três lacunas que a documentação oficial expõe **[medido, 06/11/2026]**. Cada uma tem decisão na §4.

### 3.1 O Datastream não entrega em Pub/Sub

A [Arquitetura §5](docs/arquitetura.md#5-mapa-de-paridade-local--gcp) declara Datastream →
Pub/Sub → `ReadFromPubSub`. Os destinos do Datastream são **BigQuery, Cloud Storage e tabelas
Iceberg no BigQuery** ([destinations](https://docs.cloud.google.com/datastream/docs/destinations));
Pub/Sub não é destino. O capítulo 07 do `NAVEGANDO_GCP` já avisava; o mapa não foi corrigido. E o
formato do Datastream não é o envelope do Debezium que o Beam lê hoje
(`src/mvp_ed1/streaming/`). → **D69**.

### 3.2 A retenção travada do livro retido impede o desmonte

O mapa diz, para o livro retido do [ADR-0050](docs/adr/0050-guardar-a-memoria-do-legado-num-livro-retido.md):
"*bucket* com escrita condicionada e retenção travada". Travar a retenção é **irreversível**, põe um
*lien* no projeto que **bloqueia apagá-lo**, e o *bucket* só sai quando todo objeto vence a
retenção ([bucket-lock](https://docs.cloud.google.com/storage/docs/bucket-lock)). Implantado como
está escrito, o desmonte falha. → **D70**.

### 3.3 O destino BigQuery do Airbyte pede credencial longeva no modo recomendado

O destino BigQuery do Airbyte recomenda *staging* em GCS, que exige **chave HMAC**; o modo
*Batched Standard Inserts* dispensa *staging*, e o `credentials_json` é opcional no OSS, com ADC
desde a 1.1.14 ([destination-bigquery](https://docs.airbyte.com/integrations/destinations/bigquery)).
O ADR-0025 proíbe credencial longeva no fluxo das *tags*; a regra 1 do `CLAUDE.md`, no repositório.
→ **D72**.

### 3.4 Uma suspeita a conferir antes do G4

O dbt materializa `table` com `create or replace`. Se a substituição apagar as *policy tags* das
colunas, o fluxo do ADR-0025 — disparado "quando o YAML muda" — deixa a tabela desprotegida a cada
`dbt build` até o próximo disparo. **Não verificado**; é pergunta para o Gemini (Q16) e teste no G4
antes de qualquer desenho. → **D71**.

---

## 4. Decisões para o Owner

Cada uma com recomendação. As que trocam componente ou mudam o mapa de paridade viram ADR
(regra 5 do `CLAUDE.md`) no *commit* da revisão 2.

### D69 — o caminho quente até o Pub/Sub (ADR novo)

| Opção | A favor | Contra |
|---|---|---|
| **(a) Debezium Server com *sink* Pub/Sub**, num *pod* do mesmo GKE do Airbyte — **recomendada** | o *sink* `pubsub` é oficial (Debezium 3.7, [debezium-server](https://debezium.io/documentation/reference/stable/operations/debezium-server.html)); mesma configuração de conector, mesmo formato JSON, o Beam muda só a leitura (`ReadFromPubSub`, como o mapa já diz); custo marginal num cluster que já existe | sai o Datastream; o CDC não é gerenciado; a igualdade do envelope com o Kafka Connect **não está escrita** na página — teste no G2 |
| (b) Datastream → Cloud Storage → notificação Pub/Sub → Beam | serviço gerenciado; é o padrão documentado pela Google | o Beam passa a ler **arquivos** (Avro/JSON) com outro metadado: reescrita do *parser* e da ordenação, desenvolvimento dentro do prazo |
| (c) Datastream → BigQuery direto | o mais simples de operar | some o Beam, a ramificação de alerta e o critério de processamento contínuo: paridade perdida |

### D70 — retenção do livro retido sem trava na janela (emenda ao ADR-0050)

**Recomendação:** política de retenção **sem trava** e curta na janela, removida no desmonte antes
de apagar o *bucket*; a escrita condicionada (`ifGenerationMatch=0`) é exercitada de verdade, que é
o que dá a semântica de "o nome existe, falha". A trava fica declarada como contrapartida de
produção, **não medida**. Não há alternativa aceitável: travar quebra a regra 1 do §0.

### D71 — *policy tags* que sobrevivem ao `dbt build`

Depende da §3.4. Se a substituição apagar as *tags*:

| Opção | A favor | Contra |
|---|---|---|
| **(a) o dbt aplica as *tags*** pela propriedade `policy_tags` do `dbt-bigquery`, gerada do mesmo YAML de classificação; o fluxo do ADR-0025 cria e mantém taxonomia e *tags* — **recomendada, se a §3.4 confirmar** | a coluna nasce protegida em cada *build*; a divergência continua impossível | emenda ao ADR-0025 ("fluxo único" passa a ter duas metades); gerar o `policy_tags` é derivado e se revisa por amostragem |
| (b) o fluxo roda também como última tarefa da DAG | o ADR-0025 fica como está | janela desprotegida entre o *build* e a tarefa; o *build* manual (fora da DAG) não aplica |

### D72 — Airbyte → BigQuery sem chave

**Recomendação:** *Batched Standard Inserts* com a identidade do *pod* (Workload Identity do GKE),
sem `credentials_json` e sem HMAC. No volume `dev` o modo basta. Alternativa descartada: *staging*
em GCS com HMAC no Secret Manager — credencial longeva, e para um volume que não precisa dela.
**A conferir:** que o conector aceita Workload Identity no GKE (a página diz ADC, não Workload
Identity) — Q17.

### D73 — região e versões

**Recomendação:** tudo em `us-central1` (mais barata, todos os serviços disponíveis; o dado é
sintético, latência e residência não pesam); **Composer 3** com
`composer-3-airflow-3.2.2-build.9` — a mesma versão de Airflow da fase local
(`docker/airflow.Dockerfile`), publicada em 20/10/2026
([composer-versions](https://docs.cloud.google.com/composer/docs/composer-versions)), ambiente
*small*; Airbyte pelo *chart* `2.3.0`, o mesmo fixado em `AIRBYTE_CHART_VERSION`; GKE **Standard**
com um *pool* pequeno, ou Autopilot se a Q7 confirmar suporte — a decidir pelo Gemini.

### D74 — projeto dedicado e as três camadas de desmonte

**Recomendação:** um **projeto novo só para a Etapa 13** (`mvp-ed1-gcp-<sufixo>`), ligado à conta de
faturamento da avaliação. O desmonte tem três camadas, nesta ordem:

1. `terraform destroy` ordenado (§6.3), seguido do inventário de resíduos;
2. **desligar o faturamento do projeto** (`gcloud billing projects unlink`) — para qualquer serviço
   cobrável que tenha escapado do estado;
3. **apagar o projeto** (`gcloud projects delete`), **com confirmação explícita do Owner na hora** —
   é o que garante que nada sobrou.

O estado do Terraform fica **local**, em `terraform/` (já coberto por `terraform.tfstate*` no
`.gitignore`), com cópia em `data/` a cada `apply`. Um *backend* em GCS no mesmo projeto morreria
com ele; num projeto à parte seria mais um recurso a desmontar. Migrar para *backend* remoto é um
`terraform init -migrate-state` quando houver operação continuada — a porta fica aberta.

### D43 — a guarda de identidade (adiada para cá em 16/09/2026)

**Recomendação:** não decidir antes da janela. No G1 o alvo BigQuery usa `SAFE_CAST` pelo
*dispatch* da macro `chave_canonica`, o alvo PostgreSQL mantém a gramática, e a paridade é
**medida** com a lista de formas que o teste já tem. A decisão vem com o número, depois da janela.

### Pequenas, sem ADR (registradas aqui e nas Pendências)

- **Uma árvore dbt, dois alvos** (`local` PostgreSQL e `gcp` BigQuery), com `adapter.dispatch` nas
  macros e `cast()` no lugar de `::`; nada de *fork*. O `make check` local continua verde a cada
  *commit*, gateado no código de saída do `make check-offline`.
- **Carga de desenvolvimento:** enquanto o Airbyte do GKE não existe, o bruto do armazém local é
  copiado para o BigQuery para o dbt ter o que transformar. É ferramenta de desenvolvimento, **não
  é evidência**; some antes da janela, e a janela carrega pelo caminho real.
- **O *job* Dataflow vive fora do estado do Terraform** (é lançado pelo SDK do Beam); o desmonte o
  drena e cancela explicitamente e o inventário confere.

---

## 5. Os blocos

Cada bloco diz o que entrega, como se prova e o que fica para depois. Os nomes de arquivo são
**[planejado]**.

### G0 — fundação (sábado, 07/11)

Projeto dedicado, ligação à conta de faturamento, **orçamento com alertas em US$ 25, 50 e 75** no
projeto e conferência do **crédito restante da conta** (passo do Owner na consola), APIs ativadas,
`gcloud auth application-default login` (passo do Owner), esqueleto de `terraform/` (módulos
`fundacao`, `rede`, `iam`, `bigquery`, `storage`, `cloud_sql`, `pubsub`, `gke`, `airbyte`,
`composer`, `streaming`, `governanca`), alvos `make gcp-*` com *preflight* que recusa sem o projeto
certo no ambiente. **Prova:** `terraform plan` do módulo `fundacao` limpo; cota do projeto lida.

### G1 — dbt em dois alvos (sábado a domingo)

Alvo `gcp` em `dbt/profiles.yml` (BigQuery, OAuth/ADC, sem chave), nove *datasets* pelo
`generate_schema_name`; os ~107 modelos com sintaxe só do PostgreSQL convertidos (a maior parte é
`::` no *staging* e no *trusted*); as 13 macros com *dispatch* onde preciso; `partition_by` e
`cluster_by` nas fatos, só no alvo `gcp`; `+grants` traduzido para papéis do BigQuery; contratos
das views mantidos; `persist_docs` ligado no alvo `gcp` (alimenta o G5). **Prova:** `dbt build
--target gcp` verde sobre a carga de desenvolvimento, com os testes de qualidade e as
reconciliações entre camadas passando; `make check` local verde.

### G2 — o código Python na nuvem (sábado a segunda)

1. **Certificado do legado** no BigQuery: carga em *staging* + `MERGE` pela chave
   `(tentativa, tabela)`, com os testes de API simulada (resposta parcial, retorno perdido) que o
   mapa exige.
2. **Livro retido** em Cloud Storage com `ifGenerationMatch=0` e retenção sem trava (D70); *locks*
   no Cloud SQL soltos só depois de o *insert* no BigQuery confirmar.
3. **Caminho quente:** fonte `ReadFromPubSub` e *sink* BigQuery no Beam, configuração do Debezium
   Server (se D69 = a), lançamento no Dataflow por alvo `make`.
4. **DAG portável:** a mesma `fluxo_batch.py` lendo do ambiente a URL do Airbyte, o alvo dbt e o
   destino do certificado; o pacote `mvp_ed1` e o projeto dbt no *bucket* do Composer; `dbt-core
   1.12.3` + `dbt-bigquery` como pacotes PyPI do ambiente — **conferido contra a lista de pacotes da
   imagem do Composer antes da janela** (conflito de dependência descoberto na janela custa horas
   de Composer).

**Prova:** testes locais com API simulada verdes; o Beam lendo de um tópico Pub/Sub real
(barato) e gravando no BigQuery antes da janela.

### G3 — Terraform (escrita sábado a domingo; `apply` barato na segunda, caro na terça)

Os módulos do G0 completos. Rede com IP privado para o Cloud SQL; Cloud SQL com
`deletion_protection = false` e sem *backup* automático retido (resíduo cobrável); *datasets* com
retenção e expiração declaradas; *buckets* com `force_destroy` onde não houver retenção;
GKE com Workload Identity; Airbyte por `helm_release`; Composer 3 por último. Rodada única do Codex
sobre o `plan` caro na segunda. **Prova:** `plan` revisado e salvo antes de cada `apply` (§6.2).

### G4 — *policy tags* (segunda)

Taxonomia e *tags* criadas pelo fluxo do ADR-0025, disparado por mudança no YAML de classificação
(`.github/workflows/`), autenticado por *Workload Identity Federation* com *attribute condition* no
repositório, permissão só de *policy tags*. Primeiro, o teste da §3.4 (D71). **Prova:** cada coluna
sensível com *tag*; consulta por uma conta sem `datacatalog.categoryFineGrainedReader` **negada** e
com ela permitida, as duas com o *log* de auditoria; nenhuma chave de conta de serviço criada
(`gcloud iam service-accounts keys list` vazio para todas).

### G5 — catálogo e linhagem (segunda, se der; terça no mais tardar)

Descrições e `domain`/`owner` dos `.yml` no catálogo (o Data Catalog está em transição para o
*Knowledge Catalog*; a Policy Tag Manager **não** está descontinuada —
[column-level-security](https://docs.cloud.google.com/bigquery/docs/column-level-security-intro));
linhagem por coluna do mesmo módulo do [Dicionário §3](docs/dicionario_de_dados.md#3-linhagem)
enviada à Data Lineage API como eventos OpenLineage. **Prova:** a linhagem de uma coluna de
`consumption` até a origem visível na consola.

### G6 — a janela (terça 08:00 → quarta 18:00)

O roteiro do §6.1. **Prova:** o registro de execução e as medições da §7.

### G7 — desmonte (quarta 18:00 → quinta 18:00)

O rito do §6.3. **Prova:** inventário de resíduos vazio, faturamento desligado, projeto apagado.

### G8 — documentação e aceite (quinta a sexta)

[Arquitetura §5](docs/arquitetura.md#5-mapa-de-paridade-local--gcp) corrigida (D69, D70); ADRs
novos; [Capacidade](docs/capacidade_e_recuperacao.md) com custo estimado e real por serviço (o real
lido depois de 24–48 h de atraso do faturamento); dicionário, catálogo e linhagem; o capítulo 07 do
`NAVEGANDO_GCP` alinhado; a V1 da [Pendências](docs/pendencias.md) com o que a Etapa 13 exercitou
dela; *tag* `v2.0.0` (D47) no aceite.

---

## 6. A janela

### 6.1 Cronograma

| Quando | O quê | Custo [estimado] |
|---|---|---|
| sáb 07 | revisão do plano (Codex r1 e r2, Gemini); G0; G1 e G2 começam; BigQuery e GCS de desenvolvimento | centavos |
| dom 08 | **revisão do plano encerrada**; G1, G2, G3 escritos; `plan` completo | centavos |
| seg 09 | Codex no `plan` caro; `apply` barato (rede, Cloud SQL, Pub/Sub, IAM, BigQuery, GCS, taxonomia, WIF); dados gerados no Cloud SQL; G4; G5 | ~US$ 5 |
| **ter 10, 08:00** | `apply` caro: GKE + Airbyte, Debezium Server, Dataflow, **Composer por último**; `fluxo_batch` de ponta a ponta; *streaming* simultâneo | ~US$ 20–30/dia |
| **qua 11, 12:00** | **ponto de decisão:** o que não rodou vira pendência; não há extensão | |
| qua 11, 18:00 | desmonte caro: Composer primeiro, Dataflow drenado, GKE | |
| qui 12 | desmonte barato; inventário; faturamento desligado; projeto apagado (Owner) — **limite 18:00** | ~US$ 5 |
| sex 13 | folga; custo real; documentação; aceite | |

A estimativa de US$ 20–30/dia é a da
[conversa de custos](CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md) §7, de 15/09, **não
conferida** contra a tabela de preço atual (Q5). A janela cara de ~34 h fica em ~US$ 30–45 mais o
barato, dentro do crédito **se o crédito restante da conta passar de US$ 100** — conferido no G0.

### 6.2 O rito de cada `apply`

`terraform plan -out` salvo em `data/medicoes/etapa_13/`, lido inteiro (contagem de criar/alterar/
destruir conferida contra o esperado do módulo), aprovado pelo Owner, e só então `apply` do arquivo
salvo. Nenhum `apply` sem `-out`. Nenhum `-auto-approve`.

### 6.3 O rito do desmonte

1. Parar o produtor; drenar e **cancelar o *job* Dataflow** (`gcloud dataflow jobs list` vazio de
   ativos).
2. `terraform destroy` do caro (Composer, GKE com Airbyte e Debezium), depois do barato.
3. Remover a política de retenção sem trava do *bucket* do livro (D70) antes de apagá-lo.
4. **Inventário de resíduos:** `gcloud asset search-all-resources --scope=projects/<id>` e as
   listas por serviço que sobrevivem a *destroy* mal ordenado — discos, *snapshots*, *backups* do
   Cloud SQL, *bucket* do Composer, *jobs* Dataflow, IPs estáticos, *load balancers* do GKE.
   Esperado: vazio, exceto o que o projeto cria por padrão.
5. `gcloud billing projects unlink <id>`; conferir `billingEnabled: false`.
6. Com o Owner: `gcloud projects delete <id>`.
7. Sexta: o relatório de faturamento por serviço lido e registrado como custo real.

---

## 7. Paridade funcional — o que se mede na janela

Paridade é o mesmo dado de origem dando o mesmo resultado nas duas fases, não o mesmo nome de
serviço. Com o gerador determinístico (mesma `seed`, mesma `as_of_date`, fator `dev`):

- contagens por camada iguais às da fase local na mesma geração, e as reconciliações entre camadas
  passando no BigQuery;
- os testes de qualidade do dbt passando nos dois alvos (contagem de PASS comparada);
- as views de `consumption` com o mesmo resultado (soma de controle por view);
- `caminhos_de_ingestao_reconciliam` passando com *batch* e *streaming* simultâneos;
- tempo de cada sincronização, do `dbt build` e da latência do caminho quente; tamanho por
  *dataset*; custo por serviço.

O que não se medir fica escrito como **não medido**, com o motivo.

---

## 8. Premissas e o não verificado

- O prazo exato da Free Trial (dia **e hora**) — o Owner confere na consola no G0.
- O crédito restante da conta, dividido com oito outros projetos.
- A cota do projeto novo (lida no G0; não pode ser aumentada).
- Envelope do Debezium Server em Pub/Sub igual ao do Kafka Connect (D69a) — testado no G2.
- Airbyte com Workload Identity (D72), Airbyte em Autopilot (D73), `dbt-bigquery` com `dbt-core
  1.12.3`, conflito de pacotes no Composer, preço atual do Composer 3 — Gemini (§9) e G2.
- A §3.4 — testada no G4 antes do desenho.

---

## 9. Verificação de fatos pelo Gemini

Questionário em `CONVERSAS_COM_CHAT/gemini/` (fora do mapa de docs). A rodada 1 (06/11) bateu
na cota da chave da API do Gemini (429 em toda busca); os fatos críticos — Datastream, Free Trial,
Composer e Airflow, Debezium Server, *policy tags*, destino BigQuery do Airbyte, retenção travada —
foram lidos pelo Claude Code nas páginas oficiais citadas acima. As perguntas restantes:

| # | Pergunta | Estado |
|---|---|---|
| Q2 | Datastream e Cloud SQL PG (se D69 = b) | aberta |
| Q4 | Composer 3 com Airflow 3.2: GA ou Preview; tempo de criação | aberta |
| Q5 | Preço do Composer 3 e Free Trial | aberta |
| Q7 | Airbyte em GKE Autopilot | aberta |
| Q8 | Dataflow: Beam 2.76, máquina e custo do *worker* | aberta |
| Q10 | Linhagem customizada por coluna | aberta |
| Q11 | `dbt-bigquery` e `dbt-core 1.12`: contratos, *grants*, partição | aberta |
| Q12 | WIF com GitHub Actions: *attribute condition* | aberta |
| Q15 | *Provider* `google`: Composer 3 estável; armadilhas de *destroy* | aberta |
| Q16 | `create or replace` do BigQuery apaga *policy tags*? (§3.4) | nova |
| Q17 | Destino BigQuery do Airbyte com Workload Identity no GKE | nova |

---

## 10. Revisão

Rodada 1 do Codex sobre este arquivo, com o repositório em `8309b66`. Pedido ao revisor: o que
quebra o prazo, o que quebra o desmonte, o que o plano supõe sobre o código que o código não faz
(`fluxo_batch.py`, `mvp_ed1.legacy.captura`, `mvp_ed1.recovery.ledger`, `mvp_ed1.streaming`, as
macros do dbt), e números errados. Formato da Etapa 12: achado com ID `RV13-n`, gravidade
(bloqueante/ajuste/observação), evidência e proposta; a coluna *Situação* preenchida na revisão
seguinte.
