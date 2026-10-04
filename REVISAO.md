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

## 8. Resposta à revisão final — 03/10/2026

Os onze achados reproduzidos antes de qualquer correção — as sondas S1 e S2 do parecer, literais —,
e os onze tratados no mesmo dia. Duas decisões do Owner, tomadas ao receber o parecer: **ADR para
a D48** (RVF12-02) e **fixar o *chart* do Airbyte** (RVF12-10). Um *commit* por achado, os dois
bloqueantes primeiro; o verificador de ADR (RVF12-07) foi corrigido antes do ADR, para que a
conferência da transação valesse. A situação de cada achado está na tabela, ao fim.

```
8e60739 fix: os moldes da varredura de segredos deixam de excusar literal
41c39c5 docs: registra a senha de fábrica do Airflow que a varredura do histórico passou a achar
09cb85c fix: o verificador de ADR conta as aprovações que esperam o Owner
021cf12 docs: registra ADR-0048 — tratar segredo achado no histórico pelo tipo da credencial
c8819d3 fix: o docs-check confere link e citação de ADR dentro de título
a819d53 fix: o docs-check reserva toda âncora já emitida ao sufixar título repetido
40e63b0 fix: o docs-check só fecha cerca de código com o mesmo caractere e comprimento
69a6f94 docs: a Capacidade conta as capturas em vez de ler o identificador da maior
df46f9c docs: a Execução Local deixa de ensinar a repetir o terraform apply
cc84cd3 fix: o airbyte-up instala o chart do Airbyte medido no B5, e não o mais recente
30e8386 docs: o plano e o README ressalvam o pico de memória que o migrate não teve
f6d34ef fix: o verificador de ADR não lê citação dentro de bloco de código
```

O último é **achado próprio**, do registro desta resposta: a saída da S1 refeita (§8.2), colada em
bloco de código, imprime a citação do ADR inexistente que a sonda monta, e o verificador da skill
de ADR a acusava — o `docs-check` já ignorava blocos de código, o verificador não. Corrigido sem
mexer na saída colada.

### 8.1 O detector, antes de mudar

Uma sonda listou, no histórico inteiro, os valores que as duas regras amplas excusavam — a forma de
cada um, com letras e dígitos trocados por `w`, e um exemplo —, para que o aperto não trocasse falso
negativo por falso positivo:

```
281 ('atr', 'referência a', '$$w') ('Makefile', '$$AIRBYTE_CLIENT_SECRET')
43 ('atr', 'expressão, n', '\\(\\w*\\).*/w=\\w/w') ('Makefile', '\\(\\S*\\).*/AIRBYTE_CLIENT_SECRET=\\1/p')
30 ('atr', 'expressão, n', 'w(...)`') ('PLANO_etapa_12.md', 'quote_plus(...)`')
22 ('atr', 'referência a', '${w}') ('docker/docker-compose.yml', '${SOURCE_DB_PASSWORD}')
8 ('atr', 'referência a', '${w:?w') ('docker/docker-compose.airflow.yml', '${AIRFLOW_JWT_SECRET:?defina')
7 ('atr', 'expressão, n', 'w.w()') ('REVISAO.md', 'airbyte.token()')
5 ('atr', 'referência a', '${w:-}') ('docker/docker-compose.airflow.yml', '${AIRBYTE_CLIENT_SECRET:-}')
3 ('atr', 'expressão, n', 'w.w(w') ('src/mvp_ed1/secrets_review.py', 're.compile(r')
1 ('atr', 'expressão, n', 'w(w.w[') ('db/migrations/env.py', 'quote_plus(os.environ[')
1 ('atr', 'expressão, n', 'w(w.w[w') ('src/mvp_ed1/db.py', 'quote_plus(os.environ[f')
1 ('atr', 'referência a', '${w(w.w') ('airbyte/versions.tf', '${trimsuffix(var.airbyte_server_url')
1 ('atr', 'expressão, n', 'w(w.w(w') ('REVISAO.md', 'len(re.findall(r')
1 ('atr', 'referência a', '(?!\\$)\\w+') ('REVISAO.md', '(?!\\$)\\S+')
```

Toda referência começa com `$`; toda expressão aparece fora de aspas — inclusive os dois grupos de
regex, que a regra de expressão nova cobre. E, no histórico inteiro, só dois *blobs* têm senha
igual ao usuário na URL ou `POSTGRES_PASSWORD` literal:

```
('4ff3be9510', 'docker/docker-compose.airflow.yml') [(21, 'url usuário=senha', 'airflow'), (71, 'POSTGRES_PASSWORD literal', '7 car.')]
('ea91a49809', 'docker/docker-compose.airflow.yml') [(21, 'url usuário=senha', 'airflow'), (78, 'POSTGRES_PASSWORD literal', '7 car.')]
total de blobs: 2
```

Depois de `8e60739`, a varredura achou exatamente esses quatro, e nada mais; depois de `41c39c5`:

```
$ .venv/bin/python -m mvp_ed1.secrets_review --historico
revisão do histórico: nada não tratado (11 achado(s), todos registrados; 0 blob(s) pulado(s))
```

O tratamento registrado cita o que se conferiu sem imprimir valor: a senha do Airflow no `.env`
difere da histórica, e as únicas chaves do `.env` com aquele valor são `AIRFLOW_DB_NAME` e
`AIRFLOW_DB_USER`, que são configuração; o volume do banco de metadados é do B5:

```
mvp_ed1_airflow_db_data 2026-09-25T10:35:44-03:00
```

### 8.2 A contraprova S1, refeita literal

```
AIRFLOW_HISTORICO {'urls_com_credencial_literal': 1, 'atribuicoes_postgres_password_literais': 1, 'achados_detector': 2, 'registros_airflow': 4, 'senha_env_diferente_da_historica': True}
LITERAL_SINTETICO controle achados= 1 motivo= None
LITERAL_SINTETICO dolar achados= 1 motivo= None
LITERAL_SINTETICO parentese achados= 1 motivo= expressão, não literal — chamada de função ou indexação
LITERAL_SINTETICO colchete achados= 1 motivo= expressão, não literal — chamada de função ou indexação
DOCS_SINTETICO link_no_titulo {"quebrados": ["README.md:1: sumiu.md — arquivo não existe"], "contagem": {"documentos": 1, "links": 1, "ancoras": 0, "adrs": 0}}
DOCS_SINTETICO adr_no_titulo {"quebrados": ["README.md:1: ADR-9999 — não existe em docs/adr/"], "contagem": {"documentos": 1, "links": 0, "ancoras": 0, "adrs": 1}}
DOCS_SINTETICO colisao_de_slug {"quebrados": [], "contagem": {"documentos": 1, "links": 0, "ancoras": 1, "adrs": 0}}
DOCS_SINTETICO cerca_interna {"quebrados": ["README.md:7: #falso — título não existe neste arquivo"], "contagem": {"documentos": 1, "links": 0, "ancoras": 1, "adrs": 0}}
PACOTE {"capturas_certificadas": 11, "maior_snapshot": 43, "quarentena_fatias": 21, "scd": 4, "max_event_sequence": 13700, "particoes": 40}
```

A coluna `motivo=` da sonda chama `placeholder(valor)` sem contexto, e o padrão sem contexto é
"fora de aspas" — por isso ela ainda nomeia a regra de expressão para `(` e `[`. O detector conhece
a aspa do JSON, e é o `achados=` que responde ao achado.

### 8.3 A ponta inteira

`make check` em `30e8386`, 7m 51s, saída 0 (trechos):

```
── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 108 documentos, 1034 links de arquivo, 160 âncoras, 652 citações de ADR — nada quebrado
Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
── 3/4 classificação derivada e linhagem em dia com os modelos ──
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
595 passed, 8 skipped in 322.54s (0:05:22)
```

Os oito pulados são os do fechamento, cada um com o motivo impresso: a carga reduzida, a fato de
trabalho e os seis do legado que comparam vereditos com o lote do manifesto, que a captura 49 não
é. Os 595 são os 579 do fechamento e os 16 testes novos desta resposta. E:

```
$ python3 .claude/skills/adr/verificar.py
ADRs aceitos: 48  ·  esperando ADR: 1  ·  esperando o Owner: 1 decisão(ões) e 1 aprovação(ões)  ·  Dnn citados: 61
Integridade conferida: links, ADRs citados, decisões pendentes e contadores.
```

### 8.4 O que NÃO foi verificado

- **Uma instalação real com o *chart* fixado.** O ramo de instalação do `airbyte-up` só roda sem
  cluster; o teste prova a chamada, e o `--help` da v0.30.4 prova a opção. Que o 2.3.0 continue
  disponível no índice do repositório do Airbyte é premissa.
- **Os limites declarados do detector continuam:** senha só com letras e **diferente** do usuário;
  valor sem aspa que comece como chamada (`Ab9(…`). O guarda das composições
  (`test_nenhuma_composicao_embute_credencial`) cobre o primeiro nas composições atuais, não no
  histórico.
- **A regra de *slug* foi conferida contra o algoritmo do `github-slugger` e a documentação do
  GitHub**, não contra uma página renderizada pelo GitHub.
- **A Paridade do ADR-0048** — na fase GCP toda credencial é do segundo tipo, inclusive a senha do
  Cloud SQL — é leitura minha do critério da decisão (o que o valor dá de acesso, e de onde); o
  Owner a confere ao revisar o ADR.
- Nada do que o parecer deixou como não medido foi medido aqui: nenhum ciclo, restauração ou
  instalação nova.

**A segunda rodada é curta, por decisão do Owner em 03/10/2026, e revisa `d8ebe5a..` a ponta**,
este registro incluído: a resposta a cada um dos onze achados, o código novo que ela trouxe — o
detector de segredos (`USER_PATTERN`, `WORD_RULE`, `EXPRESSION_RULES`, o contexto de literal), o
`docs_check` (título, sufixo, cerca) e o verificador de ADR (aprovações, bloco de código) —, o
ADR-0048 com a sua transação, e o *chart* fixado. Não reabre o que o parecer já sustentou: os
critérios 2, 3 e 4, o B5 e os logs. O ambiente e as proibições são os da §6, sem mudança.

---

## 9. Resposta à segunda rodada — 03/10/2026

Os seis ajustes reproduzidos antes de qualquer correção, pela sonda R2-A/B/C do parecer, extraída
literal deste dossiê: as seis saídas idênticas às do parecer. Seis *commits* de correção, um por
assunto — RVF12-2-01 e RVF12-2-03 são a mesma regra e entraram juntos —, e dois achados próprios:
o parêntese do último argumento nomeado (`3b81cc3`) e o usuário web do Airflow, levado ao Owner,
que decidiu corrigir (§9.4, `e828acd`). A situação de cada achado está na tabela, ao fim.

```
29d2424 fix: a referência a variável precisa estar completa e alcançar o fim do valor
3b72ca6 fix: a senha igual ao usuário só conta quando os dois lados são literais
3b81cc3 fix: o identificador no último argumento nomeado não vira credencial
8283886 fix: o verificador de ADR conta decisões e aprovações fora de bloco de código
6be1f54 fix: o docs-check não confere link dentro de código em linha
42e2ce9 fix: o recuo da cerca de código conta contra a coluna do item de lista
e828acd fix: o Airflow deixa de prometer a senha de fábrica que nunca valeu
```

Cada teste novo rodou contra o código anterior antes do *commit*, e ficou vermelho onde devia:
9 de 12 na referência (os verdes são `$1Ab9Z7q1`, que a regra antiga já acusava, e a lista de
moldes); 2 de 7 na igualdade (os verdes são os controles literais); 1 de 1 no parêntese; 1 de 2 no
bloco de código do verificador; 1 de 1 no código em linha; 5 de 8 no recuo (os dois casos de lista
e o teste de paridade já passavam).

### 9.1 O detector, antes de mudar

Duas sondas no histórico inteiro, *blob* por *blob*, como a varredura. A primeira pegou todo valor
de atribuição ou URL que começa com `$`, `{{` ou `{` e conferiu se a forma completa, lida no resto
da linha, alcança o fim do valor:

```
cobrem: {'$': 575, '{': 13, '{{': 1}
18 ('{', '{SENHA}\\n') ('tests/test_secrets_review.py', '(repositorio / "conector.yml").write_text(f"password: {SENHA}\\n", encoding="utf-8")')
3 ('{', '{TOKEN_GITHUB}\\n') ('tests/test_secrets_review.py', '(repositorio / "ci.yml").write_text(f"token: {TOKEN_GITHUB}\\n", encoding="utf-8")')
```

As 575 ocorrências do `$` e a do `{{` são formas completas: a regra nova não cria achado. O `{var}`
de *f-string* ficou como estava — já exige a chave que fecha dentro do valor —, porque, exigindo
também alcançar o fim, os 21 *blobs* do teste com `\n` depois da interpolação virariam achados
falsos. A segunda listou toda senha cujo valor está no conjunto de usuários do mesmo texto:

```
2 ('docker/docker-compose.airflow.yml', 'POSTGRES_PASSWORD: airflow', 'POSTGRES_USER: airflow', None)
```

Um par só, o da composição do Airflow em `4ff3be9` e `ea91a49`, e a linha de configuração YAML o
mantém. Depois das três correções do detector:

```
revisão de segredos: nada encontrado nos arquivos rastreados
revisão do histórico: nada não tratado (11 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Do lado dos documentos, a regra de cerca nova comparada com a anterior em cada `.md` rastreado,
linha a linha do que cada uma lê como fora de código: `documentos com diferença: 0 de 108`. O código
em linha também não tirou link nenhum do repositório: as contagens do `docs-check` não mudaram.

### 9.2 As sondas, refeitas na ponta

R2-A/B/C do parecer, literal, em `42e2ce9`:

```
R2_A usuario_literal antes= 0 depois= 1
R2_A identificador_python antes= 0 depois= 0
R2_A grupo_literal antes= 0 depois= 1
R2_A referencia_completa antes= 0 depois= 0
R2_A referencia_incompleta antes= 0 depois= 1
R2_A shell_posicional_url antes= 0 depois= 0
R2_B controle {"exit": 0, "problemas": []}
R2_B aprovacao_em_codigo {"exit": 0, "problemas": []}
R2_B fecho_indentado {"exit": 1, "problemas": ["- link quebrado — docs/pendencias.md: sumiu.md"]}
R2_C {"quebrados": [], "contagem": {"documentos": 1, "links": 0, "ancoras": 0, "adrs": 0}}
```

Contraprovas próprias do detector, reproduzíveis da raiz do checkout com `.venv/bin/python`; os
valores são montados em partes pelo mesmo motivo do parecer:

```python
from mvp_ed1.secrets_review import detectar

k, u = "pass" + "word", "u" + "ser"
casos = {
    "yaml_sem_fecho": f"{k}: ${{Ab9Z7q1",
    "aspa_simples_sem_fecho": f"{k}: '${{Ab9Z7q1'",
    "referencia_mais_literal": f'{k}: "${{A}}Ab9Z7q1"',
    "posicional_mais_literal": f"{k}: $1Ab9Z7q1x",
    "parentese_sem_fecho": f"{k}: $(Ab9Z7q1",
    "gabarito_sem_fecho": f"{k}: {{{{Ab9Z7q1",
    "make_subshell": f'echo "SOURCE_DB_{k.upper()}=$$(pw)"',
    "terraform_interp": 'token_url = "${trimsuffix(var.airbyte_server_url, "/")}/applications/token"',
    "jinja": f"{k}: \"{{{{ env_var('DBT_PASS') }}}}\"",
    "compose_msg": f"POSTGRES_{k.upper()}: ${{AIRFLOW_DB_PASSWORD:?defina AIRFLOW_DB_PASSWORD no .env}}",
    "env_par_fabrica": f"POSTGRES_USER=airflow\nPOSTGRES_{k.upper()}=airflow",
    "lista_compose_par": f"  - POSTGRES_USER=airflow\n  - POSTGRES_{k.upper()}=airflow",
    "kwargs_multilinha": f"connect(\n    {u}=db_user,\n    {k}=db_user,\n)",
    "kwargs_linha": f"connect({u}=db_user, {k}=db_user)",
    "python_aspas_par": f'{u} = "airflow"\n{k} = "airflow"',
    "yaml_flow_limite": f"{{{k}: ${{Ab9Z7q1, {u}: x}}",
}
for nome, texto in casos.items():
    print(f"{nome:26} {len(detectar(texto))}")
```

```
yaml_sem_fecho             1
aspa_simples_sem_fecho     1
referencia_mais_literal    1
posicional_mais_literal    1
parentese_sem_fecho        1
gabarito_sem_fecho         1
make_subshell              0
terraform_interp           0
jinja                      0
compose_msg                0
env_par_fabrica            1
lista_compose_par          1
kwargs_multilinha          0
kwargs_linha               0
python_aspas_par           1
yaml_flow_limite           0
```

O `kwargs_linha` dava 1 antes de `3b81cc3` — e já dava em `d8ebe5a`, antes da revisão final: o `)`
colado ao identificador o fazia passar por valor. O último é limite, não acerto: num mapeamento
YAML em linha, a chave que fecha o mapeamento completa a referência aberta. O repositório não
escreve credencial nessa forma; está na §9.5.

### 9.3 A ponta inteira

`make check` em `42e2ce9`, saída 0 (trechos):

```
── 1/4 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 108 documentos, 1035 links de arquivo, 160 âncoras, 658 citações de ADR — nada quebrado
Done. PASS=905 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=905
── 3/4 classificação derivada e linhagem em dia com os modelos ──
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia
625 passed, 8 skipped in 268.52s (0:04:28)
check: as quatro etapas passaram
```

Os oito pulados são os da §8.3, com o mesmo motivo impresso. Os três arquivos de teste tocados
coletam 88 testes; o parecer coletou 60 neles (os 62 da validação dele, menos os dois do
`Makefile`): 28 novos. Depois da correção do Airflow, `make check` em `e828acd`, saída 0, com as
mesmas linhas das etapas 1 a 3 e o teste novo do `airflow-up`:

```
626 passed, 8 skipped in 264.95s (0:04:24)
check: as quatro etapas passaram
```

### 9.4 Achado próprio, decidido pelo Owner: o usuário web do Airflow

O `airflow_init` da composição traz `airflow users create --username admin --password admin` desde
`4ff3be9`, e o `make airflow-up` imprime "admin / admin". A varredura não vê essa forma — opção de
linha de comando não está entre as que a Governança §9 promete. Lido na imagem local, num contêiner
descartável, e no log do último `airflow_init`, sem subir serviço:

```
$ docker run --rm --entrypoint airflow mvp_ed1/airflow:3.2.2 config get-value core auth_manager
airflow.api_fastapi.auth.managers.simple.simple_auth_manager.SimpleAuthManager
$ docker run --rm --entrypoint airflow mvp_ed1/airflow:3.2.2 config get-value core simple_auth_manager_users
admin:admin
$ docker logs mvp_ed1-airflow_init-1 2>&1 | grep 'command error'
airflow users create command error: the following arguments are required: -e/--email, -f/--firstname, -l/--lastname, -r/--role, see help above.
```

Três coisas, então. O comando nunca rodou: o bloco dobrado do YAML (`>`) mantém em linha própria as
linhas mais recuadas, o `bash` executa `users create` só com usuário e senha, e o `|| true` engole a
falha. Se rodasse, criaria um usuário do FAB que o `SimpleAuthManager` — o padrão do Airflow 3 —
não consulta: o `admin:admin` da configuração é usuário e **papel**, e a senha é gerada pelo próprio
gerenciador quando o *api-server* sobe e impressa no log dele (o valor não é reproduzido aqui). E a
instrução do `make airflow-up` é falsa. Nenhuma credencial de fábrica chegou a valer, mas havia uma
escrita na composição e uma instrução errada no `Makefile`.

**O Owner decidiu limpar e corrigir, sem mudar a forma de autenticar** (03/10/2026); a alternativa
de pôr a senha do `admin` no `.env` ficou de fora. Em `e828acd`: o `airflow_init` passa a ser só
`db migrate` — que agora falha alto, sem o `|| true` —, o `airflow-up` aponta o arquivo em que o
Airflow grava a senha, e o guarda das composições (`test_nenhuma_composicao_embute_credencial`)
acusa também senha literal em opção de linha de comando. Os dois testes ficaram vermelhos no código
anterior. Conferido numa subida real, autorizada pelo Owner, pelo alvo guardado e sem `FORCE`; o
estado de partida era o Airbyte e os bancos de pé, o Airflow parado:

```
$ make preflight ALVO=airflow
[preflight] RAM disponível agora: 3,4 GB
[preflight] Já de pé: Airbyte (cluster kind)
[preflight] 'airflow' custa ~1,4 GB — sobraria 2,0 GB
[preflight] OK
$ make airflow-up            # 24 s, saída 0
$ docker inspect mvp_ed1-airflow_init-1 --format 'cmd={{json .Config.Cmd}} exit={{.State.ExitCode}} criado={{.Created}}'
cmd=["db","migrate"] exit=0 criado=2026-10-04T02:40:59.365714581Z
$ docker logs mvp_ed1-airflow_init-1 2>&1 | grep -v "alembic\|plugin" | grep -i -E "error|migrat|done|users create" | tail -4
2026-10-04T02:41:14.257009Z [info     ] Migrating the Airflow database [airflow.utils.db] loc=db.py:1179
2026-10-04T02:41:17.007344Z [info     ] Database migration done!       [airflow.cli.commands.db_command] loc=db_command.py:152
```

O login, com a senha lida do arquivo e passada ao `POST /auth/token` sem ser impressa, e o par de
fábrica como controle:

```
senha lida: 16 caracteres
admin + senha do arquivo: HTTP 201
admin + admin (controle): HTTP 401
```

A subida real mostrou duas coisas que o texto não sabia. **O `airflow-up` volta antes de o
api-server responder:** a primeira leitura não achou o arquivo, que o api-server gravou às
02:41:42, 23 s depois de o alvo terminar — a composição não declara verificação de saúde para ele.
A mensagem diz isso:

```
Airflow em http://localhost:8081 — usuário admin. A senha é gerada pelo Airflow quando o api-server
termina de subir, uns 20 s depois daqui, e se lê com:
  docker exec mvp_ed1-airflow_apiserver-1 cat /opt/airflow/simple_auth_manager_passwords.json.generated
```

E **a segunda subida, sem mudança na composição, recriou os quatro contêineres**, e o arquivo foi
gravado de novo (02:43:11): a senha muda a cada recriação, e a mensagem aponta a da vez. A causa da
recriação não foi investigada. `make dag-status` mostrou como última execução a do B5, de
25/09 — nada foi disparado. No fim, `make airflow-pause` devolveu o Airflow ao estado parado.

### 9.5 O que NÃO foi verificado

- **Limites declarados do detector, novos:** a chave que fecha um mapeamento YAML em linha completa
  uma referência aberta dentro dele; `{var}` de *f-string* seguido de literal (`{a}Ab9Z7q1`) segue
  excusado; num `.env`, `chave = valor` com espaços não é linha de configuração; a opção de linha de
  comando (`--password valor`) não é lida pela varredura — o guarda das composições a acusa desde
  `e828acd`, só na árvore atual e só nas composições. Os da §8.4 continuam.
- **Limites declarados da regra de cerca:** tab, citação (`>`), item que abre com a própria cerca,
  bloco indentado sem cerca e continuação de parágrafo sem recuo — nesta última o erro é acusar um
  exemplo, não esconder. Código em linha que atravessa linhas não é lido como tal.
- A regra de recuo foi conferida contra a especificação do GFM, não contra uma página renderizada.
- Nenhum ciclo, restauração ou instalação; a única subida foi a do Airflow, na §9.4. Nada do que a
  §8.4 deixou como não medido foi medido aqui.
- A interface do Airflow não foi aberta num navegador: o login foi conferido pela API que ela usa.

**A terceira rodada é curta, por decisão do Owner em 03/10/2026, e revisa `ebc84ae..` a ponta**,
este registro incluído: a resposta a cada um dos seis achados — o detector de segredos
(`REFERENCE_RULE` e o contexto da linha, `CONFIG_LINE_PATTERN` e `_literal`, o `)` da
`WORD_RULE`), o `docs_check` (código em linha, recuo da cerca contra o item de lista) e o
verificador de ADR (texto sem código nas decisões, a cópia da regra de cerca e o teste de
paridade) — e o achado próprio do Airflow (`e828acd`: a composição, a mensagem do `airflow-up` e o
guarda das composições). Não reabre o que as rodadas anteriores já sustentaram. O ambiente e as
proibições são os da §6, sem mudança; a senha do Airflow, se lida, não entra no parecer.

---

## Achados da revisão

**Parecer de 03/10/2026 — Codex. Devolver para ajustes antes do aceite:** dois bloqueantes,
oito ajustes e uma observação na tabela ao fim. A execução do B5 está documentada e os seus
resultados operacionais conferem; isso ainda não sustenta os seis critérios sem ressalvas.
Os bloqueantes dizem respeito ao registro do segredo histórico conhecido e à formalização da D48.
O segundo é um parecer de governança submetido ao Owner, não uma decisão tomada pelo revisor.

Revisão sobre `04e1aa5`, no checkout `/home/doug/Projetos/mvp_eng_dados_1`, inicialmente limpo.
Escopo: `7b0bea6..807a904`, mais `6453bb5`, `0b89b3d` e `bb783f4`. Dossiê lido inteiro antes das
sondas; declarações do escopo lidas integralmente, testes por amostragem. B0/B1/B4 e o roteiro já
revisados não foram reabertos. Somente este parecer foi escrito no repositório.

**Resposta aos seis critérios, na ordem do plano:**

| Critério | Parecer e evidência |
|---|---|
| 1. Todos os critérios do Termo em ambiente limpo | **Parcial.** Os logs do B5 sustentam o produto e a execução na modalidade autorizada pela D45: 13 tarefas `success`, `PASS=905`, 579 testes Python, migrações e reconciliações. Nesta revisão as 16 views responderam, os dois caminhos reconciliaram e o catálogo foi inspecionado por amostragem. A parte documental e a de governança dependem dos achados abaixo; não ratifico o ✓ agregado enquanto elas estiverem abertas. |
| 2. Cada cenário com tamanho, tempo e memória | **Sustentado para o ciclo observado.** As 17 linhas da Capacidade foram confrontadas com os logs: `CAPACIDADE_LINHAS_CONFERIDAS 17 / 17`. O pico da DAG, 6,5 GB nos contêineres e 1,1 GB disponíveis, confere. `migrate` tem zero amostras e memória **não medida**; a ressalva precisa acompanhar os resumos (RVF12-11). Nenhuma variância ou instalação sem caches foi inferida. |
| 3. Cobertura integral | **Sustentado pelas evidências do B5.** O `check` do ciclo contém os testes de cobertura; a geração legada registrou 24/24 códigos injetáveis. Agora foram lidas 40 tabelas de cada origem, todas não vazias: 252.955 linhas na principal e 12.744 na legada restaurada, com cada contagem igual à do manifesto. Os 12.747 do ciclo limpo e os 12.744 do pacote mutado são estados distintos, não uma divergência omitida. |
| 4. Recuperação, incluindo novo snapshot CDC | **Sustentado pelo B5 e pela integridade atual do pacote.** O log da linha 9 refeita termina com a sequência inteira aprovada, em 16m 59s; `make recovery-verify` passou nesta revisão. A captura 49 tem 40 tabelas `complete`; o livro restaurado tem 13.700 eventos e os quatro zeros. Restauração nova não foi executada. Segundo ciclo com gerações negativas e pilha completa em destino vazio continuam **não medidos ao vivo**, como a §4 declara. |
| 5. Documentação coerente com código | **Requer ajustes.** `docs-check` passa, mas as contraprovas de B3 encontram lacunas, o verificador de ADR reprova o estado atual, a Capacidade confunde identificador com quantidade e a Execução Local ainda descreve criação paralela depois da correção que a serializou. |
| 6. Nenhum segredo no repositório/histórico | **Não encerrável com a evidência apresentada.** A varredura devolveu os mesmos sete achados de fixtures, todos tratados, porém omite a credencial histórica real do Airflow, reconhecida no próprio `0b89b3d` e ausente do registro D48. Isso não demonstra uma credencial ainda ativa; demonstra um caso conhecido fora do controle que sustenta o ✓. |

**Validações executadas nesta revisão.** Os processos de banco foram acessados com
`default_transaction_read_only=on`; a própria sessão respondeu `transaction_read_only=on` nos três
bancos. Não executei `make check`, pois ele chama `dbt-build` e escreve no armazém. Não executei
restauração, sincronização, produção de eventos nem disparo de DAG. As chamadas de Airflow e
Terraform dos testes abaixo usam transporte/executáveis simulados em diretórios temporários.
O teste de `d0cbd75`, que chama `recovery-restore`, foi inspecionado, mas não executado, em respeito
à proibição desta revisão. O tratamento específico de `UndefinedTable`, o destino `qualificado`,
a confirmação da DAG despausada, `dag_run_id`, `-parallelism=1` e a dependência `docs-generate`
estão coerentes com as formas observadas no B5.

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/pytest -q -rs -p no:cacheprovider \
  tests/test_secrets_review.py tests/test_docs_check.py tests/test_verificador_adr.py \
  tests/test_makefile.py::test_dbt_docs_gera_e_serve \
  tests/test_makefile.py::test_airbyte_config_aplica_um_recurso_por_vez \
  tests/test_medicao.py::test_sem_destino_o_livro_e_o_da_configuracao \
  tests/test_medicao.py::test_livro_que_ainda_nao_existe_e_livro_vazio \
  tests/test_preflight.py::test_disparar_le_o_dag_run_id_do_airflow_322 \
  tests/test_preflight.py::test_disparar_so_dispara_depois_de_ver_a_dag_despausada \
  tests/test_preflight.py::test_disparar_recusa_sem_ver_a_dag_despausada
```

```text
49 passed in 15.10s

$ make docs-check
docs-check: 107 documentos, 1016 links de arquivo, 156 âncoras, 591 citações de ADR — nada quebrado

$ make secrets-history
revisão do histórico: nada não tratado (7 achado(s), todos registrados; 0 blob(s) pulado(s))

$ make recovery-verify
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_eng_dados_1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_eng_dados_1/data/recovery/aprovado
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.

$ .venv/bin/python -m mvp_ed1.models.sensitivity --check
classificação derivada de 2983 colunas em 199 nós; 0 arquivo(s) desatualizado(s)

$ .venv/bin/python -m mvp_ed1.models.lineage --check
linhagem de 2983 colunas em 199 relações; §3 do dicionário em dia

$ python3 .claude/skills/adr/verificar.py
ADRs aceitos: 47  ·  esperando ADR: 1  ·  esperando o Owner: 1  ·  Dnn citados: 61

PROBLEMAS:
 - README desatualizado — a linha Pendências do Owner conta 2, e 'Esperando você' tem 1 (D43)
```

Saídas acima colhidas antes de acrescentar este parecer; o verificador de ADR saiu **1**, os demais
comandos saíram **0**. `sensitivity` também emitiu os mesmos três avisos sobre o alias `c` já
explicados na §3. As primeiras conexões ao Docker/PostgreSQL foram bloqueadas pelo sandbox;
as sondas foram repetidas com a permissão de acesso local e concluíram. Não restou sonda de banco
classificada como sucesso por inferência de disponibilidade.

**Contraprova reproduzível S1 — B2, B3 e manifesto.** Execute da raiz do checkout de trabalho.
Os exemplos de Markdown são montados em partes para que este dossiê não crie links quebrados
ou citações fictícias no próprio verificador. Só os repositórios temporários são escritos; o
valor da credencial histórica não é impresso.

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python - <<'PY'
import json
import os
import pathlib
import re
import subprocess
import tempfile
from mvp_ed1 import docs_check, secrets_review

root = pathlib.Path.cwd()
def git(*args, cwd=root):
    return subprocess.check_output(['git', *args], cwd=cwd, text=True)

old = git('show', '0b89b3d^:docker/docker-compose.airflow.yml')
urls = list(secrets_review.URL_CREDENTIAL_PATTERN.finditer(old))
print('AIRFLOW_HISTORICO', {
    'urls_com_credencial_literal': sum('$' not in m['valor'] for m in urls),
    'atribuicoes_postgres_password_literais': len(re.findall(r'^\s+POSTGRES_PASSWORD: (?!\$)\S+', old, re.M)),
    'achados_detector': len(secrets_review.detectar(old)),
    'registros_airflow': sum(k[1] == 'docker/docker-compose.airflow.yml' for k in secrets_review._tratados(root)),
    'senha_env_diferente_da_historica': all(secrets_review.read_env(root / '.env').get('AIRFLOW_DB_PASSWORD') != m['valor'] for m in urls),
})
for name, value in [('controle', 'Ab9xZ7q1'), ('dolar', 'Ab9$Z7q1'), ('parentese', 'Ab9(Z7q1'), ('colchete', 'Ab9[Z7q1')]:
    text = json.dumps({'password': value})
    print('LITERAL_SINTETICO', name, 'achados=', len(secrets_review.detectar(text)), 'motivo=', secrets_review.placeholder(value))

def link(label, target):
    return '[' + label + ']' + '(' + target + ')'
cases = {
    'link_no_titulo': '# Ver ' + link('alvo', 'sumiu.md') + '\n',
    'adr_no_titulo': '# ADR-' + '9999\n',
    'colisao_de_slug': '# X\n# X\n# X-1\n\n' + link('terceiro', '#x-1-1') + '\n',
    'cerca_interna': '````markdown\n```python\n# Falso\n```\n````\n\n' + link('falso', '#falso') + '\n',
}
for name, content in cases.items():
    with tempfile.TemporaryDirectory(prefix='docs-e12-') as d:
        p=pathlib.Path(d)
        git('init', '-q', cwd=p)
        (p/'README.md').write_text(content)
        git('add', 'README.md', cwd=p)
        broken, counts = docs_check.verificar(p)
        print('DOCS_SINTETICO', name, json.dumps({'quebrados': [str(x) for x in broken], 'contagem': counts}, ensure_ascii=False))

m=json.loads((root/'data/recovery/aprovado/manifesto.json').read_text())
print('PACOTE',json.dumps({'capturas_certificadas': len(m['oraculo_capturas']['certificadas']),
    'maior_snapshot':m['oraculo_capturas']['maior_snapshot'],
    'quarentena_fatias':len(m['oraculo_quarentena']), 'scd':len(m['oraculo_scd']),
    'max_event_sequence':m['max_event_sequence'], 'particoes':len(m['oraculo_particao'])},ensure_ascii=False))
PY
```

Saída literal:

```text
AIRFLOW_HISTORICO {'urls_com_credencial_literal': 1, 'atribuicoes_postgres_password_literais': 1, 'achados_detector': 0, 'registros_airflow': 0, 'senha_env_diferente_da_historica': True}
LITERAL_SINTETICO controle achados= 1 motivo= None
LITERAL_SINTETICO dolar achados= 0 motivo= referência a variável — `$VAR`, `${…}`, `$$VAR` do Make
LITERAL_SINTETICO parentese achados= 0 motivo= expressão, não literal — chamada de função ou indexação
LITERAL_SINTETICO colchete achados= 0 motivo= expressão, não literal — chamada de função ou indexação
DOCS_SINTETICO link_no_titulo {"quebrados": [], "contagem": {"documentos": 1, "links": 0, "ancoras": 0, "adrs": 0}}
DOCS_SINTETICO adr_no_titulo {"quebrados": [], "contagem": {"documentos": 1, "links": 0, "ancoras": 0, "adrs": 0}}
DOCS_SINTETICO colisao_de_slug {"quebrados": ["README.md:5: #x-1-1 — título não existe neste arquivo"], "contagem": {"documentos": 1, "links": 0, "ancoras": 1, "adrs": 0}}
DOCS_SINTETICO cerca_interna {"quebrados": [], "contagem": {"documentos": 1, "links": 0, "ancoras": 1, "adrs": 0}}
PACOTE {"capturas_certificadas": 11, "maior_snapshot": 43, "quarentena_fatias": 21, "scd": 4, "max_event_sequence": 13700, "particoes": 40}
```

**Sonda S2 — quantas capturas o bruto guarda.** A distinção importa: 11 certificados no pacote
não são todo o bruto. A consulta abaixo percorre as 40 tabelas, em leitura, e mede os `sync_id`
distintos; o resultado também refuta a quantidade 43 sem confundir bruto com certificado.

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python - <<'PY'
import os
from pathlib import Path
import sqlalchemy as sa
from mvp_ed1 import db, secrets_review
os.environ.update(secrets_review.read_env(Path('.env')))
e = sa.create_engine(db.database_url(db.WAREHOUSE), connect_args={
    'options': '-c default_transaction_read_only=on -c statement_timeout=60000'})
with e.connect() as c:
    names = c.exec_driver_sql("select table_name from information_schema.tables where table_schema='raw_legacy'").scalars().all()
    ids = set()
    for t in names:
        ids.update(c.exec_driver_sql(f'SELECT DISTINCT (_airbyte_meta::jsonb ->> \'sync_id\')::bigint FROM raw_legacy."{t}"').scalars().all())
    print('raw_legacy_sync_ids', sorted(x for x in ids if x is not None))
    print('raw_legacy_quantidade_sync_ids', len(ids - {None}))
    print('raw_legacy_retidos_do_pacote', len((ids - {None}) - {49}))
e.dispose()
PY
```

```text
raw_legacy_sync_ids [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33, 34, 35, 36, 38, 39, 43, 49]
raw_legacy_quantidade_sync_ids 29
raw_legacy_retidos_do_pacote 28
```

**Conferência do B6 e sondas do produto.** Foram confrontadas as 17 linhas da tabela da Capacidade
com as linhas emitidas pelo medidor nos logs do clone, não só com o diário. Na amostra de números
do plano e README conferem 13 tarefas, 16 views, 905 resultados dbt, 579 testes Python e 14 testes
de fronteira; na Execução Local, 12m 47s, 200 e 2.200 eventos, 11 alertas e o limiar 25; nas duas
consequências do ADR-0044, jobs 5, 43, 44, 46 e 49. As menções afetadas nos riscos, Governança e
pendências foram confrontadas com essas mesmas saídas. Os sete achados automáticos são sete
ocorrências agrupadas em cinco entradas YAML, conforme a identidade declarada pelo registro.

O arquivo do ADR-0044 preserva byte a byte o prefixo que existia em `7b0bea6`, acrescentando apenas
23 linhas: `ADR0044_texto_anterior_preservado True linhas_acrescentadas 23`. Nenhuma medição antiga
do ADR foi reescrita.

Logs usados, todos no checkout de trabalho: `data/medicoes/b5/`, em especial
`20260925T132812Z_73_l4_check.log`, `20260925T135141Z_73_l5_dag_status.log`,
`20260925T135631Z_73_l6_stream_alerts_2200.log`, `20260925T140242Z_73_l7_quatro_zeros.log` e
`20260925T154755Z_73_l9_recovery_restore_refeito.log`. Deles foram lidas, entre outras, as saídas:

```text
579 passed, 4 skipped in 271.12s (0:04:31)
tópico mvp.alerts.inventory_low_stock: 11 alertas
  aberturas (cruzaram o limiar de 25 para baixo): 4
  normalizações (voltaram acima): 7
  correções de evento atrasado: 0
corte 16100
so_no_lote 0
so_no_fluxo 0
payloads_diferentes 0
saldos_diferentes 0
linhas_lote 16100
linhas_fluxo 16100
soma_lote 702104
soma_fluxo 702104
579 passed, 8 skipped in 269.31s (0:04:29)
conferir-restauracao: fontes iguais ao manifesto, memória contida e intacta, identidade nova acima da retida, auditoria dela igual ao que a classificação rejeitou, memória de exclusões renascida igual, livro da origem inteiro e igual nos dois caminhos.
recovery-restore: a sequência inteira passou. 'make recovery-promote' aprova o pacote.
```

Nesta revisão, consultas `SELECT count(*)` por tabela das fontes, leitura de
`governance.legacy_captures` e `SELECT count(md5(to_jsonb(s)::text)) FROM consumption.<view> s`
por cada uma das 16 views produziram:

```text
source_db transaction_read_only= on
source_db tabelas= 40 linhas= 252955 vazias= [] contagens_iguais_manifesto= True
livro_origem (13700, 13700)
legacy_db transaction_read_only= on
legacy_db tabelas= 40 linhas= 12744 vazias= [] contagens_iguais_manifesto= True
warehouse_db transaction_read_only= on
brands (-27, 4, 27, 28)
views_consumo 16
```

A consulta de capturas devolveu, para a nova, `(49, 'complete', 40)`. As 16 avaliações completas
das views terminaram sem erro. `leitura.comparar_caminhos(engine, 13700)`, com o mesmo motor
somente de leitura, devolveu:

```text
{"corte": 13700, "linhas_fluxo": 13700, "linhas_lote": 13700, "payloads_diferentes": 0, "saldos_diferentes": 0, "so_no_fluxo": 0, "so_no_lote": 0, "soma_fluxo": 701841, "soma_lote": 701841}
```

O catálogo foi servido a partir dos arquivos existentes em `dbt/target`, por servidor HTTP local
temporário, e aberto no Chrome sem interface. `/`, `manifest.json` e `catalog.json` responderam
`200`; o DOM mostrou o título `monthly_revenue_by_channel_and_category`, a descrição da P01,
o texto expandido de receita líquida e suas colunas. A captura de tela com `?g_v=1` mostrou o grafo
renderizado. Para reproduzir esta inspeção, servir `dbt/target` com
`python3 -m http.server 8080 --bind 127.0.0.1 --directory dbt/target` e abrir
`http://127.0.0.1:8080/#!/model/model.mvp_ed1.monthly_revenue_by_channel_and_category?g_v=1`;
remover `?g_v=1` permite inspecionar a descrição. O servidor temporário foi encerrado. Isso amplia
a prova de `200` do B5 por amostragem; não é revisão visual integral das 199 relações. Os artefatos
temporários desta revisão estão em `/tmp/revisao-final-e12-gBC8aG/` e não entram no commit.

Permanecem **não medidos nesta revisão**: novo ciclo completo ou restauração, instalação sem
caches, variância de recursos, segundo ciclo real do re-base, restauração da pilha completa em
destino vazio e quantidade esperada de alertas por oráculo independente. O B5 mediu a emissão de
11 alertas, suficiente para o oráculo explícito da linha 6, que pede mais de zero; não provou que
11 era a quantidade correta para aquele corte. Essas limitações não foram convertidas em novos
resultados nem usadas para reabrir o que já estava aceito no roteiro.

**Segunda rodada, 03/10/2026 — Codex, sobre `d8ebe5a..503edf6`.** A §8 inteira e as situações
dos onze achados foram lidas antes das sondas. Os dois bloqueantes originais estão tratados;
recomendo **seis ajustes novos nas automações antes do aceite**, sem novo bloqueante. As
contraprovas originais foram corrigidas, mas parte da resposta introduz regressões ou deixa
lacunas. Os critérios 2, 3 e 4, o B5 e seus logs não foram reabertos. Nenhuma correção foi feita.

| Resposta original | Conferência própria nesta rodada |
|---|---|
| RVF12-01 | **Confirmada para o caso conhecido.** S1 literal: `achados_detector: 2`, `registros_airflow: 4`, senha atual diferente. A comparação de todas as chaves sensíveis do `.env` com o valor histórico devolveu `[]`. `docker volume inspect mvp_ed1_airflow_db_data --format '{{.Name}} {{.CreatedAt}}'` devolveu `mvp_ed1_airflow_db_data 2026-09-25T10:35:44-03:00`. O histórico tem 11 ocorrências tratadas, sem blob pulado. A rotação registrada é coerente com essas evidências; não instalei nem retomei Airflow. |
| RVF12-02 | **Confirmada a formalização e a transação.** ADR-0048 aceito, D48 no Registro e nas Pendências, Governança §9, R7, critério 6, registro YAML e README conferidos integralmente no diff. Os contadores dão 48 ADRs, uma decisão e uma aprovação pendentes; os links passam. A opinião sobre Paridade está abaixo. |
| RVF12-03 | **Contraprova corrigida; resposta ainda parcial.** Os quatro literais da S1 têm um achado cada; R2-A também acusa o grupo entre aspas. A referência completa segue dispensada. Uma referência incompleta também é dispensada, e há dois falsos positivos novos (RVF12-2-01, 02 e 03). |
| RVF12-04 | **Contraprova corrigida, com regressão.** S1 acusa o arquivo e o ADR inexistentes no título. R2-C acusa como link um exemplo dentro de código em linha (RVF12-2-05). |
| RVF12-05 | **Confirmada.** S1 aceita a terceira âncora. Sonda adicional com títulos `X`, `X`, `X-1`, `X`, `X-1`, `X-1-1`, `X-2`, `X` devolveu `['x', 'x-1', 'x-1-1', 'x-1-1-1', 'x-1-2', 'x-2', 'x-2-1', 'x-3']`, coerente com o [algoritmo de colisões do github-slugger](https://github.com/Flet/github-slugger/blob/master/index.js). |
| RVF12-06 | **Comprimento e caractere confirmados; GFM ainda parcial.** S1 acusa a âncora fictícia; sonda com abertura de quatro crases, três crases e tis dentro, e fechamento de cinco crases devolveu somente `[(6, '# Real')]`. A indentação livre foi copiada para o verificador de ADR e oculta texto válido (RVF12-2-06). |
| RVF12-07 | **Contagem atual confirmada; exclusão de exemplos parcial.** O verificador real passa com uma decisão e uma aprovação. R2-B faz um título dentro de código virar aprovação (RVF12-2-04). O teste novo que ignora a citação de ADR em código passou. |
| RVF12-08 | **Confirmada.** S1 mede 11 certificadas e maior snapshot 43. S2, com `SHOW transaction_read_only` devolvendo `on`, contou 29 `sync_id`, 28 retidos e o 49. A prosa agora distingue essas quantidades e declara não medida a atribuição dos 293 MB. A contagem das duas capturas do ciclo é documental; não reexecutei o B5. |
| RVF12-09 | **Confirmada.** `rg -n -e 'Uma armadilha' -e 'Havia uma segunda' -e 'parallelism=1' docs/execucao_local.md Makefile` mostra o problema datado como anterior e o alvo serializado. O teste da serialização passou. |
| RVF12-10 | **Confirmado o contrato de instalação.** `AIRBYTE_CHART_VERSION := 2.3.0`, flag no ramo sem cluster, teste simulado passando e `abctl` v0.30.4 com a opção no `--help`. Conferi o índice v2 e o arquivo: versão disponível e HTTP 200. Instalação efetiva **não medida**, conforme a autorização desta rodada. |
| RVF12-11 | **Confirmada.** Leitura própria do diff e `rg -n -e 'não foi medido' -e 'todas menos' docs/plano_de_desenvolvimento.md README.md` encontram as ressalvas no critério 2 e no Status. Nenhum pico novo foi atribuído ao `migrate`. |

**Paridade do ADR-0048.** Considero coerente incluir a senha do Cloud SQL no segundo tipo: ela
protege um serviço externo à estação, mesmo com IP privado. É uma classificação conservadora
pela política, que distingue o contêiner da estação dos serviços externos. O acesso ao Cloud SQL
também exige conectividade; com IP privado, alcance da VPC, e com Auth Proxy, autorização IAM
além da autenticação do banco ([documentação do proxy](https://docs.cloud.google.com/sql/docs/postgres/sql-proxy)).
Rotacionar a senha no próprio banco invalida o valor antigo
([gestão de usuários](https://docs.cloud.google.com/sql/docs/postgres/create-manage-users)). A obrigação
adicional de reescrever o histórico é a decisão do Owner, com seu custo aceito. Armazenar no
Secret Manager cumpre a paridade da Arquitetura §5; a classificação acompanha o serviço protegido.
Esta é uma leitura normativa e técnica, **não uma medição da implantação GCP**, que não existe
neste escopo. Não proponho reescrever o ADR aceito.

**Validação própria na ponta `503edf6`, antes deste parecer:**

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/pytest -q -rs -p no:cacheprovider \
  tests/test_secrets_review.py tests/test_docs_check.py tests/test_verificador_adr.py \
  tests/test_makefile.py::test_airbyte_up_instala_quando_nao_ha_cluster \
  tests/test_makefile.py::test_airbyte_config_aplica_um_recurso_por_vez
```

```text
62 passed in 13.38s
docs-check: 108 documentos, 1035 links de arquivo, 160 âncoras, 656 citações de ADR — nada quebrado
revisão de segredos: nada encontrado nos arquivos rastreados
revisão do histórico: nada não tratado (11 achado(s), todos registrados; 0 blob(s) pulado(s))
ADRs aceitos: 48  ·  esperando ADR: 1  ·  esperando o Owner: 1 decisão(ões) e 1 aprovação(ões)  ·  Dnn citados: 61
Integridade conferida: links, ADRs citados, decisões pendentes e contadores.
transaction_read_only on
raw_legacy_quantidade_sync_ids 29
raw_legacy_retidos_do_pacote 28
```

Todos esses comandos saíram 0, sem teste pulado. A S1 foi extraída do próprio parecer anterior
e executada literal: saída idêntica à §8.2. A conexão inicial ao PostgreSQL e a inspeção do volume
foram bloqueadas pelo sandbox; repetidas com acesso local autorizado, concluíram. Nenhum alvo
proibido foi executado. O alvo de instalação foi exercitado **só com executáveis simulados**.

Para conferir a disponibilidade do chart sem instalar, o [resolver v0.30.4](https://github.com/airbytehq/abctl/blob/v0.30.4/internal/helm/chart.go)
seleciona o repositório v2 para 2.3.0. Consultei `https://airbytehq.github.io/charts/index.yaml`
com `curl -fsSL --max-time 30` e filtrei `entries.airbyte` pela versão: **uma entrada**,
`urls: ['airbyte-2.3.0.tgz']`, `appVersion: '2.3.0'`. A consulta
`curl -fsSL --max-time 30 --head https://airbytehq.github.io/charts/airbyte-2.3.0.tgz` devolveu
`HTTP/2 200`, `content-length: 60130`. O primeiro índice consultado, `/helm-charts`, era o v1;
sua ausência de 2.3.0 foi descartada ao conferir as constantes da versão do abctl. Não é achado.

**Sondas adicionais R2-A/B/C, reproduzíveis da raiz do checkout.** Escrevem apenas em diretórios
temporários. Valores e links são montados em partes para que o parecer não acrescente fixtures
ao histórico nem links fictícios aos documentos. R2-B reaproveita apenas o montador do teste;
as entradas adicionais são contraprovas desta revisão. `antes` é o detector de `d8ebe5a`.

```bash
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python - <<'PY'
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import types

from mvp_ed1 import docs_check, secrets_review

root = Path.cwd()
old = types.ModuleType('secrets_antes_r2')
sys.modules[old.__name__] = old
exec(subprocess.check_output(['git', 'show', 'd8ebe5a:src/mvp_ed1/secrets_review.py'], text=True), old.__dict__)
key, user = 'pass' + 'word', 'u' + 'ser'
cases = {
    'usuario_literal': json.dumps({'username': 'reader', key: 'reader'}),
    'identificador_python': f'{user} = db_user\n{key} = db_user\n',
    'grupo_literal': json.dumps({key: '(Ab9Z7q1)'}),
    'referencia_completa': json.dumps({key: '${DB_PASSWORD}'}),
    'referencia_incompleta': json.dumps({key: '${Ab9Z7q1'}),
    'shell_posicional_url': 'url="' + 'postgresql' + '://' + 'reader' + ':' + '$1' + '@localhost/db"',
}
for label, text in cases.items():
    print('R2_A', label, 'antes=', len(old.detectar(text)), 'depois=', len(secrets_review.detectar(text)))

spec = importlib.util.spec_from_file_location('adr_tests_r2', root / 'tests/test_verificador_adr.py')
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)
def link(label, target):
    return '[' + label + ']' + '(' + target + ')'
adr_cases = {
    'controle': '',
    'aprovacao_em_codigo': '\n```markdown\n### Exemplo\n```\n',
    'fecho_indentado': '\n```text\n    ```\nExemplo\n```\n\n' + link('perdido', 'sumiu.md') + '\n',
}
for label, extra in adr_cases.items():
    with tempfile.TemporaryDirectory(prefix='adr-e12-r2-') as d:
        result = tests._verificar(Path(d), esperando=tests.ATUAL['esperando'] + extra)
        problems = [s.strip() for s in result.stdout.splitlines() if s.startswith(' -')]
        print('R2_B', label, json.dumps({'exit': result.returncode, 'problemas': problems}, ensure_ascii=False))

with tempfile.TemporaryDirectory(prefix='docs-e12-r2-') as d:
    p = Path(d)
    subprocess.run(['git', 'init', '-q'], cwd=p, check=True)
    (p / 'README.md').write_text('# Como escrever `' + link('perdido', 'sumiu.md') + '`\n')
    subprocess.run(['git', 'add', 'README.md'], cwd=p, check=True)
    broken, counts = docs_check.verificar(p)
    print('R2_C', json.dumps({'quebrados': [str(x) for x in broken], 'contagem': counts}, ensure_ascii=False))
PY
```

```text
R2_A usuario_literal antes= 0 depois= 1
R2_A identificador_python antes= 0 depois= 1
R2_A grupo_literal antes= 0 depois= 1
R2_A referencia_completa antes= 0 depois= 0
R2_A referencia_incompleta antes= 0 depois= 0
R2_A shell_posicional_url antes= 0 depois= 1
R2_B controle {"exit": 0, "problemas": []}
R2_B aprovacao_em_codigo {"exit": 1, "problemas": ["- pendencias.md desatualizado — o cabeçalho deveria dizer 1 aprovações pendentes (Exemplo)", "- README desatualizado — a linha Pendências do Owner conta 1, e 'Esperando você' tem 2 (D43; Exemplo)"]}
R2_B fecho_indentado {"exit": 0, "problemas": []}
R2_C {"quebrados": ["README.md:1: sumiu.md — arquivo não existe"], "contagem": {"documentos": 1, "links": 1, "ancoras": 0, "adrs": 0}}
```

Também confrontei o código anterior com as duas últimas entradas: no exemplo de cerca, o
verificador anterior saía **1**, `link quebrado — docs/pendencias.md: sumiu.md`; no título com
código em linha, o `docs_check` anterior contava **0 links**, sem quebrados. São regressões
do intervalo. **Não medidos:** instalação real do chart, implantação GCP e caminhos operacionais
que exigiriam escrever dados. Os artefatos temporários estão em `/tmp/revisao-e12-r2-503edf6/`.


**Achados — cada linha inclui reprodução, saída observada e encaminhamento proposto.**

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVF12-01 | `docs/segredos_tratados.yml`; `src/mvp_ed1/secrets_review.py`, `detectar`; critério 6 do plano | **O histórico real do Airflow ficou fora do registro D48.** Reproduzir S1, caso `AIRFLOW_HISTORICO`, e ler `git show --format=full 0b89b3d`: o commit reconhece a senha usada no banco de metadados e relata sua rotação. Saída da sonda: **1 URL literal, 1 atribuição literal, 0 achados, 0 registros do Airflow**; o valor do `.env` atual é diferente. `make secrets-history` sai 0 com apenas as sete fixtures. O limite de detecção foi declarado, mas não dispensa registrar um caso que já foi encontrado por inspeção. Proponho registrar o tratamento desse caso e cobrir a composição histórica com um controle que não o dispense; então repetir a varredura. Não há aqui demonstração de senha ainda ativa. | **bloqueante** | Aberto; o ✓ de ausência de segredo histórico não está integralmente respaldado pelo controle/registro apresentado. — **Resposta, 03/10/2026: corrigido.** `8e60739`: a senha igual ao usuário, da mesma URL ou de uma atribuição de usuário do mesmo texto, não passa mais pela regra da palavra sem dígito nem pelo mínimo de 8; referência repetida continua molde. `41c39c5`: os 4 achados registrados pela D48, com o tratamento conferido (volume do banco de metadados atual criado no B5; nenhuma chave secreta do `.env` com o valor antigo). No histórico inteiro, só os dois blobs da composição (4ff3be9, ea91a49) têm a forma; `make secrets-history`: nada não tratado, 11 achados. S1 refeita: `achados_detector: 2`, `registros_airflow: 4` (§8). |
| RVF12-02 | `docs/governanca_de_dados.md` §9–§10; `docs/pendencias.md`, aceite; plano, Etapa 12 | **Parecer solicitado: a varredura aplica a política; a D48 acrescenta política.** Reproduzir `git diff 7b0bea6..807a904 -- docs/governanca_de_dados.md` e ler a §10. O diff acrescenta à rotação já exigida uma distinção entre credencial local e externa, registro obrigatório e, para token externo/nuvem, revogação **e reescrita** pelo Owner; a §10 continua exigindo decisão explícita e ADR. A obrigação de reescrever não se deduz da regra anterior de rotacionar. D48 já tem decisão do Owner; falta, nesta leitura, formalizá-la em **novo ADR**, sem reescrever aceitos. A varredura, isoladamente, é uma implementação do controle existente. “Nenhum componente novo, logo nenhum ADR” não resolve o requisito específico da §10. | **bloqueante** | Parecer normativo para decisão expressa do Owner antes do fechamento; recomendo ADR para D48. Não implementei nem tratei o aceite geral como ratificação tácita. — **Resposta, 03/10/2026: o Owner decidiu pelo ADR.** `021cf12`: [ADR-0048](docs/adr/0048-tratar-segredo-achado-no-historico-pelo-tipo-da-credencial.md), com a transação — Registro §2, Governança v2.6 §9, Riscos v1.5 (R7), Plano v3.7 (critério 6), Pendências (a decisão embutida no aceite, resolvida), `segredos_tratados.yml` e README; `verificar.py` e `docs-check` sem problema. A varredura em si continua lida como aplicação da regra existente, como o parecer leu. |
| RVF12-03 | `src/mvp_ed1/secrets_review.py`, `PLACEHOLDER_RULES` e `detectar` | **Os moldes dispensam literais, além do limite alfabético declarado.** S1 serializa quatro valores sintéticos como JSON: o controle tem **1 achado**; os valores com `$`, `(` e `[` têm **0**, classificados como variável/expressão mesmo estando entre aspas. A regra usa busca por caractere em qualquer posição e o detector perde o contexto de literal. São credenciais na própria forma JSON prometida por B2. Proponho restringir os moldes às referências completas/contextos reconhecidos e testar literais nessas mesmas posições, sem enfraquecer a detecção após rotação. | **ajuste** | Aberto; contraprova isolada, sem alegação de outro segredo real encontrado. — **Resposta, 03/10/2026: corrigido.** `8e60739`: as regras de referência ancoram no início (`$`, e também `{{`); a de expressão vive em `EXPRESSION_RULES` e só vale fora de literal — entre aspas ou numa URL o valor é texto —, com o grupo de regex (`\(` do `sed`, `(?` do Python) que a sonda do histórico achou protegido pela regra antiga (§8.1). S1 refeita: os quatro literais com 1 achado cada. Modo rastreado sem achado; histórico sem achado novo além dos 4 do RVF12-01. Limite declarado no módulo: valor **sem aspa** que comece como chamada (`Ab9(…`) segue tomado por código. |
| RVF12-04 | `src/mvp_ed1/docs_check.py`, `ler`, ramo `if titulo` | **Links e citações de ADR em títulos são ignorados.** S1, casos `link_no_titulo` e `adr_no_titulo`: um arquivo inexistente ligado num título e um título citando ADR inexistente devolvem `quebrados: []`, com `links: 0` e `adrs: 0`. O `continue` após registrar a âncora impede a conferência do restante da linha. Proponho extrair a âncora e também examinar links/citações do título. | **ajuste** | Aberto; os testes atuais passam porque conferem o slug do título com link, sem conferir o destino dele. — **Resposta, 03/10/2026: corrigido.** `c8819d3`: o título gera a âncora e segue lido como texto. S1 refeita: `link_no_titulo` e `adr_no_titulo` acusados. No repositório, as citações de ADR conferidas passam de 604 para 652 (os títulos dos próprios ADRs); nada quebrado. |
| RVF12-05 | `src/mvp_ed1/docs_check.py`, `ler`, sufixos em `vistos` | **A unicidade de âncoras não inclui as já geradas por sufixo.** S1, `colisao_de_slug`, com títulos `X`, `X`, `X-1`: o link `#x-1-1` é acusado como inexistente. Pela regra de [âncoras únicas do GitHub](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#section-links), a terceira âncora deve evitar `x-1`, já ocupada pela segunda. Proponho conferir colisões contra todas as âncoras emitidas, inclusive sufixadas. | **ajuste** | Aberto; falso positivo reproduzido, sem supor que uma âncora atual do projeto esteja quebrada. — **Resposta, 03/10/2026: corrigido.** `a819d53`: o algoritmo do `github-slugger`, com toda âncora emitida reservada. S1 refeita: `colisao_de_slug` sem quebrado. O repositório não muda: 160 âncoras. |
| RVF12-06 | `src/mvp_ed1/docs_check.py`, `_fora_de_codigo` e `CERCA` | **Cerca menor fecha indevidamente um bloco maior.** S1, `cerca_interna`: dentro de uma cerca de quatro crases, três crases fazem o leitor alternar para fora e registrar `# Falso` como título; o link posterior para `#falso` passa com **0 quebrados**. No [GFM, a cerca de fechamento precisa ter o mesmo caractere e comprimento suficiente](https://github.github.com/gfm/#fenced-code-blocks); esse título continua sendo código. Proponho guardar caractere/comprimento da abertura e cobrir cercas aninhadas e de tipos diferentes. | **ajuste** | Aberto; falso negativo reproduzido sobre Markdown válido. — **Resposta, 03/10/2026: corrigido.** `40e63b0`: o bloco fecha só com o mesmo caractere, comprimento igual ou maior e nada depois; crase na abertura de cerca de crases é código em linha. S1 refeita: `cerca_interna` acusa `#falso`. As linhas lidas como texto são idênticas às do leitor antigo nos 108 documentos. |
| RVF12-07 | `.claude/skills/adr/verificar.py`, `decisoes`; `README.md`, linha Pendências do Owner | **O verificador não conta aprovações, embora anuncie contar tudo que espera o Owner.** Reproduzir `python3 .claude/skills/adr/verificar.py` em `04e1aa5`: saída **1**, `README ... conta 2, e 'Esperando você' tem 1 (D43)`. O README conta corretamente aceite da Etapa 12 + D43; `codigos_dos_titulos` só extrai `Dnn` e perde o aceite. Proponho distinguir decisões e aprovações e testar o estado real com ambas. Não reduzir o README para 1 para satisfazer o teste. | **ajuste** | Aberto; os dez cenários do teste do verificador passaram, mas não incluem este estado criado por B6. — **Resposta, 03/10/2026: corrigido.** `09cb85c`: título `###` sem `Dnn` em "Esperando você" é aprovação; o cabeçalho *Aprovações pendentes* é conferido, e a linha do README conta decisões e aprovações. O estado de `04e1aa5` virou cenário que passa; o README que esquece a aprovação e o cabeçalho que não a conta são acusados. O README não foi reduzido a 1. |
| RVF12-08 | `docs/capacidade_e_recuperacao.md` §2.12, explicação 3 | **“Memória de 43 capturas” usa o identificador como quantidade e não sustenta a explicação causal de tamanho.** Reproduzir S1 (`PACOTE`) e S2: **11 capturas certificadas, maior snapshot 43; 28 sync_ids retidos no bruto, mais o 49 novo**, não 43 capturas. Os tamanhos medidos **627,9 MB e 334,6 MB** conferem; a causalidade quantitativa da frase não foi medida por ela. Proponho corrigir a contagem e distinguir certificados, bruto retido e identificador, preservando os tamanhos observados. | **ajuste** | Aberto; corrigir no dono atual do número, sem alterar medições de ADRs aceitos. — **Resposta, 03/10/2026: corrigido.** `69a6f94`: S2 reproduzida em leitura (`transaction_read_only=on`) — 29 `sync_id`, 28 retidos e o 49; 11 certificadas no pacote, a maior a 43. O "3" do ciclo novo também era identificador: eram **duas** capturas, a 2 e a 3 (diário do B5, 13:52). Os tamanhos ficam; a atribuição causal dos 293 MB de diferença passa a ser declarada não medida. Capacidade v2.14. |
| RVF12-09 | `docs/execucao_local.md` §6, “Duas armadilhas no caminho de volta”; `Makefile`, `airbyte-config` | **O procedimento ainda descreve criação paralela como comportamento atual.** Reproduzir `rg -n -e 'Duas armadilhas' -e 'cria fonte e destino em paralelo' -e 'parallelism=1' docs/execucao_local.md Makefile`. Saída: a linha 663 da prosa diz que o `terraform apply` cria fonte e destino em paralelo e recomenda rodar de novo; a linha 420 da receita agora passa `-parallelism=1`. O teste `test_airbyte_config_aplica_um_recurso_por_vez` passou. Proponho datar a armadilha como comportamento anterior e apontar o tratamento já aplicado, sem conservar a repetição como orientação normal. | **ajuste** | Aberto; contradição introduzida pela correção do intervalo, por isso está no escopo. — **Resposta, 03/10/2026: corrigido.** `df46f9c`: a armadilha vira registro do que acontecia antes de `45395e3`, e a que continua valendo (a conexão recriada sem cursor) fica como orientação. Execução Local v1.17. |
| RVF12-10 | `Makefile`, `airbyte-up`; premissa 1 da §5 deste dossiê; risco R6 | **Fixar o abctl não fixa a instalação nova do Airbyte.** Reproduzir `DO_NOT_TRACK=1 .tools/abctl version` → `version: v0.30.4`; a receita de instalação não passa `--chart-version`. No [resolver da versão v0.30.4](https://github.com/airbytehq/abctl/blob/v0.30.4/internal/helm/chart.go#L62-L73), chart e versão vazios chamam `GetLatestAirbyteChartUrlFromRepoIndex`. O log B5 `20260925T124958Z_73_l2_airbyte_up.log`, sem escapes ANSI, registra `Starting Helm Chart installation of 'airbyte/airbyte' (version: 2.3.0)`. A premissa de versão estável está refutada pelo código upstream; uma próxima instalação efetiva não foi executada nem sua versão inferida. Proponho fixar o chart medido antes da tag, ou obter decisão explícita sobre essa limitação de reprodutibilidade. | **ajuste** | Aberto; é tratamento do R6 existente. Nenhuma instalação ou atualização foi feita pela revisão. — **Resposta, 03/10/2026: o Owner decidiu fixar.** `cc84cd3`: `AIRBYTE_CHART_VERSION := 2.3.0`, a do log da linha 2 do B5, e `--chart-version` no ramo de instalação do `airbyte-up`; `abctl local install --help` da v0.30.4 lista a opção; o teste do ramo exige a chamada. Execução Local e R6 atualizados. **Não medido:** uma instalação real com o *chart* fixado — o cluster de pé não passa por esse ramo. |
| RVF12-11 | Plano, Etapa 12; README, Status; Capacidade §2.12, linha `migrate` | **O pico de memória não foi medido em toda linha.** Reproduzir a leitura de `data/medicoes/b5/20260925T124837Z_73_l1_migrate.log`: `migrate`, **0m 02s**, **não medido**, **não medido**, **0 amostras**, **24.9 MB**. A Capacidade declara corretamente a lacuna; o plano diz “cada uma” com extremos e o README “pico ... em cada linha”. Proponho carregar a mesma ressalva para esses resumos. O ciclo dos cinco cenários tem medições; não atribuo um pico ao comando curto nem peço sua reexecução nesta revisão. | **observação** | Ressalva de P5 para o fechamento; a ausência está explicitamente preservada no parecer do critério 2. — **Resposta, 03/10/2026: ressalva aplicada.** `30e8386`: o critério 2 do plano e o status do README dizem que o pico do `migrate`, de 2 s, não foi medido. A linha não foi refeita. |
| RVF12-2-01 | `src/mvp_ed1/secrets_review.py:113`, regra de referência; RVF12-03 | **A referência ainda é reconhecida só pelo prefixo.** Reproduzir R2-A, `referencia_incompleta`: JSON com valor sintético começando com `${` e **sem chave de fechamento** devolve **0 achados antes e depois**; a referência completa também dá 0. A forma incompleta não é uma referência válida, mas dispensa o literal. A promessa de molde como propriedade do valor inteiro, na Governança §9 e no módulo, continua mais forte que o controle. Proponho delimitar as formas completas e considerar o contexto, incluindo um controle negativo para referência malformada. | **ajuste** | Aberto; lacuna remanescente da resposta, não falso negativo introduzido agora nem segredo real adicional encontrado. — **Resposta, 03/10/2026: corrigido.** `29d2424`: a referência é forma completa — `$VAR`, `$1`, `${…}`, `$(…)`, `$$` do Make e `{{ … }}` —, lida no resto da linha e alcançando o fim do valor; aspa dentro dela só com par, e a chave do objeto JSON em volta não a fecha. R2-A `referencia_incompleta`: 1 achado; controle negativo em JSON e YAML nos testes. O `{{`, com o mesmo defeito, entrou na mesma regra. No histórico, as 575 ocorrências do `$` são completas e a varredura segue em 11 (§9.1). |
| RVF12-2-02 | `src/mvp_ed1/secrets_review.py:88`, `USER_PATTERN`; `detectar:232`, exceção da `WORD_RULE` | **Dois identificadores Python viram senha de fábrica.** Reproduzir R2-A, `identificador_python`: as atribuições de usuário e senha recebem o identificador `db_user`, sem aspas; **0 achados antes, 1 depois**. São referências a uma variável, sem credencial literal. O conjunto de usuários perdeu essa distinção e desativa a regra de identificador por igualdade textual. Proponho preservar referências no código e manter a detecção do par literal de fábrica da composição/URL. | **ajuste** | Aberto; falso positivo novo. O controle JSON com usuário/senha literais iguais é corretamente acusado. — **Resposta, 03/10/2026: corrigido.** `3b72ca6`: o par só conta entre literais — entre aspas, ou numa linha de configuração YAML ou ENV, em que a chave abre a linha e o valor a fecha. R2-A `identificador_python`: 0; argumentos nomeados em várias linhas: 0; os controles literais (JSON, Python entre aspas, ENV, lista da composição) e o par de `4ff3be9` continuam achados. Achado próprio em `3b81cc3`: o `)` do último argumento nomeado fazia do identificador um valor, desde antes da revisão final (§9.2). |
| RVF12-2-03 | `src/mvp_ed1/secrets_review.py:113`, regra `$`; `detectar`, URL | **Uma referência posicional válida de shell passou a ser acusada.** Reproduzir R2-A, `shell_posicional_url`: uma URL sob aspas duplas usa `$1` como senha; **0 achados antes, 1 depois**. `$1` é parâmetro posicional, e a regra nova só admite letra, sublinhado, chave ou parêntese depois de `$`. Proponho reconhecer a forma completa do parâmetro nesse contexto, preservando a detecção de texto literal com `$`. | **ajuste** | Aberto; falso positivo novo em entrada sintética válida, sem alegação de uso atual dessa forma no projeto. — **Resposta, 03/10/2026: corrigido** em `29d2424`, na regra do RVF12-2-01: `$1` é forma completa, e `$1Ab9Z7q1` continua achado. R2-A `shell_posicional_url`: 0. |
| RVF12-2-04 | `.claude/skills/adr/verificar.py:74`, `decisoes`; `main:203` | **Blocos de código ainda entram na contagem de aprovações.** Reproduzir R2-B, `aprovacao_em_codigo`: só acrescentar um título `### Exemplo` em cerca ao estado correto faz a saída mudar de **0 para 1**, exigindo uma aprovação inexistente e acusando que o README conta 1 com 2 pendentes. `sem_codigo` só é usado na varredura de links/ADRs; `decisoes` recebe os textos inteiros. Proponho excluir exemplos também antes de extrair seções, títulos e contadores. | **ajuste** | Aberto; regressão na contagem nova, além da citação em código que o teste já cobre. — **Resposta, 03/10/2026: corrigido.** `8283886`: o texto sem código é calculado uma vez e serve aos links, às citações de ADR e às seções, títulos e contadores das decisões. R2-B `aprovacao_em_codigo`: saída 0; cenário novo com aprovação e decisão só em bloco de código. |
| RVF12-2-05 | `src/mvp_ed1/docs_check.py:141`, `ler`, links em títulos | **Exemplo de link em código em linha virou link real.** Reproduzir R2-C: título que mostra a sintaxe de link entre crases; saída **`README.md:1: sumiu.md — arquivo não existe`**, 1 link. Antes havia 0 links. Pelo [GFM, código em linha tem precedência sobre links](https://github.github.com/gfm/#code-spans); esse texto não cria ponteiro. Proponho conferir os links renderizáveis do título respeitando código em linha, preservando sua contribuição ao texto da âncora. | **ajuste** | Aberto; falso positivo novo na resposta a RVF12-04. — **Resposta, 03/10/2026: corrigido.** `6be1f54`: o código em linha sai antes da busca de link em toda linha, não só no título — a sequência de crases fecha só noutra do mesmo comprimento, crase escapada não abre, e link cujo texto é código continua link. O texto da âncora não muda. R2-C: 0 quebrados, 0 links; as contagens do repositório não mudaram. |
| RVF12-2-06 | `.claude/skills/adr/verificar.py:160`, `CERCA`/`sem_codigo`; regra compartilhada com `docs_check` | **A cerca indentada faz o verificador novo ocultar um link quebrado fora do bloco.** Reproduzir R2-B, `fecho_indentado`: abertura normal, três crases com quatro espaços como conteúdo, fechamento normal e depois um link inexistente. Saída nova **0, `Integridade conferida`**, sem problemas; o verificador anterior saía **1** com `link quebrado — docs/pendencias.md: sumiu.md`. No [GFM o fechamento admite até três espaços](https://github.github.com/gfm/#fenced-code-blocks), fora de contexto de lista; o `\s*` aceita quatro, fecha cedo e reabre na cerca verdadeira, escondendo o link. Proponho respeitar a indentação e o contexto de lista, com controle do texto depois do fechamento. | **ajuste** | Aberto; a liberdade de indentação já existia no `docs_check`, mas sua cópia para o verificador de ADR introduziu esta regressão no intervalo. — **Resposta, 03/10/2026: corrigido.** `42e2ce9`: a cerca abre e fecha com até três espaços além da coluna em que o conteúdo do item de lista começa, zero fora de lista; linha com menos recuo que o item encerra o item e o bloco. Vale nas duas cópias, e um teste confere que elas dão o mesmo texto nos casos de recuo e nos 108 documentos. R2-B `fecho_indentado`: saída 1, `link quebrado — docs/pendencias.md: sumiu.md`. Limites declarados na §9.5. |
