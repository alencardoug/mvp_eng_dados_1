-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.order_status_history`, na forma que `stg_retail__order_status_history`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'order_status_history'

)

select
    (cleaned_payload->>'id')::bigint                    as order_status_event_id,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    (cleaned_payload->>'from_status')::text             as from_status,
    (cleaned_payload->>'to_status')::text               as to_status,
    (cleaned_payload->>'changed_at')::timestamptz       as changed_at,
    (cleaned_payload->>'reason')::text                  as change_reason,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    false                                               as is_deleted,
    snapshot_at                                         as ingested_at
from apto
