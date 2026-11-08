# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `4e0dea2..b9e9c04` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
f6c45a5 fix: impede que o desmonte deixe peering, backup ou disco do Airbyte
d9b8dc3 feat: acrescenta o desmonte da §6.5 em alvos do make
75fb375 docs: registra o desmonte em alvos do make e o inventário padrão
8a82c8a feat: deixa as cargas das origens gravarem os registros fora do data/ local
d73a771 feat: acrescenta os alvos das origens no Cloud SQL pelo proxy
9b22a76 docs: escreve o roteiro de segunda e registra as origens no Cloud SQL
f7c2d42 feat: expõe a raiz do livro, o IP privado do Cloud SQL e os datasets
675f201 feat: acrescenta a época inicial da nuvem e o que ela pede antes
c8f8dd3 docs: escreve a parte 1 do roteiro de terça e registra a época inicial
be5dbc0 feat: acrescenta as capturas e o caminho quente da nuvem em alvos
b8eae8a docs: escreve a parte 2 do roteiro de terça e registra o que a P3 ainda não prova
3b703e6 feat: faz o oráculo da memória ler o BigQuery
7fadef3 feat: audita os jobs da conexão legada contra o livro
f9399b5 feat: acrescenta os alvos do oráculo da memória e da auditoria na nuvem
132edf2 docs: põe a memória e os jobs no roteiro de terça e registra o G2.1 inteiro
6f83fda refactor: tira dos testes a matriz do diário de mutações para o código
1bfceae fix: grava o diário das mutações no manifesto do legado do ambiente
b714d3c feat: acrescenta a fluxo_batch, as mutações e a matriz da quarta em alvos
633878c docs: escreve o roteiro de quarta e registra a matriz das duas capturas
c117f8e feat: mede a latência do caminho quente e o tamanho por dataset
b9e9c04 docs: põe a latência e o tamanho nos roteiros e registra a medida de hoje
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 32 arquivos

- `Makefile`
- `PLANO_etapa_13.md`
- `docs/registro_fase_gcp.md`
- `src/mvp_ed1/gcp/armazem_janela.py`
- `src/mvp_ed1/gcp/desmonte.py`
- `src/mvp_ed1/gcp/mutacoes_da_janela.yml`
- `src/mvp_ed1/gcp/mutacoes_janela.py`
- `src/mvp_ed1/gcp/origens.py`
- `src/mvp_ed1/gcp/quente.py`
- `src/mvp_ed1/gcp/residuos_esperados.yml`
- `src/mvp_ed1/generator/cli.py`
- `src/mvp_ed1/legacy/cli.py`
- `src/mvp_ed1/legacy/diario.py`
- `src/mvp_ed1/recovery/job_audit.py`
- `src/mvp_ed1/recovery/memory_oracle.py`
- `src/mvp_ed1/recovery/sources.py`
- `src/mvp_ed1/registros.py`
- `terraform/aplicacoes_gke.tf`
- `terraform/bigquery.tf`
- `terraform/cloud_sql.tf`
- `terraform/composer.tf`
- `terraform/gke.tf`
- `terraform/helm/airbyte_gke.yaml`
- `terraform/rede.tf`
- `terraform/variables.tf`
- `tests/test_armazem_janela.py`
- `tests/test_desmonte.py`
- `tests/test_janela_legado.py`
- `tests/test_job_audit.py`
- `tests/test_legado_remocao.py`
- `tests/test_memoria_bigquery.py`
- `tests/test_origens_gcp.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega:** não há gerado nesta entrega, mas há declaração revisável que governa
o resto e pede revisão integral:

- `src/mvp_ed1/gcp/desmonte.py` (`JANELA`, `PLANOS`) — que interruptores cada plano do desmonte
  leva, e a guarda `conferir_plano` que recusa plano que cria no desmonte ou apaga na construção;
- `src/mvp_ed1/gcp/residuos_esperados.yml` — o que o inventário de quinta aceita como padrão do
  projeto. Padrão largo demais aqui esconde recurso cobrável;
- `src/mvp_ed1/gcp/mutacoes_da_janela.yml` — as mutações da quarta no legado do Cloud SQL;
- `Makefile`, os macros `GCP_ENV`, `GCP_LIMPEZA`, `GCP_ORIGENS`, `GKE_KUBECTL`, `GKE_AIRBYTE`,
  `GCP_LIVRO`, `COMPOSER_G`, `COMPOSER_RODAR` — todo alvo `gcp-*` novo é composição deles;
- `PLANO_etapa_13.md` §6.5–§6.9 — os roteiros que o Owner executa literalmente.

O resto (`armazem_janela.py`, `quente.py`, `origens.py`, `job_audit.py`, `diario.py`,
`mutacoes_janela.py`, os ramos BigQuery do `memory_oracle.py`, os testes) é código comum.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
SKIPPED [1] tests/test_carga.py:52: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [4] tests/test_gcp_dialetos.py:94: só com GCP_TESTES=1 (BigQuery real)
SKIPPED [1] tests/test_governanca_bigquery.py:63: só com GCP_TESTES=1 (BigQuery real)
SKIPPED [1] tests/test_legado_remocao.py:563: sem mutações no diário: a prova entre capturas ainda não aconteceu
SKIPPED [1] tests/test_livro_gcs.py:170: só com GCP_TESTES=1 (Cloud Storage real)
SKIPPED [1] tests/test_memoria_bigquery.py:50: só com GCP_TESTES=1 (BigQuery real)
1205 passed, 18 skipped in 432.15s (0:07:12)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

Quase nada desta entrega rodou contra a infraestrutura em que vai rodar: o Cloud SQL, o GKE, o
Composer e o Dataflow **não existem** hoje no projeto `mvp-ed1-gcp` (só o degrau barato e o tópico).

- **Nenhum alvo que age na janela rodou:** `gcp-origens-*`, `gcp-airbyte-config`,
  `gcp-armazem-zerar`, `gcp-livro-epoca`, `gcp-sync-retail/-legacy`, `gcp-debezium-status`,
  `gcp-quente-*`, `gcp-memoria-oraculo`, `gcp-jobs-auditoria`, `gcp-composer-fluxo/-exportar`,
  `gcp-legado-mutar/-matriz`, `gcp-desmonte-parar/-slot/-kubernetes/-linhagem`, e as camadas 2 e 3
  (`gcp-desligar-faturamento`, `gcp-apagar-projeto`). Rodaram só para conferir a recusa limpa sem
  Cloud SQL/Composer/manifesto (registro §33, §35) — saída não colada aqui.
- **A guarda do `gcp-plan`** foi exercida com três planos reais só de leitura (0/1/0 aceito;
  `enable_cheap=false` recusado com 90 a destruir; `PASSO=2` recusado, criaria 24 contra o estado
  de hoje). Textos em `data/medicoes/etapa_13/g7/guarda/` (git-ignorado). Os planos 20–25 **reais**,
  contra a janela de pé, nunca existiram: a ordem do desmonte é prova só por teste unitário.
- **Inventário de quinta:** medido hoje sobre 870 recursos (713 resíduos com o barato de pé,
  `g7/inventario_padrao_20261108.json`). O que Composer, GKE, Cloud SQL e Dataflow criam por padrão
  e o que sobra depois do `destroy` deles **não é conhecido**; o `residuos_esperados.yml` só cobre
  os padrões de um projeto com Compute Engine ligado.
- **`REMOVE_PEERING`** e **`retain_backups_on_delete = false`**: lidos na documentação do provedor,
  não exercidos.
- **Os macros com processo em segundo plano** (proxy do Cloud SQL na 15432, *port-forward* do
  Airbyte na 18001): o `GCP_LIMPEZA` foi conferido por teste de texto do Makefile, não por
  execução com o processo de pé e uma falha no meio.
- **`memory_oracle` no BigQuery:** o teste real (`tests/test_memoria_bigquery.py`, `GCP_TESTES=1`)
  rodou por mim em 08/11 contra o BigQuery de desenvolvimento e passou; a saída não está colada aqui
  e o `make check` acima o pula — trate como relatado. A equivalência byte a byte do `to_json(struct)`
  com o *payload* do PostgreSQL não foi comparada sobre dado real das duas bases ao mesmo tempo.
- **`job_audit`:** só com dublê da listagem do Airbyte; paginação e estados reais da API do Airbyte
  1.x do GKE não exercidos.
- **`quente.latencia`:** só com relógio e cliente dublês. Não medi o desvio de relógio entre esta
  máquina e o BigQuery, nem o custo de consultar o destino a cada 5 s por até 15 min, nem se
  `_stream_from_snapshot` pode vir nulo no destino.
- **`armazem_janela.zerar`:** não rodou (apagaria o estado de desenvolvimento). `pronto` rodou só
  de leitura e recusou com 276 resíduos; `tamanho` rodou e deu `trusted` 110 MiB, `raw_legacy`
  82 MiB, `analytics` 45 MiB, `raw` 40 MiB (registro §36; saída não colada aqui).
- **`legacy/diario` no BigQuery:** só por BigQuery simulado (`test_janela_legado.py`); no
  PostgreSQL, os testes de integração da remoção (55) passaram pelo módulo novo, em bancos efêmeros.
- **`mutacoes_janela.aplicar`:** só com `mutacoes.*` dublês; falha no meio da lista não exercida.
- **Os roteiros:** nenhum foi ensaiado de ponta a ponta; o tempo de cada passo é estimativa, e o
  prazo de quinta (12:00 desligar faturamento, 18:00 nada cobrável) depende dele.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- O `gcloud` desta máquina tem `core/project = analisador-de-risco`; todo alvo `gcp-*` força o
  projeto por `CLOUDSDK_CORE_PROJECT` (via `GCP_ENV`). Assumo que nenhum comando `gcloud` dos alvos
  ignora essa variável.
- O Cloud SQL Auth Proxy fixado aceita a porta 15432 livre e a ADC do Owner; assumo que a ADC
  personificada (D81) basta para o proxy e para o `gcloud secrets versions access`.
- A API do Airbyte no GKE (porta 18001 por *port-forward*, credenciais do segredo
  `airbyte-auth-secrets`) é a mesma do `abctl` local, e o `mvp_ed1.airbyte sync` não muda.
- `gcloud composer environments run … dags trigger/state/tasks states-for-dag-run` existem com
  essa forma no Composer 3 / Airflow 2 da imagem fixada.
- `__TABLES__` continua legível com leitura no *dataset* (o `TABLE_STORAGE` deu 403 à ADC).
- O `recorded_at` dos movimentos é gravado pelo relógio desta máquina (produtor local contra o
  Cloud SQL pelo proxy) e o NTP desta máquina está certo.
- O Composer alcança o Cloud SQL pelo *peering* PSA — **hipótese aberta**, testada no *smoke*
  `rede` de quarta (passo do §6.9 que para para a decisão do Owner sobre PSC).

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

Esta revisão é estática sobre a janela: **nada no GCP** pode ser tocado (custo e rito do Owner).
O mínimo acima basta para `make check-offline` e `make secrets-history`. Os três bancos estão de
pé; Airflow de pé; Airbyte e *streaming* pausados — não precisa subir nenhum.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **A45, `apply` interativo** do `gcp-airbyte-config` contra o rito §6.3 (plano salvo revisado):
  um plano salvo levaria as senhas para arquivo. A alternativa seria plano salvo em pasta
  temporária, aplicado e apagado na mesma receita.
- **A46, zerar o armazém inteiro** antes da época, em vez de só a cópia do `gcp-carga-dev`.
- **A47, latência observada** com resolução de 5 s, em vez de uma coluna de gravação no destino
  (mudaria o contrato do destino da D75 às vésperas).
- **A40, apagar os processos da Data Lineage** no desmonte, exigindo antes a captura de tela.
- **A41, aceitar a VPC `default`** no inventário, com `default-allow-ssh/-rdp` abertas a
  `0.0.0.0/0` (sem VM nela); a alternativa é apagá-la.
- **A42, o produtor para no terminal do Owner** e não por alvo, pelo risco do `pgrep -f`.
- **`VARS` cumulativo** no `gcp-plan`: o Owner passa todos os interruptores de pé a cada degrau; a
  alternativa era um `PASSO` também para a construção.
- **`MVP_REGISTROS_DIR`** em vez de um `.env` da nuvem (A44).

---

## Rodada 1 — lote janela

**Changes required.** Há 12 achados de severidade alta (`bloqueante`) e 2 de severidade média
(`ajuste`). A execução literal encontra dependências fora de ordem e provas que falham mesmo no
ciclo previsto; também há verificações que podem anunciar sucesso após falha. O lote **não pode
ser fechado** nesta rodada. O resultado não é um parecer sobre a correção do projeto inteiro.

### Estado e recorte revisados

- Revisão independente em 08/11/2026, sobre `main`, HEAD
  `f1c1c2c103f7c154f9412b0a3628e31f6e2cacef`, base fixa `4e0dea2`.
- `git status --short` inicialmente vazio: nenhuma alteração local nem arquivo não rastreado.
  A única edição autorizada e realizada pela revisão é esta seção de `REVISAO.md`.
- `git rev-list --count 4e0dea2..f1c1c2c` retornou **22**, não os 24 mencionados no pedido.
  Foram mantidos os extremos explícitos: 21 commits de implementação/documentação e o dossiê.
  O diff abrange 33 arquivos. Nenhuma base alternativa foi adotada.
- Lidos primeiro o dossiê §§1–7, AGENTS.md, CLAUDE.md e a skill local
  `.claude/skills/revisao/SKILL.md`; depois os roteiros, requisitos e registro §§30–36.
  A39–A48 foram tratados como propostas; a confirmação de A43 não foi estendida às demais.
- Percurso confrontado: §6.6 → §6.7 → §6.8 → §6.9 → §6.5. Todos os nomes de alvos desse
  percurso existem. Foram rastreadas as dependências anteriores necessárias, incluindo os
  contratos dos ADRs 0044, 0045, 0050 e 0051; isso não amplia a revisão para todos os commits
  anteriores. Cada achado abaixo informa sua origem.

### Achados por severidade

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV13J-1-01 | `Makefile:1002`; `terraform/aplicacoes_gke.tf:17` | O plano salvo da raiz contém segredo, inclusive token da ADC | bloqueante | **Corrigido em parte e levado ao Owner.** `gcp-plan` grava com `umask 077` e `gcp-apply` apaga o binário depois do `apply` que o consumiu (o texto fica); §6.3 diz por quê. A forma final (essa, ou `exec` no Kubernetes/Helm e senhas só de escrita) é pergunta ao Owner no Registro §37, com a recomendação. Os 7 `.tfplan` já aplicados ficam até o Owner decidir apagá-los; o *token* do `09_politicas` venceu. |
| RV13J-1-02 | `PLANO_etapa_13.md:810` | O build de terça precede a criação e a carga de sua fonte quente | bloqueante | **Corrigido.** §6.8 reordenada: passos 3–9 (prova, tabela, plano, lançamento, *snapshot* conferido por conteúdo, parada) antes das capturas (10–13) e do `build` (15); movimentos novos só depois da paridade (21–28). Percurso conferido à mão desde os datasets vazios: a tabela quente nasce no passo 4, o IAM no 5, o *snapshot* no 8, o *build* no 15. |
| RV13J-1-03 | `Makefile:1389`; `recovery/memory_oracle.py:370` | O T3 não aceita o ciclo inicial e os tratamentos previstos pelos roteiros | bloqueante | **Corrigido.** `memory_oracle`: linha de base **sem captura** vale como memória vazia (`_base_vazia`; com captura, `None` continua "não se sabe"); `--diary` deriva remoções e reaparições aceitas do efeito líquido do diário (`accepted_from_diary`); `make gcp-livro-tratamento` nos roteiros (§6.8 passo 16, §6.9 passo 10); `gcp-memoria-oraculo` passa o diário. Contraprova: 3 dos testes novos falham no código anterior (`git stash` do módulo: 3 failed, 2 passed); o da memória ainda sem tabela passa nos dois — guarda a regressão que `test_recuperacao_adversaria` pegou na primeira versão da correção; 117 de integração (`test_oraculo_da_memoria`, `test_recuperacao_adversaria`, `test_legado_remocao`) passam. |
| RV13J-1-04 | `gcp/mutacoes_janela.py:39`; `PLANO_etapa_13.md:994` | Uma execução parcial é reconhecida como se todas as mutações tivessem ocorrido | bloqueante | **Corrigido.** `mutacoes_janela.aplicar` lê o diário como prefixo da declaração: completo não aplica nada, parcial retoma da seguinte, outra coisa recusa; antes de cada mutação o *hash* do banco tem de ser o do diário (ou o `lote.tabelas`). `ValueError` vira `Recusa` legível. Contraprova: 11 de 14 testes falham no código anterior (falha após cada uma das 4, mudança fora do diário, prefixo errado). **Achado ao corrigir:** `remover brands quantidade 2` cairia — a geração declarada tem 1 marca apta; declaração corrigida para 1, com teste contra as aptas do manifesto (Registro §37). |
| RV13J-1-05 | `gcp/quente.py:121` | A latência pode passar com o produtor falhando e zero eventos observados | bloqueante | **Corrigido.** `latencia` recebe o código de saída do produtor (`poll`), exige saída 0, ao menos `--limite` eventos na origem e todos vistos; o relatório leva `motivo`, e o CLI imprime `INCOMPLETO`. Subprocesso esperado (`wait`, `kill` no limite). Contraprova: os 5 casos do parametrizado (erro antes, erro depois de rajada, zero, parcial, prazo) falham no código anterior. |
| RV13J-1-06 | `gcp/politicas.py:178`; `Makefile:1361` | O inventário de tags aprova tabelas ausentes | bloqueante | **Corrigido.** `politicas.main` sai com 1 e imprime `AUSENTE — …` para toda tabela declarada ausente, nos dois comandos; o alvo diz `0 divergências, nenhuma tabela ausente` só com rc 0. Contraprova: 4 casos falham no código anterior. |
| RV13J-1-07 | `Makefile:1277`; `Makefile:1416` | Falha de consulta é convertida em ausência de trabalho no desmonte | bloqueante | **Corrigido.** `gcp-dataflow-parar`: `vazio()` sai com erro quando a listagem falha, em toda consulta (antes, durante e depois de *drain* e *cancel*). `gcp-desmonte-parar`: a resposta do `list-runs` é capturada com o retorno conferido e lida pelo `composer_cli execucoes`, que recusa vazio e não-JSON. Sondas em *shell* isolado: listagem com rc 7 → `ERRO`, rc 1; vazia → `nenhum job ativo`. Testes de texto da receita e de unidade do leitor. |
| RV13J-1-08 | `Makefile:1094` | O retorno do catálogo encobre falha dos oráculos de paridade | bloqueante | **Corrigido.** `gcp-oraculos` roda as quatro comparações, cada uma com `\|\| { echo …; rc=1; }`, e sai com `rc`. Teste da receita. |
| RV13J-1-09 | `Makefile:1092`; `gcp/oraculo.py:125` | A comparação usa identidades de execução distintas e não prova o conteúdo de consumo | bloqueante | **Corrigido em parte e levado ao Owner.** Novo `oraculo consumo`: o conteúdo de cada *view* de `consumption` (multiconjunto normalizado; colunas de execução `_*` excluídas e declaradas), no `gcp-oraculos`. Medido só leitura sobre o estado de desenvolvimento: 13 de 16 iguais (Registro §37). O pareamento por `snapshot_id` da classificação e das contagens entre ambientes é decisão do Owner (Registro §37, com recomendação); os roteiros dizem que essas duas não provam paridade até lá e declaram as diferenças esperadas da quarta. |
| RV13J-1-10 | `PLANO_etapa_13.md:749` | O roteiro não executa as provas de G2.3 exigidas para P3 | bloqueante | **Corrigido.** `make gcp-quente-prova` (os testes reais de `test_caminho_quente_nuvem.py`, recusando pulado, e o `gcp.prova_quente`); `quente conferir` compara chave e as 16 colunas de negócio; `make gcp-debezium-reiniciar`; §6.8 mapeia cada prova da §G2.3 a um passo (tabela no início) e diz que sem os passos 3 e 8 o G2.3 não passa. Reinício do *worker* = parar, produzir com ele parado, relançar, conferir. O alerta no caminho do GKE fica declarado como observado, não forçado; o provado é o do passo 3. |
| RV13J-1-11 | `Makefile:1312`; `PLANO_etapa_13.md:476` | A45 operacionaliza uma exceção ainda não aprovada ao rito de apply | bloqueante | **Corrigido; o Owner confirma.** `gcp-airbyte-config` volta ao rito: `plan -out` na pasta temporária, texto em `data/medicoes/etapa_13/planos/`, o Owner lê e digita o id do projeto, `apply` do arquivo. A A45 deixa de valer (Registro §37). A pergunta ao Owner é só se o plano fora de `data/` cumpre a §6.3. |
| RV13J-1-12 | `Makefile:1221` | Falha ao guardar os tempos das tarefas termina como sucesso | bloqueante | **Corrigido.** `COMPOSER_TAREFAS` com `pipefail` e o `composer_cli tarefas --terminada`, que recusa vazio, não-JSON e tarefa sem `start_date`/`end_date` e só então grava; DAG verde sem os tempos sai com 1 e manda `make gcp-composer-tarefas DAG= RUN=`. Testes de unidade do leitor e da receita. |
| RV13J-1-13 | `Makefile:1037`; `Makefile:1148` | A limpeza mata o shell da função, deixando o port-forward filho vivo | ajuste | **Corrigido.** O *port-forward* é lançado direto (`$$KUBECTL … &`), e o `$!` é o do `kubectl` (sonda: o PID era o do processo, morto e esperado); `GCP_PORTA_LIVRE` antes do proxy e do *port-forward*; o laço confere `kill -0`; `GCP_LIMPEZA` faz `wait`. O *token* da ADC saiu da linha de comando: `kubeconfig` com `umask 077` na pasta temporária. |
| RV13J-1-14 | `PLANO_etapa_13.md` §§6.7–6.9 | Diversos passos não especificam saída esperada e conduta na falha | ajuste | **Corrigido.** Regra de falha comum na §6.6 (cinco regras: leitura repetível que corta dependentes, `plan`, `apply` sem repetir, escrita que recusa repetir, relógio). Esperado e conduta nos passos citados: §6.7 3/5/6, §6.8 4/5/8/9/10/14–29, §6.9 3/5/8/9/12–17; o "anote e siga" do PASS separa `FAIL` (achado, segue) de `ERROR` (corta 16–20). |

Os caminhos abreviados `gcp/` e `recovery/` na tabela ficam sob `src/mvp_ed1/`.
Não há achados de severidade baixa nesta rodada.

### Evidências e correções necessárias

**RV13J-1-01 — Segredos no plano salvo. Alta; bloqueante.**

Onde: `Makefile:1002`, `terraform/aplicacoes_gke.tf:17` e `terraform/cloud_sql.tf:91`.
`gcp-plan` salva o plano completo; a raiz consulta `data.google_client_config.atual` e usa seu
`access_token` no provider Helm. Depois da criação do Cloud SQL, o estado anterior também contém
as senhas usadas por `google_sql_user`, Secret Manager e `set_sensitive`. Marcar como sensível
oculta a apresentação, mas não retira o material do plano binário.

Evidência **executada, somente leitura**: inspeção com `zipfile`/`json` dos sete `.tfplan`
existentes em `data/medicoes/etapa_13/planos/`, sem imprimir valores. Resultado relevante:
`09_politicas.tfplan tfstate: access_token presente`. Os outros seis não tinham esse atributo nos
membros inspecionados. Não foi criado plano novo nem acessada a ADC. Isso comprova o mecanismo
local; não é uma alegação de senha encontrada no Git. O `.gitignore` protege o versionamento,
mas o requisito desta revisão também proíbe segredo **no arquivo de plano**.

Correção: apresentar ao Owner uma forma de conciliar o rito com esse requisito para **a raiz
inteira**, não apenas `airbyte/`; não tratar plano ignorado pelo Git como plano sem segredo.
Validar offline o conteúdo de planos representativos com credenciais fictícias, inclusive o
estado anterior embutido, sem revelar material real. **Preexistente**, exposto pelo percurso
novo; a justificativa de A45 reconhece o risco apenas para a outra raiz.

**RV13J-1-02 — Fonte quente fora de ordem. Alta; bloqueante.**

Onde: `PLANO_etapa_13.md:720`, `PLANO_etapa_13.md:810`,
`src/mvp_ed1/gcp/armazem_janela.py:45`, `dbt/models/staging/stg_retail__inventory_movements.sql:40`
e `dbt/tests/caminhos_de_ingestao_reconciliam.sql:26`.
O zerar remove também `raw.inventory_movements_stream`. A sincronização retail não a recria:
ela vem do caminho quente. O passo 7 da §6.8 executa o build completo, mas a criação da tabela
só aparece no passo 13, e a carga pelo Dataflow nos passos 16–17. O staging e a view
`consumption.skus_below_reorder_point` dependem dessa tabela. Mesmo antecipar apenas o DDL
deixaria os movimentos históricos exclusivamente no batch, reprovando a reconciliação.

Evidência **estática**: cadeia acima; `governance.garantir_bigquery` só cria a governança.
Correção: ordenar criação, IAM, lançamento e alcance do snapshot antes dos consumidores e das
provas que exigem os dois caminhos; fazer a convergência das fontes após sua existência.
Validar um percurso iniciado com os nove datasets vazios: nenhum consumidor precede sua fonte e
o build completo passa sobre os dois caminhos preenchidos. **Regressão do lote**, pela nova
combinação zerar → roteiro de build.

**RV13J-1-03 — Contrato do T3 incompleto para a janela. Alta; bloqueante.**

Onde: `src/mvp_ed1/recovery/ledger.py:389`, `src/mvp_ed1/recovery/leitura.py:277`,
`src/mvp_ed1/recovery/memory_oracle.py:370`, `src/mvp_ed1/recovery/memory_oracle.py:546`,
`Makefile:1389` e §§6.8 passos 7/10, 6.9 passos 9/12.
A época inicial é tirada antes de existir `trusted.legacy_removed_records`: grava `deletions=None`
e `deletion_keys=None`. Depois do primeiro build há uma memória materializada, mesmo vazia.
Sem mudanças aceitas, `_deletion_problems` exige igualdade com `None` e reprova esse nascimento
legítimo. Na quarta há mais duas incompatibilidades: as exclusões declaradas não entram como
remoções aceitas no alvo T3; e o tratamento da terça nunca é registrado como `TREATMENT` antes
de a classificação corrente mudar. A quarentena retém a fatia da terça, mas o T3 não encontra
nem linha de base nem tratamento que a explique. O registro da captura precede o build e não
substitui o registro do tratamento.

Evidência **executada com objetos em memória**: base `deletions=None` contra memória vazia
produziu `a memória de exclusões mudou desde a linha de base`; uma fatia anterior sem tratamento
produziu `quarentena: fatia fatia_antiga que nem a linha de base nem um tratamento explica`.
Evidência **estática**: o alvo só passa `--out`; não há registro de tratamento no percurso.
Os testes locais existentes registram tratamentos explicitamente; o teste BigQuery novo só
exercita `_presenca` e `_payload`, não este ciclo.

Correção: integrar a inicialização vazia, o registro dos tratamentos e o esperado das mutações
ao contrato já exigido pelo T3, sem desligar suas verificações nem reescrever o livro.
Validar vazio → primeira captura/build → tratamento registrado → mutações → segunda captura/build,
com contraprovas de perda e adulteração das capturas e da quarentena anteriores.
**Regressão de integração do lote** com um contrato preexistente do oráculo.

**RV13J-1-04 — Retomada de mutações parciais. Alta; bloqueante.**

Onde: `src/mvp_ed1/gcp/mutacoes_janela.py:39`, `src/mvp_ed1/legacy/mutacoes.py:137` e
`PLANO_etapa_13.md:994`. Cada operação confirma e grava seu diário separadamente. Se a segunda
ou terceira falhar, as anteriores permanecem aplicadas. Na repetição, qualquer entrada faz o
alvo dizer que as mutações da janela já foram aplicadas; o roteiro manda seguir nessa recusa.
A matriz então cobra apenas o diário parcial e pode deixar de exercitar inserção/alteração.

Evidência **executada com mutações e manifesto simulados em memória**: primeira execução falhou
na segunda operação, com uma entrada persistida; segunda execução respondeu
`já tem 1 mutações: as da janela já foram aplicadas`. Nenhum arquivo de manifesto foi escrito.
O teste atual só cobre diário previamente preenchido e o caminho feliz.

Correção: distinguir lote completo de parcial e oferecer retomada verificável ou recusa que
mande parar, sem repetir remoções já confirmadas. Validar falha após cada operação, incluindo
falha de gravação do diário após commit; só o conjunto completo pode autorizar o passo seguinte.
**Regressão do lote.**

**RV13J-1-05 — Latência aprovada sem produção válida. Alta; bloqueante.**

Onde: `src/mvp_ed1/gcp/quente.py:121` e `src/mvp_ed1/gcp/quente.py:178`.
O encerramento do produtor é interpretado apenas como `poll() is not None`; seu código de saída
nunca é conferido. Se ele falha antes de gravar, `esperados()` devolve zero e `vistos >= total`
aprova. Se falha após uma rajada, a amostra parcial também pode ser declarada completa. O alvo
promete emitir 200/500 movimentos e medir percentis, mas retorna sucesso sem cumprir isso.

Evidência **executada sem produtor nem banco**: consulta vazia, produtor encerrado e esperado
zero retornaram `{'esperados': 0, 'vistos': 0, 'completo': True, 'eventos': 0}`.
Correção: conferir o desfecho do produtor e a produção efetiva contra a amostra pedida, rejeitar
amostra vazia/incompleta e esperar o subprocesso na limpeza. Validar erro antes da primeira
rajada, erro após uma rajada, sucesso e timeout. **Regressão do lote.**

**RV13J-1-06 — Tabela ausente passa no inventário de tags. Alta; bloqueante.**

Onde: `src/mvp_ed1/gcp/politicas.py:143`, `src/mvp_ed1/gcp/politicas.py:178` e `Makefile:1361`.
`NotFound` entra em `rel.ausentes`, mas o retorno só considera `divergentes` e
`sem_classificacao`. O alvo traduz o zero em `0 divergências`. A convergência também imprime
`fontes convergidas` apesar de fonte ausente. O caso ocorre no próprio percurso atual, depois
de zerar a fonte quente, e pode ocorrer após perda de outra tabela sensível.

Evidência **executada com cliente BigQuery simulado**, chamando `politicas.main`: a única tabela
declarada estava ausente; relatório `tabelas: 0`, `ausentes: [raw.t]`, **rc=0**.
Correção: ausência de relação obrigatória deve impedir o sucesso, preservando o diagnóstico no
relatório e no terminal. Validar todos os objetos ausentes, um ausente entre presentes e schema
com tag divergente. **Preexistente no módulo**, acionado pelos novos alvos e roteiros.

**RV13J-1-07 — Desmonte não distingue consulta falha de lista vazia. Alta; bloqueante.**

Onde: `Makefile:1277`, `Makefile:1280` e `Makefile:1416`.
Após pedir drain/cancel, `test -z "$(ativos)"` aprova stdout vazio mesmo quando a listagem falha.
No Composer, o pipeline não usa `pipefail`; o Python recebe vazio, imprime zero e encobre o
erro de `g dags list-runs`. Assim o passo 1 pode autorizar a remoção de IAM/ambiente com job ou
DAG ainda em execução. As verificações iniciais de Dataflow e os `pause ... || exit 1` são
corretos, mas não protegem as consultas posteriores.

Evidência **executada em expressões Bash isoladas**, sem executar receita nem CLI de nuvem:
função de listagem com rc=7 foi aceita como nenhum job ativo; pipeline com produtor rc=7
resultou em `n=0` e status zero.
Correção: capturar e verificar o retorno de cada consulta antes de interpretar o conteúdo;
resposta ausente/inválida não é prova de ausência. Validar falhas durante polling, após drain,
após cancel e ao consultar running/queued do Composer. **Dataflow preexistente; ramo Composer
introduzido no lote.** Não se afirmou que um recurso realmente ficou cobrável: foi demonstrado
que a prova pode ser falsa, comprometendo a camada 1 do desmonte.

**RV13J-1-08 — Falha da paridade encoberta. Alta; bloqueante.**

Onde: `Makefile:1091`. O encadeamento é `classificação && contagens; catálogo`.
Se a classificação falhar, as contagens nem rodam; se as contagens falharem, o catálogo roda
mesmo assim. Com catálogo bem-sucedido, `make gcp-oraculos` termina com zero em ambos os casos.

Evidência **estática e executada no equivalente booleano Bash**: `false && true; true`
retornou zero. Nenhum oráculo real nem catálogo foi executado.
Correção: propagar todas as falhas e identificar qual comparação não foi executada. Validar
falha independente de cada uma das três etapas. **Preexistente**, agora usado como prova nos
dois novos roteiros.

**RV13J-1-09 — Paridade entre execuções independentes. Alta; bloqueante.**

Onde: `Makefile:1092`, `src/mvp_ed1/gcp/oraculo.py:75`,
`src/mvp_ed1/gcp/oraculo.py:125` e `PLANO_etapa_13.md:1108`.
A chave comparada contém `snapshot_id`, que é o job do Airbyte de cada ambiente (ADR-0044).
O GKE novo começa sua própria sequência; não há passo que a iguale à da fase local. As
contagens também comparam todo o histórico bruto e o certificado local com as três/quatro
tentativas novas da nuvem. Mesma geração não significa mesmo histórico de execução. Na quarta,
as mutações só na nuvem e os movimentos ao vivo também tornam a comparação indiscriminada
inadequada. Além disso, `contagens` só faz `count(*)`: duas views de consumo com as mesmas
quantidades e valores diferentes passam, contrariando a soma de controle normalizada da §7.2.
O catálogo não verifica esses valores.

Evidência **executada com `_linhas` e dados fictícios**: payload igual, `snapshot_id` local 12
e nuvem 3 produziram uma chave só local e uma só nuvem. Evidência **estática**: nenhuma consulta
de conteúdo das views nem exclusão/mapeamento dos metadados de execução no percurso.
Correção: definir o pareamento de cortes comparáveis, o recorte dos históricos e a normalização
dos campos de execução; comparar conteúdo de cada view exigida. As diferenças intencionais da
quarta precisam de esperado próprio. Validar equivalência com jobs diferentes e reprovar valor
adulterado mantendo `count(*)`. **Preexistente nos comparadores; lacuna de integração dos novos
roteiros.**

**RV13J-1-10 — P3 não demonstrada pelo ensaio proposto. Alta; bloqueante.**

Onde: `PLANO_etapa_13.md:295`, `PLANO_etapa_13.md:469`, §6.8 passos 12–18,
`Makefile:1078` e `src/mvp_ed1/gcp/quente.py:65`.
G2.3 exige antes da janela: decimal/fuso exatos, reinício do pod e worker, reenvios dentro/fora
da deduplicação e após retorno perdido, lotes concorrentes da mesma chave, unicidade, saldo e
alerta. O roteiro que diz cobrir P3 só inspeciona pod/slot, lança o job e compara contagem/máximo,
depois mede latência. Contagem/máximo iguais não comparam chaves nem payloads; o caminho pode
perder um movimento e conter outro indevido sem alterar esses agregados. Não há passos para
as demais provas. `gcp-g21-prova` cobre três arquivos de G2.1 e não executa os testes do caminho
quente. Os testes reais de `test_caminho_quente_nuvem.py` ficaram pulados no check desta revisão.

Evidência **estática**, não inferência de falha real do Dataflow. Correção: acrescentar os
comandos, esperados e contraprovas que fecham G2.3, ou marcar explicitamente P3/G2.3 como não
atendida e cortar suas dependências conforme §6.2. Validar que nenhuma declaração de aprovação
de P3 decorre apenas de contagens e latência. **Lacuna introduzida pelo roteiro do lote.**

**RV13J-1-11 — Exceção A45 sem aprovação ao rito. Alta; bloqueante.**

Onde: `PLANO_etapa_13.md:476`, `PLANO_etapa_13.md:714`, `Makefile:1312` e Registro §32/A45.
O rito proíbe apply sem plano salvo. O novo alvo faz `TF_WORKSPACE=gcp ... apply -parallelism=1`
interativo, e o roteiro manda digitar `yes`. A justificativa de não salvar segredos é pertinente,
mas A45 é proposta do autor, não a aprovação do Owner que a substituiria. A confirmação de A43
trata da data da época e não resolve esta exceção.

Evidência **estática e documental**. Correção: submeter uma solução concreta ao Owner e registrar
o rito que ele aceitar, conciliado com RV13J-1-01; até lá, o passo não pode ser apresentado como
conforme à §6.3. Validar a correspondência entre decisão, roteiro e receita, sem apply durante
a revisão. **Regressão do lote.**

**RV13J-1-12 — Sucesso sem evidência dos tempos. Alta; bloqueante.**

Onde: `Makefile:1221` e `PLANO_etapa_13.md:1009`.
Depois de observar sucesso da DAG, `COMPOSER_RODAR` tenta exportar `tasks states-for-dag-run`,
mas ignora seu retorno e oculta stderr. Uma falha de permissão/transporte/comando deixa arquivo
vazio ou inválido e o alvo anuncia sucesso com o caminho das tarefas. A evidência dos tempos de
sincronização e dbt da §7.2 não foi produzida.

Evidência **estática**: o `case` depende apenas do estado anterior. Não há defeito demonstrado
no formato escolhido: o [código do Airflow 3.2.2](https://github.com/apache/airflow/blob/3.2.2/airflow-core/src/airflow/cli/commands/task_command.py)
inclui `start_date`/`end_date`, dos quais se pode derivar duração. A
[CLI do Composer](https://docs.cloud.google.com/sdk/gcloud/reference/composer/environments/run)
propaga o retorno do subcomando; é a receita que o descarta.
Correção: conferir coleta e conteúdo antes de declarar a evidência disponível, distinguindo
sucesso da DAG de falha da medição. Validar coleta com rc diferente de zero, JSON inválido e
tarefas sem tempos finais. **Regressão do lote.**

**RV13J-1-13 — PID errado na limpeza do port-forward. Média; ajuste.**

Onde: `Makefile:1037`, `Makefile:1142` e `Makefile:1148`.
`k` é uma função Bash que executa `kubectl`; em `k ... &`, `$!` identifica o shell da função.
O trap mata esse shell, sem assegurar o encerramento do `kubectl` filho e sem `wait`. A porta
18001 pode continuar ocupada após o alvo; o próximo alvo aceita qualquer listener TCP na porta,
mesmo se seu próprio port-forward não abriu. O proxy externo direto não tem esse mesmo problema
de wrapper, embora também falte esperar seu término na limpeza.

Evidência **executada com processo inofensivo de 2 s**, sem kubectl: `k() { sleep 2; }; k &`
seguido da morte/espera de `$!` deixou o filho vivo. O filho da sonda foi encerrado pela revisão.
Correção: possuir o PID efetivo ou grupo exclusivo do processo iniciado, encerrá-lo e esperar;
conferir a identidade/vida do encaminhamento antes de reutilizar a porta. Validar saídas normal,
com erro e Ctrl-C, com porta livre ao terminar. **Regressão do lote.**

**RV13J-1-14 — Passos sem contrato operacional completo. Média; ajuste.**

Onde: §6.7 passos 3/5; §6.8 passos 13/19; §6.9 passos 5/11/12/14/15.
Por exemplo, o passo 13 da terça só nomeia `gcp-dataflow-tabela`, sem saída esperada ou ação na
falha; o passo 12 da quarta só contém o comando T3; a exportação de logs não diz o que fazer se
falhar antes de destruir o bucket. Há também instrução de anotar e seguir após número de PASS
diferente, sem separar mera diferença de contagem de erro de build que invalida dependências.
Isso não atende ao requisito de executar cada passo literalmente com pré-condição, esperado e
conduta segura na falha. Não se está exigindo repetir as mesmas instruções em cada parágrafo.

Evidência **documental**. Correção: completar os contratos, podendo referenciar uma regra comum
de falha e as portas §6.2/relógio §6.4; explicitar quais falhas cortam dependências, quais são
repetíveis e como preservar evidência antes de destruir. Validar a leitura passo a passo sem
decisões operacionais implícitas. **Regressão do lote.**

### Achados anteriores

Nenhum: esta é a primeira revisão de implementação do lote janela. Os achados de revisão do
plano citados no dossiê não foram considerados revisões anteriores desta implementação.

### Verificações executadas e resultados

Executados nesta revisão, sem ler o conteúdo de `.env`, acessar banco ou chamar serviços:

```text
make check-offline — exit 0
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 121 documentos, 1192 links de arquivo, 235 âncoras, 726 citações de ADR — nada quebrado
1020 passed, 15 skipped, 188 deselected in 217.89s (0:03:37)
check-offline: as três etapas passaram

make secrets-history — exit 0
revisão do histórico: nada não tratado (14 achado(s), todos registrados; 1 blob(s) pulado(s))
```

Os 15 pulados dependem de `GCP_TESTES=1`: 4 de armazém, 4 de caminho quente, 4 de dialetos,
1 de governança, 1 de livro GCS e 1 de memória BigQuery. Os 188 excluídos levam `integracao`;
o alvo os inventariou em 19 arquivos. O blob pulado pelo scanner é uma captura JPG, por extensão
binária. Esses resultados foram obtidos antes da inclusão desta seção; a revisão do diff final
confere que apenas `REVISAO.md` foi editado.

Também executadas: sondas puras/in-memory descritas nos achados 03–09, 13; leitura dos membros
de planos já existentes no achado 01; inspeção de status/log/diff e contratos. Não foram escritos
testes, fixtures ou manifestos. Nenhuma receita de nuvem foi executada, nem mesmo com `make -n`.

O `make check` com 1205 testes aprovados em b9e9c04 e a execução real de
`test_memoria_bigquery.py` são **relatos do autor**, não medições desta revisão. Não foram
repetidos: envolvem bancos/serviços ou escrita no projeto GCP, fora da autorização.

Sobre a suficiência dos testes novos: `test_desmonte` prova as flags cumulativas, contagem de
ações e classificação de resíduos, mas boa parte da integração com receitas é verificação de
texto; ela não detectou os retornos ignorados. `test_origens_gcp` também mistura testes puros
úteis com asserts de texto, sem testar os processos reais do trap. `test_armazem_janela` usa
cliente em memória; `test_janela_legado` não provoca falha entre mutações; `test_job_audit` cobre
os cruzamentos puros, não a API. O teste real de memória usa uma tabela `brands` toda STRING e
exercita duas consultas BigQuery: não compara os dois bancos nem executa `read_memory/check`
com a época nova. O reaproveitamento de `diario` pelos testes PostgreSQL mantém contraprovas
do consumidor; isso não prova a integração completa da janela.

### Limites, hipóteses resolvidas e questões abertas

- **Desmonte/custo:** `JANELA` cobre os seis `enable_*`; os planos 20–25 desligam cumulativamente
  os degraus e removem a retenção do livro antes dos buckets. Não foi encontrada regra do
  `residuos_esperados.yml` que aceite diretamente disco, VM, load balancer, dataset, bucket,
  backup ou job. Há `delete_contents_on_destroy`, `force_destroy` e proteção de exclusão
  desligada nos recursos inspecionados. Isso é análise estática, não prova de ausência de custo.
  Defaults reais de Composer/GKE/Cloud SQL, backups, peering, PVs, resíduos de linhagem e duração
  dos destroys permanecem **não medidos** nesta revisão. O inventário de recursos pode atrasar;
  não substitui as provas específicas nem o desligamento do faturamento. O orçamento é externo
  ao projeto e tem sua exclusão e conferência próprias.
- O cronograma reserva quinta 07:00–11:00 para a camada 1 e fixa as camadas 2/3 às 12:00/15:00,
  independentemente do progresso. Ele contempla escalada pela consola. Não há medição que
  permita certificar duração ou ausência de cobrança às 18:00. RV13J-1-07 precisa ser corrigido
  antes de usar os retornos da camada 1 como prova. Desligamento e exclusão não foram ensaiados.
- A guarda de planos rejeita criações no desmonte e destruições na construção, incluindo
  substituições; `DESTROI=n` é a exceção explícita do Owner. Não foi demonstrado bypass dessa
  guarda nos comandos normais escritos. Uma janela com blocos cortados pode fazer os planos
  baseados em `JANELA` recusarem criação de degrau ausente; não se deve contornar a recusa para
  cumprir o relógio. A alternativa segura prevista é a escalada independente da §6.4.
- **Segredos/processos:** as senhas das origens e credenciais Airbyte são capturadas em ambiente,
  sem `echo` ou `set -x` encontrados nesse percurso. Isso não exonera os planos (01). A função
  `k` preexistente passa token em argv (`--token`), visível a processos com permissão de
  inspeção; não foi usado `ps` sobre credenciais reais. A avaliação de exposição nessa máquina
  não foi medida. Não há `pgrep -f` nos novos alvos; a escolha de não parar produtor de outro
  terminal está explícita em A42. A limpeza de processos próprios tem o defeito 13.
- **Registros/armazém:** as cargas, o manifesto/diário do legado e a leitura do oráculo de
  origens usam a nova raiz; livro usa `livro_raiz`. Não se encontrou sobrescrita do manifesto
  local nesses caminhos. O produtor continua usando `.stream/producer_state.json` comum aos
  ambientes; o isolamento desse cursor não foi ensaiado. `zerar` mantém datasets e suas
  concessões, mas remove os objetos e metadados de tabela; tags e autorizações de views
  dependem da reconstrução posterior, e o IAM de tabela do Dataflow é aplicado depois no
  percurso previsto. `pronto` intencionalmente aceita tabela vazia; sob a sequência escrita não
  há escritor de streaming BigQuery antes da época. Metadados durante ingestão concorrente e
  tabelas externas não foram exercidos. Não há tabela externa declarada nesse percurso.
- **Dialetos/T3:** o legado declara colunas de negócio como texto, o que reduz a hipótese de
  divergência de serialização numérica/data no payload bruto. Os arrays de ids não vazios usam
  INT64 e os valores de chaves usam STRING no adaptador. Os objetos lidos pelo T3/matriz no
  percurso são materializados como tabelas; a suspeita de time travel sobre a view selecionada
  não se confirmou. A equivalência de payload real PostgreSQL/Airbyte/BigQuery e o ciclo T3
  inteiro continuam sem medição desta revisão; o defeito de integração 03 independe disso.
- **Jobs:** `audit` consome os iteráveis, aceita o mesmo job nos registros attempt/transition
  da mesma tentativa e distingue duas tentativas que o citem. O chamador recusa listagem com
  1000 itens, mas não percorre paginação nem confere metadados de próxima página. Sem observar
  a resposta da versão instalada, não se comprovou truncamento com página menor, omissão de
  estado ou falso POST por retry interno do mesmo job. São limites da validação da API, não
  defeitos afirmados. A39–A48 continuam sujeitos à revisão declarativa do Owner.
- **Latência/tamanho:** `_stream_from_snapshot` é NOT NULL no DDL do destino e a escrita sempre
  fornece bool; a hipótese de NULL no fluxo construído não se confirmou. `recorded_at` vem do
  relógio local do produtor; NTP, desvio para o servidor e custo das consultas repetidas não
  foram medidos. `_percentil` usa a posição arredondada em `p*(n-1)`; não há estimador diferente
  exigido no plano. `__TABLES__` mede o estado lógico, com views a zero, não custo físico nem
  armazenamento cobrado. O achado 05 trata da validade da amostra, não de latência real medida.
- **Cobertura de aceite:** nenhuma sonda desta revisão prova acesso negado por identidade,
  acesso só ao segredo destinado, catálogo visível/linhagem por coluna, cobertura real dos dados
  ou execução simultânea no GCP. Esses itens da §7 permanecem não medidos; não se convertem em
  aprovação por haver testes offline verdes. A suficiência das provas G2.3 tem o achado 10.
- Rede: foram feitas **8 tentativas de leitura de páginas oficiais**, sem outras chamadas de
  rede. Três forneceram conteúdo (GoogleSQL, CLI do Composer e fonte Airflow 3.2.2); cinco
  tentativas sobre documentação das versões Terraform/provider não retornaram conteúdo útil.
  Nenhum achado depende de supor o conteúdo dessas cinco. O achado 01 usa evidência local.

### Passagem para Claude Code

Correções exigidas, sem autorização de apply, alteração de dados, commit ou encerramento formal
decorrente deste parecer. Os critérios abaixo são o que a próxima rodada deve confrontar:

- [ ] **RV13J-1-01:** solução revisável para planos sem segredos nas duas raízes, incluindo estado
  embutido; verificação com material fictício que falhe se token/senha aparecer no artefato.
- [ ] **RV13J-1-02:** percurso de terça ordenado desde datasets vazios; tabela quente criada,
  permissões aplicadas e snapshot alcançado antes do build/reconciliação.
- [ ] **RV13J-1-03:** ciclo T3 vazio → primeiro tratamento → tratamento seguinte com mutações passa;
  tratamento anterior registrado e alterações aceitas derivadas de esperado independente;
  perdas/adulterações continuam reprovando.
- [ ] **RV13J-1-04:** falha em qualquer operação deixa estado parcial reconhecível e recuperável;
  somente as quatro operações completas autorizam seguir, sem repetir remoções.
- [ ] **RV13J-1-05:** produtor com saída de erro, amostra zero ou incompleta nunca aprova latência;
  subprocesso recolhido em sucesso, erro e timeout.
- [ ] **RV13J-1-06:** qualquer relação obrigatória ausente reprova inventário/convergência e
  aparece no diagnóstico; não imprimir `0 divergências` nesse caso.
- [ ] **RV13J-1-07:** falha de listagem nunca vira zero trabalhos; contraprovas para todas as
  consultas de drain/cancel e running/queued.
- [ ] **RV13J-1-08:** cada falha de classificação, contagens ou catálogo resulta em retorno não
  zero do alvo, com etapas não executadas identificadas.
- [ ] **RV13J-1-09:** cortes pareados e metadados de execução normalizados; payload equivalente
  com job diferente passa, alteração de valor com mesma contagem reprova, em cada view exigida.
- [ ] **RV13J-1-10:** cada prova G2.3 da porta P3 tem comando, esperado e evidência; ausente uma
  prova essencial, bloco e dependências ficam explicitamente não aprovados para a janela.
- [ ] **RV13J-1-11:** solução concreta do rito apresentada ao Owner; receita e roteiro só
  declaram conformidade depois da decisão explícita correspondente.
- [ ] **RV13J-1-12:** falha/arquivo inválido na coleta dos tempos é reportada como falha de
  evidência, mesmo com DAG verde; sucesso exige tarefas e tempos finais verificáveis.
- [ ] **RV13J-1-13:** processos próprios encerrados e esperados, sem porta 18001 residual, nas
  saídas normal, erro e Ctrl-C; sem matar processo alheio por padrão de nome.
- [ ] **RV13J-1-14:** cada passo do percurso tem pré-condição, saída verificável e ramo de falha
  seguro, com dependências cortadas e escalada do relógio preservada.

Validação técnica das correções, revisão integral do declarativo pelo Owner e fechamento formal
do lote/M6 são atos distintos. Esta rodada entrega o parecer e deixa a coluna Situação para a
resposta do autor.

