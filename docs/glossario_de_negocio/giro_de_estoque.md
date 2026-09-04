# Giro de estoque

{% docs inventory_turnover %}

**Giro de estoque** é quantas vezes o estoque de um SKU se renovou no período:
o custo do que saiu dividido pelo valor médio parado.

- **Cálculo:** `cost_of_goods_sold ÷ inventory_value_amount`, por SKU, armazém e
  trimestre.
- **Implementado em:** view `inventory_turnover_by_sku_and_warehouse`.
- **Relacionado:** custo do produto vendido, cobertura de estoque.

**O saldo é semiaditivo, e é aqui que isso importa.** `quantity_on_hand` soma
por armazém e por SKU, e **nunca ao longo do tempo**: somar o saldo de três
meses produz um estoque que nunca existiu — e produz um número plausível, que é
o pior tipo de erro. Por isso o saldo entra como média do período, não como
soma.

**Giro indefinido não é giro zero.** SKU sem estoque médio no período não girou
zero vezes: não havia o que girar. A view devolve nulo, e escrever zero ali
diria uma coisa diferente da que aconteceu.

{% enddocs %}
