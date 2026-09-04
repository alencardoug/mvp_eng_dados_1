# Ticket médio

{% docs average_order_value %}

**Ticket médio** é a receita líquida dividida pelo número de pedidos distintos do mesmo recorte.

- **Cálculo:** `net_revenue_amount / order_count`, **recalculado a cada recorte**.
- **Implementado em:** view `average_order_value_by_channel_and_segment`.
- **Relacionado:** receita líquida, recorrência de compra.

**É medida não aditiva, e isso tem consequência prática.** A média das médias mensais não é a média
do ano: doze meses de tamanhos diferentes não se somam e dividem por doze. Por isso a view entrega
`net_revenue_amount` e `order_count` **ao lado** do resultado — quem reagregar por trimestre soma os
dois e divide de novo, em vez de somar ticket médio com ticket médio.

O denominador é o **pedido**, não o item: um pedido de cinco itens conta uma vez.

{% enddocs %}
