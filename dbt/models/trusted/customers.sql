-- Cliente com segmento, geografia principal e o seu histórico de compra.
--
-- Três conceitos do Glossário de Negócio nascem aqui, e não em cada view que os
-- usa: cliente ativo, primeira compra e recorrência. Definidos uma vez, eles
-- param de divergir entre perguntas.
--
-- **A janela é contada de `as_of_date`, nunca de `current_date`.** Um modelo que
-- usa o relógio do banco produz resultado diferente a cada execução sobre o
-- mesmo dado, e a reprodutibilidade do projeto (P2) deixa de existir.

{% set as_of = "date '" ~ var("as_of_date") ~ "'" %}

with clientes as (

    select * from {{ ref('stg_retail__customers') }}

),

segmentos as (

    select * from {{ ref('stg_retail__customer_segments') }}

),

endereco_principal as (

    -- Um principal por cliente e tipo, garantido por índice parcial na origem.
    -- `distinct on` protege o modelo mesmo assim: se a garantia cair, o
    -- resultado continua determinístico em vez de dobrar linhas de cliente.
    select distinct on (customer_id)
        customer_id,
        city,
        state,
        country
    from {{ ref('stg_retail__customer_addresses') }}
    where is_primary and address_type = 'shipping' and not is_deleted
    order by customer_id, valid_from desc

),

compras as (

    select
        o.customer_id,
        min(o.placed_at)                                as first_order_at,
        max(o.placed_at)                                as last_order_at,
        count(*)                                        as order_count,
        sum(o.items_net_revenue_amount)                 as lifetime_net_revenue_amount
    from {{ ref('orders') }} o
    where o.is_realised
    group by o.customer_id

),

segunda_compra as (

    -- Recorrência: existe segundo pedido dentro da janela contada da estreia.
    -- A coorte é a do mês da **estreia**, não a da recompra — é assim que a
    -- taxa de um mês para de mudar depois de fechada a janela.
    select
        o.customer_id,
        min(o.placed_at)                                as second_order_at
    from {{ ref('orders') }} o
    join compras c on c.customer_id = o.customer_id
    where o.is_realised and o.placed_at > c.first_order_at
    group by o.customer_id

)

select
    c.customer_id,
    c.customer_code,
    c.first_name,
    c.last_name,
    c.customer_full_name,
    c.customer_document,
    c.birth_date,
    c.customer_status,
    c.registered_at,

    c.customer_segment_id,
    s.customer_segment_code,
    s.customer_segment_name,

    e.city,
    e.state                                             as state_code,
    e.country,

    p.first_order_at,
    p.last_order_at,
    coalesce(p.order_count, 0)                          as order_count,
    coalesce(p.lifetime_net_revenue_amount, 0)          as lifetime_net_revenue_amount,
    r.second_order_at,

    -- Glossário: cliente ativo tem pedido não cancelado na janela declarada,
    -- contada de `as_of_date`. Pedido devolvido conta — houve compra, e a
    -- devolução é outro fato.
    p.last_order_at >= {{ as_of }} - interval '{{ var("active_customer_window_days") }} days'
                                                        as is_active,
    r.second_order_at is not null
        and r.second_order_at <= p.first_order_at
            + interval '{{ var("repeat_purchase_window_days") }} days'
                                                        as is_repeat_buyer,

    -- Glossário: **churn** é a perda de um cliente que já foi ativo. Exige as
    -- duas metades — comprou alguma vez, e a janela de cliente ativo se fechou
    -- sem compra nova. Quem nunca comprou não entrou, e por isso não saiu: é
    -- cadastro sem conversão, que é outro problema e outra métrica.
    p.first_order_at is not null
        and p.last_order_at < {{ as_of }}
            - interval '{{ var("active_customer_window_days") }} days'
                                                        as is_churned,
    case
        when p.last_order_at is not null
        then extract(epoch from {{ as_of }} - p.last_order_at) / 86400.0
    end::numeric(12, 2)                                 as days_since_last_order,

    c.is_deleted,
    c.source_created_at,
    c.source_updated_at
from clientes c
left join segmentos s on s.customer_segment_id = c.customer_segment_id
left join endereco_principal e on e.customer_id = c.customer_id
left join compras p on p.customer_id = c.customer_id
left join segunda_compra r on r.customer_id = c.customer_id
