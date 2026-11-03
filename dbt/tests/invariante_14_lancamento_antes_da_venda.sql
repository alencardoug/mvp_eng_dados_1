-- Invariante 14 — nenhum produto é vendido antes do lançamento.
--
-- `launched_at` nulo quer dizer lançamento desconhecido e passa; conhecido, ele
-- não pode suceder o `placed_at` de nenhum pedido que contém o produto. Era a
-- D65: 3.130 de 7.500 itens do varejo vendidos antes do lançamento, corrigido
-- no gerador da v1.1.0 (N39 do plano do `bi-como-codigo`).
--
-- **Só o varejo, por decisão do Owner (03/11/2026).** No legado, a conversão
-- de um formato de data pode antecipar um pedido em horas — `dd/mm/aaaa` vira
-- meia-noite —, e cada caso tem o código de falha do manifesto que o explica;
-- a sonda da regeneração da v1.1.0 os confere um a um. Sobre os dados de antes
-- da regeneração, este teste falha por desenho: é a guarda contra a volta.

select
    i.source_system,
    i.order_item_id,
    i.order_id,
    s.product_id,
    s.launched_at,
    o.placed_at
from {{ ref('order_items') }} i
join {{ ref('orders') }} o
    on o.source_system = i.source_system and o.order_id = i.order_id
join {{ ref('product_skus') }} s
    on s.source_system = i.source_system and s.product_variant_id = i.product_variant_id
where i.source_system = 'retail'
  and s.launched_at > o.placed_at
