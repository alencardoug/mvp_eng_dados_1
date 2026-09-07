-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.coupon_redemptions` — camada `staging` (ADR-0016).
--
-- Uma linha por ocorrência física da **captura mais recente**. Reter capturas
-- antigas (ADR-0037) não significa somá-las: o tratamento olha a última, e as
-- anteriores existem para comparação e reprocessamento.
--
-- Duas saídas por coluna: o valor tratado e o **achado**, que é o código da
-- primeira falha que casa. O valor original permanece acessível em
-- `raw_legacy`, que é imutável.

with captura as (

    select *
    from {{ source('legacy', 'coupon_redemptions') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'coupon_redemptions') }}
    ))

),

-- A limpeza vem **antes** dos achados, e não junto: o achado de rejeição
-- precisa ser conferido contra o valor já convertido, senão uma conversão
-- bem-sucedida esconde a invalidade do resultado dela.
limpo as (

    select
        c.legacy_row_id,
        case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."id"
        end as "id",
        c."coupon_id" as "coupon_id",
        c."customer_id" as "customer_id",
        c."order_id" as "order_id",
        case
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then c."discount_amount"
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (   c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$'   or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$'   or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$'   or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') then case when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,4}$' then replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."discount_amount"
            else c."discount_amount"
        end as "discount_amount",
        case
            when btrim(c."redeemed_at") = '' or btrim(c."redeemed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."redeemed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."redeemed_at"
            when case when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) then left(c."redeemed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."redeemed_at"
            when case when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."redeemed_at" ~ '^[0-9]{2}/' then to_date(c."redeemed_at", 'DD/MM/YYYY')::text else to_date(c."redeemed_at", 'YYYY.MM.DD')::text end
            when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."redeemed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."redeemed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when c."redeemed_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."redeemed_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."redeemed_at" !~ '^[0-9]{2}/[0-9]{4}$' then c."redeemed_at"
            else c."redeemed_at"
        end as "redeemed_at",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when c."created_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."created_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."created_at" !~ '^[0-9]{2}/[0-9]{4}$' then c."created_at"
            else c."created_at"
        end as "created_at"
    from captura c

)

select
    c.legacy_row_id,
    c._airbyte_generation_id                    as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
    l."id",
    l."coupon_id",
    l."customer_id",
    l."order_id",
    l."discount_amount",
    l."redeemed_at",
    l."created_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'discount_amount', case
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (   c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$'   or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$'   or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$'   or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') then 'MONEY_LOCALE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'redeemed_at', case
            when btrim(c."redeemed_at") = '' or btrim(c."redeemed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."redeemed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) then left(c."redeemed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."redeemed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
            when c."redeemed_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."redeemed_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."redeemed_at" !~ '^[0-9]{2}/[0-9]{4}$' then 'DATE_UNPARSEABLE'
        end,
            'created_at', case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
            when c."created_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."created_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."created_at" !~ '^[0-9]{2}/[0-9]{4}$' then 'DATE_UNPARSEABLE'
        end
        )
    )                                           as achados,
    jsonb_build_object('id', c."id", 'coupon_id', c."coupon_id", 'customer_id', c."customer_id", 'order_id', c."order_id", 'discount_amount', c."discount_amount", 'redeemed_at', c."redeemed_at", 'created_at', c."created_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id
