-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.stock_reservations` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'stock_reservations') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'stock_reservations') }}
    )

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
            when btrim(c."reservation_code") = '' or btrim(c."reservation_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."reservation_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."reservation_code", 'LATIN1'), 'UTF8')
            when c."reservation_code" <> btrim(c."reservation_code") or c."reservation_code" ~ '  ' then regexp_replace(btrim(c."reservation_code"), '\s+', ' ', 'g')
            else c."reservation_code"
        end as "reservation_code",
        c."warehouse_id" as "warehouse_id",
        c."product_variant_id" as "product_variant_id",
        c."cart_id" as "cart_id",
        c."order_id" as "order_id",
        case
            when btrim(c."quantity") = '' or btrim(c."quantity") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."quantity" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity"), ',', '.') ~ '^-?[0-9]+\.0+$') then case lower(btrim(c."quantity")) when 'um' then '1' when 'dois' then '2' when 'três' then '3' when 'tres' then '3' when 'quatro' then '4' when 'cinco' then '5' when 'seis' then '6' when 'sete' then '7' when 'oito' then '8' when 'nove' then '9' when 'dez' then '10' else split_part(replace(btrim(c."quantity"), ',', '.'), '.', 1) end
            else c."quantity"
        end as "quantity",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."status"
        end as "status",
        case
            when btrim(c."expires_at") = '' or btrim(c."expires_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."expires_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."expires_at" from 4 for 2)::int between 1 and 12  and substring(c."expires_at" from 1 for 2)::int between 1 and 31) or c."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."expires_at" ~ '^[0-9]{2}/' then to_date(c."expires_at", 'DD/MM/YYYY')::text else to_date(c."expires_at", 'YYYY.MM.DD')::text end
            when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."expires_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."expires_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."expires_at"
        end as "expires_at",
        case
            when btrim(c."released_at") = '' or btrim(c."released_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."released_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."released_at" from 4 for 2)::int between 1 and 12  and substring(c."released_at" from 1 for 2)::int between 1 and 31) or c."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."released_at" ~ '^[0-9]{2}/' then to_date(c."released_at", 'DD/MM/YYYY')::text else to_date(c."released_at", 'YYYY.MM.DD')::text end
            when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."released_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."released_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."released_at"
        end as "released_at",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."created_at" from 4 for 2)::int between 1 and 12  and substring(c."created_at" from 1 for 2)::int between 1 and 31) or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."created_at"
        end as "created_at",
        case
            when btrim(c."updated_at") = '' or btrim(c."updated_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."updated_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."updated_at" from 4 for 2)::int between 1 and 12  and substring(c."updated_at" from 1 for 2)::int between 1 and 31) or c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."updated_at" ~ '^[0-9]{2}/' then to_date(c."updated_at", 'DD/MM/YYYY')::text else to_date(c."updated_at", 'YYYY.MM.DD')::text end
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."updated_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."updated_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."updated_at"
        end as "updated_at",
        case
            when btrim(c."deleted_at") = '' or btrim(c."deleted_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
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
            'reservation_code', case
            when btrim(c."reservation_code") = '' or btrim(c."reservation_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."reservation_code" like '%;%' then 'TEXT_DELIMITER'
            when c."reservation_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."reservation_code" <> btrim(c."reservation_code") or c."reservation_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'quantity', case
            when btrim(c."quantity") = '' or btrim(c."quantity") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."quantity" ~ '^-?[0-9]+$' and (c."quantity"::numeric < 0 or c."quantity"::numeric > 1000000) then 'NUM_OUT_OF_RANGE'
            when c."quantity" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity"), ',', '.') ~ '^-?[0-9]+\.0+$') then 'NUM_TEXT_EQUIV'
            when c."quantity" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('active', 'released', 'expired', 'consumed') then 'ENUM_UNKNOWN'
        end,
            'expires_at', case
            when btrim(c."expires_at") = '' or btrim(c."expires_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."expires_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."expires_at" from 4 for 2)::int not between 1 and 12   or substring(c."expires_at" from 1 for 2)::int not between 1 and 31   or (substring(c."expires_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."expires_at" from 1 for 2)::int > 30)   or (substring(c."expires_at" from 4 for 2)::int = 2       and substring(c."expires_at" from 1 for 2)::int > 29)   or (substring(c."expires_at" from 4 for 2)::int = 2       and substring(c."expires_at" from 1 for 2)::int = 29       and not (substring(c."expires_at" from 7 for 4)::int % 4 = 0                and (substring(c."expires_at" from 7 for 4)::int % 100 <> 0                     or substring(c."expires_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."expires_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."expires_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."expires_at" from 4 for 2)::int between 1 and 12  and substring(c."expires_at" from 1 for 2)::int between 1 and 31) or c."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."expires_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'released_at', case
            when btrim(c."released_at") = '' or btrim(c."released_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."released_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."released_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."released_at" from 4 for 2)::int not between 1 and 12   or substring(c."released_at" from 1 for 2)::int not between 1 and 31   or (substring(c."released_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."released_at" from 1 for 2)::int > 30)   or (substring(c."released_at" from 4 for 2)::int = 2       and substring(c."released_at" from 1 for 2)::int > 29)   or (substring(c."released_at" from 4 for 2)::int = 2       and substring(c."released_at" from 1 for 2)::int = 29       and not (substring(c."released_at" from 7 for 4)::int % 4 = 0                and (substring(c."released_at" from 7 for 4)::int % 100 <> 0                     or substring(c."released_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."released_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."released_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."released_at" from 4 for 2)::int between 1 and 12  and substring(c."released_at" from 1 for 2)::int between 1 and 31) or c."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."released_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
    )                                           as achados
from captura c
