-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.customer_contacts` — camada `staging` (ADR-0016).
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
  FROM {{ source('legacy', 'customer_contacts') }}
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
    c.`customer_id` AS `customer_id`,
    CASE
      WHEN TRIM(c.`contact_type`) = ''
      OR TRIM(c.`contact_type`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`contact_type`) IN ('email', 'phone', 'mobile')
      THEN c.`contact_type`
      ELSE c.`contact_type`
    END AS `contact_type`,
    CASE
      WHEN TRIM(c.`contact_value`) = ''
      OR TRIM(c.`contact_value`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`contact_value` LIKE '%;%'
      AND (
        c.`is_primary` IS NULL OR TRIM(c.`is_primary`) = ''
      )
      AND (
        c.`is_verified` IS NULL OR TRIM(c.`is_verified`) = ''
      )
      THEN c.`contact_value`
      WHEN REGEXP_CONTAINS(c.`contact_value`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`contact_value`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`contact_value`)))
      WHEN REGEXP_CONTAINS(c.`contact_value`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`contact_value`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`contact_value`
      WHEN c.`contact_value` <> TRIM(c.`contact_value`)
      OR REGEXP_CONTAINS(c.`contact_value`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`contact_value`), '\\s+', ' ')
      ELSE c.`contact_value`
    END AS `contact_value`,
    CASE
      WHEN TRIM(c.`is_primary`) = ''
      OR TRIM(c.`is_primary`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT c.`is_primary` IN ('true', 'false')
      AND LOWER(TRIM(c.`is_primary`)) IN ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')
      THEN CASE
        WHEN LOWER(TRIM(c.`is_primary`)) IN ('true', 'sim', 's', '1', 'y', 'yes')
        THEN 'true'
        ELSE 'false'
      END
      WHEN NOT TRIM(c.`is_primary`) IN ('true', 'false')
      THEN c.`is_primary`
      ELSE c.`is_primary`
    END AS `is_primary`,
    CASE
      WHEN TRIM(c.`is_verified`) = ''
      OR TRIM(c.`is_verified`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT c.`is_verified` IN ('true', 'false')
      AND LOWER(TRIM(c.`is_verified`)) IN ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')
      THEN CASE
        WHEN LOWER(TRIM(c.`is_verified`)) IN ('true', 'sim', 's', '1', 'y', 'yes')
        THEN 'true'
        ELSE 'false'
      END
      WHEN NOT TRIM(c.`is_verified`) IN ('true', 'false')
      THEN c.`is_verified`
      ELSE c.`is_verified`
    END AS `is_verified`,
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
  l.`customer_id`,
  l.`contact_type`,
  l.`contact_value`,
  l.`is_primary`,
  l.`is_verified`,
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
      'contact_type',
      CASE
        WHEN NOT TRIM(l.`contact_type`) IN ('email', 'phone', 'mobile')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`contact_type`) = ''
        OR TRIM(c.`contact_type`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`contact_type`) IN ('email', 'phone', 'mobile')
        THEN 'ENUM_UNKNOWN'
      END,
      'contact_value',
      CASE
        WHEN TRIM(c.`contact_value`) = ''
        OR TRIM(c.`contact_value`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`contact_value` LIKE '%;%'
        AND (
          c.`is_primary` IS NULL OR TRIM(c.`is_primary`) = ''
        )
        AND (
          c.`is_verified` IS NULL OR TRIM(c.`is_verified`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`contact_value`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`contact_value`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`contact_value`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`contact_value`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`contact_value` <> TRIM(c.`contact_value`)
        OR REGEXP_CONTAINS(c.`contact_value`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'is_primary',
      CASE
        WHEN NOT TRIM(l.`is_primary`) IN ('true', 'false')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`is_primary`) = ''
        OR TRIM(c.`is_primary`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT c.`is_primary` IN ('true', 'false')
        AND LOWER(TRIM(c.`is_primary`)) IN ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')
        THEN 'BOOL_VARIANT'
        WHEN NOT TRIM(c.`is_primary`) IN ('true', 'false')
        THEN 'ENUM_UNKNOWN'
      END,
      'is_verified',
      CASE
        WHEN NOT TRIM(l.`is_verified`) IN ('true', 'false')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`is_verified`) = ''
        OR TRIM(c.`is_verified`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT c.`is_verified` IN ('true', 'false')
        AND LOWER(TRIM(c.`is_verified`)) IN ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')
        THEN 'BOOL_VARIANT'
        WHEN NOT TRIM(c.`is_verified`) IN ('true', 'false')
        THEN 'ENUM_UNKNOWN'
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
    'customer_id',
    c.`customer_id`,
    'contact_type',
    c.`contact_type`,
    'contact_value',
    c.`contact_value`,
    'is_primary',
    c.`is_primary`,
    'is_verified',
    c.`is_verified`,
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
    from {{ source('legacy', 'customer_contacts') }}
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
        c."customer_id" as "customer_id",
        case
            when btrim(c."contact_type") = '' or btrim(c."contact_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."contact_type") not in ('email', 'phone', 'mobile') then c."contact_type"
            else c."contact_type"
        end as "contact_type",
        case
            when btrim(c."contact_value") = '' or btrim(c."contact_value") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."contact_value" like '%;%' and (c."is_primary" is null or btrim(c."is_primary") = '') and (c."is_verified" is null or btrim(c."is_verified") = '') then c."contact_value"
            when c."contact_value" ~ '(Ã[-¿]|Â[-¿])' and c."contact_value" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."contact_value", 'LATIN1'), 'UTF8')
            when c."contact_value" ~ '(Ã[-¿]|Â[-¿])' and c."contact_value" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."contact_value"
            when c."contact_value" <> btrim(c."contact_value") or c."contact_value" ~ '  ' then regexp_replace(btrim(c."contact_value"), '\s+', ' ', 'g')
            else c."contact_value"
        end as "contact_value",
        case
            when btrim(c."is_primary") = '' or btrim(c."is_primary") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."is_primary" not in ('true', 'false') and lower(btrim(c."is_primary")) in ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no') then case when lower(btrim(c."is_primary")) in ('true', 'sim', 's', '1', 'y', 'yes') then 'true' else 'false' end
            when btrim(c."is_primary") not in ('true', 'false') then c."is_primary"
            else c."is_primary"
        end as "is_primary",
        case
            when btrim(c."is_verified") = '' or btrim(c."is_verified") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."is_verified" not in ('true', 'false') and lower(btrim(c."is_verified")) in ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no') then case when lower(btrim(c."is_verified")) in ('true', 'sim', 's', '1', 'y', 'yes') then 'true' else 'false' end
            when btrim(c."is_verified") not in ('true', 'false') then c."is_verified"
            else c."is_verified"
        end as "is_verified",
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
    l."customer_id",
    l."contact_type",
    l."contact_value",
    l."is_primary",
    l."is_verified",
    l."created_at",
    l."updated_at",
    l."deleted_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'contact_type', case
            when btrim(l."contact_type") not in ('email', 'phone', 'mobile') then 'ENUM_UNKNOWN'
            when btrim(c."contact_type") = '' or btrim(c."contact_type") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."contact_type") not in ('email', 'phone', 'mobile') then 'ENUM_UNKNOWN'
        end,
            'contact_value', case
            when btrim(c."contact_value") = '' or btrim(c."contact_value") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."contact_value" like '%;%' and (c."is_primary" is null or btrim(c."is_primary") = '') and (c."is_verified" is null or btrim(c."is_verified") = '') then 'TEXT_DELIMITER'
            when c."contact_value" ~ '(Ã[-¿]|Â[-¿])' and c."contact_value" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."contact_value" ~ '(Ã[-¿]|Â[-¿])' and c."contact_value" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."contact_value" <> btrim(c."contact_value") or c."contact_value" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'is_primary', case
            when btrim(l."is_primary") not in ('true', 'false') then 'ENUM_UNKNOWN'
            when btrim(c."is_primary") = '' or btrim(c."is_primary") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."is_primary" not in ('true', 'false') and lower(btrim(c."is_primary")) in ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no') then 'BOOL_VARIANT'
            when btrim(c."is_primary") not in ('true', 'false') then 'ENUM_UNKNOWN'
        end,
            'is_verified', case
            when btrim(l."is_verified") not in ('true', 'false') then 'ENUM_UNKNOWN'
            when btrim(c."is_verified") = '' or btrim(c."is_verified") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."is_verified" not in ('true', 'false') and lower(btrim(c."is_verified")) in ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no') then 'BOOL_VARIANT'
            when btrim(c."is_verified") not in ('true', 'false') then 'ENUM_UNKNOWN'
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
    jsonb_build_object('id', c."id", 'customer_id', c."customer_id", 'contact_type', c."contact_type", 'contact_value', c."contact_value", 'is_primary', c."is_primary", 'is_verified', c."is_verified", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
