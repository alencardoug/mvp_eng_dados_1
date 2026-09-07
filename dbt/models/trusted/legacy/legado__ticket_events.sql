-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.ticket_events`, na forma que `stg_retail__ticket_events`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'ticket_events'

)

select
    (cleaned_payload->>'id')::bigint                    as ticket_event_id,
    (cleaned_payload->>'ticket_id')::bigint             as support_ticket_id,
    (cleaned_payload->>'agent_id')::bigint              as support_agent_id,
    (cleaned_payload->>'event_type')::text              as ticket_event_type,
    (cleaned_payload->>'occurred_at')::timestamptz      as occurred_at,
    (cleaned_payload->>'message')::text                 as ticket_message,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    false                                               as is_deleted,
    snapshot_at                                         as ingested_at
from apto
