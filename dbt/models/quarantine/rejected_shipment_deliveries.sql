-- Remessas que a origem diz entregues e o livro não confirma.
--
-- Primeiro morador do schema `quarantine` ([ADR-0008](../../../docs/adr/0008-schemas-do-armazem.md)),
-- que até aqui existia declarado e vazio. Ele chega antes da Etapa 10 porque o
-- [ADR-0034](../../../docs/adr/0034-entrega-do-livro-de-eventos.md) criou a
-- primeira rejeição possível fora do legado: se `shipments.delivered_at` está
-- preenchida e não há evento `delivered` correspondente, a remessa **não** é
-- contada como entregue — e a regra 4 do `CLAUDE.md` proíbe que ela seja
-- descartada em silêncio por isso.
--
-- Esta tabela é destino, não passagem: nada lê dela para transformar. Quem lê é
-- quem audita, e o teste `entrega_projetada_tem_evento_no_livro`, que falha se
-- ela deixar de estar vazia sem que alguém tenha decidido o contrário.
--
-- O código de rejeição segue a convenção do catálogo do legado
-- ([Origem Legada §3.1](../../../docs/origem_legada.md)) — `UPPER_SNAKE`, estável
-- e nunca reaproveitado —, ainda que a origem aqui seja outra. Um segundo
-- vocabulário de motivos seria duas linguagens para a mesma auditoria.

select
    shipment_id,
    shipment_code,
    order_id,
    carrier_id,
    warehouse_id,
    shipment_status,
    shipped_at,
    estimated_delivery_at,
    delivered_at_projected,
    delivery_event_count,
    last_event_at,

    'DELIVERY_WITHOUT_EVENT'                        as rejection_code,
    'A origem marcou a remessa como entregue, e o livro `delivery_events` não '
    || 'registra o evento `delivered` correspondente. A entrega não é contada, e '
    || 'a data projetada não é usada como substituta (ADR-0034).'
                                                    as rejection_reason,
    'trusted.shipments'                             as rejected_from
from {{ ref('shipments') }}
where is_delivery_unbacked
