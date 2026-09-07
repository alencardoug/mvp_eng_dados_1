-- Identificadores iguais nas duas origens não podem virar a mesma linha.
--
-- Dois sistemas numeram clientes a partir de 1, então o cliente 42 existe nos
-- dois — e o risco não é hipotético: sem a origem na chave substituta, o
-- `unique` de `dim_customer` quebra na primeira carga com legado. Foi o que
-- aconteceu ao empilhar pela primeira vez, e é o que este teste guarda.
--
-- Duas afirmações, uma consulta: nenhuma chave substituta se repete, e a
-- sobreposição de identificadores entre as origens é **real** — se ela deixar
-- de existir, o teste passa a não provar nada e precisa ser revisto.

with chaves_repetidas as (

    select customer_key
    from {{ ref('dim_customer') }}
    group by customer_key
    having count(*) > 1

),

sobreposicao as (

    select customer_natural_key
    from {{ ref('dim_customer') }}
    group by customer_natural_key
    having count(distinct source_system) > 1

)

select 'chave substituta repetida' as violacao, customer_key::text as detalhe
from chaves_repetidas

union all

-- Zero sobreposição significaria que o teste não está exercitando o que diz.
select 'sem sobreposição de identificadores entre origens', 'nenhuma'
where not exists (select 1 from sobreposicao)
