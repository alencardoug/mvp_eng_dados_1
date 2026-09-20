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

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

