-- Fornecedores.
select
    supplier_id, supplier_code, supplier_legal_name, supplier_trade_name,
    supplier_document, supplier_contact_email, supplier_country,
    payment_terms_days, is_active, is_deleted, source_created_at, source_updated_at
from {{ ref('stg_retail__suppliers') }}
