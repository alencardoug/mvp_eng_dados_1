-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A captura do legado que esta execução lê.
--
-- `legacy_snapshot_id` escolhe explicitamente, para reprocessar uma captura
-- antiga; sem ele, vale a mais recente **certificada** — `complete` nas 40
-- tabelas em `governance.legacy_captures` (ADR-0044). Que a escolhida exista
-- e seja íntegra não se assume: é o que `legacy_captura_existe` e
-- `legacy_captura_completa` conferem.

{{ config(materialized='table') }}

{% if target.type == 'bigquery' %}
WITH certificadas AS (
  SELECT
    snapshot_id
  FROM {{ source('governance', 'legacy_captures') }}
  WHERE
    status = 'complete'
  GROUP BY
    snapshot_id
  HAVING
    COUNT(DISTINCT source_table) = 40
)
SELECT
  CAST(COALESCE({{ legacy_snapshot_id() }}, (
    SELECT
      MAX(snapshot_id)
    FROM certificadas
  )) AS INT64) AS snapshot_id
{% else %}with certificadas as (

    select snapshot_id
    from {{ source('governance', 'legacy_captures') }}
    where status = 'complete'
    group by snapshot_id
    having count(distinct source_table) = 40

)

select coalesce(
    {{ legacy_snapshot_id() }},
    (select max(snapshot_id) from certificadas)
)::bigint                                       as snapshot_id{% endif %}
