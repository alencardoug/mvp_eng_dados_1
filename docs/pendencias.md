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
| Aprovações pendentes | 1 |
| Decisões pendentes | 22 |
| Última revisão | 01/09/2026 |

---

## 1. Aprovações

| # | O que | Onde | Bloqueia |
|---|---|---|---|
| A1 | **Aprovar o Termo de Abertura v1.1** | [Abertura_de_projeto.md](../Abertura_de_projeto.md) | Marco **M0** e todo o resto |
| A2 | Confirmar a saída de **riscos** e **princípios** do Termo para artefatos próprios | [riscos.md](riscos.md), [principios.md](principios.md) | Fechamento da Etapa 0 |
| A3 | Confirmar a estrutura de 28 artefatos e o mapa da documentação | [README.md](../README.md) | Fechamento da Etapa 0 |

## 2. Decisões que travam o início do código

Nenhuma linha de código deve ser escrita antes destas quatro. Todas na Etapa 1.

| ID | Pergunta | Bloqueia |
|---|---|---|
| **D02** | Quais são os nomes e a quantidade definitiva das camadas? | Etapas 5 a 7 |
| **D03** | Acesso a dados em Python: driver puro ou ORM? | Etapas 4 a 7 |
| **D04** | Qual ferramenta de migração de schema? | Etapa 3 |
| **D09** | Confirmar o esquema de classificação de sensibilidade e as regras de acesso por camada | Etapa 11 |

Opções e argumentos de cada uma em [decisões pendentes](adr/README.md#3-decisões-pendentes).

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
| Q3 | O objetivo de portfólio pede volume (`cart_items` acima de 1 milhão de linhas); o objetivo de aprendizado pede ciclos rápidos. Confirmar que o perfil `smoke` será o padrão de desenvolvimento e o `demo_4gb` só em validação | Define o ritmo de trabalho de todas as etapas |
| Q4 | A geração assistida por IA torna barato produzir 40 tabelas, centenas de testes e todos os metadados — mas a revisão continua sendo humana e é o gargalo real (risco **R14**). Confirmar que revisar por amostragem é aceitável, ou definir o que exige revisão integral | Define o que significa "revisado" na definição de pronto |

## 5. Do lado do assistente

Nada pendente. A Etapa 0 está entregue: 28 artefatos, sem duplicação, links e identificadores
verificados. O trabalho retoma quando A1 for aprovado e as quatro decisões da seção 2 estiverem
fechadas.

---

**Como manter este documento:** um item sai daqui quando é aprovado ou decidido — decisão vira ADR,
questão vira linha em documento existente. Se um item envelhece sem resposta, ele é revisto ao
final de cada etapa, junto com o [Registro de Riscos](riscos.md).
