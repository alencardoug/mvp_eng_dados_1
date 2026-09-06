-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.shipment_items` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'shipment_items') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'shipment_items') }}
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
        c."shipment_id" as "shipment_id",
        c."order_item_id" as "order_item_id",
        case
            when btrim(c."quantity") = '' or btrim(c."quantity") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."quantity" ~ '^-?[0-9]+$' and (c."quantity"::numeric < 0 or c."quantity"::numeric > 1000000) then c."quantity"
            when c."quantity" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity"), ',', '.') ~ '^-?[0-9]+\.0+$') then case lower(btrim(c."quantity")) when 'um' then '1' when 'dois' then '2' when 'três' then '3' when 'tres' then '3' when 'quatro' then '4' when 'cinco' then '5' when 'seis' then '6' when 'sete' then '7' when 'oito' then '8' when 'nove' then '9' when 'dez' then '10' else split_part(replace(btrim(c."quantity"), ',', '.'), '.', 1) end
            when c."quantity" !~ '^-?[0-9]+$' then c."quantity"
            else c."quantity"
        end as "quantity",
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
            'quantity', case
            when btrim(c."quantity") = '' or btrim(c."quantity") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."quantity" ~ '^-?[0-9]+$' and (c."quantity"::numeric < 0 or c."quantity"::numeric > 1000000) then 'NUM_OUT_OF_RANGE'
            when c."quantity" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity"), ',', '.') ~ '^-?[0-9]+\.0+$') then 'NUM_TEXT_EQUIV'
            when c."quantity" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
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
    jsonb_build_object('id', c."id", 'shipment_id', c."shipment_id", 'order_item_id', c."order_item_id", 'quantity', c."quantity", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
