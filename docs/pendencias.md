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
| Etapa atual | Etapa 10 — Corte 6: origem legada |
| Aprovações pendentes | 0 |
| Decisões pendentes | 1 |
| Última revisão | 05/09/2026 |

---

## 1. Esperando você

### D31 — a remessa que nasce sem item

**Implementação e revalidação técnica concluídas em 05/09/2026; revisão final e aceite do Owner
ainda não registrados.** A escolha de corrigir o gerador e re-medir já foi autorizada; não está
sendo pedida novamente. A pendência agora é o aceite da entrega conforme `CLAUDE.md` §5/§7.

| | |
|---|---|
| **Código entregue** | `522a8fc`: gerador e testes em memória; `04a824a`: descarte conferido do estado do streaming; `e5ff5ca`: teste dbt bloqueante |
| **Evidências** | [Qualidade](qualidade_de_dados.md#43-a-entrega-e-a-primeira-quarentena-fora-do-legado): remessas e P13; [Streaming §7.2](streaming.md#72-revalidação-da-d31): conteúdos, saldo, duplicatas, alertas e incremental; [Capacidade §2.7](capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026): volumes, tempos e DAG |
| **O que revisar** | Comentário da probabilidade em `geracao.yml` (valor inalterado), invariante 13 no Modelo de Dados, severidade do teste dbt e procedimento destrutivo restrito; revisão integral do declarativo e amostragem do derivado |
| **Enquanto não vem** | Correção permanece aplicada e testes bloqueantes; não repetir a reconstrução por padrão. Não declarar aceite nem iniciar a Etapa 10 |

Nenhum ADR novo foi necessário; os aceitos não foram reescritos. Após a revisão, registrar o aceite,
retirar D31 dos índices pendentes e remover seu encaminhamento no mesmo commit. A autorização para
executar não foi tratada como evidência de que essa revisão já ocorreu.

---

## 2. O que já foi fechado

**Fora a D31, não há nada esperando você.** As decisões de abertura das Etapas 8 e 9 foram fechadas
no mesmo dia em que foram levantadas, em 05/09/2026: o grão em que a entrega é medida
([ADR-0033](adr/0033-entrega-medida-em-dois-graos.md)), a procedência da data realizada
([ADR-0034](adr/0034-entrega-do-livro-de-eventos.md)), o escopo do inventário dimensional
([ADR-0035](adr/0035-aposentar-dimensoes-sem-pergunta.md)) e a âncora da janela de recompra de P16
([ADR-0036](adr/0036-recompra-ancorada-no-pedido.md)). As da Etapa 7 foram fechadas em 04/09/2026
nos
[ADR-0031](adr/0031-aterrissagem-do-caminho-quente-em-raw.md) e
[ADR-0032](adr/0032-fonte-python-no-lugar-do-kafkaio.md). Todas por interrogatório com alternativas.

Os marcos **M0** (Termo aprovado), **M1** (decisões registradas), **M2** (ambiente reproduzível),
**M3** (primeiro fluxo completo) e **M4** (*streaming* em operação) estão fechados. As Etapas 3 a 9
foram entregues — o modelo dimensional está completo e as 16 perguntas de negócio têm view —, e a
próxima é a **Etapa 10 — Corte 6: origem legada**.

O único número que o projeto ainda carregava rotulado como **não medido** — o *allowed lateness* do
[ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md) — foi medido na Etapa 7, e a
medição derrubou a hipótese: 300 s ficavam abaixo da mediana do atraso real. O valor vigente é
1200 s ([Streaming §3.3](streaming.md#33-eventos-atrasados)).

## 3. Onde cada item foi parar

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

## 4. Do lado do assistente

Nenhuma execução técnica da D31 pendente. Os resultados estão publicados nos donos documentais e
o estado anterior dos processos foi restabelecido: DAG despausada, serviços de pé, sem produtor ou
Beam/Prism no host. A transição para a Etapa 10 aguarda o aceite acima e as decisões próprias daquele
corte; sua implementação não fez parte desta entrega.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
