-- Destino permanente, nunca entrada de transformação (ADR-0008).
-- Conserva capturas e versões já auditadas, inclusive ao reprocessar uma
-- captura antiga. A própria tabela anterior só é lida para retenção.
{% set previous = adapter.get_relation(database=this.database, schema=this.schema, identifier=this.identifier) if execute else none %}
-- A **captura tratada** vem da classificação inteira, não só dos rejeitados.
--
-- A primeira versão procurava a chave a substituir dentro de `incoming`, que já
-- estava filtrado para `rejected`. Se uma captura passasse a ser inteiramente
-- aceita — porque o tratamento foi corrigido —, `incoming` ficava vazio, o
-- `not exists` era sempre verdadeiro, e **todas** as rejeições obsoletas dela
-- sobreviviam, contradizendo a classificação corrente.
--
-- A identidade da captura reprocessada não pode depender de existir ao menos
-- uma rejeição nova.
--
-- A identidade da captura tratada inclui a **impressão digital** do tratamento
-- (D34). A versão do catálogo é o rótulo humano e pode não avançar quando
-- `regras.py` ou `classification.sql` mudam; a impressão avança sempre que o
-- resultado muda. Sem ela, dois tratamentos diferentes caberiam sob a mesma
-- identidade e o segundo apagaria a auditoria do primeiro em silêncio.
--
-- Com ela, a substituição é **recusada**: a auditoria antiga fica, a nova
-- entra ao lado, e `legacy_versao_do_tratamento_e_univoca` diz em voz alta que
-- a versão precisa avançar.
with tratadas as (
    select distinct source_system, snapshot_id, catalog_version, treatment_fingerprint
    from {{ ref('legacy_classifications') }}
),
incoming as (
    select * from {{ ref('legacy_classifications') }} where classification = 'rejected'
)
select * from incoming
{% if previous is not none %}
union all
{#-
    A auditoria anterior é lida coluna a coluna, e não com `old.*`.

    Quando o contrato da classificação ganha uma coluna — foi o caso de
    `treatment_fingerprint` —, a tabela antiga ainda não a tem, e um `union all`
    posicional casaria colunas trocadas ou falharia por contagem. Enumerar
    permite preencher o que falta com um marcador que **diz** o que aconteceu,
    em vez de nulo mudo.

    Só a impressão digital pode faltar. Qualquer outra ausência é contrato
    divergindo por outro motivo, e aí a geração para em vez de adivinhar.
-#}
{%- set colunas = adapter.get_columns_in_relation(ref('legacy_classifications')) if execute else [] %}
{%- set antigas = adapter.get_columns_in_relation(previous) | map(attribute='name') | list if execute else [] %}
{%- set faltando = colunas | map(attribute='name') | reject('in', antigas) | list %}
{%- if faltando and faltando != ['treatment_fingerprint'] %}
    {{ exceptions.raise_compiler_error(
        'quarentena anterior sem as colunas ' ~ faltando | join(', ') ~
        '; o contrato mudou por um motivo que este modelo não sabe preencher') }}
{%- endif %}
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
select
{%- for coluna in colunas %}
    {% if coluna.name in antigas %}old.{{ coluna.name }}{% else %}'anterior-a-D34'::text{% endif %} as {{ coluna.name }}{{ "," if not loop.last }}
{%- endfor %}
from {{ previous }} old
where not exists (
    select 1 from tratadas t
    where t.source_system = old.source_system
        and t.snapshot_id = old.snapshot_id
        and t.catalog_version = old.catalog_version
        -- A auditoria que precede a impressão digital nunca casa: ela veio de
        -- um tratamento que não se sabe qual era, e por isso é retida.
        and t.treatment_fingerprint = {% if 'treatment_fingerprint' in antigas %}old.treatment_fingerprint{% else %}'anterior-a-D34'::text{% endif %}
)
{% endif %}
