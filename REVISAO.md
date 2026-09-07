# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `afa5898..38a6ec1` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
eceaa2c docs: cria a skill de passagem entre agentes
f3b2ac5 docs: acrescenta o guia de operação da skill de revisão
8a62049 docs: separa papel de agente do arquivo que está na raiz
bcb5865 fix: fixa o intervalo do dossiê em SHA, não em HEAD
da06142 docs: amplia o dossiê para a Etapa 10 inteira, desde a Etapa 9
250e6e5 docs: reabre a Etapa 10 depois da revisão
ea2f308 fix: conserta sete achados da revisão nas regras de limpeza
a1de7f9 feat: empilha o legado em trusted, com a origem na chave
7603796 feat: empilha as 36 tabelas do legado e leva a origem até analytics
fdc2c6a feat: prova que a captura do legado existe e está completa
38a6ec1 feat: fecha D33, D34 e D35 do Owner
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 93 arquivos

- `.claude/skills/revisao/SKILL.md`
- `.claude/skills/revisao/comandos.txt`
- `.claude/skills/revisao/como_usar_skill_revisao.md`
- `.claude/skills/revisao/dossie.py`
- `AGENTS.md`
- `README.md`
- `airflow/dags/fluxo_batch.py`
- `dbt/macros/empilhado.sql`
- `dbt/macros/explicado_pela_quarentena.sql`
- `dbt/models/analytics/_analytics__models.yml`
- `dbt/models/analytics/dim_brand.sql`
- `dbt/models/analytics/dim_campaign.sql`
- `dbt/models/analytics/dim_carrier.sql`
- `dbt/models/analytics/dim_category.sql`
- `dbt/models/analytics/dim_coupon.sql`
- `dbt/models/analytics/dim_customer.sql`
- `dbt/models/analytics/dim_payment_method.sql`
- `dbt/models/analytics/dim_product.sql`
- `dbt/models/analytics/dim_sales_channel.sql`
- `dbt/models/analytics/dim_supplier.sql`
- `dbt/models/analytics/dim_support_agent.sql`
- `dbt/models/analytics/dim_warehouse.sql`
- `dbt/models/analytics/fact_cart_event.sql`
- `dbt/models/analytics/fact_coupon_redemption.sql`
- `dbt/models/analytics/fact_inventory_movement.sql`
- `dbt/models/analytics/fact_order_status_event.sql`
- `dbt/models/analytics/fact_payment_transaction.sql`
- `dbt/models/analytics/fact_purchase_order_item.sql`
- `dbt/models/analytics/fact_refund.sql`
- `dbt/models/analytics/fact_sales_order_item.sql`
- `dbt/models/analytics/fact_shipment_item.sql`
- `dbt/models/analytics/fact_support_ticket_event.sql`
- `dbt/models/quarantine/rejected_legacy_records.sql`
- `dbt/models/trusted/campaigns.sql`
- `dbt/models/trusted/carriers.sql`
- `dbt/models/trusted/cart_lifecycle_events.sql`
- `dbt/models/trusted/carts.sql`
- `dbt/models/trusted/coupon_redemptions.sql`
- `dbt/models/trusted/coupons.sql`
- `dbt/models/trusted/customers.sql`
- `dbt/models/trusted/delivery_events.sql`
- `dbt/models/trusted/geographies.sql`
- `dbt/models/trusted/inventory_balances.sql`
- `dbt/models/trusted/inventory_movements.sql`
- `dbt/models/trusted/legacy/_medidas__models.yml`
- `dbt/models/trusted/legacy/legacy_order_totals_divergence.sql`
- `dbt/models/trusted/order_items.sql`
- `dbt/models/trusted/order_status_events.sql`
- `dbt/models/trusted/orders.sql`
- `dbt/models/trusted/payment_methods.sql`
- `dbt/models/trusted/payment_transactions.sql`
- `dbt/models/trusted/payments.sql`
- `dbt/models/trusted/product_skus.sql`
- `dbt/models/trusted/purchase_order_items.sql`
- `dbt/models/trusted/purchase_orders.sql`
- `dbt/models/trusted/refunds.sql`
- `dbt/models/trusted/sales_channels.sql`
- `dbt/models/trusted/shipment_items.sql`
- `dbt/models/trusted/shipments.sql`
- `dbt/models/trusted/suppliers.sql`
- `dbt/models/trusted/support_agents.sql`
- `dbt/models/trusted/support_tickets.sql`
- `dbt/models/trusted/ticket_events.sql`
- `dbt/models/trusted/warehouses.sql`
- `dbt/snapshots/scd_coupon.sql`
- `dbt/snapshots/scd_customer.sql`
- `dbt/snapshots/scd_product.sql`
- `dbt/snapshots/scd_support_agent.sql`
- `dbt/tests/invariante_02_total_do_pedido_reconcilia.sql`
- `dbt/tests/invariante_05_remessa_nao_excede_o_vendido.sql`
- `dbt/tests/invariante_08_reserva_encerrada_nao_ocupa_saldo.sql`
- `dbt/tests/invariante_10_causalidade_das_datas.sql`
- `dbt/tests/legacy_outputs_reconcile.sql`
- `dbt/tests/legacy_versao_do_tratamento_e_univoca.sql`
- `dbt/tests/legado_nao_colide_com_a_origem_principal.sql`
- `dbt/tests/remessa_leva_ao_menos_um_item.sql`
- `dbt/tests/saldo_reconstruido_confere_com_a_projecao.sql`
- `docs/adr/README.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/qualidade_de_dados.md`
- `src/mvp_ed1/legacy/catalogo.yml`
- `src/mvp_ed1/legacy/classification.py`
- `src/mvp_ed1/legacy/classification.sql`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/injetor.py`
- `src/mvp_ed1/legacy/ponte.py`
- `src/mvp_ed1/legacy/regras.py`
- `src/mvp_ed1/legacy/writer.py`
- `tests/test_legacy_models.py`
- `tests/test_legado_deteccao.py`

### Gerados — 86 arquivos, revisar por amostragem

- `REVISAO.md`
- `dbt/models/quarantine/_legacy__models.yml`
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
- `dbt/models/trusted/legacy/_pontes__models.yml`
- `dbt/models/trusted/legacy/legacy_classifications.sql`
- `dbt/models/trusted/legacy/legado__brands.sql`
- `dbt/models/trusted/legacy/legado__campaigns.sql`
- `dbt/models/trusted/legacy/legado__carriers.sql`
- `dbt/models/trusted/legacy/legado__cart_items.sql`
- `dbt/models/trusted/legacy/legado__carts.sql`
- `dbt/models/trusted/legacy/legado__coupon_redemptions.sql`
- `dbt/models/trusted/legacy/legado__coupons.sql`
- `dbt/models/trusted/legacy/legado__customer_addresses.sql`
- `dbt/models/trusted/legacy/legado__customer_segments.sql`
- `dbt/models/trusted/legacy/legado__customers.sql`
- `dbt/models/trusted/legacy/legado__delivery_events.sql`
- `dbt/models/trusted/legacy/legado__goods_receipt_items.sql`
- `dbt/models/trusted/legacy/legado__goods_receipts.sql`
- `dbt/models/trusted/legacy/legado__inventory_balances.sql`
- `dbt/models/trusted/legacy/legado__inventory_movements.sql`
- `dbt/models/trusted/legacy/legado__order_items.sql`
- `dbt/models/trusted/legacy/legado__order_status_history.sql`
- `dbt/models/trusted/legacy/legado__orders.sql`
- `dbt/models/trusted/legacy/legado__payment_methods.sql`
- `dbt/models/trusted/legacy/legado__payment_transactions.sql`
- `dbt/models/trusted/legacy/legado__payments.sql`
- `dbt/models/trusted/legacy/legado__product_categories.sql`
- `dbt/models/trusted/legacy/legado__product_variants.sql`
- `dbt/models/trusted/legacy/legado__products.sql`
- `dbt/models/trusted/legacy/legado__purchase_order_items.sql`
- `dbt/models/trusted/legacy/legado__purchase_orders.sql`
- `dbt/models/trusted/legacy/legado__refunds.sql`
- `dbt/models/trusted/legacy/legado__sales_channels.sql`
- `dbt/models/trusted/legacy/legado__shipment_items.sql`
- `dbt/models/trusted/legacy/legado__shipments.sql`
- `dbt/models/trusted/legacy/legado__stock_reservations.sql`
- `dbt/models/trusted/legacy/legado__suppliers.sql`
- `dbt/models/trusted/legacy/legado__support_agents.sql`
- `dbt/models/trusted/legacy/legado__support_tickets.sql`
- `dbt/models/trusted/legacy/legado__ticket_events.sql`
- `dbt/models/trusted/legacy/legado__warehouses.sql`
- `dbt/tests/legacy_captura_completa.sql`
- `dbt/tests/legacy_captura_existe.sql`
- `dbt/tests/legado_empilhado_reconcilia.sql`
- `dbt/tests/legado_ponte_preserva_o_conjunto_apto.sql`

**Declaração desta entrega**, que pede revisão integral (§5 do `CLAUDE.md`):

| Arquivo | O que declara |
|---|---|
| `src/mvp_ed1/legacy/ponte.py` | **Novo.** Como o legado vira a forma da origem principal; as listas `SEM_CONTRAPARTE`, `CONDUTORAS`, `ENRIQUECIMENTO`, `FORA_DA_ORIGEM` e o mapa de tipos |
| `src/mvp_ed1/legacy/dbt.py` | A seleção da captura e a impressão digital do tratamento |
| `src/mvp_ed1/legacy/catalogo.yml` | `versao: 4` e o critério de quando ela avança |
| `src/mvp_ed1/legacy/classification.py` e `.sql` | A coluna `treatment_fingerprint` e a chave da quarentena |
| `src/mvp_ed1/legacy/injetor.py`, `writer.py` | Serialização JSON e o `COPY` em formato texto |
| `dbt/macros/empilhado.sql`, `explicado_pela_quarentena.sql` | **Novos.** O contrato do empilhamento e o da exceção tolerada |
| `dbt/models/trusted/*.sql` (29) e `analytics/*.sql` (22) | Onde a origem entra na chave e na junção — escritos à mão |
| `dbt/models/quarantine/rejected_legacy_records.sql` | A retenção que recusa substituir |
| `dbt/models/trusted/legacy/legacy_order_totals_divergence.sql` | **Novo.** A medida do D33 |
| `airflow/dags/fluxo_batch.py` | A tarefa que fixa a captura para as sete tarefas de dbt |

**Derivado**, revisável por amostragem: os 40 `stg_legacy__*.sql`, as 36 pontes
`legado__*.sql`, `legacy_selected_capture.sql`, `legacy_records.sql`,
`legacy_classifications.sql`, os quatro testes gerados e os `_*__models.yml`. Erro neles é
sintoma — o conserto é no gerador.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
..s..................................................................... [ 55%]
..........................................................               [100%]
129 passed, 1 skipped in 237.27s (0:03:57)
```

### `make dbt-build` ✓

```
19:26:09  862 of 863 START sql view model consumption.payment_approval_rate_by_method .... [RUN]
19:26:09  863 of 863 START sql view model consumption.refund_rate_by_reason .............. [RUN]
19:26:10  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['approval_rate_pct', 'authorized_amount', 'captured_amount']`
19:26:10  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['refunded_amount', 'captured_amount', 'refund_rate_pct']`
19:26:10  862 of 863 OK created sql view model consumption.payment_approval_rate_by_method  [CREATE VIEW in 0.35s]
19:26:10  863 of 863 OK created sql view model consumption.refund_rate_by_reason ......... [CREATE VIEW in 0.36s]
19:26:10
19:26:10  Finished running 1 incremental model, 3 seeds, 4 snapshots, 96 table models, 667 data tests, 92 view models in 0 hours 15 minutes and 37.77 seconds (937.77s).
19:26:12
19:26:12  Completed successfully
19:26:12
19:26:12  Done. PASS=863 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=863
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

1. **A DAG não foi executada.** A tarefa `geracao_do_legado` e o `--vars` nas sete tarefas
   de dbt foram escritos e **nunca rodaram**: derrubei o Airflow no meio da sessão para
   liberar memória e não o subi de volta. O que se conferiu foi que o módulo faz *parse*.
   O `xcom_pull` no `bash_command`, o `task_id` referenciado e o acesso ao armazém de
   dentro do contêiner são todos não verificados.
2. **O vínculo `jobId` ↔ `_airbyte_generation_id` não existe.** Está dito no código e na
   Origem Legada §4.2. Os dois testes cobrem existência e completude da captura, não a
   autoria dela: uma sincronização que falhe silenciosamente e deixe a captura anterior
   intacta passa nos dois.
3. **A causa da lentidão não foi isolada.** `fact_payment_transaction` leva 595 s e
   `fact_sales_order_item` 186 s, contra menos de 3,3 s das outras oito fatos. O número
   está medido; a causa, não. E **não há medição anterior ao empilhamento**, então não
   afirmo que seja regressão.
4. **O D34 tem meia prova experimental.** A recusa de substituição está *observada* em
   dado real — a versão 3 guarda duas impressões lado a lado —, mas isso aconteceu por
   acidente durante a minha iteração, não num experimento controlado. O ciclo completo
   (mudar o tratamento sem avançar a versão, ver falhar, reverter) **não foi feito**: o
   teste foi provado contra a quarentena real com uma impressão simulada em consulta
   avulsa. Não fiz o ciclo porque ele deixaria resíduo permanente sob a versão 4.
5. **A medida do D33 olha só um elo.** `legacy_order_totals_divergence` cruza pedido com
   itens em quarentena. Não verifiquei o caso em que o **cliente** do pedido foi rejeitado
   e o pedido sobreviveu — a cadeia mais longa não é coberta pela medida nem por teste.
6. **A comparação da macro `explicado_pela_quarentena` é textual.** Ela casa
   `original_payload->>'fk'` com `pai.fk::text`. Não verifiquei o comportamento quando o
   valor bruto traz espaço à volta, zero à esquerda ou outra formatação — casos que o
   catálogo injeta de propósito noutras colunas. Se não casar, a diferença deixa de ser
   tolerada e o teste falha (falha segura), mas não medi se acontece.
7. **Nenhuma migração Alembic acompanha a coluna nova.** `treatment_fingerprint` vive em
   modelo dbt, não no schema legado, então o R12 continua aberto e nada aqui o mexeu.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **A máquina esteve sob pressão de memória durante todas as medições** — 9,2 GB de
  11,7 GB em uso, com o Airbyte segurando cerca de 3,6 GB em JVMs e o Airflow parado.
  Todos os tempos da seção 3 refletem esse estado, e o `dbt build` inteiro levou 15 min 38 s.
- **O estado do banco não é o de uma instalação do zero.** `raw_legacy` tem 17 gerações
  retidas, e **uma delas tem `brands` vazia** de propósito: é o resíduo da contraprova do
  R09. Quem subir o ambiente limpo não reproduz esse estado, e os números de retenção da
  quarentena serão outros.
- **A quarentena carrega quatro combinações de versão e impressão**, duas delas anteriores
  ao contrato do D34 e marcadas `anterior-a-D34`. Isso é migração, não dado de negócio.
- **`data/legacy/manifesto.json` não é versionado** (`.gitignore` cobre `data/`). O oráculo
  dos testes de detecção existe só nesta máquina, e quem clonar o repositório precisa
  rodar `make seed-legacy` antes de `make test`.
- **Postgres 16 numa instância só, sem escrita concorrente durante o build.** A
  materialização de `legacy_selected_capture` como tabela assume isso: se duas execuções
  do dbt correrem em paralelo, elas disputam a mesma relação.
- **O Airbyte estava de pé e respondendo** durante os `seed-legacy` e `sync-legacy`. A
  recuperação documentada em `execucao_local.md` §6 não foi reexercitada nesta entrega.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

1. **`event_sequence` do legado recebe `legacy_row_id`** (`ponte.py`). Na origem principal
   é ordenação que o banco atribui; no legado não existe equivalente. Escolhi a identidade
   da ocorrência física por ser o mais próximo de uma ordem local — mas **é uma
   equivalência que eu inventei**, e é o ponto desta entrega em que mais me aproximei de
   inventar dado. A alternativa era não expor a coluna e quebrar o formato do `union all`.
2. **O universo do `legacy_versao_do_tratamento_e_univoca`.** Escrevi primeiro cobrindo
   todas as versões, e ele ficou permanentemente vermelho: uma mistura histórica que o
   remédio prescrito (avançar a versão) não limpa. Reescrevi para comparar só a versão
   corrente. Acho que é a leitura certa, mas ela **abre mão** de acusar mistura antiga, e
   alguém pode achar que isso é o buraco voltando por outra porta.
3. **`legacy_order_totals_divergence` mora em `trusted/legacy/`** apesar de medir as duas
   origens. Escolhi proximidade ao motivo em vez de pureza de camada; o argumento
   contrário é que um modelo que fala do `retail` não deveria estar num diretório do legado.
4. **O marcador `'anterior-a-D34'`** na retenção da quarentena. Preferi um valor que se lê
   a um nulo mudo, mas ele é um valor mágico que nenhum domínio declara e que vai
   sobreviver a esta migração para sempre.
5. **Avançar `catalog_version` de 3 para 4.** Foi o remédio que o próprio teste prescreve,
   mas fui eu quem decidiu que "coluna nova na saída da classificação" conta como mudança
   de tratamento. Se a régua for "mudou o veredito de algum registro", não contaria: os
   2.280 rejeitados são os mesmos.
6. **`geographies` conforma sem `source_system`** enquanto `warehouses` recebe. As duas
   são geografia; a diferença é que armazém tem identidade própria por sistema e cidade
   não. Está no ADR-0039, mas a linha é fina.
7. **Deixei a lentidão sem investigar.** Podia ter aberto o plano de execução das duas
   fatos. Preferi registrar o número e seguir, para não trocar uma entrega fechada por uma
   caçada de desempenho — mas isso significa que ninguém sabe se o empilhamento a causou.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

