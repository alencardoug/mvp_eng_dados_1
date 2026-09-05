# Ruptura de estoque

{% docs stockout %}

**Ruptura de estoque** é a condição em que não há saldo disponível de um SKU em
um armazém: `quantity_available` menor ou igual a zero. É a condição, não o
evento — a view responde "está em ruptura agora", e não "rompeu tal dia".

- **Cálculo:** `quantity_available <= 0`, por armazém e SKU.
- **Implementado em:** view `skus_below_reorder_point`.
- **Relacionado:** cobertura de estoque, ponto de reposição.

**Ruptura é do disponível, não do físico.** Uma unidade reservada para um pedido
já colocado está fisicamente no armazém e não está à venda. Medir ruptura pelo
saldo físico diria que há estoque quando não há nada que se possa vender, que é
o erro que o conceito existe para evitar.

**Ruptura e ponto de reposição são coisas diferentes.** O ponto de reposição é o
aviso — o saldo caiu ao nível em que é hora de comprar; a ruptura é o dano — não
há mais o que vender. Todo SKU em ruptura está abaixo do ponto de reposição; o
contrário quase nunca é verdade, e é essa distância que dá tempo de reagir.

{% enddocs %}

{% docs stock_availability %}

**Saldo disponível** é o que existe fisicamente menos o que já está reservado:
`quantity_on_hand − quantity_reserved`. É o número que responde "quantas unidades
posso vender agora".

É **semiaditivo**: soma por armazém e por SKU, e **nunca ao longo do tempo** —
somar o disponível de três dias produz um estoque que nunca existiu.

{% enddocs %}
