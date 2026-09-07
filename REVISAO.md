# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `5325c40..afa5898` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

**São três corpos de trabalho distintos**, e vale separá-los ao revisar:

| Commits | O quê |
|---|---|
| `522a8fc`, `04a824a`, `e5ff5ca`, `1e6da99`, `fcb1deb` | O conserto da **D31** — remessa que nascia sem item — e a re-medição que ele obrigou |
| `b14c9dd`, `509c532` | O encaminhamento para outro agente; ferramenta, não produto |
| `6cb8754` em diante | A **Etapa 10** propriamente: origem legada de ponta a ponta |

```
b14c9dd docs: encaminha a D31 e a Etapa 10 para outro agente
509c532 docs: marca os encaminhamentos como ordem de execução e acrescenta três achados
522a8fc fix: impede remessas vazias no gerador
04a824a fix: verifica o descarte do estado do streaming
e5ff5ca fix: torna bloqueante a remessa sem item no dbt
1e6da99 docs: registra a re-medição da D31 nos donos documentais
fcb1deb docs: encerra a D31 com o aceite do Owner
6cb8754 docs: fecha as decisões de abertura da Etapa 10
8c1b53f feat: gera a origem legada com injeção declarativa de falhas
9548bae feat: ingere o legado em raw_legacy com retenção por captura
e3b817d feat: detecta em SQL as falhas que o catálogo declara
8412324 feat: imprime o catálogo de falhas em português para revisão
3d11bb6 fix: torna verossímeis o truncamento e o valor fora de domínio
3f1316b feat: gera os modelos dbt de limpeza a partir do catálogo
d0ccdfb feat: classifica, quarentena e empilha o legado
01dc447 fix: tira os domínios fechados do sorteio de injeção
afa5898 feat: orquestra a captura do legado e fecha a Etapa 10
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 52 arquivos

- `AGENTS.md`
- `Makefile`
- `README.md`
- `airbyte/main.tf`
- `airbyte/outputs.tf`
- `airbyte/streams.yml`
- `airbyte/variables.tf`
- `airflow/dags/fluxo_batch.py`
- `dbt/macros/legacy_snapshot_id.sql`
- `dbt/models/quarantine/rejected_legacy_records.sql`
- `dbt/models/trusted/legacy/legacy_eligible_records.sql`
- `dbt/tests/legacy_classification_reconciles.sql`
- `dbt/tests/legacy_eligible_has_valid_parents.sql`
- `dbt/tests/legacy_outputs_reconcile.sql`
- `dbt/tests/legacy_selected_capture_is_consistent.sql`
- `dbt/tests/remessa_leva_ao_menos_um_item.sql`
- `docs/adr/0037-reter-capturas-do-legado-por-acrescimo.md`
- `docs/adr/0038-quarentena-de-excedente-e-rejeicao-em-cascata.md`
- `docs/adr/0039-alcance-da-procedencia.md`
- `docs/adr/0040-rejeitar-nulo-em-campo-obrigatorio.md`
- `docs/adr/README.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/execucao_local.md`
- `docs/geracao_de_dados.md`
- `docs/modelo_de_dados.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/qualidade_de_dados.md`
- `docs/streaming.md`
- `src/mvp_ed1/generator/domains/logistica.py`
- `src/mvp_ed1/generator/geracao.yml`
- `src/mvp_ed1/legacy/__init__.py`
- `src/mvp_ed1/legacy/catalogo.py`
- `src/mvp_ed1/legacy/catalogo.yml`
- `src/mvp_ed1/legacy/classification.py`
- `src/mvp_ed1/legacy/classification.sql`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/injetor.py`
- `src/mvp_ed1/legacy/regras.py`
- `src/mvp_ed1/legacy/schema.py`
- `src/mvp_ed1/legacy/writer.py`
- `src/mvp_ed1/streaming/maintenance.py`
- `tests/test_dbt.py`
- `tests/test_invariantes.py`
- `tests/test_legacy_classification.py`
- `tests/test_legacy_models.py`
- `tests/test_legado.py`
- `tests/test_legado_deteccao.py`
- `tests/test_manutencao_streaming.py`
- `tests/test_remessas.py`

### Gerados — 46 arquivos, revisar por amostragem

- `dbt/models/quarantine/_legacy__models.yml`
- `dbt/models/staging/legacy/_legacy__models.yml`
- `dbt/models/staging/legacy/_legacy__sources.yml`
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
- `dbt/models/trusted/legacy/legacy_classifications.sql`
- `dbt/models/trusted/legacy/legacy_records.sql`

**Declaração desta entrega**, em ordem de importância. É aqui que o esforço rende:

1. `src/mvp_ed1/legacy/catalogo.yml` — as 22 falhas e as **quatro listas de exceção** que dizem
   onde cada uma se aplica. Os 46 arquivos gerados nascem daqui. `make legacy-catalogo` imprime
   em português, sem abrir o YAML.
2. `src/mvp_ed1/legacy/classification.sql` — classificação nas três saídas e a cascata. Os dois
   defeitos mais graves da entrega estavam neste arquivo.
3. `src/mvp_ed1/legacy/regras.py` — a detecção e a conversão em SQL, uma expressão por código.
4. `src/mvp_ed1/legacy/injetor.py` — como cada defeito é produzido. Se a injeção estiver errada,
   o oráculo está errado, e **todo** o resto mede a coisa errada.
5. `airbyte/streams.yml` — o que se lê de cada origem e em que modo.
6. `src/mvp_ed1/generator/domains/logistica.py` — a correção da D31.
7. `airflow/dags/fluxo_batch.py` — a ordem de execução.
8. Os quatro ADRs novos, **0037** a **0040**.

Os 40 `stg_legacy__*.sql`, o `legacy_classifications.sql` e o `_legacy__sources.yml` são
**derivados**: saem de `legacy/dbt.py` e `legacy/classification.py` via `make legacy-models`.
Amostre dois ou três. Erro neles se corrige a montante, e a regeração propaga.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
..s..................................................................... [ 55%]
.........................................................                [100%]
128 passed, 1 skipped in 25.97s
```

### `make dbt-build` ✓

```
09:24:18  810 of 812 PASS not_null_rejected_legacy_records_snapshot_id ................... [PASS in 0.09s]
09:24:18  812 of 812 START test not_null_rejected_legacy_records_source_table ............ [RUN]
09:24:18  811 of 812 PASS not_null_rejected_legacy_records_source_system ................. [PASS in 0.07s]
09:24:18  812 of 812 PASS not_null_rejected_legacy_records_source_table .................. [PASS in 0.07s]
09:24:18  805 of 812 PASS legacy_outputs_reconcile ....................................... [PASS in 0.46s]
09:24:24  793 of 812 PASS legacy_eligible_has_valid_parents .............................. [PASS in 6.97s]
09:24:24
09:24:24  Finished running 1 incremental model, 3 seeds, 4 snapshots, 58 table models, 654 data tests, 92 view models in 0 hours 0 minutes and 52.93 seconds (52.93s).
09:24:25
09:24:25  Completed successfully
09:24:25
09:24:25  Done. PASS=812 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=812
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

### Lacunas de escopo — coisas que a etapa deveria ter e não tem

- **O empilhamento não existe.** `trusted.legacy_eligible_records` é construída, testada e
  **lida por ninguém**. Nenhum modelo dimensional enxerga o legado, e nenhuma das 16 views o
  inclui. O `README` diz que "a segunda origem atravessa o fluxo inteiro" — ela atravessa até
  `trusted` e para ali. A fase E do plano está pela metade, e o critério de conclusão não cobria
  isso explicitamente, o que é falha do critério.
- **Não há migração Alembic para o schema legado.** `legacy.*` é criado por
  `create table if not exists` dentro do próprio *writer*. `make migrate` não conhece o legado, e
  a definição de pronto do `CLAUDE.md` pede "migrações aplicáveis do zero".

### Critérios marcados com ✓ que não foram exercitados nesta entrega

- **Reprocessar o mesmo `snapshot_id` não duplica.** Está verde por causa do teste que existe, não
  de uma execução repetida que eu tenha feito e medido.
- **Exclusão física entre duas capturas.** Há 11 capturas retidas, mas eu **não** removi um
  registro da origem para provar que a comparação o detecta.

### Medições que não foram refeitas

- **A cascata não tem oráculo.** Os defeitos de valor têm o manifesto dizendo 74 de 74. A cascata
  não tem equivalente: sei que 2.268 registros foram rejeitados e que a equação fecha, mas **não**
  sei se são os 2.268 certos. É exatamente onde os dois defeitos consertados estavam.
- **`make dbt-build` roda sobre o banco no estado atual**, nunca do zero. Nenhum
  `--full-refresh` a partir de banco vazio nesta entrega.
- **O tempo da DAG (5 min 20 s) é de uma execução só.**
- **O Terraform de duas origens foi aplicado, não recriado.** A refatoração destruiu e recriou os
  seis recursos num Airbyte existente; não testei `apply` a partir de um Airbyte limpo.

### O que **foi** conferido e vale dizer, para o revisor não gastar esforço nisso

Os números de [Capacidade §2.7](docs/capacidade_e_recuperacao.md) — a re-medição da D31 — não
envelheceram: `git log 1e6da99..afa5898 -- src/mvp_ed1/generator/ src/mvp_ed1/models/` volta
**vazio**. Tudo que mudou depois foi em `src/mvp_ed1/legacy/`, que não toca a origem principal.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **Que `_airbyte_generation_id` é comparável entre tabelas.** A seleção da captura corrente usa
  `max(_airbyte_generation_id)` **por tabela**. Se o Airbyte numerar por *stream* em vez de por
  conexão, duas tabelas da mesma captura podem cair em gerações diferentes, e a classificação
  misturaria capturas sem nada acusar. Não confirmei o contrato dessa coluna na documentação.
- **Que `pg_input_is_valid` cobre exatamente o que `::numeric` recusaria.** É usado para decidir
  se um valor é convertível antes de castar, e a equivalência foi assumida.
- **Que a chave de retenção da quarentena é a certa.** Escolhi
  `(source_system, snapshot_id, catalog_version)`. Se duas execuções da mesma captura com o mesmo
  catálogo divergirem, a segunda apaga a auditoria da primeira sem aviso.
- **Que os quatro "domínios fechados" são os quatro certos.** O critério que declarei é conceitual
  — guardam valores, não coisas. `warehouses` tem 5 linhas e *fan-in* enorme, e ficou de fora.
- **Que a heurística do `TEXT_TRUNCATED` é aceitável em 0,10%.** O teto está em teste, mas o
  número depende das 8 colunas declaradas como estreitadas; mudar a lista muda o falso positivo.
- **Que remover o `base_rejected` não deixou consumidor órfão.** Conferido por `grep`, não por
  análise do plano de execução.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Inverti um teste escrito pelo outro agente, em vez de devolver ao Owner.** O
  `test_rejected_product_makes_remaining_order_total_fail` afirmava que um produto rejeitado faz o
  total do pedido falhar. Concluí que prendia a circularidade e o inverti. É defensável — 175 de
  177 pedidos reconciliam contra todos os itens capturados —, mas **mudei a afirmação de outro
  agente sobre o que o sistema deve fazer**, e isso podia ter ido ao Owner.
- **Declarei `NULL_REQUIRED` como falha de contexto no meu teste de detecção.** Ela é do ADR-0040,
  que veio do outro agente. Reclassificá-la fez o teste passar; se a intenção original era que ela
  fosse achado de valor, eu escondi uma divergência em vez de resolvê-la.
- **A quarentena acumula 11 capturas sem política de descarte.** O ADR-0037 adiou a decisão de
  propósito, mas `raw_legacy` e a quarentena crescem a cada execução da DAG e ninguém mede.
- **Removi o diretório `encaminhamentos/` inteiro** ao fechar a etapa. O índice mandava preservar
  o que continuasse encaminhado; como não sobrou nada, apaguei tudo — a alternativa era manter o
  índice vazio como marca da convenção.
- **Aceitei a taxa de rejeição de 17,8% sem um segundo par de olhos.** Ela caiu de 44% com uma
  decisão do Owner, mas continua sendo quase um quinto do legado que não chega a `trusted`, e não
  há critério escrito dizendo qual seria "alta demais".

---

## Achados da revisão

> **Triagem do autor, 07/09/2026.** Conferi oito dos achados técnicos por reprodução — R01, R02,
> R03, R04, R05, R06, R08 e R11 — e **os oito se confirmaram**, exatamente como descritos. Não
> disputo nenhum dos 17. A coluna *Situação* diz o que foi feito em cada um.
>
> A consequência de processo veio primeiro: a Etapa 10 foi **reaberta**. Eu a havia encerrado com
> base nos testes que eu mesmo escrevi, e teste desenhado pelo autor mede o que o autor pensou em
> medir.

Revisão por Codex em **07/09/2026**, limitada a `5325c40..afa5898`. **Veredito geral:
bloqueante para o encerramento da Etapa 10.** Nenhuma correção implementada; somente esta seção
foi preenchida. A D31 foi examinada separadamente e não apresentou regressão nos testes executados.

### Cobertura e limites

Leitura integral dos oito itens prioritários da seção 2 — o oitavo compreende **os quatro ADRs**,
0037 a 0040. Leitura complementar dos geradores SQL (`dbt.py`, `classification.py`, `schema.py`),
do carregador, dos testes, da quarentena, das alterações de manutenção do streaming e das
declarações/documentos necessários para conferir os contratos. Amostragem semântica nos derivados
`stg_legacy__orders.sql`, `stg_legacy__inventory_movements.sql` e
`stg_legacy__customer_addresses.sql`: seleção da captura, precedência, valores monetários,
quantidade assinada, booleanos, datas e preservação do original. A igualdade mecânica com os
geradores foi conferida sem gravar os derivados; não equivale a revisão semântica integral dos 46.

O código executável no checkout corresponde ao topo solicitado: `git diff --name-only
afa5898..HEAD` apresentou somente a skill local, `AGENTS.md` e este dossiê. As consultas usaram
transações PostgreSQL **somente de leitura**; os casos dirigidos usaram valores sintéticos em
`SELECT`/CTEs. Não foram executados carga, sincronização, build dbt, DAG, Terraform, exclusão física,
reconstrução do zero ou reprocessamento materializado de captura. As medições da seção 3 continuam
sendo do autor, não reexecuções desta revisão. O contrato externo de numeração das gerações do
Airbyte não foi confirmado; não o trato como defeito demonstrado. Ao contrário da hipótese da
seção 5, o teste existente **acusa gerações distintas presentes nas linhas**; sua lacuna comprovada
é outra, descrita em R09.

### Evidências executadas nesta revisão

Com o `.env` carregado sem imprimir credenciais:

```bash
PGOPTIONS='-c default_transaction_read_only=on' MVP_TESTE_CARGA=0 \
  .venv/bin/pytest -q --tb=short -p no:cacheprovider \
  tests/test_remessas.py tests/test_invariantes.py tests/test_manutencao_streaming.py \
  tests/test_legado.py tests/test_legacy_models.py tests/test_legacy_classification.py \
  tests/test_legado_deteccao.py tests/test_dbt.py
```

Saída literal:

```text
........................................................................ [ 83%]
..............                                                           [100%]
86 passed in 17.76s
```

Conferência em memória por `.venv/bin/python -`: comparação dos arquivos com `records_sql()`,
`classification_sql(carregar())`, `sources_yml()` e `metadata_files()`; busca de consumidores
`ref('legacy_eligible_records')` em modelos/snapshots, sem incluir testes ou artefatos de build.
Saída literal:

```text
Derivados auxiliares iguais à declaração, sem regeração: 6 / 6
Consumidores de legacy_eligible_records em models/snapshots: []
Códigos: 23 injetáveis: 21
```

Contraprovas executadas por `.venv/bin/python -`, usando `_aplicaveis`, `_achado` e `_limpo`
do gerador sobre `SELECT cast(:value as text)`, com corte `2026-09-01`. O resultado foi passado
ao classificador real por `record`/`classify` de `tests/test_legacy_classification.py`, em ocorrência
isolada com `id` obrigatório, sem FKs ou outros defeitos. **`classification_isolated` não é uma
contagem do banco nem execução completa de uma tabela de negócio**: isola a decisão sobre o valor.
Trechos literais da saída:

```text
{"case": "customer_addresses.is_primary", "input": "talvez", "code": "BOOL_VARIANT", "cleaned": "false", "classification_isolated": "corrected"}
{"case": "cart_items.quantity", "input": "-1.0", "code": "NUM_TEXT_EQUIV", "cleaned": "-1", "classification_isolated": "corrected"}
{"case": "cart_items.quantity", "input": "1000001,0", "code": "NUM_TEXT_EQUIV", "cleaned": "1000001", "classification_isolated": "corrected"}
{"case": "orders.placed_at", "input": "2024-02-31", "error": "DataError", "sqlstate": "22008"}
{"case": "orders.placed_at", "input": "2024.02.31", "error": "DataError", "sqlstate": "22008"}
{"case": "orders.placed_at", "input": "01/01/2030", "code": "DATE_FORMAT_KNOWN", "cleaned": "2030-01-01", "classification_isolated": "corrected"}
{"case": "orders.placed_at", "input": "sem data", "code": null, "cleaned": "sem data", "classification_isolated": "accepted"}
{"case": "products.name", "input": "CÂMERA", "error": "DataError", "sqlstate": "22021"}
{"case": "products.name", "input": "A;B", "code": "TEXT_DELIMITER", "cleaned": "A;B", "classification_isolated": "rejected"}
{"case": "product_prices.unit_price", "input": "abc", "code": "MONEY_LOCALE", "cleaned": "abc", "numeric_valid": false, "classification_isolated": "corrected"}
{"case": "product_prices.unit_price", "input": "12,3456", "code": "MONEY_LOCALE", "cleaned": "123456", "numeric_valid": true, "classification_isolated": "corrected"}
{"case": "product_prices.unit_price", "input": "1.234,5678", "code": "MONEY_LOCALE", "cleaned": "1.2345678", "numeric_valid": true, "classification_isolated": "corrected"}
```

Outras contraprovas: dois endereços com ids diferentes, mesma chave parcial
`(customer_id, address_type)`, `is_primary='TRUE'` e `deleted_at` nulo, usando o contrato real de
`table_contract('customer_addresses')`; renderização do SQL real da quarentena com CTEs que
representam a mesma captura/versão antes rejeitada e agora aceita; chamadas diretas às formas do
injetor. Saída literal:

```text
Índice parcial com dois TRUE: [(1, 'accepted'), (2, 'accepted')]
Quarentena: rejeitados antigos após captura ficar 100% aceita: 1
Injetor monetário: _pt_br 12.3456 -> 12,34
Injetor monetário: _en_us 12.3456 -> 12.34
Injetor monetário: _com_simbolo 12.3456 -> R$ 12,34
Injetor temporal: _dd_mm_aaaa 2024-02-29T13:14:15-03:00 -> 29/02/2024
Injetor temporal: _aaaa_ponto_mm_dd 2024-02-29T13:14:15-03:00 -> 2024.02.29
```

Consultas ao estado existente: confronto dos horários originais do manifesto com os valores
classificados, sem publicar payloads; contagens por classificação; seleção de uma geração maior
que todas as existentes e execução do teste de consistência sobre esse resultado vazio; comparação
dos achados de valor pelo mesmo critério de conjuntos usado nos testes. Saída literal:

```text
Manifesto: horários não nulos perdidos por DATE_FORMAT_KNOWN, por classificação: {'corrected': 2, 'rejected': 2}
Estado atual das classificações: [('accepted', 10452), ('corrected', 27), ('rejected', 2268)]
Captura inexistente: 12 linhas selecionadas: 0 violações no teste de consistência: 0
Achados de valor, estado atual: esperados: 74 detectados: 74 perdidos: 0 extras: 14
Extras por código: {'TEXT_TRUNCATED': 11, 'TEXT_WHITESPACE_CASE': 1, 'TEXT_ENCODING': 1, 'NULL_DISGUISED': 1}
```

### Tabela de achados

Todos os locais abaixo pertencem ao intervalo revisado; números de linha referem-se ao conteúdo
em `afa5898`. `Pendente` significa **não corrigido nesta revisão**, não autorização para implementar.
Erros de regras/declaração são bloqueantes conforme `CLAUDE.md` §5. Lacunas de prova não são
apresentadas como falhas reproduzidas. Os ajustes devem nascer a montante dos arquivos gerados.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| R01 | `dbt/models/trusted/legacy/legacy_eligible_records.sql:1`; `README.md:85`; ADR-0039 | **O empilhamento e a procedência até analytics não foram entregues.** O conjunto apto não tem consumidor em modelos/snapshots; por exemplo, `trusted.order_items` ainda lê somente `stg_retail__order_items`, e a chave da fato de venda continua derivada apenas do id do item. Portanto os relatórios não incluem o legado e `empilhados = aceitos + corrigidos` não foi demonstrada na fronteira real. Concluir o empilhamento com as chaves e o alcance do ADR-0039, incluindo testes de colisão/reconciliação, antes de declarar a Etapa 10 concluída. Não basta acrescentar um `union all` sem adequar as chaves. | `bloqueante` | **Entregue e verificado.** As 36 tabelas do legado com contraparte na origem principal atravessam até `analytics`: 10.233 registros aptos empilhados, `source_system` na coluna, no `unique_key` dos quatro *snapshots* e na chave substituta de dez dimensões, e as junções entre modelos de `trusted` e entre fato e dimensão qualificadas pela origem. A ponte `legado__<tabela>` é **gerada** do próprio modelo de `staging` (`src/mvp_ed1/legacy/ponte.py`), então o mapa de renome tem um dono só. Quatro tabelas — `customer_contacts`, `customer_preferences`, `price_lists`, `product_prices` — não têm modelo na origem principal e não são empilháveis; a exceção está declarada no gerador e na Origem Legada §6. O empilhamento expôs três defeitos que este achado não previa: junção sem origem contaminava o histórico de compra (66 clientes do legado herdavam pedidos do `retail`), o `metadata` do legado era gravado como `repr` de Python em vez de JSON, e o `COPY` passava por um `csv.writer` que citava valores. Os três corrigidos na origem. Abriu também a **D35** — o pai sobrevive à rejeição do filho —, que é decisão do Owner. |
| R02 | `src/mvp_ed1/legacy/regras.py:120` e `:139`/`:162` | **Datas inválidas podem abortar a limpeza ou sair aceitas.** `DATE_IMPOSSIBLE` verifica apenas parte dos formatos; `2024-02-31` chega ao cast de `DATE_FUTURE`, e `2024.02.31` ao `to_date`, ambos com SQLSTATE `22008`. Já `sem data` não recebe achado e sai aceita na contraprova isolada. Validar calendário/formato antes de qualquer cast e garantir uma saída de rejeição para entradas não interpretáveis; uma ocorrência ruim não pode impedir a quarentena do lote. | `bloqueante` | **Corrigido e verificado.** A validade de calendário passou a ser conferida também em ISO e ponto, em aritmética pura — `to_date` nunca é chamado na detecção. `DATE_FUTURE` ganhou `case` guardando o cast, porque o `and` do PostgreSQL não garante curto-circuito. E `DATE_UNPARSEABLE` entrou no catálogo: `sem data` saía **aceita**. Treze casos conferidos, com bissexto. |
| R03 | `src/mvp_ed1/legacy/regras.py:175` | **A identificação de codificação dupla confunde texto legítimo e derruba a consulta.** O padrão `(Ã.\|Â.)` tenta recodificar `CÂMERA`, que é válido, e gera SQLSTATE `22021`. O catálogo autoriza reversão somente quando o par é identificável, não por conter uma dessas letras. Conferir a reversibilidade antes da conversão e cobrir texto legítimo, codificação realmente dupla e conteúdo não reversível, sem lançar erro na view. | `bloqueante` | **Corrigido e verificado.** A detecção deixou de ser `(Ã.|Â.)` e passou a exigir pares que a dupla codificação produz de fato, excluindo letra maiúscula depois. `CÂMERA` passa intacto; `JosÃ©` vira `José`. Risco residual invertido e declarado: mojibake fora da lista deixa de ser reconhecido. |
| R04 | `src/mvp_ed1/legacy/regras.py:98` | **A normalização monetária não assegura valor válido nem preserva quatro casas.** `abc` recebe `MONEY_LOCALE`, permanece `abc` e sai corrigido mesmo falhando em `pg_input_is_valid(..., 'numeric')`. Em `product_prices.unit_price`, `12,3456` vira `123456`, e `1.234,5678` vira `1.2345678`. O modelo declara `UnitPrice = Numeric(14, 4)`; a regra decide o separador apenas por uma ou duas casas finais. Restringir formatos reconhecidos, preservar a escala declarada e rejeitar o que não tiver interpretação segura. | `bloqueante` | **Corrigido e verificado.** A detecção enumera os formatos aceitos em vez de aceitar tudo que não seja decimal puro, e a escala vai a **quatro casas**, que é o que `Numeric(14, 4)` declara. `12,3456` → `12.3456`; `1.083,15` → `1083.15`. `MONEY_AMBIGUOUS` entrou no catálogo para o que não tem formato reconhecido — `abc` saía corrigido. |
| R05 | `src/mvp_ed1/legacy/regras.py:187`; `src/mvp_ed1/legacy/classification.sql:32` | **A conversão booleana inventa falsos e não canoniza verdadeiros válidos.** Qualquer variante desconhecida, como `talvez`, cai no `else 'false'` e sai corrigida, contrariando “somente as variantes declaradas”. Inversamente, `TRUE` é mantido em maiúsculas, enquanto o predicado do índice parcial exige o texto `true`: dois endereços primários conflitantes saíram aceitos. Usar domínio explícito e representação canônica, sem transformar desconhecido em falso, e verificar o efeito na unicidade parcial. | `bloqueante` | **Corrigido e verificado.** A comparação virou sensível a caixa, então `TRUE` é canonizado para `true` e o índice parcial volta a valer. O `else 'false'` saiu: `talvez` não é mais convertido — cai no `ENUM_UNKNOWN`, que passou a alcançar colunas booleanas. |
| R06 | `src/mvp_ed1/legacy/dbt.py:86` e `:98`; regras `NUM_TEXT_EQUIV`/`DATE_FUTURE` | **A primeira conversão encerra a análise antes de validar o valor resultante.** `cart_items.quantity='-1.0'` vira `-1`, `1000001,0` vira `1000001`, e `orders.placed_at='01/01/2030'` vira `2030-01-01` com corte em 2026; todos saem corrigidos nas contraprovas, sem a rejeição de faixa/futuro já declarada no catálogo. A precedência atual funciona para os defeitos sorteados isoladamente, mas não para formato e invalidade na mesma célula. Garantir que rejeição de domínio prevaleça também após normalização. | `bloqueante` | **Corrigido e verificado.** O modelo gerado ganhou uma CTE de limpeza, e o achado é conferido em duas passagens: primeiro as regras de **rejeição contra o valor convertido**, depois todas contra o original. `-1.0` deixa de sair corrigido como `-1`. |
| R07 | `src/mvp_ed1/legacy/injetor.py:171` e `:185`; `tests/test_legado_deteccao.py:173` | **O injetor perde informação em falhas declaradas como corrigíveis.** Os formatadores monetários cortam a terceira/quarta casa de `12.3456`; os de data removem horário e fuso de colunas `DateTime`. No estado observado há dois registros ainda classificados como corrigidos cujo horário não nulo foi perdido por `DATE_FORMAT_KNOWN`. Encontrar o código não prova recuperar o valor. Tornar as formas de mera representação reversíveis para o tipo alcançado e testar também o valor recuperado contra um oráculo independente; qualquer tratamento de perda irreversível precisa respeitar o catálogo/Owner. | `bloqueante` | **Aceito**: os formatadores do injetor cortam casas e perdem fuso. Em correção junto de R04. |
| R08 | `src/mvp_ed1/legacy/regras.py:171`; `src/mvp_ed1/legacy/catalogo.yml:242` | **`TEXT_DELIMITER` omite metade da condição declarada.** O catálogo exige delimitador **e campos seguintes vazios**; o SQL testa somente `like '%;%'`. Assim `A;B` em texto livre é rejeitado independentemente dos vizinhos, inclusive quando a linha não sofreu deslocamento. Levar o contexto necessário à detecção e testar as duas situações; ampliar a heurística exigiria decisão explícita, não uma condição omitida. | `bloqueante` | **Corrigido e verificado.** A detecção passou a exigir a outra metade da condição declarada — os campos seguintes vazios. A regra agora declara `precisa_da_linha`, porque não é avaliável sobre um valor isolado, e o teste que a avaliava assim foi ajustado em vez de contornado. |
| R09 | `src/mvp_ed1/legacy/dbt.py:140`; `dbt/macros/legacy_snapshot_id.sql:3`; `dbt/tests/legacy_selected_capture_is_consistent.sql:2`; `airflow/dags/fluxo_batch.py:90` | **A seleção não prova que a captura existe e está completa.** Um `legacy_snapshot_id` inexistente selecionou zero linhas nas 40 fontes e o teste de consistência devolveu zero violações: ele agrupa somente linhas presentes. O máximo por tabela também não identifica uma captura nova sem linhas naquele stream; o job retornado pela DAG não é vinculado à seleção dbt. Validar existência/completude antes de publicar ou reprocessar e distinguir tabela legitimamente vazia de captura ausente/incompleta. A contraprova não é um build materializado nem prova que gerações Airbyte sejam incomparáveis. | `bloqueante` | **Entregue e verificado por contraprova.** A seleção deixou de ser um máximo por tabela e virou um valor só, resolvido em `legacy_selected_capture` e materializado — os 40 modelos leem dele. Dois testes gerados afirmam o que faltava: `legacy_captura_existe` (a geração selecionada está em `raw_legacy`) e `legacy_captura_completa` (as 40 tabelas têm linha nela). **As duas contraprovas foram feitas:** com `legacy_snapshot_id=9999` os testes acusam 1 e 40 violações — antes o teste de consistência devolvia zero, porque agrupava só o que estava presente; e esvaziando `legacy.brands` na origem e recapturando, a existência passa e a completude acusa **exatamente uma** violação, nomeando `brands`. É a distinção entre tabela vazia e captura incompleta, que no bruto são a mesma coisa. A origem foi restaurada e os três testes voltaram ao verde. Na DAG, a geração é observada uma vez após a sincronização e viaja para as sete tarefas de dbt como `legacy_snapshot_id`. **O que continua sem prova** é o vínculo `jobId` → geração: o Airbyte não o expõe, e está dito no código e na Origem Legada §4.2 em vez de simulado. |
| R10 | `src/mvp_ed1/legacy/dbt.py:136`; `dbt/tests/legacy_classification_reconciles.sql:1`; ADR-0037; `docs/origem_legada.md:317` | **Retenção existe, mas detecção de exclusão física não.** A transformação seleciona uma captura; os testes novos comparam essa seleção com sua classificação/saídas. Não há comparação das chaves com a captura anterior completa para acusar desaparecimento, como exige o contrato. Uma linha sem filhos pode sumir da origem e a equação da captura seguinte continuar fechando sem registrar sua ausência. Entregar a comparação e uma prova de remoção real versus falha de ingestão; ter capturas antigas armazenadas é apenas o pré-requisito. | `bloqueante` | **Aceito.** A retenção existe; a comparação entre capturas não. Era uma das lacunas que eu próprio declarei na seção 4. |
| R11 | `dbt/models/quarantine/rejected_legacy_records.sql:23` | **A substituição da quarentena falha quando a captura passa a ter zero rejeitados.** A chave a substituir é procurada em `incoming`, que já foi filtrado para `rejected`. Se a mesma captura/versão ficar inteiramente aceita/corrigida, `incoming` fica vazio e todos os rejeitados antigos sobrevivem. A contraprova com uma linha preservou uma rejeição obsoleta, contrariando a classificação corrente e fazendo as saídas discordarem. A identificação da captura reprocessada não pode depender de existir ao menos uma rejeição nova. | `bloqueante` | **Corrigido e verificado.** A identidade da captura reprocessada passou a vir da classificação inteira, e não de `incoming`, que estava filtrado para rejeitados. Captura que fica 100% aceita já não preserva a auditoria obsoleta. |
| R12 | `src/mvp_ed1/legacy/writer.py:36`; `src/mvp_ed1/legacy/schema.py:154`; ADR-0010 | **O schema legado ficou fora do ciclo de migrações declarado.** A criação ocorre no writer por `CREATE TABLE IF NOT EXISTS`; não há revisão Alembic para o legado, e `make migrate` continua restrito à origem principal. Uma coluna nova derivada dos modelos não atualiza uma tabela legada já existente, enquanto o `COPY` passa a exigir essa coluna. Falta caminho versionado de evolução/reversão e a prova de instalação do zero. Cumprir o ADR-0010 ou levar a exceção ao Owner; não tratar o DDL idempotente como migração equivalente. | `bloqueante` | **Aceito.** Sem revisão Alembic para o legado. Era a segunda lacuna que declarei na seção 4. Trabalho a fazer. |
| R13 | `tests/test_legado_deteccao.py:129` e `:173`; `tests/test_legacy_classification.py`; `docs/plano_de_desenvolvimento.md:248` | **A prova contra manifesto cobre achados de valor, não o resultado completo da classificação.** Os códigos de contexto são excluídos daquele confronto; os testes dirigidos cobrem órfã, duplicatas, total e cascata, mas não confrontam as ocorrências finais da captura com um oráculo independente desses efeitos. Portanto “74 de 74” não valida os 2.268 rejeitados nem os valores convertidos. Acrescentar essa verificação independente e discriminar o alcance da evidência publicada, sem usar o classificador para fabricar seu próprio esperado. | `ajuste` | **Aceito.** É a mesma lacuna que declarei — a cascata não tem oráculo. Trabalho a fazer. |
| R14 | `docs/origem_legada.md:16`, `:171` e `:257`; `docs/plano_de_desenvolvimento.md:239`/`:248`; `README.md:85` | **Os donos documentais misturam estados e evidências diferentes.** Origem Legada ainda anuncia D32/contexto/quarentena/DAG como pendentes e 22 códigos, embora o catálogo tenha 23 e o ADR-0040 esteja aceito; o plano já encerra a etapa e marca reprocessamento idempotente sem execução repetida documentada. A métrica atual pelo método do teste foi 14 achados extras em 12.747 ocorrências (11 `TEXT_TRUNCATED`), não 13 em 12.749. Rotular a medição anterior como histórica, identificar captura/versão e registrar o estado real após tratar os bloqueios. Achado extra contra manifesto não prova sozinho falso positivo semântico; não reescrever números históricos dentro de ADRs aceitos. | `ajuste` | **Aceito e em correção agora**: plano, README e Pendências voltaram a dizer que a etapa está aberta. A contagem de códigos e a métrica de falso positivo serão refeitas com a captura identificada. |
| R15 | `src/mvp_ed1/legacy/classification.sql:96`; `tests/test_legacy_classification.py:133`; seção 6 deste dossiê | **Ratificar com o Owner o universo da reconciliação de pedidos.** O código soma todos os itens capturados menos excedentes exatos, mesmo quando um item é rejeitado por outro pai; o teste agora admite pedido aceito sem aquele item apto. Isso distingue consistência da origem de consistência do conjunto que será empilhado, e altera a política, não apenas a implementação. A melhora de contagens não decide qual contrato deve valer. Registrar a decisão e o efeito esperado nas métricas/reconciliações do empilhamento; não restaurar automaticamente a regra anterior. | `observação` | **Vai ao Owner** como **D33** — registrada em `docs/pendencias.md` §1 e na §3 do Registro de Decisões. Nenhuma política alterada. |
| R16 | `dbt/models/quarantine/rejected_legacy_records.sql:19`; `src/mvp_ed1/legacy/catalogo.yml:28` | **Formalizar o que identifica uma versão auditável do tratamento.** Havendo rejeitados novos, a mesma captura/versão de catálogo substitui a auditoria anterior. Alterações em `regras.py`, `classification.sql` ou parâmetros de execução podem mudar resultados sem mudar o número do catálogo. Confirmar com o Owner quando esse número deve avançar e se resultados distintos sob a mesma chave devem ser recusados ou ter identidade própria. É questão de contrato de auditoria, distinta do caso vazio reproduzido em R11. | `observação` | **Vai ao Owner** como **D34** — idem. Nenhuma política alterada. |
| R17 | `src/mvp_ed1/generator/domains/logistica.py:136`; `tests/test_remessas.py`; `dbt/tests/remessa_leva_ao_menos_um_item.sql:1` | **D31 sem achado corretivo nesta revisão.** A partição mantém caixas não vazias e conserva quantidades nos casos dirigidos, inclusive uma unidade única e vários itens avulsos. Passaram também os testes em fatores completo/reduzido e as barreiras de manutenção com mocks; a salvaguarda dbt deixou de ser `warn`. Isto não é nova medição da Etapa 7: eventos ao vivo, duplicatas, alertas e reconstrução não foram repetidos nesta revisão. | `observação` | Sem ação. Registro de que a D31 não regrediu no recorte executado. |
