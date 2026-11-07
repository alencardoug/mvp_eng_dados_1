# Revisão da entrega — plano da Etapa 13

> Dossiê escrito à mão pelo Claude Code, na estrutura do `.claude/skills/revisao/dossie.py`.
> **Transitório**: sai no *commit* que fecha a revisão do plano. Não é documentação do projeto e não
> entra no mapa do README. **É um convite, não uma ordem.**
>
> **Por que à mão:** a entrega é só documentação, e o único comando de `comandos.txt` é
> `make check`, que exige os três bancos de pé. Subi-los para medir um diff sem código nem modelo
> não mede nada desta entrega — e o primeiro comando `docker` depois do *boot* sobe Airbyte e
> Airflow juntos (R11). O portão rodado foi o `make check-offline` (§3).

## 1. Escopo

Intervalo: `8309b66..ce4e850` — leia o diff, ele não é repetido aqui.

```
01979d0 docs: registra a autorização da Etapa 13 e a D68, fase GCP no fator dev
817f25b docs: reduz o GEMINI.md a verificador de fatos e arquiva os registros do Gemini
ed406ce docs: adiciona o plano transitório da Etapa 13
ce4e850 docs: registra no plano da Etapa 13 o crédito, o prazo e a cota do Gemini
```

**O objeto da revisão é o `PLANO_etapa_13.md`** — um plano de execução, revisado **antes** de
qualquer código, como o da Etapa 12. Os outros arquivos registram decisões que o Owner já tomou
(autorização, D68) e não são o foco.

## 2. Mapa de revisão

| Arquivo | Natureza | Revisão |
|---|---|---|
| `PLANO_etapa_13.md` | declaração: o plano inteiro | integral |
| `Abertura_de_projeto.md` (v1.3), `docs/plano_de_desenvolvimento.md` (v3.11), `docs/pendencias.md` (D68) | registro de decisão do Owner | conferir só coerência com o plano |
| `docs/adr/0014…`, `docs/adr/0016…` | nota datada (ADR aceito não se reescreve) | conferir só a nota |
| `GEMINI.md`, `CONVERSAS_COM_CHAT/gemini/` | instrução de agente e registro de conversa | amostragem |

## 3. O que foi executado

**Portão offline, em `ce4e850`:**

```
$ make check-offline
894 passed, 188 deselected in 155.94s (0:02:35)
check-offline: as três etapas passaram
```

**Leituras na conta GCP, só leitura (06/11/2026):**

```
$ gcloud billing accounts list
ACCOUNT_ID            NAME                        OPEN  MASTER_ACCOUNT_ID
0199D3-0FDAC3-ED35E5  Minha conta de faturamento  True
$ gcloud projects list   # 9 projetos, todos na mesma conta; o mais antigo criado em 2026-08-17
$ gcloud compute project-info describe --project analisador-de-risco   # extrato
CPUS_ALL_REGIONS 32.0 0.0
GPUS_ALL_REGIONS 0.0 0.0
IN_USE_ADDRESSES 8.0 0.0
$ gcloud compute regions describe us-central1 --project analisador-de-risco   # extrato
CPUS 200.0 0.0
E2_CPUS 24.0 0.0
N2D_CPUS 16.0 0.0
INSTANCES 24.0 0.0
```

A consola, lida pelo Owner em 06/11: "Você tem R$ 1.740,37 de crédito e 9 dias restantes no seu
teste gratuito."

**Páginas oficiais lidas pelo Claude Code (06/11/2026)** — citação curta, para conferência:

| Fato do plano | Página | O que a página diz |
|---|---|---|
| §3.1 Datastream sem Pub/Sub | docs.cloud.google.com/datastream/docs/destinations | destinos: BigQuery, Cloud Storage e tabelas Iceberg no BigQuery; Pub/Sub não aparece |
| §3.2 retenção travada | docs.cloud.google.com/storage/docs/bucket-lock | "automatically applies a lien on the project"; "Locking a bucket's retention policy is irreversible" |
| §3.3 HMAC | docs.airbyte.com/integrations/destinations/bigquery | GCS Staging recomendado, exige HMAC; `credentials_json` "optional for open-source"; ADC desde 1.1.14 |
| D73 Composer | docs.cloud.google.com/composer/docs/composer-versions | `composer-3-airflow-3.2.2-build.9`, 20/10/2026; a página não diz GA ou Preview |
| D69a Debezium Server | debezium.io/…/debezium-server.html | `debezium.sink.type=pubsub`; 3.7.1.Final; a página **não** afirma o mesmo envelope do Kafka Connect nem a autenticação |
| §0 Free Trial | docs.cloud.google.com/free/docs/free-cloud-features | sem aumento de cota; recursos parados no fim, 30 dias de carência, depois apagados |
| G5 *policy tags* | docs.cloud.google.com/bigquery/docs/column-level-security-intro | Policy Tag Manager não descontinuada; catálogo do Data Catalog em transição para *Knowledge Catalog* |

**Gemini:** a rodada 1 do questionário (`CONVERSAS_COM_CHAT/gemini/2026-11-06_questionario_1.md`)
não produziu resposta — 429 `RESOURCE_EXHAUSTED` em toda chamada com busca na web, em
`gemini-3-flash-preview`, `gemini-3-pro-preview`, `gemini-3.1-pro-preview` e `gemini-flash-latest`.

## 4. Não verificado

1. **Nada do código foi lido para além do inventário.** As contagens do G1 — 192 modelos, "~107"
   com sintaxe só do PostgreSQL, 13 macros, 34 testes singulares — vêm de um `grep` por `::`,
   `plpgsql`, `pg_input_is_valid`, `jsonb`, `distinct on`, `ilike`, `generate_series`, `regexp_`,
   `to_char`, `interval`; o *grep* casa com comentários e não sabe o que é conversão trivial. A
   dimensão real da conversão não foi medida.
2. **Os ~20 módulos Python "presos ao PostgreSQL"** são os arquivos que citam `advisory`, `pg_`,
   `psycopg` ou `postgresql`; nenhum foi lido para dizer o que muda.
3. **A DAG no Composer:** que `fluxo_batch.py` rode com o pacote no *bucket*, que `dbt-core 1.12.3`
   + `dbt-bigquery` instalem sem conflito na imagem do Composer, que a rede deixe o Composer chamar
   a API do Airbyte no GKE. Nada disso foi conferido.
4. **A §3.4** (`create or replace` apaga *policy tags*?) é hipótese.
5. **O cronograma** (§6.1) não tem medição por trás: as durações de cada bloco são estimativa do
   autor, e o custo/dia é o de 15/09, não conferido.
6. **A cota do projeto novo** é suposta igual à de `analisador-de-risco`.
7. **O envelope do Debezium Server** no Pub/Sub ser igual ao do Kafka Connect (D69a).
8. Os itens da V1 da Pendências que a Etapa 13 deveria revisitar não foram cruzados com os blocos.

## 5. Premissas sobre o ambiente

- A Free Trial não bloqueia Composer, GKE, Datastream, Dataflow nem Cloud SQL (a página lista só
  GPU, Windows, Marketplace, VMware e cota).
- Um projeto novo ligado à conta da avaliação herda a cota de 32 vCPUs.
- `us-central1` tem todos os serviços do plano.
- O Owner está disponível todos os dias até 13/11 para os passos que só ele dá.

## 6. Ambiente necessário para esta revisão

**Nada de pé.** É revisão de plano: leitura do repositório, `grep`, e rede para conferir páginas
oficiais. Não suba bancos, Airbyte, Airflow nem *streaming*; não rode `make check`, `make up` nem
nenhum alvo que chame `docker`; não rode `gcloud` nem `terraform`.

## 7. Onde hesitei

- **D69 (a) contra (b).** Recomendei o Debezium Server porque preserva o envelope e o código do
  Beam, mas isso troca o "Datastream" do mapa — e o capítulo 07 do `NAVEGANDO_GCP` foi escrito
  para ele. Se o envelope não for o mesmo, (a) perde a vantagem.
- **D74, estado local do Terraform.** É o oposto do padrão corporativo (P10); escolhi pelo prazo e
  porque o *backend* remoto no mesmo projeto morreria com ele.
- **Escopo inteiro em sete dias.** O Owner recusou o corte preventivo; o plano responde com ponto
  de decisão na quarta 12:00 e "encurta-se o escopo, nunca a margem". Não sei se o cronograma cabe.
- **G1 numa árvore só, dois alvos.** Mais barato de manter, mas cada modelo convertido mexe no
  caminho local e pede `make check` completo antes do *commit*.

## 8. Rodadas
