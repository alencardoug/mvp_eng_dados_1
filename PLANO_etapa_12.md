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
| C5 | Documentação coerente com o código | Revisão a olho | Verificador de links/âncoras; e a Execução Local já tem **três** desvios conhecidos (ordem `dbt-build`/`stream-up`, `dbt deps`, `.tools/`) a corrigir antes de servir de roteiro |
| C6 | Nenhum segredo no repositório **nem no histórico** | `secrets_review` sobre o rastreado, dependente do `.env` atual | Detecção independente dos valores, sobre todo *blob*, com os limites declarados e os achados tratados (D48) visíveis |
| — | Versão marcada no Git | Nenhuma *tag* | `v1.0.0` (D47) no *commit* que fecha M5 |

Tudo o que falta é **instrumento** (C2, C5, C6), **produto** (C4) ou **execução** (C1, C3).
Nenhum ADR novo: D49 muda o conteúdo do pacote como **consequência** de ADRs aceitos, e é a
Capacidade §3 que passa a dizer isso.

---

## 2. Ordem, e por quê

```
B1 medição ─┐
B2 segredos ├─► B4 pacote (fontes + memória do armazém,  ─► B5 do zero (desmonta as três ─► B6
B3 docs ────┘      do estado ATUAL, em janela parada)         composições; ciclo medido)
```

1. **B1, B2, B3 primeiro, em qualquer ordem** — código local, sem ambiente pesado; B1 mede B4 e
   B5; B2 e B3 entram no `make check` que B5 roda.
2. **B4 antes de B5**: o pacote guarda o estado **atual** — as fontes e a memória do armazém
   (D49) — e B5 destrói as três composições. O destino do estado permanente antes do `reset` é o
   pacote; o que o pacote não leva está listado na §6 como limite, não descoberto depois.
3. **B5 é o bloco caro** (~2 h de trocas, mais sincronizações e *snapshot*).
4. **B6 por último**: estado se documenta depois de medido.

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
| `dag-wait` | o `run_id` disparado por `dag-run` chega a estado terminal (`success`/`failed`) | prazo (`PRAZO=`, padrão 30 min) ou `failed` — o código de saída propaga |
| `stream-wait` | o livro (`raw.inventory_movements_stream`) tem as chaves da origem até um corte declarado (`ATE_SEQ=` = `max(event_sequence)` da origem no início) **e** o produtor terminou | prazo, ou o *pipeline* morreu |
| `docs-generate` | `dbt docs generate` termina (o servir sai da medição: `dbt-docs` continua servindo, e a prova de que responde é um `curl` no diário) | — |

A linha *Streaming* de B5 **encerra o Beam e o produtor** ao fim (`stream-wait` os espera; o
`medir` mata o que sobrou, registrando) — sem isso a troca para `airbyte-up` recusa, e a recusa
seria correta.

**Prova.** `tests/test_medicao.py`: o amostrador acha o mínimo e o máximo numa série sintética e
reporta intervalo e contagem; a linha gerada é a da tabela; `ALVO` inexistente falha antes de
amostrar; `ATE` que falha propaga o código. Sem banco. **Oráculos do bloco**, em B5: a duração
de `make medir ALVO=dbt-build` é **maior** que a do `run_results.json` (o alvo inclui
`governance.garantir` e a inicialização do dbt) e a diferença é registrada, não tolerada por
um ±5 s fixo; a duração de `ALVO=dag-run ATE=dag-wait` bate com `end_date − start_date` do
`dag-status`.

---

## 4. B2 — segredos no histórico

**O que existe [medido].** `mvp_ed1.secrets_review`: compara o rastreado com os **valores** do
`.env` atual (`secret_values(read_env())`) e com cinco formas genéricas (chave privada, `AKIA`,
`ghp_`, `xox`, `private_key_id`); acusa `.env` no índice. Depois de uma rotação, o valor antigo
não é mais conhecido → o *blob* antigo não casa com nada (§13.2). D45 troca o `.env` antes da
validação final: o modo atual seria cego exatamente onde a etapa exige enxergar.

**O que muda [planejado].** `python -m mvp_ed1.secrets_review --historico`, com detecção
**independente dos valores atuais** — uma declaração nova, ao lado das existentes:

- **atribuições**: `(PASSWORD|PASSWD|SECRET|TOKEN|API_KEY|PRIVATE_KEY|CREDENTIAL)[A-Z0-9_]*\s*[=:]\s*['"]?<valor>`
  com `<valor>` de 8+ caracteres sem espaço; **credencial em URL**: `://[^/:@\s]+:[^@\s]+@`;
  mais as cinco formas genéricas;
- **placeholders declarados**, não adivinhados: valor vazio, `<…>`, `${…}`, `{{ … }}`,
  `changeme`, `example`, `xxx…`, e os arquivos `*.example` — cada exclusão é uma linha numa lista
  no módulo, com o motivo;
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
de pulados.

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
| `manifesto.json` | `seed`, `as_of_date`, `alembic current` dos **dois bancos de origem**, `governance._versions` do armazém (é o oráculo de versão dele — não há Alembic lá, e não haverá), `max(event_sequence)`, `git rev-parse HEAD`, contagens e tamanhos por tabela dos três *dumps*, hora do corte | gerado |
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
8. **Reconstruir**: `airbyte-up` → `sync-airbyte RESET=1` → `sync-legacy` → `dbt-build RESET=1`
   → `make check`.
9. **Oráculos explícitos**, no roteiro executável, não só o `PASS`: as contagens de `oltp` e
   `legacy` = manifesto; a comparação dos **dois caminhos** da Execução Local §3.2 — chaves só
   num lado = 0, linhas com coluna de negócio diferente (as 16 de `COLUNAS_DO_EVENTO`) = 0, pares
   armazém/SKU com saldo diferente = 0, soma dos deltas igual — **é ela que prova o livro
   restaurado**; `caminhos_de_ingestao_reconciliam` lê *flags* de chegada e tempo, não os
   *payloads*, e só complementa; a memória de exclusões renasce igual (4 registros; clientes
   `1`,`2`,`3`); a captura selecionada é certificada; `governance._versions` intacto.

O `pg_restore` ocupa o lugar do `seed-data` do procedimento da §3.2; o resto da §3.2 é o que a
sequência acima aplica, na ordem que ela já tinha.

**Prova sem banco.** `tests/test_recovery.py`: manifesto gerado e lido; *checksum* alterado
acusado; árvore suja recusada; `restore` sem `RESTAURAR=1` recusado antes de tocar em banco;
**composição** `recovery-restore RESTAURAR=1` num Makefile de simulação com a macro real do
preflight: os submakes de subida **não** anunciam "preflight ignorado" (a contraprova do
RV12-06); `RECOVERY_DIR` relativo é rejeitado.

---

## 7. B5 — o ciclo do zero, medido

**Pré-condição:** B1–B4 entregues, pacote candidato montado e verificado, Execução Local
corrigida nos três desvios da §0 (senão o roteiro está errado antes de começar).

### 7.1 Desmontar — no *checkout* antigo, que tem `.tools/`

Com os processos parados (preflight sem trabalho):

1. `make stream-down FORCE=1` — tópicos, *offsets* do Connect, **e os *slots* enquanto o
   `source_db` antigo ainda existe** (RV12-03).
2. `make airflow-down FORCE=1` — metadados e histórico de execuções.
3. `make airbyte-down` — o cluster `kind` cai; o diretório antigo do `abctl` é **apartado**
   (renomeado com data) e isso fica no diário — é a armadilha do `PG_VERSION` da Execução Local
   §6, reproduzida com o remédio documentado.
4. `make reset` — os três volumes PostgreSQL (confirmação interativa, como sempre).
5. **Inventário**: `docker volume ls`, `docker ps -a`, `kind get clusters` filtrados pelo nome
   do projeto → **vazio**. Colado no diário.

### 7.2 Preparar o clone

1. `git clone` de `origin/main` em outro diretório; `make env` (senhas novas); `make install`
   — que passa a incluir **`dbt deps`** com o `package-lock.yml` versionado (RV12-07: hoje
   `uv sync` só); `make tools` (baixa `abctl` e Terraform fixados para o `.tools/` do clone —
   tempo medido, é a primeira vez que o alvo roda do zero desde a Etapa 5).
2. `RECOVERY_DIR=<caminho absoluto do pacote no checkout antigo>` exportado no `.env` do clone.
3. `make check` **antes de subir nada**: segredos, `docs-check`, e o que falhar sem banco é
   achado (o pytest sem banco pula os de integração — a lista de *skips* é colada, com motivo).

### 7.3 O ciclo, na ordem certa — cada linha sob `make medir`

A ordem **não** é a da Execução Local §3 de hoje: o *streaming* vem antes do primeiro
`dbt-build` completo (RV12-04), e a §3 é corrigida para dizer isso.

| # | Cenário | Alvos | De pé | `ATE` | O que a linha prova |
|---|---|---|---|---|---|
| 1 | Base | `up` → `migrate` → `seed-data` → `migrate-legacy` → `seed-legacy` | bancos | — | migrações do zero; cobertura (`test_cobertura`, manifesto do legado novo) |
| 2 | Carga | `airbyte-up` → `airbyte-config` → `sync-airbyte` → `sync-legacy` | + Airbyte | — | `raw`, `raw_legacy`, captura 1 certificada; o pico da etapa |
| 3 | Streaming — o *snapshot* | `stream-up` (pausa o Airbyte) → `stream-run` → `stream-wait` | + streaming | `stream-wait` com `ATE_SEQ` = `max(event_sequence)` da origem | o livro quente igual à origem (comparação da §3.2, os quatro zeros); Beam e produtor **encerrados** ao fim |
| 4 | Transformação | `airbyte-up` (pausa o streaming) → `dbt-build` → `check` | + Airbyte | — | o primeiro `build` completo: `PASS=`, `caminhos_de_ingestao_reconciliam`, as oito fronteiras |
| 5 | Orquestração | `airflow-up` → `dag-run` | + Airflow (Airbyte de pé: o par permitido) | `dag-wait` | 13 tarefas `success`, tempo da DAG, captura 2 certificada |
| 6 | Streaming — eventos novos | `stream-up` (pausa Airbyte e Airflow) → `stream-run` → `stream-produce LIMITE=n` → `stream-wait` → `stream-alerts` | + streaming | `stream-wait` | eventos além do *snapshot* chegam; alerta emitido; encerrados ao fim |
| 7 | Reconciliação dos caminhos | `airbyte-up` → `sync-airbyte` → `dbt-build` | + Airbyte | — | os dois caminhos iguais com os eventos novos |
| 8 | Catálogo | `docs-generate` → `catalog` | bancos | — | tempo; `sensitivity --check`, `lineage --check` sem diferença; `curl` na porta do `dbt-docs` no diário |
| 9 | Recuperação | `recovery-restore RESTAURAR=1` (a sequência da §6, passo a passo, cada um medido) → `recovery-promote` | conforme o passo | — | C4 inteira: as fontes **e a memória** de volta, o livro igual, a memória de exclusões renascida |

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
   `recovery-*`); §3.2 apontando para a sequência de restauração; §4 com os alvos novos; §6 com
   a armadilha do `PG_VERSION` conferida.
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

## 11. Riscos deste plano

- **`reset` e as três desmontagens são destrutivos** e o pacote é a única volta — por isso B4
  antes, `verify` antes do `reset`, e o inventário vazio colado antes de `up`.
- **Tempo de relógio de B5** (~2 h de trocas + sincronizações + dois *snapshots* + a
  restauração); não cabe num fim de tarde. O estado da estação é anotado, não controlado.
- **Divergência entre Execução Local e realidade** é o achado esperado — três já conhecidas
  (§0), corrigidas antes de B5; as que B5 achar, corrigidas antes de fechar.
- **`stream-wait` sem corte** mediria para sempre: `ATE_SEQ` é obrigatório.
- **R11**: o preflight decide; `FORCE=1` só com a sua autorização, e **nunca** herdado por um
  alvo composto (§6).

---

## 12. O que pedir ao outro agente

1. **Deste plano, revisão 3** — antes do código: os nove achados estão fechados na letra e no
   espírito? Sobrou furo na ordem (§7.1 → §7.3 → §6) ou oráculo que ainda é só um `PASS`?
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
