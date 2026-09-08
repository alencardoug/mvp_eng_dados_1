-- Quanto o total do pedido diverge dos itens **que chegaram ao armazém**.
--
-- ── Por que esta medida existe separada da classificação (D33) ──────────────
-- A classificação confere o total do pedido contra **todos** os itens
-- capturados, menos as duplicatas exatas — inclusive itens que serão
-- rejeitados por outro motivo. Isso mede consistência da *origem antiga*, e é
-- o único universo que não se morde: conferir contra o que será empilhado
-- faria o empilhamento depender da classificação e a classificação depender do
-- empilhamento. A circularidade não é hipótese — ela já custou 114 pedidos
-- falsamente não reconciliados.
--
-- Mas a pergunta que a classificação deixa sem resposta é a mais útil das
-- duas: *o que o armazém está mostrando fecha?* Esta é a resposta, e ela é
-- **medida**, não regra: nenhuma linha aqui rejeita nada.
--
-- ── As duas origens, de propósito ──────────────────────────────────────────
-- A origem principal aparece com zero divergências porque não tem quarentena —
-- e é melhor que isso seja um resultado observável do que uma suposição
-- embutida num `where source_system = 'legacy'`.
--
-- O que rejeita continua sendo `invariante_02_total_do_pedido_reconcilia`, que
-- tolera a diferença apenas onde a quarentena a explica (D35).

{{ config(tags=['legado_reconciliacao']) }}

with corrente as (

    -- A captura e o tratamento que esta execução está medindo. A quarentena
    -- guarda auditorias antigas de propósito; contá-las aqui atribuiria a um
    -- pedido de hoje a rejeição de um item de outra captura.
    select distinct source_system, snapshot_id, catalog_version, treatment_fingerprint
    from {{ ref('legacy_classifications') }}

),

itens_em_quarentena as (

    select
        q.source_system,
        -- Canônica, e não bruta: agrupar pelo texto separaria `08` de `8`
        -- e a junção seguinte multiplicaria o pedido. Ver a macro.
        {{ identidade_canonica("q.original_payload->>'order_id'") }} as order_id,
        count(*)                                            as itens_rejeitados,
        string_agg(distinct q.rejection_origin, ', ')        as motivos
    from {{ ref('rejected_legacy_records') }} q
    join corrente c
      on  c.source_system = q.source_system
     and c.snapshot_id = q.snapshot_id
     and c.catalog_version = q.catalog_version
     and c.treatment_fingerprint = q.treatment_fingerprint
    where q.source_table = 'order_items'
    group by 1, 2

)

select
    o.source_system,
    o.order_id,
    o.subtotal_amount,
    o.items_gross_revenue_amount,
    o.subtotal_amount - o.items_gross_revenue_amount        as divergence_amount,
    o.item_count                                            as itens_empilhados,
    coalesce(q.itens_rejeitados, 0)                         as itens_rejeitados,
    q.motivos                                               as motivos_da_rejeicao,

    -- A diferença tem contrapartida em quarentena? É a mesma pergunta que a
    -- invariante faz para decidir se tolera; aqui ela é coluna, não veredito.
    q.order_id is not null                                  as explicada_pela_quarentena
from {{ ref('orders') }} o
left join itens_em_quarentena q
    on q.source_system = o.source_system
   and q.order_id = {{ identidade_canonica('o.order_id::text') }}
where abs(o.subtotal_amount - o.items_gross_revenue_amount) > 0.01
