-- Canais de venda conformados.
--
-- Camada `trusted` (ADR-0016): aplica regra de negócio e é muito referenciada.
-- Aqui a regra é pequena — o canal é domínio fechado —, mas o modelo existe
-- para que `analytics` nunca leia de `staging` direto: a camada seguinte lê a
-- anterior, sempre, e é isso que mantém a linhagem legível.

select
    sales_channel_id,
    sales_channel_code,
    sales_channel_name,
    channel_type,
    is_active,
    -- ADR-0029: a exclusão viaja como marca. Nenhuma dimensão perde membro.
    is_deleted,
    source_created_at,
    source_updated_at
from {{ ref('stg_retail__sales_channels') }}
