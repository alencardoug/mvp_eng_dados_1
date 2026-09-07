-- Canal de venda — SCD tipo 1 (Modelo de Dados §3.2).
--
-- Tipo 1 porque o canal não muda de significado: "loja física" em 2024 é a
-- mesma coisa que em 2026. Historizá-lo custaria uma versão por linha sem
-- responder pergunta nenhuma.

select
    {{ dbt_utils.generate_surrogate_key(['source_system', 'sales_channel_id']) }}
                                                        as sales_channel_key,
    source_system,
    sales_channel_id                                    as sales_channel_natural_key,
    sales_channel_code,
    sales_channel_name,
    channel_type,
    is_active,
    is_deleted
from {{ ref('sales_channels') }}

union all

-- Membro desconhecido, acrescentado na Etapa 9. Quinze por cento dos chamados
-- não nascem de um pedido — o cliente liga por dúvida de cadastro, não por uma
-- compra —, e sem pedido não há canal. Sem esta linha, `fact_support_ticket_event`
-- precisaria de chave nula, e esses chamados sumiriam de todo recorte por canal
-- em vez de aparecerem agrupados como o que são.
select
    {{ chave_desconhecida() }}                          as sales_channel_key,
    -- O membro desconhecido não é de origem nenhuma: ele existe porque a fato
    -- não encontrou par, e atribuí-lo a `retail` ou a `legacy` seria dizer de
    -- onde veio o que não veio de lugar algum.
    'unknown'                                           as source_system,
    -1                                                  as sales_channel_natural_key,
    'UNK'                                               as sales_channel_code,
    'Sem canal'                                         as sales_channel_name,
    'unknown'                                           as channel_type,
    false                                               as is_active,
    false                                               as is_deleted
