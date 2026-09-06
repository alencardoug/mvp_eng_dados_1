-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.inventory_movements` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'inventory_movements') }}
    where _airbyte_generation_id = coalesce(
        {{ legacy_snapshot_id() }}, (
        select max(_airbyte_generation_id) from {{ source('legacy', 'inventory_movements') }}
    ))

)

select
    c.legacy_row_id,
    c._airbyte_generation_id                    as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
        case
            when btrim(c."movement_id") = '' or btrim(c."movement_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."movement_id"
        end as "movement_id",
        case
            when btrim(c."idempotency_key") = '' or btrim(c."idempotency_key") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."idempotency_key" like '%;%' then c."idempotency_key"
            when c."idempotency_key" ~ '(Ã.|Â.)' then convert_from(convert_to(c."idempotency_key", 'LATIN1'), 'UTF8')
            when c."idempotency_key" <> btrim(c."idempotency_key") or c."idempotency_key" ~ '  ' then regexp_replace(btrim(c."idempotency_key"), '\s+', ' ', 'g')
            else c."idempotency_key"
        end as "idempotency_key",
        c."warehouse_id" as "warehouse_id",
        c."product_variant_id" as "product_variant_id",
        case
            when btrim(c."movement_type") = '' or btrim(c."movement_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."movement_type") not in ('purchase_receipt', 'customer_return', 'transfer_in', 'adjustment_in', 'sale_dispatch', 'supplier_return', 'transfer_out', 'adjustment_out') then c."movement_type"
            else c."movement_type"
        end as "movement_type",
        case
            when btrim(c."quantity_delta") = '' or btrim(c."quantity_delta") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."quantity_delta" ~ '^-?[0-9]+$' and abs(c."quantity_delta"::numeric) > 1000000 then c."quantity_delta"
            when c."quantity_delta" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity_delta")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity_delta"), ',', '.') ~ '^-?[0-9]+\.0+$') then case lower(btrim(c."quantity_delta")) when 'um' then '1' when 'dois' then '2' when 'três' then '3' when 'tres' then '3' when 'quatro' then '4' when 'cinco' then '5' when 'seis' then '6' when 'sete' then '7' when 'oito' then '8' when 'nove' then '9' when 'dez' then '10' else split_part(replace(btrim(c."quantity_delta"), ',', '.'), '.', 1) end
            when c."quantity_delta" !~ '^-?[0-9]+$' then c."quantity_delta"
            else c."quantity_delta"
        end as "quantity_delta",
        case
            when btrim(c."unit_cost") = '' or btrim(c."unit_cost") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."unit_cost", 'R$', ''), ' ', '')) ~ '^-' then c."unit_cost"
            when c."unit_cost" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."unit_cost", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), ',', '') end
            else c."unit_cost"
        end as "unit_cost",
        case
            when btrim(c."source_type") = '' or btrim(c."source_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."source_type") not in ('purchase', 'sale', 'return', 'transfer', 'adjustment') then c."source_type"
            else c."source_type"
        end as "source_type",
        case
            when btrim(c."source_id") = '' or btrim(c."source_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."source_id" like '%;%' then c."source_id"
            when c."source_id" ~ '(Ã.|Â.)' then convert_from(convert_to(c."source_id", 'LATIN1'), 'UTF8')
            when c."source_id" <> btrim(c."source_id") or c."source_id" ~ '  ' then regexp_replace(btrim(c."source_id"), '\s+', ' ', 'g')
            else c."source_id"
        end as "source_id",
        case
            when btrim(c."correlation_id") = '' or btrim(c."correlation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."correlation_id"
        end as "correlation_id",
        case
            when btrim(c."causation_id") = '' or btrim(c."causation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."causation_id"
        end as "causation_id",
        case
            when btrim(c."aggregate_version") = '' or btrim(c."aggregate_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."aggregate_version"
        end as "aggregate_version",
        case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."occurred_at" from 4 for 2)::int not between 1 and 12   or substring(c."occurred_at" from 1 for 2)::int not between 1 and 31   or (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."occurred_at" from 1 for 2)::int > 30)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int > 29)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int = 29       and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0                and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0                     or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))))) then c."occurred_at"
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' then c."occurred_at"
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."occurred_at" from 4 for 2)::int between 1 and 12  and substring(c."occurred_at" from 1 for 2)::int between 1 and 31) or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."occurred_at" ~ '^[0-9]{2}/' then to_date(c."occurred_at", 'DD/MM/YYYY')::text else to_date(c."occurred_at", 'YYYY.MM.DD')::text end
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."occurred_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."occurred_at"
        end as "occurred_at",
        case
            when btrim(c."recorded_at") = '' or btrim(c."recorded_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."recorded_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."recorded_at" from 4 for 2)::int not between 1 and 12   or substring(c."recorded_at" from 1 for 2)::int not between 1 and 31   or (substring(c."recorded_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."recorded_at" from 1 for 2)::int > 30)   or (substring(c."recorded_at" from 4 for 2)::int = 2       and substring(c."recorded_at" from 1 for 2)::int > 29)   or (substring(c."recorded_at" from 4 for 2)::int = 2       and substring(c."recorded_at" from 1 for 2)::int = 29       and not (substring(c."recorded_at" from 7 for 4)::int % 4 = 0                and (substring(c."recorded_at" from 7 for 4)::int % 100 <> 0                     or substring(c."recorded_at" from 7 for 4)::int % 400 = 0)))))) then c."recorded_at"
            when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."recorded_at", 10)::date > date '{{ var("as_of_date") }}' then c."recorded_at"
            when c."recorded_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."recorded_at" from 4 for 2)::int between 1 and 12  and substring(c."recorded_at" from 1 for 2)::int between 1 and 31) or c."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."recorded_at" ~ '^[0-9]{2}/' then to_date(c."recorded_at", 'DD/MM/YYYY')::text else to_date(c."recorded_at", 'YYYY.MM.DD')::text end
            when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."recorded_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."recorded_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."recorded_at"
        end as "recorded_at",
        case
            when btrim(c."schema_version") = '' or btrim(c."schema_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."schema_version"
        end as "schema_version",
        case
            when btrim(c."metadata") = '' or btrim(c."metadata") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."metadata"
        end as "metadata",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'movement_id', case
            when btrim(c."movement_id") = '' or btrim(c."movement_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'idempotency_key', case
            when btrim(c."idempotency_key") = '' or btrim(c."idempotency_key") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."idempotency_key" like '%;%' then 'TEXT_DELIMITER'
            when c."idempotency_key" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."idempotency_key" <> btrim(c."idempotency_key") or c."idempotency_key" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'movement_type', case
            when btrim(c."movement_type") = '' or btrim(c."movement_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."movement_type") not in ('purchase_receipt', 'customer_return', 'transfer_in', 'adjustment_in', 'sale_dispatch', 'supplier_return', 'transfer_out', 'adjustment_out') then 'ENUM_UNKNOWN'
        end,
            'quantity_delta', case
            when btrim(c."quantity_delta") = '' or btrim(c."quantity_delta") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."quantity_delta" ~ '^-?[0-9]+$' and abs(c."quantity_delta"::numeric) > 1000000 then 'NUM_OUT_OF_RANGE'
            when c."quantity_delta" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity_delta")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity_delta"), ',', '.') ~ '^-?[0-9]+\.0+$') then 'NUM_TEXT_EQUIV'
            when c."quantity_delta" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
        end,
            'unit_cost', case
            when btrim(c."unit_cost") = '' or btrim(c."unit_cost") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."unit_cost", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."unit_cost" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'source_type', case
            when btrim(c."source_type") = '' or btrim(c."source_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."source_type") not in ('purchase', 'sale', 'return', 'transfer', 'adjustment') then 'ENUM_UNKNOWN'
        end,
            'source_id', case
            when btrim(c."source_id") = '' or btrim(c."source_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."source_id" like '%;%' then 'TEXT_DELIMITER'
            when c."source_id" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."source_id" <> btrim(c."source_id") or c."source_id" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'correlation_id', case
            when btrim(c."correlation_id") = '' or btrim(c."correlation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'causation_id', case
            when btrim(c."causation_id") = '' or btrim(c."causation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'aggregate_version', case
            when btrim(c."aggregate_version") = '' or btrim(c."aggregate_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'occurred_at', case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."occurred_at" from 4 for 2)::int not between 1 and 12   or substring(c."occurred_at" from 1 for 2)::int not between 1 and 31   or (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."occurred_at" from 1 for 2)::int > 30)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int > 29)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int = 29       and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0                and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0                     or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."occurred_at" from 4 for 2)::int between 1 and 12  and substring(c."occurred_at" from 1 for 2)::int between 1 and 31) or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'recorded_at', case
            when btrim(c."recorded_at") = '' or btrim(c."recorded_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."recorded_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."recorded_at" from 4 for 2)::int not between 1 and 12   or substring(c."recorded_at" from 1 for 2)::int not between 1 and 31   or (substring(c."recorded_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."recorded_at" from 1 for 2)::int > 30)   or (substring(c."recorded_at" from 4 for 2)::int = 2       and substring(c."recorded_at" from 1 for 2)::int > 29)   or (substring(c."recorded_at" from 4 for 2)::int = 2       and substring(c."recorded_at" from 1 for 2)::int = 29       and not (substring(c."recorded_at" from 7 for 4)::int % 4 = 0                and (substring(c."recorded_at" from 7 for 4)::int % 100 <> 0                     or substring(c."recorded_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."recorded_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."recorded_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."recorded_at" from 4 for 2)::int between 1 and 12  and substring(c."recorded_at" from 1 for 2)::int between 1 and 31) or c."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."recorded_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
        end,
            'schema_version', case
            when btrim(c."schema_version") = '' or btrim(c."schema_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'metadata', case
            when btrim(c."metadata") = '' or btrim(c."metadata") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end
        )
    )                                           as achados,
    jsonb_build_object('movement_id', c."movement_id", 'idempotency_key', c."idempotency_key", 'warehouse_id', c."warehouse_id", 'product_variant_id', c."product_variant_id", 'movement_type', c."movement_type", 'quantity_delta', c."quantity_delta", 'unit_cost', c."unit_cost", 'source_type', c."source_type", 'source_id', c."source_id", 'correlation_id', c."correlation_id", 'causation_id', c."causation_id", 'aggregate_version', c."aggregate_version", 'occurred_at', c."occurred_at", 'recorded_at', c."recorded_at", 'schema_version', c."schema_version", 'metadata', c."metadata")              as original_payload
from captura c
