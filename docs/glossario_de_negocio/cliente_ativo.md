# Cliente ativo

{% docs active_customer %}

**Cliente ativo** é o cliente com ao menos um pedido não cancelado nos últimos **180 dias**,
contados a partir da `as_of_date` da execução.

- **Cálculo:** existe pedido do cliente com `placed_at` dentro da janela e estado diferente de
  `cancelled`. Pedido devolvido **conta** — houve compra; a devolução é outro fato.
- **Implementado em:** `dim_customer`, coluna `is_active`.
- **Relacionado:** recorrência de compra, churn.

**A janela é contada da `as_of_date`, nunca de `now()`.** Um modelo que usa o relógio do banco
produz resultado diferente a cada execução sobre o mesmo dado, e a reprodutibilidade do projeto
(**P2**) deixa de existir na primeira reconstrução.

O estado do relacionamento em `customers.status` é **outra coisa**: ele é cadastral, e um cliente
pode estar `active` no cadastro sem ter comprado em dois anos.

{% enddocs %}
