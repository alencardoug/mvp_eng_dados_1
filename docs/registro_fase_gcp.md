# Registro da fase GCP — o processo de construção da Etapa 13

> **O que vive aqui:** o diário de construção da fase GCP, em ordem cronológica — o que foi feito,
> com que comando, o que saiu, o que se decidiu, o que deu errado e como se resolveu, e quanto
> custou. A infraestrutura da Etapa 13 é **destruída** em 12/11/2026; o que sobrevive é o
> repositório, e este registro é a parte dele que conta como foi.
>
> **O que não vive aqui:** o plano e as suas regras (ver o plano transitório `PLANO_etapa_13.md`
> enquanto existir, e o [Plano de Desenvolvimento](plano_de_desenvolvimento.md#etapa-13--replicação-no-gcp-com-terraform--m6));
> as decisões (ver os [ADRs](adr/README.md) e as [Pendências §2](pendencias.md)); os números de
> custo e capacidade como referência (ver [Capacidade §2.6](capacidade_e_recuperacao.md#26-custo-da-janela-na-nuvem));
> o mapa de paridade (ver [Arquitetura §5](arquitetura.md#5-mapa-de-paridade-local--gcp)). Este
> registro conta a história e aponta para eles; não repete as regras.
>
> Rótulos: **[medido]** tem saída de comando ou página oficial por trás; **[estimado]** não.
> Horários em America/Sao_Paulo. O identificador da conta de faturamento aparece mascarado
> (`0199D3-…`); o projeto é `mvp-ed1-gcp`.

| Campo | Informação |
|---|---|
| Versão | 1.0 |
| Abertura | 06/11/2026 |
| Última revisão | 07/11/2026 — G0: projeto, fundação aplicada, preços lidos, roteiro de evidências |

---

## 1. Como a etapa foi aberta (06/11/2026)

**A pergunta do Owner:** "Vamos iniciar a etapa 13? Me fale mais dos planos, e avalie se há algo a
mudar, revisar, enviar ao Codex ou enviar ao Gemini."

**O que existia:** a Etapa 13 era uma linha de tabela no plano de desenvolvimento, o mapa de
paridade, o ADR-0024 (Airbyte e Composer em janela curta), o ADR-0025 (*policy tags* por fluxo com
federação de identidade), um guia de estudo (`NAVEGANDO_GCP/`) e uma conversa de custos
(`CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md`). Nenhum Terraform da nuvem.

**A primeira leitura achou um furo no mapa:** a Arquitetura §5 dizia Datastream → Pub/Sub →
`ReadFromPubSub`; a página oficial de destinos do Datastream lista **só** BigQuery, Cloud Storage e
Iceberg. O capítulo 07 do guia de estudo já avisava; o mapa não tinha sido corrigido. Virou o
[ADR-0051](adr/0051-cdc-da-fase-gcp-pelo-debezium-server.md) (§3).

**O Gemini como parecerista:** havia um parecer dele, de 03/11, no `NAVEGANDO_GCP/` e um
`GEMINI.md`. Lidos, eram genéricos — nenhuma recomendação que mudasse o plano, sem o furo do
Datastream, e contando 48 ADRs quando havia 50. O `GEMINI.md` foi reduzido ao papel de
**verificador de fatos com URL oficial**, e o parecer foi arquivado em `CONVERSAS_COM_CHAT/gemini/`.

**Decisões do Owner na abertura:**

- autorizou a Etapa 13 (Termo v1.3 §11);
- a conta é a da **avaliação gratuita**, não convertida — "temos 7 dias para ter tudo ativado e
  desativado, e falhar nisso é falhar no projeto";
- **D68**: sem volume alto — a fase GCP roda no fator `dev` (a premissa estava no Termo §7 e nas
  consequências do ADR-0014 e do ADR-0016, emendados por nota);
- **escopo inteiro**, recusando o corte preventivo; revisões em rodadas com prazo.

**A conta, lida pelo `gcloud` e pela consola** [medido]: uma conta de faturamento compartilhada por
nove projetos; **R$ 1.740,37 de crédito e 9 dias restantes** em 06/11 (fim real ~15/11; o Owner
fixou 13/11 por prudência). Cota de 32 vCPUs em todas as regiões, sem aumento possível na avaliação.

## 2. O Gemini e a cota (06–07/11/2026)

O plano era usar o Gemini CLI para conferir fatos do GCP. O que aconteceu, na ordem:

1. `gemini -p` com as 15 perguntas de uma vez → **429 `RESOURCE_EXHAUSTED`** em todas as buscas:
   ele disparou as buscas em paralelo e estourou o limite.
2. Uma pergunta por chamada, em série, com pausa → 429 do mesmo jeito.
3. Troca de modelo (`gemini-3-pro-preview`, `gemini-3.1-pro-preview`, `gemini-flash-latest`) → 429.
   O "Login with Google" é recusado pela ferramenta nesta conta; só a chave de API funciona, no
   nível gratuito.
4. O Owner sugeriu `gemini-2.5-flash`. Testado direto na API REST: **"This model
   models/gemini-2.5-flash is no longer available to new users"** (404).
5. Teste isolado: chamada **sem** ferramenta funciona; o esgotado é a cota de **busca na web**
   (*grounding*), comum a todos os modelos.
6. **A saída:** a ferramenta `url_context` — o Gemini lê uma URL que se passa a ele — tem outra cota
   e funciona. Conferida com a página do Datastream: confirmou o furo do §1.

Daí o uso que ficou: o Claude Code indica a página oficial, o Gemini lê e cita o trecho. Foi assim
que os preços do §6 foram lidos.

## 3. A revisão do plano pelo Codex (06–07/11/2026)

O plano transitório `PLANO_etapa_13.md` foi revisado **antes de qualquer código**, como o da
Etapa 12. Três rodadas, cada uma com escopo fixo em *commits*:

| Rodada | Conta e esforço | Achados | O que pegou de mais importante |
|---|---|---|---|
| 1 | conta 1, `xhigh` | 11 (9 bloqueantes, 2 ajustes) | o desmonte dependia de passos que podem falhar; a conversão do dbt **não** era "a maior parte `::`" — só 4 a 8 de 106 modelos são *cast* puro, e 81 nascem dos geradores do legado; o catálogo analisa o SQL como PostgreSQL; o caminho quente depende de `on conflict … returning` e do *Producer* do Kafka; a DAG tem `/opt/mvp_ed1` fixo; *authorized views* e Secret Manager sem bloco |
| 2 | conta 2, `xhigh` | 5 (1 bloqueante, 3 ajustes, 1 observação) | transações do BigQuery que só acrescentam **rodam em paralelo** — a idempotência proposta não impedia dois lotes simultâneos de inserir o mesmo movimento; um *pool* regional do GKE teria 6 nós, não 2 |
| 3 | conta 1, `high`, só regressão | 0 | revisão encerrada; o G0 pode começar |

Depois da rodada 1, o Claude Code avaliou que fazer tudo bem feito até segunda era improvável e
ofereceu ao Owner uma janela parcial com segunda janela paga depois. **O Owner manteve o escopo
inteiro.** A consequência ficou escrita no plano: critério que não for provado deixa o M6
**incompleto, sem aceite e sem *tag***, e o desmonte acontece do mesmo jeito.

As decisões tomadas pelo Owner sobre a rodada 1 (07/11) estão nas
[Pendências §2](pendencias.md#d69-a-d74--decididas-em-07112026-na-revisão-do-plano-da-etapa-13):
D69 (Debezium Server → Pub/Sub, ADR-0051), D70 (retenção sem trava — travar põe *lien* no projeto),
D71 (o dbt aplica as *policy tags*, porque substituir tabela no BigQuery as apaga), D72 (Airbyte →
BigQuery sem chave), D73 (`us-central1`, Composer 3 com Airflow 3.2.2), D74 (projeto dedicado e
relógio de emergência).

**Perguntas do Owner no caminho, e as respostas:** qual é a referência GCP — é a de **paridade**
(o mapa), derivada da local; a referência nativa do GCP (Datastream, Workflows, Cloud Run) seria
uma terceira entrega, depois do M6, porque trocá-la agora seria reprojetar o protocolo do legado.
Em custo [estimado, conversa de 15/09], a nativa sairia ~10× mais barata ligada o mês inteiro
(~US$ 30–80 contra ~600–900) e mais leve de operar; a paridade é a que prova portabilidade.

## 4. Ferramentas e contas usadas

- **Codex CLI** `0.166.0`, modelo `gpt-6.1-sol`, duas contas ChatGPT (sem custo de API), sandbox
  com escrita só no `REVISAO.md` e rede para documentação oficial.
- **Gemini** pela API REST com `url_context` (o CLI sem busca não serve para fatos).
- **Terraform** `1.16.1` (`.tools/terraform`), *provider* `hashicorp/google` `~> 8.10`.
- **gcloud** com a conta do Owner; **ADC** de usuário (`authorized_user`), sem chave de conta de
  serviço.

## 5. G0 — fundação (07/11/2026)

**Projeto** [medido]:

```
$ gcloud projects create mvp-ed1-gcp --labels=projeto=mvp-ed1,etapa=13,desmontar-ate=2026-11-12
$ gcloud billing projects link mvp-ed1-gcp --billing-account=0199D3-…
billingEnabled: true
```

**As conferências do relógio de emergência, antes de qualquer recurso** [medido]: o Owner tem
`roles/billing.admin` na conta (pode desligar o faturamento do projeto); a lista de *liens* do
projeto veio vazia (`GET cloudresourcemanager v3 liens` → `{}`; o `gcloud alpha` não estava
instalado, e a API REST respondeu no lugar dele depois de ativada a `cloudresourcemanager`); cota
do projeto novo igual à da conta — `CPUS_ALL_REGIONS` 32, `E2_CPUS` 24 em `us-central1`,
`IN_USE_ADDRESSES` 8.

**ADC** — passo do Owner. Rodado como `! gcloud …` dentro da sessão, não criou o arquivo (o *login*
é interativo); num terminal à parte funcionou, seguido de
`gcloud auth application-default set-quota-project mvp-ed1-gcp`.

**A raiz do Terraform** (`terraform/`): uma raiz só, com um interruptor por degrau de preço
(`enable_cheap`, `enable_cloud_sql`, `enable_gke`, `enable_composer`) — desmontar um degrau é o
mesmo `apply` com o interruptor desligado, então a ordem do desmonte fica declarada. Estado local
(D74), `terraform.tfvars` e planos salvos fora do Git.

**Primeiro `plan` e primeiro `apply`** [medido], pelo rito do plano (§6.3: `plan -out`, leitura,
aprovação do Owner, `apply` do arquivo salvo):

```
Plan: 23 to add, 0 to change, 0 to destroy.     # 22 APIs + 1 orçamento
Apply complete! Resources: 23 added, 0 changed, 0 destroyed.
```

Dois cuidados que só apareceram escrevendo:

- **Os créditos escondem o gasto.** Com o padrão do orçamento, os créditos da avaliação entram no
  cálculo, o gasto líquido fica em zero e nenhum alerta dispara. O orçamento usa
  `credit_types_treatment = "EXCLUDE_ALL_CREDITS"`: teto de R$ 400 na moeda da conta, alertas em
  30, 60 e 90%.
- **O orçamento é da conta, não do projeto** — apagar o projeto não o remove. O `deletion_policy`
  do *provider* tem padrão `DELETE`, mas `ABANDON` ou `PREVENT` o deixariam para trás; ficou
  explícito.

## 6. Preços lidos para a estimativa (07/11/2026)

Lidos pelo Gemini nas páginas oficiais, com o trecho citado; os arquivos de resposta ficam fora do
Git, e os números entram na [Capacidade](capacidade_e_recuperacao.md#26-custo-da-janela-na-nuvem)
como estimativa antes do primeiro `apply` cobrável.

| Serviço | Preço lido | Página |
|---|---|---|
| Composer 3 | US$ 0,06 por DCU-hora; armazenamento do banco US$ 0,000232877/GiB-h; a taxa de ambiente está dentro do DCU | composer pricing |
| Composer 3, preset *small* | *scheduler* 0,5 vCPU/2,5 GB, *triggerer* 0,5/0,5, *DAG processor* 1/2, *web server* 1/2,5, *workers* 1/2 (2 a 4) | environment-scaling |
| GKE | US$ 0,10 por *cluster*-hora; crédito de US$ 74,40/mês por conta, que cobre um *cluster* zonal | kubernetes-engine/pricing |
| Cloud SQL Enterprise | US$ 0,0413 por vCPU-h; US$ 0,007 por GiB-h; SSD US$ 0,17/GiB-mês | sql/pricing |
| Dataflow *streaming* | US$ 0,069 por vCPU-h; US$ 0,003557 por GB-h; Streaming Engine US$ 0,018/GB; máquina padrão `n1-standard-2` | dataflow/pricing |
| Pub/Sub | 10 GiB/mês grátis, depois US$ 40/TiB | pubsub/pricing |
| BigQuery | 1 TiB de consulta e 10 GiB de armazenamento grátis por mês; US$ 6,25/TiB | bigquery/pricing |
| Rede | *forwarding rule* de LB interno US$ 0,025/h; Cloud NAT US$ 0,0014/h por VM | vpc/nat pricing |

**Dois buracos e como foram tapados.** A página de preço de VM carrega a tabela dinamicamente, e
nem o Gemini nem a leitura direta a viram; o preço da `e2-standard-4` saiu da **Cloud Billing
Catalog API**, a fonte oficial por SKU [medido]: E2 US$ 0,021812 por vCPU-h e US$ 0,002924 por
GiB-h; N1 US$ 0,031611 e US$ 0,004237; `pd-balanced` US$ 0,10/GiB-mês. E a conversão do Composer 3
em DCU não está escrita; o que a página traz é um **exemplo oficial** — 12 DCUs para um ambiente
em uso normal, 15 com mais *workers*, a US$ 0,06 —, lido do HTML baixado depois que o Gemini
esgotou também a cota de `url_context` (429, 07/11). A estimativa por serviço está na
[Capacidade §2.14](capacidade_e_recuperacao.md#214-a-estimativa-da-janela-da-etapa-13--07112026).

## 7. As evidências para o portfólio (07/11/2026)

O Owner, no meio do G0: "o produto que terei ao término deste projeto é o processo de construção,
visto que o produto em si construído será destruído" — e o objetivo é **comprovar que consegue
replicar uma estrutura local adequada na nuvem**, mostrando isso no portfólio por código, capturas,
documentos e páginas, em conteúdo humanamente interessante.

Daí três coisas: este registro passou a ser escrito **no momento**, não no fim; o plano ganhou um
roteiro de capturas com a frase que cada uma prova (19 capturas e 2 GIFs, a maioria na quarta, antes
do `destroy`); e o caso de portfólio será redigido aqui e publicado pelo Owner no portfólio depois
do M6. As capturas saem do Chrome do Owner, logado na consola, e ficam em
[`registro_fase_gcp/capturas/`](registro_fase_gcp/capturas/).

**A primeira captura** — o painel do projeto recém-criado; a faixa no alto é a própria consola
contando o crédito e os dias restantes da avaliação:

![Painel do projeto mvp-ed1-gcp em 07/11/2026](registro_fase_gcp/capturas/2026-11-07_01_projeto_criado.jpg)
