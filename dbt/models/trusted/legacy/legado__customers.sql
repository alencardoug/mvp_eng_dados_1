-- Clientes aptos do legado, na forma que `stg_retail__customers` produz.
--
-- ── Por que este modelo existe ──────────────────────────────────────────────
-- O empilhamento acontece em `trusted` (ADR-0021 e Origem Legada §6), e lá os
-- modelos leem colunas **renomeadas** pelo `staging`. O conjunto apto do legado
-- chega como `cleaned_payload` em JSONB, com os nomes da origem. Este modelo é
-- a ponte: extrai, tipa e renomeia, para que o empilhamento seja um `union all`
-- entre duas relações do mesmo formato.
--
-- ── A duplicação que ele cria, e como ela é contida ─────────────────────────
-- O mapa de renome vive em dois lugares: aqui e em `stg_retail__customers`. Não
-- há como evitá-lo sem extrair o mapa dos modelos escritos à mão da Etapa 5,
-- que é refatoração de outra etapa.
--
-- A contenção é mecânica, não disciplinar: o teste
-- `legado_e_retail_tem_o_mesmo_formato` compara as colunas dos dois e falha se
-- divergirem. Duplicata vigiada por teste envelhece com aviso.

with apto as (

    select *
    from {{ ref('legacy_eligible_records') }}
    where source_table = 'customers'

)

select
    (cleaned_payload->>'id')::bigint                     as customer_id,
    cleaned_payload->>'customer_code'                    as customer_code,
    (cleaned_payload->>'segment_id')::bigint             as customer_segment_id,
    cleaned_payload->>'first_name'                       as first_name,
    cleaned_payload->>'last_name'                        as last_name,
    cleaned_payload->>'first_name' || ' ' || (cleaned_payload->>'last_name')
                                                        as customer_full_name,
    cleaned_payload->>'document'                         as customer_document,
    (cleaned_payload->>'birth_date')::date               as birth_date,
    cleaned_payload->>'status'                           as customer_status,
    (cleaned_payload->>'registered_at')::timestamptz     as registered_at,

    (cleaned_payload->>'created_at')::timestamptz        as source_created_at,
    (cleaned_payload->>'updated_at')::timestamptz        as source_updated_at,
    (cleaned_payload->>'deleted_at')::timestamptz        as source_deleted_at,
    cleaned_payload->>'deleted_at' is not null           as is_deleted,
    snapshot_at                                          as ingested_at
from apto
