{#-
    Vigências de uma mesma chave natural não podem se sobrepor.

    É a invariante 11 do Modelo de Dados e a exigência do ADR-0017. Sem ela, um
    *join* temporal pode encontrar **duas** versões válidas no mesmo instante e
    duplicar a linha de fato — erro que não aparece como falha, aparece como
    receita maior.

    Duas vigências se sobrepõem quando cada uma começa antes de a outra acabar.
    `coalesce` com um horizonte distante trata a versão corrente, cujo fim é
    nulo, sem precisar de ramo separado.
-#}
{% test vigencias_sem_sobreposicao(model, chave_natural, inicio='valid_from', fim='valid_to') %}

with vigencias as (
    select
        {{ chave_natural }} as chave,
        {{ inicio }}        as inicio,
        coalesce({{ fim }}, timestamptz '9999-12-31') as fim
    from {{ model }}
)

select
    a.chave,
    a.inicio as inicio_a,
    b.inicio as inicio_b
from vigencias a
join vigencias b
  on a.chave = b.chave
 and a.inicio < b.inicio
where a.fim > b.inicio

{% endtest %}
