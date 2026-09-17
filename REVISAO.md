# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `b650125..ccc30eb` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
953ea59 docs: abre o dossiê da quarta rodada de revisão da Etapa 10
e5ebc7d test: o consumidor do diário exige linha no intervalo para toda chave presente
ccc30eb docs: registra a situação do achado da quarta rodada e a terceira saída da D43
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 2 arquivos

- `docs/pendencias.md`
- `tests/test_legado_remocao.py`

### Gerados — 1 arquivos, revisar por amostragem

- `REVISAO.md`

**Declaração desta entrega:** responde ao único achado da quarta rodada, RV10-4-01 (parecer e
coluna *Situação* no *commit* `ccc30eb`, `git show ccc30eb:REVISAO.md`). Nenhum código de produção
mudou — o intervalo é teste e registro.

| Arquivo | Por que é declaração |
|---|---|
| `tests/test_legado_remocao.py::_faltas` | RV10-4-01: chave presente exige linha no intervalo (`presente mas fora do intervalo`) **e** `rows_after > 0`; `None` só para ausência com memória. É a regra que o ciclo real e o ciclo em bancos efêmeros cobram — conferir que ela não aceita menos do que o modelo publica nem mais do que o diário sabe |
| `tests/test_legado_remocao.py::test_o_ciclo_inteiro_…` — contraprova final | EV10-4-04 reproduzida: a linha `mantida` da chave `1` é apagada do intervalo materializado; a reconciliação física continua vazia e `_faltas` acusa. Conferir que apagar a linha da tabela equivale, para o consumidor, a omiti-la no SQL — é a diferença entre a sonda do revisor e o teste |
| `docs/pendencias.md` — D43 | Terceira saída (`pg_input_is_valid` + `case`) anotada para a Etapa 13, como o parecer sugeriu; não é decisão nova |

**Derivado — amostragem basta.** O unitário `test_o_consumidor_…` (chave `3` sem linha passa a ser
acusada); as docstrings alinhadas.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
.......................s.....................................s.......... [ 28%]
........................................sss................sss.......... [ 56%]
........................................................................ [ 84%]
.......................................                                  [100%]
247 passed, 8 skipped in 147.20s (0:02:27)
```

### `make dbt-build` ✓

```
11:52:08  890 of 891 START sql view model consumption.payment_approval_rate_by_method .... [RUN]
11:52:08  891 of 891 START sql view model consumption.refund_rate_by_reason .............. [RUN]
11:52:08  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['refunded_amount', 'captured_amount', 'refund_rate_pct']`
11:52:08  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['approval_rate_pct', 'authorized_amount', 'captured_amount']`
11:52:08  891 of 891 OK created sql view model consumption.refund_rate_by_reason ......... [CREATE VIEW in 0.21s]
11:52:08  890 of 891 OK created sql view model consumption.payment_approval_rate_by_method  [CREATE VIEW in 0.21s]
11:52:08
11:52:08  Finished running 1 incremental model, 3 seeds, 4 snapshots, 139 table models, 687 data tests, 5 unit tests, 52 view models in 0 hours 11 minutes and 46.73 seconds (706.73s).
11:52:10
11:52:10  Completed successfully
11:52:10
11:52:10  Done. PASS=891 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=891
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**1. A contraprova apaga a linha da tabela materializada, não omite a chave no SQL do modelo.**
Para `_faltas` é o mesmo — ele lê a tabela —, mas a sonda EV10-4-04 mutou o SQL de transições em
memória e executou a reconciliação sobre ele; aqui a reconciliação roda sobre a tabela mutilada. Que
a equação física não veja a perda foi confirmado nas duas formas (o teste afirma `== []` depois do
`delete`); que os dois caminhos sejam equivalentes para todo modelo, não.

**2. O ciclo real passou com o consumidor mais estrito** (`make test`, §3) — as chaves presentes do
diário de produção têm linha no intervalo 35→36. Não listei quais são nem quantas; o `record_property`
do teste continua registrando só o total de entradas e de ausentes.

**3. `legacy_presence_by_capture` levou 17,7 s neste *build*** (15,39 s no anterior, 5,66 s em
15/09), com o total do *build* em 706,7 s (724,9 s e 777,9 s antes). Continua sendo o item aberto da
rodada anterior: não isolei a macro nem comparei planos, e o revisor tem razão em que totais de
*builds* diferentes não bastam para atribuir a diferença a ruído.

**4. Como nas rodadas anteriores:** DAG, Airbyte real, `FATO=1`, `CARGA=1`, interrupção de *job*
real e o próximo bloco de sincronizações (D44) não rodaram.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

**1. Que toda chave presente na captura selecionada tem linha em `legacy_capture_transitions`
quando existe anterior certificada** — é o que `remocao.transicoes()` faz por construção (`full outer
join` entre os dois lados, `mantida` incluída), e é a premissa que torna a regra nova de `_faltas`
correta. Lida no gerador; medida só nos dois ciclos (efêmero e real).

**2. As premissas 1–6 do dossiê anterior continuam de pé e não foram remedidas** — nada no código
que elas sustentam mudou neste intervalo.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

**1. Acusar com um nome novo (`presente mas fora do intervalo`) em vez de reaproveitar
`presente mas removida no intervalo`.** São defeitos diferentes — um é o modelo dizendo `removida`,
o outro é o modelo não dizendo nada — e quem lê a falta precisa saber qual dos dois é.

**2. Manter `None` aceitável para chave ausente.** Chave removida há duas ou mais certificadas não
está no intervalo e só a memória a responde; exigir `removida` reprovaria o ciclo real correto (as 5
chaves de produção). O parecer pediu exatamente esta assimetria.

**3. Apagar a linha da tabela em vez de mutar o SQL.** Mais curto e sem um segundo renderizador de
modelo dentro do teste; o preço está no item 1 da §4.

**4. Anotar `pg_input_is_valid` na D43 sem reabrir a decisão.** O Owner adiou a D43 na rodada
anterior; a sugestão do revisor é uma terceira alternativa para a mesma decisão adiada, e o lugar
dela é a pendência, não um ADR nem uma troca de implementação agora.

---

## Achados da revisão

### Parecer do revisor — Codex, 17/09/2026, quinta rodada

**RV10-4-01 corrigido; resta um ajuste no desvio que antecede o consumidor.** Revisado
`b650125..ccc30eb`, com o dossiê publicado em `464b75d` e a árvore limpa ao início.
A correção de `_faltas` cumpre o pedido da quarta rodada: chave presente sem linha no
intervalo é acusada; ausência histórica com memória continua válida. A contraprova
original, que omite a chave no SQL, agora faz o teste completo falhar corretamente.

O limite encontrado nesta rodada fica antes dessa chamada: intervalo inteiramente vazio
faz o teste pular sem conferir se existe anterior certificada. **É preexistente**, também
reproduzido em `b650125`, e não regressão introduzida pela entrega. Não encontrei novo
defeito no código de produção nem novo bloqueante. Este parecer não encerra a Etapa 10
nem substitui o aceite do Owner.

### Conferência da entrega

- **Regra declarada:** conferida integralmente contra `remocao.transicoes()` e o ADR-0045.
  O `full outer join` inclui as chaves `mantida`, portanto exigir a linha da chave presente
  está correto quando existe anterior certificada. Redução e aumento continuam aceitos.
- **Contraprova do teste:** apagar a linha materializada é suficiente para exercitar
  `_ler_intervalo_e_memoria` e `_faltas`. A sonda desta revisão também omitiu a linha no
  SQL gerado, reproduzindo o caminho da quarta rodada, com o resultado esperado.
- **D43:** a ressalva sobre a lista finita de entradas e a terceira alternativa ficaram
  registradas como solicitado. O adiamento permanece; nenhuma implementação ou decisão
  de arquitetura foi trocada neste intervalo.

### Evidências produzidas nesta revisão

**EV10-5-01 — suíte existente.** Comando:
`PYTEST_ADDOPTS='--tb=short -rs' make test`, sem `FATO=1` nem `CARGA=1`.
Recorte literal de `/tmp/mvp_ed1-revisao5-tests-validos.log`:

```text
.......................s.....................................s.......... [ 28%]
........................................sss................sss.......... [ 56%]
........................................................................ [ 84%]
.......................................                                  [100%]
247 passed, 8 skipped in 158.15s (0:02:38)
```

Dois testes pulam pelas opções de carga e escrita na fato; seis pulam porque a captura 36,
mutada, não corresponde ao lote do manifesto. Recortes literais dos motivos:

```text
SKIPPED [1] tests/test_carga.py:51: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:124: a captura 36 não é o lote 3f9e5088c722 do manifesto (3 tabelas divergem: ['customers', 'inventory_movements', 'refunds']); sincronize o lote corrente antes de comparar vereditos
```

A primeira tentativa, no sandbox, não conseguiu conectar aos bancos locais. Foi repetida
com acesso autorizado; apenas essa repetição sustenta a validação de integração acima.

**EV10-5-02 — omissão parcial e total do intervalo.** Comando:
`.venv/bin/python /tmp/mvp_ed1-revisao5-consumidor.py`, com o ambiente local carregado.
A sonda cria dois bancos efêmeros, certifica as capturas 851 e 852 e altera apenas o nome
da chave `brands/1` entre elas. O diário confirma presença. Executa os modelos íntegros,
depois omite essa chave no SQL de transições e, por fim, omite o intervalo inteiro
(`and false`). O bruto e os certificados permanecem iguais. Compara o helper e o teste
completo de `b650125` com os atuais; código antigo carregado em memória, sem trocar a árvore.
Saída literal de `/tmp/mvp_ed1-revisao5-consumidor.log`:

```json
{"scenario": "integro", "certified_interval": [851, 852], "interval_rows": 2, "physical_reconciliation_errors": 0, "consumer_base": [], "consumer_current": [], "cycle_base": "PASS", "cycle_current": "PASS"}
{"scenario": "omite_chave_presente", "certified_interval": [851, 852], "interval_rows": 1, "physical_reconciliation_errors": 0, "consumer_base": [], "consumer_current": [["presente mas fora do intervalo", "brands", "1"]], "cycle_base": "PASS", "cycle_current": "FAIL: efeito líquido do diário sem correspondência: [('presente mas fora do intervalo', 'brands', '1')]"}
{"scenario": "intervalo_vazio", "certified_interval": [851, 852], "interval_rows": 0, "physical_reconciliation_errors": 0, "consumer_base": [], "consumer_current": [["presente mas fora do intervalo", "brands", "1"]], "cycle_base": "SKIP: sem intervalo: a captura selecionada não tem anterior certificada", "cycle_current": "SKIP: sem intervalo: a captura selecionada não tem anterior certificada"}
```

No último caso o helper corrigido acusa a perda, mas o teste completo não chega a chamá-lo.
O motivo do `SKIP` é falso nesse cenário: as duas capturas foram certificadas. A
reconciliação física também não acusa, pois deriva seu universo das transições vazias.
Isso demonstra uma lacuna de validação; não demonstra perda no modelo íntegro de produção.

**EV10-5-03 — diário real, somente leitura.** Na mesma sonda, consulta ao armazém de
trabalho em transação `read only`. Saída literal:

```json
{"scenario": "diario_real_somente_leitura", "interval": [35, 36], "diary_entries": 16, "present_keys": 11, "absent_keys": 5, "present_keys_in_interval": 11, "absent_keys_only_in_memory": 5, "consumer_errors": []}
```

As chaves presentes têm linha no intervalo; as ausências históricas são respondidas pela
memória sem linha no intervalo. A regra mais estrita não reprova esse estado correto.

### Limites desta rodada

- Não repeti `make dbt-build`: nenhum modelo ou gerador de produção mudou no intervalo.
  O `PASS=891` da seção 3 permanece evidência do autor. Os modelos de remoção foram
  executados nos bancos efêmeros pela suíte e pelas sondas.
- Não executei DAG, Airbyte real, interrupção de job, `FATO=1`, `CARGA=1` nem o bloco
  operacional da D44. Os seis testes de comparação com o manifesto que pularam não
  revalidam o lote íntegro nesta rodada.
- Não isolei o custo da macro nem comparei planos. A variação de desempenho declarada
  na seção 4 continua sem explicação medida; a paridade com BigQuery continua pendente.
- A injeção de falha de EV10-5-02 foi apenas nos bancos efêmeros, removidos pelas fixtures.
  O diário real foi lido, sem mutação. Roteiro e logs ficaram em `/tmp/mvp_ed1-revisao5-*`.
  A única alteração versionável desta revisão é este parecer.

### Tabela de achados

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV10-5-01 | `tests/test_legado_remocao.py:549–550` | **Intervalo vazio pula a validação mesmo quando existe anterior certificada.** O teste deduz a falta de anterior de `not intervalo`, antes de chamar `_faltas`. EV10-5-02 mantém duas capturas certificadas e uma chave declarada presente no diário, mas omite todas as transições: o helper acusa a falta; o teste completo retorna `SKIP`, e a reconciliação física também não acusa. **Preexistente em `b650125`; não introduzido por esta entrega.** Determinar a existência de anterior pela seleção e pelos certificados, independentemente da tabela auditada; só pular quando de fato não houver anterior. Havendo anterior, submeter também o intervalo vazio ao consumidor. Acrescentar a contraprova no nível do teste completo e preservar o caso legítimo sem anterior e as ausências históricas com memória. | `ajuste` | **Aplicado em `4a3b692`.** `_anterior_certificada(conexao, selecionada)` lê `governance.legacy_captures` com a regra de `certificadas_sql()` (`complete` nas 40 tabelas, `max(snapshot_id) < selecionada`) — a mesma do `anterior` de `remocao.transicoes()` — e a selecionada sai de `staging.legacy_selected_capture`. O ciclo real só pula quando o helper devolve `None`; com anterior, o intervalo vai ao consumidor mesmo vazio, e o par materializado, quando existe, tem de ser `(anterior, selecionada)`. Contraprova no ciclo efêmero: `delete from trusted.legacy_capture_transitions`, anterior ainda encontrada, `legado_presenca_fisica_reconcilia` devolvendo `[]` (não acusa, como EV10-5-02 mostrou) e `_faltas` acusando `1`, `8` e `9` como `presente mas fora do intervalo`; `_anterior_certificada(conexao, anterior) is None` preserva o salto legítimo da primeira certificada, e as ausências históricas com memória seguem aceitas (EV10-5-03 continua verde: `tests/test_legado_remocao.py` → `55 passed`, o ciclo real em 35→36 sem skip). |

---

### Parecer do revisor — Codex, 17/09/2026, sexta rodada

**A correção funcional de RV10-5-01 está confirmada; falta a contraprova de regressão no
teste completo.** O intervalo desta conferência é `464b75d..b9523f1`: implementação em
`4a3b692` e resposta do autor em `b9523f1`, com a árvore limpa ao início. O escopo da seção 1
e as medições anteriores permanecem históricos; não representam estes dois commits novos.

Revisei integralmente `_anterior_certificada`, a alteração no teste do diário e a
contraprova acrescentada ao ciclo efêmero. O helper segue a regra de `certificadas_sql()`
e o corte estrito de `remocao.transicoes()`: seleciona a maior captura anterior com
`complete` nas 40 tabelas. A seleção vem do modelo materializado, e a conferência do par
recusa limites divergentes. Nenhum código de produção mudou neste intervalo.

A sonda que chama o teste completo agora confirma o comportamento solicitado: a perda
total do intervalo falha; a primeira captura sem anterior pula legitimamente. O que ainda
não foi atendido é a parte do achado que pede **contraprova no nível do teste completo**.
O teste versionado novo chama `_anterior_certificada` e `_faltas` separadamente; não passa
pelo desvio onde estava o defeito. EV10-6-03 mostra que restaurar esse desvio deixa os dois
testes envolvidos verdes. É a cobertura restante do mesmo achado, não um novo defeito
funcional ou um novo bloqueante.

### Evidências da sexta rodada

**EV10-6-01 — suíte existente.** Comando:
`PYTEST_ADDOPTS='--tb=short -rs' make test`, sem `FATO=1` nem `CARGA=1`.
Recorte literal de `/tmp/mvp_ed1-revisao6-tests.log`:

```text
.......................s.....................................s.......... [ 28%]
........................................sss................sss.......... [ 56%]
........................................................................ [ 84%]
.......................................                                  [100%]
247 passed, 8 skipped in 154.75s (0:02:34)
```

Os motivos dos oito testes pulados continuam os de EV10-5-01: dois dependem de carga ou
escrita na fato e seis dependem do lote íntegro do manifesto, diferente da captura 36.
O teste do diário real passou sem pular.

**EV10-6-02 — fluxo completo, com seleção materializada.** Comando:
`.venv/bin/python /tmp/mvp_ed1-revisao6-consumidor.py`, com o ambiente local carregado.
Dois bancos efêmeros, capturas 861 e 862 certificadas, alteração do nome de `brands/1`
registrada no diário. A seleção é materializada a partir de `captura_selecionada()`;
a sonda chama `test_as_mutacoes_do_diario_aparecem_nas_transicoes_e_na_memoria` diretamente.
O teste de `464b75d` é carregado em memória para comparação. Recortes literais de
`/tmp/mvp_ed1-revisao6-consumidor.log`:

```json
{"scenario": "primeira_certificada", "selected": 861, "cycle_current": {"status": "SKIP", "detail": "sem intervalo: a captura 861 não tem anterior certificada"}}
{"scenario": "integro", "certified_interval": [861, 862], "interval_rows": 2, "cycle_base": {"status": "PASS"}, "cycle_current": {"status": "PASS"}}
{"scenario": "omite_chave_presente", "certified_interval": [861, 862], "interval_rows": 1, "cycle_base": {"status": "FAIL", "detail": "efeito líquido do diário sem correspondência: [('presente mas fora do intervalo', 'brands', '1')]"}, "cycle_current": {"status": "FAIL", "detail": "efeito líquido do diário sem correspondência: [('presente mas fora do intervalo', 'brands', '1')]"}}
{"scenario": "intervalo_vazio", "certified_interval": [861, 862], "interval_rows": 0, "cycle_base": {"status": "SKIP", "detail": "sem intervalo: a captura selecionada não tem anterior certificada"}, "cycle_current": {"status": "FAIL", "detail": "efeito líquido do diário sem correspondência: [('presente mas fora do intervalo', 'brands', '1')]"}}
{"scenario": "par_materializado_divergente", "certified_interval": [861, 862], "interval_rows": 2, "cycle_base": {"status": "PASS"}, "cycle_current": {"status": "FAIL", "detail": "o intervalo materializado não é o certificado: [(861, 861)]"}}
{"probe": "fluxo_completo", "result": "PASS"}
```

Os `FAIL` acima são falhas esperadas e conferidas pela sonda. A omissão parcial e total
foi injetada no SQL das transições; no último caso, só o par materializado foi adulterado.
As alterações ficaram nos bancos efêmeros.

**EV10-6-03 — a contraprova versionada não detecta a volta do salto indevido.** Copiei
`tests/test_legado_remocao.py` para `/tmp/test_legado_remocao_rv6_mutante.py` e alterei
somente a condição do teste completo:

```diff
-    if anterior is None:
+    if not intervalo or anterior is None:
```

Isso restaura o desvio indevido de RV10-5-01, mantendo os helpers e os demais testes
intactos. Executei os dois testes que poderiam exercer essa integração — ciclo efêmero
com a nova contraprova e consumidor do diário real — usando a configuração do projeto:

```bash
PYTHONPATH=/home/doug/Projetos/mvp_ed1/tests .venv/bin/pytest -c pyproject.toml -q --tb=short -rs /tmp/test_legado_remocao_rv6_mutante.py -k 'o_ciclo_inteiro or as_mutacoes_do_diario'
```

Saída literal de `/tmp/mvp_ed1-revisao6-mutante-configurado.log`:

```text
..                                                                       [100%]
2 passed, 53 deselected in 2.90s
```

O ciclo efêmero não chama o teste completo, e o diário real tem intervalo preenchido;
nenhum atravessa o desvio com intervalo vazio. Não executei a suíte inteira sobre a
cópia mutante. A primeira execução dessa cópia não carregava `pyproject.toml` e emitia
avisos de marcador desconhecido; o comando acima é a repetição com a configuração correta.

### Situação do achado após a sexta rodada

| # | Onde | O que resta | Veredito | Situação |
|---|---|---|---|---|
| RV10-5-01 | `tests/test_legado_remocao.py:519–530` | **A contraprova não atravessa o desvio corrigido.** As asserções de `_anterior_certificada` e `_faltas` isolados não protegem o teste completo contra a volta do salto por intervalo vazio; EV10-6-03 restaura esse salto e os dois testes envolvidos passam. Materializar a seleção necessária no banco efêmero e exercitar o fluxo completo, cobrando falha por chave presente ausente com duas certificadas e salto legítimo apenas sem anterior. Um helper compartilhado também serve se incluir o desvio de elegibilidade e a validação. A contraprova deve falhar ao reintroduzir `if not intervalo`. | `ajuste` | **Aplicado em `eb6f176`.** O teste completo virou `_conferir_diario(conexao, diario)` — elegibilidade (`skip` só com `_anterior_certificada` nula) e validação num lugar só; o ciclo real o chama. O ciclo efêmero o exercita por `_veredito_do_diario`, que devolve `("passa",)`, `("salto", motivo)` ou `("falha", faltas)` como valor — porque um `Skipped` escapando de `pytest.raises(AssertionError)` pulava o teste inteiro em silêncio, o mesmo defeito no teste que o cobre (foi o primeiro resultado da cópia mutante). O armazém efêmero passa a materializar `staging.legacy_selected_capture` pelo gerador real (`captura_selecionada()` com `legacy_snapshot_id` explícito), e `ref` aponta para ela como no dbt. Cobertura pelo fluxo completo: íntegro `passa`; chave `1` omitida `falha` com `[('presente mas fora do intervalo', 'brands', '1')]`; intervalo inteiro apagado `falha` com `8`, `9` e `1`, com a equação física ainda em `[]`; modelos reconstruídos sobre a primeira certificada → `salto` com `a captura {anterior} não tem anterior certificada`. Contraprova de EV10-6-03 repetida: cópia com `if not intervalo or anterior is None` → `o_ciclo_inteiro` **falha** (`assert ('salto', …) == ('falha', [('presente mas fora do intervalo', 'brands', '1')])`), `1 failed, 1 passed`. Suíte inteira: `247 passed, 8 skipped in 152.10s`, mesmos oito motivos de EV10-6-01. |

### Limites da sexta rodada

- Não repeti `make dbt-build`, sincronização real do Airbyte, DAG, interrupção de job,
  `FATO=1`, `CARGA=1` ou o bloco da D44. O `PASS=891` anterior não é medição desta rodada.
- Não remedi o custo da macro, planos de execução ou paridade com BigQuery. As ressalvas
  anteriores sobre esses pontos permanecem.
- Os bancos efêmeros foram removidos pelas fixtures. A cópia mutante e as sondas ficaram
  em `/tmp`; a única alteração versionável desta revisão é este parecer.
- A confirmação da correção funcional não é aceite da Etapa 10 pelo Owner.

---

### Parecer do revisor — Codex, 17/09/2026, sétima rodada

**RV10-5-01 resolvido, incluindo a cobertura de regressão. Sem novos achados no intervalo
revisado.** Conferido `b9523f1..6050cd5`: implementação em `eb6f176` e resposta do autor em
`6050cd5`, com a árvore limpa ao início. Os pareceres anteriores permanecem históricos.

Revisei integralmente a extração de `_conferir_diario`, o adaptador `_veredito_do_diario`
e a materialização da seleção no armazém efêmero. O ciclo real e as contraprovas passam
pelo mesmo desvio de elegibilidade e pela mesma validação. O salto é convertido em valor
nas contraprovas, portanto sua ocorrência indevida faz a asserção falhar em vez de pular
o próprio teste. A seleção usa o modelo gerado com a captura explícita, e as referências
apontam para a tabela materializada. Nenhum código de produção mudou nesta entrega.

### Evidências da sétima rodada

**EV10-7-01 — suíte existente.** Comando:
`PYTEST_ADDOPTS='--tb=short -rs' make test`, sem `FATO=1` nem `CARGA=1`.
Recorte literal de `/tmp/mvp_ed1-revisao7-tests.log`:

```text
.......................s.....................................s.......... [ 28%]
........................................sss................sss.......... [ 56%]
........................................................................ [ 84%]
.......................................                                  [100%]
247 passed, 8 skipped in 162.08s (0:02:42)
```

Os oito motivos de salto permanecem os de EV10-5-01: dois dependem de carga ou escrita
na fato e seis da correspondência com o lote íntegro do manifesto. O ciclo efêmero e o
teste do diário real passaram, sem salto.

**EV10-7-02 — a contraprova agora detecta a regressão.** Copiei o arquivo vigente para
`/tmp/test_legado_remocao_rv7_mutante.py` e repeti a única alteração de EV10-6-03, agora
no helper compartilhado:

```diff
-    if anterior is None:
+    if not intervalo or anterior is None:
```

Com o ambiente local carregado, executei:

```bash
PYTHONPATH=/home/doug/Projetos/mvp_ed1/tests .venv/bin/pytest -c pyproject.toml -q --tb=short -rs /tmp/test_legado_remocao_rv7_mutante.py -k 'o_ciclo_inteiro or as_mutacoes_do_diario'
```

Recortes literais de `/tmp/mvp_ed1-revisao7-mutante.log`:

```text
F.                                                                       [100%]
=================================== FAILURES ===================================
______ test_o_ciclo_inteiro_entre_duas_certificadas_concorda_com_o_diario ______
/tmp/test_legado_remocao_rv7_mutante.py:532: in test_o_ciclo_inteiro_entre_duas_certificadas_concorda_com_o_diario
    assert _veredito_do_diario(conexao, diario) == (
E   AssertionError: assert ('salto', 'se... certificada') == ('falha', [('...rands', '1')])
E
E     At index 0 diff: 'salto' != 'falha'
E     Use -v to get more diff
```

```text
1 failed, 1 passed, 53 deselected in 3.66s
```

**Falha esperada**, com código de saída 1: o ciclo efêmero detecta a volta do salto por
intervalo inteiramente vazio. Na sexta rodada os mesmos dois testes passavam com essa
mutação; agora a contraprova versionada protege o caminho corrigido. O arquivo original
não foi alterado pela sonda.

**EV10-7-03 — fluxo completo preservado após a extração.** Repeti
`.venv/bin/python /tmp/mvp_ed1-revisao6-consumidor.py` contra o código vigente. A sonda
mantém as asserções da sexta rodada, executa os modelos em bancos efêmeros e chama o teste
do diário completo. Recortes literais de `/tmp/mvp_ed1-revisao7-consumidor.log`:

```json
{"scenario": "primeira_certificada", "selected": 861, "cycle_current": {"status": "SKIP", "detail": "sem intervalo: a captura 861 não tem anterior certificada"}}
{"scenario": "integro", "certified_interval": [861, 862], "interval_rows": 2, "cycle_base": {"status": "PASS"}, "cycle_current": {"status": "PASS"}}
{"scenario": "par_materializado_divergente", "certified_interval": [861, 862], "interval_rows": 2, "cycle_base": {"status": "PASS"}, "cycle_current": {"status": "FAIL", "detail": "o intervalo materializado não é o certificado: [(861, 861)]"}}
{"probe": "fluxo_completo", "result": "PASS"}
```

A sonda também confirmou falha para omissão parcial e total do intervalo; os registros
completos estão no mesmo log. O `FAIL` do par adulterado é esperado. O primeiro caso
preserva o salto legítimo sem anterior, e o segundo confirma o caminho íntegro.

### Situação após a sétima rodada

| # | Veredito original | Situação conferida |
|---|---|---|
| RV10-5-01 | `ajuste` | **Resolvido tecnicamente.** Elegibilidade independente do intervalo e validação compartilhada confirmadas; a contraprova versionada agora falha ao reintroduzir o salto indevido. Nenhum ajuste remanescente deste achado. |

### Limites da sétima rodada

- Não repeti `make dbt-build`, Airbyte real, DAG, interrupção de job, `FATO=1`, `CARGA=1`
  nem o bloco da D44. O `PASS=891` histórico não é medição desta rodada.
- Não remedi custo da macro, planos de execução ou paridade com BigQuery; as ressalvas
  anteriores sobre esses pontos permanecem.
- As injeções de falha ficaram nos bancos efêmeros, removidos pelas fixtures, e na cópia
  em `/tmp`. A única alteração versionável desta revisão é este parecer.
- O encerramento técnico de RV10-5-01 não presume o aceite formal da Etapa 10 pelo Owner.
