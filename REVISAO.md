# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `2136781..dbdb52b` — leia o diff, ele não é repetido aqui.

**Quarta rodada, mesmo escopo B0/B1/B4** (B2/B3 continuam para a revisão final, depois de B6,
por decisão do Owner). O intervalo começa onde o da terceira terminou (`2136781`) e traz duas
coisas: a resposta aos dois achados dela — RVE3-01 e RVE3-02, com a verificação do que a aplicação
deixou aberto — e as duas decisões que essa verificação levantou, **D53 e D54**, tomadas pelo Owner
em 24/09/2026 e implementadas aqui. Exercitá-las de verdade, com a memória liberada pelo Owner,
levantou mais duas, **D55 e D56**, decididas no mesmo dia e também implementadas aqui. O parecer da
terceira rodada, as evidências E3-\* e as saídas da aplicação e da verificação estão no dossiê
anterior, `git show c10a30c:REVISAO.md` (§9–§11), com o código das sondas. A §8 abaixo traz os dois
achados com a resposta de cada um, a §9, as quatro decisões, e a §10, o exercício real — é o que
esta rodada confere.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
78d0dcb docs: prepara o dossiê da terceira rodada de revisão da entrega
9f19705 docs: registra a terceira rodada de revisão do Codex no dossiê
4921289 fix: o medidor converte a memória sob o locale C, e não sob o da máquina
d3a20df fix: a retomada do Airbyte espera a API responder, e prazo esgotado é erro
c58a3cd fix: sem curl, a retomada do Airbyte recusa antes de religar o cluster
9d856df fix: o prazo esgotado da retomada do Airbyte é dito em consultas, não em minutos
6cf0118 test: o dublê da API não afirma o código de saída que não foi medido
b63df0b docs: aplica a terceira rodada de revisão da entrega no dossiê, no plano e nas pendências
5851d41 fix: o prazo esgotado da retomada diz o tempo que contou, não uma cadência
f3f20db docs: registra D53 e D54, levantadas na verificação do RVE3-02
c10a30c docs: registra a verificação do que a terceira rodada deixou aberto
5f5efc5 fix: o preflight não cobra de novo o alvo que já está de pé
4c3410f fix: airbyte-up com o cluster de pé confere a API em vez de reinstalar
93c849c fix: as retomadas passam pela troca do preflight
4b785d3 docs: registra D53 e D54, decididas e implementadas
8e7f01b docs: prepara o dossiê da quarta rodada de revisão da entrega
d1cfb27 fix: a rede do projeto é externa, e nenhum down a remove
dbdb52b docs: registra D55 e D56, levantadas ao exercitar a D53 e a D54
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 15 arquivos

- `CLAUDE.md`
- `Makefile`
- `PLANO_etapa_12.md`
- `README.md`
- `docker/conteineres.sh`
- `docker/docker-compose.airflow.yml`
- `docker/docker-compose.streaming.yml`
- `docker/docker-compose.yml`
- `docker/medir.sh`
- `docker/preflight.sh`
- `docs/execucao_local.md`
- `docs/pendencias.md`
- `tests/test_makefile.py`
- `tests/test_medicao.py`
- `tests/test_preflight.py`

### Gerados — 1 arquivos, revisar por amostragem

- `REVISAO.md`

**Declaração desta entrega.** O único "gerado" acima é o dossiê anterior, marcado pelo próprio
cabeçalho; não há derivado de código no intervalo. Pedem revisão integral, porque são o contrato
do que o resto faz:

- `Makefile` — `ESTADO_AIRBYTE`, `CURL_DA_ESPERA`, `AGUARDAR_API_AIRBYTE` e `RETOMAR_AIRBYTE`;
  `airbyte-up` com os três estados lidos e as conferências antes do preflight; os três `*-resume`,
  com a conferência de que há o que religar e o preflight da própria família (RVE3-02, D53, D54);
- `docker/preflight.sh` — `_inteiro_no_ar` e `ALVO_DE_PE`: o alvo inteiro de pé não é cobrado, e a
  pausa da outra família não é desfeita por memória (D53);
- `docker/medir.sh` — todo `awk` sob `LC_ALL=C` e a vírgula da tabela posta à mão (RVE3-01);
- as três composições (`docker/docker-compose*.yml`) — a rede do projeto, `external`; e no `Makefile`,
  `REDE` e `GARANTIR_REDE`, antes de todo `up` de composição; o nome do projeto vem de
  `docker/conteineres.sh projeto` (D55).

Os testes são os oráculos: vale conferir se provam o que dizem. `tests/test_makefile.py` executa o
`Makefile` real num rascunho com executáveis simulados; o `docker` simulado imita o `docker ps` real
(`-a`, `-f status=`, `--format '{{.State}}'`), e a regra da D54 é lida do texto do `Makefile`.
`tests/test_preflight.py` roda o script num *namespace* com `/proc/meminfo` trocado.
`PLANO_etapa_12.md`, `CLAUDE.md`, `README.md` e os `docs/` só registram.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
............................s........................................... [ 27%]
......................sss................sss............................ [ 40%]
........................................................................ [ 54%]
........................................................................ [ 68%]
........................................................................ [ 81%]
........................................................................ [ 95%]
.........................                                                [100%]
521 passed, 8 skipped in 247.88s (0:04:07)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

O `dbt build` desse mesmo `make check`, pelo `dbt/target/run_results.json` que ele deixou
(`generated_at` `2026-09-24T20:24:47Z`): 905 resultados — 705 `pass` e 200 `success`.
Os três `aviso:` do fim são da linhagem derivada, sobre `legacy_classifications`, e não são
desta entrega: os mesmos três saem desde o dossiê de 20/09 (`e46e87a`), e o modelo não muda desde
15/09 (`9200b15`).

### Medições desta entrega, além do `comandos.txt`

Saída literal, colada. As do RVE3-01 e do RVE3-02 — a reprodução antes da correção, as duas pausas
reais do Airbyte, o prazo esgotado de verdade, o `busybox awk` — estão nas §10 e §11 do dossiê
anterior (`git show c10a30c:REVISAO.md`), com o código das sondas, e não são repetidas. As desta
seção são da D53 e da D54, de antes do exercício real; as do exercício, da D55 e da D56 estão na §10.

**Os testes novos, antes e depois.** Cada teste novo rodou contra o código de `c10a30c`, onde
precisa reprovar, e contra o novo. O preflight, com `/proc/meminfo` e `docker` simulados — antes,
com `docker/preflight.sh` de `c10a30c`; depois, com o de `5f5efc5`:

```text
FAILED tests/test_preflight.py::test_alvo_ja_de_pe_nao_e_cobrado_de_novo[airbyte]
FAILED tests/test_preflight.py::test_alvo_ja_de_pe_nao_e_cobrado_de_novo[airflow]
FAILED tests/test_preflight.py::test_alvo_ja_de_pe_nao_e_cobrado_de_novo[streaming]
FAILED tests/test_preflight.py::test_alvo_de_pe_ainda_troca_a_outra_familia
4 failed, 5 passed, 30 deselected in 5.12s
```

```text
39 passed in 20.76s
```

Os dois que passam nos dois lados — `test_alvo_de_pe_pela_metade_continua_cobrado` e
`test_alvo_de_pe_com_trabalho_na_outra_familia_recusa_sem_tocar` — fixam o que **não** podia mudar.
Os outros três dos cinco que passam antes são testes do RVE2-03 cujo nome contém `de_pe`.

O `Makefile`: o arquivo de testes novo rodado contra o `Makefile` de `c10a30c`, copiado para um
rascunho; contra o de `4c3410f` (só a D53, com o arquivo de testes daquele *commit*); e
contra o de `93c849c`:

```text
FAILED tests/test_makefile.py::test_a_retomada_diz_pronta_so_quando_a_api_responde[pronta-na-primeira-airbyte-up-de-pe]
FAILED tests/test_makefile.py::test_a_retomada_diz_pronta_so_quando_a_api_responde[espera-o-silencio-e-o-503-passarem-airbyte-up-de-pe]
FAILED tests/test_makefile.py::test_a_retomada_que_esgota_o_prazo_falha[sem-resposta-airbyte-up-de-pe]
FAILED tests/test_makefile.py::test_a_retomada_que_esgota_o_prazo_falha[ingress-sem-servidor-airbyte-up-de-pe]
FAILED tests/test_makefile.py::test_a_retomada_que_esgota_o_prazo_falha[available-false-airbyte-up-de-pe]
FAILED tests/test_makefile.py::test_sem_curl_a_espera_recusa_antes_de_mexer_em_qualquer_coisa[airbyte-up-pausado]
FAILED tests/test_makefile.py::test_sem_curl_a_espera_recusa_antes_de_mexer_em_qualquer_coisa[airbyte-up-de-pe]
FAILED tests/test_makefile.py::test_airbyte_up_com_o_cluster_de_pe_confere_a_api_sem_reinstalar
FAILED tests/test_makefile.py::test_docker_mudo_nao_decide_as_cegas[airbyte-up]
FAILED tests/test_makefile.py::test_docker_mudo_nao_decide_as_cegas[airbyte-resume]
FAILED tests/test_makefile.py::test_airbyte_up_em_estado_que_nao_trata_recusa
FAILED tests/test_makefile.py::test_todo_alvo_que_liga_ambiente_pesado_passa_pelo_preflight
FAILED tests/test_makefile.py::test_a_retomada_passa_pela_troca_antes_de_religar[airbyte-resume]
FAILED tests/test_makefile.py::test_a_retomada_passa_pela_troca_antes_de_religar[stream-resume]
FAILED tests/test_makefile.py::test_a_retomada_passa_pela_troca_antes_de_religar[airflow-resume]
FAILED tests/test_makefile.py::test_recusa_do_preflight_nao_religa_nada[airbyte-resume]
FAILED tests/test_makefile.py::test_recusa_do_preflight_nao_religa_nada[stream-resume]
FAILED tests/test_makefile.py::test_recusa_do_preflight_nao_religa_nada[airflow-resume]
FAILED tests/test_makefile.py::test_force_na_retomada_e_a_autorizacao_do_owner[airbyte-resume]
FAILED tests/test_makefile.py::test_force_na_retomada_e_a_autorizacao_do_owner[stream-resume]
FAILED tests/test_makefile.py::test_force_na_retomada_e_a_autorizacao_do_owner[airflow-resume]
FAILED tests/test_makefile.py::test_retomar_o_que_nao_existe_recusa_antes_da_troca[stream-resume]
FAILED tests/test_makefile.py::test_retomar_o_que_nao_existe_recusa_antes_da_troca[airflow-resume]
23 failed, 18 passed in 3.29s
```

```text
28 passed in 11.04s
```

```text
41 passed in 4.15s
```

Dois dos 23 — `test_retomar_o_que_nao_existe_recusa_antes_da_troca[stream-resume]` e
`[airflow-resume]` — reprovam o antigo por um limite do dublê, não pelo defeito: o `conteineres.sh`
simulado sai 0 em `retomar`, e o real sairia 3 ("nada a retomar"). O que eles afirmam de novo —
nenhuma troca antes de saber que há o que religar — o antigo cumpria por não ter troca.

A D55, com o arquivo de testes novo contra o código de `d1cfb27^` e contra o de `d1cfb27`:

```text
FAILED tests/test_makefile.py::test_as_composicoes_declaram_a_rede_do_projeto_como_externa[docker/docker-compose.yml]
FAILED tests/test_makefile.py::test_as_composicoes_declaram_a_rede_do_projeto_como_externa[docker/docker-compose.airflow.yml]
FAILED tests/test_makefile.py::test_as_composicoes_declaram_a_rede_do_projeto_como_externa[docker/docker-compose.streaming.yml]
FAILED tests/test_makefile.py::test_todo_up_do_compose_garante_a_rede_antes
FAILED tests/test_makefile.py::test_make_up_cria_a_rede_so_quando_falta[sem-rede]
FAILED tests/test_makefile.py::test_make_up_cria_a_rede_so_quando_falta[com-rede]
FAILED tests/test_makefile.py::test_sem_rede_nada_sobe - AssertionError: dock...
FAILED tests/test_preflight.py::test_projeto_diz_o_nome_que_o_compose_usa - A...
8 failed, 80 deselected in 0.42s
```

```text
88 passed in 24.81s
```

**Contra a máquina, sem mudar o estado dela.** Os três bancos e o Airbyte de pé, o Airflow parado
(`exited` há três dias) e o *streaming* ausente. As receitas rodaram na árvore que virou `93c849c`,
antes do *commit*; depois disso só mudou um comentário de `airbyte-up`. A consulta do preflight, sem
`--trocar`, com o script de `c10a30c` e com o novo:

```text
$ docker ps --format '{{.Names}}\t{{.Status}}'
mvp_ed1_legacy_db	Up 27 minutes (healthy)
mvp_ed1_source_db	Up 27 minutes (healthy)
mvp_ed1_warehouse_db	Up 27 minutes (healthy)
airbyte-abctl-control-plane	Up 27 minutes
== docker/preflight.sh airbyte — o de c10a30c
[preflight] RAM disponível agora: 2,3 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airbyte' custa ~4,9 GB — sobraria -2,5 GB

RECUSADO — sobraria menos que a folga mínima de 1,5 GB para o host.
  A política de quais subconjuntos bastam está em docs/execucao_local.md §5.

  Feche o que não está em uso — VS Code, navegador, sessões de agente —
  ou derrube o que estiver de pé, e rode de novo.

  Se ambos são mesmo necessários (reconciliar o CDC contra a
  carga completa), isto é uma PAUSA para o Owner liberar recursos:
  peça a ele, confirme, e então autorize com FORCE=1.
saida=1
== docker/preflight.sh airbyte — o novo
[preflight] RAM disponível agora: 2,3 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airbyte' já está de pé — nada a cobrar
[preflight] OK
saida=0
```

`make airbyte-up` com o cluster de pé:

```text
[preflight] RAM disponível agora: 2,3 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airbyte' já está de pé — nada a cobrar
[preflight] OK
cluster de pé — conferindo a API
aguardando a API do Airbyte pronta.

Interface em http://localhost:8000 — credenciais em 'make airbyte-credentials'.

real	0m0,320s
user	0m0,135s
sys	0m0,149s
saida=0
```

`make airbyte-resume` com o cluster de pé — o `StartedAt` do nó antes e depois —, `make stream-resume`
sem contêineres de *streaming*, e a consulta que o `airflow-resume` faz agora antes de religar:

```text
== make airbyte-resume (cluster de pé)
[preflight] RAM disponível agora: 2,6 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airbyte' já está de pé — nada a cobrar
[preflight] OK
aguardando a API do Airbyte pronta.

real	0m0,318s
user	0m0,127s
sys	0m0,135s
saida=0
StartedAt antes: 2026-09-24T18:13:59.936591809Z
StartedAt depois: 2026-09-24T18:13:59.936591809Z
== make stream-resume (sem contêineres de streaming)
streaming não tem contêineres neste projeto — use 'make stream-up'.
make: *** [Makefile:336: stream-resume] Erro 1
saida=2
== make preflight ALVO=airflow (consulta, sem efeito)
[preflight] RAM disponível agora: 2,6 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 1,2 GB

RECUSADO — sobraria menos que a folga mínima de 1,5 GB para o host.
  A política de quais subconjuntos bastam está em docs/execucao_local.md §5.

  Feche o que não está em uso — VS Code, navegador, sessões de agente —
  ou derrube o que estiver de pé, e rode de novo.

  Se ambos são mesmo necessários (reconciliar o CDC contra a
  carga completa), isto é uma PAUSA para o Owner liberar recursos:
  peça a ele, confirme, e então autorize com FORCE=1.
make: *** [Makefile:254: preflight] Erro 1
saida=2
mvp_ed1_legacy_db	Up 34 minutes (healthy)
mvp_ed1_source_db	Up 34 minutes (healthy)
mvp_ed1_warehouse_db	Up 34 minutes (healthy)
airbyte-abctl-control-plane	Up 34 minutes
```

Com 2,6 GB livres, o `airflow-resume` de `c10a30c` teria religado os quatro contêineres do Airflow —
~1,4 GB, custo derivado, não medido isoladamente — sem essa pergunta. O `airflow-resume` novo não
rodou de verdade: se a memória subisse entre a consulta e ele, a retomada passaria e religaria o
Airflow, que ninguém pediu. Rodou depois, com a memória liberada — e não religou nada: §10.3.

**`docker start` num contêiner de pé não o reinicia** — é do que `airbyte-resume` depende com o
cluster de pé. Sonda com um contêiner descartável, removido no fim:

```bash
set -u; n=sonda-docker-start-$$; docker run -d --rm --name $n --entrypoint sleep redis:7.2-bookworm 120 >/dev/null
a=$(docker inspect -f '{{.State.StartedAt}} pid={{.State.Pid}}' $n); docker start $n >/dev/null
echo "docker start num contêiner de pé: saída=$?"
b=$(docker inspect -f '{{.State.StartedAt}} pid={{.State.Pid}}' $n)
echo "antes:  $a"; echo "depois: $b"; [ "$a" = "$b" ] && echo "mesmo início e mesmo pid — não reiniciou"
docker rm -f $n >/dev/null && echo "sonda removida"
```

```text
docker start num contêiner de pé: saída=0
antes:  2026-09-24T18:47:51.176851791Z pid=56317
depois: 2026-09-24T18:47:51.176851791Z pid=56317
mesmo início e mesmo pid — não reiniciou
sonda removida
```

**Os estados que o `{{.State}}` devolve nesta máquina** — é por eles que `ESTADO_AIRBYTE` decide:

```text
$ docker ps -a --format '{{.Names}}\t{{.State}}\t{{.Status}}' | grep -E "mvp_ed1|airbyte|codex-backend"
mvp_ed1_legacy_db	running	Up 38 minutes (healthy)
mvp_ed1_source_db	running	Up 38 minutes (healthy)
mvp_ed1_warehouse_db	running	Up 38 minutes (healthy)
mvp_ed1-airflow_scheduler-1	exited	Exited (1) 3 days ago
mvp_ed1-airflow_apiserver-1	exited	Exited (0) 3 days ago
mvp_ed1-airflow_dag_processor-1	exited	Exited (1) 3 days ago
mvp_ed1-airflow_init-1	exited	Exited (0) 3 days ago
mvp_ed1-airflow_db-1	exited	Exited (0) 3 days ago
ws_plataforma_atendimento_codex-backend-1	created	Created
airbyte-abctl-control-plane	running	Up 38 minutes
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

O que a versão anterior desta seção listava por falta de memória — as trocas das retomadas, as
retomadas religando de verdade, `airbyte-up` e `airbyte-resume` pelo ramo pausado depois da
reestruturação, o Docker que não responde, o estado `paused` e o alvo de pé pela metade — foi
exercitado depois, com a memória liberada: §10. O que continua sem verificação:

- **Uma retomada recusada por memória, de verdade.** Havia memória em todas as do exercício; a
  recusa só rodou com o preflight simulado.
- **`ESTADO_AIRBYTE` com o nó do Airbyte em `paused` ou `restarting`.** O estado `paused` foi
  observado num contêiner descartável (§10.2); o nó do `kind` não foi congelado.
- **O Docker que trava em vez de recusar.** O que rodou foi o cliente sem daemon (`DOCKER_HOST` num
  soquete inexistente), que falha na hora; um daemon que responde devagar não foi provocado.
- **`stream-up` depois da D55.** Rodou antes dela (§10.5); a linha nova é a mesma `GARANTIR_REDE`
  que `up` e `airflow-up` exercitaram depois dela (§10.8).
- **`make reset` com a rede externa, e um clone com outro `COMPOSE_PROJECT_NAME`.** `reset` apaga
  os volumes e não entra em exercício; o nome da rede por projeto foi provado com o nome simulado
  (`test_projeto_diz_o_nome_que_o_compose_usa`), não num clone.
- **A troca antes de uma subida que só falha depois** continua possível, e é anterior a esta entrega:
  `airbyte-up` sem cluster pausa o *streaming* e chama o `abctl`, que pode abortar — o `PG_VERSION`
  da Execução Local §6 —, e o *streaming* fica pausado.
- **O acréscimo de uma sincronização sobre o Airbyte ocioso** continua sem conferência — é o custo
  aceito da D53. Não sincronizei para medir.
- **O `/health` como sinal de pronto não acusa o banco interno vazio** da Execução Local §6: nesse
  estado ele responde, e `airbyte-up` com o cluster de pé diz "pronta" onde antes esbarrava no
  `PG_VERSION`. Não reproduzido.
- **`retomar` confere que os contêineres estão de pé, não que estão saudáveis**, e `stream-resume`
  diz que o conector "volta do ponto em que parou" antes de ele voltar — no exercício, o *slot*
  ficou ativo aos ~40 s (§10.5). É anterior a esta entrega.
- **O exemplo de saída da Execução Local §5** continua com a mensagem antiga ("não convive com
  'streaming'"), e a lista "Já de pé" junta os nomes com `;` sem espaço — cosmético, anterior. A
  atualização da §5 é de B6 (plano, §8, item 2).
- **O `verificar.py` da skill de ADR acusava dois contadores — e já acusava em `c10a30c`**: contava
  as pendentes pelo `**Dnn**` em negrito da §3 do Registro de Decisões, onde a D43 não está em
  negrito, e não reconhecia o formato `1 (D43, …)` do cabeçalho das Pendências. **Corrigido depois,
  fora do intervalo desta rodada** (`bb783f4`, a pedido do Owner): é ferramenta de coerência dos
  documentos, escopo de B3, que fica para a revisão final.
- O que os dossiês anteriores listavam como de B5 continua de B5.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **O `MemAvailable` já desconta o que o alvo de pé ocupa** — é o que justifica não cobrá-lo de novo.
  Vale para o consumo de agora; o acréscimo até o pico, numa sincronização, é o custo aceito da D53.
- **"Inteiro de pé" é cada serviço do grupo com um contêiner `running`**, pelos grupos de
  `conteineres.sh` (`airflow_init` fica de fora de propósito). Um serviço novo no grupo entra
  sozinho.
- **`docker ps -a --format '{{.State}}'` devolve o estado em minúsculas** — `running`, `exited`,
  `created` e `paused` observados no Docker 29.7.2 desta máquina (§3, §10.2) — e sai diferente de 0
  quando o daemon não responde: provocado com o cliente sem daemon (§10.1); um daemon que trava, não.
- **`docker start` num contêiner de pé sai 0 sem reiniciá-lo** — medido (§3), no mesmo Docker.
- **O `FORCE` chega ao preflight dos `*-resume` como chega ao dos `*-up`** — é a mesma macro.
  `recovery-restore` passa `FORCE=` vazio a `medir` e a `airbyte-up`, e não chama nenhum `*-resume`.
- **O `abctl local install` sobre o cluster de pé aborta no `PG_VERSION`** enquanto o `pgdata`
  pertencer ao `uid 70` com modo `0700` — registrado em 05/09/2026 (Execução Local §6, com o cluster
  inteiro depois de reiniciar a máquina) e em 23/09/2026. A de 20/09 (`13f0065`) não registra o
  estado do cluster e não é contada. A D53 deixa de chamá-lo nesse caso; se a permissão mudar,
  reaplicar o chart pelo `abctl` pode voltar a funcionar — e não existe alvo para isso.
- **O Compose não remove rede `external`** — medido no projeto: `make down` manteve
  `mvp_ed1_default` com o mesmo ID (§10.8) —, **e não recria contêiner de pé só porque a declaração
  da rede mudou para externa** — medido: `make up` sobre os bancos de pé disse `Running`.
- **O nome da rede é `<projeto>_default`, e o projeto é o que `conteineres.sh projeto` diz** —
  ambiente, `.env` ou `mvp_ed1`, a mesma regra que o Compose segue com `--env-file .env`: as três
  composições resolvem para `mvp_ed1_default` em `docker compose config`. A do Airflow não declara
  `name:` no topo e depende do `.env`, que o `make env` sempre preenche.
- **A pausa do Airbyte mata o nó aos 10 s, e o Postgres interno se recupera da queda** — o SIGKILL
  (137) foi observado; a recuperação, inferida de a API voltar e o contador de *jobs* continuar o
  mesmo em cada retomada, sem olhar o log do Postgres interno.
- As premissas dos dossiês anteriores sobre o GNU Make 4.3 (detecção textual de `$(MAKE)`) e o
  `mawk` continuam valendo.

## 6. Ambiente que a revisão precisa

O que precisa estar de pé para as sondas, e como pôr de pé. **Subir é permitido;
alterar dado não.** A regra "deixar o ambiente como o encontrou" vale para o conteúdo
dos bancos e dos volumes — não para contêiner parado ou ausente, que o revisor sobe.

| Precisa de | Como subir | Como conferir |
|---|---|---|
| Os três bancos (`source_db`, `legacy_db`, `warehouse_db`) | `make up` — recria os contêineres sobre os volumes existentes; nada é regerado | `make ps`; portas no `.env` |
| Airbyte, Airflow ou streaming | `make airbyte-up` · `make airflow-up` · `make stream-up` — a troca é automática: pausa o conflitante, retoma depois | `make preflight ALVO=…` responde sem efeito |

Contêiner que não aparece em `docker ps -a` não está em outro contexto Docker: foi
derrubado por `make down`, que preserva os volumes. `make up` o traz de volta.

**Nunca** na revisão: `make reset`, `seed-*` ou `*-down` com `FORCE=1`, ou qualquer alvo que
reescreva dado — isso é execução, não revisão. Se o ambiente não puder ser preparado, a
indisponibilidade entra nos achados e o que dependia dela fica **não medido** — nunca inferido.

**O estado em que a entrega foi deixada:**

- **os três bancos de pé**, recriados por `make down` e `make up` no exercício da D55, sobre os
  mesmos volumes — `make recovery-verify CONTRA_O_BANCO=1` confere o candidato contra eles (§10.8);
- **Airbyte de pé e ocioso**, contador de *jobs* em 43 (`docker/airbyte_jobs.sh ler`, só leitura);
- **Airflow pausado**, com contêineres novos na rede de agora — os anteriores estavam presos à rede
  de antes de 21/09 (§10.3) —, histórico da DAG preservado no volume; **streaming ausente**, sem
  volume de tópicos e sem *slot* de replicação — o exercício criou os três e os removeu;
- **a rede `mvp_ed1_default`, externa**, com o mesmo ID desde 21/09 (`23dec8900a25`);
- **memória:** ~5,5 GB livres com o Airbyte de pé, quando o exercício terminou — cabe uma retomada
  ou uma troca; **não force** se o preflight recusar: `FORCE=1` é autorização do Owner (`CLAUDE.md`
  §5), e o que depender disso fica não medido;
- as sondas das quatro decisões não precisam de nada de pé: `tests/test_preflight.py` usa um
  *namespace* com `/proc/meminfo` trocado, e `tests/test_makefile.py`, um rascunho com executáveis
  simulados. Consultas reais sem efeito: `make preflight ALVO=…`, `docker/preflight.sh <alvo>` sem
  `--trocar`, e `DOCKER_HOST=unix:///tmp/nao-existe.sock make <alvo>`, que recusa antes de tocar em
  qualquer coisa;
- as sondas do RVE3 (dossiê anterior, §10–§11) rodam contra este código; a do prazo esgotado real
  usa uma porta local e não toca no Airbyte.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **A recomendação da D54 mudou antes da pergunta.** O registro de 23/09 recomendava só apontar a
  mensagem para os `*-up`; recomendei o preflight nos `*-resume` porque `FORCE=1` já é o caminho sem
  conferência em todo alvo da macro, e a guarda no alvo não depende de quem lê a mensagem. O Owner
  escolheu esta.
- **As conferências antes do preflight** — há o que retomar, o estado do nó, o `curl` — custam uma
  linha de receita a mais em cada alvo e, em `airbyte-up`, uma segunda leitura do estado, porque
  cada linha de receita é outro *shell*. A alternativa, trocar primeiro e falhar depois, deixava o
  outro ambiente pausado à toa, contra o "pausa que não resolve é desfeita".
- **De pé pela metade é cobrado inteiro.** Descontar o que já está no ar pediria custo por serviço,
  que não foi medido — o do Airflow é derivado. Cobrar inteiro repete a conta dupla antiga só nesse
  caso, pelo lado conservador.
- **Com o alvo de pé, não há conta de memória depois de pausar a outra família.** A pausa só devolve
  memória e o alvo não acrescenta nada; recusar ali seria religar a outra família ao lado do alvo,
  que é o R11.
- **Estado estranho do nó recusa**, em vez de cair no `abctl local install` como antes: o `abctl`
  recusaria o contêiner de qualquer jeito, e a mensagem nova diz qual é o estado.
- **`AGUARDAR_API_AIRBYTE` separado de `RETOMAR_AIRBYTE`**, em vez de usar a retomada também com o
  cluster de pé — o `docker start` seria inócuo (§3): o ramo de pé não chama `docker start`, e o
  registro das chamadas diz o que aconteceu.
- **Os *commits* da D53 são dois** — o preflight (`5f5efc5`) e `airbyte-up` (`4c3410f`)
  —, e o da D54 (`93c849c`) vem depois: o `Makefile` e o `tests/test_makefile.py` intermediários
  foram montados à mão para cada *commit* ter a sua suíte passando (§3, "28 passed").
- **Consertei o ambiente do Airflow à mão para seguir o exercício.** `make airflow-up` não recriava o
  `airflow_db` preso à rede antiga; removi só esse contêiner (`docker rm`, o volume ficou) e rodei
  `make airflow-up` de novo (§10.4). A alternativa pelo `Makefile` era `make airflow-down`, que
  remove os cinco; preferi o menor passo, e ele está escrito na Execução Local §6.
- **O nome da rede ficou `<projeto>_default`**, e não `<projeto>_rede`, como a pergunta da D55
  dizia: é o nome que o Compose já dava, e mantê-lo evitou recriar os contêineres de pé e os
  pausados; e identificador técnico é em inglês (`CLAUDE.md` §2). O custo é o nome parecer do Compose.
- **Nenhum alvo remove a rede, nem `make reset`.** Ela não guarda estado, e removê-la é exatamente o
  que prendia os pausados. Uma máquina "limpa" fica com uma rede vazia a mais.
- **A D56 foi medida antes de ser perguntada:** uma parada com `docker stop -t 180` fora do
  `Makefile`, e a retomada pelo alvo guardado. Na pergunta, eu disse "três retomadas hoje"; uma das
  três veio depois dessa parada limpa, e não de uma pausa com SIGKILL — as depois do SIGKILL foram
  duas, como a Execução Local registra.
- **O dossiê foi regerado com `--forcar`** sobre os achados RVE3, que estão respondidos e carregados
  na §8.

## 8. A terceira rodada — achados e respostas, para conferir

A terceira rodada deixou dois achados, RVE3-01 (bloqueante) e RVE3-02 (ajuste), aplicados em
23/09/2026, cada um reproduzido antes de corrigido; a verificação do que a aplicação deixou aberto
veio no mesmo dia, com a memória liberada pelo Owner. As respostas estão abaixo como ficaram no
dossiê anterior — as §10 e §11 citadas nelas são daquele dossiê, `git show c10a30c:REVISAO.md`,
com o código das sondas. Os *commits* da resposta, com a origem de cada um:

| Origem | *Commit* | O quê |
|---|---|---|
| RVE3-01 | `4921289` | o medidor converte a memória sob o locale C, e não sob o da máquina |
| RVE3-02 | `d3a20df` | a retomada do Airbyte espera a API responder, e prazo esgotado é erro |
| achado próprio, no RVE3-02 | `c58a3cd` | sem `curl`, a retomada do Airbyte recusa antes de religar o cluster |
| achado próprio, no RVE3-02 | `9d856df` | o prazo esgotado é dito em consultas, não em minutos |
| achado próprio, no RVE3-02 | `6cf0118` | o dublê da API não afirma o código de saída que não foi medido |
| verificação da §10.4 | `5851d41` | o prazo esgotado diz o tempo que contou, não uma cadência |

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVE3-01 | `docker/medir.sh:61–72` | **A conversão da memória ainda depende do locale e subestima leituras válidas.** Com `LC_ALL=pt_BR.UTF-8`, as entradas `1.5GiB` e `512.5MiB` resultam em **1.536 MB**, contra **2.048 MB** sob `C`, com código 0 e nenhuma falha. O `awk` da coleta interpreta o ponto conforme a localidade; o `LC_ALL=C` acrescentado à agregação não recupera a fração perdida antes. Isso impede usar o medidor como evidência de capacidade de B5 nesse ambiente (P5). Fixar a localidade numérica da conversão e testar a mesma entrada decimal sob `C` e `pt_BR.UTF-8`; conferir a necessidade de remedir registros anteriores, sem estimar números. **E3-4.** | `bloqueante` | **Corrigido** (`4921289`). Todo `awk` do medidor roda sob `LC_ALL=C` — leitura, soma e agregação —, e `_gb` põe a vírgula da tabela à mão, como o período já fazia. Sonda E3-4 repetida: 2.048 MB sob C, C.UTF-8 e pt_BR.UTF-8, com a mesma linha nos três. Contra o Docker real, sob pt_BR: 3.879 MB, entre leituras diretas de 3.878 e 3.882 MB somadas sob C. A mesma leitura real, somada sob pt_BR, perdia 733 MB (3.271 contra 4.004). **Achado próprio:** a linha da tabela também mudava de forma com o locale (`2.2 GB` sob C), e por isso o teste do RVE2-02 que recusava `0.0 GB` era vazio sob pt_BR; ele passa a recusar `0,0 GB`. Registros anteriores: há um só, o `size-report` de 20/09, com 3.961 MB, citado no plano §3. Ele saiu sob pt_BR e ficou marcado no plano como subestimado, sem estimativa de correção, porque a série bruta não existe. Nada o consome, e a Capacidade é medida em B5. Testes: `test_toda_conta_do_medidor_roda_sob_o_locale_c` (a regra, lida do texto) e `test_a_conversao_da_memoria_nao_depende_do_locale[C, pt_BR]` (o efeito, com a entrada do revisor). Os três reprovam o medidor anterior. §10.1. **Verificado depois (§11.5):** com o `busybox awk` no lugar do `mawk`, o medidor novo dá o mesmo número e a mesma linha; o `gawk` não está instalado. |
| RVE3-02 | `Makefile:277–280` (`RETOMAR_AIRBYTE`) | **A espera da retomada anuncia sucesso sem observar prontidão.** `grep -q Ready` aceita uma linha `NotReady` e imprime `pronto`; se nenhuma linha casar nas 30 tentativas, o último `echo` também devolve 0. As duas formas afetam `airbyte-resume` e o ramo de retomada de `airbyte-up`, permitindo que chamadores prossigam mesmo sem a condição que o alvo promete esperar. Reconhecer o estado `Ready` de forma exata e sair com erro ao esgotar o prazo; cobrir `NotReady`, consulta sem resposta útil e timeout nos dois chamadores. Preservar a correção de `make -n`. **E3-5.** | `ajuste` | **Corrigido** (`d3a20df`, `c58a3cd`, `9d856df`, `5851d41`). Por decisão do Owner, pronto é `GET /api/v1/health` responder `available:true`, que é o que os passos seguintes usam. Medido em duas pausas reais, autorizadas: a espera antiga disse "pronto" em 5,6 s, com 34 sandboxes `NotReady` e nenhum pronto, e a API respondeu em 101 s e em 96 s. Nem o sandbox exato (pronto em ~5 s) nem a prontidão do Kubernetes (8/8 aos 5 s, estado de antes da pausa) serviriam. O prazo é de 60 consultas a cada 5 s, três vezes o medido; esgotado, sai com erro nos dois chamadores, e `airbyte-up` não anuncia a interface. Numa retomada real, a receita nova disse "pronta" em 95,7 s, junto com a API. O `airbyte-up` real foi recusado pelo preflight por memória, e não foi forçado. Sonda E3-5 repetida: os quatro casos saem 2. **Achado próprio:** sem `curl`, o `2>/dev/null` engoliria o "command not found", e a espera venceria dizendo que a API não respondeu; a receita passa a conferir o `curl` antes de religar (`c58a3cd`). O "~20 s" que a Execução Local dava para a volta tinha saído da espera defeituosa, e foi trocado pelo medido. `make -n` continua sem executar nada, e agora vigia também o `curl`. Testes: dez da retomada (os dois chamadores × pronta na primeira; pronta depois de ficar sem resposta e de 503; sem resposta; 503; `available:false`) e o do `curl` ausente, todos reprovando a receita anterior. §10.2. **Verificado depois (§11):** `airbyte-up` real, com o preflight aprovando, disse "pronta" em 75,9 s, e os dois passos seguintes do passo 8 acharam banco e API de pé; o prazo esgotou de verdade em 301 s e, no pior caso, 602 s — e a mensagem passou a dizer o tempo contado (`5851d41`). |

Depois da resposta, `ESTADO_AIRBYTE`, `CURL_DA_ESPERA` e `AGUARDAR_API_AIRBYTE` substituíram parte
de `RETOMAR_AIRBYTE` (D53, §9): a espera do RVE3-02 é a mesma, e o `curl` passou a ser conferido
antes do preflight, e não só antes de religar.

## 9. As decisões do Owner depois da terceira rodada — D53 a D56

A D53 e a D54 foram levantadas na verificação do RVE3-02 (dossiê anterior, §11.8); a D55 e a D56,
ao exercitá-las de verdade (§10). As quatro foram decididas pelo Owner em 24/09/2026, com as
alternativas na mesa, e implementadas nesta entrega. O registro — decisão, alternativas
descartadas e custo aceito — está em
Pendências §2 ([D53 e D54](docs/pendencias.md#d53-e-d54--decididas-e-implementadas-em-24092026),
[D55 e D56](docs/pendencias.md#d55-e-d56--decididas-em-24092026)); aqui fica o que
o revisor precisa para conferir.

| Decisão | *Commit* | O que conferir |
|---|---|---|
| D53 — o que já está de pé não é cobrado de novo | `5f5efc5` | `_inteiro_no_ar` e `ALVO_DE_PE` no preflight: o alvo inteiro de pé não é cobrado, e de pé pela metade é; a troca continua, e a pausa da outra família não é desfeita por memória |
| D53 — `airbyte-up` com o cluster de pé confere a API | `4c3410f` | `ESTADO_AIRBYTE` e os três ramos de `airbyte-up`; o Docker que não responde e o estado estranho recusam antes da troca, e o `curl` também |
| D54 — as retomadas passam pela troca do preflight | `93c849c` | os três `*-resume`: a existência antes, o preflight da própria família, `FORCE=1` como única saída; a regra lida do texto em `test_todo_alvo_que_liga_ambiente_pesado_passa_pelo_preflight` |
| o registro | `4b785d3` | Pendências §1 → §2 e contadores, Execução Local §4–§6, `CLAUDE.md` §5, README e plano |
| D55 — a rede do projeto é externa | `d1cfb27` | as três composições com `networks.default` externa e `<projeto>_default`; `GARANTIR_REDE` antes de todo `up`; `conteineres.sh projeto`; `make down` não a remove (§10.8) |
| D56 — a pausa do Airbyte continua em SIGKILL, documentada · o registro das duas | `dbdb52b` | nenhum código; Execução Local §5 (o custo da pausa, a rede) e §6 (a retomada que falha com `network … not found`), Pendências §2 e plano |

Perguntas que valem uma sonda: há alvo que liga ambiente pesado e escapa do padrão `LIGA_AMBIENTE`
do teste? Há `up` de composição que escapa de `SOBE_COMPOSICAO`, ou composição nova sem a rede
externa? O `FORCE` atravessa algum `*-resume` chamado por outro alvo? Existe caminho em que a troca
pausa a outra família e a receita falha depois, deixando-a pausada à toa?

## 10. Exercitado de verdade, com a memória liberada — 24/09/2026

A pedido do Owner, com a memória que havia no início — 5,4 GB livres com o Airbyte de pé, contra os
2,3–2,6 GB das medições da §3 —, contra a máquina e pelos alvos guardados, sem `FORCE` em nenhuma
subida. Estado de partida: os três
bancos e o Airbyte de pé, o Airflow parado com os cinco contêineres, o *streaming* ausente, nenhum
*slot* de replicação, a DAG com `schedule=None` e `catchup=False` (retomar o Airflow não dispara
nada). Saída literal; onde houve filtro na captura, ele está dito.

### 10.1 O Docker que não responde

O cliente real, apontado para um soquete que não existe — o daemon não é tocado:

```text
== DOCKER_HOST apontando para um soquete que não existe — o Docker real não responde
$ make airbyte-up
failed to connect to the docker API at unix:///tmp/nao-existe-153735.sock; check if the path is correct and if the daemon is running: dial unix /tmp/nao-existe-153735.sock: connect: no such file or directory
ERRO: o Docker não respondeu — sem saber o estado do cluster, nada foi tocado.
make: *** [Makefile:363: airbyte-up] Erro 1
saida=2
$ make airbyte-resume
failed to connect to the docker API at unix:///tmp/nao-existe-153735.sock; check if the path is correct and if the daemon is running: dial unix /tmp/nao-existe-153735.sock: connect: no such file or directory
ERRO: o Docker não respondeu — sem saber o estado do cluster, nada foi tocado.
make: *** [Makefile:326: airbyte-resume] Erro 1
saida=2
$ make stream-resume
ERRO: o Docker não respondeu — nada foi tocado.
make: *** [Makefile:336: stream-resume] Erro 1
saida=2
$ make airflow-resume
ERRO: o Docker não respondeu — nada foi tocado.
make: *** [Makefile:347: airflow-resume] Erro 1
saida=2
$ make preflight ALVO=airbyte

RECUSADO — não consegui enumerar os contêineres de 'Airbyte' (o Docker respondeu?).
  Sem saber o que está de pé, subir 'airbyte' é subir às cegas — que é o R11.
make: *** [Makefile:254: preflight] Erro 1
saida=2
== o estado real, depois
mvp_ed1_legacy_db	running
mvp_ed1_source_db	running
mvp_ed1_warehouse_db	running
mvp_ed1-airflow_scheduler-1	exited
mvp_ed1-airflow_apiserver-1	exited
mvp_ed1-airflow_dag_processor-1	exited
mvp_ed1-airflow_init-1	exited
mvp_ed1-airflow_db-1	exited
airbyte-abctl-control-plane	running
```

### 10.2 O estado `paused`

O único estado que `ESTADO_AIRBYTE` recusa e que ainda não tinha sido visto, num contêiner
descartável:

```text
rodando: running
depois de docker pause: paused
depois de docker unpause: running
sonda removida
```

### 10.3 `airflow-resume` de verdade — e o que ele achou

O preflight aprovou, e nenhum dos quatro religou — a guarda denunciou, com saída 1, e nada foi
pausado:

```text
antes: MemAvailable:    5603916 kB
$ make airflow-resume
[preflight] RAM disponível agora: 5,3 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 4,0 GB
[preflight] OK
ATENÇÃO: Airflow NÃO voltou por inteiro — 4 de 4 continuam parados:
  mvp_ed1-airflow_apiserver-1
  mvp_ed1-airflow_dag_processor-1
  mvp_ed1-airflow_db-1
  mvp_ed1-airflow_scheduler-1
make: *** [Makefile:349: airflow-resume] Erro 1

real	0m1,328s
user	0m0,291s
sys	0m0,286s
saida=2
depois: MemAvailable:    5574148 kB
mvp_ed1-airflow_scheduler-1	exited	Exited (1) 3 days ago
mvp_ed1-airflow_apiserver-1	exited	Exited (128) 3 days ago
mvp_ed1-airflow_dag_processor-1	exited	Exited (1) 3 days ago
mvp_ed1-airflow_init-1	exited	Exited (0) 3 days ago
mvp_ed1-airflow_db-1	exited	Exited (128) 3 days ago
```

O erro que o Docker guardou em cada contêiner, e as redes:

```text
$ docker inspect -f 'erro={{.State.Error}} | saida={{.State.ExitCode}} | fim={{.State.FinishedAt}}' <contêiner>
mvp_ed1-airflow_db-1: erro=failed to set up container networking: network ca8efc33b24f288fc2a92492781787fe284474abd8ca464d8d21c3177054c7c0 not found | saida=128 | fim=2026-09-20T22:36:31.691966983Z
mvp_ed1-airflow_apiserver-1: erro=failed to set up container networking: network ca8efc33b24f288fc2a92492781787fe284474abd8ca464d8d21c3177054c7c0 not found | saida=128 | fim=2026-09-20T22:36:33.195578612Z
mvp_ed1-airflow_scheduler-1: erro=failed to set up container networking: network ca8efc33b24f288fc2a92492781787fe284474abd8ca464d8d21c3177054c7c0 not found | saida=1 | fim=2026-09-20T22:36:32.867772523Z
mvp_ed1-airflow_dag_processor-1: erro=failed to set up container networking: network ca8efc33b24f288fc2a92492781787fe284474abd8ca464d8d21c3177054c7c0 not found | saida=1 | fim=2026-09-20T22:36:32.32822633Z
$ docker network ls   # só a do projeto
23dec8900a25	mvp_ed1_default	2026-09-21 15:46:16.517097089 -0300 -03
$ docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{$v.NetworkID}}{{end}}' mvp_ed1-airflow_db-1 mvp_ed1_source_db
mvp_ed1_default ca8efc33b24f288fc2a92492781787fe284474abd8ca464d8d21c3177054c7c0
mvp_ed1_default 23dec8900a2580dd8d3a95e34b5f307ac7c36a32dbc4be6dd62f17c0e2463a4f
```

Os contêineres do Airflow apontam para a rede `ca8efc33…`, que não existe mais; a `mvp_ed1_default`
de agora nasceu em 21/09 às 15h46 — o dia em que a revisão encontrou os bancos derrubados por
`make down`. Desde então, nenhuma retomada do Airflow religaria nada, antes ou depois da D54. É a
D55.

### 10.4 O conserto do ambiente, e o Airflow pela metade

`make airflow-up` recriou quatro contêineres — porque o `--build` gera imagem nova —, e não o
`airflow_db`, cuja configuração não mudou (filtradas, na captura, só as linhas do preflight, dos
contêineres e do erro):

```text
antes: MemAvailable:    5569936 kB
$ make airflow-up
[preflight] RAM disponível agora: 5,3 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 4,0 GB
[preflight] OK
 Container mvp_ed1-airflow_init-1 Recreate 
 Container mvp_ed1-airflow_init-1 Recreated 
 Container mvp_ed1-airflow_scheduler-1 Recreate 
 Container mvp_ed1-airflow_apiserver-1 Recreate 
 Container mvp_ed1-airflow_dag_processor-1 Recreate 
 Container mvp_ed1-airflow_dag_processor-1 Recreated 
 Container mvp_ed1-airflow_scheduler-1 Recreated 
 Container mvp_ed1-airflow_apiserver-1 Recreated 
 Container mvp_ed1-airflow_db-1 Starting 
Error response from daemon: failed to set up container networking: network ca8efc33b24f288fc2a92492781787fe284474abd8ca464d8d21c3177054c7c0 not found
make: *** [Makefile:424: airflow-up] Erro 1
saida=2
depois: MemAvailable:    5631668 kB
mvp_ed1-airflow_apiserver-1	created	Created
mvp_ed1-airflow_dag_processor-1	created	Created
mvp_ed1-airflow_scheduler-1	created	Created
mvp_ed1-airflow_init-1	created	Created
mvp_ed1-airflow_db-1	exited	Exited (128) 3 days ago
```

Os dados do banco do Airflow ficam no volume `mvp_ed1_airflow_db_data`, de 04/09. Removido só o
contêiner preso, `make airflow-up` subiu tudo (na captura, só as linhas do preflight, de contêiner e
de erro):

```text
$ docker rm mvp_ed1-airflow_db-1   # o contêiner preso à rede de antes de 21/09; o volume fica
mvp_ed1-airflow_db-1
saida=0
antes: MemAvailable:    5604984 kB
$ make airflow-up
[preflight] RAM disponível agora: 5,3 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 4,0 GB
[preflight] OK
 Container mvp_ed1-airflow_db-1 Creating 
 Container mvp_ed1-airflow_db-1 Created 
 Container mvp_ed1-airflow_init-1 Recreate 
 Container mvp_ed1-airflow_init-1 Recreated 
 Container mvp_ed1-airflow_dag_processor-1 Recreate 
 Container mvp_ed1-airflow_apiserver-1 Recreate 
 Container mvp_ed1-airflow_scheduler-1 Recreate 
 Container mvp_ed1-airflow_apiserver-1 Recreated 
 Container mvp_ed1-airflow_scheduler-1 Recreated 
 Container mvp_ed1-airflow_dag_processor-1 Recreated 
 Container mvp_ed1-airflow_db-1 Starting 
 Container mvp_ed1-airflow_db-1 Started 
 Container mvp_ed1-airflow_db-1 Waiting 
 Container mvp_ed1-airflow_db-1 Healthy 
 Container mvp_ed1-airflow_init-1 Starting 
 Container mvp_ed1-airflow_init-1 Started 
 Container mvp_ed1-airflow_init-1 Waiting 
 Container mvp_ed1-airflow_db-1 Waiting 
 Container mvp_ed1-airflow_db-1 Waiting 
 Container mvp_ed1-airflow_init-1 Waiting 
 Container mvp_ed1-airflow_init-1 Waiting 
 Container mvp_ed1-airflow_db-1 Waiting 
 Container mvp_ed1-airflow_db-1 Healthy 
 Container mvp_ed1-airflow_db-1 Healthy 
 Container mvp_ed1-airflow_db-1 Healthy 
 Container mvp_ed1-airflow_init-1 Exited 
 Container mvp_ed1-airflow_init-1 Exited 
 Container mvp_ed1-airflow_dag_processor-1 Starting 
 Container mvp_ed1-airflow_scheduler-1 Starting 
 Container mvp_ed1-airflow_init-1 Exited 
 Container mvp_ed1-airflow_apiserver-1 Starting 
 Container mvp_ed1-airflow_apiserver-1 Started 
 Container mvp_ed1-airflow_dag_processor-1 Started 
 Container mvp_ed1-airflow_scheduler-1 Started 
 Container mvp_ed1-airflow_dag_processor-1 Waiting 
 Container mvp_ed1-airflow_db-1 Waiting 
 Container mvp_ed1-airflow_init-1 Waiting 
 Container mvp_ed1-airflow_apiserver-1 Waiting 
 Container mvp_ed1-airflow_scheduler-1 Waiting 
 Container mvp_ed1-airflow_scheduler-1 Healthy 
 Container mvp_ed1-airflow_init-1 Exited 
 Container mvp_ed1-airflow_apiserver-1 Healthy 
 Container mvp_ed1-airflow_db-1 Healthy 
 Container mvp_ed1-airflow_dag_processor-1 Healthy 
Airflow em http://localhost:8081 — admin / admin.
real	0m24,896s
saida=0
depois: MemAvailable:    5291788 kB
mvp_ed1-airflow_scheduler-1	running	Up Less than a second
mvp_ed1-airflow_dag_processor-1	running	Up Less than a second
mvp_ed1-airflow_apiserver-1	running	Up Less than a second
mvp_ed1-airflow_init-1	exited	Exited (0) 1 second ago
mvp_ed1-airflow_db-1	running	Up 21 seconds (healthy)
```

O histórico da DAG sobreviveu. E a D53 no Airflow, de verdade: inteiro de pé, "nada a cobrar"; três
de quatro, cobrado inteiro:

```text
$ execuções registradas da DAG (só leitura)
dag_id       run_id                                    state    run_after                         logical_date    start_date                        end_date
fluxo_batch  manual__2026-09-20T19:59:58.032670+00:00  failed   2026-09-20T19:59:58.032670+00:00                  2026-09-20T20:00:37.227160+00:00  2026-09-20T20:00:51.038532+00:00
fluxo_batch  manual__2026-09-18T06:34:00.867703+00:00  success  2026-09-18T06:34:00.867703+00:00                  2026-09-18T06:34:01.786341+00:00  2026-09-18T06:42:00.917046+00:00
fluxo_batch  manual__2026-09-15T05:12:22.688282+00:00  success  2026-09-15T05:12:22.688282+00:00                  2026-09-15T05:12:22.972497+00:00  2026-09-15T05:25:22.945412+00:00
fluxo_batch  manual__2026-09-06T18:26:03.721841+00:00  success  2026-09-06T18:26:03.721841+00:00                  2026-09-06T18:26:04.566344+00:00  2026-09-06T18:31:25.264668+00:00
$ make preflight ALVO=airflow   # os quatro de pé
[preflight] RAM disponível agora: 4,8 GB
[preflight] Já de pé: Airbyte (cluster kind);Airflow
[preflight] 'airflow' já está de pé — nada a cobrar
[preflight] OK
saida=0
$ docker stop mvp_ed1-airflow_apiserver-1   # de pé pela metade
saida=0
$ make preflight ALVO=airflow   # três de quatro
[preflight] RAM disponível agora: 4,9 GB
[preflight] Já de pé: Airbyte (cluster kind);Airflow
[preflight] 'airflow' custa ~1,4 GB — sobraria 3,5 GB
[preflight] OK
saida=0
```

`airflow-resume` a partir do estado pela metade:

```text
$ make airflow-resume   # apiserver parado, os outros três de pé
[preflight] RAM disponível agora: 4,8 GB
[preflight] Já de pé: Airbyte (cluster kind);Airflow
[preflight] 'airflow' custa ~1,4 GB — sobraria 3,5 GB
[preflight] OK
Airflow retomado — 4 contêineres de pé.

real	0m0,998s
user	0m0,312s
sys	0m0,301s
saida=0
mvp_ed1-airflow_scheduler-1	running	Up 34 seconds
mvp_ed1-airflow_dag_processor-1	running	Up 34 seconds
mvp_ed1-airflow_apiserver-1	running	Up Less than a second
mvp_ed1-airflow_init-1	exited	Exited (0) 34 seconds ago
mvp_ed1-airflow_db-1	running	Up 55 seconds (healthy)
```

### 10.5 As trocas, de verdade

`make stream-up` com o Airbyte e o Airflow de pé — a troca pausa os dois. Saída completa: o filtro da
captura, que tiraria as linhas `Waiting` e `Healthy` do Compose, não casou, porque elas terminam
com espaço:

```text
antes: MemAvailable:    4874900 kB
$ make stream-up   # Airbyte e Airflow de pé e ociosos
[preflight] RAM disponível agora: 4,6 GB
[preflight] Já de pé: Airbyte (cluster kind);Airflow
[preflight] 'streaming' custa ~0,5 GB — sobraria 4,2 GB
[preflight] Airbyte está de pé e ocioso — pausando.
[preflight] Airbyte pausado — retomar com make airbyte-resume
[preflight] Airflow está de pé e ocioso — pausando.
[preflight] Airflow pausado — retomar com make airflow-resume
[preflight] RAM disponível agora: 8,7 GB — sobraria 8,2 GB
[preflight] OK
 Volume mvp_ed1_redpanda_data Creating 
 Volume mvp_ed1_redpanda_data Creating 
 Volume mvp_ed1_redpanda_data Created 
 Volume mvp_ed1_redpanda_data Created 
 Container mvp_ed1_redpanda Creating 
 Container mvp_ed1_redpanda Created 
 Container mvp_ed1_kafka_connect Creating 
 Container mvp_ed1_kafka_connect Created 
 Container mvp_ed1_redpanda Starting 
 Container mvp_ed1_redpanda Started 
 Container mvp_ed1_redpanda Waiting 
 Container mvp_ed1_redpanda Healthy 
 Container mvp_ed1_kafka_connect Starting 
 Container mvp_ed1_kafka_connect Started 
 Container mvp_ed1_redpanda Waiting 
 Container mvp_ed1_kafka_connect Waiting 
 Container mvp_ed1_redpanda Healthy 
 Container mvp_ed1_kafka_connect Healthy 
conector 'inventory-movements' aplicado a partir de inventory_movements.yml

Transporte em localhost:19092; Connect em http://localhost:8083.
O pipeline é processo em primeiro plano: 'make stream-run'.

real	1m4,021s
user	0m0,651s
sys	0m0,445s
saida=0
depois: MemAvailable:    8410608 kB
mvp_ed1_kafka_connect	running	Up 31 seconds (healthy)
mvp_ed1_redpanda	running	Up 37 seconds (healthy)
mvp_ed1-airflow_scheduler-1	exited	Exited (1) 40 seconds ago
mvp_ed1-airflow_dag_processor-1	exited	Exited (1) 41 seconds ago
mvp_ed1-airflow_apiserver-1	exited	Exited (0) 40 seconds ago
mvp_ed1-airflow_init-1	exited	Exited (0) About a minute ago
airbyte-abctl-control-plane	exited	Exited (137) 42 seconds ago
```

`make airbyte-resume` com o *streaming* de pé — D54: pausa o *streaming*, confere a memória, espera
a API:

```text
slot criado pelo conector: mvp_inventory_movements ativo=true
antes: MemAvailable:    8373596 kB
$ make airbyte-resume   # streaming de pé, Airbyte pausado
[preflight] RAM disponível agora: 8,0 GB
[preflight] Já de pé: streaming (Redpanda + Kafka Connect)
[preflight] 'airbyte' custa ~4,9 GB — sobraria 3,1 GB
[preflight] streaming está de pé e ocioso — pausando.
[preflight] streaming pausado — retomar com make stream-resume
[preflight] RAM disponível agora: 8,7 GB — sobraria 3,9 GB
[preflight] OK
aguardando a API do Airbyte............... pronta.

real	1m28,263s
user	0m0,294s
sys	0m0,338s
saida=0
depois: MemAvailable:    5996560 kB
mvp_ed1_kafka_connect	exited	Exited (137) About a minute ago
mvp_ed1_redpanda	exited	Exited (0) About a minute ago
airbyte-abctl-control-plane	running	Up About a minute
```

`make stream-resume` com o Airbyte de pé — D54 no outro sentido —, e o conector voltando ao mesmo
*slot*:

```text
antes: MemAvailable:    5894256 kB
$ make stream-resume   # Airbyte de pé, streaming pausado
[preflight] RAM disponível agora: 5,6 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'streaming' custa ~0,5 GB — sobraria 5,1 GB
[preflight] Airbyte está de pé e ocioso — pausando.
[preflight] Airbyte pausado — retomar com make airbyte-resume
[preflight] RAM disponível agora: 8,7 GB — sobraria 8,2 GB
[preflight] OK
streaming retomado — 2 contêineres de pé.
O conector Debezium volta do ponto em que parou.

real	0m13,402s
user	0m0,277s
sys	0m0,299s
saida=0
depois: MemAvailable:    9073436 kB
mvp_ed1_kafka_connect	running	Up Less than a second (health: starting)
mvp_ed1_redpanda	running	Up Less than a second (health: starting)
airbyte-abctl-control-plane	exited	Exited (137) 2 seconds ago
conector, 20 s depois: 
mvp_ed1_kafka_connect	Up 30 seconds (health: starting)
mvp_ed1_redpanda	Up 30 seconds (healthy)
conector: {"name":"inventory-movements","connector":{"state":"RUNNING","worker_id":"172.22.0.6:8083","version":"3.6.2.Final"},"tasks":[{"id":0,"state":"RUNNING","worker_id":"172.22.0.6:8083","version":"3.6.2.Final"}],"type":"source"}
slot: mvp_inventory_movements ativo=false
slot ativo=t depois de mais 0 s; Connect: Up 40 seconds (healthy)
```

`make airflow-resume` com o *streaming* de pé:

```text
antes: MemAvailable:    8394152 kB
$ make airflow-resume   # streaming de pé, Airflow e Airbyte pausados
[preflight] RAM disponível agora: 8,0 GB
[preflight] Já de pé: streaming (Redpanda + Kafka Connect)
[preflight] 'airflow' custa ~1,4 GB — sobraria 6,6 GB
[preflight] streaming está de pé e ocioso — pausando.
[preflight] streaming pausado — retomar com make stream-resume
[preflight] RAM disponível agora: 8,7 GB — sobraria 7,3 GB
[preflight] OK
Airflow retomado — 4 contêineres de pé.

real	0m14,144s
user	0m0,380s
sys	0m0,379s
saida=0
depois: MemAvailable:    9062608 kB
mvp_ed1_kafka_connect	exited	Exited (137) 3 seconds ago
mvp_ed1_redpanda	exited	Exited (0) 13 seconds ago
mvp_ed1-airflow_scheduler-1	running	Up 1 second
mvp_ed1-airflow_dag_processor-1	running	Up Less than a second
mvp_ed1-airflow_apiserver-1	running	Up 1 second
mvp_ed1-airflow_init-1	exited	Exited (0) 5 minutes ago
mvp_ed1-airflow_db-1	running	Up Less than a second (health: starting)
airbyte-abctl-control-plane	exited	Exited (137) About a minute ago
depois de 0 s:
mvp_ed1-airflow_scheduler-1	running	Up 11 seconds
mvp_ed1-airflow_dag_processor-1	running	Up 11 seconds
mvp_ed1-airflow_apiserver-1	running	Up 11 seconds
mvp_ed1-airflow_init-1	exited	Exited (0) 5 minutes ago
mvp_ed1-airflow_db-1	running	Up 10 seconds (healthy)
```

`make airbyte-up` pelo ramo pausado, depois da reestruturação — com o Airflow de pé, que é da mesma
família:

```text
antes: MemAvailable:    8474204 kB
$ make airbyte-up   # Airbyte pausado, Airflow de pé, streaming pausado
[preflight] RAM disponível agora: 8,1 GB
[preflight] Já de pé: Airflow
[preflight] 'airbyte' custa ~4,9 GB — sobraria 3,2 GB
[preflight] OK
cluster pausado — retomando em vez de reinstalar
aguardando a API do Airbyte............. pronta.

Interface em http://localhost:8000 — credenciais em 'make airbyte-credentials'.

real	1m5,762s
user	0m0,208s
sys	0m0,247s
saida=0
depois: MemAvailable:    5578300 kB
mvp_ed1_kafka_connect	exited	Exited (137) About a minute ago
mvp_ed1_redpanda	exited	Exited (0) About a minute ago
mvp_ed1-airflow_scheduler-1	running	Up About a minute
mvp_ed1-airflow_dag_processor-1	running	Up About a minute
mvp_ed1-airflow_apiserver-1	running	Up About a minute
mvp_ed1-airflow_init-1	exited	Exited (0) 6 minutes ago
mvp_ed1-airflow_db-1	running	Up About a minute (healthy)
airbyte-abctl-control-plane	running	Up About a minute
```

O estado interno do Airbyte depois das trocas:

```text
$ docker/airbyte_jobs.sh ler   # só leitura
maior_job=43 ultimo_valor=43 chamado=t sequencia=public.jobs_id_seq
saida=0
```

### 10.6 A limpeza

O que o exercício criou — contêineres, volume de tópicos e *slot* — sai; a publicação, que já
existia, fica:

```text
$ make airflow-pause
Airflow pausado — 4 contêineres parados. Retomar: make airflow-resume
saida=0
$ make stream-down FORCE=1   # só o que o exercício criou: contêineres, volume de tópicos e slot
 Container mvp_ed1_kafka_connect Stopping 
 Container mvp_ed1_kafka_connect Stopped 
 Container mvp_ed1_kafka_connect Removing 
 Container mvp_ed1_kafka_connect Removed 
 Container mvp_ed1_redpanda Stopping 
 Container mvp_ed1_redpanda Stopped 
 Container mvp_ed1_redpanda Removing 
 Container mvp_ed1_redpanda Removed 
 Volume mvp_ed1_redpanda_data Removing 
 Network mvp_ed1_default Removing 
 Network mvp_ed1_default Resource is still in use 
 Volume mvp_ed1_redpanda_data Removed 
slot 'mvp_inventory_movements': removido e ausência conferida
saida=0
== estado final
mvp_ed1-airflow_scheduler-1	exited	Exited (1) 1 second ago
mvp_ed1-airflow_dag_processor-1	exited	Exited (1) 1 second ago
mvp_ed1-airflow_apiserver-1	exited	Exited (0) 1 second ago
mvp_ed1-airflow_init-1	exited	Exited (0) 6 minutes ago
mvp_ed1-airflow_db-1	exited	Exited (0) 2 seconds ago
mvp_ed1_legacy_db	running	Up 2 hours (healthy)
mvp_ed1_source_db	running	Up 2 hours (healthy)
mvp_ed1_warehouse_db	running	Up 2 hours (healthy)
airbyte-abctl-control-plane	running	Up About a minute
volumes do streaming: 0
slots: 0
publicação: mvp_inventory_movements
memória: MemAvailable:    5947032 kB
```

### 10.7 A pausa do Airbyte, medida — D56

Toda pausa acima terminou em 137 no nó do Airbyte e no Kafka Connect. A configuração de parada do
nó, e uma parada com prazo longo, fora do `Makefile`, seguida da retomada pelo alvo guardado:

```text
$ docker inspect -f '{{.Name}} StopSignal={{.Config.StopSignal}} StopTimeout={{.Config.StopTimeout}}' airbyte-abctl-control-plane
/airbyte-abctl-control-plane StopSignal=SIGRTMIN+3 StopTimeout=<nil>
```

```text
$ docker stop -t 180 airbyte-abctl-control-plane   # o mesmo sinal da pausa, com prazo longo
docker stop saiu 0 em 90.664622366 s
estado: exited ExitCode=130 OOMKilled=false
memória: MemAvailable:    9212476 kB
$ make airbyte-resume
[preflight] RAM disponível agora: 8,8 GB
[preflight] Já de pé: nada além dos bancos
[preflight] 'airbyte' custa ~4,9 GB — sobraria 3,9 GB
[preflight] OK
aguardando a API do Airbyte.............. pronta.

real	1m10,700s
user	0m0,199s
sys	0m0,248s
saida=0
$ docker/airbyte_jobs.sh ler
maior_job=43 ultimo_valor=43 chamado=t sequencia=public.jobs_id_seq
```

### 10.8 A D55 — a sonda e o projeto

O mecanismo, isolado, numa composição descartável com dois serviços no mesmo projeto: com a rede
gerida pelo Compose, o `down` de um remove a rede e o `docker start` do outro, pausado, falha com o
erro do Airflow; externa, o ID não muda e ele volta. A sonda:

```bash
servico() { printf 'name: sondarede
services:
  %s:
    image: redis:7.2-bookworm
    entrypoint: ["sleep", "600"]
' "$1"; }
externa() { printf 'networks:
  default:
    name: sondarede_default
    external: true
'; }
sobe() { docker compose -f "$1" up -d 2>&1 | grep -iE "error|network" ; }
rodada() {  # $1 = gerida|externa
  echo "== rede $1"
  [ "$1" = externa ] && docker network create sondarede_default >/dev/null
  sobe a.yml; sobe b.yml
  docker stop sondarede-b-1 >/dev/null; echo "b pausado; rede $(docker network inspect -f '{{.Id}}' sondarede_default | cut -c1-12)"
  docker compose -f a.yml down 2>&1 | grep -i network
  sobe a.yml; echo "a de volta; rede $(docker network inspect -f '{{.Id}}' sondarede_default | cut -c1-12)"
  docker start sondarede-b-1 >/dev/null 2>$D/erro; echo "docker start b: saída $? $(cat $D/erro)"
  docker compose -f b.yml down -v >/dev/null 2>&1; docker compose -f a.yml down -v >/dev/null 2>&1; docker rm -f sondarede-b-1 >/dev/null 2>&1
  [ "$1" = externa ] && docker network rm sondarede_default >/dev/null
  return 0
}
export COMPOSE_IGNORE_ORPHANS=true
servico a > a.yml; servico b > b.yml; rodada gerida
{ servico a; externa; } > a.yml; { servico b; externa; } > b.yml; rodada externa
echo "sobras: $(docker ps -a --format '{{.Names}}' | grep -c sondarede) contêineres, $(docker network ls --format '{{.Name}}' | grep -c sondarede) redes"
```

```text
== rede gerida
 Network sondarede_default Creating 
 Network sondarede_default Creating 
 Network sondarede_default Created 
 Network sondarede_default Created 
b pausado; rede 9c15e3d6a6e1
 Network sondarede_default Removing 
 Network sondarede_default Removed 
 Network sondarede_default Creating 
 Network sondarede_default Creating 
 Network sondarede_default Created 
 Network sondarede_default Created 
a de volta; rede 1f35fe4189bb
docker start b: saída 1 Error response from daemon: failed to set up container networking: network 9c15e3d6a6e1fe4e0b86af698e4482339c569788233657a813e0564e7ca9ebac not found
failed to start containers: sondarede-b-1
== rede externa
b pausado; rede 329b7fa8b5c9
a de volta; rede 329b7fa8b5c9
docker start b: saída 0 
sobras: 0 contêineres, 0 redes
```

No projeto, com o código de `d1cfb27`: `make up` sobre os bancos de pé, `make down`, `make up`, e o
Airflow pausado retomando depois — o cenário de 21/09. Na captura: as 12 primeiras linhas não vazias
do primeiro `make up`; do `make down`, as linhas de rede, de remoção e de erro; do segundo `make up`,
as de rede, de início, de saúde, de erro e de contêiner, até 12:

```text
rede antes: 23dec8900a25
$ make up   # bancos já de pé, rede já existente
docker compose --env-file .env -f docker/docker-compose.yml up -d --wait source_db legacy_db warehouse_db
 Container mvp_ed1_warehouse_db Running 
 Container mvp_ed1_source_db Running 
 Container mvp_ed1_legacy_db Running 
 Container mvp_ed1_legacy_db Waiting 
 Container mvp_ed1_warehouse_db Waiting 
 Container mvp_ed1_source_db Waiting 
 Container mvp_ed1_source_db Healthy 
 Container mvp_ed1_legacy_db Healthy 
 Container mvp_ed1_warehouse_db Healthy 
NAME                   STATUS                 PORTS
mvp_ed1_legacy_db      Up 2 hours (healthy)   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
saida=0; rede: 23dec8900a25
$ make down
 Container mvp_ed1_source_db Removed 
 Container mvp_ed1_legacy_db Removed 
 Container mvp_ed1_warehouse_db Removed 
saida=0; rede depois do down: 23dec8900a25
$ make up
 Container mvp_ed1_warehouse_db Creating 
 Container mvp_ed1_legacy_db Creating 
 Container mvp_ed1_source_db Creating 
 Container mvp_ed1_legacy_db Created 
 Container mvp_ed1_warehouse_db Created 
 Container mvp_ed1_source_db Created 
 Container mvp_ed1_source_db Starting 
 Container mvp_ed1_legacy_db Starting 
 Container mvp_ed1_warehouse_db Starting 
 Container mvp_ed1_warehouse_db Started 
 Container mvp_ed1_source_db Started 
 Container mvp_ed1_legacy_db Started 
saida=0; rede: 23dec8900a25
$ make airflow-resume   # os pausados do Airflow, depois do down/up
[preflight] RAM disponível agora: 5,5 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 4,2 GB
[preflight] OK
Airflow retomado — 4 contêineres de pé.

real	0m1,740s
user	0m0,304s
sys	0m0,292s
saida=0
mvp_ed1_warehouse_db	running	Up 7 seconds (healthy)
mvp_ed1_source_db	running	Up 7 seconds (healthy)
mvp_ed1_legacy_db	running	Up 7 seconds (healthy)
mvp_ed1-airflow_scheduler-1	running	Up 1 second
mvp_ed1-airflow_dag_processor-1	running	Up Less than a second
mvp_ed1-airflow_apiserver-1	running	Up 1 second
mvp_ed1-airflow_init-1	exited	Exited (0) 20 minutes ago
mvp_ed1-airflow_db-1	running	Up Less than a second (health: starting)
```

O Airflow pausado de novo, e o candidato do pacote contra os bancos recriados, só leitura:

```text
$ make airflow-pause
Airflow pausado — 4 contêineres parados. Retomar: make airflow-resume
saida=0
$ make recovery-verify CONTRA_O_BANCO=1   # só leitura
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_ed1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações como no manifesto)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.

real	0m12,548s
user	0m9,490s
sys	0m0,635s
saida=0
```

`make airflow-up` depois da D55 — o `airflow_db` sobe sem ser recriado. Na captura, as linhas do
preflight, do Compose e do erro foram contadas com `sort | uniq -c`, e o filtro das linhas de
contêiner não casou, pelo mesmo espaço do fim; as datas de criação, no fim, dizem o que foi recriado:

```text
antes: MemAvailable:    5686856 kB; rede 23dec8900a25
$ make airflow-up   # depois da D55, Airflow pausado
      1 Airflow em http://localhost:8081 — admin / admin.
      4  Image mvp_ed1/airflow:3.2.2 Built 
      1 [preflight] 'airflow' custa ~1,4 GB — sobraria 4,0 GB
      1 [preflight] Já de pé: Airbyte (cluster kind)
      1 [preflight] OK
      1 [preflight] RAM disponível agora: 5,4 GB
      1 real	0m24,581s
saida=0
mvp_ed1-airflow_dag_processor-1	running	Up Less than a second
mvp_ed1-airflow_apiserver-1	running	Up Less than a second
mvp_ed1-airflow_scheduler-1	running	Up Less than a second
mvp_ed1-airflow_init-1	exited	Exited (0) 1 second ago
mvp_ed1-airflow_db-1	running	Up 20 seconds (healthy)
$ make airflow-pause
Airflow pausado — 4 contêineres parados. Retomar: make airflow-resume
mvp_ed1-airflow_db-1 criado 2026-09-24T19:54:18Z
mvp_ed1-airflow_scheduler-1 criado 2026-09-24T20:19:35Z
mvp_ed1-airflow_apiserver-1 criado 2026-09-24T20:19:35Z
mvp_ed1-airflow_dag_processor-1 criado 2026-09-24T20:19:35Z
mvp_ed1-airflow_init-1 criado 2026-09-24T20:19:34Z
```

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

