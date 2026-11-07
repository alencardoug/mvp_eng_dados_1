-- Campanhas, com a vigência resolvida contra o "hoje" da simulação.
--
-- O objetivo da campanha (`acquisition`, `retention`, `reactivation`,
-- `clearance`) é o que classifica o cupom numa análise: dois cupons de 10% não
-- são a mesma coisa se um busca cliente novo e o outro segura cliente antigo.

with campanhas as (
    {{ empilhado('campaigns') }}
)

select
    c.source_system,
    c.campaign_id,
    c.campaign_code,
    c.campaign_name,
    c.campaign_objective,
    c.campaign_valid_from,
    c.campaign_valid_to,
    c.budget_amount,
    c.campaign_is_active,

    -- Vigência contra `as_of_date`, nunca contra `current_date`: o relógio do
    -- banco daria resultado diferente a cada execução sobre o mesmo dado.
    {{ meia_noite(var("as_of_date")) }}
        between c.campaign_valid_from and c.campaign_valid_to  as is_running,
    c.campaign_valid_to < {{ meia_noite(var("as_of_date")) }}
                                                              as is_finished,

    c.is_deleted,
    c.source_created_at,
    c.source_updated_at
from campanhas c
