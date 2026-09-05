-- Invariante 12 — o cupom só é usado dentro da vigência e segundo as suas
-- regras de elegibilidade.
--
-- São três regras independentes, e o teste devolve **qual** delas quebrou. Uma
-- falha genérica diria que há resgate inválido; esta diz se o problema é
-- vigência, piso ou teto — e as três se corrigem em lugares diferentes.
--
-- Nenhuma delas é `CHECK` na origem porque nenhuma cabe numa linha só: a
-- vigência mora no cupom e o resgate mora na tabela de resgates; o piso compara
-- com o **pedido**; e o teto depende de **todos** os resgates anteriores do
-- mesmo cupom — é a mesma razão pela qual a invariante 5 também é teste.
--
-- A quarta condição não é da lista original e foi acrescentada ao construir: o
-- desconto concedido não pode passar do valor do pedido. Cupom não paga o
-- cliente para comprar, e nenhuma das três primeiras impediria isso.

with resgates as (

    select * from {{ ref('coupon_redemptions') }}

)

select coupon_redemption_id, coupon_id, order_id, 'fora da vigencia' as violacao
from resgates where not is_within_validity

union all
select coupon_redemption_id, coupon_id, order_id, 'pedido abaixo do minimo'
from resgates where not is_above_minimum

union all
select coupon_redemption_id, coupon_id, order_id, 'acima do teto de resgates'
from resgates where not is_within_limit

union all
select coupon_redemption_id, coupon_id, order_id, 'desconto maior que o pedido'
from resgates where not is_discount_bounded
