# Cobertura de estoque

{% docs days_of_cover %}

**Cobertura de estoque** é por quantos dias o saldo disponível de um SKU dura ao
ritmo da demanda recente. Responde "quanto tempo eu tenho", que é a pergunta que
o comprador faz — e não "quanto eu tenho", que é a que o saldo responde.

- **Cálculo:** `quantity_available ÷ demanda diária média`, onde a demanda é a
  média das unidades **vendidas** por dia na janela de cobertura declarada em
  `dbt_project.yml`.
- **Implementado em:** view `skus_below_reorder_point`.
- **Relacionado:** ruptura de estoque, giro de estoque, ponto de reposição.

**Só venda conta como demanda.** Transferência entre armazéns e devolução ao
fornecedor também tiram unidades do armazém, e nenhuma das duas é demanda de
cliente. Somá-las encurtaria a cobertura e faria o alerta disparar antes da hora,
sobre um consumo que não vai se repetir.

**Cobertura é razão, e razão não se soma.** É **não aditiva**: a cobertura de
dois SKUs não é a soma das duas, nem a média delas — quem reagregar precisa
refazer a conta a partir do saldo e da demanda, que por isso vão ao lado dela na
view.

**Cobertura indefinida não é cobertura zero.** SKU sem venda na janela não tem
cobertura de zero dias: ele tem cobertura indeterminada, porque não há ritmo
contra o qual medir. A view devolve nulo, e escrever zero diria que o estoque
acaba hoje.

{% enddocs %}
