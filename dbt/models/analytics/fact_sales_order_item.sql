-- Fato de venda.
--
-- **Grão: uma linha de item de pedido.** Uma linha aqui é um SKU comprado em um
-- pedido. O teste de unicidade sobre `order_item_key` é o que prova que o grão
-- é o que se afirma — sem ele, "grão" é intenção.
--
-- ── O *join* temporal ────────────────────────────────────────────────────────
-- Cliente e produto entram pela versão **vigente no instante da venda**, não
-- pela corrente (ADR-0017). É mais caro que um *join* por igualdade, e é o preço
-- de a fato ser historicamente correta: recategorizar um produto hoje não muda a
-- categoria em que a venda de 2024 foi contada.
--
-- ── O que **não** está aqui ──────────────────────────────────────────────────
-- Nenhum valor de nível de pedido — `order_total_amount`, `shipping_amount`.
-- Eles são do pedido, e esta fato é de item: somá-los aqui multiplicaria o frete
-- pelo número de itens do pedido. Quem reconcilia com o financeiro é
-- `trusted.orders`, que está no grão certo. Ratear o frete entre as linhas é
-- possível e vira necessário na margem da Etapa 6 — quando for, será decisão
-- escrita, não um número que apareceu.

with itens as (

    select * from {{ ref('order_items') }}

),

pedidos as (

    select * from {{ ref('orders') }}

),

cliente as (

    select * from {{ ref('dim_customer') }}

),

produto as (

    select * from {{ ref('dim_product') }}

),

vendas as (

    select
        i.order_item_id,
        i.order_id,
        i.product_variant_id,
        i.quantity,
        i.unit_price,
        i.gross_revenue_amount,
        i.discount_amount,
        i.net_revenue_amount,
        i.tax_amount,
        i.line_total_amount,

        p.order_number,
        p.customer_id,
        p.sales_channel_id,
        p.order_status,
        p.placed_at,
        p.is_realised,
        p.is_cancelled,
        p.is_from_cart,
        p.has_post_order_repeat,
        p.is_repeat_window_closed,
        p.days_to_next_order,
        cast(p.placed_at at time zone 'America/Sao_Paulo' as date) as order_date
    from itens i
    join pedidos p on p.order_id = i.order_id

)

select
    {{ dbt_utils.generate_surrogate_key(['v.order_item_id']) }} as order_item_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    d.date_key,
    c.customer_key,
    pr.product_key,
    ch.sales_channel_key,
    cat.category_key,
    br.brand_key,
    coalesce(g.geography_key, {{ chave_desconhecida() }}) as geography_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    -- Identificadores operacionais que não merecem dimensão própria, mas que
    -- toda investigação começa procurando (Modelo de Dados §3.2).
    v.order_id,
    v.order_item_id,
    v.order_number,
    v.order_status,
    v.order_date,
    v.placed_at,
    v.is_realised,
    v.is_cancelled,
    v.is_from_cart,

    -- ── Grão de pedido — reduzir antes de agregar ────────────────────────────
    -- Recompra pós-pedido ([ADR-0036](../../../docs/adr/0036-recompra-ancorada-no-pedido.md)):
    -- atributos do **pedido**, repetidos em cada item dele. Estão aqui porque
    -- P16 os compara e o consumo só lê `analytics`. Média ou contagem sobre eles
    -- no grão do item pesa cada pedido pelo número de itens — reduza a
    -- `order_id` antes, como a view de P16 faz.
    --
    -- `has_post_order_repeat` é **nulo** enquanto a janela de 90 dias não fechou:
    -- janela aberta não é ausência de recompra.
    v.has_post_order_repeat,
    v.is_repeat_window_closed,
    v.days_to_next_order,

    -- ── Medidas, todas aditivas ──────────────────────────────────────────────
    v.quantity,
    v.unit_price,
    v.gross_revenue_amount,
    v.discount_amount,
    v.net_revenue_amount,
    v.tax_amount,
    v.line_total_amount
from vendas v
join {{ ref('dim_date') }} d on d.full_date = v.order_date

-- Versão do cliente vigente no instante da venda.
join cliente c
  on c.customer_natural_key = v.customer_id
 and v.placed_at >= c.valid_from
 and (c.valid_to is null or v.placed_at < c.valid_to)

-- Versão do SKU vigente no instante da venda.
join produto pr
  on pr.product_natural_key = v.product_variant_id
 and v.placed_at >= pr.valid_from
 and (pr.valid_to is null or v.placed_at < pr.valid_to)

join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_natural_key = v.sales_channel_id
join {{ ref('dim_category') }} cat on cat.category_natural_key = pr.product_category_id
left join {{ ref('dim_brand') }} br on br.brand_natural_key = pr.brand_id
left join {{ ref('dim_geography') }} g
  on g.country = c.country and g.state_code = c.state_code and g.city = c.city
