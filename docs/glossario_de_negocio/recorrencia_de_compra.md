# Recorrência de compra

{% docs repeat_purchase %}

**Cliente recorrente** é o que fez um segundo pedido dentro de **90 dias** do primeiro. A **taxa de
recompra em 90 dias** é a fração dos clientes que estrearam no período e voltaram dentro da janela.

- **Cálculo:** `returning_customer_count / new_customer_count`, onde o numerador conta clientes com
  segundo pedido em até 90 dias do `first_order_at`.
- **Implementado em:** `dim_customer`, colunas `first_order_at` e `order_count`; view
  `new_and_repeat_customers_by_month`.
- **Relacionado:** cliente ativo, ticket médio, churn.

**A coorte é do mês da estreia, não do mês da recompra.** Um cliente que estreou em janeiro e voltou
em março conta na coorte de **janeiro** — é assim que a taxa de um mês para de mudar depois de
fechada a janela de 90 dias. Contar no mês da recompra faria toda coorte antiga variar para sempre.

{% enddocs %}
