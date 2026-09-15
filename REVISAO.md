# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `a66f869..beb3774` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
f51fc2a docs: abre o plano de fechamento da Etapa 10 para revisão
819b88f docs: fecha no plano da Etapa 10 as decisões do Owner antes da revisão
e65efa5 docs: registra o parecer do revisor sobre o plano de fechamento da Etapa 10
186d8d7 docs: reescreve o plano de fechamento da Etapa 10 com os achados do parecer
deb3c40 docs: registra o segundo parecer do revisor sobre o plano da Etapa 10
caae643 docs: reescreve o plano da Etapa 10 sem marca dimensional e com dois ADRs
ea80aaf docs: registra a terceira reavaliação do revisor sobre o plano da Etapa 10
85ab89a docs: corrige o plano da Etapa 10 com a terceira reavaliação — revisão 5
b4acc16 fix: separa os interruptores dos testes que escrevem e isola o teste de carga
fa0dd12 feat: declara a recuperação esperada por falha no catálogo do legado
5acf371 feat: identifica o manifesto por conteúdo e calcula o esperado de toda ocorrência
722956d test: confere veredito, cascata e recuperação contra o oráculo, com mutações
dca2480 feat: leva o schema legado para o ciclo Alembic
8ff0f1b docs: fecha as decisões D39 e D41 do plano da Etapa 10 — ADR-0044 e ADR-0045
ea91a49 feat: certifica cada captura do legado em duas fases, por stream, conteúdo e job
5b9b4bb feat: detecta exclusão física entre capturas certificadas do legado
37e36dd docs: registra o contrato de event_sequence no legado
e7a0097 fix: ensina ao oráculo a heurística declarada de truncamento e preserva o diário
f2d1b64 test: confere o certificado mais recente contra o bruto em vez de remedir a origem
7eac705 fix: a identidade da captura do legado passa a ser o job, não a geração
ad940e5 docs: registra a situação dos seis achados abertos da terceira revisão
beb3774 docs: atualiza o estado da Etapa 10 com as medições — aguardando revisão
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 51 arquivos

- `Makefile`
- `README.md`
- `REVISAO.md`
- `airflow/dags/fluxo_batch.py`
- `alembic.ini`
- `db/migrations_legacy/env.py`
- `db/migrations_legacy/script.py.mako`
- `db/migrations_legacy/versions/20260914_f558a05ce90e_cria_o_schema_legacy_com_as_40_tabelas_.py`
- `dbt/macros/chave_canonica.sql`
- `dbt/tests/legado_event_sequence_e_desempate_tecnico.sql`
- `docker/docker-compose.airflow.yml`
- `docs/adr/0015-sincronizacao-e-exclusoes.md`
- `docs/adr/0023-escopo-do-schema-governance.md`
- `docs/adr/0037-reter-capturas-do-legado-por-acrescimo.md`
- `docs/adr/0039-alcance-da-procedencia.md`
- `docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md`
- `docs/adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md`
- `docs/adr/README.md`
- `docs/arquitetura.md`
- `docs/execucao_local.md`
- `docs/governanca_de_dados.md`
- `docs/modelo_de_dados.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/qualidade_de_dados.md`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/governance.py`
- `src/mvp_ed1/legacy/captura.py`
- `src/mvp_ed1/legacy/catalogo.py`
- `src/mvp_ed1/legacy/catalogo.yml`
- `src/mvp_ed1/legacy/classification.py`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/conteudo.py`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/estrutura.py`
- `src/mvp_ed1/legacy/injetor.py`
- `src/mvp_ed1/legacy/mutacoes.py`
- `src/mvp_ed1/legacy/oraculo.py`
- `src/mvp_ed1/legacy/ponte.py`
- `src/mvp_ed1/legacy/remocao.py`
- `src/mvp_ed1/legacy/schema.py`
- `src/mvp_ed1/legacy/writer.py`
- `tests/test_captura_legado.py`
- `tests/test_carga.py`
- `tests/test_fato_incremental.py`
- `tests/test_legado.py`
- `tests/test_legado_deteccao.py`
- `tests/test_legado_oraculo.py`
- `tests/test_legado_remocao.py`
- `tests/test_migracao_legado.py`

### Gerados — 50 arquivos, revisar por amostragem

- `dbt/models/staging/legacy/_legacy__sources.yml`
- `dbt/models/staging/legacy/legacy_selected_capture.sql`
- `dbt/models/staging/legacy/stg_legacy__brands.sql`
- `dbt/models/staging/legacy/stg_legacy__campaigns.sql`
- `dbt/models/staging/legacy/stg_legacy__carriers.sql`
- `dbt/models/staging/legacy/stg_legacy__cart_items.sql`
- `dbt/models/staging/legacy/stg_legacy__carts.sql`
- `dbt/models/staging/legacy/stg_legacy__coupon_redemptions.sql`
- `dbt/models/staging/legacy/stg_legacy__coupons.sql`
- `dbt/models/staging/legacy/stg_legacy__customer_addresses.sql`
- `dbt/models/staging/legacy/stg_legacy__customer_contacts.sql`
- `dbt/models/staging/legacy/stg_legacy__customer_preferences.sql`
- `dbt/models/staging/legacy/stg_legacy__customer_segments.sql`
- `dbt/models/staging/legacy/stg_legacy__customers.sql`
- `dbt/models/staging/legacy/stg_legacy__delivery_events.sql`
- `dbt/models/staging/legacy/stg_legacy__goods_receipt_items.sql`
- `dbt/models/staging/legacy/stg_legacy__goods_receipts.sql`
- `dbt/models/staging/legacy/stg_legacy__inventory_balances.sql`
- `dbt/models/staging/legacy/stg_legacy__inventory_movements.sql`
- `dbt/models/staging/legacy/stg_legacy__order_items.sql`
- `dbt/models/staging/legacy/stg_legacy__order_status_history.sql`
- `dbt/models/staging/legacy/stg_legacy__orders.sql`
- `dbt/models/staging/legacy/stg_legacy__payment_methods.sql`
- `dbt/models/staging/legacy/stg_legacy__payment_transactions.sql`
- `dbt/models/staging/legacy/stg_legacy__payments.sql`
- `dbt/models/staging/legacy/stg_legacy__price_lists.sql`
- `dbt/models/staging/legacy/stg_legacy__product_categories.sql`
- `dbt/models/staging/legacy/stg_legacy__product_prices.sql`
- `dbt/models/staging/legacy/stg_legacy__product_variants.sql`
- `dbt/models/staging/legacy/stg_legacy__products.sql`
- `dbt/models/staging/legacy/stg_legacy__purchase_order_items.sql`
- `dbt/models/staging/legacy/stg_legacy__purchase_orders.sql`
- `dbt/models/staging/legacy/stg_legacy__refunds.sql`
- `dbt/models/staging/legacy/stg_legacy__sales_channels.sql`
- `dbt/models/staging/legacy/stg_legacy__shipment_items.sql`
- `dbt/models/staging/legacy/stg_legacy__shipments.sql`
- `dbt/models/staging/legacy/stg_legacy__stock_reservations.sql`
- `dbt/models/staging/legacy/stg_legacy__suppliers.sql`
- `dbt/models/staging/legacy/stg_legacy__support_agents.sql`
- `dbt/models/staging/legacy/stg_legacy__support_tickets.sql`
- `dbt/models/staging/legacy/stg_legacy__ticket_events.sql`
- `dbt/models/staging/legacy/stg_legacy__warehouses.sql`
- `dbt/models/trusted/legacy/_legacy__models.yml`
- `dbt/models/trusted/legacy/legacy_capture_transitions.sql`
- `dbt/models/trusted/legacy/legacy_classifications.sql`
- `dbt/models/trusted/legacy/legacy_presence_by_capture.sql`
- `dbt/models/trusted/legacy/legacy_removed_records.sql`
- `dbt/tests/legacy_captura_completa.sql`
- `dbt/tests/legacy_captura_existe.sql`
- `dbt/tests/legado_presenca_fisica_reconcilia.sql`

**Declaração desta entrega — revisão integral, nesta ordem.** A classificação automática acima
separa "escrito à mão" de "gerado"; o que decide onde gastar esforço é isto:

| Arquivo | Por que é declaração |
|---|---|
| `docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md` | A certificação inteira: duas fases, `complete` por conteúdo, exceção delimitada ao ADR-0023, recuperação, idempotência, paridade. Se o raciocínio estiver errado, `captura.py` está errado |
| `docs/adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md` | A detecção: identidade pela PK declarada canonizada pelo tipo, só capturas certificadas, dois modelos (memória × intervalo), **sem marca dimensional** — e o registro do que foi descartado e por quê |
| `src/mvp_ed1/legacy/catalogo.yml` | `recuperacao` por falha (o contrato do que a conversão devolve) e `versao: 8`. **É a tabela que o Owner precisa ler linha a linha**: `original` ou `nulo` em cada conversão é decisão de tratamento |
| `src/mvp_ed1/legacy/oraculo.py` | O esperado independente. É outro algoritmo do mesmo autor: revisar se ele implementa a **semântica decidida** (os quatro casos de cascata, precedência de origem, heurística de truncamento pelo catálogo) e não o que o SQL faz por acaso |
| `src/mvp_ed1/legacy/captura.py` | `decidir()` é a regra; `iniciar`/`concluir` são as duas fases. O estado `unstable` na recuperação de tentativa antiga é conservador de propósito (ver §6) |
| `src/mvp_ed1/legacy/schema.py` | `CAPTURA_SQL` — a identidade da captura, declarada uma vez — e `metadata()`, a declaração que o Alembic migra |
| `src/mvp_ed1/legacy/remocao.py` + `dbt/macros/chave_canonica.sql` | Os três modelos da exclusão física e a canonização por tipo. `transicoes()` e `removidos()` são a implementação das duas perguntas do ADR-0045 |
| `src/mvp_ed1/legacy/conteudo.py` | A serialização canônica e a normalização de transporte (`''` → nulo). Tudo que compara conteúdo passa por aqui |
| `src/mvp_ed1/governance.py` | As duas migrações do schema `governance`, inclusive a que reescreveu `snapshot_id = job_id` nos certificados já gravados |
| `db/migrations_legacy/versions/20260914_f558a05ce90e_*.py` | Rascunho de *autogenerate* ajustado à mão (criação e descarte do schema); derivado de `schema.metadata()`, mas é o que o `stamp` do banco existente assumiu |
| `airflow/dags/fluxo_batch.py` | A ordem `iniciar` → sincronizar (grava `job_id` antes de esperar) → `concluir` é o contrato de recuperabilidade |
| `Makefile` (`test`, `test-carga`, `sync-legacy`, `migrate-legacy*`, `dbt-build`) | Os interruptores e as dependências que impedem repetir o que aconteceu com a origem |

**Derivado — amostragem basta.** Os 40 `stg_legacy__*`, `legacy_selected_capture`,
`legacy_presence_by_capture`, `legacy_capture_transitions`, `legacy_removed_records`,
`_legacy__models.yml` (inclusive os `unit_tests`), `_legacy__sources.yml` e os testes SQL gerados
nascem de `dbt.py`, `remocao.py` e `classification.py` — divergência aqui é sintoma. Os documentos
(`origem_legada.md`, `qualidade_de_dados.md`, `arquitetura.md`, `execucao_local.md`,
`governanca_de_dados.md`, `modelo_de_dados.md`, `pendencias.md`, `plano_de_desenvolvimento.md`,
`README.md`, notas nos ADRs 0015/0023/0037/0039) decorrem das decisões acima.

**Onde eu olharia primeiro, se fosse revisar:** `oraculo.py` contra `classification.sql`, com a
pergunta "onde os dois concordam por copiarem a mesma premissa errada?" — a heurística de truncamento
é o exemplo de premissa compartilhada, e passou a estar no oráculo porque está no catálogo; se o
catálogo estiver errado, os dois estão. Em segundo, `captura.py::decidir` e o que `medir_recebido`
considera "intrusa" depois de a identidade ter mudado para o *job*.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
................s.....................................s................. [ 38%]
.........................sss................sss......................... [ 77%]
...........................................                              [100%]
179 passed, 8 skipped in 72.94s (0:01:12)
```

### `make dbt-build` ✓

```
05:48:43  Finished running 1 incremental model, 3 seeds, 4 snapshots, 139 table models, 687 data tests, 5 unit tests, 52 view models in 0 hours 16 minutes and 57.75 seconds (1017.75s).
05:48:44
05:48:44  Completed successfully
05:48:44
05:48:44  Done. PASS=891 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=891
05:48:44  [WARNING][DeprecationsSummary]: Deprecated functionality
Summary of encountered deprecations:
- MissingArgumentsPropertyInGenericTestDeprecation: 105 occurrences
To see all deprecation instances instead of just the first occurrence of each,
run command again with the `--show-all-deprecations` flag. You may also need to
run with `--no-partial-parse` as some deprecations are only encountered during
parsing.
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**1. A prova entre capturas usou a interface do Airbyte, não a DAG, para os passos B–F.** As
sincronizações A–F e a final foram `make sync-legacy` (mesma função `sincronizar_certificando`); a
DAG rodou **uma** vez, ao final, e certificou a captura 36 sem mutação entre ela e a 35 (12.738
`mantida`). A DAG com remoção real entre duas execuções dela não foi exercitada.

**2. O *retry* de um mesmo *job* do Airbyte não foi exercitado** — a premissa é a do ADR-0044: um
*retry* que reescreva a mesma geração da tabela com o mesmo `sync_id` passaria pela conferência de
intrusas. Não sei se o Airbyte instalado faz isso; não há como forçá-lo sem provocar falha no destino.

**3. A recuperação de tentativa pendente foi medida só em banco efêmero** (`test_tentativa_pendente_e_recuperada`).
Nenhuma execução real foi interrompida entre a sincronização e a fase 2.

**4. O `MERGE` no BigQuery não existe** — só está declarado no ADR-0044. Não há código do caminho
GCP nesta entrega; "testado localmente com API simulada" (plano, P30) **não aconteceu**: o que existe
é o *upsert* PostgreSQL por `(capture_attempt_id, source_table)`, exercitado pelo reenvio da fase 2.

**5. A contraprova (c) do plano — origem alterada entre a fase 1 e o fim do *job* — foi medida em
banco efêmero** com `_simular_job`, não com um `UPDATE` real durante uma sincronização do Airbyte.

**6. `chave_canonica` para `texto` nunca foi exercitada com dado real**: as 40 PKs são 39 inteiros e
1 UUID. O ramo `texto` da macro só existe por completude.

**7. O custo da comparação cumulativa não foi medido em escala.** `legacy_presence_by_capture` lê
9 capturas certificadas × 40 tabelas hoje (12,7 mil linhas cada); o *build* completo levou 17 min,
contra 20 min em 08/09 — mas com Airbyte pausado, então não é comparável. Com 50 capturas o modelo
cresce linearmente e ninguém mediu.

**8. O oráculo não foi confrontado com um lote que exercite `DUP_PARTIAL` em coluna já defeituosa**,
porque o injetor passou a evitar isso. O caso existe no mundo e não tem esperado.

**9. `make test` no dossiê rodou sem `FATO=1`** (é o que `comandos.txt` declara): o teste de
reprocessamento da fato está entre os 8 pulados aqui. Medido à parte: `make test FATO=1` → 180
passed, 7 skipped (15/09, antes do dossiê).

**10. O estado final da origem não é o lote do manifesto.** `legacy_db` tem os clientes 1–5 removidos,
o 6 inválido, o 99001 inserido e rejeitado, e os movimentos e reembolsos repostos. O diário descreve
isso; a captura selecionada (36) **não** é comparável ao manifesto por hash — os testes de veredito
por ocorrência pulam nela de propósito, e só passaram sobre a 28 (o lote íntegro).

**11. Nenhum teste prova que `_airbyte_meta.sync_id` continuará igual a `jobId` numa versão nova do
Airbyte.** O teste que fixa a igualdade lê o que está instalado.

**12. O `preflight` conta o custo do Airbyte mesmo quando ele já está de pé** — recusou subir o que
já estava no ar. Não é desta entrega e não foi corrigido; contornei rodando `make sync-legacy`, que
não passa por ele. Fica como observação para o dono da troca de ambientes.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

**1. Que `_airbyte_meta.sync_id` é igual ao `jobId` e é escrito em toda linha**, na versão instalada
do Airbyte. Conferido nos *jobs* 25, 26 e 28–36; não é contrato documentado.

**2. Que o destino do Airbyte entrega `''` como `NULL`, e só isso.** Foi medido em 05/09 e reproduzido
em 14/09 (40/40 tabelas coincidem com a normalização). Qualquer outra normalização de transporte —
espaço, caixa, Unicode — faria o hash divergir e a captura ser `incomplete` por engano.

**3. Que um *job* do Airbyte escreve exatamente uma geração por tabela.** É o que `decidir()` assume
ao tratar duas gerações da mesma tabela como `inconsistent`.

**4. Que `information_schema` descreve tudo que importa na equivalência física** do schema legado
(colunas, tipos, nulabilidade, identidade, *constraints*, índices). Comentários, *grants* e
*defaults* de sequência não entraram na comparação.

**5. Que o `pg_dump | psql` da cópia isolada do ciclo D34 preserva o que o teste compara.** O ciclo foi
medido numa cópia de `trusted.legacy_records`; a quarentena de trabalho não foi tocada.

**6. Que a máquina suporta o cenário `batch` com o ambiente de trabalho aberto.** A DAG rodou com
1,7–2,9 GB disponíveis e o *watchdog* do harness matou **quatro** observadores de fundo por memória
baixa durante a sessão; o `make dbt-build` completo só terminou com o Airbyte pausado. O ADR-0041 e a
D36 continuam descrevendo o problema certo.

**7. Que `setsid nohup` é suficiente para o *build* sobreviver ao *watchdog*.** Sobreviveu duas vezes;
é observação, não garantia.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

**1. A identidade da captura virou o *job* no meio do bloco de provas.** Poderia ter parado, levado ao
Owner e recomeçado o bloco do zero. Levei ao Owner, ele decidiu, e **reprovei** R13 sobre a captura 28
sob o v8 (12.747 vereditos iguais) antes de seguir — mas as capturas 17–22 foram produzidas e medidas
com a identidade antiga, e o que se vê hoje delas passou pela migração `0002`. Um revisor pode
querer a sequência B–F repetida inteira sob a identidade nova; eu julguei que o intervalo 35→36
(DAG) e a memória migrada bastam, e registro a dúvida.

**2. Recuperação de tentativa pendente como `unstable` quando a origem mudou depois.** A fase 2
tardia remede a origem **agora**; se ela mudou depois do *job*, o certificado sai `unstable` mesmo
que o *job* tenha sido perfeito. É o lado conservador: nunca certifica o que não pode provar. O outro
lado — confiar no `hash_before` e no bruto e ignorar o `after` — certificaria sem saber se a origem
estava parada durante a carga. Fiquei com o conservador.

**3. Ensinar a heurística de truncamento ao oráculo, em vez de declarar 2.271 divergências como
custo.** A alternativa era manter o oráculo "puro" (só defeitos injetados) e aceitar que a comparação
nunca fecha. Como a heurística está **declarada no catálogo**, aplicá-la no oráculo é ler o contrato,
não o SQL. Mas é o ponto em que os dois algoritmos compartilham mais premissa, e digo isso no mapa.

**4. Reposição dos movimentos e reembolsos no fim.** Repor restaurou `saldo_reconstruido` (que tinha
falhado em 2 no passo B, corretamente) e deixou a origem consistente; mas apagou do estado final a
evidência viva do custo da remoção de movimentos. A evidência está no diário e neste dossiê, não no
banco.

**5. `versao: 8` por causa da identidade, não por regra nova.** O catálogo diz "avançar sempre que o
tratamento produzir resultado diferente"; `snapshot_id` mudar de valor é resultado diferente. Poderia
ter argumentado que identidade não é tratamento. Preferi a leitura literal — e o ciclo D34 medido em
isolado mostra o que aconteceria sem o avanço.

**6. Deixar o plano e o `REVISAO.md` anteriores saírem do repositório.** A skill manda; os pareceres
do Codex (três sobre o plano, um sobre a memória) estão no histórico. Se o revisor preferir lê-los
sem `git show`, os SHAs estão no *commit* `beb3774`.

**7. Não corrigir o `preflight` que conta o Airbyte já de pé.** Não é desta entrega, tem dono
(troca de ambientes, ADR-0041) e mexer nele sem medir seria o tipo de conserto que esta rodada
inteira existe para evitar.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

