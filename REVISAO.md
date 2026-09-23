# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `2b2b0f0..3e21a54` — leia o diff, ele não é repetido aqui.

**Rechecagem de 23/09/2026:** as correções posteriores foram revisadas até
`b1011e701beacf89d2f1b25346e4200dc920bcd9`, mantendo o escopo B0/B1/B4.
O parecer atual está na **§11** e na **tabela da segunda rodada**, ao fim.
O intervalo e os pareceres anteriores abaixo permanecem como histórico.

**Aplicação de 23/09/2026:** os cinco achados foram corrigidos em
`fba57cc..8c04106`, com a coluna *Situação* preenchida e as saídas na **§12**.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
5f32370 feat: preflight enxerga o Airflow e acredita no que vê (Etapa 12, B0)
3a0baef feat: instrumento de medição com fim declarado (Etapa 12, B1)
6453bb5 feat: varredura histórica de segredos e coerência dos documentos (Etapa 12, B2 e B3)
0b89b3d fix: credencial do banco de metadados do Airflow sai da composição e vai para o .env
13f0065 feat: ponto único de recuperação e guarda da identidade da captura (Etapa 12, B4)
5e32d0d fix: o pacote pergunta por trabalho em andamento, não por memória para subir
6b811dc fix: o pacote copia os artefatos por padrão, não por nome fixo
3e21a54 fix: o verify lista os dumps por dentro do contêiner, e diz o que conferiu
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 32 arquivos

- `.env.example`
- `Makefile`
- `PLANO_etapa_12.md`
- `airflow/dags/fluxo_batch.py`
- `docker/airflow_cli.sh`
- `docker/conteineres.sh`
- `docker/docker-compose.airflow.yml`
- `docker/medir.sh`
- `docker/preflight.sh`
- `docs/adr/0035-aposentar-dimensoes-sem-pergunta.md`
- `docs/glossario_de_negocio/perguntas_de_negocio.md`
- `docs/origem_legada.md`
- `docs/segredos_tratados.yml`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/docs_check.py`
- `src/mvp_ed1/legacy/identidade.py`
- `src/mvp_ed1/recovery/__init__.py`
- `src/mvp_ed1/recovery/__main__.py`
- `src/mvp_ed1/recovery/cli.py`
- `src/mvp_ed1/recovery/leitura.py`
- `src/mvp_ed1/recovery/oraculos.py`
- `src/mvp_ed1/recovery/pacote.py`
- `src/mvp_ed1/recovery/rebase.py`
- `src/mvp_ed1/secrets_review.py`
- `src/mvp_ed1/streaming/cli.py`
- `src/mvp_ed1/streaming/espera.py`
- `tests/test_docs_check.py`
- `tests/test_identidade_captura.py`
- `tests/test_medicao.py`
- `tests/test_preflight.py`
- `tests/test_recovery.py`
- `tests/test_secrets_review.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega:** **Declaração desta entrega**, e o escopo pedido para esta rodada.

**O Owner pediu revisão escopada em B0, B1 e B4** — o declarativo de que a execução de B5
depende e que **nenhuma execução exercitou**. B2 e B3 (`secrets_review.py`, `docs_check.py`
e os testes deles) estão no diff porque vieram na mesma sequência, mas **não travam B5** e
ficam para a revisão final da entrega, depois de B6. Gastar esforço neles agora é opcional.

**Revisão integral — é daqui que o resto nasce:**

| Arquivo | Por que é declaração |
|---|---|
| `src/mvp_ed1/recovery/rebase.py` | o contrato do re-base (D52 + RV12-4-01). Se ele admitir uma implementação que funde classes de geração, a certificação recusa capturas corretas depois de toda restauração |
| `src/mvp_ed1/recovery/oraculos.py` | a serialização canônica. Se o digest não distinguir conteúdo, o pacote "confere" e devolveu outra coisa |
| `src/mvp_ed1/legacy/identidade.py` | a pré-condição de todo disparo da conexão legada (D50 + RV12-4-03) |
| `src/mvp_ed1/recovery/pacote.py` | o que o pacote guarda, o destino absoluto e os *checksums* |
| `src/mvp_ed1/recovery/leitura.py` | o SQL que alimenta os oráculos — é onde um `select` sem `order by` ou um schema esquecido passaria |
| `src/mvp_ed1/recovery/cli.py` | os verbos, e a sequência de `pg_restore` em destino povoado |
| `Makefile` (alvos `recovery-*`, `dbt-rebuild`, `medir`, `dag-wait`, `stream-wait`) | a sequência de nove passos e o roteamento de `FORCE`/`RESTAURAR` |
| `docker/conteineres.sh` | a resolução por rótulo, consumida pelo preflight e pelo Makefile |
| `docker/preflight.sh` | a decisão de trocar ambiente, e a consulta de trabalho do Airflow |
| `docker/airflow_cli.sh` | as três armadilhas da CLI do Airflow, num lugar só |
| `docker/medir.sh` | o medidor: se ele errar, todo número de B5 sai errado |
| `src/mvp_ed1/streaming/espera.py` | o fim declarado do caminho quente |
| `src/mvp_ed1/airbyte.py` | `disparar` é a **única** porta para o `POST /jobs` — se houver outra, a guarda não existe |

**Derivado, por amostragem:** os arquivos de teste. Eles são muitos e repetitivos de
propósito; o que importa neles é se o **oráculo** está certo, não a repetição.

**Nada aqui é gerado por ferramenta.** A seção "Gerados — 0 arquivos" é verdadeira: esta
entrega não tem código derivado de configuração.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
── 4/4 pytest: código, contratos e integração ──
..................................s..................................... [ 17%]
............................s........................................... [ 35%]
..................sss................sss................................ [ 53%]
........................................................................ [ 71%]
........................................................................ [ 89%]
..........................................                               [100%]
394 passed, 8 skipped in 228.27s (0:03:48)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**Nenhuma restauração foi feita.** É o limite que engloba os outros.

- **`pg_restore` em destino povoado não foi exercitado.** Dependências entre objetos,
  permissões dos cinco papéis, substituição efetiva e propagação de erro são exatamente o
  que `pg_restore --list` **não** confere. O `verify` lista o pacote; listar não é restaurar.
- **O re-base nunca foi aplicado.** Rodou só `--dry-run`, que é leitura: o plano de 27–28
  classes por tabela foi calculado e nada foi escrito em `raw_legacy`. A transação única do
  `update ... case ... end`, a idempotência sobre dado real e a conferência de domínio
  depois da escrita não têm medição.
- **A sequência de nove passos nunca rodou de ponta a ponta.** O que se provou dela é a
  **composição declarada**, lida do `Makefile` — ordem dos passos, ausência de
  `dbt-drop-snapshots`, roteamento de `FORCE`. Nenhum passo foi executado em sequência.
- **`recovery-promote`, `restore-artefatos` e `conferir-restauracao` nunca foram executados.**
  Só têm teste de unidade (`promover`) ou nenhum.
- **A guarda de identidade nunca enfrentou um Airbyte recém-instalado.** E há um ponto
  específico a olhar: `maior_job_conhecido` lê `/jobs?limit=100&orderBy=createdAt|DESC` e
  tira o máximo dos `jobId` devolvidos. **Essa chamada nunca foi feita contra a API real.**
  Se a ordenação não for a que suponho, ou se houver mais de 100 *jobs* e o mais recente
  ficar fora da página, o máximo sai errado — e errado **para menos** faz a guarda recusar
  um disparo legítimo; errado para mais a faz liberar um disparo que colide. Vale conferir
  a forma da resposta e se `limit` e `orderBy` são mesmo esses parâmetros nesta versão.
- **`dbt-rebuild` nunca rodou.** A afirmação de que a quarentena sobrevive ao
  `--full-refresh` porque `rejected_legacy_records` lê a própria tabela anterior é **leitura
  de código**, herdada das rodadas anteriores de revisão do plano — não um rebuild medido.
- **O modo de cenário do medidor nunca rodou contra Redpanda, Connect e Beam reais.** O
  encerramento por grupo de processo, o corte lido depois do produtor e o `stream-wait` têm
  contraprova com `Makefile` de mentira e relógio injetado, e só isso.
- **`espera.pendentes` puxa as chaves dos dois lados para a memória** e faz diferença de
  conjuntos. Com 13.700 movimentos isso é trivial, mas nunca foi medido com dado real.
- **`dag-run` e `dag-wait` nunca mediram uma DAG real.** `airflow dags trigger -o json`
  nunca foi executado: o `run_id` que a implementação espera ler de volta é suposição sobre
  o formato da resposta. `airflow_cli.sh pausar` também nunca rodou.
- **A tarefa da DAG não é exercitada.** O `.venv` não tem `airflow.providers`, então o
  módulo não é importável aqui; o teste é **estrutural, por AST** — garante que ninguém
  troque `disparar` por `sincronizar` de volta, e nada além disso. Está declarado no teste.
- **Os prazos do preflight foram exercitados com relógio falso.** Um *scheduler* lento de
  verdade, uma DAG recém-registrada em ambiente real e uma falha real de `docker stop` não
  foram produzidos.
- **O clone com outro `COMPOSE_PROJECT_NAME` é simulação.** Nenhum clone foi feito.
- **`docs-generate` não foi cronometrado**, e o tempo do digest da quarentena sobre 63.802
  linhas não foi registrado — o `pack` rodou, mas eu não medi quanto essa parte custou.
- **Os números da §0 do plano anteriores a 19/09 não foram remedidos** nesta entrega.
- **B2 e B3 não foram revisados por mim com o mesmo rigor** nesta passagem, por escolha de
  escopo do Owner.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

Cada uma destas é uma afirmação sobre ferramenta, banco ou serviço que **não** foi
confirmada nesta entrega. É a classe de erro que atravessa revisão de código.

- **As cargas novas do Airbyte escrevem gerações não negativas.** É o que mantém a faixa
  retida (negativa) separada da nova. Se uma versão do conector passar a usar negativos, o
  re-base perde o sentido — e o oráculo de domínio não pegaria, porque ele confere o
  **retido**, não o que chega depois.
- **O `jobId` do Airbyte é monotônico e compartilhado entre conexões.** A guarda compara o
  maior *job* conhecido com o maior `snapshot_id` certificado; se o contador não for
  monotônico, a comparação não significa o que eu escrevi que significa.
- **`GET /jobs?limit=100&orderBy=createdAt|DESC` devolve os mais recentes primeiro.** Ver a
  seção 4 — é a premissa mais frágil desta entrega.
- **`pg_restore` devolve 1 para avisos benignos e mais que 1 para falha dura.** Tratei 0 e 1
  como aceitáveis e deixei o passo 5 decidir pelo conteúdo. Se uma falha real sair com 1, a
  sequência segue e só o passo 5 a pega — o que é o desenho, mas depende da premissa.
- **`docker exec -i <contêiner> pg_restore` lê o *dump* por `stdin`.** Funcionou para
  `--list`; para o `--clean --if-exists` de verdade, não foi exercitado.
- **Os rótulos `com.docker.compose.project` e `.service` existem em todo contêiner criado
  pelo Compose**, com ou sem `container_name`. Confirmado nesta máquina, nesta versão.
- **`timeout` e `setsid` (coreutils/util-linux) estão no PATH.** O medidor e o preflight
  dependem dos dois e não conferem a presença.
- **O Airflow 3.2.2 aceita `--state queued` em `dags list-runs`.** Li na saída de `--help`;
  o caso `queued` foi exercitado de verdade na contraprova de B0.
- **O nome da sequência interna de *jobs* do Airbyte (`jobs`, `jobs_id_seq`) continua sendo
  esse.** Não foi confirmado — é a premissa que D50 manda **parar** com mensagem se falhar,
  e o passo correspondente ainda não existe em código.
- **`rejected_legacy_records` retém a fatia antiga ao ser reconstruída com
  `--full-refresh`**, por ler a própria tabela anterior via `adapter.get_relation`. Leitura
  de código, herdada das rodadas anteriores; nenhum rebuild foi medido.

### 5.1 Ambiente que a revisão precisa

> Acrescentado em 21/09/2026, depois da rodada do Codex: o revisor encontrou os três bancos
> fora do ar (E1) e não sabia se podia subi-los. O dossiê não dizia — passa a dizer, e o
> gerador (`dossie.py`) passa a emitir esta seção em toda revisão. Numerada como 5.1 para
> não deslocar as seções 6–9 que o parecer já referencia.

O que precisa estar de pé para as sondas, e como pôr de pé. **Subir é permitido; alterar dado
não.** A regra "deixar o ambiente como o encontrou" vale para o conteúdo dos bancos e dos
volumes — não para contêiner parado ou ausente, que o revisor sobe.

| Precisa de | Como subir | Como conferir |
|---|---|---|
| Os três bancos (`source_db`, `legacy_db`, `warehouse_db`) | `make up` — recria os contêineres sobre os volumes existentes; nada é regerado | `make ps`; portas no `.env` |
| Airbyte, Airflow ou streaming | `make airbyte-up` · `make airflow-up` · `make stream-up` — a troca é automática: pausa o conflitante, retoma depois | `make preflight ALVO=…` responde sem efeito |

Contêiner que não aparece em `docker ps -a` não está em outro contexto Docker: foi derrubado
por `make down`, que preserva os volumes. `make up` o traz de volta. Conferido em 21/09/2026:
`docker context ls` mostra só `default`, e `docker volume ls` mostra `mvp_ed1_source_db_data`,
`mvp_ed1_legacy_db_data` e `mvp_ed1_warehouse_db_data` presentes.

**Nunca** na revisão: `make reset`, `seed-*` ou `*-down` com `FORCE=1`, ou qualquer alvo que
reescreva dado — isso é execução, não revisão. Se o ambiente não puder ser preparado, a
indisponibilidade entra nos achados e o que dependia dela fica **não medido** — nunca inferido.

**O que esta revisão precisa encontrar de pé, além do mínimo acima:**

- os três bancos com os dados da carga atual e a captura do legado certificada (o
  `snapshot_id` 44 citado em RVE-05 vem de `governance.legacy_captures`) — vêm do volume, não
  precisam ser regerados;
- o Airbyte no ar para a contraprova real da listagem de jobs (RVE-01, E2) — já estava;
- o Airflow no ar só para as sondas de `dag-wait`/pausa (RVE-14, RVE-17); `make airflow-up`
  pausa o Airbyte sozinho e `make airbyte-up` o devolve;
- streaming **não** é necessário para esta rodada: as sondas do medidor e do preflight usaram
  dublês por desenho (E6, E7).

## 6. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **Digest em Python, sobre as linhas lidas, em vez de `md5(string_agg(...))` em SQL.** O
  SQL seria mais barato — não puxaria 63.802 linhas da quarentena. Escolhi Python porque um
  oráculo em SQL não é exercitável sem banco, e foi exatamente a falta de contraprova que
  produziu as duas insuficiências que as rodadas 3 e 4 acharam. O custo está declarado no
  módulo. **Se o revisor achar que o volume não justifica, é uma troca razoável de fazer.**
- **Normalização densa por ordem** como regra do re-base, entre as que satisfazem o contrato.
  Alternativas: deslocar tudo por um `offset` fixo abaixo do mínimo (não é idempotente) ou
  numerar por *job* (funde ou separa classes erradas). A densa é idempotente e preserva a
  ordem cronológica; o preço é que os valores **mudam** a cada ciclo, e quem olhar a coluna
  entre dois ciclos vê números diferentes para a mesma geração histórica.
- **O `sync` da conexão legada é *encaminhado* ao fluxo certificado, com ou sem a flag** —
  em vez de recusado exigindo `--certificar-legado`. Encaminhar faz a flag virar redundante
  para essa conexão; recusar seria mais explícito e quebraria quem já usa o comando. Fui de
  encaminhar porque o ramo direto era a entrada que escapava, e deixá-lo aberto com um aviso
  só adiaria o problema. **É uma mudança de comportamento de um comando existente.**
- **O `reset` da conexão legada é recusado por nome**, sem porta de saída. O plano admitia
  "ou exige autorização própria e declarada". Não criei a autorização porque ela ficaria sem
  dono — nenhum alvo a consumiria — e uma porta que ninguém abre é pior que não ter porta. A
  mensagem diz o que fazer à mão, com o pacote montado antes.
- **Os testes da sequência leem o `Makefile` estaticamente.** Queria executá-la com
  registradores, como a §14.3 fez. Não deu: `make -n` executa de verdade toda linha que
  contenha `$(MAKE)`, e a primeira versão disparou `abctl local install`. O que ficou prova
  a composição declarada, não o efeito — e está escrito no teste.
- **`preflight.sh trabalho` como alvo novo**, em vez de uma opção do alvo existente. Alvo
  separado deixa a pergunta explícita para quem lê o `Makefile`; opção teria menos superfície.
- **Encerrar grupo de processo (`setsid`) em vez de PID** no medidor. Matar o grupo alcança
  o Beam sob o `make`; matar o PID deixaria o Beam órfão. O risco do grupo é alcançar mais do
  que se quis — mitigado por cada processo sob guarda nascer no próprio grupo, e há
  contraprova com um processo alheio que precisa sobreviver.
- **A regra "palavra única sem dígito" nos moldes do `secrets_review`** é a mais arriscada da
  entrega: excusa uma senha escrita à mão só com letras. Está declarada no módulo como
  escolha, não cobertura. É de B2, fora do escopo pedido, mas registro aqui porque é onde eu
  menos confio.

---

## 7. Parecer da entrega — 21/09/2026

**Há impedimentos para avançar a B5.** Esta revisão encontrou 17 achados: 12
`bloqueante` e cinco `ajuste`, detalhados na tabela ao fim. A chamada real de
listagem de jobs falha; a validação do medidor executa instalação antes do
preflight; e as conferências de recuperação aceitam estados que o contrato
manda recusar. O verde dos testes amostrados não fecha essas lacunas.

Escopo integral: todos os arquivos de `src/mvp_ed1/recovery/`, `identidade.py`,
`airbyte.py`, os quatro scripts de Docker indicados, `streaming/espera.py` e os
alvos indicados do Makefile. Foram lidos também os chamadores da DAG e da CLI de
streaming, os ADRs 0037/0044/0045 e os modelos/testes necessários para confrontar
os contratos. B2 e B3 ficaram fora desta rodada. As seções 3–6 acima preservam
o relato do autor; as evidências abaixo registram o que esta revisão acrescentou.

O intervalo permanece `2b2b0f0..3e21a54`. O checkout observado era
`e46e87af6f4753fd982c6b8ae1147eefdfcf4143`; a diferença depois de `3e21a54`
era somente este dossiê. Nenhuma implementação foi corrigida nesta sessão.

### Respostas às quatro perguntas prioritárias

1. **API de jobs:** a forma `data[].jobId` e os parâmetros `limit`, `offset`
   e `orderBy` funcionaram no Airbyte disponível, mas o `|` literal da URL
   construída pelo código provoca **400 / Malformed URI**. A mesma ordenação
   com `%7C` funcionou; limite 2 retornou 43/42, offset 2 retornou 41/40 e
   ordem crescente retornou 1/2. **RVE-01, E2.** Não foi criado histórico com
   mais de 100 jobs nem confirmada a monotonicidade do contador interno.
2. **Digest canônico:** não satisfaz o contrato. A sonda produziu tanto
   igualdade de hash para conteúdos diferentes quanto desigualdade para
   valores equivalentes. `timestamptz` e `numeric` aparecem no DDL do dump
   candidato; a contraprova de `bytea` é sobre representações Python, sem
   afirmar presença desse tipo nessas tabelas. **RVE-07, E3/E8.**
3. **Portas de disparo:** a varredura dos arquivos rastreados não encontrou
   outro chamador operacional que contorne `disparar`. O transporte cru
   `sincronizar` continua público, mas seu único chamador de produção encontrado
   é `disparar`. CLI com/sem flag, reset do legado e corpo real da tarefa da
   DAG isolado fizeram **zero POSTs** com contador abaixo do retido. Isso não
   corrige o erro de URL. **E5.**
4. **Re-base em ciclos sucessivos:** não apareceu contraexemplo para a regra
   densa no domínio de inteiros não nulos. Foram conferidos 512 conjuntos e
   4.374 passos em 729 sequências de seis ciclos. A razão geral é que ordenar
   `n` valores distintos e numerá-los de `-n` a `-1` é uma bijeção; reaplicar
   nessa imagem é identidade; acrescentar classes não negativas mantém a
   separação no ciclo seguinte. Isso sustenta a regra pura, **não a aplicação
   SQL**: a conferência da partição não foi ligada à CLI. **RVE-04, E3/E4.**

`dbt-rebuild` declara `governance.garantir` e `dbt build --full-refresh`, sem
`dbt-drop-snapshots`; a retenção da quarentena é declarada pela leitura da
relação anterior. A distinção está correta no código lido. Não houve rebuild
para medir seu efeito. `espera.py` compara conjuntos de chaves e mantém a
espera enquanto falta o último evento; seus testes amostrados exercitaram esse
oráculo. Isso não equivale à comparação das 16 colunas do evento exigida no
passo 9.

## 8. Evidências produzidas nesta revisão

As sondas abaixo ficaram em `/tmp/rve_entrega_YkzQiO/`. Seu código integral
está incluído nos blocos recolhíveis para que a evidência não dependa da
sobrevida desse diretório. Os comandos devem partir da raiz do repositório.
Quando há dublês, eles são identificados: retorno de função com entrada
simulada não é medição de uma restauração. Nenhuma dessas sondas escreve nos
bancos do projeto ou no candidato real.

### E1 — ambiente disponível e limite das leituras do armazém

```bash
git rev-parse HEAD
git diff 3e21a54..HEAD --stat
```

Saída literal:

```text
e46e87af6f4753fd982c6b8ae1147eefdfcf4143
 REVISAO.md | 254 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 254 insertions(+)
```

O ambiente encontrado divergiu da premissa da solicitação. A enumeração
inicial de `docker ps -a` mostrou os contêineres do Airflow parados e não
mostrou os três bancos. A enumeração final, filtrada pelo projeto, foi:

```bash
docker ps -a --filter label=com.docker.compose.project=mvp_ed1 --format '{{.Names}}\t{{.State}}'
docker ps --filter name=airbyte-abctl-control-plane --format '{{.Names}}\t{{.State}}'
```

```text
mvp_ed1-airflow_scheduler-1	exited
mvp_ed1-airflow_apiserver-1	exited
mvp_ed1-airflow_dag_processor-1	exited
mvp_ed1-airflow_init-1	exited
mvp_ed1-airflow_db-1	exited
airbyte-abctl-control-plane	running
```

As tentativas de conexão usaram `default_transaction_read_only=on`,
`BEGIN READ ONLY` e `statement_timeout=5000`. A primeira tentativa no sandbox
retornou `connection is bad: no error details available`. Repetida com acesso
local autorizado, a indisponibilidade foi confirmada sem executar SQL:

```bash
set -a; . ./.env; set +a; .venv/bin/python /tmp/rve_entrega_YkzQiO/bancos.py
```

```text
SOURCE_DB OperationalError connection failed: connection to server at "127.0.0.1", port 5432 failed: Connection refused
LEGACY_DB OperationalError connection failed: connection to server at "127.0.0.1", port 5433 failed: Connection refused
WAREHOUSE_DB OperationalError connection failed: connection to server at "127.0.0.1", port 5434 failed: Connection refused
```

<details>
<summary>Código da sonda <code>bancos.py</code></summary>

```python
import sqlalchemy as sa
from mvp_ed1 import db

for prefix in db.BANCOS:
    engine = sa.create_engine(db.database_url(prefix), connect_args={'connect_timeout': 3, 'options': '-c default_transaction_read_only=on -c statement_timeout=5000'})
    try:
        with engine.connect() as connection:
            connection.exec_driver_sql('BEGIN READ ONLY')
            connection.exec_driver_sql("SET LOCAL statement_timeout = '5s'")
            print(prefix, connection.execute(sa.text('select current_database(), current_setting(\'transaction_read_only\')')).one())
            connection.rollback()
    except sa.exc.OperationalError as error:
        print(prefix, type(error).__name__, str(error.orig).splitlines()[0])
    finally:
        engine.dispose()
```

</details>

### E2 — API real do Airbyte, sem disparo de sincronização

O token foi obtido pelo cliente do projeto, sem imprimir credenciais. Houve
somente autenticação e consultas `GET /jobs`, nenhum `POST /jobs` real.

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/api_airbyte.py
```

**Recortes literais da saída**, incluindo a falha original e todas as
consultas paginadas pequenas; a linha extensa da consulta corrigida com limite
100 foi omitida aqui:

```text
400 em /jobs?limit=100&orderBy=createdAt|DESC: {"message":"Bad Request","_links":{"self":{"href":"/","templated":false}},"_embedded":{"errors":[{"message":"Malformed URI","_links":{},"_embedded":{}}]}}
{"GET": "/jobs?limit=2&orderBy=createdAt%7CDESC", "jobs": [{"createdAt": null, "jobId": 43, "jobType": "sync", "status": "succeeded"}, {"createdAt": null, "jobId": 42, "jobType": "sync", "status": "succeeded"}], "keys": ["data", "next", "previous"], "maior_job_conhecido": 43, "rows": 2}
{"GET": "/jobs?limit=2&offset=2&orderBy=createdAt%7CDESC", "jobs": [{"createdAt": null, "jobId": 41, "jobType": "sync", "status": "succeeded"}, {"createdAt": null, "jobId": 40, "jobType": "reset", "status": "succeeded"}], "keys": ["data", "next", "previous"], "maior_job_conhecido": 41, "rows": 2}
{"GET": "/jobs?limit=2&orderBy=createdAt%7CASC", "jobs": [{"createdAt": null, "jobId": 1, "jobType": "sync", "status": "succeeded"}, {"createdAt": null, "jobId": 2, "jobType": "sync", "status": "succeeded"}], "keys": ["data", "next", "previous"], "maior_job_conhecido": 2, "rows": 2}
```

O `createdAt: null` acima é o `.get()` da sonda sobre o objeto recebido; não é
uma conclusão sobre a coluna usada na ordenação interna. O que foi observado
foi a mudança de ordem dos `jobId`.

```bash
docker exec airbyte-abctl-control-plane crictl images --output json
```

Recorte literal do inventário de imagens, sem tratá-lo como inspeção do
processo servidor:

```json
      "repoTags": [
        "docker.io/airbyte/server:2.2.0"
      ],
      "repoDigests": [
        "docker.io/airbyte/server@sha256:70e125498a1c110bc3e9444ccf9b373cc82517a3cfc68b8d4c54dbc553a4f4eb"
      ],
```

A documentação primária também declara limite até 100, offset e ordenação
por `createdAt`/`updatedAt`: [Airbyte — List Jobs](https://reference.airbyte.com/reference/listjobs).
A contraprova local, e não essa documentação, é a evidência do HTTP 400.

<details>
<summary>Código da sonda <code>api_airbyte.py</code></summary>

```python
import json
import os
import re
import subprocess

from mvp_ed1 import airbyte
from mvp_ed1.legacy import identidade

raw = subprocess.run(['.tools/abctl', 'local', 'credentials'], capture_output=True, text=True, timeout=30)
clean = re.sub(r'\x1b\[[0-9;]*m', '', raw.stdout + raw.stderr)
for label, key in [('Client-Id', 'AIRBYTE_CLIENT_ID'), ('Client-Secret', 'AIRBYTE_CLIENT_SECRET')]:
    match = re.search(label + r':\s+(\S+)', clean)
    if not match:
        raise SystemExit(f'abctl: credencial {label} indisponivel; exit={raw.returncode}')
    os.environ[key] = match[1]
token = airbyte.token()
for path in ['/jobs?limit=100&orderBy=createdAt|DESC', '/jobs?limit=100&orderBy=createdAt%7CDESC', '/jobs?limit=2&orderBy=createdAt%7CDESC', '/jobs?limit=2&offset=2&orderBy=createdAt%7CDESC', '/jobs?limit=2&orderBy=createdAt%7CASC']:
    try:
        result = airbyte._chamar(path, token)
    except airbyte.AirbyteIndisponivel as error:
        print(str(error))
        continue
    rows = result.get('data', [])
    print(json.dumps({'GET': path, 'keys': sorted(result), 'rows': len(rows), 'jobs': [{k: r.get(k) for k in ('jobId', 'createdAt', 'jobType', 'status')} for r in rows], 'maior_job_conhecido': identidade.maior_job_conhecido(lambda: result)}, sort_keys=True))
```

</details>

### E3 — serialização e ciclos do re-base, com funções reais

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/oraculos_rebase.py
```

```text
NULL vs texto \N: valores_iguais=False; digests_iguais=True
separador dentro de texto: valores_iguais=False; digests_iguais=True
mesmo instante, outro fuso: valores_iguais=True; digests_iguais=False
Decimal com escala diferente: valores_iguais=True; digests_iguais=False
bytea bytes vs memoryview: valores_iguais=True; digests_iguais=False
bytea duas memoryviews: valores_iguais=True; digests_iguais=False
rebase: 512 dominios; 4374 passos em 729 sequencias de seis ciclos; violacoes=0
decidir real: complete e inconsistent preservados em 10 casos; medir_recebido SQL nao executado
dominio_valido sobre iter([0, 1]): []
```

Os casos de nulo e separador são **colisões da serialização**, sem ataque ao
MD5. As contraprovas de representação usam objetos Python equivalentes;
nenhuma migração entre drivers ou mudança de fuso do banco foi executada.

<details>
<summary>Código da sonda <code>oraculos_rebase.py</code></summary>

```python
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from itertools import combinations, product
from mvp_ed1.recovery import oraculos as o, rebase as r
from mvp_ed1.legacy import captura

pairs = [
    ('NULL vs texto \\N', {'v': None}, {'v': r'\N'}),
    ('separador dentro de texto', {'a': 'x\x1fb=y', 'b': 'z'}, {'a': 'x', 'b': 'y\x1fb=z'}),
    ('mesmo instante, outro fuso', {'v': datetime(2026, 9, 21, 12, tzinfo=timezone.utc)}, {'v': datetime(2026, 9, 21, 9, tzinfo=timezone(timedelta(hours=-3)))}),
    ('Decimal com escala diferente', {'v': Decimal('1.00')}, {'v': Decimal('1.0')}),
    ('bytea bytes vs memoryview', {'v': b'abc'}, {'v': memoryview(b'abc')}),
    ('bytea duas memoryviews', {'v': memoryview(b'abc')}, {'v': memoryview(b'abc')}),
]
for name, a, b in pairs:
    print(f'{name}: valores_iguais={a == b}; digests_iguais={o.digest([a]) == o.digest([b])}')

domains = [s for n in range(10) for s in combinations(range(-4, 5), n)]
checked = 0
for values in domains:
    mapping = r.plano(values)
    assert not r.conforme(mapping)
    assert len(set(mapping.values())) == len(values)
    assert all(v < 0 for v in mapping.values())
    assert r.plano(mapping.values()) == {v: v for v in mapping.values()}
    checked += 1
cycles = 0
for additions in product([(), (0,), (1, 2)], repeat=6):
    rows = [('a', -9), ('b', -9), ('c', 3)]
    for cycle, fresh in enumerate(additions):
        rows += [(f'{cycle}:{v}', v) for v in fresh]
        before = r.particao(rows)
        mapping = r.plano(v for _, v in rows)
        rows = [(key, mapping[v]) for key, v in rows]
        assert not r.particao_preservada(before, r.particao(rows))
        assert not r.dominio_valido([v for _, v in rows])
        cycles += 1
print(f'rebase: {checked} dominios; {cycles} passos em {3**6} sequencias de seis ciclos; violacoes=0')

for generation in (-20, -1, 0, 1, 50):
    mapping = r.plano([generation, generation+1])
    for intruders in (0, 1):
        a = captura.Medida(2, 'mesmo-conteudo')
        before = captura.Recebido(2, a.hash, (generation,), intruders)
        after = captura.Recebido(2, a.hash, (mapping[generation],), intruders)
        assert captura.decidir(a, a, before) == captura.decidir(a, a, after)
print('decidir real: complete e inconsistent preservados em 10 casos; medir_recebido SQL nao executado')
print('dominio_valido sobre iter([0, 1]):', r.dominio_valido(iter([0, 1])))
```

</details>

### E4 — os limites efetivos dos passos 5 e 9, D50 e publicação do pacote

As funções de decisão e da CLI são reais; motores, leituras e subprocesso do
restore são dublês. O candidato usado na falha de `pack` é um diretório
temporário separado, com um arquivo fictício. O pacote real não é passado à
função de escrita.

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/recovery_limites.py
```

```text
[recovery] quarentena: 1 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 1 snapshot(s) conferidos pelo digest canônico de todas as colunas
passo5: problemas=[]; leituras=['oraculo_da_quarentena', 'oraculo_scd']
[recovery] quarentena: 1 fatia(s) do manifesto contidas, 0 acrescentada(s) pela captura nova
[recovery] captura selecionada: 44 (certificada)
conferir-restauracao: memória contida, versões intactas, identidade nova acima da retida e faixas de geração separadas.
  A comparação dos dois caminhos e as oito fronteiras são do `make check` do passo 8.
passo9: exit=0; leituras=['versoes_do_armazem', 'oraculo_scd', 'oraculo_da_quarentena', 'oraculo_das_capturas', 'maior_event_sequence']
fixture: certificados 9/43 ausentes; geracoes so positivas; quarentena sem fatia 44; contagens divergentes
[recovery] avisos de falso: pg_restore: warning: errors ignored on restore: 1
pg_restore simulado: exit=1 + erro COPY => funcao retornou sem recusar
D50: jobs=[3], certificada=43 => recusado; avancar so a sequencia nao altera GET /jobs
pack simulado com falha: candidato_anterior_preservado=False
```

A afirmação da linha D50 sobre a sequência é uma **inferência do contrato da
API e do código**: o ensaio não executa `setval`. Ele mostra que a guarda só
recebe o histórico de jobs. Uma sequência avançada sem job criado não altera
essa entrada; o futuro passo operacional precisa conferir essa distinção.

O significado do retorno 1 foi conferido no [código do PostgreSQL 16](https://github.com/postgres/postgres/blob/REL_16_STABLE/src/bin/pg_dump/pg_restore.c):
`exit_code = AH->n_errors ? 1 : 0;`. Ele representa erros acumulados de
restauração, não uma categoria de aviso benigno. `--if-exists` já trata o caso
de objetos ausentes, e `--exit-on-error` interrompe no erro SQL, conforme a
[documentação de pg_restore 16](https://www.postgresql.org/docs/16/app-pgrestore.html).
Não foi executado restore para produzir esse erro real.

```bash
git grep -n -E 'jobs_id_seq|setval|maior_job_conhecido|particao_preservada|particao\(' -- src/mvp_ed1/recovery src/mvp_ed1/legacy/identidade.py Makefile
```

```text
src/mvp_ed1/legacy/identidade.py:52:def maior_job_conhecido(listar: Callable[[], Any]) -> int | None:
src/mvp_ed1/legacy/identidade.py:70:    return maior_job_conhecido(listar), (max(certificadas) if certificadas else None)
src/mvp_ed1/recovery/rebase.py:130:def particao(linhas: Iterable[tuple[object, int | None]]) -> dict[int | None, frozenset]:
src/mvp_ed1/recovery/rebase.py:143:def particao_preservada(antes: Mapping, depois: Mapping) -> list[str]:
```

Leitura da composição, **sem executar o alvo**:

```bash
nl -ba Makefile | sed -n '465,488p'
```

```text
   465		@echo "── 1/9 conferindo o pacote ──"
   466		@$(MAKE) --no-print-directory recovery-verify DIR="$(RECOVERY_DIR)"
   467		@echo "── 2/9 manutenção: janela parada, DAG pausada ──"
   468		@docker/preflight.sh trabalho || { echo "RECUSADO — há trabalho em andamento."; exit 1; }
   469		@$(AIRFLOW_CLI) pausar $(DAG) || true
   470		@echo "── 3/9 descartando o CDC enquanto a origem antiga ainda existe ──"
   471		@$(MAKE) --no-print-directory stream-down FORCE=1
   472		@$(MAKE) --no-print-directory stream-reset-sink FORCE=1
   473		@echo "── 4/9 pg_restore das duas fontes e da memória do armazém ──"
   474		@$(RECOVERY) --dir "$(RECOVERY_DIR)" restore-dumps
   475		@echo "── 4b/9 re-base das gerações retidas (D52) ──"
   476		@$(MAKE) --no-print-directory recovery-rebase
   477		@echo "── 5/9 conferindo o conteúdo restaurado contra o manifesto ──"
   478		@$(MAKE) --no-print-directory recovery-verify DIR="$(RECOVERY_DIR)" CONTRA_O_BANCO=1
   479		@echo "── 6/9 devolvendo os artefatos de trabalho ──"
   480		@$(RECOVERY) --dir "$(RECOVERY_DIR)" restore-artefatos
   481		@echo "── 7/9 novo snapshot do caminho quente ──"
   482		@$(MAKE) --no-print-directory medir CENARIO=streaming FORCE=
   483		@echo "── 8/9 reconstruindo sem apagar o que acabou de voltar ──"
   484		@$(MAKE) --no-print-directory airbyte-up FORCE=
   485		@$(MAKE) --no-print-directory sync-airbyte RESET=1
   486		@$(MAKE) --no-print-directory sync-legacy
   487		@$(MAKE) --no-print-directory dbt-rebuild
   488		@$(MAKE) --no-print-directory check
```

O teste `dbt/tests/caminhos_de_ingestao_reconciliam.sql`, lido integralmente,
consulta flags de chegada e tempos. Ele não compara os payloads dos dois
caminhos nem substitui o oráculo explícito do passo 9.

<details>
<summary>Código da sonda <code>recovery_limites.py</code></summary>

```python
import argparse
import contextlib
import copy
import io
import pathlib
import subprocess
import tempfile
from unittest.mock import Mock, patch
from mvp_ed1.recovery import cli, leitura, pacote
from mvp_ed1.legacy import identidade

manifest = pacote.Manifesto({
    'contagens': {'source_db': {'oltp.customers': 10}, 'legacy_db': {'legacy.customers': 10}, 'warehouse_db': {'raw_legacy.customers': 20}},
    'alembic': {'source_db': 'head-source', 'legacy_db': 'head-legacy'},
    'governance_versions': ['v1'], 'max_event_sequence': 100,
    'oraculo_scd': {'scd_customer': {'linhas': 2, 'versoes': 2, 'digest': 'igual'}},
    'oraculo_quarentena': {'legacy|43|9|hash': {'linhas': 1, 'digest': 'igual'}},
    'oraculo_capturas': {'maior_snapshot': 43, 'certificadas': [9, 43], 'geracoes_por_tabela': {'customers': {'minima': 1, 'maxima': 2, 'classes': 2, 'nulas': 0}}},
})
calls = []
def read(name, value):
    def inner(*args, **kwargs):
        calls.append(name)
        return copy.deepcopy(value)
    return inner

with contextlib.ExitStack() as stack:
    stack.enter_context(patch.object(cli, '_motor', return_value=Mock()))
    fixtures = {
        'oraculo_scd': manifest.dados['oraculo_scd'],
        'oraculo_da_quarentena': manifest.dados['oraculo_quarentena'],
        'contagens': {'raw_legacy.customers': 0},
        'alembic_current': 'versao-errada',
        'versoes_do_armazem': ['versao-errada'],
        'oraculo_das_capturas': {'certificadas': [], 'maior_snapshot': None, 'geracoes_por_tabela': {}},
    }
    for name, value in fixtures.items():
        stack.enter_context(patch.object(leitura, name, side_effect=read(name, value)))
    problems = cli._conferir_contra_o_banco(manifest)
    print('passo5: problemas=', problems, '; leituras=', calls, sep='')

calls.clear()
with contextlib.ExitStack() as stack:
    stack.enter_context(patch.object(cli, '_motor', return_value=Mock()))
    stack.enter_context(patch.object(cli, '_pasta_do_pacote', return_value=pathlib.Path('/nao-usado')))
    stack.enter_context(patch.object(pacote.Manifesto, 'ler', return_value=manifest))
    fixtures.update({
        'versoes_do_armazem': ['v1'],
        'maior_event_sequence': 100,
        'oraculo_das_capturas': {'certificadas': [44], 'maior_snapshot': 44, 'geracoes_por_tabela': {'customers': {'minima': 1, 'maxima': 1, 'classes': 1, 'nulas': 0}}},
    })
    for name, value in fixtures.items():
        stack.enter_context(patch.object(leitura, name, side_effect=read(name, value)))
    result = cli.comando_conferir_restauracao(argparse.Namespace(dir=None))
    print('passo9: exit=', result, '; leituras=', calls, sep='')
    print('fixture: certificados 9/43 ausentes; geracoes so positivas; quarentena sem fatia 44; contagens divergentes')

with tempfile.TemporaryDirectory(prefix='rve-restore-mock-') as tmp:
    dump = pathlib.Path(tmp) / 'falso.dump'
    dump.write_bytes(b'nenhum dump real')
    error = b'pg_restore: error: COPY failed: duplicate key\npg_restore: warning: errors ignored on restore: 1\n'
    with patch.object(cli, '_conteineres', return_value='docker-falso'), patch.object(cli.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, b'', error)):
        cli._pg_restore('source_db', 'falso', 'falso', dump)
        print('pg_restore simulado: exit=1 + erro COPY => funcao retornou sem recusar')

with patch('mvp_ed1.legacy.captura.certificadas', return_value=[43]):
    try:
        identidade.exigir(Mock(), lambda: {'data': [{'jobId': 3}]})
    except identidade.IdentidadeReutilizada:
        print('D50: jobs=[3], certificada=43 => recusado; avancar so a sequencia nao altera GET /jobs')

with tempfile.TemporaryDirectory(prefix='rve-pack-mock-') as tmp:
    root = pathlib.Path(tmp)
    candidate = root / 'candidato'
    candidate.mkdir()
    (candidate / 'volta.dump').write_bytes(b'pacote anterior ficticio')
    with patch.object(pacote, 'arvore_suja', return_value=''), patch.object(cli, '_env', return_value='falso'), patch.object(cli, '_pg_dump', side_effect=pacote.PacoteRecusado('falha simulada no primeiro dump')), contextlib.redirect_stdout(io.StringIO()):
        try:
            cli.comando_pack(argparse.Namespace(dir=tmp, permitir_arvore_suja=False))
        except pacote.PacoteRecusado:
            pass
    print('pack simulado com falha: candidato_anterior_preservado=', (candidate / 'volta.dump').exists(), sep='')
```

</details>

### E5 — varredura dos disparos e contraprovas nas entradas

Foi usado `git grep` sobre todos os arquivos rastreados, seguido da leitura
dos resultados e dos chamadores. As conexões Terraform declaram agendamento
manual. Esta é a busca final restrita a código/configuração, sem os testes:

```bash
git grep -n -E '(/jobs|jobType|connections/sync|create_job|submit_sync|AirbyteTrigger|airbyte[.]sincronizar|airbyte[.]disparar|sincronizar\(connection_id|disparar\(nome|disparar\(args)' -- '*.py' '*.sh' '*.tf' '*.yml' '*.yaml' Makefile ':!tests/*'
```

```text
airflow/dags/fluxo_batch.py:98:        criado = airbyte.disparar(conexao, connection_id, jwt)
src/mvp_ed1/airbyte.py:85:def sincronizar(connection_id: str, jwt: str, tipo: str = "sync") -> dict:
src/mvp_ed1/airbyte.py:86:    return _chamar("/jobs", jwt, {"connectionId": connection_id, "jobType": tipo})
src/mvp_ed1/airbyte.py:95:    return _chamar(f"/jobs?limit={limite}&orderBy=createdAt|DESC", jwt)
src/mvp_ed1/airbyte.py:131:    return sincronizar(connection_id, jwt, tipo)
src/mvp_ed1/airbyte.py:147:            return _chamar(f"/jobs/{job_id}", atual)
src/mvp_ed1/airbyte.py:152:            return _chamar(f"/jobs/{job_id}", atual)
src/mvp_ed1/airbyte.py:197:        job = disparar(nome, connection_id, jwt)
src/mvp_ed1/airbyte.py:245:            job = acompanhar(disparar(args.connection, connection_id, jwt, tipo)["jobId"], jwt)
src/mvp_ed1/legacy/identidade.py:19:`--certificar-legado`, chega ao `POST /jobs` pelo ramo direto do `main`, e a
```

As chamadas abaixo executam o `main` real e o corpo da tarefa obtido por AST,
com transporte e banco simulados. Não executam o operador/scheduler Airflow:

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/entradas.py
```

```text
CLI sync: exit=3; POST /jobs=0
CLI sync --certificar-legado: exit=3; POST /jobs=0
CLI reset: exit=3; POST /jobs=0
corpo real da tarefa DAG isolado: recusou identidade; POST /jobs=0
src/mvp_ed1/airbyte.py:131: sincronizar
src/mvp_ed1/airbyte.py:197: disparar
src/mvp_ed1/airbyte.py:245: disparar
airflow/dags/fluxo_batch.py:98: airbyte.disparar
```
<details>
<summary>Código da sonda <code>entradas.py</code></summary>

```python
import ast
import contextlib
import io
import os
from pathlib import Path
from unittest.mock import Mock, patch
from mvp_ed1 import airbyte
from mvp_ed1.legacy import captura, identidade

posts = []
def transport(path, token=None, corpo=None):
    if path == '/connections':
        return {'data': [{'name': identidade.CONEXAO_LEGADA, 'connectionId': 'id-legado'}]}
    if path.startswith('/jobs?'):
        return {'data': [{'jobId': 3}]}
    if path == '/jobs' and corpo:
        posts.append(corpo)
        return {'jobId': 4}
    raise AssertionError(path)

with contextlib.ExitStack() as stack:
    stack.enter_context(patch.object(airbyte, '_chamar', side_effect=transport))
    stack.enter_context(patch.object(airbyte, 'token', return_value='token-ficticio'))
    stack.enter_context(patch('sqlalchemy.create_engine', return_value=Mock()))
    stack.enter_context(patch('mvp_ed1.db.database_url', return_value='url-ficticia'))
    stack.enter_context(patch.object(captura, 'certificadas', return_value=[43]))
    stack.enter_context(patch.object(captura, 'iniciar', return_value='tentativa-ficticia'))
    stack.enter_context(patch.dict(os.environ, {'AIRBYTE_CLIENT_ID': 'ficticio'}))
    for command in ['sync', 'sync --certificar-legado', 'reset']:
        posts.clear()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            result = airbyte.main([*command.split(), '--connection', identidade.CONEXAO_LEGADA])
        print('CLI ' + command + ': exit=' + str(result) + '; POST /jobs=' + str(len(posts)))
    tree = ast.parse(Path('airflow/dags/fluxo_batch.py').read_text())
    task = next(n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef) and n.name == 'sincronizar')
    task.decorator_list = []
    namespace = {'os': os}
    exec(compile(ast.fix_missing_locations(ast.Module(body=[task], type_ignores=[])), 'corpo-real-da-tarefa', 'exec'), namespace)
    posts.clear()
    try:
        namespace['sincronizar'](identidade.CONEXAO_LEGADA, 'tentativa-ja-existente')
    except identidade.IdentidadeReutilizada:
        print('corpo real da tarefa DAG isolado: recusou identidade; POST /jobs=' + str(len(posts)))

for path in ['src/mvp_ed1/airbyte.py', 'airflow/dags/fluxo_batch.py']:
    tree = ast.parse(Path(path).read_text())
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and ast.unparse(node.func) in ['sincronizar', 'disparar', 'airbyte.disparar', 'airbyte.sincronizar']:
            print(f'{path}:{node.lineno}: {ast.unparse(node.func)}')
```

</details>

### E6 — medidor e identidade da execução esperada

Cópia integral do Makefile em diretório temporário; `docker`, `abctl` e
preflight substituídos por registradores. **Nenhuma instalação ocorreu.** O
medidor e o `make` são reais. A interrupção sinaliza apenas o processo criado
pela sonda, que limpa seu grupo no `finally`.

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/medicao_cli.py
```

```text
medir airbyte-up => exit=0
chamadas isoladas: ['abctl local install --values airbyte/values.yaml', 'preflight airbyte --trocar', 'abctl local install --values airbyte/values.yaml']
medir airbyte-up --ate alvo-inexistente-rve => exit=2
chamadas isoladas: ['abctl local install --values airbyte/values.yaml']
ERRO: 'alvo-inexistente-rve' não é um alvo do Makefile — nada foi medido.
interrupcao: exit=130; jsons=0
mensagem_interrompido=True
dag-wait pedida=rve-10, resposta=rve-100; exit=0
[dag-wait] rve-10 terminou: success (0s de espera)
```

O comportamento de receitas recursivas sob `make -n` também está documentado
no [manual do GNU Make](https://www.gnu.org/software/make/manual/make.html):
linhas com `$(MAKE)` continuam sendo executadas. O efeito específico sobre
`airbyte-up` foi observado acima com o Makefile desta entrega.

Uma primeira versão da sonda de interrupção esperou o fechamento dos pipes
antes de recolher o processo e atingiu timeout de 10 s. A versão reproduzível
abaixo faz `wait()` antes de `communicate()` e limpa seu grupo; a saída acima
é dessa versão. O timeout do primeiro arranjo não é contado como defeito do
produto.

<details>
<summary>Código da sonda <code>medicao_cli.py</code></summary>

```python
import json
import os
import pathlib
import signal
import subprocess
import tempfile
import time

ROOT = pathlib.Path.cwd()
def executable(path, body):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('#!/bin/bash\n' + body)
    path.chmod(0o755)

with tempfile.TemporaryDirectory(prefix='rve-medir-') as tmp:
    work = pathlib.Path(tmp)
    (work / 'Makefile').write_text((ROOT / 'Makefile').read_text())
    executable(work / 'bin/docker', 'case "$1" in ps) exit 0;; stats) echo "10MiB / 1GiB";; *) exit 98;; esac\n')
    executable(work / '.tools/abctl', 'echo "abctl $*" >> "$RVE_LOG"\n')
    executable(work / 'docker/preflight.sh', 'echo "preflight $*" >> "$RVE_LOG"\n')
    env = os.environ | {'PATH': str(work / 'bin') + ':' + os.environ['PATH'], 'RVE_LOG': str(work / 'calls'), 'MEDIR_DIR': str(work / 'medicoes'), 'MEDIR_INTERVALO': '0.1'}
    for suffix in [[], ['--ate', 'alvo-inexistente-rve']]:
        (work / 'calls').write_text('')
        result = subprocess.run([str(ROOT / 'docker/medir.sh'), 'airbyte-up', *suffix], cwd=work, env=env, capture_output=True, text=True, timeout=15)
        print('medir airbyte-up', *suffix, '=> exit=' + str(result.returncode))
        print('chamadas isoladas:', (work / 'calls').read_text().splitlines())
        if suffix:
            print(result.stderr.strip())

with tempfile.TemporaryDirectory(prefix='rve-interromper-') as tmp:
    work = pathlib.Path(tmp)
    (work / 'Makefile').write_text('alvo:\n\t@touch pronto; sleep 2\n')
    executable(work / 'bin/docker', 'case "$1" in ps) exit 0;; stats) echo "10MiB / 1GiB";; *) exit 98;; esac\n')
    env = os.environ | {'PATH': str(work / 'bin') + ':' + os.environ['PATH'], 'MEDIR_DIR': str(work / 'medicoes'), 'MEDIR_INTERVALO': '0.1'}
    process = subprocess.Popen([str(ROOT / 'docker/medir.sh'), 'alvo'], cwd=work, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True)
    deadline = time.monotonic() + 5
    while not (work / 'pronto').exists() and time.monotonic() < deadline:
        time.sleep(.05)
    process.send_signal(signal.SIGTERM)
    try:
        process.wait(timeout=6)
        stdout, stderr = process.communicate(timeout=3)
    finally:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    print('interrupcao: exit=', process.returncode, '; jsons=', len(list((work / 'medicoes').glob('*.json'))), sep='')
    print('mensagem_interrompido=', '[medir] interrompido' in stdout, sep='')

command = r'''
. docker/airflow_cli.sh
airflow_cli() {
    case "$*" in
        *'--state success'*) echo '[{"run_id":"rve-100","state":"success"}]' ;;
        *) echo '[]' ;;
    esac
}
airflow_aguardar_run fluxo_batch rve-10 0
'''
result = subprocess.run(['bash', '-c', command], capture_output=True, text=True, timeout=5)
print('dag-wait pedida=rve-10, resposta=rve-100; exit=', result.returncode, sep='')
print(result.stdout.strip())
```

</details>

Duas medições sucessivas, no mesmo dia e diretório, contra um alvo fictício:

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/registro_repetido.py
```

```text
execucao=1; exit=0; registros=1
execucao=2; exit=0; registros=1
primeiro_registro_preservado=False
campos_gravados=['alvo', 'amostragem', 'ate', 'codigo_de_saida', 'duracao_involucro_s', 'estacao', 'fim', 'inicio', 'interrompido', 'limite']
```

O marcador é inserido somente no JSON temporário da primeira execução, para
observar se o arquivo é preservado. O segundo registro o substitui. Em B5,
snapshot, produção e recuperação usam o mesmo nome `cenario:streaming`.

<details>
<summary>Código da sonda <code>registro_repetido.py</code></summary>

```python
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path.cwd()
with tempfile.TemporaryDirectory(prefix='rve-registros-') as tmp:
    work = Path(tmp)
    (work / 'Makefile').write_text('alvo:\n\t@sleep 0.2\n')
    (work / 'bin').mkdir()
    docker = work / 'bin/docker'
    docker.write_text('#!/bin/bash\ncase "$1" in ps) exit 0;; stats) echo "10MiB / 1GiB";; *) exit 98;; esac\n')
    docker.chmod(0o755)
    env = os.environ | {'PATH': str(work / 'bin') + ':' + os.environ['PATH'], 'MEDIR_DIR': str(work / 'medicoes'), 'MEDIR_INTERVALO': '0.1'}
    for i in (1, 2):
        result = subprocess.run([str(root / 'docker/medir.sh'), 'alvo'], cwd=work, env=env, capture_output=True, text=True, timeout=10)
        paths = list((work / 'medicoes').glob('*.json'))
        print(f'execucao={i}; exit={result.returncode}; registros={len(paths)}')
        if i == 1:
            first = paths[0]
            data = json.loads(first.read_text())
            data['marcador_da_primeira_execucao'] = True
            first.write_text(json.dumps(data))
    data = json.loads(first.read_text())
    print('primeiro_registro_preservado=' + str('marcador_da_primeira_execucao' in data))
    print('campos_gravados=' + repr(sorted(data)))
```

</details>

### E7 — preflight: indeterminação, trabalho no host e pausa parcial

Scripts reais com Docker e `pgrep` simulados. Nenhum contêiner real é parado:

```bash
.venv/bin/python /tmp/rve_entrega_YkzQiO/preflight.py
```

```text
Docker ilegivel: exit=0
[preflight] nenhum trabalho em andamento — janela parada.
pgrep_consultado=False
mutacoes_simuladas=[]
estado_simulado_final={}
produtor ativo sem transporte: exit=0
[preflight] nenhum trabalho em andamento — janela parada.
pgrep_consultado=False
mutacoes_simuladas=[]
estado_simulado_final={}
pausa parcial do Airflow: exit=1
RECUSADO — não consegui pausar Airflow, e ele continua de pé.
pgrep_consultado=False
mutacoes_simuladas=['docker stop rve-airflow_scheduler rve-airflow_apiserver rve-airflow_dag_processor rve-airflow_db']
estado_simulado_final={"airflow_apiserver": "exited", "airflow_dag_processor": "exited", "airflow_db": "exited", "airflow_scheduler": "up"}
```
<details>
<summary>Código da sonda <code>preflight.py</code></summary>

```python
import json
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path.cwd()
DOCKER = r'''
import json, os, pathlib, sys
args = sys.argv[1:]
state_file = pathlib.Path(os.environ['RVE_STATE'])
state = json.loads(state_file.read_text())
with open(os.environ['RVE_LOG'], 'a') as log:
    log.write('docker ' + ' '.join(args) + '\n')
if args[0] == 'ps':
    if os.environ.get('RVE_PS_FAIL') == '1':
        sys.exit(1)
    for service, status in state.items():
        if '-a' not in args and status != 'up':
            continue
        filters = [args[i+1] for i, v in enumerate(args) if v == '--filter']
        if any(f.startswith('label=com.docker.compose.service=') and f.rsplit('=', 1)[-1] != service for f in filters):
            continue
        print('rve-' + service)
elif args[0] == 'exec':
    print('[]')
elif args[0] in ('stop', 'start'):
    for name in args[1:]:
        service = name.removeprefix('rve-')
        if args[0] == 'stop' and service == 'airflow_scheduler':
            continue
        state[service] = 'up' if args[0] == 'start' else 'exited'
    state_file.write_text(json.dumps(state))
else:
    sys.exit(98)
'''
for name, state, extra, args in [
    ('Docker ilegivel', {}, {'RVE_PS_FAIL': '1'}, ['trabalho']),
    ('produtor ativo sem transporte', {}, {}, ['trabalho']),
    ('pausa parcial do Airflow', {s: 'up' for s in ['airflow_scheduler', 'airflow_apiserver', 'airflow_dag_processor', 'airflow_db']}, {}, ['streaming', '--trocar']),
]:
    with tempfile.TemporaryDirectory(prefix='rve-preflight-') as tmp:
        work = pathlib.Path(tmp)
        (work / 'docker').write_text('#!' + sys.executable + '\n' + DOCKER)
        (work / 'docker').chmod(0o755)
        (work / 'pgrep').write_text('#!/bin/bash\necho pgrep >> "$RVE_LOG"\nexit 0\n')
        (work / 'pgrep').chmod(0o755)
        (work / 'state').write_text(json.dumps(state))
        (work / 'log').write_text('')
        env = os.environ | {'PATH': str(work) + ':' + os.environ['PATH'], 'RVE_STATE': str(work / 'state'), 'RVE_LOG': str(work / 'log'), 'COMPOSE_PROJECT_NAME': 'rve'} | extra
        result = subprocess.run([str(ROOT / 'docker/preflight.sh'), *args], env=env, capture_output=True, text=True, timeout=15)
        logs = (work / 'log').read_text().splitlines()
        after = json.loads((work / 'state').read_text())
        print(name + ': exit=' + str(result.returncode))
        print('\n'.join(line for line in result.stdout.splitlines() if 'janela parada' in line or 'RECUSADO' in line))
        print('pgrep_consultado=' + str('pgrep' in logs))
        print('mutacoes_simuladas=' + repr([line for line in logs if line.startswith(('docker stop', 'docker start'))]))
        print('estado_simulado_final=' + json.dumps(after, sort_keys=True))
```

</details>

### E8 — leitura do candidato preservado

```bash
.venv/bin/python - <<'PY'
import json
from pathlib import Path
from mvp_ed1.recovery import pacote
p = Path('data/recovery/candidato')
m = json.loads((p / 'manifesto.json').read_text())
print('checksums:', pacote.conferir_checksums(p))
print('sha256_checksums:', pacote.sha256(p / 'checksums.sha256'))
print('manifesto_campos:', sorted(m))
print('ausentes_planejados:', sorted(set(['seed', 'as_of_date', 'tamanhos']) - set(m)))
print('commit:', m['commit'])
print('certificadas:', m['oraculo_capturas']['certificadas'])
print('arquivos_copiados:', m['artefatos_copiados'])
PY
```

```text
checksums: []
sha256_checksums: d3a71d7851b86f334278e56805d016154061295ec904436d9ad7596fdd2f6903
manifesto_campos: ['alembic', 'artefatos_ausentes', 'artefatos_copiados', 'commit', 'contagens', 'corte', 'governance_versions', 'limite', 'max_event_sequence', 'oraculo_capturas', 'oraculo_quarentena', 'oraculo_scd']
ausentes_planejados: ['as_of_date', 'seed', 'tamanhos']
commit: 6b811dc9d6cd2b203fce88fe3aea16158a496af8
certificadas: [28, 29, 30, 31, 32, 33, 35, 36, 38, 39, 43]
arquivos_copiados: ['data/legacy/manifesto-3f9e5088c72234045351b251d406ce9e.json', 'data/legacy/manifesto-anterior-20260907-sem-hash.json', 'data/legacy/manifesto.json', '.stream/producer_state.json']
```

Leitura dos trechos DDL não comprimidos do arquivo, sem conectar ou restaurar:

```bash
.venv/bin/python - <<'PY'
import pathlib, re
p = pathlib.Path('data/recovery/candidato/warehouse_memoria.dump').read_bytes()
for match in re.finditer(rb'CREATE TABLE (snapshots|quarantine)\.[\s\S]+?\n\);', p):
    sql = match.group().decode('utf-8')
    name = sql.split(' (')[0].removeprefix('CREATE TABLE ')
    special = [line.strip().rstrip(',') for line in sql.splitlines()
               if any(t in line for t in ('timestamp', 'numeric', 'bytea', 'jsonb'))]
    print(name, ':', '; '.join(special))
PY
```

```text
quarantine.rejected_legacy_records : snapshot_at timestamp with time zone; original_payload jsonb; cleaned_payload jsonb; findings jsonb
quarantine.rejected_shipment_deliveries : shipped_at timestamp with time zone; estimated_delivery_at timestamp with time zone; delivered_at_projected timestamp with time zone; last_event_at timestamp with time zone
snapshots.scd_coupon : discount_value numeric; min_order_amount numeric; coupon_valid_from timestamp with time zone; coupon_valid_to timestamp with time zone; redeemed_discount_amount numeric; first_redeemed_at timestamp with time zone; last_redeemed_at timestamp with time zone; source_created_at timestamp with time zone; source_updated_at timestamp with time zone; dbt_updated_at timestamp without time zone; dbt_valid_from timestamp without time zone; dbt_valid_to timestamp without time zone
snapshots.scd_customer : registered_at timestamp with time zone; first_order_at timestamp with time zone; last_order_at timestamp with time zone; lifetime_net_revenue_amount numeric; second_order_at timestamp with time zone; days_since_last_order numeric(12,2); source_created_at timestamp with time zone; source_updated_at timestamp with time zone; dbt_updated_at timestamp without time zone; dbt_valid_from timestamp without time zone; dbt_valid_to timestamp without time zone
snapshots.scd_product : launched_at timestamp with time zone; source_created_at timestamp with time zone; source_updated_at timestamp with time zone; dbt_updated_at timestamp without time zone; dbt_valid_from timestamp without time zone; dbt_valid_to timestamp without time zone
snapshots.scd_support_agent : hired_at timestamp with time zone; source_created_at timestamp with time zone; source_updated_at timestamp with time zone; dbt_updated_at timestamp without time zone; dbt_valid_from timestamp without time zone; dbt_valid_to timestamp without time zone
```

A conferência final releu os checksums e comparou o SHA-256 do arquivo de
checksums com o valor salvo pela sonda inicial em `/tmp`:

```bash
.venv/bin/python - <<'PY'
from pathlib import Path
from mvp_ed1.recovery import pacote
p = Path('data/recovery/candidato')
print('checksums finais:', pacote.conferir_checksums(p))
print('arquivo de checksums inalterado:', pacote.sha256(p / 'checksums.sha256') ==
      Path('/tmp/rve_entrega_YkzQiO/candidato_checksum_antes.txt').read_text())
PY
```

```text
checksums finais: []
arquivo de checksums inalterado: True
```

### E9 — amostragem dos testes e sintaxe

O caso excluído chama o alvo `recovery-restore` sem autorização; foi excluído
para respeitar a proibição de invocá-lo nesta sessão, mesmo que o teste espere
recusa. Não foi executado `make check`, que inclui escrita pelo dbt.

```bash
.venv/bin/pytest -q tests/test_recovery.py tests/test_identidade_captura.py tests/test_medicao.py -k 'not test_restore_sem_autorizacao_nao_toca_em_banco'
```

```text
.............................................................            [100%]
61 passed, 1 deselected in 26.93s
```

```bash
.venv/bin/pytest -q tests/test_preflight.py -k 'conteiner or pausa_sem or pausa_confirmada_diz or pausa_parcial or retomada or resolucao_separa'
```

```text
......                                                                   [100%]
6 passed, 15 deselected in 2.43s
```

```bash
.venv/bin/python - <<'PY'
import subprocess
result = subprocess.run(['bash', '-n', 'docker/conteineres.sh',
                         'docker/preflight.sh', 'docker/airflow_cli.sh', 'docker/medir.sh'])
print('bash -n: exit=' + str(result.returncode))
PY
```

```text
bash -n: exit=0
```

## 9. O que esta revisão NÃO verificou

- **B5 não foi executado.** Nenhum `recovery-restore`, reset, desmontagem,
  re-base aplicado, promoção, carga, reconstrução dbt ou troca de ambiente
  real foi feito. O candidato real foi somente lido.
- **Não houve consulta ao conteúdo vivo dos três bancos.** As conexões foram
  recusadas (E1). A indisponibilidade foi informada ao Owner; não foram
  criados bancos novos para substituir os que a solicitação supunha ativos.
- Não foram exercitados `pg_restore` em destino povoado, dependências entre
  schemas, concessões dos cinco papéis, restauração do cursor ou dos artefatos,
  nem os efeitos do re-base no SQL real. E4 prova falhas das decisões com
  dublês; não mede os efeitos de uma restauração.
- O digest não foi comparado após dump/restore real ou entre drivers
  conectados. Foram conferidos os objetos Python e o DDL presente no dump.
  A estabilidade sob diferentes configurações de sessão continua sem medição.
- A equivalência de geração foi conferida nas funções puras e em dez
  chamadas de `captura.decidir`; **`captura.medir_recebido` não rodou** nesta
  revisão. Os ensaios finitos de ciclos não substituem a aplicação e a
  conferência transacional da partição.
- Não houve disparo, pausa/despausa ou espera de uma DAG real. O formato
  efetivo do retorno de `airflow dags trigger -o json` continua pendente.
  Compilar o corpo da tarefa por AST não exercita decorators, XCom, providers
  ou scheduler.
- Não houve pipeline, produtor, Connect ou Redpanda real sob o medidor;
  duração de trabalho versus invólucro, custo de memória real, prazo de
  consultas lentas e encerramento do Beam continuam sem medição nesta revisão.
- Não houve Airbyte reinstalado, avanço/leitura de `jobs_id_seq`, colisão
  intencional, captura nova ou prova de que todas as cargas futuras terão
  geração não negativa. A chamada GET real confirma somente a API atualmente
  disponível e as páginas consultadas; mais de 100 jobs não foram produzidos.
- B2/B3, revisão final depois de B6, aceite do Owner e encerramento formal
  permanecem fora deste parecer. Os 67 testes amostrados não autorizam B5.

## 10. A aplicação dos achados — o que foi medido, 21/09/2026

Saída literal, colada. Nada abaixo tocou nos três bancos do projeto: o que
precisou de restauração real rodou num banco **isolado** (`rve_restore`),
criado e derrubado pela sonda no contêiner do armazém; o pacote de medição foi
montado num diretório de rascunho, não em `data/recovery/`.

**RVE-01 — a API real, só `GET`:**

```text
{"GET": "/jobs?limit=100&orderBy=createdAt%7CDESC", "rows": 43, "primeiros": [43, 42, 41], "maior_job_conhecido": 43}
{"GET": "/jobs?limit=2&orderBy=createdAt%7CDESC", "rows": 2, "primeiros": [43, 42], "maior_job_conhecido": 43}
GET /jobs?limit=2&orderBy=createdAt|DESC -> 400 em /jobs?limit=2&orderBy=createdAt|DESC: {"message":"Bad Request"…
```

**RVE-02 — a sonda da E6, repetida no Makefile real copiado com executáveis simulados:**

```text
[medir] registro: …/mk/medicoes/2026-09-21T185625Z_airbyte_up.json
chamadas: preflight airbyte --trocar;abctl local install --values airbyte/values.yaml;
ERRO: 'alvo-inexistente-rve' não é um alvo do Makefile — nada foi medido.
chamadas: ''
```

**RVE-03 — `pg_restore` de verdade, em banco isolado (`warehouse_memoria.dump` de 21/09):**

```text
destino vazio: pg_restore ok em 4.8s; contagens == manifesto: True (48 tabelas, 423377 linhas)
destino povoado (segunda vez): pg_restore ok em 6.4s; contagens == manifesto: True (48 tabelas, 423377 linhas)
destino com view dependente: RECUSADO — pg_restore de rve_restore falhou (código 1) e a transação foi desfeita — o banco está como estava.
  banco intocado depois da recusa: contagens iguais=True; a view continua lendo 2063 linhas
banco isolado derrubado: True
```

O diagnóstico que a recusa devolve, inteiro:

```text
pg_restore: error: could not execute query: ERROR:  cannot drop table raw_legacy.customers because other objects depend on it
DETAIL:  view public.rve_dependente depends on table raw_legacy.customers
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
Command was: DROP TABLE IF EXISTS raw_legacy.customers;
```

**RVE-04 — o re-base aplicado, no mesmo banco isolado, e o passo 5 depois dele:**

```text
[recovery] re-base aplicado a 40 tabela(s); partição conferida antes de confirmar: mesmas classes, mesmo agrupamento, toda linha retida com geração estritamente negativa | rc 0 | 10.9s
gerações em customers (min|max|classes): -28|-1|28
--- rebase de novo (idempotência)
[recovery] re-base aplicado a 40 tabela(s); … | rc 0
--- verify --contra-o-banco com o armazém apontando para o banco isolado re-baseado
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações re-baseadas na faixa negativa)
```

A primeira execução do re-base real falhou — e é o defeito que só a execução
acha: `_linhas` fixava `stream_results` na **conexão**, e o `update` seguinte
saiu como `DECLARE "c_…" CURSOR FOR update raw_legacy."brands" …` (erro de
sintaxe). A opção passou para a instrução; a saída acima é da segunda execução.

**RVE-05 — o passo 9 contra o armazém vivo, com o pacote de medição** (recusa
esperada: não houve re-base nem captura nova; o que interessa é o SQL rodar):

```text
[recovery] fontes: contagens, Alembic e corte do livro conferidos contra o manifesto
[recovery] quarentena: 21 fatia(s) do manifesto contidas, 0 acrescentada(s) pela(s) captura(s) []
[recovery] livro até 13700: 13700 no lote, 13700 no fluxo; só num lado 0/0, payloads diferentes 0, saldos diferentes 0, soma dos deltas 701841 × 701841
  nenhuma captura certificada além das do manifesto — a sincronização do passo 8 não produziu identidade nova
conferir-restauracao: 22 problema(s)
```

**RVE-06 — a premissa de D50, lida no Airbyte 2.2.0 instalado (só leitura):**

```text
$ docker/airbyte_jobs.sh ler
maior_job=43 ultimo_valor=43 chamado=t sequencia=public.jobs_id_seq
$ python -m mvp_ed1.recovery avancar-jobs
[recovery] Airbyte: maior job 43, sequência public.jobs_id_seq em 43 (já usada) → próximo job 44; captura retida 43
[recovery] o próximo job já nasce acima da captura retida — nada a avançar
```

`jobs.id` é `bigint generated by default as identity`; a sequência veio de
`pg_get_serial_sequence('jobs','id')`, não de um nome escrito.

**RVE-07 — a sonda da E3, repetida sobre a codificação nova:**

```text
NULL vs texto \N: valores_iguais=False; digests_iguais=False
separador dentro de texto: valores_iguais=False; digests_iguais=False
mesmo instante, outro fuso: valores_iguais=True; digests_iguais=True
Decimal com escala diferente: valores_iguais=True; digests_iguais=True
bytea bytes vs memoryview: valores_iguais=True; digests_iguais=True
bytea duas memoryviews: valores_iguais=True; digests_iguais=True
"1" vs 1 vs Decimal 1: valores_iguais=False; digests_iguais=False
dominio_valido sobre iter([0, 1]): ['gerações não negativas ainda no bruto retido: [0, 1]']
```

**RVE-10/15 — o pacote montado ao lado, com o manifesto novo (rascunho):**

```text
[recovery] corte em 2026-09-21T19:14:19+00:00 — janela parada
[recovery] três dumps em …/recovery/candidato.em-montagem
candidato pronto em …/recovery/candidato          real 0m20,029s
campos: ['alembic', 'artefatos_ausentes', 'artefatos_copiados', 'commit', 'contagens', 'corte', 'geracao', 'governance_versions', 'limite', 'max_event_sequence', 'oraculo_capturas', 'oraculo_exclusoes', 'oraculo_formato', 'oraculo_particao', 'oraculo_quarentena', 'oraculo_scd', 'tamanhos']
formato: 2 | geracao: source_db None ("data/source/geracao.json não existe — … nada foi inferido"); legacy_db {'semente': 20260906, 'as_of': '2026-09-01', 'fator': 0.05, …}
particao customers: {'classes': 28, 'linhas': 2063, 'nulas': 0, 'digest': '4b606d…'} | exclusoes: {'linhas': 4, 'digest': 'db8b8c…'}
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam.   real 0m11,971s
```

**A suíte inteira:** `make test` → `437 passed, 8 skipped in 232.84s` (eram
394 + 8 na entrega).

**O que continua não verificado, e é de B5:** a sequência de nove passos
ponta a ponta; o `pg_restore` nos bancos **do projeto** (o medido foi o dump
da memória, em banco isolado — as duas fontes não foram restauradas em lugar
nenhum); o passo 9 depois de uma captura nova real; `avancar-jobs` com uma
sequência de fato atrás da retida (o `setval` real não rodou — o instalado já
estava em 43); pausa e espera de uma DAG real; o medidor sob pipeline real. O
candidato de 20/09 era do formato 1 e o `verify` o recusaria por forma: **foi
refeito** depois do último *commit* (`make recovery-pack`, árvore limpa, corte
`2026-09-21T19:27:54+00:00`, código `118416f`, 19,6 s) e conferido contra os
bancos vivos (`make recovery-verify CONTRA_O_BANCO=1`, 12,2 s, sem problema).

## 11. Segunda rodada da revisão da entrega — 23/09/2026

**Ainda há impedimentos para avançar a B5: dois bloqueantes e três ajustes.**
A conferência final ainda aceita a falta da auditoria da captura nova, e o
medidor transforma uma consulta de memória que falhou em uma medição de zero.
As contraprovas também expuseram a recomposição de serviços que já estavam
parados, `SIGINT` ignorado pelo processo lançado no cenário e a preservação de
um registro de geração posterior ao pacote. Achados **RVE2-01 a RVE2-05** na
tabela ao fim; RVE2-01 e RVE2-03 complementam RVE-05 e RVE-11.

Checkout observado: `b1011e701beacf89d2f1b25346e4200dc920bcd9`, inicialmente
limpo. Conferidos o diff `3e21a54..b1011e7`, o declarativo atual de B0/B1/B4,
seus chamadores e os contratos da §6 do plano e dos ADRs 0037/0044/0045.
Os testes existentes foram executados e serviram também de base a
contraprovas independentes. B2/B3 continuam fora do escopo desta rodada.
Só este dossiê foi alterado no repositório; não houve correção de implementação.

### 11.1 Conferência dos achados anteriores

| Achados | Resultado desta rodada |
|---|---|
| RVE-01 | **Confirmado no transporte real.** A função `jobs` devolveu 43 jobs, máximo 43, com a URL codificada. E2-2. |
| RVE-02, 08, 09, 10, 12, 13, 14, 16, 17 | **Correções confirmadas por leitura e pelos testes executados.** Validação sem executar receita; indeterminação de Docker; consulta do host; preservação do candidato durante montagem; registro da interrupção; registros distintos; identidade exata do run; iterador; recusa da pausa que falhou. Isso não equivale a executar uma troca real ou interromper Beam real. E2-1. |
| RVE-03, 04, 06, 07, 15 | **Correções incorporadas, com limites de validação.** Flags de restauração e recuo, partição, sequência D50, codificação tipada e metadados foram conferidos no código e nos testes. O passo 5 passou contra o candidato e os bancos vivos; D50 foi lido sem avanço. Não repeti a restauração nem o re-base em banco isolado relatados pelo autor na §10. A devolução do registro de geração tem o defeito adicional RVE2-05. E2-1/E2-2/E2-5. |
| RVE-05 | **Parcial.** As conferências acrescentadas existem, mas o acréscimo da quarentena só é filtrado pelo pertencimento do `snapshot_id`: a falta da fatia esperada ainda passa. RVE2-01, E2-3. |
| RVE-11 | **Parcial.** O grupo que falhou é religado; porém `resolver --todos` inclui serviços que já estavam parados antes da tentativa. O conjunto original continua sem ser guardado. RVE2-03, E2-4. |

### 11.2 Evidências desta rodada

As sondas foram executadas em `/tmp/rve2_xEBKdU/`. Seus códigos estão
incluídos abaixo para que as evidências não dependam da permanência desse
diretório. Os comandos partem da raiz do repositório. Dublês de Docker,
Makefile e leituras do banco são identificados; nenhum resultado deles é
apresentado como uma restauração ou uma execução de Beam real.

#### E2-1 — testes existentes e candidato contra os bancos vivos

```bash
.venv/bin/python -m pytest -q tests/test_recovery.py tests/test_medicao.py tests/test_preflight.py tests/test_identidade_captura.py
```

Saída literal:

```text
........................................................................ [ 57%]
......................................................                   [100%]
126 passed in 51.34s
```

O comando de sintaxe `bash -n docker/conteineres.sh docker/preflight.sh
docker/airflow_cli.sh docker/airbyte_jobs.sh docker/medir.sh` saiu 0, sem
saída. A conferência abaixo usou o `.env` sem imprimir credenciais e conexões
com `default_transaction_read_only=on`. O acesso local foi liberado fora do
sandbox após a primeira conexão TCP ser recusada.

```bash
set -a
. ./.env
set +a
PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=30000' .venv/bin/python -m mvp_ed1.recovery verify --contra-o-banco
```

```text
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações como no manifesto)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
```

Leitura adicional, sob transações somente de leitura:

```bash
set -a
. ./.env
set +a
.venv/bin/python /tmp/rve2_xEBKdU/leituras.py
```

```text
SOURCE_DB ('source_db', 'on')
LEGACY_DB ('legacy_db', 'on')
WAREHOUSE_DB ('warehouse_db', 'on')
dependencias_fora_do_dump 0
exemplos_dependencias []
snapshots_dependentes []
candidato {'corte': '2026-09-21T19:27:54+00:00', 'commit': '118416f5c10bbe716f9c42927888d4c19bcff3c3', 'oraculo_formato': 2, 'max_event_sequence': 13700}
checksums []
capturas [28, 29, 30, 31, 32, 33, 35, 36, 38, 39, 43]
quarentena_manifesto_fatias 21
caminhos {'corte': 13700, 'so_no_lote': 0, 'so_no_fluxo': 0, 'payloads_diferentes': 0, 'saldos_diferentes': 0, 'soma_lote': 701841, 'soma_fluxo': 701841, 'linhas_lote': 13700, 'linhas_fluxo': 13700}
```

`dependencias_fora_do_dump` é a consulta a dependências de **views/regras**
em `pg_depend`/`pg_rewrite`, não uma certificação de todas as dependências
possíveis. Ela descartou a hipótese de que views externas aos quatro schemas
já impediriam o restore no estado observado; não executei restore para testar
outros impedimentos. Os 13.700 movimentos de cada caminho e a soma 701.841 são
do estado atual, anterior a B5.

#### E2-2 — API e contador do Airbyte reais, sem sincronizar ou avançar

```bash
.venv/bin/python /tmp/rve2_xEBKdU/api_airbyte.py
docker/airbyte_jobs.sh ler
```

Saídas literais, respectivamente:

```text
{"GET": "/jobs?limit=100&orderBy=createdAt%7CDESC", "rows": 43, "maior_job_conhecido": 43, "primeiros": [43, 42, 41]}
maior_job=43 ultimo_valor=43 chamado=t sequencia=public.jobs_id_seq
```

O acesso pelo sandbox foi recusado; a repetição autorizada leu Docker/API
local. O único POST foi a autenticação do cliente; nenhum `POST /jobs`,
`setval` ou mudança de configuração foi executado.

#### E2-3 — passo 9 com a captura nova, mas sem a auditoria dela

```bash
.venv/bin/python /tmp/rve2_xEBKdU/sondas_oraculos.py
```

Recorte literal das duas saídas pertinentes ao achado:

```text
controle_valido codigo= 0 erros= ''
sem_fatia_da_captura_nova codigo= 0 erros= ''
```

A sonda parte da fixture que os testes chamam de restauração válida, mantém
as capturas 9/43/44, as partições e as outras leituras, passa **`job=44`** e
troca somente a quarentena pela do manifesto, retirando a fatia da 44. A
função real continua devolvendo 0. `estranhas` só procura fatias a mais de
outro snapshot; não procura as que faltam nem compara conteúdo/contagem do
acréscimo com o esperado para a captura tratada. A identificação exata do job
também é opcional, e o Makefile não fornece `--job` ao passo 9.

Isso demonstra uma lacuna no oráculo explícito exigido pela §6, passo 9, não
uma restauração real incorreta que tenha passado por `make check`. Uma
captura legitimamente sem rejeições deve continuar válida: o esperado precisa
vir da classificação da captura efetivamente disparada, sem exigir um total
positivo constante.

#### E2-4 — pausa parcial, falha de medição e sinal do processo lançado

```bash
.venv/bin/python /tmp/rve2_xEBKdU/sondas_scripts.py
```

Saída literal da execução final da sonda:

```text
pausa_parcial_codigo 1
estavam_de_pe ['mvp_ed1-airflow_dag_processor-1', 'mvp_ed1-airflow_db-1', 'mvp_ed1-airflow_scheduler-1']
ficaram_de_pe ['mvp_ed1-airflow_apiserver-1', 'mvp_ed1-airflow_dag_processor-1', 'mvp_ed1-airflow_db-1', 'mvp_ed1-airflow_scheduler-1']
ligados_sem_estarem_de_pe ['mvp_ed1-airflow_apiserver-1']
stats_falhou_codigo_medidor 0
stats_falhou_estacao Airbyte
stats_falhou_amostragem {'intervalo_s': 1, 'amostras': 2, 'disponivel_minimo_mb': 2756, 'disponivel_minimo_em': '2026-09-23T20:14:08Z', 'conteineres_maximo_mb': 0, 'conteineres_maximo_em': '2026-09-23T20:14:07Z', 'janela_s': 1}
pipeline_sigint_disposicao Handlers.SIG_IGN
pipeline_recebeu_keyboardinterrupt False
pipeline_exigiu_sigkill True
pipeline_codigo_medidor 0
```

No primeiro caso, Docker e memória são dublês dos testes. O apiserver estava
`exited` **antes** da troca recusada; passou a `up` porque `_religar` resolve
todos os contêineres, em vez de recompor os que estavam de pé.

No segundo, o Docker simulado informa Airbyte de pé em `ps` e falha em toda
consulta `stats`. O `awk` imprime 0 para a entrada vazia, e o `printf` do
amostrador perde o código de erro da substituição de comando. O JSON registra
duas amostras e um máximo de 0 MB sem marcar a medição como indisponível.
Os valores de `MemAvailable` são da estação, lidos de verdade; os 0 MB **não**
são uma medição dos contêineres reais.

No terceiro, o Makefile simulado usa um Python que informa sua disposição de
`SIGINT` e captura `KeyboardInterrupt`; não inicia Beam. Lançado pelo cenário
real de `medir.sh`, esse processo recebe `SIG_IGN`, não interrompe no SIGINT
e só termina por SIGKILL após o prazo de teste de 2 s. `setsid` separa o grupo,
mas não restaura a disposição herdada do lançamento assíncrono pelo shell.
A CLI real depende de `KeyboardInterrupt` em `comando_pipeline`. Não medi o
runner Beam real; a falha comprovada é a disposição de sinal entregue pelo
lançador a um processo Python comum.

#### E2-5 — ausência de artefato no candidato não restaura ausência no checkout

```bash
.venv/bin/python /tmp/rve2_xEBKdU/sonda_artefatos.py
```

```text
artefatos_ausentes_no_candidato ['data/source/geracao.json']
geracao_source_no_candidato None
[recovery] devolvido: data/legacy/manifesto-3f9e5088c72234045351b251d406ce9e.json
[recovery] devolvido: data/legacy/manifesto-anterior-20260907-sem-hash.json
[recovery] devolvido: data/legacy/manifesto.json
[recovery] devolvido: .stream/producer_state.json
restore_artefatos_codigo 0
registro_posterior_sobreviveu True
proximo_pack_atribuiria_a_origem {'semente': 'carga-posterior-ao-pacote', 'as_of': '2026-09-23'}
```

Usados o manifesto e os artefatos do candidato real, **copiados para `/tmp`**;
o checkout de destino também é temporário. Nenhum artefato de trabalho do
projeto foi substituído. O registro posterior é um marcador sintético da
sonda, não uma semente medida no banco. Ele sobrevive à função real porque
ela só considera `artefatos_copiados`. No fluxo previsto de B5, `seed-data`
cria esse registro antes da restauração; o candidato atual declara sua
ausência. Deixá-lo no checkout faria o próximo pacote atribuir os parâmetros
da carga de B5 à fonte restaurada do pacote anterior.

#### Códigos das sondas

<details>
<summary>leituras.py</summary>

```python
import json
from pathlib import Path
import sqlalchemy as sa
from mvp_ed1 import db
from mvp_ed1.recovery import leitura, pacote

engines = {}
for prefix in db.BANCOS:
    engine = sa.create_engine(db.database_url(prefix), connect_args={
        'connect_timeout': 3,
        'options': '-c default_transaction_read_only=on -c statement_timeout=15000',
    })
    engines[prefix] = engine
    try:
        with engine.connect() as conn:
            print(prefix, conn.execute(sa.text('select current_database(), current_setting(\'transaction_read_only\')')).one())
    except sa.exc.OperationalError as error:
        print(prefix, type(error).__name__, str(error.orig).splitlines()[0])
        raise SystemExit(1)

warehouse = engines[db.WAREHOUSE]
with warehouse.connect() as conn:
    deps = conn.execute(sa.text('''
        select distinct sn.nspname || '.' || s.relname as restored,
                        vn.nspname || '.' || v.relname as dependent
        from pg_depend d
        join pg_rewrite r on r.oid = d.objid
        join pg_class v on v.oid = r.ev_class
        join pg_namespace vn on vn.oid = v.relnamespace
        join pg_class s on s.oid = d.refobjid
        join pg_namespace sn on sn.oid = s.relnamespace
        where d.classid = 'pg_rewrite'::regclass
          and d.refclassid = 'pg_class'::regclass
          and sn.nspname in ('raw_legacy','governance','snapshots','quarantine')
          and vn.nspname not in ('raw_legacy','governance','snapshots','quarantine')
        order by 1,2
    ''')).all()
    print('dependencias_fora_do_dump', len(deps))
    print('exemplos_dependencias', [tuple(row) for row in deps[:8]])
    print('snapshots_dependentes', [tuple(row) for row in deps if row[0].startswith('snapshots.')])

root = Path.cwd()
manifest = pacote.Manifesto.ler(root / 'data/recovery/candidato')
print('candidato', {key: manifest.dados[key] for key in ['corte', 'commit', 'oraculo_formato', 'max_event_sequence']})
print('checksums', pacote.conferir_checksums(root / 'data/recovery/candidato'))
print('capturas', leitura.oraculo_das_capturas(warehouse)['certificadas'])
print('quarentena_manifesto_fatias', len(manifest.dados['oraculo_quarentena']))
print('caminhos', leitura.comparar_caminhos(warehouse, manifest.dados['max_event_sequence']))
for engine in engines.values():
    engine.dispose()
```

</details>

<details>
<summary>api_airbyte.py</summary>

```python
import json
import os
import re
import subprocess
from mvp_ed1 import airbyte
from mvp_ed1.legacy import identidade

raw = subprocess.run(['.tools/abctl', 'local', 'credentials'], capture_output=True, text=True, timeout=30)
clean = re.sub(r'\x1b\[[0-9;]*m', '', raw.stdout + raw.stderr)
for label, key in [('Client-Id', 'AIRBYTE_CLIENT_ID'), ('Client-Secret', 'AIRBYTE_CLIENT_SECRET')]:
    match = re.search(label + r':\s+(\S+)', clean)
    if not match:
        raise SystemExit(f'abctl: credencial {label} indisponivel; exit={raw.returncode}')
    os.environ[key] = match[1]
jwt = airbyte.token()
response = airbyte.jobs(jwt)
print(json.dumps({
    'GET': airbyte.caminho_dos_jobs(),
    'rows': len(response.get('data', [])),
    'maior_job_conhecido': identidade.maior_job_conhecido(lambda: response),
    'primeiros': [r['jobId'] for r in response.get('data', [])[:3]],
}))
```

</details>

<details>
<summary>sondas_oraculos.py</summary>

```python
import copy
import importlib.util
from pathlib import Path

root = Path.cwd()
spec = importlib.util.spec_from_file_location('tests_recovery', root / 'tests/test_recovery.py')
t = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t)

cases = {
    'controle_valido': dict(t.ESTADO_RESTAURADO),
    'sem_fatia_da_captura_nova': dict(t.ESTADO_RESTAURADO) | {
        'oraculo_da_quarentena': lambda engine: copy.deepcopy(t.MANIFESTO['oraculo_quarentena']),
    },
    'livros_ambos_vazios': dict(t.ESTADO_RESTAURADO) | {
        'comparar_caminhos': lambda engine, corte: {
            'corte': corte, 'so_no_lote': 0, 'so_no_fluxo': 0, 'payloads_diferentes': 0,
            'saldos_diferentes': 0, 'soma_lote': 0, 'soma_fluxo': 0, 'linhas_lote': 0, 'linhas_fluxo': 0,
        },
    },
}
for name, case in cases.items():
    code, error = t._passo_9(case, job=44)
    print(name, 'codigo=', code, 'erros=', repr(error))
```

</details>

<details>
<summary>sondas_scripts.py</summary>

```python
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path.cwd()
def module(name, file):
    spec = importlib.util.spec_from_file_location(name, root / file)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

p = module('test_preflight_rve2', 'tests/test_preflight.py')
m = module('test_medicao_rve2', 'tests/test_medicao.py')

with tempfile.TemporaryDirectory(prefix='preflight_', dir=Path(__file__).parent) as folder:
    base = Path(folder)
    originally_up = p._linhas_de_estado(['Airflow']).replace(
        'mvp_ed1-airflow_apiserver-1|mvp_ed1|airflow_apiserver|up',
        'mvp_ed1-airflow_apiserver-1|mvp_ed1|airflow_apiserver|exited',
    )
    result = p.executa(base, 'streaming', [], estado_extra=originally_up,
                       stop_ignorar='mvp_ed1-airflow_scheduler-1')
    before = [line.split('|')[0] for line in originally_up.splitlines() if line.endswith('|up')]
    print('pausa_parcial_codigo', result.codigo)
    print('estavam_de_pe', sorted(before))
    print('ficaram_de_pe', sorted(result.de_pe))
    print('ligados_sem_estarem_de_pe', sorted(set(result.de_pe) - set(before)))

with tempfile.TemporaryDirectory(prefix='stats_', dir=Path(__file__).parent) as folder:
    base = Path(folder)
    env, cwd = m._ambiente(base, makefile='alvo:\n\t@sleep 2\n')
    fake = base / 'bin/docker'
    fake.write_text('#!/usr/bin/env bash\ncase "$1" in\nps) [[ "$*" == *--filter* ]] || echo airbyte-abctl-control-plane; exit 0 ;;\nstats) echo "daemon unavailable" >&2; exit 1 ;;\nesac\n')
    result = subprocess.run([str(m.MEDIR), 'alvo'], env=env, cwd=cwd,
                            capture_output=True, text=True, timeout=10)
    record = m._registro(base)
    print('stats_falhou_codigo_medidor', result.returncode)
    print('stats_falhou_estacao', record['estacao']['de_pe'])
    print('stats_falhou_amostragem', record['amostragem'])

with tempfile.TemporaryDirectory(prefix='sigint_', dir=Path(__file__).parent) as folder:
    base = Path(folder)
    makefile = m.CENARIO_OK.replace('@echo $$$$ > pipeline.pid; sleep 600', '@python3 sinal.py')
    env, cwd = m._ambiente(base, makefile=makefile)
    env['MEDIR_PRAZO_ENCERRAMENTO'] = '2'
    (cwd / 'sinal.py').write_text('''import signal, time
from pathlib import Path
Path('disposicao').write_text(str(signal.getsignal(signal.SIGINT)))
try:
    time.sleep(30)
except KeyboardInterrupt:
    Path('interrompido').write_text('sim')
''')
    result = subprocess.run([str(m.MEDIR), '--cenario', 'streaming'], env=env, cwd=cwd,
                            capture_output=True, text=True, timeout=10)
    print('pipeline_sigint_disposicao', (cwd / 'disposicao').read_text())
    print('pipeline_recebeu_keyboardinterrupt', (cwd / 'interrompido').exists())
    print('pipeline_exigiu_sigkill', 'SIGKILL' in result.stdout)
    print('pipeline_codigo_medidor', result.returncode)
```

</details>

<details>
<summary>sonda_artefatos.py</summary>

```python
import argparse
import json
from pathlib import Path
import tempfile
from unittest.mock import patch
from mvp_ed1.recovery import cli, leitura, pacote

real = pacote.Manifesto.ler(Path('data/recovery/candidato'))
print('artefatos_ausentes_no_candidato', real.dados['artefatos_ausentes'])
print('geracao_source_no_candidato', real.dados['geracao']['source_db'])

with tempfile.TemporaryDirectory(prefix='artefatos_', dir=Path(__file__).parent) as folder:
    root = Path(folder) / 'checkout'
    recovery = Path(folder) / 'pacote'
    root.mkdir()
    recovery.mkdir()
    for name in real.dados['artefatos_copiados']:
        target = recovery / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes((Path('data/recovery/candidato') / name).read_bytes())
    real.gravar(recovery)
    marker = root / leitura.REGISTRO_DA_GERACAO
    marker.parent.mkdir(parents=True)
    marker.write_text(json.dumps({'semente': 'carga-posterior-ao-pacote', 'as_of': '2026-09-23'}))
    with patch.object(cli, 'RAIZ', root), patch.object(cli, '_pasta_do_pacote', return_value=recovery):
        code = cli.comando_restore_artefatos(argparse.Namespace(dir=None))
    print('restore_artefatos_codigo', code)
    print('registro_posterior_sobreviveu', marker.exists())
    print('proximo_pack_atribuiria_a_origem', leitura.geracao_registrada(root)['source_db'])
```

</details>

### 11.3 O que esta rodada não verificou

- Não executei `recovery-restore`, `restore-dumps`, re-base aplicado, avanço
  de sequência, sincronização, `dbt-rebuild`, DAG, promoção ou o ciclo B5.
- Não executei `make check`: ele inclui reconstrução e escrita nos bancos.
  Os 126 testes acima são a suíte selecionada, não a suíte inteira de 437.
- Não subi, parei ou retomei ambiente pesado. Os três bancos e o Airbyte já
  estavam de pé; Airflow estava parado. As falhas de pausa e os processos do
  medidor foram exercitados com dublês em diretórios temporários.
- Não há medição nesta rodada de restauração nos três bancos do projeto,
  reconstrução com uma captura nova real, `setval` em Airbyte reinstalado ou
  encerramento de Beam real. As medições isoladas da §10 continuam sendo o
  relato do autor, com seus limites.
- Não foram feitos aceite do declarativo pelo Owner, revisão de B2/B3 ou
  encerramento formal da etapa. Corrigir os achados abaixo permite nova
  conferência técnica; não substitui esses atos nem as medições de B5.

## 12. A aplicação da segunda rodada — o que foi medido, 23/09/2026

Saída literal, colada. Os cinco achados foram reproduzidos **antes** de
corrigidos, com as sondas da §11.2 ainda em `/tmp/rve2_xEBKdU/` — as cinco
saídas bateram com as da E2-3, E2-4 e E2-5 —, e as mesmas sondas foram
repetidas depois de cada correção. Leituras dos bancos vivos em transação
somente de leitura; nenhuma restauração, sincronização ou avanço de sequência.
Um *commit* por achado: `fba57cc` (RVE2-01), `e12d39d` (RVE2-02), `e2a18c5`
(RVE2-04), `ad19028` (RVE2-03), `8c04106` (RVE2-05).

**RVE2-01 — a sonda E2-3, repetida (os três casos dela):**

```text
controle_valido codigo= 0 erros= ''
sem_fatia_da_captura_nova codigo= 1 erros= '  quarentena, auditoria da captura nova: fatia sumiu: \'["legacy",44,9,"hash"]\' (1 linhas)\n\nconferir-restauracao: 1 problema(s)\n'
livros_ambos_vazios codigo= 1 erros= '  caminhos do livro: 0 no lote e 0 no fluxo até o corte, e a origem tem 100 — iguais entre si não é o livro de volta\n\nconferir-restauracao: 1 problema(s)\n'
```

O terceiro caso não tinha virado achado e também saía 0 antes: é o achado
próprio desta aplicação. A premissa de que depende a correção — a auditoria de
uma captura é `select *` das rejeitadas da classificação dela — foi medida no
armazém vivo, com a 43 no papel de captura nova e o manifesto do candidato sem
a fatia dela:

```text
tratadas ['["legacy",43,9,"607e6288f4f57e39"]']
rejeitadas {'["legacy",43,9,"607e6288f4f57e39"]': {'linhas': 3207, 'digest': '2f4d3211d2eb589828e9ec3a7117d68b'}}
acrescimo_se_a_43_fosse_nova {'["legacy",43,9,"607e6288f4f57e39"]': {'linhas': 3207, 'digest': '2f4d3211d2eb589828e9ec3a7117d68b'}}
problemas_com_a_auditoria []
problemas_sem_a_fatia ['quarentena, auditoria da captura nova: fatia sumiu: \'["legacy",43,9,"607e6288f4f57e39"]\' (3207 linhas)']
livro {'origem': 13700, 'lote': 13700, 'fluxo': 13700}
```

**RVE2-02, 03 e 04 — a sonda E2-4, repetida:**

```text
pausa_parcial_codigo 1
estavam_de_pe ['mvp_ed1-airflow_dag_processor-1', 'mvp_ed1-airflow_db-1', 'mvp_ed1-airflow_scheduler-1']
ficaram_de_pe ['mvp_ed1-airflow_dag_processor-1', 'mvp_ed1-airflow_db-1', 'mvp_ed1-airflow_scheduler-1']
ligados_sem_estarem_de_pe []
stats_falhou_codigo_medidor 0
stats_falhou_estacao Airbyte
stats_falhou_amostragem {'intervalo_s': 1, 'amostras': 2, 'disponivel_minimo_mb': 2584, 'disponivel_minimo_em': '2026-09-23T20:33:32Z', 'disponivel_falhas': 0, 'conteineres_maximo_mb': None, 'conteineres_falhas': 2, 'janela_s': 1}
pipeline_sigint_disposicao <built-in function default_int_handler>
pipeline_recebeu_keyboardinterrupt True
pipeline_exigiu_sigkill False
pipeline_codigo_medidor 0
```

A leitura real continua lendo — o medidor contra o Docker de verdade, com um
`Makefile` de rascunho (`sleep 3`) e o registro fora de `data/medicoes/`:

```text
| alvo | Airbyte,bancos | 0m 03s | 2,4 GB | 3,1 GB | 1 amostras a cada 1s |
{'intervalo_s': 1, 'amostras': 1, 'disponivel_minimo_mb': 2507, 'disponivel_minimo_em': '2026-09-23T20:34:01Z', 'disponivel_falhas': 0, 'conteineres_maximo_mb': 3222, 'conteineres_maximo_em': '2026-09-23T20:34:01Z', 'conteineres_falhas': 0, 'janela_s': 0}
```

E um alvo que termina antes da primeira amostra (`medir.sh help`) agora diz
`| help | Airbyte,bancos | 0m 00s | não medido | não medido | 0 amostras a cada 1s |`
— antes, a mesma linha imprimia `0.0 GB` nas duas colunas.

A correção do RVE2-04 revelou que **os cenários da própria suíte** também
passavam pelo SIGKILL: o `sleep 600` do `Makefile` de mentira herdava o SIGINT
ignorado e só saía no prazo de 5 s. A suíte do medidor caiu de 35 s para 29 s
com os mesmos casos.

**RVE2-05 — o achado, e o link:**

A premissa do achado próprio, medida num diretório de rascunho — o `copy2`
da restauração sobre um `manifesto.json` que aponta para outro lote:

```text
lrwxrwxrwx 1 doug doug   20 set 23 17:38 manifesto.json -> manifesto-outro.json
-rw-rw-r-- 1 doug doug   18 set 23 17:38 manifesto-outro.json
--- manifesto-outro.json agora:
{"lote":"pacote"}
```

`mutacoes._ler` resolve o link e grava o diário no arquivo apontado: é o
arquivo do lote, não o link, que carrega o diário. A sonda E2-5 contra o
candidato de 21/09 passou a recusar antes de mexer em qualquer arquivo — o
manifesto dele não tem `artefatos_links` —, e é por isso que o candidato foi
refeito:

```text
$ .venv/bin/python /tmp/rve2_xEBKdU/sonda_artefatos.py     # contra o candidato de 21/09
artefatos_ausentes_no_candidato ['data/source/geracao.json']
geracao_source_no_candidato None
restore_artefatos_codigo 1
registro_posterior_sobreviveu True
proximo_pack_atribuiria_a_origem {'semente': 'carga-posterior-ao-pacote', 'as_of': '2026-09-23'}
```

A recusa não mexeu em nada, nem no registro da sonda — é o "confere tudo
antes de mudar qualquer arquivo". Com a árvore limpa em `8c04106` (os
documentos desta rodada guardados à parte), o candidato foi refeito e
conferido contra os bancos vivos:

```text
$ make recovery-pack
[preflight] nenhum trabalho em andamento — janela parada.
[recovery] ATENÇÃO: nenhum arquivo para os padrões ['data/source/geracao.json'] — os oráculos que dependem deles não estarão no pacote
[recovery] corte em 2026-09-23T20:53:54+00:00 — janela parada
candidato pronto em /home/doug/Projetos/mvp_ed1/data/recovery/candidato          real 0m20,938s
$ make recovery-verify CONTRA_O_BANCO=1
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações como no manifesto)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam.          real 0m15,656s
commit 8c04106 | corte 2026-09-23T20:53:54+00:00 | formato 2
artefatos_links {'data/legacy/manifesto.json': 'manifesto-3f9e5088c72234045351b251d406ce9e.json'}
artefatos_ausentes ['data/source/geracao.json']
```

E a sonda E2-5, repetida contra o candidato novo (cópias dele num *checkout*
temporário; os artefatos do projeto não foram tocados — `data/legacy/` e a
ausência de `data/source/` conferidos depois):

```text
[recovery] afastado: data/source/geracao.json (o pacote não o traz) → *.anterior-a-restauracao-20260923T205446Z
[recovery] devolvido: data/legacy/manifesto-3f9e5088c72234045351b251d406ce9e.json
[recovery] devolvido: data/legacy/manifesto-anterior-20260907-sem-hash.json
[recovery] devolvido: data/legacy/manifesto.json → manifesto-3f9e5088c72234045351b251d406ce9e.json
[recovery] devolvido: .stream/producer_state.json
restore_artefatos_codigo 0
registro_posterior_sobreviveu False
proximo_pack_atribuiria_a_origem None
```

**A suíte inteira:** `make test` → `461 passed, 8 skipped in 257.09s` (eram
437 + 8; os 24 novos são 7 do passo 9 e do job, 5 dos artefatos, 3 do
`--job-em`, 7 do medidor e 2 do preflight). `make check`:

```text
── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 107 documentos, 976 links de arquivo, 128 âncoras, 588 citações de ADR — nada quebrado
── 2/4 dbt build: modelos, testes de dados e reconciliações ──
20:48:21  Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
── 3/4 classificação derivada e linhagem em dia com os modelos ──
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
── 4/4 pytest: código, contratos e integração ──
461 passed, 8 skipped in 264.39s (0:04:24)
exit=0
```

**Um incidente desta aplicação, e o que ele confirma.** Para ler a receita
editada, rodei `make -n recovery-restore RESTAURAR=1` — a armadilha que o
RVE-02 e o docstring de `tests/test_recovery.py::_receita` registram: o `make`
executa de verdade a linha de `airbyte-up` que mistura `$(MAKE)` com o `if`
(`Makefile:297–302`), e ela chamou `abctl local install` com o Airbyte de pé.
O `abctl` reescreveu `~/.airbyte/abctl/abctl.kubeconfig` (17:27:18) e abortou
antes de mudar o cluster — o mesmo desfecho que o docstring descreve. Conferido
em seguida, só leitura: a *release* do helm continua `airbyte-abctl.v1` (de
05/09), nenhum *pod* recriado, o nó de pé desde 20:00:37Z, `GET /health` → 200,
`airbyte_jobs.sh ler` → `maior_job=43 ultimo_valor=43 chamado=t`. A receita foi
conferida lendo o texto. A linha de `airbyte-up` continua sendo uma armadilha
para quem rodar `make -n` sobre qualquer alvo que a chame — fica registrada
aqui, fora do escopo desta rodada.

**Depois da rodada, a pedido do Owner — `docker stats` falha de verdade?**
Doze leituras seguidas enquanto um contêiner descartável (`postgres:16-alpine`,
`sleep 2`, `--rm`, 64 MB) nascia e morria seis vezes — a transição que a troca
do preflight provoca no meio do cenário de *streaming*:

```text
leitura  1 rc=0 2,0s linhas=5 com_tracos=0 sonda=452KiB / 64MiB
leitura  2 rc=0 3,0s linhas=5 com_tracos=0 sonda=356KiB / 64MiB
leitura  3 rc=0 2,0s linhas=4 com_tracos=0 sonda=
…
leitura 12 rc=0 2,0s linhas=4 com_tracos=0 sonda=
sobrou: 0
```

Recorte: omitidas as linhas de erro do `printf` da própria sonda, que recusava
o decimal com ponto em pt_BR e por isso trunca as durações acima — as exatas
foram de 1,95 a 3,06 s. Nenhuma falha, nenhuma linha `--`: o Docker só demora
mais (3 s) quando o contêiner morre no meio da leitura. A falha da E2-4 continua sendo um dublê; o
caminho real que resta para ela é o *daemon* não responder, e esperar alguns
segundos não o resolve — por isso não há nova tentativa dentro da amostra: a
amostra seguinte já é essa tentativa, com o instante certo. O que a medição
mostrou foi outra coisa: `intervalo_s` é a **pausa**, e o período real é maior
(4,5 s no registro de 20/09). `2022bdd` grava `periodo_medio_s`, medido na
série, e a tabela o mostra — contra o Docker real:

```text
| alvo | Airbyte,bancos | 0m 12s | 2,1 GB | 3,2 GB | 3 amostras, uma a cada 4,0 s (pausa de 2 s) |
{'intervalo_s': 2, 'amostras': 3, 'janela_s': 8, 'periodo_medio_s': 4.0, 'conteineres_maximo_mb': 3317, 'conteineres_falhas': 0}
```

**O que continua não verificado, e é de B5:** o passo 9 depois de uma
captura nova real (o esperado vem da classificação dela, e isso só se mede
com ela); o `jobId` atravessando `sync-legacy JOB_EM=` num disparo real (o
teste injeta o fluxo certificado); o runner Beam real encerrando pelo SIGINT
(a prova é de um Python comum lançado pelo cenário real); `restore-artefatos`
num clone; e tudo o que a §10 e a §11.3 já listavam.

## Achados da revisão — primeira rodada e respostas do autor

As referências E1–E9 são as evidências acima; as linhas de "Onde" referem-se ao
código da entrega em `3e21a54`. **Situação preenchida em 21/09/2026**, na mesma
sessão em que os 17 foram aplicados: cada um foi reproduzido antes de corrigir
— com a sonda da revisão onde ela existia, e com medição própria onde a revisão
declarou dublê. O que a execução acrescentou está na §10.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVE-01 | `src/mvp_ed1/airbyte.py:95` | **A própria URL da guarda é recusada pela API real.** `createdAt\|DESC` sem codificação retorna 400 / Malformed URI; `%7C` retorna a página esperada. Todo sync legado protegido depende dessa consulta, inclusive numa instalação normal. Construir a query com codificação de parâmetros e incluir contraprova no transporte real. **E2.** | `bloqueante` | **Corrigido** em `airbyte.py` (`caminho_dos_jobs`, query por `urlencode`). Contraprova real em 21/09: `GET /jobs?limit=100&orderBy=createdAt%7CDESC` → 43 jobs, maior 43; o `\|` cru continua 400. Teste: `test_a_listagem_de_jobs_codifica_a_ordenacao`. |
| RVE-02 | `docker/medir.sh:208`; `Makefile:293` | **Validar o alvo executa a receita antes da medição e do preflight.** O `make -n` executa a linha recursiva de `airbyte-up`; o registrador viu instalação, preflight e outra instalação. Com `ATE` inexistente houve instalação e depois a mensagem “nada foi medido”. A validação precisa consultar alvos sem executar receitas. **E6.** | `bloqueante` | **Corrigido** em `medir.sh` (`_alvo_existe`): a existência é lida da base de dados do `make` (`make -pn` com objetivo inexistente), sem executar receita. Repetida a sonda no Makefile real copiado: `airbyte-up` → `preflight` e **uma** instalação, na medição; `--ate` inexistente → nenhuma chamada. Teste: `test_validar_o_alvo_nao_executa_receita_recursiva`. |
| RVE-03 | `src/mvp_ed1/recovery/cli.py:340` | **Erros de restauração com retorno 1 são aceitos como aviso.** PostgreSQL usa 1 para erros SQL acumulados; a sonda com erro de COPY voltou sem recusa. O código ainda reduz o diagnóstico à última linha. Propagar falha e preservar o diagnóstico; tratar explicitamente dependências do destino povoado. A conferência incompleta do passo 5 não compensa isso. **E4.** | `bloqueante` | **Corrigido** em `cli._pg_restore`: `--single-transaction` (implica `--exit-on-error`), qualquer código ≠ 0 recusa com o diagnóstico inteiro. **Medido em banco isolado** (`rve_restore`, derrubado ao fim): restore em destino vazio 4,8 s e em destino povoado 6,4 s, 48 tabelas/423.377 linhas = manifesto; com uma view dependente fora do dump → recusado (código 1, `cannot drop table … other objects depend on it`) e o banco intocado. Teste: `test_pg_restore_com_erro_acumulado_e_recusado_numa_transacao_so`. |
| RVE-04 | `src/mvp_ed1/recovery/cli.py:228,265`; `leitura.py:110`; `rebase.py:130` | **O passo 5 não executa o contrato de conteúdo e de re-base.** Só consulta SCD e uma tabela da quarentena: não confere contagens das fontes/quatro schemas, Alembic, versões de governance ou capturas. `particao_preservada` não é chamada na aplicação, e o manifesto não guarda a partição. O domínio é conferido depois do commit. Ligar os oráculos reais à sequência e verificar a partição antes de confirmar a escrita, com recuo em violação. **E3/E4.** | `bloqueante` | **Corrigido**. Passo 5 (`_conferir_contra_o_banco`) confere contagens das três fontes, Alembic, `governance._versions`, corte do livro, capturas certificadas, classes/nulos por tabela e a **partição** (`rebase.assinatura`, invariante ao re-base, gravada no manifesto como `oraculo_particao`); acréscimo na quarentena é problema no passo 5. `comando_rebase` lê a partição antes e depois **dentro da transação** e recua (`_Recuo`) em violação. Medido: re-base real em banco isolado, 40 tabelas em 10,9 s, `customers` −28..−1 com 28 classes, idempotente, partição igual ao manifesto depois. O dublê incompleto da revisão agora devolve seis problemas (`test_o_passo_5_recusa_o_estado_que_a_revisao_viu_passar`). Defeito extra achado ao executar: `_linhas` fixava `stream_results` na **conexão** e o `update` seguinte saía como `DECLARE … CURSOR FOR update`; a opção passou para a instrução. |
| RVE-05 | `src/mvp_ed1/recovery/cli.py:404` | **O passo 9 anuncia uma restauração que não demonstrou.** Aceitou só o certificado 44, sem os certificados retidos, gerações exclusivamente positivas e sem fatia nova da quarentena. Não compara contagens das fontes, payloads/saldos dos dois caminhos ou memória de exclusões; também não recebe o jobId efetivamente disparado. Implementar os oráculos da §6 do plano, relacionar o acréscimo ao job real e validar os conjuntos esperados. `make check` não substitui essa comparação. **E4.** | `bloqueante` | **Corrigido** em `comando_conferir_restauracao`: contagens de `oltp`/`legacy` e Alembic = manifesto; certificados do manifesto todos presentes; capturas novas = as certificadas **depois do corte** (`capturas_certificadas_desde`, `job_id` gravado por `registrar_job`) e acima da retida, `--job N` opcional exige exatamente `{N}`; partição das linhas retidas (faixa negativa) = manifesto; acréscimo da quarentena só das capturas novas; memória de exclusões = `oraculo_exclusoes` (sem `observed_in_snapshot_id`); os dois caminhos por chave + 16 colunas (`metadata` como `jsonb`), saldo por armazém/SKU e soma dos deltas (`leitura.comparar_caminhos`). Medido no armazém vivo: 13.700 × 13.700, quatro zeros, somas 701.841. A fixture inválida da revisão agora sai 1 (`test_o_passo_9_recusa_a_restauracao_que_a_revisao_viu_ser_anunciada`). |
| RVE-06 | `Makefile:483`; `src/mvp_ed1/legacy/identidade.py:52` | **Falta o passo operacional D50 para um Airbyte novo.** A sequência vai de `airbyte-up` às sincronizações sem reconhecer/avançar o contador nem conferir o próximo job. Com histórico novo abaixo da captura retida, a guarda recusa; avanço isolado da sequência também não aparece no histórico GET. Implementar o passo já decidido, sua pós-condição e o recuo para interno desconhecido, sem confundir maior job existente com próximo valor da sequência. **E4.** | `bloqueante` | **Implementado**: `docker/airbyte_jobs.sh` (`ler`/`avancar`, premissas conferidas uma a uma: pod, tabela `jobs`, sequência por `pg_get_serial_sequence`, `setval` = valor) + verbo `avancar-jobs` + alvo `recovery-airbyte-jobs`, entre `airbyte-up` e `sync-airbyte` na sequência. Próximo valor lido da sequência com `is_called`, não do maior job; o verbo diz que a listagem só muda quando um job nasce — por isso `sync-airbyte` antecede `sync-legacy`. Premissa **medida** no Airbyte 2.2.0 instalado: `jobs.id` identity, `public.jobs_id_seq`, `last_value` 43 = `max(id)`; `avancar-jobs` real → "próximo job 44 > 43, nada a avançar", sem escrita. Testes: os cinco de D50 em `test_recovery.py`. |
| RVE-07 | `src/mvp_ed1/recovery/oraculos.py:40` | **A serialização não distingue todo conteúdo nem normaliza representações equivalentes.** `NULL`/texto `\N` e delimitadores dentro do texto colidem; fuso, escala de Decimal e memoryview divergem para valores equivalentes. Definir codificação não ambígua para tipos/nulos/limites e normalização temporal, decimal e binária; versionar o formato do oráculo. `timestamptz`/`numeric` estão no pacote. **E3/E8.** | `bloqueante` | **Corrigido** em `oraculos.py`: linha = documento JSON com valores tipados (nulo = `null`, texto escapado, `numeric` normalizado, instante em UTC, binário em hex, `jsonb` ordenado, etiquetas para data/hora/intervalo/UUID); `FORMATO = 2` gravado no manifesto e conferido em `verify`/`conferir-restauracao`. Os seis pares da sonda agora saem certos (colisões acusadas, equivalentes iguais) e `"1"`/`1`/`numeric 1` distinguem-se. Testes parametrizados em `test_recovery.py`. |
| RVE-08 | `docker/conteineres.sh:75`; `docker/preflight.sh:80,224` | **Falha ao enumerar Docker vira ausência de ambiente.** Com `docker ps` retornando 1, `preflight trabalho` saiu 0 e afirmou janela parada. Propagar erro de resolução como indeterminação, também nas conferências depois de parar/retomar. Sem isso, indisponibilidade da consulta pode liberar pacote ou troca sem conhecer o estado. **E7.** | `bloqueante` | **Corrigido**: `conteineres.sh resolver` sai 4 quando `docker ps` falha, `pausar`/`retomar` recusam-se a anunciar estado não lido; `preflight.sh` distingue 0/1/4 em `_ainda_no_ar`, recusa a troca antes de pausar e trata `trabalho` como indeterminado; `_parar` só é sucesso com estado lido; `airflow_scheduler` devolve 4; `medir.sh` grava `indeterminado`; `cli._conteineres` recusa. Testes: `test_docker_que_nao_responde_e_indeterminado_e_nao_janela_parada`, `test_enumeracao_que_falha_recusa_a_troca_antes_de_pausar`, `test_pausa_com_docker_mudo_nao_anuncia_nada`. |
| RVE-09 | `docker/preflight.sh:226` | **O produtor no host fica invisível quando o transporte está parado/ausente.** `_ainda_no_ar streaming` impede até chamar `pgrep`; a sonda com produtor ativo e sem contêineres terminou “janela parada”. O produtor escreve na origem independentemente de Redpanda, quebrando o corte entre dumps e manifesto. Conferir processos do host independentemente dos contêineres. **E7.** | `bloqueante` | **Corrigido** em `preflight.sh trabalho`: `_processos_no_host` (`pgrep -f mvp_ed1[.]streaming`) roda sempre, independente dos contêineres; `pgrep` que falha é indeterminado. Teste: `test_produtor_no_host_e_visto_mesmo_sem_transporte_de_pe` (`pgrep_consultado=True`, exit 1). |
| RVE-10 | `src/mvp_ed1/recovery/cli.py:99` | **Refazer o pacote apaga a volta anterior antes de obter a nova.** `rmtree(candidato)` precede o primeiro dump; uma falha nesse dump deixa o candidato anterior perdido. Construir em diretório separado, conferir e só então substituir, preservando a volta em qualquer falha. **E4.** | `bloqueante` | **Corrigido**: o candidato nasce em `candidato.em-montagem/` e só substitui o anterior inteiro (`pacote.comecar_montagem`/`concluir_montagem`); falha em qualquer passo abandona a montagem e preserva o anterior. Teste: `test_refazer_o_pacote_preserva_o_candidato_anterior_ate_o_novo_existir`. Pacote real montado no diretório de medição em 20 s. |
| RVE-11 | `docker/preflight.sh:305` | **A recusa de pausa parcial não restaura os contêineres que já parou dentro do grupo que falhou.** O grupo só entra em `PAUSADOS` quando a pausa inteira sucede. A contraprova deixou scheduler ativo e os outros três serviços do Airflow parados, sem `docker start`. Guardar o conjunto inicial por contêiner e recompor também a parte alterada do grupo que falhou; conferir a retomada integral. **E7.** | `ajuste` | **Corrigido** em `preflight.sh`: `_religar` religa **todos** os contêineres do grupo e confere que todos voltaram; o grupo cuja pausa falhou é recomposto além dos já pausados. Teste: `test_pausa_parcial_recompoe_o_grupo_que_falhou` (quatro de pé ao fim, `docker start` registrado). |
| RVE-12 | `docker/medir.sh:172` | **Interrupção não produz o registro prometido.** O trap define `INTERROMPIDO=true` e sai antes de `_escrever`; a sonda retornou 130 e nenhum JSON. Encerrar/recolher os filhos e o amostrador, e persistir o resultado também em INT/TERM. **E6.** | `ajuste` | **Corrigido** em `medir.sh`: `_finalizar` comum aos dois desfechos; o trap encerra os filhos, grava o registro com `interrompido: true` e `codigo_de_saida: 130` e sai 130. O trap só é instalado depois de as variáveis existirem. Teste: `test_interrupcao_deixa_o_registro_com_a_marca`. |
| RVE-13 | `docker/medir.sh:284` | **Medições do mesmo alvo no mesmo dia sobrescrevem a evidência anterior.** Duas execuções deixaram um único JSON, substituído. Snapshot, eventos novos e recuperação de B5 usam `cenario:streaming`; seus registros se perdem entre si e não guardam `LIMITE`/`ATE_SEQ` do cenário. Identificar cada execução/cenário com seus parâmetros e preservar todos os registros. **E6.** | `bloqueante` | **Corrigido** em `medir.sh`: nome `<instante ISO>_<alvo>` mais `_limite_n` e `_ate_x` quando existem, `.json`, colisão no mesmo segundo ganha o PID; o registro leva `parametros: {limite, corte}`. Testes: `test_duas_medicoes_do_mesmo_alvo_deixam_dois_registros`, e o cenário com `LIMITE=5` confere `{limite: 5, corte: 99}`. |
| RVE-14 | `docker/airflow_cli.sh:117` | **`dag-wait` reconhece substring, não identidade do run.** A resposta de sucesso de `rve-100` encerrou com sucesso a espera de `rve-10`. Interpretar o JSON e comparar exatamente `run_id` e estado, descartando o ruído antes da decisão. **E6.** | `ajuste` | **Corrigido** em `airflow_cli.sh` (`airflow_run_na_lista`): a lista é interpretada como JSON pelo Python do projeto e comparada por `run_id` **e** `state` exatos, com o ruído de log descartado antes. `rve-100` não fecha mais a espera de `rve-10`. Testes: `test_dag_wait_nao_aceita_run_id_que_so_contem_o_pedido`, `test_dag_wait_reconhece_o_run_id_exato_no_estado_pedido`. |
| RVE-15 | `src/mvp_ed1/recovery/cli.py:122`; `leitura.py:65` | **O manifesto não contém todo o metadado prometido pela §6.** O candidato real e o gerador não têm `seed`, `as_of_date` ou tamanhos por tabela; gravam somente contagens. Registrar os valores de geração efetivos e tamanhos medidos, sem inferir defaults, e conferir os campos obrigatórios antes de declarar o pacote apto. **E8.** | `ajuste` | **Corrigido**: o gerador da origem passa a gravar `data/source/geracao.json` (semente, `as_of`, fator, linhas, commit, instante — os efetivos); o manifesto ganha `geracao` (com `None` + motivo quando não há registro — a origem atual foi carregada antes disto, e o manifesto diz isso), `tamanhos` por tabela (`pg_total_relation_size`) e `CAMPOS_OBRIGATORIOS` conferidos em `pack` e `verify`. Teste: `test_a_geracao_registrada_nunca_e_inferida`, `test_o_manifesto_incompleto_ou_de_outro_formato_e_dito`. |
| RVE-16 | `src/mvp_ed1/recovery/rebase.py:120` | **O oráculo de domínio consome um Iterable duas vezes.** `dominio_valido(iter([0, 1]))` devolveu lista vazia porque a contagem de nulos esgotou o iterador antes de procurar não negativos. Materializar uma vez ou conferir em passagem única. Os chamadores atuais fornecem lista, então a falha não invalida os ciclos medidos. **E3.** | `ajuste` | **Corrigido** em `rebase.dominio_valido`: materializa uma vez. Teste: `test_o_dominio_aceita_um_iterador_sem_perder_a_segunda_passagem`. |
| RVE-17 | `Makefile:469` | **Falha ao pausar a DAG é ignorada pela manutenção.** `pausar ... \|\| true` deixa a sequência destrutiva continuar também quando há scheduler ativo e a pausa falha/expira. Diferenciar Airflow comprovadamente ausente de pausa indeterminada/falha; no segundo caso, recusar antes do descarte. **E4, inspeção do declarativo; pausa não executada.** | `bloqueante` | **Corrigido**: `airflow_cli.sh pausar` sai 0 (pausou), 3 (Airflow ausente — seguro) ou 1 (falhou/indeterminado); o passo 2 de `recovery-restore` só segue com 0 ou 3 e recusa com instrução nos demais. Testes: `test_pausar_distingue_airflow_ausente_de_pausa_que_falhou`, `test_a_manutencao_nao_ignora_a_pausa_que_falhou`. |

## Achados da revisão — segunda rodada, 23/09/2026

Esta tabela é o estado atual do parecer. As respostas da primeira rodada
acima ficam preservadas como relato do autor; RVE-05 e RVE-11 permanecem
parciais pelos motivos abaixo. Nenhuma correção desta rodada foi aplicada.

**Situação preenchida em 23/09/2026**, na sessão que aplicou os cinco: cada um
foi reproduzido pela sonda da §11.2 antes de corrigido e conferido por ela
depois; o que a aplicação acrescentou — dois achados próprios — está na §12.

| ID | Onde | Achado e correção necessária | Veredito | Situação |
|---|---|---|---|---|
| RVE2-01 | `src/mvp_ed1/recovery/cli.py:724` | **O passo 9 aceita a ausência da auditoria da captura nova.** Partindo da fixture válida, retirar somente a fatia 44 da quarentena mantém saída 0, inclusive com `job=44`. O código confere que fatias extras pertencem às capturas novas, mas não que as fatias esperadas existem com as linhas certas. Comparar contagem/conteúdo do acréscimo com a classificação da captura efetivamente disparada, aceitando vazio somente quando o esperado for vazio; conduzir seu jobId do passo 8 ao passo 9. É a parte ainda não cumprida de RVE-05 e da §6, passo 9. **E2-3.** | `bloqueante` | **Corrigido** (`fba57cc`) em `cli._conferir_auditoria_da_captura_nova`: o acréscimo da captura nova é comparado, por contagem **e** digest, com `leitura.classificacao_corrente` — as rejeitadas de `trusted.legacy_classifications`, de que a quarentena é `select *` —; a classificação precisa tratar exatamente as capturas novas; nada a mais entra em nome delas; captura sem rejeição tem acréscimo vazio e passa. `--job` é obrigatório: `sync-legacy JOB_EM=` grava o jobId da captura concluída **e** certificada, e `recovery-restore` o leva ao passo 9, apagando antes o de uma execução anterior. Premissa medida no banco vivo, só leitura: a fatia da 43 é igual às rejeitadas da classificação (3.207 linhas, mesmo digest), e a conferência nova, com a 43 no papel de nova, passa com a fatia e acusa sem ela (§12). Sonda E2-3 repetida: `sem_fatia_da_captura_nova codigo= 1`. **Achado próprio na mesma sonda:** `livros_ambos_vazios` também saía 0 — os dois caminhos agora precisam ter o tamanho do livro na origem (13.700 nos três, medido). Testes: `test_o_passo_9_recusa_a_falta_da_auditoria_da_captura_nova` e mais nove — seis do passo 9 (um é o do livro vazio), três do `--job-em`. |
| RVE2-02 | `docker/medir.sh:42`; `docker/medir.sh:58` | **Falha de `docker stats` vira medição de 0 MB com sucesso.** Na sonda, `ps` informa Airbyte de pé, `stats` sai 1 nas duas consultas e o JSON grava duas amostras, máximo 0 e código 0. O `awk` produz zero para entrada vazia; o `printf` externo perde a falha. Propagar o estado da coleta, separar amostras válidas de falhas e registrar a métrica como indisponível quando não foi medida. Um zero inventado não pode alimentar a tabela de capacidade de B5 (P5). **E2-4.** | `bloqueante` | **Corrigido** (`e12d39d`) em `medir.sh`: leitura que falha é `NA` — `docker stats` com erro, linha sem número (`--`), `/proc/meminfo` ilegível —; `agregar` tira o extremo só das amostras válidas de cada grandeza e conta `disponivel_falhas`/`conteineres_falhas`; sem nenhuma válida o extremo é `null`, sem instante; a linha da tabela diz "não medido" e avisa quantas faltaram. O código de saída continua o do alvo, que rodou. Sonda E2-4 repetida: `conteineres_maximo_mb: None`, `conteineres_falhas: 2`. Contra o Docker real: 3.222 MB, 0 falhas (§12). Testes: `test_docker_stats_que_nao_mede_vira_nao_medido_e_nao_zero` (duas formas) e mais três. |
| RVE2-03 | `docker/preflight.sh:134` | **O recuo da pausa liga serviços que já estavam parados.** Com apiserver inicialmente `exited` e parada do scheduler falhando, a tentativa recusada terminou com os quatro serviços de pé. `_religar` usa `resolver --todos`, sem preservar o conjunto inicial pedido em RVE-11. Guardar os nomes de pé antes da pausa e recompor exatamente esse conjunto, tanto na falha parcial quanto na recusa por memória; não aumentar o consumo ao desfazer uma troca recusada por R11. **E2-4.** | `ajuste` | **Corrigido** (`ad19028`) em `preflight.sh`: `_parar` anota por ambiente o que estava de pé (`ANTES_DA_PAUSA`) e `_religar` recompõe **exatamente** esse conjunto, conferindo nome a nome; vale para a pausa parcial e para a recusa por memória. `resolver --todos` fica só com a retomada pedida pelo operador (`*-resume`). Sonda E2-4 repetida: `ligados_sem_estarem_de_pe []`. Testes: `test_recuo_da_pausa_parcial_nao_liga_o_que_ja_estava_parado`, `test_recusa_por_memoria_devolve_so_o_que_estava_de_pe`. Com isto RVE-11 fica inteiro. |
| RVE2-04 | `docker/medir.sh:303` | **O processo Python lançado pelo cenário herda `SIGINT` ignorado.** Com o lançador real e um Python mínimo que captura `KeyboardInterrupt`, a disposição foi `SIG_IGN`; SIGINT não o encerrou e houve SIGKILL após o prazo, com retorno 0. A CLI real usa `KeyboardInterrupt` para a interrupção; `setsid` só separa o grupo. Restaurar a disposição de sinal antes de executar o filho e provar encerramento cooperativo; registrar quando foi necessário forçar. O runner Beam real não foi executado nesta contraprova. **E2-4.** | `ajuste` | **Corrigido** (`e2a18c5`) em `medir.sh`: `( trap - INT QUIT; exec setsid make … stream-run ) &` — a disposição volta ao padrão antes do `exec`, que preserva o PID anotado como grupo. O registro ganha `encerramento`: `limpo`, `forcado` ou `null`. Sonda repetida: `default_int_handler`, `KeyboardInterrupt` recebido, sem SIGKILL. **O que a correção revelou:** os cenários da suíte com `sleep 600` também só saíam pelo SIGKILL do prazo, sem que ninguém visse — a suíte do medidor caiu de 35 s para 29 s. O runner Beam real não foi executado (é de B5). Testes: `test_o_pipeline_lancado_encerra_pelo_sigint_e_nao_pelo_prazo`, `test_encerramento_forcado_fica_no_registro`. |
| RVE2-05 | `src/mvp_ed1/recovery/cli.py:562` | **Restaurar artefatos preserva metadado de uma carga posterior quando ele estava ausente do pacote.** O candidato real não tem `data/source/geracao.json`; em um checkout temporário com esse arquivo de outra carga, `restore-artefatos` saiu 0 e o próximo `geracao_registrada` atribuiu à fonte restaurada os parâmetros posteriores. B5 executa `seed-data` antes de restaurar, portanto cria esse caso com o candidato atual. Restaurar também a ausência dos arquivos de estado conhecidos, ou invalidar explicitamente o registro incompatível, para que a falta continue sendo `None` com motivo. **E2-5.** | `ajuste` | **Corrigido** (`8c04106`) em `restore-artefatos`: o estado de trabalho que o pacote não traz é afastado — renomeado com `.anterior-a-restauracao-<instante>`, fora dos padrões de `ARTEFATOS`, nunca apagado —, e tudo é conferido antes de qualquer arquivo mudar. **Achado próprio na mesma função:** o `copy2` sobre `data/legacy/manifesto.json` escrevia **através do link** do *checkout*, no manifesto do lote apontado — onde `mutacoes._ler` grava o diário (medido num rascunho, §12). O pack passa a registrar `artefatos_links` (obrigatório) e a restauração refaz o link. O candidato de 21/09 não tinha o campo e a restauração o recusava sem tocar em nada: **refeito** (corte `2026-09-23T20:53:54+00:00`, código `8c04106`) e conferido contra os bancos. Sonda E2-5 repetida contra ele: `registro_posterior_sobreviveu False`, `proximo_pack_atribuiria_a_origem None`. Testes: `test_restaurar_os_artefatos_restaura_a_ausencia` e mais quatro. |
