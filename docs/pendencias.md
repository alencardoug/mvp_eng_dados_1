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
| Etapa atual | Etapa 10 — Corte 6: origem legada, reaberta |
| Aprovações pendentes | 0 |
| Decisões pendentes | 2 |
| Última revisão | 06/09/2026 |

---

## 1. Esperando você

Duas questões que a revisão da Etapa 10 levantou e que **não** são implementação: mudam o
contrato, e por isso são suas.

### D33 — o universo da reconciliação de pedidos

O total do pedido é conferido contra **todos** os itens capturados, menos as duplicatas exatas —
inclusive itens que serão rejeitados por outro motivo. Isso mede *consistência da origem*.

A alternativa é conferir contra o conjunto que será **empilhado**, o que mede *consistência do que
chega ao armazém*. São contratos diferentes, e a escolha muda a política, não só o número.

Escolhi o primeiro ao consertar uma circularidade — 114 pedidos falsamente não reconciliados
viraram 8 —, mas melhora de contagem não decide qual contrato deve valer.

### D34 — o que identifica uma versão auditável do tratamento

A quarentena substitui a auditoria anterior quando captura e `catalog_version` coincidem. Mas
mudanças em `regras.py` ou em `classification.sql` alteram o resultado **sem** mudar o número do
catálogo — duas auditorias diferentes sob a mesma identidade.

Falta decidir quando esse número avança, e se resultado distinto sob a mesma chave deve ser
recusado ou receber identidade própria.

---

## 2. Decisões já fechadas

**D32 — decidida em 06/09/2026.** O Owner autorizou `NULL_REQUIRED`, preservando
`NULL_DISGUISED` como achado de conversão e mantendo campos opcionais corrigíveis.
Contexto e consequências no [ADR-0040](adr/0040-rejeitar-nulo-em-campo-obrigatorio.md).
A decisão libera a implementação; não significa aceite de conclusão da Etapa 10.

### D31 — encerrada

A remessa que nascia sem item: 91 das 3.647, todas em pedidos divididos, porque o repartidor do
gerador dava zero unidades ao primeiro lote quando cada item do pedido tinha quantidade 1.

| | |
|---|---|
| **Decisão** | Corrigir o gerador e re-medir, entre as três alternativas apresentadas |
| **Código** | `522a8fc` gerador e testes · `04a824a` descarte conferido do estado do streaming · `e5ff5ca` teste dbt bloqueante · `1e6da99` re-medição publicada |
| **Resultado** | Nenhuma remessa sem item; P13 e `trusted.shipments` reconciliam em 3.166 dos dois lados, contra 3.141 e 3.221 antes; `dbt build` com `WARN=0` |
| **Regra que impede a volta** | [Invariante 13](modelo_de_dados.md#4-invariantes-de-negócio) — toda remessa contém ao menos um item —, com teste bloqueante |
| **Evidências** | [Capacidade §2.7](capacidade_e_recuperacao.md#27-re-medição-da-d31--05092026) · [Streaming §7.2](streaming.md#72-revalidação-da-d31) · [Execução Local §3.2](execucao_local.md#32-regerar-uma-origem-que-já-alimenta-streaming) |

**O que ela ensinou, e vale além dela:** regerar a origem com o caminho quente de pé corrompia em
silêncio — 2.246 movimentos órfãos e 13.626 chaves com payload diferente antes do descarte do
estado —, porque nenhum alvo limpava o destino do *streaming* e o `staging` desempata em favor dele.
O procedimento reproduzível nasceu daí.

Nenhum ADR novo foi necessário, e nenhum aceito foi reescrito: a re-medição entrou como execução
nova, ao lado das históricas.

---

## 2. O que já foi fechado

As três lacunas de contrato que a Etapa 10 levantou na abertura foram fechadas em 05/09/2026, por
interrogatório: como o legado retém as capturas
([ADR-0037](adr/0037-reter-capturas-do-legado-por-acrescimo.md)), o que acontece com a duplicata
exata e com o filho de um pai rejeitado
([ADR-0038](adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md)), e onde a procedência passa
a existir ([ADR-0039](adr/0039-alcance-da-procedencia.md)).

As decisões de abertura das Etapas 8 e 9 foram fechadas
no mesmo dia em que foram levantadas, em 05/09/2026: o grão em que a entrega é medida
([ADR-0033](adr/0033-entrega-medida-em-dois-graos.md)), a procedência da data realizada
([ADR-0034](adr/0034-entrega-do-livro-de-eventos.md)), o escopo do inventário dimensional
([ADR-0035](adr/0035-aposentar-dimensoes-sem-pergunta.md)) e a âncora da janela de recompra de P16
([ADR-0036](adr/0036-recompra-ancorada-no-pedido.md)). As da Etapa 7 foram fechadas em 04/09/2026
nos
[ADR-0031](adr/0031-aterrissagem-do-caminho-quente-em-raw.md) e
[ADR-0032](adr/0032-fonte-python-no-lugar-do-kafkaio.md). Todas por interrogatório com alternativas.

Os marcos **M0** (Termo aprovado), **M1** (decisões registradas), **M2** (ambiente reproduzível),
**M3** (primeiro fluxo completo) e **M4** (*streaming* em operação) estão fechados. As Etapas 3 a 10
foram entregues — o modelo dimensional está completo, as 16 perguntas de negócio têm view e a
segunda origem atravessa o fluxo inteiro —, e a próxima é a **Etapa 11 — Consolidação de governança
e qualidade**.

O único número que o projeto ainda carregava rotulado como **não medido** — o *allowed lateness* do
[ADR-0019](adr/0019-saldo-em-deltas-com-entrega-idempotente.md) — foi medido na Etapa 7, e a
medição derrubou a hipótese: 300 s ficavam abaixo da mediana do atraso real. O valor vigente é
1200 s ([Streaming §3.3](streaming.md#33-eventos-atrasados)).

## 4. Onde cada item foi parar

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

## 5. Do lado do assistente

A D31 está encerrada. Na Etapa 10, gerador, ingestão com retenção e modelos de limpeza já existem.
A correção da precedência entre rejeição e conversão foi validada em 06/09/2026
([Qualidade §5.1](qualidade_de_dados.md#51-validação-dos-valores-tratados--06092026)).
Classificação com contexto, quarentena, empilhamento com procedência e DAG estão em implementação;
a D32 foi decidida e deixou de pausar o tratamento. Nenhum aceite da Etapa 10 foi presumido.

---

**Como manter este documento:** um item entra aqui quando depende de você e sai quando é aprovado
ou decidido — decisão vira ADR, questão vira linha em documento existente. Se um item envelhece sem
resposta, ele é revisto ao final de cada etapa, junto com o [Registro de Riscos](riscos.md).
