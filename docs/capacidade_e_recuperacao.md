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
| Versão | 2.2 |
| Situação | Vigente. Origem transacional (Etapa 4) e ingestão (Etapa 5) **medidas**; as demais camadas, não |
| Última revisão | 04/09/2026 |

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

### 2.3 A restrição real passou a ser memória — e, na Etapa 5, CPU

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

### 2.4 Custo da janela na nuvem

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
