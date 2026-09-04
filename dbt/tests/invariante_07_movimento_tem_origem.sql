-- Invariante 7 — todo movimento de estoque tem origem de negócio identificável.
--
-- Sem origem, o movimento é um número que apareceu no saldo: não dá para
-- reconciliar contra a compra que o gerou nem contra a venda que o consumiu, e
-- a linhagem do estoque deixa de existir.

select
    movement_id,
    movement_type,
    source_type,
    source_id
from {{ ref('inventory_movements') }}
where source_type is null
   or source_id is null
   or source_id = ''
   or quantity_delta = 0
