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

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

