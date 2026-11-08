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

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

