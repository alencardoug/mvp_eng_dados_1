{#
    Convenções de coluna do projeto: o texto de cada uma, declarado uma vez.

    Uma coluna de convenção não transporta o valor de coluna nenhuma da origem —
    nasce de uma macro, de uma regra do `staging` ou de uma ferramenta —, e a
    mesma frase valeria em dezenas de modelos. `make catalog`
    (`mvp_ed1/models/descriptions.py`) escreve `{{ doc("<coluna>") }}` onde a
    coluna nasce **com a forma da convenção** — nome e expressão —, e dali o
    texto segue por transporte como qualquer outro. Coluna de mesmo nome com
    outra expressão não recebe este texto: precisa do seu.

    Editar um texto aqui muda a descrição em todo lugar que a convenção alcança;
    acrescentar uma convenção é mudar a tabela `CONVENTIONS` daquele módulo, com
    contraprova.
#}

{% docs source_system %}
Sistema de origem do registro: `retail`, a origem principal, ou `legacy`, a legada — e `unknown` só
no membro desconhecido de uma dimensão. É parte da identidade: os dois sistemas numeram as
entidades a partir de 1, e o mesmo identificador em sistemas diferentes é outro registro — por isso
a origem entra em toda chave e em toda junção junto com o identificador (macro `empilhado`).
{% enddocs %}

{% docs is_deleted %}
Verdadeiro quando a linha foi excluída logicamente na origem — `deleted_at` preenchido. A origem
nunca apaga fisicamente (ADR-0015): a linha continua no armazém, marcada.
{% enddocs %}

{% docs is_deleted_append_only %}
Sempre falso: a tabela é só de acréscimo na origem — um evento publicado não se exclui, nem
logicamente; corrigi-lo é inserir outro —, e a coluna existe para que ela tenha a forma das demais.
{% enddocs %}

{% docs _airbyte_raw_id %}
Identificador que o Airbyte atribui a cada linha que grava no bruto.
{% enddocs %}

{% docs _airbyte_extracted_at %}
Instante em que o Airbyte extraiu a linha da origem, com fuso.
{% enddocs %}

{% docs _airbyte_meta %}
Metadados que o Airbyte grava com a linha: o `sync_id` da sincronização que a trouxe e as
alterações que ele fez no valor ao gravar (`changes`).
{% enddocs %}

{% docs _airbyte_generation_id %}
Geração do stream no Airbyte, que muda a cada recarga completa da conexão. É contada por stream, e
por isso não identifica a captura: quem a identifica é o `sync_id` de `_airbyte_meta`.
{% enddocs %}

{% docs legacy_row_id %}
Identidade física da linha na tabela do legado — única dentro da captura, renumerada a cada geração
da origem legada. Não é chave de negócio nem ordem de evento.
{% enddocs %}

{% docs _stream_partition %}
Partição do tópico do Redpanda de que o evento chegou pelo caminho quente.
{% enddocs %}

{% docs _stream_offset %}
Posição do evento na partição; com ela, identifica a entrega no tópico.
{% enddocs %}

{% docs _stream_lsn %}
Posição da alteração no log de escrita (WAL) do PostgreSQL da origem, como o Debezium a informou;
nula quando o evento não traz a posição.
{% enddocs %}

{% docs _stream_from_snapshot %}
Verdadeiro quando o evento veio da carga inicial (*snapshot*) do Debezium, e não de uma alteração
lida do log.
{% enddocs %}

{% docs _stream_extracted_at %}
Instante em que o caminho quente gravou o evento no armazém, com fuso.
{% enddocs %}

{% docs dbt_scd_id %}
Identificador da versão no snapshot, gerado pelo dbt a partir da chave e do instante da versão.
{% enddocs %}

{% docs dbt_updated_at %}
Instante em que o snapshot registrou a versão — com a estratégia `check`, o da execução que viu a
mudança.
{% enddocs %}

{% docs dbt_valid_from %}
Início da vigência da versão.
{% enddocs %}

{% docs dbt_valid_to %}
Fim da vigência da versão; nulo na versão vigente.
{% enddocs %}
