{#-
    A fato tem as linhas da sua relação condutora e as mesmas somas.

    É a fronteira `trusted → analytics` da Qualidade §7: grão declarado e
    **medidas somadas**. Toda fato nasce de uma relação de `trusted` — o item
    de pedido, a transação, a remessa — e a leva a um grão de dimensões por
    junções internas, algumas temporais (ADR-0017). Uma junção que não casa
    derruba a linha em silêncio: a fato continua com chave única, `not_null` e
    `relationships` passando, e a receita fica menor. Este teste é o que vê
    isso — contagem e soma de cada medida, dos dois lados, têm de ser iguais.

    `condutora` é a relação de `trusted` (`ref(...)`); `medidas` mapeia a
    coluna da fato à coluna da condutora (`{quantity: quantity}`) e pode ser
    vazio, quando só a contagem faz sentido. As somas são de `numeric` e
    inteiros, exatas; `is distinct from` trata a medida toda nula.

    Uma linha no resultado é uma medida (ou a contagem) em que os dois lados
    divergiram, com os dois valores.
-#}
{% test fato_reconcilia_com_a_condutora(model, condutora, medidas={}) %}

with fato as (
    select
        count(*)                                    as linhas
        {%- for na_fato, na_condutora in medidas.items() %},
        sum({{ na_fato }})                          as {{ na_fato }}
        {%- endfor %}
    from {{ model }}
),

condutora as (
    select
        count(*)                                    as linhas
        {%- for na_fato, na_condutora in medidas.items() %},
        sum({{ na_condutora }})                     as {{ na_fato }}
        {%- endfor %}
    from {{ condutora }}
)

select 'linhas' as medida, f.linhas::numeric as na_fato, c.linhas::numeric as na_condutora
from fato f, condutora c
where f.linhas <> c.linhas
{%- for na_fato in medidas %}

union all

select '{{ na_fato }}', f.{{ na_fato }}::numeric, c.{{ na_fato }}::numeric
from fato f, condutora c
where f.{{ na_fato }} is distinct from c.{{ na_fato }}
{%- endfor %}

{% endtest %}
