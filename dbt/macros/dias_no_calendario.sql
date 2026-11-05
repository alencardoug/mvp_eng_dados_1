{#
    Um instante deslocado de `dias` dias **no calendário de São Paulo** — o mesmo
    que as fatos usam para reduzir instante a data (`America/Sao_Paulo`).

    `timestamptz + interval 'N days'` soma os dias no fuso da **sessão**: numa sessão
    com horário de verão, o limite de uma janela andaria uma hora e uma compra perto
    dele mudaria de lado, sem nenhum instante de entrada mudar (revisão do lote 3 da
    v1.1.0, RVL3-6-04; decisão do Owner: calendário de São Paulo, explícito). Com o
    calendário dito, a janela não depende de quem roda. `dias` negativo subtrai.
#}
{%- macro dias_no_calendario(instante, dias) -%}
    ((({{ instante }}) at time zone 'America/Sao_Paulo') + interval '{{ dias }} days') at time zone 'America/Sao_Paulo'
{%- endmacro -%}
