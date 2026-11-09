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

### 1. Conclusão

**Mudanças necessárias.** Rodada 1 da revisão independente da sessão de 08/11/2026:
**3 bloqueantes, 7 ajustes e 1 observação**. A D85 admite aprovação indevida de estado de
migração e de objeto ausente; o laboratório não limita de forma segura a inferência em 7.1
e não encerra os runtimes dos notebooks conforme promete.

As decisões D84–D87, opção (a), foram tratadas como vigentes. Os achados pedem correção da
implementação, das evidências ou da explicação; não reabrem essas decisões nem reduzem o M6.
Este parecer não é aceite do declarativo nem encerramento formal da Etapa 13.

### 2. Escopo e versão revisados

- **A:** `79ab2b1..4888126`, os seis commits informados; oito arquivos alterados. Dossiê lido
  em `1f85574`, que era o `HEAD`; árvore inicialmente limpa. Foram confrontados os modelos,
  modos de ingestão, critérios e código auxiliar necessários para interpretar a mudança.
- **B:** os onze arquivos de `data/medicoes/estudo_gcp/`, inclusive SQL, gerador, modelo HTML,
  fontes Python/YAML, executor, medidas e HTML publicado. Como são ignorados pelo Git, a
  versão foi fixada por SHA-256. Hash do conjunto: `67f2250cd0ca1c0a8eea4d77cfc2dccd1ecc1886502c01784134e5ad7b3ce551`
  (nomes ordenados; concatenação de `nome`, TAB, SHA-256 do arquivo, LF). Em particular:
  `resultados.json` = `dee4e96255a60d982bb475e297fd95954bd30a4e1335138795b8a6ab3ed544f4`;
  HTML = `9dc2fbbb362ff8a8020fa3efcbc17dbaba72274c1d6eef8de5b56282b7ca0e7c`.
- Revisão em 09/11/2026, somente leitura, exceto este parecer e a cópia expressamente
  autorizada do laboratório para `/tmp`. Nenhum recurso dos dois projetos foi consultado
  por CLI ou alterado.

### 3. Evidências dos achados

**RV0811-1-01 — exceção histórica também aprova estado e ausência de objeto.**
`src/mvp_ed1/gcp/oraculo.py:79`, `:122` e `:127`; `src/mvp_ed1/governance.py:300` e `:342`;
`tests/test_oraculo_consumo.py:44`; critério `PLANO_etapa_13.md:1358`.
A presença de tabelas e as migrações aplicadas não dependem do número de capturas.
O catálogo (`src/mvp_ed1/gcp/catalogo.py:33`) compara manifests, não a existência dos objetos
no armazém. O novo teste chega a aceitar um snapshot ausente do outro lado.

Contraprova executada sem importar a aplicação, acessar configuração ou conectar a banco:

```python
# python3 -I - <<'PY'  (núcleo da sonda executada)
import ast
from pathlib import Path
p = Path('src/mvp_ed1/gcp/oraculo.py')
t = ast.parse(p.read_text())
nodes = [n for n in t.body if
         isinstance(n, ast.Assign) and any(isinstance(x, ast.Name) and x.id == 'HISTORIA' for x in n.targets)
         or isinstance(n, ast.FunctionDef) and n.name == 'comparar_contagens']
ns = {}
exec(compile(ast.Module(body=nodes, type_ignores=[]), str(p), 'exec'), ns)
# Entradas sintéticas de contraprova, não contagens dos armazéns:
ns['comparar_contagens']({('governance', '_versions'): 2}, {('governance', '_versions'): 1})
ns['comparar_contagens']({('snapshots', 'snap_products'): 7}, {})
```

Saída relevante observada, em ambos os casos:

```text
governance._versions: local 2, BigQuery 1 (história do ambiente, não comparável — D85)
snapshots.snap_products: local 7, BigQuery None (história do ambiente, não comparável — D85)
divergências que reprovam: 0
```

**RV0811-1-02 — há história ainda contada como estado.**
`dbt/models/trusted/legacy/legacy_presence_by_capture.sql:31` inclui todas as capturas
certificadas, além da selecionada. `legacy_capture_transitions.sql:32` depende da anterior,
e `legacy_removed_records.sql:40` lê as anteriores. Isso contradiz a justificativa geral de
`docs/registro_fase_gcp.md:1615` e a promessa de comparar somente estado.

Comandos: `nl -ba dbt/models/trusted/legacy/legacy_presence_by_capture.sql | sed -n '1,90p'`
e a mesma sonda AST acima, aplicada a duas quantidades sintéticas de presença histórica.
Saídas relevantes:

```text
31  ), consideradas AS (
34    FROM certificadas
35    UNION DISTINCT
38    FROM selecionada

trusted.legacy_presence_by_capture: local 20, BigQuery 10
contagens: 0 iguais, 1 diferentes ou de um lado só nas camadas de estado, 0 nas de história (não comparáveis, D85)
divergências que reprovam: 1
```

É uma demonstração da classificação do comparador, não medição de divergência real entre
os ambientes. Uma captura antiga adicional basta para alterar essa contagem, mesmo mantendo
a captura corrente idêntica em conteúdo.

**RV0811-1-03 — 7.1 mantém a inferência antes da limitação garantida de entrada.**
`data/medicoes/estudo_gcp/consultas.py:285`–`:296`; aviso em `gerar_pagina.py:194`;
incidente registrado em `docs/registro_fase_gcp.md:1664`.
Comando: `nl -ba data/medicoes/estudo_gcp/consultas.py`. Trecho observado:

```sql
SELECT
  name AS produto,
  category AS categoria,
  AI.GENERATE(
    ...
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE department = 'Women'
ORDER BY id
LIMIT 10
```

O JSON registra dez linhas **de saída**, 2,1 MiB processados e 10 MiB faturados
(`resultados.json:1019`), sem contagem de chamadas/tokens. Isso não prova só dez inferências.
A [referência oficial de AI.GENERATE, seção Manage inference costs](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-generate#manage_inference_costs)
adverte que `ORDER BY ... LIMIT` pode processar mais linhas no modelo e recomenda materializar
a entrada limitada em outra tabela para controle estrito. A subconsulta de 7.2 melhora a
forma, mas não deve ser apresentada como garantia absoluta sem essa barreira. Há risco de
custo Vertex adicional ao processamento SQL mostrado; nenhum gasto adicional foi provocado
por esta revisão.

**RV0811-1-04 — desconectar não encerra o recurso cobrável.**
`data/medicoes/estudo_gcp/gerar_pagina.py:218`, `:341` e `:346`–`:351`.
Comando: `nl -ba data/medicoes/estudo_gcp/gerar_pagina.py | sed -n '184,430p'`.
Instruções observadas:

```text
desconecte o runtime no fim.
gcloud dataproc sessions list --location=us-central1   # nenhuma ACTIVE
bq rm -r -f -d mvp-ed1-estudo:exercicios
Desconecte também o runtime dos notebooks.
```

Não há parada/exclusão de runtime Colab nem ação para uma sessão Dataproc que ainda esteja
ativa. A [documentação oficial de runtimes](https://docs.cloud.google.com/colab/docs/manage-runtimes)
separa desconexão, parada e exclusão, e prevê reconectar ao runtime que continuou rodando.
A limpeza pode, portanto, terminar deixando computação faturável até a parada por outro
mecanismo. O desligamento geral de quinta não torna correta a instrução de encerramento
de quarta. Faltam ação de encerramento e conferência do estado final, incluindo o caminho
em que a consulta falha antes de `spark.stop()`.

**RV0811-1-05 — RDD não existe nesse runtime de Spark.**
`data/medicoes/estudo_gcp/gerar_pagina.py:269`–`:276`.
O mesmo comando de leitura acima mostrou:

```python
print(recente.rdd.getNumPartitions())
```

O texto também propõe `df.rdd.getNumPartitions()` na sessão de 9.4, que é Spark Connect
(`spark_interativo.py:3`). A [documentação oficial de Spark no BigQuery Studio](https://docs.cloud.google.com/bigquery/docs/use-spark#write_and_run_pyspark_code_in_your_bigquery_studio_notebook)
exclui suporte a SparkContext e RDD. O selo de não executado é correto, mas o snippet
continua incompatível com o runtime indicado. Corrigir o exercício usando APIs suportadas,
preservando a execução de Spark na nuvem.

**RV0811-1-06 — o leitor recebe uma garantia de execução maior que a evidência.**
`data/medicoes/estudo_gcp/modelo.html:113`, `gerar_pagina.py:377`;
`docs/registro_fase_gcp.md:1655`; dossiê original `REVISAO.md:109`–`:120`.
Comandos: `nl -ba data/medicoes/estudo_gcp/modelo.html | sed -n '96,141p'`,
`nl -ba REVISAO.md | sed -n '95,160p'` e leitura das chamadas `ex` por AST.
Saídas relevantes:

```text
Cada consulta e comando desta página rodou no projeto de estudo antes de entrar aqui
não rodados marcados: ['10.4', '11.2', '8.1', '9.5']
```

O dossiê informa que 9.1, 9.3, 10.1, 10.2 e 11.1 não rodaram exatamente na forma/ambiente
publicados; Python e `%pip` não rodaram no notebook. A nota de 8.2 explica parte disso,
mas não cobre os demais; o Registro diz que cada exercício rodou, incluindo os quatro
marcados como não executados. A análise estática desta rodada não equivale a execução
no runtime. Ajustar os rótulos da página e a afirmação do Registro ao alcance real da prova.

**RV0811-1-07 — números não SQL sem fonte nas duas evidências indicadas.**
`data/medicoes/estudo_gcp/gerar_pagina.py:252`, `:266`, `:319` e `:333`.
Comando executado abaixo; a mesma leitura também produziu as saídas numéricas dos
achados 08, 09 e 11:

```bash
python3 -I - <<'PY'
import json
from pathlib import Path
base = Path('data/medicoes/estudo_gcp')
d = json.loads((base / 'resultados.json').read_text())
r = Path('docs/registro_fase_gcp.md').read_text().split('## 42.', 1)[1]
for k in ('9.2', '9.3', '9.4', '10.1', '10.2', '10.3'):
    print(k, 'presente em resultados:', k in d)
for x in ('2.211', '126 s', '2 min 16', '0,99998', '75', '84%'):
    print(x, x in r)
for k in ('4.3', '4.4', '4.9'):
    print(f"{k}: mib_proc={d[k]['mib_proc']}, mib_fat={d[k]['mib_fat']}")
for x, y in zip(d['6.2']['amostra'], d['6.3']['amostra']):
    print(x['dia'], x['previsto'], y['previsto'], 'diferença %', round(100 * (y['previsto'] - x['previsto']) / x['previsto'], 1))
print('6.10 pesos:', [(x['feature'], x['peso']) for x in d['6.10']['amostra']])
print('1.6 GiB:', d['1.6']['mib_proc'] / 1024)
PY
```

Saída relevante (as últimas seis buscas são restritas ao Registro §42):

```text
9.2 presente em resultados: False
9.3 presente em resultados: False
9.4 presente em resultados: False
10.1 presente em resultados: False
10.2 presente em resultados: False
10.3 presente em resultados: False
2.211 False
126 s False
2 min 16 False
0,99998 False
75 False
84% False
```

São 2.211 linhas do Spark, 126 s da sessão, 2 min 16 s do Cloud Run e os resultados
Dataplex (0,99998, 75 e 84%). Também não há nesses registros a tabela dos líderes mensais
do Spark prometida em 9.3. O Registro sustenta 2 min 50 s/0,32 DCU-hora do lote Spark e
7 min do Gemini, mas não os outros resultados. Não se conclui que sejam falsos: falta
evidência consultável para aprová-los pelo critério pedido. Anexar a saída medida na fonte
de evidências ou retirar a apresentação como medição conferida.

**RV0811-1-08 — bytes de consulta são usados como prova de armazenamento e de plano.**
`data/medicoes/estudo_gcp/gerar_pagina.py:128`–`:136`; `rodar.py:39`;
`resultados.json:648`, `:656` e `:728`.
Comandos: leitura numerada desses arquivos e sonda Python transcrita no achado 07.
Saídas relevantes:

```text
4.3: mib_proc=0.0, mib_fat=0.0
4.4: mib_proc=0.0, mib_fat=0.0
4.9: mib_proc=0.0, mib_fat=10.0
```

`rodar.py` usa `job.total_bytes_processed` e `job.total_bytes_billed`, arredondados para
uma casa decimal. Isso não mede bytes de armazenamento de clone/snapshot, nem contém
estatísticas de uso da materialized view. Portanto, o zero do job DDL não demonstra
armazenamento sem cobrança, e o `0,0 MiB` arredondado não demonstra a reescrita afirmada
em 4.9. Distinguir as métricas e rotular a explicação de plano como não verificada até
haver estatísticas do job. Não foi medido armazenamento nesta revisão.

**RV0811-1-09 — dois “Confira” de ML contradizem os resultados.**
`data/medicoes/estudo_gcp/gerar_pagina.py:169` e `:181`;
`resultados.json:802`, `:853` e `:994`.
Comando: sonda Python transcrita no achado 07, comparando `amostra` por data e os pesos.
Saídas relevantes:

```text
2026-11-12 5954.0 9283.0 diferença % 55.9
2026-11-14 6116.0 10945.0 diferença % 79.0
6.10 pesos: [('traffic_source', 0.1149), ('gender', 0.1149), ('country', 0.1147), ('valor_primeiro', 0.0012), ('age', 0.0006), ('itens_primeiro', 0.0001)]
maior/menor: 1149.0
```

As previsões só ficam próximas nos dois primeiros dias da amostra; os pesos não são
“quase iguais” no conjunto. Reescrever a interpretação em função do resultado observado.
Essas saídas tampouco bastam para provar a ausência de todo sinal preditivo no dataset.

**RV0811-1-10 — a segunda passagem não recria o retrato que o texto compara.**
`data/medicoes/estudo_gcp/consultas.py:154`, `:163`, `:165` e `:173`;
`gerar_pagina.py:132`; dossiê original `REVISAO.md:119`.
Comando: `nl -ba data/medicoes/estudo_gcp/consultas.py`. Saída relevante:

```sql
CREATE OR REPLACE TABLE exercicios.itens AS ...
CREATE OR REPLACE TABLE exercicios.itens_clone CLONE exercicios.itens
CREATE SNAPSHOT TABLE IF NOT EXISTS exercicios.itens_retrato ...
CREATE MATERIALIZED VIEW IF NOT EXISTS exercicios.mv_receita_dia ...
```

Em uma repetição, base e clone são recriados; o snapshot existente continua sendo o da
passagem anterior, inclusive com o vencimento anterior. Se a origem pública mudou, 4.6
pode deixar de mostrar original e retrato iguais, contrariando o “Confira”. A view
existente também não é recriada pelo passo 4.7. Documentar um preparo/reset explícito
para repetir o bloco, ou declarar a execução única e como recomeçar. Não foi feita
segunda execução SQL; o achado decorre do fluxo declarado e da semântica de `IF NOT EXISTS`.

**RV0811-1-11 — conversão MiB → GiB incorreta em 1.6.**
`data/medicoes/estudo_gcp/gerar_pagina.py:72`; entrada 1.6 de `resultados.json`.
Comando: sonda Python transcrita no achado 07, dividindo a medida em MiB por 1.024.

```text
1.6 GiB: 1.23525390625
```

A página diz 1,26 GiB; a medida de 1.264,9 MiB corresponde a aproximadamente 1,24 GiB.
Corrigir a unidade/conversão no gerador. O preço de US$ 0,008 é uma estimativa separada,
cuja tarifa não foi revalidada nesta rodada.

### 4. Verificações executadas

- Leitura integral de `CLAUDE.md`, da skill local `.claude/skills/revisao/SKILL.md`, do
  dossiê (incluindo §2/§4/§5/§7) e do diff dos seis commits. Confronto com os modelos
  dbt e as decisões vigentes, sem modificar ADR aceito.
- `.venv/bin/python -m pytest -q tests/test_oraculo_consumo.py tests/test_composer_cli.py`:

  ```text
  ...............................                                          [100%]
  31 passed in 0.09s
  ```

- Contraprovas em memória da função `comparar_contagens`, extraída por AST: o defeito
  de `_versions`/objeto ausente acima e o falso positivo histórico. A contraprova em
  `raw.inventory_movements_stream` (4 versus 3, entradas sintéticas) retornou **1**,
  preservando a reprovação do estado. A retirada da comparação da classificação por
  `snapshot_id` corresponde à D85 e não foi tratada como defeito por si só. O `RECORTE`
  da quarentena foi lido: mantém o filtro da captura e tratamento correntes.
- Cópia para `/tmp/rv0811-1-7ift8_tw/estudo_gcp/`, seguida de
  `python3 -I /tmp/rv0811-1-7ift8_tw/estudo_gcp/gerar_pagina.py`:

  ```text
  exercícios: 65 · bytes: 81693
  HTML reproduzido idêntico: True
  ```

  O arquivo original não foi regenerado. Os sete fontes Python passaram por análise
  de sintaxe em memória. Os quatro snippets Python publicados passaram por `ast.parse`
  após excluir as linhas mágicas `%pip`; isso não valida instalações nem execução remota.
- Extração do código do HTML, análise lexical por `shlex` e leitura dos heredocs:

  ```text
  9.1 heredoc íntegro: True
  10.3 heredoc íntegro: True
  10.1 JSON: {'pedido_id': 1, 'status': 'pago', 'valor': 10.5, 'momento': '2026-11-09T00:00:00Z'} barras residuais: 0
  10.2 argumentos: ['--project_id=mvp-ed1-estudo', 'query', '--use_legacy_sql=false', '$SQL']
  ```

  Na análise de 10.1, as expansões foram substituídas em memória por exemplos fixos.
  O teste de 10.2 preservou a variável SQL como um argumento após o separador declarado;
  a atribuição original está entre aspas simples e sua expansão, entre aspas duplas.
  Nenhum comando publicado foi executado contra GCP.
- Leitura das 48 entradas de medidas, todas com `ok: true`; confronto dos medidores
  gerados e dos “Confira” com JSON e Registro §42. As amostras de 1.4/1.5 e 1.7/1.8
  coincidem; 8.908 casos, 681.610/679.137 (0,36%), 1.138/2 clientes e 154.375/181.610
  conferem. Os totais globais de 78 consultas/3,29 GiB têm suporte narrativo no Registro,
  não foram recontados em `JOBS_BY_PROJECT` nesta revisão.
- D84/D86, D87, aprovação de US$ 40–70 e referências de §40/§41 confrontados entre
  Pendências, Plano e Registro; âncoras de D84–D87 e §41 existem. Listagem dos nomes
  dos planos confirma ausência dos sete `.tfplan` citados; backups de estado não foram lidos.
- Relógio dos dois projetos conferido. O `unlink` explícito e a confirmação de
  `billingEnabled: false` em `PLANO_etapa_13.md:500` são suficientes como barreira de
  faturamento para o projeto de estudo: a [documentação oficial de Cloud Billing](https://docs.cloud.google.com/billing/docs/how-to/modify-project#disable_billing_for_a_project)
  informa que a desativação interrompe serviços GCP e cobrança do projeto. A execução
  manual não é, por si, defeito. G7 continua restrito ao inventário do M6; o segundo
  projeto depende da ação do Owner na §6.4, inclusive da escalada do mesmo relógio se
  ela falhar. Não há prova operacional do desligamento nesta rodada.
- `git diff --check 79ab2b1..4888126`: sem saída, código 0. Varredura por padrões de
  e-mail pessoal, ID de conta de faturamento, chaves privadas e tokens comuns: nenhum
  achado nos oito arquivos alterados e nos onze do laboratório. Em particular, §42
  não contém e-mail pessoal nem ID da conta de faturamento. Os endereços de contas
  de serviço encontrados no laboratório são identidades de máquina. A leitura não
  encontrou outra violação demonstrável de `CLAUDE.md` §6 no escopo.

### 5. Limites

Não foram executados `make`, Docker, abctl, gcloud, bq, Terraform, dbt, sincronização,
consulta a banco ou leitura de `.env`. Não foram criados serviços nem consultas cobráveis.
O `make check` do autor não foi repetido; os 31 testes acima são a validação executada
por este revisor. As contraprovas de contagem são sintéticas e não medem o estado real
dos armazéns; a paridade da janela permanece por provar.

Não foram verificados o IAM efetivo das contas de serviço, o estado atual das APIs,
orçamento/cotas, os projetos vazios, a operação no Cloud Shell/Colab, a autenticação
remota, o encerramento por `idle_ttl`, o faturamento real ou a limpeza real dos projetos.
A ausência de chave nos snippets não certifica privilégio mínimo no IAM. Também não
houve revisão visual da página publicada nem acesso ao link privado. As quatro páginas
oficiais citadas foram as únicas abertas; as demais premissas de preço/modelos não
foram revalidadas. A varredura de segredos foi delimitada aos arquivos do escopo, por
padrões e leitura; não constitui auditoria de todo o histórico Git.

Os ajustes da página devem nascer em suas fontes declarativas e ser propagados por
regeneração; este parecer não alterou essas fontes nem o HTML.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV0811-1-01 | `src/mvp_ed1/gcp/oraculo.py:122`–`:129`; `tests/test_oraculo_consumo.py:44` | **Alta.** A exceção por schema aprova migração ausente em `governance._versions` e tabela ausente em schemas históricos. Separar presença/estado de migração da contagem histórica isenta, preservando a D85, e cobrir essas falhas nos testes. | bloqueante || Corrigido. A história passou a ser declarada por objeto (`HISTORIA_SCHEMAS`, `HISTORIA_OBJETOS`, `e_historia`); `governance._versions` é estado; objeto de um lado só reprova sempre, de história ou não. Teste novo `test_migracoes_e_objeto_de_um_lado_so_reprovam_mesmo_na_historia` com os três casos da contraprova (`_versions` 2×1, snapshot ausente, `raw_legacy` só na nuvem). |
| RV0811-1-02 | `src/mvp_ed1/gcp/oraculo.py:79`; `dbt/models/trusted/legacy/legacy_presence_by_capture.sql:31`; Registro §41 | **Média.** A seleção por camada ainda compara história em `trusted` como se fosse estado. Declarar as exceções/recortes por objeto e a validação própria de memória; corrigir a justificativa documental. Não alargar a isenção para todo `trusted`. | ajuste || Corrigido. `legacy_presence_by_capture`, `legacy_capture_transitions` e `legacy_removed_records` entraram como objetos de história; o resto de `trusted` segue estado. Conferido por `grep` que só `legacy_selected_capture` (estado, a captura corrente) lê `legacy_captures`. Pendências D85, plano §6.8 passo 18 e §7.2 e Registro §41 (nota) corrigidos. |
| RV0811-1-03 | `data/medicoes/estudo_gcp/consultas.py:285`–`:315`; página 7.1/7.2 | **Alta.** O `ORDER BY ... LIMIT 10` de 7.1 não garante só dez inferências; a saída e os MiB não provam esse limite. Materializar a entrada limitada para controle estrito, alinhar a receita de 7.2 e avisar do custo Vertex separado, não limitado pelos bytes SQL. | bloqueante || Corrigido. 7.0 materializa a amostra (10 Women + 5 Men) e 7.4 os 2.000 textos; 7.1, 7.2 e 7.4b leem dessas tabelas. Reexecutado em 09/11: 7.1 leu 940 bytes e devolveu 10 linhas; 7.2, 1.060 bytes e 5. O texto do 7.0 cita o aviso da documentação e diz que a chamada ao Vertex AI é cobrada à parte dos bytes. |
| RV0811-1-04 | `data/medicoes/estudo_gcp/gerar_pagina.py:218`, `:346`–`:351` | **Alta.** Desconectar notebook não encerra seu runtime; listar sessões Dataproc também não termina as ativas. Ensinar parada/exclusão e confirmação de encerramento, incluindo falhas antes de `spark.stop()`. | bloqueante || Corrigido. 11.1 é um script (`limpeza.sh`) que encerra cada sessão ACTIVE pela API REST do Dataproc, exclui cada runtime do Colab e confere as duas listas; a 9.4 ganhou `try/finally` com `spark.stop()`, reexecutada com sucesso (`TERMINATING` ao fim). Os passos 2–4 rodaram sem nada ativo (`{}`, `Listed 0 items`); encerrar e excluir não foram exercitados, e a página diz isso. Achado próprio no caminho: `gcloud dataproc sessions` não existe sem `beta`. |
| RV0811-1-05 | `data/medicoes/estudo_gcp/gerar_pagina.py:269`–`:276` | **Média.** 9.5 usa `.rdd.getNumPartitions()`, indisponível no Spark Connect indicado. Substituir por exercício compatível com a sessão na nuvem. | ajuste || Corrigido. 9.5 usa `spark_partition_id()` e o texto diz que o Spark Connect não tem RDD. Segue marcado "não rodado por mim". |
| RV0811-1-06 | `data/medicoes/estudo_gcp/modelo.html:113`; `gerar_pagina.py:377`; `docs/registro_fase_gcp.md:1655` | **Média.** A garantia de que cada comando/exercício rodou excede a prova descrita no dossiê. Rotular os comandos adaptados e runtimes não exercitados e corrigir a afirmação universal do Registro. | ajuste || Corrigido. Selos "rodou adaptado, fora do Cloud Shell" (9.1, 9.2, 9.3, 10.1, 10.2, 10.3) e "rodou fora do notebook" (8.2, 8.4, 9.4); a abertura da página e o Registro §42 dizem que só o SQL rodou como está. |
| RV0811-1-07 | `data/medicoes/estudo_gcp/gerar_pagina.py:252`, `:266`, `:319`, `:333` | **Média.** Linhas e líderes do Spark, tempo da sessão/Cloud Run e métricas Dataplex não têm saída verificável em `resultados.json` nem no Registro §42. Registrar evidência ou retirar a apresentação como medição conferida. | ajuste || Corrigido. Saídas literais em `data/medicoes/estudo_gcp/evidencias/`: `spark_lote_gcloud.txt` (2.211 linhas, 2m50s), `spark_lote_driveroutput.txt` (plano e líderes por mês), `gemini_lote.txt`, e `saidas_do_terminal.md` (sessão interativa, Pub/Sub, Cloud Run 2m16s e Scheduler, Dataplex 0,99998/75/0,84176, acesso por coluna, mascaramento recusado). A sessão interativa foi refeita: 47 s / 64 s, que a página passou a citar. |
| RV0811-1-08 | `data/medicoes/estudo_gcp/gerar_pagina.py:128`–`:136`; `rodar.py:39` | **Média.** Zero bytes do job DDL não mede armazenamento de clone/snapshot; `0,0 MiB` arredondado não prova uso de materialized view. Distinguir métrica medida de explicação não verificada e não sugerir ausência de custo de armazenamento. | ajuste || Corrigido. `rodar.py` grava bytes exatos e `materializedViewStatistics`. 4.9 reexecutada: `chosen: true`, 44.896 bytes; 4.8: `rejectedReason: NO_DATA`. O "Confira" do 4.4 diz que o job faturou 0 bytes de consulta e que o armazenamento de clone e snapshot não foi medido. |
| RV0811-1-09 | `data/medicoes/estudo_gcp/gerar_pagina.py:169`, `:181` | **Média.** “Valores próximos” e “pesos quase iguais” não descrevem as amostras de 6.2/6.3 e 6.10. Ajustar os “Confira” aos valores e limitar a conclusão sobre sinal preditivo ao que foi avaliado. | ajuste || Corrigido. 6.3: próximas nos dois primeiros dias (8.712 × 8.403), divergem até 79% depois. 6.9: "estas seis variáveis não separam quem volta", sem afirmar ausência de sinal no thelook. 6.10: três categóricas perto de 0,115 e três numéricas perto de zero. |
| RV0811-1-10 | `data/medicoes/estudo_gcp/consultas.py:154`–`:175` | **Média.** A repetição recria base/clone mas conserva o snapshot anterior por `IF NOT EXISTS`; o resultado prometido em 4.6 deixa de ser garantido. Explicitar preparo/reset e a repetição de 4.4/4.7. | ajuste || Corrigido. Exercício 4.0 (DROP da view, do snapshot, do clone e da restaurada) para recomeçar o bloco, reexecutado: 4.6 voltou a mostrar original e retrato iguais. |
| RV0811-1-11 | `data/medicoes/estudo_gcp/gerar_pagina.py:72` | **Baixa.** 1.264,9 MiB são aproximadamente 1,24 GiB, não 1,26 GiB. Corrigir a conversão no texto gerador. | observação || Corrigido no gerador: 1,24 GiB. |

## Rodada 2 — regressão

### 1. Conclusão

**Nenhum bloqueante no escopo revisado.** Os onze achados da rodada 1 estão **resolvidos**
no alcance desta revisão. As correções não reabriram achado anterior. Resta **uma observação
documental**, RV0811-2-01, sobre a data atribuída às medidas reexecutadas: **0 bloqueantes,
0 ajustes e 1 observação**. Essa observação ainda está aberta; este parecer não registra o
encerramento da revisão.

A conclusão é sobre as correções e suas regressões. Não equivale a aceite do M6, prova da
paridade dos armazéns ou validação operacional dos comandos de nuvem. D84–D87, opção (a),
escopo integral, projeto de estudo separado e Spark na nuvem foram mantidos como decisões
vigentes.

### 2. Escopo e versão

- **A — Git:** `1f85574..8fc7185`, exclusivamente os commits `31676ad` e `8fc7185`.
  `HEAD` conferido: `8fc718559287fe9a063459161d7aced636964e5e`; árvore inicialmente limpa.
  Leitura integral do diff, incluindo a resposta do autor na tabela da rodada 1, e confronto
  entre comparador, testes, D85, Plano §6.8 passo 18/§7.2 e Registro §41–§43.
- **B — ignorado pelo Git:** os **16 arquivos** atualmente em `data/medicoes/estudo_gcp/`,
  incluindo os quatro de `evidencias/`. Hash SHA-256 do conjunto:
  `f3bdde25efa2ddf54f55a60058d6ee1a2a4909c5c2abcc8b914c2bd96446c150`.
  Mesmo método da rodada 1: nomes relativos à pasta, ordenados; concatenação de
  `nome`, TAB, SHA-256 hexadecimal do arquivo, LF, codificada em UTF-8. Em particular:
  `resultados.json` = `f4fbb03a185dec2a2d067a6836edcc370a3900c836e588ab77e4e2bcb039afa7`;
  `laboratorio_gcp.html` = `1cb9bc747c540ca4f665465fec61186ee01386a48d6e80c14f4a8b4331f19b64`;
  `gerar_pagina.py` = `419f741c6b36143487fb6c1bca1cab9b3f69dc2f11b75360634e8eec691838ad`;
  `limpeza.sh` = `e1db3a86d867a56f044481a4ec0ad41e23f66d12700566bbcce1cb8bddadf0ee`.
  O HTML local foi confrontado com as fontes; a publicação privada como versão 2 é
  informação do autor, não uma publicação acessada nesta revisão.
- Revisão em **09/11/2026**, restrita à resolução dos achados anteriores e às regressões
  das correções. Somente `REVISAO.md` foi editado no projeto. A geração autorizada ocorreu
  numa cópia em `/tmp/rv0811-2-_fw0o983/estudo_gcp/`.

### 3. Estado de RV0811-1-01…11

Os caminhos abreviados do laboratório abaixo são relativos a `data/medicoes/estudo_gcp/`.

| Achado anterior | Estado | Evidência e alcance |
|---|---|---|
| RV0811-1-01 | resolvido | `src/mvp_ed1/gcp/oraculo.py:79`, `:126`, `:140`; `tests/test_oraculo_consumo.py:53`. `_versions` ficou fora da isenção; a contagem histórica só é isenta quando o objeto existe nos dois lados. Os testes reprovam migrações 2×1, snapshot só local e `raw_legacy` só na nuvem. D85 em `docs/pendencias.md:277` declara a mesma regra. |
| RV0811-1-02 | resolvido | `src/mvp_ed1/gcp/oraculo.py:80` lista os três objetos históricos de `trusted`, sem isentar o schema inteiro; teste em `tests/test_oraculo_consumo.py:42`. Lista alinhada com `PLANO_etapa_13.md:1015`/`:1345`, `docs/pendencias.md:277` e Registro em `docs/registro_fase_gcp.md:1682`. A narrativa original do §41 recebe ressalva explícita em `:1618`. A prova própria da memória permanece no passo 19 (`PLANO_etapa_13.md:1019`), sem ter sido executada nesta rodada. |
| RV0811-1-03 | resolvido | `consultas.py:289`, `:299`, `:309`, `:328`, `:333`: materialização prévia das amostras, sem inferência durante a seleção limitada; 7.1/7.2 leem `amostra_produtos`, 7.4b lê `produtos_texto`. `gerar_pagina.py:200` distingue cobrança Vertex dos bytes SQL. O JSON registra 940 bytes/10 saídas em 7.1 e 1.060 bytes/5 saídas em 7.2; esses números não foram tratados como medição de tokens ou contagem de chamadas. |
| RV0811-1-04 | resolvido | `limpeza.sh:5`, `:14`, `:19` inclui encerramento, exclusão e conferência; `spark_interativo.py:24`/`:31` protege a consulta com `try/finally`. `gerar_pagina.py:366`–`:372` informa expressamente que terminate/delete não foram exercitados. `evidencias/saidas_do_terminal.md:124` registra a reexecução com sessão pronta em 47 s, total 64 s e estado `TERMINATING`, sem confundi-lo com prova de estado final `TERMINATED`. A ausência de execução dos caminhos declarados não exercitados não é achado nesta rodada, conforme o limite solicitado. |
| RV0811-1-05 | resolvido | `gerar_pagina.py:287`–`:297` troca RDD por `F.spark_partition_id()` e mantém o exercício como não executado. A API escolhida suporta Spark Connect; não houve execução de Spark local ou remoto por este revisor. |
| RV0811-1-06 | resolvido | `modelo.html:114`, `gerar_pagina.py:379`/`:394` e `docs/registro_fase_gcp.md:1656` distinguem SQL, comandos adaptados e Python fora do notebook. O HTML contém seis selos de adaptação, três de execução fora do notebook e quatro de não execução; 5.5 informa teste pela API (`gerar_pagina.py:165`) e 11.1 explicita sua prova parcial (`:371`). A nova divergência de data das medidas é registrada separadamente em RV0811-2-01. |
| RV0811-1-07 | resolvido | `evidencias/spark_lote_gcloud.txt:37`/`:62`: 2.211 linhas/2m50,962s; `evidencias/spark_lote_driveroutput.txt:22`/`:47`: plano e seis líderes mensais pedidos pelo exercício. `evidencias/saidas_do_terminal.md:18`, `:56`, `:68`, `:124`: uso do lote, Cloud Run/Scheduler, Dataplex e sessão refeita. `gerar_pagina.py:282` agora cita 47 s/64 s, não os 126 s da execução anterior. As medidas antes sem fonte têm saídas consultáveis. |
| RV0811-1-08 | resolvido | `rodar.py:39`–`:45` preserva bytes exatos e estatística da view. `resultados.json:771` registra 44.896 bytes e `chosen: true`; 4.8 registra `NO_DATA` e 2,4 MiB. `gerar_pagina.py:131`–`:144` separa consulta de armazenamento não medido e explica a diferença das duas leituras. O zero arredondado deixou de ser a prova da reescrita. |
| RV0811-1-09 | resolvido | `gerar_pagina.py:177`–`:192` descreve a divergência das previsões e a separação entre pesos categóricos/numéricos, limitando a interpretação ao modelo e às variáveis avaliadas. Recontagem das amostras: diferenças de 3,55% e 0,55% nos dois primeiros dias, máximo de 78,96%; pesos categóricos 0,1147–0,1149 e numéricos 0,0001–0,0012. |
| RV0811-1-10 | resolvido | `consultas.py:154`–`:157` remove view, snapshot, clone e restaurada; `gerar_pagina.py:122` manda executar esse preparo antes de repetir o bloco. O JSON contém 4.0 com sucesso e 4.6 com original/retrato 9.231.974 e clone 18.463.947, compatíveis com o dobro antes do arredondamento. A sequência agora declara o reset necessário; o SQL não foi reexecutado pelo revisor. |
| RV0811-1-11 | resolvido | `gerar_pagina.py:73`: 1,24 GiB. A medida continua em 1.264,9 MiB; divisão por 1.024 = 1,23525390625 GiB. O HTML reproduz a correção. |

### 4. Achados

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV0811-2-01 | `data/medicoes/estudo_gcp/gerar_pagina.py:421`, `:127`; artigo 4.2 de `laboratorio_gcp.html` | **Baixa.** As medidas reexecutadas em 09/11 continuam recebendo o selo fixo **“medido em 08/11”**. No próprio 4.2, o selo atribui 26 MiB/28 MiB/7,3 s a 08/11 e o “Confira” atribui as 154.487/181.798 linhas da mesma entrada a **09/11**. A reexecução dos blocos 4 e 7 introduziu essa divergência de rastreabilidade. Ajustar a data exibida às medições correspondentes nas fontes e regenerar o HTML. Não há divergência dos valores numéricos conferidos. | observação || Corrigido. `gerar_pagina.py` data cada medida pela execução que a produziu (`data_da_medida`: as entradas refeitas em 09/11 são as que gravaram `bytes_proc`); regenerado: 1.4 diz 08/11, e 4.2, 4.9, 7.1 e 7.4b dizem 09/11, com o selo e o "Confira" do 4.2 concordando. Página republicada (versão 3). |

Evidência de RV0811-2-01: leitura do gerador e extração do texto dos artigos do HTML por
`html.parser.HTMLParser`, sem executar os comandos publicados:

```text
4.2 data 08/11: True data 09/11: True
4.9 data 08/11: True data 09/11: False
7.0 data 08/11: True data 09/11: False
7.1 data 08/11: True data 09/11: False
7.2 data 08/11: True data 09/11: False
7.4b data 08/11: True data 09/11: False
```

O primeiro caso demonstra a contradição no mesmo exercício; os demais exemplificam o selo
fixo aplicado aos blocos reexecutados. Nenhum outro achado foi reaberto.

### 5. Verificações executadas

- Leitura das regras de `CLAUDE.md`, do mapa no README e da skill local
  `.claude/skills/revisao/SKILL.md`; preservação integral do parecer da rodada 1 e das
  respostas do autor. Leitura do diff dos dois commits e das declarações/evidências
  relacionadas aos onze achados, com os confrontos indicados na tabela acima.
- Comando autorizado:

  ```text
  .venv/bin/python -m pytest -q tests/test_oraculo_consumo.py tests/test_composer_cli.py
  ................................                                         [100%]
  32 passed in 0.10s
  ```

  São testes locais; não demonstram paridade real nem execução do `gcp-oraculos` na janela.
- `bash -n data/medicoes/estudo_gcp/limpeza.sh` e
  `git diff --check 1f85574..8fc7185`: sem saída, código 0.
- SHA-256 dos 16 arquivos originais antes da reprodução; cópia para o diretório temporário
  indicado na §2 e execução de `python3 -I gerar_pagina.py` **somente nessa cópia**:

  ```text
  exercícios: 68 · bytes: 87766
  HTML reproduzido idêntico: True
  exercícios HTML: 68
  11.1 igual ao fonte: True
  IDs CONSULTAS = JSON: True
  selos: {'não rodado por mim': 4, 'rodou adaptado, fora do Cloud Shell': 6, 'rodou fora do notebook': 3}
  ```

  A identidade foi comparada em bytes; o texto “bytes” da primeira linha é a saída literal
  do gerador. O original não foi regenerado.
- Análise de sintaxe em memória dos sete fontes Python e dos quatro snippets Python
  publicados, retirando apenas as linhas mágicas `%pip` para analisar os snippets.
  Confronto das **51 entradas**, todas com `ok: true`, com os IDs declarados; verificação
  dos bytes exatos, estatísticas da materialized view, amostras dos blocos 4/7 e das
  interpretações alteradas de ML. Conferência das saídas literais adicionadas em
  `evidencias/`, inclusive 1.137.600 milli-DCU-segundos = 0,316 DCU-hora, arredondados
  para 0,32 na página. Esses são exames dos registros recebidos, não medições remotas
  novas.
- **Duas páginas oficiais consultadas**, sem outras páginas externas: a referência de
  [AI.GENERATE, controle de custo](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-generate#manage_inference_costs),
  que recomenda materializar a entrada para limitar as linhas inferidas; e a referência de
  [spark_partition_id](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.functions.spark_partition_id.html),
  que documenta suporte a Spark Connect desde 3.4.0. Não foram revalidados preços,
  disponibilidade dos modelos nem outros comportamentos dos serviços.

Não foram executados `make`, Docker, gcloud, bq, Terraform, dbt, `uv sync`, serviços,
consultas a banco ou comandos da página contra GCP; não foi lido conteúdo de `.env`.
Terminate/delete de 11.1, itens de console, notebook/Cloud Shell, estado final dos recursos,
faturamento e publicação privada permanecem não exercitados por este revisor. A página
declara os limites operacionais pertinentes; sua falta de execução não foi convertida
em achado. O parecer não altera a infraestrutura nem encerra pendências do Owner.

