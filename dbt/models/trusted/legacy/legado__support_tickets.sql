-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.support_tickets`, na forma que `stg_retail__support_tickets`
-- produz. É esta relação que o modelo `trusted` empilha à origem principal.
--
-- Só `accepted` e `corrected` chegam aqui. O rejeitado fica em `quarantine`,
-- com o motivo: nada é descartado, e nada inválido atravessa (regra 4).

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'support_tickets'

)

select
    (cleaned_payload->>'id')::bigint                    as support_ticket_id,
    (cleaned_payload->>'ticket_number')::text           as ticket_number,
    (cleaned_payload->>'customer_id')::bigint           as customer_id,
    (cleaned_payload->>'order_id')::bigint              as order_id,
    (cleaned_payload->>'shipment_id')::bigint           as shipment_id,
    (cleaned_payload->>'assigned_agent_id')::bigint     as assigned_agent_id,
    (cleaned_payload->>'category')::text                as ticket_category,
    (cleaned_payload->>'priority')::text                as ticket_priority,
    (cleaned_payload->>'status')::text                  as ticket_status,
    (cleaned_payload->>'subject')::text                 as ticket_subject,
    (cleaned_payload->>'opened_at')::timestamptz        as opened_at,
    (cleaned_payload->>'closed_at')::timestamptz        as closed_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto
