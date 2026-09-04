-- Cliente — SCD tipo 2, com atributos descritivos e métricas de tipo 1.
--
-- Mesmo padrão misto de `dim_product`, pela mesma razão: o `dbt snapshot` só
-- versiona as colunas declaradas em `check_cols`, e congela as demais no valor
-- da primeira captura. Aqui a divisão é:
--
--   **tipo 2** — segmento, estado do relacionamento, geografia e exclusão. São
--                os atributos pelos quais se recorta uma venda histórica.
--   **tipo 1** — nome, documento, data de nascimento, e as **métricas de
--                compra**. Estas últimas são de natureza corrente: "quantos
--                pedidos este cliente já fez" é uma pergunta sobre hoje, não
--                sobre o instante da venda.

with versoes as (

    select
        *,
        row_number() over (partition by customer_id order by dbt_valid_from)
            as numero_da_versao
    from {{ ref('scd_customer') }}

),

atual as (

    select * from {{ ref('customers') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['v.customer_id', 'v.dbt_valid_from']) }} as customer_key,
    v.customer_id                                           as customer_natural_key,

    -- ── Tipo 1: descrevem a pessoa, ou descrevem o hoje ─────────────────────
    a.customer_code,
    a.first_name,
    a.last_name,
    a.customer_full_name,
    a.customer_document,
    a.birth_date,
    a.registered_at,
    a.first_order_at,
    a.last_order_at,
    a.order_count,
    a.lifetime_net_revenue_amount,
    a.is_active,
    a.is_repeat_buyer,

    -- ── Tipo 2: classificam a venda no instante em que ela aconteceu ────────
    v.customer_status,
    v.customer_segment_id,
    v.customer_segment_code,
    coalesce(v.customer_segment_name, 'Sem segmento')       as customer_segment_name,
    v.city,
    v.state_code,
    v.country,
    v.is_deleted,

    -- Vigência da primeira versão estendida até `period_start` — ver o
    -- comentário equivalente em `dim_product`.
    case
        when v.numero_da_versao = 1 then timestamptz '{{ var("period_start") }} 00:00-03'
        else v.dbt_valid_from
    end                                                     as valid_from,
    v.dbt_valid_to                                          as valid_to,
    v.dbt_valid_to is null                                  as is_current
from versoes v
join atual a on a.customer_id = v.customer_id
