-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.orders` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'orders') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'orders') }}
    ))

)

select
    c.legacy_row_id,
    c._airbyte_generation_id                    as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
        case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."id"
        end as "id",
        case
            when btrim(c."order_number") = '' or btrim(c."order_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."order_number" like '%;%' then c."order_number"
            when c."order_number" ~ '(Ã.|Â.)' then convert_from(convert_to(c."order_number", 'LATIN1'), 'UTF8')
            when c."order_number" <> btrim(c."order_number") or c."order_number" ~ '  ' then regexp_replace(btrim(c."order_number"), '\s+', ' ', 'g')
            else c."order_number"
        end as "order_number",
        c."customer_id" as "customer_id",
        c."sales_channel_id" as "sales_channel_id",
        c."cart_id" as "cart_id",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then c."status"
            else c."status"
        end as "status",
        case
            when btrim(c."placed_at") = '' or btrim(c."placed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."placed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."placed_at" from 4 for 2)::int not between 1 and 12   or substring(c."placed_at" from 1 for 2)::int not between 1 and 31   or (substring(c."placed_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."placed_at" from 1 for 2)::int > 30)   or (substring(c."placed_at" from 4 for 2)::int = 2       and substring(c."placed_at" from 1 for 2)::int > 29)   or (substring(c."placed_at" from 4 for 2)::int = 2       and substring(c."placed_at" from 1 for 2)::int = 29       and not (substring(c."placed_at" from 7 for 4)::int % 4 = 0                and (substring(c."placed_at" from 7 for 4)::int % 100 <> 0                     or substring(c."placed_at" from 7 for 4)::int % 400 = 0)))))) then c."placed_at"
            when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."placed_at", 10)::date > date '{{ var("as_of_date") }}' then c."placed_at"
            when c."placed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."placed_at" from 4 for 2)::int between 1 and 12  and substring(c."placed_at" from 1 for 2)::int between 1 and 31) or c."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."placed_at" ~ '^[0-9]{2}/' then to_date(c."placed_at", 'DD/MM/YYYY')::text else to_date(c."placed_at", 'YYYY.MM.DD')::text end
            when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."placed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."placed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."placed_at"
        end as "placed_at",
        case
            when btrim(c."currency") = '' or btrim(c."currency") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."currency" like '%;%' then c."currency"
            when c."currency" ~ '(Ã.|Â.)' then convert_from(convert_to(c."currency", 'LATIN1'), 'UTF8')
            when c."currency" <> btrim(c."currency") or c."currency" ~ '  ' then regexp_replace(btrim(c."currency"), '\s+', ' ', 'g')
            else c."currency"
        end as "currency",
        case
            when btrim(c."subtotal_amount") = '' or btrim(c."subtotal_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."subtotal_amount", 'R$', ''), ' ', '')) ~ '^-' then c."subtotal_amount"
            when c."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."subtotal_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), ',', '') end
            else c."subtotal_amount"
        end as "subtotal_amount",
        case
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then c."discount_amount"
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '') end
            else c."discount_amount"
        end as "discount_amount",
        case
            when btrim(c."shipping_amount") = '' or btrim(c."shipping_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."shipping_amount", 'R$', ''), ' ', '')) ~ '^-' then c."shipping_amount"
            when c."shipping_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."shipping_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), ',', '') end
            else c."shipping_amount"
        end as "shipping_amount",
        case
            when btrim(c."tax_amount") = '' or btrim(c."tax_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."tax_amount", 'R$', ''), ' ', '')) ~ '^-' then c."tax_amount"
            when c."tax_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."tax_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), ',', '') end
            else c."tax_amount"
        end as "tax_amount",
        case
            when btrim(c."total_amount") = '' or btrim(c."total_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."total_amount", 'R$', ''), ' ', '')) ~ '^-' then c."total_amount"
            when c."total_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."total_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), ',', '') end
            else c."total_amount"
        end as "total_amount",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."created_at" from 4 for 2)::int not between 1 and 12   or substring(c."created_at" from 1 for 2)::int not between 1 and 31   or (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."created_at" from 1 for 2)::int > 30)   or (substring(c."created_at" from 4 for 2)::int = 2       and substring(c."created_at" from 1 for 2)::int > 29)   or (substring(c."created_at" from 4 for 2)::int = 2       and substring(c."created_at" from 1 for 2)::int = 29       and not (substring(c."created_at" from 7 for 4)::int % 4 = 0                and (substring(c."created_at" from 7 for 4)::int % 100 <> 0                     or substring(c."created_at" from 7 for 4)::int % 400 = 0)))))) then c."created_at"
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' then c."created_at"
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."created_at" from 4 for 2)::int between 1 and 12  and substring(c."created_at" from 1 for 2)::int between 1 and 31) or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."created_at"
        end as "created_at",
        case
            when btrim(c."updated_at") = '' or btrim(c."updated_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."updated_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."updated_at" from 4 for 2)::int not between 1 and 12   or substring(c."updated_at" from 1 for 2)::int not between 1 and 31   or (substring(c."updated_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."updated_at" from 1 for 2)::int > 30)   or (substring(c."updated_at" from 4 for 2)::int = 2       and substring(c."updated_at" from 1 for 2)::int > 29)   or (substring(c."updated_at" from 4 for 2)::int = 2       and substring(c."updated_at" from 1 for 2)::int = 29       and not (substring(c."updated_at" from 7 for 4)::int % 4 = 0                and (substring(c."updated_at" from 7 for 4)::int % 100 <> 0                     or substring(c."updated_at" from 7 for 4)::int % 400 = 0)))))) then c."updated_at"
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."updated_at", 10)::date > date '{{ var("as_of_date") }}' then c."updated_at"
            when c."updated_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."updated_at" from 4 for 2)::int between 1 and 12  and substring(c."updated_at" from 1 for 2)::int between 1 and 31) or c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."updated_at" ~ '^[0-9]{2}/' then to_date(c."updated_at", 'DD/MM/YYYY')::text else to_date(c."updated_at", 'YYYY.MM.DD')::text end
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."updated_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."updated_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."updated_at"
        end as "updated_at",
        case
            when btrim(c."deleted_at") = '' or btrim(c."deleted_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."deleted_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."deleted_at" from 4 for 2)::int not between 1 and 12   or substring(c."deleted_at" from 1 for 2)::int not between 1 and 31   or (substring(c."deleted_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."deleted_at" from 1 for 2)::int > 30)   or (substring(c."deleted_at" from 4 for 2)::int = 2       and substring(c."deleted_at" from 1 for 2)::int > 29)   or (substring(c."deleted_at" from 4 for 2)::int = 2       and substring(c."deleted_at" from 1 for 2)::int = 29       and not (substring(c."deleted_at" from 7 for 4)::int % 4 = 0                and (substring(c."deleted_at" from 7 for 4)::int % 100 <> 0                     or substring(c."deleted_at" from 7 for 4)::int % 400 = 0)))))) then c."deleted_at"
            when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."deleted_at", 10)::date > date '{{ var("as_of_date") }}' then c."deleted_at"
            when c."deleted_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."deleted_at" from 4 for 2)::int between 1 and 12  and substring(c."deleted_at" from 1 for 2)::int between 1 and 31) or c."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."deleted_at" ~ '^[0-9]{2}/' then to_date(c."deleted_at", 'DD/MM/YYYY')::text else to_date(c."deleted_at", 'YYYY.MM.DD')::text end
            when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."deleted_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."deleted_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."deleted_at"
        end as "deleted_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'order_number', case
            when btrim(c."order_number") = '' or btrim(c."order_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."order_number" like '%;%' then 'TEXT_DELIMITER'
            when c."order_number" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."order_number" <> btrim(c."order_number") or c."order_number" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
        end,
            'placed_at', case
            when btrim(c."placed_at") = '' or btrim(c."placed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."placed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."placed_at" from 4 for 2)::int not between 1 and 12   or substring(c."placed_at" from 1 for 2)::int not between 1 and 31   or (substring(c."placed_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."placed_at" from 1 for 2)::int > 30)   or (substring(c."placed_at" from 4 for 2)::int = 2       and substring(c."placed_at" from 1 for 2)::int > 29)   or (substring(c."placed_at" from 4 for 2)::int = 2       and substring(c."placed_at" from 1 for 2)::int = 29       and not (substring(c."placed_at" from 7 for 4)::int % 4 = 0                and (substring(c."placed_at" from 7 for 4)::int % 100 <> 0                     or substring(c."placed_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."placed_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."placed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."placed_at" from 4 for 2)::int between 1 and 12  and substring(c."placed_at" from 1 for 2)::int between 1 and 31) or c."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."placed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'currency', case
            when btrim(c."currency") = '' or btrim(c."currency") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."currency" like '%;%' then 'TEXT_DELIMITER'
            when c."currency" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."currency" <> btrim(c."currency") or c."currency" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'subtotal_amount', case
            when btrim(c."subtotal_amount") = '' or btrim(c."subtotal_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."subtotal_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'discount_amount', case
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'shipping_amount', case
            when btrim(c."shipping_amount") = '' or btrim(c."shipping_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."shipping_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."shipping_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'tax_amount', case
            when btrim(c."tax_amount") = '' or btrim(c."tax_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."tax_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."tax_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'total_amount', case
            when btrim(c."total_amount") = '' or btrim(c."total_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."total_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."total_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'created_at', case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."created_at" from 4 for 2)::int not between 1 and 12   or substring(c."created_at" from 1 for 2)::int not between 1 and 31   or (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."created_at" from 1 for 2)::int > 30)   or (substring(c."created_at" from 4 for 2)::int = 2       and substring(c."created_at" from 1 for 2)::int > 29)   or (substring(c."created_at" from 4 for 2)::int = 2       and substring(c."created_at" from 1 for 2)::int = 29       and not (substring(c."created_at" from 7 for 4)::int % 4 = 0                and (substring(c."created_at" from 7 for 4)::int % 100 <> 0                     or substring(c."created_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."created_at" from 4 for 2)::int between 1 and 12  and substring(c."created_at" from 1 for 2)::int between 1 and 31) or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'updated_at', case
            when btrim(c."updated_at") = '' or btrim(c."updated_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."updated_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."updated_at" from 4 for 2)::int not between 1 and 12   or substring(c."updated_at" from 1 for 2)::int not between 1 and 31   or (substring(c."updated_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."updated_at" from 1 for 2)::int > 30)   or (substring(c."updated_at" from 4 for 2)::int = 2       and substring(c."updated_at" from 1 for 2)::int > 29)   or (substring(c."updated_at" from 4 for 2)::int = 2       and substring(c."updated_at" from 1 for 2)::int = 29       and not (substring(c."updated_at" from 7 for 4)::int % 4 = 0                and (substring(c."updated_at" from 7 for 4)::int % 100 <> 0                     or substring(c."updated_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."updated_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."updated_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."updated_at" from 4 for 2)::int between 1 and 12  and substring(c."updated_at" from 1 for 2)::int between 1 and 31) or c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."updated_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'deleted_at', case
            when btrim(c."deleted_at") = '' or btrim(c."deleted_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."deleted_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."deleted_at" from 4 for 2)::int not between 1 and 12   or substring(c."deleted_at" from 1 for 2)::int not between 1 and 31   or (substring(c."deleted_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."deleted_at" from 1 for 2)::int > 30)   or (substring(c."deleted_at" from 4 for 2)::int = 2       and substring(c."deleted_at" from 1 for 2)::int > 29)   or (substring(c."deleted_at" from 4 for 2)::int = 2       and substring(c."deleted_at" from 1 for 2)::int = 29       and not (substring(c."deleted_at" from 7 for 4)::int % 4 = 0                and (substring(c."deleted_at" from 7 for 4)::int % 100 <> 0                     or substring(c."deleted_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."deleted_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."deleted_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."deleted_at" from 4 for 2)::int between 1 and 12  and substring(c."deleted_at" from 1 for 2)::int between 1 and 31) or c."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."deleted_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end
        )
    )                                           as achados,
    jsonb_build_object('id', c."id", 'order_number', c."order_number", 'customer_id', c."customer_id", 'sales_channel_id', c."sales_channel_id", 'cart_id', c."cart_id", 'status', c."status", 'placed_at', c."placed_at", 'currency', c."currency", 'subtotal_amount', c."subtotal_amount", 'discount_amount', c."discount_amount", 'shipping_amount', c."shipping_amount", 'tax_amount', c."tax_amount", 'total_amount', c."total_amount", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
