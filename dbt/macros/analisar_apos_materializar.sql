{#-
    `ANALYZE` depois de materializar tabela — o que fecha a §5 das pendências.

    ── O que se mediu (17/09/2026) ────────────────────────────────────────────
    `fact_payment_transaction` levava 680 s no build e 0,3 s sozinha; a
    consulta é a mesma. A diferença era estatística: dentro do build, `orders`,
    `payments` e as dimensões acabaram de nascer por `create table as`, e o
    autovacuum ainda não as tinha analisado. Sem estatística o planejador
    assume `source_system` seletivo — a coluna tem **dois** valores desde o
    empilhamento (ADR-0021) — e junta `payment_transactions` a `orders` só por
    ela: 24,9 milhões de linhas intermediárias, 2 048 lotes de hash, 17 GB de
    arquivo temporário para um resultado de 7 419 linhas (plano gravado pelo
    `auto_explain`, `pendencias.md` §5).

    ── Por que aqui ───────────────────────────────────────────────────────────
    O consumidor de uma tabela é o próximo modelo, no mesmo build, segundos
    depois; esperar o autovacuum é esperar o acaso. `ANALYZE` de tabela pequena
    custa milissegundos. Views e o que não é tabela não têm estatística, e o
    hook fica vazio — o dbt ignora hook em branco. No BigQuery não existe
    `ANALYZE` nem o problema (o planejador não depende de estatística de
    tabela), e a macro devolve vazio pelo mesmo caminho.
-#}
{% macro analisar_apos_materializar() -%}
    {%- if target.type == 'postgres' and config.get('materialized') in ('table', 'incremental') -%}
        analyze {{ this }}
    {%- endif -%}
{%- endmacro %}
