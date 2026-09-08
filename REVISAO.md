# Revisão da entrega

> **Parecer mais recente:** [reavaliação do estado atual em 08/09/2026](#reavaliação-do-estado-atual--08092026).
> O intervalo e os achados anteriores abaixo são históricos; a reavaliação inclui as correções posteriores e as alterações sem commit.

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

Revisão por Codex em **07/09/2026**, conforme a skill `revisao`, do intervalo fixado na
seção 1: **`afa5898..38a6ec1`**. O commit posterior `fd9fbf8` altera somente este dossiê;
suas anotações adicionais nas seções 4–6 foram relidas e consideradas. **Veredito geral:
bloqueante para encerrar a Etapa 10.** Nenhuma correção implementada: a única edição desta
revisão é esta seção.

### Cobertura e limites da revisão

Esforço concentrado nas declarações da seção 2: geradores de limpeza, contratos e pontes,
catálogo, serialização, macros, retenção, medida D33 e DAG; conferência das alterações de
chaves, junções, agrupamentos e janelas nos modelos manuais de `trusted`, dimensões, fatos
e snapshots. Amostragem semântica dos derivados de pedidos, movimentos de estoque e
endereços, incluindo as respectivas pontes. Paridade mecânica não equivale a prova de
semântica: um gerador errado também produz arquivos perfeitamente sincronizados.

Foram lidos consumidores fora do diff para verificar o efeito da mudança de identidade.
É o caso das views P04, P07, P11, P12 e P16: o defeito exposto nelas nasce quando esta
entrega passa a fornecer duas origens com ids naturais coincidentes. Não é exigência de
expor `source_system` em toda saída; é exigência de preservá-lo enquanto identifica uma
entidade, antes de agregar/conformar.

Consultas PostgreSQL executadas em modo **somente de leitura**, com limite por comando;
contraprovas em `SELECT`/CTEs sintéticas, sem materialização. Não executei carga, sync,
build dbt, DAG, Terraform, migração, exclusão, reconstrução ou reprocessamento persistido.
As saídas da seção 3 continuam sendo medições **do autor**, não desta revisão.

As notas adicionais mudam o alcance do veredito, não substituem a verificação:

- A falta de execução da DAG e de vínculo entre job e captura é reconhecida; não a
  apresento como execução malsucedida que tenha observado. R22 é uma dependência
  incompatível demonstrável no código, distinta dessa ausência de teste.
- Não atribuo a lentidão ao empilhamento: falta comparação controlada. Os dois timeouts
  abaixo são limites desta execução, não prova de perda de detecção.
- D33, D34 e D35 estão decididas pelo Owner. R21 e R24 questionam suas implementações,
  não propõem inverter a cascata nem trocar o universo da classificação.
- Reter impressões antigas e testar a versão corrente é compatível com o remédio de
  avançar a versão. Não é, por si, defeito apagar o alerta sobre uma versão histórica;
  apagar a auditoria seria outra coisa, e não foi o que o código fez.
- A hipótese de cliente rejeitado com pedido sobrevivente da seção 4.5 contrariaria a
  cascata descendente. Sem ocorrência reproduzida, permanece cenário a provar no
  oráculo de R13, não um defeito adicional afirmado aqui.
- Não medi a falha de comparação textual citada na seção 4.6. A contraprova de R21 usa
  chaves já canônicas e revela outro problema: a ausência de recorte da auditoria.

### Evidências executadas pelo revisor

Com `.env` carregado sem imprimir credenciais:

```bash
PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=30000' \
  MVP_TESTE_CARGA=0 .venv/bin/pytest -q --tb=short -p no:cacheprovider \
  tests/test_remessas.py tests/test_invariantes.py tests/test_manutencao_streaming.py \
  tests/test_legado.py tests/test_legacy_models.py tests/test_legacy_classification.py \
  tests/test_legado_deteccao.py tests/test_dbt.py
```

Trechos literais da saída, código de saída 1:

```text
E   psycopg.errors.QueryCanceled: canceling statement due to statement timeout
FAILED tests/test_legado_deteccao.py::test_os_modelos_encontram_tudo_que_o_injetor_produziu
FAILED tests/test_legado_deteccao.py::test_o_falso_positivo_da_heuristica_continua_marginal
2 failed, 85 passed in 353.83s (0:05:53)
```

Ambas as falhas ocorreram na consulta que reúne os achados das 40 views, antes da
comparação esperada. **Não há nova medição de recall ou de falsos positivos nesta
revisão.** Não substituo os números do autor por uma extrapolação desses timeouts.

Contraprovas por `.venv/bin/python -`: renderização do **modelo completo** retornado por
`dbt.modelo()`, com fontes sintéticas em CTE, corte `2026-09-01` e seleção da captura 1.
Saídas abaixo são achado e valor limpo da célula, não uma classificação contextual
completa do lote. O classificador trata os códigos de conversão como corrigíveis;
ausência de achado não protege os casts posteriores nas pontes. Trechos literais:

```text
{"field": "orders.placed_at", "input": "2024-02-31", "code": "DATE_IMPOSSIBLE", "cleaned": "2024-02-31"}
{"field": "orders.placed_at", "input": "2024.02.31", "code": "DATE_IMPOSSIBLE", "cleaned": "2024.02.31"}
{"field": "orders.placed_at", "input": "sem data", "code": "DATE_UNPARSEABLE", "cleaned": "sem data"}
{"field": "orders.placed_at", "input": "0000-01-01", "sqlstate": "22008", "error": "DataError"}
{"field": "orders.placed_at", "input": "2024-01-01T99:00:00", "sqlstate": "22008", "error": "DataError"}
{"field": "orders.placed_at", "input": "2024-01-01 lixo", "code": null, "cleaned": "2024-01-01 lixo"}
{"field": "products.name", "input": "CÂMERA", "code": null, "cleaned": "CÂMERA"}
{"field": "products.name", "input": "CafÃ©", "code": "TEXT_ENCODING", "cleaned": "Café"}
{"field": "products.name", "input": "CafÃ© e café", "sqlstate": "22021", "error": "DataError"}
{"field": "products.name", "input": "CafÃ© 😀", "sqlstate": "22P05", "error": "DataError"}
{"field": "product_prices.unit_price", "input": "abc", "code": "MONEY_AMBIGUOUS", "cleaned": "abc"}
{"field": "product_prices.unit_price", "input": "12,3456", "code": "MONEY_LOCALE", "cleaned": "12.3456"}
{"field": "product_prices.unit_price", "input": "1.234,5678", "code": "MONEY_LOCALE", "cleaned": "1234.5678"}
{"field": "product_prices.unit_price", "input": "1,234,567", "code": "MONEY_LOCALE", "cleaned": "1.234.567"}
{"field": "customer_addresses.is_primary", "input": "talvez", "code": null, "cleaned": "talvez"}
{"field": "customer_addresses.is_primary", "input": "TRUE", "code": "BOOL_VARIANT", "cleaned": "true"}
{"field": "customer_addresses.is_primary", "input": " true ", "code": null, "cleaned": " true "}
{"field": "cart_items.quantity", "input": "-1.0", "code": "NUM_TEXT_EQUIV", "cleaned": "-1"}
{"field": "cart_items.quantity", "input": "1000001,0", "code": "NUM_TEXT_EQUIV", "cleaned": "1000001"}
{"field": "orders.placed_at", "input": "01/01/2030", "code": "DATE_FORMAT_KNOWN", "cleaned": "2030-01-01"}
Formatadores ainda perdem precisão/horário: 12,34 29/02/2024
```

A última linha chama `_pt_br('12.3456', None)` e
`_dd_mm_aaaa('2024-02-29T13:14:15-03:00', None)` diretamente; não confundir com o
normalizador SQL, cujo tratamento de quatro casas foi parcialmente corrigido.

Conferência em memória, sem regerar arquivos: auxiliares, metadados e 36 pontes comparados
com seus geradores. Para D34, alternância temporária de `brands.name.nullable` no metadata
SQLAlchemy **somente no processo diagnóstico**, com restauração, comparando `records_sql()`
e `impressao_digital()` antes/depois. Saída literal:

```text
D34: mudar nullable muda contrato: True
D34: fingerprint permanece igual: True
Derivados auxiliares e pontes comparados: 47 divergentes: []
Catálogo atual: 4 códigos: 25 injetáveis: 23
```

Outras contraprovas por `.venv/bin/python -`, executando SQL real renderizado em relações
sintéticas: R08 com os dois vizinhos preenchidos/vazios; R11 com classificação inteiramente
aceita e quarentena anterior; D35 com pai da captura 2 e rejeição apenas da captura 1; teste
SCD com id 1 nas duas origens, cada uma com uma única versão aberta, inícios distintos.
Os testes R09 receberam uma linha por fonte na captura 1 e nenhuma na captura 2.
Saída literal:

```text
R11_rejeitados_retidos_fp_atual 0
R11_rejeitados_retidos_fp_antigo 1
D35_historico_sozinho_exonera_captura_2 True
SCD_falsa_sobreposicao_entre_origens 1
R08_vizinhos_vazios_False None
R08_vizinhos_vazios_True TEXT_DELIMITER
R09_existe_captura_1 0
R09_existe_captura_2 1
R09_completa_captura_1 0
R09_completa_captura_2 40
```

Consultas ao banco existente, também por `.venv/bin/python -`/SQLAlchemy somente de
leitura. P04 compara `count(distinct customer_natural_key)` com
`count(distinct (source_system, customer_natural_key))` no conjunto de vendas realizadas.
P16 conta pedidos elegíveis com chamado de mesmo id **apenas em outra origem**. P07 conta
linhas após a junção por categoria natural e movimentos distintos antes da multiplicação.
P12 conta pares naturais armazém/SKU presentes nas duas origens do caminho frio.
D33 compara a soma de `itens_rejeitados` da medida com as ocorrências rejeitadas da
classificação corrente para aqueles mesmos pedidos. P11 foi consultada por
`select count(*) from consumption.inventory_turnover_by_sku_and_warehouse`.
Saídas literais:

```text
captura_e_classificacao [(16, 4, 'accepted', 10441), (16, 4, 'corrected', 26), (16, 4, 'rejected', 2280)]
P04_clientes_fundidos [(1327, 1390)]
P16_pedidos_com_chamado_apenas_em_outra_origem [('legacy', 9), ('retail', 1)]
P11_leitura_da_view erro ProgrammingError SQLSTATE 21000
P12_colisoes_de_pares_no_frio [(121,)]
P07_custo_multiplicado_por_categoria_sem_origem [(14570, 8160)]
D33_itens_contados_da_quarentena_retida [(Decimal('843'),)]
D33_itens_da_classificacao_corrente_para_os_pedidos [(74,)]
D35_explicadas_so_por_historico [(0,)]
cupom_pedidos_duplicados_sem_origem [(0,)]
cupom_pedidos_duplicados_com_origem [(0,)]
movimentos_legado_janela_configurada_7_dias [(553, 7)]
```

P07 acima mede **linhas**, não reais de custo. O caso D35 em que só o histórico explica
não apareceu nos pedidos atuais consultados; sua contraprova é sintética. Também não há
colisão atual de `order_id` na fato de cupons: R23 identifica um teste incompatível com
uma colisão válida, não um teste que tenha falhado no build publicado. A última consulta
aplica o filtro incremental real, com os **7 dias** declarados em `dbt_project.yml`: de
553 movimentos legados em `trusted`, 7 seriam relidos. Isso não mede perda atual nem
executa o reprocessamento discutido em R25.

### Situação dos achados anteriores

Os números R01–R17 referem-se à revisão anterior preservada no histórico (por exemplo,
`git show 250e6e5:REVISAO.md`). Não são dezessete descobertas novas nesta entrega.
Linhas e caminhos abaixo referem-se ao código em `38a6ec1`. “Pendente” não autoriza
implementação. As correções de derivados devem nascer nas declarações.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| R01 | `src/mvp_ed1/legacy/ponte.py`; modelos de `trusted` e `analytics` | O conjunto apto ganhou 36 pontes, consumidores e identidade por origem até as fatos. A ausência original foi tratada, mas a integração não termina aí: consumidores ainda fundem identidades; ver R18–R20 e R25. As quatro tabelas sem contraparte permanecem explicitamente fora das pontes, não foram contadas como empilhadas pelo revisor. | `bloqueante` | **Parcialmente resolvido.** Não encerrar a integração com base apenas nas contagens das pontes. |
| R02 | `src/mvp_ed1/legacy/regras.py:31`, `:172`, `:210`, `:229` | Calendário impossível e texto sem data agora têm rejeição nos exemplos originais. Persistem casts que abortam com ano zero e hora 99; o reconhecimento por prefixo deixa `2024-01-01 lixo` sem achado. Validar a entrada inteira, calendário e horário antes da conversão, inclusive para os casts das pontes. | `bloqueante` | **Parcialmente resolvido; contraprovas ainda falham.** |
| R03 | `src/mvp_ed1/legacy/regras.py:252` | `CÂMERA` foi preservado e `CafÃ©` foi corrigido. A detecção de um par, porém, autoriza recodificar a célula inteira: misturá-lo com `café` legítimo ou emoji ainda aborta a consulta. A reversibilidade precisa valer para o conteúdo convertido, não apenas para um fragmento. | `bloqueante` | **Parcialmente resolvido; SQLSTATE 22021 e 22P05 reproduzidos.** |
| R04 | `src/mvp_ed1/legacy/regras.py:134` | Os exemplos de quatro casas e `abc` foram tratados. A variante americana sem parte decimal `1,234,567` é reconhecida, mas vira `1.234.567`, inválido como numeric, ainda sob código corrigível. Separar a interpretação dos formatos e validar o resultado. | `bloqueante` | **Parcialmente resolvido; saída inválida reproduzida.** |
| R05 | `src/mvp_ed1/legacy/regras.py:276`; `src/mvp_ed1/legacy/dbt.py:62` | `TRUE` agora vira `true`, mas `talvez` fica sem achado: o comentário promete `ENUM_UNKNOWN` em booleanos sem alterar o alcance da regra. Além disso, ` true ` não é canonizado e continua incompatível com a comparação textual do índice parcial. Rejeitar desconhecidos e entregar forma canônica para os predicados de contexto. | `bloqueante` | **Parcialmente resolvido.** Deixou de inventar `false`, mas ainda permite valor não conversível chegar à ponte booleana. |
| R06 | `src/mvp_ed1/legacy/dbt.py:97`, `:134`, `:166` | A CTE `limpo` foi criada, mas `_achado()` continua referenciando exclusivamente `c`, o original, nunca `l`, o convertido. `-1.0`, `1000001,0` e `01/01/2030` continuam recebendo apenas conversão, não a rejeição de faixa/futuro aplicável ao resultado. O comentário descreve uma segunda validação que não existe no SQL emitido. | `bloqueante` | **Não resolvido; reproduzido no modelo completo**, não apenas na expressão antiga. |
| R07 | `src/mvp_ed1/legacy/injetor.py:178`, `:192`; testes de detecção | Os formatadores ainda cortam casas monetárias e eliminam horário/fuso em falhas declaradas corrigíveis. Encontrar o código injetado não prova recuperar o valor. Cobrir o valor recuperado com esperado independente e preservar a informação nas formas meramente representacionais. | `bloqueante` | **Não resolvido.** A serialização JSON nova não altera estes formatadores. |
| R08 | `src/mvp_ed1/legacy/regras.py:317`; `src/mvp_ed1/legacy/dbt.py:80` | A detecção passou a considerar os dois vizinhos alcançados pela injeção. `A;B` não recebe `TEXT_DELIMITER` com vizinhos preenchidos e recebe com vizinhos vazios. | `observação` | **Resolvido no recorte dirigido executado.** |
| R09 | `src/mvp_ed1/legacy/dbt.py:265`, `:312`, `:358`; `airflow/dags/fluxo_batch.py:93` | Seleção única e testes novos fecham captura inexistente e ausência de stream. “Completa” ainda significa apenas ter alguma linha nas 40 tabelas; não prova carga integral nem que a seleção pertence ao job acabado. Uma carga que não deixe linhas novas reutiliza a anterior e passa. O dossiê reconhece isso, mas a docstring da DAG ainda afirma o contrário. | `bloqueante` | **Parcialmente resolvido.** Existência/ausência reproduzidas; vínculo job–captura e execução da DAG continuam sem prova, conforme notas do autor. |
| R10 | Seleção de captura em `src/mvp_ed1/legacy/dbt.py`; ADR-0037 | A retenção continua sem comparação de chaves entre capturas completas que detecte exclusão física. Os novos testes de presença de stream não substituem essa comparação. | `bloqueante` | **Pendente já reconhecido pelo autor.** Nenhuma remoção foi executada nesta revisão. |
| R11 | `dbt/models/quarantine/rejected_legacy_records.sql:25` | A chave substituída vem da classificação inteira. A contraprova agora retém zero rejeitados para a mesma captura/versão/impressão inteiramente aceita; retém a auditoria de impressão diferente, como D34 determina. | `observação` | **Resolvido no recorte dirigido executado.** Não equivale ao ciclo persistido completo de D34. |
| R12 | `src/mvp_ed1/legacy/writer.py`; ciclo Alembic | O schema legado segue fora do ciclo versionado de evolução/reversão. A coluna dbt `treatment_fingerprint` não resolve nem agrava por si essa lacuna do schema de origem. | `bloqueante` | **Pendente já reconhecido pelo autor**, inclusive na anotação adicional 4.7. |
| R13 | `tests/test_legado_deteccao.py`; `tests/test_legacy_classification.py` | Continua faltando esperado independente por ocorrência para órfãs, excedentes, total, cascata e valores recuperados. Paridade de gerados e testes de contagem não respondem se são as ocorrências certas. | `ajuste` | **Pendente já reconhecido.** A detecção de valor tampouco foi revalidada por completo nesta execução, devido aos timeouts. |
| R14 | `docs/pendencias.md:25`, `:128`, `:188`; `docs/plano_de_desenvolvimento.md:254` | Estados ainda divergem: Pendências anuncia que só restam R10/R12/R13, mais abaixo considera etapas 3–10 entregues e próxima a 11; o plano ainda diz que a fronteira de empilhamento não existe e mantém a ressalva antiga de R11. Atualizar os donos documentais com estado verificado e medidas identificadas por captura/versão, preservando o histórico dos ADRs. | `ajuste` | **Parcialmente resolvido.** A reabertura no cabeçalho e as notas adicionais não corrigem esses trechos. |
| R15 | D33 em `docs/pendencias.md:64` | O Owner ratificou reconciliação contra todos os capturados menos excedentes e medida separada para o conjunto empilhado. Não há motivo para restaurar a política anterior. O defeito da medida está em R21. | `observação` | **Questão de decisão resolvida.** Implementação ainda requer correção. |
| R16 | D34 em `docs/pendencias.md:46` | O Owner definiu versão humana mais impressão digital, retenção de tratamentos divergentes e teste da versão corrente. Essa decisão resolve a pergunta anterior; a cobertura insuficiente da impressão é o novo R24. | `observação` | **Questão de decisão resolvida.** Não confundir com prova completa de implementação. |
| R17 | `tests/test_remessas.py`; `dbt/tests/remessa_leva_ao_menos_um_item.sql` | Os testes dirigidos da D31 passaram na bateria desta revisão. Não foi repetida a Etapa 7 ao vivo; a mudança da exceção legada no teste de remessa é avaliada em R21/R22. | `observação` | **Sem novo achado no conserto do gerador da D31.** |

### Achados adicionais desta entrega

Para regressões que aparecem em consumidores inalterados, a coluna “Onde” identifica
também a mudança de contrato no diff que as introduz.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| R18 | `dbt/models/analytics/dim_customer.sql:31`, `fact_sales_order_item.sql:78`, `fact_support_ticket_event.sql:89`; consumidores P04/P16 | **Coortes fundem entidades de origens diferentes.** P04 continua fazendo `distinct on` e recompra apenas por `customer_natural_key`: mede 1.327 identidades onde o par origem/id identifica 1.390 clientes compradores. P16 junta chamados e pedidos apenas por `order_id`: 9 pedidos legados e 1 retail recebem chamado existente somente na outra origem. Propagar a identidade composta nas CTEs e junções e testar colisões antes da agregação de negócio. | `bloqueante` | **Novo, reproduzido no banco existente.** A adequação das fatos não preservou o contrato dos consumidores. |
| R19 | `dbt/models/analytics/dim_category.sql:23`, `dim_warehouse.sql:8`; P07 `gross_margin_by_category.sql:51` e P11 `inventory_turnover_by_sku_and_warehouse.sql:33`, `:78` | **As novas dimensões multiplicam custos e tornam P11 não consultável.** A junção categoria/id sem origem produz 14.570 linhas para 8.160 movimentos distintos no ramo de custo da P07. Na P11, procurar armazém apenas pelo nome agora retorna mais de uma linha na subconsulta escalar e gera SQLSTATE 21000; suas junções de saldo também omitem origem. Corrigir as chaves de ligação e exercitar a leitura das views: `CREATE VIEW` bem-sucedido não prova que consultá-las funciona. | `bloqueante` | **Novo, multiplicação e erro reproduzidos.** Não é só incluir uma coluna na apresentação. |
| R20 | `dbt/models/analytics/fact_inventory_movement.sql:53`; P12 `skus_below_reorder_point.sql:30`, `:59`, `:76`, `:159` | **A união quente/frio perde a procedência que acabou de chegar à fato.** P12 descarta a origem no ramo frio, agrupa saldo apenas por armazém/SKU e faz as junções finais pelos mesmos ids. Há 121 pares naturais presentes nas duas origens. O anti-join do quente também usa somente `movement_id`, podendo suprimir evento retail por coincidência com legado. Preservar identidade nos dois ramos, no anti-join, nos saldos e nas dimensões antes de produzir reposição/cobertura. | `bloqueante` | **Novo; colisões atuais medidas e perda de identidade constatada no SQL.** Não foram reexercitados alertas/eventos ao vivo. |
| R21 | `dbt/macros/explicado_pela_quarentena.sql:38`; `dbt/models/trusted/legacy/legacy_order_totals_divergence.sql:24` | **D33/D35 consultam toda a auditoria retida como se fosse da captura corrente.** O recorte contém apenas origem, tabela e FK; faltam captura, versão e impressão. A medida conta 843 ocorrências rejeitadas para pedidos que têm 74 na classificação corrente. A macro aceita rejeição exclusivamente histórica como explicação de pai da captura seguinte, reproduzido em CTE. Vincular a contrapartida ao tratamento/captura em análise, mantendo intacta a retenção histórica. | `bloqueante` | **Novo, reproduzido.** A aceitação do pai válido por D35 não autoriza usar rejeição obsoleta para exonerar divergência atual. |
| R22 | `airflow/dags/fluxo_batch.py:157`, `:162`, `:191`; medida D33 e testes que chamam `explicado_pela_quarentena` | **A DAG constrói um consumidor antes da quarentena de que ele depende.** `legacy_order_totals_divergence` está em `trusted`, sem a tag excluída, mas lê `rejected_legacy_records`; as invariantes também ganharam essa dependência. `dbt_trusted` precede `dbt_quarantine`. Sem a relação anterior, a medida não pode ser construída; com ela, usa a auditoria anterior e não é reconstruída depois. Adequar a seleção/ordem às dependências e provar primeira execução e troca de captura. | `bloqueante` | **Novo, incompatibilidade estática.** A DAG não foi executada, conforme anotação 4.1; o build integral do autor tem outra ordenação e não prova essas tarefas separadas. |
| R23 | `dbt/models/analytics/_analytics__models.yml:28`, `:47`, `:481`, `:501`, `:530` | **Parte dos testes ainda exige identidade global por id natural.** O `unique` de `fact_coupon_redemption.order_id` permaneceu mesmo após a inclusão da unicidade composta; um pedido de cada origem com o mesmo id passa no contrato novo e falha no antigo. Os quatro testes de vigência continuam recebendo somente a chave natural: duas origens válidas com início diferente produzem falsa sobreposição na contraprova. Adequar também os testes ao grão com procedência. | `bloqueante` | **Novo; falha SCD reproduzida sinteticamente.** Sem colisão atual medida nos cupons; o risco não foi apresentado como falha do build existente. |
| R24 | `src/mvp_ed1/legacy/dbt.py:393`; `src/mvp_ed1/legacy/classification.py` (`records_sql`) | **A impressão de D34 não cobre todo o tratamento que determina o resultado.** O hash inclui limpeza e classificação, mas não `records_sql()`, onde entram obrigatoriedade, FKs e unicidade. Mudar `brands.name.nullable` altera esse contrato sem alterar o hash. Variáveis como `as_of_date` também permanecem como Jinja não resolvido no material hasheado. Resultados distintos podem conservar a mesma identidade e substituir auditoria sem o alarme prometido. Cobrir o contrato efetivo e parâmetros que mudam decisões, com contraprova independente. | `bloqueante` | **Novo, omissão do contrato reproduzida em memória.** Distinto da meia prova persistida reconhecida na anotação 4.4. |
| R25 | `dbt/models/analytics/fact_inventory_movement.sql:27`, `:40`; empilhamento de `inventory_movements` | **O reprocessamento de uma captura completa não foi conciliado com a fato incremental.** A origem legada agora entra num `merge` filtrado pelo máximo global de tempo de evento menos 7 dias. Correção que torne apto um movimento antigo não o insere fora da janela; rejeição/ausência posterior não remove a linha já materializada. No estado consultado, só 7 de 553 movimentos legados seriam relidos. Provar o caminho de atualização/reconciliação da captura sem contrariar a exceção incremental do ADR-0016; não basta igualdade após uma reconstrução inicial. | `bloqueante` | **Novo, caminho incompatível identificado no SQL e alcance do filtro medido.** Não afirmo perda atual nem executei mudança de captura. |
| R26 | `src/mvp_ed1/legacy/ponte.py:68`; anotação adicional 6.1 | **`event_sequence = legacy_row_id` é sequência da ocorrência física, não sequência observada do evento na origem.** A equivalência foi assumida pelo autor e não há nesta revisão prova de estabilidade entre recapturas. Não foi encontrado consumidor atual que use essa coluna legada para ordenar o saldo; por isso não afirmo corrupção reproduzida. Explicitar o contrato e confirmar com o Owner antes de atribuir-lhe garantias de ordenação/linhagem que a origem não fornece. | `observação` | **Pendente de esclarecimento do contrato**, não autorização para inventar outra sequência. |

## Reavaliação do estado atual — 08/09/2026

**Veredito: bloqueante para encerrar a Etapa 10.** Revisão por Codex, conforme
`.claude/skills/revisao/SKILL.md`. Há correções confirmadas, mas as contraprovas ainda
encontram consultas interrompidas, rejeição de valores válidos e identidade insuficiente
do tratamento. A troca automática de ambientes também tem um caminho de falso sucesso.

### Recorte e cobertura

Esta reavaliação toma o parecer anterior como base e examina o estado atual:
`38a6ec1..344718715eff92eb306bdf9b97237dc43682a6e6`, mais as alterações locais já
presentes no início da sessão. O dossiê anterior não abrangia essas correções.
O catálogo local está na versão **6**; a classificação materializada consultada está na
versão **5**, captura **16**. Os dois estados não foram tratados como equivalentes.

O diff local foi preservado em `/tmp/mvp_revisao_20260907/estado_sem_commit.patch`.
Seu SHA-256, conferido novamente antes de editar este parecer, permaneceu:

```text
e2ad34394fda2a903a96c328ef96c14e7c3e0a904ca009eab7d6b7e51f75e520
```

Revisadas as mudanças nos declarativos de limpeza, catálogo, alcance dos arquétipos,
injetor, impressão digital, macros, seleção da DAG, cinco views de consumo, testes,
preflight, Makefile e limites do Airbyte. Conferidos o ADR-0041 e os contratos aplicáveis
dos ADRs 0037–0039 e das decisões D33–D35. Os modelos gerados foram conferidos
mecanicamente e amostrados semanticamente com SQL completo renderizado sobre CTEs.
Os novos valores de memória foram lidos como medições do autor, sem nova medição aqui.

**A única alteração desta revisão no repositório é o `REVISAO.md`.** Não foram
implementadas correções nem alterados ADRs, pendências ou critérios de aceite.

### Evidências desta execução

Os comandos com banco carregaram `.env` sem imprimir credenciais e usaram
`PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=30000'`.
As contraprovas de valores usaram limite de 10 segundos por consulta.
Conexão observada:

```text
('PostgreSQL 16.15 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit', 'on')
```

Bateria dirigida:

```bash
MVP_TESTE_CARGA=0 .venv/bin/pytest -q --tb=short -p no:cacheprovider \
  tests/test_legacy_models.py tests/test_legacy_classification.py \
  tests/test_legado_deteccao.py tests/test_consumo.py \
  tests/test_procedencia.py tests/test_dbt.py
```

Trechos literais, saída 1:

```text
E   psycopg.errors.QueryCanceled: canceling statement due to statement timeout
E   psycopg.errors.QueryCanceled: canceling statement due to statement timeout
E   psycopg.errors.QueryCanceled: canceling statement due to statement timeout
E   AssertionError: esperadas 16 views de consumo, encontradas 2: ['skus_below_reorder_point', 'top_skus_by_revenue']
FAILED tests/test_legado_deteccao.py::test_os_modelos_encontram_tudo_que_o_injetor_produziu
FAILED tests/test_legado_deteccao.py::test_o_falso_positivo_da_heuristica_continua_marginal
FAILED tests/test_legado_deteccao.py::test_cleaned_models_materialize_every_column
FAILED tests/test_consumo.py::test_as_dezesseis_perguntas_estao_publicadas - ...
4 failed, 38 passed in 95.78s (0:01:35)
```

Os três timeouts impedem medir detecção, falsos positivos e leitura integral dos modelos
instalados nesta execução; **não demonstram divergência contra o manifesto**. A quarta
falha constata publicação incompleta no banco existente, sem demonstrar sua causa.

Gerador, incluindo o novo código de codificação ambígua, sem escrita no banco:

```bash
.venv/bin/pytest -q --tb=short -p no:cacheprovider tests/test_legado.py
```

```text
..........                                                               [100%]
10 passed in 2.63s
```

Contraprovas em `.venv/bin/python /tmp/mvp_revisao_20260907/contraprovas.py`:
cada entrada foi aplicada ao **modelo completo produzido por `dbt.modelo()`**, com
as demais colunas nulas, captura sintética 1 e `as_of_date=2026-09-01`. São saídas
de limpeza, não a classificação contextual de um lote inteiro. Trechos literais:

```text
{"field": "orders.placed_at", "input": "0000-01-01", "cleaned": "0000-01-01", "code": "DATE_IMPOSSIBLE"}
{"field": "orders.placed_at", "input": "2024-01-01 99:00", "cleaned": "2024-01-01 99:00", "code": "DATE_IMPOSSIBLE"}
{"field": "orders.placed_at", "input": "2024-01-01 lixo", "cleaned": "2024-01-01 lixo", "code": "DATE_UNPARSEABLE"}
{"field": "orders.placed_at", "input": "2024-01-01 12:30", "sqlstate": "22P02", "error": "invalid input syntax for type integer: \"\""}
{"field": "orders.placed_at", "input": "2024-01-01T12:30Z", "sqlstate": "22P02", "error": "invalid input syntax for type integer: \"\""}
{"field": "orders.placed_at", "input": "2024-01-01T12:30:00", "cleaned": "2024-01-01 15:30:00+00", "code": "DATE_UNPARSEABLE"}
{"field": "orders.placed_at", "input": "2024-01-01T12:30:00+00", "cleaned": "2024-01-01T12:30:00+00", "code": "DATE_UNPARSEABLE"}
{"field": "orders.placed_at", "input": "2024-01-01T12:30:00+00:00", "cleaned": "2024-01-01T12:30:00+00:00", "code": null}
{"field": "orders.placed_at", "input": "2024-01-01T12:30:00+99:99", "cleaned": "2024-01-01T12:30:00+99:99", "code": null}
{"field": "orders.placed_at", "input": "01/01/2030", "cleaned": "2030-01-01", "code": "DATE_FUTURE"}
{"field": "products.name", "input": "CafÃ©", "cleaned": "Café", "code": "TEXT_ENCODING"}
{"field": "products.name", "input": "CafÃ© e café", "cleaned": "CafÃ© e café", "code": "TEXT_ENCODING_AMBIGUOUS"}
{"field": "products.name", "input": "CafÃ© 😀", "cleaned": "CafÃ© 😀", "code": "TEXT_ENCODING_AMBIGUOUS"}
{"field": "product_prices.unit_price", "input": "1,234,567", "cleaned": "1234567", "code": "MONEY_LOCALE"}
{"field": "product_prices.unit_price", "input": "1,234", "cleaned": "1.234", "code": "MONEY_LOCALE"}
{"field": "customer_addresses.is_primary", "input": "talvez", "cleaned": "talvez", "code": "ENUM_UNKNOWN"}
{"field": "customer_addresses.is_primary", "input": " true ", "cleaned": "true", "code": "BOOL_VARIANT"}
{"field": "cart_items.quantity", "input": "-1.0", "cleaned": "-1", "code": "NUM_OUT_OF_RANGE"}
{"field": "cart_items.quantity", "input": "1000001,0", "cleaned": "1000001", "code": "NUM_OUT_OF_RANGE"}
state [(16, 5, 'accepted', 10441), (16, 5, 'corrected', 26), (16, 5, 'rejected', 2280)]
offset_example [('2024-01-01 15:30:00+00',)]
count_projection [(2,)]
formatters 12,34 29/02/2024
```

Para R03, o mesmo script acrescentou a `CafÃ© ` o resultado de
`bytes.fromhex(hexadecimal).decode('latin1')`. Os três sufixos `eda080`, `e08080`
e `f4908080` passaram pela autorização de conversão e produziram **SQLSTATE 22021**.
Mensagens literais do PostgreSQL:

```text
invalid byte sequence for encoding "UTF8": 0xed 0xa0 0x80
invalid byte sequence for encoding "UTF8": 0xe0 0x80 0x80
invalid byte sequence for encoding "UTF8": 0xf4 0x90 0x80 0x80
```

Para R28, `count_projection` acima executou:

```sql
select count(*)
from (
  select (select x from (values (1), (2)) t(x)) bad
  from generate_series(1, 2)
) s;
```

O `count(*)` retornou 2. Substituí-lo por `count(md5(to_jsonb(s)::text))` na
contraprova seguinte obrigou a avaliação de `bad` e revelou o erro.

Em `.venv/bin/python /tmp/mvp_revisao_20260907/contratos.py`, consultas sintéticas
exercitaram a macro D35 e os parâmetros de D34. A mudança de `nullable` foi feita
somente no metadata em memória e restaurada. Os dois cortes de data renderizaram o
mesmo modelo, com o mesmo SQL de classificação gerado e sua impressão constante.
Nenhuma auditoria foi substituída no banco. Saídas literais selecionadas:

```text
invalid_offset_cast SQLSTATE 22009 time zone displacement out of range: "2024-01-01T12:30:00+99:99"
all_columns_projection SQLSTATE 21000 more than one row returned by a subquery used as an expression
D35_raw_8_snapshot_2 [(True,)]
D35_raw_8_snapshot_1 [(False,)]
D34_nullable_changes_fingerprint True
D34_as_of_2026-09-01_fp_56c2f9cb2f965f76 [('DATE_FUTURE',)]
D34_as_of_2026-09-03_fp_56c2f9cb2f965f76 [(None,)]
auxiliary_generated_mismatches []
```

A seleção real da tarefa `dbt_trusted` foi conferida sem execução de modelos:

```bash
DBT_TARGET_PATH=/tmp/mvp_revisao_20260907/dbt_target \
DBT_LOG_PATH=/tmp/mvp_revisao_20260907/dbt_logs \
  .venv/bin/dbt --quiet ls --project-dir dbt --profiles-dir dbt \
  --no-partial-parse --select trusted --exclude tag:legado_reconciliacao \
  --output json --output-keys unique_id resource_type depends_on tags
```

O script `contratos.py` inspecionou essa seleção e renderizou os cinco modelos de
consumo corrigidos, resolvendo referências pelo manifesto dbt. Executou cada SQL como
subconsulta com `count(md5(to_jsonb(s)::text))`, sem criar views. Saída literal:

```text
R22_trusted_dependencies_on_quarantine []
R22_selection legacy_order_totals_divergence in_trusted False tags ['legado_reconciliacao']
R22_selection invariante_02_total_do_pedido_reconcilia in_trusted False tags ['legado_reconciliacao']
R22_selection invariante_08_reserva_encerrada_nao_ocupa_saldo in_trusted False tags ['legado_reconciliacao']
R22_selection remessa_leva_ao_menos_um_item in_trusted False tags ['legado_reconciliacao']
R22_selection saldo_reconstruido_confere_com_a_projecao in_trusted False tags ['legado_reconciliacao']
current_model_new_and_repeat_customers_by_month [(560,)]
current_model_repeat_purchase_rate_after_support [(175,)]
current_model_gross_margin_by_category [(396,)]
current_model_inventory_turnover_by_sku_and_warehouse [(6340,)]
current_model_skus_below_reorder_point [(524,)]
```

Esses números contam linhas dos SQLs atuais executados sobre as relações existentes.
Não são uma nova publicação das 16 views nem prova de todas as medidas de negócio.

Em `.venv/bin/python /tmp/mvp_revisao_20260907/limites.py`, a macro recebeu pai com
`cast('08' as bigint)` e filho rejeitado cujo payload original e limpo preserva `08`,
na mesma captura/versão/impressão. Também foram conferidos os dois padrões monetários
e o teste de vigências renderizado com duas origens, seguido da contraprova na mesma
origem:

```text
D35_pai_08_tipado_bigint_filho_08 False
MONEY_1,234_casa_BR_e_US (True, True)
SCD_same_source_False 0
SCD_same_source_True 1
```

Preflight exercitado por `python3 /tmp/mvp_revisao_20260907/preflight_simulado.py`:
`docker`, `pgrep`, leitura de memória e espera foram substituídos por executáveis
simulados em `/tmp`. **Nenhum Docker real foi chamado.** O cenário fornece memória
suficiente, streaming ocioso e `docker stop` retornando 1. Saída literal:

```text
Cenario: streaming ocioso, docker stop retorna 1, 12000 MiB disponiveis; nenhum Docker real chamado
[preflight] RAM disponível agora: 11.7 GB
[preflight] Já de pé: streaming (Redpanda + Kafka Connect)
[preflight] 'airbyte' custa ~4.9 GB — sobraria 6.8 GB
[preflight] streaming está de pé e ocioso — pausando.
[preflight] streaming pausado — retomar com make stream-resume
[preflight] RAM disponível agora: 11.7 GB — sobraria 6.8 GB
[preflight] OK
exit_code: 0
chamadas_simuladas: ['ps --format {{.Names}}', 'ps --format {{.Names}}', 'ps --format {{.Names}}', 'stop mvp_ed1_kafka_connect mvp_ed1_redpanda']
```

### Correções revalidadas

Estas situações atualizam o parecer anterior somente no alcance descrito.

| # | Onde | Veredito | Situação atual |
|---|---|---|---|
| R05 | `regras.py`, `schema.py`, `dbt.py` | `observação` | **Resolvido nas contraprovas.** `talvez` recebe `ENUM_UNKNOWN`; `TRUE`, ` true ` e `sim` são canonizados. |
| R06 | `src/mvp_ed1/legacy/dbt.py` | `observação` | **Resolvido no defeito de precedência.** Faixa e futuro alcançam o resultado convertido. A validação de formatos de data introduziu os problemas remanescentes de R02. |
| R18 | Views P04/P16 | `observação` | **Correção conferida no SQL.** Origem acompanha identidade, junções e coortes; ambos os modelos foram executados com todas as colunas. Não foi repetida uma validação completa dos indicadores. |
| R19 | Views P07/P11 | `observação` | **Correção conferida no SQL e na execução.** Junções incluem origem e P11 usa id de armazém; ambas responderam à leitura completa do SQL atual. |
| R20 | View P12 | `observação` | **Correção conferida no SQL e na execução.** Origem preservada no frio/quente, anti-join, saldo e dimensões. Streaming ao vivo não reexercitado. |
| R21 | Macro D35 e medida D33 | `observação` | **Recorte histórico corrigido.** A macro recusa a rejeição exclusiva da captura anterior; medida e macro incluem captura, versão e impressão. A comparação de identidade ainda tem o problema distinto R29. |
| R22 | Tags dos modelos/testes e seleção da DAG | `observação` | **Incompatibilidade estática corrigida.** `dbt ls` confirma a exclusão dos cinco consumidores de quarentena da tarefa `trusted`. Primeira execução e troca de captura pela DAG continuam sem prova. |
| R23 | Teste de vigências e YAML de cupons | `observação` | **Resolvido no recorte dirigido.** Duas origens válidas dão zero sobreposições; sobreposição na mesma origem continua detectada. O `unique` global de `order_id` foi removido e a combinação com origem permanece. |

R08, R11, R15–R17 não receberam correção nova neste recorte; mantém-se o alcance
limitado do parecer anterior, sem nova alegação de execução. R01 avançou com as
correções de consumo, mas não está encerrado enquanto R25 persistir.

### Achados ainda abertos ou novos

As linhas abaixo são o parecer atual. R27–R29 são novos; os demais preservam a
numeração anterior. “Pendente” indica trabalho a responder, não aceite ou decisão
arquitetural do revisor. Correções nos derivados devem nascer nos geradores.

| # | Onde | Achado e ajuste necessário | Veredito | Situação |
|---|---|---|---|---|
| R02 | `src/mvp_ed1/legacy/regras.py:33`, `:120`, `:287`, `:333` | **O validador de datas ainda interrompe consultas e rejeita valores válidos.** Segundos são opcionais na regex, mas `substring` ausente devolve string vazia, que `coalesce` não trata: `2024-01-01 12:30` falha com 22P02. A conversão sem fuso produz `+00`, formato excluído pela nova regex, e o próprio resultado recebe `DATE_UNPARSEABLE`. O offset `+99:99` passa sem achado e falha depois no cast para `timestamptz` (22009). Tratar componentes opcionais, aceitar o formato canônico produzido e validar o deslocamento antes de liberar o cast; testar entradas e resultados completos. | `bloqueante` | **Resolvido.** O momento passou a ser lido por componente (`substring(v from 'padrão')`, nulo quando ausente) em vez de posição fixa, o sufixo de fuso virou constante única com minutos opcionais — a forma que `at time zone` produz —, e o deslocamento é validado (0–15h, 0–59min) dentro de `DATE_IMPOSSIBLE`. Contraprovas, no banco: `2024-01-01 12:30` e `2024-01-01T12:30Z` deixaram de abortar com 22P02; `2024-01-01T12:30:00` vira `2024-01-01 15:30:00+00` com `DATE_TZ_MISSING` em vez de `DATE_UNPARSEABLE`; `+00` é aceito; `+99:99` passou a `DATE_IMPOSSIBLE` em vez de 22009 adiante. Fixado em `test_o_momento_e_lido_por_componente_e_nao_por_posicao`. |
| R03 | `src/mvp_ed1/legacy/regras.py:83` | **A gramática de reversibilidade admite sequências UTF-8 inválidas.** Os ramos de três e quatro bytes não restringem as combinações de E0, ED, F0 e F4; aceitam codificação excessivamente longa, substitutos Unicode e pontos além do limite. Células com `CafÃ© ` mais os bytes Latin-1 `eda080`, `e08080` ou `f4908080` ainda chegam a `convert_from` e abortam com 22021. Completar a validação da sequência inteira e testar esses limites contra o conversor real. | `bloqueante` | **Resolvido.** `LATIN1_REVERSIVEL` passou a ser a gramática UTF-8 da RFC 3629: `E0` exige continuação `A0-BF`, `ED` exige `80-9F`, `F0` exige `90-BF`, `F4` exige `80-8F`. Contraprova no banco com os três sufixos do parecer (`eda080`, `e08080`, `f4908080`): os três recebem `TEXT_ENCODING_AMBIGUOUS` e **não** chegam ao `convert_from` — nenhum 22021. `CafÃ©` continua virando `Café`. Fixado em `test_a_reversibilidade_recusa_utf8_invalido`. |
| R04 | `src/mvp_ed1/legacy/regras.py:53`, `:257` | **Formatos monetários reconhecidos ainda podem ser ambíguos entre si.** `1,234` casa com BR decimal e US milhar; o `case` escolhe BR e entrega `1.234` como corrigido, embora a outra interpretação seja `1234`. Verificar unicidade da interpretação antes de converter, conforme Origem Legada §3.1; usar `MONEY_AMBIGUOUS` quando os valores possíveis diferirem. | `bloqueante` | **Resolvido.** `MONEY_LOCALE` passou a exigir leitura única: a ambiguidade é **medida** — converte pelos dois formatos e compara — em vez de deduzida do padrão. Sem leitura única, cai para `MONEY_AMBIGUOUS`, que rejeita, como a Origem Legada §3.1 manda. Contraprova no banco: `1,234` era `1.234`/`MONEY_LOCALE` e passou a `MONEY_AMBIGUOUS`; `1,234,567`, `12,34` e `1.234,56` seguem corrigidos. Fixado em `test_moeda_com_duas_leituras_e_rejeitada_em_vez_de_escolhida`. |
| R07 | `src/mvp_ed1/legacy/injetor.py:178`, `:192` | Os formatadores ainda descartam casas monetárias e horário/fuso em falhas declaradas corrigíveis. Preservar informação nas variantes representacionais e conferir valor recuperado com esperado independente. | `bloqueante` | **Resolvido.** `_partes_monetarias` deixou de truncar em duas casas (até 4, a escala de `Numeric(14,4)` e dos padrões de `regras.py`; acima disso recusa em vez de truncar em silêncio), e `_data_pura` recusa valor com horário ou fuso — a forma de data pura os descartaria sob código corrigível. Contraprova de **recuperação**, com esperado independente do injetor: para `_pt_br`, `_en_us`, `_com_simbolo`, `_dd_mm_aaaa` e `_aaaa_ponto_mm_dd`, o valor injetado passa pela limpeza e volta ao original, com o código esperado. Fixado em `test_falha_representacional_devolve_o_valor_original`. **A contraprova colheu um achado a mais:** `_en_us` abaixo de mil produzia `12.00`, que difere do original — então o injetor aceitava — e é exatamente a forma canônica, sem falha a detectar; o manifesto declarava `MONEY_LOCALE` numa célula sem defeito. Agora recusa, e o laço de injeção escolhe outra célula. |
| R09 | `airflow/dags/fluxo_batch.py:93`; seleção da captura | A docstring agora admite a lacuna, mas existência de linhas nos streams não comprova que a captura é integral ou pertence ao job concluído. Falta a prova que distingue captura anterior reutilizada de carga nova. | `bloqueante` | **Documentação corrigida; garantia funcional pendente.** Não foi executada sincronização nesta revisão. |
| R10 | Comparação entre capturas; ADR-0037 | A detecção de exclusões físicas entre capturas completas continua ausente. Retenção e presença de stream não a substituem. | `bloqueante` | **Pendente, sem implementação nova neste recorte.** Nenhuma exclusão foi realizada pelo revisor. |
| R12 | `src/mvp_ed1/legacy/writer.py`, `schema.py`; Alembic | O schema da origem legada continua criado por DDL fora do ciclo versionado de evolução/reversão. | `bloqueante` | **Pendente.** A alteração de alcance dos booleanos em `schema.py` não é migração. |
| R13 | Testes do legado e manifesto | Há testes sintéticos úteis e eles passaram; ainda falta o esperado independente completo por ocorrência para o lote, a cascata e os valores recuperados. A paridade dos arquivos e a cobertura de códigos não fecham essa prova. | `ajuste` | **Parcialmente resolvido — a medição destravou.** Os `timeouts` não eram lentidão: eram o armazém esgotando a memória da máquina, causa encontrada e fechada pelo [ADR-0043](docs/adr/0043-impedir-que-o-tratamento-do-legado-esgote-a-estacao.md). A detecção integral no banco **passou a ser medida**: `tests/test_legado_deteccao.py` roda inteiro, 19 testes, sem pulo, em 10 s, e a suíte completa em 83 s com pico de 41 MB de memória anônima no armazém. **O que continua pendente é o mérito**, não a execução: falta o esperado independente por ocorrência para o lote, a cascata e os valores recuperados. |
| R14 | `README.md`; `docs/pendencias.md`; Plano §Etapa 10 | Permanecem estados incompatíveis: empilhamento declarado inexistente e descrito como implementado; etapa reaberta e etapas 3–10 anunciadas entregues; pendências resumidas a R10/R12/R13. Identificar medidas por captura/versão e atualizar o estado nos donos documentais, preservando ADRs aceitos. | `ajuste` | **Não resolvido.** O banco observado tem 2 das 16 views publicadas; as afirmações históricas de build não certificam o estado atual. |
| R24 | `src/mvp_ed1/legacy/dbt.py:487`; classificação gerada | **A impressão continua dissociada dos parâmetros efetivos da execução.** `_parametros()` lê apenas o YAML durante a geração e grava hash literal; `--vars` ou mudança posterior do YAML sem regerar modelos alteram o tratamento e preservam a impressão. Para `placed_at=2026-09-02`, cortes 01/09 e 03/09 retornam respectivamente `DATE_FUTURE` e nenhum achado sob o mesmo hash. Vincular a impressão à configuração efetivamente executada ou recusar divergência entre configuração e artefato gerado. | `bloqueante` | **Resolvido pela segunda saída do parecer — recusar a divergência.** Hashear a configuração efetiva exigiria calcular a impressão em tempo de execução, o que o SQL não faz. O modelo passou a emitir uma guarda Jinja com os parâmetros gravados na geração; na compilação, onde `--vars` já foi resolvido, valor diferente vira `raise_compiler_error`. Contraprova: mesma configuração compila (exit 0); `--vars '{as_of_date: 2026-09-03}'` dá `Compilation Error ... as_of_date vale 2026-09-03, mas a impressão digital deste modelo foi gerada com as_of_date=2026-09-01` (exit 2). A lista de variáveis tem dono único, `parametros_do_tratamento`, compartilhado com o hash. Fixado em `test_configuracao_divergente_da_impressao_recusa_a_compilacao`, que roda o `dbt compile`. |
| R25 | `dbt/models/analytics/fact_inventory_movement.sql:40` | A captura completa do legado ainda alimenta o filtro incremental global de 7 dias; aptidão nova fora da janela e rejeição/remoção posterior não são reconciliadas pela estratégia atual. Provar atualização e remoção no reprocessamento sem assumir que reconstrução inicial basta. | `bloqueante` | **Medido e escalado ao Owner — não implementado de propósito.** Consertar isto muda a estratégia incremental da fato, que é a **única** exceção do ADR-0016, com quatro proteções nomeadas: é alteração de modelagem central, e o CLAUDE.md §5 a põe no Owner. Medido em 08/09/2026, somente leitura: a janela alcança **7 de 553** movimentos legados contra 2.342 de 15.900 do retail, porque o corte usa `max(occurred_at)` global e o retail está quatro dias à frente. Fato e `trusted` estão hoje consistentes nos dois sentidos (0 órfãos) — o defeito está no caminho de reprocessamento, não no estado, como o parecer já dizia. Três saídas com custo explícito registradas em `docs/pendencias.md` como **D37**. |
| R26 | `src/mvp_ed1/legacy/ponte.py:68` | O contrato de `event_sequence = legacy_row_id` continua dependente do esclarecimento já solicitado. Identidade física da captura não demonstra ordem observada ou estabilidade entre recapturas. | `observação` | **Pendente.** Não foi encontrada evidência nova que autorize garantias adicionais. |
| R27 | `docker/preflight.sh:161`, `:178` | **Falha ao pausar é anunciada como sucesso e elimina o conflito.** O retorno de `docker stop` é ignorado, o ambiente entra em `PAUSADOS` e `CONFLITO` é esvaziado sem nova consulta. Com memória suficiente, o script retorna 0 mesmo mantendo o conflitante de pé. Verificar cada parada, confirmar o estado resultante e tratar falhas parciais e de restauração antes de liberar o alvo. | `bloqueante` | **Resolvido.** `_parar`/`_religar` respondem pelo estado reconsultado, não pelo código de saída; pausa que falha recua as anteriores e recusa (exit 1); restauração que falha é anunciada por nome. Contraprova antes/depois no mesmo cenário: HEAD dá `[preflight] OK` e exit 0, corrigido dá `falhei em pausar Airbyte` e exit 1. Fixado em `tests/test_preflight.py` — 6 oráculos, 4,58 s, sem Docker real. |
| R28 | `tests/test_consumo.py:62`, `:73` | **`count(*)` não garante avaliar as colunas da view.** O PostgreSQL eliminou uma subconsulta escalar inválida da projeção e retornou 2; leitura de todas as colunas produziu 21000. O teste pode passar com medidas que falham ao serem lidas. Consumir efetivamente todas as colunas, preservando o teste separado de publicação das 16 views. | `ajuste` | **Resolvido.** A consulta passou a `count(md5(to_jsonb(s)::text))` sobre a view aliasada, que obriga a avaliar toda coluna; a docstring passou a dizer por quê. Contraprova no warehouse, somente leitura: sobre o mesmo corpo, `count(*)` devolve 2 e a formulação nova levanta `CardinalityViolation` 21000. O teste separado das 16 views publicadas foi preservado. |
| R29 | `dbt/macros/explicado_pela_quarentena.sql:61`; `legacy_order_totals_divergence.sql:40` | **A auditoria ainda compara representação bruta com identidade tipada.** Pai com id textual `08` chega à ponte como bigint 8; o filho rejeitado conserva FK `08`. Mesmo com captura/versão/impressão iguais, a macro não encontra a contrapartida, e a medida usa a mesma comparação incompatível. Preservar ou resolver a identidade do vínculo com o mesmo contrato do pai, sem cast indiscriminado sobre payload rejeitado. | `bloqueante` | **Resolvido.** Nova macro `identidade_canonica` (`dbt/macros/identidade_do_vinculo.sql`) canoniza os dois lados **sem cast indiscriminado**: só age quando o texto é inteiro por extenso, e payload não conversível passa intacto. Aplicada na macro D35 e na medida D33 — nesta última também no `group by`, senão a junção multiplicaria o pedido. Contraprova no banco, com a macro lida do próprio arquivo: pai `cast('08' as bigint)` e filho `08` davam falso e agora dão verdadeiro; `80` contra `8` segue falso; `abc`, `2024-01-01` e vazio passam intactos. `dbt compile` dos dois consumidores: exit 0. Fixado em `test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai`. |

### O que permanece sem validação

- Build integral da versão 6, publicação das 16 views e reconciliação completa entre
  camadas sobre esse tratamento. Os SQLs novos foram exercitados sem reconstruir o banco.
- DAG executada do zero, vínculo job–captura, carga incompleta, duas capturas com exclusão
  física e reprocessamento da fato incremental.
- Ciclo persistido de D34: mudar tratamento, conservar auditorias, observar recusa e
  avançar/reverter versão. As contraprovas desta sessão não gravaram dados.
- Oráculo completo da cascata e recuperação exata de todos os valores; recall e falsos
  positivos do lote não medidos nesta bateria.
- Troca real de ambientes, identificação de jobs em todas as fases, concorrência,
  restauração parcial, retomada e prontidão de serviços. O preflight foi simulado e passou
  em `bash -n`; isso não comprova operação real nem memória disponível.
- Aplicação dos valores do Airbyte ao chart/cluster, picos e OOM sob os limites declarados,
  streaming ao vivo, migrações do zero e paridade GCP.

Os auxiliares e logs desta sessão estão temporariamente em
`/tmp/mvp_revisao_20260907/`; as saídas essenciais foram coladas acima para que o
parecer não dependa da permanência desse diretório. O fechamento formal da etapa e as
decisões de arquitetura continuam com o Owner.
