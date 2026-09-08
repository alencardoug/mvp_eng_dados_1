-- A partição legada da fato é exatamente a captura corrente — nos dois sentidos.
--
-- O teste de reconciliação irmão
-- (`incremental_confere_com_a_reconstrucao_completa`) compara **agregados**:
-- contagem, saldo e CMV. Ele pega a maioria dos desvios e não pega o que se
-- compensa — uma linha a mais e outra a menos, com o mesmo `quantity_delta`,
-- fecham os três números e deixam a fato errada. Este confere **linha a linha**,
-- e só do ramo legado, que é onde o ADR-0042 mudou a estratégia.
--
-- ── O que cada lado prova ───────────────────────────────────────────────────
-- `sobrou_na_fato`: movimento legado materializado que a captura corrente não
-- tem mais. É o caminho que o `merge` sozinho nunca fecharia — `merge` só faz
-- *upsert*, e o registro que deixa de vir numa recaptura ficaria de pé até o
-- `--full-refresh` agendado, corrompendo o saldo em silêncio no meio-tempo.
--
-- `faltou_na_fato`: movimento apto na captura corrente que a fato não tem. É o
-- caminho da **aptidão nova fora da janela** — uma correção de tratamento torna
-- apto o que era rejeitado, e o `occurred_at` dele é antigo demais para a
-- margem de atraso alcançar.
--
-- Os dois eram invisíveis antes do ADR-0042, e nenhum aparece numa fato que
-- nasceu de reconstrução completa: é exatamente por isso que o achado R25 dizia
-- que reconstrução inicial não prova reprocessamento.

with na_fato as (

    select movement_id
    from {{ ref('fact_inventory_movement') }}
    where source_system = 'legacy'

),

na_captura as (

    select movement_id
    from {{ ref('inventory_movements') }}
    where source_system = 'legacy'

)

select
    coalesce(f.movement_id, c.movement_id)      as movement_id,
    f.movement_id is not null
        and c.movement_id is null               as sobrou_na_fato,
    c.movement_id is not null
        and f.movement_id is null               as faltou_na_fato
from na_fato f
full outer join na_captura c
  on c.movement_id = f.movement_id
where f.movement_id is null
   or c.movement_id is null
