-- Critério de conclusão da Etapa 7: transferência confere dos dois lados.
--
-- Uma transferência é **um** fato de negócio gravado como **dois** eventos, no
-- armazém de origem e no de destino, unidos pelo `correlation_id`. É o único
-- caso do livro em que a soma de duas linhas tem de dar exatamente zero.
--
-- Por que é o teste certo para esta etapa: um par que não fecha some do saldo
-- consolidado sem deixar rastro. Nenhuma `CHECK` o pega — o banco valida linha
-- a linha, e cada uma das duas está perfeitamente válida sozinha. E é o caso
-- que o caminho quente mais ameaça: se o CDC perder um dos lados, ou se a
-- deduplicação descartar um deles por engano, o desequilíbrio aparece aqui e em
-- nenhum outro lugar.

with pares as (

    select
        correlation_id,
        sum(quantity_delta)                                     as desequilibrio,
        count(*)                                                as lados,
        count(*) filter (where movement_type = 'transfer_out')   as saidas,
        count(*) filter (where movement_type = 'transfer_in')    as entradas,
        count(distinct warehouse_id)                             as armazens,
        count(distinct product_variant_id)                       as skus
    from {{ ref('inventory_movements') }}
    where movement_type in ('transfer_out', 'transfer_in')
    group by correlation_id

)

select *
from pares
where desequilibrio <> 0            -- o que saiu não é o que entrou
   or lados <> 2                    -- par incompleto, ou triplicado
   or saidas <> 1 or entradas <> 1  -- dois lados do mesmo sentido
   or armazens <> 2                 -- transferência para o próprio armazém
   or skus <> 1                     -- saiu um SKU e entrou outro
