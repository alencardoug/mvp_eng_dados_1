# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `79ab2b1..4888126` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
623fbf1 feat: compara só o estado corrente na paridade local × nuvem (D85)
8472faa docs: registra as decisões D84 a D87 e a passagem da P1
9295f1e fix: corrige no registro a data da P1, que passou em 07/11
28c73a1 docs: registra a aprovação da estimativa da janela da Etapa 13
cbe69ee docs: registra o projeto de estudo e o põe no relógio de quinta
4888126 docs: registra o laboratório de estudo e os três achados dele
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 8 arquivos

- `Makefile`
- `PLANO_etapa_13.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/pendencias.md`
- `docs/registro_fase_gcp.md`
- `src/mvp_ed1/gcp/oraculo.py`
- `tests/test_composer_cli.py`
- `tests/test_oraculo_consumo.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Declaração desta entrega.** A entrega tem duas partes de natureza diferente.

**No Git (`79ab2b1..4888126`, 6 commits).** Declaração, para revisão integral:
- `src/mvp_ed1/gcp/oraculo.py` — `HISTORIA` (as camadas cuja contagem não reprova, D85) e
  `comparar_contagens`, extraída de `contagens`;
- `Makefile`, alvo `gcp-oraculos` — sem a comparação da classificação por captura, com a declaração
  impressa; três vereditos em vez de quatro;
- `docs/pendencias.md` — D84 a D87 movidas para §2, com o que cada uma descarta;
- `PLANO_etapa_13.md` — §6.3 (D84/D86), §6.4 (o projeto de estudo no relógio, à mão), §6.8 (D87 na
  tabela do G2.3; passo 18 com a D85), §6.9 passo 15, §7.2;
- `docs/capacidade_e_recuperacao.md` §2.14 — a aprovação da estimativa.
Derivado, por amostragem: `tests/test_oraculo_consumo.py`, `tests/test_composer_cli.py`. Narrativa:
`docs/registro_fase_gcp.md` §41 e §42.

**Fora do Git: o laboratório de estudo** (`data/medicoes/estudo_gcp/`, ignorado pelo Git), publicado
como página privada para o Owner. Declaração: `consultas.py` (todas as consultas SQL, na ordem dos
blocos), `gerar_pagina.py` (os textos da página e os comandos de Cloud Shell e Python),
`receita_por_categoria.py`, `vertex_sdk.py`, `vertex_lote.py`, `spark_interativo.py`,
`regras_clientes.yaml`. Medidas: `resultados.json` (saída de `rodar.py`). Derivado:
`laboratorio_gcp.html` (saída de `python3 -I gerar_pagina.py`, com `modelo.html`).

**Estado externo, sem arquivo**: o projeto `mvp-ed1-estudo` (orçamento, cota, APIs, conexão,
*bucket*, sub-rede, IAM), o faturamento tirado do "My First Project" da conta, os sete `.tfplan`
apagados de `data/medicoes/etapa_13/planos/`.

Onde gastar esforço, em ordem:
1. **D85 pode esconder uma falha de paridade real?** `HISTORIA = {raw_legacy, governance, snapshots}`
   saiu do que cada camada guarda (`airbyte/streams.yml`, `legacy_selected_capture`), não de uma
   comparação medida no estado da janela. Uma diferença em `raw_legacy` por outro motivo que não a
   história passa calada.
2. **O relógio de quinta com dois projetos.** O critério "nada cobrável depois de qui 18:00" agora
   depende de três comandos à mão para o `mvp-ed1-estudo`, fora dos alvos do `make` e fora do
   inventário do desmonte.
3. **A página do laboratório diz o que foi medido?** Cada "Confira" e cada número contra
   `resultados.json` e contra o Registro §42; comandos da página que divergem do que rodou.

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
1284 passed, 19 skipped in 476.53s (0:07:56)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

- **A D85 nunca rodou contra um armazém.** `comparar_contagens` só tem o teste de unidade; o alvo
  `gcp-oraculos` não rodou depois da mudança (pede o BigQuery do `mvp-ed1-gcp` e o armazém local). Não
  sei quais contagens divergem no estado da janela; a escolha das três camadas é dedução.
- **Os comandos de Cloud Shell da página não rodaram no Cloud Shell**: rodei os equivalentes com o
  `gcloud` local. Divergem do que rodou: o 10.1 (o *loop* de `publish` com aspas escapadas de outro
  jeito e `$N` por substituição), o 10.2 (`$SA` por substituição; o SQL é o mesmo), o 9.1 (o
  *heredoc* `FIM`), o 9.3 (`bq query` sem `--project_id`, contando com o `gcloud config set project`)
  e o 11.1 inteiro (a limpeza que fiz usou outros comandos).
- **O Python da página não rodou num notebook do BigQuery Studio**: `vertex_sdk.py`,
  `vertex_lote.py` e `spark_interativo.py` rodaram em ambiente temporário do `uv`, na máquina. O
  `%pip install` e o ambiente do Colab Enterprise não foram exercitados.
- **Os itens marcados "não rodado por mim"**: 8.1, 9.5, 10.4 e 11.2. O 5.5 rodou pela API, não pelo
  console, e os nomes de menu da página são suposição.
- **Repetição dos exercícios**: 4.4 e 4.7 usam `IF NOT EXISTS`; numa segunda passada não recriam
  nada. Não testei a página executada duas vezes em sequência.
- **Custo do Gemini**: o job cancelado da 7.2 rodou ~10 min; o custo dele não foi medido, e o
  faturamento real dos testes ainda não apareceu.
- **A página renderizada**: não abri em telefone nem em tema escuro; publiquei sem pré-visualização.
- **Preços** de US$ 6,25/TiB e de DCU-hora: de memória, não lidos nesta sessão.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- O BigQuery sob demanda cobra US$ 6,25 por TiB e 10 MiB mínimos por tabela lida (os 10 MiB foram
  observados em `resultados.json`; o preço, não).
- A conta de faturamento limita a 5 projetos ligados — inferido do erro `Cloud billing quota
  exceeded` e da lista de 5 projetos ligados.
- O `uv cache clean` não quebra os `.venv` porque o `uv` usa *hardlinks* no Linux: conferi a contagem
  de *links* de um arquivo e importei pacotes nos 12 `.venv`; não rodei os testes dos outros projetos.
- `idle_ttl` de 600 s fecha a sessão interativa do Dataproc: a sessão de teste fechou com
  `spark.stop()`, não pelo `ttl`.
- O endpoint `global` do Gemini continua sendo o único com os modelos 3.x para este projeto até
  quarta.

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

**Esta revisão.** - Leitura apenas. Não rode `gcloud`, `bq`, `terraform` nem `make` com alvo `gcp-*`: os dois projetos
  GCP são cobráveis, e o `mvp-ed1-estudo` foi devolvido vazio de propósito.
- O armazém local está de pé (`make ps`), o Airbyte local pausado (`make airbyte-resume` o retoma, não
  é preciso para esta revisão).
- As fontes do laboratório estão em `data/medicoes/estudo_gcp/`; a página publicada é
  `laboratorio_gcp.html` ali mesmo (o link claude.ai não abre fora da conta do Owner).
- `python3 -I data/medicoes/estudo_gcp/gerar_pagina.py` regenera a página localmente, sem rede, e é a
  forma de conferir que o HTML nasce das declarações.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **A camada `governance` inteira em `HISTORIA`.** Ela tem tabelas de estado (`_versions`, por
  exemplo) ao lado das de história; marcar a camada inteira é mais simples e cala também a parte de
  estado. A alternativa era listar tabelas.
- **Tirar a classificação do alvo, em vez de imprimi-la sem reprovar.** O módulo continua sabendo
  compará-la (o *docstring* mostra a linha de comando), mas a janela não a vê mais. Imprimir daria
  evidência; tirar evita uma saída que alguém leia como reprovação.
- **Um segundo projeto, em vez de um *dataset* no `mvp-ed1-gcp`.** Isola o inventário do desmonte e o
  `armazem_janela pronto`; o custo é o relógio à mão e um projeto fora do `residuos_esperados.yml`.
- **A conta de serviço padrão do Compute, com `roles/editor`, roda o Dataproc e o Cloud Run do
  laboratório.** É o padrão do projeto novo e serve para estudo; a página diz que em produção não
  seria assim, mas o laboratório ensina com ela.
- **Devolver o projeto de estudo vazio.** O Owner refaz tudo do zero, mas as medidas da página são de
  uma execução que não existe mais para conferir no console.
- **"P1 passou" no §41**: corrigido no mesmo dia (9295f1e), depois de ver que a §10 do plano já a dava
  por passada em 07/11.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

