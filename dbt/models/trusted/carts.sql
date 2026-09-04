-- Carrinho com contagem e valor dos seus itens.
--
-- O valor usa o preço praticado **no momento em que o item entrou** — é o que
-- o Glossário define como valor abandonado. Reprecificar pelo preço de hoje
-- responderia outra pergunta.

with carrinhos as (

    select * from {{ ref('stg_retail__carts') }}

),

itens as (

    select
        cart_id,
        count(*)                            as item_count,
        sum(quantity)                       as unit_count,
        round(sum(quantity * unit_price), 2) as cart_value_amount,
        min(added_at)                       as first_item_added_at
    from {{ ref('stg_retail__cart_items') }}
    group by cart_id

)

select
    c.cart_id,
    c.cart_code,
    c.customer_id,
    c.sales_channel_id,
    c.cart_status,
    c.cart_created_at,
    c.cart_expires_at,
    c.cart_converted_at,

    coalesce(i.item_count, 0)               as item_count,
    coalesce(i.unit_count, 0)               as unit_count,
    coalesce(i.cart_value_amount, 0)        as cart_value_amount,
    i.first_item_added_at,

    -- Sessão anônima: carrinho sem cliente identificado. Fica no funil, mas
    -- não entra em nenhuma análise por cliente.
    c.customer_id is null                   as is_anonymous,
    c.cart_status = 'converted'             as is_converted,
    -- Glossário: carrinho abandonado teve item e encerrou o ciclo sem virar
    -- pedido. Carrinho vazio nunca teve intenção registrada; carrinho ainda
    -- aberto e no prazo ainda pode converter — nenhum dos dois é abandono.
    c.cart_status in ('abandoned', 'expired') and coalesce(i.item_count, 0) > 0
                                            as is_abandoned,

    c.is_deleted,
    c.source_created_at,
    c.source_updated_at
from carrinhos c
left join itens i on i.cart_id = c.cart_id
