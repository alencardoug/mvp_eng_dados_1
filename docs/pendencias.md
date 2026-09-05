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
| Etapa atual | Etapa 8 — Corte 4: entrega e logística |
| Aprovações pendentes | 0 |
| Decisões pendentes | 0 |
| Última revisão | 05/09/2026 |

---

## 1. Nada pendente

**Não há nada esperando você.** As duas decisões que a Etapa 8 levantou foram fechadas na abertura
dela, em 05/09/2026, nos [ADR-0033](adr/0033-entrega-medida-em-dois-graos.md) — o grão em que a
entrega é medida — e [ADR-0034](adr/0034-entrega-do-livro-de-eventos.md) — a procedência da data
realizada. As da Etapa 7 foram fechadas em 04/09/2026 nos
[ADR-0031](adr/0031-aterrissagem-do-caminho-quente-em-raw.md) e
[ADR-0032](adr/0032-fonte-python-no-lugar-do-kafkaio.md). Todas por interrogatório com alternativas.

Os marcos **M0** (Termo aprovado), **M1** (decisões registradas), **M2** (ambiente reproduzível),
**M3** (primeiro fluxo completo) e **M4** (*streaming* em operação) estão fechados. As Etapas 3 a 7
foram entregues, e a próxima é a **Etapa 8 — Corte 4: entrega e logística**.

O único número que o projeto ainda carregava rotulado como **não medido** — o *allowed lateness* do
[ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md) — foi medido na Etapa 7, e a
medição derrubou a hipótese: 300 s ficavam abaixo da mediana do atraso real. O valor vigente é
1200 s ([Streaming §3.3](streaming.md#33-eventos-atrasados)).

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

Depois delas, cada etapa trouxe escolhas novas, decididas por você na hora com as alternativas na
mesa — do ambiente Python ([ADR-0026](adr/0026-uv-para-ambiente-e-dependencias.md)) ao grão da
medição de entrega ([ADR-0033](adr/0033-entrega-medida-em-dois-graos.md)). Todas estão na seção 2 do
[Registro de Decisões](adr/README.md).

### Questões que não eram ADR

| # | Questão | Resultado |
|---|---|---|
| Q1 | *Policy tags* aplicadas à mão ou por automação | Escopo aberto para CI/CD mínimo — [ADR-0025](adr/0025-policy-tags-por-fluxo-automatizado.md), com federação de identidade como condição |
| Q2 | Orçamento de 4 GB e conforto do ambiente local | Premissa substituída: alto volume passa à fase GCP, e o ambiente local é dimensionado por cobertura — [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) e [Termo](../Abertura_de_projeto.md) §8 |
| Q3 | Perfil padrão de desenvolvimento | Absorvida pela Q2: os perfis antigos foram aposentados pelo [ADR-0014](adr/0014-volume-por-proporcoes-e-fator-de-escala.md) |
| Q4 | O que significa "revisado" na definição de pronto | Revisão integral do declarativo, amostragem no derivado — [`CLAUDE.md`](../CLAUDE.md) §5 e §7 |

## 3. Do lado do assistente

Nada pendente. Cada ADR foi registrado com os índices e os documentos afetados atualizados na mesma
entrega. O trabalho prossegue na Etapa 8.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
