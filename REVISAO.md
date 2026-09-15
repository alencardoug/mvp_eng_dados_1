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

### Parecer do desenvolvimento — Codex, 15/09/2026

**O desenvolvimento ainda não está pronto para encerrar a Etapa 10: seis bloqueantes e seis
ajustes.** A revisão foi feita no ramo `feat/troca-entre-ambientes-pesados`, HEAD `9b4e3d0`,
sobre o intervalo `a66f869..beb3774`. Foram lidos integralmente os declarativos indicados na §2,
os ADRs 0044/0045 e o plano com seus três pareceres, recuperado por
`git show 85ab89a:PLANO_fechamento_etapa_10.md`. O derivado foi conferido por amostragem e por
comparação com a saída dos geradores em memória. Os identificadores `RV10-*` pertencem a esta
revisão; não encerram os R/P anteriores nem substituem o aceite do Owner.

O caminho normal da DAG preserva a ordem das duas fases e grava o `job_id` antes da espera.
A leitura de `governance` permanece delimitada à elegibilidade. A migração do legado passou
pelos testes de criação, reversão e equivalência física. Nos dados retidos, a separação entre
presença física, intervalo com multiplicidade e memória cumulativa reproduziu o ADR-0045,
inclusive ao selecionar capturas antigas. Os bloqueantes abaixo estão na recuperação e
repetição das fases, nas fronteiras de conversão das chaves e no esperado do oráculo.

### Evidências produzidas nesta revisão

As sondas `/tmp/revisao_etapa10_*.py` são arquivos locais da revisão, fora do repositório.
Usam as funções desta revisão do código. As consultas PostgreSQL foram executadas com
`default_transaction_read_only=on`; as sondas de interrupção usam SQLite em memória e
medições simuladas, sem interromper um job real do Airbyte. Os trechos abaixo são saídas
literais, com o alcance de cada prova indicado.

**EV10-01 — suíte disponível.** `make test`, com `CARGA` e `FATO` desativados:

```text
179 passed, 8 skipped in 260.81s (0:04:20)
```

Os oito pulados incluem os dois testes com escrita optativa e seis comparações contra o lote
do manifesto, incompatível com a captura selecionada 36. Portanto, este resultado não é uma
nova medição dos 12.747 vereditos da captura 28. Houve duas tentativas anteriores sem conexão
com os bancos — primeiro sob a restrição de rede do sandbox, depois com `Connection refused`
também fora dele. Depois de os bancos estarem disponíveis, a execução acima passou. Resumos
literais das tentativas sem conexão:

```text
13 failed, 134 passed, 18 skipped, 22 errors in 66.96s (0:01:06)
13 failed, 134 passed, 18 skipped, 22 errors in 67.38s (0:01:07)
```

**EV10-02 — repetição, retomada e interrupção da fase 2.**
`.venv/bin/python /tmp/revisao_etapa10_memoria.py` exercita `iniciar`, `concluir`, `_pendentes`
e `certificadas` com as 40 linhas de controle em memória. No caso de retomada, a tentativa
tem `job_id`, mas o bruto simulado ainda está vazio, estado possível durante a sincronização.
No caso de interrupção, a primeira transação é confirmada e a abertura da segunda falha.

```text
REPLAY primeira: complete [901]
REPLAY apos mudanca posterior: unstable []
JOB_AINDA_EM_CURSO recuperado como: [('incomplete',)]
JOB_AINDA_EM_CURSO tentativa antiga continua pendente: False
CRASH: interrupcao entre as duas transacoes da fase 2
CRASH linhas (status, snapshot_id, count): [('complete', None, 40)]
CRASH pendentes para recuperacao: []
CRASH certificadas: TypeError int() argument must be a string, a bytes-like object or a real number, not 'NoneType'
```

**EV10-03 — conversão pela macro real, em PostgreSQL 16.15.**
`.venv/bin/python /tmp/revisao_etapa10_leitura.py` renderiza `chave_canonica.sql` e compara
seu resultado com a conversão para o tipo declarado, usando apenas `SELECT`. Trechos:

```text
CHAVE: uuid 'a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11'
[('macro', None), ('tipo', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')]
CHAVE: inteiro '9223372036854775808'
[('macro', '9223372036854775808'), ('tipo', '22003', 'value "9223372036854775808" is out of range for type bigint')]
CHAVE: inteiro '+8'
[('macro', None), ('tipo', '8')]
CHAVE: inteiro '08'
[('macro', '8'), ('tipo', '8')]
```

As entradas UUID `{A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11` e
`A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11}` também foram executadas: ambas passam pelo regex
da macro e fazem seu `cast` lançar SQLSTATE `22P02`, em vez de produzir nulo.

**EV10-04 — precedência, ordem da carga e derivação.**
`.venv/bin/python /tmp/revisao_etapa10_contrato.py` usa a transformação real
`injetor._espaco_a_volta`, o oráculo e o SQL de tratamento da coluna `warehouses.name` em
um `SELECT`. O original tem 21 caracteres; a única injeção o leva à largura antiga de 24.
O mesmo script registra a ordem das chamadas do CLI com o escritor e o manifesto simulados
e compara 51 arquivos com os geradores, sem gravá-los — 49 do intervalo e dois metadados de
apoio. Saída pertinente:

```text
TRUNCAMENTO original/injetado: 21 24 '  ABCDEFGHIJKLMNOPQRSTU '
TRUNCAMENTO oraculo: corrected [('TEXT_WHITESPACE_CASE', 'name')] {'name': 'ABCDEFGHIJKLMNOPQRSTU'}
TRUNCAMENTO SQL: [('  ABCDEFGHIJKLMNOPQRSTU ', '  ABCDEFGHIJKLMNOPQRSTU ', 'TEXT_TRUNCATED')]
ORDEM_CLI_SEED: ['COPY/hash/commit', 'manifesto']
GERACAO_EM_MEMORIA: 51 arquivos; divergencias: []
```

**EV10-05 — conteúdo retido e memória calculada independentemente.**
`.venv/bin/python /tmp/revisao_etapa10_retido.py` compara o bruto com os hashes do manifesto
e com as medições antes/depois já persistidas nos certificados. A origem atual não é usada
como substituta da origem histórica:

```text
CLASSIFICACAO: [(36, 8, 12743)]
HASH_MANIFESTO: 28 40 /40; divergentes: []
HASH_MANIFESTO: 35 37 /40; divergentes: ['customers', 'inventory_movements', 'refunds']
HASH_MANIFESTO: 36 37 /40; divergentes: ['customers', 'inventory_movements', 'refunds']
REVALIDAR_CERTIFICADO: 28 {'complete': 40}
REVALIDAR_CERTIFICADO: 29 {'complete': 40}
REVALIDAR_CERTIFICADO: 30 {'complete': 40}
REVALIDAR_CERTIFICADO: 31 {'complete': 40}
REVALIDAR_CERTIFICADO: 32 {'complete': 40}
REVALIDAR_CERTIFICADO: 33 {'complete': 40}
REVALIDAR_CERTIFICADO: 35 {'complete': 40}
REVALIDAR_CERTIFICADO: 36 {'complete': 40}
```

O script também calcula em Python, diretamente do bruto, as transições e a memória para
cada uma dessas oito seleções, incluindo multiplicidades, `last_seen_snapshot_id`,
`removed_in_snapshot_id` e `last_payload`. Compara esse esperado com os `SELECT`s renderizados
de `remocao.py`, usando a presença já materializada. Não foi um novo `dbt build`:

```text
COMPARACAO_BRUTO_PYTHON_SQL:
28 transicoes esperados=0 obtidos=0 divergencias=0
28 memoria esperados=0 obtidos=0 divergencias=0
29 transicoes esperados=12743 obtidos=12743 divergencias=0
29 memoria esperados=8 obtidos=8 divergencias=0
30 transicoes esperados=12735 obtidos=12735 divergencias=0
30 memoria esperados=8 obtidos=8 divergencias=0
31 transicoes esperados=12739 obtidos=12739 divergencias=0
31 memoria esperados=4 obtidos=4 divergencias=0
32 transicoes esperados=12739 obtidos=12739 divergencias=0
32 memoria esperados=5 obtidos=5 divergencias=0
33 transicoes esperados=12738 obtidos=12738 divergencias=0
33 memoria esperados=11 obtidos=11 divergencias=0
35 transicoes esperados=12738 obtidos=12738 divergencias=0
35 memoria esperados=5 obtidos=5 divergencias=0
36 transicoes esperados=12738 obtidos=12738 divergencias=0
36 memoria esperados=5 obtidos=5 divergencias=0
```

**EV10-06 — esperado do diário.** Chamada em memória de
`tests/test_legado_remocao.py::_efeito_liquido`, com remoção solicitada para `1` e `999`,
uma linha apagada e `devolvidas` contendo somente `1`:

```text
DIARIO solicitadas: ['1', '999']
DIARIO devolvidas: ['1']
DIARIO efeito esperado pelo teste: {('brands', '1'): False, ('brands', '999'): False}
```

### Limites desta revisão

Não foram executados `make dbt-build` completo, `make test FATO=1`, `make test CARGA=1`,
nova carga, sincronização ou DAG. Nenhum ambiente pesado foi iniciado ou pausado pelo revisor.
A sequência B–F, a interrupção de um job real e os caminhos BigQuery não foram repetidos.
As contraprovas sintéticas não medem frequência de ocorrência no ambiente; demonstram estados
que o código admite. As medições históricas das §§3–6 permanecem atribuídas ao executor.
Somente este parecer foi acrescentado: código, ADRs e as seções anteriores foram preservados.

### Tabela de achados

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV10-01 | `src/mvp_ed1/legacy/captura.py:208`, `:240`, `:257` | **A fase 2 publica o estado final e a identidade em transações diferentes.** A primeira confirma as 40 linhas como `complete` com `snapshot_id = NULL`; a segunda grava o job como identidade. Uma interrupção entre elas deixa um estado que `_pendentes` não encontra e faz `certificadas` falhar em `int(None)` (EV10-02). A próxima execução normal não recupera essa tentativa. Publicar identidade e resultado atomicamente, ou manter um estado intermediário explicitamente recuperável; provar a interrupção entre as gravações e a retomada. Contraria recuperação e publicação do ADR-0044, itens 4–5. | `bloqueante` | **Corrigido em 15/09/2026.** `concluir` publica veredito e `snapshot_id` das 40 linhas numa única transação (`_publicar`), com `where status = 'pending'`; `certificadas` ignora `complete` sem identidade. Prova: `test_interrupcao_no_meio_da_publicacao_nao_deixa_nada_e_a_retomada_conclui` — transação morta depois de 25 comandos deixa 40 `pending` sem identidade, `_pendentes` a lista, `retomar` conclui. Nota datada no ADR-0044, item 5. |
| RV10-02 | `src/mvp_ed1/legacy/captura.py:187`, `:203` | **Reenviar uma conclusão pode revogar um certificado histórico válido.** `concluir` não lê o estado final persistido: remede a origem e sobrescreve medidas, estado e horário. Após uma conclusão `complete`, uma alteração legítima posterior na origem faz o mesmo attempt virar `unstable` e sair das elegíveis (EV10-02), mudando também a história usada pela memória. Isso é diferente da conclusão tardia de uma tentativa ainda `pending`, assumida na §6.2. Repetição de tentativa finalizada deve devolver o resultado persistido, conforme a idempotência do ADR-0044, item 5; acrescentar prova com origem alterada depois da primeira conclusão. | `bloqueante` | **Corrigido em 15/09/2026.** `concluir` lê o estado persistido e, se nenhuma linha é `pending`, devolve o certificado gravado sem remedir nada. Prova: `test_reenviar_a_conclusao_devolve_o_certificado_gravado_sem_remedir_a_origem` — origem alterada depois do `complete`, reenvio devolve o mesmo e `source_hash_after`/`completed_at` não mudam. |
| RV10-03 | `src/mvp_ed1/legacy/captura.py:139` | **A retomada não distingue tentativa interrompida de job ainda em execução.** `iniciar` chama `concluir` para todo pendente com `job_id`, sem consultar ou aguardar o estado terminal no Airbyte; pendente sem job é abandonado mesmo que outro chamador esteja entre a fase 1 e o registro do job. Após perder o observador de uma sync, uma nova chamada pode fechar o bruto ainda parcial como `incomplete` e retirar a tentativa da recuperação (EV10-02). `max_active_runs=1` da DAG não exclui o CLI. Condicionar a conclusão ao término observado do job e impedir que a retomada encerre uma tentativa ainda ativa. Exercitar retomada durante a sync e sobreposição entre chamadores. ADR-0044, itens 2 e 4. | `bloqueante` | **Corrigido em 15/09/2026.** `retomar` (chamado por `iniciar`) só conclui pendente com *job* depois de um observador (`airbyte.estado_do_job`, passado pela DAG e por `sincronizar_certificando`) dizer que ele terminou; sem observador fica pendente; pendente sem *job* só é abandonada depois de `CARENCIA_SEM_JOB` (1 h da fase 1) — carência decidida pelo Owner em 15/09. Prova: `test_a_retomada_nao_fecha_tentativa_com_job_em_curso_nem_sem_job_dentro_da_carencia` (bruto parcial com `running` não é fechado; sobreposição de chamadores preservada). Interrupção de um *job* real continua não executada. |
| RV10-04 | `dbt/macros/chave_canonica.sql:34` | **A guarda UUID deixa um texto inválido derrubar a presença e descarta representações válidas.** As chaves `{UUID` e `UUID}` passam pelo regex, pois abertura e fechamento são opcionais independentes, mas o cast lança `22P02`. Já `a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11` converte no PostgreSQL e a macro devolve nulo (EV10-03). Isso pode interromper o build ou transformar mudança de representação em ausência. A fronteira deve corresponder à conversão UUID do ADR-0045, item 1, devolvendo nulo com segurança para inválidos. Testar a macro real com esses casos; os exemplos com chaves já canonizadas não a exercitam. | `bloqueante` | **Corrigido em 15/09/2026.** A guarda passou a ser a gramática de entrada do PostgreSQL, medida forma a forma: chaves `{}` só aos pares, hífen só depois de grupo de quatro, sem espaço à volta (o `cast` não apara — resultado que mudou, registrado no ADR-0045). Prova: `test_a_macro_real_devolve_o_que_o_cast_do_postgresql_devolve_ou_nulo` executa a macro **renderizada** contra 18 formas de UUID e confere, caso a caso, igualdade com `::uuid` ou nulo onde ele lança. |
| RV10-05 | `dbt/macros/chave_canonica.sql:29`; `src/mvp_ed1/legacy/remocao.py` — escolha do tipo | **A identidade inteira não respeita o domínio da PK declarada.** A macro converte para `numeric`: aceita `9223372036854775808`, que não cabe em `BigInteger`, e rejeita `+8`, que converte para a mesma chave `8` (EV10-03). Assim, uma chave não conversível entra na comparação e uma representação válida vira `sem identidade`, contrariando o ADR-0045, item 1. Preservar o domínio do tipo declarado na geração e conferir sinal, limites e valores externos ao domínio na macro executada. | `bloqueante` | **Corrigido em 15/09/2026.** `remocao.chave` passa a devolver o domínio declarado (`bigint`/`integer`/`smallint`, lido do SQLAlchemy) em vez de `inteiro`; a macro aceita sinal e espaço, confere o domínio em `numeric` e converte ao tipo. `remocao.canonizar` é o espelho em Python. Prova: o mesmo teste da macro, com 16 formas de `bigint` e 5 de `integer` (`+8` → `8`; `9223372036854775808` → nulo), e `test_a_canonizacao_em_python_segue_a_gramatica_do_postgresql`. |
| RV10-06 | `src/mvp_ed1/legacy/oraculo.py:198`, `:217`, `:220`; precedência em `legacy/catalogo.yml` | **O oráculo aplica a recuperação antes da heurística de truncamento e ignora a precedência no texto bruto.** Uma única injeção de espaços em `warehouses.name`, de 21 para 24 caracteres, recebe `corrected/TEXT_WHITESPACE_CASE` no oráculo; o catálogo dá precedência a `TEXT_TRUNCATED`, como faz o SQL, preservando o texto e rejeitando-o (EV10-04). O oráculo mede o texto já recuperado e ainda pula a coluna se nela existir qualquer achado. O erro também afeta a aptidão usada na cascata. Calcular o esperado respeitando a precedência declarada sobre a entrada, independentemente do SQL, e incluir esta sobreposição literal. Não mudar o contrato para acomodar o esperado incorreto. | `bloqueante` | **Corrigido em 15/09/2026.** O oráculo resolve os candidatos por coluna — o declarado pelo injetor e a heurística de truncamento medida na **entrada** — pela ordem de declaração do catálogo; a rejeição que precede uma correção preserva o texto e não recupera valor. O manifesto do lote corrente não muda (hash, 12.747 vereditos e achados iguais, conferido em memória). Prova: `test_a_precedencia_do_catalogo_vale_sobre_a_entrada_bruta` com a sobreposição literal (21 → 24 em `warehouses.name`). |
| RV10-07 | `src/mvp_ed1/legacy/cli.py:196`, `:200`; plano histórico §2, item 5/P21 | **O manifesto nasce depois do COPY confirmado, invertendo a ordem acordada.** O CLI chama `writer.escrever` antes de `gravar_manifesto`; EV10-04 confirma `COPY/hash/commit → manifesto`. Uma interrupção ou falha no cálculo/escrita do manifesto deixa a carga confirmada sem o esperado durável que deveria antecedê-la. Gravar e validar o manifesto antes da carga, mantendo a conferência do hash do banco depois do COPY; exercitar falha na gravação do manifesto e garantir que a carga ainda não ocorreu. | `ajuste` | **Corrigido em 15/09/2026.** `seed` confere o destino (`writer.exigir_destino`), grava o manifesto e só então carrega; o hash do banco continua conferido depois do `COPY`. Prova: `test_o_seed_grava_o_manifesto_antes_da_carga_e_nao_carrega_se_o_manifesto_falhar` com escritor e manifesto simulados. |
| RV10-08 | ADR-0044 — paridade, linhas 124–130; `src/mvp_ed1/legacy/captura.py`, `src/mvp_ed1/governance.py`, `tests/test_captura_legado.py`; plano P30 | **A prova local de idempotência da escrita BigQuery acordada no plano não foi entregue.** Não há caminho de staging seguido de MERGE no módulo nem testes com API simulada para resposta parcial e retorno perdido. A §4.4 deste dossiê reconhece a ausência; o ADR e a situação final de P30 prometem esses testes locais, deixando somente a medição ao vivo para a fase 2. Entregar a implementação simulável e as contraprovas previstas, ou submeter o adiamento desse recorte ao Owner e registrá-lo no dono documental atual, preservando o ADR aceito. | `ajuste` | **Adiado por decisão do Owner em 15/09/2026**, registrado no mapa de paridade (Arquitetura §5) e em nota datada no ADR-0044: o caminho BigQuery e os testes com API simulada nascem com o módulo na Etapa 13. Nenhum código GCP na fase local; a decisão de escrever por *staging* + `MERGE` não muda. |
| RV10-09 | `tests/test_legado_oraculo.py:193`, `:221`; plano histórico §2, item 8 | **As contraprovas não exercitam os caminhos que deveriam proteger.** O teste copia `esperado` para `obtido` e altera objetos `Veredito`; isso prova o comparador, mas não injeta defeito no algoritmo do oráculo nem no SQL compilado para demonstrar falha da integração, como acordado em R13. A mutação de conteúdo só verifica a mudança do hash, sem executar a recusa da comparação. Acrescentar as três contraprovas nos respectivos caminhos, sobre lote compatível com o manifesto e sem depender dos skips da captura 36. | `ajuste` | **Corrigido em 15/09/2026**, pelo caminho local decidido pelo Owner (sem ambiente pesado): `tests/test_legado_contraprovas.py` carrega o lote gerado num armazém efêmero como o Airbyte o entregaria — compatível com o manifesto **por construção** — e (a) muta o algoritmo do oráculo (cascata, precedência, origem da rejeição) → diverge do manifesto; (b) executa os 40 modelos de limpeza compilados no PostgreSQL e compara achado a achado e valor a valor com o oráculo, depois muta o SQL (rótulo trocado, `btrim` removido, ramo anulado) → acusado; (c) executa a recusa por hash (`conteudo.tabelas_divergentes`, agora a mesma função da *fixture* de integração). A classificação completa (contexto e cascata) segue coberta só quando a captura selecionada é o lote do manifesto. Custo: as 40 tabelas levavam 656 s porque o SQL compilado deixava o planejador embutir o CTE `limpo` em cada referência — achado novo, decidido pelo Owner no mesmo dia como **ADR-0047** (`materialized` no PostgreSQL): 47 s depois. |
| RV10-10 | `tests/test_legado_remocao.py:148`, `:155` | **O esperado do diário volta a usar intenção em lugar de RETURNING.** Se uma remoção pede `1` e `999`, mas só `1` existe, `_efeito_liquido` marca ambas ausentes porque `linhas_apagadas` é não zero, ignorando `devolvidas` (EV10-06). Uma alteração de zero linhas também marca a chave como presente. Isso fabrica testemunhas e pode reprovar uma memória correta. Derivar o efeito das linhas efetivamente devolvidas, com chave canonizada pelo tipo, e cobrir remoção parcial e alteração sem correspondência. O diário de produção contém a evidência; seu consumidor deve usá-la, conforme o ADR-0045, item 6. | `ajuste` | **Corrigido em 15/09/2026.** `mutacoes.efeito_liquido` deriva do `RETURNING` (`devolvidas`), canoniza a chave pelo tipo e ignora alteração sem linha devolvida; o teste de integração passa a usá-la. Prova: `test_o_efeito_liquido_sai_do_que_o_banco_devolveu_e_nao_do_que_se_pediu` (remoção parcial `1`/`999`, `08` → `8`, alteração de zero linhas, chave sem identidade). |
| RV10-11 | `src/mvp_ed1/legacy/dbt.py:314`; fonte gerada `governance.legacy_captures` | **Os campos novos do certificado ficaram sem dicionário e classificação de sensibilidade.** A source tem descrição da tabela, mas nenhuma entrada de coluna ou metadado de sensibilidade; os metadados gerados de `trusted` não cobrem essa fonte. A descrição geral do objeto não satisfaz a classificação dos campos novos exigida em `CLAUDE.md` §7. Declarar os campos e suas classificações no gerador responsável, regenerar a fonte e conferir sua presença no catálogo. | `ajuste` | **Corrigido em 15/09/2026.** `dbt.COLUNAS_DO_CERTIFICADO` declara as 15 colunas com descrição e `sensitivity: internal`, mais `domain`/`owner`; `_legacy__sources.yml` regenerada; `dbt parse` mostra as 15 colunas no manifesto do catálogo. Prova: `test_a_source_do_certificado_declara_todas_as_colunas_do_ddl` confere a lista contra o `information_schema` do DDL de `governance`. |
| RV10-12 | `docs/plano_de_desenvolvimento.md:256` | **O registro permanente atribui a comparação integral do manifesto também à captura 35, que é outro lote.** A linha afirma 12.747 vereditos e 44 recuperações conferidos nas capturas 28 e 35. O próprio dossiê restringe a comparação integral à 28, e EV10-05 confirma que a 35 diverge do manifesto em três tabelas. Corrigir a atribuição no registro atual, separando a prova do lote íntegro das provas de mutação/remoção e preservando os ADRs aceitos. Não usar o resultado de uma captura para preencher o critério de outra. | `ajuste` | **Corrigido em 15/09/2026.** O critério no plano atribui a comparação integral só à captura 28 e diz o que as 29–36 provam (mutação e remoção). README não fazia a atribuição errada. |

### Resposta do desenvolvimento — 15/09/2026

Doze achados: onze corrigidos, um adiado por decisão do Owner (RV10-08). As três decisões que a
resposta exigiu foram tomadas pelo Owner antes de qualquer código: adiar o caminho BigQuery e os
seus testes simulados para a Etapa 13; provar as contraprovas (a)(b)(c) localmente, sem ambiente
pesado, sobre o lote carregado num armazém efêmero; e resolver a tentativa sem *job* por carência de
uma hora. A coluna *Situação* de cada linha acima diz o que mudou e onde está a prova.

**Medido**, saída literal:

`make test` (sem `FATO`, `CARGA` e `LOTE`) — os oito pulados são os mesmos de antes (fato de
trabalho e seis comparações contra o lote do manifesto, que a captura selecionada 36 não é):

```text
216 passed, 8 skipped in 216.98s (0:03:36)
```

`.venv/bin/pytest tests/test_legado_contraprovas.py` sobre as 40 tabelas, **antes** do ADR-0047 (o
SQL compilado com o CTE `limpo` embutido pelo planejador):

```text
655.78s call     tests/test_legado_contraprovas.py::test_b_a_limpeza_compilada_concorda_com_o_oraculo_sobre_o_lote_inteiro
6 passed in 714.34s (0:11:54)
```

O mesmo arquivo, as mesmas 40 tabelas, **depois** do ADR-0047 (`limpo as materialized`):

```text
46.55s call     tests/test_legado_contraprovas.py::test_b_a_limpeza_compilada_concorda_com_o_oraculo
4.80s setup    tests/test_legado_contraprovas.py::test_c_conteudo_diferente_com_as_mesmas_identidades_recusa_a_comparacao
6 passed in 61.26s (0:01:01)
```

`make dbt-build DBT_ARGS='--select path:models/staging/legacy'` — as 41 tabelas de *staging* do legado
regeradas com o CTE materializado, no armazém de trabalho (não há medição anterior deste recorte
isolado; o *build* completo de 15/09 levou 17 min com o Airbyte pausado):

```text
6 of 284 OK created sql table model staging.stg_legacy__carts .................. [SELECT 2000 in 15.74s]
5 of 284 OK created sql table model staging.stg_legacy__cart_items ............. [SELECT 5500 in 31.41s]
Finished running 41 table models, 243 data tests in 0 hours 0 minutes and 42.55 seconds (42.55s).
Done. PASS=284 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=284
```

A palavra `materialized` move a impressão digital do tratamento (D34 hasheia o SQL gerado):
`8710ca3f…` → `92f72e5d…`. Pela leitura literal da D34, decidida pelo Owner, `versao` avançou para
**9** sem regra nova; o manifesto do lote foi regerado com `versao_catalogo: 9` (mesmo hash, diário
preservado). **O armazém continua auditado em v8**: `trusted.legacy_classifications` e a quarentena
só recebem a v9 no próximo `dbt build` completo — não executado nesta resposta, e é onde
`legacy_versao_do_tratamento_e_univoca` deve passar com as duas auditorias lado a lado.

`make dbt-build DBT_ARGS='--select legacy_presence_by_capture+'` — os três modelos da exclusão
física com a macro nova, sobre as oito capturas certificadas do armazém de trabalho; o resultado é o
mesmo de antes da macro (5 na memória, 12.738 `mantida` no intervalo 35→36, zero `sem_identidade`):

```text
1 of 27 OK created sql table model trusted.legacy_presence_by_capture .......... [SELECT 101897 in 3.70s]
11 of 27 OK created sql table model trusted.legacy_removed_records ............. [SELECT 5 in 0.68s]
12 of 27 OK created sql table model trusted.legacy_capture_transitions ......... [SELECT 12738 in 0.80s]
Done. PASS=27 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=27
```

`dbt parse` — a *source* `governance.legacy_captures` no manifesto do catálogo passa a ter 15
colunas, todas com `sensitivity: internal`.

O manifesto do lote corrente **não muda** com o oráculo corrigido: hash, 12.747 vereditos e achados
iguais aos gravados, conferido em memória (a sobreposição do RV10-06 não ocorre no lote).

**Não verificado nesta resposta:** `make dbt-build` completo (só os dois recortes acima; a v9 ainda não está no armazém); `make test FATO=1`
e `CARGA=1`; a DAG com a retomada nova (`estado_do_job` só foi exercitado com observador simulado);
interrupção de um *job* real do Airbyte; e os seis testes de veredito por ocorrência continuam
pulando na captura 36 — a prova sobre o lote compatível é a do armazém efêmero.

**Achado novo, fora da lista:** a lentidão da contraprova (b) era do SQL compilado — o planejador
embute o CTE `limpo` em cada referência do `case` de achados (94 s → 8,7 s em `carts` com
`materialized`). Medição em Capacidade §2.11; decidido pelo Owner no mesmo dia como **ADR-0047**
(`materialized` só no adaptador PostgreSQL), com os 40 modelos regerados. Na mesma sessão o Owner
fechou a **D36** (ADR-0046: a Etapa 12 valida por partes) — fora do escopo desta revisão, registrado
aqui só porque entra no mesmo intervalo de *commits*.
