# Capacidade e Recuperação

> **O que vive aqui:** como o ambiente local é dimensionado, o que é medido, e o único ponto de
> recuperação do projeto.
>
> **O que não vive aqui:** o fator de escala e os parâmetros do gerador (ver
> [Geração de Dados](geracao_de_dados.md)); as contagens por tabela (ver
> [Modelo de Dados](modelo_de_dados.md)); o *snapshot* imutável do legado, que tem outra finalidade
> (ver [Origem Legada](origem_legada.md#4-snapshot-imutável)).

| Campo | Informação |
|---|---|
| Critério de dimensionamento | **Cobertura**, não volume — [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) |
| Abrangência | `source_db` + `legacy_db` + `warehouse_db` + ponto de recuperação |
| Versão | 2.7 |
| Situação | Vigente. Origem transacional (Etapa 4) e ingestão (Etapa 5) **medidas**; as demais camadas, não |
| Última revisão | 05/09/2026 |

---

## 1. O ambiente local é dimensionado por cobertura

O orçamento de 4 GB foi **aposentado em 04/09/2026**. Ele nunca foi medido, e a premissa que o
sustentava — trabalhar volume alto localmente — mudou: o volume alto pertence à fase GCP.

O ambiente local não é dimensionado por tamanho. É dimensionado pelo que precisa **exercitar**, e o
[ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) fixa o piso que garante isso em
qualquer escala:

- toda tabela populada — nenhuma das 40 vazia;
- todo valor de enumeração presente ao menos uma vez;
- todo tipo de falha do [catálogo do legado](origem_legada.md) representado;
- toda invariante de negócio do [Modelo de Dados](modelo_de_dados.md#4-invariantes-de-negócio)
  exercida ao menos uma vez, incluindo os casos que devem falhar.

**Consequência prática:** não há limite de bytes, não há alerta de 3,7 GB e não há bloqueio em
4 GB. Tamanho deixou de ser restrição e passou a ser observação.

## 2. O que continua sendo medido

Sem limite, a medição continua — por dois motivos. O primeiro é o princípio **P5**: o projeto
distingue planejado de medido, e não pode afirmar tamanho que não conferiu. O segundo é que a fase
GCP precisa de números reais para calibrar o fator `cloud`.

Ao final de cada etapa, registra-se:

- tamanho por banco, schema, tabela e índice, via `pg_database_size`, `pg_total_relation_size` e
  `pg_indexes_size`;
- linhas por tabela, conferidas contra as proporções declaradas;
- tempo de execução do pipeline completo.

Nada disso interrompe execução. Os valores alimentam a definição do fator `cloud`, na Etapa 13, e a
tabela de reconciliação do schema `governance`
([ADR-0023](adr/0023-escopo-do-schema-governance.md)).

### 2.1 Medido na Etapa 4 — origem transacional

Primeira medição real do projeto. Ambiente limpo: `make reset` → `make up` → `make migrate` →
`make seed-data`, sem carga anterior no volume — a distinção importa, porque uma carga sobre tuplas
mortas de uma execução abortada mediu 86 MB onde havia 55.

| Medida | Valor |
|---|---:|
| Linhas carregadas em `oltp`, fator `dev` | 253.414 |
| Tamanho do schema `oltp` (dados + índices) | 54,5 MB |
| Tamanho do `source_db`, com catálogo e WAL | 63,1 MB |
| Soma dos três bancos, dois deles vazios | 77,8 MB |
| **Média por linha, incluindo índices** | **225 bytes** |
| Tempo de geração em memória | 5,1 s |
| Tempo de carga por `COPY` | 26,0 s |
| **Tempo total de `make seed-data`** | **31,1 s** |

Bytes por linha varia mais de uma ordem de grandeza entre as tabelas, e a média esconde isso: 154
bytes em `cart_items` e 528 em `inventory_movements`, que carrega três `uuid`, um `jsonb` e seis
índices. Nas tabelas de domínio fechado o número perde sentido — `sales_channels` marca 13 kB por
linha porque três linhas pagam o custo fixo de oito páginas de índice. **Para projetar volume, use
as tabelas grandes; a média serve para comparar execuções, não para extrapolar.**

O detalhe por tabela e por índice não é copiado para cá: ele sai de `make size-report`, que é o dono
do número, e muda a cada execução.

*Ainda não medidos:* `legacy_db`, `warehouse_db`, tempo do pipeline completo e tamanho das camadas
analíticas. Eles não existem ainda (**P5**).

### 2.2 Medido na Etapa 5 — ingestão `oltp` → `raw`

Primeira sincronização completa do corte comercial, doze tabelas, em máquina de 4 CPUs com o
dimensionamento de [`airbyte/values.yaml`](../airbyte/values.yaml).

| Medida | Valor |
|---|---:|
| Linhas ingeridas | 165.553 |
| Bytes transferidos | 41,2 MB |
| **Tempo da sincronização** | **2 min 6 s** |
| Reconciliação `raw` ↔ `staging` | 12 de 12 tabelas exatas |
| `dbt build` da camada `staging` | 12 modelos + 69 testes em 5,0 s |

As contagens em `raw` batem exatamente com a origem em todas as tabelas, incluindo as 110.000 linhas
de `cart_items`. As linhas com exclusão lógica atravessam como marca e são contáveis: 6 clientes,
8 SKUs, 2 produtos e 1 endereço.

### 2.3 Medido na Etapa 5 — fluxo completo pelo orquestrador

A DAG do caminho frio executada de ponta a ponta, em máquina de 4 CPUs com Airbyte e Airflow
simultaneamente de pé. A primeira coluna é a medição da Etapa 5, com 12 fluxos de ingestão; a
segunda é a da Etapa 6, com 27; a terceira é a da Etapa 8, com 30 e uma tarefa a mais — a
quarentena, que estreou como camada.

| Tarefa | Etapa 5 | Etapa 6 | Etapa 8 | Etapa 9 |
|---|---:|---:|---:|---:|
| `sincronizar_oltp_para_raw` (incremental) | 1 min 20 s | 1 min 32 s | 1 min 37 s | 1 min 31 s |
| `dbt_seed` · `dbt_staging` · `dbt_trusted` | 16 s · 13 s · 11 s | 18 s · 15 s · 10 s | 15 s · 15 s · 13 s | 16 s · 16 s · 12 s |
| `dbt_quarantine` | — | — | 7 s | 7 s |
| `dbt_snapshots` · `dbt_analytics` · `dbt_consumption` | 10 s · 15 s · 10 s | 8 s · 18 s · 10 s | 8 s · 21 s · 10 s | 8 s · 20 s · 9 s |
| `dbt_docs` | 13 s | 16 s | 13 s | 16 s |
| **Total da execução** | **2 min 53 s** | **3 min 12 s** | **3 min 25 s** | **3 min 21 s** |
| **Tarefas** | 8 | 8 | 9 | 9 |

Dobrar o número de fluxos e passar de 36 para 53 modelos custou **19 segundos** entre as Etapas 5 e
6. A Etapa 8 acrescentou três fluxos de ingestão, catorze modelos, uma *seed* e a camada
`quarantine`, e custou **13 segundos** sobre a Etapa 6. A Etapa 9 acrescentou seis fluxos, dezoito
modelos, dois *snapshots* SCD tipo 2 e mais uma *seed*, e **não custou nada** — 4 segundos a menos,
dentro da variação entre execuções.

É a evidência do que as três medições vinham sugerindo: o que domina é a **sincronização**, não a
transformação. Ela é 45% do tempo total, e o `dbt` inteiro — 485 objetos, 371 testes — roda em menos
de 30 segundos. Foi essa proporção que o caminho quente da Etapa 7 atacou, tirando o estoque do
caminho crítico.

Memória com o *batch* de pé — três bancos, cluster do Airbyte e os quatro contêineres do Airflow:
cerca de **6 GB**. Com o caminho quente junto, o número da Etapa 7 é **8 GB** (§2.4).

### 2.4 Medido na Etapa 7 — o caminho quente

O [ADR-0020](adr/0020-debezium-sobre-kafka-connect.md) aceitou o Kafka Connect prevendo *"cerca de
1 GB de memória a mais"*. A previsão era pessimista por quase o dobro:

| Serviço | Memória residente |
|---|---|
| Redpanda | **51 MB** |
| Kafka Connect com o conector Debezium | **434 MB** |
| **Os dois juntos** | **485 MB** |

O Redpanda reserva 1 GB por configuração (`--memory=1G` em `docker-compose.streaming.yml`), e usa
5% disso nesta escala; o Connect roda com teto de heap de 768 MB declarado no mesmo arquivo. Sem
esses dois limites os dois serviços dimensionam-se pela memória da máquina, e aí a previsão do ADR
estaria certa.

O `pipeline` Beam roda **fora** dos contêineres, no processo Python do host, e leva junto o
executor Prism em processo próprio.

| Observação do fluxo | Valor |
|---|---|
| Movimentos entregues pelo *snapshot* inicial | 13.746 |
| Tempo para atravessar o *snapshot* inteiro | ~4 min, em lotes de 500 |
| Eventos ao vivo produzidos | 2.200, a 43–55 eventos/s |
| Linhas em `raw.inventory_movements_stream` | 15.946 |
| Objetos dbt construídos, com os dois caminhos | **262, zero erro** |
| DAG `fluxo_batch` com o caminho quente em operação | 3 min 10 s — contra 3 min 12 s na Etapa 6 |

**Memória com tudo simultaneamente de pé** — três bancos, cluster do Airbyte, quatro contêineres do
Airflow, Redpanda, Kafka Connect e o *pipeline* Beam com o Prism: cerca de **8 GB**. É o número a
usar para dimensionar a máquina da fase local, e é o estado que a Etapa 12 exige; nas demais, o
[Execução Local §5](execucao_local.md#5-executando-por-partes) diz o que basta subir.

O tempo do *snapshot* é dominado pela escrita em lote e pelo autocheckpoint do executor local, não
pelo transporte. Como avisa o [Streaming §2.1](streaming.md#21-limites-honestos-da-execução-local),
medição de latência no executor local vale como ordem de grandeza, nunca como desempenho.

### 2.5 A restrição real passou a ser memória — e, na Etapa 5, CPU

**Correção do que estava escrito aqui.** Até a Etapa 5, este documento afirmava que a restrição do
ambiente local era memória. A ingestão mostrou que é **CPU**: o *pod* de replicação do Airbyte pede
4 CPUs por padrão, a máquina tem 4, e a plataforma já segura 1,1 — o job nunca é agendado. Memória
nunca chegou a ser o limite.

O tratamento está em [`airbyte/values.yaml`](../airbyte/values.yaml): pedidos de 100m por
contêiner, limites altos. Pedido é reserva do agendador, limite é teto — baixar o pedido não torna
a carga mais lenta em máquina ociosa.

#### Memória

Com o disco fora de questão, a memória é o segundo limite do ambiente local. O
[ADR-0020](adr/0020-debezium-sobre-kafka-connect.md) adotou Kafka Connect, que custa cerca de 1 GB
de RAM a mais que a alternativa autônoma — custo aceito por **P10**.

Tratamento, que é o do risco **R11**: os alvos do `Makefile` sobem apenas o subconjunto necessário à
etapa em curso. *Batch* e *streaming* não precisam estar no ar simultaneamente, exceto na validação
final da Etapa 12.

### 2.6 Custo da janela na nuvem

O [ADR-0024](adr/0024-airbyte-e-airflow-no-gcp.md) escolheu Cloud Composer e Airbyte em contêiner,
que cobram por hora ligada. A contenção é temporal, não técnica: os dois existem **apenas durante a
janela de demonstração da Etapa 13**, criados e destruídos pelo mesmo Terraform.

O custo estimado é registrado antes de subir e o custo real depois — planejado e medido, rotulados
como tais. É o tratamento do risco **R9**.

---

## 3. Ponto único de recuperação

Após uma execução ponta a ponta aprovada, o projeto mantém **um único *snapshot* lógico *last known
good***, em formato customizado e comprimido do `pg_dump`. Ele permite restaurar uma fonte degradada
e reconstruir as demais camadas.

### 3.1 Conteúdo do pacote

- `source_db.dump`;
- `legacy_db.dump`;
- *checksums* dos arquivos;
- `seed`, `as_of_date` e versão das migrações;
- último `event_sequence` emitido;
- *commit* Git correspondente ao código aprovado;
- manifesto com contagens e tamanhos por tabela;
- instruções testadas de restauração e de reconstrução do `warehouse_db`.

### 3.2 O cursor de CDC não está no pacote — e por quê

O [ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md) colocou *offsets*, histórico de
schema e status nos tópicos internos do Redpanda, geridos pelo conector. Guardar uma cópia no pacote
criaria duas verdades sobre a mesma posição.

Há uma consequência operacional que não é óbvia: **restaurar `source_db` de um dump invalida o
cursor do conector.** A posição de WAL gravada nos tópicos internos aponta para um ponto do log que
o banco restaurado não tem. O procedimento correto após uma restauração é **descartar o estado do
conector e deixá-lo refazer o *snapshot* inicial** — não tentar retomar de onde parou.

Como o destino do *streaming* é idempotente por chave de evento
([ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md)), refazer o *snapshot* reprocessa
eventos já vistos sem duplicar saldo. É essa propriedade que torna a recuperação segura.

### 3.3 Regras

- O `warehouse_db` **não** entra no pacote: é refeito por Airbyte, dbt e Airflow a partir das duas
  fontes restauradas. Incluí-lo duplicaria armazenamento sem ganho.
- O pacote **não é versionado no Git**.
- Um novo *snapshot* só substitui o anterior depois que migrações, pipeline, testes,
  reconciliações, *checksums* e uma **validação de restauração** forem concluídos.
- Durante a troca pode haver espaço temporário para o anterior e o candidato; ao final, somente o
  aprovado é retido.
- A restauração **altera o estado dos bancos** e só é executada mediante decisão explícita do
  responsável técnico.
