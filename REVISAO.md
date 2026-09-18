# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `b1a3975..5fe88b7` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
468d2fb fix: estatística fresca depois de cada tabela materializada
f8160de fix: o CTE de remessas não é materializado em fact_shipment_item
187a27b test: sentinela da identidade do vínculo pai entre limpeza e comparação de capturas
b36042e docs: fecha "medido e não explicado" das fatos lentas e anexa a identidade do vínculo à D43
9ac0e4e feat: o armazém grava o plano executado de toda instrução acima de 30 s
310c978 feat: make check — segredos, dbt build e pytest num comando, parando na primeira falha
be7f0fd test: cobertura de classificação medida coluna a coluna, como catraca por camada
a0a0767 feat: classificação de sensibilidade derivada dos modelos por linhagem do SQL compilado
f852eb5 feat: toda coluna das nove camadas classificada — 4.161 de 4.161
3cfb928 feat: retenção declarada por objeto e cobrada contra a política
2aa7019 feat: papéis de acesso criados e concessão declarada por camada, assumida e testada
8edbd20 feat: linhagem por coluna do consumo às fontes, derivada do SQL e publicada no dicionário
afb4be1 feat: reconciliação automática em todas as oito fronteiras, e o que ela achou
e5a9e99 docs: registra o re-snapshot do CDC que fechou os três estados da origem regenerada
e6d675f fix: testes de fronteira saem das tarefas por camada da DAG e rodam depois da última
5fe88b7 docs: fecha a Etapa 11 — definição de pronto aplicada, aguardando o aceite do Owner
```

A base é `b1a3975`, o último ponto **aceito** pelo Owner (bloco da D44, Etapa 10). A entrega a
revisar é a **Etapa 11** inteira: do `310c978` (`make check`) ao `5fe88b7` (fechamento). Os cinco
primeiros commits (`468d2fb`…`9ac0e4e`, 17/09) são anteriores à etapa — fecham o "medido e não
explicado" das fatos lentas (pendências §5) e anexam a identidade do vínculo à D43 — e entram
porque ninguém os revisou: mudam o `post-hook` de toda tabela (`analyze`), um CTE de
`fact_shipment_item` e a configuração do armazém (`auto_explain`). O que a etapa entregou está
resumido no item *Aceite da Etapa 11* de `docs/pendencias.md` §1, com a lista do que é
declaração e do que é derivado; abaixo, a mesma divisão sobre os arquivos do diff.

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 46 arquivos

- `Makefile`
- `README.md`
- `airflow/dags/fluxo_batch.py`
- `dbt/dbt_project.yml`
- `dbt/macros/analisar_apos_materializar.sql`
- `dbt/macros/aplicar_acesso_por_camada.sql`
- `dbt/macros/test_fato_reconcilia_com_a_condutora.sql`
- `dbt/models/analytics/_analytics__models.yml`
- `dbt/models/analytics/fact_shipment_item.sql`
- `dbt/models/consumption/_consumption__models.yml`
- `dbt/models/staging/_retail__models.yml`
- `dbt/models/staging/_retail__sources.yml`
- `dbt/models/trusted/legacy/_medidas__models.yml`
- `dbt/seeds/_seeds.yml`
- `dbt/tests/incremental_confere_com_a_reconstrucao_completa.sql`
- `dbt/tests/legado_na_fato_segue_a_captura_corrente.sql`
- `dbt/tests/saldo_da_view_confere_com_o_livro_distinto.sql`
- `docker/docker-compose.yml`
- `docs/adr/0011-classificacao-e-papeis-de-acesso.md`
- `docs/arquitetura.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/dicionario_de_dados.md`
- `docs/execucao_local.md`
- `docs/governanca_de_dados.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/qualidade_de_dados.md`
- `docs/riscos.md`
- `pyproject.toml`
- `src/mvp_ed1/governance.py`
- `src/mvp_ed1/legacy/classification.py`
- `src/mvp_ed1/legacy/dbt.py`
- `src/mvp_ed1/legacy/ponte.py`
- `src/mvp_ed1/legacy/remocao.py`
- `src/mvp_ed1/models/lineage.py`
- `src/mvp_ed1/models/sensitivity.py`
- `src/mvp_ed1/secrets_review.py`
- `tests/test_acesso.py`
- `tests/test_classificacao.py`
- `tests/test_classificacao_derivada.py`
- `tests/test_legacy_models.py`
- `tests/test_linhagem.py`
- `tests/test_reconciliacao_raw.py`
- `tests/test_retencao.py`
- `tests/test_secrets_review.py`
- `uv.lock`

### Gerados — 12 arquivos, revisar por amostragem

- `dbt/models/quarantine/_legacy__models.yml`
- `dbt/models/quarantine/_sensitivity.yml`
- `dbt/models/staging/_sensitivity.yml`
- `dbt/models/staging/legacy/_legacy__models.yml`
- `dbt/models/staging/legacy/_legacy__sources.yml`
- `dbt/models/staging/legacy/_sensitivity.yml`
- `dbt/models/trusted/_sensitivity.yml`
- `dbt/models/trusted/legacy/_legacy__models.yml`
- `dbt/models/trusted/legacy/_pontes__models.yml`
- `dbt/snapshots/_sensitivity.yml`
- `dbt/tests/legado_vinculo_nao_diverge_por_representacao.sql`
- `dbt/tests/retail_empilhado_reconcilia.sql`

**Declaração desta entrega** — revisão integral, na ordem em que uma coisa nasce da outra:

1. **Política e o que a cobra.** `dbt/dbt_project.yml` (`+grants`, `+meta.writers`, `+meta.retention`
   por camada, snapshots e seeds; o `on-run-end`), `dbt/models/staging/_retail__sources.yml` (o
   `meta` da fonte `raw` e o da tabela de aterrissagem — **atenção**: os `meta.sensitivity` de
   coluna nesse arquivo são derivados, escritos por `sensitivity.py`; a declaração é o `meta` da
   fonte e da tabela), `dbt/seeds/_seeds.yml` (seed é declaração), `tests/test_acesso.py`
   (`POLITICA`, `EXCECOES`), `tests/test_retencao.py` (`POLITICA`), `tests/test_classificacao.py`
   (os pisos), `src/mvp_ed1/governance.py` (`PAPEIS`, `_garantir_papeis`).
2. **As regras de derivação.** `src/mvp_ed1/models/sensitivity.py` (folhas por coluna; a regra do
   valor), `src/mvp_ed1/models/lineage.py` (fecho até a origem, `meta.lineage`, o que é publicado),
   `src/mvp_ed1/secrets_review.py`.
3. **Os geradores** — o que eles emitem é a declaração dos derivados: `src/mvp_ed1/legacy/dbt.py`
   (`writers`/`grants` das fontes legadas), `src/mvp_ed1/legacy/ponte.py` (`origens()` →
   `meta.lineage` de cada coluna da ponte; `teste_do_empilhamento_retail()`; a etiqueta
   `fronteira`), `src/mvp_ed1/legacy/classification.py` e `remocao.py` (commits de 17/09).
4. **As macros e os testes escritos.** `dbt/macros/aplicar_acesso_por_camada.sql` (grant/revoke a
   cada execução), `dbt/macros/test_fato_reconcilia_com_a_condutora.sql` (o genérico) e as **dez
   declarações** dele em `dbt/models/analytics/_analytics__models.yml` (condutora, medidas, a regra
   do carrinho), `dbt/macros/analisar_apos_materializar.sql`,
   `dbt/tests/saldo_da_view_confere_com_o_livro_distinto.sql`, `tests/test_reconciliacao_raw.py`,
   `tests/test_linhagem.py`, `tests/test_classificacao_derivada.py`.
5. **Orquestração e ambiente.** `airflow/dags/fluxo_batch.py` (`--exclude tag:fronteira` e a tarefa
   `dbt_fronteiras`), `Makefile` (`check`, `catalog`), `docker/docker-compose.yml` (`auto_explain`,
   `jit=off`), `dbt/models/analytics/fact_shipment_item.sql` (CTE `not materialized`).
6. **Documentos que fixam regra**: `docs/governanca_de_dados.md` §5.1, §6, §7 e §8 — a tabela da §7
   **mudou** para refletir ADR-0031 e ADR-0044 (a Governança §10 diz que isso pede decisão do
   Owner; está embutida no aceite) —, `docs/qualidade_de_dados.md` §7, `docs/execucao_local.md`
   §3.2 (nota do passo 5), `docs/dicionario_de_dados.md` §3 (o texto; o bloco marcado é gerado).

**Derivado — amostragem:** os `_sensitivity.yml`, `_pontes__models.yml` (457 colunas com `lineage`),
`_legacy__sources.yml`, os `_legacy__models.yml`, `dbt/tests/retail_empilhado_reconcilia.sql`,
`dbt/tests/legado_vinculo_nao_diverge_por_representacao.sql`, o bloco gerado da §3 do Dicionário
(§3.3: 188 colunas de consumo com origem) e os `meta.sensitivity` dentro dos `.yml` escritos à mão.
O que não é nem um nem outro — `README.md`, `docs/plano_de_desenvolvimento.md`, `docs/pendencias.md`,
`docs/riscos.md`, `docs/capacidade_e_recuperacao.md`, `docs/arquitetura.md`, o ADR-0011 — é registro
de estado: conferir se o que dizem tem medição na seção 3 ou está na seção 4.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
── 4/4 pytest: código, contratos e integração ──
..............................s......................................... [ 24%]
.....s...................................................sss............ [ 49%]
....sss................................................................. [ 74%]
........................................................................ [ 98%]
...                                                                      [100%]
283 passed, 8 skipped in 214.21s (0:03:34)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

A ferramenta guarda as 12 últimas linhas, e o veredito do `dbt build` (etapa 2) fica de fora.
As medições abaixo foram colhidas **ao montar este dossiê**, do mesmo ambiente, cada uma com o
comando que a produz — para o revisor repetir.

### `.venv/bin/python -c` sobre `dbt/target/run_results.json` — o build da etapa 2 do `make check` ✓

```
gerado em: 2026-09-18T07:02:45.759504Z | comando: build | tempo total: 93 s
status: {'success': 200, 'pass': 705}
por tipo: {'model:success': 192, 'operation:success': 1, 'seed:success': 3, 'snapshot:success': 4, 'test:pass': 700, 'unit_test:pass': 5}
testes de reconciliação no build: 22 todos com status {'pass'}
```

### `make dag-status` — a DAG `fluxo_batch` disparada no fechamento (18/09/2026 06:34 UTC) ✓

```
dag_id       logical_date    task_id                             state    start_date                        end_date
fluxo_batch                  dbt_seed                            success  2026-09-18T06:37:46.229764+00:00  2026-09-18T06:38:15.335620+
fluxo_batch                  concluir_captura_do_legado          success  2026-09-18T06:37:42.949513+00:00  2026-09-18T06:37:45.182133+
fluxo_batch                  dbt_staging                         success  2026-09-18T06:38:16.521600+00:00  2026-09-18T06:39:16.724346+
fluxo_batch                  dbt_quarantine                      success  2026-09-18T06:40:05.095498+00:00  2026-09-18T06:40:19.885253+
fluxo_batch                  dbt_fronteiras                      success  2026-09-18T06:41:17.177099+00:00  2026-09-18T06:41:30.351068+
fluxo_batch                  sincronizar_legado_para_raw_legacy  success  2026-09-18T06:34:12.601183+00:00  2026-09-18T06:37:41.994147+
fluxo_batch                  iniciar_captura_do_legado           success  2026-09-18T06:34:02.131898+00:00  2026-09-18T06:34:10.943267+
fluxo_batch                  dbt_docs                            success  2026-09-18T06:41:30.935720+00:00  2026-09-18T06:42:00.225660+
fluxo_batch                  dbt_trusted                         success  2026-09-18T06:39:17.245972+00:00  2026-09-18T06:40:04.465779+
fluxo_batch                  dbt_snapshots                       success  2026-09-18T06:40:21.050675+00:00  2026-09-18T06:40:32.273291+
fluxo_batch                  dbt_analytics                       success  2026-09-18T06:40:32.699702+00:00  2026-09-18T06:41:01.204156+
fluxo_batch                  dbt_consumption                     success  2026-09-18T06:41:01.898291+00:00  2026-09-18T06:41:16.014000+
fluxo_batch                  sincronizar_oltp_para_raw           success  2026-09-18T06:34:02.134155+00:00  2026-09-18T06:37:11.635609+
```

O log da tarefa `dbt_fronteiras` (lido no contêiner do Airflow durante o fechamento) terminou em
`Done. PASS=15 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=15` — 14 testes e o hook.

### `dbt ls` por seleção de tarefa da DAG — o que cada tarefa executaria ✓

```
--select staging --exclude tag:fronteira: 0 de fronteira em 375 testes
--select trusted --exclude tag:legado_reconciliacao tag:fronteira: 0 de fronteira em 64 testes
--select analytics --exclude tag:fronteira: 0 de fronteira em 213 testes
--select consumption --exclude tag:fronteira: 0 de fronteira em 1 testes
--select tag:fronteira: 14 de fronteira em 14 testes
```

("de fronteira" = `retail_empilhado`, `incremental_confere`, `legado_na_fato`, `saldo_da_view`,
`fato_reconcilia_com_a_condutora_*`.)

### `psql` no armazém — os dois caminhos do livro de estoque depois do *re-snapshot* (§3.2) ✓

```
chaves só no lote|0
chaves só no fluxo|0
chaves nos dois|13700
linhas com coluna de negócio diferente|0
pares armazém/SKU com saldo diferente|0
soma dos deltas no lote|701841
soma dos deltas no fluxo|701841
```

(`raw.inventory_movements` × `raw.inventory_movements_stream`, as 16 colunas de negócio de
`COLUNAS_DO_EVENTO` comparadas com `is distinct from`, `unit_cost` como `numeric`, `metadata` como
`jsonb`; a origem `oltp.inventory_movements` tem **13700** linhas.)

### `psql` no armazém — papéis e ACL dos nove schemas depois do `make check` ✓

```
analyst login=false super=false
auditor login=false super=false
ingestor login=false super=false
mvp_warehouse login=true super=true
streamer login=false super=false
transformer login=false super=false
analytics {mvp_warehouse=UC/mvp_warehouse,transformer=UC/mvp_warehouse}
consumption {mvp_warehouse=UC/mvp_warehouse,analyst=U/mvp_warehouse,transformer=UC/mvp_warehouse}
governance {mvp_warehouse=UC/mvp_warehouse,ingestor=UC/mvp_warehouse,transformer=U/mvp_warehouse,auditor=U/mvp_warehouse}
quarantine {mvp_warehouse=UC/mvp_warehouse,transformer=UC/mvp_warehouse,auditor=U/mvp_warehouse}
raw {mvp_warehouse=UC/mvp_warehouse,ingestor=UC/mvp_warehouse,streamer=UC/mvp_warehouse,transformer=U/mvp_warehouse}
raw_legacy {mvp_warehouse=UC/mvp_warehouse,ingestor=UC/mvp_warehouse,transformer=U/mvp_warehouse}
snapshots {mvp_warehouse=UC/mvp_warehouse,transformer=UC/mvp_warehouse}
staging {mvp_warehouse=UC/mvp_warehouse,transformer=UC/mvp_warehouse}
trusted {mvp_warehouse=UC/mvp_warehouse,transformer=UC/mvp_warehouse}
```

### Medido durante a etapa, com saída na sessão mas **não** repetido aqui

Estão nos documentos com data e número, e o revisor pode repetir cada um: as contraprovas do
acesso (grant à mão ao `analyst` em `trusted` acusado e revogado na execução seguinte; `insert` a
mais em `raw.customers` removido; `drop role auditor` refeito pelo `garantir()`; declaração fora da
política reprovada pelo teste); a contraprova da linhagem (edição à mão na §3 do Dicionário
reprovada pelo `--check`; sem `meta.lineage`, o maior conjunto de origens no consumo sobe de 12
para ≥ 400 — esta está **embutida** em `tests/test_linhagem.py`); a contraprova da view (+1 no
saldo publicado → 1.044 divergências); as migrações do zero nos três bancos (`make test-carga`:
`alembic upgrade head` + 3 testes; legado: 1 migração, 40 tabelas; armazém: `garantir()` aplicou
`0001` e `0002` num banco novo); e os três achados do fechamento das fronteiras (Qualidade §7).

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**Acesso por papel**

- Nenhum componente se conecta como membro de um papel: Airbyte, dbt, Beam e o certificado de
  captura continuam com o superusuário do `.env`. A prova é por `set role` a partir dele — os
  privilégios de um `LOGIN` membro do grupo (herança `INHERIT`) nunca foram exercitados, e não
  existe um login por papel para exercitar.
- O ramo BigQuery da macro (`target.type != 'postgres'` → devolve vazio) nunca executou.
- `+grants` só foi observado em objetos **recriados** a cada build; o caminho de `revoke` que o
  próprio dbt faz em relação já existente (`should_revoke`) não foi exercitado — a única
  incremental, `fact_inventory_movement`, nasce sem grant estranho.
- Grant a mais numa tabela de **modelo** dado a um papel **declarado** (ex.: `insert` em
  `trusted.orders` para `transformer`) só some no próximo build do modelo; a macro não zera objetos
  de modelo. Documentado no cabeçalho da macro, não medido.
- `on-run-end` em `dbt docs generate`: a tarefa `dbt_docs` da DAG passou, mas não conferi no log
  se o hook rodou nela. Em `dbt compile` observei que **não** roda.

**Linhagem**

- "2.983 de 2.983 colunas fecham numa origem" é contagem; a **correção** de cada origem foi
  conferida por nome em duas colunas de consumo (`net_revenue_amount`, `cost_of_goods_sold`) e
  por amostragem visual da §3.3. As outras camadas têm a linhagem calculada e não lida por ninguém.
- A regra do valor herdada de `sensitivity.py` (`case` decide o ramo e não entra no valor; `union`
  por posição) está provada em `test_classificacao_derivada.py`; para a linhagem, só o fecho e as
  declarações têm teste próprio.
- Payloads JSON fora das pontes continuam opacos: `legacy_classifications.findings` aponta para
  578 origens — correto, e inútil como registro. Não há caso de consumo afetado (máximo 12), mas
  é a fronteira do método.
- A frequência da travessia do Airbyte é lida da DAG por expressão regular (`schedule=`); se a
  linha mudar de forma, o texto vira `agenda ?` sem quebrar nada.

**Reconciliação**

- `oltp → raw`: o corte por `created_at`/`recorded_at ≤ max(_airbyte_extracted_at)` pressupõe
  que a origem só perde linha por regeneração. Uma exclusão física de verdade na origem faria o
  teste acusar "raw atrás da origem" — a mensagem é a do outro sentido. Por lote, só o `sync_id`
  não nulo é cobrado; a contagem por lote é registrada, não igualada.
- `fato_reconcilia_com_a_condutora` compara 1–3 medidas por fato, não todas;
  `fact_support_ticket_event` só a contagem.
- `saldo_da_view_confere_com_o_livro_distinto` só rodou com a parcela quente **vazia** (no build
  a fato absorve tudo). O caso que motiva o anti-join da view — delta em `raw` ainda fora da fato
  — nunca esteve presente durante um `make check` desta etapa. A contraprova foi artificial (+1).
- A falha falsa que motivou a etiqueta `fronteira` (tarefa `trusted` comparando com a fato
  **velha**) não foi reproduzida; a correção foi verificada por seleção (`dbt ls`) e por uma DAG
  em que nada mudou entre tarefas.
- A captura 43 foi certificada e selecionada; o que a comparação 39 → 43 detectou (remoções,
  inclusões) não foi inspecionado — os testes passaram, e é só isso que sei.
- `make sync-airbyte RESET=1` deixou os lotes antigos das tabelas `append` em `raw`
  (`payment_transactions`: lotes 1, 16, 19… mais o 41). Não investiguei por que o *reset* não os
  limpou; a reconciliação por identidade fecha apesar disso.

**Ambiente e operação**

- "Migrações do zero" foi provado em bancos novos do **mesmo** cluster; os papéis já existiam. Um
  cluster novo (Etapa 12) é o teste de verdade.
- O `make check` foi de 4 min 27 s (17/09) a 6 min 34 s; a decomposição (duas leituras do SQL
  pelo sqlglot ≈ 40 s, pytest +36 s, o resto carga da máquina com Airbyte e Airflow no ar) é
  estimativa, não medição isolada.
- O DAG rodou uma vez com `dbt_fronteiras`; nunca com o streaming de pé ao mesmo tempo (R11), e
  isso é de propósito (ADR-0046).
- Links e âncoras dos documentos foram conferidos a olho, não por ferramenta.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **PostgreSQL 16, `SET ROLE`:** a verificação de privilégio passa a ser a do papel assumido,
  inclusive para o superusuário que o assume. Confirmado só de forma indireta — os 1.390 vereditos
  de `test_acesso.py` batem com a política —, não por leitura de documentação nesta entrega.
- **`ALL TABLES IN SCHEMA`** cobre views (o `revoke` da macro conta com isso). Não conferido.
- **`pg_roles` sem login e sem prefixo `pg_` = os nossos papéis.** Qualquer grupo criado por fora
  entra no `revoke` da macro e reprova `test_os_papeis_existem…`. Intencional, e não testado com
  um grupo estranho.
- **dbt 1.12 / dbt-postgres 1.11:** `+grants` substitui a lista da camada acima por chave
  (`clobber`), e `+select` acrescentaria; o hook `on-run-end` recebe uma string com vários
  comandos separados por `; ` e o psycopg2 os executa numa chamada; hook em branco é ignorado.
  Os dois primeiros foram observados; o terceiro vem do `post-hook` já existente e nunca foi
  exercitado na macro nova.
- **Seleção indireta `eager`** é o padrão da versão instalada e `--exclude a b` é união —
  observado por `dbt ls`, não por documentação.
- **Airbyte (destino v2):** `_airbyte_meta->>'sync_id'` existe em toda linha e identifica o *job*;
  `full_refresh_overwrite` recria a tabela (e apaga grants); `reset` "descarta o estado e o dado
  em `raw`" — **esta se mostrou parcial** para as tabelas `append` (lotes antigos ficaram).
- **Dados sintéticos:** `created_at`/`recorded_at` da simulação ficam antes do relógio real da
  extração (`as_of_date` 2026-09-01 < 18/09). O corte de `test_reconciliacao_raw.py` depende
  dessa ordem; com um `as_of_date` no futuro ele deixaria de separar linhas novas.
- **sqlglot** (dependência de 17/09) parseia e qualifica os 199 modelos compilados hoje; um
  construto novo que ele não entenda vira `problema` e derruba o `make check` na etapa 3 — é o
  comportamento desejado, mas é uma dependência de parser que a base não tinha.
- **Airflow 3 no contêiner:** a DAG nova foi registrada sem erro de importação e rodou; a leitura
  do log da tarefa foi por `grep` no arquivo dentro do contêiner, não pela interface.
- **Memória:** o preflight pausou o Airbyte para subir o streaming e o retomou; a máquina tinha
  3,4 GB livres antes e 7,3 GB depois da pausa (saída do preflight). Não medi o pico durante o
  snapshot do Beam.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Papéis em `governance.garantir()`, não no `init` do contêiner** (o Owner escolheu a opção com
  o `init`). O `init` só roda com o volume vazio, e o armazém já povoado nunca os receberia; um
  `garantir` idempotente vale para o ambiente novo e para o existente. Desvio explicado ao Owner.
- **Grupos sem login + `set role`, em vez de um login por papel.** Sem senha nova no `.env` e igual
  ao desenho da fase GCP (grupo IAM); o custo é a prova indireta da seção 4.
- **Lista completa de leitores por camada (`select: [analyst, transformer]`) em vez de `+select`.**
  Menos esperto, mais legível: quem lê o `dbt_project.yml` vê a tabela do §7 inteira.
- **Grant de fonte por tabela declarada, não `on all tables in schema`.** Declarado = concedido;
  tabela em `raw` que ninguém declara não recebe nada. O custo é uma linha por tabela no hook.
- **A macro revoga o que não está declarado.** A alternativa (só conceder) deixaria um grant dado
  à mão viver para sempre; a convergência exige o universo de papéis, que vem de `pg_roles`.
- **`meta.lineage` gerado pela ponte, em vez de ensinar o motor a ler chave de JSON e podar ramos
  do `union` pelo `source_table`.** A segunda mudaria a classificação derivada de algumas colunas
  sem ninguém decidir (os payloads são `personal` por regra escrita na §5.1); a primeira mantém a
  classificação intacta e usa o mesmo padrão do `sensitivity_reason`.
- **Só o consumo é publicado coluna a coluna.** As outras 2.800 colunas mudariam a cada modelo e
  ninguém as leria (R14); `--all` as imprime.
- **`count(*)` rotulado "gerada".** É a regra do motor (sem folha); o texto da §3 explica. Uma
  marca própria ("contagem") seria mais fiel e é uma linha no motor.
- **`oltp → raw` por identidade no instante da extração.** Contar linhas não fecha por
  construção (ao menos uma vez); o corte é o que evita acusar latência como defeito (§6.1).
- **Teste genérico declarado no `.yml` para as fatos, em vez de dez singulares gerados.** A
  declaração fica ao lado da fato e do `unique` do grão; o preço foi a chave `data_tests`
  duplicada que precisei fundir e o `arguments:` que o dbt novo pede.
- **O teste da view reproduz o filtro da view** (ponto de reposição, reservado) porque a view não
  expõe `source_system` e o par (armazém, SKU) existe nas duas origens. Acrescentar a coluna ao
  contrato de consumo seria mais limpo — e é decisão sua, não minha. Fica como acoplamento.
- **Executei `make sync-airbyte RESET=1` sem perguntar** (remédio documentado no próprio Makefile,
  réplica descartável) e o procedimento da Execução Local §3.2 **com o seu OK**.
- **`--full-refresh` só da fato incremental, em vez de `RESET=1`.** O `RESET=1` destruiria o
  histórico SCD, que não mudou (regeneração determinística); ficou como nota medida no §3.2.
- **Etiqueta `fronteira` + tarefa própria, em vez de `--indirect-selection cautious` em todas as
  tarefas.** `cautious` faria os testes entre camadas nunca rodarem na DAG; a etiqueta é
  explícita e é o padrão que `legado_reconciliacao` já usava.
- **`comandos.txt` passou a `make check`** (englobava `make test` e `make dbt-build`). A ferramenta
  guarda 12 linhas e perde o veredito do dbt — por isso o resumo do `run_results.json` na seção 3.
- **Base deste dossiê em `b1a3975`**, o último ponto aceito, e não em `origin/main` (`3cfb928`, o
  meio da etapa): a revisão é da etapa inteira, com os cinco commits das fatos lentas junto.
- **A tabela da Governança §7 mudou sem ADR novo.** Reflete ADR-0031 e ADR-0044, já aceitos; a §10
  diz que alteração na política pede a decisão do Owner, e ela está embutida no aceite da etapa.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

