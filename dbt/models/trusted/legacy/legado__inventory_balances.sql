-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir do modelo de staging da        ║
-- ║  origem principal. Não edite: a próxima geração o sobrescreve. Erro      ║
-- ║  aqui é sintoma — corrija em src/mvp_ed1/legacy/ponte.py.                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Registros aptos de `legacy.inventory_balances`, na forma que `stg_retail__inventory_balances`
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
    source_table = 'inventory_balances'
)
SELECT
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.id')
  ) AS INT64) AS inventory_balance_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.warehouse_id')
  ) AS INT64) AS warehouse_id,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.product_variant_id')
  ) AS INT64) AS product_variant_id,
  CAST(CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.quantity_on_hand')
  ) AS INT64) AS INT64) AS quantity_on_hand,
  CAST(CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.quantity_reserved')
  ) AS INT64) AS INT64) AS quantity_reserved,
  CAST((
    CAST((
      JSON_EXTRACT_SCALAR(cleaned_payload, '$.quantity_on_hand')
    ) AS INT64) - CAST((
      JSON_EXTRACT_SCALAR(cleaned_payload, '$.quantity_reserved')
    ) AS INT64)
  ) AS INT64) AS quantity_available,
  CAST((
    JSON_EXTRACT_SCALAR(cleaned_payload, '$.last_movement_at')
  ) AS TIMESTAMP) AS last_movement_at,
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
    where source_table = 'inventory_balances'

)

select
    (cleaned_payload->>'id')::bigint                    as inventory_balance_id,
    (cleaned_payload->>'warehouse_id')::bigint          as warehouse_id,
    (cleaned_payload->>'product_variant_id')::bigint    as product_variant_id,
    cast((cleaned_payload->>'quantity_on_hand')::integer as integer) as quantity_on_hand,
    cast((cleaned_payload->>'quantity_reserved')::integer as integer) as quantity_reserved,
    cast(((cleaned_payload->>'quantity_on_hand')::integer - (cleaned_payload->>'quantity_reserved')::integer) as integer) as quantity_available,
    (cleaned_payload->>'last_movement_at')::timestamptz as last_movement_at,
    (cleaned_payload->>'created_at')::timestamptz       as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz       as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz       as source_deleted_at,
    (cleaned_payload->>'deleted_at')::timestamptz is not null as is_deleted,
    snapshot_at                                         as ingested_at
from apto{% endif %}
