# Glossário Técnico

> **O que vive aqui:** os termos de engenharia de dados usados no projeto, definidos de forma
> curta e ancorados no que este repositório faz com eles.
>
> **O que não vive aqui:** conceitos de negócio do varejo (ver
> [Glossário de Negócio](glossario_de_negocio/)); nomes de tabelas (ver
> [Modelo de Dados](modelo_de_dados.md)).

Este glossário existe para que nenhum documento use um termo técnico sem definição acessível: cada
termo entra aqui na primeira vez que é usado.

---

## Modelagem

**Normalização / 3FN** — organização das tabelas transacionais para eliminar redundância: cada
fato não-chave depende da chave, da chave inteira e de nada além dela. É a referência do
`source_db`; desvios exigem justificativa escrita.

**Grão** — o que exatamente uma linha de uma tabela fato representa. Declarar o grão antes de
escrever o modelo é a decisão mais importante da modelagem dimensional; quase todo erro em
*datamart* nasce de grão mal definido.

**Esquema estrela** — uma tabela fato central cercada por dimensões, sem normalizar as dimensões.
Otimiza leitura analítica, não escrita transacional.

**Fato transacional** — registra um evento que aconteceu (uma venda, um pagamento). Todas as 9
fatos do projeto são deste tipo — não há fatos do tipo *snapshot*.

**Dimensão conformada** — dimensão compartilhada por várias fatos com o mesmo significado, o que
permite comparar métricas de processos diferentes (`dim_date`, `dim_geography`).

**Dimensão degenerada** — identificador operacional guardado na própria fato, sem dimensão
própria (`order_number`, `tracking_number`).

**SCD (Slowly Changing Dimension)** — como a dimensão trata mudança de atributo. **Tipo 1**
sobrescreve e perde histórico; **tipo 2** cria nova linha com período de vigência e preserva o
histórico. Intervalos de tipo 2 nunca podem se sobrepor para a mesma chave natural.

**Chave substituta** — chave técnica gerada pelo armazém, independente da chave natural da origem,
que permite ao SCD tipo 2 ter várias linhas para a mesma entidade.

---

## Pipeline

**Camada** — estágio nomeado e fisicamente separado do fluxo (`raw`, `staging`, `trusted`,
`analytics`). Cada camada tem transformações permitidas e consumidores definidos.

**Materialização** — como o dbt persiste um modelo: `view` (só a consulta), `table` (dados
gravados), `ephemeral` (embutido em quem o usa) ou `incremental` (acrescenta apenas o novo). A
escolha define diretamente o consumo de disco.

**Idempotência** — reexecutar o mesmo processo produz o mesmo resultado, sem duplicar nem perder
dados. É requisito de toda carga do projeto.

**Backfill** — carga histórica inicial, executada antes de o fluxo incremental assumir.

**Reconciliação** — conferência de que as contagens fecham entre camadas adjacentes. É o teste que
prova que nada foi criado nem perdido no caminho.

**Quarentena** — destino dos registros que não puderam ser aceitos nem corrigidos com segurança.
Não é descarte: é evidência preservada com o motivo da rejeição.

**Procedência** — informação que identifica de qual origem um registro veio, indispensável quando
duas fontes são empilhadas na mesma camada.

**Invariante** — regra que deve ser sempre verdadeira sobre os dados. Aqui, cada invariante é ao
mesmo tempo regra de geração e teste automatizado.

**Oráculo de teste** — fonte independente que diz qual seria a resposta certa. No tratamento do
legado, é o manifesto do gerador — que a transformação nunca consulta.

**Schema-on-write / schema-on-read** — validar a estrutura na escrita (origem principal, tipos
estritos) ou apenas na leitura (origem legada, tudo `text`). O projeto exercita os dois.

**Seed** — semente que torna a geração aleatória determinística: mesma `seed`, mesmos dados.

---

## Streaming

**CDC (Change Data Capture)** — capturar mudanças lendo o log de transações do banco, em vez de
consultar a tabela repetidamente. Evita *polling* pesado sobre a origem.

**WAL** — o log de escrita antecipada do PostgreSQL, de onde o CDC lê as mudanças confirmadas.

**LSN (Log Sequence Number)** — a posição de um registro dentro do WAL. Serve como cursor de
leitura do CDC e como chave estável de deduplicação.

**Arquitetura Lambda** — caminho *batch* e caminho contínuo coexistindo, unificados na leitura por
uma view. É o desenho adotado aqui: o dbt produz a fotografia periódica e o streaming acrescenta os
deltas recentes.

**Arquitetura Kappa** — variante em que **tudo** passa pelo caminho de eventos, sem *batch*
separado. Não é o desenho deste projeto; aparece como contraste ao entender por que a Lambda foi
escolhida.

**Tempo de evento × tempo de processamento** — o momento em que o fato ocorreu contra o momento em
que a mensagem chegou. O pipeline agrega por tempo de evento; é isso que mantém o resultado estável
quando a ordem de chegada não corresponde à ordem dos fatos.

**Janela** — intervalo de tempo de evento sobre o qual uma agregação é calculada.

**Watermark** — estimativa de até que ponto no tempo de evento o fluxo já viu tudo o que deveria.
Fecha janelas sem esperar para sempre.

**Allowed lateness** — quanto tempo depois do fechamento uma janela ainda aceita eventos atrasados
e recalcula o resultado.

**At least once / exactly once** — garantias de entrega. O transporte oferece *at least once*
(pode repetir); a idempotência do consumidor é o que produz o efeito de *exactly once*.

**Deduplicação** — descartar reentregas usando uma chave estável, aqui a `idempotency_key`.

**Evento compensatório** — corrigir um livro *append-only* inserindo um evento que anula o efeito
do anterior, em vez de alterar o registro original.

---

## Governança

**Catálogo** — inventário dos objetos de dados com descrição e responsável.

**Dicionário de dados** — descrição campo a campo: tipo, obrigatoriedade, significado e
classificação.

**Linhagem** — o caminho de um dado da origem até o consumo, coluna a coluna.

**Classificação de sensibilidade** — nível atribuído a cada campo, que determina como ele pode ser
exposto.

**PII** — dado pessoal identificável. No projeto, sempre sintético, mas classificado e tratado como
se fosse real.

**Policy tag** — no BigQuery, etiqueta ligada ao IAM que **bloqueia** o `SELECT` sobre uma coluna
para quem não tem permissão. É a classificação deixando de ser documental.

**Catálogo como código** — manter catálogo e glossário em arquivos versionados no repositório, em
vez de em um sistema separado.

**ADR** — registro de uma decisão de arquitetura: contexto, alternativas, decisão e consequências.

---

## Ferramentas

| Ferramenta | Papel no projeto |
|---|---|
| **PostgreSQL** | Bancos de origem, legado e armazém na fase local |
| **Faker** | Geração de valores sintéticos plausíveis |
| **Airbyte** | Ingestão das origens para as camadas `raw` |
| **dbt** | Transformação, testes, documentação e linhagem |
| **dbt-expectations** | Pacote de testes de dados além dos nativos do dbt |
| **Airflow** | Orquestração do fluxo *batch* |
| **Debezium** | Captura de mudanças a partir do WAL do PostgreSQL |
| **Redpanda** | Transporte de eventos compatível com Kafka, leve para uso local |
| **Apache Beam** | Pipeline de processamento contínuo, portável entre executores |
| **DirectRunner** | Executor local do Beam |
| **Terraform** | Provisionamento da infraestrutura GCP |
| **Cloud SQL** | PostgreSQL gerenciado na fase GCP |
| **BigQuery** | Armazém analítico na fase GCP |
| **Datastream** | CDC gerenciado na fase GCP |
| **Pub/Sub** | Transporte de eventos na fase GCP |
| **Dataflow** | Execução gerenciada do mesmo pipeline Beam |
| **Dataplex** | Catálogo corporativo na fase GCP |

**Particionamento** — dividir uma tabela do BigQuery por data para que a consulta leia apenas as
partições necessárias, reduzindo custo.

**Clustering** — ordenar fisicamente os dados dentro da partição pelas colunas mais filtradas.
