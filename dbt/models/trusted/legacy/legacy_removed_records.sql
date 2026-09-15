-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  GERADO por `make legacy-models` a partir de src/mvp_ed1/legacy/         ║
-- ║  catalogo.yml. Não edite este arquivo: a próxima geração o sobrescreve.  ║
-- ║  Erro aqui é sintoma — corrija no catálogo ou em `regras.py`.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- A memória da ausência: o que já sumiu da origem legada e não voltou (ADR-0045).
--
-- Chave presente em **qualquer** captura certificada anterior à selecionada e
-- ausente nela. `last_seen_snapshot_id` é a maior onde esteve;
-- `removed_in_snapshot_id` é a menor certificada **posterior a ela** — depois
-- de um reaparecimento e nova exclusão, as duas avançam juntas. Persiste por
-- construção em toda captura seguinte; sai quando a chave reaparece. Não entra
-- em equação nenhuma: é auditoria. O payload é o **bruto** da última captura em
-- que a chave existiu — não é tratado, e o dicionário diz isso.

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

presenca as (

    select * from {{ ref('legacy_presence_by_capture') }}
    where business_key is not null

),

historico as (

    select p.*
    from presenca p
    join certificadas c on c.snapshot_id = p.snapshot_id
    where p.snapshot_id < (select snapshot_id from selecionada)

),

presentes_agora as (

    select source_table, business_key
    from presenca
    where snapshot_id = (select snapshot_id from selecionada)

),

ausentes as (

    select h.source_table, h.business_key, max(h.snapshot_id) as last_seen_snapshot_id
    from historico h
    where not exists (
        select 1 from presentes_agora a
        where a.source_table = h.source_table and a.business_key = h.business_key
    )
    group by 1, 2

)

select
    a.source_table,
    a.business_key,
    a.last_seen_snapshot_id,
    (
        select min(c.snapshot_id) from certificadas c
        where c.snapshot_id > a.last_seen_snapshot_id
          and c.snapshot_id <= (select snapshot_id from selecionada)
    )                                                   as removed_in_snapshot_id,
    (select snapshot_id from selecionada)               as observed_in_snapshot_id,
    h.n                                                 as rows_last_seen,
    h.payloads                                          as last_payload
from ausentes a
join historico h
  on h.source_table = a.source_table
 and h.business_key = a.business_key
 and h.snapshot_id = a.last_seen_snapshot_id
