{#-
    Chave do **membro desconhecido** de uma dimensão.

    Toda dimensão conformada carrega uma linha de aterrissagem para o caso em
    que a fato não encontra par. Sem ela a alternativa é chave nula na fato — e
    chave nula não pode ser testada com `not_null`, some de qualquer `join` e
    faz a linha desaparecer de todo recorte por aquela dimensão, silenciosamente.

    Com a linha, o `not_null` volta a valer e o dado aparece agrupado em
    "Desconhecido", que é uma resposta honesta em vez de uma ausência.
-#}
{% macro chave_desconhecida() -%}
    {{ dbt_utils.generate_surrogate_key(["'__desconhecido__'"]) }}
{%- endmacro %}
