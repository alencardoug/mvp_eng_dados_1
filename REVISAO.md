# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `b1011e7..2136781` — leia o diff, ele não é repetido aqui.

**Terceira rodada, mesmo escopo B0/B1/B4** (B2/B3 ficam para a revisão final, depois de B6,
por decisão do Owner). As duas rodadas anteriores — parecer, evidências E1–E9 e E2-1–E2-5, o
código das sondas e as respostas — estão no dossiê anterior: `git show 2136781:REVISAO.md`. A
§8 abaixo traz os cinco achados da segunda rodada com a resposta de cada um, que é o que esta
rodada confere. Os cinco primeiros *commits* do intervalo respondem a RVE2-01–05; depois
entraram, a pedido do Owner, o período medido do medidor (`2022bdd`) e a correção das linhas de
receita que misturavam `$(MAKE)` com outro comando (`0c03e7e`).

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
fba57cc fix: o passo 9 recusa a ausência — da auditoria da captura nova e do livro
e12d39d fix: o medidor registra a leitura que falhou como não medida, nunca como zero
e2a18c5 fix: o pipeline lançado pelo medidor nasce com SIGINT, e o SIGKILL fica no registro
ad19028 fix: desfazer a troca religa só o que estava de pé antes da pausa
8c04106 fix: restaurar os artefatos devolve o estado do pacote, inclusive o que ele não traz
849e508 docs: aplica a segunda rodada de revisão da entrega no dossiê, no plano e nas pendências
2022bdd fix: o medidor registra o período medido entre amostras, não só a pausa
bbf40fa docs: registra o período medido do medidor no plano e a sonda do docker stats no dossiê
0c03e7e fix: nenhuma linha de receita mistura $(MAKE) com outro comando
2136781 docs: registra a correção da linha de airbyte-up no plano e no dossiê
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 15 arquivos

- `Makefile`
- `PLANO_etapa_12.md`
- `docker/medir.sh`
- `docker/preflight.sh`
- `docs/pendencias.md`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/recovery/cli.py`
- `src/mvp_ed1/recovery/leitura.py`
- `src/mvp_ed1/recovery/oraculos.py`
- `src/mvp_ed1/recovery/pacote.py`
- `tests/test_identidade_captura.py`
- `tests/test_makefile.py`
- `tests/test_medicao.py`
- `tests/test_preflight.py`
- `tests/test_recovery.py`

### Gerados — 1 arquivos, revisar por amostragem

- `REVISAO.md`

**Declaração desta entrega.** O único "gerado" acima é o dossiê anterior, marcado pelo próprio
cabeçalho; não há derivado de código no intervalo. Pedem revisão integral, porque são o contrato
do que o resto faz:

- `Makefile` — em `recovery-restore`, o `jobId` que atravessa do passo 8 ao 9 (`RECOVERY_JOB`,
  `sync-legacy JOB_EM=` → `airbyte.py --job-em`, `conferir-restauracao --job`); `RETOMAR_AIRBYTE`, que `airbyte-resume`
  e `airbyte-up` compartilham; e `dbt-build`, com o descarte separado do build;
- `src/mvp_ed1/recovery/cli.py` e `leitura.py` — os oráculos novos do passo 9
  (`_conferir_auditoria_da_captura_nova` sobre `classificacao_corrente`; o livro com o tamanho da
  origem, `LIVRO_NA_ORIGEM`) e `comando_restore_artefatos`;
- `src/mvp_ed1/recovery/pacote.py` — o formato do pacote: `artefatos_links` **obrigatório** e
  `afastar_o_que_o_pacote_nao_traz`;
- `docker/medir.sh` — `NA` no lugar da leitura que falhou, `agregar` com as falhas e
  `periodo_medio_s`, o lançamento do pipeline com `trap - INT QUIT` e `encerramento`;
  `docker/preflight.sh` — `ANTES_DA_PAUSA`.

Os testes são os oráculos: vale conferir se provam o que dizem. `tests/test_makefile.py` é novo e
é o único que executa o `Makefile` real — sob `make -n` e, para `airbyte-up`, sem ele —, sempre
com executáveis simulados. `PLANO_etapa_12.md` e `docs/pendencias.md` só registram.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
..................................s..................................... [ 15%]
............................s........................................... [ 30%]
......................sss................sss............................ [ 45%]
........................................................................ [ 60%]
........................................................................ [ 75%]
........................................................................ [ 90%]
..............................................                           [100%]
470 passed, 8 skipped in 240.04s (0:04:00)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

Os três `aviso:` do fim são da linhagem derivada, sobre `legacy_classifications`, e não são
desta entrega: os mesmos três saem desde o dossiê de 20/09 (`e46e87a`), e o modelo não muda
desde 15/09 (`9200b15`).

### Medições desta entrega, além do `comandos.txt`

Saída literal, colada. Os cinco achados foram reproduzidos **antes** de corrigidos, com as sondas
da rodada anterior — ainda em `/tmp/rve2_xEBKdU/`; o código delas está na §11.2 do dossiê
anterior — e as cinco saídas bateram com as da E2-3, E2-4 e E2-5. As mesmas sondas foram
repetidas depois de cada correção. Leituras dos bancos vivos em transação somente de leitura;
nenhuma restauração, sincronização ou avanço de sequência. Um *commit* por achado: `fba57cc`
(RVE2-01), `e12d39d` (RVE2-02), `e2a18c5` (RVE2-04), `ad19028` (RVE2-03), `8c04106` (RVE2-05).

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
conferida lendo o texto.

**A linha foi corrigida depois, a pedido do Owner (`0c03e7e`).** A medição
achou uma segunda linha da mesma forma e mostrou que a detecção do `make` é
**textual**: no GNU Make 4.3, o ramo falso de um `$(if)` com `$(MAKE)` rodou
sob `-n`. Com o `Makefile` real copiado para um rascunho e executáveis
simulados que registram cada chamada:

```text
Makefile antigo: make -n airbyte-up -> ['docker ps -aq -f name=^airbyte-abctl-control-plane$ -f status=exited', 'abctl local install --values airbyte/values.yaml']
Makefile antigo: make -n dbt-build RESET=1 -> ['dbt build --full-refresh']
```

`make -n recovery-restore RESTAURAR=1`, no antigo — o `dbt build` sem
`--full-refresh` vem do `check`, que chama `dbt-build` com o `RESET` vazio:

```text
['docker ps -aq -f name=^airbyte-abctl-control-plane$ -f status=exited', 'abctl local install --values airbyte/values.yaml', 'dbt build']
```

No novo, os três `make -n` não registram chamada nenhuma, e os testes de
comportamento continuam passando:

```text
$ .venv/bin/python -m pytest -q tests/test_makefile.py
.......                                                                  [100%]
7 passed in 0.20s
```

A retomada virou a variável `RETOMAR_AIRBYTE`, chamada por `airbyte-resume` e
pelo ramo "pausado" de `airbyte-up`, e `dbt-build` separou o descarte do build.
`tests/test_makefile.py` guarda a regra e o efeito. Os três testes de
comportamento — retoma sem reinstalar, instala sem cluster, `airbyte-resume`
retoma — passam no `Makefile` antigo e no novo. `make check` depois da
correção: `PASS=905`, `470 passed, 8 skipped`.

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

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **O passo 9 depois de uma captura nova de verdade.** O oráculo novo rodou contra o armazém vivo
  com a 43 no papel de nova e o manifesto sem a fatia dela, e contra dublês; `recovery-restore`
  nunca rodou de ponta a ponta.
- **O `jobId` atravessando um disparo real.** `sync-legacy JOB_EM=` foi exercitado com o fluxo
  certificado injetado (`test_a_captura_certificada_deixa_o_seu_job`); o arquivo
  `$(RECOVERY_DIR)/job-do-passo-8` nunca foi criado por uma sincronização, e a composição
  `rm -f` → `sync-legacy JOB_EM=` → `cat` → `--job` foi conferida lendo a receita e sob `make -n`
  simulado, não executada.
- **O runner Beam real encerrando pelo SIGINT.** A prova é de um Python comum lançado pelo cenário
  real de `medir.sh`, sob `make`; o Beam — com as *threads* e os subprocessos do runner — não foi
  lançado, e o prazo de 60 s não foi medido contra ele.
- **`medir.sh` com `/proc/meminfo` ilegível:** o ramo `NA` de `_mem_disponivel` não tem teste; só
  o de `docker stats` (falha e linha `--`).
- **A linha `--` do `docker stats` no Docker real:** tratada como `NA`, nunca observada — a sonda
  de transição não a produziu.
- **A precisão do período medido:** a série guarda o *epoch* em segundos inteiros, e com poucas
  amostras o período é aproximado; a sensibilidade não foi medida.
- **`restore-artefatos` num clone**; o caminho de colisão do nome afastado (sufixo `-2`), que
  nenhum teste exercita; e link com destino absoluto, que `links_sem_destino` recusaria — sem teste.
- **O preflight com contêineres reais** numa pausa parcial: os casos de `ANTES_DA_PAUSA` usam
  `docker` simulado.
- **`dbt-build RESET=1` de verdade:** a separação das linhas foi exercitada sob `make -n` simulado
  e no `make check` real com `RESET` vazio; com `RESET=1` real, que derruba os snapshots, não.
- **`airbyte-up` e `airbyte-resume` de verdade:** `RETOMAR_AIRBYTE` foi exercitado com `docker`
  simulado; o nó do `kind` não foi parado nem retomado.
- **O candidato refeito não foi restaurado** em lugar nenhum — só conferido por
  `verify --contra-o-banco`.
- O que o dossiê anterior já listava como de B5 continua de B5.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **A auditoria de uma captura é `select *` das rejeitadas da classificação dela**
  (`rejected_legacy_records.sql`), e a classificação corrente cobre só a captura selecionada.
  Medido na 43 (3.207 linhas, mesmo digest, uma chave tratada); para a captura nova é premissa —
  o modelo é o mesmo.
- **O oráculo novo prova presença e integridade da auditoria em relação à classificação, não a
  classificação.** A correção dela é dos testes de dados do `make check` do passo 8.
- **bash, `setsid` e sinais:** comando assíncrono de script nasce com SIGINT e SIGQUIT ignorados, e
  `trap - INT QUIT` num subshell os devolve ao padrão antes do `exec` — medido neste bash
  (`default_int_handler`); `setsid` sem `fork` mantém `$!` como o grupo — premissa anterior, que a
  suíte exercita.
- **O GNU Make 4.3 detecta `$(MAKE)` pelo texto da linha** — medido aqui; outra versão do `make`
  não foi testada.
- **O `mawk` segue o locale** (`4,5` em pt_BR) — medido; o `LC_ALL=C` da agregação é o que mantém o
  JSON válido, e o teste do período roda sob o locale da máquina.
- **O `docker stats` imprime `-- / --` para o contêiner que não conseguiu medir** — conhecimento da
  ferramenta, não observado aqui.
- **O link do manifesto do legado é relativo** (`gravar_manifesto` usa `destino.name`) — conferido
  no pacote novo: `manifesto-3f9e5088c72234045351b251d406ce9e.json`.
- **O `make` para no primeiro erro de receita:** é o que garante que o passo 9 só lê o `jobId` de um
  passo 8 que terminou; o `rm -f` antes de `sync-legacy` cobre o resto de uma execução anterior.

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

- **os três bancos de pé**, com o estado do pacote: o candidato em `data/recovery/candidato/`
  (corte `2026-09-23T20:53:54+00:00`, código `8c04106`) confere contra eles —
  `make recovery-verify CONTRA_O_BANCO=1`, só leitura, ~16 s;
- **Airbyte de pé e ocioso**, contador em 43 (`docker/airbyte_jobs.sh ler`, só leitura);
- **Airflow parado** (`exited`) e **streaming ausente** — nenhum dos dois é preciso. Não suba o
  streaming para sondar: `stream-run` escreve no destino do CDC, e isso é alterar dado;
- as sondas da rodada anterior continuam em `/tmp/rve2_xEBKdU/` e rodam contra este código; a
  `sonda_artefatos.py` precisa do candidato **novo** — contra o de 21/09 a restauração recusa,
  porque ele não tem `artefatos_links`;
- `make -n` sobre este `Makefile` não executa mais nada (`tests/test_makefile.py` guarda), mas
  sonda que precise **executar** alvo continua no padrão de rascunho com executáveis simulados
  (`tests/test_makefile.py::_make`, `tests/test_medicao.py::_ambiente`).

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **O esperado do RVE2-01 vem do mesmo modelo que produz a quarentena.** Um esperado
  independente — reclassificar a captura em Python, ou partir do catálogo de falhas do lote —
  provaria mais, mas é outro oráculo, maior, e o achado era de **ausência**: a classificação prova
  que a auditoria entrou inteira, e só isso. A correção da classificação é dos testes de dados.
- **`--job` obrigatório**, e não opcional com o `Makefile` passando: opcional era a lacuna. Quem
  chamar à mão precisa informar o job.
- **O arquivo do job fica em `$(RECOVERY_DIR)/job-do-passo-8`**, fora de `candidato/`: é estado da
  restauração, não do pacote. A outra opção era o `data/` do *checkout*, mas o `RECOVERY_DIR` é
  absoluto e é o que a sequência já carrega.
- **O tamanho do livro vem da origem viva**, não do manifesto: depois do passo 5 os dois são
  iguais, e a origem é o que o livro precisa reproduzir.
- **Uma linha `--` torna a amostra inteira `NA`**, em vez de uma soma parcial: a soma sem um
  contêiner não é o total. E a leitura que falha **não** muda o código de saída — o alvo rodou; o
  registro diz `null` e a tabela diz "não medido".
- **Sem nova tentativa dentro da amostra** (pergunta do Owner): a amostra seguinte já é essa
  tentativa, com o instante certo; e o `docker stats` não falhou na transição de contêiner medida.
- **O período medido ao lado de `intervalo_s`, sem renomeá-lo:** renomear quebraria a leitura dos
  registros de 20/09; o campo novo fica ao lado, e o `limite` do registro explica os dois.
- **`trap - INT QUIT`, e não `env --default-signal`:** o segundo exige coreutils ≥ 8.31, e o bash
  basta. O encerramento forçado é registrado, mas não reprova a medição.
- **Afastar, não apagar**, o que o pacote não traz: renomear com sufixo fora dos padrões. E
  **`artefatos_links` obrigatório**, em vez de refazer o link por igualdade de conteúdo — seria
  inferir. Custou o candidato de 21/09, refeito.
- **`RETOMAR_AIRBYTE` como variável**, e não script novo nem `$(MAKE)` em linha separada: um dono
  só, e a linha deixa de citar `$(MAKE)`. **Não** mudei que a retomada que esgota o prazo sai 0 —
  é assim desde antes; fica como observação para esta rodada.
- **A regra de `tests/test_makefile.py` só aceita a forma `$(if $(filter 1,$(VAR)),$(MAKE) …[,true])`**
  além da recursão pura: uma forma nova e legítima vai reprovar e pedir que o teste a reconheça.
  Preferi o falso positivo ao falso negativo.

## 8. A segunda rodada — achados e respostas, para conferir

A rodada anterior deixou RVE-05 e RVE-11 parciais e abriu RVE2-01–05. As respostas estão abaixo,
como ficaram no dossiê anterior, com o *commit* de cada uma — RVE2-01 completa RVE-05, e RVE2-03
completa RVE-11. Dentro da tabela, as evidências E2-3, E2-4 e E2-5 são do dossiê anterior
(§11.2, com o código das sondas), e as saídas que as células atribuem à "§12" estão agora na §3
deste. "§6, passo 9" é do plano. A aplicação achou mais dois defeitos, e depois dela entraram
duas mudanças a pedido do Owner:

| Origem | *Commit* | O quê |
|---|---|---|
| achado próprio, na sonda E2-3 | `fba57cc` | o passo 9 aceitava os dois caminhos do livro vazios |
| achado próprio, em `restore-artefatos` | `8c04106` | o `copy2` escrevia através do link `data/legacy/manifesto.json` |
| pedido do Owner | `2022bdd` | o medidor grava o período medido entre amostras (`periodo_medio_s`) |
| pedido do Owner | `0c03e7e` | nenhuma linha de receita mistura `$(MAKE)` com outro comando |

| ID | Onde | Achado e correção necessária | Veredito | Situação |
|---|---|---|---|---|
| RVE2-01 | `src/mvp_ed1/recovery/cli.py:724` | **O passo 9 aceita a ausência da auditoria da captura nova.** Partindo da fixture válida, retirar somente a fatia 44 da quarentena mantém saída 0, inclusive com `job=44`. O código confere que fatias extras pertencem às capturas novas, mas não que as fatias esperadas existem com as linhas certas. Comparar contagem/conteúdo do acréscimo com a classificação da captura efetivamente disparada, aceitando vazio somente quando o esperado for vazio; conduzir seu jobId do passo 8 ao passo 9. É a parte ainda não cumprida de RVE-05 e da §6, passo 9. **E2-3.** | `bloqueante` | **Corrigido** (`fba57cc`) em `cli._conferir_auditoria_da_captura_nova`: o acréscimo da captura nova é comparado, por contagem **e** digest, com `leitura.classificacao_corrente` — as rejeitadas de `trusted.legacy_classifications`, de que a quarentena é `select *` —; a classificação precisa tratar exatamente as capturas novas; nada a mais entra em nome delas; captura sem rejeição tem acréscimo vazio e passa. `--job` é obrigatório: `sync-legacy JOB_EM=` grava o jobId da captura concluída **e** certificada, e `recovery-restore` o leva ao passo 9, apagando antes o de uma execução anterior. Premissa medida no banco vivo, só leitura: a fatia da 43 é igual às rejeitadas da classificação (3.207 linhas, mesmo digest), e a conferência nova, com a 43 no papel de nova, passa com a fatia e acusa sem ela (§12). Sonda E2-3 repetida: `sem_fatia_da_captura_nova codigo= 1`. **Achado próprio na mesma sonda:** `livros_ambos_vazios` também saía 0 — os dois caminhos agora precisam ter o tamanho do livro na origem (13.700 nos três, medido). Testes: `test_o_passo_9_recusa_a_falta_da_auditoria_da_captura_nova` e mais nove — seis do passo 9 (um é o do livro vazio), três do `--job-em`. |
| RVE2-02 | `docker/medir.sh:42`; `docker/medir.sh:58` | **Falha de `docker stats` vira medição de 0 MB com sucesso.** Na sonda, `ps` informa Airbyte de pé, `stats` sai 1 nas duas consultas e o JSON grava duas amostras, máximo 0 e código 0. O `awk` produz zero para entrada vazia; o `printf` externo perde a falha. Propagar o estado da coleta, separar amostras válidas de falhas e registrar a métrica como indisponível quando não foi medida. Um zero inventado não pode alimentar a tabela de capacidade de B5 (P5). **E2-4.** | `bloqueante` | **Corrigido** (`e12d39d`) em `medir.sh`: leitura que falha é `NA` — `docker stats` com erro, linha sem número (`--`), `/proc/meminfo` ilegível —; `agregar` tira o extremo só das amostras válidas de cada grandeza e conta `disponivel_falhas`/`conteineres_falhas`; sem nenhuma válida o extremo é `null`, sem instante; a linha da tabela diz "não medido" e avisa quantas faltaram. O código de saída continua o do alvo, que rodou. Sonda E2-4 repetida: `conteineres_maximo_mb: None`, `conteineres_falhas: 2`. Contra o Docker real: 3.222 MB, 0 falhas (§12). Testes: `test_docker_stats_que_nao_mede_vira_nao_medido_e_nao_zero` (duas formas) e mais três. |
| RVE2-03 | `docker/preflight.sh:134` | **O recuo da pausa liga serviços que já estavam parados.** Com apiserver inicialmente `exited` e parada do scheduler falhando, a tentativa recusada terminou com os quatro serviços de pé. `_religar` usa `resolver --todos`, sem preservar o conjunto inicial pedido em RVE-11. Guardar os nomes de pé antes da pausa e recompor exatamente esse conjunto, tanto na falha parcial quanto na recusa por memória; não aumentar o consumo ao desfazer uma troca recusada por R11. **E2-4.** | `ajuste` | **Corrigido** (`ad19028`) em `preflight.sh`: `_parar` anota por ambiente o que estava de pé (`ANTES_DA_PAUSA`) e `_religar` recompõe **exatamente** esse conjunto, conferindo nome a nome; vale para a pausa parcial e para a recusa por memória. `resolver --todos` fica só com a retomada pedida pelo operador (`*-resume`). Sonda E2-4 repetida: `ligados_sem_estarem_de_pe []`. Testes: `test_recuo_da_pausa_parcial_nao_liga_o_que_ja_estava_parado`, `test_recusa_por_memoria_devolve_so_o_que_estava_de_pe`. Com isto RVE-11 fica inteiro. |
| RVE2-04 | `docker/medir.sh:303` | **O processo Python lançado pelo cenário herda `SIGINT` ignorado.** Com o lançador real e um Python mínimo que captura `KeyboardInterrupt`, a disposição foi `SIG_IGN`; SIGINT não o encerrou e houve SIGKILL após o prazo, com retorno 0. A CLI real usa `KeyboardInterrupt` para a interrupção; `setsid` só separa o grupo. Restaurar a disposição de sinal antes de executar o filho e provar encerramento cooperativo; registrar quando foi necessário forçar. O runner Beam real não foi executado nesta contraprova. **E2-4.** | `ajuste` | **Corrigido** (`e2a18c5`) em `medir.sh`: `( trap - INT QUIT; exec setsid make … stream-run ) &` — a disposição volta ao padrão antes do `exec`, que preserva o PID anotado como grupo. O registro ganha `encerramento`: `limpo`, `forcado` ou `null`. Sonda repetida: `default_int_handler`, `KeyboardInterrupt` recebido, sem SIGKILL. **O que a correção revelou:** os cenários da suíte com `sleep 600` também só saíam pelo SIGKILL do prazo, sem que ninguém visse — a suíte do medidor caiu de 35 s para 29 s. O runner Beam real não foi executado (é de B5). Testes: `test_o_pipeline_lancado_encerra_pelo_sigint_e_nao_pelo_prazo`, `test_encerramento_forcado_fica_no_registro`. |
| RVE2-05 | `src/mvp_ed1/recovery/cli.py:562` | **Restaurar artefatos preserva metadado de uma carga posterior quando ele estava ausente do pacote.** O candidato real não tem `data/source/geracao.json`; em um checkout temporário com esse arquivo de outra carga, `restore-artefatos` saiu 0 e o próximo `geracao_registrada` atribuiu à fonte restaurada os parâmetros posteriores. B5 executa `seed-data` antes de restaurar, portanto cria esse caso com o candidato atual. Restaurar também a ausência dos arquivos de estado conhecidos, ou invalidar explicitamente o registro incompatível, para que a falta continue sendo `None` com motivo. **E2-5.** | `ajuste` | **Corrigido** (`8c04106`) em `restore-artefatos`: o estado de trabalho que o pacote não traz é afastado — renomeado com `.anterior-a-restauracao-<instante>`, fora dos padrões de `ARTEFATOS`, nunca apagado —, e tudo é conferido antes de qualquer arquivo mudar. **Achado próprio na mesma função:** o `copy2` sobre `data/legacy/manifesto.json` escrevia **através do link** do *checkout*, no manifesto do lote apontado — onde `mutacoes._ler` grava o diário (medido num rascunho, §12). O pack passa a registrar `artefatos_links` (obrigatório) e a restauração refaz o link. O candidato de 21/09 não tinha o campo e a restauração o recusava sem tocar em nada: **refeito** (corte `2026-09-23T20:53:54+00:00`, código `8c04106`) e conferido contra os bancos. Sonda E2-5 repetida contra ele: `registro_posterior_sobreviveu False`, `proximo_pack_atribuiria_a_origem None`. Testes: `test_restaurar_os_artefatos_restaura_a_ausencia` e mais quatro. |

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

