-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.products` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'products') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'products') }}
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
            when btrim(c."product_code") = '' or btrim(c."product_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."product_code" like '%;%' then c."product_code"
            when c."product_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."product_code", 'LATIN1'), 'UTF8')
            when c."product_code" <> btrim(c."product_code") or c."product_code" ~ '  ' then regexp_replace(btrim(c."product_code"), '\s+', ' ', 'g')
            else c."product_code"
        end as "product_code",
        c."category_id" as "category_id",
        c."brand_id" as "brand_id",
        case
            when btrim(c."name") = '' or btrim(c."name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when length(c."name") = 24 then c."name"
            when c."name" like '%;%' then c."name"
            when c."name" ~ '(Ã.|Â.)' then convert_from(convert_to(c."name", 'LATIN1'), 'UTF8')
            when c."name" <> btrim(c."name") or c."name" ~ '  ' then regexp_replace(btrim(c."name"), '\s+', ' ', 'g')
            else c."name"
        end as "name",
        case
            when btrim(c."description") = '' or btrim(c."description") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."description" like '%;%' then c."description"
            when c."description" ~ '(Ã.|Â.)' then convert_from(convert_to(c."description", 'LATIN1'), 'UTF8')
            when c."description" <> btrim(c."description") or c."description" ~ '  ' then regexp_replace(btrim(c."description"), '\s+', ' ', 'g')
            else c."description"
        end as "description",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."status") not in ('draft', 'active', 'discontinued') then c."status"
            else c."status"
        end as "status",
        case
            when btrim(c."launched_at") = '' or btrim(c."launched_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."launched_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."launched_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."launched_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."launched_at" from 4 for 2)::int not between 1 and 12   or substring(c."launched_at" from 1 for 2)::int not between 1 and 31   or (substring(c."launched_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."launched_at" from 1 for 2)::int > 30)   or (substring(c."launched_at" from 4 for 2)::int = 2       and substring(c."launched_at" from 1 for 2)::int > 29)   or (substring(c."launched_at" from 4 for 2)::int = 2       and substring(c."launched_at" from 1 for 2)::int = 29       and not (substring(c."launched_at" from 7 for 4)::int % 4 = 0                and (substring(c."launched_at" from 7 for 4)::int % 100 <> 0                     or substring(c."launched_at" from 7 for 4)::int % 400 = 0)))))) then c."launched_at"
            when c."launched_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."launched_at", 10)::date > date '{{ var("as_of_date") }}' then c."launched_at"
            when c."launched_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."launched_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."launched_at" from 4 for 2)::int between 1 and 12  and substring(c."launched_at" from 1 for 2)::int between 1 and 31) or c."launched_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."launched_at" ~ '^[0-9]{2}/' then to_date(c."launched_at", 'DD/MM/YYYY')::text else to_date(c."launched_at", 'YYYY.MM.DD')::text end
            when c."launched_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."launched_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."launched_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."launched_at"
        end as "launched_at",
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
            'product_code', case
            when btrim(c."product_code") = '' or btrim(c."product_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."product_code" like '%;%' then 'TEXT_DELIMITER'
            when c."product_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."product_code" <> btrim(c."product_code") or c."product_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'name', case
            when btrim(c."name") = '' or btrim(c."name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."name") = 24 then 'TEXT_TRUNCATED'
            when c."name" like '%;%' then 'TEXT_DELIMITER'
            when c."name" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."name" <> btrim(c."name") or c."name" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'description', case
            when btrim(c."description") = '' or btrim(c."description") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."description" like '%;%' then 'TEXT_DELIMITER'
            when c."description" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."description" <> btrim(c."description") or c."description" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('draft', 'active', 'discontinued') then 'ENUM_UNKNOWN'
        end,
            'launched_at', case
            when btrim(c."launched_at") = '' or btrim(c."launched_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."launched_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."launched_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."launched_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."launched_at" from 4 for 2)::int not between 1 and 12   or substring(c."launched_at" from 1 for 2)::int not between 1 and 31   or (substring(c."launched_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."launched_at" from 1 for 2)::int > 30)   or (substring(c."launched_at" from 4 for 2)::int = 2       and substring(c."launched_at" from 1 for 2)::int > 29)   or (substring(c."launched_at" from 4 for 2)::int = 2       and substring(c."launched_at" from 1 for 2)::int = 29       and not (substring(c."launched_at" from 7 for 4)::int % 4 = 0                and (substring(c."launched_at" from 7 for 4)::int % 100 <> 0                     or substring(c."launched_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."launched_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."launched_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."launched_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."launched_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."launched_at" from 4 for 2)::int between 1 and 12  and substring(c."launched_at" from 1 for 2)::int between 1 and 31) or c."launched_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."launched_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."launched_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
    jsonb_build_object('id', c."id", 'product_code', c."product_code", 'category_id', c."category_id", 'brand_id', c."brand_id", 'name', c."name", 'description', c."description", 'status', c."status", 'launched_at', c."launched_at", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
