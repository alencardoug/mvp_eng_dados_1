# ADR-0042 — Reconciliar a captura legada na fato incremental por `delete+insert`

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 08/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D37 |
| Substitui / é substituída por | Altera o alcance da exceção do [ADR-0016](0016-materializacao-por-camada.md); não o substitui |

## Contexto

O [ADR-0016](0016-materializacao-por-camada.md) fixou `table` em `analytics` e concedeu **uma**
exceção incremental — `fact_inventory_movement` —, porque a Etapa 7 a alimenta por *streaming* e
reconstruí-la a cada execução contradiria o fluxo contínuo. A exceção veio com quatro proteções
obrigatórias, e a nº 2 é *filtro por tempo de evento, com margem de atraso, nunca por tempo de
carga*.

Essa proteção foi desenhada para uma origem de **eventos**, que entrega fato novo em ordem
aproximada. A Etapa 10 pôs na mesma fato uma origem de natureza diferente: a captura legada é um
**lote inteiro e retroativo**, que além disso pode **mudar de veredito entre capturas** — uma
correção de tratamento torna apto o que era rejeitado, e uma captura seguinte pode não trazer mais
uma ocorrência que a anterior trazia.

O filtro usa `max(occurred_at)` **global**. Medido em 08/09/2026, somente leitura:

| | legado | retail |
|---|---|---|
| movimentos em `trusted` | 553 | 15.900 |
| alcançados pela janela | **7** | 2.342 |
| faixa de `occurred_at` | 2024-01-01 … 2026-09-01 | 2024-01-01 … 2026-09-05 |

O retail está quatro dias à frente, então a janela de sete dias alcança 1,3% da captura legada.
Decorrem daí dois caminhos que a estratégia atual não reconcilia: **aptidão nova fora da janela**,
que nunca é relida, e **rejeição ou ausência posterior**, que o `merge` nunca apaga porque `merge`
só faz *upsert*.

Hoje não há perda — fato e `trusted` estão consistentes nos dois sentidos, zero órfãos —, porque a
fato veio de uma reconstrução completa. É exatamente o ponto do achado **R25** da terceira revisão:
reconstrução inicial não prova reprocessamento, e a decisão precisa ser tomada antes de a Etapa 10
fechar, não depois de a primeira recaptura perder dado em silêncio.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **A — `delete+insert` recortado pela origem legada** | Resolve os dois caminhos, inclusive a remoção; a prova de atualização **e** remoção que o R25 cobra passa a ser executável na Etapa 10 | Troca a estratégia incremental, o que mexe na proteção nº 1 da exceção (`unique_key` deixa de ser o mecanismo de idempotência do ramo legado) e obriga a reescrever a exceção do ADR-0016 |
| **B — janela por origem, legado recortado pela captura corrente** | Mais próximo do que a exceção já pretendia; mantém `merge` e as quatro proteções na forma escrita; resolve a aptidão nova | **Não resolve a remoção.** Movimento que saia da captura seguinte permanece materializado até o `--full-refresh` agendado — ou seja, a garantia depende da proteção nº 3 como rede, e não da estratégia |
| **C — tirar o legado da fato incremental**, em relação própria reconstruída por inteiro | Preserva a exceção do ADR-0016 intacta e sem reinterpretação | Custa uma relação a mais e uma junção em **todo** consumidor da fato; espalha por vários modelos um problema que é de um só |

## Decisão

O ramo legado de `fact_inventory_movement` passa a ser materializado por `delete+insert` recortado
pela captura corrente, enquanto o ramo de *streaming* mantém o filtro por tempo de evento com margem
de atraso.

## Consequências

- **Positivas:** os dois caminhos de reprocessamento passam a ser reconciliáveis, e a remoção deixa
  de depender do `--full-refresh` agendado para não corromper o saldo. A prova que o R25 cobra —
  atualização e remoção, não só reconstrução — passa a ser escrevível como teste.
- **Negativas:** a exceção do ADR-0016 deixa de ter **uma** estratégia e passa a ter duas, uma por
  origem. É mais difícil de ler e de revisar, e a proteção nº 1 deixa de valer para o ramo legado —
  a idempotência dele passa a vir do recorte por captura, não da `unique_key`. Aceito porque a
  alternativa é uma garantia de remoção que depende de agendamento. O `delete+insert` também reescreve
  a partição legada inteira a cada execução: com 553 movimentos isso é irrelevante hoje, e é o número
  que precisa ser reavaliado se a origem legada crescer.
- **Paridade com o GCP:** o equivalente é `insert_overwrite` particionado — a mesma estratégia que o
  ADR-0016 já registra como tradução do incremental para o BigQuery, aqui aplicada com a captura como
  chave de partição do ramo legado. É tradução configurável por perfil do dbt, não replicação: o
  `delete+insert` local e o `insert_overwrite` remoto precisam ser declarados lado a lado.
- **Documentos a atualizar:** [ADR-0016](0016-materializacao-por-camada.md) — o alcance da exceção;
  [Arquitetura](../arquitetura.md) §2; [Origem Legada](../origem_legada.md); e o próprio modelo
  `dbt/models/analytics/fact_inventory_movement.sql`, cujo cabeçalho enumera as quatro proteções.
