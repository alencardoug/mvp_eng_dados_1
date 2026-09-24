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

## 9. Parecer da terceira rodada — 23/09/2026

**As respostas a RVE2-01–05 foram confirmadas nos caminhos ensaiados. Há dois problemas
remanescentes: um bloqueante no instrumento de medição e um ajuste na espera da retomada do
Airbyte. Ambos também foram reproduzidos em `b1011e7`: são lacunas anteriores, ainda presentes
nos trechos revisados, e não regressões introduzidas pelo intervalo desta rodada.**

Escopo: `b1011e7..2136781`, com o dossiê de `78d0dcb`. Revisados o declarativo e os testes
indicados na §2, as decisões D45–D52 e os contratos pertinentes dos ADRs 0044–0046. B2/B3
continuam fora deste parecer. Esta revisão altera somente este dossiê; não executa B5, não
aprova a implementação pelo Owner nem encerra a Etapa 12.

### 9.1 Conferência das respostas

| Item | Resultado desta rodada |
|---|---|
| RVE2-01 — auditoria e identidade | **Confirmado.** As contraprovas anteriores recusam a auditoria ausente e os dois livros vazios. A classificação real da 43 coincide com sua auditoria e a conferência acusa sua retirada. A receita real, copiada para um rascunho com ferramentas simuladas, elimina o job antigo e entrega o novo ao passo 9; falha ou ausência do arquivo impedem esse passo. Uma captura nova real continua pendente de B5. |
| RVE2-02 — leitura indisponível | **Confirmado para a falha descrita.** `docker stats` com erro ou `--` vira indisponível, e a ausência de `MemAvailable` também vira `null`, com falhas contadas. A conversão de uma leitura decimal válida ainda depende do locale: RVE3-01. |
| RVE2-03 — recuo da pausa | **Confirmado com Docker simulado.** Pausa parcial e recusa por memória recompõem os contêineres que estavam de pé, preservando os que já estavam parados. A sonda anterior voltou a produzir `ligados_sem_estarem_de_pe []`. |
| RVE2-04 — sinais | **Confirmado com processo Python.** Disposição `default_int_handler`, `KeyboardInterrupt` recebido e nenhum SIGKILL na sonda anterior. A suíte também confere o registro do encerramento forçado. O runner Beam real continua não exercitado. |
| RVE2-05 — artefatos | **Confirmado.** A sonda anterior, com cópia dos artefatos do candidato atual em diretório temporário, retira o registro posterior de geração; o próximo leitor devolve `None`. A suíte confere a reconstrução do link e a preservação do manifesto de outro lote. |
| Período do medidor | **Confirmado nos testes.** A série sintética confere o cálculo; a coleta com `stats` lento inclui o custo da leitura no período. Isso não valida a conversão dos valores de memória, objeto de RVE3-01. |
| Receitas sob `make -n` | **Confirmado.** Os sete testes do Makefile passaram, inclusive os três alvos sob `-n`. A extração de `RETOMAR_AIRBYTE` preservou também os falsos sucessos da espera antiga: RVE3-02. |

### 9.2 Evidências executadas pelo revisor

**E3-1 — suíte do escopo.** Sem `.env` carregado; os cinco arquivos exercitam dublês e
diretórios temporários. Saída final literal:

```text
$ .venv/bin/python -m pytest -q tests/test_recovery.py tests/test_medicao.py tests/test_preflight.py tests/test_makefile.py tests/test_identidade_captura.py
159 passed in 56.67s
```

**E3-2 — candidato e leituras reais.** A primeira tentativa de `recovery-verify` foi recusada
pelo sandbox ao acessar Docker. Repetido com a permissão solicitada pela ferramenta, somente
leitura, terminou com código 0:

```text
$ make recovery-verify CONTRA_O_BANCO=1
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_ed1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_ed1/data/recovery/candidato
[recovery] contagens das três fontes, Alembic, versões do armazém e corte do livro conferidos
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s) desde o corte
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
[recovery] capturas: 11 certificada(s) do manifesto conferidas; 40 tabela(s) do bruto com a partição por geração igual à do manifesto (gerações como no manifesto)
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
```

A sonda `/tmp/rve3_fECjjc/leitura.py` abriu conexões com
`default_transaction_read_only=on` e `statement_timeout=15000`. A conexão também precisou de
permissão para sair do sandbox. A 43 foi tratada **em memória** como a nova captura; nenhum
registro foi excluído do banco. Saída literal:

```text
SOURCE_DB transaction_read_only on
WAREHOUSE_DB transaction_read_only on
capturas_tratadas [43]
rejeitadas {'["legacy",43,9,"607e6288f4f57e39"]': {'linhas': 3207, 'digest': '2f4d3211d2eb589828e9ec3a7117d68b'}}
conferencia_com_fatia []
conferencia_sem_fatia ['quarentena, auditoria da captura nova: fatia sumiu: \'["legacy",43,9,"607e6288f4f57e39"]\' (3207 linhas)']
livro_na_origem 13700
caminhos {'corte': 13700, 'so_no_lote': 0, 'so_no_fluxo': 0, 'payloads_diferentes': 0, 'saldos_diferentes': 0, 'soma_lote': 701841, 'soma_fluxo': 701841, 'linhas_lote': 13700, 'linhas_fluxo': 13700}
```

**E3-3 — contraprovas e composição.** Repetidas as três sondas anteriores,
`/tmp/rve2_xEBKdU/{sondas_oraculos,sondas_scripts,sonda_artefatos}.py`. Recorte literal dos
resultados; o código delas permanece no dossiê histórico identificado na §1:

```text
controle_valido codigo= 0 erros= ''
sem_fatia_da_captura_nova codigo= 1 erros= '  quarentena, auditoria da captura nova: fatia sumiu: \'["legacy",44,9,"hash"]\' (1 linhas)\n\nconferir-restauracao: 1 problema(s)\n'
livros_ambos_vazios codigo= 1 erros= '  caminhos do livro: 0 no lote e 0 no fluxo até o corte, e a origem tem 100 — iguais entre si não é o livro de volta\n\nconferir-restauracao: 1 problema(s)\n'
ligados_sem_estarem_de_pe []
stats_falhou_amostragem {'intervalo_s': 1, 'amostras': 2, 'disponivel_minimo_mb': 2498, 'disponivel_minimo_em': '2026-09-23T22:56:32Z', 'disponivel_falhas': 0, 'conteineres_maximo_mb': None, 'conteineres_falhas': 2, 'janela_s': 1, 'periodo_medio_s': 1.0}
pipeline_sigint_disposicao <built-in function default_int_handler>
pipeline_recebeu_keyboardinterrupt True
pipeline_exigiu_sigkill False
pipeline_codigo_medidor 0
restore_artefatos_codigo 0
registro_posterior_sobreviveu False
proximo_pack_atribuiria_a_origem None
```

`/tmp/rve3_fECjjc/sondas.py` também executou uma cópia do Makefile inteiro: os executáveis
do projeto e Docker foram substituídos por registradores, e o arquivo de job começou com
`999`. O substituto da sincronização escreveu `61`, não escreveu nada ou falhou, conforme o
caso. Outra sonda montou um `/proc/meminfo` sem `MemAvailable` em namespace privado, sem
modificar o do host. Saída literal:

```text
make_job valido codigo 0 passo_9 ['--job 61'] estado_no_disparo ['job_anterior_presente=False'] arquivo_final 61
make_job ausente codigo 2 passo_9 [] estado_no_disparo ['job_anterior_presente=False'] arquivo_final None
make_job falha codigo 2 passo_9 [] estado_no_disparo ['job_anterior_presente=False'] arquivo_final None
sem_MemAvailable codigo 0 inicial None minimo None falhas 3 amostras 3
```

**E3-4 — decimal no medidor.** O script real mediu um alvo `sleep 3`, com Docker simulado
entregando sempre `1.5GiB / 8GiB` e `512.5MiB / 1GiB`. O esperado é 2.048 MB após o truncamento
inteiro adotado pelo medidor. Saída literal de `sondas.py`:

```text
locale C codigo 0 maximo_mb 2048 falhas 0 esperado_mb 2048
locale pt_BR.UTF-8 codigo 0 maximo_mb 1536 falhas 0 esperado_mb 2048
```

O `LC_ALL=C` de `agregar` só protege a agregação; o valor já chega truncado indevidamente
por `_mem_conteineres`. Repetindo a mesma sonda com `medir.sh` e `conteineres.sh` extraídos de
`b1011e7`, sem alterar o checkout:

```text
base b1011e7 locale pt_BR.UTF-8 codigo 0 maximo_mb 1536
```

Reprodução independente de conservar `/tmp`, a partir da raiz, usando apenas os dublês
versionados da suíte:

```python
import importlib.util, subprocess, tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("m", "tests/test_medicao.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
for locale in ("C", "pt_BR.UTF-8"):
    with tempfile.TemporaryDirectory() as folder:
        base = Path(folder)
        env, cwd = m._ambiente(base, makefile="alvo:\n\t@sleep 3\n")
        env["LC_ALL"] = locale
        m._docker_com_stats(base, 'printf "1.5GiB / 8GiB\\n512.5MiB / 1GiB\\n"')
        r = subprocess.run([str(m.MEDIR), "alvo"], cwd=cwd, env=env,
                           capture_output=True, text=True, timeout=20)
        print(locale, r.returncode, m._registro(base)["amostragem"])
```

**E3-5 — espera da retomada.** `/tmp/rve3_fECjjc/retomada.py` executou os dois alvos do
Makefile copiado com Docker simulado. `docker start` saiu 0; `crictl pods` respondeu somente
um pod `NotReady`, ou nenhuma linha. `sleep` foi substituído por um executável que sai 0:
foram exercitadas as 30 tentativas, **não medidos 150 segundos**. Saída literal:

```text
airbyte-resume NotReady codigo 0 pronto True tempo_esgotado False consultas 1
airbyte-up NotReady codigo 0 pronto True tempo_esgotado False consultas 1
airbyte-resume vazio codigo 0 pronto False tempo_esgotado True consultas 30
airbyte-up vazio codigo 0 pronto False tempo_esgotado True consultas 30
```

Repetição com `git show b1011e7:Makefile` no rascunho:

```text
base b1011e7
airbyte-resume NotReady codigo 0 pronto True tempo_esgotado False consultas 1
airbyte-up NotReady codigo 0 pronto True tempo_esgotado False consultas 1
airbyte-resume vazio codigo 0 pronto False tempo_esgotado True consultas 30
airbyte-up vazio codigo 0 pronto False tempo_esgotado True consultas 30
```

Reprodução independente de `/tmp`, também só com dublês:

```python
import importlib.util, os, tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("mk", "tests/test_makefile.py")
mk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mk)
for state in ("NotReady", ""):
    for target in ("airbyte-resume", "airbyte-up"):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            extra = base / "extra"
            extra.mkdir()
            (extra / "sleep").write_text("#!/bin/sh\nexit 0\n")
            (extra / "sleep").chmod(0o755)
            docker = ('#!/bin/sh\ncase "$1" in\n'
                      'ps) echo node-id ;;\n'
                      f'exec) echo "{state}" ;;\nesac\nexit 0\n')
            r, _ = mk._make(base, target, docker=docker, ambiente_extra={
                "PATH": f'{base / "bin"}:{extra}:{os.environ["PATH"]}'})
            print(target, state or "vazio", r.returncode, r.stdout.strip())
```

### 9.3 Limites do parecer

- Não executados: `make check` completo (inclui escrita via dbt), nova sincronização,
  restauração dos dumps, avanço de sequências, runner Beam, pausa/retomada de contêineres
  reais ou clone de B5. As leituras reais não substituem essas validações.
- O candidato atual foi verificado e seus artefatos foram restaurados somente em rascunho;
  não há prova nova de restauração integral. B5 continua sem autorização nesta conversa.
- `MemAvailable` ausente foi ensaiado; falha de permissão ao abrir `/proc/meminfo`, colisão do
  sufixo de afastamento e link absoluto continuam sem contraprova específica nesta rodada.
- O impacto do locale nas medições históricas não foi quantificado. Não cabe corrigir seus
  números por estimativa: é preciso conferir a localidade de cada execução e remedir os
  cenários afetados. A sessão do revisor iniciou com `LC_ALL=C.UTF-8`; a contraprova fixou
  explicitamente `pt_BR.UTF-8`.

## 10. A aplicação dos achados — o que foi medido, 23/09/2026

Um *commit* por assunto: `9f19705` registra este parecer como chegou; `4921289` corrige o RVE3-01;
`d3a20df` corrige o RVE3-02; `c58a3cd` e `9d856df` corrigem dois defeitos que a própria correção do
RVE3-02 trazia; `6cf0118` tira do comentário do dublê da API um código de saída que não foi medido;
o *commit* de documentação que traz esta seção registra a rodada no plano (§3,
"Terceira rodada"), na Execução Local e nas pendências. Cada achado foi reproduzido **antes** de corrigido, e cada teste
novo foi rodado contra o código anterior, onde precisa reprovar, e contra o novo.

### 10.1 RVE3-01 — o medidor e o locale

**A sonda E3-4, antes.** A mesma entrada, sobre os dublês versionados (`tests/test_medicao.py`),
com o `medir.sh` de `9f19705`:

```text
C 0 maximo_mb 2048 falhas 0 | | alvo | Airbyte | 0m 03s | 2.2 GB | 2.0 GB | 3 amostras, uma a cada 1,0 s (pausa de 1 s) |
C.UTF-8 0 maximo_mb 2048 falhas 0 | | alvo | Airbyte | 0m 04s | 2.2 GB | 2.0 GB | 3 amostras, uma a cada 1,0 s (pausa de 1 s) |
pt_BR.UTF-8 0 maximo_mb 1536 falhas 0 | | alvo | Airbyte | 0m 03s | 2,2 GB | 1,5 GB | 3 amostras, uma a cada 1,0 s (pausa de 1 s) |
```

O 1.536 é o do revisor. **Achado próprio, na mesma saída:** a linha da tabela mudava de forma com o
locale — `2.2 GB` sob C, `2,2 GB` sob pt_BR —, enquanto o período já saía com vírgula nos dois. E,
por isso, o teste do RVE2-02 que recusava `"0.0 GB"` na linha era vazio sob pt_BR, onde o zero
sairia `0,0 GB`.

**O tamanho do defeito no ambiente real.** Uma leitura só do `docker stats`, somada pelo programa
`awk` do medidor sob os dois locales:

```text
44.19MiB / 2GiB
18.97MiB / 2GiB
137.4MiB / 2GiB
3.715GiB / 11.46GiB
pt_BR: 3271 MB
C:     4004 MB
```

São 733 MB a menos (18 %), quase tudo na fração do nó do Airbyte. O `awk` desta máquina é o
`mawk 1.3.4 20200120`; sob pt_BR ele lê a *string* `"1.5"` como 1 e escreve `%.1f` com vírgula
(`x="1.5"; x+0`, o literal `1.5`, o campo `1.5` e `printf "%.1f", 2.25`):

```text
string=1 literal=1,5 campo: 1 printf=2,2
```

**Depois (`4921289`).** Todo `awk` do medidor roda sob `LC_ALL=C`, e `_gb` põe a vírgula à mão. A
sonda E3-4, repetida:

```text
C 0 maximo_mb 2048 falhas 0 | | alvo | Airbyte | 0m 03s | 2,6 GB | 2,0 GB | 3 amostras, uma a cada 1,0 s (pausa de 1 s) |
C.UTF-8 0 maximo_mb 2048 falhas 0 | | alvo | Airbyte | 0m 03s | 2,6 GB | 2,0 GB | 3 amostras, uma a cada 1,0 s (pausa de 1 s) |
pt_BR.UTF-8 0 maximo_mb 2048 falhas 0 | | alvo | Airbyte | 0m 03s | 2,6 GB | 2,0 GB | 3 amostras, uma a cada 1,0 s (pausa de 1 s) |
```

O medidor corrigido contra o Docker real, no locale desta sessão (`LANG=pt_BR.UTF-8`, `LC_ALL`
vazio), com um `Makefile` de rascunho (`sleep 5`) e o registro fora de `data/medicoes/`, entre
duas leituras diretas somadas sob C:

```text
| alvo | Airbyte,bancos | 0m 05s | 2,7 GB | 3,8 GB | 2 amostras, uma a cada 3,0 s (pausa de 1 s) |
leitura direta sob C: antes=3878 MB depois=3882 MB
{'amostras': 2, 'conteineres_maximo_mb': 3879, 'conteineres_falhas': 0, 'periodo_medio_s': 3.0}
```

**Os testes novos contra o `medir.sh` anterior.** Os três reprovam, cada um pelo seu motivo (os
outros dois selecionados são os do RVE2-02):

```text
E       assert ["mb=$(awk '/...' ;; esac; }"] == []
E       assert '| 2,0 GB |' in '| alvo | Airbyte | 0m 02s | 2.7 GB | 2.0 GB | 2 amostras, uma a cada 1,0 s (pausa de 1 s) |'
E       assert 1536 == 2048
FAILED tests/test_medicao.py::test_toda_conta_do_medidor_roda_sob_o_locale_c
FAILED tests/test_medicao.py::test_a_conversao_da_memoria_nao_depende_do_locale[C]
FAILED tests/test_medicao.py::test_a_conversao_da_memoria_nao_depende_do_locale[pt_BR]
3 failed, 2 passed, 26 deselected in 8.96s
```

Contra o novo, a suíte do medidor inteira: `31 passed in 40.31s`.

**Registros anteriores.** Há um só, `data/medicoes/2026-09-20_size_report.json`, citado no plano
(§3), com `conteineres_maximo_mb: 3961`. A linha dele saiu `2,7 GB | 3,9 GB`, com vírgula: pt_BR,
portanto subestimado. O arquivo de amostras é temporário, então a série bruta não existe, e corrigir
o número seria estimá-lo. Ficou marcado no plano como subestimado. Ele não sustentava decisão
nenhuma, e a tabela da Capacidade é medida em B5, com o medidor corrigido. As leituras reais das
rodadas anteriores (3.222 e 3.317 MB, na §3 deste dossiê) também saíram sob pt_BR, e ficam no
histórico, onde nada as consome.

### 10.2 RVE3-02 — a retomada do Airbyte

**O cluster vivo, antes de tudo, só leitura.** O nó guarda os sandboxes das partidas anteriores
como `NotReady`, e alguns nunca saem, como o `bootloader` de duas semanas atrás. Recorte do
`crictl pods`, as duas últimas das 34 linhas:

```text
3fe11853b9856       2 days ago          NotReady            etcd-airbyte-abctl-control-plane                      kube-system          21                  (default)
fc5a1c2d717b4       2 weeks ago         NotReady            airbyte-abctl-bootloader                              airbyte-abctl        0                   (default)
```

O filtro exato do `crictl 1.32.0` existe, e é o que o preflight já usa na consulta de trabalho:

```text
--- --state Ready -q (contagem) ---
18
--- --state NotReady -q (contagem) ---
16
--- estado com letra minúscula ---
18
--- estado inválido ---
2026/09/23 23:08:06 --state should be ready or notready
rc=1
```

A API tem dois *health*, e só um diz se está disponível — `/api/public/v1/health`, depois
`/api/v1/health`:

```text
Successful operation http=200
{"available":true} http=200
```

**A decisão do Owner.** Consultado com três alternativas — a API responder; o sandbox pronto exato,
que é a correção literal do achado; os dois em sequência —, o Owner escolheu **a API responder**, e
autorizou pausar e retomar o Airbyte de verdade para medir.

**Ciclo 1, a receita antiga, real.** `make preflight ALVO=trabalho` → `nenhum trabalho em
andamento`; `docker/airbyte_jobs.sh ler` → `maior_job=43`; `make airbyte-pause`. No instante T0, a
sonda abaixo em segundo plano e `make airbyte-resume`. Na sonda, `antigo` diz se o `grep -q Ready`
da receita antiga casaria naquele instante. Recorte: cada sequência de estados iguais fica com a
primeira e a última linha, e "…" no meio; o corpo HTML do 503, de sete linhas, vira `<html 503>`.

```text
make airbyte-resume (receita antiga) saiu 0 em +5.6s
aguardando o cluster. pronto.
t=+   0.0s antigo=sem_resposta sandbox_ready=0   notready=0   k8s_airbyte_prontos=0/0    api= http=000
t=+   2.6s antigo=casa         sandbox_ready=0   notready=34  k8s_airbyte_prontos=0/0    api= http=000
t=+   5.1s antigo=casa         sandbox_ready=4   notready=19  k8s_airbyte_prontos=0/0    api= http=000
t=+  10.3s antigo=casa         sandbox_ready=14  notready=19  k8s_airbyte_prontos=0/8    api= http=000
t=+  13.3s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api= http=000
…
t=+  44.4s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api= http=000
t=+  47.2s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=4/8    api=<html 503> http=503
…
t=+  58.7s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=4/8    api=<html 503> http=503
t=+  61.8s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=5/8    api=<html 503> http=503
t=+  64.4s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+  67.0s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=6/8    api=<html 503> http=503
…
t=+  98.0s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+ 100.8s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=7/8    api={"available":true} http=200
…
t=+ 107.1s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=7/8    api={"available":true} http=200
fim: API disponível 3 vezes seguidas
```

A espera antiga disse "pronto" em 5,6 s. Em +2,6 s o `crictl` listava 34 sandboxes `NotReady` e
nenhum pronto, e o `grep` já casava. O primeiro sandbox pronto de fato veio em +5,1 s. A API não deu
resposta HTTP nenhuma até +44 s (`http=000`), o ingress devolveu 503 de +47 s a +98 s, e `available:true` chegou em
+100,8 s: a espera declarou pronto uns 95 s antes de o Airbyte servir.

**Ciclo 2, a receita nova, real.** `make preflight ALVO=trabalho` e `make airbyte-pause` de novo.
`make airbyte-up`, o chamador de B5, foi **recusado pelo preflight por memória**:

```text
make airbyte-up (receita nova) saiu 2 em +0.2s
[preflight] RAM disponível agora: 6,0 GB
[preflight] Já de pé: nada além dos bancos
[preflight] 'airbyte' custa ~4,9 GB — sobraria 1,1 GB

RECUSADO — sobraria menos que a folga mínima de 1,5 GB para o host.
```

Não forcei (`CLAUDE.md` §5). Devolvi o Airbyte ao estado em que o encontrei com
`make airbyte-resume`, o outro chamador da mesma variável, que não passa pelo preflight:

```text
make airbyte-resume (receita nova) saiu 0 em +95.7s
aguardando a API do Airbyte................... pronta.
t=+   0.0s antigo=sem_resposta sandbox_ready=0   notready=0   k8s_airbyte_prontos=0/0    api= http=000
t=+   2.6s antigo=casa         sandbox_ready=0   notready=21  k8s_airbyte_prontos=0/0    api= http=000
t=+   5.4s antigo=casa         sandbox_ready=4   notready=19  k8s_airbyte_prontos=8/8    api= http=000
t=+   9.2s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=1/8    api= http=000
t=+  12.3s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api= http=000
…
t=+  40.3s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api= http=000
t=+  43.1s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=4/8    api=<html 503> http=503
…
t=+  51.7s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=4/8    api=<html 503> http=503
t=+  54.5s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=5/8    api=<html 503> http=503
t=+  57.3s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=6/8    api=<html 503> http=503
…
t=+  62.4s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+  64.9s antigo=casa         sandbox_ready=18  notready=16  k8s_airbyte_prontos=6/8    api=<html 503> http=503
…
t=+  91.5s antigo=casa         sandbox_ready=18  notready=16  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+  94.1s antigo=casa         sandbox_ready=18  notready=16  k8s_airbyte_prontos=7/8    api=<html 503> http=503
t=+  96.6s antigo=casa         sandbox_ready=18  notready=16  k8s_airbyte_prontos=8/8    api={"available":true} http=200
…
t=+ 101.6s antigo=casa         sandbox_ready=18  notready=16  k8s_airbyte_prontos=8/8    api={"available":true} http=200
fim: API disponível 3 vezes seguidas
```

A receita disse "pronta" em +95,7 s. A sonda viu 503 em +94,1 s e `available:true` em +96,6 s: a
receita pegou a API no instante em que ela respondeu. **E o Kubernetes, em +5,4 s, dizia 8/8 pods
do Airbyte prontos** — estado de antes da pausa, que caiu para 1/8 em +9,2 s. A prontidão do
Kubernetes também não serviria de critério.

Depois, o ambiente como estava:

```text
maior_job=43 ultimo_valor=43 chamado=t sequencia=public.jobs_id_seq
{"available":true} http=200
mvp_ed1_legacy_db	Up 3 hours (healthy)
mvp_ed1_source_db	Up 3 hours (healthy)
mvp_ed1_warehouse_db	Up 3 hours (healthy)
airbyte-abctl-control-plane	Up About a minute
```

A sonda das duas retomadas (`LC_ALL=C` porque ela mesma faz conta com decimal):

```bash
#!/usr/bin/env bash
# Sonda da retomada do Airbyte: a cada ~2 s, desde T0 (epoch em $1), registra
#   - se o `grep -q Ready` da receita antiga casaria (antigo=casa|nao|sem_resposta);
#   - quantos sandboxes o crictl diz Ready e NotReady (filtro exato);
#   - quantos pods do namespace airbyte-abctl o Kubernetes diz prontos (READY n/n, sem Completed);
#   - o código e o corpo de GET /api/v1/health.
# Para depois de 3 respostas `available:true` seguidas, ou em $2 segundos.
# Só leitura.
export LC_ALL=C
T0="$1"; PRAZO="${2:-300}"
NO=airbyte-abctl-control-plane
seguidas=0
while :; do
	agora=$(date +%s.%N)
	t=$(awk -v a="$agora" -v b="$T0" 'BEGIN{printf "%.1f", a-b}')
	todos=$(timeout 5 docker exec "$NO" crictl pods 2>/dev/null); rc=$?
	if [ $rc -ne 0 ]; then antigo=sem_resposta; else
		printf '%s\n' "$todos" | grep -q Ready && antigo=casa || antigo=nao; fi
	prontos=$(timeout 5 docker exec "$NO" crictl pods --state Ready -q 2>/dev/null | grep -c . || true)
	naoprontos=$(timeout 5 docker exec "$NO" crictl pods --state NotReady -q 2>/dev/null | grep -c . || true)
	k8s=$(timeout 8 docker exec "$NO" kubectl get pods -n airbyte-abctl --no-headers 2>/dev/null \
		| awk '$3 != "Completed" { split($2, r, "/"); n++; if (r[1] == r[2]) p++ } END { printf "%d/%d", p, n }')
	corpo=$(curl -s --max-time 3 -w ' http=%{http_code}' http://localhost:8000/api/v1/health 2>/dev/null)
	printf 't=+%6ss antigo=%-12s sandbox_ready=%-3s notready=%-3s k8s_airbyte_prontos=%-6s api=%s\n' \
		"$t" "$antigo" "${prontos:-?}" "${naoprontos:-?}" "${k8s:-?}" "$corpo"
	case "$corpo" in *'"available":true'*) seguidas=$((seguidas + 1)) ;; *) seguidas=0 ;; esac
	[ "$seguidas" -ge 3 ] && { echo "fim: API disponível 3 vezes seguidas"; exit 0; }
	if awk -v t="$t" -v p="$PRAZO" 'BEGIN{exit !(t+0 > p+0)}'; then echo "fim: prazo de ${PRAZO}s"; exit 1; fi
	sleep 2
done
```

**A sonda E3-5, repetida.** O trecho reprodutível do revisor, sem mudança, contra a receita nova. Ela
não consulta mais o `docker exec`, e os rótulos `NotReady` e `vazio` deixam de importar: quem
responde é o `curl` simulado padrão de `_make`, que nunca diz nada, e a espera esgota nos quatro
casos. O 2 é o código com que o `make` sinaliza receita falhada, e o texto é a última linha da
saída:

```text
airbyte-resume NotReady 2   Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'.
airbyte-up NotReady 2   Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'.
airbyte-resume vazio 2   Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'.
airbyte-up vazio 2   Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'.
```

**Os testes novos contra o `Makefile` anterior.** `12 failed, 5 passed in 121.89s`: reprovam os dez
da retomada e os dois de comportamento reescritos. Os dois de comportamento sem `sleep` simulado
vencem pelo prazo de 60 s do teste, e daí os 121 s. O caso de prazo esgotado, literal: a receita
anterior imprimia "tempo esgotado", anunciava a interface e saía 0:

```text
>       assert r.returncode != 0, r.stdout
E       AssertionError: cluster pausado — retomando em vez de reinstalar
E         aguardando o cluster.............................. tempo esgotado — veja 'docker logs airbyte-abctl-control-plane'.
E         
E         Interface em http://localhost:8000 — credenciais em 'make airbyte-credentials'.
```

Contra o novo: `17 passed in 2.60s`, e `18 passed in 2.52s` com o teste do `curl` ausente.

**Achado próprio, na correção (`c58a3cd`).** A espera nova consulta a API por `curl` com
`2>/dev/null`. Numa máquina sem `curl`, o "command not found" sumiria ali, e as 60 consultas
venceriam dizendo que a API não respondeu. A receita passa a conferir o `curl` antes de religar
qualquer coisa. O teste roda com um `PATH` restrito ao que a receita usa além do `curl`. Contra
`d3a20df`, o `make` travou até o prazo do teste; contra o novo, recusa sem chamar o `docker start`:

```text
E           subprocess.TimeoutExpired: Command '['make', '--no-print-directory', 'airbyte-resume']' timed out after 60 seconds
```

### 10.3 `make check`

Sobre `9d856df`, recorte das linhas que resumem cada etapa. Os três `aviso:` são os mesmos de
sempre, da linhagem de `legacy_classifications` (§3):

```text
── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 107 documentos, 976 links de arquivo, 128 âncoras, 588 citações de ADR — nada quebrado
── 2/4 dbt build: modelos, testes de dados e reconciliações ──
23:46:03  Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
── 3/4 classificação derivada e linhagem em dia com os modelos ──
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
── 4/4 pytest: código, contratos e integração ──
484 passed, 8 skipped in 254.17s (0:04:14)
check: as quatro etapas passaram
real	6m31,169s
```

São 470 testes antes, mais 3 do medidor e 11 do `Makefile`. Depois do `check`, `6cf0118` mudou só
comentário, docstring e o id de um teste de `tests/test_makefile.py`: `18 passed in 2.60s`.

### 10.4 O que esta aplicação não verificou

- **`airbyte-up` retomando de verdade.** O preflight o recusou por memória. O ramo "pausado" só rodou
  com dublês, e a variável que ele chama é a que `airbyte-resume` rodou de verdade.
- **O prazo esgotando de verdade.** A API real respondeu em 96 e 101 s, e o caminho da falha só
  rodou com dublês. Os 300 s são três vezes duas amostras, tiradas com ~6 GB livres depois da pausa;
  sob mais pressão de memória, o tempo não foi medido.
- **O Kubernetes com estado velho** foi visto uma vez (ciclo 2, +5,4 s). No ciclo 1 a primeira
  leitura do Kubernetes, em +10,3 s, já dizia 0/8.
- **Máquina sem pt_BR.** O caso pt_BR do teste de locale é pulado lá, com o motivo escrito. Com o
  `gawk` no lugar do `mawk`, o defeito não existe, porque ele não segue o locale ao ler número;
  isso não foi testado.
- **O `_gb` do preflight** continua seguindo o locale na vírgula das mensagens. Nada lê número de
  volta dali, e ficou como estava.
- **O passo 8 de `recovery-restore` de ponta a ponta** continua de B5, com o resto da sequência.

### 10.5 Onde hesitei

- **Pronto é a API**, por decisão do Owner. `/api/v1/health`, e não `/api/public/v1/health`, porque
  a pública responde só "Successful operation", sem dizer se está disponível.
- **`grep -Eq '"available": *true'`** em vez de ler o JSON: o corpo medido é `{"available":true}`,
  e tolerar o espaço não custa nada. Qualquer outra forma falha fechada, com erro no prazo, e nunca
  aberta.
- **O prazo contado em consultas, e não no relógio**, como já era na receita antiga: é o que deixa
  os testes trocarem o `sleep` por um que não dorme. Cada consulta tem `--max-time 5`. Nos casos
  medidos, sem resposta e 503, ela volta na hora, mas no pior caso o prazo dobra. Por isso a
  mensagem de prazo esgotado dizia "5 min" na primeira versão, e agora diz "60 consultas, uma a cada
  5 s" (`9d856df`), com o teste conferindo que ela e o dublê contaram o mesmo.
- **O "~20 s" saiu do comentário geral da pausa, sem número novo no lugar:** a volta do *streaming*
  e do Airflow não foi medida nesta aplicação. O número medido fica onde a retomada do Airbyte é
  descrita.
- **Devolver o Airbyte com `airbyte-resume` depois da recusa do preflight.** Não é contornar a
  recusa: o preflight recusou subir o Airbyte pelo custo de pico de uma sincronização (5 GB), e
  nenhuma rodaria. Retomar devolveu a máquina ao estado de dois minutos antes, que o Owner autorizou
  pausar e retomar. Fica escrito para o Owner julgar.
- **A vírgula da tabela posta à mão** vai além da letra do RVE3-01, e é a mesma regra que o período
  já seguia.

## 11. O que a §10.4 deixou aberto, verificado depois — 23/09/2026

A pedido do Owner, com a memória liberada por ele: item a item, na ordem da §10.4. O que ainda
depende de outra autorização fica dito como tal.

### 11.1 `airbyte-up` retomando de verdade

`make preflight ALVO=trabalho` → `nenhum trabalho em andamento`; `airbyte_jobs.sh ler` →
`maior_job=43`; `make airbyte-pause`; `MemAvailable: 9028160 kB`. No instante T0, a sonda da §10.2
em segundo plano e, em sequência, o que o passo 8 da restauração faz: `make airbyte-up`,
`make recovery-airbyte-jobs` (só lê: o próximo job, 44, já nasce acima da captura retida, 43) e a
leitura autenticada da guarda de identidade (`GET /jobs`, a mesma que a sincronização do legado faz
antes do `POST`), por um alvo de uma linha passado em `--eval`, com as credenciais pela macro do
próprio `Makefile`:

```bash
make --no-print-directory --eval 'sonda-api: ; @set -a; . ./.env; set +a; $(CREDENCIAIS); .venv/bin/python -c "from mvp_ed1 import airbyte; from mvp_ed1.legacy import identidade; jwt = airbyte.token(); print(\"maior_job_conhecido pela API:\", identidade.maior_job_conhecido(lambda: airbyte.jobs(jwt)))"' sonda-api
```

```text
airbyte-up saiu 0 em +75.9s | recovery-airbyte-jobs saiu 0 em +77.5s | sonda-api saiu 0 em +81.7s
=== airbyte-up ===
[preflight] RAM disponível agora: 8,6 GB
[preflight] Já de pé: nada além dos bancos
[preflight] 'airbyte' custa ~4,9 GB — sobraria 3,8 GB
[preflight] OK
cluster pausado — retomando em vez de reinstalar
aguardando a API do Airbyte............... pronta.

Interface em http://localhost:8000 — credenciais em 'make airbyte-credentials'.
=== recovery-airbyte-jobs ===
[recovery] Airbyte: maior job 43, sequência public.jobs_id_seq em 43 (já usada) → próximo job 44; captura retida 43
[recovery] o próximo job já nasce acima da captura retida — nada a avançar
=== sonda-api ===
maior_job_conhecido pela API: 43
```

A sonda, com o mesmo recorte da §10.2:

```text
t=+   0.0s antigo=sem_resposta sandbox_ready=0   notready=0   k8s_airbyte_prontos=0/0    api= http=000
t=+   2.1s antigo=casa         sandbox_ready=0   notready=34  k8s_airbyte_prontos=0/0    api= http=000
t=+   4.6s antigo=casa         sandbox_ready=4   notready=19  k8s_airbyte_prontos=0/0    api= http=000
t=+   8.6s antigo=casa         sandbox_ready=10  notready=19  k8s_airbyte_prontos=0/8    api= http=000
t=+  11.5s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=2/8    api= http=000
t=+  14.4s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api= http=000
…
t=+  42.2s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api= http=000
t=+  45.1s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=3/8    api=<html 503> http=503
t=+  47.9s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=4/8    api=<html 503> http=503
t=+  50.7s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=4/8    api=<html 503> http=503
t=+  53.4s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+  56.1s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+  58.8s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=7/8    api=<html 503> http=503
t=+  61.2s antigo=casa         sandbox_ready=18  notready=19  k8s_airbyte_prontos=7/8    api=<html 503> http=503
t=+  63.7s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=7/8    api=<html 503> http=503
t=+  66.3s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=6/8    api=<html 503> http=503
…
t=+  71.7s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=6/8    api=<html 503> http=503
t=+  74.2s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=7/8    api={"available":true} http=200
…
t=+  79.1s antigo=casa         sandbox_ready=18  notready=18  k8s_airbyte_prontos=7/8    api={"available":true} http=200
fim: API disponível 3 vezes seguidas
```

O preflight aprovou (sobrariam 3,8 GB), a receita disse "pronta" em +75,9 s — a sonda viu
`available:true` em +74,2 s —, e os dois passos seguintes encontraram o banco interno e a API
autenticada de pé. Três retomadas, agora: 101 s (a primeira, sem a memória lida depois da pausa),
96 s com 6,3 GB livres e 74 s com 9,0 GB.

### 11.2 O prazo esgotando de verdade

`make`, `curl`, `sleep` e `docker` reais; só a URL da API trocada, por `AIRBYTE_WEB=` na linha de
comando (conferido antes, sem `make -n`: `--eval` que imprime a variável). O Airbyte estava de pé, e
o `docker start` da receita não mudou nada. Dois casos em paralelo — a porta sem ninguém ouvindo, e
um servidor que aceita a conexão e nunca responde:

```bash
#!/usr/bin/env bash
# O prazo da retomada esgotando de verdade: make, curl, sleep e docker reais;
# só a URL da API muda. O Airbyte está de pé, então o `docker start` da receita
# não muda nada. Dois casos em paralelo:
#   fechada   — porta sem ninguém ouvindo: o curl volta na hora;
#   buraco    — um servidor que aceita a conexão e nunca responde: cada consulta
#               gasta os 5 s do --max-time (o "pior caso" da §10.5).
S=/tmp/claude-1000/-home-doug-Projetos-mvp-ed1/a5300d4d-5d68-4ecc-813f-6ef3f76cde85/scratchpad
cd /home/doug/Projetos/mvp_ed1 || exit 1

python3 - <<'EOF' &
import socket, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 58322))
s.listen(256)
guardadas = []
while True:
    c, _ = s.accept()
    guardadas.append(c)   # aceita e nunca responde
EOF
BURACO=$!
timeout 3 tail -f /dev/null

_caso() {  # $1 = nome, $2 = porta
	local ini fim rc
	ini=$(date +%s.%N)
	make --no-print-directory airbyte-resume AIRBYTE_WEB="http://127.0.0.1:$2" > "$S/prazo_$1.txt" 2>&1
	rc=$?
	fim=$(date +%s.%N)
	LC_ALL=C awk -v a="$fim" -v b="$ini" -v rc=$rc -v n="$1" \
		'BEGIN{printf "%s: make saiu %d em %.1f s\n", n, rc, a-b}' >> "$S/prazo_$1.txt"
}
_caso fechada 58321 &
P1=$!
_caso buraco 58322 &
P2=$!
wait $P1 $P2
kill $BURACO 2>/dev/null
echo "fim dos dois casos"
```

```text
aguardando a API do Airbyte............................................................ tempo esgotado: a API não respondeu a 60 consultas, uma a cada 5 s.
  Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'.
make: *** [Makefile:302: airbyte-resume] Erro 1
fechada: make saiu 2 em 301.5 s
aguardando a API do Airbyte............................................................ tempo esgotado: a API não respondeu a 60 consultas, uma a cada 5 s.
  Veja 'docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl'.
make: *** [Makefile:302: airbyte-resume] Erro 1
buraco: make saiu 2 em 601.8 s
```

**301,5 s e 601,8 s**, erro nos dois. O segundo mede o "pior caso dobra" da §10.5, que era
argumento. E desmentiu a mensagem: "60 consultas, uma a cada 5 s" foi uma a cada ~10 s. É a
confusão entre pausa e período que o medidor já tinha corrigido. `5851d41` troca a cadência pelo
tempo que o bash contou (`a API não respondeu a 60 consultas em $SECONDS s.`), e o teste do prazo
confere o formato com `make` e bash reais.

### 11.3 Sob mais pressão de memória

Não induzi. O preflight só deixa `airbyte-up` passar com o custo (5.000 MB) mais a folga
(1.500 MB) livres depois da pausa, ~6,5 GB. O ciclo 2 foi recusado a 6,0 GB, e as retomadas de 96 s
e 101 s aconteceram nesse limite, com a carga normal da estação. Com o Airflow de pé, a pausa
deixaria ~7,5 GB livres, menos pressão que naquelas duas. Abaixo do limite só se chega por
`airbyte-resume`, que não passa por preflight, e medir isso é provocar o travamento que o R11
registra — é a D54.

### 11.4 O Kubernetes com estado velho

Visto uma vez em três retomadas: no ciclo 2, 8/8 em +5,4 s. Nos ciclos 1 e 3, a primeira leitura do
Kubernetes veio em +10,3 s e +8,6 s, já com 0/8. A janela é curta e nem sempre é pega; basta uma vez
para o critério não servir.

### 11.5 Máquina sem pt_BR, e outra implementação de `awk`

O caso pt_BR do teste pula, com o motivo, quando o locale falta (`_locale_instalado` trocado por um
que responde `False`):

```text
instalado de verdade: True | inexistente: False
pulou: pt_BR.UTF-8 não está instalado — o medidor não roda sob ele nesta máquina
```

O `gawk` não está instalado nesta máquina; não instalei pacote de sistema. O que há é o `mawk` e o
`busybox awk`:

```text
/bin/mawk 23
/etc/alternatives/awk /bin/awk
/etc/alternatives/awk /usr/bin/awk
/etc/alternatives/nawk /bin/nawk
/etc/alternatives/nawk /usr/bin/nawk
/usr/bin/mawk 23
/usr/bin/busybox
/usr/bin/nawk
/usr/bin/mawk
```

Então a afirmação sobre o `gawk` continua não verificada. O que importa ao projeto — que o resultado
não dependa da implementação — foi medido com as duas que existem. O medidor antigo (`78d0dcb`) e o
novo, com a entrada do revisor, trocando o `awk` do `PATH` por um que chama o `busybox awk`:

```text
busybox awk sob pt_BR, lendo "1.5": 1.5
medir.sh antigo (78d0dcb)  mawk        C            codigo 0 maximo_mb 2048 tabela '2.0 GB'
medir.sh antigo (78d0dcb)  mawk        pt_BR.UTF-8  codigo 0 maximo_mb 1536 tabela '1,5 GB'
medir.sh antigo (78d0dcb)  busybox awk C            codigo 0 maximo_mb 2048 tabela '2.0 GB'
medir.sh antigo (78d0dcb)  busybox awk pt_BR.UTF-8  codigo 0 maximo_mb 2048 tabela '2.0 GB'
medir.sh novo              mawk        C            codigo 0 maximo_mb 2048 tabela '2,0 GB'
medir.sh novo              mawk        pt_BR.UTF-8  codigo 0 maximo_mb 2048 tabela '2,0 GB'
medir.sh novo              busybox awk C            codigo 0 maximo_mb 2048 tabela '2,0 GB'
medir.sh novo              busybox awk pt_BR.UTF-8  codigo 0 maximo_mb 2048 tabela '2,0 GB'
```

O defeito era do `mawk`. O `busybox awk` não segue o locale nem para ler nem para escrever, e o
medidor novo dá o mesmo número e a mesma linha nas quatro combinações.

### 11.6 O `_gb` do preflight

Ninguém lê número de volta das mensagens dele — só o próprio `preflight.sh` as usa:

```text
docker/preflight.sh:323:_gb() { awk -v m="$1" 'BEGIN {printf "%.1f GB", m/1024}'; }
docker/preflight.sh:325:echo "[preflight] RAM disponível agora: $(_gb "$DISPONIVEL")"
docker/preflight.sh:331:echo "[preflight] '$ALVO' custa ~$(_gb "$CUSTO") — sobraria $(_gb "$PROJECAO")"
docker/preflight.sh:338:  RECUSA="sobraria menos que a folga mínima de $(_gb "$FOLGA_MINIMA") para o host"
docker/preflight.sh:418:  echo "[preflight] RAM disponível agora: $(_gb "$DISPONIVEL") — sobraria $(_gb "$PROJECAO")"
docker/preflight.sh:425:    RECUSA="mesmo depois de pausar $(IFS=' e '; echo "${PAUSADOS[*]}"), sobraria menos que a folga mínima de $(_gb "$FOLGA_MI
```

`docker/preflight.sh airbyte`, só leitura, sob C e sob pt_BR, com o Airbyte de pé — a mesma decisão,
e só o separador muda (o 0.3 contra 0,2 é a memória que oscilou entre as duas execuções; a decisão
é uma conta inteira em MB, no bash):

```text
C: rc=1
pt_BR: rc=1
1c1
< [preflight] RAM disponível agora: 5.1 GB
---
> [preflight] RAM disponível agora: 5,1 GB
3c3
< [preflight] 'airbyte' custa ~4.9 GB — sobraria 0.3 GB
---
> [preflight] 'airbyte' custa ~4,9 GB — sobraria 0,2 GB
5c5
< RECUSADO — sobraria menos que a folga mínima de 1.5 GB para o host.
---
> RECUSADO — sobraria menos que a folga mínima de 1,5 GB para o host.
```

E a suíte do preflight nos dois:

```text
C            33 passed in 18.41s
pt_BR.UTF-8  33 passed in 18.54s
```

### 11.7 O passo 8 de `recovery-restore` de ponta a ponta

Não rodado: é de B5, que restaura os dumps sobre os bancos de trabalho e sincroniza com `RESET=1`, e
exige autorização própria. A parte dele que o RVE3-02 toca — o que vem logo depois de `airbyte-up` e
só lê — rodou de verdade, na 11.1.

### 11.8 Duas pendências que a verificação levantou

Anteriores a esta entrega, e nenhuma mudada por ela; registradas em `docs/pendencias.md` §1 com as
alternativas, para decisão do Owner:

- **D53** — o preflight de `airbyte-up` cobra de novo o Airbyte que já está de pé. A recusa da
  11.6 é ela: 5,1 GB livres com o Airbyte rodando, "sobraria 0,3 GB". É a conta dupla que o pacote
  tinha (`5e32d0d`).
- **D54** — ao pausar, o preflight manda retomar por `make *-resume`, e os três religam sem conferir
  memória nem conflito. Retomar o Airbyte com o *streaming* de pé põe as duas famílias juntas.

### 11.9 `make check`

Sobre `5851d41`, com os documentos desta seção na árvore:

```text
── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 107 documentos, 977 links de arquivo, 128 âncoras, 589 citações de ADR — nada quebrado
── 2/4 dbt build: modelos, testes de dados e reconciliações ──
00:18:44  Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
── 3/4 classificação derivada e linhagem em dia com os modelos ──
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
── 4/4 pytest: código, contratos e integração ──
484 passed, 8 skipped in 249.28s (0:04:09)
check: as quatro etapas passaram
real	6m27,127s
```

## Achados da revisão

Um achado por linha, com veredito. Os dois são remanescentes reproduzidos também na base;
as cinco correções anteriores permanecem confirmadas conforme §9.1.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVE3-01 | `docker/medir.sh:61–72` | **A conversão da memória ainda depende do locale e subestima leituras válidas.** Com `LC_ALL=pt_BR.UTF-8`, as entradas `1.5GiB` e `512.5MiB` resultam em **1.536 MB**, contra **2.048 MB** sob `C`, com código 0 e nenhuma falha. O `awk` da coleta interpreta o ponto conforme a localidade; o `LC_ALL=C` acrescentado à agregação não recupera a fração perdida antes. Isso impede usar o medidor como evidência de capacidade de B5 nesse ambiente (P5). Fixar a localidade numérica da conversão e testar a mesma entrada decimal sob `C` e `pt_BR.UTF-8`; conferir a necessidade de remedir registros anteriores, sem estimar números. **E3-4.** | `bloqueante` | **Corrigido** (`4921289`). Todo `awk` do medidor roda sob `LC_ALL=C` — leitura, soma e agregação —, e `_gb` põe a vírgula da tabela à mão, como o período já fazia. Sonda E3-4 repetida: 2.048 MB sob C, C.UTF-8 e pt_BR.UTF-8, com a mesma linha nos três. Contra o Docker real, sob pt_BR: 3.879 MB, entre leituras diretas de 3.878 e 3.882 MB somadas sob C. A mesma leitura real, somada sob pt_BR, perdia 733 MB (3.271 contra 4.004). **Achado próprio:** a linha da tabela também mudava de forma com o locale (`2.2 GB` sob C), e por isso o teste do RVE2-02 que recusava `0.0 GB` era vazio sob pt_BR; ele passa a recusar `0,0 GB`. Registros anteriores: há um só, o `size-report` de 20/09, com 3.961 MB, citado no plano §3. Ele saiu sob pt_BR e ficou marcado no plano como subestimado, sem estimativa de correção, porque a série bruta não existe. Nada o consome, e a Capacidade é medida em B5. Testes: `test_toda_conta_do_medidor_roda_sob_o_locale_c` (a regra, lida do texto) e `test_a_conversao_da_memoria_nao_depende_do_locale[C, pt_BR]` (o efeito, com a entrada do revisor). Os três reprovam o medidor anterior. §10.1. **Verificado depois (§11.5):** com o `busybox awk` no lugar do `mawk`, o medidor novo dá o mesmo número e a mesma linha; o `gawk` não está instalado. |
| RVE3-02 | `Makefile:277–280` (`RETOMAR_AIRBYTE`) | **A espera da retomada anuncia sucesso sem observar prontidão.** `grep -q Ready` aceita uma linha `NotReady` e imprime `pronto`; se nenhuma linha casar nas 30 tentativas, o último `echo` também devolve 0. As duas formas afetam `airbyte-resume` e o ramo de retomada de `airbyte-up`, permitindo que chamadores prossigam mesmo sem a condição que o alvo promete esperar. Reconhecer o estado `Ready` de forma exata e sair com erro ao esgotar o prazo; cobrir `NotReady`, consulta sem resposta útil e timeout nos dois chamadores. Preservar a correção de `make -n`. **E3-5.** | `ajuste` | **Corrigido** (`d3a20df`, `c58a3cd`, `9d856df`, `5851d41`). Por decisão do Owner, pronto é `GET /api/v1/health` responder `available:true`, que é o que os passos seguintes usam. Medido em duas pausas reais, autorizadas: a espera antiga disse "pronto" em 5,6 s, com 34 sandboxes `NotReady` e nenhum pronto, e a API respondeu em 101 s e em 96 s. Nem o sandbox exato (pronto em ~5 s) nem a prontidão do Kubernetes (8/8 aos 5 s, estado de antes da pausa) serviriam. O prazo é de 60 consultas a cada 5 s, três vezes o medido; esgotado, sai com erro nos dois chamadores, e `airbyte-up` não anuncia a interface. Numa retomada real, a receita nova disse "pronta" em 95,7 s, junto com a API. O `airbyte-up` real foi recusado pelo preflight por memória, e não foi forçado. Sonda E3-5 repetida: os quatro casos saem 2. **Achado próprio:** sem `curl`, o `2>/dev/null` engoliria o "command not found", e a espera venceria dizendo que a API não respondeu; a receita passa a conferir o `curl` antes de religar (`c58a3cd`). O "~20 s" que a Execução Local dava para a volta tinha saído da espera defeituosa, e foi trocado pelo medido. `make -n` continua sem executar nada, e agora vigia também o `curl`. Testes: dez da retomada (os dois chamadores × pronta na primeira; pronta depois de ficar sem resposta e de 503; sem resposta; 503; `available:false`) e o do `curl` ausente, todos reprovando a receita anterior. §10.2. **Verificado depois (§11):** `airbyte-up` real, com o preflight aprovando, disse "pronta" em 75,9 s, e os dois passos seguintes do passo 8 acharam banco e API de pé; o prazo esgotou de verdade em 301 s e, no pior caso, 602 s — e a mensagem passou a dizer o tempo contado (`5851d41`). |
