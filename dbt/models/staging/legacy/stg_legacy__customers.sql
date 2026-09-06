-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.customers` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'customers') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'customers') }}
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
            when btrim(c."customer_code") = '' or btrim(c."customer_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."customer_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."customer_code", 'LATIN1'), 'UTF8')
            when c."customer_code" <> btrim(c."customer_code") or c."customer_code" ~ '  ' then regexp_replace(btrim(c."customer_code"), '\s+', ' ', 'g')
            else c."customer_code"
        end as "customer_code",
        c."segment_id" as "segment_id",
        case
            when btrim(c."first_name") = '' or btrim(c."first_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."first_name" ~ '(Ã.|Â.)' then convert_from(convert_to(c."first_name", 'LATIN1'), 'UTF8')
            when c."first_name" <> btrim(c."first_name") or c."first_name" ~ '  ' then regexp_replace(btrim(c."first_name"), '\s+', ' ', 'g')
            else c."first_name"
        end as "first_name",
        case
            when btrim(c."last_name") = '' or btrim(c."last_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."last_name" ~ '(Ã.|Â.)' then convert_from(convert_to(c."last_name", 'LATIN1'), 'UTF8')
            when c."last_name" <> btrim(c."last_name") or c."last_name" ~ '  ' then regexp_replace(btrim(c."last_name"), '\s+', ' ', 'g')
            else c."last_name"
        end as "last_name",
        case
            when btrim(c."document") = '' or btrim(c."document") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."document" ~ '(Ã.|Â.)' then convert_from(convert_to(c."document", 'LATIN1'), 'UTF8')
            when c."document" <> btrim(c."document") or c."document" ~ '  ' then regexp_replace(btrim(c."document"), '\s+', ' ', 'g')
            else c."document"
        end as "document",
        case
            when btrim(c."birth_date") = '' or btrim(c."birth_date") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."birth_date" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."birth_date" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."birth_date" from 4 for 2)::int between 1 and 12  and substring(c."birth_date" from 1 for 2)::int between 1 and 31) or c."birth_date" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."birth_date" ~ '^[0-9]{2}/' then to_date(c."birth_date", 'DD/MM/YYYY')::text else to_date(c."birth_date", 'YYYY.MM.DD')::text end
            when c."birth_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."birth_date" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."birth_date"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."birth_date"
        end as "birth_date",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."status"
        end as "status",
        case
            when btrim(c."registered_at") = '' or btrim(c."registered_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."registered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."registered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."registered_at" from 4 for 2)::int between 1 and 12  and substring(c."registered_at" from 1 for 2)::int between 1 and 31) or c."registered_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."registered_at" ~ '^[0-9]{2}/' then to_date(c."registered_at", 'DD/MM/YYYY')::text else to_date(c."registered_at", 'YYYY.MM.DD')::text end
            when c."registered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."registered_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."registered_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."registered_at"
        end as "registered_at",
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
            'customer_code', case
            when btrim(c."customer_code") = '' or btrim(c."customer_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."customer_code" like '%;%' then 'TEXT_DELIMITER'
            when c."customer_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."customer_code" <> btrim(c."customer_code") or c."customer_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'first_name', case
            when btrim(c."first_name") = '' or btrim(c."first_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."first_name" like '%;%' then 'TEXT_DELIMITER'
            when c."first_name" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."first_name" <> btrim(c."first_name") or c."first_name" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'last_name', case
            when btrim(c."last_name") = '' or btrim(c."last_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."last_name" like '%;%' then 'TEXT_DELIMITER'
            when c."last_name" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."last_name" <> btrim(c."last_name") or c."last_name" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'document', case
            when btrim(c."document") = '' or btrim(c."document") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."document" like '%;%' then 'TEXT_DELIMITER'
            when c."document" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."document" <> btrim(c."document") or c."document" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'birth_date', case
            when btrim(c."birth_date") = '' or btrim(c."birth_date") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."birth_date" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."birth_date" ~ '^[0-9]{2}/[0-9]{4}$' or (c."birth_date" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."birth_date" from 4 for 2)::int not between 1 and 12   or substring(c."birth_date" from 1 for 2)::int not between 1 and 31   or (substring(c."birth_date" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."birth_date" from 1 for 2)::int > 30)   or (substring(c."birth_date" from 4 for 2)::int = 2       and substring(c."birth_date" from 1 for 2)::int > 29)   or (substring(c."birth_date" from 4 for 2)::int = 2       and substring(c."birth_date" from 1 for 2)::int = 29       and not (substring(c."birth_date" from 7 for 4)::int % 4 = 0                and (substring(c."birth_date" from 7 for 4)::int % 100 <> 0                     or substring(c."birth_date" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."birth_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."birth_date", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."birth_date" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."birth_date" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."birth_date" from 4 for 2)::int between 1 and 12  and substring(c."birth_date" from 1 for 2)::int between 1 and 31) or c."birth_date" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."birth_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."birth_date" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('active', 'inactive', 'blocked', 'pending') then 'ENUM_UNKNOWN'
        end,
            'registered_at', case
            when btrim(c."registered_at") = '' or btrim(c."registered_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."registered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."registered_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."registered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."registered_at" from 4 for 2)::int not between 1 and 12   or substring(c."registered_at" from 1 for 2)::int not between 1 and 31   or (substring(c."registered_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."registered_at" from 1 for 2)::int > 30)   or (substring(c."registered_at" from 4 for 2)::int = 2       and substring(c."registered_at" from 1 for 2)::int > 29)   or (substring(c."registered_at" from 4 for 2)::int = 2       and substring(c."registered_at" from 1 for 2)::int = 29       and not (substring(c."registered_at" from 7 for 4)::int % 4 = 0                and (substring(c."registered_at" from 7 for 4)::int % 100 <> 0                     or substring(c."registered_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."registered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."registered_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."registered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."registered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."registered_at" from 4 for 2)::int between 1 and 12  and substring(c."registered_at" from 1 for 2)::int between 1 and 31) or c."registered_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."registered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."registered_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
