-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.stock_reservations` — camada `staging` (ADR-0016).
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
  FROM {{ source('legacy', 'stock_reservations') }}
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
      WHEN TRIM(c.`id`) = '' OR TRIM(c.`id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      ELSE c.`id`
    END AS `id`,
    CASE
      WHEN TRIM(c.`reservation_code`) = ''
      OR TRIM(c.`reservation_code`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`reservation_code` LIKE '%;%'
      AND (
        c.`warehouse_id` IS NULL OR TRIM(c.`warehouse_id`) = ''
      )
      AND (
        c.`product_variant_id` IS NULL OR TRIM(c.`product_variant_id`) = ''
      )
      THEN c.`reservation_code`
      WHEN REGEXP_CONTAINS(c.`reservation_code`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`reservation_code`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`reservation_code`)))
      WHEN REGEXP_CONTAINS(c.`reservation_code`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`reservation_code`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`reservation_code`
      WHEN c.`reservation_code` <> TRIM(c.`reservation_code`)
      OR REGEXP_CONTAINS(c.`reservation_code`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`reservation_code`), '\\s+', ' ')
      ELSE c.`reservation_code`
    END AS `reservation_code`,
    c.`warehouse_id` AS `warehouse_id`,
    c.`product_variant_id` AS `product_variant_id`,
    c.`cart_id` AS `cart_id`,
    c.`order_id` AS `order_id`,
    CASE
      WHEN TRIM(c.`quantity`) = ''
      OR TRIM(c.`quantity`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(c.`quantity`, '^-?[0-9]+$')
      AND (
        CAST(c.`quantity` AS NUMERIC) < 0 OR CAST(c.`quantity` AS NUMERIC) > 1000000
      )
      THEN c.`quantity`
      WHEN NOT REGEXP_CONTAINS(c.`quantity`, '^-?[0-9]+$')
      AND (
        LOWER(TRIM(c.`quantity`)) IN (
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
        OR REGEXP_CONTAINS(REPLACE(TRIM(c.`quantity`), ',', '.'), '^-?[0-9]+\\.0+$')
      )
      THEN CASE LOWER(TRIM(c.`quantity`))
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
        ELSE COALESCE(SPLIT(REPLACE(TRIM(c.`quantity`), ',', '.'), '.')[SAFE_ORDINAL(1)], '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`quantity`, '^-?[0-9]+$')
      THEN c.`quantity`
      ELSE c.`quantity`
    END AS `quantity`,
    CASE
      WHEN TRIM(c.`status`) = ''
      OR TRIM(c.`status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`status`) IN ('active', 'released', 'expired', 'consumed')
      THEN c.`status`
      ELSE c.`status`
    END AS `status`,
    CASE
      WHEN TRIM(c.`expires_at`) = ''
      OR TRIM(c.`expires_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`expires_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`expires_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`expires_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`expires_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`expires_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`expires_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`expires_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`expires_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`expires_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`expires_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`expires_at`
      ELSE c.`expires_at`
    END AS `expires_at`,
    CASE
      WHEN TRIM(c.`released_at`) = ''
      OR TRIM(c.`released_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`released_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`released_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`released_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`released_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`released_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`released_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`released_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`released_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`released_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`released_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`released_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`released_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`released_at`
      ELSE c.`released_at`
    END AS `released_at`,
    CASE
      WHEN TRIM(c.`created_at`) = ''
      OR TRIM(c.`created_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`created_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`created_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`created_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`created_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`created_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`created_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`created_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`created_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`created_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`created_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`created_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`created_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`created_at`
      ELSE c.`created_at`
    END AS `created_at`,
    CASE
      WHEN TRIM(c.`updated_at`) = ''
      OR TRIM(c.`updated_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`updated_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`updated_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`updated_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`updated_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`updated_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`updated_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`updated_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`updated_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`updated_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`updated_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`updated_at`
      ELSE c.`updated_at`
    END AS `updated_at`,
    CASE
      WHEN TRIM(c.`deleted_at`) = ''
      OR TRIM(c.`deleted_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`deleted_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`deleted_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`deleted_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`deleted_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`deleted_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`deleted_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`deleted_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`deleted_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`deleted_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`deleted_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`deleted_at`
      ELSE c.`deleted_at`
    END AS `deleted_at`
  FROM captura AS c
)
SELECT
  c.legacy_row_id,
  CAST((
    JSON_EXTRACT_SCALAR(c._airbyte_meta, '$.sync_id')
  ) AS INT64) AS snapshot_id,
  c._airbyte_extracted_at AS snapshot_at,
  'legacy' AS source_system,
  l.`id`, /* ── Valores tratados ───────────────────────────────────────────────────── */
  l.`reservation_code`,
  l.`warehouse_id`,
  l.`product_variant_id`,
  l.`cart_id`,
  l.`order_id`,
  l.`quantity`,
  l.`status`,
  l.`expires_at`,
  l.`released_at`,
  l.`created_at`,
  l.`updated_at`,
  l.`deleted_at`,
  JSON_STRIP_NULLS(
    JSON_OBJECT(
      'id',
      CASE
        WHEN TRIM(c.`id`) = '' OR TRIM(c.`id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'reservation_code',
      CASE
        WHEN TRIM(c.`reservation_code`) = ''
        OR TRIM(c.`reservation_code`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`reservation_code` LIKE '%;%'
        AND (
          c.`warehouse_id` IS NULL OR TRIM(c.`warehouse_id`) = ''
        )
        AND (
          c.`product_variant_id` IS NULL OR TRIM(c.`product_variant_id`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`reservation_code`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`reservation_code`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`reservation_code`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`reservation_code`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`reservation_code` <> TRIM(c.`reservation_code`)
        OR REGEXP_CONTAINS(c.`reservation_code`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'quantity',
      CASE
        WHEN REGEXP_CONTAINS(l.`quantity`, '^-?[0-9]+$')
        AND (
          CAST(l.`quantity` AS NUMERIC) < 0 OR CAST(l.`quantity` AS NUMERIC) > 1000000
        )
        THEN 'NUM_OUT_OF_RANGE'
        WHEN NOT REGEXP_CONTAINS(l.`quantity`, '^-?[0-9]+$')
        THEN 'NUM_AMBIGUOUS'
        WHEN TRIM(c.`quantity`) = ''
        OR TRIM(c.`quantity`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(c.`quantity`, '^-?[0-9]+$')
        AND (
          CAST(c.`quantity` AS NUMERIC) < 0 OR CAST(c.`quantity` AS NUMERIC) > 1000000
        )
        THEN 'NUM_OUT_OF_RANGE'
        WHEN NOT REGEXP_CONTAINS(c.`quantity`, '^-?[0-9]+$')
        AND (
          LOWER(TRIM(c.`quantity`)) IN (
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
          OR REGEXP_CONTAINS(REPLACE(TRIM(c.`quantity`), ',', '.'), '^-?[0-9]+\\.0+$')
        )
        THEN 'NUM_TEXT_EQUIV'
        WHEN NOT REGEXP_CONTAINS(c.`quantity`, '^-?[0-9]+$')
        THEN 'NUM_AMBIGUOUS'
      END,
      'status',
      CASE
        WHEN NOT TRIM(l.`status`) IN ('active', 'released', 'expired', 'consumed')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`status`) = ''
        OR TRIM(c.`status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`status`) IN ('active', 'released', 'expired', 'consumed')
        THEN 'ENUM_UNKNOWN'
      END,
      'expires_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`expires_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`expires_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`expires_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`expires_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`expires_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`expires_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`expires_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`expires_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`expires_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`expires_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`expires_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`expires_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`expires_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`expires_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`expires_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`expires_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`expires_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`expires_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`expires_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`expires_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`expires_at`) = ''
        OR TRIM(c.`expires_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`expires_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`expires_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`expires_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`expires_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`expires_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`expires_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`expires_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`expires_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`expires_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`expires_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`expires_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'released_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`released_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`released_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`released_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`released_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`released_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`released_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`released_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`released_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`released_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`released_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`released_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`released_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`released_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`released_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`released_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`released_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`released_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`released_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`released_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`released_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`released_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`released_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`released_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`released_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`released_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`released_at`) = ''
        OR TRIM(c.`released_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`released_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`released_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`released_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`released_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`released_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`released_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`released_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`released_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`released_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`released_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`released_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`released_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`released_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`released_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'created_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`created_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`created_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`created_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`created_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`created_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`created_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`created_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`created_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`created_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`created_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`created_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`created_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`created_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`created_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`created_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`created_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`created_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`created_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`created_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`created_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`created_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`created_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`created_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`created_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`created_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`created_at`) = ''
        OR TRIM(c.`created_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`created_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`created_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`created_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`created_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`created_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`created_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`created_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`created_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`created_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`created_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`created_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`created_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`created_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`created_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'updated_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`updated_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`updated_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`updated_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`updated_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`updated_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`updated_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`updated_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`updated_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`updated_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`updated_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`updated_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`updated_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`updated_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`updated_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`updated_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`updated_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`updated_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`updated_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`updated_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`updated_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`updated_at`) = ''
        OR TRIM(c.`updated_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`updated_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`updated_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`updated_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`updated_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`updated_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`updated_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`updated_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`updated_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`updated_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`updated_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`updated_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'deleted_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`deleted_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`deleted_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`deleted_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`deleted_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`deleted_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`deleted_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`deleted_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`deleted_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`deleted_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`deleted_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`deleted_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`deleted_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`deleted_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`deleted_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`deleted_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`deleted_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`deleted_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`deleted_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`deleted_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`deleted_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`deleted_at`) = ''
        OR TRIM(c.`deleted_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`deleted_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`deleted_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`deleted_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`deleted_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`deleted_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`deleted_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`deleted_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`deleted_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`deleted_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`deleted_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`deleted_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END
    )
  ) AS achados, /* ── Achados por coluna, sem os nulos ───────────────────────────────────── */
  JSON_OBJECT(
    'id',
    c.`id`,
    'reservation_code',
    c.`reservation_code`,
    'warehouse_id',
    c.`warehouse_id`,
    'product_variant_id',
    c.`product_variant_id`,
    'cart_id',
    c.`cart_id`,
    'order_id',
    c.`order_id`,
    'quantity',
    c.`quantity`,
    'status',
    c.`status`,
    'expires_at',
    c.`expires_at`,
    'released_at',
    c.`released_at`,
    'created_at',
    c.`created_at`,
    'updated_at',
    c.`updated_at`,
    'deleted_at',
    c.`deleted_at`
  ) AS original_payload
FROM captura AS c
JOIN limpo AS l
  ON l.legacy_row_id = c.legacy_row_id
{% else %}with captura as (

    select *
    from {{ source('legacy', 'stock_reservations') }}
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
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            else c."id"
        end as "id",
        case
            when btrim(c."reservation_code") = '' or btrim(c."reservation_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."reservation_code" like '%;%' and (c."warehouse_id" is null or btrim(c."warehouse_id") = '') and (c."product_variant_id" is null or btrim(c."product_variant_id") = '') then c."reservation_code"
            when c."reservation_code" ~ '(Ã[-¿]|Â[-¿])' and c."reservation_code" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."reservation_code", 'LATIN1'), 'UTF8')
            when c."reservation_code" ~ '(Ã[-¿]|Â[-¿])' and c."reservation_code" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."reservation_code"
            when c."reservation_code" <> btrim(c."reservation_code") or c."reservation_code" ~ '  ' then regexp_replace(btrim(c."reservation_code"), '\s+', ' ', 'g')
            else c."reservation_code"
        end as "reservation_code",
        c."warehouse_id" as "warehouse_id",
        c."product_variant_id" as "product_variant_id",
        c."cart_id" as "cart_id",
        c."order_id" as "order_id",
        case
            when btrim(c."quantity") = '' or btrim(c."quantity") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."quantity" ~ '^-?[0-9]+$' and (c."quantity"::numeric < 0 or c."quantity"::numeric > 1000000) then c."quantity"
            when c."quantity" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity"), ',', '.') ~ '^-?[0-9]+\.0+$') then case lower(btrim(c."quantity")) when 'um' then '1' when 'dois' then '2' when 'três' then '3' when 'tres' then '3' when 'quatro' then '4' when 'cinco' then '5' when 'seis' then '6' when 'sete' then '7' when 'oito' then '8' when 'nove' then '9' when 'dez' then '10' else split_part(replace(btrim(c."quantity"), ',', '.'), '.', 1) end
            when c."quantity" !~ '^-?[0-9]+$' then c."quantity"
            else c."quantity"
        end as "quantity",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."status") not in ('active', 'released', 'expired', 'consumed') then c."status"
            else c."status"
        end as "status",
        case
            when btrim(c."expires_at") = '' or btrim(c."expires_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."expires_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."expires_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."expires_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."expires_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."expires_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."expires_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) when c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."expires_at" from 7 for 4)::int between 1 and 9999 and substring(c."expires_at" from 4 for 2)::int between 1 and 12 and substring(c."expires_at" from 1 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 1 for 2)::int > 30) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int > 29) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int = 29 and not (substring(c."expires_at" from 7 for 4)::int % 4 = 0 and (substring(c."expires_at" from 7 for 4)::int % 100 <> 0 or substring(c."expires_at" from 7 for 4)::int % 400 = 0)))) when c."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."expires_at"
            when case when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) then left(c."expires_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."expires_at"
            when case when c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."expires_at" from 7 for 4)::int between 1 and 9999 and substring(c."expires_at" from 4 for 2)::int between 1 and 12 and substring(c."expires_at" from 1 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 1 for 2)::int > 30) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int > 29) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int = 29 and not (substring(c."expires_at" from 7 for 4)::int % 4 = 0 and (substring(c."expires_at" from 7 for 4)::int % 100 <> 0 or substring(c."expires_at" from 7 for 4)::int % 400 = 0)))) when c."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."expires_at" ~ '^[0-9]{2}/' then to_date(c."expires_at", 'DD/MM/YYYY')::text else to_date(c."expires_at", 'YYYY.MM.DD')::text end
            when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."expires_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."expires_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."expires_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."expires_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."expires_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."expires_at"
            else c."expires_at"
        end as "expires_at",
        case
            when btrim(c."released_at") = '' or btrim(c."released_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."released_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."released_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."released_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."released_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."released_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."released_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) when c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."released_at" from 7 for 4)::int between 1 and 9999 and substring(c."released_at" from 4 for 2)::int between 1 and 12 and substring(c."released_at" from 1 for 2)::int between 1 and 31 and not (substring(c."released_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 1 for 2)::int > 30) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int > 29) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int = 29 and not (substring(c."released_at" from 7 for 4)::int % 4 = 0 and (substring(c."released_at" from 7 for 4)::int % 100 <> 0 or substring(c."released_at" from 7 for 4)::int % 400 = 0)))) when c."released_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."released_at"
            when case when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) then left(c."released_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."released_at"
            when case when c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."released_at" from 7 for 4)::int between 1 and 9999 and substring(c."released_at" from 4 for 2)::int between 1 and 12 and substring(c."released_at" from 1 for 2)::int between 1 and 31 and not (substring(c."released_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 1 for 2)::int > 30) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int > 29) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int = 29 and not (substring(c."released_at" from 7 for 4)::int % 4 = 0 and (substring(c."released_at" from 7 for 4)::int % 100 <> 0 or substring(c."released_at" from 7 for 4)::int % 400 = 0)))) when c."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."released_at" ~ '^[0-9]{2}/' then to_date(c."released_at", 'DD/MM/YYYY')::text else to_date(c."released_at", 'YYYY.MM.DD')::text end
            when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."released_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."released_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."released_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."released_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."released_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."released_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."released_at"
            else c."released_at"
        end as "released_at",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."created_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."created_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 7 for 4)::int between 1 and 9999 and substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 7 for 4)::int between 1 and 9999 and substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."created_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."created_at"
            else c."created_at"
        end as "created_at",
        case
            when btrim(c."updated_at") = '' or btrim(c."updated_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."updated_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."updated_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."updated_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."updated_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."updated_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."updated_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) when c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."updated_at" from 7 for 4)::int between 1 and 9999 and substring(c."updated_at" from 4 for 2)::int between 1 and 12 and substring(c."updated_at" from 1 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 1 for 2)::int > 30) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int > 29) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int = 29 and not (substring(c."updated_at" from 7 for 4)::int % 4 = 0 and (substring(c."updated_at" from 7 for 4)::int % 100 <> 0 or substring(c."updated_at" from 7 for 4)::int % 400 = 0)))) when c."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."updated_at"
            when case when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) then left(c."updated_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."updated_at"
            when case when c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."updated_at" from 7 for 4)::int between 1 and 9999 and substring(c."updated_at" from 4 for 2)::int between 1 and 12 and substring(c."updated_at" from 1 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 1 for 2)::int > 30) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int > 29) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int = 29 and not (substring(c."updated_at" from 7 for 4)::int % 4 = 0 and (substring(c."updated_at" from 7 for 4)::int % 100 <> 0 or substring(c."updated_at" from 7 for 4)::int % 400 = 0)))) when c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."updated_at" ~ '^[0-9]{2}/' then to_date(c."updated_at", 'DD/MM/YYYY')::text else to_date(c."updated_at", 'YYYY.MM.DD')::text end
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."updated_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."updated_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."updated_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."updated_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."updated_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."updated_at"
            else c."updated_at"
        end as "updated_at",
        case
            when btrim(c."deleted_at") = '' or btrim(c."deleted_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."deleted_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."deleted_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."deleted_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."deleted_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."deleted_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."deleted_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) when c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."deleted_at" from 7 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 4 for 2)::int between 1 and 12 and substring(c."deleted_at" from 1 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 1 for 2)::int > 30) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int > 29) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int = 29 and not (substring(c."deleted_at" from 7 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 7 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 7 for 4)::int % 400 = 0)))) when c."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."deleted_at"
            when case when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) then left(c."deleted_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."deleted_at"
            when case when c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."deleted_at" from 7 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 4 for 2)::int between 1 and 12 and substring(c."deleted_at" from 1 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 1 for 2)::int > 30) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int > 29) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int = 29 and not (substring(c."deleted_at" from 7 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 7 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 7 for 4)::int % 400 = 0)))) when c."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."deleted_at" ~ '^[0-9]{2}/' then to_date(c."deleted_at", 'DD/MM/YYYY')::text else to_date(c."deleted_at", 'YYYY.MM.DD')::text end
            when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."deleted_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."deleted_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."deleted_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."deleted_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."deleted_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."deleted_at"
            else c."deleted_at"
        end as "deleted_at"
    from captura c

)

select
    c.legacy_row_id,
    (c._airbyte_meta->>'sync_id')::bigint       as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
    l."id",
    l."reservation_code",
    l."warehouse_id",
    l."product_variant_id",
    l."cart_id",
    l."order_id",
    l."quantity",
    l."status",
    l."expires_at",
    l."released_at",
    l."created_at",
    l."updated_at",
    l."deleted_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'reservation_code', case
            when btrim(c."reservation_code") = '' or btrim(c."reservation_code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."reservation_code" like '%;%' and (c."warehouse_id" is null or btrim(c."warehouse_id") = '') and (c."product_variant_id" is null or btrim(c."product_variant_id") = '') then 'TEXT_DELIMITER'
            when c."reservation_code" ~ '(Ã[-¿]|Â[-¿])' and c."reservation_code" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."reservation_code" ~ '(Ã[-¿]|Â[-¿])' and c."reservation_code" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."reservation_code" <> btrim(c."reservation_code") or c."reservation_code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'quantity', case
            when l."quantity" ~ '^-?[0-9]+$' and (l."quantity"::numeric < 0 or l."quantity"::numeric > 1000000) then 'NUM_OUT_OF_RANGE'
            when l."quantity" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
            when btrim(c."quantity") = '' or btrim(c."quantity") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."quantity" ~ '^-?[0-9]+$' and (c."quantity"::numeric < 0 or c."quantity"::numeric > 1000000) then 'NUM_OUT_OF_RANGE'
            when c."quantity" !~ '^-?[0-9]+$' and (  lower(btrim(c."quantity")) in ('um','dois','três','tres','quatro','cinco','seis','sete','oito','nove','dez')  or replace(btrim(c."quantity"), ',', '.') ~ '^-?[0-9]+\.0+$') then 'NUM_TEXT_EQUIV'
            when c."quantity" !~ '^-?[0-9]+$' then 'NUM_AMBIGUOUS'
        end,
            'status', case
            when btrim(l."status") not in ('active', 'released', 'expired', 'consumed') then 'ENUM_UNKNOWN'
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('active', 'released', 'expired', 'consumed') then 'ENUM_UNKNOWN'
        end,
            'expires_at', case
            when case when l."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."expires_at" from 1 for 4)::int between 1 and 9999 and substring(l."expires_at" from 6 for 2)::int between 1 and 12 and substring(l."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(l."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."expires_at" from 9 for 2)::int > 30) and not (substring(l."expires_at" from 6 for 2)::int = 2 and substring(l."expires_at" from 9 for 2)::int > 29) and not (substring(l."expires_at" from 6 for 2)::int = 2 and substring(l."expires_at" from 9 for 2)::int = 29 and not (substring(l."expires_at" from 1 for 4)::int % 4 = 0 and (substring(l."expires_at" from 1 for 4)::int % 100 <> 0 or substring(l."expires_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."expires_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."expires_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."expires_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."expires_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."expires_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."expires_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."expires_at" from 1 for 4)::int between 1 and 9999 and substring(l."expires_at" from 6 for 2)::int between 1 and 12 and substring(l."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(l."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."expires_at" from 9 for 2)::int > 30) and not (substring(l."expires_at" from 6 for 2)::int = 2 and substring(l."expires_at" from 9 for 2)::int > 29) and not (substring(l."expires_at" from 6 for 2)::int = 2 and substring(l."expires_at" from 9 for 2)::int = 29 and not (substring(l."expires_at" from 1 for 4)::int % 4 = 0 and (substring(l."expires_at" from 1 for 4)::int % 100 <> 0 or substring(l."expires_at" from 1 for 4)::int % 400 = 0)))) when l."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."expires_at" from 7 for 4)::int between 1 and 9999 and substring(l."expires_at" from 4 for 2)::int between 1 and 12 and substring(l."expires_at" from 1 for 2)::int between 1 and 31 and not (substring(l."expires_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."expires_at" from 1 for 2)::int > 30) and not (substring(l."expires_at" from 4 for 2)::int = 2 and substring(l."expires_at" from 1 for 2)::int > 29) and not (substring(l."expires_at" from 4 for 2)::int = 2 and substring(l."expires_at" from 1 for 2)::int = 29 and not (substring(l."expires_at" from 7 for 4)::int % 4 = 0 and (substring(l."expires_at" from 7 for 4)::int % 100 <> 0 or substring(l."expires_at" from 7 for 4)::int % 400 = 0)))) when l."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."expires_at" from 1 for 4)::int between 1 and 9999 and substring(l."expires_at" from 6 for 2)::int between 1 and 12 and substring(l."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(l."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."expires_at" from 9 for 2)::int > 30) and not (substring(l."expires_at" from 6 for 2)::int = 2 and substring(l."expires_at" from 9 for 2)::int > 29) and not (substring(l."expires_at" from 6 for 2)::int = 2 and substring(l."expires_at" from 9 for 2)::int = 29 and not (substring(l."expires_at" from 1 for 4)::int % 4 = 0 and (substring(l."expires_at" from 1 for 4)::int % 100 <> 0 or substring(l."expires_at" from 1 for 4)::int % 400 = 0)))) then left(l."expires_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."expires_at") = '' or btrim(c."expires_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."expires_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."expires_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."expires_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."expires_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."expires_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."expires_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) when c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."expires_at" from 7 for 4)::int between 1 and 9999 and substring(c."expires_at" from 4 for 2)::int between 1 and 12 and substring(c."expires_at" from 1 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 1 for 2)::int > 30) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int > 29) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int = 29 and not (substring(c."expires_at" from 7 for 4)::int % 4 = 0 and (substring(c."expires_at" from 7 for 4)::int % 100 <> 0 or substring(c."expires_at" from 7 for 4)::int % 400 = 0)))) when c."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) then left(c."expires_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."expires_at" from 7 for 4)::int between 1 and 9999 and substring(c."expires_at" from 4 for 2)::int between 1 and 12 and substring(c."expires_at" from 1 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 1 for 2)::int > 30) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int > 29) and not (substring(c."expires_at" from 4 for 2)::int = 2 and substring(c."expires_at" from 1 for 2)::int = 29 and not (substring(c."expires_at" from 7 for 4)::int % 4 = 0 and (substring(c."expires_at" from 7 for 4)::int % 100 <> 0 or substring(c."expires_at" from 7 for 4)::int % 400 = 0)))) when c."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."expires_at" from 1 for 4)::int between 1 and 9999 and substring(c."expires_at" from 6 for 2)::int between 1 and 12 and substring(c."expires_at" from 9 for 2)::int between 1 and 31 and not (substring(c."expires_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."expires_at" from 9 for 2)::int > 30) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int > 29) and not (substring(c."expires_at" from 6 for 2)::int = 2 and substring(c."expires_at" from 9 for 2)::int = 29 and not (substring(c."expires_at" from 1 for 4)::int % 4 = 0 and (substring(c."expires_at" from 1 for 4)::int % 100 <> 0 or substring(c."expires_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."expires_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."expires_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."expires_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."expires_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."expires_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."expires_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."expires_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."expires_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'released_at', case
            when case when l."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."released_at" from 1 for 4)::int between 1 and 9999 and substring(l."released_at" from 6 for 2)::int between 1 and 12 and substring(l."released_at" from 9 for 2)::int between 1 and 31 and not (substring(l."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."released_at" from 9 for 2)::int > 30) and not (substring(l."released_at" from 6 for 2)::int = 2 and substring(l."released_at" from 9 for 2)::int > 29) and not (substring(l."released_at" from 6 for 2)::int = 2 and substring(l."released_at" from 9 for 2)::int = 29 and not (substring(l."released_at" from 1 for 4)::int % 4 = 0 and (substring(l."released_at" from 1 for 4)::int % 100 <> 0 or substring(l."released_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."released_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."released_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."released_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."released_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."released_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."released_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."released_at" from 1 for 4)::int between 1 and 9999 and substring(l."released_at" from 6 for 2)::int between 1 and 12 and substring(l."released_at" from 9 for 2)::int between 1 and 31 and not (substring(l."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."released_at" from 9 for 2)::int > 30) and not (substring(l."released_at" from 6 for 2)::int = 2 and substring(l."released_at" from 9 for 2)::int > 29) and not (substring(l."released_at" from 6 for 2)::int = 2 and substring(l."released_at" from 9 for 2)::int = 29 and not (substring(l."released_at" from 1 for 4)::int % 4 = 0 and (substring(l."released_at" from 1 for 4)::int % 100 <> 0 or substring(l."released_at" from 1 for 4)::int % 400 = 0)))) when l."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."released_at" from 7 for 4)::int between 1 and 9999 and substring(l."released_at" from 4 for 2)::int between 1 and 12 and substring(l."released_at" from 1 for 2)::int between 1 and 31 and not (substring(l."released_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."released_at" from 1 for 2)::int > 30) and not (substring(l."released_at" from 4 for 2)::int = 2 and substring(l."released_at" from 1 for 2)::int > 29) and not (substring(l."released_at" from 4 for 2)::int = 2 and substring(l."released_at" from 1 for 2)::int = 29 and not (substring(l."released_at" from 7 for 4)::int % 4 = 0 and (substring(l."released_at" from 7 for 4)::int % 100 <> 0 or substring(l."released_at" from 7 for 4)::int % 400 = 0)))) when l."released_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."released_at" from 1 for 4)::int between 1 and 9999 and substring(l."released_at" from 6 for 2)::int between 1 and 12 and substring(l."released_at" from 9 for 2)::int between 1 and 31 and not (substring(l."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."released_at" from 9 for 2)::int > 30) and not (substring(l."released_at" from 6 for 2)::int = 2 and substring(l."released_at" from 9 for 2)::int > 29) and not (substring(l."released_at" from 6 for 2)::int = 2 and substring(l."released_at" from 9 for 2)::int = 29 and not (substring(l."released_at" from 1 for 4)::int % 4 = 0 and (substring(l."released_at" from 1 for 4)::int % 100 <> 0 or substring(l."released_at" from 1 for 4)::int % 400 = 0)))) then left(l."released_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."released_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."released_at") = '' or btrim(c."released_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."released_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."released_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."released_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."released_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."released_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."released_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) when c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."released_at" from 7 for 4)::int between 1 and 9999 and substring(c."released_at" from 4 for 2)::int between 1 and 12 and substring(c."released_at" from 1 for 2)::int between 1 and 31 and not (substring(c."released_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 1 for 2)::int > 30) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int > 29) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int = 29 and not (substring(c."released_at" from 7 for 4)::int % 4 = 0 and (substring(c."released_at" from 7 for 4)::int % 100 <> 0 or substring(c."released_at" from 7 for 4)::int % 400 = 0)))) when c."released_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) then left(c."released_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."released_at" from 7 for 4)::int between 1 and 9999 and substring(c."released_at" from 4 for 2)::int between 1 and 12 and substring(c."released_at" from 1 for 2)::int between 1 and 31 and not (substring(c."released_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 1 for 2)::int > 30) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int > 29) and not (substring(c."released_at" from 4 for 2)::int = 2 and substring(c."released_at" from 1 for 2)::int = 29 and not (substring(c."released_at" from 7 for 4)::int % 4 = 0 and (substring(c."released_at" from 7 for 4)::int % 100 <> 0 or substring(c."released_at" from 7 for 4)::int % 400 = 0)))) when c."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."released_at" from 1 for 4)::int between 1 and 9999 and substring(c."released_at" from 6 for 2)::int between 1 and 12 and substring(c."released_at" from 9 for 2)::int between 1 and 31 and not (substring(c."released_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."released_at" from 9 for 2)::int > 30) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int > 29) and not (substring(c."released_at" from 6 for 2)::int = 2 and substring(c."released_at" from 9 for 2)::int = 29 and not (substring(c."released_at" from 1 for 4)::int % 4 = 0 and (substring(c."released_at" from 1 for 4)::int % 100 <> 0 or substring(c."released_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."released_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."released_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."released_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."released_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."released_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."released_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."released_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."released_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'created_at', case
            when case when l."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."created_at" from 1 for 4)::int between 1 and 9999 and substring(l."created_at" from 6 for 2)::int between 1 and 12 and substring(l."created_at" from 9 for 2)::int between 1 and 31 and not (substring(l."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."created_at" from 9 for 2)::int > 30) and not (substring(l."created_at" from 6 for 2)::int = 2 and substring(l."created_at" from 9 for 2)::int > 29) and not (substring(l."created_at" from 6 for 2)::int = 2 and substring(l."created_at" from 9 for 2)::int = 29 and not (substring(l."created_at" from 1 for 4)::int % 4 = 0 and (substring(l."created_at" from 1 for 4)::int % 100 <> 0 or substring(l."created_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."created_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."created_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."created_at" from 1 for 4)::int between 1 and 9999 and substring(l."created_at" from 6 for 2)::int between 1 and 12 and substring(l."created_at" from 9 for 2)::int between 1 and 31 and not (substring(l."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."created_at" from 9 for 2)::int > 30) and not (substring(l."created_at" from 6 for 2)::int = 2 and substring(l."created_at" from 9 for 2)::int > 29) and not (substring(l."created_at" from 6 for 2)::int = 2 and substring(l."created_at" from 9 for 2)::int = 29 and not (substring(l."created_at" from 1 for 4)::int % 4 = 0 and (substring(l."created_at" from 1 for 4)::int % 100 <> 0 or substring(l."created_at" from 1 for 4)::int % 400 = 0)))) when l."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."created_at" from 7 for 4)::int between 1 and 9999 and substring(l."created_at" from 4 for 2)::int between 1 and 12 and substring(l."created_at" from 1 for 2)::int between 1 and 31 and not (substring(l."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."created_at" from 1 for 2)::int > 30) and not (substring(l."created_at" from 4 for 2)::int = 2 and substring(l."created_at" from 1 for 2)::int > 29) and not (substring(l."created_at" from 4 for 2)::int = 2 and substring(l."created_at" from 1 for 2)::int = 29 and not (substring(l."created_at" from 7 for 4)::int % 4 = 0 and (substring(l."created_at" from 7 for 4)::int % 100 <> 0 or substring(l."created_at" from 7 for 4)::int % 400 = 0)))) when l."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."created_at" from 1 for 4)::int between 1 and 9999 and substring(l."created_at" from 6 for 2)::int between 1 and 12 and substring(l."created_at" from 9 for 2)::int between 1 and 31 and not (substring(l."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."created_at" from 9 for 2)::int > 30) and not (substring(l."created_at" from 6 for 2)::int = 2 and substring(l."created_at" from 9 for 2)::int > 29) and not (substring(l."created_at" from 6 for 2)::int = 2 and substring(l."created_at" from 9 for 2)::int = 29 and not (substring(l."created_at" from 1 for 4)::int % 4 = 0 and (substring(l."created_at" from 1 for 4)::int % 100 <> 0 or substring(l."created_at" from 1 for 4)::int % 400 = 0)))) then left(l."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."created_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."created_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 7 for 4)::int between 1 and 9999 and substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 7 for 4)::int between 1 and 9999 and substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."created_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'updated_at', case
            when case when l."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."updated_at" from 1 for 4)::int between 1 and 9999 and substring(l."updated_at" from 6 for 2)::int between 1 and 12 and substring(l."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(l."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."updated_at" from 9 for 2)::int > 30) and not (substring(l."updated_at" from 6 for 2)::int = 2 and substring(l."updated_at" from 9 for 2)::int > 29) and not (substring(l."updated_at" from 6 for 2)::int = 2 and substring(l."updated_at" from 9 for 2)::int = 29 and not (substring(l."updated_at" from 1 for 4)::int % 4 = 0 and (substring(l."updated_at" from 1 for 4)::int % 100 <> 0 or substring(l."updated_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."updated_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."updated_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."updated_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."updated_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."updated_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."updated_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."updated_at" from 1 for 4)::int between 1 and 9999 and substring(l."updated_at" from 6 for 2)::int between 1 and 12 and substring(l."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(l."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."updated_at" from 9 for 2)::int > 30) and not (substring(l."updated_at" from 6 for 2)::int = 2 and substring(l."updated_at" from 9 for 2)::int > 29) and not (substring(l."updated_at" from 6 for 2)::int = 2 and substring(l."updated_at" from 9 for 2)::int = 29 and not (substring(l."updated_at" from 1 for 4)::int % 4 = 0 and (substring(l."updated_at" from 1 for 4)::int % 100 <> 0 or substring(l."updated_at" from 1 for 4)::int % 400 = 0)))) when l."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."updated_at" from 7 for 4)::int between 1 and 9999 and substring(l."updated_at" from 4 for 2)::int between 1 and 12 and substring(l."updated_at" from 1 for 2)::int between 1 and 31 and not (substring(l."updated_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."updated_at" from 1 for 2)::int > 30) and not (substring(l."updated_at" from 4 for 2)::int = 2 and substring(l."updated_at" from 1 for 2)::int > 29) and not (substring(l."updated_at" from 4 for 2)::int = 2 and substring(l."updated_at" from 1 for 2)::int = 29 and not (substring(l."updated_at" from 7 for 4)::int % 4 = 0 and (substring(l."updated_at" from 7 for 4)::int % 100 <> 0 or substring(l."updated_at" from 7 for 4)::int % 400 = 0)))) when l."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."updated_at" from 1 for 4)::int between 1 and 9999 and substring(l."updated_at" from 6 for 2)::int between 1 and 12 and substring(l."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(l."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."updated_at" from 9 for 2)::int > 30) and not (substring(l."updated_at" from 6 for 2)::int = 2 and substring(l."updated_at" from 9 for 2)::int > 29) and not (substring(l."updated_at" from 6 for 2)::int = 2 and substring(l."updated_at" from 9 for 2)::int = 29 and not (substring(l."updated_at" from 1 for 4)::int % 4 = 0 and (substring(l."updated_at" from 1 for 4)::int % 100 <> 0 or substring(l."updated_at" from 1 for 4)::int % 400 = 0)))) then left(l."updated_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."updated_at") = '' or btrim(c."updated_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."updated_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."updated_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."updated_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."updated_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."updated_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."updated_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) when c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."updated_at" from 7 for 4)::int between 1 and 9999 and substring(c."updated_at" from 4 for 2)::int between 1 and 12 and substring(c."updated_at" from 1 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 1 for 2)::int > 30) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int > 29) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int = 29 and not (substring(c."updated_at" from 7 for 4)::int % 4 = 0 and (substring(c."updated_at" from 7 for 4)::int % 100 <> 0 or substring(c."updated_at" from 7 for 4)::int % 400 = 0)))) when c."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) then left(c."updated_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."updated_at" from 7 for 4)::int between 1 and 9999 and substring(c."updated_at" from 4 for 2)::int between 1 and 12 and substring(c."updated_at" from 1 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 1 for 2)::int > 30) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int > 29) and not (substring(c."updated_at" from 4 for 2)::int = 2 and substring(c."updated_at" from 1 for 2)::int = 29 and not (substring(c."updated_at" from 7 for 4)::int % 4 = 0 and (substring(c."updated_at" from 7 for 4)::int % 100 <> 0 or substring(c."updated_at" from 7 for 4)::int % 400 = 0)))) when c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."updated_at" from 1 for 4)::int between 1 and 9999 and substring(c."updated_at" from 6 for 2)::int between 1 and 12 and substring(c."updated_at" from 9 for 2)::int between 1 and 31 and not (substring(c."updated_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."updated_at" from 9 for 2)::int > 30) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int > 29) and not (substring(c."updated_at" from 6 for 2)::int = 2 and substring(c."updated_at" from 9 for 2)::int = 29 and not (substring(c."updated_at" from 1 for 4)::int % 4 = 0 and (substring(c."updated_at" from 1 for 4)::int % 100 <> 0 or substring(c."updated_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."updated_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."updated_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."updated_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."updated_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."updated_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."updated_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."updated_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."updated_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'deleted_at', case
            when case when l."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(l."deleted_at" from 6 for 2)::int between 1 and 12 and substring(l."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(l."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."deleted_at" from 9 for 2)::int > 30) and not (substring(l."deleted_at" from 6 for 2)::int = 2 and substring(l."deleted_at" from 9 for 2)::int > 29) and not (substring(l."deleted_at" from 6 for 2)::int = 2 and substring(l."deleted_at" from 9 for 2)::int = 29 and not (substring(l."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(l."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(l."deleted_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."deleted_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."deleted_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."deleted_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."deleted_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."deleted_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."deleted_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(l."deleted_at" from 6 for 2)::int between 1 and 12 and substring(l."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(l."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."deleted_at" from 9 for 2)::int > 30) and not (substring(l."deleted_at" from 6 for 2)::int = 2 and substring(l."deleted_at" from 9 for 2)::int > 29) and not (substring(l."deleted_at" from 6 for 2)::int = 2 and substring(l."deleted_at" from 9 for 2)::int = 29 and not (substring(l."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(l."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(l."deleted_at" from 1 for 4)::int % 400 = 0)))) when l."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."deleted_at" from 7 for 4)::int between 1 and 9999 and substring(l."deleted_at" from 4 for 2)::int between 1 and 12 and substring(l."deleted_at" from 1 for 2)::int between 1 and 31 and not (substring(l."deleted_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."deleted_at" from 1 for 2)::int > 30) and not (substring(l."deleted_at" from 4 for 2)::int = 2 and substring(l."deleted_at" from 1 for 2)::int > 29) and not (substring(l."deleted_at" from 4 for 2)::int = 2 and substring(l."deleted_at" from 1 for 2)::int = 29 and not (substring(l."deleted_at" from 7 for 4)::int % 4 = 0 and (substring(l."deleted_at" from 7 for 4)::int % 100 <> 0 or substring(l."deleted_at" from 7 for 4)::int % 400 = 0)))) when l."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(l."deleted_at" from 6 for 2)::int between 1 and 12 and substring(l."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(l."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."deleted_at" from 9 for 2)::int > 30) and not (substring(l."deleted_at" from 6 for 2)::int = 2 and substring(l."deleted_at" from 9 for 2)::int > 29) and not (substring(l."deleted_at" from 6 for 2)::int = 2 and substring(l."deleted_at" from 9 for 2)::int = 29 and not (substring(l."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(l."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(l."deleted_at" from 1 for 4)::int % 400 = 0)))) then left(l."deleted_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."deleted_at") = '' or btrim(c."deleted_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."deleted_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."deleted_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."deleted_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."deleted_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."deleted_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."deleted_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) when c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."deleted_at" from 7 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 4 for 2)::int between 1 and 12 and substring(c."deleted_at" from 1 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 1 for 2)::int > 30) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int > 29) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int = 29 and not (substring(c."deleted_at" from 7 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 7 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 7 for 4)::int % 400 = 0)))) when c."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) then left(c."deleted_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."deleted_at" from 7 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 4 for 2)::int between 1 and 12 and substring(c."deleted_at" from 1 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 1 for 2)::int > 30) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int > 29) and not (substring(c."deleted_at" from 4 for 2)::int = 2 and substring(c."deleted_at" from 1 for 2)::int = 29 and not (substring(c."deleted_at" from 7 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 7 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 7 for 4)::int % 400 = 0)))) when c."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."deleted_at" from 1 for 4)::int between 1 and 9999 and substring(c."deleted_at" from 6 for 2)::int between 1 and 12 and substring(c."deleted_at" from 9 for 2)::int between 1 and 31 and not (substring(c."deleted_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."deleted_at" from 9 for 2)::int > 30) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int > 29) and not (substring(c."deleted_at" from 6 for 2)::int = 2 and substring(c."deleted_at" from 9 for 2)::int = 29 and not (substring(c."deleted_at" from 1 for 4)::int % 4 = 0 and (substring(c."deleted_at" from 1 for 4)::int % 100 <> 0 or substring(c."deleted_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."deleted_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."deleted_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."deleted_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."deleted_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."deleted_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."deleted_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."deleted_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."deleted_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end
        )
    )                                           as achados,
    jsonb_build_object('id', c."id", 'reservation_code', c."reservation_code", 'warehouse_id', c."warehouse_id", 'product_variant_id', c."product_variant_id", 'cart_id', c."cart_id", 'order_id', c."order_id", 'quantity', c."quantity", 'status', c."status", 'expires_at', c."expires_at", 'released_at', c."released_at", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
