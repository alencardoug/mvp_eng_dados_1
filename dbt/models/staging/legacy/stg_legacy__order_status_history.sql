-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.order_status_history` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'order_status_history') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'order_status_history') }}
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
        c."order_id" as "order_id",
        case
            when btrim(c."from_status") = '' or btrim(c."from_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."from_status"
        end as "from_status",
        case
            when btrim(c."to_status") = '' or btrim(c."to_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."to_status"
        end as "to_status",
        case
            when btrim(c."changed_at") = '' or btrim(c."changed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."changed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."changed_at" from 4 for 2)::int between 1 and 12  and substring(c."changed_at" from 1 for 2)::int between 1 and 31) or c."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."changed_at" ~ '^[0-9]{2}/' then to_date(c."changed_at", 'DD/MM/YYYY')::text else to_date(c."changed_at", 'YYYY.MM.DD')::text end
            when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."changed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."changed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."changed_at"
        end as "changed_at",
        case
            when btrim(c."reason") = '' or btrim(c."reason") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."reason" ~ '(Ã.|Â.)' then convert_from(convert_to(c."reason", 'LATIN1'), 'UTF8')
            when c."reason" <> btrim(c."reason") or c."reason" ~ '  ' then regexp_replace(btrim(c."reason"), '\s+', ' ', 'g')
            else c."reason"
        end as "reason",
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
            'from_status', case
            when btrim(c."from_status") = '' or btrim(c."from_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."from_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
        end,
            'to_status', case
            when btrim(c."to_status") = '' or btrim(c."to_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."to_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
        end,
            'changed_at', case
            when btrim(c."changed_at") = '' or btrim(c."changed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."changed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."changed_at" from 4 for 2)::int not between 1 and 12   or substring(c."changed_at" from 1 for 2)::int not between 1 and 31   or (substring(c."changed_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."changed_at" from 1 for 2)::int > 30)   or (substring(c."changed_at" from 4 for 2)::int = 2       and substring(c."changed_at" from 1 for 2)::int > 29)   or (substring(c."changed_at" from 4 for 2)::int = 2       and substring(c."changed_at" from 1 for 2)::int = 29       and not (substring(c."changed_at" from 7 for 4)::int % 4 = 0                and (substring(c."changed_at" from 7 for 4)::int % 100 <> 0                     or substring(c."changed_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."changed_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."changed_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."changed_at" from 4 for 2)::int between 1 and 12  and substring(c."changed_at" from 1 for 2)::int between 1 and 31) or c."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."changed_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'reason', case
            when btrim(c."reason") = '' or btrim(c."reason") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."reason" like '%;%' then 'TEXT_DELIMITER'
            when c."reason" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."reason" <> btrim(c."reason") or c."reason" ~ '  ' then 'TEXT_WHITESPACE_CASE'
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
