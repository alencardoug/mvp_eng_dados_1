# Arquitetura e custos — local, GCP "confortável" e GCP barato

> **O que este arquivo é:** registro de uma conversa entre o Owner e o assistente em 15/09/2026,
> sobre custo e escolha de arquitetura. **Não é documento do projeto**: não entra no mapa do README,
> não decide nada, e o que aqui é estimativa está rotulado como estimativa.
>
> **Sobre os números:** são **aproximações de preço de lista** (região `us-central1`, sob demanda,
> sem impostos, sem créditos promocionais), de memória do assistente — **nada foi medido nem
> consultado na calculadora do GCP nesta conversa** (princípio **P5**). Antes de qualquer decisão,
> confirmar em <https://cloud.google.com/products/calculator>. Preços de nuvem mudam; a ordem de
> grandeza costuma se manter, o valor exato não.

---

## 1. "dbt + Airflow localmente é uma tecnologia ótima, procede?"

**Procede, com duas ressalvas honestas.**

O par é o padrão da indústria para o caminho frio: dbt para transformação declarativa e testada,
Airflow para orquestrar. Não é modismo — é o que a maioria das equipes de dados usa e o que
Composer, Astronomer e MWAA vendem gerenciado. O que o projeto fez em cima disso é o que
diferencia: camadas explícitas, testes de reconciliação em toda fronteira, quarentena em vez de
descarte, oráculo independente, catálogo como código. Isso vale em qualquer ferramenta.

As ressalvas:

1. **Airflow é pesado para o tamanho deste fluxo.** São duas DAGs; um `cron` + `dbt build` fariam
   o mesmo trabalho com 1/10 da memória. Ele está aqui por **paridade com o Composer** (P4) e por
   fidelidade à prática de produção (P10) — decisão consciente, registrada no ADR-0024, e é a
   escolha certa **para este objetivo**. Não é a escolha certa para "o menor custo possível".
2. **O componente caro não é o dbt nem o Airflow — é o Airbyte.** Ele sozinho custa ~4,5 GB de RAM
   na máquina local (Capacidade §2), obrigou a política de troca entre ambientes (R11) e é a peça
   que mais pesa na conta do GCP. dbt custa quase nada; Airflow, ~1 GB; o resto é Airbyte e os três
   PostgreSQL.

**Confirmo o plano como bom plano** para o que o Termo diz que ele é: um MVP que enfrenta os
problemas de um ambiente real, com custo local próximo de zero. Se o objetivo fosse outro —
"o pipeline mais barato de operar" —, o desenho seria outro (ver §4).

## 2. "Cabe numa VM? Quanto custa por mês?"

**Cabe.** O que foi medido localmente (Capacidade §2.4 e §2.8):

| O que | Memória medida |
|---|---|
| Três PostgreSQL + Airbyte + Airflow (caminho frio) | ~6 GB |
| Mais o caminho quente (Redpanda, Kafka Connect/Debezium, Beam) | ~8 GB |
| CPU | 4 vCPUs foram o gargalo dos *pods* do Airbyte, não do dbt |

Numa VM não há VS Code, navegador nem sessões de agente (os ~4 GB que travaram a estação), então
os 8 GB medidos são o número inteiro. Uma VM de **4 vCPU / 16 GB** é o tamanho confortável; 8 GB
é o mínimo apertado e obriga a mesma troca entre ambientes que se faz hoje.

**Estimativa** (aproximação de lista, ver aviso no topo):

| Cenário | Máquina | ~ US$/mês |
|---|---|---|
| Ligada 24 h/dia | `e2-standard-4` (4 vCPU, 16 GB), disco 50 GB balanceado | **~100–110** |
| Ligada 8 h/dia, 22 dias (desliga quando não usa) | idem | **~40** |
| 24 h/dia, mínimo apertado | `e2-standard-2` (2 vCPU, 8 GB) | ~50–55 |
| 24 h/dia, *spot* (pode ser interrompida) | `e2-standard-4` | ~30–40 |

Referência de cálculo: `e2-standard-4` ≈ US$ 0,134/h sob demanda; disco balanceado ≈ US$ 0,10/GB/mês;
desconto por uso contínuo já reduz ~20% no mês cheio. Tráfego de saída é desprezível neste volume.

Ou seja: **o plano inteiro, exatamente como roda na sua máquina hoje, custa uma VM de ~US$ 100/mês
ligada direto, ou ~US$ 40 se desligar fora do horário.** Zero serviço gerenciado, zero reescrita.

## 3. "Pro GCP, para quem tem dinheiro sobrando: Composer é ótimo?"

É o desenho do mapa de paridade (Arquitetura §5), e sim, é o "confortável": tudo gerenciado, cada
peça no serviço nativo. O que ele custa **em operação continuada** (o Termo hoje prevê só janela
curta — a estimativa abaixo é para o cenário futuro que você descreveu):

| Peça | Serviço | ~ US$/mês | Observação |
|---|---|---|---|
| Orquestração | **Cloud Composer 2**, ambiente *small* | **~350–450** | É o piso: ambiente ligado o mês inteiro mesmo ocioso. É a peça que domina a conta |
| Ingestão | **Airbyte no GKE Autopilot** | ~80–150 | Taxa do cluster (~US$ 73; a primeira zona tem crédito gratuito) + *pods* de 4–6 GB |
| Origem transacional | **Cloud SQL PostgreSQL** (2 vCPU / 8 GB) | ~100–130 | Dois bancos (principal + legado) como duas instâncias pequenas dobram isso; como dois *databases* na mesma instância, não |
| Armazém | **BigQuery** | ~1–10 | Armazenamento US$ 0,02/GB/mês; consulta US$ 6,25/TB com 1 TB grátis/mês. Neste volume é centavos |
| CDC + transporte | **Datastream + Pub/Sub** | ~5–30 | Por GB processado; os primeiros 10 GB do Pub/Sub são grátis |
| Processamento contínuo | **Dataflow** (*streaming*, 1 *worker* pequeno) | ~60–120 | *Job* de *streaming* fica ligado; *batch* seria centavos |
| Governança | Dataplex, *policy tags*, IAM | ~0–20 | Catálogo por metadado é barato; *scans* de qualidade custam à parte |
| **Total** | | **~600–900 / mês** | Dominado por Composer + GKE + Cloud SQL |

Vale ver que **três quartos disso é "ter serviço gerenciado ligado"**, não dado processado: o
volume deste projeto é pequeno demais para o BigQuery e o Pub/Sub cobrarem algo relevante.

## 4. "Para quem não tem: há forma barata? Quanto?"

Há, e ela é uma família de três desenhos, do mais fiel ao mais econômico. O que muda em cada
passo é **quanto da paridade você abre mão** para tirar serviço gerenciado da conta.

### 4.1 A VM (o que já existe, na nuvem) — ~US$ 100/mês

Igual ao §2: uma `e2-standard-4` com os mesmos contêineres (`make up`, `airbyte-up`,
`airflow-up`, `stream-up`). Zero reescrita; Terraform provisiona a VM, o disco e a rede. Perde-se:
nada de funcional; ganha-se: nenhum serviço gerenciado. **É o mais barato que preserva 100% do que
foi construído**, e é o que eu faria primeiro num cenário sem orçamento.

### 4.2 VM + BigQuery — ~US$ 100–130/mês

A VM continua com Airflow, Airbyte e a origem PostgreSQL; **o armazém vira BigQuery** (o Airbyte
tem destino BigQuery; o dbt troca de adaptador — a Etapa 13 já prevê essa adaptação de dialeto).
É onde a paridade começa a valer de verdade: o mesmo dbt, o mesmo catálogo, as *policy tags*.
Custo extra: centavos de BigQuery. Perde-se: o PostgreSQL como armazém (que é justamente o que
o Termo trata como fase local).

### 4.3 *Serverless* de ponta a ponta — ~US$ 30–80/mês

Para quem quer ficar perto de zero em repouso, trocando peça a peça pelo equivalente que **só cobra
quando roda**:

| Peça | No lugar de | Por | ~ US$/mês |
|---|---|---|---|
| Orquestração | Composer | **Cloud Scheduler + Cloud Run Jobs** (um *job* por camada rodando `dbt build`) | ~0–5 |
| Ingestão | Airbyte | **Datastream** (Cloud SQL → BigQuery, por GB) ou o próprio *job* dbt lendo via *federated query* | ~5–20 |
| Origem | Cloud SQL 2 vCPU | **Cloud SQL menor** (`db-f1-micro`/`db-g1-small`) ou PostgreSQL numa `e2-micro` | ~10–30 |
| Armazém | — | BigQuery | ~1–5 |
| *Streaming* | Dataflow ligado | **Pub/Sub → Cloud Run** (serviço com escala a zero) ou Dataflow em *batch* agendado | ~0–20 |
| **Total** | | | **~30–80** |

O que se perde aqui é **exatamente o que o projeto escolheu por paridade**: Airflow (as DAGs viram
*jobs* e agendamento), Airbyte (o `streams.yml` e o critério por tabela do ADR-0015 precisam ser
reexpressos no Datastream) e o Beam como *streaming* contínuo. É o desenho que o ADR-0024 rejeitou
para a Etapa 13 — porque lá o objetivo é **replicar**, não reconstruir. Para **operar barato**, é o
desenho certo, e a Etapa 13 deixa a maior parte pronta (Terraform, BigQuery, *policy tags*, dbt).

### 4.4 O que eu recomendaria, se a pergunta fosse "e agora, com o produto pronto"

Começar pela **4.1 ou 4.2** — custa uma VM, preserva tudo, e dá tempo de medir o que de fato
roda. Migrar para 4.3 peça a peça, na ordem em que cada serviço gerenciado se paga: BigQuery
primeiro (é grátis neste volume e destrava as *policy tags*), Cloud Run Jobs no lugar do Airflow
depois (é onde a VM deixa de precisar de 16 GB), Datastream por último (é onde o Airbyte sai e a
VM vira micro). Cada passo é um ADR, com o custo estimado antes e o real depois — o mesmo
procedimento que o ADR-0024 já exige para a janela da Etapa 13.

## 5. Créditos que mudam a conta no início

- **Conta nova no GCP:** US$ 300 de crédito por 90 dias — cobre a Etapa 13 inteira e meses da 4.1.
- **Nível gratuito permanente:** uma `e2-micro` por mês, 1 TB de consulta e 10 GB de armazenamento
  no BigQuery, 10 GB de Pub/Sub, crédito de um cluster zonal no GKE — é por isso que o cenário
  4.3 encosta em zero neste volume.

## 6. O que fica registrado para quando a decisão chegar

Nada disto altera o plano vigente (duas fases; GCP como réplica de janela curta; operação
continuada fora do escopo). Quando a fase de operação continuada for aberta, o caminho é o que
já está no projeto: Termo §4 e ADR-0024 ganham uma fase nova, cada troca de peça vira um ADR com
custo estimado e medido, e os números desta conversa são substituídos pelos da calculadora e da
fatura — **estimado e medido nunca se misturam**.

## 7. A janela curta da Etapa 13, em dias

O plano vigente é o desenho da §3 **em janela curta**: `terraform apply` → carregar → rodar o fluxo
→ testes e medições → evidências → `terraform destroy` (ADR-0024; critério da Etapa 13: "criados e
destruídos na mesma janela, com custo estimado e real registrados"). Sobrevivem o repositório, as
medições e as evidências — não o ambiente.

| | US$/mês | ≈ US$/dia | 2 dias | 5 dias |
|---|---|---|---|---|
| Piso (~600) | 600 | ~20 | ~40 | ~100 |
| Teto (~900) | 900 | ~30 | ~60 | ~150 |

Com o crédito de US$ 300 cabem uma ou duas janelas de 2 a 5 dias. Três cuidados:

1. **Composer cobra por hora de pé e leva 25–40 min para nascer** — sobe por último, desce primeiro.
   Se a janela escorregar por depuração, é ele que consome o crédito.
2. **Conferir o `destroy` na fatura**: discos órfãos, *backups* do Cloud SQL, o *bucket* do Composer
   e *jobs* de Dataflow em *streaming* sobrevivem a um *destroy* mal ordenado. O custo real é lido
   **depois** do *destroy*.
3. **Alerta de orçamento** no *billing* (ex.: US$ 100 e US$ 200) antes do primeiro `apply`, e
   confirmar que a conta ainda está dentro dos 90 dias do crédito.

Consequência para o plano da Etapa 13, quando abrir: chegar à janela com tudo pronto — dbt no
dialeto, `terraform plan` revisado, **roteiro de evidências escrito** — para que a janela seja
ligar, medir e desligar, não desenvolver com o taxímetro correndo.

## 8. A semana da Etapa 13 — proposta do Owner (15/09/2026)

Segunda: ligar. Terça e quarta: fluxo, testes, laboratórios e evidências. Quinta, primeiro horário:
`destroy`. Sexta: conferir que nada ficou de pé. Cinco dias úteis.

| Período | Ambiente | ≈ US$ |
|---|---|---|
| Segunda manhã | só o barato: Cloud SQL, BigQuery, Pub/Sub, IAM, *policy tags* | ~5 |
| Segunda tarde → quarta noite | tudo de pé (~2,5 dias a US$ 20–30/dia) | 50–75 |
| Quinta → sexta | `destroy` e resíduos até apagar | ~5 |
| **Janela** | | **~60–85** (o dobro ainda cabe em US$ 300, e sobra uma segunda janela) |

Ajustes combinados:

1. **Nada de desenvolver com taxímetro.** dbt no dialeto, `terraform plan` revisado, roteiro de
   evidências e scripts de carga prontos na semana anterior. Composer e GKE sobem **depois** de a
   carga estar no Cloud SQL — cada hora de Composer parado é dinheiro sem evidência.
2. **Quarta meio-dia é o ponto de decisão.** Não rodou ponta a ponta? Derruba na quinta do mesmo
   jeito; o que faltou vira achado e segunda janela, não extensão. Alertas de orçamento em
   US$ 100 e US$ 150.
3. **Sexta fecha o `destroy`, não a conta.** O *billing* atrasa 24–48 h: o custo real da janela é
   lido na semana seguinte e só então entra no registro (critério da Etapa 13: "custo estimado e
   real registrados"). Sexta é para conferir na consola: discos, *backups* do Cloud SQL, *bucket*
   do Composer, *jobs* de Dataflow, cluster GKE — nada de pé.

## 9. O roteiro depois da Etapa 13 — intenção do Owner (15/09/2026), fora do plano vigente

§3 (paridade, janela curta) → §4.1 (portabilidade: a mesma árvore numa VM, um dia, evidências,
`destroy`) → **§4.3 permanente**, refinado, visível a entrevistadores como portfólio.

O que cada passo prova: §3, que o desenho tem contrapartida real na nuvem; §4.1, que o projeto
inteiro sobe em qualquer máquina com um comando (~US$ 3 por dia de VM); §4.3, que dá para operar
por ~US$ 30–80/mês e deixar ligado.

O que o §4.3 exige que ainda não existe — cada item é ADR quando chegar:

- **Termo §4**: operação continuada entra no escopo; ADR-0024 ganha a fase de operação.
- **Trocas de peça**: Cloud Run Jobs + Scheduler no lugar do Airflow; Datastream no lugar do
  Airbyte; Cloud Run (escala a zero) no *streaming*. Cada uma com custo estimado e medido.
- **Looker Studio** (o "Power BI grátis do GCP") sobre as views de `consumption` — sem licença;
  o custo é a consulta no BigQuery, dentro do 1 TB gratuito neste volume. As *policy tags* já
  dizem o que um visitante não vê.
- **API** em Cloud Run com escala a zero, ~US$ 0–5/mês; o `contract: enforced` das views vira o
  contrato da API.
- **Exposição pública**: dados sintéticos tornam possível (regra 2), mas IAM, chaves, o que é
  público e um teto duro de orçamento (painel público pode ser abusado) pedem ADR próprio — o
  mesmo cuidado do ADR-0025, agora para leitores externos.
- **CI/CD**: com ambiente permanente, `make test` e `dbt build` viram o *pipeline* que promove
  sandbox → prod; é onde os ambientes (sandbox/qa/prod) passam a existir de fato.

Nada disto altera o plano vigente até a Etapa 13 fechar.
