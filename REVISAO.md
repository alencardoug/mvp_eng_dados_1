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

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |
