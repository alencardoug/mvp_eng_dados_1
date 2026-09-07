-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.delivery_events` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'delivery_events') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'delivery_events') }}
    ))

),

-- A limpeza vem **antes** dos achados, e não junto: o achado de rejeição
-- precisa ser conferido contra o valor já convertido, senão uma conversão
-- bem-sucedida esconde a invalidade do resultado dela.
limpo as (

    select
        c.legacy_row_id,
        case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."id"
        end as "id",
        c."shipment_id" as "shipment_id",
        case
            when btrim(c."event_type") = '' or btrim(c."event_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."event_type") not in ('picked_up', 'in_transit', 'out_for_delivery', 'delivery_attempt', 'delivered', 'returned') then c."event_type"
            else c."event_type"
        end as "event_type",
        case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."occurred_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."occurred_at"
            when case when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) then left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."occurred_at"
            when case when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."occurred_at" ~ '^[0-9]{2}/' then to_date(c."occurred_at", 'DD/MM/YYYY')::text else to_date(c."occurred_at", 'YYYY.MM.DD')::text end
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."occurred_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when c."occurred_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."occurred_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."occurred_at" !~ '^[0-9]{2}/[0-9]{4}$' then c."occurred_at"
            else c."occurred_at"
        end as "occurred_at",
        case
            when btrim(c."location") = '' or btrim(c."location") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."location" like '%;%' and (c."description" is null or btrim(c."description") = '') and (c."created_at" is null or btrim(c."created_at") = '') then c."location"
            when c."location" ~ '(Ã[-¿]|Â[-¿])' and c."location" !~ '(Ã|Â)[A-ZÁÂÃÉÊÍÓÔÕÚÇ ]' then convert_from(convert_to(c."location", 'LATIN1'), 'UTF8')
            when c."location" <> btrim(c."location") or c."location" ~ '  ' then regexp_replace(btrim(c."location"), '\s+', ' ', 'g')
            else c."location"
        end as "location",
        case
            when btrim(c."description") = '' or btrim(c."description") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."description" like '%;%' and (c."created_at" is null or btrim(c."created_at") = '') then c."description"
            when c."description" ~ '(Ã[-¿]|Â[-¿])' and c."description" !~ '(Ã|Â)[A-ZÁÂÃÉÊÍÓÔÕÚÇ ]' then convert_from(convert_to(c."description", 'LATIN1'), 'UTF8')
            when c."description" <> btrim(c."description") or c."description" ~ '  ' then regexp_replace(btrim(c."description"), '\s+', ' ', 'g')
            else c."description"
        end as "description",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when c."created_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."created_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."created_at" !~ '^[0-9]{2}/[0-9]{4}$' then c."created_at"
            else c."created_at"
        end as "created_at"
    from captura c

)

select
    c.legacy_row_id,
    c._airbyte_generation_id                    as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
    l."id",
    l."shipment_id",
    l."event_type",
    l."occurred_at",
    l."location",
    l."description",
    l."created_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'event_type', case
            when btrim(c."event_type") = '' or btrim(c."event_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."event_type") not in ('picked_up', 'in_transit', 'out_for_delivery', 'delivery_attempt', 'delivered', 'returned') then 'ENUM_UNKNOWN'
        end,
            'occurred_at', case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."occurred_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) then left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
            when c."occurred_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."occurred_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."occurred_at" !~ '^[0-9]{2}/[0-9]{4}$' then 'DATE_UNPARSEABLE'
        end,
            'location', case
            when btrim(c."location") = '' or btrim(c."location") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."location" like '%;%' and (c."description" is null or btrim(c."description") = '') and (c."created_at" is null or btrim(c."created_at") = '') then 'TEXT_DELIMITER'
            when c."location" ~ '(Ã[-¿]|Â[-¿])' and c."location" !~ '(Ã|Â)[A-ZÁÂÃÉÊÍÓÔÕÚÇ ]' then 'TEXT_ENCODING'
            when c."location" <> btrim(c."location") or c."location" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'description', case
            when btrim(c."description") = '' or btrim(c."description") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."description" like '%;%' and (c."created_at" is null or btrim(c."created_at") = '') then 'TEXT_DELIMITER'
            when c."description" ~ '(Ã[-¿]|Â[-¿])' and c."description" !~ '(Ã|Â)[A-ZÁÂÃÉÊÍÓÔÕÚÇ ]' then 'TEXT_ENCODING'
            when c."description" <> btrim(c."description") or c."description" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'created_at', case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}'   then not (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."created_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
            when c."created_at" !~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}' and c."created_at" !~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and c."created_at" !~ '^[0-9]{2}/[0-9]{4}$' then 'DATE_UNPARSEABLE'
        end
        )
    )                                           as achados,
    jsonb_build_object('id', c."id", 'shipment_id', c."shipment_id", 'event_type', c."event_type", 'occurred_at', c."occurred_at", 'location', c."location", 'description', c."description", 'created_at', c."created_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id
