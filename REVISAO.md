# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `7faad24..b650125` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
108a283 docs: abre o dossiê da terceira rodada de revisão da Etapa 10
624730c fix: a guarda e o espelho aceitam as bases e o separador que o cast do PostgreSQL 16 aceita
2024072 fix: alteração de zero linhas não toca a presença do diário
adfff25 test: o consumidor do diário aceita redução e aumento, e o ciclo inteiro roda os modelos reais
a9b07d9 docs: registra a situação dos quatro achados da terceira rodada
b650125 docs: registra D43 adiada e D44 decidida na terceira rodada
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 9 arquivos

- `README.md`
- `dbt/macros/chave_canonica.sql`
- `docs/adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md`
- `docs/adr/README.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `src/mvp_ed1/legacy/mutacoes.py`
- `src/mvp_ed1/legacy/remocao.py`
- `tests/test_legado_remocao.py`

### Gerados — 1 arquivos, revisar por amostragem

- `REVISAO.md`

**Declaração desta entrega:** responde aos quatro achados RV10-3-01…04 do terceiro parecer (parecer e
coluna *Situação* no *commit* `a9b07d9`, `git show a9b07d9:REVISAO.md`) e registra duas decisões do
Owner (D43 adiada, D44 decidida — §7 abaixo). Revisão integral, nesta ordem:

| Arquivo | Por que é declaração |
|---|---|
| `dbt/macros/chave_canonica.sql` — ramo inteiro | RV10-3-01: a guarda é a gramática de `pg_strtoint64` (quatro bases, `_`, brancos ASCII, sinal); o valor sai da soma dos dígitos na base em `numeric`, numa subquery escalar com `lateral`; o domínio é conferido antes do `cast`. Conferir que a regex é **exatamente** o que o cast aceita — `0x_8` sim, `0x8_`/`_8`/`00x8` não — e que o limite de dígitos por base (19/16/22/64) não corta nada dentro do domínio |
| `src/mvp_ed1/legacy/remocao.py` — `_INTEIRO`, `_BASES`, `canonizar` | RV10-3-01/03: o espelho, sem quantificadores sobrepostos; `lstrip('0')` depois do casamento; `int(digitos, base)` |
| `src/mvp_ed1/legacy/mutacoes.py::alterar` — `tocadas` | RV10-3-02: só o que o `RETURNING` devolveu toca a presença; zero linhas ⇒ `{}` |
| `tests/test_legado_remocao.py` — `_faltas`, `_modelos_renderizados`, `_construir_modelos`, `test_o_ciclo_inteiro_…` | RV10-3-04 e a prova de ponta a ponta: o consumidor lê `rows_after`; o ciclo em bancos efêmeros executa os quatro SQL gerados com a macro vigente e termina no mesmo `_faltas` do ciclo real. É onde eu olharia primeiro: o que a sonda do revisor fez em `/tmp` agora é teste, e vale conferir que os `source`/`ref` resolvidos batem com o que o dbt resolveria |
| `docs/pendencias.md` — D43 e D44; nota de 16/09 no ADR-0045 | Decisões do Owner desta rodada e a retificação dentro de ADR aceito |

**Derivado — amostragem basta.** As 60 formas novas em `FORMAS` e os casos da parametrização de
`canonizar` (todos saídos da sonda de 16/09 — a saída está na *Situação* de RV10-3-01 em `a9b07d9`);
Origem Legada, `docs/adr/README.md` e o README (propagação de D43/D44). Nenhum modelo dbt gerado
mudou: a macro é lida no *build*.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
.......................s.....................................s.......... [ 28%]
........................................sss................sss.......... [ 56%]
........................................................................ [ 84%]
.......................................                                  [100%]
247 passed, 8 skipped in 150.94s (0:02:30)
```

### `make dbt-build` ✓

```
11:21:26  890 of 891 START sql view model consumption.payment_approval_rate_by_method .... [RUN]
11:21:26  891 of 891 START sql view model consumption.refund_rate_by_reason .............. [RUN]
11:21:26  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['refunded_amount', 'captured_amount', 'refund_rate_pct']`
11:21:26  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['approval_rate_pct', 'authorized_amount', 'captured_amount']`
11:21:26  891 of 891 OK created sql view model consumption.refund_rate_by_reason ......... [CREATE VIEW in 0.20s]
11:21:26  890 of 891 OK created sql view model consumption.payment_approval_rate_by_method  [CREATE VIEW in 0.21s]
11:21:26
11:21:26  Finished running 1 incremental model, 3 seeds, 4 snapshots, 139 table models, 687 data tests, 5 unit tests, 52 view models in 0 hours 12 minutes and 4.91 seconds (724.91s).
11:21:29
11:21:29  Completed successfully
11:21:29
11:21:29  Done. PASS=891 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=891
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**1. O custo da macro nova no *build* completo foi medido uma vez e é maior do que o recorte
sugeria.** `legacy_presence_by_capture` (101.897 linhas) levou 15,39 s no `dbt build` completo (§3,
com os 4 *threads* disputando) contra 5,66 s no *build* de 15/09; no recorte
`--select legacy_presence_by_capture+`, isolado, 8,65 s contra os mesmos 5,66 s. O total do *build*
caiu (724,9 s contra 777,9 s), o que diz que a diferença está dentro do ruído do conjunto — mas
não medi a macro sozinha, linha a linha, nem comparei planos.

**2. A subquery escalar dentro de `group by 1, 2, 3` foi executada, não explicada.** O PostgreSQL
aceitou e devolveu o mesmo resultado (101.897 linhas, `PASS=891`); não olhei o plano para saber se
a subquery roda uma vez por linha ou é achatada.

**3. A exatidão de `numeric ^ int` foi medida nos expoentes que a macro usa** (`2^63`, `2^64`,
`16^15`, `16^16`, `8^21`, `8^22`, `10^18`, `10^19` — todos exatos) e nas fronteiras de cada base
contra o cast nativo. Não li o código de `power_var_int`; se ele arredondasse em algum expoente
intermediário, a fronteira do teste pegaria só se o erro caísse numa das formas listadas.

**4. A concorrência real de duas transações continua medida só pela sonda do revisor
(EV10-3-02),** não pela suíte: os testes da entrega anterior interpõem o segundo chamador dentro
de `medir_origem`. Nada mudou nisso nesta rodada.

**5. O diário de produção (16 entradas) continua sem `presenca_apos_commit`** e é lido pelo
`RETURNING`; a leitura nova só é exercitada em banco efêmero — decisão D44, não omissão.

**6. `FATO=1`, `CARGA=1`, `make sync-legacy`, DAG, interrupção de *job* real, sequência B–F:** como
nas rodadas anteriores, não repetidos. A mutação só de representação no bruto real (D44) **ainda
não aconteceu** — é do próximo bloco de sincronizações.

**7. A contraprova (b) continua no nível de *staging*,** atribuída à captura 28.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

**1. Que a gramática de `pg_strtoint64` é a que a sonda de 16/09 mediu no 16.15 dos dois bancos** —
brancos `isspace`, sinal, `0x`/`0o`/`0b` em qualquer caixa, `_` entre dígitos ou logo depois do
prefixo, nunca no fim nem dobrado. Não li `numutils.c`; a premissa está codificada em `FORMAS` e o
teste a reconfere contra o cast a cada execução, nos dois bancos.

**2. Que `int2in`/`int4in` têm a mesma gramática do `int8in`** — medido para as formas de
`integer` e `smallint` em `FORMAS` (inclusive `0x8000` e `-0x8000` no `smallint`), não lido no
código-fonte.

**3. Que `numeric ^ int` é exato nos expoentes até 64 com bases 2, 8, 10 e 16** — item 3 da §4.

**4. Que a avaliação de `case` no PostgreSQL é preguiçosa por linha** — a subquery só roda quando a
guarda passou. Nada dentro dela lança para entrada inválida (não há `cast` de texto: a soma é sobre
`position`), então a premissa não afeta a correção, só o custo — sem ela, a soma rodaria para todas
as linhas. Documentado pelo PostgreSQL; não medido.

**5. Que as tabelas do legado continuam pequenas o bastante para `_presenca_canonica` ler a PK
inteira** — 5.500 linhas na maior; o custo por linha agora é linear na entrada.

**6. Que `from test_captura_legado import administradores, efemeros` é uma forma estável de
partilhar fixtures** — funciona porque `tests/` não é pacote e o `rootdir` do pytest o põe no
caminho. Se `tests/` ganhar `__init__.py`, o import muda de forma.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

**1. Gramática em SQL, e não função `safe_cast` no armazém.** A função seria literalmente "a
guarda é o cast" e o par exato do `SAFE_CAST` do BigQuery; custaria DDL novo via *hook* do dbt, uma
subtransação por linha e uma emenda ao ADR-0045. Levei ao Owner em vez de decidir — virou D43,
adiada de propósito (§7).

**2. Subquery escalar com `lateral` em vez de repetir a expressão.** Sem ela, `expressao` apareceria
umas quinze vezes no SQL renderizado de cada um dos 40 ramos; com ela, aparece duas (guarda e
`btrim`). O preço é o item 1 da §4: a macro ficou mais lenta, e não isolei quanto.

**3. Soma de dígitos em `numeric` para as quatro bases, em vez de `bit(64)` para hexa/binário e
tradução para octal.** A rota por *bit strings* devolve o bit 63 como sinal (`0x8000000000000000`
viraria `-2^63` sem o `-`) e não existe para octal; a soma é uma rota só, e a exatidão é medida.

**4. Uma cota de dígitos por base (19/16/22/64) em vez de uma só.** Uma cota única de 64 bastaria
para a correção, mas obrigaria `10^63` e `16^63` a serem exatos — premissa que não precisei fazer.

**5. `_faltas` aceita `None` no intervalo para chave ausente.** Chave removida há duas ou mais
certificadas não está no intervalo e só a memória a responde — é o caso das 5 chaves de produção.
A alternativa (exigir `removida`) reprovaria o ciclo real correto.

**6. O ciclo inteiro em bancos efêmeros resolve `ref('legacy_selected_capture')` para um literal.**
É o que a contraprova (b) já fazia; a alternativa — materializar também `legacy_selected_capture`
— testaria um modelo que não mudou.

**7. D44 como uma decisão, não duas.** As duas respostas do Owner (manter as duas leituras; uma
mutação só de representação) são consequências do mesmo fato — o diário de produção é anterior ao
formato novo — e se resolvem no mesmo bloco de sincronizações.

## 7. Decisões do Owner nesta rodada — para o revisor avaliar

Três perguntas foram levadas ao Owner em 16/09/2026, com alternativas e recomendação; as respostas
estão registradas em `docs/pendencias.md` (D43, D44) e cabem na revisão: o revisor pode discordar da
resposta, da recomendação ou da forma como foi registrada.

| # | Pergunta | Alternativas oferecidas | Resposta do Owner | Registro |
|---|---|---|---|---|
| Q1 | Como a macro decide o que é "conversível": gramática reproduzida em SQL ou função plpgsql `safe_cast` criada pelo dbt? | (a) manter a gramática na macro — recomendada; (b) função `safe_cast` — a guarda é o próprio cast, par do `SAFE_CAST`; (c) adiar e registrar | **(c) adiar** — a gramática fica; a alternativa é decidida na Etapa 13, quando a paridade com `SAFE_CAST` for medida | D43, §1 das Pendências, tabela de pendentes do registro de ADRs |
| Q2 | O que fazer com a bifurcação de `efeito_liquido` (16 entradas sem `presenca_apos_commit`)? | (a) manter as duas leituras até o próximo bloco B–F — recomendada; (b) descartar a leitura antiga agora (o ciclo real passa a pular); (c) regravar o diário com a origem de hoje — desaconselhada por fabricar evidência | **(a)** | D44 |
| Q3 | Deve o ciclo real exercitar a fronteira da identidade (`08`, `+8`, `0x8`), hoje só medida em teste? | (a) uma mutação só de representação pela CLI no próximo bloco B–F — recomendada; (b) injetar representações alternativas no gerador (catálogo, oráculo, D34, ADR); (c) não, o teste basta | **(a)** | D44 |

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

