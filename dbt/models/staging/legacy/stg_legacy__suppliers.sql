-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.suppliers` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'suppliers') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'suppliers') }}
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
            when btrim(c."supplier_code") = '' or btrim(c."supplier_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."supplier_code" like '%;%' then c."supplier_code"
            when c."supplier_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."supplier_code", 'LATIN1'), 'UTF8')
            when c."supplier_code" <> btrim(c."supplier_code") or c."supplier_code" ~ '  ' then regexp_replace(btrim(c."supplier_code"), '\s+', ' ', 'g')
            else c."supplier_code"
        end as "supplier_code",
        case
            when btrim(c."legal_name") = '' or btrim(c."legal_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when length(c."legal_name") = 24 then c."legal_name"
            when c."legal_name" like '%;%' then c."legal_name"
            when c."legal_name" ~ '(Ã.|Â.)' then convert_from(convert_to(c."legal_name", 'LATIN1'), 'UTF8')
            when c."legal_name" <> btrim(c."legal_name") or c."legal_name" ~ '  ' then regexp_replace(btrim(c."legal_name"), '\s+', ' ', 'g')
            else c."legal_name"
        end as "legal_name",
        case
            when btrim(c."trade_name") = '' or btrim(c."trade_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when length(c."trade_name") = 24 then c."trade_name"
            when c."trade_name" like '%;%' then c."trade_name"
            when c."trade_name" ~ '(Ã.|Â.)' then convert_from(convert_to(c."trade_name", 'LATIN1'), 'UTF8')
            when c."trade_name" <> btrim(c."trade_name") or c."trade_name" ~ '  ' then regexp_replace(btrim(c."trade_name"), '\s+', ' ', 'g')
            else c."trade_name"
        end as "trade_name",
        case
            when btrim(c."document") = '' or btrim(c."document") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."document" like '%;%' then c."document"
            when c."document" ~ '(Ã.|Â.)' then convert_from(convert_to(c."document", 'LATIN1'), 'UTF8')
            when c."document" <> btrim(c."document") or c."document" ~ '  ' then regexp_replace(btrim(c."document"), '\s+', ' ', 'g')
            else c."document"
        end as "document",
        case
            when btrim(c."contact_email") = '' or btrim(c."contact_email") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."contact_email" !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then c."contact_email"
            when c."contact_email" like '%;%' then c."contact_email"
            when c."contact_email" ~ '(Ã.|Â.)' then convert_from(convert_to(c."contact_email", 'LATIN1'), 'UTF8')
            when c."contact_email" <> btrim(c."contact_email") or c."contact_email" ~ '  ' then regexp_replace(btrim(c."contact_email"), '\s+', ' ', 'g')
            else c."contact_email"
        end as "contact_email",
        case
            when btrim(c."country") = '' or btrim(c."country") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."country" like '%;%' then c."country"
            when c."country" ~ '(Ã.|Â.)' then convert_from(convert_to(c."country", 'LATIN1'), 'UTF8')
            when c."country" <> btrim(c."country") or c."country" ~ '  ' then regexp_replace(btrim(c."country"), '\s+', ' ', 'g')
            else c."country"
        end as "country",
        case
            when btrim(c."payment_terms_days") = '' or btrim(c."payment_terms_days") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."payment_terms_days"
        end as "payment_terms_days",
        case
            when btrim(c."is_active") = '' or btrim(c."is_active") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when lower(btrim(c."is_active")) not in ('true', 'false') then case when lower(btrim(c."is_active")) in ('sim', 's', '1', 'y', 'yes') then 'true' else 'false' end
            else c."is_active"
        end as "is_active",
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
            'supplier_code', case
            when btrim(c."supplier_code") = '' or btrim(c."supplier_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."supplier_code" like '%;%' then 'TEXT_DELIMITER'
            when c."supplier_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."supplier_code" <> btrim(c."supplier_code") or c."supplier_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'legal_name', case
            when btrim(c."legal_name") = '' or btrim(c."legal_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."legal_name") = 24 then 'TEXT_TRUNCATED'
            when c."legal_name" like '%;%' then 'TEXT_DELIMITER'
            when c."legal_name" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."legal_name" <> btrim(c."legal_name") or c."legal_name" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'trade_name', case
            when btrim(c."trade_name") = '' or btrim(c."trade_name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."trade_name") = 24 then 'TEXT_TRUNCATED'
            when c."trade_name" like '%;%' then 'TEXT_DELIMITER'
            when c."trade_name" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."trade_name" <> btrim(c."trade_name") or c."trade_name" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'document', case
            when btrim(c."document") = '' or btrim(c."document") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."document" like '%;%' then 'TEXT_DELIMITER'
            when c."document" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."document" <> btrim(c."document") or c."document" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'contact_email', case
            when btrim(c."contact_email") = '' or btrim(c."contact_email") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."contact_email" !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then 'EMAIL_MALFORMED'
            when c."contact_email" like '%;%' then 'TEXT_DELIMITER'
            when c."contact_email" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."contact_email" <> btrim(c."contact_email") or c."contact_email" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'country', case
            when btrim(c."country") = '' or btrim(c."country") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."country" like '%;%' then 'TEXT_DELIMITER'
            when c."country" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."country" <> btrim(c."country") or c."country" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'payment_terms_days', case
            when btrim(c."payment_terms_days") = '' or btrim(c."payment_terms_days") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'is_active', case
            when btrim(c."is_active") = '' or btrim(c."is_active") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when lower(btrim(c."is_active")) not in ('true', 'false') then 'BOOL_VARIANT'
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
    jsonb_build_object('id', c."id", 'supplier_code', c."supplier_code", 'legal_name', c."legal_name", 'trade_name', c."trade_name", 'document', c."document", 'contact_email', c."contact_email", 'country', c."country", 'payment_terms_days', c."payment_terms_days", 'is_active', c."is_active", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
