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
| Versão | 2.9 |
| Situação | Medições históricas até a Etapa 9 preservadas; reconstrução da D31 identificada na §2.7. Recuperação da Etapa 12 ainda não entregue |
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
| Tamanho do `source_db`, incluindo catálogo | 63,1 MB |
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

*Naquele corte ainda não medidos:* `legacy_db`, `warehouse_db`, tempo do pipeline completo e
tamanho das camadas analíticas. As medições posteriores estão nas seções seguintes (**P5**).

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

| Tarefa | Etapa 5 | Etapa 6 | Etapa 8 | Etapa 9 | Etapa 10 |
|---|---:|---:|---:|---:|---:|
| `sincronizar_oltp_para_raw` (incremental) | 1 min 20 s | 1 min 32 s | 1 min 37 s | 1 min 31 s | 2 min 37 s |
| `sincronizar_legado_para_raw_legacy` | — | — | — | — | 2 min 7 s, em paralelo |
| `dbt_seed` · `dbt_staging` · `dbt_trusted` | 16 s · 13 s · 11 s | 18 s · 15 s · 10 s | 15 s · 15 s · 13 s | 16 s · 16 s · 12 s | 19 s · 34 s · 32 s |
| `dbt_quarantine` | — | — | 7 s | 7 s | 9 s |
| `dbt_snapshots` · `dbt_analytics` · `dbt_consumption` | 10 s · 15 s · 10 s | 8 s · 18 s · 10 s | 8 s · 21 s · 10 s | 8 s · 20 s · 9 s | 8 s · 22 s · 11 s |
| `dbt_docs` | 13 s | 16 s | 13 s | 16 s | 22 s |
| **Total da execução** | **2 min 53 s** | **3 min 12 s** | **3 min 25 s** | **3 min 21 s** | **5 min 20 s** |
| **Tarefas** | 8 | 8 | 9 | 9 | 10 |

A Etapa 10 é a primeira em que o total **salta**: 5 min 20 s contra 3 min 21 s. A causa não é a
transformação — é a segunda origem. As duas capturas correm em paralelo e a mais lenta define o
piso, e a do `oltp` passou a levar 2 min 37 s por reler tudo depois da conexão ter sido recriada.
O `dbt` inteiro, agora com 812 objetos e os 40 modelos do legado, roda em 2 min 17 s.

Dobrar o número de fluxos e passar de 36 para 53 modelos custou **19 segundos** entre as Etapas 5 e
6. A Etapa 8 acrescentou três fluxos de ingestão, catorze modelos, uma *seed* e a camada
`quarantine`, e custou **13 segundos** sobre a Etapa 6. A Etapa 9 acrescentou seis fluxos, dezoito
modelos, dois *snapshots* SCD tipo 2 e mais uma *seed*, e **não custou nada** — 4 segundos a menos,
dentro da variação entre execuções.

É a evidência do que as três medições vinham sugerindo: o que domina é a **sincronização**, não a
transformação. Na medição da Etapa 9 ela era 45% do tempo total, e o `dbt` inteiro — 485 objetos,
371 testes — rodou em menos de 30 segundos. Foi essa proporção que o caminho quente da Etapa 7
atacou, tirando o estoque do caminho crítico.

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

### 2.7 Re-medição da D31 — 05/09/2026

Esta é uma **nova execução**, não uma substituição das medições históricas das Etapas 4 a 9 ou dos
ADRs aceitos. Comparação em memória: revisão anterior `509c532` contra a correção posteriormente
registrada em `522a8fc`, com `seed=20260904`, `as_of_date=2026-09-01` e fator `dev=1` iguais.
Hashes SHA-256 das colunas graváveis, ordenadas por conteúdo, localizaram mudanças em **oito**
tabelas; as outras **32** permaneceram idênticas. Contagem igual não significa conteúdo igual.

| Tabela cujo conteúdo mudou | Antes | Corrigida |
|---|---:|---:|
| `shipments` | 3.647 | 3.595 |
| `shipment_items` | 7.329 | 7.305 |
| `delivery_events` | 17.633 | 17.340 |
| `inventory_movements` | 13.746 | 13.700 |
| `inventory_balances` | 2.910 | 2.911 |
| `stock_reservations` | 4.200 | 4.200 |
| `support_tickets` | 400 | 400 |
| `ticket_events` | 1.723 | 1.723 |
| **Total das 40 tabelas** | **253.369** | **252.955** |

Dos 3.010 pedidos com remessa, **637 → 585** têm divisão; a cobertura do caso permaneceu e é
testada também no fator reduzido. O total anterior em memória não é o total da primeira medição da
Etapa 4 (253.414), nem o da origem viva antes desta manutenção (255.578): eram revisões/cortes
distintos. Não atribuir essas diferenças prévias à D31.

| Medida da nova carga inicial, antes do produtor ao vivo | Valor |
|---|---:|
| Linhas carregadas nas 40 tabelas | 252.955 |
| Remessas sem item na origem | 0 |
| Tempo de geração em memória, medido no `seed-data` | 6,5 s |
| Tempo de carga por `COPY` | 23,0 s |
| **Total do `seed-data`** | **29,5 s** |
| `source_db`, por `pg_database_size` | 60,7 MB |
| Schema `oltp`, dados + índices | 51,2 MB |
| Média por linha, com índices | 212 bytes |

Os tamanhos dessa tabela foram coletados antes de reiniciar o CDC e reconstruir o dbt, pelo
formatador de `make size-report` (divisão por 1024). O banco foi recarregado por
truncamento das tabelas, **sem** apagar seus volumes; catálogo e alocação anteriores continuam no
tamanho do banco. A saída por tabela desse alvo consulta `oltp`: “sem tabelas com dados” no
warehouse **não** significa warehouse vazio. Suas camadas precisam ser consultadas por schema.

Após o cenário ao vivo e a DAG final, a origem tinha **255.161 linhas**. A medição de banco por
`pg_database_size` deu `source_db` **62,4 MB**, `legacy_db` **7,5 MB** (sem tabelas de aplicação) e
`warehouse_db` **180,3 MB** — soma **250,2 MB**. `oltp` ocupava 55.214.080 bytes com índices.
No warehouse, a soma de `pg_total_relation_size` das relações físicas por schema foi:

| Schema | Dados + índices, bytes | Índices, bytes |
|---|---:|---:|
| `raw` | 88.915.968 | 14.958.592 |
| `trusted` | 36.995.072 | 0 |
| `snapshots` | 811.008 | 0 |
| `analytics` | 47.685.632 | 0 |
| `quarantine` | 8.192 | 0 |

Views de `staging`/`consumption` não têm armazenamento próprio. Os bytes não são uma medida isolada
do custo da correção: esta manutenção também descartou histórico SCD e estado antigo da ingestão.

| Execução observada | Tempo |
|---|---:|
| Snapshot CDC, do estado `RUNNING` do Beam até a última gravação histórica | 44,6 s |
| Intervalo entre primeira e última gravação do snapshot | 37,7 s |
| `dbt build RESET=1`, carga inicial | 56,12 s |
| `dbt build` incremental após eventos ao vivo | 36,07 s |
| Reconstrução dirigida da fato e descendentes, 20 objetos | 2,53 s |
| DAG final, início até fim no metadado do Airflow | **257,10 s — 4 min 17 s** |

Os tempos de dbt são os do `run_results.json`, não incluem a inicialização do comando; o do
snapshot não inclui a subida do Compose e não é benchmark de latência. Não generalizar uma
execução local como ganho ou regressão de desempenho do gerador.

A DAG foi `manual__2026-09-05T22:21:30.899526+00:00`, em sucesso, com nove tarefas na primeira
tentativa. Durações em segundos, preservadas do metadado:

| Tarefa | Segundos |
|---|---:|
| `sincronizar_oltp_para_raw` | 107,40 |
| `dbt_seed` | 23,77 |
| `dbt_staging` | 20,71 |
| `dbt_trusted` | 13,27 |
| `dbt_quarantine` | 10,29 |
| `dbt_snapshots` | 10,39 |
| `dbt_analytics` | 29,61 |
| `dbt_consumption` | 12,94 |
| `dbt_docs` | 21,25 |

As evidências brutas e a salvaguarda da origem anterior ficam em `data/validacoes/d31/`, ignorado
pelo Git. O dump é uma salvaguarda desta manutenção, **não** o pacote aprovado e testado da
Etapa 12. Os resultados do cenário com eventos novos, saldos e idempotência pertencem a
[Streaming §7.2](streaming.md#72-revalidação-da-d31).

### 2.8 O número de dimensionamento não incluía o ambiente de trabalho — 07/09/2026

**Correção do alcance do que está medido acima, não dos valores.** Os ~6 GB da §2.3 e os ~8 GB da
§2.4 medem o **ambiente**: contêineres, cluster e *pipeline*. Nenhum deles conta as ferramentas com
que se trabalha nesse ambiente, e é sobre a mesma memória que elas correm.

Medido durante um travamento real da máquina, com Airbyte e *streaming* simultâneos:

| Consumidor | Memória residente |
|---|---|
| Cluster do Airbyte (contêiner `kind`, `docker stats`) | **4,5 GB** |
| VS Code | 3,0 GB |
| Duas sessões de agente | 0,6 GB |
| Navegador | 0,4 GB |
| **Ambiente de trabalho, fora dos contêineres** | **~4,0 GB** |

O total do ambiente de trabalho **não é folga disponível**: numa máquina de 11,5 GB, os 8 GB da
Etapa 12 mais esses 4 GB são 12 GB. É déficit, não margem apertada — e foi o que se observou: o
`kswapd` em atividade contínua, o *load average* em 32,4 sobre 4 CPUs, o OOM *killer* disparando
151 vezes em uma hora e a sessão gráfica congelando até o botão de reinício.

Duas consequências, uma tratada e uma em aberto:

- **Tratada.** O tratamento do **R11** deixou de depender de quem lê a [Execução Local
  §5](execucao_local.md#5-executando-por-partes): `make airbyte-up`, `airflow-up` e `stream-up`
  passam por `docker/preflight.sh`, que **pausa o ambiente conflitante** antes de subir o pedido —
  ciclo de troca medido em 18 s. Recusa só resta quando nem pausar basta, e aí `FORCE=1` autoriza,
  no mesmo idioma de `seed-data` e `reset`.
- **Em aberto.** A Etapa 12 exige tudo de pé ao mesmo tempo, e nessa máquina isso não cabe com o
  ambiente de trabalho aberto. É a pendência **D36**.

Um segundo achado, estrutural, sobre o custo do Airbyte: as JVMs permanentes do cluster rodam com
`-XX:MaxRAMPercentage=75.0` dentro de um contêiner `kind` **sem limite de memória**, de modo que
cada uma dimensiona o próprio *heap* pela memória da máquina inteira. É a mesma armadilha que a §2.4
descreve para o Redpanda e o Kafka Connect — lá, resolvida por limite declarado no
`docker-compose.streaming.yml`. Foi fechada no mesmo dia pelo
[ADR-0041](adr/0041-teto-de-memoria-nos-servicos-do-airbyte.md), e o resultado está na §2.9.

### 2.9 O teto de memória do Airbyte, medido — 07/09/2026

Aplicados os tetos do [ADR-0041](adr/0041-teto-de-memoria-nos-servicos-do-airbyte.md), com
`make sync-airbyte` completando **26.093 linhas** e o contêiner do cluster amostrado a cada 10 s:

| Medida | Sem teto | Com teto |
|---|---|---|
| `server` | 662 MB | 634 MB |
| `cron` | 624 MB | 605 MB |
| `workload-api-server` | 553 MB | 455 MB |
| `workload-launcher` | 484 MB | 437 MB |
| `worker` | 480 MB | 466 MB |
| **JVMs permanentes, ocioso** | **2.803 MB** | **2.596 MB** |
| **Pico do cluster durante a sincronização** | 4,47 GiB | **4,95 GiB** |

Nenhum *pod* morto por limite, nenhum disparo do OOM *killer* na janela, sincronização bem-sucedida.
O único reinício foi do `workload-launcher`, e a causa foi conferida: `ConnectException` ao servidor
que ainda subia — ordem de inicialização, não memória. A verificação importava porque o `JAVA_OPTS`
do *chart* traz `-XX:+ExitOnOutOfMemoryError`, e OOM de *heap* apareceria como saída de código 1, não
como `OOMKilled`.

**As duas conclusões que contrariam a expectativa**, e é por isso que estão registradas:

1. **O ocioso cai pouco — 7%.** Aritmética simples: o RSS já estava abaixo dos tetos declarados, e
   teto acima do consumo não aperta nada.
2. **O pico não cai.** Ele é dominado pelos *pods de job* da sincronização, cujos limites vivem em
   `global.workloads.resources` e não foram tocados — `replication` 2Gi + `mainContainer` 2Gi +
   `sidecar` 512Mi somam mais que toda a plataforma permanente.

O número que sai daqui e muda o comportamento do ambiente é o **pico de 5,0 GB**, que passou a
dimensionar o `docker/preflight.sh`. Autorizar a subida do Airbyte pelo consumo ocioso seria
autorizar um travamento alguns minutos depois, quando a sincronização começasse.

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
([ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md)), refazer o *snapshot* não duplica
eventos de **mesmo conteúdo**. Isso não remove eventos posteriores ao dump nem substitui conteúdo
sob chave reutilizada numa regeração. Para reconstruir contra outra base, o destino quente também
precisa ser esvaziado, com consumidores parados, antes do snapshot; o procedimento de desenvolvimento
está em [Execução Local §3.2](execucao_local.md#32-regerar-uma-origem-que-já-alimenta-streaming).
Uma retomada do mesmo livro não deve ser confundida com essa reconstrução.

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
