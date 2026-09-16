# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `1ae2f53..7faad24` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
9db0a43 fix: abandono e associação do job com guarda na escrita, e conclusão devolve o gravado
699d74c fix: a guarda inteira e o espelho Python reproduzem a fronteira do cast em toda entrada textual
15a21c1 fix: o diário grava a multiplicidade canônica depois do commit, e o efeito sai dela
58fe693 test: o comparador exige inteiro sem truncar e a contraprova de precedência usa sobreposição real
ac4fa2f docs: conclui a propagação do ADR-0046 e registra a v9 no armazém
7faad24 docs: registra a situação dos dez achados da segunda rodada
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 13 arquivos

- `README.md`
- `airflow/dags/fluxo_batch.py`
- `dbt/macros/chave_canonica.sql`
- `docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/execucao_local.md`
- `src/mvp_ed1/legacy/captura.py`
- `src/mvp_ed1/legacy/mutacoes.py`
- `src/mvp_ed1/legacy/oraculo.py`
- `src/mvp_ed1/legacy/remocao.py`
- `tests/test_captura_legado.py`
- `tests/test_legado_contraprovas.py`
- `tests/test_legado_remocao.py`

### Gerados — 1 arquivos, revisar por amostragem

- `REVISAO.md`

**Declaração desta entrega:** responde aos dez achados RV10-2-01…10 do segundo parecer (parecer
e coluna *Situação* no *commit* `7faad24`, `git show 7faad24:REVISAO.md`). Revisão integral,
nesta ordem:

| Arquivo | Por que é declaração |
|---|---|
| `src/mvp_ed1/legacy/captura.py` — `_abandonar`, `registrar_job`, `_gravado` | RV10-2-01/02/03: a condição do abandono e da associação está **no `UPDATE`**, não na lista lida antes; `concluir` devolve o que ficou gravado. É o que os itens 4–5 do ADR-0044 significam sob concorrência |
| `dbt/macros/chave_canonica.sql` — ramo inteiro | RV10-2-04: brancos ASCII do `isspace`, zeros à esquerda fora antes de converter, `::numeric` só sobre ≤ 19 dígitos significativos. Conferir que é a gramática do cast, e não mais estreita |
| `src/mvp_ed1/legacy/remocao.py` — `_INTEIRO`, `_UUID`, `canonizar` | RV10-2-05: o espelho, com `\Z` e sem `\s`; o teste da macro compara os dois ao cast em todas as formas |
| `src/mvp_ed1/legacy/mutacoes.py` — `_presenca_canonica`, `efeito_liquido` | RV10-2-06/07: o diário grava a multiplicidade canônica pós-commit das chaves tocadas, e o esperado sai dela; as 16 entradas antigas continuam pelo `RETURNING` canonizado |
| `src/mvp_ed1/legacy/oraculo.py::mesmo_valor` | RV10-2-08: igualdade numérica **e** integralidade para inteiro |
| `tests/test_legado_contraprovas.py` — `_lote_com_sobreposicao`, mutante `|| '.9'` | RV10-2-09/08: a contraprova de precedência exige divergência num lote que distingue as ordens; o mutante fracionário roda no SQL executado |
| Nota no ADR-0044 (itens 4–5, segunda rodada) | Retificação dentro de ADR aceito |

**Derivado — amostragem basta.** Os testes novos de `test_captura_legado.py` (sobreposição
interposta em `medir_origem` e `_pendentes`) e de `test_legado_remocao.py` (formas do parecer, dois
bancos); a docstring da DAG; Execução Local §5, Capacidade §2.4/§2.5/§2.8 e README (propagação do
ADR-0046 e v9 no armazém). Nenhum modelo dbt gerado mudou: a macro é lida no *build*, e o recorte
`legacy_presence_by_capture+` foi reconstruído com o mesmo resultado.

**Onde eu olharia primeiro, se fosse revisar:** `_presenca_canonica` lê a coluna da PK **inteira**
a cada mutação e canoniza em Python — correto e barato nas tabelas do legado (≤ 5.500 linhas), mas
é uma leitura que cresce com a tabela; e `efeito_liquido` com duas leituras (com e sem
`presenca_apos_commit`) é o tipo de bifurcação que envelhece — vale perguntar se o diário de
produção deveria ser regravado com o campo.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
.......................s.....................................s.......... [ 31%]
........................................sss................sss.......... [ 62%]
........................................................................ [ 93%]
................                                                         [100%]
224 passed, 8 skipped in 165.50s (0:02:45)
```

### `make dbt-build` ✓

```
23:24:24  890 of 891 START sql view model consumption.payment_approval_rate_by_method .... [RUN]
23:24:24  891 of 891 START sql view model consumption.refund_rate_by_reason .............. [RUN]
23:24:24  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['approval_rate_pct', 'authorized_amount', 'captured_amount']`
23:24:24  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['refunded_amount', 'captured_amount', 'refund_rate_pct']`
23:24:24  890 of 891 OK created sql view model consumption.payment_approval_rate_by_method  [CREATE VIEW in 0.20s]
23:24:24  891 of 891 OK created sql view model consumption.refund_rate_by_reason ......... [CREATE VIEW in 0.20s]
23:24:24
23:24:24  Finished running 1 incremental model, 3 seeds, 4 snapshots, 139 table models, 687 data tests, 5 unit tests, 52 view models in 0 hours 12 minutes and 57.93 seconds (777.93s).
23:24:26
23:24:26  Completed successfully
23:24:26
23:24:26  Done. PASS=891 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=891
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**1. A DAG não rodou com a guarda nova de `registrar_job`.** `TentativaIndisponivel` só foi
exercitada em banco efêmero; a tarefa `sincronizar` da DAG a propaga como falha, e ninguém viu isso
no Airflow.

**2. As disputas foram provadas com o segundo chamador interposto dentro de `medir_origem` do
primeiro** — determinístico, mas não é concorrência real de dois processos com transações abertas
ao mesmo tempo. Que o `UPDATE` com guarda espere o *lock* de linha e reavalie o `WHERE` é
comportamento do PostgreSQL que não foi medido aqui, só assumido (premissa 1).

**3. `make dbt-build` completo rodou (§3, `PASS=891`, 12 min 58 s), mas nada nele exercita as
entradas adversas da macro** — as 40 PKs do bruto são inteiros e UUIDs limpos. A fronteira só é
medida pelo teste da macro renderizada, nos dois bancos.

**4. O diário de produção (16 entradas) não tem `presenca_apos_commit`.** O teste de integração do
ciclo real passou com a leitura antiga; a leitura nova só foi exercitada em banco efêmero e no
teste unitário. Não regravei o diário.

**5. `FATO=1`, `CARGA=1`, `make sync-legacy`, interrupção de *job* real, sequência B–F:** como nas
rodadas anteriores, não repetidos.

**6. A contraprova (b) continua no nível de *staging*.** Contexto e cascata no SQL completo seguem
atribuídos à captura 28 (rodada anterior).

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

**1. Que `UPDATE … WHERE status = 'pending' …` sob duas transações concorrentes faz a segunda
esperar o *lock* e reavaliar a condição** — é o comportamento documentado do PostgreSQL em
`READ COMMITTED`, e é o que torna a guarda na escrita suficiente. Não foi medido com dois processos.

**2. Que `isspace` do cast de inteiro aceita exatamente espaço, TAB, LF, VT, FF e CR** — medido em
15/09/2026 nos dois bancos (16.15) para as seis formas; não conferido no código-fonte do PostgreSQL.

**3. Que o `numeric` aceita até 131.072 dígitos e estoura acima** — a guarda deixou de depender
disso (só ≤ 19 dígitos chegam ao `::numeric`), então a premissa virou irrelevante para a macro.

**4. Que as tabelas do legado continuam pequenas o bastante para `_presenca_canonica` ler a PK
inteira** — 5.500 linhas na maior, hoje.

**5. Que `Decimal(obtido).to_integral_value()` é a definição certa de "inteiro"** — `244.0` passa
como recuperação de `244`; `244.9` não. Foi a leitura do achado; um revisor pode querer que
`244.0` também seja recusado.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

**1. Devolver `_gravado` sempre, em vez de só quando a publicação perdeu.** Custa uma leitura a
mais por conclusão; a alternativa era `_publicar` devolver `rowcount` e só reler no empate. Preferi
a forma em que o retorno **nunca** pode divergir do banco, mesmo que um caso novo apareça.

**2. `registrar_job` idempotente também depois de fechada.** O parecer pedia "idempotente para o
mesmo job"; interpretei que vale antes e depois da fase 2 — reexecutar a tarefa de sincronização
com o mesmo job não deve falhar. Outro job, sempre recusado.

**3. Manter as duas leituras em `efeito_liquido`** (com e sem `presenca_apos_commit`) em vez de
regravar o diário de produção com o campo. Regravar exigiria reler a origem de hoje para dizer o
que restou depois de cada mutação de ontem — e a origem de hoje não é a de ontem. As entradas
antigas ficam com a leitura que tinham; as novas têm a melhor.

**4. `\Z` no Python contra `$` no ARE.** São dialetos: o `$` do PostgreSQL já não aceita `\n`
final; o do Python aceita. Registrei no comentário para que ninguém "harmonize" para `$`.

**5. Não regravar o comparador para rejeitar `244.0`.** Igualdade numérica + integralidade foi o
que o achado pediu; exigir texto idêntico invalidaria recuperações legítimas de coluna numérica
que o SQL entrega com escala.

---

## Achados da revisão

### Parecer do revisor — Codex, 16/09/2026, terceira rodada

**Devolver ao desenvolvimento: dois bloqueantes e dois ajustes.** Revisado o intervalo
`1ae2f53..7faad24`, com o dossiê publicado em `108a283`. A árvore estava limpa ao início.
As guardas de concorrência foram confirmadas também com transações simultâneas; a fronteira
da identidade inteira ainda não cumpre o ADR-0045, e a escrita nova do diário introduz um
esperado falso quando a alteração não encontra linha. O parecer não encerra a Etapa 10 nem
substitui a revisão do declarativo e o aceite do Owner.

### Situação dos dez achados anteriores

| Achados | Resultado desta rodada |
|---|---|
| RV10-2-01/02/03 — abandono, retorno da conclusão e associação do job | **Correções confirmadas.** Além dos testes da entrega, EV10-3-02 observou a segunda transação esperando o lock: a associação impede o abandono e a troca de job; conclusões concorrentes devolvem o certificado vencedor nos dois sentidos. |
| RV10-2-04/05 — fronteira da macro e do espelho Python | **Parciais.** Os exemplos anteriores passam, mas notação hexadecimal, binária, octal e separadores aceitos pelo PostgreSQL continuam perdendo identidade nos dois lados. RV10-3-01 demonstra remoção falsa com reconciliação e comparação do diário passando. O novo regex também introduz a regressão de RV10-3-03. |
| RV10-2-06/07 — troca da PK e sobrevivência de alias | **Mecanismo confirmado nos casos anteriores**, com ressalvas novas: alteração sem correspondência fabrica testemunha de ausência (RV10-3-02), e o teste que consome o diário rejeita uma redução correta (RV10-3-04). |
| RV10-2-08 — comparação de recuperação inteira | **Correção confirmada.** Igualdade numérica com integralidade preserva `244.0 = 244` e recusa `244.9`; o teste com a projeção SQL mutada passou na suíte desta revisão. Não há motivo, no contrato atual, para exigir identidade textual. |
| RV10-2-09 — contraprova de precedência | **Correção confirmada.** O caso de sobreposição exige divergência de classificação e achados; a alternativa que aceitava divergência vazia saiu. Teste executado em EV10-3-01. |
| RV10-2-10 — propagação do ADR-0046 | **Correção confirmada por leitura.** As orientações alteradas em README, Execução Local e Capacidade dizem que a validação local é por partes, em acordo com o plano e o risco R11. As medições históricas permanecem identificadas como históricas. |

### Evidências produzidas nesta revisão

As sondas adicionais foram escritas em `/tmp/mvp_ed1-revisao3-*.py`; suas saídas estão nos
arquivos `.log` de mesmo nome. São auxiliares temporários, não arquivos do projeto.
Carregaram o ambiente local sem imprimir credenciais. As escritas das sondas ocorreram em
bancos efêmeros, criados e removidos pelas fixtures existentes; os ciclos abaixo usam a cópia
de origem para bruto de `tests/test_captura_legado.py`, não uma sincronização real do Airbyte.

**EV10-3-01 — suíte existente.** Comando: `make test`, sem `FATO=1` nem `CARGA=1`.
Saída literal final, em `/tmp/mvp_ed1-revisao3-tests.log`:

```text
.......................s.....................................s.......... [ 31%]
........................................sss................sss.......... [ 62%]
........................................................................ [ 93%]
................                                                         [100%]
224 passed, 8 skipped in 152.14s (0:02:32)
```

**EV10-3-02 — concorrência real das transações.** Comando:
`.venv/bin/python /tmp/mvp_ed1-revisao3-concorrencia.py`.
Dois chamadores em threads, com conexões e backends distintos. A primeira transação é
interrompida pela sonda depois do `UPDATE`, antes do commit; a segunda só é liberada depois
de `pg_stat_activity` mostrar `wait_event_type = 'Lock'`. `registrar_job`, `_abandonar` e
`concluir` são as funções reais. As conclusões medem estados diferentes da origem, como nos
testes interpostos da entrega, mas disputam a escrita simultaneamente. Saída literal dos casos:

```json
{"scenario": "registrar_job_vence_abandono", "lock_observed": true, "abandoned": false, "saved_status": "pending", "saved_job": 840}
{"scenario": "disputa_de_jobs", "lock_observed": true, "loser": "TentativaIndisponivel", "saved_job": 841}
{"scenario": "concluir_complete_vence", "lock_observed": true, "winner_status": "complete", "loser_status": "complete", "certified": [843]}
{"scenario": "concluir_unstable_vence", "lock_observed": true, "winner_status": "unstable", "loser_status": "unstable", "certified": []}
```

**EV10-3-03 — gramática nativa e efeito entre capturas.** Comandos:
`.venv/bin/python /tmp/mvp_ed1-revisao3-fronteira.py` e
`.venv/bin/python /tmp/mvp_ed1-revisao3-ciclos.py`.
Consultado `version()` nos dois bancos; ambos devolveram literalmente:

```text
PostgreSQL 16.15 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
```

A primeira sonda compara o cast nativo, a macro renderizada do arquivo vigente e
`remocao.canonizar`, em consultas somente de leitura. Recorte literal; as mesmas divergências
foram obtidas no legado e nos tipos `integer` e `smallint`:

```json
{"db": "WAREHOUSE_DB", "type": "bigint", "input": "0x8", "cast": "8", "macro": null, "python": null, "matches": false}
{"db": "WAREHOUSE_DB", "type": "bigint", "input": "0b1000", "cast": "8", "macro": null, "python": null, "matches": false}
{"db": "WAREHOUSE_DB", "type": "bigint", "input": "0o10", "cast": "8", "macro": null, "python": null, "matches": false}
{"db": "WAREHOUSE_DB", "type": "bigint", "input": "1_000", "cast": "1000", "macro": null, "python": null, "matches": false}
```

A segunda sonda certifica duas capturas por `iniciar` → `registrar_job` → `concluir`, troca
somente `brands.id = '8'` por `'0x8'` entre elas e executa o SQL renderizado das declarações de
seleção, presença, transições, memória e reconciliação física. Depois chama o teste existente
que compara o diário com os modelos. A identidade nativa é a mesma, mas o resultado declara
remoção — e os dois verificadores concordam com o erro:

```json
{"scenario": "alias_hexadecimal"}
{"returned": [{"legacy_row_id": 1, "valor": "0x8"}], "post_commit_presence": {"8": 0}}
{"physical_reconciliation_failures": 0, "transitions": [["8", 1, 0, "removida"], [null, 0, 1, "sem_identidade"]], "memory": [["brands", "8"]]}
{"net_effect": [["brands", "8", false]]}
{"existing_diary_test": "PASS"}
```

**EV10-3-04 — alteração sem linha e redução canônica.** Mesmo comando dos ciclos,
com bancos efêmeros próprios para cada caso. As duas capturas de cada caso foram certificadas;
as falhas abaixo vêm da execução do teste existente sobre os modelos renderizados, não de
um comparador reimplementado pela sonda.

No primeiro caso, `alterar(..., 'brands', '777', 'name', 'Nada')` não encontra linha nem muda
conteúdo. Mesmo assim, o diário exige memória de remoção de uma chave que nunca existiu:

```json
{"scenario": "alteracao_sem_linha"}
{"returned": [], "post_commit_presence": {"777": 0}}
{"physical_reconciliation_failures": 0, "transitions": [["8", 1, 1, "mantida"]], "memory": []}
{"net_effect": [["brands", "777", false]]}
{"existing_diary_test": "FAIL", "detail": "efeito líquido do diário sem correspondência: [('ausente e fora da memória', 'brands', '777')]"}
```

No segundo, existem `'8'` e `'08'` na primeira captura; remove-se somente `'08'` antes da
segunda. O diário novo e os modelos estão corretos, mas o teste rejeita `reduzida`:

```json
{"scenario": "reducao_canonica"}
{"returned": [{"legacy_row_id": 2, "id": "08", "code": "b08", "name": "Oito", "country": null, "is_active": null, "created_at": null, "updated_at": null, "deleted_at": null}], "post_commit_presence": {"8": 1}}
{"physical_reconciliation_failures": 0, "transitions": [["8", 2, 1, "reduzida"]], "memory": []}
{"net_effect": [["brands", "8", true]]}
{"existing_diary_test": "FAIL", "detail": "efeito líquido do diário sem correspondência: [('presente com transição estranha', 'brands', '8', 'reduzida')]"}
```

**EV10-3-05 — regressão do regex em entrada inválida longa.** Comando:
`.venv/bin/python /tmp/mvp_ed1-revisao3-regex.py`.
A sonda compara o regex de `1ae2f53` com o atual sobre a mesma entrada e impõe limite
de dois segundos. Depois coloca essa chave inválida numa segunda linha da tabela e altera
o nome de uma linha normal, `id = '8'`, pela função real `mutacoes.alterar`.
Saída literal, omitidas apenas as mensagens de migração:

```json
{"revision": "base_1ae2f53", "input": "131080 zeros + x", "elapsed_seconds": 0.004011, "matched": false}
{"revision": "head_7faad24", "input": "131080 zeros + x", "elapsed_seconds": 2.000054, "timeout_seconds": 2}
{"scenario": "alteracao_de_outra_linha", "probe_interruption": "limite de 2 s da sonda", "saved_value": "Depois", "diary_entries": 0}
```

O limite e a interrupção são **da sonda**, não um timeout existente no produto; o tempo até
o regex atual terminar essa entrada **não foi medido**. A regressão vem da sobreposição
entre `0*` e `[0-9]+`: um sufixo inválido força a reconsideração das divisões dos zeros entre
os dois grupos. Como `_presenca_canonica` agora lê todas as PKs depois do commit, basta uma
linha inválida longa, mesmo não tocada pela mutação, para atrasar a gravação do diário.

### Limites desta rodada

- Não executei `make dbt-build`, a DAG, sincronização real do Airbyte, interrupção de job real,
  `FATO=1`, `CARGA=1` nem a sequência operacional B–F. O `PASS=891` da seção 3 continua sendo
  medição do autor, não desta revisão.
- O SQL dos modelos de remoção foi executado sobre capturas pequenas em bancos efêmeros,
  pela renderização das declarações com `source`/`ref` apontando para esses bancos. Isso
  prova os casos apresentados, não uma execução pelo runner do dbt nem o fluxo até as fatos.
- Não regravei o manifesto de trabalho nem suas entradas antigas. A compatibilidade antiga
  continua limitada à informação que elas registraram; reconstruir presença passada a partir
  da origem atual fabricaria evidência.
- A contraprova de limpeza da suíte continua no nível de staging. Não atribuo à captura
  corrente uma nova comparação integral de classificação e cascata contra o manifesto.
- A nota acrescida ao ADR-0044 explicita a implementação das guardas. Nenhuma decisão
  arquitetural ou ADR foi alterado por esta revisão; o adiamento do caminho BigQuery permanece.

### Tabela de achados

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV10-3-01 | `dbt/macros/chave_canonica.sql:58`; `src/mvp_ed1/legacy/remocao.py:51` | **A guarda ainda nega identidade a inteiros conversíveis no PostgreSQL instalado.** `0x8`, `0b1000`, `0o10` e `1_000` convertem, mas macro e Python devolvem nulo. No ciclo `'8' → '0x8'`, a mesma chave vira `removida` e entra na memória; reconciliação e comparação com o diário passam porque ambos reproduzem a fronteira errada (EV10-3-03). Completar a gramática dos dois lados, preservando domínio e conversão segura, e testar a fronteira contra o cast nativo e uma mudança só de representação entre capturas. É lacuna remanescente de RV10-2-04/05, não mudança proposta ao ADR-0045. | `bloqueante` | **Corrigido nos dois lados.** A guarda da macro e o `_INTEIRO` do espelho passaram a ser a gramática de `pg_strtoint64` do PostgreSQL 16: sinal, decimal/hexa (`0x`)/octal (`0o`)/binário (`0b`), `_` entre dígitos ou logo depois do prefixo, brancos ASCII à volta. O valor sai da soma dos dígitos na base em `numeric` (medido exato até `2^64`), com o domínio conferido antes do `cast`. Sondado forma a forma em 16/09 (`0x_8` converte, `0x8_` e `_8` não; `-0x8000000000000000` é o mínimo do `bigint`); as 60 formas novas entraram em `FORMAS` e o teste compara macro **e** Python ao cast nos dois bancos (`0x8` na macro de `7faad24` falha: `('0x8', None, '8')`). O ciclo `'8' → '0x8'` entre duas certificadas agora é `mantida`, provado até o consumidor por `test_o_ciclo_inteiro_entre_duas_certificadas_concorda_com_o_diario`. Custo medido: `legacy_presence_by_capture` (101.897 linhas, o mesmo resultado) passou de 5,66 s para 8,65 s no `dbt build --select legacy_presence_by_capture+` (`PASS=27`). Nota no ADR-0045 e em Origem Legada. |
| RV10-3-02 | `src/mvp_ed1/legacy/mutacoes.py:249`, `:253` | **Alteração de zero linhas passou a fabricar uma testemunha de ausência.** `tocadas = [chave] + ...` inclui o pedido mesmo com `devolvidas = []`; a presença nova prevalece sobre a guarda que a leitura antiga tinha. Alterar a chave inexistente `777` grava `{777: 0}`, e o teste exige sua presença na memória de removidos, apesar de ela nunca ter existido (EV10-3-04). Derivar as chaves tocadas das ocorrências efetivamente alteradas, preservando a identidade anterior quando a PK muda, e provar alteração sem correspondência no formato novo do diário. | `bloqueante` | **Corrigido.** `tocadas` só existe quando o `UPDATE … RETURNING` devolveu linha: `[chave] + [nova PK]` se devolveu, `[]` se não — e `presenca_apos_commit` vem vazio. `alterar('777', 'name', …)` grava `{}` e fica fora do efeito líquido (teste da multiplicidade); o mesmo caso atravessa os modelos reais no ciclo inteiro sem gerar falta. Com o `mutacoes.py` de `7faad24`, os dois testes falham (`{'777': 0} == {}`). |
| RV10-3-03 | `src/mvp_ed1/legacy/remocao.py:51`; `src/mvp_ed1/legacy/mutacoes.py:97` | **O regex novo introduz custo excessivo para zeros seguidos de sufixo inválido.** Na entrada de EV10-3-05, o regex anterior recusa em 0,004011 s; o novo não termina nos dois segundos permitidos pela sonda. A varredura nova aplica isso também às chaves não tocadas, depois do commit: na interrupção controlada, a alteração estava gravada e o diário ainda vazio. Separar validação e retirada de zeros, evitando quantificadores com consumo sobreposto, e exercitar entradas longas inválidas além das válidas. O tamanho da tabela sozinho não limita esse custo. | `ajuste` | **Corrigido.** O regex do espelho não tem mais quantificadores sobrepostos (`0*` saiu; os zeros à esquerda saem por `lstrip`, depois do casamento), e a macro nunca teve o `0*` na guarda. Medido: as seis entradas adversas (131.080 zeros + `x`, + `_`, `1_…x`, `0xf…g`, `123_…x`, `0x_f…_`) recusam em ~0,01 s cada; `test_a_canonizacao_recusa_entrada_longa_invalida_em_tempo_linear` cobra menos de 1 s, e quatro delas entraram em `FORMAS` para a macro nos dois bancos. `_presenca_canonica` continua lendo a PK inteira (premissa 4 mantida); o custo agora é linear na entrada. |
| RV10-3-04 | `tests/test_legado_remocao.py:116`, `:344` | **A prova do diário novo para antes do consumidor que rejeita a redução correta.** O teste acrescentado confirma `{8: 1}`, mas o teste do ciclo aceita presença só com `mantida`, `adicionada` ou ausência de transição. Em duas capturas certificadas com `['8', '08'] → ['8']`, os modelos produzem corretamente `reduzida`, a memória fica vazia e o teste falha como “presente com transição estranha” (EV10-3-04). Alinhar a comparação a `rows_after > 0` e às transições de multiplicidade, exercitando redução e aumento com o diário novo até o consumidor. A condição antiga já existia; esta rodada não concluiu a integração da correção RV10-2-07 com ela. | `ajuste` | **Corrigido.** A comparação saiu do teste do ciclo real para `_faltas(efeito, intervalo, memoria)`, que lê `rows_after`: presente ⇒ fora da memória e, se está no intervalo, `rows_after > 0` em qualquer transição; ausente ⇒ na memória e, se está no intervalo, só `removida`. Unitário com `reduzida`/`aumentada` e as três contradições nomeadas; no ciclo inteiro em bancos efêmeros, `['8','08'] → ['8']` dá `reduzida` com memória vazia e `9` + `0o11` dá `aumentada`, e o mesmo `_faltas` do ciclo real aceita os dois. |
