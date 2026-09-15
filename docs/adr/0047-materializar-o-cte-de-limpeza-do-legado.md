# ADR-0047 — Materializar o CTE de limpeza dos modelos do legado no PostgreSQL

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 15/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D42 — levantada em 15/09/2026, pela contraprova (b) da revisão de desenvolvimento |
| Substitui / é substituída por | — ; complementa o [ADR-0043](0043-impedir-que-o-tratamento-do-legado-esgote-a-estacao.md), que tratou o JIT e a materialização do `staging` |

## Contexto

Cada modelo de limpeza do legado (`stg_legacy__*`, gerado por `legacy/dbt.py`) tem dois CTEs:
`captura`, que filtra a captura selecionada, e `limpo`, que calcula o valor tratado de cada coluna.
O `select` final junta os dois e monta o `achados` — um `case` por coluna que referencia o valor
**limpo** (`l."coluna"`) para conferir as rejeições que julgam o resultado da conversão; a
validação de uma data referencia a coluna limpa dezenas de vezes.

O PostgreSQL embute um CTE referenciado uma só vez no lugar da referência. O plano medido em
15/09/2026 mostra a junção direta entre duas varreduras de `captura`, sem `limpo`: a expressão de
limpeza inteira — com as suas expressões regulares — é reavaliada em **cada** referência do `case`.
Só as colunas limpas de `carts` (2.000 linhas) custam 2,2 s; com o `achados`, **94 s**; em
`cart_items` (5.500 linhas), 295 s. Com `limpo as materialized`, 8,7 s e 25 s. Ligar ou desligar o
JIT não muda a diferença
([Capacidade §2.11](../capacidade_e_recuperacao.md#211-o-cte-limpo-embutido-em-cada-referência--15092026)).

É uma causa anterior à do [ADR-0043](0043-impedir-que-o-tratamento-do-legado-esgote-a-estacao.md):
a árvore em que cada referência carrega a expressão inteira é também o que o LLVM tentava compilar.
Apareceu ao executar os 40 modelos compilados sobre o lote gerado, num armazém efêmero — a
contraprova (b) da revisão de desenvolvimento levava 656 s por causa disso.

A decisão precisava do Owner porque é SQL do tratamento (mudar o texto emitido pelo gerador, ainda
que o resultado seja idêntico linha a linha), porque `MATERIALIZED` não existe no BigQuery — e
porque a impressão digital da D34 hasheia **o SQL gerado**: a palavra move a impressão
(`8710ca3f…` → `92f72e5d…` só com a palavra; `607e6288…` depois de a versão 9 entrar no SQL da
classificação, que também é hasheado), e sob a D34 impressão nova exige versão nova.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **`limpo as materialized`, só no adaptador PostgreSQL** (escolhida) | Uma palavra no gerador; resultado idêntico, provado pela contraprova (b) achado a achado e valor a valor; ganho de 10× na limpeza medido nas duas maiores tabelas | O SQL emitido diverge entre adaptadores — um `{% if target.type == 'postgres' %}` no gerador —, o comportamento do BigQuery com o mesmo CTE não foi medido, e a impressão digital move: `versao` avança para 9 sem que uma regra tenha mudado |
| Deixar como está e conviver com o custo | Nada muda no tratamento | A limpeza compilada e o `dbt build` do legado seguem uma ordem de grandeza mais lentos do que precisam; a contraprova (b) só compararia o lote inteiro sob um interruptor separado (~11 min) |
| Reestruturar o modelo para que `achados` não referencie `limpo` | Portável, sem palavra específica de adaptador | Reescreve o gerador para um problema que uma palavra resolve, e a referência ao valor limpo é o que o R06 exigiu — a rejeição confere o resultado da conversão |
| Cerca de otimização por `offset 0` ou `distinct` | Portável em sintaxe | Depende de comportamento não documentado do planejador; é o tipo de truque que a próxima versão desfaz em silêncio |

## Decisão

**O CTE `limpo` dos modelos de limpeza do legado é declarado `materialized` quando o adaptador é o
PostgreSQL, e permanece como estava nos demais.** O gerador escreve
`limpo as {{ 'materialized ' if target.type == 'postgres' else '' }}(`; os 40 modelos são
regenerados; nenhuma regra muda e o resultado é idêntico — mas a impressão digital move, e a
`versao` do catálogo avança para **9** pela leitura literal da D34, decidida pelo Owner em
15/09/2026 como na 8.

## Consequências

- **Positivas:** a limpeza compilada passa de 656 s para 47 s sobre o lote inteiro (as 40
  tabelas); a contraprova (b) compara as 40 tabelas em toda execução de `make test`, sem
  interruptor; e o `dbt build` do ramo legado deixa de pagar a reavaliação — medição no dossiê de
  revisão.
- **Negativas:** o SQL emitido depende do adaptador, e é a primeira vez que o gerador escreve algo
  que não é idêntico nos dois alvos; quem ler um modelo gerado precisa saber por que a palavra
  está lá — o comentário no modelo diz. E a versão avança sem mudança de regra: no próximo `dbt build`
  completo a quarentena guarda a auditoria v9 ao lado da v8, e as medições documentadas continuam
  rotuladas v8 até serem refeitas.
- **Paridade com o GCP:** no BigQuery o CTE fica sem a palavra, e o modelo é o mesmo; o custo da
  reavaliação lá **não foi medido** e é premissa de que o planejador do BigQuery não embute o CTE
  do mesmo modo — a Etapa 13 mede, e se embutir, a alternativa é o `dispatch` de uma
  materialização intermediária.
- **Documentos a atualizar:** `legacy/catalogo.yml` — `versao: 9` e o cabeçalho;
  [Capacidade](../capacidade_e_recuperacao.md) §2.11 — a pendência fecha; [Pendências](../pendencias.md) e [`docs/adr/README.md`](README.md) — D42 sai da tabela de
  pendentes.
