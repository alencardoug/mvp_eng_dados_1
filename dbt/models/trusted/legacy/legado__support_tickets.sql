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

{% if target.type == 'bigquery' %}
WITH apto AS (
  SELECT
    *
  FROM {{ ref('legacy_eligible_records') }}
  WHERE
    source_table = 'support_tickets'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS support_ticket_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.ticket_number')
  ) AS STRING) AS ticket_number,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.customer_id')
  ) AS INT64) AS customer_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.order_id')
  ) AS INT64) AS order_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.shipment_id')
  ) AS INT64) AS shipment_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.assigned_agent_id')
  ) AS INT64) AS assigned_agent_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.category')
  ) AS STRING) AS ticket_category,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.priority')
  ) AS STRING) AS ticket_priority,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.status')
  ) AS STRING) AS ticket_status,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.subject')
  ) AS STRING) AS ticket_subject,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.opened_at')
  ) AS TIMESTAMP) AS opened_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.closed_at')
  ) AS TIMESTAMP) AS closed_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.created_at')
  ) AS TIMESTAMP) AS source_created_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.updated_at')
  ) AS TIMESTAMP) AS source_updated_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.deleted_at')
  ) AS TIMESTAMP) AS source_deleted_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.deleted_at')
  ) AS TIMESTAMP) IS NOT NULL AS is_deleted,
  snapshot_at AS ingested_at
FROM apto
{% else %}with apto as (

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
from apto{% endif %}
