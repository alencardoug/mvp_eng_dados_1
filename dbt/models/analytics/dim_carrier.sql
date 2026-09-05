-- Transportadora — SCD tipo 1.
--
-- Tipo 1 e não tipo 2 pelo critério misto que o projeto já usa (Modelo de Dados
-- §3.3): historiza-se o que **classifica** o fato, não o que apenas o descreve.
-- Nome e URL de rastreio descrevem; a modalidade classifica — e ela não muda
-- para uma transportadora contratada, porque contratar a mesma empresa em outra
-- modalidade é outra linha de contrato, não a mesma linha com outro valor.
--
-- Se um dia mudar, a promessa de prazo das remessas antigas passaria a ser lida
-- pela modalidade nova, e a taxa de pontualidade histórica mudaria sozinha. É o
-- gatilho que transformaria esta dimensão em tipo 2, e está escrito aqui para
-- que a decisão seja tomada com o motivo à vista.

select
    {{ dbt_utils.generate_surrogate_key(['c.carrier_id']) }} as carrier_key,
    c.carrier_id                                    as carrier_natural_key,
    c.carrier_code,
    c.carrier_name,
    c.service_level,
    c.service_level_rank,
    c.tracking_url_template,
    c.is_active,
    c.is_deleted
from {{ ref('carriers') }} c
