-- O que foi empilhado é exatamente o que foi julgado apto.
--
-- A segunda equação da Origem Legada §6 — `empilhados = aceitos + corrigidos` —
-- só pode ser conferida **na fronteira do empilhamento**, e até esta entrega
-- essa fronteira não existia: o conjunto apto era construído e ninguém o lia.
--
-- Confere nos dois sentidos, por tabela: nada apto ficou de fora, e nada que
-- não fosse apto entrou.

with aptos as (

    select source_table, count(*) as quantidade
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'customers'
    group by source_table

),

empilhados as (

    select 'customers' as source_table, count(*) as quantidade
    from {{ ref('customers') }}
    where source_system = 'legacy'

)

select
    coalesce(a.source_table, e.source_table)     as tabela,
    coalesce(a.quantidade, 0)                   as aptos,
    coalesce(e.quantidade, 0)                   as empilhados
from aptos a
full outer join empilhados e on e.source_table = a.source_table
where coalesce(a.quantidade, 0) <> coalesce(e.quantidade, 0)
