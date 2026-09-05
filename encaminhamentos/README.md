# Encaminhamentos

Planos de trabalho para leitura e avaliação pelo Codex, um por assunto. **São transitórios**:
cada encaminhamento é apagado no *commit* que entrega o trabalho correspondente, depois da
validação e da atualização dos documentos permanentes.

Não são documentação do projeto e por isso não estão no mapa do [README](../README.md) — o dono
documental de cada assunto continua sendo o documento de sempre. O que vive aqui é só o recorte do
que fazer, em que ordem e como saber que acabou.

| Arquivo | O que encaminha | Pré-requisito para execução |
|---|---|---|
| [`d31-remessa-sem-item.md`](d31-remessa-sem-item.md) | Corrigir a divisão, reconstruir os caminhos frio e quente, re-medir e encerrar a D31 | Decisão de corrigir já registrada; conferir ambiente e escopo da reconstrução |
| [`etapa-10-origem-legada.md`](etapa-10-origem-legada.md) | Avaliar as lacunas do contrato e executar o corte completo da segunda origem | **D31 entregue** e questões de tratamento/modelagem aplicáveis resolvidas |

**A ordem não é preferência.** A D31 regenera os dados sintéticos, e a Etapa 10 é medida contra
eles. Fazer a 10 primeiro obriga a re-medi-la inteira depois.

## Como usar

1. Leia [`CLAUDE.md`](../CLAUDE.md), [`AGENTS.md`](../AGENTS.md) e este índice.
2. Reconfira as premissas medidas no ambiente que você tem à frente — os números destes arquivos
   são de 05/09/2026 e envelhecem.
3. Execute a D31 até os critérios dela fecharem, com o encerramento da pendência registrado.
   Só então comece a Etapa 10.
4. Ao relatar, separe o que foi **medido** do que foi **planejado** (**P5**), e não apresente
   caminho ou comando proposto como capacidade já existente.

**Estado em 05/09/2026:** os dois planos foram redigidos, revisados e **conferidos contra o
repositório e o ambiente em operação** (ver abaixo). Nenhuma implementação ou reconstrução foi feita
nesta entrega: este índice e os dois encaminhamentos, junto de `AGENTS.md`, são os quatro arquivos
do planejamento.

**Quando o Owner encaminhar um destes arquivos, é para executá-lo.** O parecer já está dentro de
cada plano e não deve ser refeito — refazer a avaliação em vez de trabalhar é a falha mais provável
desta passagem de bastão. Se a execução expuser um ponto que o plano não cobre, ele volta como
pendência (`CLAUDE.md` §5); o resto se implementa.

## Verificação independente, em 05/09/2026

As afirmações dos planos sobre o código e o ambiente foram conferidas por leitura e consulta
somente-leitura. Confirmadas:

| Afirmação | Onde se confirma |
|---|---|
| `full_refresh` vira `full_refresh_overwrite` no Terraform | `airbyte/main.tf` linha 22 — destrutivo, incompatível com a retenção que os ADR-0008 e 0015 exigem do legado |
| Alembic tem destino único | `db/migrations/env.py` — `Base.metadata` e `database_url()`, com filtro por `obj.schema == SCHEMA` |
| 36 fluxos para 40 tabelas | Fora do *stream*: `customer_contacts`, `customer_preferences`, `price_lists`, `product_prices` |
| `envelope.py` recusa `TRUNCATE` e o destino é `on conflict do nothing` | `OPERACOES_PROIBIDAS` e `sink.py` |
| O *staging* de estoque desempata em favor do payload do *stream* | `stg_retail__inventory_movements.sql` — é o que torna o `movement_id` reaproveitado um risco real |
| `make stream-down FORCE=1` **não** limpa `raw.inventory_movements_stream` | `Makefile` — só derruba o Compose e tenta remover o slot |
| `DUP_EXACT` manda deduplicar, contra as equações de reconciliação | `docs/origem_legada.md` §3.1 e §6 |
| A origem em operação tem 15.946 movimentos | Consulta a `oltp.inventory_movements`; a Etapa 7 mediu 15.446, e a diferença é do produtor ao vivo |

**Nenhuma afirmação conferida foi contrariada.** Os números acima são de 05/09/2026 e devem ser
reconferidos antes da execução, não reaproveitados como resultado.

## Passagem entre as entregas

A D31 só libera a etapa seguinte com código validado, reconciliações medidas e registro de
encerramento em [`docs/pendencias.md`](../docs/pendencias.md). Ao apagar seu encaminhamento,
atualize este índice e o pré-requisito da Etapa 10 para apontarem para esse registro e para o
*commit* real da entrega. Não invente um identificador de *commit* antes de ele existir.

Ao concluir a Etapa 10, retire sua entrada e seu arquivo; preserve neste índice apenas o trabalho
que continuar encaminhado. Resultados e instruções de operação devem estar nos respectivos donos
documentais do [README](../README.md).
