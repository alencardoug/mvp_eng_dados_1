{#-
    A linha está incompleta porque um filho dela foi para a quarentena?

    ── O problema que esta macro resolve ────────────────────────────────────
    As invariantes que atravessam entidades — o total do pedido contra os seus
    itens, o saldo contra o livro de movimentos, a remessa contra as suas
    caixas — comparam um pai com a soma dos filhos. Elas valem na origem
    principal, onde o conjunto está inteiro.

    Na origem legada não podem valer, e o motivo é aritmético, não um defeito
    novo: a regra 4 manda o registro inválido para a quarentena, e o ADR-0038
    faz a rejeição cascatear do pai para o filho — **nunca do filho para o
    pai**. Um pedido bom com um item ruim continua no armazém, e o item ruim
    não. A soma dos itens deixa de bater com o total do pedido, e é assim que
    tem de ser: a alternativa seria descartar o pedido bom, ou empilhar o item
    inválido.

    ── O que fica no lugar da invariante ────────────────────────────────────
    Exigir a igualdade seria exigir que a quarentena não existisse. Aceitar a
    diferença em silêncio seria perder a invariante. Esta macro é a terceira
    saída: a diferença é tolerada **apenas onde a quarentena a explica**, e
    continua sendo violação em qualquer outro lugar.

    O teste passa a afirmar algo mais forte do que antes: não que os números
    fecham, mas que **todo lugar em que não fecham tem um registro em
    quarentena com o motivo**. Uma divergência sem essa contrapartida falha.

    A origem principal não é afetada: ela não tem quarentena, então nada ali é
    exonerado por esta cláusula.

    ── Decidido ─────────────────────────────────────────────────────────────
    Que o pai sobreviva à rejeição de um filho é a **D35**, decidida em
    07/09/2026 contra as duas alternativas — cascatear para cima, que descartaria
    58 pedidos válidos, e marcar o pai com uma coluna própria. O ADR-0038 segue
    sem inversão.
-#}
{% macro explicado_pela_quarentena(tabela_do_filho, colunas, alias) -%}
    exists (
        select 1
        from {{ ref('rejected_legacy_records') }} q
        -- ── Só a auditoria da captura e do tratamento em análise ────────────
        -- A quarentena é destino permanente e guarda capturas antigas e versões
        -- anteriores (ADR-0037). Sem este recorte, uma rejeição de outra captura
        -- explicaria uma divergência de hoje: a tolerância viraria um curinga
        -- histórico, e a garantia — toda diferença tem contrapartida — seria
        -- mais fraca do que anuncia.
        join (
            select distinct
                source_system, snapshot_id, catalog_version, treatment_fingerprint
            from {{ ref('legacy_classifications') }}
        ) corrente
          on  corrente.source_system = q.source_system
         and corrente.snapshot_id = q.snapshot_id
         and corrente.catalog_version = q.catalog_version
         and corrente.treatment_fingerprint = q.treatment_fingerprint
        where q.source_table = '{{ tabela_do_filho }}'
          and q.source_system = {{ alias }}.source_system
          {%- for coluna in colunas %}
          -- Identidade canônica dos dois lados, e não texto cru contra valor
          -- tipado: era o R29. O payload guarda `08`, o pai empilhado é o
          -- `bigint 8`, e a contrapartida não era encontrada. A canonização não
          -- converte o que não é inteiro — o valor pode ter sido rejeitado
          -- justamente por não ser conversível.
          and {{ identidade_canonica("q.original_payload->>'" ~ coluna ~ "'") }}
            = {{ identidade_canonica(alias ~ '.' ~ coluna ~ '::text') }}
          {%- endfor %}
    )
{%- endmacro %}
