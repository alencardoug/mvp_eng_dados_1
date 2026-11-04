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
| RVL1-01 | `src/mvp_ed1/recovery/memory_oracle.py:260` | **T3 declara memória contida com a memória histórica adulterada após uma reaparição aceita.** O retorno antecipado dispensa todo conteúdo das linhas restantes da linha de base. Com o arquivo real de aceite da N56, alterar `last_payload` e `rows_last_seen` de `customers/99001` mantém `check(...) == []`. A sonda avulsa da regeneração não fecha a lacuna no oráculo reutilizável. É preciso conservar/comparar uma expectativa de conteúdo por chave, ou recusar a afirmação de integridade quando ela não puder ser provada; a alteração do formato/protocolo cabe ao Owner. Evidência E1. | `bloqueante` | **Corrigido em `ae74356`** — decisão do Owner (04/11): recalcular do bruto, sem mudar o formato do livro. Reproduzido com a tua sonda E1. O T3 recalcula a memória de exclusões do bruto retido, que ele já prova contra o livro, pela regra do ADR-0045 em Python e sem o SQL do modelo (`expected_deletion_rows`), e compara cada linha inteira (`deletion_content_problems`). Sem o recalculado, "o conteúdo não se prova" é problema. **No armazém real, somente leitura:** reproduz as 11 linhas inteiras em 1,3 s; adulterar em memória `last_payload` + `rows_last_seen` da 99001 é acusado. **T3 real refeito sobre o livro, época 0002:** `20261104T174734Z_t3_ae74356.json`, `ok` sem problemas nem notas, árvore limpa. Integração: `test_a_memoria_recalculada_do_bruto_e_a_do_modelo_e_acusa_o_conteudo_adulterado` (alias, sem identidade, remoção de duas linhas). A tua E1 agora falha nos cinco casos. |
| RVL1-02 | `src/mvp_ed1/recovery/memory_oracle.py:266` | **As dez remoções aceitas pela N54 têm apenas suas chaves conferidas, nunca seu conteúdo.** Mesmo sem reaparições, a comparação do digest seleciona somente linhas que já estavam na linha de base. Alterar payload e `removed_in_snapshot_id` de uma das dez mantém T3 verde. Aceitar uma remoção não autoriza qualquer memória sobre ela: falta uma expectativa independente dos atributos e das capturas que explicam a remoção. E1 também confirma que as chaves extras e as aceitas ausentes são recusadas; o defeito é de conteúdo. | `bloqueante` | **Corrigido em `ae74356`**, pelo mesmo recálculo: cada uma das dez remoções da N54 tem o conteúdo esperado próprio, vindo do bruto. Sobre o dado real, adulterar `last_payload` + `removed_in_snapshot_id` de `inventory_balances/145` é acusado, e duplicar o *payload* de `146` também. Offline: `test_conteudo_adulterado_com_a_chave_intacta_e_acusado` (5 campos). |
| RVL1-03 | `src/mvp_ed1/recovery/capture_recovery.py:336` e `:347` | **H7 adota a adulteração de um certificado pendente já registrado e pode certificá-lo incorretamente.** Não compara o estado lido com `estado.rows` antes de `retomar`; publica a transição sobre o valor adulterado e a barreira compara somente com esse novo registro. No probe de 40 tabelas, trocar `source_hash_before` pelo hash atual produziu `complete` e barreira vazia, embora o valor retido exigisse `unstable`. T3 acusa a troca posteriormente, mas a recuperação já liberou a próxima captura/build. Comparar o certificado com o registro anterior antes de qualquer transição; divergência deve parar sem ser adotada, conforme N34. Evidência E2; um único chamador, sem corrida entre capturadores. | `bloqueante` | **Corrigido em `2a73690`**, pela N34. Reproduzido (E2). Antes de retomar, uma pendente cujo certificado difere do último registro dela no livro para (`RecoveryStopped`), sem que a diferença seja adotada: nada se retoma e nenhuma transição é publicada. É a mesma comparação canônica que a barreira faz no passo 3, só que antes. `test_certificado_adulterado_depois_do_registro_para_sem_ser_adotado`. |
| RVL1-04 | `src/mvp_ed1/recovery/capture_recovery.py:350` | **A transição perde a medição do job associado apenas no livro.** A tentativa interrompida antes de `registrar_job` ganha `associated_job` e bruto no primeiro registro, mas `attempt_record(..., kind=TRANSITION)` não recebe essa associação. Publica `raw=None`; H7 passa e T3 recusa uma recuperação íntegra com “o registro não mediu as linhas do job 9”. Propagar a associação e medir novamente o mesmo job na transição; exercitar a recuperação seguida do T3 no mesmo teste. Evidência E2. | `ajuste` | **Corrigido em `2a73690`.** A associação, nova ou já guardada no livro, vai também na transição (`associated_job`), que mede de novo o mesmo *job*. Com a tua E2: transição com `raw`, T3 com 0 problemas. `test_a_transicao_leva_o_job_associado_e_o_t3_aceita_a_recuperacao_integra`, que encadeia a recuperação com o T3, como pediste. |
| RVL1-05 | `src/mvp_ed1/recovery/capture_recovery.py:259`; `tests/test_recuperacao_da_captura.py:252` | **A janela compara precisão de microssegundos com a listagem real em segundos.** Um job criado no mesmo segundo do `started_at`, mas depois dele, aparece antes do limite inferior quando `startTime` não traz fração. O dublê usa `datetime.now().isoformat()` e não reproduz isso. No probe, o job `running` foi ignorado, a tentativa foi registrada e abandonada; só a barreira final parou pelo job sem dono. Tratar a precisão temporal e sua ambiguidade antes de escrever registros ou abandonar; não ampliar silenciosamente a janela a ponto de associar outro job. Evidências E2 e E3. | `ajuste` | **Corrigido em `2a73690`.** Um `startTime` sem fração é tratado como o segundo inteiro `[s, s+1s)`: dentro da janela é candidato, fora não, e **atravessando um limite — início ou fim — para**, antes de registrar ou abandonar, sem alargar a janela. Com a tua E2: parou, o certificado segue `pending` e só a linha de base está no livro. 5 casos de precisão em `test_reconcile_trata_a_precisao_do_inicio_do_job` e `test_o_fim_da_janela_tambem_e_limite`. **Custo aceito:** nesse caminho raro (tentativa sem *job* depois da carência, com o *job* no mesmo segundo), a recuperação para para o Owner em vez de associar. |
| RVL1-06 | `src/mvp_ed1/recovery/ledger.py:485` | **T4 manual permite um segundo primeiro registro da mesma tentativa.** Dois `operator_record` com a mesma tentativa e nomes diferentes retornam sucesso e publicam dois registros `attempt`. O runbook §5 exige recusar uma tentativa que a época já guarda; a unicidade do nome de arquivo não cumpre essa regra. Conferir a identidade da tentativa no conteúdo dos registros, sob o lock. Evidência E1. | `ajuste` | **Corrigido em `e50e859`.** Sob o lock, `operator_record` lê a época e recusa a tentativa que ela já guarda (pelo conteúdo, via `held`: linha de base, `attempt` ou `transition`). A tua sonda: o segundo nome é recusado. `test_registro_manual_nao_reabre_tentativa_que_a_epoca_guarda`. |
| RVL1-07 | `src/mvp_ed1/recovery/ledger.py:147` e `:184` | **Uma publicação pode retornar sucesso e ficar invisível ao livro.** `publish` aceita `D2_a1_memoria` sem extensão, enquanto `records` só lê `.json`. O arquivo existe e tem SHA, mas a tentativa não entra na leitura usada por H7/T3; os comandos manuais repassam `--name` sem validar. Recusar nomes que o leitor ignora ou uniformizar publicação e leitura. Os nomes gerados pelos portões já têm `.json`. Evidência E4. | `ajuste` | **Corrigido em `e50e859`.** `publish` recusa nome sem `.json`, o único que `records` lê. Os nomes dos portões, da recuperação, da linha de base e os do runbook já têm `.json`. `test_nome_que_a_leitura_ignoraria_e_recusado` (3 nomes). |
| RVL1-08 | `src/mvp_ed1/recovery/ledger.py:449` | **O portão mede o bruto antes de confirmar que o job pendente terminou.** Se a sincronização termina entre `attempt_record` e `job_state`, publica como definitivo um retrato parcial. O probe publicou uma linha quando o job final já tinha duas. Isso pode ocorrer após falha/timeout da tarefa de sincronização, quando o portão `all_done` encontra o certificado pendente. Confirmar o estado final antes da medição que será publicada; depois o T3 detecta a divergência, mas o registro imutável já nasceu incorreto. Evidência E5. | `ajuste` | **Corrigido em `e50e859`.** Com o certificado pendente, o portão consulta o estado do *job* e, só se final, toma o retrato de novo, conferindo que o *job* é o mesmo. A tua E5: "bruto registrado: 2 bruto final: 2". `test_o_portao_mede_o_bruto_depois_de_o_job_estar_final`. |
| RVL1-09 | `src/mvp_ed1/recovery/memory_oracle.py:37`; `../bi-como-codigo/docs/regeneration_runbook.md:52` | **O histórico SCD citado no pedido não está na garantia implementada do T3.** O runbook o exclui expressamente: os quatro snapshots são substituídos na regeneração e sobrevivem nos pacotes. O código segue esse recorte. Registro a diferença para decisão do Owner, sem ampliar o lote nem classificar como defeito de implementação uma exclusão explícita do desenho. Evidência E6. | `observação` | **Mantido fora e declarado** — decisão do Owner (04/11). Origem Legada §4.3, no item novo do oráculo: o SCD fica fora da garantia do T3 por desenho, e é o manifesto do pacote que o protege, com o *digest* canônico de cada *snapshot*. |
| RVL1-10 | `src/mvp_ed1/legacy/captura.py:90` | **A colisão de `hashtext` é reproduzível para IDs com o formato usado pelas tentativas.** A consulta somente leitura encontrou dois IDs hexadecimais distintos de 32 caracteres com chave `-270689899`. Compartilham o lock; o efeito esperado é espera/recusa indevida, não permitir abandono através de um lock ocupado. Não foi induzida colisão entre tentativas reais nem medida sua frequência no volume do projeto. A aceitação desse limite continua com o Owner; N35 não foi reaberta. Evidência E7. | `observação` | **Aceito e declarado** — decisão do Owner (04/11). Origem Legada §4.3: 32 bits, a tua evidência (dois IDs reais), efeito só de espera ou recusa, aceito pelo volume. Os locks não mudam. |

## Evidências da revisão — lote 1

Revisão executada em 04/11/2026 sobre `add459cd9addca7bea8d2c5892bb244451a0e4ad`, mantendo o
intervalo de avaliação `33d6451..6d93d72`. Os três módulos de recuperação, `legacy/captura.py`,
o gerador, a DAG e os SQLs citados não diferem do topo do lote. No chamador `airbyte.py`, a mudança
posterior é a mensagem “recuperação: nada devido”; ela não altera o protocolo examinado.

Os probes abaixo usam dados sintéticos em memória e diretórios temporários; os arquivos do livro
real foram apenas lidos. Nenhuma captura, recuperação mutante, restauração, seed ou tarefa da DAG
foi executada. Nenhuma correção foi implementada. As colunas **Situação** ficam vazias para a
resposta do autor/Owner. Os dois arquivos não rastreados já presentes (`GEMINI.md` e
`NAVEGANDO_GCP/parecer_migracao_gcp.md`) foram preservados.

### E1 — exclusões aceitas e registro manual repetido (RVL1-01, RVL1-02 e RVL1-06)

As chaves de aceite e a interseção da N56 vêm dos arquivos reais. O restante do estado é um
modelo mínimo: a linha de base tem os três clientes que reaparecem e `customers/99001`; o bruto
e o certificado vazios isolam a conferência das exclusões. O probe chama o **`check` completo**,
não uma reimplementação de sua decisão. A segunda parte substitui somente a leitura do banco e
o lock; publicação e escolha da época são reais, em `/tmp`.


Comando: `.venv/bin/python -B /tmp/rvl1_memory.py` (saída 0). Para reproduzir, salve o bloco abaixo nesse caminho.

```python
import copy
import json
from pathlib import Path
from mvp_ed1.recovery import memory_oracle as mo, ledger, oraculos

def row(table, key, payload='original'):
    return dict(source_table=table, business_key=key, last_seen_snapshot_id=55,
                removed_in_snapshot_id=59, rows_last_seen=1, last_payload=[{'name':payload}])

def world(old, now):
    base=dict(kind='baseline', format=1, captures={}, certificate={'rows':[]},
              deletions={'linhas':len(old), 'digest':oraculos.digest(old)},
              deletion_keys=[[r['source_table'],r['business_key']] for r in old])
    mem=mo.Memory(certificate={}, captures={}, certified=[], received={}, selected=None,
                  quarantine=None, quarantine_by_table={}, classification=None, versions=[],
                  deletions={'linhas':len(now), 'digest':oraculos.digest(now)}, deletion_rows=now)
    return [base],mem

h2=json.loads(Path('data/medicoes/v1_1_0/D4_a2_h2_estado_real.json').read_text())
removed=mo.accepted_removals(h2)
added=mo.accepted_reappearances(h2)
base_real=json.loads(next(Path('data/memoria_do_legado').glob('epoch_0001_*/baseline.json')).read_text())
print('N54:',sorted(removed))
print('N56 efetiva:',sorted(added & {tuple(k) for k in base_real['deletion_keys']}))
old=[row('customers',k) for k in ('1','2','3','99001')]
new=[row(t,k) for t,k in sorted(removed)]
good=[old[-1],*new]
rs,mem=world(old,good)
print('controle:',mo.check(rs,mem,remocoes_aceitas=removed,reaparicoes_aceitas=added))
mem.deletion_rows=copy.deepcopy(good)
mem.deletion_rows[0]['last_payload']=[{'name':'ADULTERADO'}]
mem.deletion_rows[0]['rows_last_seen']=999
mem.deletions={'linhas':len(good),'digest':oraculos.digest(mem.deletion_rows)}
print('baseline customers/99001 adulterada:',mo.check(rs,mem,remocoes_aceitas=removed,reaparicoes_aceitas=added))
rs,mem=world(old,[*good,row('customers','99999')])
print('chave extra:',mo.check(rs,mem,remocoes_aceitas=removed,reaparicoes_aceitas=added))
rs,mem=world(old,good[:-1])
print('chave aceita ausente:',mo.check(rs,mem,remocoes_aceitas=removed,reaparicoes_aceitas=added))
rs,mem=world(old,[*old,*new])
mem.deletion_rows[-1]['last_payload']=[{'name':'ADULTERADO'}]
mem.deletion_rows[-1]['removed_in_snapshot_id']=-999
mem.deletions={'linhas':len(mem.deletion_rows),'digest':oraculos.digest(mem.deletion_rows)}
print('N54 payload e snapshot adulterados (sem reaparição):',mo.check(rs,mem,remocoes_aceitas=removed))

# T4 manual: um segundo nome não pode reabrir o primeiro registro da mesma tentativa.
from tempfile import TemporaryDirectory
from unittest.mock import patch
from contextlib import nullcontext
from mvp_ed1.legacy import captura
with TemporaryDirectory(prefix='rvl1-') as td:
    p=Path(td)
    ledger.open_epoch(p, {'format':1,'kind':'baseline','captures':{},'certificate':{'rows':[]}})
    rec={'format':1,'kind':'attempt','capture_attempt_id':'a','certificate':{'rows':[]}}
    with patch.object(ledger,'attempt_record',return_value=rec), patch.object(captura,'bloqueio_da_tentativa',return_value=nullcontext()):
        first=ledger.operator_record(None,'a','D2_a1_memoria.json',environ={ledger.ENV:td})
        second=ledger.operator_record(None,'a','D2_a2_memoria.json',environ={ledger.ENV:td})
    print('T4 mesma tentativa, nomes distintos:',first.path.exists(),second.path.exists())
```

Saída literal:

```text
N54: [('inventory_balances', '145'), ('inventory_balances', '146'), ('inventory_movements', '2288a42a-b7b2-443a-ae49-d8076f49e423'), ('inventory_movements', '29311a0f-b5ed-4361-93d8-19f8769699fe'), ('inventory_movements', '42211726-bb89-4903-a29d-84ba5b2a8224'), ('inventory_movements', '841f5b32-74b2-42b3-b18c-3a690bdfa1e1'), ('inventory_movements', 'a0f9002c-9ed2-446d-b5f7-7363f786f57c'), ('inventory_movements', 'c8a2ecd0-15a0-45f9-a1fc-fb2275ad4f2b'), ('inventory_movements', 'ee64e872-4397-4ec8-82aa-ef2af75fc0e2'), ('inventory_movements', 'eeaa9bcb-0a2e-40bf-8ccc-15be9d8e4361')]
N56 efetiva: [('customers', '1'), ('customers', '2'), ('customers', '3')]
controle: []
baseline customers/99001 adulterada: []
chave extra: ["memória de exclusões: faltam [] e sobram [('customers', '99999')] (0 e 1)"]
chave aceita ausente: ["memória de exclusões: faltam [('inventory_movements', 'eeaa9bcb-0a2e-40bf-8ccc-15be9d8e4361')] e sobram [] (1 e 0)"]
N54 payload e snapshot adulterados (sem reaparição): []
T4 mesma tentativa, nomes distintos: True True
```

### E2 — recuperação real com adaptador em memória (RVL1-03, RVL1-04 e RVL1-05)

Rodam as implementações de `recover`, `retomar`, `concluir`, `_publicar`, `_abandonar`,
`attempt_record`, `held`, `barrier` e `check`. Foram substituídos a conexão SQL, as leituras e
medições do banco, o lock e as respostas do Airbyte. O adaptador conserva as 40 linhas e aplica
os UPDATEs emitidos; os registros são publicados de verdade em diretórios temporários.
Não modela rollback, concorrência do PostgreSQL ou transporte HTTP; nenhum desses efeitos é
necessário para os três contraexemplos. No caso temporal, o chamador anterior já morreu, o job
permanece `running`, sem linhas recebidas, e a recuperação ocorre após duas horas.

Comando: `.venv/bin/python -B /tmp/rvl1_recovery.py` (saída 0). Para reproduzir, salve o bloco abaixo nesse caminho.

```python
import copy
import datetime as dt
import json
from contextlib import nullcontext, ExitStack
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
from mvp_ed1.legacy import captura, schema
from mvp_ed1.recovery import capture_recovery as rec, ledger, memory_oracle as mo

UTC=dt.timezone.utc
start=dt.datetime(2026,11,4,10,0,0,500000,tzinfo=UTC)
now=start+dt.timedelta(hours=2)
tables=schema.tabelas()

def pending(job):
    return [dict(capture_attempt_id='a',source_table=t,connection_name='legacy_para_raw_legacy',
                 started_at=start,job_id=job,snapshot_id=None,status='pending',
                 source_rows_before=1,source_hash_before='original',source_rows_after=None,
                 source_hash_after=None,received_rows=None,received_hash=None,
                 sync_id_matches=None,completed_at=None) for t in tables]

class Result:
    def __init__(self, rows=(), rowcount=0): self.rows,self.rowcount=rows,rowcount
    def all(self): return self.rows
    def __iter__(self): return iter(self.rows)

class DB:
    def __init__(self,rows): self.rows=rows
    def connect(self): return nullcontext(self)
    def begin(self): return nullcontext(self)
    def execute(self,sql,p=None):
        s=str(sql)
        if s.startswith('select source_table, job_id, source_rows_before'):
            return Result([tuple(r[k] for k in ('source_table','job_id','source_rows_before','source_hash_before','status','snapshot_id')) for r in self.rows])
        if s.startswith('select source_table, job_id, status'):
            return Result([tuple(r[k] for k in ('source_table','job_id','status','snapshot_id')) for r in self.rows])
        if "set status = 'abandoned'" in s:
            for r in self.rows: r.update(status='abandoned',completed_at=now)
            return Result(rowcount=len(self.rows))
        if 'set source_rows_after' in s:
            for r in self.rows:
                if r['source_table']==p['t'] and r['status']=='pending':
                    for key,param in [('source_rows_after','na'),('source_hash_after','ha'),('received_rows','nr'),('received_hash','hr'),('sync_id_matches','m'),('status','s'),('completed_at','quando'),('snapshot_id','g')]:
                        r[key]=p[param]
            return Result(rowcount=1)
        raise AssertionError(s)

def scenario(associated, rounded_running=False):
    db=DB(pending(None if associated else 9))
    raw={t:{'rows':1,'digest':'raw','generations':[1]} for t in tables}
    before=copy.deepcopy(db.rows)
    listing=rec.Listing([{'id':9,'type':'sync','status':'succeeded','started_at':(start+dt.timedelta(seconds=2)).isoformat()}],None)
    if rounded_running:
        listing=rec.Listing([{'id':9,'type':'sync','status':'running','started_at':start.replace(microsecond=0).isoformat()}],None)
    def warehouse(_):
        return rec.Warehouse({'a':ledger.canonical_rows(db.rows)},{'a':start},set() if rounded_running else {'9'})
    def cert(_conn, attempt_id=None):
        rows=ledger.canonical_rows(db.rows)
        return {'rows':rows,'count':len(rows),'digest':'fixture'}
    def lines(_conn,query,*args):
        assert 'select distinct job_id' in query
        return [{'job_id':db.rows[0]['job_id']}]
    with TemporaryDirectory(prefix='rvl1-rec-') as td, ExitStack() as stack:
        ep=ledger.open_epoch(Path(td),dict(format=1,kind='baseline',taken_at=(start-dt.timedelta(hours=1)).isoformat(),captures={},certificate={'rows':[]})).path.parent
        stack.enter_context(patch.object(ledger,'_read_only',lambda _:nullcontext(db)))
        stack.enter_context(patch.object(ledger,'certificate_rows',cert))
        stack.enter_context(patch.object(ledger.leitura,'_linhas',lines))
        stack.enter_context(patch.object(ledger,'measure_capture',lambda *_:copy.deepcopy(raw)))
        stack.enter_context(patch.object(rec,'read_warehouse',warehouse))
        stack.enter_context(patch.object(captura,'_pendentes',lambda _: [('a',db.rows[0]['job_id'],start)] if db.rows[0]['status']=='pending' else []))
        stack.enter_context(patch.object(captura,'bloqueio_da_tentativa',lambda *a,**k:nullcontext()))
        stack.enter_context(patch.object(captura,'medir_origem',lambda _: {t:captura.Medida(1,'alterado') for t in tables}))
        stack.enter_context(patch.object(captura,'medir_recebido',lambda _,job: {t:captura.Recebido(1,'alterado',(1,),0) for t in tables}))
        if not associated:
            ledger.publish(ep,'first.json',ledger.attempt_record(db,'a',caller={}))
            for r in db.rows: r['source_hash_before']='alterado'
        try:
            outcome=rec.recover(None,db,job_state=lambda _: 'succeeded',listar=lambda:listing,caller={},environ={ledger.ENV:td},agora=now)
        except rec.RecoveryStopped as e:
            assert rounded_running
            print('job running no mesmo segundo: recuperação parou:',e.problems)
            print('certificado já alterado:',sorted({r['status'] for r in db.rows}))
            print('registros publicados:',sorted(r['kind'] for r in ledger.records(ep)))
            return
        records=ledger.records(ep)
        held=rec.held(records)
        transition=next(r for r in records if r['kind']=='transition')
        certified=[] if associated else [9]
        mem=mo.Memory(certificate=warehouse(None).certificate,captures={'9':raw},certified=certified,
                      received={} if associated else {9:{t:(1,'alterado') for t in tables}},selected=None if associated else 9,
                      quarantine=None,quarantine_by_table={},classification=None,versions=[],deletions=None)
        problems=mo.check(records,mem)
        print('caso:', 'job associado sem job_id' if associated else 'imutável adulterado antes da recuperação')
        print('recover:',outcome['transitions'],'status:',sorted({r['status'] for r in db.rows}))
        print('barreira:',rec.barrier(held,warehouse(None),listing))
        print('transição raw ausente:',transition['raw'] is None)
        print('T3:',len(problems),'problemas; primeiro:',problems[:1])
        if not associated:
            print('veredito com o antes retido:',captura.decidir(captura.Medida(1,'original'),captura.Medida(1,'alterado'),captura.Recebido(1,'alterado',(1,),0)))

scenario(False)
scenario(True)
scenario(True, rounded_running=True)

# O M35 real lista segundos, enquanto o certificado e o dublê usam microssegundos.
w=rec.Warehouse({'a':pending(None)},{'a':start},set())
h=rec.Held(baseline_taken_at=start-dt.timedelta(hours=1))
for stamp in ('2026-11-04T10:00:00.750000Z','2026-11-04T10:00:00Z'):
    listing=rec.Listing([{'id':9,'type':'sync','status':'running','started_at':stamp}],None)
    r=rec.reconcile('a',w,h,listing,now)
    print('reconcile startTime='+stamp, 'job='+str(r.job),'stop='+str(r.stop))
```

Saída literal:

```text
caso: imutável adulterado antes da recuperação
recover: {'a': 'concluida'} status: ['complete']
barreira: []
transição raw ausente: False
T3: 40 problemas; primeiro: ["tentativa a, brands: campo imutável mudou: ['source_hash_before']"]
veredito com o antes retido: unstable
caso: job associado sem job_id
recover: {'a': 'abandonada'} status: ['abandoned']
barreira: []
transição raw ausente: True
T3: 1 problemas; primeiro: ['tentativa a: o registro não mediu as linhas do job 9']
job running no mesmo segundo: recuperação parou: ['job 9 da conexão legada, de depois da linha de base, reivindicado por 0 tentativas']
certificado já alterado: ['abandoned']
registros publicados: ['attempt', 'baseline', 'transition']
reconcile startTime=2026-11-04T10:00:00.750000Z job=9 stop=None
reconcile startTime=2026-11-04T10:00:00Z job=None stop=None
```

### E3 — precisão observada no Airbyte (RVL1-05)

Comando somente leitura:

```bash
cat /home/doug/Projetos/bi-como-codigo/evidence/20261023/q13_airbyte_job_records.out.txt
```

Trecho literal da medição **anterior**, de 23/10; não é uma nova chamada ao Airbyte nesta revisão:

```text
2026-10-23T19:51:08Z
== 1. The listing, through airbyte.jobs: fields and the legacy connection's jobs
listed 18 | fields ['bytesSynced', 'connectionId', 'duration', 'jobId', 'jobType', 'lastUpdatedAt', 'rowsSynced', 'startTime', 'status']
oldest listed 2026-09-25T13:08:01Z
legacy connection jobs listed 6
  2 sync succeeded 2026-09-25T13:11:38Z 12747
  3 sync succeeded 2026-09-25T13:44:50Z 12747
  46 sync succeeded 2026-09-25T15:36:21Z 12744
  49 sync succeeded 2026-09-25T15:55:02Z 12744
  52 sync succeeded 2026-10-04T05:24Z 12744
  55 sync succeeded 2026-10-12T21:41:55Z 12744
[exit 0]
```

O contraexemplo não pressupõe dois chamadores vivos nem job invisível: ele já consta da listagem.
Não foi induzida a interrupção real no mesmo segundo. A associação ambígua deve parar antes do
abandono, não tratar ausência de candidato pelo filtro como prova de ausência de job.

### E4 — publicação, interrupção, temporário e épocas (RVL1-07)

Foi injetada uma exceção no `fsync` do diretório **depois** de o `link` real publicar o arquivo.
A repetição não substituiu o registro. Um temporário órfão não impediu a publicação seguinte.
Isso testa o comportamento do código diante da falha; **não** simula queda de energia ou perda de
metadados pelo sistema de arquivos. A parte final demonstra a publicação invisível ao leitor.

Comando: `.venv/bin/python -B /tmp/rvl1_publish.py` (saída 0). Para reproduzir, salve o bloco abaixo nesse caminho.

```python
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
from mvp_ed1.recovery import ledger

with TemporaryDirectory(prefix='rvl1-publish-') as td:
    root=Path(td)
    ep=ledger.open_epoch(root,{'format':1,'kind':'baseline'}).path.parent
    try:
        with patch.object(ledger,'_sync_dir',side_effect=OSError('crash entre link e fsync')):
            ledger.publish(ep,'a.json',{'kind':'attempt','v':1})
    except OSError as e: print('falha injetada:',e)
    original=(ep/'a.json').read_bytes()
    try: ledger.publish(ep,'a.json',{'kind':'attempt','v':2})
    except ledger.LedgerError: print('retry recusado; original preservado:',(ep/'a.json').read_bytes()==original)
    (ep/'.resto.tmp').write_text('temporário órfão')
    ledger.publish(ep,'b.json',{'kind':'attempt','v':3})
    print('temporário órfão preservado:',(ep/'.resto.tmp').read_text()=='temporário órfão')
    pub=ledger.publish(ep,'D2_a1_memoria',{'format':1,'kind':'attempt','capture_attempt_id':'perdida'})
    print('nome sem .json: publicação retornou; arquivo existe:',pub.path.exists())
    print('nome sem .json: tentativa lida por records:',any(r.get('capture_attempt_id')=='perdida' for r in ledger.records(ep)))
    old=ep
    newer=ledger.open_epoch(root,{'format':1,'kind':'baseline'}).path.parent
    print('época nova selecionada; antiga preservada:',ledger.current_epoch(root)==newer,(old/'a.json').read_bytes()==original)
```

Saída literal:

```text
falha injetada: crash entre link e fsync
retry recusado; original preservado: True
temporário órfão preservado: True
nome sem .json: publicação retornou; arquivo existe: True
nome sem .json: tentativa lida por records: False
época nova selecionada; antiga preservada: True True
```

### E5 — job termina entre medição e consulta de estado (RVL1-08)

`gate` e `publish` são reais. A medição e o observador representam duas leituras sucessivas:
na primeira há uma linha; antes da segunda, o mesmo job recebe a segunda linha e termina.
O lock de tentativa não impede o servidor Airbyte de concluir sua escrita.

Comando: `.venv/bin/python -B /tmp/rvl1_gate.py` (saída 0). Para reproduzir, salve o bloco abaixo nesse caminho.

```python
from contextlib import ExitStack, nullcontext
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
from mvp_ed1.recovery import ledger
from mvp_ed1.legacy import captura

with TemporaryDirectory(prefix='rvl1-gate-') as td, ExitStack() as s:
    root=Path(td)
    ledger.open_epoch(root,{'format':1,'kind':'baseline'})
    state={'rows':1,'status':'running'}
    def measure(*args,**kwargs):
        return {'kind':'attempt','capture_attempt_id':'a','job_id':9,
                'certificate':{'rows':[{'status':'pending'}]},'raw':{'brands':{'rows':state['rows']}}}
    def final(job):
        # A última escrita do único job em curso acontece depois da leitura do portão.
        state.update(rows=2,status='succeeded')
        return state['status']
    s.enter_context(patch.object(ledger,'attempt_record',measure))
    s.enter_context(patch.object(captura,'bloqueio_da_tentativa',lambda *a,**k:nullcontext()))
    published,record=ledger.gate(None,'a',caller={},job_state=final,environ={ledger.ENV:td})
    print('portão retornou; arquivo publicado:',published.path.exists())
    print('bruto registrado:',record['raw']['brands']['rows'],'bruto final:',state['rows'])
```

Saída literal:

```text
portão retornou; arquivo publicado: True
bruto registrado: 1 bruto final: 2
```

### E6 — SCD fora do contrato implementado (RVL1-09)

Comandos somente leitura:

```bash
sed -n '37p' src/mvp_ed1/recovery/memory_oracle.py
sed -n '52p' /home/doug/Projetos/bi-como-codigo/docs/regeneration_runbook.md
```

Saída literal:

```text
O histórico SCD fica fora (runbook §1).
| The SCD history — four snapshots | Dropped by `dbt-build RESET=1` (D3), rebuilt with one version. **Outside the survival claim of T3**: replaced by design | Only in the packages — the snapshots are unchanged since 2026-09-25 (M24); the cut's manifest keeps their oracle for a rollback |
```

### E7 — banco real, somente leitura (RVL1-10 e conferências sem achado)

Comando (saída 0 após liberar o acesso ao socket do Docker):

```bash
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh /tmp/rvl1_read.sql
```

Conteúdo integral do SQL:

```sql
show transaction_read_only;
select count(*) as certificate_rows, count(distinct capture_attempt_id) as attempts,
       count(*) filter(where status='pending') as pending_rows
from governance.legacy_captures;
select * from staging.legacy_selected_capture;
select source_table, business_key, last_seen_snapshot_id, removed_in_snapshot_id, rows_last_seen
from trusted.legacy_removed_records order by 1,2;
select (select sum(captured_amount) from consumption.payment_approval_rate_by_method) as p09,
       (select sum(captured_amount) from analytics.fact_payment_transaction where transaction_type='capture') as fact;
select count(*) as invariant14_violations
from trusted.order_items i join trusted.orders o using(source_system,order_id)
join trusted.product_skus s using(source_system,product_variant_id)
where i.source_system='retail' and s.launched_at>o.placed_at;
with hashed as (select md5(i::text) as attempt_id,hashtext(md5(i::text)) as lock_key from generate_series(1,200000) as g(i))
select lock_key,array_agg(attempt_id order by attempt_id) as attempts
from hashed group by lock_key having count(*)>1 order by lock_key limit 1;
```

Saída literal (omitidos apenas espaços finais de apresentação do psql):

```text
 transaction_read_only
-----------------------
 on
(1 row)

 certificate_rows | attempts | pending_rows
------------------+----------+--------------
              760 |       19 |            0
(1 row)

 snapshot_id
-------------
          67
(1 row)

    source_table     |             business_key             | last_seen_snapshot_id | removed_in_snapshot_id | rows_last_seen
---------------------+--------------------------------------+-----------------------+------------------------+----------------
 customers           | 99001                                |                    36 |                     38 |              1
 inventory_balances  | 145                                  |                    55 |                     59 |              1
 inventory_balances  | 146                                  |                    55 |                     59 |              1
 inventory_movements | 2288a42a-b7b2-443a-ae49-d8076f49e423 |                    55 |                     59 |              1
 inventory_movements | 29311a0f-b5ed-4361-93d8-19f8769699fe |                    55 |                     59 |              1
 inventory_movements | 42211726-bb89-4903-a29d-84ba5b2a8224 |                    55 |                     59 |              1
 inventory_movements | 841f5b32-74b2-42b3-b18c-3a690bdfa1e1 |                    55 |                     59 |              1
 inventory_movements | a0f9002c-9ed2-446d-b5f7-7363f786f57c |                    55 |                     59 |              1
 inventory_movements | c8a2ecd0-15a0-45f9-a1fc-fb2275ad4f2b |                    55 |                     59 |              1
 inventory_movements | ee64e872-4397-4ec8-82aa-ef2af75fc0e2 |                    55 |                     59 |              1
 inventory_movements | eeaa9bcb-0a2e-40bf-8ccc-15be9d8e4361 |                    55 |                     59 |              1
(11 rows)

     p09     |    fact
-------------+-------------
 12720071.75 | 12720071.75
(1 row)

 invariant14_violations
------------------------
                      0
(1 row)

  lock_key  |                              attempts
------------+---------------------------------------------------------------------
 -270689899 | {c76dd3ad639db45fb9ee439db59bb3bd,fdcf9747dcdac7462ccdfeff7c83d9a1}
(1 row)
```

### E8 — guarda da DAG e atribuição da P09, sem novo achado

A guarda não tem dispensa pelo nome da invariante 09: deixa passar seed + trusted por ordem de
construção. O probe chama o teste existente, alterando apenas a leitura do manifest em memória;
adicionar um pai tardio à invariante 09 é recusado, assim como retirar `fronteira` da P09.

Comando: `.venv/bin/python -B /tmp/rvl1_guard.py` (saída 0). Para reproduzir, salve o bloco abaixo nesse caminho.

```python
import copy
import json
import runpy
from pathlib import Path
from unittest.mock import patch

ns=runpy.run_path('tests/test_dbt.py')
test=ns['test_teste_que_atravessa_tarefas_da_dag_nunca_roda_antes_de_um_pai']
test()
print('manifest atual: guarda passou')
p=ns['DBT']/'target'/'manifest.json'
original=Path.read_text
manifest=json.loads(p.read_text())
for name in ('p09_capturado_reconcilia_com_a_fato','invariante_09_transicoes_de_estado_validas'):
    altered=copy.deepcopy(manifest)
    node=next(n for n in altered['nodes'].values() if n['name']==name)
    if name.startswith('p09'):
        node['tags']=[]
    else:
        print('invariante_09 pais atuais:',node['depends_on']['nodes'])
        node['depends_on']['nodes'].append('model.mvp_ed1.payment_approval_rate_by_method')
    def read(self,*a,**k): return json.dumps(altered) if self==p else original(self,*a,**k)
    with patch.object(Path,'read_text',read):
        try: test()
        except AssertionError as e: print(name+': contraprova recusada:',str(e))
        else: print(name+': contraprova passou indevidamente')
```

Saída literal:

```text
manifest atual: guarda passou
p09_capturado_reconcilia_com_a_fato: contraprova recusada: teste que roda numa tarefa da DAG antes da tarefa que constrói um pai dele — leva a etiqueta `fronteira`: [('p09_capturado_reconcilia_com_a_fato', 'analytics', ['consumption'])]
invariante_09 pais atuais: ['seed.mvp_ed1.order_status_transitions', 'model.mvp_ed1.order_status_events']
invariante_09_transicoes_de_estado_validas: contraprova recusada: teste que roda numa tarefa da DAG antes da tarefa que constrói um pai dele — leva a etiqueta `fronteira`: [('invariante_09_transicoes_de_estado_validas', 'trusted', ['consumption'])]
```

A P09 também foi exercitada com duas aprovações em meses distintos, duas capturas parciais e
`payment_id` igual entre retail e legacy. O SQL é o arquivo da view, só com os `ref` resolvidos
para tabelas em SQLite `:memory:`. Isso testa a atribuição e a multiplicidade; a igualdade dos
totais no PostgreSQL real está em E7. Não se usa SQLite para afirmar equivalência geral de dialetos.

Comando: `.venv/bin/python -B /tmp/rvl1_p09.py` (saída 0). Para reproduzir, salve o bloco abaixo nesse caminho.

```python
import re
import sqlite3
from pathlib import Path

db=sqlite3.connect(':memory:')
db.executescript('''
create table fact_payment_transaction(source_system text,payment_id integer,payment_transaction_id integer,
transaction_type text,occurred_at text,date_key integer,payment_method_key integer,installments integer,
is_instalment_plan boolean,authorization_count integer,approved_authorization_count integer,
authorized_amount numeric,captured_amount numeric);
create table dim_date(date_key integer,year_month text,year_number integer,month_number integer);
insert into dim_date values(1,'2026-01',2026,1),(2,'2026-02',2026,2);
create table dim_payment_method(payment_method_key integer,payment_method_name text,method_type text);
insert into dim_payment_method values(1,'Cartão','card');
insert into fact_payment_transaction values
('retail',1,1,'authorization','2026-01-01',1,1,1,0,1,0,0,0),
('retail',1,2,'authorization','2026-01-02',1,1,1,0,1,1,100,0),
('retail',1,3,'authorization','2026-02-02',2,1,1,0,1,1,100,0),
('retail',1,4,'capture','2026-02-03',2,1,1,0,0,0,0,70),
('retail',1,5,'capture','2026-02-04',2,1,1,0,0,0,0,30),
('legacy',1,6,'authorization','2026-01-02',1,1,1,0,1,1,20,0),
('legacy',1,7,'capture','2026-02-03',2,1,1,0,0,0,0,20);
''')
sql=Path('dbt/models/consumption/payment_approval_rate_by_method.sql').read_text()
sql=re.sub(r"\{\{ ref\('([^']+)'\) \}\}",r'\1',sql)
rows=db.execute(sql).fetchall()
print('SQL da P09 em SQLite :memory: (sem tabelas reais)')
print('capturado por mês:',[(r[0],r[-1]) for r in rows])
print('total view:',sum(r[-1] for r in rows),'capturas:',db.execute("select sum(captured_amount) from fact_payment_transaction where transaction_type='capture'").fetchone()[0])
```

Saída literal:

```text
SQL da P09 em SQLite :memory: (sem tabelas reais)
capturado por mês: [('2026-01', 120), ('2026-02', 0)]
total view: 120 capturas: 120
```

### E9 — verificações executadas e limites

Os processos de `check-offline` e `secrets-history` da primeira passagem perderam sua sessão de
coleta com a interrupção. Não lhes atribuo resultado; foram repetidos com saída em `/tmp`.

```bash
PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider --basetemp=/tmp/rvl1-pytest-continuacao' make check-offline > /tmp/rvl1_check_offline.log 2>&1
```

Saída 0. Saída literal completa:

```text
── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1100 links de arquivo, 188 âncoras, 664 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
........................................................................ [  9%]
........................................................................ [ 19%]
........................................................................ [ 29%]
........................................................................ [ 39%]
........................................................................ [ 49%]
........................................................................ [ 59%]
........................................................................ [ 69%]
........................................................................ [ 79%]
........................................................................ [ 89%]
........................................................................ [ 99%]
.                                                                        [100%]
721 passed, 182 deselected in 153.31s (0:02:33)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
     11 tests/test_acesso.py
     13 tests/test_captura_legado.py
      3 tests/test_carga.py
      3 tests/test_classificacao.py
      2 tests/test_consumo.py
      4 tests/test_descricao.py
      1 tests/test_fato_incremental.py
      3 tests/test_ledger.py
     12 tests/test_legacy_classification.py
      7 tests/test_legado_contraprovas.py
     22 tests/test_legado_deteccao.py
     55 tests/test_legado_remocao.py
      4 tests/test_migracao_legado.py
     15 tests/test_oraculo_da_memoria.py
      1 tests/test_portoes_da_captura.py
      3 tests/test_reconciliacao_raw.py
     21 tests/test_recuperacao_da_captura.py
      2 tests/test_retencao.py
check-offline: as três etapas passaram
```

```bash
PYTHONDONTWRITEBYTECODE=1 make secrets-history > /tmp/rvl1_secrets_history.log 2>&1
```

Saída 0. Linha final literal (o restante discrimina os 12 achados históricos tratados):

```text
revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))
```

```bash
make recovery-verify
```

Saída 0, após o sandbox impedir a primeira leitura do Docker e a repetição receber acesso:

```text
[recovery] RECOVERY_DIR = /home/doug/Projetos/mvp_eng_dados_1/data/recovery
[recovery] conferindo /home/doug/Projetos/mvp_eng_dados_1/data/recovery/aprovado
recovery-verify: checksums conferem, manifesto completo e no formato atual, os três dumps se listam. Listar o pacote não é restaurá-lo — isso é a linha 9 de B5.
```

T3 real: executado o módulo do alvo autorizado `memory-oracle`, com `--out` para manter a saída
em `/tmp`, sem criar medição no checkout. A primeira tentativa teve a conexão bloqueada pelo
sandbox; a repetição recebeu acesso. Não foram passados os aceites do ciclo da época 1 nem seu
livro de capturas, pois a época corrente é a 2, cuja linha de base já contém aquelas remoções e
capturas. A checagem da época 2 passou; isso não demonstra ausência dos contraexemplos de E1/E2.

```bash
set -a; . ./.env; set +a; .venv/bin/python -B -m mvp_ed1.recovery.memory_oracle --out /tmp/rvl1_t3.json
```

Saída 0:

```text
  (sem o livro de capturas do diário: as certificadas novas saem dos registros da época)
T3: memória contida · /tmp/rvl1_t3.json
```

O relatório registra `epoch_0002_20261104T143228Z`, `ok: true`, `problems: []`, `notes: []`.

**Cobertura da leitura:** declaração integral de `geracao.yml` (as 40 tabelas, árvore e 16 faixas),
ADR-0050, DAG e dois contratos SQL; implementação integral de T1–T4/H6–H8, locks e chamadas;
pricing, RNG e lançamento; testes negativos do T3/recuperação e amostras dos demais testes e
derivados. A leitura não revelou outro erro nas três correções do gerador, na P09 ou na ordem
recuperação → abertura → captura → conclusão → registro → `dbt_seed`. O determinismo no ambiente
atual e as faixas/preços/invariantes são exercitados pela suíte offline; não foram medidos entre
máquinas ou versões de Python. O nulo da invariante 14 é uma exclusão explícita da afirmação sobre
a data de lançamento, não prova de causalidade para os produtos com data desconhecida.

**Limites ambientais:** `findmnt -T data/memoria_do_legado -n -o FSTYPE,TARGET` retornou
`ext4   /home/doug/Projetos/mvp_eng_dados_1`. O compose monta a raiz em `/opt/mvp_ed1_ledger`.
Não escrevi nesse mount nem no livro do host para provar `link`/durabilidade; os testes de
publicação ficaram em `/tmp`. Não houve queda de energia, perda de sessão PostgreSQL, timeout
real do Airbyte, listagem real com 1.000 jobs, recuperação real de pendentes ou restauração
repetida. Foram lidos os limites e os caminhos de recusa da listagem, mas completude/paginação
e visibilidade tardia da API não foram medidas novamente. A limitação de um chamador vivo (N35)
foi respeitada nos modelos; não se reivindica garantia de concorrência além dela.

As falhas demonstradas não são afirmações de adulteração do banco real: as alterações de conteúdo
aconteceram somente nos dublês. Este parecer não concede aceite nem encerra pendências do Owner.


## Rodada 2 — lote 1

Revisão em 04/11/2026 sobre `d4ca0bb73fc428768ba8389500d879555a0f75be`, restrita a
`add459c..d4ca0bb`. O `git log --oneline add459c..d4ca0bb` contém **cinco**, não seis commits:
`ae74356`, `2a73690`, `e50e859`, `3441150` e `d4ca0bb`. Não foi incluído outro intervalo para
completar a contagem. Os lotes 2 e 3 não foram revisados nesta rodada.

**O lote 1 ainda tem um bloqueante:** a resposta a RVL1-01/02 corrige as adulterações originais,
mas a nova comparação pode ocultar uma linha duplicada adulterada. Os outros oito achados estão
fechados no recorte examinado. Isso é parecer técnico, sem aceite ou decisão pelo Owner. A escolha
de reconstruir do bruto, sem mudar o formato do livro, foi respeitada.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVL1-2-01 | `src/mvp_ed1/recovery/memory_oracle.py:321`, `:335` e `:366` | **RVL1-01 e RVL1-02 ainda não fecham: duplicatas da memória de exclusões são descartadas antes da comparação.** Tanto `_deletion_problems` quanto `deletion_content_problems` convertem as linhas em dicionário por `(source_table, business_key)`, conservando só a última. Uma linha com `last_payload` adulterado e `rows_last_seen=999`, seguida da íntegra da mesma chave, faz o **`check` completo retornar `[]`**, com 3 linhas onde espera 2 após reaparição aceita (RVL1-01), e 4 onde espera 3 numa remoção aceita sem reaparição (RVL1-02). Inverter a ordem acusa o erro. O digest/contagem atuais realmente diferem, mas o ramo de aceites não os confronta antes de eliminar duplicatas. A tabela real não tem constraint nem índice de unicidade; o teste dbt de unicidade é outra verificação e não faz parte do T3. Recusar chaves repetidas antes de indexar, preservando a prova de multiplicidade, e cobrir as duas ordens com e sem N56 fecha esta lacuna sem alterar o formato do livro. Evidência R2-E2. | `bloqueante` || Corrigido em `58c10b4`. Reproduzida a sonda R2-E2 antes do fix (`antes … check: []` nos dois casos). `_repetidas` recusa chave em mais de uma linha antes de indexar, no armazém e no recalculado, em `deletion_content_problems` (roda sempre que há a tabela) e em `_deletion_problems`; a multiplicidade é preservada como problema, não descartada. Depois do fix, a mesma sonda acusa as quatro posições (`chave(s) em mais de uma linha [('customers', '99001')]` e `[('inventory_balances', '145')]`). Seis testes novos em `tests/test_oraculo_da_memoria.py` — as duas ordens com N56 e sem ela, duas cópias íntegras, e repetição no recalculado —, os seis falham com o `memory_oracle.py` de `d4ca0bb` (`6 failed`). `make check-offline`: 749 passed. T3 real somente leitura sobre `58c10b4`: `memória contida` (`data/medicoes/v1_1_0/20261104T220812Z_t3_58c10b4.json`); o teste de integração `…recalculada_do_bruto…` passa (1 passed). |
| RVL1-2-02 | `src/mvp_ed1/recovery/capture_recovery.py:285`; `docs/origem_legada.md` §4.3 | **Limite operacional da solução aceita para RVL1-05.** A ambiguidade no início da primeira tentativa persiste mesmo após um dia: o limite inferior não avança. Se a fronteira for a próxima tentativa, ela também é fixa; se for apenas `agora`, esperar pode resolver. Não há comando/procedimento documentado para o Owner fornecer a associação verificada e retomar localmente: a CLI de `ledger` não recebe `associated_job`, e `ledger-attempt` sozinho não resolve a identificação. Existe o retorno geral por pacote no runbook §6, ou uma resolução explícita a definir pelo Owner; repetir a recuperação não é uma saída garantida. Registro o custo da parada já aceita, sem reabrir a escolha nem propor uma associação automática. Evidência R2-E4. | `observação` || Aceito como observação e declarado em `d03598e`: Origem Legada §4.3 (v2.11) registra o custo — no fim móvel (`agora`) esperar resolve; no início da tentativa ou da seguinte o limite é fixo e repetir para de novo; o livro não tem comando que receba a associação; a saída hoje é o runbook §6 (pacote) ou uma resolução do Owner. Nada implementado: um comando de associação manual é decisão do Owner, levada a ele neste fechamento. |
| RVL1-2-03 | `src/mvp_ed1/recovery/memory_oracle.py:32` | **A descrição de abertura ainda diz “por chave, e não por conteúdo”.** O trecho permaneceu do código anterior e contradiz a implementação nova e Origem Legada §4.3. A comparação com a linha de base é por chave quando há reaparição, mas agora há uma segunda prova de conteúdo contra o bruto. Observação documental sobre linhas não alteradas no intervalo, sem novo defeito funcional. Evidência R2-E6. | `observação` || Corrigido em `58c10b4`: a descrição do módulo passa a ter o item 6 — a memória de exclusões linha a linha e por conteúdo contra a recalculada do bruto, com uma linha por chave —, e o item 5 diz que a conferência contra a linha de base, com reaparição aceita, é só por chave. `check` passa a dizer "seis grupos". |

### Fechamento individual dos dez achados

- **RVL1-01 — não fechado; continua em RVL1-2-01.** A alteração original de 99001 é detectada no
  armazém copiado em memória (`/tmp/rvl1r2_t3.py`: `['last_payload', 'rows_last_seen']`), e o esperado
  independente reproduz 11/11 linhas. Mas `/tmp/rvl1r2_duplicates.py` retorna
  `RVL1-01 antes linhas: 3 / 2 check: []` (R2-E1/E2).
- **RVL1-02 — não fechado; continua em RVL1-2-01.** A alteração original da 145 acusa
  `['last_payload', 'removed_in_snapshot_id']` e a duplicação dentro do payload da 146 acusa
  `['last_payload']`. A duplicação da linha inteira ainda passa:
  `RVL1-02 antes linhas: 4 / 3 check: []` (R2-E1/E2).
- **RVL1-03 — fechado.** E2 adaptada apenas para aceitar a nova parada devolve `RecoveryStopped`
  por divergência do certificado; as 40 linhas seguem `pending` e o livro tem somente
  `['attempt', 'baseline']`. As pendentes intactas do portão e da baseline são retomadas, e o
  portão recusa uma pendente sem job antes de publicá-la (R2-E3/E4).
- **RVL1-04 — fechado.** E2: `transição raw ausente: False`, `T3: 0 problemas`; a associação
  previamente guardada no `attempt` também chega à transição com `associated_job: 9` e bruto
  presente (R2-E3/E4).
- **RVL1-05 — fechado quanto ao defeito e à parada escolhida.** E2 para antes do registro e do
  abandono; o certificado fica `pending` e só existe `baseline`. Foram conferidos o início, a
  próxima tentativa, `agora` e os segundos exatamente nas fronteiras. A ausência de retomada
  local documentada é RVL1-2-02 (R2-E3/E4).
- **RVL1-06 — fechado.** E1 original agora termina em `LedgerError: a época já guarda a tentativa
  a (attempt): um registro manual não a reabre`. A baseline também impede o segundo primeiro
  registro; duas baselines provocam `a época tem 2 linhas de base, e precisa de uma`, sem publicar
  o manual. Esta é a recusa correta de uma época estruturalmente inválida (R2-E3/E4).
- **RVL1-07 — fechado.** E4 original termina em `LedgerError: nome de registro sem .json, que a
  leitura do livro ignoraria: 'D2_a1_memoria'`; os três nomes dos testes são recusados antes da
  escrita. A preservação após falha entre `link` e `fsync` continua funcionando (R2-E3/E5).
- **RVL1-08 — fechado.** E5 original: `bruto registrado: 2 bruto final: 2`. A troca de job 9 para
  10 entre as leituras é recusada, sem publicar. A segunda `attempt_record` abre outra leitura
  `REPEATABLE READ`, depois da observação final, eliminando o retrato parcial da primeira. No
  contrato vigente de job final e um chamador, não encontrei outra janela parcial introduzida
  pela correção; não foi simulada escrita tardia de um job que a API já diz final (R2-E3/E4).
- **RVL1-09 — fechado pela decisão do Owner.** `sed -n '403,421p' docs/origem_legada.md` confirma
  SCD fora do T3 e proteção pelo manifesto do pacote. A exclusão foi mantida, sem ampliação
  do contrato nesta revisão (R2-E6).
- **RVL1-10 — fechado pela decisão do Owner.** O mesmo trecho declara `hashtext`, 32 bits,
  espera/recusa indevida e aceitação pelo volume; `legacy/captura.py` não mudou neste intervalo.
  Não foi induzida colisão entre tentativas reais (R2-E6).

### R2-E1 — independência, equivalência com SQL e armazém real

Leitura integral de `expected_deletion_rows`, `deletion_content_problems`, seus chamadores, dos
dois modelos SQL e da canonização. O esperado não consulta `legacy_presence_by_capture` nem
`legacy_removed_records`: lê a PK do bruto, usa `remocao.canonizar` e relê o payload de
`schema.colunas` com `jsonb_build_object`. O conjunto certificado vem de `captura.certificadas`.
As 40 PKs atuais são 39 `bigint` e uma `uuid`; não se reivindica equivalência de tipos ausentes
da declaração.

O script `/tmp/rvl1r2_sql_cases.py` executa a função Python sobre um adaptador de linhas brutas
em memória e gera CTEs `VALUES`/`jsonb_to_recordset` para a contraparte PostgreSQL. No lado SQL,
renderiza a macro e o braço real da presença de `brands` ou `inventory_movements`, seguido do
arquivo real de `legacy_removed_records`; substitui apenas as fontes/ref por CTEs. Certificados
simulados têm as 40 tabelas. Não cria tabelas nem altera dados.

```bash
.venv/bin/python -B /tmp/rvl1r2_sql_cases.py
ENG_DADOS_DIR=/home/doug/Projetos/mvp_eng_dados_1 /home/doug/Projetos/bi-como-codigo/evidence/20261022/ro.sh /tmp/rvl1r2_cases.sql -At > /tmp/rvl1r2_cases.out
```

Ambos saíram 0; o segundo precisou da liberação do socket Docker após a recusa do sandbox.
Comparação dos resultados JSON com a saída Python, por chave e por conteúdo (saída literal):

```text
transaction_read_only: on
alias-dup-null-invalid SQL == Python: True linhas: 1 removed_in: [3]
non-certified-only SQL == Python: True linhas: 0 removed_in: []
non-certified-latest-ignored SQL == Python: True linhas: 1 removed_in: [3]
selected-not-certified-present SQL == Python: True linhas: 0 removed_in: []
selected-not-certified-removed-null SQL == Python: True linhas: 1 removed_in: [None]
selected-not-certified-with-removal SQL == Python: True linhas: 1 removed_in: [2]
reappearance-removal SQL == Python: True linhas: 1 removed_in: [4]
later-than-selected-ignored SQL == Python: True linhas: 1 removed_in: [3]
no-certificates SQL == Python: True linhas: 0 removed_in: []
selected-first SQL == Python: True linhas: 0 removed_in: []
uuid-alias-multiplicity SQL == Python: True linhas: 1 removed_in: [3]
uuid-selected-alias SQL == Python: True linhas: 0 removed_in: []
{"cases": 427, "grammar": "bigint", "differences": []}
{"cases": 268, "grammar": "uuid", "differences": []}
```

Incluídos: alias na mesma captura e na selecionada, repetição física, nulo/inválido sem identidade,
presença só em não certificada, última presença não certificada, selecionada não certificada,
`removed_in_snapshot_id` nulo, reaparição seguida de remoção, primeira captura e capturas futuras.
A gramática cobre bases 2/8/10/16, sinais, separadores, brancos ASCII/Unicode, limites de bigint,
zeros longos e as 128 combinações de hífens em UUID, com e sem chaves. Não apareceu divergência.

A consulta de tipos retornou `text` para tabela/chave, `bigint` para os três snapshots e
`rows_last_seen`, e `jsonb` para `last_payload`. O `int()` de `_normal_da_exclusao` pode truncar
`1.9` num dublê, mas a coluna real é `bigint`; não se elevou esse valor impossível na tipagem
atual a defeito. Os payloads relidos e os atuais são JSONB decodificado, com valores das colunas
textuais do legado: `default=str` não normaliza dois valores de negócio distintos nesse domínio.
A ordem dos payloads é desprezada como previsto, mas suas repetições são preservadas.
`observed_in_snapshot_id` é a única coluna retirada por `ledger.deletion_rows`, volátil por desenho.

Também foi lido `data/medicoes/v1_1_0/20261104T174734Z_t3_ae74356.json`: commit `ae74356`,
`ok: true`, `problems: []`, `notes: []`, época 0002. A medição abaixo é desta rodada:

```bash
set -a; . ./.env; set +a; .venv/bin/python -B /tmp/rvl1r2_t3.py > /tmp/rvl1r2_t3.log 2>&1
```

Saída 0, após liberar a conexão que o sandbox impediu. O script chama o `main` do T3 com
`--out /tmp/rvl1r2_t3.json` e envolve `read_memory` somente para contar as linhas e aplicar três
adulterações a `deepcopy` do resultado; devolve ao T3 a memória original. Nenhuma escrita no
armazém ou livro. Saída literal:

```text

memória real/recalculada: 11 11 problemas de conteúdo: []
contraprova só em memória customers 99001 ["memória de exclusões: 1 linha(s) com conteúdo diferente do recalculado do bruto: [(('customers', '99001'), ['last_payload', 'rows_last_seen'])]"]
contraprova só em memória inventory_balances 145 ["memória de exclusões: 1 linha(s) com conteúdo diferente do recalculado do bruto: [(('inventory_balances', '145'), ['last_payload', 'removed_in_snapshot_id'])]"]
contraprova só em memória inventory_balances 146 ["memória de exclusões: 1 linha(s) com conteúdo diferente do recalculado do bruto: [(('inventory_balances', '146'), ['last_payload'])]"]
  (sem o livro de capturas do diário: as certificadas novas saem dos registros da época)
T3: memória contida · /tmp/rvl1r2_t3.json

```

O relatório novo registra `d4ca0bb`, `2026-11-04T21:40:19+00:00`, época
`epoch_0002_20261104T143228Z`, `ok: true`, `problems: []`, `notes: []`. Como na primeira rodada,
sem passar o livro de capturas do diário, as certificadas novas são obtidas dos registros da época.

### R2-E2 — contraprova da duplicata: RVL1-2-01

Reprodução mínima do `check` completo, só em memória. O esperado fica fixo; o digest e a contagem
atuais são recalculados **incluindo** a linha adulterada. Salvar como `/tmp/rvl1r2_duplicates.py`:

```python

from copy import deepcopy
from mvp_ed1.recovery import memory_oracle as mo, oraculos


def row(table, key):
    return dict(source_table=table, business_key=key, last_seen_snapshot_id=55,
                removed_in_snapshot_id=59, rows_last_seen=1, last_payload=[{'name': 'original'}])


base_rows = [row('customers', '1'), row('customers', '99001')]
addition = row('inventory_balances', '145')
base = dict(kind='baseline', format=1, captures={}, certificate={'rows': []},
            deletion_keys=[[r['source_table'], r['business_key']] for r in base_rows],
            deletions={'linhas': len(base_rows), 'digest': oraculos.digest(base_rows)})

for label, expected, target, reappeared in [
    ('RVL1-01', [base_rows[1], addition], base_rows[1], {('customers', '1')}),
    ('RVL1-02', [*base_rows, addition], addition, None),
]:
    damaged = deepcopy(target)
    damaged.update(last_payload=[{'name': 'ADULTERADO'}], rows_last_seen=999)
    for position, actual in [('controle', expected), ('antes', [damaged, *expected]),
                             ('depois', [*expected, damaged])]:
        mem = mo.Memory(certificate={}, captures={}, certified=[], received={}, selected=None,
                        quarantine=None, quarantine_by_table={}, classification=None, versions=[],
                        deletions={'linhas': len(actual), 'digest': oraculos.digest(actual)},
                        deletion_rows=actual, expected_deletion_rows=expected)
        problems = mo.check([base], mem, remocoes_aceitas={('inventory_balances', '145')},
                            reaparicoes_aceitas=reappeared)
        print(label, position, 'linhas:', len(actual), '/', len(expected), 'check:', problems)

```

Comando `.venv/bin/python -B /tmp/rvl1r2_duplicates.py`, saída 0:

```text

RVL1-01 controle linhas: 2 / 2 check: []
RVL1-01 antes linhas: 3 / 2 check: []
RVL1-01 depois linhas: 3 / 2 check: ["memória de exclusões: 1 linha(s) com conteúdo diferente do recalculado do bruto: [(('customers', '99001'), ['last_payload', 'rows_last_seen'])]"]
RVL1-02 controle linhas: 3 / 3 check: []
RVL1-02 antes linhas: 4 / 3 check: []
RVL1-02 depois linhas: 4 / 3 check: ["memória de exclusões: 1 linha(s) com conteúdo diferente do recalculado do bruto: [(('inventory_balances', '145'), ['last_payload', 'rows_last_seen'])]"]

```

A mesma sonda com os conjuntos reais de aceite de `D4_a2_h2_estado_real.json`
(`/tmp/rvl1r2_content.py`, saída 0) retorna `[]` com 12/11 linhas para N56 e 15/14 para N54 sem
reaparição, com `digest diferente: True` em ambos. Quando só a linha original é alterada, sem
duplicata, a correção acusa o conteúdo como esperado.

Consultas incluídas no SQL somente leitura de R2-E1:

```sql
select jsonb_build_object('unique_constraints', count(*)) from pg_constraint
where conrelid='trusted.legacy_removed_records'::regclass and contype in ('p','u');
select jsonb_build_object('unique_indexes', count(*)) from pg_index
where indrelid='trusted.legacy_removed_records'::regclass and indisunique;
select jsonb_build_object('actual_rows', count(*), 'distinct_keys', count(distinct (source_table,business_key)))
from trusted.legacy_removed_records;
```

```text
{"unique_constraints": 0}
{"unique_indexes": 0}
{"actual_rows": 11, "distinct_keys": 11}
```

O estado real está limpo; a adulteração ocorreu só no dublê. Há teste dbt de unicidade em
`dbt/models/trusted/legacy/_legacy__models.yml:427`, mas `memory-oracle` não o executa. A garantia
do T3 não pode depender de esse teste ter rodado depois de toda alteração da tabela.

### R2-E3 — repetição de E1, E2, E4 e E5

Executados os quatro scripts originais preservados em `/tmp`, sem mudanças. E1, E2 e E4 saíram 1
pelas novas recusas; E5 saiu 0 com o retrato final correto. Excertos literais:

```text
$ .venv/bin/python -B /tmp/rvl1_memory.py
controle: ['memória de exclusões: o esperado recalculado do bruto não se leu — o conteúdo não se prova']
mvp_ed1.recovery.ledger.LedgerError: a época já guarda a tentativa a (attempt): um registro manual não a reabre
$ .venv/bin/python -B /tmp/rvl1_recovery.py
mvp_ed1.recovery.capture_recovery.RecoveryStopped: a recuperação parou:
  tentativa a: o certificado no armazém difere do último registro dela no livro (attempt) — a divergência não se adota; o Owner decide (N34)
$ .venv/bin/python -B /tmp/rvl1_publish.py
falha injetada: crash entre link e fsync
retry recusado; original preservado: True
temporário órfão preservado: True
mvp_ed1.recovery.ledger.LedgerError: nome de registro sem .json, que a leitura do livro ignoraria: 'D2_a1_memoria'
$ .venv/bin/python -B /tmp/rvl1_gate.py
portão retornou; arquivo publicado: True
bruto registrado: 2 bruto final: 2
```

O E1 antigo não preenche o novo esperado, então sua recusa sozinha não prova a reconstrução;
R2-E1/E2 e `/tmp/rvl1r2_content.py` fornecem o controle positivo. O E2 antigo tinha
`assert rounded_running` no tratamento de `RecoveryStopped`: com a primeira falha agora barrada,
esse assert interrompe o script. A continuação `/tmp/rvl1r2_e2.py` troca **somente** esse assert por
`assert rounded_running or not associated` e o rótulo da mensagem. Assim os três cenários rodam:

```bash
.venv/bin/python -B /tmp/rvl1r2_e2.py
```

Saída 0, literal:

```text

parada esperada, associated=False, rounded=False: ['tentativa a: o certificado no armazém difere do último registro dela no livro (attempt) — a divergência não se adota; o Owner decide (N34)']
certificado já alterado: ['pending']
registros publicados: ['attempt', 'baseline']
caso: job associado sem job_id
recover: {'a': 'abandonada'} status: ['abandoned']
barreira: []
transição raw ausente: False
T3: 0 problemas; primeiro: []
parada esperada, associated=True, rounded=True: ['tentativa a: job(s) 9 com início em segundos no limite da janela — não se decide se é desta tentativa sem a precisão que a listagem não dá; nada se registra nem se abandona, e o Owner decide']
certificado já alterado: ['pending']
registros publicados: ['baseline']
reconcile startTime=2026-11-04T10:00:00.750000Z job=9 stop=None
reconcile startTime=2026-11-04T10:00:00Z job=None stop=tentativa a: job(s) 9 com início em segundos no limite da janela — não se decide se é desta tentativa sem a precisão que a listagem não dá; nada se registra nem se abandona, e o Owner decide

```

### R2-E4 — estados legítimos, fronteiras e recusas adicionais

`/tmp/rvl1r2_recovery_edges.py` reutiliza `_cenario` de
`tests/test_recuperacao_adversaria.py`: recuperações reais sobre as 40 linhas do adaptador e
publicações em `TemporaryDirectory`. Para uma baseline pendente, a fixture põe nela o certificado
intacto antes de chamar a recuperação; para uma associação prévia, publica o `attempt` com
`associated_job=9`. Os testes do portão substituem apenas a medição, o lock e o observador.

```bash
.venv/bin/python -B /tmp/rvl1r2_recovery_edges.py
```

Saída 0, literal:

```text

pending do portão com job final e certificado intacto: {'a': 'concluida'} status: ['unstable'] associated_job: None raw ausente: False
pending da baseline com job final e certificado intacto: {'a': 'concluida'} status: ['unstable'] associated_job: None raw ausente: False
pending da baseline sem job, sem divergência: {'a': 'abandonada'} status: ['abandoned'] associated_job: None raw ausente: True
associação já guardada no attempt: {'a': 'abandonada'} status: ['abandoned'] associated_job: 9 raw ausente: False
portão pending sem job: tentativa a pendente sem job: fica para a recuperação (H7) | arquivos: ['baseline.json']
manual, tentativa na baseline: a época já guarda a tentativa a (baseline): um registro manual não a reabre
manual, duas baselines: a época tem 2 linhas de base, e precisa de uma | manual publicado: False
portão, job muda entre leituras: tentativa a: o job mudou de 9 para 10 entre as duas leituras do portão | arquivos: ['baseline.json']
janela lower crosses stop: True job: None
janela lower exact stop: False job: 9
janela second ends at lower stop: False job: None
janela now crosses stop: True job: None
janela exact upper stop: False job: None
janela second ends at upper stop: False job: 9
janela lower after one day stop: True job: None
janela previous upper after one second stop: False job: 9
limite inferior exato, representação '2026-11-04T10:00:00Z' job: 9 stop: None
limite inferior exato, representação '2026-11-04T10:00:00.000000Z' job: 9 stop: None
limite inferior exato, representação 1793786400 job: 9 stop: None

```

Não se encontrou o suposto caminho em que a DAG registra `pending` antes de receber job:
`gate` recusa esse estado. Com job final e certificado intacto, tanto `attempt` quanto baseline
passam pela nova igualdade e chegam a `unstable`, que é o veredito correto da fixture cujo
conteúdo mudou. A baseline sem job e sem diferença também não sofre falso bloqueio da igualdade.
Mudar legitimamente `job_id` depois de um registro exigiria retomar o chamador antigo após o
registro; o procedimento vigente manda encerrar a execução falha e iniciar outra, com H7 antes.
Não se ampliou N35 para cobrir chamadores simultâneos.

Nas fronteiras, o segundo inteiro que termina no início fica fora; o que começa exatamente nele
fica dentro; o que termina no fim fica dentro; o que começa exatamente no fim fica fora. A
primeira tentativa recebe o mesmo teste de limite inferior. A fronteira da tentativa seguinte
também é exercitada pelo teste permanente `test_o_fim_da_janela_tambem_e_limite`. O limite `agora`
foi exercitado acima, inclusive depois de avançar um segundo. Os resultados distinguem uma
parada transitória no fim móvel da persistente no início fixo.

Quanto à saída operacional de RVL1-2-02: `ledger.main` oferece `baseline`, `attempt`, `treatment`
e não expõe associação manual. O runbook §5 exige investigar, proíbe ultrapassar a parada e
remete ao Owner; §6 oferece retorno por pacote. Não há instrução de resolução local para essa
nova ambiguidade. Não se tentou nem se recomenda usar uma nova baseline ou alterar o certificado
para fazer a barreira passar.

### R2-E5 — sensibilidade dos testes e regressões

Para retirar as correções **somente do processo de teste**, sem checkout, patch ou escrita no
repositório, usado o plugin `/tmp/rvl1r2_mutation.py`:

```python

import os
import subprocess


def pytest_configure(config):
    name = os.environ.get('RVL_MUTATION')
    if name:
        import importlib
        module = importlib.import_module('mvp_ed1.recovery.' + name)
        path = 'src/mvp_ed1/recovery/' + name + '.py'
        before = subprocess.check_output(['git', 'show', 'add459c:' + path], text=True)
        exec(compile(before, 'add459c:' + path, 'exec'), module.__dict__)

```

Comandos e finais literais; saída 1 esperada nos dois, porque cada módulo foi trocado em memória
pelo de `add459c`:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=/tmp RVL_MUTATION=capture_recovery .venv/bin/pytest -p no:cacheprovider -p rvl1r2_mutation --basetemp=/tmp/rvl1r2-mut-rec -q tests/test_recuperacao_adversaria.py
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=/tmp RVL_MUTATION=ledger .venv/bin/pytest -p no:cacheprovider -p rvl1r2_mutation --basetemp=/tmp/rvl1r2-mut-ledger -q tests/test_ledger.py -k 'nome_que_a_leitura_ignoraria or registro_manual_nao_reabre or o_portao_mede_o_bruto_depois'
```

```text

FAILED tests/test_recuperacao_adversaria.py::test_certificado_adulterado_depois_do_registro_para_sem_ser_adotado
FAILED tests/test_recuperacao_adversaria.py::test_a_transicao_leva_o_job_associado_e_o_t3_aceita_a_recuperacao_integra
FAILED tests/test_recuperacao_adversaria.py::test_job_em_segundos_no_limite_da_janela_para_antes_de_registrar_ou_abandonar
FAILED tests/test_recuperacao_adversaria.py::test_reconcile_trata_a_precisao_do_inicio_do_job[2026-11-04T10:00:00Z-esperado4]
FAILED tests/test_recuperacao_adversaria.py::test_o_fim_da_janela_tambem_e_limite
5 failed, 4 passed in 0.48s
FAILED tests/test_ledger.py::test_nome_que_a_leitura_ignoraria_e_recusado[D2_a1_memoria]
FAILED tests/test_ledger.py::test_nome_que_a_leitura_ignoraria_e_recusado[registro.txt]
FAILED tests/test_ledger.py::test_nome_que_a_leitura_ignoraria_e_recusado[registro.json.bak]
FAILED tests/test_ledger.py::test_registro_manual_nao_reabre_tentativa_que_a_epoca_guarda
FAILED tests/test_ledger.py::test_o_portao_mede_o_bruto_depois_de_o_job_estar_final
5 failed, 23 deselected in 0.37s

```

Os cinco testes da recuperação falham pelos comportamentos antigos: adoção da divergência,
transição sem associação e três recusas temporais ausentes. Os quatro controles de precisão
continuam passando. Os cinco do ledger falham por publicação dos três nomes invisíveis, repetição
manual aceita e retrato parcial com uma linha. Não são falhas de importação/configuração.

Sobre o código atual:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTEST_ADDOPTS='-p no:cacheprovider --basetemp=/tmp/rvl1r2-offline' make check-offline > /tmp/rvl1r2_check_offline.log 2>&1
PYTHONDONTWRITEBYTECODE=1 make secrets-history > /tmp/rvl1r2_secrets_history.log 2>&1
```

Saída 0 em ambos, lida diretamente dos processos. Saída completa do primeiro:

```text

── 1/3 revisão de segredos, .gitignore e coerência dos documentos ──
revisão de segredos: nada encontrado nos arquivos rastreados
docs-check: 115 documentos, 1101 links de arquivo, 189 âncoras, 666 citações de ADR — nada quebrado
── 2/3 pytest sem os testes de integração ──
........................................................................ [  9%]
........................................................................ [ 19%]
........................................................................ [ 29%]
........................................................................ [ 38%]
........................................................................ [ 48%]
........................................................................ [ 58%]
........................................................................ [ 67%]
........................................................................ [ 77%]
........................................................................ [ 87%]
........................................................................ [ 96%]
.......................                                                  [100%]
743 passed, 183 deselected in 171.70s (0:02:51)
── 3/3 o que ficou de fora: os de integração, que rodam no make check ──
     11 tests/test_acesso.py
     13 tests/test_captura_legado.py
      3 tests/test_carga.py
      3 tests/test_classificacao.py
      2 tests/test_consumo.py
      4 tests/test_descricao.py
      1 tests/test_fato_incremental.py
      3 tests/test_ledger.py
     12 tests/test_legacy_classification.py
      7 tests/test_legado_contraprovas.py
     22 tests/test_legado_deteccao.py
     56 tests/test_legado_remocao.py
      4 tests/test_migracao_legado.py
     15 tests/test_oraculo_da_memoria.py
      1 tests/test_portoes_da_captura.py
      3 tests/test_reconciliacao_raw.py
     21 tests/test_recuperacao_da_captura.py
      2 tests/test_retencao.py
check-offline: as três etapas passaram

```

Última linha do segundo:

```text

revisão do histórico: nada não tratado (12 achado(s), todos registrados; 0 blob(s) pulado(s))

```

### R2-E6 — documentação, escopo e limites

`sed -n '403,421p' docs/origem_legada.md`, trecho literal da decisão de escopo:

```text

  tentativa à mão, e recusa com o lock tomado ou com a tentativa já guardada na época.
- **O oráculo da memória** (`make memory-oracle`, T3). Somente leitura: as capturas da linha de base
  e de cada registro intactas no bruto, o certificado só com as transições do eng_dados, a
  quarentena e o tratamento como os registros os guardam, e a memória de exclusões **linha a
  linha**, contra a recalculada do bruto retido pela regra do ADR-0045 — em Python, sem o SQL do
  modelo. Mudanças na memória de exclusões entre a linha de base e agora só passam declaradas
  (`REMOCOES_ACEITAS=`, `REAPARICOES_ACEITAS=`). **Fora da garantia, por desenho:** o histórico SCD,
  que a regeneração substitui e que o manifesto do pacote protege com o *digest* canônico de cada
  *snapshot* ([Capacidade §3.1](capacidade_e_recuperacao.md#31-conteúdo-do-pacote)).

A garantia vale com **um chamador de captura vivo por vez**; dois juntos são limitação declarada,
e os locks são defesa além disso. Os locks de tentativa usam `hashtext` do identificador dela, de
32 bits: duas tentativas distintas podem cair no mesmo lock — achado na revisão do lote 1 da
v1.1.0 com dois identificadores reais —, e o efeito é uma espera ou uma recusa indevida, nunca o
abandono de uma tentativa através de um lock tomado. Aceito pelo volume, de dezenas de tentativas
por época. A especificação completa — a reconciliação com os *jobs* do
Airbyte, os registros de tratamento e o oráculo que lê o livro — é o
[runbook da regeneração](https://github.com/alencardoug/bi-como-codigo/blob/c82391a/docs/regeneration_runbook.md#32-what-stage-15-hands-over)
no `bi-como-codigo` (H6 a H8, T3 e T4). Implementados até aqui: as épocas, a linha de base, os

```

`sed -n '32,35p' src/mvp_ed1/recovery/memory_oracle.py`, descrição antiga que motivou RVL1-2-03:

```text

   desenho: "sai quando a chave reaparece" (ADR-0045). Com reaparição aceita, as
   linhas que restam da linha de base se conferem **por chave**, e não por
   conteúdo: a linha de base guarda o *digest* do conjunto, e um conjunto menor
   não se compara com ele. O relatório diz isso numa nota, sem esconder.

```

**Não executado nesta rodada:** `make check` completo e os testes de integração que criam bancos
efêmeros. `PASS=907`, `923 passed, 3 skipped` são o resultado informado pelo autor, não uma nova
medição deste revisor. Foram executados o gate offline, a revisão do histórico, o T3 real somente
leitura, os SQLs acima e os probes em memória/temporários. Não foram medidos concorrência real,
queda de sessão, durabilidade sob pane, visibilidade tardia da API ou retomada operacional após a
ambiguidade. Esses limites não invalidam a contraprova determinística de R2-E2.

Nenhuma fonte, certificado ou linha do livro real foi escrita; nenhuma DAG foi disparada ou
pausada. Nenhum comando de carga, sincronização, restauração ou recuperação mutante foi executado.
Nenhum fix foi implementado, nem houve commit/push. No checkout, a única alteração desta revisão
é o acréscimo desta seção a `REVISAO.md`; os dois arquivos não rastreados preexistentes foram
preservados. As colunas **Situação** desta rodada ficam vazias para a resposta do autor/Owner.
