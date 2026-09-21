# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `2b2b0f0..3e21a54` — leia o diff, ele não é repetido aqui.

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

## Achados da revisão

Todos estão **abertos**; a sessão foi de revisão, sem correções de implementação.
As referências E1–E9 são as evidências acima. Linhas referem-se ao código da
entrega, que não foi alterado depois de `3e21a54`.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVE-01 | `src/mvp_ed1/airbyte.py:95` | **A própria URL da guarda é recusada pela API real.** `createdAt\|DESC` sem codificação retorna 400 / Malformed URI; `%7C` retorna a página esperada. Todo sync legado protegido depende dessa consulta, inclusive numa instalação normal. Construir a query com codificação de parâmetros e incluir contraprova no transporte real. **E2.** | `bloqueante` | Aberto — erro HTTP medido; nenhum job disparado. |
| RVE-02 | `docker/medir.sh:208`; `Makefile:293` | **Validar o alvo executa a receita antes da medição e do preflight.** O `make -n` executa a linha recursiva de `airbyte-up`; o registrador viu instalação, preflight e outra instalação. Com `ATE` inexistente houve instalação e depois a mensagem “nada foi medido”. A validação precisa consultar alvos sem executar receitas. **E6.** | `bloqueante` | Aberto — contraprova com Makefile real copiado e executáveis simulados. |
| RVE-03 | `src/mvp_ed1/recovery/cli.py:340` | **Erros de restauração com retorno 1 são aceitos como aviso.** PostgreSQL usa 1 para erros SQL acumulados; a sonda com erro de COPY voltou sem recusa. O código ainda reduz o diagnóstico à última linha. Propagar falha e preservar o diagnóstico; tratar explicitamente dependências do destino povoado. A conferência incompleta do passo 5 não compensa isso. **E4.** | `bloqueante` | Aberto — sem restore real; semântica conferida na fonte primária e tratamento exercitado com dublê. |
| RVE-04 | `src/mvp_ed1/recovery/cli.py:228,265`; `leitura.py:110`; `rebase.py:130` | **O passo 5 não executa o contrato de conteúdo e de re-base.** Só consulta SCD e uma tabela da quarentena: não confere contagens das fontes/quatro schemas, Alembic, versões de governance ou capturas. `particao_preservada` não é chamada na aplicação, e o manifesto não guarda a partição. O domínio é conferido depois do commit. Ligar os oráculos reais à sequência e verificar a partição antes de confirmar a escrita, com recuo em violação. **E3/E4.** | `bloqueante` | Aberto — o dublê de estado incompleto passou com `problemas=[]`. |
| RVE-05 | `src/mvp_ed1/recovery/cli.py:404` | **O passo 9 anuncia uma restauração que não demonstrou.** Aceitou só o certificado 44, sem os certificados retidos, gerações exclusivamente positivas e sem fatia nova da quarentena. Não compara contagens das fontes, payloads/saldos dos dois caminhos ou memória de exclusões; também não recebe o jobId efetivamente disparado. Implementar os oráculos da §6 do plano, relacionar o acréscimo ao job real e validar os conjuntos esperados. `make check` não substitui essa comparação. **E4.** | `bloqueante` | Aberto — contraprova retornou 0 com o estado inválido descrito. |
| RVE-06 | `Makefile:483`; `src/mvp_ed1/legacy/identidade.py:52` | **Falta o passo operacional D50 para um Airbyte novo.** A sequência vai de `airbyte-up` às sincronizações sem reconhecer/avançar o contador nem conferir o próximo job. Com histórico novo abaixo da captura retida, a guarda recusa; avanço isolado da sequência também não aparece no histórico GET. Implementar o passo já decidido, sua pós-condição e o recuo para interno desconhecido, sem confundir maior job existente com próximo valor da sequência. **E4.** | `bloqueante` | Aberto — ausência confirmada no declarativo; interno do Airbyte não foi alterado. |
| RVE-07 | `src/mvp_ed1/recovery/oraculos.py:40` | **A serialização não distingue todo conteúdo nem normaliza representações equivalentes.** `NULL`/texto `\N` e delimitadores dentro do texto colidem; fuso, escala de Decimal e memoryview divergem para valores equivalentes. Definir codificação não ambígua para tipos/nulos/limites e normalização temporal, decimal e binária; versionar o formato do oráculo. `timestamptz`/`numeric` estão no pacote. **E3/E8.** | `bloqueante` | Aberto — colisões e falsos diferentes reproduzidos; sem mudança no pacote. |
| RVE-08 | `docker/conteineres.sh:75`; `docker/preflight.sh:80,224` | **Falha ao enumerar Docker vira ausência de ambiente.** Com `docker ps` retornando 1, `preflight trabalho` saiu 0 e afirmou janela parada. Propagar erro de resolução como indeterminação, também nas conferências depois de parar/retomar. Sem isso, indisponibilidade da consulta pode liberar pacote ou troca sem conhecer o estado. **E7.** | `bloqueante` | Aberto — falha de enumeração simulada, aceitação observada. |
| RVE-09 | `docker/preflight.sh:226` | **O produtor no host fica invisível quando o transporte está parado/ausente.** `_ainda_no_ar streaming` impede até chamar `pgrep`; a sonda com produtor ativo e sem contêineres terminou “janela parada”. O produtor escreve na origem independentemente de Redpanda, quebrando o corte entre dumps e manifesto. Conferir processos do host independentemente dos contêineres. **E7.** | `bloqueante` | Aberto — `pgrep_consultado=False`, exit 0. |
| RVE-10 | `src/mvp_ed1/recovery/cli.py:99` | **Refazer o pacote apaga a volta anterior antes de obter a nova.** `rmtree(candidato)` precede o primeiro dump; uma falha nesse dump deixa o candidato anterior perdido. Construir em diretório separado, conferir e só então substituir, preservando a volta em qualquer falha. **E4.** | `bloqueante` | Aberto — comprovado apenas em candidato fictício; candidato real preservado. |
| RVE-11 | `docker/preflight.sh:305` | **A recusa de pausa parcial não restaura os contêineres que já parou dentro do grupo que falhou.** O grupo só entra em `PAUSADOS` quando a pausa inteira sucede. A contraprova deixou scheduler ativo e os outros três serviços do Airflow parados, sem `docker start`. Guardar o conjunto inicial por contêiner e recompor também a parte alterada do grupo que falhou; conferir a retomada integral. **E7.** | `ajuste` | Aberto — troca recusada corretamente, mas estado anterior não preservado. |
| RVE-12 | `docker/medir.sh:172` | **Interrupção não produz o registro prometido.** O trap define `INTERROMPIDO=true` e sai antes de `_escrever`; a sonda retornou 130 e nenhum JSON. Encerrar/recolher os filhos e o amostrador, e persistir o resultado também em INT/TERM. **E6.** | `ajuste` | Aberto — sinal enviado somente ao processo temporário da sonda. |
| RVE-13 | `docker/medir.sh:284` | **Medições do mesmo alvo no mesmo dia sobrescrevem a evidência anterior.** Duas execuções deixaram um único JSON, substituído. Snapshot, eventos novos e recuperação de B5 usam `cenario:streaming`; seus registros se perdem entre si e não guardam `LIMITE`/`ATE_SEQ` do cenário. Identificar cada execução/cenário com seus parâmetros e preservar todos os registros. **E6.** | `bloqueante` | Aberto — perda reproduzida em diretório temporário. |
| RVE-14 | `docker/airflow_cli.sh:117` | **`dag-wait` reconhece substring, não identidade do run.** A resposta de sucesso de `rve-100` encerrou com sucesso a espera de `rve-10`. Interpretar o JSON e comparar exatamente `run_id` e estado, descartando o ruído antes da decisão. **E6.** | `ajuste` | Aberto — resposta simulada; nenhuma DAG disparada. |
| RVE-15 | `src/mvp_ed1/recovery/cli.py:122`; `leitura.py:65` | **O manifesto não contém todo o metadado prometido pela §6.** O candidato real e o gerador não têm `seed`, `as_of_date` ou tamanhos por tabela; gravam somente contagens. Registrar os valores de geração efetivos e tamanhos medidos, sem inferir defaults, e conferir os campos obrigatórios antes de declarar o pacote apto. **E8.** | `ajuste` | Aberto — ausência medida no candidato e confirmada no código. |
| RVE-16 | `src/mvp_ed1/recovery/rebase.py:120` | **O oráculo de domínio consome um Iterable duas vezes.** `dominio_valido(iter([0, 1]))` devolveu lista vazia porque a contagem de nulos esgotou o iterador antes de procurar não negativos. Materializar uma vez ou conferir em passagem única. Os chamadores atuais fornecem lista, então a falha não invalida os ciclos medidos. **E3.** | `ajuste` | Aberto — contraprova da assinatura pública; sem efeito medido na CLI atual. |
| RVE-17 | `Makefile:469` | **Falha ao pausar a DAG é ignorada pela manutenção.** `pausar ... \|\| true` deixa a sequência destrutiva continuar também quando há scheduler ativo e a pausa falha/expira. Diferenciar Airflow comprovadamente ausente de pausa indeterminada/falha; no segundo caso, recusar antes do descarte. **E4, inspeção do declarativo; pausa não executada.** | `bloqueante` | Aberto — encadeamento lido, não executado. |
