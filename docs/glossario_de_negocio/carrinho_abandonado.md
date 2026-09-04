# Carrinho abandonado

{% docs abandoned_cart %}

**Carrinho abandonado** é o carrinho que teve ao menos um item adicionado e **não** virou pedido,
já tendo encerrado o seu ciclo — abandonado explicitamente ou expirado por prazo.

- **Cálculo:** carrinho com `cart_item_count > 0` e evento terminal em `abandoned` ou `expired`.
- **Implementado em:** `fact_cart_event`, evento terminal; medida `abandoned_cart_value`.
- **Relacionado:** taxa de conversão.

**Carrinho vazio não é carrinho abandonado**, e carrinho ainda dentro do prazo também não: o
primeiro nunca teve intenção de compra registrada, e o segundo ainda pode converter. Contar os dois
como abandono infla o funil e faz a taxa de conversão parecer pior do que é.

O **valor abandonado** é a soma de `quantity × unit_price` dos itens no momento em que entraram no
carrinho — preço praticado então, não o preço de hoje.

{% enddocs %}
