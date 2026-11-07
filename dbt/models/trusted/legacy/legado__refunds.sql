-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.refunds`, na forma que `stg_retail__refunds`
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
    source_table = 'refunds'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS refund_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.refund_code')
  ) AS STRING) AS refund_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.payment_transaction_id')
  ) AS INT64) AS payment_transaction_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.amount')
  ) AS NUMERIC) AS refund_amount,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.reason')
  ) AS STRING) AS refund_reason,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.status')
  ) AS STRING) AS refund_status,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.refunded_at')
  ) AS TIMESTAMP) AS refunded_at,
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
    where source_table = 'refunds'

)

select
    (cleaned_payload->>'id')::bigint                    as refund_id,
    (cleaned_payload->>'refund_code')::text             as refund_code,
    (cleaned_payload->>'payment_transaction_id')::bigint as payment_transaction_id,
    (cleaned_payload->>'amount')::numeric(14, 2)        as refund_amount,
    (cleaned_payload->>'reason')::text                  as refund_reason,
    (cleaned_payload->>'status')::text                  as refund_status,
    (cleaned_payload->>'refunded_at')::timestamptz      as refunded_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
