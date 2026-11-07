-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.suppliers`, na forma que `stg_retail__suppliers`
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
    source_table = 'suppliers'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS supplier_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.supplier_code')
  ) AS STRING) AS supplier_code,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.legal_name')
  ) AS STRING) AS supplier_legal_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.trade_name')
  ) AS STRING) AS supplier_trade_name,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.document')
  ) AS STRING) AS supplier_document,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.contact_email')
  ) AS STRING) AS supplier_contact_email,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.country')
  ) AS STRING) AS supplier_country,
  CAST(CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.payment_terms_days')
  ) AS INT64) AS INT64) AS payment_terms_days,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.is_active')
  ) AS BOOL) AS is_active,
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
    where source_table = 'suppliers'

)

select
    (cleaned_payload->>'id')::bigint                    as supplier_id,
    (cleaned_payload->>'supplier_code')::text           as supplier_code,
    (cleaned_payload->>'legal_name')::text              as supplier_legal_name,
    (cleaned_payload->>'trade_name')::text              as supplier_trade_name,
    (cleaned_payload->>'document')::text                as supplier_document,
    (cleaned_payload->>'contact_email')::text           as supplier_contact_email,
    (cleaned_payload->>'country')::text                 as supplier_country,
    cast((cleaned_payload->>'payment_terms_days')::integer as integer) as payment_terms_days,
    (cleaned_payload->>'is_active')::boolean            as is_active,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
