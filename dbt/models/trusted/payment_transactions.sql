-- Operações financeiras do pagamento — o grão de `fact_payment_transaction`.
--
-- Livro de eventos: autorização, captura, estorno e reembolso são registros
-- imutáveis do que o adquirente respondeu. Uma captura que falhou continua aqui,
-- porque "quantas tentativas foram precisas" é pergunta de negócio.

with transacoes as (

    select * from {{ ref('stg_retail__payment_transactions') }}

)

select
    payment_transaction_id,
    transaction_code,
    payment_id,
    transaction_type,
    transaction_result,
    transaction_amount,
    gateway_response_code,
    occurred_at,

    -- Sinalizadores que toda pergunta financeira usa, definidos uma vez.
    transaction_result = 'succeeded'                            as is_approved,
    transaction_type = 'authorization'                          as is_authorization,
    transaction_type = 'capture'                                as is_capture,
    transaction_type = 'refund'                                 as is_refund,
    transaction_type = 'void'                                   as is_void,

    -- Valor que **entrou** no caixa: só captura aprovada. Autorização é
    -- promessa, estorno é desfazimento, e somar os três daria um número que
    -- não corresponde a dinheiro nenhum.
    case
        when transaction_type = 'capture' and transaction_result = 'succeeded'
        then transaction_amount else 0
    end                                                         as captured_amount,
    case
        when transaction_type = 'authorization' and transaction_result = 'succeeded'
        then transaction_amount else 0
    end                                                         as authorized_amount,
    case
        when transaction_type = 'refund' and transaction_result = 'succeeded'
        then transaction_amount else 0
    end                                                         as refunded_amount,

    is_deleted,
    source_created_at
from transacoes
