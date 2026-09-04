-- Fornecedor — SCD tipo 2 pelo Modelo de Dados §3.2, tipo 1 aqui.
--
-- **Divergência declarada, não esquecimento.** O §3.2 classifica o fornecedor
-- como tipo 2, e o mecanismo do ADR-0017 é `dbt snapshot`. Não há *snapshot* de
-- fornecedor nesta etapa porque nenhuma das perguntas de negócio da Etapa 6
-- recorta por atributo histórico dele: a P08 usa custo, que vem do livro de
-- estoque, e não do cadastro do fornecedor.
--
-- Criar o histórico agora seria versão sem consumidor — o oposto do que o
-- ADR-0018 decidiu. Ele nasce na etapa em que uma pergunta o exigir, e a
-- passagem de tipo 1 para tipo 2 é acréscimo, não reescrita.

select
    {{ dbt_utils.generate_surrogate_key(['supplier_id']) }} as supplier_key,
    supplier_id                                     as supplier_natural_key,
    supplier_code,
    supplier_legal_name,
    coalesce(supplier_trade_name, supplier_legal_name) as supplier_name,
    supplier_country,
    payment_terms_days,
    is_active,
    is_deleted
from {{ ref('suppliers') }}
