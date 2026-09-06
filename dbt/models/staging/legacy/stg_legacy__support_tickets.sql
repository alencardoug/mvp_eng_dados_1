-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.support_tickets` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'support_tickets') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'support_tickets') }}
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
            when btrim(c."ticket_number") = '' or btrim(c."ticket_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."ticket_number" ~ '(Ã.|Â.)' then convert_from(convert_to(c."ticket_number", 'LATIN1'), 'UTF8')
            when c."ticket_number" <> btrim(c."ticket_number") or c."ticket_number" ~ '  ' then regexp_replace(btrim(c."ticket_number"), '\s+', ' ', 'g')
            else c."ticket_number"
        end as "ticket_number",
        c."customer_id" as "customer_id",
        c."order_id" as "order_id",
        c."shipment_id" as "shipment_id",
        c."assigned_agent_id" as "assigned_agent_id",
        case
            when btrim(c."category") = '' or btrim(c."category") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."category"
        end as "category",
        case
            when btrim(c."priority") = '' or btrim(c."priority") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."priority"
        end as "priority",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."status"
        end as "status",
        case
            when btrim(c."subject") = '' or btrim(c."subject") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."subject" ~ '(Ã.|Â.)' then convert_from(convert_to(c."subject", 'LATIN1'), 'UTF8')
            when c."subject" <> btrim(c."subject") or c."subject" ~ '  ' then regexp_replace(btrim(c."subject"), '\s+', ' ', 'g')
            else c."subject"
        end as "subject",
        case
            when btrim(c."opened_at") = '' or btrim(c."opened_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."opened_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."opened_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."opened_at" from 4 for 2)::int between 1 and 12  and substring(c."opened_at" from 1 for 2)::int between 1 and 31) or c."opened_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."opened_at" ~ '^[0-9]{2}/' then to_date(c."opened_at", 'DD/MM/YYYY')::text else to_date(c."opened_at", 'YYYY.MM.DD')::text end
            when c."opened_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."opened_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."opened_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."opened_at"
        end as "opened_at",
        case
            when btrim(c."closed_at") = '' or btrim(c."closed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."closed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."closed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."closed_at" from 4 for 2)::int between 1 and 12  and substring(c."closed_at" from 1 for 2)::int between 1 and 31) or c."closed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."closed_at" ~ '^[0-9]{2}/' then to_date(c."closed_at", 'DD/MM/YYYY')::text else to_date(c."closed_at", 'YYYY.MM.DD')::text end
            when c."closed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."closed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."closed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."closed_at"
        end as "closed_at",
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
            'ticket_number', case
            when btrim(c."ticket_number") = '' or btrim(c."ticket_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."ticket_number" like '%;%' then 'TEXT_DELIMITER'
            when c."ticket_number" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."ticket_number" <> btrim(c."ticket_number") or c."ticket_number" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'category', case
            when btrim(c."category") = '' or btrim(c."category") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."category") not in ('delivery', 'payment', 'product', 'return', 'account', 'other') then 'ENUM_UNKNOWN'
        end,
            'priority', case
            when btrim(c."priority") = '' or btrim(c."priority") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."priority") not in ('low', 'normal', 'high', 'urgent') then 'ENUM_UNKNOWN'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('open', 'in_progress', 'waiting_customer', 'resolved', 'closed') then 'ENUM_UNKNOWN'
        end,
            'subject', case
            when btrim(c."subject") = '' or btrim(c."subject") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."subject") = 24 then 'TEXT_TRUNCATED'
            when c."subject" like '%;%' then 'TEXT_DELIMITER'
            when c."subject" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."subject" <> btrim(c."subject") or c."subject" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'opened_at', case
            when btrim(c."opened_at") = '' or btrim(c."opened_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."opened_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."opened_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."opened_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."opened_at" from 4 for 2)::int not between 1 and 12   or substring(c."opened_at" from 1 for 2)::int not between 1 and 31   or (substring(c."opened_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."opened_at" from 1 for 2)::int > 30)   or (substring(c."opened_at" from 4 for 2)::int = 2       and substring(c."opened_at" from 1 for 2)::int > 29)   or (substring(c."opened_at" from 4 for 2)::int = 2       and substring(c."opened_at" from 1 for 2)::int = 29       and not (substring(c."opened_at" from 7 for 4)::int % 4 = 0                and (substring(c."opened_at" from 7 for 4)::int % 100 <> 0                     or substring(c."opened_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."opened_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."opened_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."opened_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."opened_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."opened_at" from 4 for 2)::int between 1 and 12  and substring(c."opened_at" from 1 for 2)::int between 1 and 31) or c."opened_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."opened_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."opened_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'closed_at', case
            when btrim(c."closed_at") = '' or btrim(c."closed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."closed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."closed_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."closed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."closed_at" from 4 for 2)::int not between 1 and 12   or substring(c."closed_at" from 1 for 2)::int not between 1 and 31   or (substring(c."closed_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."closed_at" from 1 for 2)::int > 30)   or (substring(c."closed_at" from 4 for 2)::int = 2       and substring(c."closed_at" from 1 for 2)::int > 29)   or (substring(c."closed_at" from 4 for 2)::int = 2       and substring(c."closed_at" from 1 for 2)::int = 29       and not (substring(c."closed_at" from 7 for 4)::int % 4 = 0                and (substring(c."closed_at" from 7 for 4)::int % 100 <> 0                     or substring(c."closed_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."closed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."closed_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."closed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."closed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."closed_at" from 4 for 2)::int between 1 and 12  and substring(c."closed_at" from 1 for 2)::int between 1 and 31) or c."closed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."closed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."closed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
