-- Destino permanente, nunca entrada de transformação (ADR-0008).
-- Conserva capturas e versões já auditadas, inclusive ao reprocessar uma
-- captura antiga. A própria tabela anterior só é lida para retenção.
{% set previous = adapter.get_relation(database=this.database, schema=this.schema, identifier=this.identifier) if execute else none %}
with incoming as (
    select * from {{ ref('legacy_classifications') }} where classification = 'rejected'
)
select * from incoming
{% if previous is not none %}
union all
-- Retenção por **captura e versão de catálogo**, não por registro.
--
-- A primeira versão retinha toda linha antiga sem correspondente novo, e o
-- efeito era o oposto do pretendido: um registro que **deixasse** de ser
-- rejeitado — porque o tratamento foi corrigido — ficava preso na quarentena
-- para sempre. Foram 734 assim quando a circularidade do `TOTAL_MISMATCH` foi
-- consertada, e o teste de reconciliação os acusou.
--
-- O que a quarentena conserva é a auditoria de capturas **já fechadas**: outra
-- captura, ou a mesma sob outra versão de catálogo. Para a captura corrente, a
-- classificação corrente é a autoridade — senão a quarentena passa a afirmar
-- coisas que o tratamento vigente não afirma mais.
select old.* from {{ previous }} old
where not exists (
    select 1 from incoming n
    where n.source_system = old.source_system
        and n.snapshot_id = old.snapshot_id
        and n.catalog_version = old.catalog_version
)
{% endif %}
