-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.order_status_history` — camada `staging` (ADR-0016).
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
  FROM {{ source('legacy', 'order_status_history') }}
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
    c.`order_id` AS `order_id`,
    CASE
      WHEN TRIM(c.`from_status`) = ''
      OR TRIM(c.`from_status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`from_status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
      THEN c.`from_status`
      ELSE c.`from_status`
    END AS `from_status`,
    CASE
      WHEN TRIM(c.`to_status`) = ''
      OR TRIM(c.`to_status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`to_status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
      THEN c.`to_status`
      ELSE c.`to_status`
    END AS `to_status`,
    CASE
      WHEN TRIM(c.`changed_at`) = ''
      OR TRIM(c.`changed_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`changed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`changed_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`changed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`changed_at`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`changed_at`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`changed_at`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`changed_at`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`changed_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`changed_at` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`changed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`changed_at`
      ELSE c.`changed_at`
    END AS `changed_at`,
    CASE
      WHEN TRIM(c.`reason`) = ''
      OR TRIM(c.`reason`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`reason` LIKE '%;%'
      AND (
        c.`created_at` IS NULL OR TRIM(c.`created_at`) = ''
      )
      THEN c.`reason`
      WHEN REGEXP_CONTAINS(c.`reason`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`reason`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`reason`)))
      WHEN REGEXP_CONTAINS(c.`reason`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`reason`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`reason`
      WHEN c.`reason` <> TRIM(c.`reason`) OR REGEXP_CONTAINS(c.`reason`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`reason`), '\\s+', ' ')
      ELSE c.`reason`
    END AS `reason`,
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
  l.`order_id`,
  l.`from_status`,
  l.`to_status`,
  l.`changed_at`,
  l.`reason`,
  l.`created_at`,
  JSON_STRIP_NULLS(
    JSON_OBJECT(
      'id',
      CASE
        WHEN TRIM(c.`id`) = '' OR TRIM(c.`id`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
      END,
      'from_status',
      CASE
        WHEN NOT TRIM(l.`from_status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`from_status`) = ''
        OR TRIM(c.`from_status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`from_status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
        THEN 'ENUM_UNKNOWN'
      END,
      'to_status',
      CASE
        WHEN NOT TRIM(l.`to_status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`to_status`) = ''
        OR TRIM(c.`to_status`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`to_status`) IN ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned')
        THEN 'ENUM_UNKNOWN'
      END,
      'changed_at',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`changed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`changed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`changed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`changed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`changed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`changed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`changed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`changed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`changed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`changed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`changed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`changed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`changed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`changed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`changed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`changed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`changed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`changed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`changed_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`changed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`changed_at`) = ''
        OR TRIM(c.`changed_at`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`changed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`changed_at`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`changed_at`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`changed_at`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`changed_at`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`changed_at`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`changed_at`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`changed_at`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`changed_at`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`changed_at`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`changed_at`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'reason',
      CASE
        WHEN TRIM(c.`reason`) = ''
        OR TRIM(c.`reason`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`reason` LIKE '%;%'
        AND (
          c.`created_at` IS NULL OR TRIM(c.`created_at`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`reason`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`reason`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`reason`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`reason`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`reason` <> TRIM(c.`reason`) OR REGEXP_CONTAINS(c.`reason`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
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
    'order_id',
    c.`order_id`,
    'from_status',
    c.`from_status`,
    'to_status',
    c.`to_status`,
    'changed_at',
    c.`changed_at`,
    'reason',
    c.`reason`,
    'created_at',
    c.`created_at`
  ) AS original_payload
FROM captura AS c
JOIN limpo AS l
  ON l.legacy_row_id = c.legacy_row_id
{% else %}with captura as (

    select *
    from {{ source('legacy', 'order_status_history') }}
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
        c."order_id" as "order_id",
        case
            when btrim(c."from_status") = '' or btrim(c."from_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."from_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then c."from_status"
            else c."from_status"
        end as "from_status",
        case
            when btrim(c."to_status") = '' or btrim(c."to_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."to_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then c."to_status"
            else c."to_status"
        end as "to_status",
        case
            when btrim(c."changed_at") = '' or btrim(c."changed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."changed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."changed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."changed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."changed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."changed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."changed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) when c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."changed_at" from 7 for 4)::int between 1 and 9999 and substring(c."changed_at" from 4 for 2)::int between 1 and 12 and substring(c."changed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 1 for 2)::int > 30) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int > 29) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int = 29 and not (substring(c."changed_at" from 7 for 4)::int % 4 = 0 and (substring(c."changed_at" from 7 for 4)::int % 100 <> 0 or substring(c."changed_at" from 7 for 4)::int % 400 = 0)))) when c."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."changed_at"
            when case when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) then left(c."changed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then c."changed_at"
            when case when c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."changed_at" from 7 for 4)::int between 1 and 9999 and substring(c."changed_at" from 4 for 2)::int between 1 and 12 and substring(c."changed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 1 for 2)::int > 30) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int > 29) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int = 29 and not (substring(c."changed_at" from 7 for 4)::int % 4 = 0 and (substring(c."changed_at" from 7 for 4)::int % 100 <> 0 or substring(c."changed_at" from 7 for 4)::int % 400 = 0)))) when c."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) else false end then case when c."changed_at" ~ '^[0-9]{2}/' then to_date(c."changed_at", 'DD/MM/YYYY')::text else to_date(c."changed_at", 'YYYY.MM.DD')::text end
            when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."changed_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."changed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."changed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."changed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."changed_at"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."changed_at"
            else c."changed_at"
        end as "changed_at",
        case
            when btrim(c."reason") = '' or btrim(c."reason") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."reason" like '%;%' and (c."created_at" is null or btrim(c."created_at") = '') then c."reason"
            when c."reason" ~ '(Ã[-¿]|Â[-¿])' and c."reason" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."reason", 'LATIN1'), 'UTF8')
            when c."reason" ~ '(Ã[-¿]|Â[-¿])' and c."reason" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."reason"
            when c."reason" <> btrim(c."reason") or c."reason" ~ '  ' then regexp_replace(btrim(c."reason"), '\s+', ' ', 'g')
            else c."reason"
        end as "reason",
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
    l."order_id",
    l."from_status",
    l."to_status",
    l."changed_at",
    l."reason",
    l."created_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'from_status', case
            when btrim(l."from_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
            when btrim(c."from_status") = '' or btrim(c."from_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."from_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
        end,
            'to_status', case
            when btrim(l."to_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
            when btrim(c."to_status") = '' or btrim(c."to_status") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."to_status") not in ('pending', 'paid', 'picking', 'shipped', 'delivered', 'cancelled', 'returned') then 'ENUM_UNKNOWN'
        end,
            'changed_at', case
            when case when l."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."changed_at" from 1 for 4)::int between 1 and 9999 and substring(l."changed_at" from 6 for 2)::int between 1 and 12 and substring(l."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."changed_at" from 9 for 2)::int > 30) and not (substring(l."changed_at" from 6 for 2)::int = 2 and substring(l."changed_at" from 9 for 2)::int > 29) and not (substring(l."changed_at" from 6 for 2)::int = 2 and substring(l."changed_at" from 9 for 2)::int = 29 and not (substring(l."changed_at" from 1 for 4)::int % 4 = 0 and (substring(l."changed_at" from 1 for 4)::int % 100 <> 0 or substring(l."changed_at" from 1 for 4)::int % 400 = 0)))) and (substring(l."changed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."changed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."changed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."changed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."changed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."changed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."changed_at" from 1 for 4)::int between 1 and 9999 and substring(l."changed_at" from 6 for 2)::int between 1 and 12 and substring(l."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."changed_at" from 9 for 2)::int > 30) and not (substring(l."changed_at" from 6 for 2)::int = 2 and substring(l."changed_at" from 9 for 2)::int > 29) and not (substring(l."changed_at" from 6 for 2)::int = 2 and substring(l."changed_at" from 9 for 2)::int = 29 and not (substring(l."changed_at" from 1 for 4)::int % 4 = 0 and (substring(l."changed_at" from 1 for 4)::int % 100 <> 0 or substring(l."changed_at" from 1 for 4)::int % 400 = 0)))) when l."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."changed_at" from 7 for 4)::int between 1 and 9999 and substring(l."changed_at" from 4 for 2)::int between 1 and 12 and substring(l."changed_at" from 1 for 2)::int between 1 and 31 and not (substring(l."changed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."changed_at" from 1 for 2)::int > 30) and not (substring(l."changed_at" from 4 for 2)::int = 2 and substring(l."changed_at" from 1 for 2)::int > 29) and not (substring(l."changed_at" from 4 for 2)::int = 2 and substring(l."changed_at" from 1 for 2)::int = 29 and not (substring(l."changed_at" from 7 for 4)::int % 4 = 0 and (substring(l."changed_at" from 7 for 4)::int % 100 <> 0 or substring(l."changed_at" from 7 for 4)::int % 400 = 0)))) when l."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."changed_at" from 1 for 4)::int between 1 and 9999 and substring(l."changed_at" from 6 for 2)::int between 1 and 12 and substring(l."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(l."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."changed_at" from 9 for 2)::int > 30) and not (substring(l."changed_at" from 6 for 2)::int = 2 and substring(l."changed_at" from 9 for 2)::int > 29) and not (substring(l."changed_at" from 6 for 2)::int = 2 and substring(l."changed_at" from 9 for 2)::int = 29 and not (substring(l."changed_at" from 1 for 4)::int % 4 = 0 and (substring(l."changed_at" from 1 for 4)::int % 100 <> 0 or substring(l."changed_at" from 1 for 4)::int % 400 = 0)))) then left(l."changed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' or l."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."changed_at") = '' or btrim(c."changed_at") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) and (substring(c."changed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."changed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."changed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."changed_at" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."changed_at" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."changed_at" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) when c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."changed_at" from 7 for 4)::int between 1 and 9999 and substring(c."changed_at" from 4 for 2)::int between 1 and 12 and substring(c."changed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 1 for 2)::int > 30) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int > 29) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int = 29 and not (substring(c."changed_at" from 7 for 4)::int % 4 = 0 and (substring(c."changed_at" from 7 for 4)::int % 100 <> 0 or substring(c."changed_at" from 7 for 4)::int % 400 = 0)))) when c."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) then left(c."changed_at", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."changed_at" from 7 for 4)::int between 1 and 9999 and substring(c."changed_at" from 4 for 2)::int between 1 and 12 and substring(c."changed_at" from 1 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 1 for 2)::int > 30) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int > 29) and not (substring(c."changed_at" from 4 for 2)::int = 2 and substring(c."changed_at" from 1 for 2)::int = 29 and not (substring(c."changed_at" from 7 for 4)::int % 4 = 0 and (substring(c."changed_at" from 7 for 4)::int % 100 <> 0 or substring(c."changed_at" from 7 for 4)::int % 400 = 0)))) when c."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."changed_at" from 1 for 4)::int between 1 and 9999 and substring(c."changed_at" from 6 for 2)::int between 1 and 12 and substring(c."changed_at" from 9 for 2)::int between 1 and 31 and not (substring(c."changed_at" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."changed_at" from 9 for 2)::int > 30) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int > 29) and not (substring(c."changed_at" from 6 for 2)::int = 2 and substring(c."changed_at" from 9 for 2)::int = 29 and not (substring(c."changed_at" from 1 for 4)::int % 4 = 0 and (substring(c."changed_at" from 1 for 4)::int % 100 <> 0 or substring(c."changed_at" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."changed_at" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."changed_at" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."changed_at" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."changed_at" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."changed_at" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."changed_at" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."changed_at" ~ '^[0-9]{2}/[0-9]{4}$' or c."changed_at" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'reason', case
            when btrim(c."reason") = '' or btrim(c."reason") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."reason" like '%;%' and (c."created_at" is null or btrim(c."created_at") = '') then 'TEXT_DELIMITER'
            when c."reason" ~ '(Ã[-¿]|Â[-¿])' and c."reason" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."reason" ~ '(Ã[-¿]|Â[-¿])' and c."reason" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."reason" <> btrim(c."reason") or c."reason" ~ '  ' then 'TEXT_WHITESPACE_CASE'
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
    jsonb_build_object('id', c."id", 'order_id', c."order_id", 'from_status', c."from_status", 'to_status', c."to_status", 'changed_at', c."changed_at", 'reason', c."reason", 'created_at', c."created_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
