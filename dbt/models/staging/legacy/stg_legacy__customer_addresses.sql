-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.customer_addresses` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'customer_addresses') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'customer_addresses') }}
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
        c."customer_id" as "customer_id",
        case
            when btrim(c."address_type") = '' or btrim(c."address_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."address_type"
        end as "address_type",
        case
            when btrim(c."street") = '' or btrim(c."street") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."street" ~ '(Ã.|Â.)' then convert_from(convert_to(c."street", 'LATIN1'), 'UTF8')
            when c."street" <> btrim(c."street") or c."street" ~ '  ' then regexp_replace(btrim(c."street"), '\s+', ' ', 'g')
            else c."street"
        end as "street",
        case
            when btrim(c."number") = '' or btrim(c."number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."number" ~ '(Ã.|Â.)' then convert_from(convert_to(c."number", 'LATIN1'), 'UTF8')
            when c."number" <> btrim(c."number") or c."number" ~ '  ' then regexp_replace(btrim(c."number"), '\s+', ' ', 'g')
            else c."number"
        end as "number",
        case
            when btrim(c."complement") = '' or btrim(c."complement") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."complement" ~ '(Ã.|Â.)' then convert_from(convert_to(c."complement", 'LATIN1'), 'UTF8')
            when c."complement" <> btrim(c."complement") or c."complement" ~ '  ' then regexp_replace(btrim(c."complement"), '\s+', ' ', 'g')
            else c."complement"
        end as "complement",
        case
            when btrim(c."district") = '' or btrim(c."district") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."district" ~ '(Ã.|Â.)' then convert_from(convert_to(c."district", 'LATIN1'), 'UTF8')
            when c."district" <> btrim(c."district") or c."district" ~ '  ' then regexp_replace(btrim(c."district"), '\s+', ' ', 'g')
            else c."district"
        end as "district",
        case
            when btrim(c."city") = '' or btrim(c."city") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."city" ~ '(Ã.|Â.)' then convert_from(convert_to(c."city", 'LATIN1'), 'UTF8')
            when c."city" <> btrim(c."city") or c."city" ~ '  ' then regexp_replace(btrim(c."city"), '\s+', ' ', 'g')
            else c."city"
        end as "city",
        case
            when btrim(c."state") = '' or btrim(c."state") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."state" ~ '(Ã.|Â.)' then convert_from(convert_to(c."state", 'LATIN1'), 'UTF8')
            when c."state" <> btrim(c."state") or c."state" ~ '  ' then regexp_replace(btrim(c."state"), '\s+', ' ', 'g')
            else c."state"
        end as "state",
        case
            when btrim(c."postal_code") = '' or btrim(c."postal_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."postal_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."postal_code", 'LATIN1'), 'UTF8')
            when c."postal_code" <> btrim(c."postal_code") or c."postal_code" ~ '  ' then regexp_replace(btrim(c."postal_code"), '\s+', ' ', 'g')
            else c."postal_code"
        end as "postal_code",
        case
            when btrim(c."country") = '' or btrim(c."country") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."country" ~ '(Ã.|Â.)' then convert_from(convert_to(c."country", 'LATIN1'), 'UTF8')
            when c."country" <> btrim(c."country") or c."country" ~ '  ' then regexp_replace(btrim(c."country"), '\s+', ' ', 'g')
            else c."country"
        end as "country",
        case
            when btrim(c."is_primary") = '' or btrim(c."is_primary") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when lower(btrim(c."is_primary")) not in ('true', 'false') then case when lower(btrim(c."is_primary")) in ('sim', 's', '1', 'y', 'yes') then 'true' else 'false' end
            else c."is_primary"
        end as "is_primary",
        case
            when btrim(c."valid_from") = '' or btrim(c."valid_from") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."valid_from" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."valid_from" from 4 for 2)::int between 1 and 12  and substring(c."valid_from" from 1 for 2)::int between 1 and 31) or c."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."valid_from" ~ '^[0-9]{2}/' then to_date(c."valid_from", 'DD/MM/YYYY')::text else to_date(c."valid_from", 'YYYY.MM.DD')::text end
            when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."valid_from" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."valid_from"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."valid_from"
        end as "valid_from",
        case
            when btrim(c."valid_to") = '' or btrim(c."valid_to") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."valid_to" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."valid_to" from 4 for 2)::int between 1 and 12  and substring(c."valid_to" from 1 for 2)::int between 1 and 31) or c."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."valid_to" ~ '^[0-9]{2}/' then to_date(c."valid_to", 'DD/MM/YYYY')::text else to_date(c."valid_to", 'YYYY.MM.DD')::text end
            when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."valid_to" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."valid_to"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."valid_to"
        end as "valid_to",
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
            'address_type', case
            when btrim(c."address_type") = '' or btrim(c."address_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."address_type") not in ('billing', 'shipping') then 'ENUM_UNKNOWN'
        end,
            'street', case
            when btrim(c."street") = '' or btrim(c."street") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."street") = 24 then 'TEXT_TRUNCATED'
            when c."street" like '%;%' then 'TEXT_DELIMITER'
            when c."street" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."street" <> btrim(c."street") or c."street" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'number', case
            when btrim(c."number") = '' or btrim(c."number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."number" like '%;%' then 'TEXT_DELIMITER'
            when c."number" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."number" <> btrim(c."number") or c."number" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'complement', case
            when btrim(c."complement") = '' or btrim(c."complement") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."complement" like '%;%' then 'TEXT_DELIMITER'
            when c."complement" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."complement" <> btrim(c."complement") or c."complement" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'district', case
            when btrim(c."district") = '' or btrim(c."district") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."district") = 24 then 'TEXT_TRUNCATED'
            when c."district" like '%;%' then 'TEXT_DELIMITER'
            when c."district" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."district" <> btrim(c."district") or c."district" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'city', case
            when btrim(c."city") = '' or btrim(c."city") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."city" like '%;%' then 'TEXT_DELIMITER'
            when c."city" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."city" <> btrim(c."city") or c."city" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'state', case
            when btrim(c."state") = '' or btrim(c."state") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."state" like '%;%' then 'TEXT_DELIMITER'
            when c."state" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."state" <> btrim(c."state") or c."state" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'postal_code', case
            when btrim(c."postal_code") = '' or btrim(c."postal_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."postal_code" like '%;%' then 'TEXT_DELIMITER'
            when c."postal_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."postal_code" <> btrim(c."postal_code") or c."postal_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'country', case
            when btrim(c."country") = '' or btrim(c."country") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."country" like '%;%' then 'TEXT_DELIMITER'
            when c."country" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."country" <> btrim(c."country") or c."country" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'is_primary', case
            when btrim(c."is_primary") = '' or btrim(c."is_primary") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when lower(btrim(c."is_primary")) not in ('true', 'false') then 'BOOL_VARIANT'
        end,
            'valid_from', case
            when btrim(c."valid_from") = '' or btrim(c."valid_from") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."valid_from" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' or (c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."valid_from" from 4 for 2)::int not between 1 and 12   or substring(c."valid_from" from 1 for 2)::int not between 1 and 31   or (substring(c."valid_from" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."valid_from" from 1 for 2)::int > 30)   or (substring(c."valid_from" from 4 for 2)::int = 2       and substring(c."valid_from" from 1 for 2)::int > 29)   or (substring(c."valid_from" from 4 for 2)::int = 2       and substring(c."valid_from" from 1 for 2)::int = 29       and not (substring(c."valid_from" from 7 for 4)::int % 4 = 0                and (substring(c."valid_from" from 7 for 4)::int % 100 <> 0                     or substring(c."valid_from" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."valid_from", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."valid_from" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."valid_from" from 4 for 2)::int between 1 and 12  and substring(c."valid_from" from 1 for 2)::int between 1 and 31) or c."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."valid_from" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'valid_to', case
            when btrim(c."valid_to") = '' or btrim(c."valid_to") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."valid_to" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' or (c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."valid_to" from 4 for 2)::int not between 1 and 12   or substring(c."valid_to" from 1 for 2)::int not between 1 and 31   or (substring(c."valid_to" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."valid_to" from 1 for 2)::int > 30)   or (substring(c."valid_to" from 4 for 2)::int = 2       and substring(c."valid_to" from 1 for 2)::int > 29)   or (substring(c."valid_to" from 4 for 2)::int = 2       and substring(c."valid_to" from 1 for 2)::int = 29       and not (substring(c."valid_to" from 7 for 4)::int % 4 = 0                and (substring(c."valid_to" from 7 for 4)::int % 100 <> 0                     or substring(c."valid_to" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."valid_to", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."valid_to" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."valid_to" from 4 for 2)::int between 1 and 12  and substring(c."valid_to" from 1 for 2)::int between 1 and 31) or c."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."valid_to" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
