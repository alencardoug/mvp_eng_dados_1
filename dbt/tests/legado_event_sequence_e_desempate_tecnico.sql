-- O contrato de `event_sequence` nas linhas legadas — e só ele (D40, 14/09/2026).
--
-- Na origem principal a coluna é a ordenação técnica do banco. No legado ela é
-- `legacy_row_id`, a identidade da ocorrência física, e o que se promete é
-- **desempate técnico dentro da captura**: presente e único entre as linhas
-- legadas do empilhamento. Nada além disso — não é ordem observada do evento e
-- não é estável entre recapturas, porque `legacy_row_id` recomeça em 1 a cada
-- geração. O teste cobra exatamente o que o contrato diz, e nada que ele não diz.
--
-- Uma linha no resultado é uma sequência legada ausente ou repetida.

with legadas as (

    select event_sequence
    from {{ ref('inventory_movements') }}
    where source_system = 'legacy'

)

select event_sequence, count(*) as ocorrencias
from legadas
group by event_sequence
having event_sequence is null or count(*) > 1
