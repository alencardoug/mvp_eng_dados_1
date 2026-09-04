-- Eventos de ciclo de vida do carrinho — o grão de `fact_cart_event`.
--
-- ADR-0028: até dois eventos por carrinho, a abertura e o desfecho. Carrinho
-- ainda aberto e dentro do prazo tem só o primeiro, porque o desfecho dele
-- ainda não aconteceu.
--
-- Cada linha carrega **duas datas**: a do evento e a da criação do carrinho. As
-- views agregam pela segunda, porque o carrinho pertence ao mês em que foi
-- aberto — um carrinho de 30 de novembro convertido em 2 de dezembro contaria
-- duas vezes em recortes diferentes, e a taxa de conversão de dezembro poderia
-- passar de 100%.

with carrinhos as (

    select * from {{ ref('carts') }}
    -- Carrinho sem item não gera evento: nunca houve intenção de compra
    -- registrada, e incluí-lo infla o denominador do funil (ADR-0028).
    where item_count > 0

),

abertura as (

    select
        cart_id,
        'created'                       as event_type,
        cart_created_at                 as occurred_at
    from carrinhos

),

desfecho as (

    select
        cart_id,
        cart_status                     as event_type,
        case cart_status
            when 'converted' then cart_converted_at
            -- Abandono e expiração não têm carimbo próprio na origem: o que se
            -- sabe é que o ciclo terminou até a validade. É a melhor
            -- aproximação disponível, e está dita aqui em vez de escondida.
            else least(cart_expires_at, timestamptz '{{ var("as_of_date") }} 00:00-03')
        end                             as occurred_at
    from carrinhos
    where cart_status <> 'open'

),

eventos as (

    select * from abertura
    union all
    select * from desfecho

)

select
    {{ dbt_utils.generate_surrogate_key(['e.cart_id', 'e.event_type']) }} as cart_event_key,
    e.cart_id,
    e.event_type,
    e.occurred_at,
    cast(e.occurred_at at time zone 'America/Sao_Paulo' as date)   as event_date,
    cast(c.cart_created_at at time zone 'America/Sao_Paulo' as date) as cart_created_date,

    c.customer_id,
    c.sales_channel_id,
    c.item_count,
    c.unit_count,
    c.cart_value_amount,
    c.is_anonymous,
    c.is_converted,
    c.is_abandoned,
    c.is_deleted
from eventos e
join carrinhos c on c.cart_id = e.cart_id
