# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `9b4e3d0..9200b15` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
5f01f45 fix: publica o certificado numa transação, não remede tentativa fechada e retoma só job terminado
21b011f fix: a guarda da chave canônica passa a ser a gramática do PostgreSQL, no domínio do tipo declarado
685c735 fix: o oráculo aplica a precedência do catálogo sobre a entrada bruta
ef98574 fix: o seed grava o manifesto antes da carga, e não carrega se ele falhar
ab40918 feat: declara as colunas do certificado de captura com dicionário e sensibilidade
85b74f8 test: contraprovas do oráculo nos caminhos que protegem, sobre o lote num armazém efêmero
aa2ae57 docs: adia para a Etapa 13 a prova local da escrita BigQuery do certificado
57164ef docs: atribui a comparação integral do manifesto só à captura 28
3e8a4c6 docs: registra o parecer do Codex sobre a Etapa 10 e a situação dos doze achados
e1f0108 docs: registra ADR-0046 — validar a fase local por partes
9200b15 perf: materializa o CTE de limpeza do legado no PostgreSQL — ADR-0047
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 32 arquivos

- `README.md`
- `airflow/dags/fluxo_batch.py`
- `dbt/macros/chave_canonica.sql`
- `docker/preflight.sh`
- `docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md`
- `docs/adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md`
- `docs/adr/0046-validar-a-fase-local-por-partes.md`
- `docs/adr/0047-materializar-o-cte-de-limpeza-do-legado.md`
- `docs/adr/README.md`
- `docs/arquitetura.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/execucao_local.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/riscos.md`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/legacy/captura.py`
- `src/mvp_ed1/legacy/catalogo.yml`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/conteudo.py`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/mutacoes.py`
- `src/mvp_ed1/legacy/oraculo.py`
- `src/mvp_ed1/legacy/remocao.py`
- `src/mvp_ed1/legacy/writer.py`
- `tests/test_captura_legado.py`
- `tests/test_legado.py`
- `tests/test_legado_contraprovas.py`
- `tests/test_legado_deteccao.py`
- `tests/test_legado_oraculo.py`
- `tests/test_legado_remocao.py`

### Gerados — 44 arquivos, revisar por amostragem

- `REVISAO.md`
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
- `dbt/models/trusted/legacy/legacy_classifications.sql`
- `dbt/models/trusted/legacy/legacy_presence_by_capture.sql`

**Declaração desta entrega:** esta rodada responde aos doze achados RV10-01…12 do parecer de
15/09/2026 (o parecer inteiro e a coluna *Situação* de cada achado estão no *commit* `3e8a4c6`,
`git show 3e8a4c6:REVISAO.md`); duas decisões do Owner fechadas no caminho (ADR-0046, ADR-0047) entram
no mesmo intervalo. Revisão integral, nesta ordem:

| Arquivo | Por que é declaração |
|---|---|
| `src/mvp_ed1/legacy/captura.py` | RV10-01/02/03: `_publicar` (uma transação), `concluir` devolvendo o persistido, `retomar` com observador e `CARENCIA_SEM_JOB`. É o que os itens 4–5 do ADR-0044 passam a significar |
| `src/mvp_ed1/airbyte.py` + `airflow/dags/fluxo_batch.py` | Quem passa o observador (`estado_do_job`) à retomada — DAG e `sincronizar_certificando`. Sem observador a retomada não conclui nada |
| `dbt/macros/chave_canonica.sql` + `remocao.py::chave/canonizar` | RV10-04/05: a guarda **é** a gramática do `cast` (medida, não deduzida); o domínio vem do SQLAlchemy; o espelho em Python é o esperado do diário. Se a macro e `canonizar` divergirem, o teste da macro acusa |
| `src/mvp_ed1/legacy/oraculo.py` — bloco 1 de `esperar` | RV10-06: candidatos por coluna resolvidos pela ordem do catálogo, medidos na entrada. É semântica do contrato, não do SQL |
| `src/mvp_ed1/legacy/mutacoes.py::efeito_liquido` | RV10-10: o esperado do diário sai do `RETURNING`, canonizado |
| `src/mvp_ed1/legacy/cli.py` + `writer.py::exigir_destino` | RV10-07: a ordem destino → manifesto → COPY → hash |
| `src/mvp_ed1/legacy/dbt.py` | RV10-11 (`COLUNAS_DO_CERTIFICADO`) e ADR-0047 (`limpo as materialized` só no PostgreSQL) — os 44 gerados nascem daqui |
| `src/mvp_ed1/legacy/catalogo.yml` | `versao: 9` sem regra nova, e o cabeçalho que diz por quê (D34: a impressão moveu) |
| `tests/test_legado_contraprovas.py` | RV10-09: é a prova de que a comparação acusa — (a) oráculo mutado, (b) SQL compilado mutado, (c) recusa por hash. Revisar se as mutações são as que importam |
| `docs/adr/0046-*.md`, `docs/adr/0047-*.md` | Decisões do Owner; conferir alternativas, custo aceito e paridade |
| Notas datadas em ADR-0044 (itens 4–5; paridade) e ADR-0045 (item 1) | Retificações dentro de ADR aceito — conferir que não reescrevem a decisão |

**Derivado — amostragem basta.** Os 40 `stg_legacy__*` (a diferença é uma palavra por modelo),
`legacy_classifications` (versão e impressão), `legacy_presence_by_capture` (`inteiro` → `bigint`),
`_legacy__sources.yml` (15 colunas do certificado); os documentos (Plano, Execução Local, Capacidade
§2.8/§2.11, Riscos, Origem Legada, Arquitetura §5, Pendências, `docs/adr/README.md`, README)
decorrem das decisões acima; `docker/preflight.sh` só perdeu a exceção da Etapa 12 no texto.

**Onde eu olharia primeiro, se fosse revisar:** `captura.retomar` contra o ADR-0044 item 4 — a
carência de uma hora é heurística declarada, e "sem observador fica pendente" é uma escolha
conservadora que deixa tentativas `pending` acumularem se a DAG rodar sem credenciais do Airbyte.
Em segundo, a contraprova (b): as três mutações no SQL são textuais (rótulo, `btrim`, ramo
anulado); um revisor pode querer uma mutação de precedência.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
....................s.....................................s............. [ 32%]
....................................sss................sss.............. [ 64%]
........................................................................ [ 96%]
........                                                                 [100%]
216 passed, 8 skipped in 140.87s (0:02:20)
```

### `make dbt-build` ✓

```
19:01:14  890 of 891 START sql view model consumption.payment_approval_rate_by_method .... [RUN]
19:01:14  891 of 891 START sql view model consumption.refund_rate_by_reason .............. [RUN]
19:01:14  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['approval_rate_pct', 'authorized_amount', 'captured_amount']`
19:01:14  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['refunded_amount', 'captured_amount', 'refund_rate_pct']`
19:01:14  890 of 891 OK created sql view model consumption.payment_approval_rate_by_method  [CREATE VIEW in 0.17s]
19:01:14  891 of 891 OK created sql view model consumption.refund_rate_by_reason ......... [CREATE VIEW in 0.18s]
19:01:14
19:01:14  Finished running 1 incremental model, 3 seeds, 4 snapshots, 139 table models, 687 data tests, 5 unit tests, 52 view models in 0 hours 12 minutes and 15.54 seconds (735.54s).
19:01:16
19:01:16  Completed successfully
19:01:16
19:01:16  Done. PASS=891 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=891
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**1. A DAG não rodou depois da mudança na retomada.** `iniciar_captura_do_legado` passa
`airbyte.estado_do_job(airbyte.token())` quando há credenciais; o caminho foi exercitado só com
observador simulado (`lambda job_id: "running"/"succeeded"`) em banco efêmero. `make sync-legacy`
também não rodou nesta rodada.

**2. Interrupção de um *job* real do Airbyte continua não executada** — como na rodada anterior. A
prova de RV10-03 é: bruto parcial simulado + observador dizendo `running` → a retomada não fecha.

**3. A carência de uma hora não foi medida contra a janela real da DAG.** A janela entre a tarefa
`iniciar_captura_do_legado` e o `registrar_job` da tarefa de sincronização é de segundos a poucos
minutos nas execuções vistas; ninguém mediu o pior caso com o *pool* do Airflow ocupado.

**4. `make test FATO=1` e `CARGA=1` não rodaram.** O `make test` da §3 é o padrão; os 8 pulados são a
fato de trabalho, seis comparações de veredito contra o lote do manifesto (a captura selecionada 36
não é o lote — a prova sobre lote compatível é a do armazém efêmero em `test_legado_contraprovas`)
e o teste de reprocessamento.

**5. O comportamento do CTE `limpo` no BigQuery não foi medido** (ADR-0047 diz isso). A palavra
`materialized` só é emitida para `target.type == 'postgres'`; que o planejador do BigQuery não
embuta o CTE do mesmo modo é premissa.

**6. A quarentena com as auditorias v8 e v9 lado a lado foi medida uma vez**, no `make dbt-build` da
§3 (`PASS=891`, com `legacy_versao_do_tratamento_e_univoca` passando): `rejected_legacy_records`
tem 9.849 linhas sob a v8 (`8710ca3f…`) e 3.470 sob a v9 (`607e6288…`). Não conferi linha a linha
que as 3.470 da v9 são as mesmas rejeições da 36 sob a v8 — o `PASS=891` e a contraprova (b) dizem
que o tratamento é idêntico; a igualdade das duas auditorias não foi comparada diretamente.

**7. A limpeza compilada ganhou 10× medido em consulta isolada; o `dbt build` completo passou de
17 min (15/09, manhã) para 12 min 15 s** (§3) — mas os dois números não são comparáveis com rigor:
o de hoje rodou com o Airbyte pausado e o Airflow de pé, o anterior com o Airbyte pausado também,
e nenhum dos dois isolou o legado. O único número limpo é o do *staging* do legado em separado:
41 tabelas e 243 testes em 42,55 s, sem medição anterior desse recorte.

**8. Os seis testes de veredito por ocorrência continuam pulando na captura 36.** A prova sobre um
lote compatível com o manifesto é a do armazém efêmero (40 tabelas, 12.747 ocorrências, achado a
achado e valor a valor) — no nível de *staging*. Contexto e cascata no SQL real continuam medidos
só na captura 28 (rodada anterior).

**9. O teste da macro foi executado no `legacy_db`** (o PostgreSQL 16.15 instalado), não no
armazém — são o mesmo binário e a mesma imagem por *digest*, mas é premissa, não medição.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

**1. Que `CONCLUIDOS` de `mvp_ed1.airbyte` (`succeeded`, `failed`, `cancelled`, `incomplete`) é a
lista completa de estados terminais do Airbyte instalado.** A retomada só conclui nesses estados; um
estado terminal desconhecido deixaria a tentativa pendente para sempre — falha segura, mas falha.

**2. Que a gramática de entrada de `uuid` e `bigint` medida no PostgreSQL 16.15 é a mesma no
armazém e no legado**, e que não muda em versão menor. A guarda da macro e `canonizar` reproduzem
o que foi medido em 15/09/2026 com 39 formas; um PostgreSQL que aceitasse outra forma faria a macro
negar identidade a uma chave válida — o teste da macro acusaria, se rodasse contra esse banco.

**3. Que o `_airbyte_meta.sync_id` continua igual ao `jobId`** — a premissa 1 da rodada anterior,
intacta: nada aqui a remede.

**4. Que `CREATE INDEX` + `ANALYZE` nas tabelas do armazém efêmero reproduzem o plano que o armazém
de trabalho escolhe.** Sem estatísticas o planejador juntava por laço aninhado e a maior tabela
levava mais de três minutos; com elas, o plano é o mesmo *hash join* visto no armazém real. É o
que faz a medição de 47 s ser comparável — e é premissa.

**5. Que o token do Airbyte renovado por `observador()` vale para `GET /jobs/{id}`** como valia em
`acompanhar` — é o mesmo código movido, não código novo.

**6. Que a memória da máquina com o Airbyte pausado (~6,5 GB disponíveis no início) basta para o
`make dbt-build` completo.** Bastou; não foi medido o pico.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

**1. Carência de uma hora por idade, e não "nunca abandonar".** O Owner decidiu entre três
opções; eu recomendei a carência porque a janela real é de segundos a minutos. Mas é heurística, e
uma DAG que fique enfileirada mais de uma hora entre a fase 1 e a sincronização teria a tentativa
abandonada por baixo: a sincronização correria, `concluir` encontraria a tentativa já `abandoned`
e devolveria isso, e a DAG falharia na tarefa `concluir_captura_do_legado`. É o comportamento
certo — a captura não é certificada —, mas ninguém o exercitou.

**2. `versao: 9` sem regra nova.** A D34 diz que a impressão nova exige versão nova, e a impressão
hasheia o SQL gerado de propósito ("refatoração que não muda o resultado não muda a impressão" —
esta mudou o texto sem mudar o resultado, e a D34 não distingue). A alternativa era ensinar a
impressão a ignorar o que é do adaptador; o Owner preferiu a leitura literal, como no v8. O custo
é uma auditoria a mais na quarentena e o rótulo "v8" nas medições documentadas.

**3. Retirar o interruptor `LOTE=1` no mesmo *commit* em que ele deixou de ser necessário.** Ele
existiu por algumas horas (entre 85b74f8 e 9200b15); poderia ter ficado como opção. Com 47 s para
as 40 tabelas, um interruptor que só existe para pular 40 s era superfície sem função.

**4. UUID com espaço à volta deixa de ter identidade.** A macro anterior aparava; o `cast` do
PostgreSQL não. Segui a fronteira que o ADR-0045 declara ("os limites de conversão do PostgreSQL"),
e registrei a mudança de resultado em nota datada — nenhuma chave real do lote tem espaço à volta,
então a medição não move. Um revisor pode preferir que a chave textual seja aparada antes do
`cast`; seria contrato novo, não este.

**5. Provar (b) no nível de *staging*, e não da classificação inteira.** Foi a opção do Owner (sem
ambiente pesado). O que fica de fora — contexto e cascata sobre o lote compatível — continua coberto
só pela captura 28. Registro a dúvida: se a próxima rodada exigir a classificação completa sobre o
lote no armazém efêmero, o caminho é `dbt build --project-dir` de uma cópia, e custa minutos.

**6. Fechar D36 e D42 no mesmo intervalo da resposta à revisão.** As duas decisões nasceram nesta
sessão e o Owner as fechou; misturá-las com os doze achados aumenta o que o revisor precisa ler. A
alternativa — segurar os ADRs para outra rodada — deixaria o plano da Etapa 12 e o gerador
divergentes do que o Owner já decidiu.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |
