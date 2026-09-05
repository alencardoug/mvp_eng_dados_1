-- A entrega que a origem projeta existe no livro.
--
-- O [ADR-0034](../../docs/adr/0034-entrega-do-livro-de-eventos.md) fez do livro
-- `delivery_events` a fonte da data de entrega, e a coluna
-- `shipments.delivered_at` a conferência. Este é o ato de conferir.
--
-- Remessa que a origem diz entregue sem evento `delivered` correspondente não
-- é contada como entregue **e não é descartada**: ela está em
-- `quarantine.rejected_shipment_deliveries` com código e motivo. Este teste
-- falha quando isso acontece — não porque a quarentena seja proibida, mas
-- porque uma divergência entre as duas fontes é achado que alguém precisa
-- olhar, e não estado normal de operação.
--
-- Hoje a quarentena está vazia: a origem sintética emite `delivered` para toda
-- remessa entregue, inclusive para a devolvida, que registra `delivered` antes
-- de `returned`.

select
    shipment_id,
    shipment_code,
    rejection_code,
    delivered_at_projected
from {{ ref('rejected_shipment_deliveries') }}
