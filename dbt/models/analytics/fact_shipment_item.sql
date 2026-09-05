-- Fato de entrega.
--
-- **Grão: um item de uma remessa.** Uma linha é *"destas unidades vendidas,
-- tantas viajaram nesta caixa"*. O `unique` sobre `shipment_item_key` é o que
-- prova o grão.
--
-- ── Duas datas, dois papéis ─────────────────────────────────────────────────
-- `date_key` é a data em que a remessa **saiu** — é o momento que cria o fato.
-- `delivered_date_key` é a data em que ela **chegou**, e é o papel que P13 usa
-- para contar entregas mês a mês. São duas junções à mesma `dim_date`, com
-- significados diferentes; misturá-las numa só faria a taxa de pontualidade de
-- um mês incluir remessas que chegaram no seguinte.
--
-- `delivered_date_key` é **nulo** enquanto a remessa não chega, e essa é a
-- única chave de dimensão nula do datamart. A alternativa habitual — o membro
-- desconhecido do `chave_desconhecida()` — não serve aqui: `dim_date` é gerada
-- da série de datas e não tem linha para "ainda não aconteceu", e inventar uma
-- criaria uma data que nenhum calendário contém. O nulo aqui significa *evento
-- futuro*, não junção falhada, e toda view que o usa filtra `is_delivered`
-- antes de juntar.
--
-- ── O que **não** está aqui ─────────────────────────────────────────────────
-- `freight_amount`, pela mesma razão que `fact_sales_order_item` não carrega
-- `shipping_amount`: o frete é da remessa, e repeti-lo em cada item o
-- multiplicaria pelo número de itens da caixa. Quem está no grão do frete é
-- `trusted.shipments`.
--
-- ── As colunas de grão de pedido ────────────────────────────────────────────
-- `order_delivered_at`, `order_to_delivery_days`, `is_order_cycle_closed` e
-- `order_shipment_count` são atributos do **pedido**, repetidos em cada linha
-- de item. Estão aqui porque o ciclo de entrega do ADR-0033 é medido no pedido
-- e o consumo só lê `analytics`. **Média sobre elas no grão do item pesa cada
-- pedido pelo número de itens que ele tem**: quem as usa reduz antes ao grão do
-- pedido, e é o que a view de P14 faz, pelas linhas em
-- `is_cycle_closing_shipment`.

with remessas as (

    select * from {{ ref('shipments') }}

),

itens as (

    select * from {{ ref('shipment_items') }}

),

pedidos as (

    select * from {{ ref('orders') }}

),

-- Ciclo de entrega no grão do pedido (ADR-0033): fecha na última remessa a
-- chegar, e só fecha quando **todas** chegaram. Pedido com uma remessa
-- extraviada nunca fecha o ciclo — e é assim que deve ser: ele não chegou.
ciclo as (

    select
        order_id,
        count(*)                                        as order_shipment_count,
        count(*) filter (where is_delivered)            as delivered_shipment_count,
        bool_and(is_delivered)                          as is_order_cycle_closed,
        max(delivered_at) filter (where is_delivered)   as order_delivered_at
    from remessas
    group by order_id

),

-- Qual remessa fechou o ciclo. O desempate por `shipment_id` existe para que
-- duas remessas chegando no mesmo instante não produzam dois fechamentos —
-- caso raro, e silencioso quando acontece.
fechamento as (

    select
        shipment_id,
        order_id,
        row_number() over (
            partition by order_id order by delivered_at desc, shipment_id desc
        ) = 1                                           as is_cycle_closing_shipment
    from remessas
    where is_delivered

),

base as (

    select
        i.shipment_item_id,
        i.shipment_id,
        i.order_item_id,
        i.order_id,
        i.product_variant_id,
        i.quantity_shipped,
        i.quantity_ordered,
        i.shipped_share_of_line,

        r.shipment_code,
        r.carrier_id,
        r.warehouse_id,
        r.shipment_status,
        r.tracking_code,
        r.shipped_at,
        r.estimated_delivery_at,
        r.delivered_at,
        r.returned_at,
        r.is_delivered,
        r.is_dispatched,
        r.is_returned,
        r.is_lost,
        r.is_on_time,
        r.delivery_delay_days,
        r.transit_days,
        r.failed_attempt_count,

        -- Remessa ainda não despachada não tem data de saída; a data em que
        -- ela foi criada é o momento que a trouxe à existência.
        cast(coalesce(r.shipped_at, r.source_created_at) at time zone 'America/Sao_Paulo' as date)
                                                        as shipment_date,
        cast(r.delivered_at at time zone 'America/Sao_Paulo' as date)
                                                        as delivered_date,

        p.customer_id,
        p.sales_channel_id,
        p.order_number,
        p.order_status,
        p.placed_at,

        c.order_shipment_count,
        c.delivered_shipment_count,
        c.is_order_cycle_closed,
        c.order_delivered_at,
        coalesce(f.is_cycle_closing_shipment, false)    as is_cycle_closing_shipment,

        -- O ciclo do pedido só existe quando ele fechou. Pedido pela metade
        -- entregue não tem tempo até a entrega — tem tempo até agora, que é
        -- outra medida e não é a de P14.
        case
            when c.is_order_cycle_closed
            then extract(epoch from c.order_delivered_at - p.placed_at) / 86400.0
        end::numeric(12, 4)                             as order_to_delivery_days
    from itens i
    join remessas r on r.shipment_id = i.shipment_id
    join pedidos p on p.order_id = i.order_id
    join ciclo c on c.order_id = i.order_id
    left join fechamento f on f.shipment_id = i.shipment_id

)

select
    {{ dbt_utils.generate_surrogate_key(['b.shipment_item_id']) }} as shipment_item_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    d.date_key,
    dd.date_key                                         as delivered_date_key,
    cr.carrier_key,
    w.warehouse_key,
    cu.customer_key,
    pr.product_key,
    ch.sales_channel_key,
    coalesce(g.geography_key, {{ chave_desconhecida() }}) as geography_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    b.shipment_id,
    b.shipment_item_id,
    b.order_item_id,
    b.order_id,
    b.shipment_code,
    b.order_number,
    b.tracking_code,
    b.shipment_status,
    b.order_status,

    b.placed_at,
    b.shipped_at,
    b.estimated_delivery_at,
    b.delivered_at,
    b.returned_at,

    -- ── Sinalizadores do grão da remessa ─────────────────────────────────────
    b.is_dispatched,
    b.is_delivered,
    b.is_returned,
    b.is_lost,
    b.is_on_time,

    -- ── Grão do pedido — reduzir antes de agregar (ver o cabeçalho) ──────────
    b.order_shipment_count,
    b.delivered_shipment_count,
    b.is_order_cycle_closed,
    b.is_cycle_closing_shipment,
    b.order_shipment_count > 1                          as is_split_order,
    b.order_delivered_at,
    b.order_to_delivery_days,

    -- ── Medidas ──────────────────────────────────────────────────────────────
    -- Aditivas: unidades. Não aditivas: os dias, que são médias.
    b.quantity_shipped,
    b.quantity_ordered,
    b.shipped_share_of_line,
    b.failed_attempt_count,
    b.delivery_delay_days,
    b.transit_days
from base b
join {{ ref('dim_date') }} d on d.full_date = b.shipment_date
left join {{ ref('dim_date') }} dd on dd.full_date = b.delivered_date

join {{ ref('dim_carrier') }} cr on cr.carrier_natural_key = b.carrier_id
join {{ ref('dim_warehouse') }} w on w.warehouse_natural_key = b.warehouse_id
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_natural_key = b.sales_channel_id

-- Versão do cliente e do SKU vigentes no instante da **venda**, não da entrega:
-- é a mesma âncora temporal de `fact_sales_order_item`, e é o que permite
-- cruzar venda e entrega sem que as duas fatos apontem para versões diferentes
-- do mesmo cliente.
join {{ ref('dim_customer') }} cu
  on cu.customer_natural_key = b.customer_id
 and b.placed_at >= cu.valid_from
 and (cu.valid_to is null or b.placed_at < cu.valid_to)

join {{ ref('dim_product') }} pr
  on pr.product_natural_key = b.product_variant_id
 and b.placed_at >= pr.valid_from
 and (pr.valid_to is null or b.placed_at < pr.valid_to)

left join {{ ref('dim_geography') }} g
  on g.country = cu.country and g.state_code = cu.state_code and g.city = cu.city
