# Pendências do Owner

> **O que vive aqui:** o que está parado **esperando decisão sua** — aprovações, decisões
> bloqueantes e questões em aberto —, em ordem de urgência.
>
> **O que não vive aqui:** as opções de cada decisão e o seu contexto (ver
> [Registro de Decisões](adr/README.md)); os critérios de conclusão das etapas (ver
> [Plano de Desenvolvimento](plano_de_desenvolvimento.md)). Esta é uma **vista por responsável**,
> não uma segunda cópia do conteúdo.

| Campo | Informação |
|---|---|
| Etapa atual | Etapa 0 — Fundação documental |
| Aprovações pendentes | 3 |
| Decisões pendentes | 18 |
| Última revisão | 03/09/2026 |

---

## 1. Aprovações

| # | O que | Onde | Bloqueia |
|---|---|---|---|
| A1 | **Aprovar o Termo de Abertura v1.1** | [Abertura_de_projeto.md](../Abertura_de_projeto.md) | Marco **M0** e todo o resto |
| A2 | Confirmar a saída de **riscos** e **princípios** do Termo para artefatos próprios | [riscos.md](riscos.md), [principios.md](principios.md) | Fechamento da Etapa 0 |
| A3 | Confirmar a estrutura de 28 artefatos e o mapa da documentação | [README.md](../README.md) | Fechamento da Etapa 0 |

## 2. Decisões que travavam o início do código

*Fechadas em 03/09/2026.* As quatro decisões da Etapa 1 estão registradas e nenhuma delas bloqueia
mais nada:

| ID | Decisão | ADR |
|---|---|---|
| **D02** | Sete schemas, com `governance` condicionado a D14 | [ADR-0008](adr/0008-schemas-do-armazem.md) |
| **D03** | SQLAlchemy, com os modelos como fonte de verdade do schema | [ADR-0009](adr/0009-sqlalchemy-para-acesso-a-dados.md) |
| **D04** | Alembic, derivando as migrações dos modelos | [ADR-0010](adr/0010-alembic-para-migracoes.md) |
| **D09** | Quatro níveis de classificação e cinco papéis de acesso | [ADR-0011](adr/0011-classificacao-e-papeis-de-acesso.md) |

O que resta para a Etapa 1 fechar é a aprovação **A1**.

## 3. Decisões das etapas seguintes

Não precisam de resposta agora — precisam estar fechadas **antes** da etapa correspondente começar.

| Etapa | Decisões | Assunto |
|---|---:|---|
| 2 | **D10** | Estrutura de diretórios do repositório |
| 3 | **D13** | Padrão de nomenclatura de objetos de banco |
| 4 | **D26** | Perfis de volume definitivos, após a primeira medição |
| 5 | **D20, D21, D23, D24, D25, D27** | Carga incremental, exclusões, materializações, medidas, chaves substitutas e primeiras views |
| 7 | **D16, D17, D18, D29** | Saldo em tempo real, semântica de entrega, cursor de CDC e implantação do Debezium |
| 10 | **D15, D28** | Procedência no empilhamento e dicionário de conversões do legado |
| 11 | **D14** | Escopo do schema `governance` |
| 13 | **D11, D22** | Airbyte e execução do Airflow no GCP |

## 4. Questões em aberto que não são ADR

Pontos que surgiram da revisão crítica das propostas e que precisam da sua posição, mas não são
decisões de arquitetura.

| # | Questão | Por que importa |
|---|---|---|
| Q1 | O Termo mantém **CI/CD de infraestrutura fora do escopo**, mas a aplicação automática de *policy tags* no BigQuery a partir do YAML é, na prática, um passo de CI/CD. Manter como script manual na Etapa 13, ou abrir o escopo? | Define se a governança na nuvem é aplicada por comando ou por automação |
| Q2 | O orçamento de **4 GB** foi herdado da proposta original, mas Airbyte, Airflow, Redpanda e Debezium juntos podem tornar o perfil `demo_4gb` desconfortável na sua máquina. Confirmar que 8 GB de disco livre e a memória disponível são suficientes, ou reduzir o perfil | Evita descobrir o problema só na Etapa 5 |
| Q4 | A geração assistida por IA torna barato produzir 40 tabelas, centenas de testes e todos os metadados — mas a revisão continua sendo humana e é o gargalo real (risco **R14**). Confirmar que revisar por amostragem é aceitável, ou definir o que exige revisão integral | Define o que significa "revisado" na definição de pronto |

## 5. Do lado do assistente

Nada pendente. As quatro decisões da Etapa 1 estão registradas em ADR e os documentos afetados
foram atualizados na mesma entrega. O trabalho retoma na Etapa 2 assim que **A1** for aprovado.

**Resolvido junto:** a questão **Q3** — `smoke` passa a ser o perfil padrão de desenvolvimento em
todas as etapas, com uma medição única no fim da Etapa 4 e o `demo_4gb` reservado à Etapa 12.
O critério do milhão de linhas migrou da Etapa 4 para a Etapa 12 no
[plano](plano_de_desenvolvimento.md).

---

**Como manter este documento:** um item sai daqui quando é aprovado ou decidido — decisão vira ADR,
questão vira linha em documento existente. Se um item envelhece sem resposta, ele é revisto ao
final de cada etapa, junto com o [Registro de Riscos](riscos.md).
