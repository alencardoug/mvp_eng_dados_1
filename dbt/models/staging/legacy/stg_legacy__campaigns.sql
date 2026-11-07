-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Limpeza de `legacy.campaigns` — camada `staging` (ADR-0016).
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
  FROM {{ source('legacy', 'campaigns') }}
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
      WHEN TRIM(c.`code`) = ''
      OR TRIM(c.`code`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN c.`code` LIKE '%;%'
      AND (
        c.`name` IS NULL OR TRIM(c.`name`) = ''
      )
      AND (
        c.`objective` IS NULL OR TRIM(c.`objective`) = ''
      )
      THEN c.`code`
      WHEN REGEXP_CONTAINS(c.`code`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`code`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`code`)))
      WHEN REGEXP_CONTAINS(c.`code`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`code`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`code`
      WHEN c.`code` <> TRIM(c.`code`) OR REGEXP_CONTAINS(c.`code`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`code`), '\\s+', ' ')
      ELSE c.`code`
    END AS `code`,
    CASE
      WHEN TRIM(c.`name`) = ''
      OR TRIM(c.`name`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN LENGTH(c.`name`) = 24
      THEN c.`name`
      WHEN c.`name` LIKE '%;%'
      AND (
        c.`objective` IS NULL OR TRIM(c.`objective`) = ''
      )
      AND (
        c.`valid_from` IS NULL OR TRIM(c.`valid_from`) = ''
      )
      THEN c.`name`
      WHEN REGEXP_CONTAINS(c.`name`, '(Ã[-¿]|Â[-¿])')
      AND REGEXP_CONTAINS(
        c.`name`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN SAFE_CONVERT_BYTES_TO_STRING(CODE_POINTS_TO_BYTES(TO_CODE_POINTS(c.`name`)))
      WHEN REGEXP_CONTAINS(c.`name`, '(Ã[-¿]|Â[-¿])')
      AND NOT REGEXP_CONTAINS(
        c.`name`,
        '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
      )
      THEN c.`name`
      WHEN c.`name` <> TRIM(c.`name`) OR REGEXP_CONTAINS(c.`name`, '  ')
      THEN REGEXP_REPLACE(TRIM(c.`name`), '\\s+', ' ')
      ELSE c.`name`
    END AS `name`,
    CASE
      WHEN TRIM(c.`objective`) = ''
      OR TRIM(c.`objective`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT TRIM(c.`objective`) IN ('acquisition', 'retention', 'reactivation', 'clearance')
      THEN c.`objective`
      ELSE c.`objective`
    END AS `objective`,
    CASE
      WHEN TRIM(c.`valid_from`) = ''
      OR TRIM(c.`valid_from`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`valid_from`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`valid_from`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        AND (
          CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        THEN CAST(LEFT(c.`valid_from`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
        ELSE FALSE
      END
      THEN c.`valid_from`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`valid_from`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`valid_from`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`valid_from`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`valid_from`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`valid_from` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`valid_from`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`valid_from`
      ELSE c.`valid_from`
    END AS `valid_from`,
    CASE
      WHEN TRIM(c.`valid_to`) = ''
      OR TRIM(c.`valid_to`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN CASE
        WHEN REGEXP_CONTAINS(
          c.`valid_to`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        THEN NOT (
          (
            CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          AND (
            CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
            AND CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
          )
          AND (
            CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
            AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
        THEN NOT (
          CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN NOT (
          CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{4}$')
        THEN TRUE
        ELSE FALSE
      END
      THEN c.`valid_to`
      WHEN CASE
        WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        THEN (
          CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        THEN (
          CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
          AND CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
          AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 30
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 29
          )
          AND NOT (
            CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) = 29
            AND NOT (
              MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 4) = 0
              AND (
                MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 100) <> 0
                OR MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 400) = 0
              )
            )
          )
        )
        ELSE FALSE
      END
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/')
        THEN CAST(PARSE_DATE('%d/%m/%Y', c.`valid_to`) AS STRING)
        ELSE CAST(PARSE_DATE('%Y.%m.%d', c.`valid_to`) AS STRING)
      END
      WHEN REGEXP_CONTAINS(
        c.`valid_to`,
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
      )
      AND NOT REGEXP_CONTAINS(c.`valid_to`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
      AND (
        CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
        AND CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
        AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
      )
      THEN CAST((
        TIMESTAMP(CAST(c.`valid_to` AS DATETIME), 'America/Sao_Paulo')
      ) AS STRING)
      WHEN NOT (
        REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
        OR REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{4}$')
        OR REGEXP_CONTAINS(
          c.`valid_to`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
      )
      THEN c.`valid_to`
      ELSE c.`valid_to`
    END AS `valid_to`,
    CASE
      WHEN TRIM(c.`budget_amount`) = ''
      OR TRIM(c.`budget_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', '')), '^-')
      THEN c.`budget_amount`
      WHEN NOT REGEXP_CONTAINS(c.`budget_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      AND (
        REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
        OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
      )
      AND NOT (
        (
          REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        )
        AND (
          REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND REPLACE(REPLACE(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', ''), ',', '')
      )
      THEN CASE
        WHEN REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
        OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
        THEN REPLACE(REPLACE(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.')
        ELSE REPLACE(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', ''), ',', '')
      END
      WHEN NOT REGEXP_CONTAINS(c.`budget_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
      THEN c.`budget_amount`
      ELSE c.`budget_amount`
    END AS `budget_amount`,
    CASE
      WHEN TRIM(c.`is_active`) = ''
      OR TRIM(c.`is_active`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
      THEN NULL
      WHEN NOT c.`is_active` IN ('true', 'false')
      AND LOWER(TRIM(c.`is_active`)) IN ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')
      THEN CASE
        WHEN LOWER(TRIM(c.`is_active`)) IN ('true', 'sim', 's', '1', 'y', 'yes')
        THEN 'true'
        ELSE 'false'
      END
      WHEN NOT TRIM(c.`is_active`) IN ('true', 'false')
      THEN c.`is_active`
      ELSE c.`is_active`
    END AS `is_active`,
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
  l.`code`,
  l.`name`,
  l.`objective`,
  l.`valid_from`,
  l.`valid_to`,
  l.`budget_amount`,
  l.`is_active`,
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
      'code',
      CASE
        WHEN TRIM(c.`code`) = ''
        OR TRIM(c.`code`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN c.`code` LIKE '%;%'
        AND (
          c.`name` IS NULL OR TRIM(c.`name`) = ''
        )
        AND (
          c.`objective` IS NULL OR TRIM(c.`objective`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`code`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`code`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`code`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`code`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`code` <> TRIM(c.`code`) OR REGEXP_CONTAINS(c.`code`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'name',
      CASE
        WHEN TRIM(c.`name`) = ''
        OR TRIM(c.`name`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN LENGTH(c.`name`) = 24
        THEN 'TEXT_TRUNCATED'
        WHEN c.`name` LIKE '%;%'
        AND (
          c.`objective` IS NULL OR TRIM(c.`objective`) = ''
        )
        AND (
          c.`valid_from` IS NULL OR TRIM(c.`valid_from`) = ''
        )
        THEN 'TEXT_DELIMITER'
        WHEN REGEXP_CONTAINS(c.`name`, '(Ã[-¿]|Â[-¿])')
        AND REGEXP_CONTAINS(
          c.`name`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING'
        WHEN REGEXP_CONTAINS(c.`name`, '(Ã[-¿]|Â[-¿])')
        AND NOT REGEXP_CONTAINS(
          c.`name`,
          '^([\\x{0001}-\\x{007f}]|[\\x{00c2}-\\x{00df}][\\x{0080}-\\x{00bf}]|\\x{00e0}[\\x{00a0}-\\x{00bf}][\\x{0080}-\\x{00bf}]|[\\x{00e1}-\\x{00ec}][\\x{0080}-\\x{00bf}]{2}|\\x{00ed}[\\x{0080}-\\x{009f}][\\x{0080}-\\x{00bf}]|[\\x{00ee}-\\x{00ef}][\\x{0080}-\\x{00bf}]{2}|\\x{00f0}[\\x{0090}-\\x{00bf}][\\x{0080}-\\x{00bf}]{2}|[\\x{00f1}-\\x{00f3}][\\x{0080}-\\x{00bf}]{3}|\\x{00f4}[\\x{0080}-\\x{008f}][\\x{0080}-\\x{00bf}]{2})*$'
        )
        THEN 'TEXT_ENCODING_AMBIGUOUS'
        WHEN c.`name` <> TRIM(c.`name`) OR REGEXP_CONTAINS(c.`name`, '  ')
        THEN 'TEXT_WHITESPACE_CASE'
      END,
      'objective',
      CASE
        WHEN NOT TRIM(l.`objective`) IN ('acquisition', 'retention', 'reactivation', 'clearance')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`objective`) = ''
        OR TRIM(c.`objective`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT TRIM(c.`objective`) IN ('acquisition', 'retention', 'reactivation', 'clearance')
        THEN 'ENUM_UNKNOWN'
      END,
      'valid_from',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`valid_from`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`valid_from`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`valid_from`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`valid_from`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`valid_from`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`valid_from`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`valid_from`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`valid_from`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`valid_from`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`valid_from`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_from`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_from`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`valid_from`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`valid_from`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`valid_from`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_from`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`valid_from`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(l.`valid_from`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`valid_from`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`valid_from`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`valid_from`) = ''
        OR TRIM(c.`valid_from`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`valid_from`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
          AND (
            CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          THEN CAST(LEFT(c.`valid_from`, 10) AS DATE) > CAST('{{ var("as_of_date") }}' AS DATE)
          ELSE FALSE
        END
        THEN 'DATE_FUTURE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_from`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_from`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_from`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_from`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`valid_from`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`valid_from`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_from`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`valid_from`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`valid_from`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'valid_to',
      CASE
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            l.`valid_to`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(l.`valid_to`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(l.`valid_to`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`valid_to`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(l.`valid_to`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(l.`valid_to`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_to`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`valid_to`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(l.`valid_to`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(l.`valid_to`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(l.`valid_to`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(l.`valid_to`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(l.`valid_to`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_to`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_to`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(l.`valid_to`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(l.`valid_to`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(l.`valid_to`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(l.`valid_to`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(l.`valid_to`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN NOT (
          REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(l.`valid_to`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            l.`valid_to`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
        WHEN TRIM(c.`valid_to`) = ''
        OR TRIM(c.`valid_to`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN CASE
          WHEN REGEXP_CONTAINS(
            c.`valid_to`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
          THEN NOT (
            (
              CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
              AND CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
              AND NOT (
                CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
                AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 30
              )
              AND NOT (
                CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 29
              )
              AND NOT (
                CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
                AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) = 29
                AND NOT (
                  MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 4) = 0
                  AND (
                    MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 100) <> 0
                    OR MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 400) = 0
                  )
                )
              )
            )
            AND (
              CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
              AND CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
            )
            AND (
              CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[+-]([0-9]{2})(?::?[0-9]{2})?$'), '00') AS INT64) BETWEEN 0 AND 15
              AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[+-][0-9]{2}:?([0-9]{2})$'), '00') AS INT64) BETWEEN 0 AND 59
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$')
          THEN NOT (
            CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN NOT (
            CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{4}$')
          THEN TRUE
          ELSE FALSE
        END
        THEN 'DATE_IMPOSSIBLE'
        WHEN CASE
          WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          THEN (
            CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 4, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 1, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_to`, 7, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          WHEN REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          THEN (
            CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64) BETWEEN 1 AND 9999
            AND CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) BETWEEN 1 AND 12
            AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) BETWEEN 1 AND 31
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) IN (4, 6, 9, 11)
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 30
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) > 29
            )
            AND NOT (
              CAST(SUBSTRING(c.`valid_to`, 6, 2) AS INT64) = 2
              AND CAST(SUBSTRING(c.`valid_to`, 9, 2) AS INT64) = 29
              AND NOT (
                MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 4) = 0
                AND (
                  MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 100) <> 0
                  OR MOD(CAST(SUBSTRING(c.`valid_to`, 1, 4) AS INT64), 400) = 0
                )
              )
            )
          )
          ELSE FALSE
        END
        THEN 'DATE_FORMAT_KNOWN'
        WHEN REGEXP_CONTAINS(
          c.`valid_to`,
          '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
        )
        AND NOT REGEXP_CONTAINS(c.`valid_to`, '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$')
        AND (
          CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T]([0-9]{2}):[0-9]{2}') AS INT64) BETWEEN 0 AND 23
          AND CAST(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:([0-9]{2})') AS INT64) BETWEEN 0 AND 59
          AND CAST(COALESCE(REGEXP_EXTRACT(c.`valid_to`, '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00') AS INT64) BETWEEN 0 AND 59
        )
        THEN 'DATE_TZ_MISSING'
        WHEN NOT (
          REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$')
          OR REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(c.`valid_to`, '^[0-9]{2}/[0-9]{4}$')
          OR REGEXP_CONTAINS(
            c.`valid_to`,
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'
          )
        )
        THEN 'DATE_UNPARSEABLE'
      END,
      'budget_amount',
      CASE
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(l.`budget_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(l.`budget_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
        WHEN TRIM(c.`budget_amount`) = ''
        OR TRIM(c.`budget_amount`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN REGEXP_CONTAINS(TRIM(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', '')), '^-')
        THEN 'MONEY_NEGATIVE'
        WHEN NOT REGEXP_CONTAINS(c.`budget_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        AND (
          REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
          OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
        )
        AND NOT (
          (
            REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(\\.[0-9]{3})*,[0-9]{1,4}$')
            OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+,[0-9]{1,4}$')
          )
          AND (
            REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]{1,4})?$')
            OR REGEXP_CONTAINS(c.`budget_amount`, '^-?(R\\$)?\\s*[0-9]+(\\.[0-9]{1,4})?$')
          )
          AND REPLACE(REPLACE(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', ''), '.', ''), ',', '.') IS DISTINCT FROM REPLACE(REPLACE(REPLACE(c.`budget_amount`, 'R$', ''), ' ', ''), ',', '')
        )
        THEN 'MONEY_LOCALE'
        WHEN NOT REGEXP_CONTAINS(c.`budget_amount`, '^-?[0-9]+(\\.[0-9]{1,4})?$')
        THEN 'MONEY_AMBIGUOUS'
      END,
      'is_active',
      CASE
        WHEN NOT TRIM(l.`is_active`) IN ('true', 'false')
        THEN 'ENUM_UNKNOWN'
        WHEN TRIM(c.`is_active`) = ''
        OR TRIM(c.`is_active`) IN ('NULL', 'null', 'N/A', '-', '#N/D', '   ')
        THEN 'NULL_DISGUISED'
        WHEN NOT c.`is_active` IN ('true', 'false')
        AND LOWER(TRIM(c.`is_active`)) IN ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no')
        THEN 'BOOL_VARIANT'
        WHEN NOT TRIM(c.`is_active`) IN ('true', 'false')
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
    'code',
    c.`code`,
    'name',
    c.`name`,
    'objective',
    c.`objective`,
    'valid_from',
    c.`valid_from`,
    'valid_to',
    c.`valid_to`,
    'budget_amount',
    c.`budget_amount`,
    'is_active',
    c.`is_active`,
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
    from {{ source('legacy', 'campaigns') }}
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
            when btrim(c."code") = '' or btrim(c."code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."code" like '%;%' and (c."name" is null or btrim(c."name") = '') and (c."objective" is null or btrim(c."objective") = '') then c."code"
            when c."code" ~ '(Ã[-¿]|Â[-¿])' and c."code" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."code", 'LATIN1'), 'UTF8')
            when c."code" ~ '(Ã[-¿]|Â[-¿])' and c."code" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."code"
            when c."code" <> btrim(c."code") or c."code" ~ '  ' then regexp_replace(btrim(c."code"), '\s+', ' ', 'g')
            else c."code"
        end as "code",
        case
            when btrim(c."name") = '' or btrim(c."name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when length(c."name") = 24 then c."name"
            when c."name" like '%;%' and (c."objective" is null or btrim(c."objective") = '') and (c."valid_from" is null or btrim(c."valid_from") = '') then c."name"
            when c."name" ~ '(Ã[-¿]|Â[-¿])' and c."name" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then convert_from(convert_to(c."name", 'LATIN1'), 'UTF8')
            when c."name" ~ '(Ã[-¿]|Â[-¿])' and c."name" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then c."name"
            when c."name" <> btrim(c."name") or c."name" ~ '  ' then regexp_replace(btrim(c."name"), '\s+', ' ', 'g')
            else c."name"
        end as "name",
        case
            when btrim(c."objective") = '' or btrim(c."objective") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(c."objective") not in ('acquisition', 'retention', 'reactivation', 'clearance') then c."objective"
            else c."objective"
        end as "objective",
        case
            when btrim(c."valid_from") = '' or btrim(c."valid_from") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) and (substring(c."valid_from" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_from" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_from" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."valid_from" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."valid_from" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."valid_from" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) when c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."valid_from" from 7 for 4)::int between 1 and 9999 and substring(c."valid_from" from 4 for 2)::int between 1 and 12 and substring(c."valid_from" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 1 for 2)::int > 30) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int > 29) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int = 29 and not (substring(c."valid_from" from 7 for 4)::int % 4 = 0 and (substring(c."valid_from" from 7 for 4)::int % 100 <> 0 or substring(c."valid_from" from 7 for 4)::int % 400 = 0)))) when c."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."valid_from"
            when case when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) then left(c."valid_from", 10)::date > date '{{ var("as_of_date") }}' else false end then c."valid_from"
            when case when c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."valid_from" from 7 for 4)::int between 1 and 9999 and substring(c."valid_from" from 4 for 2)::int between 1 and 12 and substring(c."valid_from" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 1 for 2)::int > 30) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int > 29) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int = 29 and not (substring(c."valid_from" from 7 for 4)::int % 4 = 0 and (substring(c."valid_from" from 7 for 4)::int % 100 <> 0 or substring(c."valid_from" from 7 for 4)::int % 400 = 0)))) when c."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) else false end then case when c."valid_from" ~ '^[0-9]{2}/' then to_date(c."valid_from", 'DD/MM/YYYY')::text else to_date(c."valid_from", 'YYYY.MM.DD')::text end
            when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."valid_from" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."valid_from" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_from" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_from" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."valid_from"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' or c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."valid_from"
            else c."valid_from"
        end as "valid_from",
        case
            when btrim(c."valid_to") = '' or btrim(c."valid_to") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when case when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."valid_to" from 1 for 4)::int between 1 and 9999 and substring(c."valid_to" from 6 for 2)::int between 1 and 12 and substring(c."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 9 for 2)::int > 30) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int > 29) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int = 29 and not (substring(c."valid_to" from 1 for 4)::int % 4 = 0 and (substring(c."valid_to" from 1 for 4)::int % 100 <> 0 or substring(c."valid_to" from 1 for 4)::int % 400 = 0)))) and (substring(c."valid_to" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_to" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_to" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."valid_to" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."valid_to" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."valid_to" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."valid_to" from 1 for 4)::int between 1 and 9999 and substring(c."valid_to" from 6 for 2)::int between 1 and 12 and substring(c."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 9 for 2)::int > 30) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int > 29) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int = 29 and not (substring(c."valid_to" from 1 for 4)::int % 4 = 0 and (substring(c."valid_to" from 1 for 4)::int % 100 <> 0 or substring(c."valid_to" from 1 for 4)::int % 400 = 0)))) when c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."valid_to" from 7 for 4)::int between 1 and 9999 and substring(c."valid_to" from 4 for 2)::int between 1 and 12 and substring(c."valid_to" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 1 for 2)::int > 30) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int > 29) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int = 29 and not (substring(c."valid_to" from 7 for 4)::int % 4 = 0 and (substring(c."valid_to" from 7 for 4)::int % 100 <> 0 or substring(c."valid_to" from 7 for 4)::int % 400 = 0)))) when c."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then c."valid_to"
            when case when c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."valid_to" from 7 for 4)::int between 1 and 9999 and substring(c."valid_to" from 4 for 2)::int between 1 and 12 and substring(c."valid_to" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 1 for 2)::int > 30) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int > 29) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int = 29 and not (substring(c."valid_to" from 7 for 4)::int % 4 = 0 and (substring(c."valid_to" from 7 for 4)::int % 100 <> 0 or substring(c."valid_to" from 7 for 4)::int % 400 = 0)))) when c."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."valid_to" from 1 for 4)::int between 1 and 9999 and substring(c."valid_to" from 6 for 2)::int between 1 and 12 and substring(c."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 9 for 2)::int > 30) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int > 29) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int = 29 and not (substring(c."valid_to" from 1 for 4)::int % 4 = 0 and (substring(c."valid_to" from 1 for 4)::int % 100 <> 0 or substring(c."valid_to" from 1 for 4)::int % 400 = 0)))) else false end then case when c."valid_to" ~ '^[0-9]{2}/' then to_date(c."valid_to", 'DD/MM/YYYY')::text else to_date(c."valid_to", 'YYYY.MM.DD')::text end
            when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."valid_to" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."valid_to" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_to" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_to" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then (c."valid_to"::timestamp at time zone 'America/Sao_Paulo')::text
            when not (c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' or c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then c."valid_to"
            else c."valid_to"
        end as "valid_to",
        case
            when btrim(c."budget_amount") = '' or btrim(c."budget_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when btrim(replace(replace(c."budget_amount", 'R$', ''), ' ', '')) ~ '^-' then c."budget_amount"
            when c."budget_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."budget_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."budget_amount", 'R$', ''), ' ', ''), ',', '')) then case when c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' then replace(replace(replace(replace(c."budget_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') else replace(replace(replace(c."budget_amount", 'R$', ''), ' ', ''), ',', '') end
            when c."budget_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then c."budget_amount"
            else c."budget_amount"
        end as "budget_amount",
        case
            when btrim(c."is_active") = '' or btrim(c."is_active") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then null
            when c."is_active" not in ('true', 'false') and lower(btrim(c."is_active")) in ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no') then case when lower(btrim(c."is_active")) in ('true', 'sim', 's', '1', 'y', 'yes') then 'true' else 'false' end
            when btrim(c."is_active") not in ('true', 'false') then c."is_active"
            else c."is_active"
        end as "is_active",
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
    l."code",
    l."name",
    l."objective",
    l."valid_from",
    l."valid_to",
    l."budget_amount",
    l."is_active",
    l."created_at",
    l."updated_at",
    l."deleted_at",

    -- ── Achados por coluna, sem os nulos ─────────────────────────────────────
    jsonb_strip_nulls(
        jsonb_build_object(
            'id', case
            when btrim(c."id") = '' or btrim(c."id") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
        end,
            'code', case
            when btrim(c."code") = '' or btrim(c."code") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."code" like '%;%' and (c."name" is null or btrim(c."name") = '') and (c."objective" is null or btrim(c."objective") = '') then 'TEXT_DELIMITER'
            when c."code" ~ '(Ã[-¿]|Â[-¿])' and c."code" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."code" ~ '(Ã[-¿]|Â[-¿])' and c."code" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."code" <> btrim(c."code") or c."code" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'name', case
            when btrim(c."name") = '' or btrim(c."name") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when length(c."name") = 24 then 'TEXT_TRUNCATED'
            when c."name" like '%;%' and (c."objective" is null or btrim(c."objective") = '') and (c."valid_from" is null or btrim(c."valid_from") = '') then 'TEXT_DELIMITER'
            when c."name" ~ '(Ã[-¿]|Â[-¿])' and c."name" ~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING'
            when c."name" ~ '(Ã[-¿]|Â[-¿])' and c."name" !~ '^([\u0001-\u007f]|[\u00c2-\u00df][\u0080-\u00bf]|\u00e0[\u00a0-\u00bf][\u0080-\u00bf]|[\u00e1-\u00ec][\u0080-\u00bf]{2}|\u00ed[\u0080-\u009f][\u0080-\u00bf]|[\u00ee-\u00ef][\u0080-\u00bf]{2}|\u00f0[\u0090-\u00bf][\u0080-\u00bf]{2}|[\u00f1-\u00f3][\u0080-\u00bf]{3}|\u00f4[\u0080-\u008f][\u0080-\u00bf]{2})*$' then 'TEXT_ENCODING_AMBIGUOUS'
            when c."name" <> btrim(c."name") or c."name" ~ '  ' then 'TEXT_WHITESPACE_CASE'
        end,
            'objective', case
            when btrim(l."objective") not in ('acquisition', 'retention', 'reactivation', 'clearance') then 'ENUM_UNKNOWN'
            when btrim(c."objective") = '' or btrim(c."objective") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(c."objective") not in ('acquisition', 'retention', 'reactivation', 'clearance') then 'ENUM_UNKNOWN'
        end,
            'valid_from', case
            when case when l."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."valid_from" from 1 for 4)::int between 1 and 9999 and substring(l."valid_from" from 6 for 2)::int between 1 and 12 and substring(l."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(l."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."valid_from" from 9 for 2)::int > 30) and not (substring(l."valid_from" from 6 for 2)::int = 2 and substring(l."valid_from" from 9 for 2)::int > 29) and not (substring(l."valid_from" from 6 for 2)::int = 2 and substring(l."valid_from" from 9 for 2)::int = 29 and not (substring(l."valid_from" from 1 for 4)::int % 4 = 0 and (substring(l."valid_from" from 1 for 4)::int % 100 <> 0 or substring(l."valid_from" from 1 for 4)::int % 400 = 0)))) and (substring(l."valid_from" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."valid_from" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."valid_from" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."valid_from" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."valid_from" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."valid_from" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."valid_from" from 1 for 4)::int between 1 and 9999 and substring(l."valid_from" from 6 for 2)::int between 1 and 12 and substring(l."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(l."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."valid_from" from 9 for 2)::int > 30) and not (substring(l."valid_from" from 6 for 2)::int = 2 and substring(l."valid_from" from 9 for 2)::int > 29) and not (substring(l."valid_from" from 6 for 2)::int = 2 and substring(l."valid_from" from 9 for 2)::int = 29 and not (substring(l."valid_from" from 1 for 4)::int % 4 = 0 and (substring(l."valid_from" from 1 for 4)::int % 100 <> 0 or substring(l."valid_from" from 1 for 4)::int % 400 = 0)))) when l."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."valid_from" from 7 for 4)::int between 1 and 9999 and substring(l."valid_from" from 4 for 2)::int between 1 and 12 and substring(l."valid_from" from 1 for 2)::int between 1 and 31 and not (substring(l."valid_from" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."valid_from" from 1 for 2)::int > 30) and not (substring(l."valid_from" from 4 for 2)::int = 2 and substring(l."valid_from" from 1 for 2)::int > 29) and not (substring(l."valid_from" from 4 for 2)::int = 2 and substring(l."valid_from" from 1 for 2)::int = 29 and not (substring(l."valid_from" from 7 for 4)::int % 4 = 0 and (substring(l."valid_from" from 7 for 4)::int % 100 <> 0 or substring(l."valid_from" from 7 for 4)::int % 400 = 0)))) when l."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when l."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(l."valid_from" from 1 for 4)::int between 1 and 9999 and substring(l."valid_from" from 6 for 2)::int between 1 and 12 and substring(l."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(l."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."valid_from" from 9 for 2)::int > 30) and not (substring(l."valid_from" from 6 for 2)::int = 2 and substring(l."valid_from" from 9 for 2)::int > 29) and not (substring(l."valid_from" from 6 for 2)::int = 2 and substring(l."valid_from" from 9 for 2)::int = 29 and not (substring(l."valid_from" from 1 for 4)::int % 4 = 0 and (substring(l."valid_from" from 1 for 4)::int % 100 <> 0 or substring(l."valid_from" from 1 for 4)::int % 400 = 0)))) then left(l."valid_from", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when not (l."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' or l."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."valid_from") = '' or btrim(c."valid_from") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) and (substring(c."valid_from" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_from" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_from" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."valid_from" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."valid_from" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."valid_from" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) when c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."valid_from" from 7 for 4)::int between 1 and 9999 and substring(c."valid_from" from 4 for 2)::int between 1 and 12 and substring(c."valid_from" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 1 for 2)::int > 30) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int > 29) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int = 29 and not (substring(c."valid_from" from 7 for 4)::int % 4 = 0 and (substring(c."valid_from" from 7 for 4)::int % 100 <> 0 or substring(c."valid_from" from 7 for 4)::int % 400 = 0)))) when c."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' and (substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) then left(c."valid_from", 10)::date > date '{{ var("as_of_date") }}' else false end then 'DATE_FUTURE'
            when case when c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."valid_from" from 7 for 4)::int between 1 and 9999 and substring(c."valid_from" from 4 for 2)::int between 1 and 12 and substring(c."valid_from" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 1 for 2)::int > 30) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int > 29) and not (substring(c."valid_from" from 4 for 2)::int = 2 and substring(c."valid_from" from 1 for 2)::int = 29 and not (substring(c."valid_from" from 7 for 4)::int % 4 = 0 and (substring(c."valid_from" from 7 for 4)::int % 100 <> 0 or substring(c."valid_from" from 7 for 4)::int % 400 = 0)))) when c."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."valid_from" from 1 for 4)::int between 1 and 9999 and substring(c."valid_from" from 6 for 2)::int between 1 and 12 and substring(c."valid_from" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_from" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_from" from 9 for 2)::int > 30) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int > 29) and not (substring(c."valid_from" from 6 for 2)::int = 2 and substring(c."valid_from" from 9 for 2)::int = 29 and not (substring(c."valid_from" from 1 for 4)::int % 4 = 0 and (substring(c."valid_from" from 1 for 4)::int % 100 <> 0 or substring(c."valid_from" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."valid_from" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."valid_from" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_from" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_from" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."valid_from" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."valid_from" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."valid_from" ~ '^[0-9]{2}/[0-9]{4}$' or c."valid_from" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'valid_to', case
            when case when l."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(l."valid_to" from 1 for 4)::int between 1 and 9999 and substring(l."valid_to" from 6 for 2)::int between 1 and 12 and substring(l."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(l."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."valid_to" from 9 for 2)::int > 30) and not (substring(l."valid_to" from 6 for 2)::int = 2 and substring(l."valid_to" from 9 for 2)::int > 29) and not (substring(l."valid_to" from 6 for 2)::int = 2 and substring(l."valid_to" from 9 for 2)::int = 29 and not (substring(l."valid_to" from 1 for 4)::int % 4 = 0 and (substring(l."valid_to" from 1 for 4)::int % 100 <> 0 or substring(l."valid_to" from 1 for 4)::int % 400 = 0)))) and (substring(l."valid_to" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(l."valid_to" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(l."valid_to" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(l."valid_to" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(l."valid_to" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when l."valid_to" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(l."valid_to" from 1 for 4)::int between 1 and 9999 and substring(l."valid_to" from 6 for 2)::int between 1 and 12 and substring(l."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(l."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(l."valid_to" from 9 for 2)::int > 30) and not (substring(l."valid_to" from 6 for 2)::int = 2 and substring(l."valid_to" from 9 for 2)::int > 29) and not (substring(l."valid_to" from 6 for 2)::int = 2 and substring(l."valid_to" from 9 for 2)::int = 29 and not (substring(l."valid_to" from 1 for 4)::int % 4 = 0 and (substring(l."valid_to" from 1 for 4)::int % 100 <> 0 or substring(l."valid_to" from 1 for 4)::int % 400 = 0)))) when l."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(l."valid_to" from 7 for 4)::int between 1 and 9999 and substring(l."valid_to" from 4 for 2)::int between 1 and 12 and substring(l."valid_to" from 1 for 2)::int between 1 and 31 and not (substring(l."valid_to" from 4 for 2)::int in (4, 6, 9, 11) and substring(l."valid_to" from 1 for 2)::int > 30) and not (substring(l."valid_to" from 4 for 2)::int = 2 and substring(l."valid_to" from 1 for 2)::int > 29) and not (substring(l."valid_to" from 4 for 2)::int = 2 and substring(l."valid_to" from 1 for 2)::int = 29 and not (substring(l."valid_to" from 7 for 4)::int % 4 = 0 and (substring(l."valid_to" from 7 for 4)::int % 100 <> 0 or substring(l."valid_to" from 7 for 4)::int % 400 = 0)))) when l."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when not (l."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or l."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or l."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or l."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' or l."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
            when btrim(c."valid_to") = '' or btrim(c."valid_to") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when case when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$'   then not ((substring(c."valid_to" from 1 for 4)::int between 1 and 9999 and substring(c."valid_to" from 6 for 2)::int between 1 and 12 and substring(c."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 9 for 2)::int > 30) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int > 29) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int = 29 and not (substring(c."valid_to" from 1 for 4)::int % 4 = 0 and (substring(c."valid_to" from 1 for 4)::int % 100 <> 0 or substring(c."valid_to" from 1 for 4)::int % 400 = 0)))) and (substring(c."valid_to" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_to" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_to" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) and (coalesce(substring(c."valid_to" from '[+-]([0-9]{2})(:?[0-9]{2})?$'), '00')::int between 0 and 15 and coalesce(substring(c."valid_to" from '[+-][0-9]{2}:?([0-9]{2})$'), '00')::int between 0 and 59)) when c."valid_to" ~ '^[0-9]{4}[-.][0-9]{2}[-.][0-9]{2}$'   then not (substring(c."valid_to" from 1 for 4)::int between 1 and 9999 and substring(c."valid_to" from 6 for 2)::int between 1 and 12 and substring(c."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 9 for 2)::int > 30) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int > 29) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int = 29 and not (substring(c."valid_to" from 1 for 4)::int % 4 = 0 and (substring(c."valid_to" from 1 for 4)::int % 100 <> 0 or substring(c."valid_to" from 1 for 4)::int % 400 = 0)))) when c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then not (substring(c."valid_to" from 7 for 4)::int between 1 and 9999 and substring(c."valid_to" from 4 for 2)::int between 1 and 12 and substring(c."valid_to" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 1 for 2)::int > 30) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int > 29) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int = 29 and not (substring(c."valid_to" from 7 for 4)::int % 4 = 0 and (substring(c."valid_to" from 7 for 4)::int % 100 <> 0 or substring(c."valid_to" from 7 for 4)::int % 400 = 0)))) when c."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' then true else false end then 'DATE_IMPOSSIBLE'
            when case when c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'   then (substring(c."valid_to" from 7 for 4)::int between 1 and 9999 and substring(c."valid_to" from 4 for 2)::int between 1 and 12 and substring(c."valid_to" from 1 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 4 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 1 for 2)::int > 30) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int > 29) and not (substring(c."valid_to" from 4 for 2)::int = 2 and substring(c."valid_to" from 1 for 2)::int = 29 and not (substring(c."valid_to" from 7 for 4)::int % 4 = 0 and (substring(c."valid_to" from 7 for 4)::int % 100 <> 0 or substring(c."valid_to" from 7 for 4)::int % 400 = 0)))) when c."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'   then (substring(c."valid_to" from 1 for 4)::int between 1 and 9999 and substring(c."valid_to" from 6 for 2)::int between 1 and 12 and substring(c."valid_to" from 9 for 2)::int between 1 and 31 and not (substring(c."valid_to" from 6 for 2)::int in (4, 6, 9, 11) and substring(c."valid_to" from 9 for 2)::int > 30) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int > 29) and not (substring(c."valid_to" from 6 for 2)::int = 2 and substring(c."valid_to" from 9 for 2)::int = 29 and not (substring(c."valid_to" from 1 for 4)::int % 4 = 0 and (substring(c."valid_to" from 1 for 4)::int % 100 <> 0 or substring(c."valid_to" from 1 for 4)::int % 400 = 0)))) else false end then 'DATE_FORMAT_KNOWN'
            when c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' and c."valid_to" !~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' and (substring(c."valid_to" from '[ T]([0-9]{2}):[0-9]{2}')::int between 0 and 23 and substring(c."valid_to" from '[ T][0-9]{2}:([0-9]{2})')::int between 0 and 59 and coalesce(substring(c."valid_to" from '[ T][0-9]{2}:[0-9]{2}:([0-9]{2})'), '00')::int between 0 and 59) then 'DATE_TZ_MISSING'
            when not (c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or c."valid_to" ~ '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' or c."valid_to" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' or c."valid_to" ~ '^[0-9]{2}/[0-9]{4}$' or c."valid_to" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]+)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$') then 'DATE_UNPARSEABLE'
        end,
            'budget_amount', case
            when btrim(replace(replace(l."budget_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when l."budget_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
            when btrim(c."budget_amount") = '' or btrim(c."budget_amount") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when btrim(replace(replace(c."budget_amount", 'R$', ''), ' ', '')) ~ '^-' then 'MONEY_NEGATIVE'
            when c."budget_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' and (c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and not ((c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(\.[0-9]{3})*,[0-9]{1,4}$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+,[0-9]{1,4}$') and (c."budget_amount" ~ '^-?(R\$)?\s*[0-9]{1,3}(,[0-9]{3})+(\.[0-9]{1,4})?$' or c."budget_amount" ~ '^-?(R\$)?\s*[0-9]+(\.[0-9]{1,4})?$') and replace(replace(replace(replace(c."budget_amount", 'R$', ''), ' ', ''), '.', ''), ',', '.') is distinct from replace(replace(replace(c."budget_amount", 'R$', ''), ' ', ''), ',', '')) then 'MONEY_LOCALE'
            when c."budget_amount" !~ '^-?[0-9]+(\.[0-9]{1,4})?$' then 'MONEY_AMBIGUOUS'
        end,
            'is_active', case
            when btrim(l."is_active") not in ('true', 'false') then 'ENUM_UNKNOWN'
            when btrim(c."is_active") = '' or btrim(c."is_active") in ('NULL', 'null', 'N/A', '-', '#N/D', '   ') then 'NULL_DISGUISED'
            when c."is_active" not in ('true', 'false') and lower(btrim(c."is_active")) in ('true', 'false', 'sim', 'nao', 'não', 's', 'n', '1', '0', 'y', 'yes', 'no') then 'BOOL_VARIANT'
            when btrim(c."is_active") not in ('true', 'false') then 'ENUM_UNKNOWN'
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
    jsonb_build_object('id', c."id", 'code', c."code", 'name', c."name", 'objective', c."objective", 'valid_from', c."valid_from", 'valid_to', c."valid_to", 'budget_amount', c."budget_amount", 'is_active', c."is_active", 'created_at', c."created_at", 'updated_at', c."updated_at", 'deleted_at', c."deleted_at")              as original_payload
from captura c
join limpo l on l.legacy_row_id = c.legacy_row_id{% endif %}
