-- Itens de remessa — o grão de `fact_shipment_item`.
--
-- Uma linha é *"desta unidade vendida, tantas foram nesta caixa"*. O item de
-- pedido é **repartido** entre as remessas do pedido, nunca copiado: é o que
-- sustenta a invariante 5 — remessa não envia mais do que foi vendido —, já
-- verificada desde a Etapa 6 por `invariante_05_remessa_nao_excede_o_vendido`.
--
-- O SKU vem do item de pedido, não da remessa: a caixa não sabe o que carrega,
-- o pedido sabe.

with itens_de_remessa as (

    select * from {{ ref('stg_retail__shipment_items') }}

),

itens_de_pedido as (

    select
        order_item_id,
        order_id,
        product_variant_id,
        quantity                                    as quantity_ordered,
        unit_price,
        net_revenue_amount
    from {{ ref('order_items') }}

)

select
    si.shipment_item_id,
    si.shipment_id,
    si.order_item_id,
    oi.order_id,
    oi.product_variant_id,

    si.quantity_shipped,
    oi.quantity_ordered,

    -- Fração da linha vendida que viajou nesta caixa. É o rateio que permite
    -- responder "quanto do pedido chegou" quando ele se divide em duas
    -- remessas, sem recontar a receita: a medida de dinheiro continua sendo de
    -- `fact_sales_order_item`, e esta é de **unidades**.
    case
        when oi.quantity_ordered > 0
        then si.quantity_shipped::numeric / oi.quantity_ordered
    end::numeric(12, 6)                             as shipped_share_of_line,

    si.is_deleted,
    si.source_created_at,
    si.source_updated_at
from itens_de_remessa si
join itens_de_pedido oi on oi.order_item_id = si.order_item_id
