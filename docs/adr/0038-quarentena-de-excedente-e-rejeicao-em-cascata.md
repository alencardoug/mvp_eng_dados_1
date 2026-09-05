# ADR-0038 — Fechar as equações com quarentena de excedente e rejeição em cascata

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 05/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | — (levantada na abertura da Etapa 10) |
| Substitui / é substituída por | — |

## Contexto

A [Origem Legada §6](../origem_legada.md) exige que a reconciliação **feche exatamente**:

```text
extraídos  = aceitos + corrigidos + rejeitados
empilhados = aceitos + corrigidos
```

E a §5 exige que cada registro saia em **exatamente uma** das três classificações. Duas regras do
catálogo de 21 falhas não cabem nesse contrato como estão escritas.

**A primeira é a `DUP_EXACT`**, cujo tratamento declarado é *"deduplicar, mantendo uma ocorrência"*.
Duas linhas idênticas entram; uma sai. Se as duas forem contadas como corrigidas e só uma for
empilhada, a segunda equação não fecha. Se a excedente simplesmente sumir, a primeira não fecha —
e some em silêncio, que a regra 4 do [`CLAUDE.md`](../../CLAUDE.md) proíbe. "Deduplicar" não diz o
que acontece com a linha que sobra, e é justamente isso que precisa ser decidido.

**A segunda é o efeito da rejeição sobre os filhos.** O catálogo manda rejeitar o pedido cujo total
não fecha (`TOTAL_MISMATCH`) e o registro que aponta para chave inexistente (`FK_ORPHAN`). Nada diz
sobre os **itens íntegros** desse pedido: eles não têm defeito nenhum, e o pai que os explica não
vai ser empilhado. Empilhá-los produziria receita sem pedido — um total que não reconcilia com
coisa alguma, que é exatamente o defeito que esta origem existe para ensinar a não cometer.

## Alternativas consideradas

### O que acontece com a duplicata exata

| Alternativa | A favor | Contra |
|---|---|---|
| **Canônica empilhada, excedente em quarentena** | As três saídas continuam mutuamente exclusivas e as duas equações fecham **sem alteração**. A evidência de que a origem tinha duas linhas sobrevive, e nada é descartado em silêncio | A quarentena passa a conter registros que não são defeito de conteúdo, e quem a lê precisa distinguir *rejeitado por inválido* de *excedente por repetido*. É uma leitura a mais, permanente |
| Deduplicar ao ler o bruto | As equações fecham trivialmente e a quarentena fica só com defeito de verdade | `extraídos` deixa de bater com a contagem física de `raw_legacy`, que é a primeira coisa que um auditor confere. E perde-se a evidência da duplicata, que é uma das 21 falhas que o catálogo existe para exercitar |
| Separar contagem física da lógica | O mais fiel à realidade, e o mais informativo | Altera as equações já publicadas, que são critério de conclusão da etapa, e dobra a superfície de reconciliação que precisa fechar exatamente — mais lugares onde um erro se esconde |

### O que acontece com o filho de um pai rejeitado

| Alternativa | A favor | Contra |
|---|---|---|
| **Rejeitar em cascata, com código próprio** | Mantém a integridade referencial de `trusted` sem inventar pai, e o motivo fica legível: o item não tinha defeito, o pedido tinha. A quarentena passa a explicar a diferença em vez de escondê-la | Um código novo no catálogo — 21 passam a 22 —, e um pai rejeitado arrasta muitos filhos. Se a cascata não aparecer separada na reconciliação, o legado parece pior do que é |
| Empilhar apontando para membro desconhecido | Nenhum dado apto se perde | Usa o membro desconhecido para esconder exatamente o que o catálogo manda rejeitar. A receita do item passaria a existir sem o pedido que a originou |
| Empilhar sem pai | Preserva o máximo de dado | Quebra o `not_null` + `relationships` que toda chave de fato carrega desde a Etapa 5. Acomodar dado sujo afrouxando a salvaguarda estrutural é o caminho oposto ao desta etapa |

## Decisão

**A duplicata exata elege uma ocorrência canônica** por regra determinística — a de menor
identificador físico dentro da captura —, que segue como `accepted` ou `corrected` conforme as
demais falhas da linha. Cada ocorrência excedente é uma linha `rejected` própria, com o código
`DUP_EXACT` e o vínculo à canônica que a explica.

**O filho íntegro de um pai rejeitado é rejeitado em cascata**, com o código novo
**`PARENT_REJECTED`** e o vínculo ao registro que causou a rejeição. O catálogo passa a ter **22**
códigos, e o novo é o único que não descreve um defeito do próprio registro — o que precisa estar
dito onde ele é declarado.

As duas equações permanecem **como estão**. A reconciliação passa a discriminar, dentro de
`rejeitados`, três origens de rejeição: defeito próprio, excedente de duplicata e cascata. Sem essa
discriminação o número fecha e não informa.

## Consequências

- **Positivas:** o contrato de reconciliação deixa de ter dois casos que não cabiam nele, e passa a
  fechar por construção em vez de por sorte. A quarentena vira o lugar onde a diferença entre
  extraído e empilhado é **explicada**, não apenas registrada — que é o que a torna evidência de
  auditoria e não depósito. E a cascata torna visível uma propriedade real de dado sujo: um defeito
  raro no pai custa muitas linhas.
- **Negativas:** a quarentena passa a misturar três coisas de naturezas diferentes, e ler o total
  sem discriminar dá uma impressão errada da qualidade da origem. O `PARENT_REJECTED` é um código
  derivado — depende do resultado de outro registro —, o que torna o tratamento **dependente de
  ordem**: os pais precisam ser classificados antes dos filhos, e isso é uma restrição real na
  construção dos modelos.
- **Paridade com o GCP:** nenhuma. É classificação e agregação; o BigQuery faz igual.
- **Documentos a atualizar:** [Origem Legada](../origem_legada.md) §3.1 — o código novo e a
  precedência entre falhas; §5 e §6 — as três origens de rejeição na reconciliação;
  [Qualidade de Dados](../qualidade_de_dados.md) — os testes que provam que as equações fecham.
