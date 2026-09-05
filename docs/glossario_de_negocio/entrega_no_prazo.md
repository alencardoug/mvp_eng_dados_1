# Entrega no prazo

{% docs on_time_delivery %}

**Entrega no prazo** é a remessa cuja chegada não é posterior à promessa que ela
carregava: `delivered_at <= estimated_delivery_at`. O grão é a **remessa**, não
o pedido.

- **Cálculo:** `on_time_count / delivered_count`, por transportadora, modalidade
  e mês de chegada.
- **Implementado em:** view `on_time_delivery_rate_by_carrier`, coluna
  `on_time_rate`; sinalizador `is_on_time` em `trusted.shipments` e em
  `fact_shipment_item`.
- **Relacionado:** ciclo de entrega, prazo prometido.

**O grão é a remessa porque a promessa é da remessa.** Transportadora e
modalidade são atributos de quem leva a caixa, e um pedido dividido em duas
remessas tem duas promessas — possivelmente de modalidades diferentes. Ele conta
**duas vezes** aqui, e é o comportamento correto: foram duas promessas e duas
chegadas. Quem quer a experiência do pedido inteiro usa o *ciclo de entrega*, que
é outro conceito e não se soma a este.

**O denominador é o entregue, não o despachado.** Remessa em trânsito ainda não
está atrasada — ela não chegou. Contá-la como fora do prazo trocaria "não chegou
ainda" por "chegou tarde", que são coisas diferentes e levam a decisões
diferentes. Remessa extraviada nunca entra no denominador, por não ter chegada.

**A data de chegada vem do livro de eventos**, não da coluna `delivered_at` da
remessa (ADR-0034). A coluna guarda o estado corrente e é sobrescrita; o livro
guarda o momento em que a chegada aconteceu. Medir prazo histórico contra a
coluna é medir contra o último `update`.

**Devolução não desfaz a entrega.** A remessa devolvida registra `delivered` e
depois `returned`: ela chegou, e no prazo em que chegou. A devolução é fato
posterior, contado à parte.

{% enddocs %}

{% docs promised_lead_time %}

**Prazo prometido** é a data até a qual a remessa deveria chegar, fixada no
despacho pela modalidade da transportadora que a leva —
`shipments.estimated_delivery_at`.

É **promessa, não evento**: pode estar no futuro sem que isso seja data
inconsistente, e não muda depois de feita. É contra ela, e não contra uma média
histórica, que a pontualidade é medida.

{% enddocs %}
