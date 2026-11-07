-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.coupon_redemptions` — camada `staging` (ADR-0016).
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
  FROM {{ source('legacy', 'coupon_redemptions') }}
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
    c.`coupon_id` AS `coupon_id`,
    c.`customer_id` AS `customer_id`,
    c.`order_id` AS `order_id`,
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
      WHEN TRIM(c.`redeemed_at`) = ''
      OR TRIM(c.`redeemed_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`redeemed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`redeemed_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`redeemed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`redeemed_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`redeemed_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`redeemed_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`redeemed_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`redeemed_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`redeemed_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`redeemed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`redeemed_at`
      ELSE c.`redeemed_at`
    END AS `redeemed_at`,
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
    END AS `created_at`
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
  l.`coupon_id`,
  l.`customer_id`,
  l.`order_id`,
  l.`discount_amount`,
  l.`redeemed_at`,
  l.`created_at`,
  JSON_STRIP_NULLS(
    JSON_OBJECT(
      'id',
      CASE
        WHEN TRIM(c.`id`) = '' OR TRIM(c.`id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
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
      'redeemed_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`redeemed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`redeemed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`redeemed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`redeemed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`redeemed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`redeemed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`redeemed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`redeemed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`redeemed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`redeemed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`redeemed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`redeemed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`redeemed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`redeemed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`redeemed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`redeemed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`redeemed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`redeemed_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`redeemed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`redeemed_at`) = ''
        OR TRIM(c.`redeemed_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`redeemed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`redeemed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`redeemed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`redeemed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`redeemed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`redeemed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`redeemed_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`redeemed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`redeemed_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`redeemed_at`,
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
      END
    )
  ) AS achados, /* ── Achados por coluna, sem os nulos ───────────────────────────────────── */
  JSON_OBJECT(
    'id',
    c.`id`,
    'coupon_id',
    c.`coupon_id`,
    'customer_id',
    c.`customer_id`,
    'order_id',
    c.`order_id`,
    'discount_amount',
    c.`discount_amount`,
    'redeemed_at',
    c.`redeemed_at`,
    'created_at',
    c.`created_at`
  ) AS original_payload
FROM captura AS c
JOIN limpo AS l
  ON l.legacy_row_id = c.legacy_row_id
{% else %}with captura as (

    select *
    from {{ source('legacy', 'coupon_redemptions') }}
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
        c."coupon_id" as "coupon_id",
        c."customer_id" as "customer_id",
        c."order_id" as "order_id",
        case
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then c."discount_amount"
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."discount_amount"
            else c."discount_amount"
        end as "discount_amount",
        case
            when btrim(c."redeemed_at") = '' or btrim(c."redeemed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."redeemed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."redeemed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."redeemed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."redeemed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."redeemed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."redeemed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."redeemed_at" from 7 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."redeemed_at"
            when case when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) then left(c."redeemed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."redeemed_at"
            when case when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."redeemed_at" from 7 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."redeemed_at" ~ '^[0-9]{2}/' then to_date(c."redeemed_at", 'DD/MM/YYYY')::text else to_date(c."redeemed_at", 'YYYY.MM.DD')::text end
            when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."redeemed_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."redeemed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."redeemed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."redeemed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."redeemed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."redeemed_at"
            else c."redeemed_at"
        end as "redeemed_at",
        case
            when btrim(c."created_at") = '' or btrim(c."created_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."created_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."created_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."created_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."created_at" from 7 for 4)::int between 1 and 9999 and substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) then left(c."created_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."created_at"
            when case when c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."created_at" from 7 for 4)::int between 1 and 9999 and substring(c."created_at" from 4 for 2)::int between 1 and 12 and substring(c."created_at" from 1 for 2)::int between 1 and 31 and not (substring(c."created_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 1 for 2)::int > 30) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int > 29) and not (substring(c."created_at" from 4 for 2)::int = 2 and substring(c."created_at" from 1 for 2)::int = 29 and not (substring(c."created_at" from 7 for 4)::int % 4 = 0 and (substring(c."created_at" from 7 for 4)::int % 100 <> 0 or substring(c."created_at" from 7 for 4)::int % 400 = 0)))) when c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."created_at" from 1 for 4)::int between 1 and 9999 and substring(c."created_at" from 6 for 2)::int between 1 and 12 and substring(c."created_at" from 9 for 2)::int between 1 and 31 and not (substring(c."created_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."created_at" from 9 for 2)::int > 30) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int > 29) and not (substring(c."created_at" from 6 for 2)::int = 2 and substring(c."created_at" from 9 for 2)::int = 29 and not (substring(c."created_at" from 1 for 4)::int % 4 = 0 and (substring(c."created_at" from 1 for 4)::int % 100 <> 0 or substring(c."created_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."created_at" ~ '^[0-9]{2}/' then to_date(c."created_at", 'DD/MM/YYYY')::text else to_date(c."created_at", 'YYYY.MM.DD')::text end
            when c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."created_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."created_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."created_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."created_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."created_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."created_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."created_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."created_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."created_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."created_at"
            else c."created_at"
        end as "created_at"
    from captura c

)

select
    c.legacy_row_id,
    (c._airbyte_meta->>'sync_id')::bigint       as snapshot_id,
    c._airbyte_extracted_at                     as snapshot_at,
    'legacy'                                    as source_system,

    -- ── Valores tratados ─────────────────────────────────────────────────────
    l."id",
    l."coupon_id",
    l."customer_id",
    l."order_id",
    l."discount_amount",
    l."redeemed_at",
    l."created_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'discount_amount', case
            when btrim(replace(replace(l."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."discount_amount") = '' or btrim(c."discount_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."discount_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."discount_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."discount_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."discount_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."discount_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'redeemed_at', case
            when case when l."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(l."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(l."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."redeemed_at" from 9 for 2)::int > 30) and not (substring(l."redeemed_at" from 6 for 2)::int = 2 and substring(l."redeemed_at" from 9 for 2)::int > 29) and not (substring(l."redeemed_at" from 6 for 2)::int = 2 and substring(l."redeemed_at" from 9 for 2)::int = 29 and not (substring(l."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(l."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(l."redeemed_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."redeemed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."redeemed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."redeemed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."redeemed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."redeemed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."redeemed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(l."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(l."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."redeemed_at" from 9 for 2)::int > 30) and not (substring(l."redeemed_at" from 6 for 2)::int = 2 and substring(l."redeemed_at" from 9 for 2)::int > 29) and not (substring(l."redeemed_at" from 6 for 2)::int = 2 and substring(l."redeemed_at" from 9 for 2)::int = 29 and not (substring(l."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(l."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(l."redeemed_at" from 1 for 4)::int % 400 = 0)))) when l."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."redeemed_at" from 7 for 4)::int between 1 and 9999 and substring(l."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(l."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(l."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."redeemed_at" from 1 for 2)::int > 30) and not (substring(l."redeemed_at" from 4 for 2)::int = 2 and substring(l."redeemed_at" from 1 for 2)::int > 29) and not (substring(l."redeemed_at" from 4 for 2)::int = 2 and substring(l."redeemed_at" from 1 for 2)::int = 29 and not (substring(l."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(l."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(l."redeemed_at" from 7 for 4)::int % 400 = 0)))) when l."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(l."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(l."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."redeemed_at" from 9 for 2)::int > 30) and not (substring(l."redeemed_at" from 6 for 2)::int = 2 and substring(l."redeemed_at" from 9 for 2)::int > 29) and not (substring(l."redeemed_at" from 6 for 2)::int = 2 and substring(l."redeemed_at" from 9 for 2)::int = 29 and not (substring(l."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(l."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(l."redeemed_at" from 1 for 4)::int % 400 = 0)))) then left(l."redeemed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."redeemed_at") = '' or btrim(c."redeemed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."redeemed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."redeemed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."redeemed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."redeemed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."redeemed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."redeemed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."redeemed_at" from 7 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) then left(c."redeemed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."redeemed_at" from 7 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 4 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 1 for 2)::int > 30) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int > 29) and not (substring(c."redeemed_at" from 4 for 2)::int = 2 and substring(c."redeemed_at" from 1 for 2)::int = 29 and not (substring(c."redeemed_at" from 7 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 7 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 7 for 4)::int % 400 = 0)))) when c."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."redeemed_at" from 1 for 4)::int between 1 and 9999 and substring(c."redeemed_at" from 6 for 2)::int between 1 and 12 and substring(c."redeemed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."redeemed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."redeemed_at" from 9 for 2)::int > 30) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int > 29) and not (substring(c."redeemed_at" from 6 for 2)::int = 2 and substring(c."redeemed_at" from 9 for 2)::int = 29 and not (substring(c."redeemed_at" from 1 for 4)::int % 4 = 0 and (substring(c."redeemed_at" from 1 for 4)::int % 100 <> 0 or substring(c."redeemed_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."redeemed_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."redeemed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."redeemed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."redeemed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."redeemed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."redeemed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."redeemed_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."redeemed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
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
        end
        )
    )                                           as achados,
    jsonb_build_object('id', c."id", 'coupon_id', c."coupon_id", 'customer_id', c."customer_id", 'order_id', c."order_id", 'discount_amount', c."discount_amount", 'redeemed_at', c."redeemed_at", 'created_at', c."created_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
