{#-
    Vigências de uma mesma chave natural não podem se sobrepor.

    É a invariante 11 do Modelo de Dados e a exigência do ADR-0017. Sem ela, um
    *join* temporal pode encontrar **duas** versões válidas no mesmo instante e
    duplicar a linha de fato — erro que não aparece como falha, aparece como
    receita maior.

    Duas vigências se sobrepõem quando cada uma começa antes de a outra acabar.
    `coalesce` com um horizonte distante trata a versão corrente, cujo fim é
    nulo, sem precisar de ramo separado.

    ── A chave natural inclui a origem ───────────────────────────────────────
    Desde o empilhamento (ADR-0021), a identidade de uma entidade é o par
    (`source_system`, id). Comparar vigências só pelo id faria duas versões
    **válidas** — uma de cada origem, com início diferente — parecerem
    sobreposição: o teste reprovaria dado correto, que é a falha mais cara de
    um teste, porque ensina a ignorá-lo.

    `origem` é parâmetro para que dimensão conformada, que legitimamente não
    tem procedência, possa passar `none`.
-#}
{% test vigencias_sem_sobreposicao(model, chave_natural, inicio='valid_from', fim='valid_to', origem='source_system') %}

with vigencias as (
    select
        {% if origem %}{{ origem }} || '-' || {% endif %}{{ chave_natural }} as chave,
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
