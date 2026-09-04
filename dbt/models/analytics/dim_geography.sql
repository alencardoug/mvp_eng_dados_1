-- Geografia — dimensão **conformada**.
--
-- Conformada quer dizer que a mesma dimensão atende mais de uma fato com o
-- mesmo significado: aqui ela recorta a venda por região de entrega, e na
-- Etapa 8 vai recortar a remessa por região de origem. Se cada fato tivesse a
-- sua própria geografia, as duas não se somariam.
--
-- São 22 localidades cobrindo 14 unidades federativas e as cinco regiões: o
-- ambiente é dimensionado por **cobertura**, não por volume (ADR-0014).

select
    {{ dbt_utils.generate_surrogate_key(['country', 'state_code', 'city']) }} as geography_key,
    country,
    state_code,
    state_name,
    region,
    city
from {{ ref('geographies') }}

union all

-- Membro desconhecido: cliente sem endereço de entrega principal aterrissa
-- aqui em vez de sair do recorte por região. Depois da correção do gerador
-- nenhum item cai nele — e ele fica, porque a dimensão não deve depender de o
-- gerador continuar correto.
select
    {{ chave_desconhecida() }} as geography_key,
    'ZZ'                       as country,
    'ZZ'                       as state_code,
    'Desconhecido'             as state_name,
    'Desconhecido'             as region,
    'Desconhecido'             as city
