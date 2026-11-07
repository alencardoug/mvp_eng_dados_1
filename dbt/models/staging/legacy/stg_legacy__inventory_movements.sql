-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.inventory_movements` — camada `staging` (ADR-0016).
--
-- Uma linha por ocorrência física da **captura mais recente**. Reter capturas
-- antigas (ADR-0037) não significa somá-las: o tratamento olha a última, e as
-- anteriores existem para comparação e reprocessamento.
--
-- Duas saídas por coluna: o valor tratado e o **achado**, que é o código da
-- primeira falha que casa. O valor original permanece acessível em
-- `raw_legacy`, que é imutável.

{% if target.type == 'bigquery' %}
WITH captura AS (
  SELECT
    *
  FROM {{ source('legacy', 'inventory_movements') }}
  /* A captura é escolhida **uma vez**, em `legacy_selected_capture`, e não */
  /* aqui. O máximo por tabela parecia equivalente e não é: uma tabela que */
  /* não veio na carga nova cairia para a geração anterior sozinha, e o */
  /* modelo serviria linhas velhas sem que nada dissesse isso. */
  WHERE
    CAST((
      JSON_EXTRACT_SCALAR(_airbyte_meta, '$.sync_id')
    ) AS INT64) = (
      SELECT
        snapshot_id
      FROM {{ ref('legacy_selected_capture') }}
    )
), limpo /* A limpeza vem **antes** dos achados, e não junto: o achado de rejeição */ /* precisa ser conferido contra o valor já convertido, senão uma conversão */ /* bem-sucedida esconde a invalidade do resultado dela. */ /* `materialized`: sem isto o PostgreSQL embute este CTE em **cada** referência */ /* `l."coluna"` do case de achados — a validação de uma data referencia a */ /* coluna limpa dezenas de vezes — e reavalia a limpeza inteira a cada uma. */ /* Medido em 15/09/2026: `carts` 94 s → 8,7 s (D42). O BigQuery não tem a */ /* palavra, e lá o CTE fica como estava. */ AS (
  SELECT
    c.legacy_row_id,
    CASE
      WHEN TRIM(c.`movement_id`) = ''
      OR TRIM(c.`movement_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`movement_id`
    END AS `movement_id`,
    CASE
      WHEN TRIM(c.`idempotency_key`) = ''
      OR TRIM(c.`idempotency_key`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`idempotency_key` LIKE '%;%'
      AND (
        c.`warehouse_id` IS NULL OR TRIM(c.`warehouse_id`) = ''
      )
      AND (
        c.`product_variant_id` IS NULL OR TRIM(c.`product_variant_id`) = ''
      )
      THEN c.`idempotency_key`
      WHEN REGEXP_CONTAINS(c.`idempotency_key`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`idempotency_key`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`idempotency_key`)))
      WHEN REGEXP_CONTAINS(c.`idempotency_key`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`idempotency_key`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`idempotency_key`
      WHEN c.`idempotency_key` <> TRIM(c.`idempotency_key`)
      OR REGEXP_CONTAINS(c.`idempotency_key`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`idempotency_key`), '\\s+', ' ')
      ELSE c.`idempotency_key`
    END AS `idempotency_key`,
    c.`warehouse_id` AS `warehouse_id`,
    c.`product_variant_id` AS `product_variant_id`,
    CASE
      WHEN TRIM(c.`movement_type`) = ''
      OR TRIM(c.`movement_type`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`movement_type`) IN (
        'purchase_receipt',
        'customer_return',
        'transfer_in',
        'adjustment_in',
        'sale_dispatch',
        'supplier_return',
        'transfer_out',
        'adjustment_out'
      )
      THEN c.`movement_type`
      ELSE c.`movement_type`
    END AS `movement_type`,
    CASE
      WHEN TRIM(c.`quantity_delta`) = ''
      OR TRIM(c.`quantity_delta`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(c.`quantity_delta`, '^-?[0-9]+$')
      AND ABS(CAST(c.`quantity_delta` AS NUMERIC)) > 1000000
      THEN c.`quantity_delta`
      WHEN NOT REGEXP_CONTAINS(c.`quantity_delta`, '^-?[0-9]+$')
      AND (
        LOWER(TRIM(c.`quantity_delta`)) IN (
          'um',
          'dois',
          'três',
          'tres',
          'quatro',
          'cinco',
          'seis',
          'sete',
          'oito',
          'nove',
          'dez'
        )
        OR REGEXP_CONTAINS(REPLACE(TRIM(c.`quantity_delta`), ',', '.'), '^-?[0-9]+\\.0+$')
      )
      THEN CASE LOWER(TRIM(c.`quantity_delta`))
        WHEN 'um'
        THEN '1'
        WHEN 'dois'
        THEN '2'
        WHEN 'três'
        THEN '3'
        WHEN 'tres'
        THEN '3'
        WHEN 'quatro'
        THEN '4'
        WHEN 'cinco'
        THEN '5'
        WHEN 'seis'
        THEN '6'
        WHEN 'sete'
        THEN '7'
        WHEN 'oito'
        THEN '8'
        WHEN 'nove'
        THEN '9'
        WHEN 'dez'
        THEN '10'
        ELSE COALESCE(SPLIT(REPLACE(TRIM(c.`quantity_delta`), ',', '.'), '.')[SAFE_ORDINAL(1)], '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`quantity_delta`, '^-?[0-9]+$')
      THEN c.`quantity_delta`
      ELSE c.`quantity_delta`
    END AS `quantity_delta`,
    CASE
      WHEN TRIM(c.`unit_cost`) = ''
      OR TRIM(c.`unit_cost`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', '')), '^-')
      THEN c.`unit_cost`
      WHEN NOT REGEXP_CONTAINS(c.`unit_cost`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`unit_cost`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`unit_cost`
      ELSE c.`unit_cost`
    END AS `unit_cost`,
    CASE
      WHEN TRIM(c.`source_type`) = ''
      OR TRIM(c.`source_type`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`source_type`) IN ('purchase', 'sale', 'return', 'transfer', 'adjustment')
      THEN c.`source_type`
      ELSE c.`source_type`
    END AS `source_type`,
    CASE
      WHEN TRIM(c.`source_id`) = ''
      OR TRIM(c.`source_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`source_id` LIKE '%;%'
      AND (
        c.`correlation_id` IS NULL OR TRIM(c.`correlation_id`) = ''
      )
      AND (
        c.`causation_id` IS NULL OR TRIM(c.`causation_id`) = ''
      )
      THEN c.`source_id`
      WHEN REGEXP_CONTAINS(c.`source_id`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`source_id`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`source_id`)))
      WHEN REGEXP_CONTAINS(c.`source_id`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`source_id`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`source_id`
      WHEN c.`source_id` <> TRIM(c.`source_id`) OR REGEXP_CONTAINS(c.`source_id`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`source_id`), '\\s+', ' ')
      ELSE c.`source_id`
    END AS `source_id`,
    CASE
      WHEN TRIM(c.`correlation_id`) = ''
      OR TRIM(c.`correlation_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`correlation_id`
    END AS `correlation_id`,
    CASE
      WHEN TRIM(c.`causation_id`) = ''
      OR TRIM(c.`causation_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`causation_id`
    END AS `causation_id`,
    CASE
      WHEN TRIM(c.`aggregate_version`) = ''
      OR TRIM(c.`aggregate_version`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`aggregate_version`
    END AS `aggregate_version`,
    CASE
      WHEN TRIM(c.`occurred_at`) = ''
      OR TRIM(c.`occurred_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`occurred_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`occurred_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`occurred_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`occurred_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`occurred_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`occurred_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`occurred_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`occurred_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`occurred_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`occurred_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`occurred_at`
      ELSE c.`occurred_at`
    END AS `occurred_at`,
    CASE
      WHEN TRIM(c.`recorded_at`) = ''
      OR TRIM(c.`recorded_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`recorded_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`recorded_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`recorded_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`recorded_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`recorded_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`recorded_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`recorded_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`recorded_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`recorded_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`recorded_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`recorded_at`
      ELSE c.`recorded_at`
    END AS `recorded_at`,
    CASE
      WHEN TRIM(c.`schema_version`) = ''
      OR TRIM(c.`schema_version`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`schema_version`
    END AS `schema_version`,
    CASE
      WHEN TRIM(c.`metadata`) = ''
      OR TRIM(c.`metadata`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`metadata`
    END AS `metadata`
  FROM captura AS c
)
SELECT
  c.legacy_row_id,
  CAST((
    JSON_EXTRACT_SCALAR(c._airbyte_meta, '$.sync_id')
  ) AS INT64) AS snapshot_id,
  c._airbyte_extracted_at AS snapshot_at,
  'legacy' AS source_system,
  l.`movement_id`, /* ── Valores tratados ───────────────────────────────────────────────────── */
  l.`idempotency_key`,
  l.`warehouse_id`,
  l.`product_variant_id`,
  l.`movement_type`,
  l.`quantity_delta`,
  l.`unit_cost`,
  l.`source_type`,
  l.`source_id`,
  l.`correlation_id`,
  l.`causation_id`,
  l.`aggregate_version`,
  l.`occurred_at`,
  l.`recorded_at`,
  l.`schema_version`,
  l.`metadata`,
  JSON_STRIP_NULLS(
    JSON_OBJECT(
      'movement_id',
      CASE
        WHEN TRIM(c.`movement_id`) = ''
        OR TRIM(c.`movement_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'idempotency_key',
      CASE
        WHEN TRIM(c.`idempotency_key`) = ''
        OR TRIM(c.`idempotency_key`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`idempotency_key` LIKE '%;%'
        AND (
          c.`warehouse_id` IS NULL OR TRIM(c.`warehouse_id`) = ''
        )
        AND (
          c.`product_variant_id` IS NULL OR TRIM(c.`product_variant_id`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`idempotency_key`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`idempotency_key`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`idempotency_key`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`idempotency_key`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`idempotency_key` <> TRIM(c.`idempotency_key`)
        OR REGEXP_CONTAINS(c.`idempotency_key`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'movement_type',
      CASE
        WHEN NOT TRIM(l.`movement_type`) IN (
          'purchase_receipt',
          'customer_return',
          'transfer_in',
          'adjustment_in',
          'sale_dispatch',
          'supplier_return',
          'transfer_out',
          'adjustment_out'
        )
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`movement_type`) = ''
        OR TRIM(c.`movement_type`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`movement_type`) IN (
          'purchase_receipt',
          'customer_return',
          'transfer_in',
          'adjustment_in',
          'sale_dispatch',
          'supplier_return',
          'transfer_out',
          'adjustment_out'
        )
        THEN 'ENUM_UNKNOWN'
      END,
      'quantity_delta',
      CASE
        WHEN REGEXP_CONTAINS(l.`quantity_delta`, '^-?[0-9]+$')
        AND ABS(CAST(l.`quantity_delta` AS NUMERIC)) > 1000000
        THEN 'NUM_OUT_OF_RANGE'
        WHEN NOT REGEXP_CONTAINS(l.`quantity_delta`, '^-?[0-9]+$')
        THEN 'NUM_AMBIGUOUS'
        WHEN TRIM(c.`quantity_delta`) = ''
        OR TRIM(c.`quantity_delta`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(c.`quantity_delta`, '^-?[0-9]+$')
        AND ABS(CAST(c.`quantity_delta` AS NUMERIC)) > 1000000
        THEN 'NUM_OUT_OF_RANGE'
        WHEN NOT REGEXP_CONTAINS(c.`quantity_delta`, '^-?[0-9]+$')
        AND (
          LOWER(TRIM(c.`quantity_delta`)) IN (
            'um',
            'dois',
            'três',
            'tres',
            'quatro',
            'cinco',
            'seis',
            'sete',
            'oito',
            'nove',
            'dez'
          )
          OR REGEXP_CONTAINS(REPLACE(TRIM(c.`quantity_delta`), ',', '.'), '^-?[0-9]+\\.0+$')
        )
        THEN 'NUM_TEXT_EQUIV'
        WHEN NOT REGEXP_CONTAINS(c.`quantity_delta`, '^-?[0-9]+$')
        THEN 'NUM_AMBIGUOUS'
      END,
      'unit_cost',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`unit_cost`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`unit_cost`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`unit_cost`) = ''
        OR TRIM(c.`unit_cost`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`unit_cost`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`unit_cost`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`unit_cost`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`unit_cost`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
      END,
      'source_type',
      CASE
        WHEN NOT TRIM(l.`source_type`) IN ('purchase', 'sale', 'return', 'transfer', 'adjustment')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`source_type`) = ''
        OR TRIM(c.`source_type`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`source_type`) IN ('purchase', 'sale', 'return', 'transfer', 'adjustment')
        THEN 'ENUM_UNKNOWN'
      END,
      'source_id',
      CASE
        WHEN TRIM(c.`source_id`) = ''
        OR TRIM(c.`source_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`source_id` LIKE '%;%'
        AND (
          c.`correlation_id` IS NULL OR TRIM(c.`correlation_id`) = ''
        )
        AND (
          c.`causation_id` IS NULL OR TRIM(c.`causation_id`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`source_id`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`source_id`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`source_id`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`source_id`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`source_id` <> TRIM(c.`source_id`) OR REGEXP_CONTAINS(c.`source_id`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'correlation_id',
      CASE
        WHEN TRIM(c.`correlation_id`) = ''
        OR TRIM(c.`correlation_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'causation_id',
      CASE
        WHEN TRIM(c.`causation_id`) = ''
        OR TRIM(c.`causation_id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'aggregate_version',
      CASE
        WHEN TRIM(c.`aggregate_version`) = ''
        OR TRIM(c.`aggregate_version`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'occurred_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`occurred_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`occurred_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`occurred_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`occurred_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`occurred_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`occurred_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`occurred_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`occurred_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`occurred_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`occurred_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`occurred_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`occurred_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`occurred_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`occurred_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`occurred_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`occurred_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`occurred_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`occurred_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`occurred_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`occurred_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`occurred_at`) = ''
        OR TRIM(c.`occurred_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`occurred_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`occurred_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`occurred_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`occurred_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`occurred_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`occurred_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`occurred_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`occurred_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`occurred_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`occurred_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`occurred_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'recorded_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`recorded_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`recorded_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`recorded_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`recorded_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`recorded_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`recorded_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`recorded_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`recorded_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`recorded_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`recorded_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`recorded_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`recorded_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`recorded_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`recorded_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`recorded_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`recorded_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`recorded_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`recorded_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`recorded_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`recorded_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`recorded_at`) = ''
        OR TRIM(c.`recorded_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`recorded_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`recorded_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`recorded_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`recorded_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`recorded_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`recorded_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`recorded_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`recorded_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`recorded_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`recorded_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`recorded_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'schema_version',
      CASE
        WHEN TRIM(c.`schema_version`) = ''
        OR TRIM(c.`schema_version`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'metadata',
      CASE
        WHEN TRIM(c.`metadata`) = ''
        OR TRIM(c.`metadata`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END
    )
  ) AS achados, /* ── Achados por coluna, sem os nulos ───────────────────────────────────── */
  JSON_OBJECT(
    'movement_id',
    c.`movement_id`,
    'idempotency_key',
    c.`idempotency_key`,
    'warehouse_id',
    c.`warehouse_id`,
    'product_variant_id',
    c.`product_variant_id`,
    'movement_type',
    c.`movement_type`,
    'quantity_delta',
    c.`quantity_delta`,
    'unit_cost',
    c.`unit_cost`,
    'source_type',
    c.`source_type`,
    'source_id',
    c.`source_id`,
    'correlation_id',
    c.`correlation_id`,
    'causation_id',
    c.`causation_id`,
    'aggregate_version',
    c.`aggregate_version`,
    'occurred_at',
    c.`occurred_at`,
    'recorded_at',
    c.`recorded_at`,
    'schema_version',
    c.`schema_version`,
    'metadata',
    c.`metadata`
  ) AS original_payload
FROM captura AS c
JOIN limpo AS l
  ON l.legacy_row_id = c.legacy_row_id
{% else %}with captura as (

    select *
    from {{ source('legacy', 'inventory_movements') }}
    -- A captura é escolhida **uma vez**, em `legacy_selected_capture`, e não
    -- aqui. O máximo por tabela parecia equivalente e não é: uma tabela que
    -- não veio na carga nova cairia para a geração anterior sozinha, e o
    -- modelo serviria linhas velhas sem que nada dissesse isso.
    where (_airbyte_meta->>'sync_id')::bigint = (
        select snapshot_id from {{ ref('legacy_selected_capture') }}
    )

),

-- A limpeza vem **antes** dos achados, e não junto: o achado de rejeição
-- precisa ser conferido contra o valor já convertido, senão uma conversão
-- bem-sucedida esconde a invalidade do resultado dela.
--
-- `materialized`: sem isto o PostgreSQL embute este CTE em **cada** referência
-- `l."coluna"` do case de achados — a validação de uma data referencia a
-- coluna limpa dezenas de vezes — e reavalia a limpeza inteira a cada uma.
-- Medido em 15/09/2026: `carts` 94 s → 8,7 s (D42). O BigQuery não tem a
-- palavra, e lá o CTE fica como estava.
limpo as {{ 'materialized ' if target.type == 'postgres' else '' }}(

    select
        c.legacy_row_id,
        case
            when btrim(c."movement_id") = '' or btrim(c."movement_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."movement_id"
        end as "movement_id",
        case
            when btrim(c."idempotency_key") = '' or btrim(c."idempotency_key") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."idempotency_key" like '%;%' and (c."warehouse_id" is null or btrim(c."warehouse_id") = '') and (c."product_variant_id" is null or btrim(c."product_variant_id") = '') then c."idempotency_key"
            when c."idempotency_key" ~ '(Ã[-¿]|Â[-¿])' and c."idempotency_key" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."idempotency_key", 'LATIN1'), 'UTF8')
            when c."idempotency_key" ~ '(Ã[-¿]|Â[-¿])' and c."idempotency_key" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."idempotency_key"
            when c."idempotency_key" <> btrim(c."idempotency_key") or c."idempotency_key" ~ '  ' then regexp_replace(btrim(c."idempotency_key"), '\s+', ' ', 'g')
            else c."idempotency_key"
        end as "idempotency_key",
        c."warehouse_id" as "warehouse_id",
        c."product_variant_id" as "product_variant_id",
        case
            when btrim(c."movement_type") = '' or btrim(c."movement_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."movement_type") not in ('purchase_receipt', 'customer_return', 'transfer_in', 'adjustment_in', 'sale_dispatch', 'supplier_return', 'transfer_out', 'adjustment_out') then c."movement_type"
            else c."movement_type"
        end as "movement_type",
        case
            when btrim(c."quantity_delta") = '' or btrim(c."quantity_delta") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."quantity_delta" ~ '^-?[0-9]+$' and abs(c."quantity_delta"::numeric) > 1000000 then c."quantity_delta"
            when c."quantity_delta" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity_delta")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity_delta"), ',', '.') ~ '^-?[0-9]+\.0+$') then case lower(btrim(c."quantity_delta")) when 'um' then '1' when 'dois' then '2' when 'três' then '3' when 'tres' then '3' when 'quatro' then '4' when 'cinco' then '5' when 'seis' then '6' when 'sete' then '7' when 'oito' then '8' when 'nove' then '9' when 'dez' then '10' else split_part(replace(btrim(c."quantity_delta"), ',', '.'), '.', 1) end
            when c."quantity_delta" !~ '^-?[0-9]+$' then c."quantity_delta"
            else c."quantity_delta"
        end as "quantity_delta",
        case
            when btrim(c."unit_cost") = '' or btrim(c."unit_cost") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."unit_cost", 'R$', ''), ' ', '')) ~ '^-' then c."unit_cost"
            when c."unit_cost" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), ',', '')) then case when c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), ',', '') end
            when c."unit_cost" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."unit_cost"
            else c."unit_cost"
        end as "unit_cost",
        case
            when btrim(c."source_type") = '' or btrim(c."source_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."source_type") not in ('purchase', 'sale', 'return', 'transfer', 'adjustment') then c."source_type"
            else c."source_type"
        end as "source_type",
        case
            when btrim(c."source_id") = '' or btrim(c."source_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."source_id" like '%;%' and (c."correlation_id" is null or btrim(c."correlation_id") = '') and (c."causation_id" is null or btrim(c."causation_id") = '') then c."source_id"
            when c."source_id" ~ '(Ã[-¿]|Â[-¿])' and c."source_id" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."source_id", 'LATIN1'), 'UTF8')
            when c."source_id" ~ '(Ã[-¿]|Â[-¿])' and c."source_id" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."source_id"
            when c."source_id" <> btrim(c."source_id") or c."source_id" ~ '  ' then regexp_replace(btrim(c."source_id"), '\s+', ' ', 'g')
            else c."source_id"
        end as "source_id",
        case
            when btrim(c."correlation_id") = '' or btrim(c."correlation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."correlation_id"
        end as "correlation_id",
        case
            when btrim(c."causation_id") = '' or btrim(c."causation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."causation_id"
        end as "causation_id",
        case
            when btrim(c."aggregate_version") = '' or btrim(c."aggregate_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."aggregate_version"
        end as "aggregate_version",
        case
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."occurred_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."occurred_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."occurred_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."occurred_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."occurred_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."occurred_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."occurred_at" from 7 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."occurred_at"
            when case when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) then left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."occurred_at"
            when case when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."occurred_at" from 7 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."occurred_at" ~ '^[0-9]{2}/' then to_date(c."occurred_at", 'DD/MM/YYYY')::text else to_date(c."occurred_at", 'YYYY.MM.DD')::text end
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."occurred_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."occurred_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."occurred_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."occurred_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."occurred_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."occurred_at"
            else c."occurred_at"
        end as "occurred_at",
        case
            when btrim(c."recorded_at") = '' or btrim(c."recorded_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."recorded_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."recorded_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."recorded_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."recorded_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."recorded_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."recorded_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) when c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."recorded_at" from 7 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 4 for 2)::int between 1 and 12 and substring(c."recorded_at" from 1 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 1 for 2)::int > 30) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int > 29) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int = 29 and not (substring(c."recorded_at" from 7 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 7 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 7 for 4)::int % 400 = 0)))) when c."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."recorded_at"
            when case when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) then left(c."recorded_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."recorded_at"
            when case when c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."recorded_at" from 7 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 4 for 2)::int between 1 and 12 and substring(c."recorded_at" from 1 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 1 for 2)::int > 30) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int > 29) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int = 29 and not (substring(c."recorded_at" from 7 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 7 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 7 for 4)::int % 400 = 0)))) when c."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."recorded_at" ~ '^[0-9]{2}/' then to_date(c."recorded_at", 'DD/MM/YYYY')::text else to_date(c."recorded_at", 'YYYY.MM.DD')::text end
            when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."recorded_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."recorded_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."recorded_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."recorded_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."recorded_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."recorded_at"
            else c."recorded_at"
        end as "recorded_at",
        case
            when btrim(c."schema_version") = '' or btrim(c."schema_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."schema_version"
        end as "schema_version",
        case
            when btrim(c."metadata") = '' or btrim(c."metadata") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."metadata"
        end as "metadata"
    from captura c

)

select
    c.legacy_row_id,
    (c._airbyte_meta->>'sync_id')::bigint       as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
    l."movement_id",
    l."idempotency_key",
    l."warehouse_id",
    l."product_variant_id",
    l."movement_type",
    l."quantity_delta",
    l."unit_cost",
    l."source_type",
    l."source_id",
    l."correlation_id",
    l."causation_id",
    l."aggregate_version",
    l."occurred_at",
    l."recorded_at",
    l."schema_version",
    l."metadata",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'movement_id', case
            when btrim(c."movement_id") = '' or btrim(c."movement_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'idempotency_key', case
            when btrim(c."idempotency_key") = '' or btrim(c."idempotency_key") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."idempotency_key" like '%;%' and (c."warehouse_id" is null or btrim(c."warehouse_id") = '') and (c."product_variant_id" is null or btrim(c."product_variant_id") = '') then 'TEXT_DELIMITER'
            when c."idempotency_key" ~ '(Ã[-¿]|Â[-¿])' and c."idempotency_key" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."idempotency_key" ~ '(Ã[-¿]|Â[-¿])' and c."idempotency_key" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."idempotency_key" <> btrim(c."idempotency_key") or c."idempotency_key" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'movement_type', case
            when btrim(l."movement_type") not in ('purchase_receipt', 'customer_return', 'transfer_in', 'adjustment_in', 'sale_dispatch', 'supplier_return', 'transfer_out', 'adjustment_out') then 'ENUM_UNKNOWN'
            when btrim(c."movement_type") = '' or btrim(c."movement_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."movement_type") not in ('purchase_receipt', 'customer_return', 'transfer_in', 'adjustment_in', 'sale_dispatch', 'supplier_return', 'transfer_out', 'adjustment_out') then 'ENUM_UNKNOWN'
        end,
            'quantity_delta', case
            when l."quantity_delta" ~ '^-?[0-9]+$' and abs(l."quantity_delta"::numeric) > 1000000 then 'NUM_OUT_OF_RANGE'
            when l."quantity_delta" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
            when btrim(c."quantity_delta") = '' or btrim(c."quantity_delta") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."quantity_delta" ~ '^-?[0-9]+$' and abs(c."quantity_delta"::numeric) > 1000000 then 'NUM_OUT_OF_RANGE'
            when c."quantity_delta" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity_delta")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity_delta"), ',', '.') ~ '^-?[0-9]+\.0+$') then 'NUM_TEXT_EQUIV'
            when c."quantity_delta" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
        end,
            'unit_cost', case
            when btrim(replace(replace(l."unit_cost", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."unit_cost" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."unit_cost") = '' or btrim(c."unit_cost") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."unit_cost", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."unit_cost" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."unit_cost" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."unit_cost" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."unit_cost", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."unit_cost" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'source_type', case
            when btrim(l."source_type") not in ('purchase', 'sale', 'return', 'transfer', 'adjustment') then 'ENUM_UNKNOWN'
            when btrim(c."source_type") = '' or btrim(c."source_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."source_type") not in ('purchase', 'sale', 'return', 'transfer', 'adjustment') then 'ENUM_UNKNOWN'
        end,
            'source_id', case
            when btrim(c."source_id") = '' or btrim(c."source_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."source_id" like '%;%' and (c."correlation_id" is null or btrim(c."correlation_id") = '') and (c."causation_id" is null or btrim(c."causation_id") = '') then 'TEXT_DELIMITER'
            when c."source_id" ~ '(Ã[-¿]|Â[-¿])' and c."source_id" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."source_id" ~ '(Ã[-¿]|Â[-¿])' and c."source_id" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."source_id" <> btrim(c."source_id") or c."source_id" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'correlation_id', case
            when btrim(c."correlation_id") = '' or btrim(c."correlation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'causation_id', case
            when btrim(c."causation_id") = '' or btrim(c."causation_id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'aggregate_version', case
            when btrim(c."aggregate_version") = '' or btrim(c."aggregate_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'occurred_at', case
            when case when l."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(l."occurred_at" from 6 for 2)::int between 1 and 12 and substring(l."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(l."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."occurred_at" from 9 for 2)::int > 30) and not (substring(l."occurred_at" from 6 for 2)::int = 2 and substring(l."occurred_at" from 9 for 2)::int > 29) and not (substring(l."occurred_at" from 6 for 2)::int = 2 and substring(l."occurred_at" from 9 for 2)::int = 29 and not (substring(l."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(l."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(l."occurred_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."occurred_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."occurred_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."occurred_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."occurred_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."occurred_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."occurred_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(l."occurred_at" from 6 for 2)::int between 1 and 12 and substring(l."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(l."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."occurred_at" from 9 for 2)::int > 30) and not (substring(l."occurred_at" from 6 for 2)::int = 2 and substring(l."occurred_at" from 9 for 2)::int > 29) and not (substring(l."occurred_at" from 6 for 2)::int = 2 and substring(l."occurred_at" from 9 for 2)::int = 29 and not (substring(l."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(l."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(l."occurred_at" from 1 for 4)::int % 400 = 0)))) when l."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."occurred_at" from 7 for 4)::int between 1 and 9999 and substring(l."occurred_at" from 4 for 2)::int between 1 and 12 and substring(l."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(l."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."occurred_at" from 1 for 2)::int > 30) and not (substring(l."occurred_at" from 4 for 2)::int = 2 and substring(l."occurred_at" from 1 for 2)::int > 29) and not (substring(l."occurred_at" from 4 for 2)::int = 2 and substring(l."occurred_at" from 1 for 2)::int = 29 and not (substring(l."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(l."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(l."occurred_at" from 7 for 4)::int % 400 = 0)))) when l."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(l."occurred_at" from 6 for 2)::int between 1 and 12 and substring(l."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(l."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."occurred_at" from 9 for 2)::int > 30) and not (substring(l."occurred_at" from 6 for 2)::int = 2 and substring(l."occurred_at" from 9 for 2)::int > 29) and not (substring(l."occurred_at" from 6 for 2)::int = 2 and substring(l."occurred_at" from 9 for 2)::int = 29 and not (substring(l."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(l."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(l."occurred_at" from 1 for 4)::int % 400 = 0)))) then left(l."occurred_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."occurred_at") = '' or btrim(c."occurred_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."occurred_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."occurred_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."occurred_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."occurred_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."occurred_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."occurred_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."occurred_at" from 7 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) then left(c."occurred_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."occurred_at" from 7 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 4 for 2)::int between 1 and 12 and substring(c."occurred_at" from 1 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 1 for 2)::int > 30) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int > 29) and not (substring(c."occurred_at" from 4 for 2)::int = 2 and substring(c."occurred_at" from 1 for 2)::int = 29 and not (substring(c."occurred_at" from 7 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 7 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 7 for 4)::int % 400 = 0)))) when c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."occurred_at" from 1 for 4)::int between 1 and 9999 and substring(c."occurred_at" from 6 for 2)::int between 1 and 12 and substring(c."occurred_at" from 9 for 2)::int between 1 and 31 and not (substring(c."occurred_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."occurred_at" from 9 for 2)::int > 30) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int > 29) and not (substring(c."occurred_at" from 6 for 2)::int = 2 and substring(c."occurred_at" from 9 for 2)::int = 29 and not (substring(c."occurred_at" from 1 for 4)::int % 4 = 0 and (substring(c."occurred_at" from 1 for 4)::int % 100 <> 0 or substring(c."occurred_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."occurred_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."occurred_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."occurred_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."occurred_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."occurred_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."occurred_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."occurred_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."occurred_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'recorded_at', case
            when case when l."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(l."recorded_at" from 6 for 2)::int between 1 and 12 and substring(l."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(l."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."recorded_at" from 9 for 2)::int > 30) and not (substring(l."recorded_at" from 6 for 2)::int = 2 and substring(l."recorded_at" from 9 for 2)::int > 29) and not (substring(l."recorded_at" from 6 for 2)::int = 2 and substring(l."recorded_at" from 9 for 2)::int = 29 and not (substring(l."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(l."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(l."recorded_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."recorded_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."recorded_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."recorded_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."recorded_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."recorded_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."recorded_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(l."recorded_at" from 6 for 2)::int between 1 and 12 and substring(l."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(l."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."recorded_at" from 9 for 2)::int > 30) and not (substring(l."recorded_at" from 6 for 2)::int = 2 and substring(l."recorded_at" from 9 for 2)::int > 29) and not (substring(l."recorded_at" from 6 for 2)::int = 2 and substring(l."recorded_at" from 9 for 2)::int = 29 and not (substring(l."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(l."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(l."recorded_at" from 1 for 4)::int % 400 = 0)))) when l."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."recorded_at" from 7 for 4)::int between 1 and 9999 and substring(l."recorded_at" from 4 for 2)::int between 1 and 12 and substring(l."recorded_at" from 1 for 2)::int between 1 and 31 and not (substring(l."recorded_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."recorded_at" from 1 for 2)::int > 30) and not (substring(l."recorded_at" from 4 for 2)::int = 2 and substring(l."recorded_at" from 1 for 2)::int > 29) and not (substring(l."recorded_at" from 4 for 2)::int = 2 and substring(l."recorded_at" from 1 for 2)::int = 29 and not (substring(l."recorded_at" from 7 for 4)::int % 4 = 0 and (substring(l."recorded_at" from 7 for 4)::int % 100 <> 0 or substring(l."recorded_at" from 7 for 4)::int % 400 = 0)))) when l."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(l."recorded_at" from 6 for 2)::int between 1 and 12 and substring(l."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(l."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."recorded_at" from 9 for 2)::int > 30) and not (substring(l."recorded_at" from 6 for 2)::int = 2 and substring(l."recorded_at" from 9 for 2)::int > 29) and not (substring(l."recorded_at" from 6 for 2)::int = 2 and substring(l."recorded_at" from 9 for 2)::int = 29 and not (substring(l."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(l."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(l."recorded_at" from 1 for 4)::int % 400 = 0)))) then left(l."recorded_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."recorded_at") = '' or btrim(c."recorded_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."recorded_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."recorded_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."recorded_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."recorded_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."recorded_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."recorded_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) when c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."recorded_at" from 7 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 4 for 2)::int between 1 and 12 and substring(c."recorded_at" from 1 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 1 for 2)::int > 30) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int > 29) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int = 29 and not (substring(c."recorded_at" from 7 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 7 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 7 for 4)::int % 400 = 0)))) when c."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) then left(c."recorded_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."recorded_at" from 7 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 4 for 2)::int between 1 and 12 and substring(c."recorded_at" from 1 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 1 for 2)::int > 30) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int > 29) and not (substring(c."recorded_at" from 4 for 2)::int = 2 and substring(c."recorded_at" from 1 for 2)::int = 29 and not (substring(c."recorded_at" from 7 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 7 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 7 for 4)::int % 400 = 0)))) when c."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."recorded_at" from 1 for 4)::int between 1 and 9999 and substring(c."recorded_at" from 6 for 2)::int between 1 and 12 and substring(c."recorded_at" from 9 for 2)::int between 1 and 31 and not (substring(c."recorded_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."recorded_at" from 9 for 2)::int > 30) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int > 29) and not (substring(c."recorded_at" from 6 for 2)::int = 2 and substring(c."recorded_at" from 9 for 2)::int = 29 and not (substring(c."recorded_at" from 1 for 4)::int % 4 = 0 and (substring(c."recorded_at" from 1 for 4)::int % 100 <> 0 or substring(c."recorded_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."recorded_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."recorded_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."recorded_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."recorded_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."recorded_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."recorded_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."recorded_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."recorded_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'schema_version', case
            when btrim(c."schema_version") = '' or btrim(c."schema_version") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'metadata', case
            when btrim(c."metadata") = '' or btrim(c."metadata") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end
        )
    )                                           as achados,
    jsonb_build_object('movement_id', c."movement_id", 'idempotency_key', c."idempotency_key", 'warehouse_id', c."warehouse_id", 'product_variant_id', c."product_variant_id", 'movement_type', c."movement_type", 'quantity_delta', c."quantity_delta", 'unit_cost', c."unit_cost", 'source_type', c."source_type", 'source_id', c."source_id", 'correlation_id', c."correlation_id", 'causation_id', c."causation_id", 'aggregate_version', c."aggregate_version", 'occurred_at', c."occurred_at", 'recorded_at', c."recorded_at", 'schema_version', c."schema_version", 'metadata', c."metadata")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
