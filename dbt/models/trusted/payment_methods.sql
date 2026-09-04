-- Meios de pagamento aceitos. Nenhuma credencial é armazenada, nem sintética.
select
    payment_method_id, payment_method_code, payment_method_name, method_type,
    method_type in ('credit_card', 'debit_card')    as is_card,
    method_type in ('pix', 'debit_card')            as is_instant,
    is_active, is_deleted, source_created_at, source_updated_at
from {{ ref('stg_retail__payment_methods') }}
