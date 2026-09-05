# Churn

{% docs churn %}

**Churn** é a perda de um cliente que já foi ativo: comprou alguma vez e passou
a janela de **180 dias** sem comprar de novo, contada de `as_of_date`.

- **Cálculo:** `first_order_at is not null and last_order_at < as_of_date − 180
  dias`.
- **Implementado em:** `dim_customer`, colunas `is_churned` e
  `days_since_last_order`.
- **Relacionado:** cliente ativo, recorrência de compra, recompra pós-pedido.

**Churn é o complemento de cliente ativo, e só isso.** A janela é a mesma, de
propósito: dois conceitos de "quanto tempo sem comprar" produziriam dois números
que se contradizem sem que nenhum esteja errado. Quem muda a janela de um muda a
do outro, e a variável `active_customer_window_days` é onde isso acontece uma
vez só.

**Quem nunca comprou não deu churn.** Cadastro sem primeira compra não entrou, e
por isso não saiu — é problema de conversão, não de retenção, e misturar os dois
faz a base parecer pior do que é sempre que uma campanha traz cadastros novos.

**É condição, não evento.** A coluna responde *"este cliente está perdido
agora?"*, e não *"em que dia ele se perdeu"*. Um cliente que volta a comprar
deixa de estar em churn na leitura seguinte, sem que nada registre que ele
esteve. Datar o churn exigiria uma fato de estado do cliente, que este modelo
não tem — e a ausência está dita aqui em vez de ser descoberta por quem
perguntar.

{% enddocs %}
