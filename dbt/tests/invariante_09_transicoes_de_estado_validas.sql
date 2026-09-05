-- Invariante 9 — os estados do pedido seguem transições válidas.
--
-- O `CHECK` da origem garante que origem e destino pertencem ao domínio e que
-- são diferentes entre si. Nenhum `CHECK` garante o que importa: que o **par**
-- é permitido. `paid → delivered` passa em todos os `CHECK` e é uma remessa que
-- nunca foi separada nem despachada.
--
-- A lista do que é permitido está na *seed* `order_status_transitions` — regra
-- em artefato declarativo, revisável de uma olhada, e não espalhada em `case`
-- dentro de modelo.
--
-- O `nullif` existe porque o CSV entrega a transição inicial com o campo vazio,
-- e vazio não é nulo: sem ele, a criação do pedido pareceria transição ilegal.

with permitidas as (

    select
        nullif(from_status, '')     as from_status,
        to_status
    from {{ ref('order_status_transitions') }}

),

observadas as (

    select distinct
        from_status,
        to_status
    from {{ ref('order_status_events') }}

)

select
    o.from_status,
    o.to_status
from observadas o
left join permitidas p
       on p.to_status = o.to_status
      and p.from_status is not distinct from o.from_status
where p.to_status is null
