{#
    O instante que o `dbt snapshot` grava em `dbt_valid_from`, `dbt_valid_to` e
    `dbt_updated_at`: **UTC explícito**, sem fuso, qualquer que seja o fuso da sessão.

    O do dbt-postgres é `now()::timestamp without time zone` — a hora local da
    sessão. As dimensões SCD leem essas colunas como instante UTC (`at time zone
    'UTC'`); com o padrão, uma sessão em outro fuso (papel, banco, `PGTZ`) gravaria
    horas locais que seriam lidas como UTC, deslocando as vigências no join temporal
    sem erro nenhum. Fixar no escritor é o que remove a premissa — um teste depois da
    gravação não a protege (revisão do lote 3 da v1.1.0, RVL3-5-01).

    Sobrepõe a macro global de mesmo nome: a do projeto raiz vence. O tipo continua
    `timestamp without time zone`, o mesmo das colunas que já existem.
#}
{%- macro snapshot_get_time() -%}
    {#- No BigQuery a coluna é TIMESTAMP, que já é instante: fica a do adaptador
        (`current_timestamp()`), sem a premissa de fuso que esta macro remove. -#}
    {%- if target.type == 'bigquery' -%}
    {{ return(adapter.dispatch('snapshot_get_time', 'dbt')()) }}
    {%- endif -%}
    (now() at time zone 'UTC')
{%- endmacro -%}

{#- A mesma, na variante que o `adapter.dispatch` procura — a checagem de tipo do
    snapshot a chama direto, sem passar pela de cima. -#}
{%- macro postgres__snapshot_get_time() -%}
    (now() at time zone 'UTC')
{%- endmacro -%}
