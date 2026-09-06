-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.purchase_orders` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'purchase_orders') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'purchase_orders') }}
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
            when btrim(c."po_number") = '' or btrim(c."po_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."po_number" like '%;%' then c."po_number"
            when c."po_number" ~ '(Ã.|Â.)' then convert_from(convert_to(c."po_number", 'LATIN1'), 'UTF8')
            when c."po_number" <> btrim(c."po_number") or c."po_number" ~ '  ' then regexp_replace(btrim(c."po_number"), '\s+', ' ', 'g')
            else c."po_number"
        end as "po_number",
        c."supplier_id" as "supplier_id",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."status") not in ('draft', 'placed', 'partially_received', 'received', 'cancelled') then c."status"
            else c."status"
        end as "status",
        case
            when btrim(c."ordered_at") = '' or btrim(c."ordered_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."ordered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."ordered_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."ordered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."ordered_at" from 4 for 2)::int not between 1 and 12   or substring(c."ordered_at" from 1 for 2)::int not between 1 and 31   or (substring(c."ordered_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."ordered_at" from 1 for 2)::int > 30)   or (substring(c."ordered_at" from 4 for 2)::int = 2       and substring(c."ordered_at" from 1 for 2)::int > 29)   or (substring(c."ordered_at" from 4 for 2)::int = 2       and substring(c."ordered_at" from 1 for 2)::int = 29       and not (substring(c."ordered_at" from 7 for 4)::int % 4 = 0                and (substring(c."ordered_at" from 7 for 4)::int % 100 <> 0                     or substring(c."ordered_at" from 7 for 4)::int % 400 = 0)))))) then c."ordered_at"
            when c."ordered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."ordered_at", 10)::date > date '{{ var("as_of_date") }}' then c."ordered_at"
            when c."ordered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."ordered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."ordered_at" from 4 for 2)::int between 1 and 12  and substring(c."ordered_at" from 1 for 2)::int between 1 and 31) or c."ordered_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."ordered_at" ~ '^[0-9]{2}/' then to_date(c."ordered_at", 'DD/MM/YYYY')::text else to_date(c."ordered_at", 'YYYY.MM.DD')::text end
            when c."ordered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."ordered_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."ordered_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."ordered_at"
        end as "ordered_at",
        case
            when btrim(c."expected_at") = '' or btrim(c."expected_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."expected_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."expected_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."expected_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."expected_at" from 4 for 2)::int not between 1 and 12   or substring(c."expected_at" from 1 for 2)::int not between 1 and 31   or (substring(c."expected_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."expected_at" from 1 for 2)::int > 30)   or (substring(c."expected_at" from 4 for 2)::int = 2       and substring(c."expected_at" from 1 for 2)::int > 29)   or (substring(c."expected_at" from 4 for 2)::int = 2       and substring(c."expected_at" from 1 for 2)::int = 29       and not (substring(c."expected_at" from 7 for 4)::int % 4 = 0                and (substring(c."expected_at" from 7 for 4)::int % 100 <> 0                     or substring(c."expected_at" from 7 for 4)::int % 400 = 0)))))) then c."expected_at"
            when c."expected_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."expected_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."expected_at" from 4 for 2)::int between 1 and 12  and substring(c."expected_at" from 1 for 2)::int between 1 and 31) or c."expected_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."expected_at" ~ '^[0-9]{2}/' then to_date(c."expected_at", 'DD/MM/YYYY')::text else to_date(c."expected_at", 'YYYY.MM.DD')::text end
            when c."expected_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."expected_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."expected_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."expected_at"
        end as "expected_at",
        case
            when btrim(c."currency") = '' or btrim(c."currency") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."currency" like '%;%' then c."currency"
            when c."currency" ~ '(Ã.|Â.)' then convert_from(convert_to(c."currency", 'LATIN1'), 'UTF8')
            when c."currency" <> btrim(c."currency") or c."currency" ~ '  ' then regexp_replace(btrim(c."currency"), '\s+', ' ', 'g')
            else c."currency"
        end as "currency",
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
            'po_number', case
            when btrim(c."po_number") = '' or btrim(c."po_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."po_number" like '%;%' then 'TEXT_DELIMITER'
            when c."po_number" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."po_number" <> btrim(c."po_number") or c."po_number" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('draft', 'placed', 'partially_received', 'received', 'cancelled') then 'ENUM_UNKNOWN'
        end,
            'ordered_at', case
            when btrim(c."ordered_at") = '' or btrim(c."ordered_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."ordered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."ordered_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."ordered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."ordered_at" from 4 for 2)::int not between 1 and 12   or substring(c."ordered_at" from 1 for 2)::int not between 1 and 31   or (substring(c."ordered_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."ordered_at" from 1 for 2)::int > 30)   or (substring(c."ordered_at" from 4 for 2)::int = 2       and substring(c."ordered_at" from 1 for 2)::int > 29)   or (substring(c."ordered_at" from 4 for 2)::int = 2       and substring(c."ordered_at" from 1 for 2)::int = 29       and not (substring(c."ordered_at" from 7 for 4)::int % 4 = 0                and (substring(c."ordered_at" from 7 for 4)::int % 100 <> 0                     or substring(c."ordered_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."ordered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."ordered_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."ordered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."ordered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."ordered_at" from 4 for 2)::int between 1 and 12  and substring(c."ordered_at" from 1 for 2)::int between 1 and 31) or c."ordered_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."ordered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."ordered_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'expected_at', case
            when btrim(c."expected_at") = '' or btrim(c."expected_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."expected_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."expected_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."expected_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."expected_at" from 4 for 2)::int not between 1 and 12   or substring(c."expected_at" from 1 for 2)::int not between 1 and 31   or (substring(c."expected_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."expected_at" from 1 for 2)::int > 30)   or (substring(c."expected_at" from 4 for 2)::int = 2       and substring(c."expected_at" from 1 for 2)::int > 29)   or (substring(c."expected_at" from 4 for 2)::int = 2       and substring(c."expected_at" from 1 for 2)::int = 29       and not (substring(c."expected_at" from 7 for 4)::int % 4 = 0                and (substring(c."expected_at" from 7 for 4)::int % 100 <> 0                     or substring(c."expected_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."expected_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."expected_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."expected_at" from 4 for 2)::int between 1 and 12  and substring(c."expected_at" from 1 for 2)::int between 1 and 31) or c."expected_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."expected_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."expected_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'currency', case
            when btrim(c."currency") = '' or btrim(c."currency") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."currency" like '%;%' then 'TEXT_DELIMITER'
            when c."currency" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."currency" <> btrim(c."currency") or c."currency" ~ '  ' then 'TEXT_WHITESPACE_CASE'
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
    jsonb_build_object('id', c."id", 'po_number', c."po_number", 'supplier_id', c."supplier_id", 'status', c."status", 'ordered_at', c."ordered_at", 'expected_at', c."expected_at", 'currency', c."currency", 'total_amount', c."total_amount", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
