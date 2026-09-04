# Taxa de conversão

{% docs cart_conversion_rate %}

**Taxa de conversão** é a fração dos carrinhos com item que resultaram em pedido, no mesmo recorte.

- **Cálculo:** `converted_cart_count / cart_count`, **recalculado a cada recorte**.
- **Implementado em:** view `cart_conversion_rate_by_channel`.
- **Relacionado:** carrinho abandonado, ticket médio.

**É medida não aditiva**, pelo mesmo motivo do ticket médio: taxas não se somam. A view entrega
numerador e denominador ao lado do resultado.

**O carrinho é contado no mês em que foi criado**, não no mês em que converteu. Um carrinho aberto
em 30 de novembro e convertido em 2 de dezembro pertence a novembro nas duas contagens — senão a
taxa de dezembro poderia passar de 100%.

Carrinhos ainda **abertos e dentro do prazo** ficam fora do denominador: o desfecho deles ainda não
existe, e incluí-los faria a taxa dos meses recentes cair sozinha com o passar dos dias.

{% enddocs %}
