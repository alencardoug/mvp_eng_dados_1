{{ config(tags=['legado_reconciliacao']) }}

-- Uma versão de catálogo, um tratamento (D34).
--
-- `catalog_version` é o rótulo humano da política, e é sob ele que a quarentena
-- guarda a auditoria de cada captura. Mudar `regras.py` ou `classification.sql`
-- muda o que o tratamento produz **sem** mexer nesse número — e então duas
-- auditorias diferentes passam a caber sob a mesma identidade, e a segunda
-- apagaria a primeira.
--
-- A quarentena recusa a sobrescrita: a antiga fica, a nova entra ao lado. Este
-- teste é a parte que fala.
--
-- ── Por que só a versão corrente ────────────────────────────────────────────
-- A pergunta é sobre o tratamento que está sendo aplicado **agora**: ele colide
-- com uma auditoria já guardada sob o mesmo número? Cobrar isso de todas as
-- versões históricas tornaria uma mistura antiga permanentemente fatal, e o
-- remédio — avançar a versão — não teria como limpá-la. Auditoria velha é fato
-- registrado; o que se recusa é confundir o presente com ela.
--
-- Uma linha aqui significa que o tratamento mudou e a versão não acompanhou. O
-- conserto é avançar `versao` em `catalogo.yml`, nunca apagar a auditoria que
-- sobrou.

with corrente as (

    select distinct catalog_version, treatment_fingerprint
    from {{ ref('legacy_classifications') }}

)

select
    q.catalog_version,
    c.treatment_fingerprint                          as tratamento_corrente,
    q.treatment_fingerprint                          as tratamento_guardado,
    count(*)                                         as linhas_em_conflito
from {{ ref('rejected_legacy_records') }} q
join corrente c on c.catalog_version = q.catalog_version
where q.treatment_fingerprint <> c.treatment_fingerprint
group by 1, 2, 3
