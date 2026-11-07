-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.orders` — camada `staging` (ADR-0016).
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
  FROM {{ source('legacy', 'orders') }}
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
      WHEN TRIM(c.`order_number`) = ''
      OR TRIM(c.`order_number`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`order_number` LIKE '%;%'
      AND (
        c.`customer_id` IS NULL OR TRIM(c.`customer_id`) = ''
      )
      AND (
        c.`sales_channel_id` IS NULL OR TRIM(c.`sales_channel_id`) = ''
      )
      THEN c.`order_number`
      WHEN REGEXP_CONTAINS(c.`order_number`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`order_number`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`order_number`)))
      WHEN REGEXP_CONTAINS(c.`order_number`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`order_number`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`order_number`
      WHEN c.`order_number` <> TRIM(c.`order_number`)
      OR REGEXP_CONTAINS(c.`order_number`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`order_number`), '\\s+', ' ')
      ELSE c.`order_number`
    END AS `order_number`,
    c.`customer_id` AS `customer_id`,
    c.`sales_channel_id` AS `sales_channel_id`,
    c.`cart_id` AS `cart_id`,
    CASE
      WHEN TRIM(c.`status`) = ''
      OR TRIM(c.`status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
      THEN c.`status`
      ELSE c.`status`
    END AS `status`,
    CASE
      WHEN TRIM(c.`placed_at`) = ''
      OR TRIM(c.`placed_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`placed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`placed_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`placed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`placed_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`placed_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`placed_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`placed_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`placed_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`placed_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`placed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`placed_at`
      ELSE c.`placed_at`
    END AS `placed_at`,
    CASE
      WHEN TRIM(c.`currency`) = ''
      OR TRIM(c.`currency`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`currency` LIKE '%;%'
      AND (
        c.`subtotal_amount` IS NULL OR TRIM(c.`subtotal_amount`) = ''
      )
      AND (
        c.`discount_amount` IS NULL OR TRIM(c.`discount_amount`) = ''
      )
      THEN c.`currency`
      WHEN REGEXP_CONTAINS(c.`currency`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`currency`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`currency`)))
      WHEN REGEXP_CONTAINS(c.`currency`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`currency`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`currency`
      WHEN c.`currency` <> TRIM(c.`currency`) OR REGEXP_CONTAINS(c.`currency`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`currency`), '\\s+', ' ')
      ELSE c.`currency`
    END AS `currency`,
    CASE
      WHEN TRIM(c.`subtotal_amount`) = ''
      OR TRIM(c.`subtotal_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', '')), '^-')
      THEN c.`subtotal_amount`
      WHEN NOT REGEXP_CONTAINS(c.`subtotal_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`subtotal_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`subtotal_amount`
      ELSE c.`subtotal_amount`
    END AS `subtotal_amount`,
    CASE
      WHEN TRIM(c.`discount_amount`) = ''
      OR TRIM(c.`discount_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', '')), '^-')
      THEN c.`discount_amount`
      WHEN NOT REGEXP_CONTAINS(c.`discount_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`discount_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`discount_amount`
      ELSE c.`discount_amount`
    END AS `discount_amount`,
    CASE
      WHEN TRIM(c.`shipping_amount`) = ''
      OR TRIM(c.`shipping_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', '')), '^-')
      THEN c.`shipping_amount`
      WHEN NOT REGEXP_CONTAINS(c.`shipping_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`shipping_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`shipping_amount`
      ELSE c.`shipping_amount`
    END AS `shipping_amount`,
    CASE
      WHEN TRIM(c.`tax_amount`) = ''
      OR TRIM(c.`tax_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', '')), '^-')
      THEN c.`tax_amount`
      WHEN NOT REGEXP_CONTAINS(c.`tax_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`tax_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`tax_amount`
      ELSE c.`tax_amount`
    END AS `tax_amount`,
    CASE
      WHEN TRIM(c.`total_amount`) = ''
      OR TRIM(c.`total_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', '')), '^-')
      THEN c.`total_amount`
      WHEN NOT REGEXP_CONTAINS(c.`total_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`total_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`total_amount`
      ELSE c.`total_amount`
    END AS `total_amount`,
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
  l.`order_number`,
  l.`customer_id`,
  l.`sales_channel_id`,
  l.`cart_id`,
  l.`status`,
  l.`placed_at`,
  l.`currency`,
  l.`subtotal_amount`,
  l.`discount_amount`,
  l.`shipping_amount`,
  l.`tax_amount`,
  l.`total_amount`,
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
      'order_number',
      CASE
        WHEN TRIM(c.`order_number`) = ''
        OR TRIM(c.`order_number`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`order_number` LIKE '%;%'
        AND (
          c.`customer_id` IS NULL OR TRIM(c.`customer_id`) = ''
        )
        AND (
          c.`sales_channel_id` IS NULL OR TRIM(c.`sales_channel_id`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`order_number`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`order_number`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`order_number`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`order_number`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`order_number` <> TRIM(c.`order_number`)
        OR REGEXP_CONTAINS(c.`order_number`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'status',
      CASE
        WHEN NOT TRIM(l.`status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`status`) = ''
        OR TRIM(c.`status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
        THEN 'ENUM_UNKNOWN'
      END,
      'placed_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`placed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`placed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`placed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`placed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`placed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`placed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`placed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`placed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`placed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`placed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`placed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`placed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`placed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`placed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`placed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`placed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`placed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`placed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`placed_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`placed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`placed_at`) = ''
        OR TRIM(c.`placed_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`placed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`placed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`placed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`placed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`placed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`placed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`placed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`placed_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`placed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`placed_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`placed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'currency',
      CASE
        WHEN TRIM(c.`currency`) = ''
        OR TRIM(c.`currency`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`currency` LIKE '%;%'
        AND (
          c.`subtotal_amount` IS NULL OR TRIM(c.`subtotal_amount`) = ''
        )
        AND (
          c.`discount_amount` IS NULL OR TRIM(c.`discount_amount`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`currency`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`currency`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`currency`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`currency`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`currency` <> TRIM(c.`currency`) OR REGEXP_CONTAINS(c.`currency`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'subtotal_amount',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`subtotal_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`subtotal_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`subtotal_amount`) = ''
        OR TRIM(c.`subtotal_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`subtotal_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`subtotal_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`subtotal_amount`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`subtotal_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
      END,
      'discount_amount',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`discount_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`discount_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`discount_amount`) = ''
        OR TRIM(c.`discount_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`discount_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`discount_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`discount_amount`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`discount_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
      END,
      'shipping_amount',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`shipping_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`shipping_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`shipping_amount`) = ''
        OR TRIM(c.`shipping_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`shipping_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`shipping_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`shipping_amount`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`shipping_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
      END,
      'tax_amount',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`tax_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`tax_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`tax_amount`) = ''
        OR TRIM(c.`tax_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`tax_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`tax_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`tax_amount`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`tax_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
      END,
      'total_amount',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`total_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`total_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`total_amount`) = ''
        OR TRIM(c.`total_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`total_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`total_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`total_amount`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`total_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
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
    'order_number',
    c.`order_number`,
    'customer_id',
    c.`customer_id`,
    'sales_channel_id',
    c.`sales_channel_id`,
    'cart_id',
    c.`cart_id`,
    'status',
    c.`status`,
    'placed_at',
    c.`placed_at`,
    'currency',
    c.`currency`,
    'subtotal_amount',
    c.`subtotal_amount`,
    'discount_amount',
    c.`discount_amount`,
    'shipping_amount',
    c.`shipping_amount`,
    'tax_amount',
    c.`tax_amount`,
    'total_amount',
    c.`total_amount`,
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
    from {{ source('legacy', 'orders') }}
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
            when btrim(c."order_number") = '' or btrim(c."order_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."order_number" like '%;%' and (c."customer_id" is null or btrim(c."customer_id") = '') and (c."sales_channel_id" is null or btrim(c."sales_channel_id") = '') then c."order_number"
            when c."order_number" ~ '(Ã[-¿]|Â[-¿])' and c."order_number" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."order_number", 'LATIN1'), 'UTF8')
            when c."order_number" ~ '(Ã[-¿]|Â[-¿])' and c."order_number" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."order_number"
            when c."order_number" <> btrim(c."order_number") or c."order_number" ~ '  ' then regexp_replace(btrim(c."order_number"), '\s+', ' ', 'g')
            else c."order_number"
        end as "order_number",
        c."customer_id" as "customer_id",
        c."sales_channel_id" as "sales_channel_id",
        c."cart_id" as "cart_id",
        case
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then c."status"
            else c."status"
        end as "status",
        case
            when btrim(c."placed_at") = '' or btrim(c."placed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."placed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."placed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."placed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."placed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."placed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."placed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) when c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."placed_at" from 7 for 4)::int between 1 and 9999 and substring(c."placed_at" from 4 for 2)::int between 1 and 12 and substring(c."placed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 1 for 2)::int > 30) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int > 29) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int = 29 and not (substring(c."placed_at" from 7 for 4)::int % 4 = 0 and (substring(c."placed_at" from 7 for 4)::int % 100 <> 0 or substring(c."placed_at" from 7 for 4)::int % 400 = 0)))) when c."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."placed_at"
            when case when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) then left(c."placed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."placed_at"
            when case when c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."placed_at" from 7 for 4)::int between 1 and 9999 and substring(c."placed_at" from 4 for 2)::int between 1 and 12 and substring(c."placed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 1 for 2)::int > 30) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int > 29) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int = 29 and not (substring(c."placed_at" from 7 for 4)::int % 4 = 0 and (substring(c."placed_at" from 7 for 4)::int % 100 <> 0 or substring(c."placed_at" from 7 for 4)::int % 400 = 0)))) when c."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."placed_at" ~ '^[0-9]{2}/' then to_date(c."placed_at", 'DD/MM/YYYY')::text else to_date(c."placed_at", 'YYYY.MM.DD')::text end
            when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."placed_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."placed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."placed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."placed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."placed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."placed_at"
            else c."placed_at"
        end as "placed_at",
        case
            when btrim(c."currency") = '' or btrim(c."currency") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."currency" like '%;%' and (c."subtotal_amount" is null or btrim(c."subtotal_amount") = '') and (c."discount_amount" is null or btrim(c."discount_amount") = '') then c."currency"
            when c."currency" ~ '(Ã[-¿]|Â[-¿])' and c."currency" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."currency", 'LATIN1'), 'UTF8')
            when c."currency" ~ '(Ã[-¿]|Â[-¿])' and c."currency" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."currency"
            when c."currency" <> btrim(c."currency") or c."currency" ~ '  ' then regexp_replace(btrim(c."currency"), '\s+', ' ', 'g')
            else c."currency"
        end as "currency",
        case
            when btrim(c."subtotal_amount") = '' or btrim(c."subtotal_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."subtotal_amount", 'R$', ''), ' ', '')) ~ '^-' then c."subtotal_amount"
            when c."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."subtotal_amount"
            else c."subtotal_amount"
        end as "subtotal_amount",
        case
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then c."discount_amount"
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."discount_amount"
            else c."discount_amount"
        end as "discount_amount",
        case
            when btrim(c."shipping_amount") = '' or btrim(c."shipping_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."shipping_amount", 'R$', ''), ' ', '')) ~ '^-' then c."shipping_amount"
            when c."shipping_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."shipping_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."shipping_amount"
            else c."shipping_amount"
        end as "shipping_amount",
        case
            when btrim(c."tax_amount") = '' or btrim(c."tax_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."tax_amount", 'R$', ''), ' ', '')) ~ '^-' then c."tax_amount"
            when c."tax_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."tax_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."tax_amount"
            else c."tax_amount"
        end as "tax_amount",
        case
            when btrim(c."total_amount") = '' or btrim(c."total_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."total_amount", 'R$', ''), ' ', '')) ~ '^-' then c."total_amount"
            when c."total_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."total_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."total_amount"
            else c."total_amount"
        end as "total_amount",
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
    l."order_number",
    l."customer_id",
    l."sales_channel_id",
    l."cart_id",
    l."status",
    l."placed_at",
    l."currency",
    l."subtotal_amount",
    l."discount_amount",
    l."shipping_amount",
    l."tax_amount",
    l."total_amount",
    l."created_at",
    l."updated_at",
    l."deleted_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'order_number', case
            when btrim(c."order_number") = '' or btrim(c."order_number") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."order_number" like '%;%' and (c."customer_id" is null or btrim(c."customer_id") = '') and (c."sales_channel_id" is null or btrim(c."sales_channel_id") = '') then 'TEXT_DELIMITER'
            when c."order_number" ~ '(Ã[-¿]|Â[-¿])' and c."order_number" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."order_number" ~ '(Ã[-¿]|Â[-¿])' and c."order_number" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."order_number" <> btrim(c."order_number") or c."order_number" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'status', case
            when btrim(l."status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
            when btrim(c."status") = '' or btrim(c."status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
        end,
            'placed_at', case
            when case when l."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."placed_at" from 1 for 4)::int between 1 and 9999 and substring(l."placed_at" from 6 for 2)::int between 1 and 12 and substring(l."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."placed_at" from 9 for 2)::int > 30) and not (substring(l."placed_at" from 6 for 2)::int = 2 and substring(l."placed_at" from 9 for 2)::int > 29) and not (substring(l."placed_at" from 6 for 2)::int = 2 and substring(l."placed_at" from 9 for 2)::int = 29 and not (substring(l."placed_at" from 1 for 4)::int % 4 = 0 and (substring(l."placed_at" from 1 for 4)::int % 100 <> 0 or substring(l."placed_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."placed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."placed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."placed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."placed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."placed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."placed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."placed_at" from 1 for 4)::int between 1 and 9999 and substring(l."placed_at" from 6 for 2)::int between 1 and 12 and substring(l."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."placed_at" from 9 for 2)::int > 30) and not (substring(l."placed_at" from 6 for 2)::int = 2 and substring(l."placed_at" from 9 for 2)::int > 29) and not (substring(l."placed_at" from 6 for 2)::int = 2 and substring(l."placed_at" from 9 for 2)::int = 29 and not (substring(l."placed_at" from 1 for 4)::int % 4 = 0 and (substring(l."placed_at" from 1 for 4)::int % 100 <> 0 or substring(l."placed_at" from 1 for 4)::int % 400 = 0)))) when l."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."placed_at" from 7 for 4)::int between 1 and 9999 and substring(l."placed_at" from 4 for 2)::int between 1 and 12 and substring(l."placed_at" from 1 for 2)::int between 1 and 31 and not (substring(l."placed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."placed_at" from 1 for 2)::int > 30) and not (substring(l."placed_at" from 4 for 2)::int = 2 and substring(l."placed_at" from 1 for 2)::int > 29) and not (substring(l."placed_at" from 4 for 2)::int = 2 and substring(l."placed_at" from 1 for 2)::int = 29 and not (substring(l."placed_at" from 7 for 4)::int % 4 = 0 and (substring(l."placed_at" from 7 for 4)::int % 100 <> 0 or substring(l."placed_at" from 7 for 4)::int % 400 = 0)))) when l."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."placed_at" from 1 for 4)::int between 1 and 9999 and substring(l."placed_at" from 6 for 2)::int between 1 and 12 and substring(l."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."placed_at" from 9 for 2)::int > 30) and not (substring(l."placed_at" from 6 for 2)::int = 2 and substring(l."placed_at" from 9 for 2)::int > 29) and not (substring(l."placed_at" from 6 for 2)::int = 2 and substring(l."placed_at" from 9 for 2)::int = 29 and not (substring(l."placed_at" from 1 for 4)::int % 4 = 0 and (substring(l."placed_at" from 1 for 4)::int % 100 <> 0 or substring(l."placed_at" from 1 for 4)::int % 400 = 0)))) then left(l."placed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."placed_at") = '' or btrim(c."placed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."placed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."placed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."placed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."placed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."placed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."placed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) when c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."placed_at" from 7 for 4)::int between 1 and 9999 and substring(c."placed_at" from 4 for 2)::int between 1 and 12 and substring(c."placed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 1 for 2)::int > 30) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int > 29) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int = 29 and not (substring(c."placed_at" from 7 for 4)::int % 4 = 0 and (substring(c."placed_at" from 7 for 4)::int % 100 <> 0 or substring(c."placed_at" from 7 for 4)::int % 400 = 0)))) when c."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) then left(c."placed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."placed_at" from 7 for 4)::int between 1 and 9999 and substring(c."placed_at" from 4 for 2)::int between 1 and 12 and substring(c."placed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 1 for 2)::int > 30) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int > 29) and not (substring(c."placed_at" from 4 for 2)::int = 2 and substring(c."placed_at" from 1 for 2)::int = 29 and not (substring(c."placed_at" from 7 for 4)::int % 4 = 0 and (substring(c."placed_at" from 7 for 4)::int % 100 <> 0 or substring(c."placed_at" from 7 for 4)::int % 400 = 0)))) when c."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."placed_at" from 1 for 4)::int between 1 and 9999 and substring(c."placed_at" from 6 for 2)::int between 1 and 12 and substring(c."placed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."placed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."placed_at" from 9 for 2)::int > 30) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int > 29) and not (substring(c."placed_at" from 6 for 2)::int = 2 and substring(c."placed_at" from 9 for 2)::int = 29 and not (substring(c."placed_at" from 1 for 4)::int % 4 = 0 and (substring(c."placed_at" from 1 for 4)::int % 100 <> 0 or substring(c."placed_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."placed_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."placed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."placed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."placed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."placed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."placed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."placed_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."placed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'currency', case
            when btrim(c."currency") = '' or btrim(c."currency") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."currency" like '%;%' and (c."subtotal_amount" is null or btrim(c."subtotal_amount") = '') and (c."discount_amount" is null or btrim(c."discount_amount") = '') then 'TEXT_DELIMITER'
            when c."currency" ~ '(Ã[-¿]|Â[-¿])' and c."currency" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."currency" ~ '(Ã[-¿]|Â[-¿])' and c."currency" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."currency" <> btrim(c."currency") or c."currency" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'subtotal_amount', case
            when btrim(replace(replace(l."subtotal_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."subtotal_amount") = '' or btrim(c."subtotal_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."subtotal_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."subtotal_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."subtotal_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."subtotal_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'discount_amount', case
            when btrim(replace(replace(l."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'shipping_amount', case
            when btrim(replace(replace(l."shipping_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."shipping_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."shipping_amount") = '' or btrim(c."shipping_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."shipping_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."shipping_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."shipping_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."shipping_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."shipping_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'tax_amount', case
            when btrim(replace(replace(l."tax_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."tax_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."tax_amount") = '' or btrim(c."tax_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."tax_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."tax_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."tax_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."tax_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."tax_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."tax_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'total_amount', case
            when btrim(replace(replace(l."total_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."total_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."total_amount") = '' or btrim(c."total_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."total_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."total_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."total_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."total_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."total_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."total_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
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
    jsonb_build_object('id', c."id", 'order_number', c."order_number", 'customer_id', c."customer_id", 'sales_channel_id', c."sales_channel_id", 'cart_id', c."cart_id", 'status', c."status", 'placed_at', c."placed_at", 'currency', c."currency", 'subtotal_amount', c."subtotal_amount", 'discount_amount', c."discount_amount", 'shipping_amount', c."shipping_amount", 'tax_amount', c."tax_amount", 'total_amount', c."total_amount", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
