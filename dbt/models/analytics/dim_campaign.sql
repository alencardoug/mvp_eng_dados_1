-- Campanha — SCD tipo 1.
--
-- Tipo 1 porque o que a campanha tem de classificatório — o objetivo — é fixado
-- quando ela é criada e não muda: uma campanha de aquisição que virasse de
-- retenção seria outra campanha. O que muda é o orçamento e o estado de
-- atividade, e ambos descrevem o hoje.

select
    {{ dbt_utils.generate_surrogate_key(['c.campaign_id']) }} as campaign_key,
    c.campaign_id                                   as campaign_natural_key,
    c.campaign_code,
    c.campaign_name,
    c.campaign_objective,
    c.campaign_valid_from,
    c.campaign_valid_to,
    c.budget_amount,
    c.campaign_is_active,
    c.is_running,
    c.is_finished,
    c.is_deleted
from {{ ref('campaigns') }} c
