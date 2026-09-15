# ADR-0044 — Certificar cada captura do legado por conteúdo, por *stream* e por *job*

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 14/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D41 — levantada e decidida em 14/09/2026, no plano de fechamento da Etapa 10 |
| Substitui / é substituída por | — ; abre uma **exceção delimitada** ao [ADR-0023](0023-escopo-do-schema-governance.md), que não é substituído |

## Contexto

A terceira revisão da Etapa 10 deixou o achado **R09** aberto: a DAG fixa **qual** captura do legado
os modelos leem (`legacy_snapshot_id`), mas nada distingue uma carga nova de uma captura anterior
reutilizada, e "captura completa" significava apenas "alguma linha nas 40 tabelas". A docstring de
`geracao_do_legado` admitia a lacuna desde 08/09/2026, e os testes `legacy_captura_existe` e
`legacy_captura_completa` não a fechavam.

Medido em 14/09/2026, sobre o que já estava retido em `raw_legacy`:

- a **geração 15** tem **39 tabelas** — `brands` não veio —, e o *job* 25 que a produziu terminou
  `succeeded` com `rowsSynced` = 12.746, igual ao total da geração. Máximo crescente e total exato
  **aceitariam** essa captura; só a presença por tabela a recusa, e presença não vê perda **dentro**
  de uma tabela não vazia;
- contagem não certifica conteúdo: a origem pode trocar `{1,2}` por `{1,3}` e a extração entregar
  `[1,1]` com as três contagens iguais (§15 do plano, VF05);
- o Airbyte grava em cada linha `_airbyte_meta.sync_id`, e nas gerações 15 e 16 ele é **igual ao
  `jobId`** (25 e 26). A documentação do Airbyte o descreve como identificador monotônico da
  sincronização, sem prometer essa igualdade — é contrato **observado na versão instalada**;
- com a normalização `''` → nulo, origem e bruto coincidem em **40/40** tabelas por hash de conteúdo;
  sem ela, em 37. A normalização é do transporte (o destino entrega string vazia como `NULL`, medido
  em 05/09) e precisa ser declarada, não descoberta.

Havia ainda uma pergunta de fronteira. Certificar exige saber o que a **origem** tinha no instante
da captura — contagem e hash por tabela **antes** e **depois** do *job* —, e isso não está em lugar
nenhum do armazém. O [ADR-0023](0023-escopo-do-schema-governance.md) declara o
schema `governance` para "log de execução: cada execução de pipeline, início, fim, resultado", que é
exatamente esta informação; mas o mesmo ADR manda mantê-lo **fora do fluxo de dados** — "nenhum
modelo de `analytics` pode ler dele, sob pena de a auditoria virar entrada do que ela audita". Ler
o certificado para decidir qual captura é elegível é ler `governance` no fluxo. Uma nota datada não
cria essa exceção; um ADR cria, delimitando-a.

A revisão do plano (§13–§17) descartou duas formas antes desta: uma tabela de controle em
`raw_legacy` (mudaria a fronteira do [ADR-0008](0008-schemas-do-armazem.md): `raw_legacy` é o
*snapshot* do Airbyte, e passaria a ter escrita própria) e verificar só em tempo de execução (a prova
não sobreviveria para o teste dbt nem para a detecção de exclusão física, que precisa saber quais
capturas conferiram).

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Certificado por *stream* e por conteúdo em `governance.legacy_captures`, em duas fases** (escolhida) | Prova integralidade **de conteúdo**, não de contagem; liga cada linha do bruto ao *job* pelo `sync_id`; tabela legitimamente vazia vira medida (origem 0, recebido 0) e a lista `VAZIAS_LEGITIMAS` deixa de existir; a medição "antes" é durável, então o certificado é recuperável depois de falha entre a sincronização e o registro; cabe no conjunto "log de execução" que o ADR-0023 já declarou | Abre uma exceção à regra de `governance` fora do fluxo — a **única** leitura, dita e delimitada; acrescenta duas fases à sincronização e uma tabela cujo ciclo de criação e evolução o armazém não tinha (não há Alembic nele) |
| Máximo de geração crescente + `rowsSynced` igual ao total | Duas consultas, nenhuma tabela nova | A geração 15 passa. Não identifica a autoria das linhas nem perda compensada por duplicata; premissas de exclusividade de geração por execução não são verificáveis (achado P01) |
| Tabela de controle em `raw_legacy._capturas` | Fica ao lado do que descreve | `raw_legacy` é o *snapshot* imutável do Airbyte (ADR-0008); escrita própria ali muda o contrato do schema e exigiria ADR de qualquer forma (P15). Descartada pelo Owner em 14/09 |
| Schema de controle novo (`ingestion_control`) | Não toca em `governance` nem em `raw_legacy` | Décimo schema no armazém, para uma tabela; o ADR-0023 já criou o lugar certo |
| Verificar só em tempo de DAG, sem persistir | Nenhuma escrita fora do Airbyte | A elegibilidade de "captura anterior certificada", de que a detecção de exclusão física depende ([ADR-0045](0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md)), não teria de onde sair; `make sync-legacy` e o teste dbt ficariam sem prova |
| Certificar só por contagem por *stream* (origem × recebido) | Mais simples que hash | Alteração sem mudança de contagem e perda compensada por duplicata passam (P02). O legado é todo `text`: o hash canônico custa uma leitura por tabela |

## Decisão

**Toda sincronização do legado produz um certificado por *stream* em `governance.legacy_captures`,
em duas fases, e só uma captura com certificado `complete` nas 40 tabelas é elegível — como captura
selecionada ou como "anterior certificada".**

1. **Fase 1 — antes de disparar o *job*.** `mvp_ed1.airbyte.iniciar_captura()` grava uma linha por
   tabela com `capture_attempt_id`, `source_rows_before`, `source_hash_before` e `status = pending`.
   O `job_id` é gravado assim que o *job* nasce. É a medição que não pode ser refeita depois: a
   origem de hoje não é a origem de antes.
2. **Fase 2 — depois de o *job* terminar.** `concluir_captura(attempt)` mede a origem de novo
   (`source_rows_after`, `source_hash_after`), lê o bruto da geração (`received_rows`,
   `received_hash`, `sync_id_matches`) e fecha o `status`:

   | `status` | Quando |
   |---|---|
   | `complete` | nas 40 tabelas: `hash_before = hash_after` (origem estável durante o *job*), `received_hash = source_hash_after` **e** `received_rows = source_rows_after` (conteúdo e multiplicidade), e `sync_id_matches` |
   | `unstable` | a origem mudou durante o *job* |
   | `incomplete` | tabela ou conteúdo faltando — a geração 15 |
   | `inconsistent` | linhas da geração com outro `sync_id`, ou linhas deste `sync_id` noutra geração |
   | `abandoned` | tentativa sem fase 1 concluída: não é certificável, exige nova captura |

   Tabela com 0 na origem e 0 recebida, com hash vazio dos dois lados, é **completa**: a lista
   `VAZIAS_LEGITIMAS` sai — "legitimamente vazia" passa a ser medida, não declarada.
3. **O hash de conteúdo é um só** (`legacy/conteudo.py`): serialização canônica de todas as linhas
   da tabela em ordem de `legacy_row_id`, com `''` lido como nulo — a normalização de transporte,
   declarada aqui. É o mesmo hash que o manifesto grava e que o `writer` confere no `legacy_db`
   depois do `COPY`: manifesto ↔ origem ↔ captura é uma cadeia de igualdades.
4. **Recuperação.** Tentativa `pending` com `job_id` é concluída pela fase 2 a partir do "antes" **já
   gravado**; tentativa sem fase 1 é `abandoned`. Nada é remedido sobre a origem corrente como se
   fosse a de antes. A próxima execução conclui ou abandona tentativas pendentes antes de abrir a
   sua — nunca as reaproveita em silêncio.
5. **Idempotência.** As duas fases são *upserts* pela chave `(capture_attempt_id, source_table)`;
   a tentativa só é `complete` quando as 40 linhas existem e concordam; reenviar produz o mesmo
   estado.
6. **Exceção delimitada ao ADR-0023.** O fluxo lê **uma** tabela de `governance`,
   `legacy_captures`, **só** para responder "esta captura é elegível?" — em
   `legacy_captura_completa` e na detecção de exclusão física. Nenhum modelo de `staging`,
   `trusted`, `analytics` ou `consumption` lê dela outra coisa; reconciliação, índice de quarentena e
   classificação aplicada continuam fora do fluxo, e a Etapa 11 não duplica este registro. A tabela
   é declarada como `source` do dbt para que a leitura seja visível na linhagem.
7. **Ciclo de vida.** Criação e evolução por DDL versionado e idempotente em `mvp_ed1/governance.py`,
   com teste. O armazém não tem Alembic e o [ADR-0010](0010-alembic-para-migracoes.md) não o exige
   ali; se o Owner quiser estendê-lo, é decisão da Etapa 11.
8. **A mesma função em dois chamadores.** A DAG (`iniciar_captura` → `sincronizar` →
   `concluir_captura` → `geracao_do_legado`) e `make sync-legacy` usam as duas funções; a DAG carrega
   o `capture_attempt_id` por XCom. `geracao_do_legado` devolve o `snapshot_id` do certificado
   `complete`, ou falha.
9. **Capturas 1–16 não têm certificado e não podem ter** — as contagens de origem daquele instante
   passaram. Não são elegíveis como "anterior certificada"; a primeira comparação entre capturas
   acontece entre duas novas.

## Consequências

- **Positivas:** captura nova, anterior reutilizada, instável e incompleta passam a ser resultados
  **diferentes e medidos**; a geração 15 fica recusada por evidência, não por sorte; "legitimamente
  vazia" deixa de ser lista; e a detecção de exclusão física ganha o que lhe faltava — saber contra
  qual captura anterior comparar.
- **Negativas:** duas fases e três leituras por tabela (origem antes, origem depois, bruto) em cada
  sincronização — no volume do legado é desprezível, mas é custo; uma exceção ao ADR-0023, que quem
  ler aquele ADR precisa conhecer; o *retry* de um mesmo *job* que reescreva a mesma geração com o
  mesmo `sync_id` não é reproduzível localmente e fica como **premissa** registrada, não como prova;
  e o contrato `sync_id = job_id` é da versão instalada — fixado por teste, revalidado a cada
  atualização do Airbyte.
- **Paridade com o GCP:** *dataset* `governance`, tabela `legacy_captures` com as mesmas colunas,
  escrita pelo **mesmo módulo** nas mesmas duas fases. A escrita **não** é `insert_rows_json`
  (deduplicação de melhor esforço, erro por linha, inserção parcial com HTTP 200): é carga numa
  tabela de *staging* seguida de `MERGE` pela mesma chave `(capture_attempt_id, source_table)`, o
  que preserva a idempotência do item 5. Respostas parciais e retorno perdido são testados
  localmente com a API simulada; a medição ao vivo no GCP fica para a fase 2. A leitura pelo dbt é a
  mesma `source`. O `_airbyte_meta.sync_id` existe igual no destino BigQuery do Airbyte.
- **Documentos a atualizar:** [ADR-0023](0023-escopo-do-schema-governance.md) —
  nota datada apontando para esta exceção, sem reescrita; [Origem Legada](../origem_legada.md) §4.2
  — qual captura a execução lê passa a ser "a certificada"; [Arquitetura](../arquitetura.md) §5 —
  linha de `governance.legacy_captures` no mapa de paridade; [Governança de Dados](../governanca_de_dados.md)
  — o primeiro conjunto do log de execução materializado; [Execução Local](../execucao_local.md) —
  `make sync-legacy` passa a certificar; [Modelo de Dados](../modelo_de_dados.md) §6 — a tabela.
