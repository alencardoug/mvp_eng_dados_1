# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `2136781..4b785d3` — leia o diff, ele não é repetido aqui.

**Quarta rodada, mesmo escopo B0/B1/B4** (B2/B3 continuam para a revisão final, depois de B6,
por decisão do Owner). O intervalo começa onde o da terceira terminou (`2136781`) e traz duas
coisas: a resposta aos dois achados dela — RVE3-01 e RVE3-02, com a verificação do que a aplicação
deixou aberto — e as duas decisões que essa verificação levantou, **D53 e D54**, tomadas pelo Owner
em 24/09/2026 e implementadas aqui. O parecer da terceira rodada, as evidências E3-\* e as saídas
da aplicação e da verificação estão no dossiê anterior, `git show c10a30c:REVISAO.md` (§9–§11),
com o código das sondas. A §8 abaixo traz os dois achados com a resposta de cada um, e a §9, as
duas decisões — é o que esta rodada confere.

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
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 11 arquivos

- `CLAUDE.md`
- `Makefile`
- `PLANO_etapa_12.md`
- `README.md`
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
- `docker/medir.sh` — todo `awk` sob `LC_ALL=C` e a vírgula da tabela posta à mão (RVE3-01).

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
......................sss................sss............................ [ 41%]
........................................................................ [ 55%]
........................................................................ [ 69%]
........................................................................ [ 82%]
........................................................................ [ 96%]
.................                                                        [100%]
513 passed, 8 skipped in 244.29s (0:04:04)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

O `dbt build` desse mesmo `make check`, pelo `dbt/target/run_results.json` que ele deixou
(`generated_at` `2026-09-24T19:06:00Z`): 905 resultados — 200 `success` e 705 `pass`, nenhum outro
estado. Os três `aviso:` do fim são da linhagem derivada, sobre `legacy_classifications`, e não são
desta entrega: os mesmos três saem desde o dossiê de 20/09 (`e46e87a`), e o modelo não muda desde
15/09 (`9200b15`).

### Medições desta entrega, além do `comandos.txt`

Saída literal, colada. As do RVE3-01 e do RVE3-02 — a reprodução antes da correção, as duas pausas
reais do Airbyte, o prazo esgotado de verdade, o `busybox awk` — estão nas §10 e §11 do dossiê
anterior (`git show c10a30c:REVISAO.md`), com o código das sondas, e não são repetidas. As desta
seção são da D53 e da D54, todas de 24/09/2026.

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
Airflow, que ninguém pediu.

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

- **A troca de uma retomada com a outra família de pé, de verdade.** `airbyte-resume` com o
  *streaming* de pé e `stream-resume` com o Airbyte de pé rodaram só com `docker` e preflight
  simulados. De verdade, a troca pausaria um ambiente para religar o outro, e com a memória desta
  máquina (2,3–2,6 GB livres com o Airbyte de pé) a subida não passaria: pararia na recusa, com
  `FORCE=1` como única saída.
- **`airflow-resume` e `stream-resume` religando de verdade.** O primeiro não rodou (§3); o segundo,
  só no caminho da recusa, porque os contêineres do *streaming* não existem.
- **`airbyte-up` e `airbyte-resume` retomando um cluster pausado, depois da reestruturação.** O ramo
  `exited` rodou de verdade em 23/09/2026 com a receita de `5851d41` (dossiê anterior, §11.1);
  depois que a espera virou `AGUARDAR_API_AIRBYTE`, só com dublês. Pausar o Airbyte agora deixaria a
  retomada presa no preflight: com 2,3 GB livres, os 5 GB do custo não cabem.
- **`ESTADO_AIRBYTE` com o Docker que não responde, e com `paused` ou `restarting`:** só com o
  `docker` simulado. Observados de verdade: `running`, `exited` e `created` (§3); `created` cai na
  recusa explícita, porque nenhum caminho o trata.
- **O alvo de pé pela metade com contêineres reais:** só simulado.
- **A troca antes de uma subida que só falha depois** continua possível, e é anterior a esta entrega:
  `airbyte-up` sem cluster pausa o *streaming* e chama o `abctl`, que pode abortar — o `PG_VERSION`
  da Execução Local §6 —, e o *streaming* fica pausado. As conferências novas cobrem o que se sabe
  antes da troca (existência, estado do nó, `curl`); o que só falha depois, não.
- **O acréscimo de uma sincronização sobre o Airbyte ocioso** continua sem conferência — é o custo
  aceito da D53. No momento das medições, com 2,3 GB livres e o Airbyte de pé, o preflight diz
  "nada a cobrar"; uma sincronização iria em direção ao pico de 4,95 GiB (Capacidade §2.9) e
  passaria da folga de 1,5 GB. Não sincronizei para medir.
- **`make -n` sobre os três `*-resume`:** nenhuma linha deles cita `$(MAKE)`, e a regra textual
  cobre isso; o teste do efeito continua só com `airbyte-up`, `dbt-build RESET=1` e
  `recovery-restore`.
- **O `/health` como sinal de pronto não acusa o banco interno vazio** da Execução Local §6: nesse
  estado ele responde, e `airbyte-up` com o cluster de pé agora diz "pronta" onde antes esbarrava no
  `PG_VERSION`. Nenhum dos dois consertava — o erro aparece no passo seguinte, com 401 —, e o corpo
  do `/health` nesse estado não foi registrado. Não reproduzido.
- **O exemplo de saída da Execução Local §5** continua com a mensagem antiga — "não convive com
  'streaming'", onde o código diz "está de pé e ocioso". A atualização da §5 é de B6, como o plano
  prevê (§8, item 2).
- **O `verificar.py` da skill de ADR acusa dois contadores — e já acusava em `c10a30c`.** Ele conta
  as pendentes pelo `**Dnn**` em negrito da §3 do Registro de Decisões, onde a D43 não está em
  negrito, e não reconhece o formato `1 (D43, …)` do cabeçalho das Pendências. Os contadores estão
  certos — uma pendente, a D43 —; o verificador não foi corrigido nesta entrega, que não passou por
  ADR.
- O que os dossiês anteriores listavam como de B5 continua de B5.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **O `MemAvailable` já desconta o que o alvo de pé ocupa** — é o que justifica não cobrá-lo de novo.
  Vale para o consumo de agora; o acréscimo até o pico, numa sincronização, é o custo aceito da D53.
- **"Inteiro de pé" é cada serviço do grupo com um contêiner `running`**, pelos grupos de
  `conteineres.sh` (`airflow_init` fica de fora de propósito). Um serviço novo no grupo entra
  sozinho.
- **`docker ps -a --format '{{.State}}'` devolve o estado em minúsculas** — `running`, `exited` e
  `created` observados no Docker 29.7.2 desta máquina — e sai diferente de 0 quando o daemon não
  responde. A segunda parte não foi provocada de verdade.
- **`docker start` num contêiner de pé sai 0 sem reiniciá-lo** — medido (§3), no mesmo Docker.
- **O `FORCE` chega ao preflight dos `*-resume` como chega ao dos `*-up`** — é a mesma macro.
  `recovery-restore` passa `FORCE=` vazio a `medir` e a `airbyte-up`, e não chama nenhum `*-resume`.
- **O `abctl local install` sobre o cluster de pé aborta no `PG_VERSION`** enquanto o `pgdata`
  pertencer ao `uid 70` com modo `0700` — registrado em 05/09/2026 (Execução Local §6, com o cluster
  inteiro depois de reiniciar a máquina) e em 23/09/2026. A de 20/09 (`13f0065`) não registra o
  estado do cluster e não é contada. A D53 deixa de chamá-lo nesse caso; se a permissão mudar,
  reaplicar o chart pelo `abctl` pode voltar a funcionar — e não existe alvo para isso.
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

- **os três bancos de pé**, com o estado de 23/09 — nenhum dado mudou nesta entrega; o `make check`
  roda o `dbt build`, que reconstrói o armazém como sempre;
- **Airbyte de pé e ocioso**, religado com a máquina em 24/09 às 15h14; a API responde
  (`make airbyte-up` confere e sai em menos de um segundo, §3);
- **Airflow parado** (`exited` há três dias — o *scheduler* e o processador de DAGs com código 1
  na parada) e **streaming ausente**; nenhum dos dois é preciso;
- **memória curta:** 2,3–2,6 GB livres com o Airbyte de pé e a estação de trabalho do Owner
  aberta. `make preflight ALVO=airflow` recusa, e qualquer `*-up` ou `*-resume` que precise subir
  algo vai recusar. **Não force**: `FORCE=1` é autorização do Owner (`CLAUDE.md` §5), e o que
  depender disso fica não medido;
- as sondas da D53 e da D54 não precisam de nada de pé: `tests/test_preflight.py` usa um
  *namespace* com `/proc/meminfo` trocado, e `tests/test_makefile.py`, um rascunho com executáveis
  simulados. Consultas reais sem efeito: `make preflight ALVO=…`, `docker/preflight.sh <alvo>` sem
  `--trocar`, e `make airbyte-up` ou `make airbyte-resume` com o cluster de pé, que só conferem a
  API;
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

## 9. As duas decisões do Owner depois da terceira rodada — D53 e D54

Levantadas na verificação do RVE3-02 (dossiê anterior, §11.8), decididas pelo Owner em 24/09/2026 com
as alternativas na mesa, e implementadas nesta entrega. O registro — decisão, alternativas
descartadas e custo aceito — está em
[Pendências §2](docs/pendencias.md#d53-e-d54--decididas-e-implementadas-em-24092026); aqui fica o que
o revisor precisa para conferir.

| Decisão | *Commit* | O que conferir |
|---|---|---|
| D53 — o que já está de pé não é cobrado de novo | `5f5efc5` | `_inteiro_no_ar` e `ALVO_DE_PE` no preflight: o alvo inteiro de pé não é cobrado, e de pé pela metade é; a troca continua, e a pausa da outra família não é desfeita por memória |
| D53 — `airbyte-up` com o cluster de pé confere a API | `4c3410f` | `ESTADO_AIRBYTE` e os três ramos de `airbyte-up`; o Docker que não responde e o estado estranho recusam antes da troca, e o `curl` também |
| D54 — as retomadas passam pela troca do preflight | `93c849c` | os três `*-resume`: a existência antes, o preflight da própria família, `FORCE=1` como única saída; a regra lida do texto em `test_todo_alvo_que_liga_ambiente_pesado_passa_pelo_preflight` |
| o registro | `4b785d3` | Pendências §1 → §2 e contadores, Execução Local §4–§6, `CLAUDE.md` §5, README e plano |

Perguntas que valem uma sonda: há alvo que liga ambiente pesado e escapa do padrão `LIGA_AMBIENTE`
do teste? O `FORCE` atravessa algum `*-resume` chamado por outro alvo? Existe caminho em que a troca
pausa a outra família e a receita falha depois, deixando-a pausada à toa?

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

