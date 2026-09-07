-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.payment_transactions`, na forma que `stg_retail__payment_transactions`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'payment_transactions'

)

select
    (cleaned_payload->>'id')::bigint                    as payment_transaction_id,
    (cleaned_payload->>'transaction_code')::text        as transaction_code,
    (cleaned_payload->>'payment_id')::bigint            as payment_id,
    (cleaned_payload->>'transaction_type')::text        as transaction_type,
    (cleaned_payload->>'result')::text                  as transaction_result,
    (cleaned_payload->>'amount')::numeric(14, 2)        as transaction_amount,
    (cleaned_payload->>'gateway_response_code')::text   as gateway_response_code,
    (cleaned_payload->>'occurred_at')::timestamptz      as occurred_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    false                                               as is_deleted,
    snapshot_at                                         as ingested_at
from apto
