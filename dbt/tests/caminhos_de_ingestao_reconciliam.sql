-- Critério de conclusão da Etapa 7: *backfill* e streaming não duplicam linhas
-- na fato — e, o outro lado da mesma moeda, nenhum dos dois perde evento.
--
-- Os dois caminhos do ADR-0031 carregam o mesmo livro imutável: o Airbyte por
-- carga completa, o CDC por captura contínua com *snapshot* inicial. A
-- sobreposição é total por construção, então **todo** movimento deve ter
-- chegado pelos dois.
--
-- O que cada falha significa:
--
--   só pelo lote    → o CDC tem lacuna: o conector perdeu o evento, ou o
--                     pipeline o descartou. É o defeito grave, porque o
--                     streaming é o caminho oficial de ingestão incremental.
--   só pelo fluxo   → a carga de reconciliação está velha. Esperado logo após
--                     produzir eventos novos, e é por isso que o teste tolera a
--                     janela declarada abaixo, e só ela.
--
-- A duplicação, que é a outra metade do critério, não precisa de teste próprio:
-- `movement_id` é chave primária da fato, e o teste `unique` dela já falharia.
-- O que este teste acrescenta é o caso que a unicidade **não** vê — o evento
-- que existe de um lado só.

with divergentes as (

    select
        movement_id,
        occurred_at,
        recorded_at,
        arrived_by_stream,
        arrived_by_batch
    from {{ ref('stg_retail__inventory_movements') }}
    where not (arrived_by_stream and arrived_by_batch)

)

select *
from divergentes
-- Evento recém-produzido ainda não foi alcançado pela carga completa do
-- Airbyte, que roda sob demanda e fora do caminho crítico. A tolerância é a
-- mesma margem de atraso da fato incremental: um número já declarado, e não
-- mais um limiar inventado aqui.
where arrived_by_stream is false
   or recorded_at < (
        select max(recorded_at) - interval '{{ var("atraso_maximo_dias") }} days'
        from {{ ref('stg_retail__inventory_movements') }}
      )
