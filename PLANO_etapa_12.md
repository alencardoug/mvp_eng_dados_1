# Plano — Etapa 12: fechamento da fase local (M5)

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item, como o plano de fechamento da Etapa 10 saiu. Escrito em 18/09/2026
> sobre `179b80a` (`main`, Etapa 11 aceita), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: **[medido]** tem saída de comando por trás; **[planejado]** é intenção. Os
> dois não se misturam (P5).
>
> **Revisão 2 — 18/09/2026.** As quatro decisões da primeira versão (D45–D48) foram tomadas pelo
> Owner antes de o plano ir à revisão.
>
> **Revisão 3 — 18/09/2026, mesma data.** Aplica o parecer do outro agente (§13: cinco
> bloqueantes, quatro ajustes, e as observações da §13.3). O que mudou de forma: o pacote de
> recuperação passou a guardar a **memória do armazém** (D49, decidida pelo Owner sobre o
> RV12-01); a restauração ganhou sequência própria (RV12-02); "do zero" passou a desmontar as
> três composições, não só os bancos (RV12-03); o *streaming* entra **antes** do primeiro
> `dbt-build` completo (RV12-04); a varredura do histórico não depende dos valores atuais
> (RV12-05); `FORCE` não atravessa o *restore* (RV12-06); o clone prepara `.tools/` e `dbt deps`
> (RV12-07); cada cenário tem início e fim declarados (RV12-08); `RECOVERY_DIR` é absoluto e o
> pacote leva os oráculos (RV12-09). A coluna *Situação* da §13.1 diz onde cada um foi parar.
>
> **Revisão 4 — 18/09/2026, mesma data.** Aplica a segunda rodada do parecer (§14: cinco
> bloqueantes, um ajuste). O que mudou de forma: a reconstrução depois do *restore* **não** derruba
> os *snapshots* e o manifesto passa a ter o oráculo das versões SCD (RV12-2-01); a identidade da
> captura ganha guarda e regra operacional — **D50**, decidida pelo Owner (RV12-2-02); o preflight
> passa a reconhecer os contêineres pelos rótulos do Compose — defeito **vivo hoje**, não só no
> clone, e vira o bloco **B0** (RV12-2-03); o clone roda `check-offline`, não `check`, antes dos
> bancos (RV12-2-04); o detector histórico cobre ENV, YAML e JSON e não dispensa arquivo por
> extensão (RV12-2-05); o corte do *streaming* é tirado **depois** do produtor e o medidor declara
> como conduz processos concorrentes (RV12-2-06). §14.1 e §14.2 ganharam a coluna *Situação*.

---

## 0. Onde estamos **[medido]**

- Etapas 0–11 aceitas; **M0–M4** concluídos. `main` em `179b80a`, 158 *commits*, publicado.
- `make check` verde em 18/09/2026: `dbt build` `PASS=905`, classificação 2.983/2.983 colunas em
  199 nós, linhagem em dia, `pytest` **291 passed, 8 skipped** (3 min 52 s só o pytest; o
  `check` inteiro entre 4 min 27 s e 6 min 34 s conforme a carga da máquina).
- DAG `fluxo_batch`: 13 tarefas `success` em **7 min 58 s** (18/09, 06:34–06:42 UTC), **captura
  43 certificada e selecionada**; os três estados da origem regenerada reconciliados (13.700
  movimentos nos dois caminhos).
- O que o armazém guarda e nenhuma reconstrução reproduz (§13.2, leitura em 18/09): **11
  capturas completas** nas 40 tabelas (`snapshot_id` 28–43) com os certificados em
  `governance.legacy_captures`; `trusted.legacy_removed_records` com **4** registros, três deles
  clientes (`1`, `2`, `3`) que a origem legada **já não tem** — a memória de exclusões do
  [ADR-0045](docs/adr/0045-detectar-exclusao-fisica-do-legado-no-bruto-retido.md), derivada das
  capturas retidas; os *snapshots* SCD (`dbt_project.yml` os declara não reconstruíveis). Versões
  do armazém: `governance._versions` = `0001_legacy_captures`, `0002_snapshot_id_e_o_job`.
- Máquina: 11,5 GB de RAM, 4 CPUs; ambiente de trabalho consome ~4 GB
  ([Capacidade §2.8](docs/capacidade_e_recuperacao.md)). Com Airbyte, Airflow e os três bancos de
  pé: 3 GB disponíveis.
- **Nenhuma *tag* no Git.** Nenhum pacote de recuperação jamais montado.
- `secrets_review` compara o rastreado com **os valores do `.env` atual** mais cinco formas
  genéricas; não tem detector geral de atribuição, não varre o histórico (§13.2: senha fictícia
  removida e rotacionada → 0 casamentos no *blob* antigo).
- Links e âncoras dos documentos são conferidos a olho.
- Uma cópia dos arquivos rastreados **sem caches** não passa em `dbt parse`: faltam `dbt_utils`,
  `dbt_date`, `dbt_expectations` — `make install` não roda `dbt deps` (§13.2).
- `make reset` remove **só os três volumes PostgreSQL** (`docker-compose.yml`); `redpanda_data`
  (tópicos, *offsets* do Connect) e os volumes do Airflow são de outras composições e sobrevivem;
  `COMPOSE_PROJECT_NAME` é o mesmo em qualquer clone.
- `stg_retail__inventory_movements.sql` lê `raw.inventory_movements_stream` **incondicionalmente**,
  e quem cria essa tabela é o *sink* do Beam; `caminhos_de_ingestao_reconciliam.sql` reprova
  movimento que só chegou pelo lote. Num armazém vazio, `dbt-build` antes do *streaming* falha —
  e a [Execução Local §3](docs/execucao_local.md#3-ciclo-completo) lista `dbt-build` (6) antes de
  `stream-up` (7).
- **O preflight não vê o Airflow — hoje.** Os contêineres chamam-se `mvp_ed1-airflow_scheduler-1`,
  `…-apiserver-1`, `…-dag_processor-1` (nomes gerados pelo Compose; a composição do Airflow não
  declara `container_name`), e `docker/preflight.sh` procura `^airflow_` e executa
  `docker exec airflow_scheduler` literal: `AIRFLOW_NO_AR` é sempre `false`, `make stream-up` não
  pausa nem consulta o Airflow, e a mitigação do **R11** está furada para ele desde que existe
  (§14.3 simulou; `docker ps` desta máquina confirma os nomes). Os testes de preflight usam nomes
  sem prefixo.
- `make dbt-build RESET=1` chama `dbt-drop-snapshots` (`drop schema snapshots cascade`) antes do
  `--full-refresh` — certo para regenerar a origem, **errado depois de um *restore*** (§14.3).
- `make check` chama `dbt-build` (que começa por `governance.garantir`, no armazém) antes do
  pytest: sem banco, para na etapa 2 e o pytest nem roda (§14.3).
- A identidade da captura do legado é o `job_id` do Airbyte (`snapshot_id = _airbyte_meta.sync_id`,
  `CAPTURA_SQL`); a seleção padrão é `max(snapshot_id)`. Um Airbyte reinstalado recomeça em 1:
  com 43 retida e 3 nova, o SQL real escolheu 43; número reutilizado mistura linhas e a
  certificação decide `incomplete` (§14.3).
- O contrato do evento tem **17** campos: `movement_id` (chave) + 16 (`COLUNAS_DO_EVENTO`).
- `kind` não está no PATH nem é instalado por `make tools`; o nó do cluster do Airbyte é o
  contêiner `airbyte-abctl-control-plane`, cujo nome não contém `mvp_ed1`.
- `airbyte/terraform.tfstate` (4 ocorrências de `password`) e `data/` estão ignorados pelo Git.
- Artefatos locais fora do Git que os oráculos usam: `data/legacy/manifesto.json` (2 mutações
  abertas, 1 diário encerrado) e `.stream/producer_state.json` (cursor do produtor).

---

## 1. O que a etapa exige, e o que falta

| # | Critério | O que existe | O que falta |
|---|---|---|---|
| C1 | Todos os critérios de sucesso do Termo verificados **em ambiente limpo** | Tudo roda nesta máquina, sobre volumes que existem desde a Etapa 2 | "Limpo" definido (D45, completado pelo RV12-03): executar a Execução Local §3 do zero, mapeando cada critério do Termo a um comando e uma saída |
| C2 | Cada cenário da [§5](docs/execucao_local.md#5-executando-por-partes) no seu subconjunto, com **tamanho, tempo e pico de memória** | Tempo e tamanho caso a caso; pico só em episódios | Um instrumento por alvo, com **início e fim declarados**, e uma tabela única na Capacidade |
| C3 | Cobertura integral conferida | `tests/test_cobertura.py`; manifesto do legado (74/74, 12.747 vereditos) | Rodar do zero, com os oráculos que correspondem ao dado, e citar |
| C4 | Restauração do ponto de recuperação testada, incluindo o *re-snapshot* | A especificação (Capacidade §3), escrita **antes** dos ADRs 0037/0044/0045 | O pacote com a memória do armazém (D49), a sequência de restauração, os oráculos explícitos |
| C5 | Documentação coerente com o código | Revisão a olho | Verificador de links/âncoras; e a Execução Local já tem **quatro** desvios conhecidos (ordem `dbt-build`/`stream-up`, `dbt deps`, `.tools/`, o preflight que não vê o Airflow) a corrigir antes de servir de roteiro |
| C6 | Nenhum segredo no repositório **nem no histórico** | `secrets_review` sobre o rastreado, dependente do `.env` atual | Detecção independente dos valores, sobre todo *blob*, com os limites declarados e os achados tratados (D48) visíveis |
| — | Versão marcada no Git | Nenhuma *tag* | `v1.0.0` (D47) no *commit* que fecha M5 |

Tudo o que falta é **instrumento** (C2, C5, C6), **produto** (C4) ou **execução** (C1, C3).
Nenhum ADR novo: D49 muda o conteúdo do pacote como **consequência** de ADRs aceitos, e é a
Capacidade §3 que passa a dizer isso.

---

## 2. Ordem, e por quê

```
B0 preflight por rótulos (defeito vivo do R11)
        │
B1 medição ─┐
B2 segredos ├─► B4 pacote (fontes + memória do armazém,  ─► B5 do zero (desmonta as três ─► B6
B3 docs ────┘      do estado ATUAL, em janela parada)         composições; ciclo medido)
```

0. **B0 antes de tudo**: o preflight não reconhece o Airflow **hoje** (§0) — é a mitigação do
   R11 furada nesta máquina, não um problema do clone. Todo bloco seguinte que troca de ambiente
   depende dele; e o `medir` de B1 usa a mesma detecção.
1. **B1, B2, B3 depois, em qualquer ordem** — código local, sem ambiente pesado; B1 mede B4 e
   B5; B2 e B3 entram no `make check` que B5 roda.
2. **B4 antes de B5**: o pacote guarda o estado **atual** — as fontes e a memória do armazém
   (D49) — e B5 destrói as três composições. O destino do estado permanente antes do `reset` é o
   pacote; o que o pacote não leva está listado na §6 como limite, não descoberto depois.
3. **B5 é o bloco caro** (~2 h de trocas, mais sincronizações e *snapshot*).
4. **B6 por último**: estado se documenta depois de medido.

---

## 2.1 B0 — o preflight reconhece o que o Compose cria

**O que existe [medido].** `preflight.sh` e os pares `*-pause`/`*-resume` acham contêineres por
prefixo de nome (`^airflow_`, e os `container_name` fixos dos bancos e do streaming); a consulta
de trabalho do Airflow é `docker exec airflow_scheduler …`. Os contêineres do Airflow têm o nome
gerado pelo Compose (`<projeto>-<serviço>-<n>`). Resultado: Airflow invisível para o preflight.

**O que muda [planejado].** Resolução por **rótulos do Compose**, em todos os consumidores —
detecção, consulta de trabalho, pausa, retomada e inventário:

```
docker ps --filter label=com.docker.compose.project=$COMPOSE_PROJECT_NAME \
          --filter label=com.docker.compose.service=airflow_scheduler --format '{{.Names}}'
```

com `COMPOSE_PROJECT_NAME` lido do `.env` (é o que o clone também usa). O mesmo para o streaming
e os bancos — os `container_name` fixos continuam existindo, mas deixam de ser o critério. O
Airbyte continua reconhecido pelo nó `airbyte-abctl-control-plane` (nome do `abctl`, declarado).
A consulta de trabalho passa a `docker exec <nome resolvido> …`, e "não resolveu" continua
contando como bloqueio (regra da Execução Local §5).

**Prova.** `tests/test_preflight.py` ganha os casos com os **nomes gerados pelo Compose**
(`mvp_ed1-airflow_scheduler-1`) e com projeto de outro nome: detecção, pausa, retomada, consulta
com DAG em execução → recusa. Contraprova na máquina: com Airflow de pé e uma DAG rodando,
`make preflight ALVO=streaming` **recusa**; com Airflow de pé e ocioso, `make stream-up` **pausa**
o Airflow e o `airflow-resume` o retoma — as duas saídas no dossiê.

---

## 3. B1 — o instrumento de medição

**O que existe [medido].** `docker/preflight.sh` lê `MemAvailable`; `make size-report` dá tamanho
por banco/tabela; tempos vêm de `time` à mão ou do Airflow. `dag-run` só **dispara**;
`dag-status` só **consulta**; `stream-run` e `dbt-docs` ficam em primeiro plano sem fim natural.

**O que muda [planejado].** `make medir ALVO=<alvo> [ATE=<alvo de espera>]` (`docker/medir.sh`):

- executa `ALVO`; se `ATE` for dado, **continua amostrando até `ATE` terminar** — é o que separa
  "disparei" de "rodou". Grava início, fim, duração, código de saída e se foi interrompido;
- amostra a cada 2 s: `MemAvailable` do *host* e a soma de `docker stats --no-stream`; guarda o
  **mínimo disponível** e o **máximo dos contêineres**, com o instante, **o intervalo e o número
  de amostras** — são extremos **amostrados**, não garantia de pico; e o mínimo de
  `MemAvailable` inclui a estação inteira, enquanto a soma dos contêineres **não inclui o Beam nem
  o produtor**, que rodam no *host* — os dois números são registrados lado a lado por isso;
- registra o estado da estação no início (`MemAvailable`, o que está de pé segundo o preflight,
  `/proc/loadavg` como observação);
- ao fim, `make size-report` e o total por banco;
- escreve `data/medicoes/<data>_<alvo>.json` e imprime a linha da tabela da Capacidade.

Três alvos de espera novos, usados por B5 e pela documentação:

| Alvo | Termina quando | Falha quando |
|---|---|---|
| `dag-wait RUN_ID=` | o `run_id` chega a estado terminal (`success`/`failed`). `dag-run` passa a **capturar e imprimir o `run_id`** do `airflow dags trigger` (hoje descarta) e a gravá-lo em `data/medicoes/ultimo_run_id`; `dag-wait` sem `RUN_ID=` lê esse arquivo | prazo (`PRAZO=`, padrão 30 min) ou `failed` — o código propaga |
| `stream-wait ATE_SEQ=` | o livro (`raw.inventory_movements_stream`) tem **todas** as chaves da origem com `event_sequence ≤ ATE_SEQ` | prazo, ou o *pipeline* morreu |
| `docs-generate` | `dbt docs generate` termina (o servir sai da medição; a prova de que responde é um `curl` no diário) | — |

**O corte do *streaming* é tirado depois do produtor, nunca antes (RV12-2-06):** no cenário do
*snapshot* (sem produtor), `ATE_SEQ` = `max(event_sequence)` da origem no início, que não muda;
no cenário de eventos novos, `ATE_SEQ` é lido da origem **depois** de `stream-produce` terminar —
é o único corte que prova que os eventos novos chegaram, e não só o *snapshot*.

**Como o medidor conduz processos concorrentes** — o `stream-run` não termina sozinho, então
`medir` tem um modo de cenário, `make medir CENARIO=streaming [LIMITE=n]`, que: (1) sobe
`stream-up` (preflight ativo); (2) inicia `stream-run` **em segundo plano, sob a sua guarda**,
com o PID anotado; (3) se `LIMITE` for dado, roda `stream-produce LIMITE=n` em primeiro plano e
espera terminar; (4) lê o corte da origem **agora**; (5) `stream-wait ATE_SEQ=<corte>`; (6) encerra
**só o que iniciou** (SIGINT ao Beam, espera o encerramento limpo, SIGKILL depois do prazo, tudo
registrado); (7) propaga falha, prazo ou interrupção (Ctrl-C mata o que iniciou e sai com código
próprio). Amostra do início ao fim. A linha *Streaming* de B5 é este modo — e é por ele que a
troca seguinte para `airbyte-up` encontra o Beam encerrado.

Duas durações ficam registradas onde há invólucro: a do **invólucro** (`medir`, que inclui
disparo, fila e espera) e a do **trabalho** (`end_date − start_date` da DAG; ou do primeiro ao
último evento gravado no livro) — o revisor da rodada 2 pediu a diferença explícita.

**Prova.** `tests/test_medicao.py`: o amostrador acha o mínimo e o máximo numa série sintética e
reporta intervalo e contagem; a linha gerada é a da tabela; `ALVO` inexistente falha antes de
amostrar; `ATE` que falha propaga o código; no modo de cenário, um processo filho que morre
propaga, e o encerramento mata só os PIDs anotados; `stream-wait` com produtor terminado e o
último evento ainda pendente **continua esperando** até o evento chegar ou o prazo vencer (a
contraprova da rodada 2); *snapshot* sem produtor fecha no corte inicial. Sem banco. **Oráculos
do bloco**, em B5: a duração de `make medir ALVO=dbt-build` é **maior** que a do
`run_results.json` (o alvo inclui `governance.garantir` e a inicialização do dbt) e a diferença é
registrada, não tolerada por um ±5 s fixo; a duração de invólucro de `dag-run` + `dag-wait` é
maior que a da DAG, e as duas ficam na tabela.

---

## 4. B2 — segredos no histórico

**O que existe [medido].** `mvp_ed1.secrets_review`: compara o rastreado com os **valores** do
`.env` atual (`secret_values(read_env())`) e com cinco formas genéricas (chave privada, `AKIA`,
`ghp_`, `xox`, `private_key_id`); acusa `.env` no índice. Depois de uma rotação, o valor antigo
não é mais conhecido → o *blob* antigo não casa com nada (§13.2). D45 troca o `.env` antes da
validação final: o modo atual seria cego exatamente onde a etapa exige enxergar.

**O que muda [planejado].** `python -m mvp_ed1.secrets_review --historico`, com detecção
**independente dos valores atuais** — uma declaração nova, ao lado das existentes:

- **atribuições, nas três formas em que este repositório escreve chaves** — ENV (`CHAVE=valor`),
  YAML (`chave: valor`) e JSON (`"chave": "valor"`, a dos conectores e do `tfstate`):
  `(?i)["']?[a-z0-9_.-]*(password|passwd|secret|token|api[_-]?key|private[_-]?key|credential)[a-z0-9_.-]*["']?\s*[=:]\s*["']?(?P<valor>[^\s"',]{8,})`
  — a aspa que **fecha** a chave é aceita, a caixa é ignorada, e o valor para na aspa ou na
  vírgula; **credencial em URL**: `://[^/:@\s]+:[^@\s]+@`; mais as cinco formas genéricas. A
  contraprova da rodada 2 (`{"password": "…"}` → 0 casamentos) é um caso de teste;
- **placeholders declarados por *valor***, não por arquivo: vazio, `<…>`, `${…}`, `{{ … }}`,
  `changeme`, `example`, `xxx…`, `***` — cada um numa lista no módulo, com o motivo. **Nenhuma
  extensão dispensa varredura**: um segredo real gravado num `*.example` num *commit* antigo é
  achado como qualquer outro; a exigência de `.env.example` **sem valores** continua sendo
  conferida pelo modo rastreado;
- percorre `git rev-list --all --objects`, lê cada *blob* uma vez (`git cat-file --batch`);
  *blobs* binários e maiores que 5 MB são **listados** (objeto, caminho, motivo), não só
  contados: pulado não é "verificado";
- confere que `.env` nunca foi rastreado (`git log --all --diff-filter=A -- .env` vazio);
- imprime cada achado como `commit  caminho:linha  CHAVE=ab***` — dois caracteres do valor e
  o tamanho, **nunca o valor**;
- **achados tratados (D48)**: `docs/segredos_tratados.yml` (ou seção da Governança — dono
  documental a fixar em B6) lista `commit`, `caminho`, `chave`, `tratamento` (rotacionado em …)
  e `motivo`; o modo `--historico` os imprime como **tratado** e não falha por eles. É assim que a
  frase da §7 ("nada encontrado") convive com D48: o veredito é "nada **não tratado**".

Não entra no `make check` (o histórico só cresce); entra na definição de pronto e no dossiê,
com a saída colada. O modo rastreado **também** ganha os detectores novos, com os mesmos
placeholders — uma declaração, dois alcances.

**Prova.** `tests/test_secrets_review.py` ganha, sobre um Git temporário: (1) senha fictícia
gravada em arquivo rastreado e no `.env`, *commit*; arquivo removido **e senha rotacionada**,
*commit* — o modo rastreado passa, o histórico acusa **sem conhecer o valor**; (2) *token* com
forma genérica (`ghp_…`) num *blob* antigo; (3) placeholder em `.env.example` não acusa; (4) o
achado listado como tratado sai como tratado e o código é 0; (5) *blob* grande aparece na lista
de pulados; (6) a mesma senha fictícia em ENV, YAML e **JSON**, removida e rotacionada, é achada
nas três formas; (7) segredo real num `config.example.yml` de um *commit* antigo é achado.

---

## 5. B3 — coerência dos documentos, por ferramenta

**O que muda [planejado].** `python -m mvp_ed1.docs_check` (e `make docs-check`, na etapa 1 do
`make check`):

- link relativo → arquivo existe; âncora → título existe no alvo, com a regra de *slug* do GitHub
  (minúsculas; espaços → `-`; pontuação removida; acentos mantidos; **títulos repetidos** ganham
  `-1`, `-2`; títulos **dentro de blocos de código** não contam); **links por referência**
  (`[x]: caminho`) e **fragmentos codificados** (`%C3%A7`) são resolvidos;
- `ADR-00nn` citado → arquivo em `docs/adr/`;
- blocos gerados não são tocados (isso é do `--check` de cada gerador);
- imprime o total de links e âncoras conferidos, e cada quebrado com arquivo:linha.

**Limite declarado:** verifica caminhos, não prosa. "Coerente com o código" é o que B5 prova
executando a Execução Local linha a linha — e a lista de desvios já começa com três (§0).

**Prova.** Testes com arquivos temporários: link bom, quebrado, âncora com acento, título
repetido, título em bloco de código, link por referência, fragmento codificado. A primeira
execução sobre o repositório real é medição: número de links, e o que achar se corrige antes de
B5.

---

## 6. B4 — o ponto único de recuperação

**O que existe [medido].** [Capacidade §3](docs/capacidade_e_recuperacao.md#3-ponto-único-de-recuperação):
dois *dumps* (`pg_dump -Fc`), *checksums*, `seed`/`as_of_date`/versões, último `event_sequence`,
*commit*, manifesto com contagens, instruções. "O `warehouse_db` **não** entra" (§3.3). Escrita
antes dos ADRs 0037, 0044 e 0045, que fizeram do armazém guardião de memória (§0).

**O que muda — D49 [decidido].** O pacote guarda as **fontes** e a **memória do armazém**:

| Conteúdo | Por quê | Como |
|---|---|---|
| `source_db.dump`, `legacy_db.dump` | as fontes, como antes | `pg_dump -Fc` pelos contêineres |
| `warehouse_memoria.dump` = schemas **`raw_legacy`**, **`governance`**, **`snapshots`** | capturas retidas com certificados (ADR-0037/0044), de onde a memória de exclusões (ADR-0045, `trusted.legacy_removed_records` é `table`, rebuildable a partir delas) renasce; histórico SCD (não reconstruível) | `pg_dump -Fc -n raw_legacy -n governance -n snapshots` |
| `data/legacy/manifesto.json` e o diário | os oráculos do dump do legado — sem eles os testes pulam ou usam o manifesto de outra geração (RV12-09) | copiados, com *checksum* |
| `.stream/producer_state.json` | o cursor do produtor que corresponde ao livro | copiado; a regra: restaurar o livro restaura o cursor |
| `manifesto.json` | `seed`, `as_of_date`, `alembic current` dos **dois bancos de origem**, `governance._versions` do armazém (é o oráculo de versão dele — não há Alembic lá, e não haverá), `max(event_sequence)`, `git rev-parse HEAD`, contagens e tamanhos por tabela dos três *dumps*, hora do corte; **o oráculo SCD** (RV12-2-01): por *snapshot*, linhas, `count(distinct dbt_scd_id)` e o `md5` de `string_agg(dbt_scd_id ‖ dbt_valid_from ‖ dbt_valid_to order by …)`; **o oráculo das capturas**: `max(snapshot_id)` retido e a lista de `snapshot_id` certificados | gerado |
| *checksums* de tudo; `RESTAURAR.md` com os comandos exatos | | gerado |

**Fora do pacote, por construção (o limite, escrito):** `raw` (o Airbyte refaz), `staging`,
`trusted`, `analytics`, `consumption`, `quarantine` (o dbt refaz), o cursor do CDC (§3.2, como
antes), o estado do Airbyte e do Airflow. Uma restauração devolve **as fontes e a memória**; o
resto é reconstruído e provado igual.

**O corte estável (RV12-02).** `recovery-pack` só roda em **janela parada**: confere, como o
preflight, que não há sincronização, DAG, Beam nem produtor; os três `pg_dump` e as contagens
do manifesto são tirados nessa janela, cada `pg_dump` consistente por si (é um *snapshot* de
transação) e as contagens numa transação `repeatable read` por banco no mesmo instante.
Trabalho em andamento → recusa, como o preflight.

**Os alvos [planejado]** — um módulo, `mvp_ed1.recovery`; um diretório, `RECOVERY_DIR`,
**absoluto** (padrão `$(abspath data/recovery)` do *checkout* onde o alvo roda, impresso em toda
execução; em B5 é passado explicitamente ao clone — RV12-09):

| Alvo | O que faz |
|---|---|
| `make recovery-pack` | janela parada → *dumps* + cópias + manifesto + *checksums* → `<dir>/candidato/`. Recusa árvore suja (`git status --porcelain` não vazio) |
| `make recovery-verify [DIR=]` | *checksums*; manifesto lido; `pg_restore --list` nos três *dumps*; contagens do manifesto × banco vivo (quando ainda é o mesmo estado) |
| `make recovery-restore RESTAURAR=1` | a sequência abaixo. A autorização é **`RESTAURAR=1`**, não `FORCE` — e é consumida na entrada: os submakes de descarte recebem `FORCE=1` **um a um** (`stream-down FORCE=1`, `stream-reset-sink FORCE=1`), e os de subida recebem `FORCE=` vazio, com o preflight obrigatório (RV12-06) |
| `make recovery-promote` | `candidato/` → `aprovado/`, só depois de `verify` **e** de uma restauração validada; o anterior é apagado |

**A sequência de restauração (RV12-02), na ordem:**

1. `verify` do pacote.
2. **Manutenção**: conferir ausência de trabalho (a mesma verificação do preflight); pausar a
   DAG; parar Beam e produtor se existirem.
3. **Descartar o CDC enquanto a origem antiga existe**: `stream-down FORCE=1` (tópicos e
   *slots*); `stream-reset-sink FORCE=1` (destino quente vazio, consumidores parados).
4. `pg_restore` das duas fontes (`--clean --if-exists`) e da memória do armazém.
5. **Conferir conteúdo**: contagens × manifesto nos três; `governance._versions`; `alembic
   current` nas fontes.
6. Restaurar `manifesto.json`/diário e `producer_state.json` nos caminhos do *checkout*.
7. **Novo *snapshot***: `stream-up` (preflight ativo) → `stream-run` até `stream-wait` (o
   corte é o `max(event_sequence)` do manifesto) → encerrar.
8. **Reconstruir sem apagar o que acabou de voltar (RV12-2-01)**: `airbyte-up` → **guarda da
   identidade (D50, abaixo)** → `sync-airbyte RESET=1` → `sync-legacy` → **`dbt-rebuild`** (alvo
   novo: `governance.garantir` + `dbt build --full-refresh`, **sem** `dbt-drop-snapshots` — o
   `--full-refresh` refaz a fato incremental sobre as chaves substitutas restauradas, e o
   `dbt snapshot` só acrescenta versão se `trusted` mudou, o que não muda) → `make check`.
   `dbt-build RESET=1` continua existindo para o caso que o justificou — regenerar a origem —
   e o `RESTAURAR.md` diz, em negrito, que não é o alvo de uma restauração.
9. **Oráculos explícitos**, no roteiro executável, não só o `PASS`: as contagens de `oltp` e
   `legacy` = manifesto; a comparação dos **dois caminhos** da Execução Local §3.2 — chaves só
   num lado = 0, linhas com coluna de negócio diferente (as 16 de `COLUNAS_DO_EVENTO`) = 0, pares
   armazém/SKU com saldo diferente = 0, soma dos deltas igual — **é ela que prova o livro
   restaurado**; `caminhos_de_ingestao_reconciliam` lê *flags* de chegada e tempo, não os
   *payloads*, e só complementa; a memória de exclusões renasce igual (4 registros; clientes
   `1`,`2`,`3`); a captura selecionada é certificada; `governance._versions` intacto; **as versões
   SCD são as do manifesto** — linhas, `dbt_scd_id` distintos e o `md5` dos intervalos de validade,
   por *snapshot*, iguais antes e depois da reconstrução.

**A identidade da captura num Airbyte novo — D50 [decidido].** `snapshot_id` é o `job_id` do
Airbyte; uma instalação nova recomeça em 1 e colide com o que o pacote retém (28–43). Duas
peças, nenhuma muda a identidade do [ADR-0044](docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md):

1. **Guarda na certificação**: uma captura com `sync_id ≤ max(snapshot_id)` já certificado é
   **recusada** com motivo próprio (`identidade reutilizada ou retrocedida`) antes de qualquer
   medição — colisão deixa de ser possível em silêncio. Entra em `captura.decidir` (ou no passo
   que a antecede), e o ADR-0044 ganha a consequência nas *Consequências*, sem ADR novo.
2. **Regra operacional na restauração**: a sequência de restauração **não toca no Airbyte** —
   numa recuperação real ele continua o mesmo e os `job_id` seguem. Só quando o Airbyte é uma
   instalação nova (B5, ou um desastre que o levou junto) entra o passo `recovery-restore` →
   *avançar a sequência de jobs do Airbyte para `max(snapshot_id)` retido + 1*, conferido
   **antes** da primeira sincronização (`sync-legacy` de prova: `sync_id` > retido, certificada).
   **Premissa a confirmar em B5** [não medido]: o nome da sequência e da tabela no banco interno
   do Airbyte (`jobs`, `jobs_id_seq` — interno da ferramenta, pode mudar com a versão); o passo
   é escrito de forma que, se a premissa falhar, ele **pare** com a mensagem, e a guarda (1)
   continua protegendo.

**Prova (exigida pela rodada 2):** teste sem banco com captura retida 43 e (a) *job* novo 3 →
recusado pela guarda; (b) *job* 43 reutilizado → recusado; (c) *job* 44 → certificado e
selecionado. Em B5, linha 9: a guarda dispara com o Airbyte novo (saída colada), a sequência é
avançada, a sincronização seguinte é certificada como 44+ e selecionada sobre a 43 restaurada.

O `pg_restore` ocupa o lugar do `seed-data` do procedimento da §3.2; o resto da §3.2 é o que a
sequência acima aplica, na ordem que ela já tinha.

**Prova sem banco.** `tests/test_recovery.py`: manifesto gerado e lido, **inclusive o oráculo
SCD e o das capturas**; *checksum* alterado acusado; árvore suja recusada; `restore` sem
`RESTAURAR=1` recusado antes de tocar em banco; a sequência de restauração, simulada com o
Makefile real e registradores no lugar dos executáveis (a técnica da §14.3), **nunca** chama
`dbt-drop-snapshots`;
**composição** `recovery-restore RESTAURAR=1` num Makefile de simulação com a macro real do
preflight: os submakes de subida **não** anunciam "preflight ignorado" (a contraprova do
RV12-06); `RECOVERY_DIR` relativo é rejeitado.

---

## 7. B5 — o ciclo do zero, medido

**Pré-condição:** B0–B4 entregues, pacote candidato montado e verificado, Execução Local
corrigida nos quatro desvios da §0 (senão o roteiro está errado antes de começar).

### 7.1 Desmontar — no *checkout* antigo, que tem `.tools/`

Com os processos parados (preflight sem trabalho):

1. `make stream-down FORCE=1` — tópicos, *offsets* do Connect, **e os *slots* enquanto o
   `source_db` antigo ainda existe** (RV12-03).
2. `make airflow-down FORCE=1` — metadados e histórico de execuções.
3. `make airbyte-down` — o cluster `kind` cai; o diretório antigo do `abctl` é **apartado**
   (renomeado com data) e isso fica no diário — é a armadilha do `PG_VERSION` da Execução Local
   §6, reproduzida com o remédio documentado.
4. `make reset` — os três volumes PostgreSQL (confirmação interativa, como sempre).
5. **Inventário**: `docker ps -a` e `docker volume ls` filtrados por `mvp_ed1` **e** por
   `airbyte-abctl` (o nó do cluster não leva o nome do projeto), `docker network ls` idem →
   **vazio**. `kind` não está no PATH nem em `make tools`: o nó é um contêiner e é assim que se
   inventaria; comando ausente **não** conta como inventário vazio. Colado no diário.

### 7.2 Preparar o clone

1. `git clone` de `origin/main` em outro diretório; `make env` (senhas novas); `make install`
   — que passa a incluir **`dbt deps`** com o `package-lock.yml` versionado (RV12-07: hoje
   `uv sync` só); `make tools` (baixa `abctl` e Terraform fixados para o `.tools/` do clone —
   tempo medido, é a primeira vez que o alvo roda do zero desde a Etapa 5).
2. `RECOVERY_DIR=<caminho absoluto do pacote no checkout antigo>` exportado no `.env` do clone.
3. **`make check-offline` antes de subir nada** (RV12-2-04) — alvo novo, explícito: segredos,
   `docs-check`, e `pytest -m "not integracao"`; `tests/test_consumo.py` ganha a marca
   `integracao` que lhe falta (o revisor da Etapa 11 já tinha esbarrado nisso). O `make check`
   completo fica **intacto** e roda na linha 4 da §7.3, depois das duas ingestões. O que
   `check-offline` pular é listado com motivo.

### 7.3 O ciclo, na ordem certa — cada linha sob `make medir`

A ordem **não** é a da Execução Local §3 de hoje: o *streaming* vem antes do primeiro
`dbt-build` completo (RV12-04), e a §3 é corrigida para dizer isso.

| # | Cenário | Alvos | De pé | `ATE` | O que a linha prova |
|---|---|---|---|---|---|
| 1 | Base | `up` → `migrate` → `seed-data` → `migrate-legacy` → `seed-legacy` | bancos | — | migrações do zero; cobertura (`test_cobertura`, manifesto do legado novo) |
| 2 | Carga | `airbyte-up` → `airbyte-config` → `sync-airbyte` → `sync-legacy` | + Airbyte | — | `raw`, `raw_legacy`, captura 1 certificada; o pico da etapa |
| 3 | Streaming — o *snapshot* | `make medir CENARIO=streaming` (sem `LIMITE`: sobe, `stream-run` sob guarda, corte = origem, `stream-wait`, encerra) | + streaming (pausa o Airbyte) | interno ao cenário | o livro quente igual à origem (comparação da §3.2: chave + as 16 colunas de `COLUNAS_DO_EVENTO`, lidas da tupla, e o saldo por armazém/SKU — os quatro zeros); Beam encerrado ao fim |
| 4 | Transformação | `airbyte-up` (pausa o streaming) → `dbt-build` → `check` | + Airbyte | — | o primeiro `build` completo: `PASS=`, `caminhos_de_ingestao_reconciliam`, as oito fronteiras |
| 5 | Orquestração | `airflow-up` → `dag-run` | + Airflow (Airbyte de pé: o par permitido) | `dag-wait` | 13 tarefas `success`, tempo da DAG, captura 2 certificada |
| 6 | Streaming — eventos novos | `make medir CENARIO=streaming LIMITE=n` (sobe, `stream-run` sob guarda, produz, **corte lido depois do produtor**, `stream-wait`, encerra) → `stream-alerts` | + streaming (Airbyte e Airflow pausados **pelo preflight de B0**) | interno ao cenário | os `n` eventos novos chegam (não só o *snapshot*); alerta emitido; Beam encerrado ao fim |
| 7 | Reconciliação dos caminhos | `airbyte-up` → `sync-airbyte` → `dbt-build` | + Airbyte | — | os dois caminhos iguais com os eventos novos |
| 8 | Catálogo | `docs-generate` → `catalog` | bancos | — | tempo; `sensitivity --check`, `lineage --check` sem diferença; `curl` na porta do `dbt-docs` no diário |
| 9 | Recuperação | `recovery-restore RESTAURAR=1` (a sequência da §6, passo a passo, cada um medido) → `recovery-promote` | conforme o passo | — | C4 inteira: as fontes **e a memória** de volta; o livro igual; a memória de exclusões renascida; **as versões SCD iguais ao manifesto**; a guarda D50 dispara com o Airbyte novo, a sequência é avançada, a captura seguinte é certificada acima da 43 |

Cada linha vira uma linha da **Capacidade §2.12**, com estado da estação, intervalo e número de
amostras. **R11** vale o tempo todo; recusa do preflight é registrada, não contornada.

### 7.4 Os critérios do Termo, mapeados

| Termo §6 | Comando que prova | Saída que vale |
|---|---|---|
| Produto: subir bancos, gerar dados, pipeline completo, consultar views, catálogo e linhagem | linhas 1–5 e 8 | `dag-status` 13 `success`; `tests/test_consumo.py` nas 16 views; `curl` do catálogo |
| Técnico: reproduzível de ponta a ponta | o ciclo inteiro do clone, sem passo fora da Execução Local corrigida | o diário: cada comando, hora, saída resumida, **desvios = 0** ao fechar |
| Técnico: migrações do zero | `migrate`, `migrate-legacy`; `governance.garantir()` no `dbt-build` | `alembic current` nas fontes; `python -m mvp_ed1.governance versoes` no armazém |
| Técnico: testes passando | `make check` | `PASS=…`, `N passed`, e a lista de *skips* com motivo |
| Técnico: reconciliação entre camadas | dentro do `check` (oito fronteiras) + a comparação explícita dos caminhos | 22 testes `pass`; os quatro zeros |
| Técnico: ausência de segredos | `secrets_review` e `--historico` | "nada não tratado", com a lista de pulados e de tratados |
| Técnico: documentação coerente | `docs-check` + a execução linha a linha | 0 quebrados; desvios corrigidos no documento antes de fechar |
| Governança | `sensitivity --check`, `lineage --check`, pisos de `test_classificacao.py` | dentro do `check`; citados |

---

## 8. B6 — fechamento

1. **Capacidade**: §2.12 com a tabela medida; §3 reescrita para D49 (conteúdo, limite,
   sequência) e "entregue em …" com o caminho do pacote aprovado; tabela de situação.
2. **Execução Local**: §3 na ordem corrigida (streaming antes do primeiro build; `dbt deps` em
   `install`; `make tools` no clone; `medir`, `dag-wait`, `stream-wait`, `docs-generate`,
   `check-offline`, `dbt-rebuild`, `recovery-*`); §3.2 apontando para a sequência de
   restauração; §4 com os alvos novos; §5 com a detecção por rótulos; §6 com a armadilha do
   `PG_VERSION` conferida e a regra da sequência do Airbyte.
2b. **ADR-0044**: a guarda de identidade da captura (D50) nas *Consequências*.
3. **Governança** (ou o dono que B6 fixar): a lista de segredos tratados, se houver.
4. **README**, **plano** (Etapa 12 com ✓ só onde há medição; M5), **pendências**, **riscos**
   (R6, R7, R10, R11).
5. **Definição de pronto** do `CLAUDE.md` §7 aplicada e registrada.
6. ***Tag* `v1.0.0`** anotada no *commit* de fechamento.
7. **Dossiê** (`REVISAO.md`) para o outro agente, com a seção "não verificado" honesta.

**Sai deste plano:** este arquivo, no último *commit*.

---

## 9. O que **não** entra

- *Batch* e *streaming* simultâneos — ADR-0046, medido na Etapa 13.
- VM na nuvem como "ambiente limpo" — depois da Etapa 13 (D45 (c): contrapartida registrada).
- Teste de carga acima de `SCALE=1` ([ADR-0014](docs/adr/0014-volume-por-proporcoes-e-fator-de-escala.md)).
- Qualquer mudança de modelagem, tratamento ou componente; defeito que B5 revelar é corrigido
  onde nasce e vira linha no dossiê.
- Ampliar o Alembic ao armazém para "ter `alembic current`" — o oráculo dele é
  `governance._versions` (ADR-0044), e fica assim.
- Trocar a identidade da captura por uma composta (instalação, *job*) — a alternativa
  descartada em D50: modelagem, ADR novo, adiaria a etapa.
- D43 — adiada para a fase GCP.

---

## 10. As decisões do Owner — tomadas em 18/09/2026

Nenhum ADR novo: nenhuma troca ferramenta, camada ou modelagem. Registro em
[Pendências §2](docs/pendencias.md#2-decisões-já-fechadas).

### D45 — "ambiente limpo" — decidido: (c)

| Opção | A favor | Contra |
|---|---|---|
| (a) Clone novo + `.env` novo + `make reset` nesta máquina | Custo zero; é o que o Termo pede ("a partir do repositório") | Não prova que sobe numa máquina que nunca viu o projeto |
| (b) VM na nuvem, um dia (~US$ 3) | Prova a portabilidade de verdade | Antecipa o §4.1 e mistura "fechar" com "provar portabilidade" |
| **(c) (a) agora, (b) como critério da fase seguinte** — **decidida** | O que (a) não prova fica registrado como contrapartida | — |

Sub-decisão, decidida junto: o Airbyte é **derrubado**, não pausado. **Completada pelo RV12-03
(revisão 3):** "do zero" desmonta as **três** composições e o cluster, com os *slots* removidos
antes de a origem antiga sumir — §7.1. Não exige outra máquina; é a mesma decisão, inteira.

### D46 — onde vive o pacote — decidido: `data/recovery/`, com `RECOVERY_DIR` **absoluto**

(Revisão 3: absoluto e impresso, por RV12-09.)

### D47 — o nome da versão — decidido: `v1.0.0`

### D48 — segredo no histórico — decidido

Senha de contêiner local: regenerar, registrar como **tratado** (lista versionada, §4), não
reescrever histórico. Chave de nuvem ou *token* externo: revogar **e** reescrever, só pela mão do
Owner. Hoje **[medido]** não há chave de nuvem em lugar nenhum.

### D49 — o que o pacote guarda — decidida em 18/09/2026 sobre o RV12-01

| Opção | A favor | Contra |
|---|---|---|
| **Fontes + memória do armazém (`raw_legacy`, `governance`, `snapshots`)** — **decidida** | É o que os ADRs 0037/0044/0045 chamam de memória e nenhuma reconstrução reproduz; o resto continua sendo refeito e **provado** igual | Pacote maior (a medir); um `pg_restore` a mais |
| Só as fontes, perda declarada | Mantém a §3.3 | A memória deixa de ser recuperável; o pacote não seria "volta" a nada além das fontes |
| Armazém inteiro | Simples | Duplica o derivável; a prova "refeito a partir das fontes" deixa de ser exercitada |

---

### D50 — a identidade da captura num Airbyte novo — decidida em 18/09/2026 sobre o RV12-2-02

| Opção | A favor | Contra |
|---|---|---|
| **Guarda na certificação + regra operacional (avançar a sequência do Airbyte antes da primeira sincronização)** — **decidida** | A colisão vira impossível em silêncio; a identidade do ADR-0044 não muda; a restauração real não toca no Airbyte | Depende de um interno do Airbyte (nome da sequência), confirmado em B5; se mudar de versão, o passo para com mensagem e a guarda segue valendo |
| Identidade composta (instalação, *job*) com `_airbyte_extracted_at` separando linhas | Independente do Airbyte | Altera identidade, SQL de captura, memória de exclusões e testes — modelagem, ADR novo, fora da Etapa 12 |
| Limite declarado: pacote só restaurável na instalação de origem | Nada muda além da guarda | A linha 9 de B5 não provaria a memória do legado; C4 fecharia com lacuna |

---

## 11. Riscos deste plano

- **`reset` e as três desmontagens são destrutivos** e o pacote é a única volta — por isso B4
  antes, `verify` antes do `reset`, e o inventário vazio colado antes de `up`.
- **Tempo de relógio de B5** (~2 h de trocas + sincronizações + dois *snapshots* + a
  restauração); não cabe num fim de tarde. O estado da estação é anotado, não controlado.
- **Divergência entre Execução Local e realidade** é o achado esperado — três já conhecidas
  (§0), corrigidas antes de B5; as que B5 achar, corrigidas antes de fechar.
- **`stream-wait` sem corte** mediria para sempre: `ATE_SEQ` é obrigatório.
- **R11**: o preflight decide — **depois de B0**; até lá, ele não vê o Airflow, e `make stream-up`
  com Airflow de pé sobe os dois. `FORCE=1` só com a sua autorização, e **nunca** herdado por um
  alvo composto (§6).
- **Interno do Airbyte** (D50): o avanço da sequência é o único passo do plano que depende de
  algo que a ferramenta não promete; está isolado, para com mensagem, e a guarda não depende dele.

---

## 12. O que pedir ao outro agente

1. **Deste plano, revisão 4** — antes do código: os seis achados da rodada 2 estão fechados na
   letra e no espírito, e os quatro "parciais" da §14.1 (RV12-01, -04, -05, -08) agora inteiros?
   B0 é a correção certa do defeito do preflight, ou há consumidor de nome que ficou de fora?
2. **Da entrega, com o dossiê** (`REVISAO.md`): o declarativo novo — `medir.sh`, `recovery.py`,
   `docs_check.py`, os detectores de `secrets_review`, a lista de tratados —, a Capacidade §2.12
   e §3, a Execução Local corrigida; o derivado é o diário de B5.

---

## 13. Parecer da revisão — 18/09/2026

**Escopo:** `179b80a..6559d80`, este plano e o registro D45–D48 em `docs/pendencias.md`,
confrontados com os alvos, consumidores, testes e ADRs vigentes. **Parecer: viável, mas ainda
não pronto para execução.** Há **5 bloqueantes e 4 ajustes** abaixo. As decisões D45–D48 foram
consideradas tomadas; os achados não pedem que sejam votadas outra vez. Não foi implementado
nenhum bloco, nem executado o ciclo destrutivo. Este parecer fica aqui por instrução da §12.

### 13.1 Achados

| ID | Veredito | Onde / problema e consequência | Ajuste proposto | Situação |
|---|---|---|---|---|
| RV12-01 | **bloqueante** | **§6 e §11 — os dois dumps não são uma volta ao estado atual inteiro.** A exclusão do armazém reproduz a especificação antiga da Capacidade, mas os ADRs 0037, 0044 e 0045 fazem das capturas retidas e de seus certificados entradas necessárias para reconstruir a memória de exclusões. Há hoje **11** capturas completas e **4** registros nessa memória; três clientes lembrados nela já não existem na origem (§13.2). O reset apaga essa evidência; sincronizar as fontes restauradas produz capturas novas, sem reconstruir o conteúdo e os certificados das anteriores. O histórico SCD também está declarado como não reconstruível em `dbt/dbt_project.yml`. | Resolver a divergência no contrato de recuperação **antes de B4/B5**: delimitar recuperação do estado corrente das fontes versus preservação do histórico, e registrar o destino do estado permanente antes do reset. Se o pacote tiver de preservar esse histórico, seu conteúdo precisa mudar por decisão do Owner; se a perda fizer parte do recomeço autorizado, declará-la como limite, sem chamar o pacote de volta completa. Não reescrever ADR aceito nem decidir retenção durante a implementação. | **Fechado na revisão 3 — D49 decidida pelo Owner:** o pacote guarda as fontes **e** a memória do armazém (`raw_legacy`, `governance`, `snapshots`); o resto é refeito e provado igual; o limite está escrito (§6). Capacidade §3 é reescrita em B6 como consequência dos ADRs, sem ADR novo. |
| RV12-02 | **bloqueante** | **§6, `recovery-restore` — `pg_restore` vem antes da parada dos consumidores.** O procedimento citado da Execução Local §3.2 começa identificando e encerrando produtores/Beam, pausando a DAG, esperando jobs e removendo o estado do CDC **antes** de substituir a origem. Colocá-lo depois permite leitura ou escrita concorrente sobre a restauração e só então invalida o conector. | Especificar uma sequência própria: verificar o pacote; entrar em manutenção e conferir ausência de trabalho; descartar CDC e limpar o destino; restaurar as fontes; conferir conteúdo; fazer o novo snapshot e reconstruir. O `pg_restore` ocupa o lugar da regeração, sem executar o `seed-data` do procedimento citado. Definir também um corte estável para dumps e manifesto de B4, para que descrevam o mesmo estado. | **Fechado na revisão 3:** sequência própria de nove passos em §6 (verify → manutenção → descartar CDC e limpar destino com a origem antiga ainda de pé → restaurar → conferir → oráculos locais → novo snapshot → reconstruir → oráculos explícitos); corte estável por janela parada e contagens em `repeatable read`. |
| RV12-03 | **bloqueante** | **§7, definição de ambiente limpo — `airbyte-down` + `reset` não zeram todo o estado do pipeline.** `reset` usa somente `docker-compose.yml` e remove os três volumes PostgreSQL. `redpanda_data`, com tópicos e offsets do Connect, e os volumes de metadados/logs do Airflow pertencem a outras composições e sobrevivem. Retomar esse transporte contra um `source_db` novo conserva um cursor de outra origem; manter o Airflow conserva o histórico da máquina anterior. O clone novo não muda isso, pois `make env` usa o mesmo `COMPOSE_PROJECT_NAME`. | Acrescentar à preparação, com os processos parados, o descarte explícito do estado das composições de streaming e Airflow, usando seus alvos existentes; remover os slots enquanto a origem antiga ainda existe. Conferir o inventário restante antes de `up`. O remédio do Airbyte deve deixar explícito quando o diretório antigo foi apartado. Isso completa a execução de D45, sem exigir outra máquina. | **Fechado na revisão 3:** §7.1 desmonta as três composições e o cluster no checkout antigo — `stream-down FORCE=1` (slots com a origem antiga viva), `airflow-down FORCE=1`, `airbyte-down` com o diretório apartado, `reset`, inventário vazio colado. D45 completada, mesma máquina. |
| RV12-04 | **bloqueante** | **§7, tabela de cenários — o primeiro `dbt-build` completo precede a primeira carga do CDC.** `stg_retail__inventory_movements.sql` lê incondicionalmente `raw.inventory_movements_stream`; quem cria a tabela é o sink do Beam. Num armazém vazio ela ainda não existe. Criá-la vazia também não resolve: `caminhos_de_ingestao_reconciliam.sql` reprova todo movimento que só chegou pelo lote. A DAG executa a mesma dependência antes da linha Streaming. | Fazer a carga inicial dos dois caminhos, por partes, antes do primeiro build completo e da DAG: carga batch; snapshot pelo Beam até igualdade; encerramento do Beam; retorno ao batch; build/check. Se houver um build parcial de preparação, declarar sua seleção e não usá-lo como prova do build completo. Preservar os testes de fronteira. | **Fechado na revisão 3:** §7.3 põe o snapshot do streaming (linha 3) antes do primeiro `dbt-build` completo (linha 4); sem build parcial. A Execução Local §3 é corrigida **antes** de B5 (pré-condição da §7) — é o primeiro dos três desvios conhecidos. |
| RV12-05 | **bloqueante** | **§4 — reutilizar os padrões atuais não encontra senha antiga depois da rotação.** O código não possui um detector geral de atribuições `PASSWORD=…`: `SECRET_KEY_PATTERN` seleciona chaves do `.env` **atual**, e o rastreado é comparado com os valores atuais mais cinco formas genéricas. A contraprova com senha fictícia removida do arquivo e rotacionada deixa o blob antigo sem nenhum casamento (§13.2). D45 troca justamente o `.env` antes da validação final. | Definir detecção histórica independente dos valores atuais, com tratamento explícito de exemplos/placeholders e evidência sem reproduzir o segredo. O teste deve remover **e rotacionar** uma senha local, além de cobrir token com forma genérica. Manter D48: achado local revogado e mantido no histórico precisa aparecer como tratado; a exigência literal de “nada encontrado” na §7 não pode contradizer esse desfecho decidido. | **Fechado na revisão 3:** §4 declara detectores independentes dos valores (atribuições `CHAVE=valor`, credencial em URL, formas genéricas) com placeholders listados; achados tratados (D48) em lista versionada, impressos como tratados; teste remove **e rotaciona**, cobre token genérico, placeholder, tratado e pulado. O veredito da §7 passa a "nada não tratado". |
| RV12-06 | **ajuste** | **§6, `FORCE=1` — a autorização de restore pode desligar o preflight dos filhos.** Variáveis passadas ao `make` são herdadas por submakes. Uma composição direta de `recovery-restore FORCE=1` com `stream-up`/`airbyte-up` faz a macro vigente anunciar preflight ignorado; a simulação com a macro real confirmou isso, sem executar Docker (§13.2). | Consumir a autorização de restauração na entrada e impedir sua propagação como autorização de recursos. Nos alvos de subida, manter `FORCE` desativado e o preflight obrigatório; nos descartes autorizados, passá-lo somente ao comando correspondente. Incluir uma contraprova da composição, não apenas de `restore` sem flag. | **Fechado na revisão 3:** a autorização é `RESTAURAR=1`, consumida na entrada; submakes de descarte recebem `FORCE=1` um a um, os de subida recebem `FORCE=` vazio com preflight obrigatório; contraprova de composição com a macro real em `test_recovery.py` (§6). |
| RV12-07 | **ajuste** | **§7, preparação do clone — faltam dependências fora do Git.** `.tools/` pertence ao diretório antigo e não aparece no clone; `airbyte-down` já exige esse caminho. `make install` só executa `uv sync`, sem instalar `dbt/packages.yml`. Na cópia dos arquivos rastreados sem caches, `dbt parse` falhou por ausência de `dbt_utils`, `dbt_date` e `dbt_expectations` (§13.2). | Declarar de qual diretório sai cada comando de desmontagem; preparar as ferramentas no clone por `make tools` ou por reaproveitamento explicitamente documentado; incluir `dbt deps` com o lock versionado antes do primeiro comando dbt. Corrigir a Execução Local com esse preparo antes de usá-la como roteiro da medição. | **Fechado na revisão 3:** §7.1 diz de onde sai cada desmontagem (checkout antigo, que tem `.tools/`); §7.2 prepara o clone com `make tools` e `make install` passando a incluir `dbt deps` com o lock versionado; Execução Local corrigida antes de B5 (desvios 2 e 3). |
| RV12-08 | **ajuste** | **§3 e §7 — tempo do alvo não é sempre tempo do trabalho.** `dag-run` só dispara e `dag-status` só consulta: amostrar enquanto esses processos existem não cobre os minutos da DAG. `stream-run` e `dbt-docs` permanecem em primeiro plano, sem um fim natural para o medidor. Além disso, a troca para `airbyte-up` recusa enquanto Beam/Prism continuam ativos; a linha Streaming não os encerra. | Definir início e fim de cada cenário: aguardar o `run_id` disparado até estado terminal, com prazo e falha propagada; medir o streaming até o snapshot e os eventos alcançarem um corte declarado, depois encerrar os processos; separar geração do catálogo da prova de que o servidor responde. Manter a amostragem durante todo esse intervalo e registrar saída/erro/interrupção do alvo. | **Fechado na revisão 3:** `make medir ALVO= ATE=` amostra até o alvo de espera terminar; `dag-wait` (run_id até estado terminal, prazo, falha propagada), `stream-wait` (corte `ATE_SEQ` obrigatório + produtor encerrado), `docs-generate` separado do servir; a linha Streaming encerra Beam e produtor antes da troca (§3, §7.3). |
| RV12-09 | **ajuste** | **§6–§7 — o pacote e as evidências locais não atravessam o clone por construção.** O candidato em `data/recovery/` fica no checkout antigo; o mesmo caminho relativo no clone aponta para outro lugar. O pacote descrito também não leva `data/legacy/manifesto*.json` e seu diário, nem define o destino do cursor `.stream/producer_state.json`. O manifesto atual tem duas mutações abertas; `seed-legacy` no clone cria outro diário. Após restaurar o legado antigo, os testes podem pular por manifesto divergente ou diário vazio, deixando um `check` verde com menos prova. | Fixar e verificar um `RECOVERY_DIR` absoluto antes da troca de diretório. Declarar a transferência ou reconstrução verificável dos oráculos que correspondem ao dump e uma regra para o cursor do produtor que corresponda ao livro restaurado. Guardar a lista/motivo dos skips e exigir as provas de recuperação esperadas, sem usar o manifesto da geração de B5 como se descrevesse automaticamente o dump de B4. | **Fechado na revisão 3:** `RECOVERY_DIR` absoluto, impresso, rejeitado se relativo, passado explicitamente ao clone; o pacote leva `manifesto.json`/diário e `producer_state.json` com checksum, restaurados nos caminhos do checkout (§6 passo 6); skips listados com motivo (§7.2, §7.4); os oráculos de recuperação são os do dump, não os da geração de B5. |

### 13.2 Evidências produzidas nesta revisão

**Arquivos e alvos [leitura declarativa].** As dependências acima foram conferidas em
[`Makefile`](Makefile), nas três composições em `docker/`, no
[`modelo de encontro dos caminhos`](dbt/models/staging/stg_retail__inventory_movements.sql),
no [`teste de reconciliação`](dbt/tests/caminhos_de_ingestao_reconciliam.sql), em
[`secrets_review.py`](src/mvp_ed1/secrets_review.py),
[`remocao.py`](src/mvp_ed1/legacy/remocao.py),
[`writer.py`](src/mvp_ed1/legacy/writer.py) e nos testes
[`test_legado_remocao.py`](tests/test_legado_remocao.py) e
[`test_legado_deteccao.py`](tests/test_legado_deteccao.py).
Não são resultados de execução do roteiro.

**Dependências dbt [medido, sem banco].** Copiados os arquivos rastreados para
`/tmp/rv12_plano_g73p28at/clone_sem_cache`, sem `.tools`, `.venv`, `target` ou `dbt_packages`.
Usado o executável dbt já instalado no checkout de trabalho, com variáveis de conexão
fictícias e telemetria desativada; nenhum serviço foi necessário:

```text
$ .venv/bin/dbt parse --no-partial-parse --project-dir /tmp/rv12_plano_g73p28at/clone_sem_cache/dbt --profiles-dir /tmp/rv12_plano_g73p28at/clone_sem_cache/dbt
DBT_PARSE_SEM_CACHE_EXIT 2
21:54:03  Running with dbt=1.12.3
21:54:03  Registered adapter: postgres=1.11.0
21:54:03  [ERROR]: Encountered an error:
Compilation Error
  dbt expects 3 package(s) based on packages specified in packages.yml, but found only 0 package(s) installed in dbt_packages. Following packages were not found: dbt_utils, dbt_date, dbt_expectations. Run "dbt deps" to install package dependencies.
```

O log integral está em `/tmp/rv12_plano_g73p28at/dbt_parse.log`. Isto prova a falta de
dependências no roteiro, não a execução de B5 nem uma instalação nova de Python.

**Senha rotacionada [medido, sem credencial real].** Em um Git temporário, gravada uma senha
fictícia em `config.yml` e no `.env` ignorado; feito um commit; removido `config.yml`,
rotacionado o `.env` e feito outro commit. Aplicados `review()` ao rastreado e os
`GENERIC_PATTERNS`/valores retornados por `secret_values(read_env(...))` ao blob antigo:

```text
ANTES_DE_ROTACIONAR ['config.yml: contém o valor de SOURCE_DB_PASSWORD do .env']
DEPOIS_DE_ROTACIONAR_RASTREADOS []
BLOB_ANTIGO_PADROES_GENERICOS 0
BLOB_ANTIGO_VALORES_ENV_ATUAL 0
```

Repositório da contraprova: `/tmp/rv12_plano_g73p28at/segredo_rotacionado`.
O modo `--historico` ainda não existe; foi verificada a insuficiência dos detectores que
o plano propõe reutilizar, não uma implementação futura.

**Herança de `FORCE` [medido, sem Docker].** Copiada literalmente a macro `preflight` do
Makefile para um Makefile temporário. A receita simulada de `recovery-restore` chama um
submake `stream-up`; este só expande a macro, sem subir serviço algum:

```text
$ make --no-print-directory -C /tmp/rv12_plano_g73p28at/force_herdado recovery-restore FORCE=1
SIMULACAO_MAKE_FORCE_EXIT 0
[preflight] ignorado por FORCE=1 — subida de streaming autorizada pelo Owner.
Apenas a macro real de preflight e uma receita simulada; nenhum Docker executado.
```

É uma condição a evitar no contrato do novo alvo; não se afirma que `recovery-restore`
já exista ou tenha sido executado.

**Estado que a recuperação precisa delimitar [medido, somente leitura].** Consultas SQLAlchemy
em transações com `set transaction read only` e `statement_timeout = '5s'`, usando o `.env`
sem imprimi-lo. A primeira tentativa foi bloqueada pela sandbox; a repetição autorizada
fora dela concluiu. Consultas:

```sql
-- warehouse_db
select count(*), min(snapshot_id), max(snapshot_id)
from (
  select snapshot_id from governance.legacy_captures
  where status = 'complete'
  group by snapshot_id having count(distinct source_table) = 40
) x;
select count(*) from trusted.legacy_removed_records;
select count(*) from trusted.legacy_removed_records
where source_table = 'customers' and business_key in ('1', '2', '3');
select nome from governance._versions order by nome;
-- legacy_db
select count(*) from legacy.customers where id in ('1', '2', '3');
```

Saída literal do coletor:

```text
capturas_completas_nas_40_tabelas [(11, 28, 43)]
memoria_removidos [(4,)]
memoria_customers_1_2_3 [(3,)]
migrações_governance [('0001_legacy_captures',), ('0002_snapshot_id_e_o_job',)]
customers_1_2_3_na_origem [(0,)]
```

Leitura dos JSON locais, sem alterá-los:

```text
ARTEFATO_LOCAL data/legacy/manifesto.json EXISTE True
MUTACOES_ABERTAS 2 DIARIOS_ENCERRADOS 1
ARTEFATO_LOCAL .stream/producer_state.json EXISTE True
CHAVES_DO_ESTADO ['emitidos', 'emitidos_acumulados', 'stream_seed', 'teto', 'ultimo_registrado_em']
```

### 13.3 Observações para a reescrita e validações pendentes

*Revisão 3 — onde cada observação foi parar:* precisão dos oráculos → §0 ("captura 43
certificada"; `governance._versions` como oráculo do armazém, e §9 recusa ampliar o Alembic);
B1 → §3 (extremos amostrados com intervalo e contagem; host × contêineres lado a lado, Beam no
host; a diferença para `run_results.json` é registrada, não tolerada por ±5 s); B2/B3 → §4 e §5
(pulados listados com motivo; casos de título repetido, título em bloco de código, link por
referência, fragmento codificado nos testes); oráculos de recuperação → §6 passo 9 (a comparação
da §3.2 — chaves, 16 colunas de negócio, saldo por armazém/SKU — no roteiro executável;
`caminhos_de_ingestao_reconciliam` só complementa).


- **Precisão dos oráculos.** Na §2, substituir “43 capturas certificadas” por “captura 43
  certificada”, ou pela contagem medida acima com sua data. Na §7, o armazém não tem
  `alembic current`: o oráculo de suas migrações é `governance._versions` / o comando
  `python -m mvp_ed1.governance versoes`, conforme o ADR-0044. Não ampliar Alembic para
  satisfazer uma linha incorreta do plano.
- **B1 responde à lacuna de memória da §2.8**, desde que se preserve a distinção: o mínimo
  de `MemAvailable` inclui a pressão da estação inteira; a soma dos contêineres não inclui
  o Beam no host. São extremos **amostrados**, com intervalo e cobertura registrados,
  não garantia de capturar todo pico entre amostras. `run_results.json` mede o comando
  dbt; `dbt-build` inclui ainda a preparação de governança e a inicialização. A tolerância
  fixa de ±5 s não foi demonstrada e não deve ser o único oráculo do medidor.
- **B2/B3 precisam declarar os limites.** Blobs pulados não contam como ausência de
  segredos verificada; listar os objetos/razões que faltaram, além da quantidade.
  Para B3, incluir casos de títulos repetidos, títulos dentro de blocos de código,
  links por referência e caminhos/fragmentos codificados na especificação dos testes.
  A descrição abreviada de slug e três exemplos ainda não demonstram compatibilidade
  com todos os links rastreados. Não foi implementado nem medido `docs_check`.
- **Oráculos de recuperação.** Manter, de forma explícita no roteiro executável, a
  comparação de chaves e de todas as colunas de negócio e o saldo por armazém/SKU da
  Execução Local §3.2. O teste `caminhos_de_ingestao_reconciliam` citado na §6 lê flags
  de chegada e tempo, não compara os dois payloads. Seu PASS e contagens iguais,
  isoladamente, não provam a igualdade do livro restaurado.

**Não verificado nesta revisão:** B1–B4 implementados; instalação em clone conectado ao
remoto; reset ou desmontagem de qualquer ambiente; criação, integridade, restauração ou
promoção de dump; novo snapshot de CDC; medição de memória/tempo do ciclo; `make check`
completo; execução da DAG; varredura integral de segredos no histórico; resolução de todos
os links; emissão da tag ou aceite da etapa. Os números da §0 continuam sendo evidência
do autor, não medições repetidas por este revisor. As contraprovas ficaram em `/tmp`;
nenhum dado, segredo ou configuração de serviço foi alterado.

---

## 14. Parecer do plano reescrito — segunda rodada, 18/09/2026

**Escopo:** revisão 3 do plano, commit `7a6ee82`, e o registro de D49 em Pendências.
**Parecer: a reescrita resolve parte dos problemas, mas ainda há 5 bloqueantes e 1 ajuste.**
D49 foi considerada decidida, inclusive o registro de que não exige ADR novo. A sequência
precisa cumprir essa decisão: guardar `snapshots` e apagá-los durante a reconstrução não
preserva o histórico; guardar capturas e reiniciar a identidade dos jobs também precisa de
uma regra operacional antes da primeira sincronização posterior ao restore.

### 14.1 Conferência dos nove achados anteriores

O fechamento aqui é do **desenho do plano**; a implementação e a prova de restauração ainda
não existem. As respostas do autor na §13.1 foram preservadas; esta é a conferência delas.

| Achados anteriores | Resultado desta rodada |
|---|---|
| RV12-01 | **Parcial.** D49 resolve o conteúdo a preservar. A sequência ainda destrói SCD e não resolve a continuidade das identidades do Airbyte: RV12-2-01 e RV12-2-02. *Revisão 4: fechados em RV12-2-01 e RV12-2-02 (D50).* |
| RV12-02 | **Atendido no plano.** Parada e descarte de CDC passam a anteceder a restauração; o corte para empacotar foi explicitado. A detecção dos serviços usada como guarda tem o problema adicional RV12-2-03. |
| RV12-03 | **Atendido no plano.** As três composições são desmontadas, com os slots removidos antes da origem antiga. Conferência real do inventário continua pendente. |
| RV12-04 | **Parcial.** A tabela da §7.3 está na ordem correta, mas a §7.2 introduz um `check` que chama o build ainda antes dos bancos: RV12-2-04. *Revisão 4: fechado em RV12-2-04.* |
| RV12-05 | **Parcial.** Os detectores deixam de depender do valor atual, mas a expressão proposta não alcança chaves JSON entre aspas e a exclusão de `*.example` é ampla: RV12-2-05. *Revisão 4: fechado em RV12-2-05.* |
| RV12-06 | **Atendido no plano.** `RESTAURAR=1` e `FORCE=` explícito nos submakes de subida resolvem a herança descrita. A contraprova foi incluída no trabalho a implementar. |
| RV12-07 | **Atendido no plano.** Checkout de desmontagem, `make tools` e instalação de pacotes dbt foram explicitados. |
| RV12-08 | **Parcial.** Espera da DAG e separação da geração do catálogo estão previstas; falta fechar o protocolo do streaming, inclusive o corte dos eventos novos: RV12-2-06. *Revisão 4: fechado em RV12-2-06; `run_id` capturado por `dag-run` (§3).* |
| RV12-09 | **Atendido no plano.** Caminho absoluto e transferência de manifesto/diário/cursor estão descritos. Correspondência desses artefatos com o dump será uma validação da implementação. |

### 14.2 Achados desta rodada

| ID | Veredito | Onde / consequência | Ajuste proposto | Situação |
|---|---|---|---|---|
| RV12-2-01 | **bloqueante** | **§6, passo 8: o restore apaga o SCD que acabou de recuperar.** `dbt-build RESET=1` chama `dbt-drop-snapshots`, que executa `drop schema if exists snapshots cascade`, antes do build com `--full-refresh`. A simulação com o Makefile real confirmou a ordem (§14.3). O `check` pode passar depois de gerar um histórico novo; os oráculos do passo 9 não comparam versões SCD. Isso contradiz D49. | Reconstruir as relações derivadas e a fato incremental preservando os snapshots restaurados; não usar o alvo que descarta SCD. Acrescentar ao manifesto/oráculo a identidade e o conteúdo das versões SCD, inclusive intervalos de validade, e verificar sua preservação após a reconstrução. | **Fechado na revisão 4:** a reconstrução após o *restore* é `dbt-rebuild` (`garantir` + `dbt build --full-refresh`, sem `dbt-drop-snapshots`); o manifesto ganha o oráculo SCD por *snapshot* (linhas, `dbt_scd_id` distintos, `md5` dos intervalos de validade) e o passo 9 o compara; a simulação com o Makefile real prova que a sequência nunca chama o drop (§6). |
| RV12-2-02 | **bloqueante** | **§6, exclusão do estado do Airbyte e passo 8; §7.1: capturas antigas e jobs de uma instalação nova compartilham a mesma identidade numérica.** `schema.CAPTURA_SQL` usa só `_airbyte_meta.sync_id`; `snapshot_id` é o próprio `job_id`, sem identidade da instalação. A seleção padrão é `max(snapshot_id)`, e a memória usa a ordem desses números. Com a certificada antiga 43 e uma nova 3, o SQL real escolheu 43. Quando um número é reutilizado, a medição do recebido soma linhas antigas e novas, e a certificação pode falhar. A própria §7.3 prevê reiniciar com capturas 1/2, mas não resolve sua convivência com o dump antigo. | Definir, antes de descartar o Airbyte e restaurar o bruto, como serão preservadas a unicidade e a ordem das identidades de captura. Não resolver forçando `legacy_snapshot_id`: isso não separa linhas com o mesmo `sync_id` nem corrige a ordem do histórico. Se a solução alterar identidade ou estado incluído na recuperação, registrá-la com o Owner conforme §5, respeitando os ADRs aceitos. Exigir uma prova com captura antiga, job novo de número menor e número reutilizado. | **Fechado na revisão 4 — D50 decidida pelo Owner:** guarda na certificação (recusa `sync_id ≤ max(snapshot_id)` retido, motivo próprio) + regra operacional só para Airbyte novo (avançar a sequência de jobs, conferido antes da primeira sincronização), premissa sobre o interno do Airbyte declarada e isolada; a restauração real não toca no Airbyte; prova com 43 retida × job 3, 43 reutilizado, 44 (§6, §10). |
| RV12-2-03 | **bloqueante** | **§7.3, troca Orquestração → Streaming; §6, guarda de manutenção: o preflight não reconhece o Airflow que o clone cria.** O Compose usa o projeto `mvp_ed1` e não declara `container_name` para os serviços Airflow. Seus nomes gerados recebem o prefixo do projeto; `preflight.sh` e os alvos de pausa procuram `^airflow_`, e a consulta de trabalho usa literalmente `docker exec airflow_scheduler`. Com os nomes do Compose na simulação, o script disse “nada além dos bancos” e liberou streaming sem consultar nem parar Airflow (§14.3). É uma dependência do ambiente antigo que B5 precisa remover antes da troca, não um motivo para usar `FORCE`. | Resolver serviços pela composição/labels ou alinhar explicitamente a declaração de nomes e todos os consumidores. Incluir detecção, consulta de jobs, pausa, retomada e inventário. A contraprova deve usar os nomes gerados pelo Compose do clone; os testes atuais de preflight usam nomes sem o prefixo e não cobrem esse caso. | **Fechado na revisão 4 — vira B0, antes de tudo:** defeito vivo hoje (`docker ps` desta máquina mostra `mvp_ed1-airflow_*-1`), resolvido por rótulos do Compose em detecção, consulta de trabalho, pausa, retomada e inventário; testes com os nomes gerados e com outro projeto; contraprova na máquina com DAG rodando → recusa (§2.1). |
| RV12-2-04 | **bloqueante** | **§7.2, item 3: `make check` antes de subir os bancos não é uma verificação offline.** O Makefile para na primeira falha e chama `dbt-build` antes do pytest; este começa conectando ao armazém para `governance.garantir`. Com a falha de conexão simulada, a execução terminou aí e nem invocou pytest (§14.3). Classificar isso como achado ou esperar skips de integração não torna a sequência executável. | Executar nesse ponto somente verificações que não dependem de serviços, explicitamente selecionadas. Manter o `make check` completo na linha 4 da §7.3, após as duas ingestões. Não enfraquecer o contrato do check para acomodar a chamada prematura. | **Fechado na revisão 4:** `make check-offline` (segredos, `docs-check`, `pytest -m "not integracao"`; `test_consumo.py` ganha a marca) no clone antes dos bancos; `make check` intacto na linha 4 da §7.3 (§7.2). |
| RV12-2-05 | **bloqueante** | **§4: permanecem falsos negativos no detector histórico.** A expressão exige `:`/`=` logo depois da chave e não aceita a aspa que fecha uma chave JSON. Mesmo com `re.IGNORECASE`, a senha fictícia em `{"password": "…"}` produziu zero casamentos, enquanto ENV e YAML produziram um (§14.3). Além disso, excluir o arquivo inteiro por `*.example` permite ignorar uma credencial real ali gravada num commit antigo, mesmo depois de removida. | Cobrir explicitamente ENV, YAML, JSON e as formas presentes nos conectores, com caixa e aspas tratadas. Excluir valores reconhecidos como placeholders, sem transformar a extensão em dispensa de varredura. Acrescentar contraprovas de senha JSON removida/rotacionada e de segredo real em arquivo de exemplo, inclusive no histórico. Preservar a exigência de `.env.example` sem valores. | **Fechado na revisão 4:** expressão que aceita a aspa que fecha a chave, caixa ignorada, valor parando em aspa/vírgula — ENV, YAML e JSON; placeholders por valor, nenhuma extensão dispensa varredura; `.env.example` sem valores continua conferido; contraprovas JSON rotacionado e segredo real em `*.example` antigo (§4). |
| RV12-2-06 | **ajuste** | **§3 e §7.3, linha 6: o corte inicial não prova a chegada dos eventos novos.** `ATE_SEQ` é definido como máximo da origem no início. Se o produtor acrescenta eventos depois, o sink pode ter somente o snapshot inicial e satisfazer “todas as chaves até o corte” assim que o produtor termina. A contraprova deixou um evento novo ausente e nenhuma falta até o corte (§14.3). Também falta explicitar como `ALVO=stream-run`, que não termina sozinho, corre junto do produtor e de `ATE`; uma sequência bloqueante nunca chega ao alvo de espera. | No cenário de eventos novos, obter o corte final após o produtor terminar e confirmar que todo esse conjunto chegou antes de encerrar Beam/Prism. Declarar como o medidor inicia e acompanha os processos concorrentes, encerra apenas os que iniciou e propaga falha/prazo/interrupção. Testar produtor terminado com evento final ainda pendente, além do snapshot sem produtor. | **Fechado na revisão 4:** corte lido **depois** do produtor no cenário de eventos novos; `make medir CENARIO=streaming` declara como sobe, guarda o PID do Beam, produz, espera, encerra só o que iniciou e propaga falha/prazo/interrupção; testes: produtor terminado com evento pendente continua esperando; *snapshot* sem produtor fecha no corte inicial (§3). |

### 14.3 Evidências desta rodada

Contraprovas em `/tmp/rv12_r2_69hwb_7b`. Nenhum banco, contêiner ou pipeline foi alterado.
Os cenários abaixo são **simulados**; seus números não são novas medições dos dados de trabalho.

**Makefile vigente, executáveis substituídos por registradores [medido].** Copiado o Makefile
sem alterações para `make_simulado/`, com `.env` vazio e `python`, `dbt`, `pytest` e `alembic`
fictícios. O registrador detecta o texto de DROP sem executá-lo. Primeiro, `make dbt-build
RESET=1`; depois, `make check` com falha de conexão injetada na chamada de governança:

```text
RECONSTRUCAO_EXIT 0
RECONSTRUCAO_CHAMADAS ['governance garantir', 'DROP SNAPSHOTS', 'dbt build --full-refresh']
CHECK_SEM_BANCO_EXIT 2
CHECK_SEM_BANCO_CHAMADAS ['-m mvp_ed1.secrets_review', 'governance garantir']
Makefile real; python, dbt, pytest e alembic substituídos por registradores locais.
```

**Seleção e certificação de capturas [medido, em memória].** Renderizada a declaração real
`mvp_ed1.legacy.dbt.captura_selecionada()` com Jinja; substituída apenas a referência à tabela
por uma tabela SQLite de teste e retirado o cast final `::bigint`. Inseridas 40 certificações
`complete` para cada identidade, 43 e 3. Para a colisão, chamada a função real
`captura.decidir`: origem antes/depois com uma linha e hash `novo`; recebido com duas linhas
e hash `antigo+novo`, uma geração, sem intrusas:

```text
CAPTURAS_FICTICIAS_CERTIFICADAS [(43, 40), (3, 40)]
CAPTURA_ESCOLHIDA_PELO_SQL_REAL 43
CAPTURA_NOVA_NO_CENARIO 3
COLISAO_SYNC_ID_DECISAO incomplete
```

É prova da seleção e da consequência de reutilizar IDs. Não foi reinstalado Airbyte para
medir quais números ele atribuirá; o plano precisa garantir a continuidade, sem depender
de que a instalação nova por acaso ultrapasse todos os números retidos.

**Configuração do Compose e preflight [medido].** Executado
`docker compose --env-file .env -f docker/docker-compose.airflow.yml config --format json`,
capturando a saída e imprimindo **somente** projeto e declarações de nome de contêiner:

```text
COMPOSE_CONFIG_EXIT 0
COMPOSE_PROJECT mvp_ed1
AIRFLOW_CONTAINER_NAMES_EXPLICITOS {'airflow_apiserver': None, 'airflow_dag_processor': None, 'airflow_db': None, 'airflow_init': None, 'airflow_scheduler': None}
```

Executado o `docker/preflight.sh streaming --trocar` real com Docker/pgrep fictícios e leitura
de memória simulada em 12.000 MiB. O Docker fictício lista
`mvp_ed1-airflow_scheduler-1`, `mvp_ed1-airflow_apiserver-1` e
`mvp_ed1-airflow_dag_processor-1`; se consultado, reportaria DAG em execução. Saída:

```text
PREFLIGHT_SIMULADO_EXIT 0
[preflight] RAM disponível agora: 11.7 GB
[preflight] Já de pé: nada além dos bancos
[preflight] 'streaming' custa ~0.5 GB — sobraria 11.2 GB
[preflight] OK
PREFLIGHT_CHAMADAS ['ps --format {{.Names}}', 'ps --format {{.Names}}', 'ps --format {{.Names}}']
```

**Detector proposto [medido, valores fictícios].** Aplicada a expressão da §4, completando
`<valor>` com `[^\s]{8,}`, mais o padrão de URL e as cinco formas genéricas atuais. Usado
`re.IGNORECASE` para não depender da omissão dessa flag no texto. Mesma senha fictícia em
`PASSWORD=…`, `password: …` e `{"password": "…"}`:

```text
CASAMENTOS_COM_RE_I env 1
CASAMENTOS_COM_RE_I yaml 1
CASAMENTOS_COM_RE_I json 0
```

**Corte do streaming [contraprova do contrato, em memória].** Origem inicial `{1,2}`;
após o produtor, `{1,2,3}`; sink ainda `{1,2}`. Aplicada a condição descrita na §3:

```text
STREAM_CORTE_NO_INICIO 2
STREAM_CHAVES_FALTANTES_ATE_CORTE []
STREAM_CHAVES_NOVAS_FALTANTES [3]
```

O `stream-wait` ainda não existe; isto identifica a condição insuficiente no plano, não um
resultado de implementação.

### 14.4 Observações e limites

*Revisão 4 — onde cada observação foi parar:* inventário com `airbyte-abctl` e sem `kind`
(§7.1); `run_id` capturado por `dag-run` e duas durações (§3); 17 campos = chave + 16 lidos de
`COLUNAS_DO_EVENTO` (§7.3, linha 3).

- O inventário da §7.1 deve reconhecer também `airbyte-abctl`, cujo nome não contém
  `mvp_ed1`. A CLI `kind` não está no PATH desta sessão (`shutil.which('kind') is not None`
  devolveu `False`) nem é instalada por `make tools`; usar as ferramentas disponíveis ou
  declarar o pré-requisito, sem tratar comando ausente como inventário vazio.
- `dag-wait` precisa receber a identidade da execução que disparou: hoje `dag-run` descarta
  a saída de `airflow dags trigger`, e `dag-status` consulta a última execução. Explicitar
  a passagem do `run_id` no trabalho de B1. A diferença entre tempo do invólucro e tempo da
  DAG também deve ser registrada, pois o primeiro inclui disparo, fila e espera.
- A contagem do contrato de eventos é **17 campos**, sendo `movement_id` a chave e **16**
  restantes. A intenção da §6 pode ser cumprida comparando a chave e todos os demais,
  lendo a tupla `COLUNAS_DO_EVENTO`, sem manter outra lista manual.

**Não verificado:** implementação dos blocos; instalação num clone novo; restauração real
dos três dumps e suas dependências; preservação dos snapshots após rebuild; continuidade
real das identidades do Airbyte; ciclo completo e medições; `make check` completo; varredura
integral do histórico; links de todo o repositório. Não houve nova medição dos bancos nesta
rodada. Não foi executada nenhuma desmontagem, subida, sincronização ou restauração real.
