# Ciclo de entrega

{% docs order_to_delivery_cycle %}

**Ciclo de entrega** é o tempo entre o pedido feito e a chegada da **última**
remessa dele: de `placed_at` até `max(delivered_at)` das suas remessas. O grão é
o **pedido**.

- **Cálculo:** média de `order_to_delivery_days` sobre pedidos com ciclo fechado,
  por região de entrega, modalidade e mês de chegada.
- **Implementado em:** view `order_to_delivery_time_by_region`, coluna
  `avg_order_to_delivery_days`; medida `order_to_delivery_days` em
  `fact_shipment_item`.
- **Relacionado:** entrega no prazo, prazo prometido.

**O ciclo fecha na última remessa porque é quando o pedido chegou inteiro.** Um
pedido dividido em duas caixas não está entregue quando a primeira chega — está
pela metade. Medir pela primeira daria uma média sistematicamente otimista, e o
erro cresceria com a fração de pedidos divididos.

**Pedido sem ciclo fechado fica de fora.** Se qualquer remessa do pedido ainda
está em trânsito, foi extraviada ou nunca saiu, o pedido não tem tempo até a
entrega — tem tempo até agora, que é outra medida. Excluí-lo é o que impede a
média de **melhorar** quando uma remessa se perde.

**A modalidade é a da remessa que fechou o ciclo**, a última a chegar. É a única
atribuição defensável quando um pedido viaja por duas transportadoras: foi ela
que determinou quando o pedido ficou completo.

**Não se cruza com a entrega no prazo.** Aquela conta remessas e esta conta
pedidos (ADR-0033). Um pedido com uma remessa entregue e outra extraviada aparece
lá e não aparece aqui — as duas medidas nem sempre contam a mesma população, e
somá-las ou dividi-las uma pela outra produz número sem significado.

{% enddocs %}
