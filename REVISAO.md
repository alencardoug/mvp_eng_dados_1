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

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

