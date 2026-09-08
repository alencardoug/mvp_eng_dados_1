{#-
    A identidade de um vínculo, comparável entre a auditoria bruta e o pai tipado.

    ── O problema (R29) ───────────────────────────────────────────────────────
    A quarentena guarda o `original_payload` como veio: um `order_id` textual
    `08` continua `08`, porque foi guardado antes de qualquer conversão — e é
    esse o ponto de guardá-lo. O pai, empilhado, chegou à ponte como `bigint 8`.
    Comparar `q.original_payload->>'order_id' = o.order_id::text` compara `08`
    com `8`: mesmo com captura, versão e impressão iguais, a contrapartida não é
    encontrada, a divergência fica sem explicação e a invariante acusa um defeito
    que não existe.

    ── Por que não converter o payload ────────────────────────────────────────
    Um `cast` direto sobre o payload rejeitado derruba a consulta: o valor pode
    ter sido rejeitado **justamente** por não ser conversível. A canonização
    abaixo só age quando o texto é um inteiro escrito por extenso; qualquer
    outra coisa passa intacta e volta a ser comparada como texto.

    ── O que se aceita ────────────────────────────────────────────────────────
    Sob esta regra, `08` e `8` passam a ser a mesma identidade. Isso é o contrato
    do pai em todos os chamadores de hoje — `order_id`, `shipment_id`,
    `warehouse_id` e `product_variant_id` são todos `bigint`, e para o `bigint`
    os dois textos são o mesmo número. Para uma chave **textual** em que o zero à
    esquerda distinga dois registros, esta canonização os fundiria; nenhum
    chamador atual tem chave assim, e um que tenha precisa de outra macro, não
    de um parâmetro a mais nesta.
-#}
{% macro identidade_canonica(expressao) -%}
    (case
        when ({{ expressao }}) ~ '^\s*-?[0-9]+\s*$' then (({{ expressao }})::numeric)::text
        else ({{ expressao }})
     end)
{%- endmacro %}
