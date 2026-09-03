# Registro de Decisões (ADR)

> **O que vive aqui:** as decisões do projeto — as tomadas (um arquivo ADR cada) e as ainda
> abertas (tabela da seção 3, com as opções em avaliação).
>
> **O que não vive aqui:** a arquitetura resultante (ver [Arquitetura](../arquitetura.md)) e a
> ordem de execução (ver [Plano de Desenvolvimento](../plano_de_desenvolvimento.md)).

Um **ADR** registra uma decisão relevante, o contexto que a motivou, as alternativas consideradas e
as consequências aceitas. O objetivo não é documentar o que foi feito, e sim **por que** — de modo
que a decisão possa ser revista com conhecimento de causa, inclusive na replicação para o GCP.

---

## 1. Como funciona

1. Enquanto a escolha está aberta, ela é uma **decisão pendente** (`Dnn`) na tabela da seção 3.
2. Quando é decidida, nasce um arquivo `NNNN-titulo-em-kebab-case.md` a partir do
   [`0000-template.md`](0000-template.md), e a pendência sai da tabela.
3. Um ADR aceito **nunca é apagado nem reescrito**. Se for revertido, passa a `Substituída` e o
   novo ADR referencia o anterior.
4. Toda *mudança relevante*, no sentido do [Termo de Abertura](../../Abertura_de_projeto.md), exige
   um ADR.
5. Todo ADR declara a sua **contrapartida na fase GCP**. Decisão sem equivalente na nuvem não é
   aceitável (princípio **P4**).

**Estados:** `Proposta` · `Aceita` · `Rejeitada` · `Substituída`

---

## 2. Decisões registradas

| ADR | Título | Estado | Resolve |
|---|---|---|---|
| [0001](0001-registrar-decisoes-em-adr.md) | Registrar decisões de arquitetura em ADR | Aceita | — |
| [0002](0002-dominio-marketplace-omnichannel.md) | Adotar um marketplace de varejo *omnichannel* como domínio | Aceita | D01 |
| [0003](0003-stack-airbyte-dbt-airflow.md) | Adotar Airbyte, dbt e Airflow desde a fase local | Aceita | D06, D07, D08 |
| [0004](0004-terraform-como-iac.md) | Usar Terraform para levar o ambiente local ao GCP | Aceita | D12 |
| [0005](0005-geracao-com-faker-orientada-a-configuracao.md) | Gerar dados com Faker por meio de um motor orientado a configuração | Aceita | D05 |
| [0006](0006-streaming-de-estoque-com-cdc-e-beam.md) | Incluir um fluxo de streaming de estoque com CDC e Apache Beam | Aceita | Mecanismo de baixa latência |
| [0007](0007-catalogo-como-codigo.md) | Manter o catálogo de dados como código | Aceita | Ferramenta de catálogo local |
| [0008](0008-schemas-do-armazem.md) | Fixar os schemas do armazém e separar estágio de schema | Aceita | D02 |
| [0009](0009-sqlalchemy-para-acesso-a-dados.md) | Usar SQLAlchemy para o acesso a dados em Python | Aceita | D03 |
| [0010](0010-alembic-para-migracoes.md) | Usar Alembic para as migrações de schema | Aceita | D04 |
| [0011](0011-classificacao-e-papeis-de-acesso.md) | Fixar os níveis de classificação e os papéis de acesso | Aceita | D09 |

---

## 3. Decisões pendentes

A coluna **Etapa** indica quando a decisão precisa estar fechada, conforme o
[Plano de Desenvolvimento](../plano_de_desenvolvimento.md).

### Arquitetura e repositório

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D10** | Estrutura de diretórios do repositório | Proposta da [Arquitetura](../arquitetura.md#7-organização-do-repositório) · estrutura orientada a pacote Python instalável | 2 |
| **D13** | Padrão de nomenclatura de objetos de banco | Prefixos por tipo (`stg_`, `dim_`, `fact_`) · sufixos · sem afixos, separação apenas por schema | 3 |

### Ingestão e transformação

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D20** | Quais tabelas sincronizam por carga completa e quais por incremental | Por volume · por presença de coluna de atualização confiável · incremental apenas nas tabelas de evento | 5 |
| **D21** | Tratamento de exclusões na origem e de atualizações tardias | *Soft delete* propagado · marcação na camada `raw` · reconciliação periódica | 5 |
| **D23** | Materializações dbt de `staging`, `trusted` e `analytics` | Views em `staging` e `trusted`, tabelas em `analytics` (candidata, exigida pelo orçamento) · incremental nas fatos de maior volume | 5 |

### Modelagem dimensional

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D24** | Atributos e medidas de cada tabela fato | A definir por fato, a partir das perguntas de negócio | 5 |
| **D25** | Chaves substitutas e estratégia SCD | *Hash* determinístico da chave natural · sequência · chave natural composta | 5 |
| **D27** | Primeiras views de consumo e seus contratos | A definir a partir do [Glossário de Negócio](../glossario_de_negocio/) | 5 |

### Streaming

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D16** | Materialização do saldo em tempo real e da view unificada | Tabela de deltas + view · tabela agregada por janela · modelo incremental dbt | 7 |
| **D17** | Semântica de entrega alvo, meta de latência e tamanho da janela | Janela de 1 minuto (candidata) · janela deslizante · *allowed lateness* a calibrar | 7 |
| **D18** | Como o cursor de CDC é armazenado e recuperado | *Offset* no transporte · tabela de controle no `warehouse_db` · estado do conector | 7 |
| **D29** | Forma de implantação do Debezium | Debezium Server autônomo (menor consumo de memória) · Kafka Connect (mais configurável) | 7 |

### Origem legada

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D15** | Chave de procedência que impede colisão no empilhamento entre origens | `source_system` + chave natural · chave substituta por origem · *hash* composto | 10 |
| **D28** | Dicionário de conversões determinísticas e motivos de rejeição | A aprovar a partir do [catálogo de falhas](../origem_legada.md#31-catálogo-de-falhas-obrigatórias) | 10 |

### Governança e volume

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D26** | Perfis de volume definitivos | Recalibração de `demo_4gb` após a primeira medição real | 4 |
| **D14** | Escopo do schema `governance`, sem duplicar metadados já mantidos pelo dbt | Apenas objetos de controle e auditoria · nenhum schema, tudo no dbt · tabelas de resultado de reconciliação | 11 |

### Fase GCP

| ID | Decisão | Opções em avaliação | Etapa |
|---|---|---|---|
| **D11** | Viabilidade do Airbyte no GCP e serviço de carga | Airbyte gerenciado · Airbyte em contêiner no GCP · serviço nativo de carga | 13 |
| **D22** | Serviço de execução do Airflow no GCP | Cloud Composer · Airflow em contêiner gerenciado · orquestração nativa | 13 |
