-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.payments`, na forma que `stg_retail__payments`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'payments'

)

select
    (cleaned_payload->>'id')::bigint                    as payment_id,
    (cleaned_payload->>'payment_code')::text            as payment_code,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    (cleaned_payload->>'payment_method_id')::bigint     as payment_method_id,
    (cleaned_payload->>'status')::text                  as payment_status,
    (cleaned_payload->>'amount')::numeric(14, 2)        as payment_amount,
    (cleaned_payload->>'currency')::text                as currency,
    cast((cleaned_payload->>'installments')::integer as integer) as installments,
    (cleaned_payload->>'authorized_at')::timestamptz    as authorized_at,
    (cleaned_payload->>'captured_at')::timestamptz      as captured_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
