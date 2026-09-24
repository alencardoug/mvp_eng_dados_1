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
>
> **Revisão 5 — 19/09/2026.** Aplica a terceira rodada do parecer (§15: três bloqueantes, três
> ajustes), com as medições de conferência refeitas no armazém de pé. O que mudou de forma: o
> pacote passa a guardar a **quarentena** — 60.595 linhas de auditoria que nenhuma reconstrução
> reproduz — **D51**, decidida pelo Owner (RV12-3-01); a restauração **re-baseia as gerações
> retidas** do bruto, e a continuidade do Airbyte deixa de depender de um segundo interno —
> **D52**, decidida pelo Owner (RV12-3-02); B0 passa a corrigir também a **consulta de trabalho**
> do Airflow, que é inválida na versão instalada, e dois defeitos vizinhos medidos aqui
> (RV12-3-03); a guarda da identidade passa a bloquear **antes** de o *job* escrever (RV12-3-04);
> o oráculo SCD passa a serializar todas as colunas, porque o proposto não distinguia conteúdo
> diferente (RV12-3-05); a seleção offline foi varrida inteira e são três acessos ao ambiente, não um
> (RV12-3-06 — a leitura "três testes" foi corrigida na revisão 6). §15.1 e §15.2 ganharam a
> coluna *Situação* preenchida.
>
> **Revisão 6 — 20/09/2026.** Aplica a quarta rodada do parecer (§17: quatro ajustes, uma
> observação; **nenhum bloqueante**, e nenhuma decisão reaberta — D45–D52 continuam como estão).
> O que mudou de forma: o re-base das gerações passa a exigir **preservação da equivalência de
> geração por tabela**, e não só sinal negativo e idempotência — um re-base por simples negação
> funde em `-1` a geração retida e a da restauração anterior, e o contraexemplo da §17.3 devolve
> `inconsistent` sem mudar o hash (RV12-4-01); o oráculo da quarentena passa a comparar **as
> linhas completas**, com multiplicidade, porque contagem por `(captura, versão, impressão)`
> aceita troca de payload e perda compensada por duplicação (RV12-4-02); a guarda da identidade
> passa a valer em **todo disparo da conexão legada** pelos pontos de entrada do projeto — a CLI
> sem `--certificar-legado` e o `reset` chegam ao `/jobs` por fora da fase 1 (RV12-4-03); a
> consulta de trabalho do Airflow passa a cobrir `queued` além de `running`, a não descartar DAG
> pausada e a ter **prazo** por consulta e no todo (RV12-4-04); e as formulações erradas da §0, da
> §6 e de D51 foram corrigidas (RV12-4-05). §17.2 ganhou a coluna *Situação* preenchida.
>
> **Revisão 7 — 20/09/2026, mesma data.** Aplica a quinta rodada do parecer (§18: **nenhum
> bloqueante, nenhum ajuste, uma observação**). Os quatro ajustes funcionais da rodada 4 foram
> dados por incorporados ao desenho, e o que restou foi a incoerência que a própria incorporação
> de RV12-4-05 deixou para trás: a §7.2 ainda dizia "exatamente três" testes tocando ambiente e
> "os outros 166", enquanto a §0 e a §16.6 já diziam outra coisa (RV12-5-01). A §7.2 passa a
> distinguir **três acessos** de **quatro testes**, com a fixture de módulo de `test_consumo.py`
> apresentada como o grupo de dois que ela é, e o resto da seleção offline é **165**. §18.2 ganhou
> a coluna *Situação* preenchida.
>
> **Revisão do plano encerrada — 20/09/2026.** A sexta rodada (§19) conferiu a revisão 7 e voltou
> **sem novos achados**: nada resta a incorporar no escopo conferido, e a conclusão da §18 fica de
> pé — o desenho permite avançar à implementação de B0–B4. Seis rodadas, **27 achados** (9 + 6 + 6
> + 5 + 1 + 0), todos fechados com a coluna *Situação* preenchida na rodada que os recebeu. O que
> falta para o código começar é o **aceite do Owner**; o ciclo destrutivo de B5 continua exigindo
> autorização própria, separada desse aceite.
>
> **Revisão da entrega B0–B4 — 21/09/2026.** A primeira rodada sobre o **código** (`REVISAO.md`,
> 17 achados RVE-01–17, 12 bloqueantes) foi aplicada na mesma data, cada achado reproduzido
> antes de corrigido; o que mudou está nos blocos "Revisão da entrega" das §2.1, §3 e §6, e as
> saídas na §10 do dossiê. B5 continua sem autorização.
>
> **Segunda rodada da revisão da entrega — 23/09/2026.** O parecer (`REVISAO.md` §11: RVE2-01–05,
> dois bloqueantes, três ajustes) foi aplicado na mesma data, cada achado reproduzido pela sonda do
> revisor antes de corrigido, e a aplicação achou mais dois; o que mudou está nos blocos "Segunda
> rodada" das §2.1, §3 e §6, e as saídas na §12 do dossiê. B5 continua sem autorização.
>
> **Terceira rodada da revisão da entrega — 23/09/2026.** O parecer (`REVISAO.md` §9) confirmou
> RVE2-01–05 e achou dois remanescentes anteriores ao intervalo, reproduzidos também na base:
> RVE3-01 (bloqueante, o medidor dependia do locale) e RVE3-02 (ajuste, a retomada do Airbyte dizia
> "pronto" sem observar prontidão). Aplicado na mesma data, cada um reproduzido antes de corrigido,
> e a aplicação achou mais dois; a retomada foi medida em duas pausas reais do Airbyte, autorizadas pelo Owner, que decidiu que
> pronto é a API responder. O que mudou está no bloco "Terceira rodada" da §3, e as saídas na §10
> do dossiê. B5 continua sem autorização.
>
> **D53 e D54 — 24/09/2026.** As duas pendências que a verificação da terceira rodada levantou foram
> decididas pelo Owner e implementadas: o *preflight* não cobra de novo o alvo que já está de pé,
> `airbyte-up` confere a API em vez de reinstalar, e os `*-resume` passam pela mesma troca dos
> `*-up`. O que mudou está no fim da §2.1. A quarta rodada de revisão da entrega confere as
> respostas da terceira e estas duas mudanças.
>
> **D55 e D56 — 24/09/2026, mesma data.** Exercitar de verdade a D53 e a D54, com a memória
> liberada, achou a rede do projeto sendo levada pelo `make down` — os contêineres pausados do
> Airflow presos à rede antiga desde 21/09 — e a pausa do Airbyte terminando em SIGKILL. O Owner
> decidiu a rede externa e manter a pausa, documentada. Tudo no fim da §2.1.
>
> **Quarta rodada da revisão da entrega — 24/09/2026, mesma data.** O parecer (`REVISAO.md` §11)
> confirmou as respostas da terceira rodada e as decisões D53, D54 e D56, e abriu um ajuste,
> RVE4-01: a garantia da rede externa (D55) tirava o nome do projeto de uma leitura do `.env` que
> diverge do Compose. Aplicado no mesmo dia, com um achado próprio; o que mudou está no fim da §2.1,
> e as saídas na §12 do dossiê. B5 continua sem autorização.
>
> **Quinta rodada da revisão da entrega — 24/09/2026, mesma data.** Curta, só sobre o RVE4-01. O
> parecer (`REVISAO.md` §14) confirmou as formas originais e achou uma regressão da correção,
> RVE5-01: o YAML do `config` põe entre aspas nomes como `123` e `yes`, e as aspas iam para o nome.
> Aplicado no mesmo dia; o que mudou está no fim da §2.1, e as saídas na §15 do dossiê.
>
> **Revisão da entrega B0/B1/B4 encerrada — 24/09/2026, mesma data.** A sexta rodada, só sobre o
> RVE5-01, confirmou a correção e não abriu achado. Seis rodadas sobre o código, **26 achados** —
> 15 bloqueantes e 11 ajustes (17 + 5 + 2 + 1 + 1 + 0) —, todos fechados com a situação preenchida
> na rodada que os recebeu, e as decisões D53 a D56 tomadas no caminho. O dossiê saiu da árvore no
> *commit* do encerramento, e o histórico está no *git*: as rodadas 1 e 2 em
> `git show 2136781:REVISAO.md`, a 3ª em `git show c10a30c:REVISAO.md`, da 4ª à 6ª em
> `git show a001887:REVISAO.md`. B2 e B3 ficam para a revisão final, depois de B6, com dossiê novo. O
> próximo bloco é B5, que exige a autorização do Owner.

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
- **A quarentena também é memória, e maior que todas as outras [medido em 19/09, §16; números
  corrigidos em 20/09, RV12-4-05]:** `quarantine.rejected_legacy_records` tem **63.802** linhas em
  **7** versões de catálogo e **8** pares (versão, impressão do tratamento), de **15** capturas
  distintas — 15 é o universo da quarentena; as **11** capturas completas do item anterior são
  outro conjunto, e a revisão 5 trocava um pelo outro. `trusted.legacy_classifications`
  cobre **uma** captura — a 43, sob a versão 9 e a impressão vigente, **3.207** rejeições. Um
  armazém reconstruído do zero reproduz essas 3.207 e **não** as outras **60.595**: são as
  auditorias que **o rebuild da captura corrente não recalcula** — o que não quer dizer que sejam
  todas de tratamento extinto, porque **9.586** delas ainda usam a versão 9 vigente, de capturas
  que a classificação corrente já não enxerga (§17.3). O modelo só as conserva porque lê a própria
  tabela anterior. `dbt_project.yml` e [Governança §8](docs/governanca_de_dados.md#8-retenção) a
  declaram `permanent`, "nunca descartada sem decisão registrada" — e a revisão 4 a listava como
  reconstruível pelo dbt. `quarantine.rejected_shipment_deliveries` está **vazia** e é derivada:
  não tem retenção própria.
- *Snapshots* SCD, o que o oráculo precisa distinguir [medido em 19/09]: `snapshots.scd_customer`
  tem **1.575** linhas, **1.574** com `dbt_valid_to` nulo. São quatro *snapshots* (`scd_coupon`,
  `scd_customer`, `scd_product`, `scd_support_agent`).
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
- **E o nome não é o único defeito [medido em 19/09, §16].** A consulta de trabalho
  `airflow dags list-runs --state running -o plain` é **inválida** no Airflow instalado (3.2.2):
  `dag_id` é obrigatório, o comando sai com **2** e `_trabalho_ativo` devolve "indeterminado" —
  que é bloqueio. Corrigido só o nome, o preflight passa a ver o Airflow e a **recusar toda troca,
  mesmo ocioso**. Dois vizinhos, medidos junto: o ruído de inicialização do Alembic sai no
  **stdout**, não no stderr (`2>/dev/null` não limpa; `dag-status` já o filtra com `grep -viE
  'alembic|plugin'`), e `airflow dags list -o json` devolve a **mesma DAG seis vezes**.
- **`make airflow-pause` diz que pausou sem pausar nada [medido em 19/09, §16].** O alvo é
  `docker ps … | grep '^airflow_' | xargs -r docker stop … && echo "Airflow pausado."`: o `grep`
  não casa (sai 1), mas o código do *pipeline* é o do `xargs -r`, que sem entrada sai **0** — e a
  mensagem de sucesso é impressa com o Airflow inteiro de pé. `airflow-resume` tem a mesma forma.
  É a família de defeito que esta base já conhece: alvo que anuncia o que não fez.
- `make dbt-build RESET=1` chama `dbt-drop-snapshots` (`drop schema snapshots cascade`) antes do
  `--full-refresh` — certo para regenerar a origem, **errado depois de um *restore*** (§14.3).
- `make check` chama `dbt-build` (que começa por `governance.garantir`, no armazém) antes do
  pytest: sem banco, para na etapa 2 e o pytest nem roda (§14.3).
- A identidade da captura do legado é o `job_id` do Airbyte (`snapshot_id = _airbyte_meta.sync_id`,
  `CAPTURA_SQL`); a seleção padrão é `max(snapshot_id)`. Um Airbyte reinstalado recomeça em 1:
  com 43 retida e 3 nova, o SQL real escolheu 43; número reutilizado mistura linhas e a
  certificação decide `incomplete` (§14.3).
- **A geração é o segundo contador, e ninguém tinha olhado para ele [medido em 19/09, §16].**
  `raw_legacy.customers` retém as gerações **1–28**, uma por *job*, de 9 a 43 — `28 ↔ 43` é a
  última. `captura.medir_recebido` conta como **intrusa** qualquer linha que esteja na geração do
  *job* com outro `sync_id`, por tabela, e `decidir` responde `inconsistent` antes de qualquer
  outra coisa. Um Airbyte novo recomeça a geração em **1**: a primeira sincronização depois do
  *restore* cai em cima das 75 linhas do *job* 9 e é recusada — **avançar só `jobs_id_seq` não
  resolve**. Nenhum certificado guarda a geração (`governance.legacy_captures` não tem a coluna) e
  só `captura.py` a lê: nos `.yml` de fonte ela é coluna declarada, sem teste.
- **A seleção offline, varrida inteira [medido em 19/09, §16; leitura corrigida em 20/09,
  RV12-4-05]:** `pytest -m "not integracao"` seleciona **169** de 299 testes, e a sonda
  interceptou **três acessos** ao ambiente —
  `test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao`
  (chama `dbt compile`), `…::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai` (SQL) e o
  *setup* da fixture de `test_consumo.py` (SQL). **Três acessos não são três testes:** a fixture é
  de módulo, e os **dois** testes de `test_consumo.py` dependem dela — são **quatro** testes
  dependentes de ambiente, e os dois de consumo pulam limpos, sem abrir uma segunda conexão. Os
  dois de `test_legacy_classification.py` **falham** com variáveis de conexão presentes e banco
  indisponível. Só o `test_consumo.py` estava previsto.
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
| C4 | Restauração do ponto de recuperação testada, incluindo o *re-snapshot* | A especificação (Capacidade §3), escrita **antes** dos ADRs 0037/0044/0045 | O pacote com a memória do armazém — capturas, certificados, SCD e a **quarentena** (D49 + D51) —, a sequência de restauração com o **re-base das gerações** (D52), os oráculos explícitos |
| C5 | Documentação coerente com o código | Revisão a olho | Verificador de links/âncoras; e a Execução Local já tem **seis** desvios conhecidos (ordem `dbt-build`/`stream-up`, `dbt deps`, `.tools/`, o preflight que não vê o Airflow, a consulta de trabalho inválida, a pausa que anuncia o que não fez) a corrigir antes de servir de roteiro |
| C6 | Nenhum segredo no repositório **nem no histórico** | `secrets_review` sobre o rastreado, dependente do `.env` atual | Detecção independente dos valores, sobre todo *blob*, com os limites declarados e os achados tratados (D48) visíveis |
| — | Versão marcada no Git | Nenhuma *tag* | `v1.0.0` (D47) no *commit* que fecha M5 |

Tudo o que falta é **instrumento** (C2, C5, C6), **produto** (C4) ou **execução** (C1, C3).
Nenhum ADR novo: D49 e D51 mudam o conteúdo do pacote como **consequência** de ADRs aceitos, e é
a Capacidade §3 que passa a dizer isso; D50 e D52 são consequências do
[ADR-0044](docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md), que as recebe nas
*Consequências* sem trocar a identidade que ele fixou.

---

## 2. Ordem, e por quê

```
B0 preflight por rótulos (defeito vivo do R11)
        │
B1 medição ─┐
B2 segredos ├─► B4 pacote (fontes + memória do armazém,  ─► B5 do zero (desmonta as três ─► B6
B3 docs ────┘      do estado ATUAL, em janela parada)         composições; ciclo medido)
```

0. **B0 antes de tudo**: o preflight não reconhece o Airflow **hoje**, a consulta que decidiria
   se ele está ocupado é inválida na versão instalada, e a pausa anuncia o que não fez (§0) — são
   três defeitos vivos nesta máquina, não problemas do clone, e juntos são a mitigação do R11
   furada para o Airflow desde que existe. Todo bloco seguinte que troca de ambiente depende
   dele; e o `medir` de B1 usa a mesma detecção.
1. **B1, B2, B3 depois, em qualquer ordem** — código local, sem ambiente pesado; B1 mede B4 e
   B5; B2 e B3 entram no `make check` que B5 roda.
2. **B4 antes de B5**: o pacote guarda o estado **atual** — as fontes e a memória do armazém,
   quarentena incluída (D49 + D51) — e B5 destrói as três composições. O destino do estado permanente antes do `reset` é o
   pacote; o que o pacote não leva está listado na §6 como limite, não descoberto depois.
3. **B5 é o bloco caro** (~2 h de trocas, mais sincronizações e *snapshot*).
4. **B6 por último**: estado se documenta depois de medido.

---

## 2.1 B0 — o preflight enxerga o Airflow, e acredita no que vê

**O que existe [medido].** Três defeitos em cima do mesmo caminho — e o primeiro escondia os
outros dois, porque quem nunca acha o contêiner nunca chega a consultá-lo nem a pará-lo. Há ainda
um quarto consumidor por nome, fora do preflight, no inventário abaixo:

1. **O nome.** `preflight.sh` e os pares `*-pause`/`*-resume` acham contêineres por prefixo de
   nome (`^airflow_`, e os `container_name` fixos dos bancos e do streaming); a consulta de
   trabalho é `docker exec airflow_scheduler …`. Os contêineres do Airflow têm o nome gerado pelo
   Compose (`<projeto>-<serviço>-<n>`). Airflow invisível para o preflight.
2. **A consulta.** `airflow dags list-runs --state running -o plain` **exige `dag_id`** no
   Airflow 3.2.2: sai com código 2 e `_trabalho_ativo` devolve "indeterminado", que quem chama
   trata como bloqueio. Corrigir só o nome troca "nunca vê o Airflow" por "**nunca deixa trocar**,
   nem com ele ocioso" — o oposto do que B0 existe para fazer.
3. **A pausa.** `airflow-pause` e `airflow-resume` têm a forma
   `… | grep '^airflow_' | xargs -r docker … && echo "…"`: o `grep` não casa, mas o código do
   *pipeline* é o do `xargs -r`, que sem entrada sai 0 — e a mensagem de sucesso sai com o
   Airflow de pé. Um alvo que anuncia o que não fez é pior que um alvo que falha.

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

**A consulta de trabalho, escrita inteira.** O nome resolvido é metade; a outra é perguntar algo
que a ferramenta responda:

- **por DAG, porque o Airflow exige**: o conjunto vem de `airflow dags list -o json`, **com os
  repetidos descartados** — a versão instalada devolve a mesma DAG seis vezes — e **sem filtrar
  por `is_paused`**: DAG pausada pode ter execução em andamento, e pausa não é ociosidade
  (RV12-4-04). A enumeração padrão lê o `SerializedDagModel` e não exclui pausadas, então uma DAG
  recém-registrada entra sozinha (§17.3). Hoje o projeto tem uma (`fluxo_batch`); a consulta não a
  fixa, porque a segunda DAG não pode depender de alguém lembrar deste arquivo;
- **`queued` conta como trabalho, não só `running` (RV12-4-04)**: a CLI filtra o **estado exato**
  pedido, e um `DagRun` `queued` fica de fora de `--state running` — e pode começar entre a
  consulta e a pausa, que é a corrida que o preflight existe para evitar. São os dois estados por
  DAG (`airflow dags list-runs <dag_id> --state queued|running -o json`), e **qualquer resposta
  não vazia recusa**;
- **a saída é lida do `stdout` sujo**: o ruído de inicialização do Alembic sai no **stdout**, não
  no stderr — `2>/dev/null` não limpa nada. O JSON é o que resta depois de descartar as linhas de
  *log*, como `dag-status` já faz; `[]` é ocioso, lista não vazia é trabalho;
- **três desfechos, não dois**: ocioso → libera; execução ativa → recusa com o `run_id` na
  mensagem; **falha de consulta, JSON ilegível ou DAG que não responde → indeterminado**, que
  continua sendo bloqueio. É a regra que já existe, agora alcançável;
- **e um prazo, porque "não responde" precisa de relógio (RV12-4-04)**: cada consulta roda sob
  limite de tempo próprio, e a verificação inteira sob um limite total; **expirar é
  indeterminado**, portanto bloqueio. Sem prazo, uma consulta pendurada não chega sozinha a
  desfecho nenhum — fica pendurada, e quem chamou fica junto. E enumerar DAGs **não** é medir a
  saúde do *scheduler*: o comando lê os metadados do banco. O que o preflight afirma é "não há
  execução conhecida", não "o processo está vivo" — a diferença é escrita na mensagem.

**O inventário dos consumidores por nome, levantado [medido em 19/09, §16]** — é a pergunta
que a §15.4 deixou aberta, e a resposta é que falta um:

| Onde | O que usa | Situação |
|---|---|---|
| `preflight.sh` — detecção, pausa, retomada, consulta, mensagens de recuo | `^airflow_`, `mvp_ed1_redpanda`, `mvp_ed1_kafka_connect`, `airbyte-abctl-control-plane` | entra em B0 |
| `Makefile` — `stream-pause`/`stream-resume` | `mvp_ed1_redpanda`, `mvp_ed1_kafka_connect` literais, com o `container_name` parametrizado por `COMPOSE_PROJECT_NAME` | entra em B0 |
| `Makefile` — `airflow-pause`/`airflow-resume` | `^airflow_` | entra em B0 (e o defeito 3) |
| `Makefile` — `test-carga` | `docker exec … mvp_ed1_source_db` literal | **entra em B0** — num clone com outro `COMPOSE_PROJECT_NAME`, o banco efêmero nasceria no contêiner do projeto **antigo** enquanto o Alembic migra o do clone |
| `Makefile` — `airbyte-*`, `dag-run`, `dag-status` | `airbyte-abctl-control-plane` (nome do `abctl`, declarado) e `compose exec` (resolve o serviço) | **corretos**, ficam |

**E os alvos de pausa param de mentir.** `airflow-pause`/`airflow-resume` passam a conferir o
efeito — quantos contêineres foram resolvidos, quantos pararam — e a mensagem descreve o que
aconteceu. Nenhum `&&` depois de `xargs -r` decide texto de sucesso.

**Prova.** `tests/test_preflight.py` ganha os casos com os **nomes gerados pelo Compose**
(`mvp_ed1-airflow_scheduler-1`) e com projeto de outro nome: detecção, pausa, retomada,
inventário. Da consulta: DAG em execução → recusa; **nenhuma execução → libera** (a contraprova
que faltava); saída com o ruído do Alembic à frente do JSON → interpretada; `dag_id` ausente,
código 2 ou JSON ilegível → indeterminado → bloqueio; duas DAGs, uma ociosa e outra rodando →
recusa. E os casos que a quarta rodada acrescentou (RV12-4-04): execução **`queued`** → recusa;
DAG **pausada com execução em andamento** → recusa; DAG recém-registrada, ausente de qualquer
lista fixa → entra na consulta; consulta **lenta ou pendurada** → expira → indeterminado →
bloqueio. Da pausa: nenhum contêiner resolvido → **não** diz "pausado". Contraprova na máquina, e
ela precisa alcançar o caminho `--trocar` — `make preflight ALVO=streaming` sozinho recusa antes
pelo conflito de famílias, e nunca chega a consultar DAG: com Airflow de pé e uma DAG rodando,
**`make stream-up` recusa**; com Airflow de pé e ocioso, `make stream-up` **pausa** o Airflow e o
`make airflow-resume` o retoma. As três saídas no dossiê.

**Entregue em 20/09/2026 [medido].** A regra de resolução vive em `docker/conteineres.sh` — dono
único, com os grupos `@airflow`, `@streaming` e `@bancos` declarados uma vez e citados pelo
preflight e pelo Makefile. `tests/test_preflight.py` passou de 6 para 21 casos; a suíte inteira
ficou em **306 passed, 8 skipped** (eram 291 e 8).

O preflight passou a ver o Airflow — antes esta linha dizia só "Airbyte":

```text
$ make preflight ALVO=streaming
[preflight] Já de pé: Airbyte (cluster kind);Airflow
```

**Troca com o Airflow ocioso** (`make stream-up`, caminho `--trocar`), a contraprova que faltava:

```text
[preflight] RAM disponível agora: 4,2 GB
[preflight] Airbyte está de pé e ocioso — pausando.
[preflight] Airbyte pausado — retomar com make airbyte-resume
[preflight] Airflow está de pé e ocioso — pausando.
[preflight] Airflow pausado — retomar com make airflow-resume
[preflight] RAM disponível agora: 6,9 GB — sobraria 6,4 GB
[preflight] OK
```

**Recusa com trabalho na fila, em DAG pausada** — os dois casos do RV12-4-04 numa medição só. A
execução foi enfileirada com a DAG pausada, de propósito: nenhuma tarefa rodou, e nenhum dado foi
tocado.

```text
[preflight] Já de pé: Airflow
RECUSADO — Airflow tem trabalho em andamento: DAG fluxo_batch com execução queued (manual__2026-09-20T19:59:58.032670+00:00).
```

Antes de B0 esta troca teria passado duas vezes: o Airflow nem era visto e, corrigido só o nome,
`--state running` devolveria `[]` com a execução enfileirada.

**Pausa e retomada, conferindo o efeito** — a mensagem descreve o que aconteceu:

```text
$ make stream-pause
streaming pausado — 2 contêineres parados. Retomar: make stream-resume
$ make airflow-resume
Airflow retomado — 4 contêineres de pé.
```

**O que esta entrega não mediu:** `--trocar` com falha real de `docker stop` (só simulada),
*scheduler* que responde devagar de verdade (o prazo foi exercitado com relógio falso), DAG nova
registrada em ambiente real, e o clone com outro `COMPOSE_PROJECT_NAME` (provado por simulação, não
por clone). A Execução Local §5 e §4 ainda descrevem o comportamento antigo em parte: a atualização
é de **B6**, como o plano prevê.

**Revisão da entrega — 21/09/2026 (RVE-08, 09, 11, 14, 17; `REVISAO.md`).** O revisor achou,
com Docker e `pgrep` simulados, quatro estados em que o preflight afirmava o que não tinha lido:
`docker ps` falhando virava "janela parada" e liberava o pacote; o produtor no *host* ficava
invisível quando o transporte estava parado (o `pgrep` nem era chamado); uma pausa parcial do
Airflow deixava três contêineres parados sem religá-los; e `dag-wait` aceitava `rve-100` como
resposta para `rve-10`. Mais um no Makefile: `pausar … || true` seguia com a sequência destrutiva
mesmo com um *scheduler* de pé. O que mudou de forma: **enumeração que falha é "não sei", e não
sei bloqueia** — `conteineres.sh resolver` sai 4, `pausar`/`retomar` recusam-se a anunciar estado
não lido, e o preflight distingue de pé / parado / indeterminado em toda consulta, inclusive depois
de parar; o *host* é consultado **sempre** em `preflight.sh trabalho`; o grupo cuja pausa falhou é
**recomposto** e a retomada confere que todos voltaram; a espera interpreta o JSON e compara
`run_id` **e** estado exatos; `airflow_cli.sh pausar` sai 0/3/1 (pausou / Airflow ausente /
falhou) e a manutenção só segue com 0 ou 3. Suíte do preflight: 21 → 31 casos.

**Segunda rodada — 23/09/2026 (RVE2-03).** O recuo de uma troca recusada religava o grupo inteiro
(`resolver --todos`) e terminava com **mais** contêineres de pé do que havia antes — o *apiserver*
parado antes da troca voltava junto, justamente num recuo motivado pelo R11. `_parar` passa a
anotar, por ambiente, o que estava de pé, e `_religar` recompõe **exatamente** esse conjunto,
conferindo nome a nome, tanto na pausa parcial quanto na recusa por memória. Suíte do preflight:
31 → 33 casos.

**D53 e D54 — 24/09/2026 (decisões do Owner; [Pendências §2](docs/pendencias.md#d53-e-d54--decididas-e-implementadas-em-24092026)).**
Duas pendências anteriores a esta entrega, levantadas na verificação da terceira rodada. **D53:** o
*preflight* cobrava de novo o alvo que já estava de pé — `airbyte-up` com o cluster rodando e
5,2 GB livres dava "sobraria 0,3 GB" —, e, se passasse, o ramo seguinte era o `abctl local
install` sobre o cluster de pé. O alvo inteiro de pé deixa de ser cobrado; a troca continua, e a
pausa da outra família não é desfeita por falta de memória, o que religaria as duas juntas.
`airbyte-up` decide por três estados lidos: ausente instala, pausado retoma, de pé confere a API;
consulta que falha ou estado que nenhum caminho trata recusa antes da troca, e o `curl` da espera
também é conferido antes dela. **D54:** os três `*-resume` religavam sem conferir nada, e o
*preflight* mandava retomar por eles. Agora passam pela mesma troca, depois de conferir que há o
que religar, e `FORCE=1` é o único caminho sem conferência. A regra — todo alvo que liga ambiente
pesado chama o *preflight* da própria família antes — é teste sobre o texto do `Makefile`. Suíte do
preflight: 33 → 39 casos; `tests/test_makefile.py`: 18 → 41. Medido sem mudar o estado da máquina:
com o Airbyte de pé e 2,3 GB livres, o *preflight* anterior recusava ("sobraria -2,5 GB") e o novo
diz "nada a cobrar"; `airbyte-up` e `airbyte-resume` com o cluster de pé terminam em 0,32 s, com o
instante de início do contêiner intacto.

**Exercitado de verdade, com a memória liberada — 24/09/2026.** Rodaram contra a máquina, sem
`FORCE`: as três trocas das retomadas (`airbyte-resume` e `airflow-resume` pausando o *streaming*,
`stream-resume` pausando o Airbyte), `stream-up` pausando o Airbyte e o Airflow juntos, `airbyte-up`
pelo ramo pausado, o Airflow de pé pela metade e o Docker que não responde (`DOCKER_HOST` num soquete
inexistente). As saídas estão no dossiê. O exercício achou dois assuntos, decididos pelo Owner no
mesmo dia ([Pendências §2](docs/pendencias.md#d55-e-d56--decididas-em-24092026)): **D55** — a rede do
projeto passa a ser externa, porque o `make down` a levava e os contêineres pausados ficavam presos
ao ID antigo, os do Airflow desde 21/09; **D56** — a pausa do Airbyte continua terminando em SIGKILL
aos 10 s, contra ~91 s da parada limpa, e ficou documentada. `tests/test_makefile.py`: 41 → 48
casos; suíte do preflight: 39 → 40.

**Quarta rodada — 24/09/2026 (RVE4-01; `REVISAO.md` §11–12).** A garantia da rede externa tirava
o nome do projeto de um `sed` no `.env`, e o Compose interpreta o arquivo: com `export`, comentário
na linha, interpolação ou chave repetida, a garantia preparava uma rede e o `up` exigia outra — o
revisor parou um `make up` real assim. A mesma leitura alimentava o `resolver` do preflight.
`conteineres.sh` passa a perguntar o nome ao próprio Compose — o `config` da composição dos bancos,
com o ambiente na frente —, e "não sei" é 4; `GARANTIR_REDE` recusa sem o nome. **Achado próprio:**
a composição do Airflow não declarava `name:`, e com o `.env` sem o nome o projeto dela seria
`docker`, invisível ao preflight. `tests/test_makefile.py`: 48 → 61 casos; suíte do preflight:
40 → 41.

**Quinta rodada — 24/09/2026 (RVE5-01; `REVISAO.md` §14–15).** A correção do RVE4-01 lia o nome do
YAML do `config`, que põe entre aspas os nomes que ele mesmo leria como outra coisa — `123`,
`20260924`, `yes`, `true`, `null` —, e as aspas iam para o nome da rede e para o filtro de rótulo do
`resolver`. A leitura passa a ser a do JSON do mesmo `config`, só a chave do topo e só um nome na
gramática do Compose; qualquer outra forma é "não sei". `jq` e Python, leitores de verdade, seriam
pré-requisitos novos, e não foram adotados. `tests/test_makefile.py`: 61 → 79 casos.

**Sexta rodada — 24/09/2026 (`REVISAO.md` §17).** Confirmou o RVE5-01 e não abriu achado; as sondas
do revisor ampliaram as nossas — dez nomes conferem com o Compose, e JSON compacto, outro recuo,
nome só aninhado e nome inválido dão "não sei". Com ela, a revisão da entrega B0/B1/B4 está
encerrada (cabeçalho deste plano).

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

**Entregue em 20/09/2026 [medido em parte].** `docker/medir.sh` (o medidor), `docker/airflow_cli.sh`
(as três armadilhas da CLI do Airflow num lugar só, que o preflight passou a consumir em vez de ter
a cópia dele) e `src/mvp_ed1/streaming/espera.py` (o fim declarado do caminho quente). Alvos novos:
`medir`, `dag-wait`, `stream-corte`, `stream-wait`, `docs-generate`; `dag-run` passou a capturar o
`run_id`, imprimi-lo e gravá-lo em `data/medicoes/ultimo_run_id`.

Medição real de ponta a ponta, num alvo barato:

```text
$ make medir ALVO=size-report
[medir] size-report — início 2026-09-20T20:20:08Z; estação: 2,8 GB livres, de pé: Airbyte,Airflow,bancos
[medir] registro: data/medicoes/2026-09-20_size_report.json
| size-report | Airbyte,Airflow,bancos | 0m 14s | 2,7 GB | 3,9 GB | 3 amostras a cada 2s |
```

O "3,9 GB" dos contêineres nesta linha está **subestimado**: saiu sob pt_BR, antes da correção do
RVE3-01 (ver "Terceira rodada", no fim desta seção). Os dois números da memória disponível não são
afetados.

**Três decisões que a implementação obrigou a tomar, e que o plano não previa:**

- **O encerramento é por grupo de processo, não por PID.** O `make` que sobe o `stream-run` é um
  invólucro, e o Beam é filho dele: sinalizar só o invólucro o mata e **deixa o Beam órfão**,
  segurando tópico e memória no instante em que o medidor anuncia que encerrou. Cada processo sob
  guarda nasce com `setsid`, e é o grupo que recebe o sinal — o que também garante que nada de fora
  seja tocado. A contraprova está no teste: um processo alheio, iniciado fora do medidor, precisa
  sobreviver.
- **O `make` achata o código de saída da receita em 2.** Qualquer `exit N` de dentro de uma receita
  chega ao medidor como 2, e "o código propaga" só pode significar "a falha propaga". O que
  distingue *a DAG falhou* de *a espera venceu* fica na mensagem do alvo de espera, por extenso, e
  está escrito assim no medidor — fingir que o número sobrevive seria pior que perdê-lo.
- **O oráculo da espera é de chaves, não de contagem.** Contar os dois lados aceita uma chave
  faltando e outra sobrando — a mesma insuficiência que o RV12-4-02 achou na quarentena. A
  diferença de conjuntos é barata aqui, porque o corte limita o volume, e `intrusas` entra no
  registro: um livro restaurado de outro ciclo é exatamente onde isso apareceria.

**Prova.** `tests/test_medicao.py`, 16 casos, sem banco e sem Docker real (suíte inteira: **322 passed, 8 skipped**): a agregação acha os
extremos numa série sintética e diz intervalo e contagem; série vazia não inventa extremo; alvo
inexistente falha **antes** de amostrar; `ATE` inexistente falha **antes** de o alvo rodar; a linha
da tabela sai como a da Capacidade; falha da espera propaga; o corte do cenário é lido **depois**
do produtor (o `Makefile` de mentira muda o corte durante a produção, e ler antes esperaria o
número velho); o *snapshot* sem produtor fecha no corte inicial; o encerramento mata o que iniciou
e **só** isso; pipeline que não sobe não vira medição de zero. Da espera: produtor terminado com
evento ainda em trânsito **continua esperando**; prazo vencido não é sucesso; pipeline morto encerra
na hora em vez de gastar meia hora; e a troca de uma chave por outra é detectada com as contagens
iguais.

**O que esta entrega não mediu:** nenhuma DAG real foi medida com `dag-run ATE=dag-wait`, e o modo
de cenário do *streaming* não rodou contra Redpanda, Connect e Beam de verdade — os dois exigem
subir ambiente pesado e são medidos em B5, onde o resultado vale. `docs-generate` não foi
cronometrado. Os oráculos do bloco citados acima (duração do invólucro maior que a do
`run_results.json`, e a de `dag-run` + `dag-wait` maior que a da DAG) são de B5, por construção.

**Revisão da entrega — 21/09/2026 (RVE-02, 12, 13; `REVISAO.md`).** Três defeitos, dois deles
medidos com o Makefile real copiado e executáveis simulados: **a validação do alvo executava a
receita** — o `make -n` roda de verdade toda linha com `$(MAKE)`, e `medir airbyte-up` chamava
`abctl local install` antes do preflight (a armadilha que `tests/test_recovery.py` já tinha
registrado ao ler a sequência, e o medidor não aplicava a si mesmo); a interrupção saía com 130
**sem registro**; e duas medições do mesmo alvo no mesmo dia deixavam um JSON só — snapshot,
eventos novos e recuperação de B5 são três `cenario:streaming`. O que mudou: a existência do alvo
é lida da base de dados do `make` (`make -pn` com objetivo inexistente), sem executar receita;
`_finalizar` é comum aos dois desfechos e o trap grava `interrompido: true`, código 130; o nome do
registro leva o instante e os parâmetros (`_limite_n`, `_ate_x`), e o JSON leva
`parametros: {limite, corte}`. Suíte do medidor: 16 → 19 casos.

**Segunda rodada — 23/09/2026 (RVE2-02, 04).** Dois defeitos que só dublês de processo mostram.
**`docker stats` que falhava virava 0 MB medido**: o `awk` somava a entrada vazia, e o JSON gravava
o máximo dos contêineres como 0 com código 0 — um zero inventado a caminho da tabela de B5 (P5).
E **o pipeline nascia com SIGINT ignorado**: o bash lança todo comando assíncrono de script assim, o
Python que nasce desse jeito não instala o `KeyboardInterrupt` de que `comando_pipeline` depende, e
o pipeline só saía pelo SIGKILL do prazo — com os cenários da própria suíte passando pelo mesmo
SIGKILL sem que ninguém visse. O que mudou: leitura que falha é `NA`, a agregação tira os extremos
só das amostras válidas e conta as falhas de cada grandeza, e o que não foi lido vai `null`, com
"não medido" na linha da tabela; o lançamento restaura a disposição (`trap - INT QUIT` antes do
`exec setsid`, que preserva o PID anotado) e o registro ganha `encerramento`
(`limpo`/`forcado`/`null`). Suíte do medidor: 19 → 26 casos.

**Período medido — 23/09/2026, a pedido do Owner.** A linha de 20/09 acima dizia "3 amostras a
cada 2s", mas 2 s era a **pausa**: cada amostra ainda espera o `docker stats`, que leva de 2 a 3 s
(medido), e o período real foi de 4,5 s — 3 amostras em 9 s. O registro passa a gravar
`periodo_medio_s`, medido na série, ao lado de `intervalo_s` (a pausa), e a linha da tabela diz os
dois: `3 amostras, uma a cada 4,0 s (pausa de 2 s)`, medido contra o Docker real. Suíte do
medidor: 26 → 28 casos.

**A linha de `airbyte-up`, corrigida — 23/09/2026, a pedido do Owner.** O RVE-02 corrigiu o
medidor e deixou a linha que mistura `$(MAKE)` com o `abctl local install`, e um
`make -n recovery-restore` a disparou com o Airbyte de pé (`REVISAO.md` §12). A detecção do
`make` é **textual** — medido no GNU Make 4.3, o ramo falso de um `$(if)` roda sob `-n` —, e a
mesma forma estava em `dbt-build`, onde o `&&` levava junto o `dbt build`. A retomada virou a
variável `RETOMAR_AIRBYTE`, com `airbyte-resume` e o ramo "pausado" de `airbyte-up` como
chamadores, e `dbt-build` separou o descarte do build. `tests/test_makefile.py` guarda a regra —
toda linha com `$(MAKE)` é só a recursão — e o efeito: `make -n` de `airbyte-up`,
`dbt-build RESET=1` e `recovery-restore` sobre o `Makefile` real, com executáveis simulados, não
chama nada.

**Terceira rodada — 23/09/2026 (RVE3-01, 02; `REVISAO.md` §9–10).** Dois defeitos anteriores ao
intervalo revisado, que o revisor reproduziu também na base:

- **a conversão da memória dependia do locale.** O `mawk` lê número conforme a localidade: sob
  pt_BR, o `1.5GiB` do `docker stats` virava 1 GiB, com código 0 e nenhuma falha. A entrada do
  revisor dava 1.536 MB em vez de 2.048, e uma leitura real, 3.271 MB em vez de 4.004. Todo `awk`
  do medidor passa a rodar sob `LC_ALL=C`, e a vírgula da tabela é posta à mão. **Achado próprio:**
  a linha da tabela também mudava de forma com o locale. O "3,9 GB" da medição de 20/09 acima está
  subestimado e não tem como ser corrigido, porque a série bruta não é guardada. Ele não sustentava
  decisão nenhuma, e a tabela da Capacidade é medida em B5, já com o medidor corrigido. Suíte do
  medidor: 28 → 31 casos;
- **a retomada do Airbyte dizia "pronto" sem observar prontidão.** O nó lista os sandboxes da
  partida anterior como `NotReady`, o `grep -q Ready` casava neles, e as consultas esgotadas
  terminavam num `echo` que saía 0. Medido em duas pausas reais: a espera antiga disse "pronto" em
  5,6 s, e a API respondeu em 101 s e em 96 s. **Por decisão do Owner, pronto é a API responder**
  (`GET /api/v1/health` → `available:true`). Nem pod serviria: o primeiro sandbox fica pronto em
  ~5 s, e o Kubernetes chegou a dizer 8/8 prontos aos 5 s, estado de antes da pausa. O prazo é de
  60 consultas com 5 s de pausa entre elas, três vezes o medido, e esgotá-lo é erro nos dois
  chamadores. A receita nova, numa retomada real, disse "pronta" em 95,7 s. O "~20 s" que a
  Execução Local dava para a volta tinha saído da espera defeituosa, e foi trocado pelo medido.
  **Achado próprio:** sem `curl`, a espera seria cega — o `2>/dev/null` engoliria o "command not
  found", e o prazo venceria dizendo que a API não respondeu —, e a receita passa a conferir o
  `curl` antes de religar. `tests/test_makefile.py`: 7 → 18 casos.

**Verificado depois, com a memória liberada pelo Owner (23/09/2026, `REVISAO.md` §11).**
`make airbyte-up` retomou de verdade, com o preflight aprovando: disse "pronta" em 75,9 s, e logo em
seguida `recovery-airbyte-jobs` leu o banco interno do Airbyte e a leitura autenticada da guarda de
identidade devolveu 43 — o que o passo 8 usa estava pronto. O prazo esgotou de verdade, com `make`,
`curl`, `sleep` e `docker` reais e só a URL trocada: 301 s com a porta recusando, 602 s com cada
consulta gastando os 5 s do `--max-time`; a mensagem, que afirmava "uma a cada 5 s", passa a dizer
o tempo contado. A verificação levantou duas pendências anteriores a esta entrega, D53 e D54 —
decididas e implementadas em 24/09/2026 (fim da §2.1).

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

**Entregue em 20/09/2026 [medido].** `python -m mvp_ed1.secrets_review --historico`, também como
`make secrets-history`. Fora do `make check` de propósito — o histórico só cresce, e conferi-lo a
cada `check` cobraria os 25 s medidos por nada; entra na definição de pronto e no dossiê. Os
detectores novos valem **também** no modo rastreado, que roda no `check`.

**A regra que a implementação obrigou a escrever, e que o plano não tinha: credencial é literal;
referência não é.** O detector de atribuição, exatamente como o plano o declarava, devolveu **24
achados no repositório e nenhum era segredo** — `password = quote_plus(...)` em `db.py`,
`var.source_db_password` no Terraform, `$$AIRBYTE_CLIENT_SECRET` no Makefile, a própria declaração
de regex deste módulo. Os moldes (`PLACEHOLDER_RULES`) passaram a cobrir as formas de **referência**
que este repositório usa: `$VAR`, `{var}`, `var.x`, expressão com `(` ou `[`, e palavra única sem
dígito. Com elas, o modo rastreado devolve **zero**.

**Um limite declarado no módulo, porque é escolha e não cobertura:** a última regra — palavra única
sem dígito — excusa uma senha escrita à mão só com letras. Vale aqui porque `make env` sorteia
valores com dígitos, e porque as formas conhecidas e a comparação com os valores do `.env` cobrem o
resto. Está escrito no código para ser revisto quando deixar de valer.

Primeira varredura do histórico, **160 commits**:

```text
$ make secrets-history
revisão do histórico: nada não tratado (7 achado(s), todos registrados; 0 blob(s) pulado(s))
```

Os sete achados são as **fixtures do próprio teste da varredura**, em dois *commits* antigos de
`tests/test_secrets_review.py` — valores fictícios escritos inteiros para provar os detectores.
Nenhum corresponde a credencial de serviço nenhum. Tratamento registrado em
`docs/segredos_tratados.yml` conforme D48; o arquivo de teste passou a montar esses valores em
partes, que é a convenção que ele já usava para o cabeçalho PEM. **Nenhum segredo real foi
encontrado no histórico deste repositório.**

**Pendência documental:** `docs/segredos_tratados.yml` ainda não está no mapa do README — o dono
documental definitivo é de B6, como o plano previa.

**Prova.** `tests/test_secrets_review.py`, de 6 para 15 casos (suíte inteira, com B3: **347 passed, 8 skipped**): senha rotacionada some do modo
rastreado e o histórico a acha **sem conhecer o valor**; a mesma senha achada em ENV, YAML e JSON;
credencial em URL; forma conhecida em blob antigo; molde em `.env.example` não acusa; **segredo
real num `config.example.yml` é achado** — molde é propriedade do valor, não do arquivo; blob
grande aparece **nomeado** na lista de pulados; achado registrado sai como tratado e o código é 0;
`.env` que já esteve rastreado vira aviso mesmo sem achado. O valor nunca é impresso: dois
caracteres e o tamanho, conferido em teste.

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

**Entregue em 20/09/2026 [medido].** `python -m mvp_ed1.docs_check`, como `make docs-check` e
dentro da etapa 1 do `make check`, ao lado da revisão de segredos.

**A primeira execução achou três âncoras quebradas — todas reais, e todas invisíveis a olho:**

| Onde | Apontava para | O que existe |
|---|---|---|
| `docs/adr/0035-…md:13` | `modelo_de_dados.md#3-modelo-dimensional` | o título tem sufixo: `…--25-tabelas-em-analytics` |
| `docs/glossario_de_negocio/perguntas_de_negocio.md:8` | `…#3-modelo-dimensional--26-tabelas-em-analytics` | são **25** tabelas, não 26 — a âncora envelheceu junto com o número |
| `docs/origem_legada.md:361` | `adr/README.md#2-decisões-já-fechadas` | esse título está em `pendencias.md`; o `adr/README.md` tem "Decisões registradas" |

As três foram corrigidas na mesma entrega. Estado depois:

```text
$ make docs-check
docs-check: 106 documentos, 976 links de arquivo, 128 âncoras, 588 citações de ADR — nada quebrado
```

**Uma regra de *slug* que a implementação obrigou a separar:** o sublinhado. `_ênfase_` some porque
é marcação, mas o de `snake_case` **fica** — e este repositório tem títulos com `snake_case` e nomes
de coluna. Removê-lo geraria uma âncora que o GitHub não gera, e a ferramenta diria "existe" sobre
um link que quebra no navegador. O travessão é o outro caso que engana: `— 25 tabelas` vira
`--25-tabelas`, com dois hífens, porque o espaço de cada lado vira hífen e o travessão some.

**Prova.** `tests/test_docs_check.py`, 16 casos: seis do *slug* (acento, travessão, `snake_case`,
negrito, link dentro do título, data com barras); link bom; arquivo inexistente; âncora
inexistente; fragmento codificado (`%C3%A7`); título repetido com `-1` e `-2`; título **dentro de
bloco de código** que não conta; link dentro de bloco de código que não é conferido; link por
referência resolvido e referência sem definição; ADR citada que não existe; link externo ignorado.
O último caso roda contra a documentação real do projeto.

---

## 6. B4 — o ponto único de recuperação

**O que existe [medido].** [Capacidade §3](docs/capacidade_e_recuperacao.md#3-ponto-único-de-recuperação):
dois *dumps* (`pg_dump -Fc`), *checksums*, `seed`/`as_of_date`/versões, último `event_sequence`,
*commit*, manifesto com contagens, instruções. "O `warehouse_db` **não** entra" (§3.3). Escrita
antes dos ADRs 0037, 0044 e 0045, que fizeram do armazém guardião de memória (§0).

**O que muda — D49 e D51 [decididos].** O pacote guarda as **fontes** e a **memória do
armazém** — e a memória inclui a quarentena, que a revisão 4 tinha classificado como
reconstruível pelo dbt (D51, sobre o RV12-3-01):

| Conteúdo | Por quê | Como |
|---|---|---|
| `source_db.dump`, `legacy_db.dump` | as fontes, como antes | `pg_dump -Fc` pelos contêineres |
| `warehouse_memoria.dump` = schemas **`raw_legacy`**, **`governance`**, **`snapshots`**, **`quarantine`** | capturas retidas com certificados (ADR-0037/0044), de onde a memória de exclusões (ADR-0045, `trusted.legacy_removed_records` é `table`, rebuildable a partir delas) renasce; histórico SCD (não reconstruível); e a **auditoria da quarentena** — 60.595 das 63.802 linhas nenhum rebuild da captura corrente recalcula (nem todas de tratamento extinto: 9.586 ainda estão sob a versão vigente, RV12-4-05), e só sobrevivem porque o modelo lê a própria tabela anterior (§0) | `pg_dump -Fc -n raw_legacy -n governance -n snapshots -n quarantine` |
| `data/legacy/manifesto.json` e o diário | os oráculos do dump do legado — sem eles os testes pulam ou usam o manifesto de outra geração (RV12-09) | copiados, com *checksum* |
| `.stream/producer_state.json` | o cursor do produtor que corresponde ao livro | copiado; a regra: restaurar o livro restaura o cursor |
| `manifesto.json` | `seed`, `as_of_date`, `alembic current` dos **dois bancos de origem**, `governance._versions` do armazém (é o oráculo de versão dele — não há Alembic lá, e não haverá), `max(event_sequence)`, `git rev-parse HEAD`, contagens e tamanhos por tabela dos três *dumps*, hora do corte; **o oráculo SCD** (RV12-2-01, corrigido pelo RV12-3-05, abaixo); **o oráculo das capturas**: `max(snapshot_id)` retido, a lista de `snapshot_id` certificados e a **maior geração retida por tabela** (D52); **o oráculo da quarentena** (D51, corrigido pelo RV12-4-02): por chave `(source_system, snapshot_id, catalog_version, treatment_fingerprint)`, a contagem **e um resumo canônico das linhas completas, com multiplicidade** — a contagem sozinha aceita troca de payload, troca de motivo e perda de uma linha compensada por outra do mesmo grupo, e a sonda da §17.3 mediu exatamente isso: contagens iguais, uma linha perdida. É oráculo de **continência**, porque uma captura nova acrescenta uma fatia (passo 9) | gerado |
| *checksums* de tudo; `RESTAURAR.md` com os comandos exatos | | gerado |

**Fora do pacote, por construção (o limite, escrito):** `raw` (o Airbyte refaz do `source_db`
restaurado, e a reconciliação dos dois caminhos prova), `staging`, `trusted`, `analytics`,
`consumption` (o dbt refaz), o cursor do CDC (§3.2, como antes), o estado do Airbyte e do
Airflow. Uma restauração devolve **as fontes e a memória**; o resto é reconstruído e provado
igual. **A quarentena saiu desta lista na revisão 5** — estava aqui por uma premissa falsa, e a
[Governança §8](docs/governanca_de_dados.md#8-retenção) já a declarava permanente.

**O oráculo SCD, refeito (RV12-3-05).** O proposto na revisão 4 —
`md5(string_agg(dbt_scd_id ‖ dbt_valid_from ‖ dbt_valid_to, '' order by dbt_scd_id))` — **não
distingue conteúdo diferente**, por dois motivos somados: não tem atributo nenhum, e
`x ‖ NULL` é nulo, que o `string_agg` descarta — com 1.574 das 1.575 linhas de `scd_customer`
vigentes, o hash inteiro se resume à única versão fechada. A sonda da §16 devolveu o **mesmo
hash** para o original, para um atributo histórico alterado e para o início de uma versão vigente
alterado. O oráculo passa a ser, por *snapshot*: linhas, `count(distinct dbt_scd_id)` e o `md5`
de uma **serialização canônica de todas as colunas de cada versão** — nulo escrito como marcador
explícito (nunca concatenação nua), ordenação estável por `(dbt_scd_id, dbt_valid_from)` e
multiplicidade preservada. Contraprovas no `tests/test_recovery.py`: alterar atributo de versão
fechada e alterar a validade de versão vigente **mudam o hash** sem mudar contagem nem
`dbt_scd_id` — são as duas que o oráculo antigo não via. Duplicar uma linha muda o hash **e** a
contagem; a redação anterior dizia que a contagem não mudava, e era falsa (RV12-4-05). As três
continuam valendo como contraprova.

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
4. `pg_restore` das duas fontes (`--clean --if-exists`) e da memória do armazém — `raw_legacy`,
   `governance`, `snapshots` e **`quarantine`** (D51).
4b. **Re-basear as gerações retidas (D52)**: o `_airbyte_generation_id` das linhas que acabaram de
   voltar em `raw_legacy` vai para uma faixa própria, **negativa** — a leitura é imediata,
   "geração anterior à restauração". É o passo que impede um Airbyte novo, que recomeça a geração
   em 1, de escrever por cima das gerações 1–28 retidas e ser recusado como `inconsistent` (§0).
   Nenhum certificado referencia a geração e só `captura.py` a lê (medido, §16), e por isso este é
   o único metadado do bruto que a restauração reescreve — o conteúdo e o `sync_id` não são
   tocados, e os hashes das capturas retidas continuam valendo.

   **O contrato do re-base, escrito por inteiro (RV12-4-01).** "Negativo e idempotente" não basta,
   e o contraexemplo é do **segundo** ciclo: depois de uma restauração o bruto já tem geração `-1`
   antiga e `1` nova, e um re-base que apenas negue as positivas e deixe as negativas como estão
   satisfaz os dois critérios escritos — **fundindo as duas em `-1`**. A sonda da §17.3 fez isso: o
   veredito real passou de `complete` a `inconsistent` **sem que o hash mudasse**, ou seja, a
   captura fica recusada com o conteúdo correto. Separar por *job* também não serve: daria
   gerações distintas a linhas que originalmente **compartilhavam** uma geração, e é nessa
   coincidência que uma intrusa se esconde. O contrato passa a ser, **por tabela**:

   - **preservação da equivalência de geração** — linhas com a mesma geração continuam com a
     mesma; linhas com gerações diferentes continuam diferentes, **inclusive perante os negativos
     já presentes** de uma restauração anterior. É injetividade sobre as classes de geração
     retidas, não um sinal;
   - **faixa livre** — os valores novos ocupam faixa estritamente negativa ainda não usada, sem
     encostar nos negativos existentes;
   - **domínio conferido** — toda linha retida fica com geração **estritamente negativa e não
     nula**; a conferência é essa, e não "ausência de positivas", que um nulo atravessa;
   - **idempotência**, como antes: aplicar duas vezes é aplicar uma.

   As cargas novas escrevem em gerações não negativas — é a premissa, declarada, e o
   [ADR-0044](docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md) não muda com ela —,
   e por isso as faixas não se encontram. **Uma implementação que não consiga preservar essas
   propriedades recua** e devolve a consequência ao Owner, em vez de re-basear do jeito que der:
   este passo escreve no único dado que o pacote traz de volta.
5. **Conferir conteúdo**: contagens × manifesto nos quatro schemas restaurados;
   `governance._versions`; `alembic current` nas fontes; a quarentena por
   `(captura, versão, impressão)` = manifesto, por contagem **e** pelo resumo canônico das linhas
   (RV12-4-02); e o **oráculo do passo 4b** (RV12-4-01): por tabela, geração estritamente negativa
   e não nula em toda linha retida, **a mesma quantidade de classes de geração** de antes do
   re-base e **a mesma partição** das linhas entre elas — não apenas "nenhuma geração positiva",
   que é satisfeito por um re-base que funde faixas.
6. Restaurar `manifesto.json`/diário e `producer_state.json` nos caminhos do *checkout*.
7. **Novo *snapshot***: `stream-up` (preflight ativo) → `stream-run` até `stream-wait` (o
   corte é o `max(event_sequence)` do manifesto) → encerrar.
8. **Reconstruir sem apagar o que acabou de voltar (RV12-2-01)**: `airbyte-up` → **guarda da
   identidade (D50, abaixo) antes de qualquer sincronização** → `sync-airbyte RESET=1` →
   `sync-legacy` → **`dbt-rebuild`** (alvo novo: `governance.garantir` +
   `dbt build --full-refresh`, **sem** `dbt-drop-snapshots` — o `--full-refresh` refaz a fato
   incremental sobre as chaves substitutas restauradas, e o `dbt snapshot` só acrescenta versão se
   `trusted` mudou, o que não muda) → `make check`. A quarentena restaurada **sobrevive ao
   `--full-refresh`**: `rejected_legacy_records` lê a própria tabela anterior por
   `adapter.get_relation` e retém tudo que não seja da captura corrente sob a impressão vigente —
   é o mecanismo que acumulou as 63.802 linhas, e é por isso que o passo 4 precisa vir antes deste.
   `dbt-build RESET=1` continua existindo para o caso que o justificou — regenerar a origem —
   e o `RESTAURAR.md` diz, em negrito, que não é o alvo de uma restauração.
9. **Oráculos explícitos**, no roteiro executável, não só o `PASS`: as contagens de `oltp` e
   `legacy` = manifesto; a comparação dos **dois caminhos** da Execução Local §3.2 — chaves só
   num lado = 0, linhas com coluna de negócio diferente (as 16 de `COLUNAS_DO_EVENTO`) = 0, pares
   armazém/SKU com saldo diferente = 0, soma dos deltas igual — **é ela que prova o livro
   restaurado**; `caminhos_de_ingestao_reconciliam` lê *flags* de chegada e tempo, não os
   *payloads*, e só complementa; a memória de exclusões renasce igual (4 registros; clientes
   `1`,`2`,`3`); a captura selecionada é certificada; `governance._versions` intacto; **as versões
   SCD são as do manifesto** — linhas, `dbt_scd_id` distintos e o `md5` da serialização canônica
   de todas as colunas, por *snapshot*, iguais antes e depois da reconstrução; **a auditoria da
   quarentena contém a do manifesto, linha por linha e não só por contagem** (D51, corrigido pelo
   RV12-4-02): cada chave `(source_system, captura, versão, impressão)` do manifesto reaparece com
   a **mesma contagem e o mesmo resumo canônico das linhas completas**, multiplicidade preservada
   — nenhuma some, nenhuma muda de conteúdo, nenhuma é trocada por outra do mesmo grupo. O
   acréscimo da captura nova é conferido **à parte**, pela identidade que o Airbyte devolveu de
   fato (o `jobId` do *job* disparado), não por um número escrito neste plano. O total **não** é
   igual, e não deve ser: a sincronização do passo 8 traz uma captura nova, que vira a
   selecionada, e a classificação corrente passa a ser dela — a fatia da 43 é **retida**, não
   recalculada, e a da nova entra ao lado. O oráculo é a continência exata mais o acréscimo
   declarado, nunca a igualdade do total; **a captura nova é certificada acima da 43** com o
   Airbyte novo (D50 + D52).

**A identidade da captura num Airbyte novo — D50 e D52 [decididos].** `snapshot_id` é o `job_id`
do Airbyte; uma instalação nova recomeça em 1 e colide com o que o pacote retém (*jobs* 9–43).
E a geração é um **segundo** contador que recomeça junto (§0). Três peças, nenhuma muda a
identidade do [ADR-0044](docs/adr/0044-certificar-cada-captura-do-legado-por-conteudo.md):

1. **Guarda antes da escrita, não depois dela (RV12-3-04).** A revisão 4 colocava a guarda em
   `captura.decidir`, que roda na **fase 2** — depois de o Airbyte ter terminado o *append*.
   Recusar ali não desfaz nada: as linhas do *job* reutilizado já estão no bruto, o certificado
   antigo continua elegível, e a captura 43 passa a ler duas linhas onde havia uma. A verificação
   operacional passa a ser **pré-condição de todo disparo da conexão legada**, em todos os pontos
   de entrada do projeto: se o próximo `job_id` do Airbyte for `≤ max(snapshot_id)` certificado,
   **o *job* não é disparado** e o motivo é `identidade reutilizada ou retrocedida`.

   **"Junto da fase 1" não cobre as entradas que existem (RV12-4-03).** A revisão 5 punha a guarda
   no fluxo certificado e na fase 1 da DAG, e a sonda da §17.3 — sem enviar requisição nenhuma —
   mostrou duas entradas que passam ao largo das duas:
   `python -m mvp_ed1.airbyte sync --connection legacy_para_raw_legacy`, **sem**
   `--certificar-legado`, chega ao `POST /jobs` pelo ramo direto do `main` da CLI, e a mesma CLI
   aceita `reset` para essa conexão. Nesses caminhos `decidir` nem é chamado — e, se fosse, não
   desfaria um *append* já ocorrido. Então:

   - **na CLI**: o `sync` da conexão legada sem *flag* ou é **encaminhado** ao fluxo protegido, ou
     é **recusado antes do POST**; não segue pelo ramo direto;
   - **o `reset` da conexão legada** é tratado explicitamente — é incompatível com a retenção do
     bruto, e ou exige autorização própria e declarada, ou é recusado no mesmo ponto;
   - **na DAG**: a verificação fica na tarefa que **efetivamente dispara**
     (`sincronizar_legado_para_raw_legacy`), não só na fase 1 — `iniciar_captura_do_legado` e a
     sincronização são tarefas distintas, e reexecutar a segunda sozinha não repete a primeira
     (medido na §17.3).

   A guarda em `decidir` **continua existindo** como rede, e o que ela faz é **recusar o
   certificado**: ela roda depois da escrita e **não protege retroativamente o bruto**. A redação
   anterior atribuía a ela uma proteção que ela não tem. O ADR-0044 ganha as duas nas
   *Consequências*, sem ADR novo. Reenvio de tentativa já concluída continua devolvendo o
   certificado gravado, sem remedição (o contrato da §fase 2).
2. **Regra operacional na restauração — o contador de *jobs***: a sequência de restauração **não
   toca no Airbyte** — numa recuperação real ele continua o mesmo e os `job_id` seguem. Só quando
   o Airbyte é uma instalação nova (B5, ou um desastre que o levou junto) entra o passo
   `recovery-restore` → *avançar a sequência de jobs do Airbyte para `max(snapshot_id)` retido +
   1*, conferido **antes** da primeira sincronização (`sync-legacy` de prova: `sync_id` > retido,
   certificada). **Premissa a confirmar em B5** [não medido]: o nome da sequência e da tabela no
   banco interno do Airbyte (`jobs`, `jobs_id_seq` — interno da ferramenta, pode mudar com a
   versão); o passo é escrito de forma que, se a premissa falhar, ele **pare** com a mensagem, e
   a guarda (1) continua protegendo.
3. **O contador de gerações, resolvido do lado do dado — D52 [decidido].** Avançar o *job* não
   basta: `medir_recebido` conta como **intrusa** qualquer linha que esteja na geração do *job*
   com outro `sync_id`, e um Airbyte novo escreve na geração 1, onde estão as 75 linhas do *job*
   9 — o veredito real seria `inconsistent` com o conteúdo correto (§0). Em vez de depender de um
   **segundo** interno do Airbyte, a restauração re-baseia as gerações retidas para a faixa
   negativa (passo 4b). Assim o contador do Airbyte novo pode recomeçar onde quiser: a faixa dele
   e a faixa retida não se encontram. **A conferência de intrusas não é enfraquecida** — continua
   valendo, inteira, sobre a faixa em que o *job* novo escreve; é o dado retido que sai do
   caminho, não a regra.
   As alternativas descartadas — avançar também a geração (dois internos), marca-d'água na
   certificação (muda o contrato do ADR-0044) e limite declarado (C4 com lacuna) — estão na §10.

**Prova (rodada 2, completada pelas rodadas 3 e 4):** teste sem banco com captura retida 43 e
(a) *job* novo de identidade abaixo da retida → recusado **antes do disparo**, com **zero
`POST /jobs`**; (b) *job* 43 reutilizado → recusado antes do disparo, **zero POSTs**, e o bruto e
o hash da captura 43 **idênticos** depois da recusa; (c) *job* acima do retido → certificado e
selecionado; (d) *job* novo numa geração reutilizada de um *job* antigo → hoje `inconsistent`, e
**depois do re-base** → `complete` (é a contraprova que fecha o RV12-3-02); (e) reenvio de
tentativa concluída → devolve o certificado gravado; (f) **`sync` da CLI sem `--certificar-legado`
e `reset` da conexão legada** → encaminhados ao fluxo protegido ou recusados, com **zero POSTs**
nos caminhos recusados (RV12-4-03); (g) a tarefa de sincronização da DAG **reexecutada sozinha**,
sem repetir a fase 1 → a pré-condição roda mesmo assim. Os números de *job* citados neste plano
(1, 2, 3, 43, 44) são **exemplos de redação**: os oráculos executáveis leem o `jobId` devolvido
pelo Airbyte, porque o contador é o mesmo da conexão principal e dos *resets* e não avança de um
em um para a conexão legada (RV12-4-05). A contraprova de colisão
intencional roda em **destino isolado**, nunca sobre o único pacote e o seu bruto. Em B5, linha
9: com o Airbyte novo, o re-base do passo 4b, a sequência avançada e a sincronização seguinte
certificada como 44+ e selecionada sobre a 43 restaurada — as saídas coladas.

O `pg_restore` ocupa o lugar do `seed-data` do procedimento da §3.2; o resto da §3.2 é o que a
sequência acima aplica, na ordem que ela já tinha.

**Prova sem banco.** `tests/test_recovery.py`: manifesto gerado e lido, **inclusive os oráculos
SCD, das capturas e da quarentena**; o oráculo SCD **muda** quando muda atributo de versão
fechada, validade de versão vigente ou multiplicidade (RV12-3-05); o **oráculo da quarentena
acusa** troca de payload, troca de motivo e perda de uma linha compensada por duplicação dentro do
mesmo grupo — os três casos que a contagem sozinha deixava passar (RV12-4-02); *checksum* alterado
acusado; árvore suja recusada; `restore` sem `RESTAURAR=1` recusado antes de tocar em banco; o
re-base das gerações é **idempotente**, não altera `sync_id`, conteúdo nem hash (D52) e
**preserva a equivalência de geração por tabela** (RV12-4-01) — com contraprova de **segundo
pacote**, em que já há negativos antes do re-base, e de **intrusa já presente no conjunto
retido**, que precisa continuar detectada depois dele; um re-base por simples negação das
positivas é **recusado** pelo teste; a sequência de
restauração, simulada com o Makefile real e registradores no lugar dos executáveis (a técnica da
§14.3), **nunca** chama `dbt-drop-snapshots` e **nunca** derruba `quarantine`, e o re-base vem
**antes** da primeira sincronização; **composição** `recovery-restore RESTAURAR=1` num Makefile de
simulação com a macro real do preflight: os submakes de subida **não** anunciam "preflight
ignorado" (a contraprova do RV12-06); `RECOVERY_DIR` relativo é rejeitado.

**O que esta prova não alcança, e a implementação precisa alcançar (RV12-3-04 e §15.4).** O
`pg_restore` em destino **povoado** — que é o caso da linha 9 de B5, oito cenários depois — não é
exercitado por simulação: dependências entre objetos, permissões dos cinco papéis, substituição
efetiva e propagação de erro do `pg_restore` são medidos na execução, com a saída colada.
`pg_restore --list` confere o pacote, não a restauração.

**Entregue em 20/09/2026 [medido em parte].** `src/mvp_ed1/recovery/` —
`rebase.py` (o contrato), `oraculos.py` (a serialização canônica), `pacote.py`
(destino, manifesto, *checksums*), `leitura.py` (o SQL) e `cli.py` (os verbos) —,
`src/mvp_ed1/legacy/identidade.py` (a guarda) e os alvos `recovery-pack`,
`recovery-verify`, `recovery-rebase`, `recovery-restore`, `recovery-promote` e
`dbt-rebuild`.

**Um pacote foi montado de verdade**, e os oráculos dele reproduzem, sem nenhum
número copiado do plano, o que as rodadas de revisão mediram por conta própria:

```text
$ make recovery-pack
[preflight] nenhum trabalho em andamento — janela parada.
[recovery] corte em 2026-09-20T21:32:22+00:00 — janela parada
candidato pronto em /home/doug/Projetos/mvp_ed1/data/recovery/candidato    (31 MB)
```

| O manifesto diz | O parecer media | |
|---|---|---|
| capturas certificadas `[28,29,30,31,32,33,35,36,38,39,43]` | **11** capturas completas (§0) | ✓ |
| quarentena: **21** fatias, **63.802** linhas | 63.802 em 21 capturas (§16.1) | ✓ |
| `customers`: 28 classes de geração, mínima 1, máxima 28, **0 nulas** | gerações 1–28, sem nulo (§16.2, §17.3) | ✓ |
| `scd_customer`: 1.575 linhas, 1.575 `dbt_scd_id` | 1.575 linhas (§0) | ✓ |
| `max(event_sequence)` = 13.700 | 13.700 movimentos (§0) | ✓ |

```text
$ make recovery-verify CONTRA_O_BANCO=1
[recovery] quarentena: 21 fatia(s) do manifesto conferidas por contagem e conteúdo, 0 acrescentada(s)
[recovery] SCD: 4 snapshot(s) conferidos pelo digest canônico de todas as colunas
recovery-verify: checksums conferem, manifesto legível, os três dumps se listam.

$ printf 'x' >> data/recovery/candidato/legacy_db.dump && make recovery-verify
recovery-verify: 1 problema(s)

$ make recovery-rebase DRY_RUN=1
  brands: 27 classe(s) → -27..-1
  … (40 tabelas)
[recovery] --dry-run: nada foi escrito
```

**Três defeitos que só a execução achou**, todos corrigidos aqui:

- **`recovery-pack` perguntava a coisa errada.** Usava `preflight.sh airbyte`
  como "há janela parada?", e o preflight responde outra coisa: quanto custa
  **subir** mais um ambiente. Com o Airbyte já de pé ele somava 4,9 GB que
  ninguém ia usar e recusava o pacote por falta de memória. `preflight.sh
  trabalho` passa a ser a pergunta isolada.
- **`pg_restore` não existe no *host*.** Vive nos contêineres — o projeto fixa a
  imagem do PostgreSQL por *digest* e não exige cliente instalado em quem
  clona. O `verify` passou a listar os *dumps* por dentro do contêiner.
- **A lista de artefatos citava um arquivo que não existe** (`diario.json`) e
  deixava para trás dois que existem (`manifesto-<hash>.json`). Passou a ser
  padrão (`data/legacy/*.json`), com os copiados listados no manifesto — e é
  dessa lista que a devolução sai, em vez de refazer a adivinhação do outro lado.

**O que esta entrega não mediu, e continua sendo de B5:** **nenhuma restauração
foi feita.** O `pg_restore` em destino povoado — dependências entre objetos,
permissões dos cinco papéis, substituição efetiva e propagação de erro — não foi
exercitado; o re-base foi planejado e **não aplicado** (o `--dry-run` é leitura);
a sequência de nove passos nunca rodou de ponta a ponta; e a guarda de
identidade nunca enfrentou um Airbyte recém-instalado. `pg_restore --list`
confere o pacote, não a restauração — e continua sendo isso.

**Revisão da entrega — 21/09/2026 (RVE-01, 03, 04, 05, 06, 07, 10, 15, 16; `REVISAO.md`).**
A rodada do outro agente sobre B0–B4 trouxe 17 achados, 12 bloqueantes, e o parecer estava
certo no essencial: **o verde dos testes não fechava as lacunas**. O que ela mediu e o que
mudou, no que é declaração:

- **a URL da guarda era recusada pela API real** (`createdAt|DESC` cru → `400 Malformed URI`):
  a query passa por `urlencode`, e a contraprova real devolveu 43 jobs;
- **o passo 5 conferia só SCD e quarentena**, e o passo 9 aceitou um estado sem os certificados
  retidos, com gerações só positivas e sem fatia nova — ambos passam a executar o contrato inteiro
  da §6: contagens das três fontes, Alembic, `governance._versions`, corte do livro, certificados,
  classes/nulos e a **partição das linhas por geração** (`rebase.assinatura`, invariante ao
  re-base e gravada no manifesto como `oraculo_particao`); o passo 9 ainda compara os **dois
  caminhos** por chave + 16 colunas, saldo por armazém/SKU e soma dos deltas, a memória de
  exclusões (`oraculo_exclusoes`, sem a coluna da captura selecionada) e relaciona o acréscimo
  às capturas certificadas **depois do corte** — a identidade que o Airbyte devolveu;
- **o re-base confere a partição dentro da transação** e recua em violação; **medido em banco
  isolado**: 40 tabelas em 10,9 s, `customers` −28..−1, idempotente, partição igual ao manifesto;
- **`pg_restore` com código 1 era aceito como aviso** — é `n_errors > 0`; passa a
  `--single-transaction` (implica `--exit-on-error`) com o diagnóstico inteiro. **Medido em banco
  isolado**: destino vazio 4,8 s e povoado 6,4 s, 48 tabelas/423.377 linhas = manifesto; com uma
  view dependente fora do dump, recusa (`cannot drop table … other objects depend on it`) e o
  banco intocado;
- **faltava o passo operacional de D50**: `docker/airbyte_jobs.sh` + `make recovery-airbyte-jobs`,
  entre `airbyte-up` e `sync-airbyte`, lê o próximo valor da **sequência** (com `is_called`), avança
  ao retido só se preciso, e para na premissa que falhar. Premissa medida no Airbyte 2.2.0:
  `jobs.id` identity, `public.jobs_id_seq` em 43 = `max(id)`;
- **a serialização colidia** (nulo × `\N`, separador dentro do texto) **e separava equivalentes**
  (fuso, escala de `numeric`, `memoryview`): linha = JSON tipado, `FORMATO = 2` no manifesto e
  recusado quando diferente;
- **refazer o pacote apagava o anterior antes do primeiro dump**: nasce em `candidato.em-montagem/`
  e só substitui inteiro;
- **o manifesto não tinha `seed`/`as_of_date`/tamanhos**: o gerador passa a registrar os
  parâmetros efetivos (`data/source/geracao.json`), o manifesto ganha `geracao` (com `None` e
  motivo quando não há registro — nunca o padrão do YAML), `tamanhos` e campos obrigatórios.

**Um defeito que só a execução achou**, além dos 17: `_linhas` fixava `stream_results` na
conexão, e o `update` do re-base saía embrulhado em `DECLARE … CURSOR FOR update`. A opção passou
para a instrução. Suíte: 394 → **437 passed, 8 skipped**. O candidato de 20/09 era do formato 1;
**foi refeito** com a árvore limpa (corte `2026-09-21T19:27:54+00:00`, código `118416f`) e
conferido contra os bancos vivos; as saídas literais estão na §10 do `REVISAO.md`.

**O que continua sendo de B5:** a sequência de ponta a ponta; o `pg_restore` nos bancos do
projeto (o medido foi o dump da memória, em banco isolado; as fontes não foram restauradas em lugar
nenhum); o passo 9 depois de uma captura nova real; o `setval` real de `avancar-jobs` (o instalado
já estava em 43); e a guarda contra um Airbyte recém-instalado.

**Segunda rodada — 23/09/2026 (RVE2-01, 05; `REVISAO.md` §11–12).** Duas ausências que passavam
por presença, e mais duas que a aplicação achou:

- **o passo 9 aceitava a falta da auditoria da captura nova** — o acréscimo da quarentena só era
  filtrado pelo `snapshot_id`, e nada a mais não é nada faltando. O acréscimo passa a ser igual,
  por contagem **e** digest, ao que a classificação da captura rejeitou
  (`trusted.legacy_classifications`, de que a quarentena é `select *` — medido igual na 43:
  3.207 linhas, mesmo digest); captura sem rejeição tem acréscimo vazio e passa. O `jobId` vem do
  passo 8 (`sync-legacy JOB_EM=`) e `--job` é obrigatório. **Achado próprio na mesma sonda:** os
  dois caminhos do livro vazios eram "iguais" — agora precisam ter o tamanho do livro na origem;
- **restaurar os artefatos não restaurava a ausência** — o registro de geração de uma carga
  posterior (o `seed-data` de B5 o cria antes da restauração) sobrevivia, e o próximo pacote o
  atribuía à origem restaurada. O que o pacote não traz sai do caminho **renomeado**
  (`.anterior-a-restauracao-<instante>`), nunca apagado. **Achado próprio:** o `copy2` sobre
  `data/legacy/manifesto.json` escrevia **através do link**, no manifesto do lote apontado — onde o
  diário de mutações grava. O pack passa a registrar `artefatos_links` (campo obrigatório) e a
  restauração refaz o link.

Suíte: 437 → **461 passed, 8 skipped**. O candidato de 21/09 não tinha `artefatos_links`:
**refeito** com a árvore limpa (corte `2026-09-23T20:53:54+00:00`, código `8c04106`) e conferido contra os bancos
vivos. Continua sendo de B5, além do que está acima: o passo 9 com uma captura nova de verdade, o
Beam real encerrando pelo SIGINT, e `restore-artefatos` no clone.

---

## 7. B5 — o ciclo do zero, medido

**Pré-condição:** B0–B4 entregues, pacote candidato montado e verificado, Execução Local
corrigida nos seis desvios da §0 (senão o roteiro está errado antes de começar).

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
   `docs-check`, e `pytest -m "not integracao"`. O `make check` completo fica **intacto** e roda
   na linha 4 da §7.3, depois das duas ingestões. O que `check-offline` pular é listado com
   motivo.

   **A seleção offline foi varrida inteira, não só o arquivo do parecer (RV12-3-06; a contagem
   corrigida pelo RV12-5-01).** Com uma sonda que substitui `Engine.connect` e a chamada do `dbt`
   por falha, e com variáveis de conexão **presentes** — sem elas os guardas de `skip` escondem o
   acesso —, dos **169** testes selecionados a sonda interceptou **três acessos**, e deles
   dependem **quatro** testes (§16.6):

   | Teste | O que tenta | Hoje |
   |---|---|---|
   | `test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao` | `dbt compile` | **falha** |
   | `test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai` | SQL no armazém | **falha** |
   | `test_consumo.py::test_toda_view_de_consumo_responde` | SQL no armazém, pela fixture `engine` | pula limpo |
   | `test_consumo.py::test_as_dezesseis_perguntas_estao_publicadas` | a **mesma** fixture, já resolvida | pula limpo, sem abrir uma segunda conexão |

   **Três acessos não são três testes:** `engine` é fixture de **escopo de módulo**
   (`tests/test_consumo.py`), resolve uma vez e serve os dois testes de consumo — a sonda vê um
   acesso, e dele dependem dois. Os quatro ganham a marca `integracao` — o `test_consumo.py`
   inteiro, que já estava previsto, e os dois de `test_legacy_classification.py`, que não estavam.
   Os outros **165** não abrem conexão nem chamam dbt. **Limite da sonda [declarado]:** ela intercepta `Engine.connect` e o `dbt` por
   subprocesso; acesso por outro caminho (psycopg cru, HTTP) não seria visto — a prova que fecha é
   a execução do `check-offline` num clone sem bancos nem caches, com as variáveis de conexão
   presentes, e é ela que roda aqui.

### 7.3 O ciclo, na ordem certa — cada linha sob `make medir`

A ordem **não** é a da Execução Local §3 de hoje: o *streaming* vem antes do primeiro
`dbt-build` completo (RV12-04), e a §3 é corrigida para dizer isso.

| # | Cenário | Alvos | De pé | `ATE` | O que a linha prova |
|---|---|---|---|---|---|
| 1 | Base | `up` → `migrate` → `seed-data` → `migrate-legacy` → `seed-legacy` | bancos | — | migrações do zero; cobertura (`test_cobertura`, manifesto do legado novo) |
| 2 | Carga | `airbyte-up` → `airbyte-config` → `sync-airbyte` → `sync-legacy` | + Airbyte | — | `raw`, `raw_legacy`, a primeira captura certificada — a identidade é o `jobId` devolvido, não `1` por definição (RV12-4-05); o pico da etapa |
| 3 | Streaming — o *snapshot* | `make medir CENARIO=streaming` (sem `LIMITE`: sobe, `stream-run` sob guarda, corte = origem, `stream-wait`, encerra) | + streaming (pausa o Airbyte) | interno ao cenário | o livro quente igual à origem (comparação da §3.2: chave + as 16 colunas de `COLUNAS_DO_EVENTO`, lidas da tupla, e o saldo por armazém/SKU — os quatro zeros); Beam encerrado ao fim |
| 4 | Transformação | `airbyte-up` (pausa o streaming) → `dbt-build` → `check` | + Airbyte | — | o primeiro `build` completo: `PASS=`, `caminhos_de_ingestao_reconciliam`, as oito fronteiras |
| 5 | Orquestração | `airflow-up` → `dag-run` | + Airflow (Airbyte de pé: o par permitido) | `dag-wait` | 13 tarefas `success`, tempo da DAG, a captura seguinte certificada (identidade lida do `jobId` devolvido) |
| 6 | Streaming — eventos novos | `make medir CENARIO=streaming LIMITE=n` (sobe, `stream-run` sob guarda, produz, **corte lido depois do produtor**, `stream-wait`, encerra) → `stream-alerts` | + streaming (Airbyte e Airflow pausados **pelo preflight de B0**) | interno ao cenário | os `n` eventos novos chegam (não só o *snapshot*); alerta emitido; Beam encerrado ao fim |
| 7 | Reconciliação dos caminhos | `airbyte-up` → `sync-airbyte` → `dbt-build` | + Airbyte | — | os dois caminhos iguais com os eventos novos |
| 8 | Catálogo | `docs-generate` → `catalog` | bancos | — | tempo; `sensitivity --check`, `lineage --check` sem diferença; `curl` na porta do `dbt-docs` no diário |
| 9 | Recuperação | `recovery-restore RESTAURAR=1` (a sequência da §6, passo a passo, cada um medido) → `recovery-promote` | conforme o passo | — | C4 inteira: as fontes **e a memória** de volta — capturas, certificados, SCD e a **quarentena** (D51); o `pg_restore` em destino **povoado**, com dependências, permissões e erros propagados; o livro igual; a memória de exclusões renascida; **as versões SCD iguais ao manifesto** pelo oráculo canônico; **a auditoria da quarentena contendo a do manifesto — contagem e conteúdo por chave, com multiplicidade** (RV12-4-02), mais o acréscimo da captura nova conferido à parte; o **re-base das gerações** conferido (D52), inclusive a preservação da equivalência de geração por tabela (RV12-4-01); a guarda D50 dispara **antes do disparo do job** com o Airbyte novo, a sequência é avançada, a captura seguinte é certificada acima da 43 |

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

1. **Capacidade**: §2.12 com a tabela medida; §3 reescrita para D49 **e D51** (conteúdo —
   quarentena incluída —, limite, sequência com o re-base do passo 4b) e "entregue em …" com o
   caminho do pacote aprovado; tabela de situação.
2. **Execução Local**: as §2–§4 foram corrigidas **antes** de B5, porque são o roteiro dele — o
   preparo do clone (`dbt deps` em `install`, `make tools`, `check-offline`), o ciclo com o
   *streaming* antes do primeiro *build* e os alvos novos (versão 1.13, 24/09/2026). O que resta
   aqui: conferi-las contra o diário de B5; a §3.2 apontando para a sequência de restauração; a §5
   com a detecção por rótulos **e a consulta de trabalho por DAG**; a §6 com a armadilha do
   `PG_VERSION` conferida e a regra da sequência do Airbyte.
2b. **ADR-0044**: nas *Consequências*, a guarda de identidade da captura — **antes do disparo do
   *job*, em todo ponto de entrada da conexão legada** (RV12-4-03), e como rede em `decidir`, que
   recusa o certificado e não protege o bruto retroativamente (D50) — e o re-base das gerações na
   restauração, com a preservação da equivalência de geração por tabela (D52 + RV12-4-01), cada
   uma com data e referência à decisão, preservando o texto aceito.
3. **Governança**: a lista de segredos tratados, se houver (ou o dono que B6 fixar); e na §8, o
   ponteiro de que a retenção `permanent` passa a ter respaldo no pacote de recuperação — uma
   linha com link para a Capacidade §3, que é quem descreve o pacote. Não repetir o conteúdo.
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
- Enfraquecer a conferência de intrusas da certificação para fazer a prova passar — alternativa
  descartada em D52; o dado retido é que sai do caminho, não a regra.
- D43 — adiada para a fase GCP.

---

## 10. As decisões do Owner — D45 a D50 em 18/09/2026, D51 e D52 em 19/09/2026

Nenhum ADR novo: nenhuma troca ferramenta, camada ou modelagem. D49 e D51 são consequência dos
ADRs 0037/0044/0045 sobre o conteúdo do pacote, e a Capacidade §3 é quem passa a dizê-la; D50 e
D52 são consequência do ADR-0044, que as recebe nas *Consequências*. Registro em
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

### D51 — a auditoria da quarentena — decidida em 19/09/2026 sobre o RV12-3-01

O que está em jogo, medido: `quarantine.rejected_legacy_records` tem **63.802** linhas de
auditoria em 8 pares (versão de catálogo, impressão do tratamento); uma reconstrução do zero
reproduz **3.207** — a fatia da captura corrente sob o tratamento vigente — e **não** as outras
**60.595**, que são as auditorias que o rebuild da captura corrente não recalcula. (Nem todas de
tratamento extinto: **9.586** ainda usam a versão 9 vigente, de capturas que a classificação
corrente já não enxerga — correção da quarta rodada, RV12-4-05, que não altera a decisão.) `dbt_project.yml` e a
[Governança §8](docs/governanca_de_dados.md#8-retenção) declaram a quarentena `permanent`,
"nunca descartada sem decisão registrada", e a revisão 4 a listava como reconstruível pelo dbt.

| Opção | A favor | Contra |
|---|---|---|
| **Entra no pacote** (`pg_dump -n quarantine`, restaurada antes do `dbt-rebuild`) — **decidida** | Cumpre a retenção já declarada; é a mesma lógica de D49 — o pacote guarda o que nenhuma reconstrução reproduz — aplicada ao que ficara de fora por premissa falsa; o modelo já retém sozinho ao reler a tabela anterior | Um *dump* e um *restore* a mais; um oráculo a mais no manifesto |
| Perda explicitamente decidida | Pacote menor, sequência mais curta | A retenção `permanent` ganharia exceção; C4 fecharia perdendo 60.595 linhas de evidência |
| Só evidência em arquivo (CSV/parquet no pacote) | Preserva a evidência sem complicar a reconstrução | A auditoria deixa de ser consultável pelo papel `auditor` e a reconciliação não a enxerga |

---

### D52 — as gerações do bruto num Airbyte novo — decidida em 19/09/2026 sobre o RV12-3-02

O que está em jogo, medido: `raw_legacy` retém as gerações **1–28**, uma por *job* (9 a 43).
`captura.medir_recebido` recusa como `inconsistent` a captura cuja geração contenha linha de
outro `sync_id` — e um Airbyte novo recomeça a geração em 1, em cima das linhas retidas. Avançar
só a sequência de *jobs* (D50) não alcança isso. Nenhum certificado guarda a geração e só
`captura.py` a lê.

| Opção | A favor | Contra |
|---|---|---|
| **Re-basear as gerações retidas no *restore*** (faixa negativa, passo 4b) — **decidida** | Não depende de nenhum interno do Airbyte; não muda o contrato do ADR-0044; a conferência de intrusas continua inteira na faixa nova; um passo idempotente e testável dentro de código versionado | Reescreve um metadado das linhas retidas — a geração deixa de corresponder ao histórico do Airbyte nessa coluna |
| Avançar também o contador de gerações | Simétrico a D50; não toca no dado retido | Passa a depender de **dois** internos não documentados; se o segundo não for alcançável na versão instalada, a linha 9 de B5 não fecha |
| Marca-d'água da restauração na certificação | Independente do Airbyte, sem tocar no dado | Muda o contrato de certificação (ADR-0044) e enfraquece, por construção, a detecção dentro da faixa retida |
| Limite declarado: pacote só restaurável na instalação de origem | Nada a implementar | A primeira captura posterior sai `inconsistent`; C4 fecha com lacuna |

---

## 11. Riscos deste plano

- **`reset` e as três desmontagens são destrutivos** e o pacote é a única volta — por isso B4
  antes, `verify` antes do `reset`, e o inventário vazio colado antes de `up`.
- **Tempo de relógio de B5** (~2 h de trocas + sincronizações + dois *snapshots* + a
  restauração); não cabe num fim de tarde. O estado da estação é anotado, não controlado.
- **Divergência entre Execução Local e realidade** é o achado esperado — **seis** já conhecidas
  (§0), corrigidas antes de B5; as que B5 achar, corrigidas antes de fechar. Cada rodada de
  revisão achou mais uma sem executar nada: é a razão de B5 medir em vez de conferir a olho.
- **`stream-wait` sem corte** mediria para sempre: `ATE_SEQ` é obrigatório.
- **R11**: o preflight decide — **depois de B0**; até lá, ele não vê o Airflow, e `make stream-up`
  com Airflow de pé sobe os dois. `FORCE=1` só com a sua autorização, e **nunca** herdado por um
  alvo composto (§6). **B0 pode piorar antes de melhorar:** corrigido só o nome, o preflight
  passaria a recusar toda troca, e é por isso que a consulta entra no mesmo bloco.
- **Interno do Airbyte** (D50): o avanço da sequência de *jobs* é o **único** passo do plano que
  depende de algo que a ferramenta não promete; está isolado, para com mensagem, e a guarda não
  depende dele. D52 tirou o segundo — a geração — dessa dependência de propósito.
- **O re-base das gerações escreve no bruto retido** (D52): é a única escrita da restauração
  sobre dado que veio do pacote. Idempotente, sem tocar em `sync_id`, conteúdo ou hash, e provada
  assim antes de B5 — mas é escrita, e é por isso que está declarada aqui e não só na §6. **A
  quarta rodada mostrou que a idempotência não basta:** sem preservar a equivalência de geração, o
  segundo ciclo funde as faixas e recusa uma captura correta (RV12-4-01). O contrato inteiro está
  na §6, passo 4b, e a implementação que não o alcançar **para** em vez de improvisar.

---

## 12. O que pedir ao outro agente

1. **Deste plano — cumprido e encerrado em 20/09/2026.** Seis rodadas (§13 a §19): a quinta deu
   os quatro ajustes funcionais por incorporados e declarou não haver impedimento para B0–B4, e a
   sexta voltou **sem achado nenhum**. Não há mais o que pedir sobre o desenho. **Isso não é
   aceite de código nem autorização do ciclo destrutivo de B5** — os dois continuam sendo decisão
   do Owner, e são decisões distintas entre si.
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

---

## 15. Parecer da revisão 4 — terceira rodada, 19/09/2026

**Escopo:** `cbe1148`, este plano e D45–D50 em `docs/pendencias.md`, confrontados com os
consumidores, os ADRs e consultas de leitura ao ambiente. **Parecer: ainda não pronto para
execução integral; há 3 bloqueantes e 3 ajustes.** As decisões do Owner foram consideradas
tomadas. Não se propõe trocar a identidade da captura nem escolher outro conteúdo do pacote
por conta do revisor: há uma premissa de reconstrução falsa e uma continuidade operacional
incompleta a resolver antes de destruir o estado atual.

### 15.1 Conferência da segunda rodada

Esta tabela avalia o desenho da revisão 4; não atesta uma implementação dos blocos.
As respostas do autor nas tabelas anteriores permanecem como registro das respectivas rodadas.

| Achado | Resultado desta rodada |
|---|---|
| RV12-2-01 | **Atendido quanto ao descarte dos snapshots:** `dbt-rebuild` separa reconstrução e apagamento do SCD. O oráculo ainda não confere todo o conteúdo nem todos os intervalos: RV12-3-05. A implementação e a restauração continuam por provar. *Revisão 5: o oráculo foi refeito em RV12-3-05.* |
| RV12-2-02 | **Parcial:** D50 resolve a escolha sobre a identidade dos jobs. O certificado também depende das gerações por stream, que o avanço de `jobs_id_seq` não resolve: RV12-3-02. O ponto da recusa e a prova de colisão precisam preservar o bruto anterior: RV12-3-04. *Revisão 5: fechados em RV12-3-02 (D52) e RV12-3-04.* |
| RV12-2-03 | **Parcial:** rótulos do Compose são adequados para a descoberta, e B0 vem na ordem correta. A consulta de trabalho que usará o nome resolvido ainda é inválida no Airflow instalado: RV12-3-03. *Revisão 5: fechado em RV12-3-03 — B0 passa a corrigir a consulta e mais dois consumidores.* |
| RV12-2-04 | **Atendido quanto à separação do `check`:** o build completo fica depois das ingestões. A seleção offline tem mais dois testes de banco sem a marca, além de `test_consumo.py`: RV12-3-06. *Revisão 5: fechado em RV12-3-06, com a seleção varrida inteira.* |
| RV12-2-05 | **Atendido no plano:** a expressão agora casa ENV, YAML e JSON na contraprova; a dispensa por extensão saiu. Isso não equivale a executar o futuro detector histórico ou provar ausência de segredos. |
| RV12-2-06 | **Atendido no plano:** corte posterior ao produtor, cenário concorrente, prazo, propagação de falha e encerramento do que o medidor iniciou estão declarados. A gestão real dos processos ainda precisa da prova prevista em B1/B5. |

A revisão das consequências de D49 encontrou também o RV12-3-01: a memória permanente não
se limita aos três schemas escolhidos no pacote. O ponto novo é a auditoria que o próprio
modelo de quarentena retém, não uma preferência por guardar todo o armazém.

### 15.2 Achados desta rodada

| ID | Veredito | Onde / consequência | Ajuste proposto | Situação |
|---|---|---|---|---|
| RV12-3-01 | **bloqueante** | **§6, conteúdo e exclusões do pacote (linhas 305–314 da revisão 4): `quarantine` não é integralmente reconstruível.** `rejected_legacy_records.sql` conserva a relação anterior por captura, versão e impressão do tratamento; sem ela, produz apenas a auditoria da captura corrente sob o tratamento vigente. A leitura do banco encontrou **63.802** linhas em **7** versões, **51.009** anteriores à v9. O reset de B5 perde essas auditorias, que `dbt-rebuild` não recupera dos dumps descritos. `dbt_project.yml` e Governança §8 declaram essa retenção permanente. | Corrigir a premissa de D49 antes de B4/B5: registrar com o Owner o destino dessa auditoria permanente, seja preservação no pacote, seja perda explicitamente decidida. Não tratar sua omissão como simples reconstrução pelo dbt. Se preservada, incluir oráculo por captura/versão/impressão e conferir o conteúdo histórico após o rebuild. | **Fechado na revisão 5 — D51 decidida pelo Owner:** `quarantine` entra no `warehouse_memoria.dump` e é restaurada **antes** do `dbt-rebuild`, que a relê e retém (§6). A leitura de conferência confirmou o achado e o quantificou: 63.802 linhas em 8 pares (versão, impressão), das quais um rebuild reproduz **3.207** e perde **60.595** (§0, §16). O manifesto ganha o oráculo por `(captura, versão, impressão)` e o passo 9 o compara. `rejected_shipment_deliveries` está vazia e é derivada — não tem retenção própria. |
| RV12-3-02 | **bloqueante** | **§6, D50 (linhas 363–384): avançar só o job não garante certificação após reinstalar.** `captura.medir_recebido` conta como intrusa qualquer linha de outro `sync_id` na mesma `_airbyte_generation_id`, por tabela. O bruto atual de `customers` já tem as gerações 1–28. Na contraprova, job **44** acima da captura **43**, com conteúdo correto, reutilizando a geração **3** de um job antigo, recebeu **`inconsistent`** pela função real. O estado de gerações da conexão nova não foi preservado nem alinhado pela regra operacional proposta. | Completar a continuidade operacional de D50 também para as gerações de cada stream, antes da primeira carga sobre o bruto restaurado. Confirmar os internos necessários e testar o par job/geração contra o estado retido; não enfraquecer a conferência de intrusas para fazer a prova passar. Se a solução exigir mudar o contrato de certificação, devolver a consequência ao Owner. | **Fechado na revisão 5 — D52 decidida pelo Owner:** medido que `raw_legacy` retém as gerações **1–28**, uma por *job* de 9 a 43, e que nenhum certificado guarda a geração — só `captura.py` a lê (§0, §16). Em vez de um segundo interno do Airbyte, a restauração **re-baseia as gerações retidas** para faixa negativa (passo 4b), idempotente e sem tocar em `sync_id`, conteúdo ou hash. A conferência de intrusas não é enfraquecida: é o dado retido que sai do caminho. Contraprova (d) da §6: *job* 44 em geração reutilizada → `inconsistent` hoje, `complete` depois do re-base. |
| RV12-3-03 | **bloqueante** | **§2.1, consulta de trabalho após resolver o contêiner (linhas 145–160): corrigir o nome não basta.** A chamada vigente é `airflow dags list-runs --state running -o plain`, sem `dag_id`. Executada no scheduler real por Compose, saiu **2**, exigindo esse argumento; com `fluxo_batch`, saiu **0** e retornou `[]`. Mantida a chamada em B0, o preflight passa a enxergar o Airflow, mas sempre o considera indeterminado e recusa a troca mesmo ocioso. | Incluir em B0 a correção da consulta e a interpretação de sua saída, cobrindo o conjunto de DAGs do projeto. Provar ocioso, execução ativa e falha de consulta. A contraprova de trabalho precisa alcançar o caminho `--trocar`: `make preflight ALVO=streaming` sozinho já recusa pelo conflito de ambientes, antes de consultar DAGs. | **Fechado na revisão 5 — B0 cresce:** confirmado na máquina que `airflow dags list-runs --state running` **exige `dag_id`** (código 2, Airflow 3.2.2) e que corrigir só o nome faria o preflight recusar toda troca. B0 passa a especificar a consulta inteira — por DAG, com o conjunto lido de `airflow dags list -o json` **sem repetidos** (a versão instalada devolve a mesma DAG seis vezes) e o JSON separado do ruído do Alembic, que sai no **stdout** —, os três desfechos, e a contraprova pelo caminho `--trocar` (`make stream-up`), nunca por `make preflight ALVO=streaming`, que recusa antes pelo conflito. Dois defeitos vizinhos entraram junto: a pausa que anuncia o que não fez e o nome fixo em `test-carga` (§2.1, com o inventário completo dos consumidores por nome). |
| RV12-3-04 | **ajuste** | **§6, ponto da guarda e teste de identidade reutilizada (linhas 367–384): recusar o certificado pode acontecer depois da mistura.** O ponto sugerido, `captura.decidir`, roda depois de o Airbyte terminar o append. Negar a tentativa nova não remove as linhas já escritas sob um `sync_id` antigo nem invalida o certificado antigo: a contraprova conservou a captura 43 elegível, agora lendo duas linhas onde havia uma. Avançar a sequência depois dessa recusa não desfaz a contaminação. | Tornar explícito que a verificação operacional bloqueia a escrita antes de disparar o job, para CLI e DAG. Executar a contraprova intencional de colisão em destino isolado, preservando o único pacote e seu bruto; exigir que o hash das capturas anteriores permaneça igual. Preservar também o reenvio de tentativa já concluída, que hoje devolve o certificado gravado sem remedição. | **Fechado na revisão 5:** a guarda deixa de morar só em `captura.decidir` — que roda depois do *append* — e passa a ser **pré-condição de disparar o *job***, nos dois chamadores (CLI e DAG), junto da fase 1. A guarda em `decidir` fica como rede, porque é a regra pura sem banco. A contraprova de colisão intencional roda em **destino isolado**, exigindo que o bruto e o hash da captura 43 fiquem idênticos depois da recusa; o reenvio de tentativa concluída continua devolvendo o certificado gravado (§6). |
| RV12-3-05 | **ajuste** | **§6, manifesto e passo 9 (linhas 308 e 359–361): o oráculo SCD pode aceitar conteúdo diferente.** O hash proposto contém apenas ID e datas, sem atributos. Além disso, a concatenação com `dbt_valid_to = NULL` resulta em nulo, que `string_agg` ignora. Na sonda SQL, mudar um atributo histórico ou o início de uma versão vigente manteve contagem, IDs e hash do plano iguais. No banco atual, **1.574 de 1.575** linhas de `scd_customer` estão com `dbt_valid_to` nulo. | Usar serialização canônica de todas as colunas de cada versão, incluindo nulos de forma explícita, ordenação estável e multiplicidade. Acrescentar contraprovas que alterem atributo de versão fechada e validade de versão vigente sem mudar ID ou contagem. | **Fechado na revisão 5:** a sonda própria reproduziu o defeito — o hash proposto saiu **igual** para o original, para um atributo histórico alterado e para o início de uma versão vigente alterado, porque `x ‖ NULL` é nulo e `string_agg` o descarta, com 1.574 das 1.575 linhas vigentes (§0, §16). O oráculo passa a ser o `md5` de uma **serialização canônica de todas as colunas** de cada versão, com nulo explícito, ordenação estável e multiplicidade; as três contraprovas entram em `tests/test_recovery.py` (§6). |
| RV12-3-06 | **ajuste** | **§7.2, `check-offline` (linhas 428–432): marcar só `test_consumo.py` não separa todos os acessos a banco.** `pytest -m "not integracao"` ainda seleciona `test_configuracao_divergente_da_impressao_recusa_a_compilacao` e `test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai`, em `test_legacy_classification.py`. Com variáveis de conexão presentes e indisponibilidade simulada, ambos falharam: um tentou `dbt compile`, outro SQL. Sem essas variáveis eles pulam; esse sucesso dependeria do ambiente do shell. | Marcar também esses testes e conferir a seleção offline inteira. Provar `check-offline` num clone sem bancos/caches, inclusive com variáveis de conexão presentes, mantendo o `check` completo e os motivos de skips. | **Fechado na revisão 5, e a varredura foi inteira:** sonda sobre os **169** testes da seleção offline, com variáveis de conexão presentes — exatamente **três** tocam ambiente: os dois de `test_legacy_classification.py` (falham) e `test_consumo.py::test_toda_view_de_consumo_responde` (pula limpo). Os três ganham a marca; os outros 166 não abrem conexão nem chamam dbt. O limite da sonda está declarado, e a prova que fecha é o `check-offline` no clone sem bancos nem caches (§7.2, §16). **Retificado na revisão 7 (RV12-5-01):** são três **acessos** e **quatro** testes — a fixture `engine` de `test_consumo.py` é de escopo de módulo e serve dois —, e o resto da seleção é **165**. A marca vale para o módulo inteiro, como esta linha já mandava. |

### 15.3 Evidências

**Consultas reais, somente leitura.** `psql -v ON_ERROR_STOP=1` via
`docker compose --env-file .env -f docker/docker-compose.yml exec -T warehouse_db`, em
transações `BEGIN READ ONLY`. Agregações de `quarantine.rejected_legacy_records` e amostra
de gerações/jobs de `raw_legacy.customers`:

```text
 auditorias_totais | auditorias_anteriores_a_v9 | versoes
-------------------+----------------------------+---------
             63802 |                      51009 |       7

 geracao | job | linhas
---------+-----+--------
       1 |   9 |     75
       3 |  11 |     75
      28 |  43 |     72
```

Agregação de `snapshots.scd_customer`, também em leitura:

```text
 total | correntes
-------+-----------
  1575 |      1574
```

**Certificação e retenção, sem serviços.** Comando:
`.venv/bin/python /tmp/rv12_r3_eYpS0J/contraprovas.py`.
SQLite em memória, linhas fictícias, `captura.medir_recebido`, `conteudo.hash_no_banco` e
`captura.decidir` reais; limitada a leitura a uma tabela e adaptado apenas `ANY(array)` para
`IN`. Para elegibilidade e quarentena, renderizadas as declarações reais
`certificadas_sql()` e `rejected_legacy_records.sql` sobre tabelas fictícias. Saída:

```text
JOB_NOVO_ACIMA_DO_RETIDO True
GERACOES_NOVO (3,)
INTRUSAS_NA_GERACAO_REUTILIZADA 1
CONTEUDO_NOVO_CONFERE True
DECISAO_REAL_COM_JOB_NOVO inconsistent
CAPTURAS_AINDA_ELEGIVEIS_APOS_RECUSA [43]
LINHAS_LIDAS_SOB_CERTIFICADO_ANTIGO 2
AUDITORIAS_COM_ANTERIOR [(44, 9), (43, 8), (43, 9)]
AUDITORIAS_SEM_ANTERIOR [(44, 9)]
CASAMENTOS_REGEX_REVISAO4 env 1
CASAMENTOS_REGEX_REVISAO4 yaml 1
CASAMENTOS_REGEX_REVISAO4 json 1
```

Os jobs 44 e a recusa são cenários simulados; não houve nova captura real nem reinstalação.
A regra D50 ainda não existe: a sonda da recusa mostra o efeito de negar a tentativa nova
sem alterar o certificado antigo, e não uma execução de implementação futura. Os três
casamentos finais aplicam literalmente a expressão da §4 a valores fictícios.

**Consulta de trabalho no Airflow instalado.** Comandos de leitura, sem disparar DAG:

```text
$ docker compose --env-file .env -f docker/docker-compose.airflow.yml exec -T airflow_scheduler airflow dags list-runs --state running -o plain
Usage: airflow dags list-runs [-h] [-e END_DATE] [--no-backfill]
                              [-o (table, json, yaml, plain)] [-s START_DATE]
                              [--state queued, running, success, failed] [-v]
                              dag_id
airflow dags list-runs command error: the following arguments are required: dag_id, see help above.
```

Código de saída **2**; acima estão a abertura e a última linha da saída, omitida a ajuda
intermediária. A segunda consulta, incluindo a DAG:

```text
$ docker compose --env-file .env -f docker/docker-compose.airflow.yml exec -T airflow_scheduler airflow dags list-runs fluxo_batch --state running -o json
[]
```

Código de saída **0**; omitidas as mensagens de inicialização do Alembic. Não foi medida a
troca de ambiente com DAG ativa: esta sonda prova a sintaxe e o caso ocioso da consulta.

**Oráculo SCD, SQL real com dados fictícios em CTE.** Duas versões, uma fechada e outra com
`dbt_valid_to` nulo. Comparados o hash proposto
`md5(string_agg(dbt_scd_id || dbt_valid_from || dbt_valid_to, '' order by dbt_scd_id))`
e um hash da linha contendo também o atributo. Saída de uma consulta `READ ONLY`:

```text
          caso           | linhas | ids |          hash_do_plano           |          hash_conteudo
-------------------------+--------+-----+----------------------------------+----------------------------------
 inicio_vigente_alterado |      2 |   2 | 7bc92ac24bf4907e58fe8833fb36171e | e46d77f0463fd075c0e0a75f06839b60
 original                |      2 |   2 | 7bc92ac24bf4907e58fe8833fb36171e | a601ab7ad201dd5d896667bf276d2ae8
 payload_alterado        |      2 |   2 | 7bc92ac24bf4907e58fe8833fb36171e | aafa800d753c48beacfd7c8e24a0008f
```

**Seleção offline.** A coleta real, sem executar testes, já deixa os dois acessos de fora
da exclusão por marcador:

```text
$ .venv/bin/pytest --collect-only -q -m 'not integracao' tests/test_legacy_classification.py
tests/test_legacy_classification.py::test_required_fields_and_partial_unique_predicates_come_from_models
tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao
tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai

3/13 tests collected (10 deselected) in 0.06s
```

Execução da mesma seleção com o plugin de sonda `/tmp/rv12_r3_eYpS0J/sem_banco.py`, variáveis
de conexão fictícias e `--tb=no -p no:cacheprovider`: o plugin substitui `Engine.connect` e
somente a chamada de `dbt compile` por falha de banco indisponível. Não abre conexões nem
executa dbt; mede quais testes selecionados tentam fazê-lo. Saída:

```text
FAILED tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao
FAILED tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai
2 failed, 1 passed, 10 deselected in 0.37s
SONDA_ACESSOS_SELECIONADOS {'sql': 1, 'dbt_compile': 1}
```

Essas duas falhas são contraprovas intencionais do recorte offline, não resultados de um
`make check` nem regressões introduzidas por implementação da Etapa 12.

### 15.4 Limites e orientação para a execução posterior

- **B0:** no caminho operacional, os consumidores por nome estão em `preflight.sh` e nos
  pares de pausa/retomada do Makefile, já abrangidos pelo texto. `dag-run` e `dag-status`
  usam `compose exec`, que resolve o serviço corretamente. Há ainda o nome fixo do banco
  em `test-carga`, fora do ciclo de B5; conferir se a promessa de outro nome de projeto
  pretende cobrir esse alvo também. Retomada precisa consultar contêineres parados, e a
  ausência do scheduler numa composição parcialmente ativa não pode significar ociosidade.
- **Restauração em destino populado:** a linha 9 ocorre depois de oito cenários, quando
  os schemas já existem. A implementação deve provar substituição efetiva, dependências,
  permissões e propagação dos erros de `pg_restore`, além de preservar a memória recuperada.
  Isso não foi exercitado nem se presume validado por `pg_restore --list`.
- **Notas em ADR aceito:** a consequência de D50 deve ser acrescentada com data e referência
  à decisão, preservando o texto aceito. Esta revisão não alterou ADR, retenção ou pendência.

**Não verificado nesta rodada:** implementação de B0–B4; clone e instalação de dependências;
varredura integral de segredos ou links; criação/verificação/restauração/promoção de pacote;
ajuste dos contadores internos do Airbyte; novo snapshot do CDC; sobrevivência real dos
processos do medidor; `make check` completo, DAG ou ciclo de B5; medições de memória/tempo;
tag e aceite de M5. Os números anteriores da §0 não foram repetidos. Nenhum dado de trabalho,
configuração de serviço, contêiner ou pipeline foi alterado pelo revisor; a alteração no
repositório é somente este parecer, e as sondas ficaram em `/tmp/rv12_r3_eYpS0J`.

---

## 16. Conferência da revisão 5 — o que foi medido para aplicar a terceira rodada

Não é parecer: é o que o autor mediu **antes** de aceitar cada achado da §15 e escrever a
revisão 5. Tudo aqui é leitura. Nenhum dado de trabalho, serviço, contêiner ou pipeline foi
alterado; as consultas ao armazém correram em transações `begin read only` pelo contêiner
`warehouse_db`, e as do Airflow são comandos de listagem, sem disparar DAG.

### 16.1 A quarentena — o que um rebuild reproduz, e o que não

```text
 catalog_version | treatment_fingerprint | linhas | capturas
-----------------+-----------------------+--------+----------
               2 | anterior-a-D34        |   6418 |        1
               3 | 8e7c2c0ba25a41f0      |   2280 |        1
               3 | anterior-a-D34        |  19243 |        7
               4 | 59841c98f23ac771      |   2280 |        1
               5 | 6df1d183d38bb9eb      |   2280 |        1
               7 | f1714cf5e32351a6      |   8659 |        3
               8 | 8710ca3fbdcfce5b      |   9849 |        3
               9 | 607e6288f4f57e39      |  12793 |        4

 auditorias_totais | versoes
-------------------+---------
             63802 |       7

 remessas_rejeitadas
---------------------
                   0
```

A fatia que uma reconstrução refaz é a da captura corrente sob o tratamento vigente, e só ela —
`trusted.legacy_classifications` cobre **uma** captura:

```text
 snapshot_id | catalog_version | treatment_fingerprint | linhas | rejeitadas
-------------+-----------------+-----------------------+--------+------------
          43 |               9 | 607e6288f4f57e39      |  12744 |       3207

 max_certificado
-----------------
              43

 auditorias_que_um_rebuild_nao_reproduz
----------------------------------------
                                  60595
```

As outras três capturas sob a versão 9 (36, 38, 39 — 3.470, 2.909 e 3.207 linhas) já não são
recalculadas: a classificação corrente só enxerga a selecionada. É o que torna a quarentena
memória, e não derivado.

**Retificação (RV12-4-05, 20/09).** A quarentena tem **15** `snapshot_id` distintos, não 11 — o 11
citado na §0 era o das capturas completas, outro universo. E das 60.595, **9.586** ainda estão sob
a versão 9 vigente: o que as define é que o rebuild da captura corrente **não as recalcula**, não
que o tratamento esteja extinto. A §0 e D51 foram corrigidas na revisão 6.

### 16.2 As gerações retidas no bruto do legado

```text
 geracao | job | linhas          geracao | job | linhas
---------+-----+--------        ---------+-----+--------
       1 |   9 |     75               15 |  25 |     75
       2 |  10 |     75               16 |  26 |     75
       3 |  11 |     75               17 |  28 |     75
       …  (uma geração por job, sem buraco)               …
      14 |  24 |     75               28 |  43 |     72

 geracao_min | geracao_max | geracoes
-------------+-------------+----------
           1 |          28 |       28
```

Uma geração por *job*, de 9 a 43, sem reuso dentro desta instalação. `governance.legacy_captures`
não tem coluna de geração (DDL da migração `0001_legacy_captures`), e a varredura de
`_airbyte_generation_id` no repositório acha uma única leitura funcional —
`src/mvp_ed1/legacy/captura.py` — além da declaração de coluna nos `.yml` de fonte, sem teste.

### 16.3 A consulta de trabalho do Airflow

```text
$ … exec -T airflow_scheduler airflow dags list-runs --state running -o plain
Usage: airflow dags list-runs [-h] [-e END_DATE] [--no-backfill]
                              [-o (table, json, yaml, plain)] [-s START_DATE]
                              [--state queued, running, success, failed] [-v]
airflow dags list-runs command error: the following arguments are required: dag_id, see help above.
rc=2
```

Com a DAG, e com o `stderr` descartado — o ruído **continua aparecendo**, porque sai no `stdout`:

```text
$ … exec -T airflow_scheduler airflow dags list-runs fluxo_batch --state running -o json 2>/dev/null
2026-09-19T23:29:36.977507Z [info     ] setup plugin alembic.autogenerate.schemas …
… (seis linhas de plugin)
[]
rc=0
```

Com o `stdout` descartado, não sobra nada: o `stderr` está vazio. E a enumeração de DAGs repete:

```text
$ … exec -T airflow_scheduler airflow dags list -o json 2>/dev/null   # (ruído omitido)
[{"dag_id": "fluxo_batch", …}, {…}, {…}, {…}, {…}, {…}]   ← a mesma DAG, seis vezes
```

`airflow version` → **3.2.2**. O projeto tem uma DAG (`airflow/dags/fluxo_batch.py`), e
`dag-status` já filtra esse ruído com `grep -viE 'alembic|plugin'` — o preflight não.

### 16.4 O alvo de pausa que anuncia o que não fez

Simulação sem efeito, com `echo` no lugar do `docker stop`, e o Airflow de pé:

```text
$ docker ps --format '{{.Names}}' | grep '^airflow_'; echo "grep rc=$?"
grep rc=1
$ docker ps --format '{{.Names}}' | grep '^airflow_' | xargs -r echo PARARIA >/dev/null 2>&1 \
    && echo 'MENSAGEM EMITIDA: "Airflow pausado."' || echo 'MENSAGEM EMITIDA: "já não estava de pé."'
MENSAGEM EMITIDA: "Airflow pausado."
```

`docker ps` da máquina no mesmo instante: `mvp_ed1-airflow_scheduler-1`,
`mvp_ed1-airflow_apiserver-1`, `mvp_ed1-airflow_dag_processor-1`, `mvp_ed1-airflow_db-1`, todos
`Up`. `airflow-resume` tem a mesma forma.

### 16.5 O oráculo SCD proposto não distingue conteúdo

Duas versões fictícias em CTE — uma fechada, uma vigente com `dbt_valid_to` nulo —, o hash da
revisão 4 ao lado de um que inclui o atributo e escreve o nulo:

```text
          caso           | linhas | ids |          hash_do_plano           |         hash_canonico
-------------------------+--------+-----+----------------------------------+----------------------------------
 inicio_vigente_alterado |      2 |   2 | 528b72f7c0512edef27c185ff82597dd | 57793e3cf20634c2e36159e659c25d29
 original                |      2 |   2 | 528b72f7c0512edef27c185ff82597dd | 15e6297a625d13644fce201093ec44d1
 payload_alterado        |      2 |   2 | 528b72f7c0512edef27c185ff82597dd | 9a2bf60fc29114d392dbe9bbee444f8c
```

O hash do plano é o **mesmo** nos três. No armazém real, `snapshots.scd_customer` tem 1.575
linhas e 1.574 vigentes — o oráculo se reduziria à única versão fechada. São quatro *snapshots*:
`scd_coupon`, `scd_customer`, `scd_product`, `scd_support_agent`.

### 16.6 A seleção offline, varrida inteira

Sonda de `pytest` que substitui `Engine.connect` e a chamada do `dbt` por falha, com variáveis de
conexão fictícias **presentes** — sem elas os guardas de `skip` escondem o acesso:

```text
SONDA_SQL tests/test_consumo.py::test_toda_view_de_consumo_responde
SONDA_SQL tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai
SONDA_DBT tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao
FAILED tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao
FAILED tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai
2 failed, 165 passed, 2 skipped, 130 deselected in 74.24s (0:01:14)
```

169 selecionados (`169/299 tests collected` no `--collect-only`), três tocam ambiente, dois
falham. As duas falhas são contraprovas da sonda, não regressões: a suíte real não roda assim.

**Retificação (RV12-4-05, 20/09).** São **três acessos** interceptados, não três testes: a fixture
de `test_consumo.py` é de módulo e serve **dois** testes, ambos dependentes de ambiente e ambos
pulando sem abrir uma segunda conexão. Os testes dependentes de ambiente são **quatro**, e é o
módulo inteiro que se marca — como a §15.2 já pedia em RV12-3-06.

### 16.7 O que **não** foi verificado nesta conferência

Nada de B0–B6 foi implementado: não há `medir.sh`, `recovery.py`, `docs_check.py`, `dbt-rebuild`,
`check-offline` nem pacote. Não foram executados: `make check`, DAG, sincronização, *streaming*,
`pg_dump`, `pg_restore`, o re-base das gerações, o avanço de contador do Airbyte, nem qualquer
desmontagem. O re-base de D52 e a sobrevivência da quarentena ao `dbt-rebuild` são **raciocínio
sobre o código lido**, não medição — a prova dos dois é a de B4/B5, e está escrita lá como tal.
Não foi confirmado onde o Airbyte guarda o contador de gerações, e o plano deixou de depender
disso de propósito. Os números da §0 anteriores a 19/09 não foram remedidos. A sonda da §16.6 vê
`Engine.connect` e `dbt` por subprocesso — outro caminho de acesso passaria por ela.

---

## 17. Parecer da revisão 5 — quarta rodada, 20/09/2026

**Escopo:** revisão 5 na **árvore de trabalho**, sobre `cbe1148`, incluindo a conferência da
§16 do autor. D45–D52 foram consideradas decisões tomadas. Esta seção é avaliação; não
implementa B0–B6, não altera as decisões nem encerra pendências. As seções anteriores foram
preservadas.

**Veredito: o plano, como escrito, ainda não está pronto para execução integral.** D51 resolve
a omissão da quarentena e D52 tem um caminho viável sem enfraquecer a conferência de intrusas.
Restam **quatro ajustes funcionais e uma observação**. Não encontrei novo motivo para trocar o
conteúdo do pacote, a identidade da captura ou o contrato de certificação. Os ajustes podem
entrar como requisitos da implementação de B0/B4; precisam estar resolvidos antes do ciclo
destrutivo de B5. **Não são apenas achados de forma.**

### 17.1 Conferência dos achados da terceira rodada

“Atendido” nesta tabela qualifica o desenho, não uma implementação ou uma restauração real.

| Achado | Resultado desta rodada |
|---|---|
| RV12-3-01 | **Atendido quanto ao conteúdo e à ordem, por D51.** A quarentena volta antes do rebuild. O modelo retém a tabela anterior e a materialização `table` instalada cria a substituta antes de remover a anterior. Uma projeção do SQL real, somente leitura, conservou as **63.802** linhas antigas e acrescentou **3.207** sob uma captura fictícia nova. O oráculo do manifesto ainda não prova conteúdo: RV12-4-02. |
| RV12-3-02 | **Atendido para a separação entre o estado atual e a próxima carga; fechamento parcial para restaurações sucessivas.** A sonda com `medir_recebido` e `decidir` reais passou de `inconsistent` a `complete` depois de separar a geração retida; uma intrusa nova continuou produzindo `inconsistent`. O hash antigo não mudou. Falta especificar a preservação das classes de geração quando o pacote já contiver negativos: RV12-4-01. |
| RV12-3-03 | **Atendido quanto ao defeito original e ao inventário operacional examinado.** Confirmados Airflow **3.2.2**, argumento obrigatório, seis entradas da mesma DAG e logs no stdout. A consulta por DAG é válida; os consumidores literais encontrados no Makefile e no preflight estão na §2.1. Restam fila e prazo da consulta: RV12-4-04. |
| RV12-3-04 | **Parcial.** Antecipar a guarda ao disparo é correto, e a prova isolada preserva o bruto de trabalho. Porém, “junto da fase 1” não basta para cobrir todas as entradas existentes; a frase que atribui proteção ao caminho que escapou para a fase 2 continua excessiva: RV12-4-03. |
| RV12-3-05 | **Atendido no desenho.** Todas as colunas, nulo explícito, ordem estável e multiplicidade corrigem o oráculo. A contraprova em CTE reproduziu a insensibilidade do hash antigo e a distinção pelo completo. Duplicar uma linha também muda a contagem; a frase contrária é só correção de redação. |
| RV12-3-06 | **Atendido no desenho e conferido na seleção inteira.** Reproduzidos **169/299** selecionados, **três chamadas interceptadas**, **165 passed**, **2 failed**, **2 skipped**, **130 deselected**. Marcar o módulo `test_consumo.py` inteiro e os dois testes indicados cobre também o segundo teste de consumo, que compartilha a fixture e pula sem abrir uma segunda conexão. |

### 17.2 Achados desta rodada

| ID | Veredito | Onde / consequência | Ajuste proposto | Situação |
|---|---|---|---|---|
| RV12-4-01 | **ajuste** | **§6, passo 4b e seu oráculo: sinal negativo e idempotência não garantem preservação da conferência de gerações.** Depois de uma recuperação pode haver geração antiga `-1` e nova `1`. Um rebase por simples negação das positivas, mantendo negativas, satisfaz os dois critérios escritos, mas reúne ambas em `-1`. A sonda mudou o veredito real de `complete` para `inconsistent` sem mudar o hash. O plano não manda usar essa fórmula: o contraexemplo demonstra que o contrato ainda admite uma implementação errada. Separar por job, por sua vez, poderia esconder intrusas que originalmente compartilhavam uma geração. | Exigir, **por tabela**, preservação da equivalência de geração entre todas as linhas retidas: gerações iguais continuam iguais; diferentes continuam diferentes, inclusive perante os negativos já existentes. Os novos valores negativos precisam ocupar faixa livre. Conferir domínio estritamente negativo e não nulo, não apenas ausência de positivos. Acrescentar contraprovas de segundo pacote/restauração e de intrusa já presente no conjunto retido. Isso completa D52 sem alterar `sync_id`, conteúdo ou a regra de intrusas; uma implementação que não consiga preservar essas propriedades deve recuar e devolver a consequência ao Owner. | **Atendido — revisão 6.** §6, passo 4b, ganhou *O contrato do re-base, escrito por inteiro*: preservação da equivalência de geração **por tabela** (inclusive perante os negativos já presentes), faixa estritamente negativa livre, domínio conferido como negativo **e não nulo**, idempotência — e o recuo obrigatório com devolução ao Owner se a implementação não alcançar. O oráculo do passo 5 deixou de ser "nenhuma geração positiva" e passou a exigir a mesma quantidade de classes e a mesma partição. Contraprovas de segundo pacote e de intrusa já retida na *Prova sem banco*, e um re-base por simples negação é recusado pelo teste. Risco atualizado na §11. |
| RV12-4-02 | **ajuste** | **§6, manifesto e passo 9: contagem por captura/versão/impressão não prova continência “linha por linha”.** Trocar o payload, os motivos ou uma linha por outra do mesmo grupo mantém esse oráculo verde. A projeção de retenção confirmou o mecanismo de D51, mas não torna suficiente a conferência descrita. É a mesma classe de insuficiência corrigida no oráculo SCD. | Guardar também um resumo canônico das **linhas completas**, com multiplicidade, por chave do manifesto incluindo `source_system`; comparar conteúdo e contagem de cada fatia histórica após o rebuild. Conferir separadamente o acréscimo da captura nova, usando a identidade efetivamente devolvida pelo Airbyte. Testar alteração de payload/motivo e perda compensada por duplicação. A continência é o critério certo; a contagem isolada é que não a implementa. Alinhar também a linha 9 da §7.3, que ainda diz “igual ao manifesto”, com essa regra. | **Atendido — revisão 6.** O manifesto (§6) passa a guardar, por chave `(source_system, snapshot_id, catalog_version, treatment_fingerprint)`, a contagem **e** um resumo canônico das linhas completas com multiplicidade; o passo 9 confere conteúdo por fatia histórica e o acréscimo da captura nova **à parte**, pela identidade devolvida pelo Airbyte; a linha 9 da §7.3 foi alinhada. Contraprovas de troca de payload, troca de motivo e perda compensada por duplicação na *Prova sem banco*. |
| RV12-4-03 | **ajuste** | **§6, guarda D50: há entrada existente que não passa pela fase 1 nem pela fase 2.** `python -m mvp_ed1.airbyte sync --connection legacy_para_raw_legacy`, sem `--certificar-legado`, chama `/jobs` pelo ramo direto de `main`. A CLI também aceita `reset` para essa conexão. Acrescentar a guarda apenas ao fluxo certificado e à fase 1 da DAG deixa essas entradas fora. `decidir` não desfaz um append já ocorrido, e nesse ramo nem é chamado. | Declarar a pré-condição em **todo disparo da conexão legada** pelos pontos de entrada do projeto: encaminhar a CLI sem flag pelo fluxo protegido ou recusá-la antes do POST; tratar explicitamente o reset incompatível com a retenção. Na DAG, verificar na tarefa que efetivamente dispara, inclusive quando reexecutada sem repetir a fase 1. As contraprovas devem exigir **zero POSTs** nos caminhos recusados, além do hash antigo intacto. Descrever a guarda em `decidir` como recusa do certificado, sem atribuir a ela proteção retroativa do bruto. | **Atendido — revisão 6.** §6, D50 item 1, ganhou *"Junto da fase 1" não cobre as entradas que existem*: o `sync` da CLI sem `--certificar-legado` é encaminhado ao fluxo protegido ou recusado **antes do POST**; o `reset` da conexão legada é tratado explicitamente; na DAG a verificação fica na tarefa que efetivamente dispara, valendo também quando ela é reexecutada sozinha. As contraprovas (f) e (g) exigem **zero `POST /jobs`** nos caminhos recusados. A guarda em `decidir` passou a ser descrita como recusa do certificado, sem proteção retroativa. |
| RV12-4-04 | **ajuste** | **§2.1, consulta de trabalho usada também pelo corte de B4: só `running` não cobre a fila, e “não responde” não tem prazo.** A CLI filtra o estado exato solicitado; um DagRun `queued` fica fora e pode começar entre a consulta e a pausa. Uma consulta pendurada não chega por si ao desfecho “indeterminado”. Enumerar DAGs não é uma consulta à saúde do processo scheduler: o comando lê os metadados. | Cobrir `queued` e `running`, inclusive em DAG pausada, e definir prazo limitado por consulta e para a verificação completa; expiração deve recusar como indeterminada. Acrescentar casos de DAG recém-registrada, pausada com trabalho, fila e resposta lenta/pendurada, além dos casos já previstos. Não filtrar `is_paused=true` como sinônimo de ociosidade. O inventário de nomes não precisa de outra reformulação. | **Atendido — revisão 6.** §2.1: `queued` passa a contar como trabalho ao lado de `running`, a enumeração não filtra `is_paused`, cada consulta tem prazo próprio e a verificação inteira um prazo total — expirar é indeterminado, portanto bloqueio —, e ficou escrito que enumerar DAGs lê metadados, não a saúde do *scheduler*. Casos novos na *Prova*: `queued`, DAG pausada com execução, DAG recém-registrada e consulta lenta ou pendurada. Inventário mantido como estava. |
| RV12-4-05 | **observação** | **§0, §6 e texto sobre as medições.** A quarentena tem **15**, não 11, valores distintos de `snapshot_id`; 11 é outro universo, o das capturas completas citado antes. Das **60.595** auditorias fora da captura corrente, **9.586** ainda usam a v9, portanto não são todas de tratamentos extintos. A frase sobre duplicar linha sem mudar contagem também é falsa. E os três acessos interceptados da sonda não equivalem a apenas três testes dependentes de ambiente: há dois testes na fixture de consumo. | Corrigir essas formulações sem alterar D51: são auditorias que **o rebuild da captura corrente não recalcula**. Distinguir chamadas observadas de testes dependentes da fixture. Manter a contraprova de duplicação, dizendo que ela muda hash **e** contagem. Os IDs 1/2/44 do roteiro devem ser exemplos; os oráculos executáveis usam o `jobId` retornado, pois o contador também atende a conexão principal e a resets. | **Atendido — revisão 6.** §0: quarentena com **15** capturas distintas, com a nota de que as 11 completas são outro universo; as 60.595 redescritas como "o rebuild da captura corrente não recalcula", com as **9.586** sob a v9; a seleção offline passa a distinguir **três acessos** de **quatro** testes dependentes de ambiente. §6: a contraprova de duplicação muda hash **e** contagem; a tabela do pacote e D51 (§10) corrigidas na mesma frase, sem alterar a decisão. Números de *job* declarados exemplos de redação, com os oráculos lendo o `jobId` devolvido (§6 e §7.3). Retificações também na §16.1 e §16.6, junto das medições que as originaram. |

### 17.3 Evidências e respostas às quatro perguntas

As consultas ao armazém usaram `psql -X -v ON_ERROR_STOP=1`, com `BEGIN READ ONLY`
(ou `BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY`) e `SET LOCAL statement_timeout`.
Não houve escrita nos dados de trabalho. Nas saídas coladas, foram removidos apenas espaços
finais para a formatação do documento. As sondas e saídas estão em
`/tmp/rv12_r4_tyVzZB`; SQLite foi usado apenas em memória com dados fictícios.

**D52 — a separação funciona, mas é preciso preservar os grupos retidos.** Conferência das
40 tabelas declaradas por `schema.tabelas()`, seguida do agrupamento de `customers` por geração
e `sync_id`:

```bash
docker compose --env-file .env -f docker/docker-compose.yml exec -T warehouse_db \
  psql -X -U mvp_warehouse -d warehouse_db -v ON_ERROR_STOP=1 \
  < /tmp/rv12_r4_tyVzZB/geracoes.sql
```

Saída literal:

```text
BEGIN
SET
 tabelas | linhas | minimo | maximo | nulos | zeros | negativos
---------+--------+--------+--------+-------+-------+-----------
      40 | 356867 |      1 |     28 |     0 |     0 |         0
(1 row)

 geracao | job | linhas
---------+-----+--------
       1 |   9 |     75
       2 |  10 |     75
       3 |  11 |     75
       4 |  12 |     75
       5 |  13 |     75
       6 |  14 |     75
       7 |  15 |     75
       8 |  16 |     75
       9 |  17 |     75
      10 |  18 |     75
      11 |  21 |     75
      12 |  22 |     75
      13 |  23 |     75
      14 |  24 |     75
      15 |  25 |     75
      16 |  26 |     75
      17 |  28 |     75
      18 |  29 |     71
      19 |  30 |     71
      20 |  31 |     72
      21 |  32 |     71
      22 |  33 |     71
      23 |  34 |     71
      24 |  35 |     71
      25 |  36 |     71
      26 |  38 |     75
      27 |  39 |     72
      28 |  43 |     72
(28 rows)

COMMIT
```

Isso confirma a amostra da §16.2 e amplia a conferência do domínio: no estado observado, não
há geração nula, zero ou negativa. Não é prova sobre o estado de um segundo pacote.

Comando da sonda: `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python /tmp/rv12_r4_tyVzZB/sondas.py`.
Ela chama `captura.medir_recebido`, `conteudo.hash_no_banco` e `captura.decidir`; a única
adaptação de SQL é `ANY(array)` para `IN` no SQLite. O bruto fictício distingue job retido 11,
job novo 44 e uma intrusa nova 45. Trecho literal:

```text
ANTES_REBASE {'intrusas': 1, 'decisao': 'inconsistent'}
APOS_REBASE {'intrusas': 0, 'decisao': 'complete', 'hash_antigo_igual': True}
INTRUSA_NOVA {'intrusas': 1, 'decisao': 'inconsistent'}
SEGUNDO_REBASE_POR_NEGACAO {'antes': [(11, -1), (44, 1)], 'depois': [(11, -1), (44, -1)], 'idempotente': True, 'sem_positiva': True, 'geracoes_distintas': 1}
SEGUNDO_REBASE_CERTIFICACAO {'antes': 'complete', 'depois': 'inconsistent', 'hash_igual': True, 'intrusas': 1}
```

O primeiro caso sustenta D52: o hash de conteúdo não inclui `_airbyte_generation_id`, e
`sync_id` continua identificando a captura. O segundo caso **não é um defeito inevitável de
D52**: demonstra por que “negativo e idempotente” precisa da condição adicional de
injetividade por geração. Mantidas essas propriedades, e a premissa de que as cargas novas
usam gerações não negativas, as faixas não se encontram. Reenviar uma tentativa já concluída
continua devolvendo o certificado gravado; isso não remede a integridade do bruto retido.

A consulta `docker exec airbyte-abctl-control-plane crictl images airbyte/destination-postgres`
inventariou a imagem local abaixo (linha de interesse, alinhamento entre colunas omitido):

```text
docker.io/airbyte/destination-postgres 3.0.16 1e2d318abc326 361MB
```

Examinei também a
[fonte do conector na revisão de publicação dessa versão](https://github.com/airbytehq/airbyte/blob/a65bba879e685874be339c8e67a6cc5f11c2b6c4/airbyte-integrations/connectors/destination-postgres/src/main/kotlin/io/airbyte/integrations/destination/postgres/write/PostgresWriter.kt)
e o [caminho append do CDK no mesmo commit](https://github.com/airbytehq/airbyte/blob/a65bba879e685874be339c8e67a6cc5f11c2b6c4/airbyte-cdk/bulk/core/load/src/main/kotlin/io/airbyte/cdk/load/table/directload/DirectLoadTableStreamLoader.kt):
a seleção com mínimo de geração zero usa append, e esse caminho conserva a tabela existente,
sem filtro que elimine linhas por geração negativa. **É leitura de fonte, não execução do
conector nem verificação do bytecode da dependência instalada.** Não identifiquei nesse caminho
uma razão para rejeitar D52; a prova de restauração seguida de sincronização continua necessária.
A afirmação “só `captura.py` lê” tem alcance do repositório do projeto, não de toda a ferramenta.

**D51 — a relação anterior é lida antes de ser descartada pelo dbt.** Foram examinados
`dbt/models/quarantine/rejected_legacy_records.sql`, a configuração `table` em
`dbt/dbt_project.yml`, os hooks e a macro instalada
`.venv/lib/python3.11/site-packages/dbt/include/global_project/macros/materializations/models/table.sql`.
A ordem é: criar a relação intermediária com o SQL do modelo; renomear a anterior; promover a
intermediária; remover o backup depois. Não há ramificação de `--full-refresh` nessa macro que
elimine a relação anterior antes de compilar/executar a seleção de retenção. Os hooks examinados
não a derrubam. Os snapshots têm materialização própria, sem descarte por `--full-refresh`.

A sonda renderizou a **declaração Jinja real** da quarentena. A entrada é uma CTE que projeta
`trusted.legacy_classifications` trocando apenas `snapshot_id` por **900044**, identidade
fictícia para esta prova; não foi criada captura alguma. O resultado foi comparado com toda a
quarentena anterior usando `to_jsonb` da linha e **`EXCEPT ALL`**, preservando multiplicidade.
No mesmo arquivo, uma CTE de uma linha altera o payload mantendo a chave e a contagem.

```bash
docker compose --env-file .env -f docker/docker-compose.yml exec -T warehouse_db \
  psql -X -U mvp_warehouse -d warehouse_db -v ON_ERROR_STOP=1 \
  < /tmp/rv12_r4_tyVzZB/quarentena.sql
```

Saída literal:

```text
BEGIN
SET
 anteriores | projetadas | anteriores_ausentes | novas
------------+------------+---------------------+-------
      63802 |      67009 |                   0 |  3207
(1 row)

 contagens_iguais | linhas_perdidas
------------------+-----------------
 t                |               1
(1 row)

COMMIT
```

Assim, **continência mais acréscimo é o oráculo correto**. O total projetado **67.009** é da
CTE desta sonda, não de um rebuild realizado nem uma previsão incondicional de B5. A segunda
consulta prova que a contagem, sozinha, aceita a perda de conteúdo. Um rebuild com relação
anterior ausente continua gerando só a fatia corrente; D51 evita esse caminho restaurando-a
antes. Dependências e permissões de um restore real em destino povoado permanecem por provar.

**Guarda antes do disparo — há ramo direto da CLI.** A mesma `sondas.py` chamou `airbyte.main`
com token, resolução da conexão, espera e `_chamar` substituídos por registradores. **Nenhuma
requisição HTTP foi enviada.** Saída literal:

```text
CLI_SEM_FLAG {'comando': 'sync', 'rc': 0, 'chamadas': [('/jobs', {'connectionId': 'legado-ficticio', 'jobType': 'sync'})], 'passou_certificador': False}
CLI_SEM_FLAG {'comando': 'reset', 'rc': 0, 'chamadas': [('/jobs', {'connectionId': 'legado-ficticio', 'jobType': 'reset'})], 'passou_certificador': False}
```

A finalidade é mapear os pontos de entrada existentes que a futura guarda precisa cobrir,
não acusar ausência de uma implementação que esta revisão não pediu. Na DAG,
`iniciar_captura_do_legado` e `sincronizar_legado_para_raw_legacy` são tarefas distintas; a função
`sincronizar` chama `airbyte.sincronizar` antes de `captura.registrar_job`. Logo, reexecutar só
a tarefa de sincronização não reexecuta automaticamente a pré-condição posta na fase 1.

**B0 — nomes, DAGs pausadas/nova DAG e espera.** Comandos de leitura no scheduler existente:

```text
$ docker compose --env-file .env -f docker/docker-compose.airflow.yml exec -T airflow_scheduler airflow version
3.2.2
$ docker compose --env-file .env -f docker/docker-compose.airflow.yml exec -T airflow_scheduler airflow dags list-runs --state running -o plain
Usage: airflow dags list-runs [-h] [-e END_DATE] [--no-backfill]
                              [-o (table, json, yaml, plain)] [-s START_DATE]
                              [--state queued, running, success, failed] [-v]
```

Trecho final literal do stderr; código de saída **2**:

```text
airflow dags list-runs command error: the following arguments are required: dag_id, see help above.
```

Com a DAG informada, código **0**; stdout literal:

```text
2026-09-20T05:54:15.145529Z [info     ] setup plugin alembic.autogenerate.schemas [alembic.runtime.plugins] loc=plugins.py:37
2026-09-20T05:54:15.145818Z [info     ] setup plugin alembic.autogenerate.tables [alembic.runtime.plugins] loc=plugins.py:37
2026-09-20T05:54:15.146101Z [info     ] setup plugin alembic.autogenerate.types [alembic.runtime.plugins] loc=plugins.py:37
2026-09-20T05:54:15.146368Z [info     ] setup plugin alembic.autogenerate.constraints [alembic.runtime.plugins] loc=plugins.py:37
2026-09-20T05:54:15.146543Z [info     ] setup plugin alembic.autogenerate.defaults [alembic.runtime.plugins] loc=plugins.py:37
2026-09-20T05:54:15.146721Z [info     ] setup plugin alembic.autogenerate.comments [alembic.runtime.plugins] loc=plugins.py:37
[]
```

`wc -c /tmp/rv12_r4_tyVzZB/airflow-running.err` devolveu:

```text
0 /tmp/rv12_r4_tyVzZB/airflow-running.err
```

`airflow dags list -o json` voltou a listar **seis** objetos, todos com
`dag_id="fluxo_batch"` e `is_paused="False"`. A leitura de
`inspect.getsource(dag_command.dag_list_dags)` e de `dag_list_dag_runs`, no contêiner instalado,
confirmou que a enumeração padrão lê `SerializedDagModel`, sem excluir DAGs pausadas, e a
consulta de execuções usa o estado exato em `DagRun.find`. **Uma nova DAG já registrada entra
sem lista fixa; uma DAG pausada não deve ser descartada da consulta.** Não foi criada uma nova
DAG nem alterado o estado da existente para produzir esse caso em ambiente real. Prazo de
resposta e fila são os complementos de RV12-4-04.

Varredura dos consumidores operacionais:

```bash
rg -n 'docker[[:space:]]+(exec|stop|start|ps)' Makefile docker src airflow \
  --glob '*.py' --glob '*.sh' --glob 'Makefile'
```

Agrupamento da saída, incluindo comentários e mensagens que também citam comandos:

```text
ARQUIVOS_COM_CONSUMIDORES {'Makefile': 9, 'docker/preflight.sh': 14}
```

Não apareceu outro consumidor operacional por nome fora dos grupos da §2.1 nesse escopo.
A consulta `docker ps --format '{{.Names}}'` foi salva em `docker-nomes.out`; repetir o pipeline
de pausa com essa lista e **`echo PARARIA` em lugar de `docker stop`** produziu:

```text
MENSAGEM_EMITIDA: Airflow pausado.
```

Nenhum contêiner foi parado. Confirma-se o defeito da §16.4; a futura pausa com rótulos e
verificação do estado resultante não foi exercitada.

**Conferência dos números da §16.** Agregações de `numeros.out`, em transação de leitura;
saída literal:

```text
BEGIN
SET
 auditorias | capturas | versoes | tratamentos
------------+----------+---------+-------------
      63802 |       15 |       7 |           8
(1 row)

                   capturas
----------------------------------------------
 {7,9,10,11,12,14,16,17,18,28,35,36,38,39,43}
(1 row)

 catalog_version |    impressao     | linhas | capturas
-----------------+------------------+--------+----------
               2 | anterior-a-D34   |   6418 |        1
               3 | 8e7c2c0ba25a41f0 |   2280 |        1
               3 | anterior-a-D34   |  19243 |        7
               4 | 59841c98f23ac771 |   2280 |        1
               5 | 6df1d183d38bb9eb |   2280 |        1
               7 | f1714cf5e32351a6 |   8659 |        3
               8 | 8710ca3fbdcfce5b |   9849 |        3
               9 | 607e6288f4f57e39 |  12793 |        4
(8 rows)

 snapshot_id | catalog_version |    impressao     | linhas | rejeitadas
-------------+-----------------+------------------+--------+------------
          43 |               9 | 607e6288f4f57e39 |  12744 |       3207
(1 row)

 remessas_rejeitadas
---------------------
                   0
(1 row)

 scd_linhas | vigentes
------------+----------
       1575 |     1574
(1 row)

COMMIT
```

As oito linhas por versão/impressão, **63.802**, **7**, **8**, **12.744**, **3.207**, a tabela
de remessas vazia e **1.575/1.574** conferem. A diferença **63.802 − 3.207 = 60.595** também.
A divergência é a quantidade de capturas atribuída à quarentena na §0, não a quantidade de
certificados completos. A consulta complementar encontrou **9.586** auditorias v9 fora da
captura 43, compatíveis com as três parcelas citadas em §16.1.

Para o SCD, `scd.sql` usou a fixture explícita
`('a', date '2026-01-01', date '2026-02-01', 'antigo')` e
`('b', date '2026-02-01', NULL::date, 'atual')`. Comparou a concatenação antiga com
`md5(string_agg((to_jsonb(c)-'caso')::text, E'\n' order by dbt_scd_id, dbt_valid_from))`,
alterando atributo fechado, início vigente e multiplicidade. Comando: o mesmo `psql` acima,
com entrada `/tmp/rv12_r4_tyVzZB/scd.sql`. Saída literal:

```text
BEGIN
SET
       caso       | linhas | ids |          hash_anterior           |          hash_completo
------------------+--------+-----+----------------------------------+----------------------------------
 duplicada        |      3 |   2 | ca1e1021c5e329d63603449fa331792b | 5d6391d513aaef10c66c5030132285a1
 inicio_alterado  |      2 |   2 | ca1e1021c5e329d63603449fa331792b | 5f2a7eb63445c0e5bd0dbfe82b271e4a
 original         |      2 |   2 | ca1e1021c5e329d63603449fa331792b | 39dfdfe25df024757f335f50d3ae34f9
 payload_alterado |      2 |   2 | ca1e1021c5e329d63603449fa331792b | 7c81d8de97ba89680dea6e419691c390
(4 rows)

 max_certificado
-----------------
              43
(1 row)

 v9_fora_da_captura_43
-----------------------
                  9586
(1 row)

COMMIT
```

Reproduzida a propriedade da §16.5. **Não reproduzi os bytes dos hashes lá publicados:** a
§16 não inclui a fixture nem o comando que os gerou. Os hashes acima pertencem à fixture
explicitada nesta rodada; não substituem os do autor como se fossem a mesma medição.

Sonda offline: variáveis de conexão fictícias presentes; `Engine.connect` e execução de
`dbt` por subprocesso interceptados antes do acesso. As variáveis de conexão usadas pela sonda eram fictícias;
caches/temporários desta execução ficaram em `/tmp`:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=/tmp/rv12_r4_tyVzZB .venv/bin/python -m pytest \
  -p sonda_offline -p no:cacheprovider -m 'not integracao' \
  --basetemp=/tmp/rv12_r4_tyVzZB/pytest -q -ra
```

Trecho final literal:

```text
SKIPPED [1] tests/test_consumo.py:59: armazém indisponível: SONDA: SQL interceptado, sem conexão
SKIPPED [1] tests/test_consumo.py:94: armazém indisponível: SONDA: SQL interceptado, sem conexão
FAILED tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao
FAILED tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai
2 failed, 165 passed, 2 skipped, 130 deselected in 65.13s (0:01:05)
SONDA_ACESSOS 3
SONDA_SQL tests/test_consumo.py::test_toda_view_de_consumo_responde (setup)
SONDA_DBT tests/test_legacy_classification.py::test_configuracao_divergente_da_impressao_recusa_a_compilacao (call)
SONDA_SQL tests/test_legacy_classification.py::test_a_identidade_do_vinculo_atravessa_a_tipagem_do_pai (call)
```

Coleta independente com `pytest --collect-only -q -m 'not integracao' -p no:cacheprovider`:

```text
169/299 tests collected (130 deselected) in 0.51s
```

Os **65,13 s** são desta execução; não validam nem contradizem os **74,24 s** medidos pelo
autor em outra carga da máquina. As duas falhas são as recusas provocadas pela instrumentação,
não falhas novas da suíte normal. O limite de cobertura da instrumentação declarado em §16.7
continua valendo.

### 17.4 O que não foi verificado e premissas que permanecem

- Não foram executados `pg_dump`, `pg_restore`, rebase no armazém, avanço de sequência,
  sincronização, DAG, produtor, Beam, build dbt, `make check`, troca de ambientes, reset ou
  desmontagem. O ambiente existente foi apenas consultado; nenhum segundo ambiente foi iniciado.
- Não foi provada a restauração dos três dumps em destino povoado, suas dependências,
  permissões dos papéis, propagação de erros ou comportamento perante interrupção. Não há
  pacote, clone novo ou implementação de B4/B5 validada por este parecer.
- A projeção da quarentena executa o SELECT do modelo; não executa a materialização completa.
  A sobrevivência ao rebuild tem apoio na leitura da macro e nessa projeção, não em um rebuild
  medido. O mesmo vale para a preservação efetiva dos snapshots depois da restauração.
- Não confirmei a tabela/sequência interna dos jobs, o primeiro job/geração de uma instalação
  nova nem a correspondência binária entre a dependência CDK instalada e a fonte consultada.
  A continuidade real do Airbyte, incluindo preservação de todo o bruto antigo após append,
  continua sendo validação da implementação. A separação de faixas pressupõe gerações novas
  não negativas e rebase que preserve os grupos; não autoriza ignorar intrusas.
- Não foram produzidos no Airflow real os cenários de DAG nova, pausada com execução, fila,
  indisponibilidade ou resposta lenta. Não foi exercitado `--trocar` nem o efeito das futuras
  pausas/retomadas. O inventário cobre os consumidores operacionais pesquisados, não uma
  garantia sobre comandos manuais externos ao projeto.
- B1–B3 receberam apenas a conferência relacionada a esta rodada, não uma nova auditoria
  integral. Não foram refeitos desempenho de ponta a ponta, varredura histórica de segredos,
  todos os links, nem as medições antigas da §0. Os valores de hash da fixture não publicada
  em §16.5 permanecem sem reprodução independente.

### 17.5 Prontidão

**Não está pronto para execução integral na redação atual.** O impedimento remanescente é a
precisão funcional do roteiro: o rebase precisa preservar os grupos também no segundo ciclo;
a quarentena precisa ser conferida pelo conteúdo; a guarda precisa alcançar o disparo em
todas as entradas do legado do projeto; e o corte de trabalho precisa cobrir fila e prazo.
São ajustes de comportamento e de critérios de aceitação, **não só de forma**.

**Há base suficiente para começar a implementação de B0–B4 incorporando esses ajustes.** Esta
rodada não encontrou razão para reabrir as escolhas D45–D52. A autorização do ciclo destrutivo
de B5 deve considerar os ajustes incorporados e as provas previstas na implementação; este
parecer não é aceite de código nem atestado de recuperação já realizada.

### 17.6 Retomada pelo autor — passagem ao Claude

O próximo passo é incorporar ao plano os achados **RV12-4-01 a RV12-4-05**, da §17.2,
seguindo o procedimento **Receber** de `.claude/skills/revisao/SKILL.md`. Ler `CLAUDE.md`
antes de editar. Atualizar as seções prescritivas afetadas, registrar a nova revisão no
cabeçalho e preencher a coluna *Situação* de cada achado com a alteração e sua referência,
ou justificar explicitamente uma recusa. Atualizar também o estado em `docs/pendencias.md`.

Preservar o parecer e suas evidências como registro desta rodada; as ressalvas da §17.4
continuam valendo até que novas verificações sejam executadas e documentadas. As saídas
coladas na §17.3 estão versionadas; os arquivos auxiliares citados em `/tmp` são temporários
e não devem ser presumidos disponíveis em outra sessão ou máquina.

Esta passagem prepara a revisão do plano. Não constitui autorização adicional para o ciclo
destrutivo de B5, aceite da implementação ou encerramento da etapa. D45–D52 permanecem
decididas; ADR aceito não deve ser reescrito. Ao concluir a incorporação, commitar o plano
atualizado e informar os achados atendidos e as validações ainda pendentes.

**Incorporado em 20/09/2026 — revisão 6.** Os cinco achados estão atendidos; onde cada um foi
parar está na coluna *Situação* da §17.2. O ciclo destrutivo de B5 **não** foi executado, e nada
de B0–B6 foi implementado: as ressalvas da §17.4 continuam valendo inteiras.

## 18. Parecer da revisão 6 — quinta rodada, 20/09/2026

**Escopo:** diff `a5f838b..f4991ae`, confrontado com as seções prescritivas do plano,
`src/mvp_ed1/airbyte.py`, `src/mvp_ed1/legacy/captura.py`,
`airflow/dags/fluxo_batch.py`, `docker/preflight.sh`, o modelo
`dbt/models/quarantine/rejected_legacy_records.sql`, `tests/test_consumo.py` e o ADR-0044.
Revisão documental e leitura de código; nenhuma execução do plano.

**Veredito:** os quatro ajustes funcionais da quarta rodada estão incorporados ao desenho.
Não identifiquei novo impedimento para implementar B0–B4. Resta uma observação de coerência
documental na incorporação de RV12-4-05; ela não muda o conjunto de testes que o plano manda
marcar. Este parecer não valida código futuro, não autoriza B5 nem encerra M5.

### 18.1 Conferência dos achados

| Achado | Resultado |
|---|---|
| RV12-4-01 | **Atendido no plano.** §6 exige preservar a partição de gerações por tabela, usar faixa livre negativa, conferir nulos e idempotência; inclui contraprovas do segundo ciclo e de intrusa retida. A regra permanece compatível com a detecção de intrusas de `captura.py`. |
| RV12-4-02 | **Atendido no plano.** Manifesto, passo 9 e §7.3 exigem contagem e conteúdo completo com multiplicidade por chave, além de conferir a captura nova separadamente. As contraprovas cobrem payload, motivo e perda compensada. |
| RV12-4-03 | **Atendido no plano.** A pré-condição alcança CLI sem flag, reset e tarefa de disparo da DAG reexecutada sozinha. A recusa exige zero POSTs; `decidir` deixa de receber a promessa de proteção retroativa. |
| RV12-4-04 | **Atendido no plano.** §2.1 inclui fila, DAG pausada, enumeração dinâmica e limites por consulta e total, com expiração bloqueante. Os valores dos prazos e seu comportamento efetivo serão conferidos na implementação. |
| RV12-4-05 | **Atendido parcialmente na redação.** §0, §6, D51 e retificações da §16 foram corrigidas; §7.2 ainda repete a contagem antiga, conforme RV12-5-01. |

### 18.2 Observação remanescente

| ID | Veredito | Onde / consequência | Ajuste proposto | Situação |
|---|---|---|---|---|
| RV12-5-01 | **observação** | **§7.2, seleção offline:** ainda afirma que exatamente três testes tocam ambiente e que os outros 166 não o fazem. `tests/test_consumo.py` contém dois testes dependentes da mesma fixture de módulo (`engine`), como a §0 e a retificação da §16.6 já reconhecem. A orientação de marcar o módulo inteiro está correta, mas a explicação e a contagem divergem dentro do roteiro vigente. | Distinguir os três acessos interceptados dos quatro testes dependentes, incluir o segundo teste de consumo na tabela ou apresentar a fixture como grupo de dois testes. Se mantida a base histórica de 169 selecionados, o restante é 165; preservar o limite de cobertura da sonda. | **Atendido — revisão 7.** A §7.2 passa a separar **três acessos** de **quatro testes**: a tabela ganhou `test_consumo.py::test_as_dezesseis_perguntas_estao_publicadas`, a fixture `engine` está apresentada como de escopo de módulo servindo os dois, e o resto da seleção é **165**, não 166. A base histórica dos 169 e o limite declarado de cobertura da sonda ficaram como estavam. Conferido na fonte antes de aplicar: `tests/test_consumo.py:25` (`scope="module"`), `:59` e `:94`. |

### 18.3 Validação e limites

`git diff a5f838b f4991ae --check` terminou com código **0**, sem saída. O diff da entrega
altera somente este plano e `docs/pendencias.md`; nenhum ADR foi alterado. A conferência dos
dois testes de consumo e da fixture foi por leitura do código, sem executar pytest.

Não foram refeitas as sondas nem as medições da §17.3. Não foram executados `make check`,
sincronizações, DAGs, consultas aos serviços, dumps, restaurações, trocas de ambientes ou
operações destrutivas. Os resultados históricos continuam atribuídos às rodadas que os
produziram. Continuam pendentes as provas de implementação e de recuperação da §17.4,
incluindo a continuidade real do Airbyte, o restore em destino povoado e a preservação
efetiva dos dados após o rebuild.

## 19. Parecer da revisão 7 — sexta rodada, 20/09/2026

**Escopo:** diff `f4991ae..0de1cc9`, com foco na resposta a RV12-5-01, na coerência entre
§0, §7.2 e a retificação da §16.6, e nas atualizações da §12 e de `docs/pendencias.md`.
Conferidos também os dois testes e a fixture de módulo de `tests/test_consumo.py` e os dois
testes indicados em `tests/test_legacy_classification.py`, por leitura do código.

**Veredito: sem novos achados. RV12-5-01 atendido no plano.** A §7.2 agora distingue os três
acessos interceptados dos quatro testes dependentes, inclui o segundo teste de consumo e
identifica a fixture compartilhada. O restante da base histórica de 169 selecionados é 165;
o limite de cobertura da sonda foi preservado. A retificação da §15.2 mantém o histórico
identificável, e a §12 e as pendências representam corretamente o alcance do parecer anterior.

Permanece a conclusão da §18: o desenho permite avançar à implementação de B0–B4. Não restam
achados de revisão do plano a incorporar no escopo conferido. O aceite do Owner, as provas
da implementação e a validação da recuperação são etapas distintas desta conferência.

**Validação:** `git diff f4991ae 0de1cc9 --check` terminou com código **0**, sem saída.
O diff altera somente o plano e `docs/pendencias.md`. Não foram executados testes, sondas,
pipelines ou restaurações nesta rodada; os números citados continuam sendo os registros
históricos das rodadas anteriores. Permanecem os limites da §17.4 e da §18.3.
