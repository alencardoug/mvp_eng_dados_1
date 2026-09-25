# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

**Esta é a revisão final da Etapa 12** — a última antes do aceite do Owner, que fecha o **M5** com a
*tag* `v1.0.0`. Três coisas nunca foram revisadas por outro agente, e são o objeto dela: **B2 e B3**
(`6453bb5` e o caminho, fora do intervalo — §2), que o plano deixou para cá; **as correções que o
B5 obrigou**, feitas durante a execução; e **o B6**, os documentos com o que o B5 mediu. O que as
seis rodadas da entrega B0/B1/B4 e as três do roteiro do B5 já confirmaram não volta à mesa, salvo
se algo aqui o contradisser.

A pergunta de fundo é a do plano: **os seis critérios da Etapa 12 estão satisfeitos, e cada ✓ tem
medição?** Os critérios, com a evidência de cada um, estão no
[plano](docs/plano_de_desenvolvimento.md#etapa-12--fechamento-da-fase-local--m5); o diário do B5,
literal, está no fim da §3. Uma pergunta é do Owner e está nas
[pendências](docs/pendencias.md#aceite-da-etapa-12): se a D48 e a varredura do histórico, que
entraram na Governança §9 sem ADR, são alteração da política (a §10 pede ADR) ou aplicação dela —
uma opinião do revisor sobre isso ajuda.

Intervalo: `7b0bea6..807a904` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
45395e3 fix: o airbyte-config aplica um recurso por vez
f198254 fix: o stream-wait lê o livro pelo nome qualificado do destino
cc9c89f fix: a espera do streaming trata o livro que ainda não existe como vazio
11c0b66 fix: o dag-run só dispara com a DAG vista despausada, e lê o dag_run_id
b42b533 docs: a linha 6 do B5 produz eventos bastantes para o alerta
f76fa7e fix: o dbt-docs serve depois de gerar
d0cbd75 test: o teste da restauração sem autorização não herda o RESTAURAR do ambiente
ea67800 docs: o roteiro do B5 conta as fronteiras que existem
1a362c9 docs: registra o B5 executado
e73364a docs: a Capacidade registra o ciclo do B5 e o ponto de recuperação entregue
3d807ff docs: a Execução Local conferida contra o B5
19a5801 docs: o ADR-0044 ganha as consequências da identidade e das gerações num Airbyte novo
7d314a9 docs: a Governança fixa a política dos segredos do histórico e o respaldo da retenção
807a904 docs: fecha a Etapa 12 — definição de pronto aplicada, aguardando a revisão final e o aceite
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 17 arquivos

- `Makefile`
- `PLANO_etapa_12.md`
- `README.md`
- `docker/airflow_cli.sh`
- `docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/execucao_local.md`
- `docs/governanca_de_dados.md`
- `docs/pendencias.md`
- `docs/plano_de_desenvolvimento.md`
- `docs/riscos.md`
- `docs/segredos_tratados.yml`
- `src/mvp_ed1/streaming/espera.py`
- `tests/test_makefile.py`
- `tests/test_medicao.py`
- `tests/test_preflight.py`
- `tests/test_recovery.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega.** Três conjuntos, e a declaração de cada um:

1. **As correções que o B5 obrigou** (`45395e3`, `f198254`, `cc9c89f`, `11c0b66`, `f76fa7e`,
   `d0cbd75`). Nenhuma foi revisada por outro agente: nasceram durante a execução, cada uma com o
   teste da forma observada e a linha do B5 refeita. A declaração é o código de cada uma — revisão
   integral:
   - `Makefile`: a receita do `airbyte-config` (`-parallelism=1`) e a do `dbt-docs` (o gerar
     virou a dependência `docs-generate`);
   - `docker/airflow_cli.sh`: `airflow_despausada` e o laço de `airflow_disparar` — a prova de
     despausa passou a ser a DAG vista na enumeração, não o código de saída do `unpause`; e o
     `dag_run_id`;
   - `src/mvp_ed1/streaming/espera.py`: o destino pelo nome qualificado da configuração, e o livro
     que ainda não existe lido como vazio — só `UndefinedTable`; outra falha continua subindo;
   - `tests/test_recovery.py::test_restore_sem_autorizacao_nao_toca_em_banco`: o teste tira o
     `RESTAURAR` do ambiente. A receita do `recovery-restore` **não** mudou (diário, observações).

   Derivado, por amostragem: os testes novos de `test_makefile.py`, `test_medicao.py` e
   `test_preflight.py` — conferir que reproduzem a forma que o Airflow 3.2.2 e o armazém novo
   devolveram, e não uma forma imaginada.

2. **B2 e B3, fora do intervalo** — ficaram para esta revisão por decisão do plano. `git show
   6453bb5` (a entrega), com `0b89b3d` (a credencial do banco de metadados do Airflow saiu da
   composição para o `.env`) e `bb783f4` (o verificador de ADR) no caminho. Revisão integral:
   - `src/mvp_ed1/secrets_review.py` — o modo `--historico`: detecção por **forma**, os moldes de
     referência aceitos (o que deixa de ser achado) e o limite declarado da última regra;
   - `docs/segredos_tratados.yml` — os 7 registros, cada um com tratamento e motivo (D48);
   - `src/mvp_ed1/docs_check.py` — o que conta como link, âncora e citação de ADR quebrados, e a
     regra de *slug* do GitHub, com a exceção do sublinhado.

   Derivado, por amostragem: `tests/test_secrets_review.py`, `tests/test_docs_check.py`,
   `tests/test_verificador_adr.py`.

3. **O B6 — os documentos com o que o B5 mediu.** A declaração é o texto; os números derivam do
   diário (literal na §3 abaixo) e dos registros do `make medir`. Revisão integral do texto:
   [Capacidade](docs/capacidade_e_recuperacao.md) §2.12 e §3 (reescrita para D49 e D51),
   [Execução Local](docs/execucao_local.md) §2–§6, o
   [ADR-0044](docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md) (só as duas
   consequências datadas; o texto aceito não mudou), a [Governança](docs/governanca_de_dados.md)
   §8 e §9, o [plano](docs/plano_de_desenvolvimento.md) (Etapa 12), os [riscos](docs/riscos.md)
   (R6, R7, R10, R11), as [pendências](docs/pendencias.md) (o aceite, a §6) e o README. Por
   amostragem: conferir cinco números de cada documento contra o diário.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:124: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:227: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:272: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:751: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:778: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:794: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
579 passed, 8 skipped in 261.59s (0:04:21)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

**Os três avisos no fim da saída acima** vêm do *stderr* da etapa 3 do `check` (o gerador cola o
*stderr* depois do *stdout*) e já estavam no `check` da linha 4 do B5: em
`dbt/models/trusted/legacy/legacy_classifications.sql`, `c(name, position)` é o alias de
`jsonb_array_elements_text(…) with ordinality` — nomes de coluna do contrato do legado, não dado de
pessoa —, e a derivação da linhagem não tem tabela de onde lê-los. Tratá-los como técnicos é a
classificação certa; o aviso é o limite declarado da derivação, não falha.

### Colhidos para este dossiê, fora do `comandos.txt`

**`make medir ALVO=check`** — sobre a árvore que virou `807a904`, antes de duas correções de texto
no plano (o `docs-check` e a revisão de segredos foram refeitos depois delas, sem achado). O
registro inteiro está em `data/medicoes/b6/20260925T163142Z_check.log`.

```
[medir] check — início 2026-09-25T16:31:42Z; estação: 3,3 GB livres, de pé: Airbyte,bancos
16:33:17  Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
SKIPPED [1] tests/test_carga.py:51: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_deteccao.py:124: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:227: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:272: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:751: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:778: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
SKIPPED [1] tests/test_legado_deteccao.py:794: a captura 49 não é o lote 3f9e5088c722 do manifesto (2 tabelas divergem: ['campaigns', 'customers']); sincronize o lote corrente antes de comparar vereditos
579 passed, 8 skipped in 294.00s (0:04:54)
check: as quatro etapas passaram
| check | Airbyte,bancos | 7m 22s | 2,3 GB | 4,0 GB | 107 amostras, uma a cada 4,1 s (pausa de 2 s) | 628.6 MB |
[saída 0]
```

**`make secrets-history`**, depois de `807a904`:

```
tratado: 310c9781df0e  tests/test_secrets_review.py:27  nWAREHOUSE_DB_PASSWORD=\n*** (23 caracteres)  [atribuição]  → nenhum — valor fictício, nunca usado em lugar nenhum — Fixture do próprio teste da revisão de segredos, escrita para ser achada. Não corresponde a credencial de nenhum serviço, passado ou presente. Em 20/09/2026 o arquivo passou a montar esses valores em partes, para que o modo rastreado deixe de acusá-lo; os blobs antigos permanecem.
tratado: 310c9781df0e  tests/test_secrets_review.py:29  nWAREHOUSE_DB_PASSWORD=s3*** (71 caracteres)  [atribuição]  → nenhum — valor fictício, nunca usado em lugar nenhum — Fixture do próprio teste da revisão de segredos, escrita para ser achada. Não corresponde a credencial de nenhum serviço, passado ou presente. Em 20/09/2026 o arquivo passou a montar esses valores em partes, para que o modo rastreado deixe de acusá-lo; os blobs antigos permanecem.
tratado: 310c9781df0e  tests/test_secrets_review.py:46  password=s3*** (31 caracteres)  [atribuição]  → nenhum — valor fictício, nunca usado em lugar nenhum — A mesma fixture, na forma YAML que o teste usa para provar o detector.
tratado: 310c9781df0e  tests/test_secrets_review.py:64  forma genérica=--*** (31 caracteres)  [forma conhecida]  → nenhum — cabeçalho sem material de chave — Cabeçalho `-----BEGIN … PRIVATE KEY-----` escrito inteiro para provar o detector de formas conhecidas. Não acompanha chave alguma. O teste já o monta em partes hoje; o blob antigo permanece.
tratado: a0a076702859  tests/test_secrets_review.py:27  nWAREHOUSE_DB_PASSWORD=\n*** (23 caracteres)  [atribuição]  → nenhum — valor fictício, nunca usado em lugar nenhum — A mesma fixture, num commit anterior do mesmo arquivo.
tratado: a0a076702859  tests/test_secrets_review.py:29  nWAREHOUSE_DB_PASSWORD=s3*** (71 caracteres)  [atribuição]  → nenhum — valor fictício, nunca usado em lugar nenhum — A mesma fixture, num commit anterior do mesmo arquivo.
tratado: a0a076702859  tests/test_secrets_review.py:46  password=s3*** (31 caracteres)  [atribuição]  → nenhum — valor fictício, nunca usado em lugar nenhum — A mesma fixture, na forma YAML, no commit anterior.
revisão do histórico: nada não tratado (7 achado(s), todos registrados; 0 blob(s) pulado(s))
[saída 0]
```

**As gerações do bruto retido, agora** — só leitura, no armazém restaurado:

```
$ psql … -At -c "select min(_airbyte_generation_id), max(_airbyte_generation_id),
    count(*) filter (where _airbyte_generation_id < 0), count(*) from raw_legacy.brands"
-27|4|27|28
```

**O `abctl` fixado não fixa o Airbyte** — `.tools/abctl local install --help`, v0.30.4:

```
      --chart=STRING            Path to chart.
      --chart-version=STRING    Version to install.
      --no-browser              Disable launching a browser post install.
```

**A versão do Airbyte instalada no B5** — só leitura, as imagens dos *pods*:

```
$ docker exec airbyte-abctl-control-plane kubectl get pods -n airbyte-abctl \
    -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | sort -u
airbyte/bootloader:2.3.0
airbyte/cron:2.3.0
airbyte/db:1.7.0-17
airbyte/manifest-server:7.28.2
airbyte/server:2.3.0
airbyte/worker:2.3.0
airbyte/workload-api-server:2.3.0
airbyte/workload-launcher:2.3.0
temporalio/auto-setup:1.27.2
```

### O diário do B5, literal

`data/medicoes/diario_b5.md` do clone, fora do Git — as saídas inteiras estão em
`data/medicoes/b5/`, indexadas em `indice.tsv`. Colado dentro de uma cerca para que os títulos dele
não se misturem aos deste dossiê:

````markdown
# Diário do B5 — o ciclo do zero, medido

Roteiro: `PLANO_etapa_12.md` §7, revisão 10 (`7b0bea6`, revisão encerrada em 25/09/2026).
Autorização do Owner (P6): 25/09/2026, na conversa ("authorized"). Clone: `~/Projetos/mvp_eng_dados_1`.
*Checkout* antigo: `~/Projetos/mvp_ed1`. Uma entrada por comando: hora (UTC), diretório, comando,
código de saída, as linhas que servem de oráculo e **desvio** (não, ou o quê). As saídas inteiras
estão em `data/medicoes/b5/`, indexadas em `indice.tsv`.

Este arquivo nasce no *checkout* antigo, porque o clone ainda não existe, e passa para o clone
depois da linha 2 do §7.2.

## Pré-condições — P4, P5, P7

| Hora (UTC) | Diretório | Comando | Saída | Oráculo | Desvio |
|---|---|---|---|---|---|
| 12:32:14 | antigo | `make preflight ALVO=trabalho` | 0 | "nenhum trabalho em andamento — janela parada." | não |
| 12:32:20–12:32:41 | antigo | `make recovery-pack` (P4, D61) | 0 | corte `2026-09-25T12:32:21+00:00`, `commit` `7b0bea6`; "candidato pronto"; o aviso de `data/source/geracao.json` ausente, como no candidato anterior | não |
| 12:42:41–12:42:53 | antigo | `make recovery-verify CONTRA_O_BANCO=1` | 0 | contagens, Alembic, versões do armazém e corte do livro; 21 fatias da quarentena; 4 SCD; 11 capturas; 40 partições por geração como no manifesto | não |
| 12:43:02 | antigo | `mkdir ~/mvp_ed1-recovery-20260925T123221Z && cp -a data/recovery/candidato ~/mvp_ed1-recovery-20260925T123221Z/` (P5) | 0 | 32 MB | não |
| 12:43:02 | a cópia | `sha256sum -c checksums.sha256` | 0 | nove `SUCESSO` | não |
| 12:43:02 | antigo | `RECOVERY_DIR=~/mvp_ed1-recovery-20260925T123221Z make recovery-verify` | 0 | "[recovery] conferindo …/mvp_ed1-recovery-20260925T123221Z/candidato"; checksums, manifesto e os três dumps | não |
| 12:43 | — | `grep MemAvailable /proc/meminfo` (P7) | — | 4,2 GiB livres, com o Airbyte e os bancos de pé | não |

Entre o corte (12:32:21) e o desmonte, nada roda (P4).

## §7.1 — o desmonte, no *checkout* antigo

| # | Hora (UTC) | Comando | Saída | Oráculo | Desvio |
|---|---|---|---|---|---|
| 1 | 12:43:22 | `make preflight ALVO=trabalho` | 0 | "janela parada" | não |
| 2 | 12:43:29 | `make stream-down FORCE=1` | 0 | "slot 'mvp_inventory_movements': já ausente"; `select count(*) from pg_replication_slots` → 0, com o `source_db` antigo de pé; nenhum contêiner nem volume do *streaming* | não |
| 3 | 12:43:36–12:43:37 | `make airflow-down FORCE=1` | 0 | os cinco contêineres do Airflow e os volumes `mvp_ed1_airflow_db_data` e `mvp_ed1_airflow_logs` removidos | não — sobra `airflow-local_postgres-db-volume`, de outro projeto, fora do filtro |
| 4 | 12:43:55–12:44:03 | `make airbyte-down` | 0 | "Airbyte uninstallation complete"; o nó fora, e o volume anônimo `/var` dele (`7750351f…`) removido junto — a premissa do dossiê, agora medida | não |
| 4 | 12:44:15 | `mv ~/.airbyte/abctl/data ~/.airbyte/abctl/data.202609250944` e `mv airbyte/terraform.tfstate airbyte/terraform.tfstate.202609250944` | 0 | os dois apartados; o `git status` do *checkout* antigo continua limpo | não |
| 5 | 12:44:24–12:44:25 | `make reset`, respondendo `s` | 0 | três contêineres e três volumes PostgreSQL removidos; "Volumes apagados" | não |
| 6 | 12:44:33 | `docker network rm mvp_ed1_default` (D57) | 0 | a rede do projeto fora | não |
| 7 | 12:44:33 | inventário por `mvp_ed1` e `airbyte-abctl` | 0 | contêineres, volumes e redes: vazio; a rede `kind` fica | não |

Memória depois do desmonte: 8,1 GiB livres.

## §7.2 — o clone, em `~/Projetos/mvp_eng_dados_1` (D58)

| # | Hora (UTC) | Diretório | Comando | Saída | Oráculo | Desvio |
|---|---|---|---|---|---|---|
| 1 | 12:44:50–12:44:57 | `~/Projetos` | `git clone git@github.com:alencardoug/mvp_eng_dados_1.git ~/Projetos/mvp_eng_dados_1` | 0 | `HEAD` = `7b0bea6`, a ponta revisada e o `commit` do candidato | não |
| 2 | 12:45:17 | clone | `make env`; `export RECOVERY_DIR=/home/doug/Projetos/mvp_ed1/data/recovery` no *shell* | 0 | `.env` 600; as 4 senhas diferentes das do *checkout* antigo; o `make` do clone vê o `RECOVERY_DIR` do antigo (`--eval`) | não |
| 3 | 12:45:32–12:45:42 | clone | `make install` | 0 | 93 pacotes; `dbt_utils` 1.4.1, `dbt_expectations` 0.10.10, `dbt_date` 0.21.0 | não |
| 4 | 12:45:46–12:45:53 | clone | `make tools` | 0 | `abctl` `v0.30.4`, Terraform `v1.16.1`; 7 s | não |
| 5 | 12:46:01–12:47:59 | clone | `make check-offline`, com nada de pé | 0 | "check-offline: as três etapas passaram"; **441 passed, 5 skipped, 134 deselected** — os cinco pulos de `sem dbt/target/manifest.json` (1 de `test_acesso_macro.py`, 4 de `test_linhagem.py`); os 134 de integração em 13 arquivos | não |

O diário e os *logs* passaram para o clone depois da linha 2.

## §7.3 — o ciclo, no clone

A linha da Capacidade que cada `make medir` imprime vai literal: alvo, o que estava de pé, duração,
`MemAvailable` mínimo, soma máxima dos contêineres, amostras e o tamanho da soma dos três bancos.

### Linha 1 — base

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 12:48:19–12:48:28 | `make medir ALVO=up` | 0 | `\| up \| nada \| 0m 07s \| 8,0 GB \| 0,1 GB \| 2 amostras, uma a cada 2,0 s (pausa de 2 s) \| 22.0 MB \|`; a rede `mvp_ed1_default` criada pela garantia às 12:48:20 (D55, D57); os três bancos `healthy` | não |
| 12:48:37–12:48:40 | `make medir ALVO=migrate` | 0 | `\| migrate \| bancos \| 0m 02s \| não medido \| não medido \| 0 amostras (pausa de 2 s) \| 24.9 MB \|`; `deae0e5943e0` | não |
| 12:48:46–12:49:09 | `make medir ALVO=seed-data` | 0 | `\| seed-data \| bancos \| 0m 21s \| 7,8 GB \| 0,1 GB \| 5 amostras, uma a cada 4,2 s (pausa de 2 s) \| 78.5 MB \|`; 252.955 linhas; `data/source/geracao.json` gravado | não |
| 12:49:17–12:49:23 | `make medir ALVO=seed-legacy` | 0 | `\| seed-legacy \| bancos \| 0m 04s \| 7,9 GB \| 0,2 GB \| 1 amostras (pausa de 2 s) \| 84.1 MB \|`; catálogo v9, semente 20260906, fator 0.05; 12.747 linhas; 108 achados em 89 ocorrências; cobertura 24/24; manifesto `3f9e5088…`, o mesmo lote de antes | não |
| 12:49:32–12:49:35 | `make migrate-status`; `make migrate-legacy-status` | 0 | `deae0e5943e0 (head)`; `f558a05ce90e (head)`; "No new upgrade operations detected." | não |

A cobertura é conferida no `check` da linha 4.

### Linha 2 — carga

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 12:49:51 | `make preflight ALVO=airbyte` | 0 | 8,0 GB livres; o Airbyte custa ~4,9 GB, sobrariam 3,1 GB; OK | não |
| 12:49:58–13:02:48 | `make medir ALVO=airbyte-up` | 0 | `\| airbyte-up \| bancos \| 12m 47s \| 5,3 GB \| 3,7 GB \| 175 amostras, uma a cada 4,4 s (pausa de 2 s) \| 81.4 MB \|`; "Airbyte installation complete", sem o `PG_VERSION` — instalação limpa; as imagens baixadas de novo, porque o `/var` do nó antigo saiu com ele | não — observação: o `abctl local install` abriu um navegador no fim (uma linha de VAAPI do Chromium caiu na saída) |
| 13:03:05–13:03:19 | `make airbyte-config AUTO=1` | **2** | "Plan: 6 to add"; três criados (as duas fontes e o destino `legacy`); o destino `retail` recusado com **500**: `CREATE TABLE IF NOT EXISTS secrets …` — `duplicate key value violates unique constraint "pg_type_typname_nsp_index"` | **sim** — num Airbyte recém-instalado a tabela de segredos nasce na primeira escrita, e as criações paralelas do Terraform colidiram nela; no ambiente antigo ela existia desde a instalação |
| 13:04:05 | a listagem da API (fontes, destinos, conexões) | 0 | 2 fontes, 1 destino, 0 conexões — igual ao estado do Terraform; sem órfão | — |
| — | correção na origem, no clone: `45395e3` "fix: o airbyte-config aplica um recurso por vez" (`-parallelism=1`, com o teste; `test_makefile.py` 85 passed) | — | — | a correção não muda o que a linha 1 provou; o ciclo segue |
| 13:05:37–13:07:38 | `make airbyte-config AUTO=1`, refeito | 0 | "Plan: 3 to add"; o destino `retail` e as duas conexões; "Apply complete! Resources: 3 added" | não |
| 13:07:38 | a listagem da API | 0 | 2 fontes, 2 destinos, 2 conexões (`oltp_para_raw`, `legacy_para_raw_legacy`) | não |

| 13:08:00–13:11:22 | `make medir ALVO=sync-airbyte` | 0 | `\| sync-airbyte \| Airbyte,bancos \| 3m 18s \| 2,4 GB \| 5,3 GB \| 48 amostras, uma a cada 4,1 s (pausa de 2 s) \| 152.2 MB \|` — o pico da etapa; "concluída: 247.870 linhas" | não — a diferença para as 252.955 da origem fica para as reconciliações do `check` da linha 4 |
| 13:11:36–13:14:13 | `make medir ALVO=sync-legacy` | 0 | `\| sync-legacy \| Airbyte,bancos \| 2m 34s \| 2,8 GB \| 4,9 GB \| 37 amostras, uma a cada 4,1 s (pausa de 2 s) \| 158.5 MB \|`; 12.747 linhas; "certificado ee99f29fa9a6: complete · snapshot 2 · tabelas {'complete': 40}" — a identidade é o job 2 que o Airbyte novo devolveu, e nada retido colide (RV12-4-05) | não |

### Linha 3 — o *snapshot* do *streaming*

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 13:15:02–13:16:03 | `make medir CENARIO=streaming` | **2** | o preflight pausou o Airbyte (7,1 GB livres depois); o Beam sob guarda; corte `event_sequence <= 13700`; o `stream-wait` morreu em `AttributeError: 'Destino' object has no attribute 'relacao'`; o Beam encerrado limpo | **sim** — `espera.pendentes` sem `destino=` lia um atributo que a configuração não tem (é `qualificado`); o teste do oráculo passava o destino à mão, e o caminho padrão nunca tinha rodado |
| — | correção no clone: `f198254` "fix: o stream-wait lê o livro pelo nome qualificado do destino" (com o teste; `test_medicao.py` 34 passed) | — | — | — |
| 13:18:05–13:18:10 | `make stream-down FORCE=1 && make stream-reset-sink FORCE=1` — para refazer a linha do zero | 0 | o *slot* removido; o volume do Redpanda fora; o livro vazio (a tentativa não tinha gravado nada) | — |
| 13:18:18–13:19:06 | `make medir CENARIO=streaming`, refeito | **2** | corte 13700; o `stream-wait` morreu em `UndefinedTable: relation "raw.inventory_movements_stream" does not exist` | **sim** — num armazém novo, a tabela do livro nasce quando o pipeline sobe (`sink.garantir_tabela`), segundos depois de a espera começar; no ambiente antigo ela existia havia meses |
| — | correção no clone: `cc9c89f` "fix: a espera do streaming trata o livro que ainda não existe como vazio" (com o teste; 35 passed) | — | — | — |
| 13:21:18–13:21:23 | `make stream-down FORCE=1 && make stream-reset-sink FORCE=1` | 0 | o mesmo | — |
| 13:21:28–13:22:43 | `make medir CENARIO=streaming`, refeito | 0 | `\| cenario:streaming \| bancos \| 1m 12s \| 5,5 GB \| 1,4 GB \| 17 amostras, uma a cada 4,1 s (pausa de 2 s) \| 165.3 MB \|`; "livro alcançou a sequência 13700: 13700 eventos em 26.0s"; o Beam encerrado pelo SIGINT, `encerramento: limpo` no registro | não — observação: a linha `ERROR apache_beam…data_plane: Failed to read inputs` sai no encerramento, depois do SIGINT |
| 13:22:55 | `leitura.comparar_caminhos(armazém, 13700)`, pelo Python — o roteiro nomeia os quatro zeros, não o comando | 0 | `so_no_lote 0`, `so_no_fluxo 0`, `payloads_diferentes 0`, `saldos_diferentes 0`; 13.700 linhas em cada caminho; somas 701.841 = 701.841 | não |

As duas correções não mudam o que as linhas 1 e 2 provaram; o ciclo segue.

### Linha 4 — transformação

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 13:23:47–13:25:16 | `make airbyte-up` | 0 | o preflight pausou o *streaming* (7,0 GB livres depois); "cluster pausado — retomando em vez de reinstalar"; a API pronta | não |
| 13:25:23–13:27:12 | `make medir ALVO=dbt-build` — o primeiro *build* completo | 0 | `\| dbt-build \| Airbyte,bancos \| 1m 41s \| 3,8 GB \| 3,6 GB \| 24 amostras, uma a cada 4,1 s (pausa de 2 s) \| 303.5 MB \|`; `PASS=905 WARN=0 ERROR=0`; `caminhos_de_ingestao_reconciliam` PASS; os 14 testes da tag `fronteira` (`dbt ls --select tag:fronteira`) entre os que passaram | **de documento** — o roteiro diz "as oito fronteiras", e não há conjunto de oito com nome; são 14 os testes de fronteira. A corrigir no roteiro |
| 13:28:12–13:35:09 | `make medir ALVO=check` | 0 | `\| check \| Airbyte,bancos \| 6m 49s \| 3,4 GB \| 3,6 GB \| 100 amostras, uma a cada 4,1 s (pausa de 2 s) \| 308.6 MB \|`; `PASS=905`; **579 passed, 4 skipped**; "check: as quatro etapas passaram". Os pulados: `test_carga.py` e `test_fato_incremental.py`, por desenho; `test_captura_legado.py:457` ("gerações 15 e 16 não estão retidas neste armazém") e `test_legado_remocao.py:597` ("sem mutações no diário"), pelo estado de um ciclo novo. Os seis de `test_legado_deteccao.py` **rodaram** — a captura é o lote do manifesto novo | não |

### Linha 5 — orquestração

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 13:35:34 | `make preflight ALVO=airflow` | 0 | 3,7 GB livres; o Airflow custa ~1,4 GB, sobrariam 2,3 GB; OK — o par permitido | não |
| 13:35:41–13:36:09 | `make airflow-up` | 0 | os contêineres `healthy`; "Airflow em http://localhost:8081" | não |
| 13:36:17–13:36:41 | `make medir ALVO=dag-run ATE=dag-wait` | **2** | "ERRO: disparei 'fluxo_batch' e não li o run_id de volta." A execução existia, `queued`, com a DAG **pausada** | **sim**, duas causas, as duas só num Airflow novo: o `dags unpause` de uma DAG ainda não registrada diz "No paused DAGs were found" e sai 0, e o laço tomou isso por sucesso; e o `dags trigger -o json` do Airflow 3.2.2 devolve `dag_run_id`, não `run_id` (lido em `local_client.trigger_dag`) |
| — | correção no clone: `11c0b66` "fix: o dag-run só dispara com a DAG vista despausada, e lê o dag_run_id" — com a terceira forma achada no caminho: a `dags list -o json` escreve `is_paused` como texto, "True"/"False" (testes com as formas observadas; `test_preflight.py` + `test_makefile.py` 129 passed) | — | — | — |
| 13:42:08–13:43:04 | `airflow dags delete fluxo_batch -y`, no *scheduler* — a execução presa, a única do Airflow novo, sairia do lugar ao despausar | 0 | "Removed 18 record(s)"; nenhuma execução; a DAG registrada de novo, pausada | — |
| 13:44:25–13:51:14 | `make medir ALVO=dag-run ATE=dag-wait`, refeito | 0 | `\| dag-run \| Airbyte,Airflow,bancos \| 6m 41s \| 1,1 GB \| 6,5 GB \| 95 amostras, uma a cada 4,2 s (pausa de 2 s) \| 325.1 MB \|` — o pico do ciclo até aqui; "manual__2026-09-25T13:44:37.036774+00:00 terminou: success (389s de espera)" | não |
| 13:51:41–13:51:49 | `make dag-status` | 0 | as **13** tarefas `success` | não |
| 13:52 | `governance.legacy_captures`, só leitura | — | capturas 2 e 3, cada uma com as 40 tabelas `complete`; `snapshot_id` = `job_id` (2 e 3), `sync_id_matches` em todas — a identidade é a do `jobId` devolvido | não |

### Linha 6 — *streaming*, eventos novos

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 13:52:26–13:53:58 | `make medir CENARIO=streaming LIMITE=200` | 0 | `\| cenario:streaming \| Airbyte,Airflow,bancos \| 1m 24s \| 2,8 GB \| 4,8 GB \| 20 amostras, uma a cada 4,1 s (pausa de 2 s) \| 325.9 MB \|`; o preflight pausou o Airbyte **e** o Airflow; "200 eventos emitidos em 4.5s"; o corte lido depois do produtor, `<= 13900`; "livro alcançou a sequência 13900"; o Beam encerrado limpo | não |
| 13:54:09–13:54:13 | `make stream-alerts` | 0 | "tópico mvp.alerts.inventory_low_stock: 0 alertas" | **sim, de documento** — com 200 eventos nenhum saldo cruzou o limiar de 25; o `LIMITE` do roteiro foi escolhido só para distinguir os eventos do *snapshot*, e o oráculo do alerta não se cumpria com ele |
| — | correção no clone: `b42b533` "docs: a linha 6 do B5 produz eventos bastantes para o alerta" — `LIMITE=2200`, o do cenário medido que emite alertas (Streaming §7.2: 154) | — | — | a linha só acrescenta eventos: não muda o que as anteriores provaram |
| 13:55:20–13:56:25 | `make medir CENARIO=streaming LIMITE=2200` | 0 | `\| cenario:streaming \| streaming,bancos \| 0m 57s \| 6,4 GB \| 1,3 GB \| 14 amostras, uma a cada 4,2 s (pausa de 2 s) \| 328.8 MB \|`; "'streaming' já está de pé — nada a cobrar" (D53); "2200 eventos emitidos em 41.9s (52/s)"; o corte `<= 16100`, lido depois do produtor; "livro alcançou a sequência 16100"; o Beam encerrado limpo | não |
| 13:56:31–13:56:35 | `make stream-alerts` | 0 | "11 alertas" — 4 aberturas (cruzaram o limiar de 25 para baixo), 7 normalizações, 0 correções de atraso | não |

### Linha 7 — reconciliação dos caminhos

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 13:56:51–13:58:40 | `make airbyte-up` | 0 | o preflight pausou o *streaming*; "cluster pausado — retomando em vez de reinstalar"; a API pronta | não |
| 13:58:47–14:00:33 | `make medir ALVO=sync-airbyte` | 0 | `\| sync-airbyte \| Airbyte,bancos \| 1m 37s \| 3,0 GB \| 4,7 GB \| 23 amostras, uma a cada 4,1 s (pausa de 2 s) \| 332.0 MB \|`; "concluída: 27.921 linhas" | não |
| 14:00:43–14:02:33 | `make medir ALVO=dbt-build` | 0 | `\| dbt-build \| Airbyte,bancos \| 1m 41s \| 3,6 GB \| 3,7 GB \| 24 amostras, uma a cada 4,1 s (pausa de 2 s) \| 334.5 MB \|`; `PASS=905`; `caminhos_de_ingestao_reconciliam` e `incremental_confere_com_a_reconstrucao_completa` PASS | não |
| 14:02:42 | `leitura.comparar_caminhos(armazém, 16100)`, pelo Python | 0 | os quatro zeros; 16.100 linhas em cada caminho; somas 702.104 = 702.104 — os dois caminhos iguais com os eventos novos | não |

### Linha 8 — catálogo

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 14:02:58–14:03:29 | `make medir ALVO=docs-generate` | 0 | `\| docs-generate \| Airbyte,bancos \| 0m 22s \| 3,9 GB \| 3,7 GB \| 5 amostras, uma a cada 4,2 s (pausa de 2 s) \| 334.6 MB \|`; "Catalog written" | não |
| 14:03:29–14:04:12 | `git status --short`; `make catalog`; `git status --short` | 0 | "classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) escrito(s)"; "§3 do dicionário já em dia"; o `git status` vazio antes e depois — as linhas "atualizado (trecho N)" do *export* reescrevem os trechos com o mesmo conteúdo | não |
| 14:04:36–14:07:41 | `make dbt-docs` servindo, e o `curl` de fora | **1** | o catálogo gerado; o servidor não subiu; o `curl` recebeu `000` por 3 min | **sim** — a receita usava `$(DBT)` duas vezes na mesma linha, e a segunda procurava `./.env` e `dbt/` de dentro de `dbt/` (da Etapa 5, `55fdf5a`, quebrada desde que o `DBT` passou a entrar em `dbt/`) |
| — | correção no clone: `f76fa7e` "fix: o dbt-docs serve depois de gerar" — o gerar é a dependência `docs-generate` (com o teste; `test_makefile.py` 86 passed) | — | — | — |
| 14:08:41–14:09:08 | `make dbt-docs` e `curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/`, refeitos | 0 | **`200`**; "Serving docs at 8080"; encerrado pelo roteiro de ensaio com SIGINT e, 3 s depois, SIGKILL — o prazo é do ensaio, não do `Ctrl-C` do roteiro | não — observação: o `dbt docs serve` abre um navegador, como o `abctl` |

## Antes da linha 9

As linhas 1–8 fecharam. Seis desvios, cada um corrigido na origem com *commit* no clone e a linha
refeita: `45395e3` (o `airbyte-config` num Airbyte novo), `f198254` e `cc9c89f` (a espera do
*streaming* num armazém novo), `11c0b66` (o `dag-run` num Airflow novo), `b42b533` (o `LIMITE` da
linha 6, de documento) e `f76fa7e` (o `dbt-docs`). Um desvio só de documento, sem refazer: as
"oito fronteiras" da linha 4 são 14. A linha 9 pede a segunda autorização (P6): `RESTAURAR=1`.

Segunda autorização do Owner (P6), para a linha 9: 25/09/2026, na conversa — "Autorizar a linha 9".

### Linha 9 — recuperação

| Hora (UTC) | Comando | Saída | Linha da Capacidade / oráculo | Desvio |
|---|---|---|---|---|
| 15:29:05–15:45:59 | `RESTAURAR=1 make medir ALVO=recovery-restore` | **2** | `\| recovery-restore \| Airbyte,bancos \| 16m 42s \| 2,5 GB \| 5,0 GB \| 243 amostras, uma a cada 4,1 s (pausa de 2 s) \| 629.9 MB \|`; os passos 1–7 passaram, e o 8 até o `check`: `dbt-rebuild` e o *build* do `check` com `PASS=905`; o pytest do `check`, **1 failed**, 578 passed, 8 skipped — `test_restore_sem_autorizacao_nao_toca_em_banco`; o passo 9 não rodou | **sim** — o `check` do próprio `recovery-restore` roda a suíte com o `RESTAURAR=1` de fora no ambiente; o teste o herdava, a guarda deixava passar, e só os executáveis simulados do teste pararam a restauração aninhada no passo 1 (nada tocou os bancos). Os seis de `test_legado_deteccao.py` pularam pela captura 46, como o dossiê previa depois de restaurar o legado mutado |
| — | correção no clone: `d0cbd75` "test: o teste da restauração sem autorização não herda o RESTAURAR do ambiente" (`test_recovery.py`, com `RESTAURAR=1` no ambiente: 79 passed) | — | — | a linha é refeita inteira — a restauração em destino povoado é o caminho do desenho |

| 15:48–16:05:06 | `RESTAURAR=1 make medir ALVO=recovery-restore`, refeito | 0 | `\| recovery-restore \| Airbyte,bancos \| 16m 59s \| 2,4 GB \| 5,0 GB \| 247 amostras, uma a cada 4,1 s (pausa de 2 s) \| 627.9 MB \|`; **C4 inteira**: o pacote conferido; a janela parada; o CDC descartado; o `pg_restore` em destino povoado; o re-base das gerações, com a partição de 40 tabelas igual à do manifesto na faixa negativa; o conteúdo contra o manifesto (contagens, Alembic, versões, corte do livro, 21 fatias da quarentena, 4 SCD, 11 capturas); os artefatos devolvidos; o *snapshot* novo; a D50 — na primeira tentativa, "maior job 5 … captura retida 43" e "sequência avançada para 43: o próximo job nasce como 44 > 43", antes do disparo; nesta, "o próximo job já nasce acima da captura retida — nada a avançar"; "certificado bb64c900d774: complete · snapshot 49 · tabelas {'complete': 40}"; `dbt-rebuild` e o `check` com `PASS=905`, **579 passed, 8 skipped** (os seis de `test_legado_deteccao.py` pela captura 49, do legado mutado restaurado); e o passo 9: "conferir-restauracao: fontes iguais ao manifesto, memória contida e intacta, identidade nova acima da retida, auditoria dela igual ao que a classificação rejeitou, memória de exclusões renascida igual, livro da origem inteiro e igual nos dois caminhos." — a quarentena com as 21 fatias do manifesto contidas e 1 acrescentada pela captura 49; "recovery-restore: a sequência inteira passou" | não |

| 16:05:50 | `make recovery-promote` | 0 | "promovido: /home/doug/Projetos/mvp_ed1/data/recovery/aprovado" | não |

## §7.5 — depois do B5

| Hora (UTC) | Comando | Saída | Oráculo | Desvio |
|---|---|---|---|---|
| 16:06:00 | `mkdir -p data/recovery && cp -a /home/doug/Projetos/mvp_ed1/data/recovery/aprovado data/recovery/` (D60) | 0 | o `aprovado` no `data/recovery` do clone | não |
| 16:06:01 | `unset RECOVERY_DIR`, depois `make recovery-verify` | 0 | "[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_eng_dados_1/data/recovery"; "[recovery] conferindo /home/doug/Projetos/mvp_eng_dados_1/data/recovery/aprovado"; checksums, manifesto e os três dumps | não |

O *checkout* antigo pode ser arquivado ou apagado quando o Owner quiser; o pacote aprovado está no
clone, e a cópia da P5 (`~/mvp_ed1-recovery-20260925T123221Z`), fora dos dois.

## Os critérios do Termo (§7.6), com as saídas

| Termo §6 | Onde está a saída |
|---|---|
| Produto: bancos, dados, pipeline completo, views, catálogo e linhagem | linhas 1–5 e 8: as 13 tarefas da DAG `success`; o `check` com `test_consumo.py`; o `curl` do catálogo, `200` |
| Reproduzível de ponta a ponta | este diário: cada comando, com hora e saída |
| Migrações do zero | linha 1: `(head)` nas duas origens; `governance versoes` → `0001_legacy_captures`, `0002_snapshot_id_e_o_job` (16:06:59) |
| Testes passando | linha 4: 579 passed, 4 skipped, cada um com o motivo; linha 9: 579 passed, 8 skipped |
| Reconciliação entre camadas | os 14 testes da tag `fronteira` e `caminhos_de_ingestao_reconciliam` em cada *build*; os quatro zeros nas linhas 3 (corte 13700) e 7 (corte 16100) |
| Ausência de segredos | `secrets_review` em cada `check`; `make secrets-history` (16:06:29): "nada não tratado (7 achado(s), todos registrados; 0 blob(s) pulado(s))" |
| Documentação coerente | `docs-check` em cada `check`; os desvios de documento corrigidos no roteiro (`b42b533`, `ea67800`) |
| Governança | `sensitivity --check` e `lineage --check` em cada `check` |

## Desvios

Oito, todos corrigidos na origem, com *commit* no clone, e a linha refeita — **desvios sem correção:
0**. Nenhum mudou o que uma linha anterior tinha provado.

| Linha | Desvio | Correção |
|---|---|---|
| 2 | o `airbyte-config` num Airbyte novo: criações paralelas colidiram na tabela de segredos, 500 | `45395e3` |
| 3 | o `stream-wait` lia `destino.relacao`, atributo que não existe | `f198254` |
| 3 | o `stream-wait` morria no livro que o pipeline ainda não tinha criado | `cc9c89f` |
| 4 | "as oito fronteiras" são 14 (de documento) | `ea67800` |
| 5 | o `dag-run` num Airflow novo: o `unpause` sem efeito saía 0, o `is_paused` vem como texto, e o identificador é `dag_run_id` | `11c0b66` |
| 6 | com `LIMITE=200`, nenhum alerta (de documento) | `b42b533` |
| 8 | o `dbt-docs` gerava e não servia | `f76fa7e` |
| 9 | o teste da restauração sem autorização herdava o `RESTAURAR=1` do `check` da própria restauração | `d0cbd75` |

Quatro dos oito só aparecem num ambiente novo — Airbyte, Airflow e armazém recém-criados —, e é para
isso que o B5 existe: no *checkout* antigo, tudo já existia. Dois são de documento. Os outros dois — o
`dbt-docs` e o teste da restauração — estavam quebrados em qualquer ambiente, num caminho que nada
exercitava.

## Observações, sem desvio

- o `abctl local install` e o `dbt docs serve` abrem um navegador;
- o Beam escreve "Failed to read inputs in the data plane" no encerramento, depois do SIGINT limpo;
- com nenhum pacote no diretório, o `recovery-verify` diz "conferindo …/aprovado" de um caminho que não existe;
- o `recovery-restore` não consome o `RESTAURAR` para os submakes: o ambiente o leva até o `check` — corrigido no teste que dependia disso, e não na receita.

Estado ao fechar: airbyte-abctl-control-plane mvp_ed1_legacy_db mvp_ed1_source_db mvp_ed1_warehouse_db — o Airflow e o *streaming* pausados pelo preflight; 3,5 GiB livres.
````

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

1. **"Do zero" não foi de um *cache* vazio.** O B5 desmontou composições, volumes, rede e o
   *cluster*, e o Airbyte baixou as imagens de novo porque o `/var` do nó saiu com ele. Mas o
   *cache* de imagens do Docker da estação ficou: `postgres`, Redpanda, Debezium e a imagem
   construída do Airflow (`mvp_ed1/airflow:3.2.2`) não foram baixadas nem construídas no B5, e o
   `make install` levou 10 s, com o *cache* do `uv` da estação, que o desmonte não limpa. Uma
   máquina sem esses *caches* baixa e constrói tudo — tempo e falhas disso **não medidos**. É a
   contrapartida da D45 (b), a máquina que nunca viu o projeto, registrada para depois da Etapa 13.
2. **Uma medição por linha.** Cada número da Capacidade §2.12 é uma execução, na estação do Owner,
   com o resto da máquina sem controle; o `MemAvailable` inclui tudo, e os extremos são amostrados
   a cada ~4 s — um pico mais curto que isso não aparece. Variância entre execuções: não medida.
3. **O segundo ciclo do re-base numa restauração real.** O pacote do B5 veio de um ambiente nunca
   restaurado — gerações positivas (o candidato registrava mínima 1 em `brands`) —, e a restauração
   fez o primeiro ciclo. A restauração que parta de um pacote feito **depois** de uma restauração
   (gerações negativas no bruto) só está coberta pelos testes de `recovery/rebase.py`
   (RV12-4-01), sem banco. O armazém de agora é exatamente esse estado — `raw_legacy.brands` com
   mínima −27 e 27 de 28 linhas negativas (§3) —: o próximo pacote, se for feito dele, exercita
   esse caminho pela primeira vez.
4. **Restauração num destino vazio, com a pilha inteira.** A linha 9 restaurou sobre o ambiente
   povoado do ciclo. O destino vazio — armazém novo, sem os papéis — só rodou no ensaio da fase 2 do
   recuo, num projeto Compose isolado, antes do B5 (RVB5-01): os *dumps* e a conferência contra o
   manifesto, sem Airbyte nem Airflow. As fases do recuo da §7.4 do plano não rodaram no B5:
   nenhuma falha as pediu.
5. **Alertas contados, não conferidos.** A linha 6 mediu 11 alertas (4 aberturas, 7
   normalizações) com `LIMITE=2200`; não houve oráculo independente do número esperado para esse
   corte. A Streaming §7.2 tem 154 para o cenário completo, que é outro.
6. **O catálogo servido respondeu `200` em `/`.** O conteúdo — dicionário, linhagem, glossário na
   página — não foi inspecionado no B5; o `make catalog` sem escrita prova que o versionado está em
   dia com o gerado, não que a página o mostra.
7. **B2 detecta por forma.** Credencial numa forma fora dos moldes passa. Os 7 achados registrados
   são *fixtures* do próprio teste; "0 blobs pulados" é o que a varredura leu, não uma prova de
   ausência.
8. **B3 confere estrutura, não sentido.** Links, âncoras e citações de ADR. A coerência da Execução
   Local com o código foi verificada executando-a no B5; a dos outros documentos, lendo — sem
   medição.
9. **A regra de *slug* do B3 contra o GitHub.** Conferida nos casos dos testes, não contra a
   renderização do GitHub.
10. **Nada do B6 é código.** Os dois `make check` do fechamento — o de `807a904`, sob `make medir`,
    e o deste dossiê (§3) — rodaram sem mudança de código desde `d0cbd75`, sobre o armazém
    restaurado; os números da Etapa 12 no plano são os do B5, o ambiente limpo, e não os deles.
11. **O *checkout* antigo e a cópia da P5** continuam em disco (`~/Projetos/mvp_ed1`, com o
    `data/recovery/aprovado` original, e `~/mvp_ed1-recovery-20260925T123221Z`). Arquivar ou apagar
    é do Owner; nada aqui depende deles.
12. **M5, a *tag* e o *push* não aconteceram.** Esperam o aceite.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

1. **A versão do Airbyte que o `abctl` instala.** O `Makefile` fixa o `abctl` (`v0.30.4`) e o
   Terraform (`1.16.1`), mas o `abctl local install` roda sem `--chart-version` (§3): assumi que ele
   instala sempre a mesma versão do Airbyte. A do B5 é a **2.3.0** — lida agora nas imagens dos
   *pods* (§3); a do ambiente antigo não ficou registrada em lugar nenhum, então não há como dizer
   se a instalação nova trouxe outra. Não conferi se o `abctl` resolve a versão do *chart* na hora.
   Se resolver, a próxima instalação nova pode trazer outra API — o que o `airbyte-config` e a
   listagem de *jobs* (`docker/airbyte_jobs.sh`) leem.
2. **As imagens sem *digest*.** A dos bancos do projeto é fixada por *digest*; a base do Airflow
   (`apache/airflow:3.2.2-python3.11`, `docker/airflow.Dockerfile`) e o banco de metadados dele
   (`postgres:16.15-alpine`, `docker/docker-compose.airflow.yml`) são fixados só por *tag*. Assumi
   *tag* estável; as três formas do Airflow 3.2.2 que o B5 achou (o `unpause` sem efeito que sai 0,
   `is_paused` como texto, `dag_run_id`) foram lidas na imagem instalada, e valem enquanto a *tag*
   apontar para ela.
3. **`MemAvailable` como medida de memória.** É o que o preflight e o medidor leem; assumi que
   representa o que a estação ainda pode dar sem trocar para o disco. Não foi confrontado com
   *swap* nem com pressão de memória do *kernel*.
4. **O `docker exec … pg_restore` do contêiner do armazém lê os três *dumps*.** O
   `recovery-verify` usa o `pg_restore` da imagem do PostgreSQL 16.15 para listar os três —
   conferido no B5 para estes três *dumps*; assumi que a mesma imagem continua sendo a das três
   origens, como o `docker-compose.yml` declara hoje.

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

O estado que o B5 deixou, e que o `make check` do fechamento usou: os três bancos com o conteúdo
**restaurado** na linha 9 — a captura 49 certificada sobre as 11 retidas do pacote, o bruto
re-baseado para a faixa negativa, a quarentena com as 21 fatias do manifesto e 1 da captura 49 —, e
o Airbyte de pé. O Airflow e o *streaming* estão **pausados** pelo preflight, não desmontados:
`make airflow-up` ou `make stream-up` os retomam, e a troca pausa o conflitante. O pacote aprovado
está em `data/recovery/aprovado`, e `make recovery-verify` o confere sem escrever nada.

Além da lista geral, **nunca nesta revisão**: `RESTAURAR=1` e qualquer `recovery-*` que não seja o
`recovery-verify` (o `recovery-pack` escreve um candidato ao lado do aprovado; o `recovery-restore`
troca os três bancos); `sync-airbyte`, `sync-legacy` e `dag-run`, que acrescentam captura e mudam o
que a restauração provou; `stream-produce`, que acrescenta eventos ao livro da origem. Para ver a
DAG, `make airflow-up` e a interface em `http://localhost:8081`, sem disparar.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

1. **O "ponto de partida" do README virou ponteiro.** Os dois blocos de comandos mandavam rodar a
   DAG antes do *snapshot* do *streaming* e sem `seed-legacy` — num clone novo, o primeiro *build*
   falha por construção (Execução Local §3). Podia corrigi-los; preferi apontar para a §2 e a §3,
   que são as donas do assunto e foram as que o B5 executou. Custo: o README deixa de ter um bloco
   para copiar.
2. **"Nenhum risco novo" nos riscos.** Pesei dois candidatos e deixei os dois dentro dos existentes:
   a versão do Airbyte sem fixação (premissa 1) é tratamento do R6, não risco novo; e o pacote morar
   no *checkout* de trabalho é o custo aceito da D60, com a cópia da P5 fora dele.
3. **A §9 da Governança e a §10.** A D48 e a varredura do histórico entraram na §9 sem ADR, e a §10
   pede ADR para alteração na política. Não escrevi o ADR nem decidi que não precisa: registrei como
   decisão embutida no aceite, nas pendências — a mesma leitura que a automação da revisão teve em
   17/09, aceita com a Etapa 11. Se o revisor ou o Owner entenderem que é alteração, o ADR vem antes
   do fechamento.
4. **A *tag* depois do aceite, não antes do dossiê.** O §8 do plano lista a *tag* (item 6) antes
   do dossiê (item 7). Pôr a *tag* antes da revisão obrigaria a movê-la se a revisão achar algo — e
   *tag* publicada não se move. Ela vai no *commit* de fechamento, junto com a data do M5.
5. **O escopo deste dossiê.** `7b0bea6..` cobre as correções do B5 e o B6; B2 e B3 entram por
   *commit* (§2), porque o intervalo que os contivesse traria de volta tudo o que as seis rodadas
   da entrega e as três do roteiro já revisaram.
6. **Os números da Etapa 12 no plano são os do B5**, o ambiente limpo, e não os do `check` do
   fechamento — que é regressão sobre documentos, num armazém restaurado.
7. **O que ficou sem corrigir, de propósito.** A linha "conferindo …/aprovado" do `recovery-verify`
   sem pacote (ele recusa em seguida, pelo manifesto ausente); a receita do `recovery-restore`, que
   leva o `RESTAURAR` do ambiente até o `check` (corrigido no teste que dependia disso); o navegador
   que o `abctl` e o `dbt docs serve` abrem (há `--no-browser` no `abctl`); e a fixação do *chart*
   do Airbyte. Nenhum muda o que o B5 provou; cada um é mudança de comportamento que prefiro que o
   Owner veja antes.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

