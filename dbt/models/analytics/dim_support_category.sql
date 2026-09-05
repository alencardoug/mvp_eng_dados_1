-- Categoria de chamado — dimensão **derivada e conformada**.
--
-- Derivada porque não existe tabela para ela na origem: a lista vive no `CHECK`
-- de `support_tickets.category`. Uma dimensão precisa de nome legível e de
-- agrupamento, e nenhum dos dois cabe num `CHECK`.
--
-- A lista está na *seed* `support_categories`, pelo mesmo motivo que
-- `order_status_transitions` está numa: regra escondida em `case` dentro de
-- modelo é regra que ninguém revisa. Um `pytest` confere que a *seed* e o
-- modelo transacional declaram as mesmas seis categorias — se a origem ganhar
-- uma sétima, o teste avisa antes de a dimensão perder uma linha em silêncio.

select
    {{ dbt_utils.generate_surrogate_key(['c.category_code']) }} as support_category_key,
    c.category_code                                 as support_category_natural_key,
    c.category_name                                 as support_category_name,
    c.category_group                                as support_category_group,
    c.description                                   as support_category_description
from {{ ref('support_categories') }} c
