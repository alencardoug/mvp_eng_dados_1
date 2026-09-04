-- Tentativas, autorizações, capturas e falhas do pagamento.
--
-- Camada `staging` (ADR-0016): renomeia e tipa, nada mais.

-- ── Deduplicação de entrega ao menos uma vez ────────────────────────────────
-- O modo `append` do ADR-0015 é **at least once**: o Airbyte relê a fronteira do
-- cursor e reescreve linhas já entregues. Foram 9 duplicatas em
-- `payment_transactions` e 1 em `inventory_movements` na segunda sincronização —
-- o suficiente para dobrar uma captura e desalinhar um saldo, e pouco o
-- bastante para ninguém notar sem teste.
--
-- A resposta é a mesma que o [ADR-0019](../../../docs/adr/0019-saldo-em-deltas-com-entrega-idempotente.md)
-- dá para o *streaming*: o consumidor deduplica pela chave, sem presumir
-- processamento exatamente uma vez do transporte. `raw` fica *at least once*;
-- `staging` entrega exatamente uma vez, e é essa a fronteira.
--
-- `distinct on` mantém a extração mais recente: se a origem corrigiu algo entre
-- as duas leituras, a correção vence.

with fonte as (
    select distinct on (id) *
    from {{ source('retail', 'payment_transactions') }}
    order by id, _airbyte_extracted_at desc
),

renomeado as (
    select
        id                                        as payment_transaction_id,
        transaction_code,
        payment_id,
        transaction_type,
        result                                    as transaction_result,
        amount                                    as transaction_amount,
        gateway_response_code,
        occurred_at,

        -- Livro de eventos: sem `updated_at` e sem `deleted_at` de propósito.
        -- Corrigir um evento publicado é inserir outro, compensatório.
        created_at                                as source_created_at,
        false                                     as is_deleted,
        _airbyte_extracted_at                     as ingested_at
    from fonte
)

select * from renomeado
