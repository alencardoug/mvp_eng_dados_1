-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.ticket_events` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'ticket_events') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'ticket_events') }}
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
        c."ticket_id" as "ticket_id",
        c."agent_id" as "agent_id",
        case
            when btrim(c."event_type") = '' or btrim(c."event_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."event_type"
        end as "event_type",
        case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."occurred_at" from 4 for 2)::int between 1 and 12  and substring(c."occurred_at" from 1 for 2)::int between 1 and 31) or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."occurred_at" ~ '^[0-9]{2}/' then to_date(c."occurred_at", 'DD/MM/YYYY')::text else to_date(c."occurred_at", 'YYYY.MM.DD')::text end
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."occurred_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."occurred_at"
        end as "occurred_at",
        case
            when btrim(c."message") = '' or btrim(c."message") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."message" ~ '(Ã.|Â.)' then convert_from(convert_to(c."message", 'LATIN1'), 'UTF8')
            when c."message" <> btrim(c."message") or c."message" ~ '  ' then regexp_replace(btrim(c."message"), '\s+', ' ', 'g')
            else c."message"
        end as "message",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."created_at" from 4 for 2)::int between 1 and 12  and substring(c."created_at" from 1 for 2)::int between 1 and 31) or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."created_at"
        end as "created_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'event_type', case
            when btrim(c."event_type") = '' or btrim(c."event_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."event_type") not in ('created', 'assigned', 'message', 'status_changed', 'resolved', 'reopened') then 'ENUM_UNKNOWN'
        end,
            'occurred_at', case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."occurred_at" from 4 for 2)::int not between 1 and 12   or substring(c."occurred_at" from 1 for 2)::int not between 1 and 31   or (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."occurred_at" from 1 for 2)::int > 30)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int > 29)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int = 29       and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0                and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0                     or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."occurred_at" from 4 for 2)::int between 1 and 12  and substring(c."occurred_at" from 1 for 2)::int between 1 and 31) or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'message', case
            when btrim(c."message") = '' or btrim(c."message") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."message" like '%;%' then 'TEXT_DELIMITER'
            when c."message" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."message" <> btrim(c."message") or c."message" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'created_at', case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."created_at" from 4 for 2)::int not between 1 and 12   or substring(c."created_at" from 1 for 2)::int not between 1 and 31   or (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."created_at" from 1 for 2)::int > 30)   or (substring(c."created_at" from 4 for 2)::int = 2       and substring(c."created_at" from 1 for 2)::int > 29)   or (substring(c."created_at" from 4 for 2)::int = 2       and substring(c."created_at" from 1 for 2)::int = 29       and not (substring(c."created_at" from 7 for 4)::int % 4 = 0                and (substring(c."created_at" from 7 for 4)::int % 100 <> 0                     or substring(c."created_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."created_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."created_at" from 4 for 2)::int between 1 and 12  and substring(c."created_at" from 1 for 2)::int between 1 and 31) or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end
        )
    )                                           as achados
from captura c
