-- Geografia conformada — cidade, UF e região.
--
-- Dimensão conformada: a mesma geografia atende o endereço de entrega na
-- Etapa 5 e a origem da remessa na Etapa 8. Por isso ela nasce em `trusted` com
-- chave natural própria, e não embutida no cliente.
--
-- A região vem do *seed* `brazilian_states`, que tem as 27 unidades federativas.
-- Um `left join` que não casa aqui é UF inválida na origem — e o teste
-- `not_null` em `region` transforma isso em falha, não em nulo silencioso.

with enderecos as (

    select distinct
        country,
        state as state_code,
        city
    from {{ ref('stg_retail__customer_addresses') }}

),

estados as (

    select * from {{ ref('brazilian_states') }}

)

select
    e.country,
    e.state_code,
    s.state_name,
    s.region,
    e.city
from enderecos e
left join estados s on s.state_code = e.state_code
