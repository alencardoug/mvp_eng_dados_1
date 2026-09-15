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

### Parecer do revisor — Codex, 15/09/2026, segunda rodada

**A entrega ainda não permite encerrar a Etapa 10: sete bloqueantes e três ajustes.** A suíte
passa, mas as sondas abaixo reproduzem falhas nas fronteiras de identidade, na concorrência das
fases e no esperado do diário. Identidade e efeito do diário são **declaração** no mapa desta
entrega; seus erros são bloqueantes conforme `CLAUDE.md` §5. Os ajustes são nas provas e na
propagação documental da decisão já tomada.

Foram conferidos o dossiê inteiro, o diff `9b4e3d0..9200b15`, as declarações da §2 e o parecer
com as situações em `git show 3e8a4c6:REVISAO.md`. A árvore observada estava em `2a78bcb`;
`git diff --name-only 9200b15 HEAD -- src tests dbt airflow docker` não produziu saída. Portanto,
o código exercitado é o do intervalo. A explicação adicional da impressão no ADR-0047, posterior
a `9200b15`, foi distinguida do texto naquele commit. Nenhuma decisão do Owner foi reaberta.

### Situação dos doze achados anteriores

**Encerrados:** RV10-01, RV10-04, RV10-06, RV10-07, RV10-11 e RV10-12.
**Não encerrados:** RV10-02, RV10-03, RV10-05, RV10-09 e RV10-10 — correções parciais.
**RV10-08:** encerrada a cobrança na fase local pelo adiamento autorizado; implementação e
provas continuam **não entregues**, previstas para a Etapa 13.

| Anterior | Conclusão desta rodada | Confronto com a situação declarada |
|---|---|---|
| RV10-01 | **Encerrado** | `_publicar` grava resultado e identidade das 40 linhas numa transação. A prova de interrupção depois de 25 comandos e recuperação passou (EV10-2-01). Os problemas de concorrência abaixo são outros mecanismos. |
| RV10-02 | **Não encerrado; parcial** | O reenvio sequencial de `complete` devolve o persistido sem remedir. Sob sobreposição, o retorno pode ser um certificado que não foi gravado; a associação a outro job também mistura identidades (EV10-2-02; RV10-2-02/03). |
| RV10-03 | **Não encerrado; parcial** | Observador e carência funcionam nos casos testados, e DAG/CLI passam o observador. Porém, o abandono usa uma lista que pode estar desatualizada e sobrescreve tentativa que já ganhou job ou terminou (EV10-2-02; RV10-2-01). A carência decidida pelo Owner não está sendo contestada. |
| RV10-04 | **Encerrado quanto à macro UUID apontada** | Chaves sem par são recusadas com nulo e a representação com hífens a cada quatro hexadecimais converte nos dois PostgreSQL consultados (EV10-2-03). O novo espelho Python tem defeito próprio, registrado em RV10-2-05. |
| RV10-05 | **Não encerrado; parcial** | O tipo declarado, `+8` e os limites usuais foram corrigidos. A guarda ainda admite textos que fazem a conversão intermediária falhar; o espelho Python também diverge (EV10-2-03; RV10-2-04/05). |
| RV10-06 | **Encerrado** | Os candidatos são resolvidos sobre a entrada bruta pela ordem do catálogo; a sobreposição literal de 21 para 24 caracteres passou. O esperado das 12.747 ocorrências continua igual ao manifesto (EV10-2-01/05). |
| RV10-07 | **Encerrado** | A ordem agora é destino → manifesto → carga; o teste passou tanto para destino recusado como para falha do manifesto antes da carga (EV10-2-01). Não foi feita carga no banco de trabalho. |
| RV10-08 | **Adiado; cobrança local encerrada** | Arquitetura §5 registra o módulo BigQuery e as provas de resposta parcial/retorno perdido na Etapa 13. A nota datada preserva a decisão de staging + `MERGE` do ADR-0044. Não se atribui implementação ou medição ao adiamento. |
| RV10-09 | **Não encerrado; parcial** | As três categorias de contraprova passaram nos caminhos novos, inclusive as 40 limpezas sobre lote compatível. O recorte de staging autorizado foi respeitado. Mas o comparador deixa passar corrupção fracionária de inteiro, e a mutação anunciada de precedência produz zero divergências sem reprovar (EV10-2-05; RV10-2-08/09). |
| RV10-10 | **Não encerrado; parcial** | Remoção parcial e alteração de zero linhas foram corrigidas. Alteração da própria PK ainda usa a chave anterior, e apagar uma representação textual declara ausência mesmo com outra ocorrência da mesma chave canônica presente (EV10-2-04; RV10-2-06/07). |
| RV10-11 | **Encerrado** | As 15 colunas coincidem com o DDL, têm descrição e `sensitivity: internal`, e aparecem no manifesto dbt produzido pelo teste de compilação (EV10-2-01/06). |
| RV10-12 | **Encerrado** | O plano atribui a comparação integral à captura 28. A nova leitura confirma 40/40 hashes nela e divergência em três tabelas nas capturas 35 e 36 (EV10-2-06). |

### Evidências produzidas nesta revisão

Os scripts `/tmp/rv10_2_*.py`, seus logs e os relatórios de teste são artefatos locais da revisão,
fora do repositório. As sondas próprias e a execução final da suíte usaram os bancos de trabalho
somente para leitura, com `default_transaction_read_only=on`; os scripts de leitura também executam literalmente
`set default_transaction_read_only = on`, encerram essa configuração e abrem a consulta em
transação somente leitura. Escritas de sondas ficaram em SQLite em memória ou em banco efêmero.
Os trechos a seguir são saídas literais; os identificadores fictícios 901–903 e 999 pertencem
exclusivamente à sonda em memória.

**EV10-2-01 — suíte padrão e alcance das provas.** Comando final:

```bash
PGOPTIONS='-c default_transaction_read_only=on' \
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=/tmp/rv10_2_guard \
PYTEST_ADDOPTS='-p no:cacheprovider -ra -o junit_family=xunit1 --junitxml=/tmp/rv10_2_pytest_final.xml' \
make test
```

A guarda temporária `sitecustomize.py` mantém as conexões de trabalho somente leitura e
encaminha exclusivamente `CREATE/DROP DATABASE` dos bancos de teste pelo banco administrativo
`postgres`. As conexões aos efêmeros podem escrever. `PGOPTIONS` cobre também os subprocessos
dbt; nenhum teste nem função de negócio foi substituído. Os caches de bytecode/pytest foram
desativados para evitar alterações em outros arquivos do repositório.

```text
....................s.....................................s............. [ 32%]
....................................sss................sss.............. [ 64%]
........................................................................ [ 96%]
........                                                                 [100%]
216 passed, 8 skipped in 158.91s (0:02:38)
```

Os oito pulados são carga, fato e seis comparações integrais que recusam a captura 36.
Exemplos literais do relatório:

```text
SKIPPED [1] tests/test_carga.py:51: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:751: a captura 36 não é o lote 3f9e5088c722 do manifesto (3 tabelas divergem: ['customers', 'inventory_movements', 'refunds']); sincronize o lote corrente antes de comparar vereditos
```

Leitura dos casos no XML dessa execução:

```text
test_a_retomada_nao_fecha_tentativa_com_job_em_curso_nem_sem_job_dentro_da_carencia PASS {}
test_reenviar_a_conclusao_devolve_o_certificado_gravado_sem_remedir_a_origem PASS {}
test_interrupcao_no_meio_da_publicacao_nao_deixa_nada_e_a_retomada_conclui PASS {}
test_a_source_do_certificado_declara_todas_as_colunas_do_ddl PASS {}
test_o_seed_grava_o_manifesto_antes_da_carga_e_nao_carrega_se_o_manifesto_falhar PASS {}
test_c_conteudo_diferente_com_as_mesmas_identidades_recusa_a_comparacao PASS {}
test_a_defeito_deliberado_no_oraculo_diverge_do_manifesto PASS {}
test_b_a_limpeza_compilada_concorda_com_o_oraculo PASS {'occurrences_compared': '12747', 'value_findings_compared': '93', 'recovered_values_compared': '44'}
test_b_defeito_deliberado_no_sql_compilado_e_acusado[customers-mutacao0-achados] PASS {}
test_b_defeito_deliberado_no_sql_compilado_e_acusado[customers-mutacao1-valor] PASS {}
test_b_defeito_deliberado_no_sql_compilado_e_acusado[orders-mutacao2-achados] PASS {}
test_a_precedencia_do_catalogo_vale_sobre_a_entrada_bruta PASS {}
```

Houve uma primeira execução também aprovada, cuja guarda de leitura cobria SQLAlchemy, mas não
impunha esse modo ao conector próprio dos subprocessos dbt. A repetição cobriu esse caminho por
`PGOPTIONS`; os quatro avisos da primeira eram de `record_property` com o
formato XML xunit2, trocado por xunit1 na execução final:

```text
216 passed, 8 skipped, 4 warnings in 174.96s (0:02:54)
```

**EV10-2-02 — sobreposição e associação do job, em memória.**
`.venv/bin/python /tmp/rv10_2_memoria.py` usa as funções reais de publicação, leitura,
associação e abandono, com 40 linhas por tentativa em SQLite. Só as medições de origem/bruto
são simuladas; `now()` e a leitura do timestamp recebem a adaptação necessária ao SQLite.
As interposições são determinísticas: executam o segundo chamador entre a leitura e a escrita
do primeiro, sem depender da sorte de agendamento de threads.

No abandono, A lê uma pendente sem job cuja carência já passou; B registra o job e conclui;
A usa sua lista antiga. Na conclusão concorrente, A mede `complete`, B mede a origem alterada
e grava `unstable`, e só então A tenta publicar. Por fim, a tentativa já certificada do
primeiro caso recebe outro `job_id` por `registrar_job` e é concluída novamente:

```text
REENVIO_SEQUENCIAL True [('complete', 901, 901, 40)]
CONCORRENCIA_ANTES_DO_ABANDONO complete [('complete', 902, 902, 40)]
CONCORRENCIA_DEPOIS_DO_ABANDONO {'abandono': 'abandonada'} [('abandoned', 902, 902, 40)] certificadas= [901]
CONCORRENCIA_CONCLUSAO_B unstable [('unstable', 903, 903, 40)]
CONCORRENCIA_CONCLUSAO_A complete 903 persistido= [('unstable', 903, 903, 40)]
JOB_REASSOCIADO status= complete job_id= 999 snapshot_id= 901 persistido= [('complete', 999, 901, 40)]
```

Estas são provas dos estados permitidos pelo código, **não** medições da frequência de
concorrência da DAG nem uma interrupção de job real.

**EV10-2-03 — macro real e espelho Python contra o cast instalado.**
`.venv/bin/python /tmp/rv10_2_leitura.py` executa a macro renderizada e o cast nativo em
transações independentes, para que uma conversão que falhe não contamine a próxima. Identificação
dos bancos e do modo de transação:

```text
AMBIENTE SOURCE_DB ('source_db', '16.15', 'en_US.utf8', 'on')
AMBIENTE LEGACY_DB ('legacy_db', '16.15', 'en_US.utf8', 'on')
AMBIENTE WAREHOUSE_DB ('warehouse_db', '16.15', 'en_US.utf8', 'on')
```

As formas foram executadas tanto no legado como no armazém, com os mesmos resultados. Trechos
do armazém; `ERRO` indica a exceção capturada pela sonda, seguida do SQLSTATE ou da classe Python:

```text
CHAVE WAREHOUSE_DB uuid 'a0ee-bc99-9c0b-4ef8-bb6d-6bb9-bd38-0a11' cast= 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' macro= 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' python= 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
CHAVE WAREHOUSE_DB uuid '{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' cast= 'ERRO 22P02' macro= None python= None
CHAVE WAREHOUSE_DB uuid 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}' cast= 'ERRO 22P02' macro= None python= None
CHAVE WAREHOUSE_DB uuid 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11\n' cast= 'ERRO 22P02' macro= None python= 'ERRO ValueError'
CHAVE WAREHOUSE_DB bigint '+8' cast= '8' macro= '8' python= '8'
CHAVE WAREHOUSE_DB bigint '9223372036854775808' cast= 'ERRO 22003' macro= None python= None
CHAVE WAREHOUSE_DB bigint '\u20038\u2003' cast= 'ERRO 22P02' macro= 'ERRO 22P02' python= '8'
CHAVE WAREHOUSE_DB bigint '\xa08\xa0' cast= 'ERRO 22P02' macro= None python= '8'
CHAVE WAREHOUSE_DB bigint 5001 caracteres; inicio='00000000'; fim='0008' cast= '8' macro= '8' python= 'ERRO ValueError'
CHAVE WAREHOUSE_DB bigint 131073 caracteres; inicio='99999999'; fim='9999' cast= 'ERRO 22003' macro= 'ERRO 22003' python= 'ERRO ValueError'
```

U+2003 é um espaço Unicode: casa com `\s` no regex instalado, mas não é aceito pelo cast
numérico. A outra falha SQL acontece antes da conferência do domínio, no próprio `::numeric`.
Não há limite de tamanho que exclua essas entradas nas colunas `text` do legado. A primeira
tentativa da sonda parou ao consultar `lc_ctype` como parâmetro de configuração; a identificação
acima foi obtida de `pg_database.datctype`, sem alteração no servidor.

**EV10-2-04 — diário produzido pelas mutações reais em PostgreSQL efêmero.**
`.venv/bin/python /tmp/rv10_2_diario.py` cria um banco `legacy_teste_rv10_2_*` pelo banco
administrativo, aplica `schema.ddl()` e usa `mutacoes.inserir/alterar/remover` com manifestos em
`/tmp`. O banco efêmero foi removido ao final. Nenhuma dessas operações usou `legacy_db`.

Primeiro, insere `id='1'` e altera a própria PK para `'2'`. Depois, num diário separado,
insere as representações `'8'` e `'08'` e remove só `'08'` por igualdade textual, como faz a CLI:

```text
ALTERACAO_PK_RETURNING [{'legacy_row_id': 1, 'valor': '2'}]
ALTERACAO_PK_ESTADO ['2'] efeito= {('brands', '1'): True}
REMOCAO_ALIAS_RETURNING ['08'] restantes_textuais= 0
REMOCAO_ALIAS_ESTADO ['8'] efeito= {('brands', '8'): False}
```

**EV10-2-05 — contraprovas adicionais e geração em memória.**
`.venv/bin/python /tmp/rv10_2_contrato.py` compara o oráculo atual ao manifesto durável,
aplica a mesma inversão de catálogo da contraprova (a) e reproduz sua asserção:

```text
ORACULO_VS_MANIFESTO 12747 divergencias= 0
MUTANTE_PRECEDENCIA divergencias= 0 asserção_atual_passa= True
```

Na prova de valor, executa somente `SELECT` sobre o bruto da captura 28, já reconhecida por
hash. Renderiza o modelo real de `purchase_order_items` e muda **só a projeção** da ocorrência
30: `quantity_ordered` passa a devolver `'244.9'` em vez de `'244'`. Usa `_obtido`, `_esperado`
e `_divergencias` do próprio arquivo de contraprovas, sem substituir o comparador:

```text
TRANSACAO_SQL_MUTADO on
SQL_INTEIRO_CORROMPIDO purchase_order_items 30 quantity_ordered esperado= '244' integro= '244' mutado= '244.9'
COMPARADOR_CONTRAPROVA divergencias_integro= [] divergencias_mutado= []
```

O mesmo script comparou os 43 derivados de código alterados no intervalo com seus geradores,
sem gravar arquivo: 40 limpezas, source, classificação e presença. Também renderizou o CTE
para os dois valores de `target.type`:

```text
GERACAO_EM_MEMORIA 43 arquivos; divergencias= []
IMPRESSAO 607e6288f4f57e39 versao= 9
CTE_RENDERIZADO postgres materialized= 40 /40
CTE_RENDERIZADO bigquery materialized= 0 /40
```

Essa última prova confirma a emissão condicional do ADR-0047; **não** é execução no BigQuery,
prova de portabilidade do restante do SQL ou nova medição do ganho de 10×.

**EV10-2-06 — estado retido, auditorias e catálogo.**
Saída de `/tmp/rv10_2_leitura.py`:

```text
CLASSIFICACAO [(36, 9, 12743)]
CERTIFICADOS [(28, 'complete', 40), (29, 'complete', 40), (30, 'complete', 40), (31, 'complete', 40), (32, 'complete', 40), (33, 'complete', 40), (34, 'complete', 39), (34, 'incomplete', 1), (35, 'complete', 40), (36, 'complete', 40)]
HASH_MANIFESTO 28 40/40 []
HASH_MANIFESTO 35 37/40 ['customers', 'inventory_movements', 'refunds']
HASH_MANIFESTO 36 37/40 ['customers', 'inventory_movements', 'refunds']
```

`/tmp/rv10_2_auditoria.py` comparou as auditorias v8/v9 da captura 36 por `EXCEPT ALL` nos
dois sentidos, excluindo **somente** `catalog_version` e `treatment_fingerprint` de cada linha.
A tupla é `(linhas_v8, linhas_v9, divergências)`. O mesmo script leu as propriedades do XML
e a source no manifesto dbt criado pelo teste de compilação:

```text
AUDITORIAS_CAPTURA_36 (3470, 3470, 0)
CONTRAPROVA_LOTE {'occurrences_compared': '12747', 'value_findings_compared': '93', 'recovered_values_compared': '44'}
SOURCE_NO_MANIFESTO_DBT 15 sem_descricao= [] sensibilidades= ['internal'] meta= {'domain': 'legado', 'owner': 'data_custodian'}
```

Isso resolve a comparação não executada da §4.6 deste dossiê, para a captura 36. A v9 já está
no armazém; o trecho do README que ainda diz que ela chegará no próximo build descreve o estado
anterior. Os números históricos permanecem históricos. Nenhum novo build foi executado pelo revisor.

**EV10-2-07 — orientações ainda contraditórias depois do ADR-0046.**
`sed -n '267,270p' docs/execucao_local.md`:

```text
**Recusa só resta quando a troca não basta:** memória insuficiente mesmo depois de pausar. Como em
`seed-data` e `reset`, `FORCE=1` autoriza — e é autorização do Owner, não atalho de quem esbarrou na
recusa. A execução completa da Etapa 12 é o caso em que ela se aplica, e não cabe nesta máquina com
o ambiente de trabalho aberto: pendência **D36**.
```

`sed -n '193,195p' docs/capacidade_e_recuperacao.md`:

```text
Tratamento, que é o do risco **R11**: os alvos do `Makefile` sobem apenas o subconjunto necessário à
etapa em curso. *Batch* e *streaming* não precisam estar no ar simultaneamente, exceto na validação
final da Etapa 12.
```

### Limites e decisões conferidas

O ADR-0046 tem alternativas, custo aceito e contrapartida de concorrência na Etapa 13; os
critérios do plano foram alterados nesse sentido. Falta completar a propagação documental
(RV10-2-10). O ADR-0047 está refletido no gerador, nos 40 modelos e na versão/impressão; a
igualdade das rejeições retidas da captura 36 foi medida acima. O desempenho anterior/posterior
e o custo no BigQuery não foram remedidos. As notas nos ADRs 0044/0045 preservam as decisões
anteriores e identificam a data da complementação.

Não foram executados `make dbt-build`, `make sync-legacy`, DAG, nova carga de trabalho,
`make test FATO=1` ou `CARGA=1`. Nenhum ambiente foi iniciado, pausado ou derrubado. Não foram
repetidos a sequência B–F, a interrupção de job real, o reprocessamento da fato nem a
classificação completa da captura 28. A prova sobre o lote efêmero cobre staging; contexto e
cascata no SQL completo continuam com a atribuição histórica declarada. Os novos casos
adversos demonstram possibilidade, não ocorrência no dado de trabalho. Validação técnica,
revisão da declaração e aceite do Owner continuam distintos. Só `REVISAO.md` foi alterado;
nenhum commit foi criado.

### Tabela de achados

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV10-2-01 | `src/mvp_ed1/legacy/captura.py:221`, `:344` | **O abandono pode revogar um certificado já publicado.** `_pendentes` é lido fora da transação de `_marcar`, e o UPDATE de abandono filtra só a tentativa. Se outro chamador registra o job ou conclui nesse intervalo, a retomada ainda escreve `abandoned` nas 40 linhas. EV10-2-02 reproduz `complete → abandoned` e a retirada da captura 902 das certificadas. Revalidar atomicamente `pending`, ausência de job e carência ao abandonar; testar a sobreposição entre leitura e escrita. | `bloqueante` | **Aberto.** RV10-03 parcialmente corrigido; a carência autorizada permanece válida. |
| RV10-2-02 | `src/mvp_ed1/legacy/captura.py:278`, `:302` | **Uma conclusão concorrente devolve um certificado que não foi persistido.** A guarda `status = 'pending'` protege a escrita vencedora, mas `_publicar` não informa se gravou e `concluir` devolve os vereditos calculados antes da disputa. EV10-2-02 obtém `complete/snapshot 903` com 40 linhas `unstable` no banco. O chamador recebe autorização para avançar incompatível com a fonte de elegibilidade. Devolver o resultado efetivamente persistido, inclusive quando outro chamador vence, e provar os dois sentidos da disputa. | `bloqueante` | **Aberto.** RV10-02 parcialmente corrigido; o reenvio sequencial passou. |
| RV10-2-03 | `src/mvp_ed1/legacy/captura.py:196`, `:260`; `airflow/dags/fluxo_batch.py:97` | **Reassociar uma tentativa fechada a outro job mistura duas capturas.** `registrar_job` sobrescreve qualquer tentativa; o novo retorno antecipado de `concluir` conserva o certificado antigo. Reexecutar a tarefa de sincronização com a mesma tentativa pode, assim, devolver `complete` para o novo job com o snapshot antigo. EV10-2-02 mede `job_id=999`, `snapshot_id=901`, `complete` nas 40 linhas. Tornar a associação idempotente para o mesmo job e impedir a troca de job numa tentativa já associada/fechada; a nova sincronização precisa de sua própria fase 1. | `bloqueante` | **Aberto.** Consequência da combinação do retorno novo com a associação sem guarda; impede encerrar a idempotência de RV10-02. |
| RV10-2-04 | `dbt/macros/chave_canonica.sql:52`, `:54` | **A guarda inteira ainda deixa entradas inválidas derrubarem o modelo.** `U+2003 + 8 + U+2003` passa pelo regex e lança `22P02` no `::numeric`; 131.073 dígitos lançam `22003` nessa conversão antes da conferência do domínio. Ambos deveriam produzir nulo, pois o cast ao tipo declarado os recusa (EV10-2-03). Fazer a guarda/conversão ser segura em todo o domínio textual, incluindo espaços Unicode e entradas extensas, e exercitar a macro real nos dois bancos. | `bloqueante` | **Aberto.** RV10-05 parcialmente corrigido; sinal e limites usuais passaram. |
| RV10-2-05 | `src/mvp_ed1/legacy/remocao.py:47`, `:88`, `:94` | **O espelho Python não reproduz a fronteira do PostgreSQL.** NBSP em volta de `8` vira identidade em Python e nulo na macro; UUID seguido de newline lança `ValueError` porque `match` com `$` aceita a quebra final; 5.000 zeros seguidos de `8` convertem no banco e lançam no `int` Python (EV10-2-03). A declaração do esperado do diário pode fabricar identidade ou interromper a prova. Validar a string inteira e o domínio antes da conversão, respeitando os espaços aceitos pelo cast e sem depender do limite de dígitos do interpretador. | `bloqueante` | **Aberto.** Defeito do espelho introduzido nesta resposta; RV10-04 está encerrado quanto à macro UUID original. |
| RV10-2-06 | `src/mvp_ed1/legacy/mutacoes.py:71`; `:195` | **Alterar a própria PK continua produzindo esperado com a chave antiga.** A CLI permite escolher a PK como coluna alterada e o `RETURNING` entrega seu novo valor, mas `efeito_liquido` usa `valor_da_chave`. No PostgreSQL efêmero, `id='1' → '2'` deixa somente `'2'` na origem e o esperado declara `'1'` presente (EV10-2-04). Derivar a identidade nova do retorno e contabilizar corretamente o efeito sobre a identidade anterior. | `bloqueante` | **Aberto.** RV10-10 parcialmente corrigido; alteração sem correspondência já não inventa presença. |
| RV10-2-07 | `src/mvp_ed1/legacy/mutacoes.py:66`, `:68` | **Apagar um alias textual não prova ausência da chave canônica.** Com ocorrências `'8'` e `'08'`, remover só `'08'` devolve uma linha e deixa `'8'` no banco; o esperado sobrescreve a chave canônica `8` como ausente. A confirmação pós-commit verifica as chaves textuais solicitadas, portanto seu zero não prova multiplicidade canônica zero (EV10-2-04). Calcular o efeito a partir das ocorrências efetivas e sua identidade canônica, preservando as sobreviventes; incluir redução sem remoção no teste do diário. | `bloqueante` | **Aberto.** RV10-10 parcialmente corrigido; a canonização nova não pode perder a multiplicidade do ADR-0045. |
| RV10-2-08 | `src/mvp_ed1/legacy/oraculo.py:493`; `tests/test_legado_contraprovas.py:251` | **O comparador de recuperação aceita inteiro corrompido em fração.** `int(Decimal(...))` trunca os dois lados. A projeção SQL mutada devolve `244.9` para o esperado `244`, e `_divergencias` continua vazio (EV10-2-05). O helper foi movido do teste antigo e passou a sustentar também a contraprova nova. Comparar o valor numérico sem truncamento e exigir integralidade; acrescentar esse mutante à prova sobre SQL executado. | `ajuste` | **Aberto.** Impede encerrar RV10-09 e limita a afirmação de conferência valor a valor. |
| RV10-2-09 | `tests/test_legado_contraprovas.py:182`, `:186` | **A contraprova anunciada de precedência aceita não detectar nada.** O lote usado não tem a sobreposição relevante: inverter o catálogo produz zero divergências, e `or divergencias == []` aprova exatamente isso (EV10-2-05). Cascata e origem da rejeição foram exercitadas, mas a afirmação de que a mutação de precedência divergiu não procede. Usar uma sobreposição que diferencie as ordens — como o caso de RV10-06 — e exigir a divergência correspondente. | `ajuste` | **Aberto.** Lacuna específica da resposta a RV10-09; a correção semântica de RV10-06 passou. |
| RV10-2-10 | `docs/execucao_local.md:269`; `docs/capacidade_e_recuperacao.md:169`, `:193`; `README.md:154` | **A propagação do ADR-0046 deixou a orientação antiga em vigor nos mesmos documentos.** Execução Local ainda apresenta a Etapa 12 como uso de `FORCE=1` e D36 como pendente; Capacidade mantém a exceção de simultaneidade na validação final, também mencionada no README (EV10-2-07). Essas instruções contradizem o critério novo e podem levar o operador ao cenário que o Owner retirou. Atualizar as orientações vigentes e referências, preservando números históricos e ADRs aceitos. | `ajuste` | **Aberto.** A decisão D36 está fechada; falta concluir sua propagação documental. |
