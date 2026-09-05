-- Transportadoras, com a modalidade que cada uma presta.
--
-- A modalidade (`service_level`) é o que P13 chama de *modalidade* e é o que
-- fixa a promessa de prazo na origem: `standard` promete de 4 a 9 dias,
-- `express` de 2 a 4 e `same_day` de 0 a 1. Ela não é atributo decorativo da
-- transportadora — é a metade da definição de **entrega no prazo**.

select
    c.carrier_id,
    c.carrier_code,
    c.carrier_name,
    c.service_level,

    -- Ordem da modalidade, para que o relatório saia do mais lento ao mais
    -- rápido sem que cada view repita o `case`.
    case c.service_level
        when 'standard' then 1
        when 'express'  then 2
        when 'same_day' then 3
    end                                         as service_level_rank,

    c.tracking_url_template,
    c.is_active,
    c.is_deleted,
    c.source_created_at,
    c.source_updated_at
from {{ ref('stg_retail__carriers') }} c
