-- Canal de venda — SCD tipo 1 (Modelo de Dados §3.2).
--
-- Tipo 1 porque o canal não muda de significado: "loja física" em 2024 é a
-- mesma coisa que em 2026. Historizá-lo custaria uma versão por linha sem
-- responder pergunta nenhuma.

select
    {{ dbt_utils.generate_surrogate_key(['sales_channel_id']) }} as sales_channel_key,
    sales_channel_id                                    as sales_channel_natural_key,
    sales_channel_code,
    sales_channel_name,
    channel_type,
    is_active,
    is_deleted
from {{ ref('sales_channels') }}
