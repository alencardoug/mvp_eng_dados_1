-- Fato de funil de carrinho (ADR-0028).
--
-- **Grão: um evento de ciclo de vida de um carrinho.** Até dois por carrinho —
-- a abertura e o desfecho.
--
-- ── Por que as medidas são contadores ────────────────────────────────────────
-- Um carrinho aparece em duas linhas. Se `cart_value_amount` viesse repetido
-- nas duas, somá-lo daria o dobro do valor real — e daria um número plausível,
-- que é o pior tipo de erro. Por isso cada medida vale **só na linha em que faz
-- sentido**, e zero nas outras: assim toda soma está certa em qualquer recorte,
-- sem ninguém precisar lembrar de filtrar por tipo de evento.
--
-- ── O denominador da conversão ───────────────────────────────────────────────
-- `closed_cart_count`, não `cart_count`. Carrinho ainda aberto e dentro do prazo
-- não tem desfecho, e incluí-lo faria a taxa dos meses recentes cair sozinha com
-- o passar dos dias (Glossário: taxa de conversão).

with eventos as (

    select * from {{ ref('cart_lifecycle_events') }}

),

cliente as (

    select * from {{ ref('dim_customer') }}

)

select
    e.cart_event_key,

    -- ── Chaves de dimensão ───────────────────────────────────────────────────
    -- Duas datas: a do evento e a da **criação do carrinho**. As views agregam
    -- pela segunda, porque o carrinho pertence ao mês em que foi aberto
    -- (ADR-0028).
    de.date_key                                     as event_date_key,
    dc.date_key                                     as cart_created_date_key,
    c.customer_key,
    ch.sales_channel_key,

    -- ── Dimensões degeneradas ────────────────────────────────────────────────
    e.cart_id,
    e.event_type,
    e.occurred_at,
    e.event_date,
    e.cart_created_date,
    e.is_anonymous,

    -- ── Medidas, todas aditivas por construção ───────────────────────────────
    case when e.event_type = 'created' then 1 else 0 end                as cart_count,
    case when e.event_type <> 'created' then 1 else 0 end               as closed_cart_count,
    case when e.event_type = 'converted' then 1 else 0 end              as converted_cart_count,
    case when e.event_type in ('abandoned', 'expired') then 1 else 0 end as abandoned_cart_count,

    case when e.event_type = 'created' then e.item_count else 0 end     as cart_item_count,
    case when e.event_type = 'created' then e.unit_count else 0 end     as cart_unit_count,
    case when e.event_type = 'created' then e.cart_value_amount else 0 end
                                                                        as cart_value_amount,
    case when e.event_type in ('abandoned', 'expired') then e.cart_value_amount else 0 end
                                                                        as abandoned_value_amount
from eventos e
join {{ ref('dim_date') }} de on de.full_date = e.event_date
join {{ ref('dim_date') }} dc on dc.full_date = e.cart_created_date
join {{ ref('dim_sales_channel') }} ch on ch.sales_channel_natural_key = e.sales_channel_id

-- Sessão anônima não tem cliente: o *join* é `left`, e a chave fica nula.
left join cliente c
  on c.customer_natural_key = e.customer_id
 and e.occurred_at >= c.valid_from
 and (c.valid_to is null or e.occurred_at < c.valid_to)
