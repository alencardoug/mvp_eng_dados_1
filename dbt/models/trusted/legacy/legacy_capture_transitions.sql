-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- O intervalo entre a certificada anterior mais recente e a selecionada (ADR-0045).
--
-- Por tabela e chave canônica, com **multiplicidade**: `removida` (n > 0 → 0),
-- `adicionada` (0 → n > 0), `reduzida`/`aumentada` (as duas > 0 e diferentes),
-- `mantida`. Linhas sem identidade entram como `sem_identidade`, por lado.
-- Sem anterior certificada não há intervalo: o modelo fica vazio, e o teste de
-- reconciliação não tem o que cobrar.

{{ config(materialized='table') }}

with certificadas as (

    select snapshot_id
    from {{ source('governance', 'legacy_captures') }}
    where status = 'complete'
    group by snapshot_id
    having count(distinct source_table) = 40

),

selecionada as (

    select snapshot_id from {{ ref('legacy_selected_capture') }}

),

anterior as (

    select max(snapshot_id) as snapshot_id
    from certificadas
    where snapshot_id < (select snapshot_id from selecionada)

),

presenca as (

    select * from {{ ref('legacy_presence_by_capture') }}

),

lado_anterior as (

    select source_table, business_key, n
    from presenca
    where snapshot_id = (select snapshot_id from anterior)

),

lado_selecionado as (

    select source_table, business_key, n
    from presenca
    where snapshot_id = (select snapshot_id from selecionada)
      and (select snapshot_id from anterior) is not null

),

com_identidade as (

    select
        coalesce(a.source_table, s.source_table)        as source_table,
        coalesce(a.business_key, s.business_key)        as business_key,
        coalesce(a.n, 0)                                as n_anterior,
        coalesce(s.n, 0)                                as n_selecionada
    from (select * from lado_anterior where business_key is not null) a
    full outer join (select * from lado_selecionado where business_key is not null) s
      on s.source_table = a.source_table and s.business_key = a.business_key

),

sem_identidade as (

    select
        coalesce(a.source_table, s.source_table)        as source_table,
        null::text                                      as business_key,
        coalesce(a.n, 0)                                as n_anterior,
        coalesce(s.n, 0)                                as n_selecionada
    from (select * from lado_anterior where business_key is null) a
    full outer join (select * from lado_selecionado where business_key is null) s
      on s.source_table = a.source_table

)

select
    (select snapshot_id from anterior)                  as previous_snapshot_id,
    (select snapshot_id from selecionada)               as selected_snapshot_id,
    source_table,
    business_key,
    n_anterior                                          as rows_before,
    n_selecionada                                       as rows_after,
    case
        when business_key is null                       then 'sem_identidade'
        when n_anterior > 0 and n_selecionada = 0       then 'removida'
        when n_anterior = 0 and n_selecionada > 0       then 'adicionada'
        when n_anterior > n_selecionada                 then 'reduzida'
        when n_anterior < n_selecionada                 then 'aumentada'
        else                                                 'mantida'
    end                                                 as transition
from (select * from com_identidade union all select * from sem_identidade) t
where (select snapshot_id from anterior) is not null
