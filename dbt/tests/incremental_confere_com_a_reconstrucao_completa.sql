-- Quarta proteção da exceção incremental (ADR-0016).
--
-- A exceção de `fact_inventory_movement` só foi concedida com quatro
-- proteções, e esta é a que as demais dependem: **o resultado incremental
-- precisa ser idêntico ao da reconstrução completa**.
--
-- Sem ela, as outras três são cerimônia. Um filtro de janela mal calibrado ou
-- um evento atrasado além da margem produzem uma fato que parece certa, cresce
-- normalmente e está incompleta — e nada avisa.
--
-- O teste compara contra `trusted.inventory_movements`, que é reconstruído
-- inteiro a cada execução por ser `table`. Divergência aqui significa: rode
-- `dbt build --full-refresh --select fact_inventory_movement`, e investigue a
-- margem de atraso antes de aceitar o resultado.

with fato as (

    select
        count(*)                    as linhas,
        sum(quantity_delta)         as saldo,
        round(sum(cogs_amount), 2)  as cmv
    from {{ ref('fact_inventory_movement') }}

),

completo as (

    select
        count(*)                    as linhas,
        sum(quantity_delta)         as saldo,
        round(sum(cogs_amount), 2)  as cmv
    from {{ ref('inventory_movements') }}

)

select
    f.linhas    as linhas_incremental,
    c.linhas    as linhas_completo,
    f.saldo     as saldo_incremental,
    c.saldo     as saldo_completo,
    f.cmv       as cmv_incremental,
    c.cmv       as cmv_completo
from fato f, completo c
where f.linhas <> c.linhas
   or f.saldo <> c.saldo
   or f.cmv <> c.cmv
