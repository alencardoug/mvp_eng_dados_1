-- O ciclo de entrega do pedido fecha na **última** remessa a chegar.
--
-- É o teste que separa os dois conceitos do
-- [ADR-0033](../../docs/adr/0033-entrega-medida-em-dois-graos.md), e o pedido
-- dividido é onde eles divergem — 22% dos pedidos, por construção do gerador.
--
-- Duas afirmações, uma consulta:
--
--   1. `order_to_delivery_days` nunca é **menor** que o tempo até a chegada de
--      qualquer remessa do pedido. Se fosse, o ciclo estaria fechando na
--      primeira caixa, e a média de P14 sairia otimista sem que nada indicasse.
--   2. O ciclo só é declarado fechado quando **todas** as remessas chegaram.
--      Pedido com uma remessa extraviada não pode ter ciclo: ele não chegou.

with por_remessa as (

    select distinct
        f.order_id,
        f.shipment_id,
        f.delivered_at,
        f.placed_at,
        f.is_delivered,
        f.is_order_cycle_closed,
        f.order_to_delivery_days,
        f.order_shipment_count,
        f.delivered_shipment_count
    from {{ ref('fact_shipment_item') }} f

)

-- 1. O ciclo é curto demais para conter esta remessa.
--
-- O `cast` dos dois lados para a escala da medida não é detalhe: sem ele, o
-- teste acusa 1.412 violações que são arredondamento. `order_to_delivery_days`
-- é `numeric(12, 4)`, e comparar o valor guardado com o cálculo em precisão
-- plena reprova a própria remessa que fechou o ciclo por diferenças da ordem de
-- 5 × 10⁻⁵ de dia — quatro segundos. A invariante é sobre a medida como o
-- datamart a guarda, e é nessa escala que ela se verifica.
select
    order_id,
    shipment_id,
    'ciclo menor que a chegada de uma remessa do pedido' as violacao
from por_remessa
where is_order_cycle_closed
  and delivered_at is not null
  and order_to_delivery_days
      < (extract(epoch from delivered_at - placed_at) / 86400.0)::numeric(12, 4)

union all

-- 2. O ciclo foi declarado fechado com remessa em aberto.
select distinct
    order_id,
    null::bigint,
    'ciclo fechado com remessa nao entregue'
from por_remessa
where is_order_cycle_closed
  and delivered_shipment_count < order_shipment_count
