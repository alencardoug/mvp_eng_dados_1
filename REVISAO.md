# Revisão da entrega

> Dossiê gerado por `.claude/skills/revisao/dossie.py`. **Transitório**: sai no *commit*
> que fecha a revisão. Não é documentação do projeto e não entra no mapa do README.
>
> **É um convite, não uma ordem.** Ele não substitui o que o Owner pediu nesta sessão: se
> o pedido foi implementar, implemente — este arquivo continua aqui esperando quem revisar.

## 1. Escopo

Intervalo: `33d6451..6d93d72` — leia o diff, ele não é repetido aqui.

Os dois extremos são SHA fixos de propósito: um dossiê que dissesse `..HEAD` passaria a
descrever outro intervalo no primeiro *commit* seguinte, sem que a lista abaixo mudasse.

```
9705aaf feat: compara o conteúdo gerado em memória com o das origens (T1 e T2 da v1.1.0)
284e8f1 refactor: reúne num módulo os multiplicadores de preço do gerador
0be7921 feat: declara a árvore de categorias no geracao.yml
c7be31c feat: dá a cada folha do catálogo a sua faixa de preço, com sorteio log-uniforme
0b8a33c feat: lança cada produto vendido antes da primeira venda dele (invariante 14)
94e0d09 fix: leva à P09 o valor capturado, que a view lia das autorizações
c272104 feat: refaz M7 a M9 sobre a geração em memória (H3 da v1.1.0)
345a6a0 feat: abre o livro retido da memória do legado, com épocas (T4 e H8 da v1.1.0)
37da7a0 feat: registra cada tentativa de captura do legado antes de qualquer build (H6 da v1.1.0)
1b636ab feat: resolve as capturas pendentes do legado numa fase de recuperação registrada (H7 da v1.1.0)
c205710 docs: registra ADR-0050 — guardar a memória do legado num livro retido, com recuperação registrada
d589eff feat: faz a restauração abrir a sua época no livro retido (H8 da v1.1.0)
8d35ab9 feat: registra no livro retido o tratamento corrente e as rejeitadas dele (T4 da v1.1.0)
27deb9f feat: confere a memória do legado contra o livro retido (T3 da v1.1.0)
61b9f4a feat: aceita no oráculo da memória exatamente as remoções do legado que o Owner aceitou (H2)
592e2cc docs: regenera os derivados que a 1.5 deixou para trás
1ae0b11 feat: compara no H2 o estado real do legado, com o diário de mutações
59f1384 feat: aceita no T3 as chaves do legado que voltam à origem, como o Owner aceitou
6d93d72 fix: leva o teste da P09 para as fronteiras da DAG, com a guarda que faltou
```

## 2. Mapa de revisão

Onde gastar esforço. **Erro em derivado é sintoma: corrige-se na declaração.**

### Escritos à mão — 46 arquivos

- `.env.example`
- `Makefile`
- `README.md`
- `airflow/dags/fluxo_batch.py`
- `dbt/models/consumption/_consumption__models.yml`
- `dbt/models/consumption/payment_approval_rate_by_method.sql`
- `dbt/tests/invariante_14_lancamento_antes_da_venda.sql`
- `dbt/tests/p09_capturado_reconcilia_com_a_fato.sql`
- `docker/docker-compose.airflow.yml`
- `docs/adr/0050-guardar-a-memoria-do-legado-num-livro-retido.md`
- `docs/adr/README.md`
- `docs/arquitetura.md`
- `docs/capacidade_e_recuperacao.md`
- `docs/dicionario_de_dados.md`
- `docs/execucao_local.md`
- `docs/geracao_de_dados.md`
- `docs/modelo_de_dados.md`
- `docs/origem_legada.md`
- `docs/qualidade_de_dados.md`
- `src/mvp_ed1/airbyte.py`
- `src/mvp_ed1/generator/config.py`
- `src/mvp_ed1/generator/domains/catalogo.py`
- `src/mvp_ed1/generator/domains/vendas.py`
- `src/mvp_ed1/generator/geracao.yml`
- `src/mvp_ed1/generator/pipeline.py`
- `src/mvp_ed1/generator/pricing.py`
- `src/mvp_ed1/generator/providers.py`
- `src/mvp_ed1/generator/rng.py`
- `src/mvp_ed1/legacy/captura.py`
- `src/mvp_ed1/recovery/capture_recovery.py`
- `src/mvp_ed1/recovery/ledger.py`
- `src/mvp_ed1/recovery/memory_oracle.py`
- `src/mvp_ed1/recovery/realism.py`
- `src/mvp_ed1/recovery/sources.py`
- `tests/test_captura_legado.py`
- `tests/test_carga.py`
- `tests/test_dbt.py`
- `tests/test_identidade_captura.py`
- `tests/test_invariantes.py`
- `tests/test_ledger.py`
- `tests/test_legado_remocao.py`
- `tests/test_oraculo_da_memoria.py`
- `tests/test_portoes_da_captura.py`
- `tests/test_realism.py`
- `tests/test_recuperacao_da_captura.py`
- `tests/test_sources.py`

### Gerados — 0 arquivos, revisar por amostragem

- `(nenhum)`

**Contexto.** Este é o **lote 1 de 3** da revisão da v1.1.0 inteira, decidida pelo Owner em
04/11/2026: lotes por risco, cada um no esforço máximo, e a *tag* `v1.1.0` só depois do último. O
lote 2 (`26b58b3..1e197ac`, etapas 1.1–1.3) e o lote 3 (`1e197ac..33d6451`, 1.7–1.8) vêm depois. A
1.9 (`6d93d72..13f1e69`) já foi revisada em três rodadas. A trilha de estudo (`3ae4ba2..26b58b3`)
fica fora, também por decisão do Owner. **Não amplie o escopo:** o que estiver fora vira
`observação`.

Este lote é a etapa 1.5 do [plano do `bi-como-codigo`](https://github.com/alencardoug/bi-como-codigo/blob/3c9ab4e/PLAN.md#62-the-stages)
— as três correções do gerador, a invariante 14, a correção da P09 (D67) — e as ferramentas T1–T4 e
os portões H6–H8 do [roteiro de regeneração](https://github.com/alencardoug/bi-como-codigo/blob/3c9ab4e/docs/regeneration_runbook.md),
mais o que a regeneração (1.6) corrigiu no caminho: N54, N56 e o `6d93d72`. **O roteiro foi revisado
em nove rodadas, até 28/10/2026; o código que o implementa, escrito de 03 a 04/11, nunca passou por
outro agente.** É aqui que o esforço rende.

**Declaração — revisão integral:**

- `src/mvp_ed1/generator/geracao.yml` — a árvore de categorias (N37), as faixas de preço por folha
  (N38) e o lançamento (N39): todo valor monetário e toda data de lançamento das duas origens nasce
  daqui;
- `docs/adr/0050-guardar-a-memoria-do-legado-num-livro-retido.md` — o único componente novo, com a
  contrapartida no GCP;
- `airflow/dags/fluxo_batch.py` — as duas tarefas novas, `retomar_capturas_do_legado` e
  `registrar_captura_do_legado`, e a ordem delas em relação ao `dbt_seed`;
- `dbt/tests/invariante_14_lancamento_antes_da_venda.sql` e
  `dbt/tests/p09_capturado_reconcilia_com_a_fato.sql` — os dois testes que viram contrato;
- `dbt/models/consumption/payment_approval_rate_by_method.sql` — a regra da D67 (o capturado de
  cada pagamento no grupo da primeira autorização aprovada, uma vez só).

**Código de maior risco — revisão integral, apesar de ser código:** `src/mvp_ed1/recovery/ledger.py`
(publicação que nunca substitui, épocas, portão), `capture_recovery.py` (a fase de recuperação H7,
com a barreira e os locks), `memory_oracle.py` (o T3, que decide se a memória sobreviveu) e
`legacy/captura.py` (os locks de abertura e de tentativa, a carência). Um defeito aqui deixa a
memória do legado — o que nenhuma reconstrução refaz — sem prova de integridade, ou bloqueia a
captura.

**Derivado — por amostragem:** os trechos gerados de `docs/dicionario_de_dados.md` e
`docs/modelo_de_dados.md`, refeitos por `make catalog` (`592e2cc`); o resto dos documentos. Os
testes repetitivos de `tests/` também, por amostragem — exceto as contraprovas do T3 e da
recuperação, que provam o oráculo.

## 3. O que foi medido

Saída literal, não resumo. Comando sem saída aqui não é medição.

### `make check` ✓

```
........................................................................ [ 87%]
........................................................................ [ 95%]
.......................................                                  [100%]
=========================== short test summary info ============================
SKIPPED [1] tests/test_carga.py:52: substitui a origem pela carga reduzida; rode por `make test-carga`, que exporta MVP_TESTE_CARGA=1 num banco efêmero
SKIPPED [1] tests/test_fato_incremental.py:105: escreve na fato de trabalho; rode `make test FATO=1` (MVP_TESTE_FATO=1)
SKIPPED [1] tests/test_legado_remocao.py:597: sem mutações no diário: a prova entre capturas ainda não aconteceu
900 passed, 3 skipped in 379.36s (0:06:19)
check: as quatro etapas passaram
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `position` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
aviso: model.mvp_ed1.legacy_classifications: origem `c` de `name` não encontrada; tratada como técnica
```

## 4. O que NÃO foi verificado

A seção mais útil do dossiê, e a que o autor tem menos vontade de escrever.
Toda afirmação sem saída de comando na seção 3 pertence aqui.

**O `make check` acima rodou sobre a ponta atual (`13f1e69`), não sobre `6d93d72`.** A diferença
entre as duas é a 1.9, já revisada: 900 testes agora, contra os 886 do G7 da 1.6 sobre `6d93d72`.
A execução real deste lote na máquina é a regeneração inteira, registrada no diário
`data/medicoes/diario_v1_1_0.md` (fora do Git), com as saídas em `data/medicoes/v1_1_0/`.

Exercitado de verdade na 1.6, e só uma vez cada: o portão da CLI (D2, G7) e o da DAG (F3, as duas
tentativas — inclusive a que falhou depois de registrar); a abertura de época pela linha de base
(A8) e pela restauração (G7); o T3 contra o livro inteiro (D4 a2, F6); o H2 sobre o estado real; o
re-base e o contador de *jobs* no G7.

**Nunca exercitado fora dos dublês dos testes:**

- **o ramo da recuperação que resolve e publica tentativas pendentes.** Em todo chamador da 1.6
  ela não tinha nada devido (D2, F3 a2, G7). Uma tentativa interrompida antes do *job*, a carência
  de uma hora (`CARENCIA_SEM_JOB`), a reconciliação de uma tentativa sem *job id* contra a listagem
  do Airbyte e a parada por chamador vivo só existem em `tests/test_recuperacao_da_captura.py`;
- **dois chamadores de captura vivos ao mesmo tempo** — a limitação declarada N35 (CLI durante
  uma DAG, duas DAGs); os locks foram testados por estrutura, não sob corrida real;
- **uma restauração repetida**, que abriria outra época;
- a falha do produtor no meio (§5.3 do roteiro), lida do código;
- a macro `GARANTIR_LIVRO_NO_ENV` (`Makefile`) acrescentando `LEGACY_LEDGER_DIR` ao `.env` sozinha:
  na P10 a linha foi escrita à mão com o texto dela;
- **o T3 confere por chave, não por conteúdo, as linhas da linha de base que restam** depois de
  reaparições aceitas, porque a linha de base guarda o *digest* do conjunto, não por linha. A lacuna
  foi fechada para este ciclo por uma sonda à parte (`D4_a2_sonda_99001.py`); no código ela continua.

**Não medido:**

- o custo do T3 e da fase de recuperação com muitas capturas: a 1.6 tinha 31 a 34;
- quanto do tempo a mais da restauração vem do livro retido (Capacidade §2.13, item 2);
- a calibração de `realism.py` (M7–M9 em memória) contra outra semente que não a do projeto.

## 5. Premissas sobre o ambiente

O que foi assumido sobre ferramenta, banco ou serviço e **não** foi confirmado nesta
entrega. É a classe de erro que passa por revisão de código sem ser vista.

- **O livro publica por `os.link`** do temporário para o nome final, que falha se o nome existe
  (`ledger.py`, `publish`), com `fsync` do arquivo e do diretório. Supõe um sistema de arquivos com
  *hard links* e `link` atômico — o do *host* e o do *bind mount* do Airflow (F2 conferiu só que é
  gravável pelo uid 1000). Não conferido para outros sistemas de arquivos.
- **Os locks são *advisory locks* do PostgreSQL com `hashtext(:a)`** (`captura.py`), um *hash* de
  32 bits: duas tentativas distintas podem colidir no mesmo lock. Assumido como aceitável pelo
  volume (dezenas de tentativas); não medido.
- **A listagem de *jobs* do Airbyte** tem os campos que a M35 leu (`connectionId`, `jobType`,
  `status`, `startTime`) e cabe abaixo do limite que o código recusa quando cheia (A8); conferido
  só contra o Airbyte 2.3.0 instalado.
- **A sequência `public.jobs_id_seq`** do banco do Airbyte é o contador de *jobs* (D50): medido no
  G7, versão 2.3.0.
- **O gerador é determinístico por semente**, inclusive com o sorteio log-uniforme novo: medido em
  memória (A7: "0 tabelas mudam" contra o H1), não entre máquinas ou versões de Python.

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

**Esta revisão precisa só dos três bancos**, para ler o estado real em sessão somente leitura
(`~/Projetos/bi-como-codigo/evidence/20261022/ro.sh`, com `ENG_DADOS_DIR` neste *checkout*), e dos
arquivos fora do Git:

- `data/memoria_do_legado/` — o livro retido real: `epoch_0001_…` (a da regeneração, com a linha de
  base, as tentativas 59, 62 e 64 e os registros de tratamento) e `epoch_0002_…` (a aberta pela
  restauração, com a 67). **Somente leitura**: o livro nunca substitui um registro, e uma escrita de
  revisão ficaria nele para sempre;
- `data/medicoes/diario_v1_1_0.md` e `data/medicoes/v1_1_0/` — o que rodou na máquina;
- `data/recovery/aprovado/` — o pacote v1.1.0.

Estado encontrado: os três bancos e o Airflow de pé, a DAG `fluxo_batch` **despausada** (só disparo
externo — não dispare), Airbyte e *streaming* pausados. Captura selecionada: 67.

**Pode rodar:** `make memory-oracle`, que é somente leitura ([Execução Local](docs/execucao_local.md)), com os arquivos de aceite do D4 a2 e o livro de capturas de `data/medicoes/v1_1_0/`. **Nunca, nesta revisão:** `ledger-baseline`,
`ledger-attempt`, `ledger-treatment`, `sync-legacy` e qualquer `recovery-*` além de
`recovery-verify` **escrevem no livro ou nos bancos**.

## 7. Onde hesitei

Decisões que poderiam ter ido para o outro lado, com o motivo de terem ido para este.

- **N54 e N56: aceitar e declarar**, as duas por decisão do Owner. As 10 chaves que a correção do
  sorteio tirou do legado e as 3 que a recarga devolveu entram no T3 por arquivo explícito
  (`REMOCOES_ACEITAS=`, `REAPARICOES_ACEITAS=`), e não por regra. A alternativa — manter o conjunto
  de chaves do legado no gerador, ou reaplicar o diário de mutações — protegeria a premissa S1 do
  roteiro ("toda diferença é das correções") ao custo de código que só serve a um ciclo. **Vale
  conferir se o T3 aceita exatamente essas chaves, e não um superconjunto.**
- **O H2 passou a comparar o estado real** (lote mais o diário de mutações, `1ae0b11`) depois de o
  T3 falhar no D4. Antes comparava lotes. É uma correção de desenho no meio da execução, feita com
  a linha parada.
- **A guarda da etiqueta `fronteira` (`6d93d72`)** lê o *manifest* e acusa teste com pais em mais de
  uma tarefa da DAG sem a etiqueta. Ficou de fora, de propósito, `invariante_09_transicoes_de_estado_validas`
  (*seed* + `trusted`): seguro porque a *seed* vem antes e `dbt seed` não roda teste. Se a exceção
  está bem cercada é pergunta legítima.
- **A faixa de preço por folha com sorteio log-uniforme** (`c7be31c`), e não uniforme: preços de
  varejo se espalham por ordem de grandeza. A escolha muda todo valor monetário.
- **O lançamento sorteado entre o início do período e a primeira venda** (N39), com nulo quando
  desconhecido; a invariante 14 é "nulo, ou lançamento ≤ venda". O nulo é aceito, não corrigido.

---

## Achados da revisão

Preenchido por quem revisa. Um achado por linha, com veredito.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| | | | `bloqueante` · `ajuste` · `observação` | |

