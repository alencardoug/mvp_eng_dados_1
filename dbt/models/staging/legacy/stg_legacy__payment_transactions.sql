-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.payment_transactions` — camada `staging` (ADR-0016).
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
    from {{ source('legacy', 'payment_transactions') }}
    where _airbyte_generation_id = (
        select max(_airbyte_generation_id) from {{ source('legacy', 'payment_transactions') }}
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
            when btrim(c."transaction_code") = '' or btrim(c."transaction_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."transaction_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."transaction_code", 'LATIN1'), 'UTF8')
            when c."transaction_code" <> btrim(c."transaction_code") or c."transaction_code" ~ '  ' then regexp_replace(btrim(c."transaction_code"), '\s+', ' ', 'g')
            else c."transaction_code"
        end as "transaction_code",
        c."payment_id" as "payment_id",
        case
            when btrim(c."transaction_type") = '' or btrim(c."transaction_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."transaction_type"
        end as "transaction_type",
        case
            when btrim(c."result") = '' or btrim(c."result") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."result"
        end as "result",
        case
            when btrim(c."amount") = '' or btrim(c."amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then case when btrim(replace(replace(c."amount", 'R$', ''), ' ', '')) ~ ',[0-9]{1,2}$' then replace(replace(replace(replace(c."amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."amount", 'R$', ''), ' ', ''), ',', '') end
            else c."amount"
        end as "amount",
        case
            when btrim(c."gateway_response_code") = '' or btrim(c."gateway_response_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."gateway_response_code" ~ '(Ã.|Â.)' then convert_from(convert_to(c."gateway_response_code", 'LATIN1'), 'UTF8')
            when c."gateway_response_code" <> btrim(c."gateway_response_code") or c."gateway_response_code" ~ '  ' then regexp_replace(btrim(c."gateway_response_code"), '\s+', ' ', 'g')
            else c."gateway_response_code"
        end as "gateway_response_code",
        case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."occurred_at" from 4 for 2)::int between 1 and 12  and substring(c."occurred_at" from 1 for 2)::int between 1 and 31) or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then case when c."occurred_at" ~ '^[0-9]{2}/' then to_date(c."occurred_at", 'DD/MM/YYYY')::text else to_date(c."occurred_at", 'YYYY.MM.DD')::text end
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then (c."occurred_at"::timestamp at time zone 'America/Sao_Paulo')::text
            else c."occurred_at"
        end as "occurred_at",
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
            'transaction_code', case
            when btrim(c."transaction_code") = '' or btrim(c."transaction_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."transaction_code" like '%;%' then 'TEXT_DELIMITER'
            when c."transaction_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."transaction_code" <> btrim(c."transaction_code") or c."transaction_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'transaction_type', case
            when btrim(c."transaction_type") = '' or btrim(c."transaction_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."transaction_type") not in ('authorization', 'capture', 'void', 'refund') then 'ENUM_UNKNOWN'
        end,
            'result', case
            when btrim(c."result") = '' or btrim(c."result") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."result") not in ('succeeded', 'failed', 'pending') then 'ENUM_UNKNOWN'
        end,
            'amount', case
            when btrim(c."amount") = '' or btrim(c."amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."amount" !~ '^-?[0-9]+(\.[0-9]+)?$' then 'MONEY_LOCALE'
        end,
            'gateway_response_code', case
            when btrim(c."gateway_response_code") = '' or btrim(c."gateway_response_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."gateway_response_code" like '%;%' then 'TEXT_DELIMITER'
            when c."gateway_response_code" ~ '(Ã.|Â.)' then 'TEXT_ENCODING'
            when c."gateway_response_code" <> btrim(c."gateway_response_code") or c."gateway_response_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'occurred_at', case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' and (   substring(c."occurred_at" from 4 for 2)::int not between 1 and 12   or substring(c."occurred_at" from 1 for 2)::int not between 1 and 31   or (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11)       and substring(c."occurred_at" from 1 for 2)::int > 30)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int > 29)   or (substring(c."occurred_at" from 4 for 2)::int = 2       and substring(c."occurred_at" from 1 for 2)::int = 29       and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0                and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0                     or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))))) then 'DATE_IMPOSSIBLE'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' then 'DATE_FUTURE'
            when c."occurred_at" !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and ( (c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'  and substring(c."occurred_at" from 4 for 2)::int between 1 and 12  and substring(c."occurred_at" from 1 for 2)::int between 1 and 31) or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$') then 'DATE_FORMAT_KNOWN'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}' and c."occurred_at" !~ '(Z|[+-][0-9]{2}:?[0-9]{2})$' then 'DATE_TZ_MISSING'
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
