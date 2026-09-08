# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `1d91102..b733046` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
96314b9 fix: impede que o tratamento do legado esgote a memória da estação
fe6f30a docs: registra ADR-0043 — impedir que o legado esgote a memória da estação
eb18f9e feat: reconcilia o ramo legado da fato por delete+insert
b733046 docs: registra o alcance por origem da exceção incremental
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 15 arquivos

- `README.md`
- `dbt/dbt_project.yml`
- `dbt/models/analytics/_analytics__models.yml`
- `dbt/models/analytics/fact_inventory_movement.sql`
- `dbt/tests/legado_na_fato_segue_a_captura_corrente.sql`
- `docker/docker-compose.yml`
- `docs/adr/0016-materializacao-por-camada.md`
- `docs/adr/0043-impedir-que-o-tratamento-do-legado-esgote-a-estacao.md`
- `docs/adr/README.md`
- `docs/arquitetura.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/origem_legada.md`
- `docs/pendencias.md`
- `tests/test_fato_incremental.py`
- `tests/test_legado_deteccao.py`

### Gerados — 1 arquivos, revisar por amostragem

- `REVISAO.md`

**Declaração desta entrega — revisão integral, seis arquivos.** A classificação automática
acima separa "escrito à mão" de "gerado", que não é a mesma pergunta. O que decide onde gastar
esforço é isto:

| Arquivo | Por que é declaração |
|---|---|
| `docs/adr/0043-...md` | A decisão de memória inteira. Se o raciocínio estiver errado, as três medidas estão |
| `docs/adr/0016-...md` | É o **dono** da regra de materialização. As duas exceções por origem vivem aqui, e mais nenhum lugar as repete |
| `docker/docker-compose.yml` | `jit=off` e o teto de 2 GB. Duas linhas que mudam o comportamento de todo o armazém |
| `dbt/dbt_project.yml` | A materialização por origem do `staging` legado |
| `dbt/models/analytics/fact_inventory_movement.sql` | A **única** implementação do ADR-0042. O `pre_hook` e a condição por origem são o mecanismo inteiro |
| `dbt/tests/legado_na_fato_segue_a_captura_corrente.sql` + `tests/test_fato_incremental.py` | Os oráculos. Se eles estiverem errados, nada mais nesta entrega protege — e o segundo é a única prova de **reprocessamento** que existe |

**Derivado — amostragem basta.** `docs/capacidade_e_recuperacao.md` §2.10, `docs/origem_legada.md`,
`docs/arquitetura.md`, `dbt/models/analytics/_analytics__models.yml`, `docs/pendencias.md`,
`README.md`, `docs/adr/README.md` e `REVISAO.md` são texto e contadores que decorrem das decisões
acima; divergência aqui é sintoma, e o conserto é no dono. `tests/test_legado_deteccao.py` mudou por
consequência mecânica do teto de memória — a consulta única virou uma por tabela e a guarda passou a
perguntar por `information_schema.tables`.

**Onde eu olharia primeiro, se fosse revisar:** o `pre_hook` do
`fact_inventory_movement.sql`. Ele apaga uma partição inteira a cada execução, e a guarda
`is_incremental()` é a única coisa entre isso e a primeira construção.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make test` ✓

```
..s.....................................s............................... [ 48%]
........................................................................ [ 96%]
.....                                                                    [100%]
147 passed, 2 skipped in 77.18s (0:01:17)
```

### `make dbt-build` ✓

```
07:04:16  862 of 863 START sql view model consumption.payment_approval_rate_by_method .... [RUN]
07:04:16  863 of 863 START sql view model consumption.refund_rate_by_reason .............. [RUN]
07:04:16  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['approval_rate_pct', 'authorized_amount', 'captured_amount']`
07:04:16  [WARNING]: Detected columns with numeric type and unspecified precision/scale, this can lead to unintended rounding: ['refunded_amount', 'captured_amount', 'refund_rate_pct']`
07:04:16  862 of 863 OK created sql view model consumption.payment_approval_rate_by_method  [CREATE VIEW in 0.28s]
07:04:16  863 of 863 OK created sql view model consumption.refund_rate_by_reason ......... [CREATE VIEW in 0.28s]
07:04:16
07:04:16  Finished running 1 incremental model, 3 seeds, 4 snapshots, 136 table models, 667 data tests, 52 view models in 0 hours 20 minutes and 8.31 seconds (1208.31s).
07:04:17
07:04:17  Completed successfully
07:04:17
07:04:17  Done. PASS=863 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=863
```

### Medições fora de `comandos.txt`

O `make test` acima roda **sem** `CARGA=1` — é por isso que ele mostra 2 pulados, e um dos dois é
justamente a prova do R25. Medido à parte:

```
$ make test CARGA=1
149 passed in 95.26s (0:01:35)
```

**A contraprova de que o teste do R25 discrimina.** Um teste que passa não vale nada se passaria
também com a estratégia antiga. Com o modelo revertido para `merge` + janela global:

```
>           assert sobrou == 0, (
E           AssertionError: o movimento ausente da captura sobreviveu ao reprocessamento — é o
E           caminho que o `merge` sozinho nunca fecha, porque `merge` só faz upsert
E           assert 1 == 0
1 failed in 20.57s
```

E o segundo caminho, medido direto no banco com a estratégia antiga:

```
alvo=368b3726-d9c7-440c-9d74-8665a20f02ef valor_correto=1390  -> corrompido para 2390
depois do reprocessamento com a estratégia ANTIGA: 2390 (esperado corrigido=1390)
>> NÃO corrigiu — a divergência fora da janela sobrevive
```

**Reconciliação da fato contra a origem, depois da entrega:**

```
fato | origem | saldo_fato | saldo_origem
16453|16453   |729150      |729150
```

**O caminho da primeira construção** — `pre_hook` com `is_incremental()` falso, que precisa
renderizar vazio e ser pulado:

```
$ make dbt-build DBT_ARGS="--select fact_inventory_movement --full-refresh"
1 of 18 OK created sql incremental model analytics.fact_inventory_movement ... [SELECT 16453 in 1.24s]
Done. PASS=18 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=18
```

**O `pre_hook` e o `insert` estão na mesma transação** — conferido no log, um `COMMIT` só fecha o
nó depois dos dois, então não há janela em que a partição legada fique vazia e commitada:

```
04:08:36.245576 [debug] [Thread-1 (]: SQL status: DELETE 553 in 0.023 seconds
04:08:36.263571 [debug] [Thread-1 (]:   create temporary table "fact_inventory_movement__dbt_tmp..."
04:08:36.668748 [debug] [Thread-1 (]: On model.mvp_ed1.fact_inventory_movement: COMMIT
04:08:36.684194 [debug] [Thread-1 (]: SQL status: COMMIT in 0.012 seconds
```

**O recorte por captura não é suposição:** toda a cadeia legada passa por
`legacy_selected_capture`, que fixa um `snapshot_id` — então "tudo que vem do legado" e "a captura
corrente" são o mesmo conjunto, que é o que o `delete+insert` assume.

**As medições do ADR-0043** (custo do JIT, curva por número de braços, pico por estratégia) estão em
[Capacidade §2.10](docs/capacidade_e_recuperacao.md), que é o dono documental delas — não repetidas
aqui.

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**1. Um modo de falha silencioso que esta entrega expôs e NÃO consertou.**
`dbt build --select fact_inventory_movement --full-refresh` derruba por `CASCADE` as três views de
consumo que dependem da fato, e **reporta sucesso**. Reproduzido ao verificar o caminho da primeira
construção: as 16 views viraram 13, e as três que sumiram são exatamente
`gross_margin_by_category`, `inventory_turnover_by_sku_and_warehouse` e
`skus_below_reorder_point` — as únicas que fazem `ref('fact_inventory_movement')`. Restaurei com
`--select fact_inventory_movement+`, e a suíte voltou a 149 passando. **É anterior a esta entrega**
— é a proteção nº 3 da exceção do ADR-0016 (*`--full-refresh` agendado*) com um modo de falha que
ninguém vê —, mas esta entrega a torna mais provável de ser exercida, e eu não a consertei porque
mexer no que a Etapa 12 agenda é escopo que não me foi pedido. Não virou pendência nem nota no dono
documental: está só aqui.

**2. Recaptura real do legado não foi executada.** `tests/test_fato_incremental.py` simula a mudança
de captura **escrevendo na fato** — insere um movimento que a origem não tem e diverge o valor de
outro. Isso prova o mecanismo de materialização, que é o que o ADR-0042 mudou. **Não** prova o ciclo
de ingestão: nenhum `make sync-legacy` rodou, nenhuma captura nova entrou, e o caminho
"registro rejeitado numa captura vira aceito na seguinte" nunca aconteceu de verdade nesta entrega.

**3. O custo do `jit=off` não foi medido do outro lado.** Medi o que ele economiza (2 GB+ → 281 MB
por view de limpeza). Não medi nenhuma consulta analítica que se beneficiaria do JIT, e o ADR aceita
a troca com número de um lado só. Se existir consulta em `analytics` ou `consumption` que fique
lenta, esta entrega não a encontraria.

**4. `make dbt-build` do zero, com banco vazio, não rodou.** Exercitei o `--full-refresh` do modelo
incremental (§3) e o `staging` legado como tabela num banco que já existia. A construção absoluta —
schemas vazios, migrações do zero, `staging` legado nascendo tabela pela primeira vez — não foi
executada nesta entrega.

**5. O teto de 2 GB não foi exercitado sob carga real.** Todas as medições do ADR-0043 foram com só
os três bancos de pé. Não sei o que o armazém consome com Airbyte ou o *streaming* rodando junto, e
o maior pico anônimo que medi foi 433 MB — folga confortável hoje, sem garantia amanhã.

**6. `jit=off` foi aplicado só ao `warehouse_db`.** `source_db` e `legacy_db` continuam com o padrão.
Não medi se eles precisam; presumi que não, porque não têm modelos de expressão grande — mas presumir
é o que esta seção existe para registrar.

**7. R14 não foi reavaliado.** O achado sobre documentos em estados incompatíveis continua aberto no
`REVISAO.md`, e esta entrega mexeu em sete documentos. Conferi os contadores de ADR com
`verificar.py`, e **não** conferi a coerência mais ampla que o R14 cobra.

**8. Nenhuma medição de tempo de execução foi comparada com antes.** O `dbt build` levou 20 min 8 s
com o `staging` legado como tabela. Não tenho o número equivalente com ele como view, porque com view
o build não terminava — travava a máquina. A afirmação "ficou mais rápido" não está feita, e não
poderia estar.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

**1. Que o comportamento do JIT medido no PostgreSQL 16.15-alpine vale para o Cloud SQL.** O
ADR-0043 declara a paridade — `jit` é parâmetro de instância no Cloud SQL, e lá também vem ligado —,
mas isso é leitura de documentação, não medição. A fase GCP pode ter outra versão do LLVM e outro
comportamento.

**2. Que 2 GB é folga suficiente para o armazém no resto do projeto.** O número saiu de "o pico
medido é 433 MB e a falha que se quer conter pedia 7,7 GB". Nada garante que a Etapa 11 ou a 12 não
peçam mais, e se pedirem a falha aparece como contêiner reiniciado — visível, mas ainda falha.

**3. Que `mem_limit` do Compose é o mecanismo certo e não interfere no `shared_buffers`.** Deixei o
PostgreSQL com a configuração de memória padrão (`shared_buffers` 128 MB, `work_mem` 4 MB) debaixo de
um teto de *cgroup*. Não conferi se alguma operação de manutenção do próprio Postgres — `VACUUM
FULL`, reindexação — passa desse teto.

**4. Que o `md5()` que o teste usa como chave substituta do movimento fantasma é compatível com o
que `generate_surrogate_key` produz.** Não precisa ser, para o teste funcionar — a linha só precisa
existir e ser apagada —, mas se algum teste futuro cruzar `movement_key`, essa suposição aparece.

**5. Que o revisor tem a máquina livre.** O `make dbt-build` desta entrega leva 20 minutos e o
`make test CARGA=1` reescreve a partição legada da fato. Rodar os dois com Airbyte ou *streaming* de
pé é o cenário que o ADR-0041 e o `preflight` tratam, e eu não o exercitei aqui.

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

**1. Manter `incremental_strategy='merge'` no `config`.** O ADR-0042 diz `delete+insert`, e o
`config` diz `merge` — parece contradição e não é: o dbt admite uma estratégia por modelo, e a do
`config` é a do ramo `retail`. Trocar para `delete+insert` faria o `config` casar com o vocabulário
do ADR, e mudaria também o mecanismo do `retail`, que está testado e não é o problema. Fui pelo
mínimo e documentei a discrepância no cabeçalho do modelo. **Poderia ter ido para o outro lado**, e
um revisor que ache que a leitura do `config` importa mais que o risco no `retail` tem argumento.

**2. `pre_hook` que apaga a partição, em vez de `post_hook` que apaga órfãos.** O `post_hook` seria
SQL sempre válido, sem depender da guarda `is_incremental()` renderizar vazio. Mas seria
"`merge` mais limpeza", e não `delete+insert` — mecanismo diferente do que o Owner aceitou. Escolhi
o mecanismo decidido e conferi a guarda em vez de contorná-la.

**3. Manter o `NullPool` em `tests/test_legado_deteccao.py` depois de medir que não era ele o
gargalo.** Eu o havia introduzido acreditando que o acúmulo entre consultas explicava o estouro;
a medição isolada mostrou que **uma** view sozinha já passa de 2 GB com o JIT ligado, e derrubou a
hipótese. Mantive porque o acúmulo entre consultas é real (475 MB contra 281 MB) e reescrevi a
justificativa para dizer o que ele é — contenção, não conserto. **Reverter também seria defensável**:
é código cuja motivação original foi refutada.

**4. Um ADR só (0043) para três medidas.** `jit=off`, materialização do `staging` legado e teto nos
bancos poderiam ser dois ou três ADRs. Agrupei porque o Contexto das três é **uma** medição, e
duplicá-lo entre ADRs é o defeito que o `CLAUDE.md` §5 nomeia. O custo é um ADR que decide mais de
uma coisa.

**5. O escopo deste dossiê: `1d91102..HEAD`, e não a sessão inteira.** Tudo anterior a esse ponto já
teve parecer na reavaliação de 08/09 do `REVISAO.md` — inclusive o `preflight`, que foi exercitado
lá. Reexaminar gastaria o orçamento do revisor no que já foi examinado. **Se o revisor discordar, a
base para a sessão inteira é `3447187`.**

**6. Escrever o dossiê em arquivo separado.** O `REVISAO.md` está ocupado por uma revisão com seis
achados ainda abertos (R09, R10, R12, R13, R14, R26). Sobrescrevê-lo apagaria achados que ninguém
respondeu.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

