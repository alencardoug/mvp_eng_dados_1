-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.shipments` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'shipments') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'shipments') }}
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
            when btrim(c."shipment_code") = '' or btrim(c."shipment_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."shipment_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."shipment_code", 'LATIN1'), 'UTF8')
            when c."shipment_code" <> btrim(c."shipment_code") or c."shipment_code" ~ '  ' then regexp_replace(btrim(c."shipment_code"), '\s+', ' ', 'g')
            else c."shipment_code"
        end as "shipment_code",
        c."order_id" as "order_id",
        c."carrier_id" as "carrier_id",
        c."warehouse_id" as "warehouse_id",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."status"
        end as "status",
        case
            when btrim(c."tracking_code") = '' or btrim(c."tracking_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."tracking_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."tracking_code", 'LATIN1'), 'UTF8')
            when c."tracking_code" <> btrim(c."tracking_code") or c."tracking_code" ~ '  ' then regexp_replace(btrim(c."tracking_code"), '\s+', ' ', 'g')
            else c."tracking_code"
        end as "tracking_code",
        case
            when btrim(c."freight_amount") = '' or btrim(c."freight_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."freight_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."freight_amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."freight_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."freight_amount", 'R$', ''), ' ', ''), ',', '') end
            else c."freight_amount"
        end as "freight_amount",
        case
            when btrim(c."shipped_at") = '' or btrim(c."shipped_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."shipped_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."shipped_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."shipped_at" from 4 for 2)::int between 1 and 12  and substring(c."shipped_at" from 1 for 2)::int between 1 and 31) or c."shipped_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."shipped_at" ~ '^[0-9]{2}/' then to_date(c."shipped_at", 'DD/MM/YYYY')::text else to_date(c."shipped_at", 'YYYY.MM.DD')::text end
            when c."shipped_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."shipped_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."shipped_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."shipped_at"
        end as "shipped_at",
        case
            when btrim(c."estimated_delivery_at") = '' or btrim(c."estimated_delivery_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."estimated_delivery_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."estimated_delivery_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."estimated_delivery_at" from 4 for 2)::int between 1 and 12  and substring(c."estimated_delivery_at" from 1 for 2)::int between 1 and 31) or c."estimated_delivery_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."estimated_delivery_at" ~ '^[0-9]{2}/' then to_date(c."estimated_delivery_at", 'DD/MM/YYYY')::text else to_date(c."estimated_delivery_at", 'YYYY.MM.DD')::text end
            when c."estimated_delivery_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."estimated_delivery_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."estimated_delivery_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."estimated_delivery_at"
        end as "estimated_delivery_at",
        case
            when btrim(c."delivered_at") = '' or btrim(c."delivered_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."delivered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."delivered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."delivered_at" from 4 for 2)::int between 1 and 12  and substring(c."delivered_at" from 1 for 2)::int between 1 and 31) or c."delivered_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."delivered_at" ~ '^[0-9]{2}/' then to_date(c."delivered_at", 'DD/MM/YYYY')::text else to_date(c."delivered_at", 'YYYY.MM.DD')::text end
            when c."delivered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."delivered_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."delivered_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."delivered_at"
        end as "delivered_at",
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
            'shipment_code', case
            when btrim(c."shipment_code") = '' or btrim(c."shipment_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."shipment_code" like '%;%' then 'TEXT_DELIMITER'
            when c."shipment_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."shipment_code" <> btrim(c."shipment_code") or c."shipment_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'status', case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('created', 'picking', 'dispatched', 'in_transit', 'delivered', 'returned', 'lost') then 'ENUM_UNKNOWN'
        end,
            'tracking_code', case
            when btrim(c."tracking_code") = '' or btrim(c."tracking_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."tracking_code" like '%;%' then 'TEXT_DELIMITER'
            when c."tracking_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."tracking_code" <> btrim(c."tracking_code") or c."tracking_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'freight_amount', case
            when btrim(c."freight_amount") = '' or btrim(c."freight_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."freight_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."freight_amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'shipped_at', case
            when btrim(c."shipped_at") = '' or btrim(c."shipped_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."shipped_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."shipped_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."shipped_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."shipped_at" from 4 for 2)::int not between 1 and 12   or substring(c."shipped_at" from 1 for 2)::int not between 1 and 31   or (substring(c."shipped_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."shipped_at" from 1 for 2)::int > 30)   or (substring(c."shipped_at" from 4 for 2)::int = 2       and substring(c."shipped_at" from 1 for 2)::int > 29)   or (substring(c."shipped_at" from 4 for 2)::int = 2       and substring(c."shipped_at" from 1 for 2)::int = 29       and not (substring(c."shipped_at" from 7 for 4)::int % 4 = 0                and (substring(c."shipped_at" from 7 for 4)::int % 100 <> 0                     or substring(c."shipped_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."shipped_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."shipped_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."shipped_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."shipped_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."shipped_at" from 4 for 2)::int between 1 and 12  and substring(c."shipped_at" from 1 for 2)::int between 1 and 31) or c."shipped_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."shipped_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."shipped_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'estimated_delivery_at', case
            when btrim(c."estimated_delivery_at") = '' or btrim(c."estimated_delivery_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."estimated_delivery_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."estimated_delivery_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."estimated_delivery_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."estimated_delivery_at" from 4 for 2)::int not between 1 and 12   or substring(c."estimated_delivery_at" from 1 for 2)::int not between 1 and 31   or (substring(c."estimated_delivery_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."estimated_delivery_at" from 1 for 2)::int > 30)   or (substring(c."estimated_delivery_at" from 4 for 2)::int = 2       and substring(c."estimated_delivery_at" from 1 for 2)::int > 29)   or (substring(c."estimated_delivery_at" from 4 for 2)::int = 2       and substring(c."estimated_delivery_at" from 1 for 2)::int = 29       and not (substring(c."estimated_delivery_at" from 7 for 4)::int % 4 = 0                and (substring(c."estimated_delivery_at" from 7 for 4)::int % 100 <> 0                     or substring(c."estimated_delivery_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."estimated_delivery_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."estimated_delivery_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."estimated_delivery_at" from 4 for 2)::int between 1 and 12  and substring(c."estimated_delivery_at" from 1 for 2)::int between 1 and 31) or c."estimated_delivery_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."estimated_delivery_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."estimated_delivery_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'delivered_at', case
            when btrim(c."delivered_at") = '' or btrim(c."delivered_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."delivered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."delivered_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."delivered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."delivered_at" from 4 for 2)::int not between 1 and 12   or substring(c."delivered_at" from 1 for 2)::int not between 1 and 31   or (substring(c."delivered_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."delivered_at" from 1 for 2)::int > 30)   or (substring(c."delivered_at" from 4 for 2)::int = 2       and substring(c."delivered_at" from 1 for 2)::int > 29)   or (substring(c."delivered_at" from 4 for 2)::int = 2       and substring(c."delivered_at" from 1 for 2)::int = 29       and not (substring(c."delivered_at" from 7 for 4)::int % 4 = 0                and (substring(c."delivered_at" from 7 for 4)::int % 100 <> 0                     or substring(c."delivered_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."delivered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."delivered_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."delivered_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."delivered_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."delivered_at" from 4 for 2)::int between 1 and 12  and substring(c."delivered_at" from 1 for 2)::int between 1 and 31) or c."delivered_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."delivered_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."delivered_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
