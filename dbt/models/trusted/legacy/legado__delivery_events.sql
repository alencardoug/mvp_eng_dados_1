-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.delivery_events`, na forma que `stg_retail__delivery_events`
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
    source_table = 'delivery_events'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS delivery_event_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.shipment_id')
  ) AS INT64) AS shipment_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.event_type')
  ) AS STRING) AS delivery_event_type,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.occurred_at')
  ) AS TIMESTAMP) AS occurred_at,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.location')
  ) AS STRING) AS event_location,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.description')
  ) AS STRING) AS event_description,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.created_at')
  ) AS TIMESTAMP) AS source_created_at,
  FALSE AS is_deleted,
  snapshot_at AS ingested_at
FROM apto
{% else %}with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'delivery_events'

)

select
    (cleaned_payload->>'id')::bigint                    as delivery_event_id,
    (cleaned_payload->>'shipment_id')::bigint           as shipment_id,
    (cleaned_payload->>'event_type')::text              as delivery_event_type,
    (cleaned_payload->>'occurred_at')::timestamptz      as occurred_at,
    (cleaned_payload->>'location')::text                as event_location,
    (cleaned_payload->>'description')::text             as event_description,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    false                                               as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
