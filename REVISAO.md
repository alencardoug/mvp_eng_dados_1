# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se o
> pedido foi implementar, implemente — este arquivo continua aqui esperando quem for revisar.

## 1. Escopo

Intervalo: `3f1316b..afa5898` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.
Os *commits* posteriores a `afa5898` são da ferramenta de revisão, e não fazem parte
desta entrega.

```
d0ccdfb feat: classifica, quarentena e empilha o legado
01dc447 fix: tira os domínios fechados do sorteio de injeção
afa5898 feat: orquestra a captura do legado e fecha a Etapa 10
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 29 arquivos

- `AGENTS.md`
- `README.md`
- `airflow/dags/fluxo_batch.py`
- `dbt/macros/legacy_snapshot_id.sql`
- `dbt/models/quarantine/rejected_legacy_records.sql`
- `dbt/models/trusted/legacy/legacy_eligible_records.sql`
- `dbt/tests/legacy_classification_reconciles.sql`
- `dbt/tests/legacy_eligible_has_valid_parents.sql`
- `dbt/tests/legacy_outputs_reconcile.sql`
- `dbt/tests/legacy_selected_capture_is_consistent.sql`
- `docs/adr/0040-rejeitar-nulo-em-campo-obrigatorio.md`
- `docs/adr/README.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/qualidade_de_dados.md`
- `encaminhamentos/README.md`
- `encaminhamentos/etapa-10-origem-legada.md`
- `src/mvp_ed1/legacy/catalogo.py`
- `src/mvp_ed1/legacy/catalogo.yml`
- `src/mvp_ed1/legacy/classification.py`
- `src/mvp_ed1/legacy/classification.sql`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/injetor.py`
- `tests/test_legacy_classification.py`
- `tests/test_legacy_models.py`
- `tests/test_legado_deteccao.py`

### Gerados — 45 arquivos, revisar por amostragem

- `dbt/models/quarantine/_legacy__models.yml`
- `dbt/models/staging/legacy/_legacy__models.yml`
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

**Declaração desta entrega**, em ordem de importância:

1. `src/mvp_ed1/legacy/catalogo.yml` — as 22 falhas, e as quatro listas de exceção que dizem
   **onde** cada uma se aplica. Os 45 modelos gerados nascem daqui. `make legacy-catalogo`
   imprime em português, sem abrir o YAML.
2. `src/mvp_ed1/legacy/classification.sql` — a classificação nas três saídas e a cascata. É o
   arquivo onde estavam os dois defeitos consertados nesta entrega.
3. `airbyte/streams.yml` — o que se lê de cada origem e em que modo.
4. `airflow/dags/fluxo_batch.py` — a ordem de execução.

Os 40 `stg_legacy__*.sql` e o `legacy_classifications.sql` são **derivados**: saem de
`legacy/dbt.py` e `legacy/classification.py` via `make legacy-models`. Amostre dois ou três; se
houver erro neles, o conserto é a montante.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
..s..................................................................... [ 55%]
.........................................................                [100%]
128 passed, 1 skipped in 34.48s
```

### `make dbt-build` ✓

```
19:31:15  810 of 812 PASS not_null_rejected_legacy_records_snapshot_id ................... [PASS in 0.25s]
19:31:15  812 of 812 START test not_null_rejected_legacy_records_source_table ............ [RUN]
19:31:15  811 of 812 PASS not_null_rejected_legacy_records_source_system ................. [PASS in 0.33s]
19:31:15  812 of 812 PASS not_null_rejected_legacy_records_source_table .................. [PASS in 0.20s]
19:31:15  805 of 812 PASS legacy_outputs_reconcile ....................................... [PASS in 0.91s]
19:31:24  793 of 812 PASS legacy_eligible_has_valid_parents .............................. [PASS in 9.96s]
19:31:24
19:31:24  Finished running 1 incremental model, 3 seeds, 4 snapshots, 58 table models, 654 data tests, 92 view models in 0 hours 1 minutes and 11.70 seconds (71.70s).
19:31:25
19:31:25  Completed successfully
19:31:25
19:31:25  Done. PASS=812 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=812
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **A cascata nunca foi testada contra um oráculo.** Os defeitos de **valor** têm o manifesto
  dizendo 74 de 74; a cascata não tem equivalente. Sei que 2.268 registros foram rejeitados e que
  a equação fecha, mas **não** sei se são os 2.268 certos. É a maior lacuna desta entrega, e é
  exatamente onde os dois defeitos apareceram.
- **`legacy_eligible_records` não é lido por ninguém.** O empilhamento em `trusted` — os aptos do
  legado se juntando aos da origem principal em `customers`, `orders` e o resto — **não foi
  feito**. A tabela existe e é testada isoladamente; a fase E do plano está pela metade, e nenhum
  modelo dimensional enxerga o legado.
- **Reprocessar a mesma captura não foi exercitado nesta entrega.** O critério "reprocessar o
  mesmo `snapshot_id` não duplica" está marcado com ✓ no plano com base no teste que existe, não
  numa execução repetida que eu tenha feito e medido.
- **A exclusão física entre duas capturas não foi demonstrada.** Há 11 capturas retidas, mas não
  removi um registro da origem para provar que a comparação o detecta.
- **A migração do schema legado do zero não foi testada.** `legacy.*` foi criado por
  `create table if not exists` no writer, e não por Alembic. O plano do Codex previa migrações
  dirigidas ao banco legado, e isso não existe — `make migrate` não conhece o legado.
- **O tempo da DAG (5 min 20 s) é de uma execução só**, sem repetição.
- **`make dbt-build` roda sobre o estado atual do banco**, não do zero. Um `--full-refresh` a
  partir de banco vazio não foi feito nesta entrega.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **Que os `_airbyte_generation_id` são monotônicos e comparáveis entre tabelas.** A seleção da
  captura corrente usa `max(_airbyte_generation_id)` **por tabela**. Se o Airbyte numerar por
  stream em vez de por conexão, duas tabelas da mesma captura podem cair em gerações diferentes e
  a classificação misturaria capturas. Não confirmei o contrato dessa coluna na documentação do
  Airbyte.
- **Que `pg_input_is_valid` cobre os casos que `::numeric` recusaria.** É usado para decidir se um
  valor é convertível antes de castar, e a equivalência entre os dois foi assumida.
- **Que a retenção da quarentena por `(snapshot_id, catalog_version)` é a chave certa.** Consertei
  para isso hoje, e a escolha é minha: se duas execuções da mesma captura com o mesmo catálogo
  divergirem, a segunda apaga a auditoria da primeira sem aviso.
- **Que remover o `base_rejected` não deixou consumidor órfão.** Conferi por `grep` no arquivo,
  não por análise do plano de execução.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Inverti um teste do Codex em vez de perguntar.** O
  `test_rejected_product_makes_remaining_order_total_fail` afirmava que um produto rejeitado faz o
  total do pedido falhar. Concluí que ele prendia a circularidade e o inverti. É defensável — 175
  de 177 pedidos reconciliam contra todos os itens capturados —, mas eu **mudei a afirmação de
  outro agente sobre o que o sistema deve fazer**, e isso podia ter voltado ao Owner.
- **Escolhi quatro tabelas como "domínio fechado" sem critério medido.** `sales_channels`,
  `payment_methods`, `customer_segments` e `carriers`. O critério que declarei é conceitual —
  guardam valores, não coisas —, mas `warehouses` tem 5 linhas e um *fan-in* enorme, e ficou de
  fora. A lista pode estar errada nas bordas.
- **Removi o diretório `encaminhamentos/` inteiro.** O índice mandava preservar o que continuasse
  encaminhado; como não sobrou nada, apaguei tudo. A alternativa era manter o índice vazio como
  marca da convenção.
- **Deixei a quarentena acumular 11 capturas sem política de descarte.** O ADR-0037 adiou essa
  decisão de propósito, mas `raw_legacy` e a quarentena crescem a cada execução da DAG, e ninguém
  está medindo o crescimento.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

