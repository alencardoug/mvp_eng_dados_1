{{ config(severity = 'warn') }}

-- Toda remessa carrega alguma coisa.
--
-- **Severidade `warn`, e não `error`, por decisão pendente.** O achado é real —
-- 91 das 3.647 remessas não têm item nenhum, e caixa vazia é estado que a
-- operação não produz —, mas a correção é no gerador da Etapa 4, e o custo dela
-- é re-medir o projeto inteiro. Enquanto a **D31** não for decidida
-- ([Pendências](../../docs/pendencias.md)), o teste existe para manter o número
-- à vista a cada `build`, não para travar a entrega.
--
-- A causa está identificada: quando **todo** item do pedido tem quantidade 1, o
-- repartidor `_fatia` dá zero unidades ao primeiro lote, e a guarda que deveria
-- impedir a divisão nesse caso (`len(itens) >= 1`) é sempre verdadeira. As 91
-- estão todas em pedidos divididos — 14,3% dos 637.
--
-- Consequência visível enquanto durar: P13 conta 3.141 entregas e
-- `trusted.shipments` diz 3.221. A diferença **não** é perda do pipeline; é o
-- grão da fato, que é o item, encontrando remessa sem item nenhum.

select
    s.shipment_id,
    s.shipment_code,
    s.order_id,
    s.shipment_status
from {{ ref('shipments') }} s
left join {{ ref('shipment_items') }} i on i.shipment_id = s.shipment_id
group by s.shipment_id, s.shipment_code, s.order_id, s.shipment_status
having count(i.shipment_item_id) = 0
