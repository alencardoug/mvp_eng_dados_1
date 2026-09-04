-- Meio de pagamento — SCD tipo 1 (Modelo de Dados §3.2).
--
-- Tipo 1 porque "Pix" não muda de significado: historizá-lo custaria uma versão
-- por linha sem responder pergunta nenhuma.

select
    {{ dbt_utils.generate_surrogate_key(['payment_method_id']) }} as payment_method_key,
    payment_method_id                               as payment_method_natural_key,
    payment_method_code,
    payment_method_name,
    method_type,
    is_card,
    is_instant,
    is_active,
    is_deleted
from {{ ref('payment_methods') }}
