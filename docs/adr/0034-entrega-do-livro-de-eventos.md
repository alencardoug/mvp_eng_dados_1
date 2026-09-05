# ADR-0034 — Tirar a data de entrega do livro de eventos, não da coluna da remessa

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 8) |
| Substitui / é substituída por | — |

## Contexto

A origem transacional registra a chegada da remessa em **dois lugares**, e eles não são a mesma
coisa:

| Onde | O que é |
|---|---|
| `shipments.delivered_at` | Coluna da remessa — o estado corrente, sobrescrito a cada atualização |
| `delivery_events`, evento `delivered` | Linha do livro *append-only* — o fato de que a chegada ocorreu, com momento e localização |

É a mesma configuração que a Etapa 6 encontrou no estoque, e o
[ADR-0030](0030-cmv-do-livro-de-estoque.md) já a resolveu uma vez: a projeção corrente
(`inventory_balances`) foi recusada como fonte, e o custo passou a sair do livro
(`inventory_movements`). O argumento de lá não era estético — a projeção guarda o **estado de hoje**,
e uma métrica histórica que a consulta muda de valor retroativamente.

A configuração se repete aqui com um agravante próprio da logística: o livro registra transições que
a coluna não consegue representar. Uma remessa devolvida passa por `delivered` **e** por `returned` —
o gerador emite os dois eventos, nessa ordem —, e a coluna `delivered_at` sozinha não diz se a caixa
ficou com o cliente. Há também a tentativa frustrada (`delivery_attempt`, em 12% das remessas), que
existe apenas no livro.

Do lado de trás, o [ADR-0021](0021-procedencia-no-empilhamento.md) e a regra 4 do
[`CLAUDE.md`](../../CLAUDE.md) — *nenhum registro descartado em silêncio* — obrigam a decidir também
o que fazer com a remessa marcada como entregue **sem** evento correspondente, caso ela apareça.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **O livro `delivery_events` é a fonte; a coluna é conferência** | Mantém o precedente do ADR-0030 na mesma entrega em que o projeto ganha o seu segundo livro de eventos — decidir diferente aqui exigiria explicar por que estoque e logística seguem regras opostas. O livro carrega o que a coluna não carrega: tentativa frustrada, trânsito multi-trecho, e a ordem `delivered` → `returned` que distingue devolução de entrega. E a divergência entre as duas fontes vira **teste**, em vez de ser herdada em silêncio | Uma junção a mais no caminho de `trusted`, e a necessidade de decidir explicitamente o destino da remessa entregue sem evento — que passa a ser `quarantine` com motivo, não descarte |
| A coluna `shipments.delivered_at` é a fonte | Mais direto e mais barato: a data já está na linha da remessa, sem junção nem agregação | Contraria o ADR-0030 sem motivo novo. Perde a distinção entre entregue e devolvido, que na coluna não existe. E o teste que acusaria a divergência entre coluna e livro deixaria de existir: a inconsistência passaria a ser importada em silêncio, que é exatamente o que a regra 4 proíbe |
| As duas, com a coluna como reserva quando falta evento | Nunca perde uma entrega | Uma medida com duas procedências possíveis por linha não é uma medida — é duas, somadas. E esconde o defeito que a reserva estaria cobrindo: se falta evento, isso é achado de qualidade, não lacuna a preencher |

## Decisão

A chegada da remessa é o evento **`delivered` mais recente** do livro `delivery_events`, e é dele que
saem a data realizada de P13 e o fechamento do ciclo de P14 ([ADR-0033](0033-entrega-medida-em-dois-graos.md)).

`shipments.delivered_at` permanece carregada até `trusted` como **coluna de conferência**, e a
divergência entre as duas é um teste de qualidade, não uma escolha silenciosa. Remessa marcada como
entregue sem evento `delivered` correspondente vai para `quarantine` com motivo — não é descartada e
não é preenchida pela coluna.

Devolução mantém a leitura do livro: uma remessa que registra `delivered` e depois `returned` **foi**
entregue no prazo em que chegou, e a devolução é fato posterior, contado à parte.

## Consequências

- **Positivas:** a data de entrega para de depender do último `update` da linha, e passa a ser um
  fato com momento próprio — o que é a condição para que `fact_order_status_event` e a entrega
  contem a mesma história. O livro ganha, como o de estoque ganhou, uma segunda razão de existir
  além do rastreamento. E a inconsistência entre projeção e livro, se existir, aparece como número
  em vez de sumir.
- **Negativas:** o caminho fica mais caro — o evento de chegada exige agregação por remessa antes da
  junção, e `delivery_events` é a maior tabela do domínio (185.000 linhas de referência, contra
  37.000 de `shipments`). E o projeto passa a ter uma **quarentena a mais para vigiar**: se a
  divergência aparecer, alguém precisa olhar, e o custo disso é permanente.
- **Paridade com o GCP:** nenhuma. É `max` com `group by` sobre uma tabela de eventos; o BigQuery faz
  igual e se beneficia do particionamento por data do evento. É, aliás, o padrão mais natural lá do
  que aqui.
- **Documentos a atualizar:** [Modelo de Dados](../modelo_de_dados.md) — a procedência da data de
  entrega em `fact_shipment_item`; [Qualidade de Dados](../qualidade_de_dados.md) — o teste de
  divergência entre coluna e livro e a regra de quarentena; [Glossário de
  Negócio](../glossario_de_negocio/) — a definição de entrega no prazo cita a fonte.
