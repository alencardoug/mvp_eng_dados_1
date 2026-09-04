# Receita líquida

{% docs net_revenue %}

**Receita líquida** é o que a venda do produto gerou, depois dos descontos e **antes** de frete e
imposto: quantidade vendida × preço unitário praticado, menos o desconto concedido na linha.

- **Cálculo:** `sum(quantity * unit_price) - sum(discount_amount)`, no grão do item de pedido. A
  **receita bruta** é a mesma soma sem o desconto.
- **Implementado em:** `fact_sales_order_item`, colunas `net_revenue_amount` e
  `gross_revenue_amount`. Ambas são **aditivas**.
- **Relacionado:** ticket médio, lucro bruto, desconto concedido.

**Por que frete e imposto ficam de fora.** São duas razões independentes, e nenhuma é preferência
de estilo. O imposto sobre venda é **dedução** na convenção contábil brasileira, não receita — e
incluí-lo faria categorias de alíquotas diferentes se compararem por política tributária em vez de
desempenho comercial. O frete é valor de **pedido**, não de item: rateá-lo entre os itens exigiria
uma regra arbitrária, e o resultado por SKU passaria a depender de com quantos outros produtos ele
foi comprado.

O valor efetivamente cobrado do cliente não se perde: `order_total_amount` viaja na fato como
dimensão degenerada, e é ele que reconcilia com o financeiro.

{% enddocs %}
