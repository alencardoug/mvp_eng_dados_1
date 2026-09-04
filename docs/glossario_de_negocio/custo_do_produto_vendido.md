# Custo do produto vendido

{% docs cost_of_goods_sold %}

**Custo do produto vendido (CMV)** é o custo do que efetivamente saiu do estoque
por venda, no valor registrado **no instante da saída**.

- **Cálculo:** soma de `|quantity_delta| × unit_cost` nos movimentos de tipo
  `sale_dispatch` do livro de estoque.
- **Implementado em:** `fact_inventory_movement`, coluna `cogs_amount`. Aditiva.
- **Relacionado:** lucro bruto, giro de estoque.

**Por que do livro e não da compra** ([ADR-0030](../adr/0030-cmv-do-livro-de-estoque.md)).
O custo médio ponderado e o custo da última compra são números **correntes**:
uma compra feita hoje mudaria a margem de 2024. O custo do movimento foi
registrado quando a mercadoria saiu, e nada que aconteça depois o move.

**Devolução ao fornecedor e transferência não entram.** As duas são saídas de
estoque e nenhuma é venda; somá-las inflaria o CMV com movimentação interna.

**A data é a da expedição, não a da venda.** Um pedido de dezembro despachado em
janeiro tem a receita em dezembro e o custo em janeiro. É o comportamento
correto por competência do estoque, e é contraintuitivo — quem olhar margem
mensal sem saber disso vai achar que há erro.

{% enddocs %}
