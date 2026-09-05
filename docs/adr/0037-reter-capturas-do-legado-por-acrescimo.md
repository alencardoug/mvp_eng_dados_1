# ADR-0037 — Reter as capturas do legado com um quarto modo de sincronização

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 10) |
| Substitui / é substituída por | Emenda o [ADR-0015](0015-sincronizacao-e-exclusoes.md), que não é substituído |

## Contexto

O [ADR-0015](0015-sincronizacao-e-exclusoes.md) fixou **três** modos de sincronização e o critério
que escolhe entre eles. Ele também decidiu, para o legado, que *"a ausência é detectada por
comparação contra o snapshot anterior"* — e é aí que os dois pedaços da decisão se chocam.

O modo que o legado exigiria é o `full_refresh`, porque a origem antiga não tem cursor confiável.
Mas a tradução vigente, em [`airbyte/main.tf`](../../airbyte/main.tf), é literal:

```hcl
full_refresh  = "full_refresh_overwrite"
```

`overwrite` **derruba a tabela de destino a cada carga**. Não há snapshot anterior contra o qual
comparar: existe sempre um só, o mais recente. A promessa do ADR-0015 sobre exclusões físicas não
tem como acontecer, e o critério de conclusão da Etapa 10 que depende dela — *"duas capturas
completas distinguem remoção real de falha de ingestão"* — fica sem o que provar.

Há um segundo requisito no mesmo lugar. O [ADR-0008](0008-schemas-do-armazem.md) declara
`raw_legacy` como *"snapshot imutável"*, e imutável não é uma propriedade que se afirma: é uma que
se garante. Sobrescrever a tabela a cada carga é o oposto exato dela.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Quarto modo, `full_refresh_append`** | A retenção passa a ser propriedade da **ingestão**, não de um passo posterior que pode não rodar. É o modo nativo do Airbyte para exatamente este caso, então a paridade com a nuvem é direta e não há peça própria a manter. E torna a comparação entre capturas uma consulta, não um procedimento | Emenda um ADR aceito: a lista de três modos do ADR-0015 passa a ter quatro, e o teste que confere `streams.yml` contra a conexão precisa conhecer o modo novo. `raw_legacy` cresce a cada captura, e o descarte de capturas antigas vira decisão futura em vez de consequência automática |
| Sobrescrever e arquivar por dbt | Não toca no ADR-0015. A cópia histórica fica sob o mesmo motor que constrói o resto | Põe uma garantia de **auditoria** na mão do agendamento: duas cargas antes de uma execução do dbt, e a primeira desapareceu sem que nada acuse. Imutabilidade que depende de alguém rodar algo a tempo não é imutabilidade |
| Uma captura só, sem retenção | O mais simples, e ainda exercita limpeza, quarentena e empilhamento | Abandona a detecção de exclusão física, que é a razão pela qual o ADR-0015 tratou o legado à parte, e deixa um critério de conclusão da etapa sem prova possível |
| Snapshot pelo banco, fora do Airbyte | Controle total sobre o instante e a consistência entre tabelas | Acrescenta um componente ao fluxo, contra a regra 5 do [`CLAUDE.md`](../../CLAUDE.md), para resolver o que a ferramenta já resolve. E cria um segundo caminho de ingestão que o `streams.yml` não descreve — a declaração deixaria de ser única |

## Decisão

`streams.yml` passa a aceitar um **quarto modo**, `full_refresh_append`, e ele é o modo do legado.
Cada captura **acrescenta** linhas a `raw_legacy`, identificadas por `snapshot_id`, `snapshot_at` e
`source_system`; nenhuma carga sobrescreve a anterior.

O critério que escolhe o modo ganha uma linha, na mesma forma das outras três:

| Situação | Modo |
|---|---|
| Origem sem cursor confiável cujo histórico de capturas **é** o dado | `full_refresh_append` |

O ADR-0015 **não é substituído**: os três modos que ele fixou continuam valendo, com o mesmo
critério, para a origem principal. O que muda é que a lista deixa de ser exaustiva, e o motivo está
aqui.

Reter não é acumular sem limite: o descarte de capturas antigas é decisão futura, e enquanto não for
tomada nenhuma captura é apagada. A [Capacidade](../capacidade_e_recuperacao.md) mede o crescimento.

## Consequências

- **Positivas:** a imutabilidade de `raw_legacy` passa a ser estrutural. A exclusão física vira uma
  comparação entre duas capturas retidas — consulta, não procedimento —, e o reprocessamento de uma
  captura antiga passa a ser possível sem depender de a origem ainda existir. O projeto ganha,
  também, o único caso em que o **histórico de capturas é o dado**, que é diferente de histórico de
  atributos (SCD) e de livro de eventos.
- **Negativas:** `raw_legacy` cresce a cada carga, e sem política de descarte ele cresce para sempre
  — é custo aceito, medido, e adiado de propósito. O `streams.yml` passa a ter um modo que a origem
  principal nunca usa, e quem ler a declaração precisa saber por que ele existe. E o teste de
  coerência entre declaração e conexão precisa aprender o modo novo, ou passa a mentir por omissão.
- **Paridade com o GCP:** direta. `full_refresh_append` é modo do próprio Airbyte e existe igual na
  nuvem; no BigQuery o destino natural é uma tabela particionada por `snapshot_at`, o que torna a
  comparação entre capturas mais barata lá do que aqui.
- **Documentos a atualizar:** [Origem Legada](../origem_legada.md) §4 — o contrato do *snapshot*;
  [ADR-0015](0015-sincronizacao-e-exclusoes.md) — não é reescrito, mas o
  [Registro de Decisões](README.md) passa a mostrar a emenda; `airbyte/streams.yml` e
  `airbyte/main.tf` — a tradução do modo novo.
