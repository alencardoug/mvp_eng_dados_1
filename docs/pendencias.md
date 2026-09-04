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
| Etapa atual | Etapa 5 — Corte 1: núcleo comercial |
| Aprovações pendentes | 0 |
| Decisões pendentes | 0 |
| Última revisão | 04/09/2026 |

---

## 1. Nada pendente

**Não há nada esperando você.** A **D30** foi fechada em 04/09/2026 pelo
[ADR-0029](adr/0029-exclusao-logica-como-marca-na-dimensao.md). Em 04/09/2026 o Termo de Abertura foi aprovado, as três aprovações
foram dadas, as dezoito decisões abertas foram fechadas em ADR e as três questões que não eram ADR
foram resolvidas nos documentos que as tratam.

Os marcos **M0** (Termo aprovado), **M1** (decisões registradas) e **M2** (ambiente reproduzível)
estão fechados, e as Etapas 3 e 4 foram entregues. A Etapa 5 está em curso; **D30**, acima, é a
única coisa que depende de você.

## 2. Onde cada item foi parar

Registro de encerramento, para que nenhuma decisão pareça ter sumido.

### Aprovações

| # | O que | Resultado |
|---|---|---|
| A1 | Termo de Abertura | **Aprovado em 04/09/2026** — [Termo](../Abertura_de_projeto.md) v1.2, §11 |
| A2 | Riscos e princípios em artefatos próprios | Confirmado — [Riscos](riscos.md) e [Princípios](principios.md) permanecem separados |
| A3 | Estrutura de artefatos e mapa da documentação | Confirmado, com a contagem de artefatos removida: a tabela do [README](../README.md) é a fonte |

### Decisões

As dezoito foram fechadas em quatorze ADRs temáticos, **0012** a **0025**. A correspondência está na
seção 2 do [Registro de Decisões](adr/README.md), coluna *Resolve*.

Depois delas, duas escolhas novas surgiram durante a construção e foram decididas por você na hora,
com as alternativas na mesa: o ambiente Python ([ADR-0026](adr/0026-uv-para-ambiente-e-dependencias.md))
e o formato e o piso da configuração do gerador
([ADR-0027](adr/0027-configuracao-do-gerador-em-yaml.md)).

### Questões que não eram ADR

| # | Questão | Resultado |
|---|---|---|
| Q1 | *Policy tags* aplicadas à mão ou por automação | Escopo aberto para CI/CD mínimo — [ADR-0025](adr/0025-policy-tags-por-fluxo-automatizado.md), com federação de identidade como condição |
| Q2 | Orçamento de 4 GB e conforto do ambiente local | Premissa substituída: alto volume passa à fase GCP, e o ambiente local é dimensionado por cobertura — [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) e [Termo](../Abertura_de_projeto.md) §8 |
| Q3 | Perfil padrão de desenvolvimento | Absorvida pela Q2: os perfis antigos foram aposentados pelo [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) |
| Q4 | O que significa "revisado" na definição de pronto | Revisão integral do declarativo, amostragem no derivado — [`CLAUDE.md`](../CLAUDE.md) §5 e §7 |

## 3. Do lado do assistente

Nada pendente. Cada ADR foi registrado com os índices e os documentos afetados atualizados na mesma
entrega. O trabalho prossegue na Etapa 5.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
