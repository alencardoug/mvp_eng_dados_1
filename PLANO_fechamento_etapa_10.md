# Plano — fechar os achados abertos da Etapa 10

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item. Escrito em 14/09/2026 sobre `a66f869`
> (`feat/troca-entre-ambientes-pesados`), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: o que está marcado **[medido]** tem saída de comando por trás; o que está
> marcado **[planejado]** é intenção. Os dois não se misturam (P5).
>
> **Revisão 2 — 14/09/2026, mesma data.** As seis decisões que a primeira versão deixava ao Owner
> (§12) foram tomadas antes de o plano ir à revisão. Onde a primeira versão dizia "proponho",
> esta diz "decidido", e a §12 registra a resposta de cada uma. O que o revisor recebe é o plano
> que vai ser executado.

---

## 0. Onde estamos

A Etapa 10 foi reaberta em 07/09/2026 e continua aberta pelo `REVISAO.md` (terceira revisão,
reavaliada em 08/09). Os achados que restam, com o veredito **do revisor**:

| # | Veredito | Uma frase |
|---|---|---|
| R09 | bloqueante | A DAG fixa **qual** captura lê, mas nada distingue carga nova de captura anterior reutilizada; "completa" só quer dizer "alguma linha nas 40 tabelas" |
| R10 | bloqueante | A exclusão física entre duas capturas completas — a razão de o ADR-0015 tratar o legado à parte — **não é detectada por nada** |
| R12 | bloqueante | O schema `legacy` nasce de `schema.ddl()` executado por `writer.criar_schema`, fora do ciclo Alembic de evolução/reversão |
| R13 | ajuste | A medição destravou (ADR-0043); falta o **esperado independente por ocorrência** para lote, cascata e valores recuperados |
| R14 | ajuste | Documentos em estados incompatíveis (Pendências, Plano §Etapa 10, Origem Legada §4.2) |
| R26 | observação | `event_sequence = legacy_row_id` é identidade física, não ordem observada; o contrato precisa ser dito pelo Owner |

Já fechado e **fora deste plano**: R25 (ADR-0042) e a quarta revisão (memória/reconciliação,
`2fb6f55`). Também fora: **D36** (Etapa 12 não cabe na máquina) e a Etapa 11.

**[medido]** em 14/09/2026: armazém com captura 16, tratamento v7, 16/16 views, fato 16.453;
`make test CARGA=1` → 149 passed; `raw_legacy.customers` retém as 16 gerações, 75 linhas cada —
nenhuma sobrescreveu a anterior.

---

## 1. Ordem, e por quê

```
R13 ──┐
      ├──► R10 ──► validação de ponta a ponta ──► R14 (último, com estado medido)
R12 ──┤              ▲
R09 ──┘              │
R26 (decisão do Owner; entra onde a resposta cair)
```

1. **R13 primeiro.** É só código local (gerador + testes), não precisa de ambiente pesado, e
   produz o oráculo por ocorrência que **R10 vai reutilizar** para dizer "estas são as linhas que
   sumiram, e eram estas que deviam sumir".
2. **R12 em paralelo lógico** — independente de tudo, também sem ambiente pesado.
3. **R09 antes de R10**, porque a prova do R10 exige duas sincronizações reais, e cada uma delas
   precisa passar a ser verificável (é o que o R09 entrega).
4. **R10** é o único que exige o Airbyte de pé duas vezes; concentra-se o custo de troca de
   ambiente num bloco só.
5. **Validação de ponta a ponta** com tudo entregue — é a lista "o que permanece sem validação" do
   `REVISAO.md`, que nenhuma revisão fechou.
6. **R14 por último**, porque documenta estado, e estado se documenta depois de medido.

---

## 2. R13 — o esperado independente por ocorrência

### O que existe hoje **[medido]**

- `data/legacy/manifesto.json`: `achados` (106 falhas de valor, com `valor_original`,
  `valor_legado`, `resultado_esperado`) e `ocorrencias` (88, só as **diretamente** atingidas).
- `tests/test_legado_deteccao.py::test_os_modelos_encontram_tudo_que_o_injetor_produziu` compara
  achados de valor do `staging` com o manifesto, **excluindo** `FK_ORPHAN`, `DUP_EXACT`,
  `DUP_PARTIAL`, `TOTAL_MISMATCH`, `NULL_REQUIRED` (`DE_CONTEXTO`).
- **Nenhum teste** compara `trusted.legacy_classifications` (`classification`,
  `rejection_origin`, `findings`) com um esperado por ocorrência. A cascata (`PARENT_REJECTED`)
  não tem oráculo nenhum. Valores recuperados são conferidos por amostra dirigida
  (`test_falha_representacional_devolve_o_valor_original`), não pelo lote.
- `tests/test_legacy_classification.py` prova a semântica em casos sintéticos pequenos — útil,
  mas é o autor desenhando o caso.

### O que muda **[planejado]**

**Declaração (revisão integral):**

1. `src/mvp_ed1/legacy/injetor.py` — `Resultado` ganha `esperado_por_ocorrencia()` que devolve,
   para **toda** ocorrência gerada (não só as atingidas), o veredito esperado:
   `{tabela, legacy_row_id, classification, rejection_origin, causa}`. A cascata é calculada
   **a partir do grafo de FKs do `Base.metadata`** (o mesmo de onde `record_contract` nasce) e da
   semântica do ADR-0038/0040 — **não** lendo o SQL. Fecho transitivo: filho íntegro de pai
   rejeitado é `rejected/parent_rejected`; excedente de `DUP_EXACT` é `rejected/duplicate_excess`;
   o resto `rejected/own_invalid`, `corrected` ou `accepted`.
2. O manifesto passa a gravar essa lista como `veredito` (12.747 entradas; o arquivo continua fora
   do `git`, como hoje). `ocorrencias` sai — vira subconjunto redundante.
3. `valor_esperado_tipado`: para cada achado `corrected`, o manifesto já tem `valor_original`; o
   teste passa a compará-lo com `cleaned_payload->>coluna` **depois de normalizar pelo tipo do
   modelo SQLAlchemy** (decimal como decimal, data como data), não por igualdade de texto.

**Derivado (amostragem):**

4. `tests/test_legado_deteccao.py` ganha três testes sobre `trusted.legacy_classifications`:
   - `test_o_veredito_de_toda_ocorrencia_confere_com_o_esperado` — igualdade de conjuntos
     `(tabela, legacy_row_id, classification, rejection_origin)`; a diferença é impressa dos dois
     lados (falsos negativos **e** falsos positivos — é o *recall* e a precisão que o revisor pediu);
   - `test_a_cascata_aponta_para_o_pai_certo` — para cada `parent_rejected`, o `findings` vincula
     ao pai que o oráculo diz;
   - `test_todo_valor_corrigido_e_recuperado` — igualdade tipada com `valor_original` para os
     `corrected`, sem exceção.
   Os testes rodam contra a captura selecionada (`legacy_selected_capture`), uma consulta por
   tabela como hoje (ADR-0043).
5. `docs/origem_legada.md` §3.2 — o manifesto passa a declarar veredito por ocorrência; §5 ganha a
   frase de que a cascata tem oráculo independente. `docs/qualidade_de_dados.md` — a medição.

### Semântica da cascata — **decidida pelo Owner em 14/09/2026**

São casos em que a documentação vigente não decidia, e o oráculo independente **não pode** copiar o
que o SQL faz por acaso. O que vale, e o que o oráculo implementa:

| Caso | Decisão | Alternativa recusada |
|---|---|---|
| Filho aponta para `id` de negócio que existe numa linha rejeitada **e** numa canônica aceita (excedente de `DUP_EXACT`) | **Não cascateia** — o pai de negócio existe e está apto | Cascatear se qualquer ocorrência do pai foi rejeitada |
| `DUP_PARTIAL` rejeita as duas versões; filhos delas | **Cascateiam** (nenhuma versão está apta) | — |
| Pai rejeitado por `NULL_REQUIRED` na própria chave (`id` nulo) | Filhos que apontariam para ele são **`FK_ORPHAN` (`own_invalid`)**, não `PARENT_REJECTED` — o vínculo não resolve para ocorrência nenhuma | Tratar como cascata |
| Ciclo de auto-referência com raiz rejeitada | **Toda a componente é `parent_rejected`** (é o que `test_self_reference_cycle_terminates_with_rejected_root` já fixa) | — |

A semântica é **declaração**, e vai para o dono documental (`origem_legada.md` §5, e o ADR-0038
ganha nota datada apontando para lá) antes do código. **Se o SQL de `legacy_classifications`
divergir dela, o SQL está errado e se corrige na mesma entrega** — decisão do Owner, um *commit*
`fix:` por defeito, com a divergência medida antes e depois no dossiê.

### Prova

```
make test                                          # os três testes novos, com contagens em record_property
make dbt-test DBT_ARGS='--select path:models/trusted/legacy path:models/quarantine'   # equações continuam fechando
```

Saída esperada: `perdidos = []`, `sobrando = []`, `recuperados = N/N`. Se o oráculo e o SQL
divergirem, a **primeira** saída mostrará a divergência — e ela vai para o dossiê como está.

### Critério de pronto

- [ ] Toda ocorrência da captura tem veredito esperado, calculado sem ler SQL.
- [ ] Os três testes passam **ou** a divergência está registrada e corrigida na declaração.
- [ ] `DE_CONTEXTO` deixa de existir como exclusão silenciosa — os códigos de contexto passam a
      ser cobertos pelo teste de veredito.

---

## 3. R12 — o schema legado no ciclo Alembic

### O que existe hoje **[medido]**

- `alembic.ini` → `db/migrations`, uma revisão (`20260904_deae0e5943e0`, schema `oltp`), alvo
  `source_db`.
- `legacy_db` nasce de `writer.criar_schema(engine)` executando `schema.ddl()` — DDL derivado
  dos modelos, mas sem versão, sem `downgrade`, sem `make migrate` que o alcance.

### O que muda **[planejado]**

**Declaração:**

1. Segundo ambiente Alembic, `db/migrations_legacy/`, com `env.py` próprio apontando para
   `legacy_db` e `target_metadata` construído de `schema.py` (as 40 tabelas em `text`, mais
   `legacy_row_id`). Um `alembic.ini` só, duas seções (`[oltp]`, `[legacy]`) — Alembic suporta
   `-n <seção>`.
2. Primeira revisão `cria_o_schema_legacy_com_as_40_tabelas_frouxas`, **gerada por autogenerate
   e revisada** (é derivado; a declaração é `schema.py`). `downgrade` derruba o schema.
3. `writer.criar_schema` **deixa de emitir DDL**: passa a exigir que a revisão esteja aplicada
   (`alembic_version` presente e na cabeça) e falhar com mensagem que aponta `make migrate-legacy`.
4. `Makefile`: `migrate-legacy`, `migrate-legacy-status`, `migrate-legacy-down`; `seed-legacy`
   passa a depender de `migrate-legacy`. `make up`/ciclo completo em `execucao_local.md` §3
   ganha a linha.
5. Teste: `tests/test_migracao_legado.py` — `upgrade head` do zero num banco vazio, `downgrade
   base`, `upgrade head` de novo, e **`schema.ddl()` e o resultado do autogenerate não divergem**
   (`alembic check` sai limpo), que é o que impede o DDL derivado e a migração de se separarem.

**Não é ADR novo:** o ADR-0009 já fixa Alembic para a origem; isto é aplicar a mesma decisão à
segunda origem. Fica registrado como nota datada no dono (`origem_legada.md` §2) e nas
Pendências como "R12 fechado".

### Prova

```
make migrate-legacy-down && make migrate-legacy && make seed-legacy FORCE=1
.venv/bin/alembic -n legacy check
make test
```

### Critério de pronto

- [ ] `legacy_db` sobe do zero **só** por migração; `criar_schema` não emite DDL.
- [ ] `downgrade` e `upgrade` de novo, medidos.
- [ ] `alembic check` limpo contra `schema.py`.

---

## 4. R09 — a captura pertence à sincronização que acabou de acontecer

### O que existe hoje **[medido]**

- `geracao_do_legado` na DAG lê `max(_airbyte_generation_id)` **depois** da sincronização. A
  docstring já admite: não distingue carga nova de anterior reutilizada.
- O *job* do Airbyte devolve `rowsSynced` (`airbyte.acompanhar`), que hoje só é impresso.
- `legacy_captura_completa` = "toda tabela tem ≥ 1 linha na captura".

### O que muda **[planejado]**

O Airbyte não expõe `jobId ↔ generation_id`. Mas expõe **duas coisas que juntas fecham o vínculo**:
a geração máxima **antes** do *job* e o `rowsSynced` **do job**.

**Declaração:**

1. `src/mvp_ed1/airbyte.py` ganha `captura_do_legado(antes: int | None, job: dict) -> int` que
   aplica a regra, usada pela DAG **e** por `make sync-legacy` (uma implementação, dois chamadores —
   a mesma razão de a DAG já importar o cliente):
   - lê a geração máxima depois; exige `depois > antes` (carga nova escreveu);
   - exige `sum(count(*) por tabela na geração depois) == job.rowsSynced` (o que o *job* diz ter
     escrito é o que está na geração — este é o vínculo *job* ↔ captura);
   - exige que **nenhuma** tabela tenha geração entre `antes` e `depois` que não seja `depois`
     (carga parcial de um *job* anterior abortado não passa por captura).
2. DAG: tarefa `geracao_antes_do_legado` antes de `sincronizar('legacy_para_raw_legacy')`;
   `geracao_do_legado(antes, job)` passa a chamar a função acima. A docstring perde o parágrafo
   "o que esta tarefa não prova" e ganha o que ela prova e com que evidência.
3. `teste_captura_completa()` em `legacy/dbt.py` ganha a segunda metade: além de "≥ 1 linha por
   tabela", **a contagem por tabela da captura selecionada é igual à contagem que o *job* reportou**
   — via *seed* pequeno? Não: via tabela `raw_legacy._capturas` escrita pela função do item 1
   (`snapshot_id, job_id, rows_synced, capturado_em`). É a única escrita fora do Airbyte em
   `raw_legacy`, e é **metadado de ingestão**, não dado — precisa estar dito no ADR-0008/`origem_legada.md` §4.1.

   > **Decidido pelo Owner em 14/09/2026:** tabela de controle **`raw_legacy._capturas`**. É
   > acrescentar uma tabela a um schema declarado como "snapshot imutável do Airbyte", e é
   > metadado de ingestão, não dado — o `_` a separa das 40 e o ADR-0008 ganha **nota datada**
   > dizendo isso; não é ADR novo. Alternativas recusadas: schema de controle próprio (schema
   > novo, exigiria ADR) e verificar só em tempo de execução (a prova não sobreviveria para o
   > teste dbt nem para o R10, que precisa saber quais capturas conferiram). Criada por migração
   > Alembic no ambiente do armazém? **Não** — o armazém não tem Alembic; nasce por `create table
   > if not exists` na própria função de ingestão, versionada em `airbyte.py`, e o teste dbt
   > declara-a como `source`. Se o revisor considerar isso DDL fora de ciclo (mesma família do R12),
   > a alternativa é um `seed` vazio do dbt com `post_hook` de carga — a decidir no parecer.

4. `src/mvp_ed1/legacy/dbt.py::teste_captura_completa` passa a comparar contagens com
   `_capturas`; e `VAZIAS_LEGITIMAS` continua valendo para o "≥ 1".

### Prova (exige Airbyte — bloco compartilhado com R10)

```
make airbyte-up            # troca de ambiente; preflight decide
make sync-legacy           # 1ª: antes=16, depois=17, rowsSynced=12.747, contagens conferem
make sync-legacy           # 2ª: antes=17, depois=18
make dbt-test DBT_ARGS='--select legacy_captura_completa legacy_captura_existe'
```

E a **contraprova**: interromper a origem (pausar `legacy_db`) e rodar `make sync-legacy` — o *job*
falha ou escreve zero, e a função recusa (`depois == antes`). Saída colada no dossiê.

### Critério de pronto

- [ ] "Captura nova" e "captura anterior reutilizada" produzem resultados diferentes, medidos.
- [ ] `rowsSynced` do *job* == linhas da geração, conferido por teste dbt a cada *build*.
- [ ] DAG e `make sync-legacy` usam a mesma função.

---

## 5. R10 — exclusão física entre capturas completas

### O que existe hoje **[medido]**

- `raw_legacy` retém todas as capturas (ADR-0037) — a matéria-prima existe.
- Nenhum modelo compara duas capturas. Registro apagado na origem simplesmente **não está** na
  captura seguinte, e como `trusted` nasce só da captura selecionada, ele some do armazém sem
  rastro — exatamente o "descartado em silêncio" da regra 4 do `CLAUDE.md`.
- O gerador não tem como apagar linhas de propósito; `legacy_row_id` é renumerado de 1 a cada
  geração (`degradar`), então **não serve** como identidade entre capturas.

### D39 — **decidida pelo Owner em 14/09/2026**

As Pendências diziam que R10 é "implementação, não decisão". O *se* era; o *como* tinha três
escolhas de modelagem, e o Owner as fechou:

| # | Pergunta | Decisão | Alternativas recusadas |
|---|---|---|---|
| D39-a | **Qual identidade diz "mesmo registro" entre capturas?** | A chave de negócio da origem (`id`), **depois do tratamento** — só entre ocorrências aptas (`accepted`/`corrected`) das duas capturas. Rejeição nova não é remoção | `legacy_row_id` (renumerado a cada geração); `original_payload` inteiro; bruto contra bruto |
| D39-b | **O que é "captura anterior completa"?** | A maior `snapshot_id < selecionada` que passa em `legacy_captura_completa` **e** cujas contagens conferem com `_capturas` (R09). Captura incompleta é pulada, nunca comparada — é isto que "distingue remoção real de falha de ingestão" | Sempre `selecionada − 1` |
| D39-c | **Onde o removido aparece, e o que acontece com ele adiante?** | Modelo `trusted.legacy_removed_records` (`source_table, business_id, last_seen_snapshot_id, removed_in_snapshot_id, last_payload`), lido pela reconciliação; e **marca `is_deleted`/`deleted_at`** carregada até a dimensão pelo mesmo caminho do ADR-0029 — a origem apagou, o datamart lembra. Fato não se apaga | Só reportar (o datamart esqueceria o membro; fatos antigas órfãs — contra o ADR-0029); `quarantine` (ausência não é rejeição) |

**É ADR:** a marca de exclusão passa a nascer de **ausência entre capturas**, não de coluna. D39
entra em `pendencias.md` como decidida e é registrada como **ADR-0044** por `/adr` **antes** do
código do R10 — a implementação nasce do ADR, não o contrário.

### O que muda **[planejado]**

**Declaração:**

1. `src/mvp_ed1/legacy/cli.py` ganha `remover --tabela T --quantidade N` (determinístico pela
   semente do catálogo): apaga N linhas de negócio em `legacy_db` **e grava no manifesto**
   `removidas: [{tabela, id, legacy_row_id_na_captura_anterior}]`. É o oráculo do R10, pelo mesmo
   princípio do manifesto de falhas: quem apaga é quem sabe o que apagou. Escolhe linhas **aptas**
   (o oráculo do R13 sabe quais são) — remover uma rejeitada não testaria nada.
2. Modelo `trusted/legacy/legacy_removed_records.sql`: aptas da captura anterior completa
   (D39-b) que não têm `id` apto na captura selecionada. Materialização `table`; reconstrói a
   cada execução (é comparação entre duas fotografias, não histórico).
3. `dbt/tests/legado_removidos_explicam_a_diferenca.sql`: `aptos(anterior) − aptos(atual)
   = removidos + rejeitados_novos`, por tabela — a equação que faz a ausência ser explicada.
4. Pontes (`ponte.py`) passam a projetar `deleted_at = snapshot_at da captura em que sumiu`
   para os removidos, entrando no mesmo caminho do ADR-0029 até `is_deleted` na dimensão.
5. **Unit test dbt** (`unit_tests:` em `_legacy__models.yml`, dbt 1.12 suporta; é a primeira vez
   no projeto — vale uma linha no `qualidade_de_dados.md`) para `legacy_removed_records` com duas
   capturas fictícias: uma completa com remoção, uma incompleta que deve ser ignorada. Roda sem
   Airbyte, em todo `make dbt-build`.
6. `tests/test_legado_remocao.py` (integração, `CARGA=1`): confere `legacy_removed_records`
   contra `manifesto.removidas` depois do ciclo real.

### Prova (exige Airbyte — mesmo bloco do R09)

```
make sync-legacy                                   # captura A, completa
.venv/bin/python -m mvp_ed1.legacy.cli remover --tabela customers --quantidade 5
make sync-legacy                                   # captura B, completa
make dbt-build && make test CARGA=1                # removidos = 5, iguais ao manifesto
```

**Contraprova obrigatória** (é o critério da etapa): pausar uma tabela da origem (renomear
`legacy.campaigns`), sincronizar (captura C, **incompleta**), e mostrar que: o *build* falha em
`legacy_captura_completa` **e** `legacy_removed_records` não acusa as linhas de `campaigns` como
removidas — porque C nunca foi elegível como "anterior completa" nem como selecionada.

### Critério de pronto

- [ ] Remoção real aparece em `legacy_removed_records` com o *snapshot* em que sumiu, igual ao
      manifesto.
- [ ] Captura incompleta **não** gera falso removido, medido.
- [ ] A ausência viaja como marca até a dimensão (se D39-c confirmar).
- [ ] Equação da diferença entre capturas fecha por tabela.

---

## 6. R26 — o contrato de `event_sequence` no legado

Não é implementação: é o Owner dizer o que a coluna promete. Três respostas possíveis, e o
código de cada uma:

| Resposta | O que muda | Custo |
|---|---|---|
| **"É só desempate técnico dentro da captura, sem promessa de ordem entre capturas"** (**recomendo** — é o que a origem fornece) | Renomear o comentário em `ponte.py:68` para dizer exatamente isso; nota em `origem_legada.md` §4.1 e no dicionário; teste que **nenhum** consumidor ordena saldo por `event_sequence` em linhas legadas (`grep` estrutural sobre os modelos, fixado em teste) | Uma sessão |
| "Precisa ser estável entre recapturas" | Não há como: `legacy_row_id` é renumerado. Exigiria chave de negócio + `snapshot_at`, e ainda assim seria ordem de captura, não de evento | Modelagem — ADR |
| "Precisa ser ordem observada do evento" | A origem não tem; qualquer coisa seria inventada | Recusar |

**Decidido pelo Owner em 14/09/2026: a primeira linha.** `event_sequence` no legado é desempate
técnico dentro da captura, sem promessa de ordem entre capturas nem de ordem observada do evento.
Entra como **D40** decidida em `pendencias.md`, fechada por **nota datada no ADR-0039** (alcance da
procedência), sem ADR novo. O que se entrega: comentário em `ponte.py:68` reescrito; nota em
`origem_legada.md` §4.1 e no dicionário de dados; e um teste estrutural que falha se algum modelo
de `analytics`/`consumption` ordenar por `event_sequence` sem restringir a `source_system = 'retail'`.

---

## 7. Validação de ponta a ponta

É a lista "o que permanece sem validação" do `REVISAO.md`, executada **uma vez, em sequência, com
saída colada**. Ordem respeitando a troca de ambientes (R11/ADR-0041):

| Passo | Ambiente | O que prova |
|---|---|---|
| `make down && docker volume rm …` (só os três bancos) → `make up && make migrate && make migrate-legacy && make seed-data && make seed-legacy` | leve | Migrações do zero, inclusive a legada (R12) |
| `make airbyte-up` → `sync-airbyte` → `sync-legacy` ×2 com remoção entre elas → contraprova incompleta | Airbyte | R09, R10 |
| `make dbt-build` do zero → `make test CARGA=1` | leve | Oráculo por ocorrência (R13), 16 views, reconciliação, fato |
| `make airflow-up` → `fluxo_batch` do zero | Airflow | DAG com `geracao_antes`/`geracao_do_legado` novos; vínculo *job*–captura ao vivo |
| Ciclo D34: mudar tratamento (v8), *build*, recusa da auditoria, voltar a v7 | leve | Já exigido pela terceira revisão e nunca executado |

Números que saem daqui vão para os donos (Capacidade §2, Qualidade, Origem Legada) **com data e
captura** — é o que R14 pede.

---

## 8. R14 — coerência documental, com o estado medido

Depois de tudo acima, e só depois:

- `docs/pendencias.md`: §1 (D36 continua), §2 ganha D39/D40, o parágrafo "R10, R12, R13 são
  implementação" sai; §6 "do lado do assistente" descreve o estado real.
- `docs/plano_de_desenvolvimento.md` §Etapa 10: critérios reescritos com ✓ **só** onde há medição
  nesta rodada, citando captura e versão; a ressalva de R11 e a frase "fronteira de empilhamento
  não existe" saem (R01 foi tratado em 07/09).
- `docs/origem_legada.md` §4.2: a frase "quem sustenta a afirmação são os dois testes acima"
  **contradiz** a DAG desde 08/09 — passa a descrever o vínculo do R09.
- `README.md` status: Etapa 10, quarta rodada, com o que ficou aberto (se ficar).
- `REVISAO.md`: coluna *Situação* dos seis achados preenchida; o arquivo **sai** no *commit* de
  fechamento, como manda a skill.

---

## 9. Ambiente e memória

- R13, R12, R26 e R14: **só os três bancos**. Nada pesado.
- R09 + R10 + validação: Airbyte de pé (~4,5 GB) — `make airbyte-up` decide pelo `preflight`; se
  recusar, é parada e pedido ao Owner, não `FORCE=1`. Airflow só no passo da DAG, depois de o
  Airbyte ser pausado.
- Nenhum `make dbt-build` seletivo sem `+` (Execução Local §6, lição de 14/09).

---

## 10. Commits previstos

Um por assunto, na ordem:

1. `feat: calcula o veredito esperado de toda ocorrência do legado no gerador` (R13, declaração)
2. `test: confere veredito, cascata e valores recuperados contra o oráculo` (R13, derivado)
3. `fix: …` — se o oráculo achar divergência no SQL (um por defeito)
4. `feat: leva o schema legado para o ciclo Alembic` (R12)
5. `feat: vincula a captura do legado ao job que a escreveu` (R09)
6. `docs: registra ADR-0044 — exclusão física do legado como marca até a dimensão` (D39)
7. `feat: detecta exclusão física entre capturas completas do legado` (R10)
8. `docs: registra a resposta ao contrato de event_sequence` (R26/D40)
9. `docs: atualiza o estado da Etapa 10 com as medições e fecha a terceira revisão` (R14; apaga
   `REVISAO.md` e este plano)

Dossiê de revisão para o Codex ao fim: `dossie.py --desde a66f869`, um só, cobrindo os nove.

---

## 11. O que este plano **não** decide

- D36 (Etapa 12 na máquina).
- Política de descarte de capturas antigas em `raw_legacy` (ADR-0037 adiou de propósito).
- Se `jit=off` deve valer para `source_db`/`legacy_db` (dossiê da quarta revisão, §4.6).
- Qualquer mudança no agendamento da Etapa 12.

## 12. Decisões do Owner — tomadas em 14/09/2026

| Decisão | Resposta | Onde fica registrada |
|---|---|---|
| D39-a identidade entre capturas | Chave de negócio `id`, só entre aptas | ADR-0044 |
| D39-b captura anterior completa | Maior `snapshot_id < selecionada` completa e conferida com `_capturas` | ADR-0044 |
| D39-c destino do removido | `legacy_removed_records` **e** marca `is_deleted`/`deleted_at` até a dimensão (caminho do ADR-0029) | **ADR-0044**, novo |
| D40 contrato de `event_sequence` no legado | Só desempate técnico dentro da captura | Nota datada no ADR-0039 |
| Vínculo *job* ↔ captura (R09) | Tabela de controle `raw_legacy._capturas` | Nota datada no ADR-0008 |
| Semântica da cascata (R13), quatro casos | Excedente de `DUP_EXACT` não cascateia · `DUP_PARTIAL` cascateia · pai com `id` nulo dá `FK_ORPHAN` · ciclo com raiz rejeitada cai inteiro | `origem_legada.md` §5 + nota no ADR-0038 |
| SQL divergente do oráculo (R13) | Corrigir na mesma entrega, um `fix:` por defeito | Dossiê |

Tudo o mais neste plano é implementação do que já está decidido. **O que o revisor pode
contestar** são os fundamentos das respostas — se houver ADR aceito que já decida diferente, ou
consequência que a recomendação não viu —, e isso volta ao Owner como achado, não como nova
pergunta minha.

---

## 13. Parecer do revisor — 14/09/2026

**O plano não pode ser executado nesta forma.** Há falhas nas provas de R09/R10 e consequências de
decisões que precisam voltar ao Owner. Os achados abaixo avaliam o plano; não encerram os achados
de desenvolvimento, não aprovam novos contratos e não substituem a revisão da futura implementação.

Li primeiro `CLAUDE.md`, depois este plano, o parecer vigente em `REVISAO.md`, os donos documentais
e os ADRs pertinentes. Consultei também `.claude/skills/revisao/SKILL.md` para conferir a passagem
e o fechamento. A revisão considera a **revisão 2 do plano** presente na árvore:
o ramo confere, mas o `HEAD` observado é `819b88f`, posterior ao `f51fc2a` informado.
Entre esses dois commits mudou somente este plano; o código-base continua sendo o indicado.

### 13.1 Fidelidade aos seis achados

| Achado original | Pedido vigente | Avaliação do plano |
|---|---|---|
| R09 — `REVISAO.md:823` | Provar integralidade e vínculo com o job concluído, distinguindo reutilização de captura anterior. | A §4 acrescenta verificações úteis, mas total igual e máximo crescente ainda não identificam o autor das linhas nem provam integralidade por stream. O registro proposto sequer contém as contagens por tabela que o teste promete comparar. P01, P02 e P21. |
| R10 — `REVISAO.md:824` | Detectar exclusões físicas entre capturas completas; retenção não substitui detecção. | A §5 trata ausência no conjunto **apto**, que também pode ser rejeição nova. A limitação a aptos foi decidida pelo Owner, mas restringe o pedido original e precisa ter suas consequências registradas. A retenção do membro desaparece na terceira captura sem a linha. P03, P04, P12–P14. |
| R12 — `REVISAO.md:825` | Pôr o schema legado no ciclo versionado de evolução e reversão. | A §3 responde ao pedido, mas só descreve a instalação vazia; falta a entrada das 40 tabelas existentes no ciclo. A prova de paridade proposta também não basta para provar equivalência com `schema.ddl()`. P05. |
| R13 — `REVISAO.md:826`, `:843–844` | Esperado independente completo por ocorrência, cascata, valores recuperados, recall e falsos positivos. | A §2 avança no grão correto. Contudo, exige uma recuperação impossível em um caso já medido e compara rótulos finais sem conferir todo o conjunto de achados. Compartilhar o grafo declarativo não é, por si só, circularidade; validar um segundo classificador sem âncoras independentes continua sendo insuficiente. P06, P07 e P18. |
| R14 — `REVISAO.md:827` | Corrigir estados incompatíveis nos donos, identificar captura/versão e preservar ADRs aceitos. | A §8 identifica os donos e as contradições principais. Faltam separar entrega técnica, nova revisão e aceite, e atualizar os contratos/metadados que o próprio plano acrescenta. P08 e P22. |
| R26 — `REVISAO.md:830` | Esclarecer o contrato de `event_sequence`. | A decisão da §6 responde ao pedido. O teste proposto promete restringir mais do que a decisão e pode confundir colunas homônimas. P09. |

### 13.2 Verificações executadas e saídas literais

As consultas às três bases foram de leitura, com timeout. A rotina Python de conferência abriu
conexões com `default_transaction_read_only=on`, `statement_timeout` e `jit=off`.
Nenhuma sincronização, exclusão, renomeação, migração ou reconstrução foi executada.
Os três bancos e o Airbyte **já estavam de pé**; não foi necessário executar `make up`.
Não executei `make dbt-build`, `make test CARGA=1` nem alvos que sobem ambientes pesados.
Credenciais foram usadas em memória, sem serem exibidas.

**V01 — árvore e base.** Comandos: `git status --short --branch`,
`git log -1 --format='%h %H %ad %s' --date=iso-strict`,
`git log --oneline f51fc2a..HEAD` e `git diff --stat f51fc2a HEAD`.

~~~text
## feat/troca-entre-ambientes-pesados...origin/feat/troca-entre-ambientes-pesados [ahead 10]
819b88f 819b88f4bac52c8b489e111c01c16b813f83ae2c 2026-09-14T15:35:49-03:00 docs: fecha no plano da Etapa 10 as decisões do Owner antes da revisão
819b88f docs: fecha no plano da Etapa 10 as decisões do Owner antes da revisão
 PLANO_fechamento_etapa_10.md | 94 +++++++++++++++++++++++++++-----------------
 1 file changed, 59 insertions(+), 35 deletions(-)
~~~

**V02 — manifesto, dependências e migrações locais.** Leitura de
`data/legacy/manifesto.json` por `json.loads`, contagem dos achados por código,
`importlib.metadata.version` e listagem de `db/migrations*/versions/*.py`.

~~~text
manifest_keys: ['achados', 'ocorrencias']
achados: 106
achados_com_coluna: 102
ocorrencias: 88
achados_por_codigo: {'BOOL_VARIANT': 5, 'DATE_FORMAT_KNOWN': 5, 'DATE_FUTURE': 3, 'DATE_IMPOSSIBLE': 4, 'DATE_TZ_MISSING': 5, 'DATE_UNPARSEABLE': 3, 'DUP_EXACT': 4, 'DUP_PARTIAL': 2, 'EMAIL_MALFORMED': 4, 'ENUM_UNKNOWN': 4, 'FK_ORPHAN': 5, 'MONEY_AMBIGUOUS': 3, 'MONEY_LOCALE': 6, 'MONEY_NEGATIVE': 3, 'NULL_DISGUISED': 7, 'NULL_REQUIRED': 12, 'NUM_AMBIGUOUS': 4, 'NUM_OUT_OF_RANGE': 4, 'NUM_TEXT_EQUIV': 5, 'TEXT_DELIMITER': 3, 'TEXT_ENCODING': 5, 'TEXT_TRUNCATED': 1, 'TEXT_WHITESPACE_CASE': 6, 'TOTAL_MISMATCH': 3}
dbt-core: 1.12.3
alembic: 1.19.1
migration_files: ['db/migrations/versions/20260904_deae0e5943e0_cria_o_schema_oltp_com_as_40_tabelas_.py']
~~~

Portanto, 106 é o total de achados, incluindo contexto. Pelo recorte `DE_CONTEXTO` do teste,
há **80 achados de valor**, como confirmado em V05. As 88 ocorrências e a versão instalada
`dbt-core 1.12.3` conferem. A única revisão Alembic pertence à origem principal.

**V03 — warehouse.** Executei pelo `psql` do serviço `warehouse_db`, com
`-X -v ON_ERROR_STOP=1 -A -F "|"`, as consultas abaixo, dentro de transação de leitura.
A primeira tentativa usou o nome inexistente `treatment_version`; terminou com erro, sem escrita.
A correção foi consultar o campo existente `catalog_version`.

~~~text
BEGIN
SET
database|postgres|jit
warehouse_db|16.15|off
snapshot_id
16
ERROR:  column "treatment_version" does not exist
LINE 1: select snapshot_id, treatment_version, count(*) as occurrenc...
                            ^
~~~

Consultas da segunda execução:

~~~sql
begin read only;
set local statement_timeout = '20s';
select snapshot_id, catalog_version, count(*) as occurrences
from trusted.legacy_classifications group by 1,2 order by 1,2;
select count(*) as consumption_views from information_schema.views
where table_schema='consumption';
select source_system, count(*) as rows
from analytics.fact_inventory_movement group by 1 order by 1;
select _airbyte_generation_id as snapshot_id, count(*) as customers
from raw_legacy.customers group by 1 order by 1;
select classification, rejection_origin, count(*) as occurrences
from trusted.legacy_classifications group by 1,2 order by 1,2;
select table_name, column_name from information_schema.columns
where table_schema='raw_legacy' and table_name='customers'
and column_name like '_airbyte%' order by ordinal_position;
select _airbyte_meta->>'sync_id' as sync_id,
       _airbyte_meta->>'changes' as changes, _airbyte_generation_id
from raw_legacy.customers where legacy_row_id=1 order by _airbyte_generation_id;
select to_regclass('raw_legacy._capturas') as capture_control,
       count(*) filter (where table_name like 'stg_legacy__%'
                        and table_type='BASE TABLE') as legacy_staging_tables
from information_schema.tables where table_schema='staging';
rollback;
~~~

~~~text
BEGIN
SET
snapshot_id|catalog_version|occurrences
16|7|12747
consumption_views
16
source_system|rows
legacy|553
retail|15900
snapshot_id|customers
1|75
2|75
3|75
4|75
5|75
6|75
7|75
8|75
9|75
10|75
11|75
12|75
13|75
14|75
15|75
16|75
classification|rejection_origin|occurrences
accepted||10441
corrected||26
rejected|duplicate_excess|3
rejected|own_invalid|67
rejected|parent_rejected|2210
table_name|column_name
customers|_airbyte_raw_id
customers|_airbyte_extracted_at
customers|_airbyte_meta
customers|_airbyte_generation_id
sync_id|changes|_airbyte_generation_id
9|[]|1
10|[]|2
11|[]|3
12|[]|4
13|[]|5
14|[]|6
15|[]|7
16|[]|8
17|[]|9
18|[]|10
21|[]|11
22|[]|12
23|[]|13
24|[]|14
25|[]|15
26|[]|16
capture_control|legacy_staging_tables
|40
ROLLBACK
~~~

Isso reproduz captura 16, tratamento 7, 16 views publicadas, 15.900 + 553 = **16.453**
movimentos na fato e 16 gerações de `customers`, com 75 linhas cada. Publicação das views
não foi tomada como prova de avaliação de todas as suas colunas nem de reconciliação ponta a ponta.

**V04 — origens, identidade de ingestão e ciclo.** A rotina de leitura contou as tabelas de
`oltp` e `legacy`; para cada uma das 40 tabelas brutas executou
`select _airbyte_generation_id, _airbyte_meta->>'sync_id', count(*) ... group by 1,2`.
Reexecutou o caso do ciclo de `tests/test_legacy_classification.py` com os dois registros
do próprio teste, imprimindo também `rejection_origin` e `findings`, que aquela asserção
não examina. Consultou `GET /api/public/v1/jobs/25` e `/jobs/26` pelo cliente existente,
após obter o token; nenhum job foi disparado. A saída foi limitada aos campos indicados,
sem credenciais. `endTime: null` significa campo ausente na resposta, como mostra `job_keys`.

~~~text
SOURCE_DB tables=40 rows=12763 customers=75 inventory_movements=672
SOURCE_DB version_tables=['public.alembic_version']
LEGACY_DB tables=40 rows=12747 customers=75 inventory_movements=692
LEGACY_DB version_tables=[]
raw_generations: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
raw_generation: 15 tables=39 rows=12746 sync_ids=['25']
raw_generation: 16 tables=40 rows=12747 sync_ids=['26']
retained_history_table_generations: 639
cycle: {"classification": "rejected", "findings": [{"action": "reject", "cleaned_value": null, "code": "NULL_REQUIRED", "column": "name", "context": {}, "original_value": null, "reason": "Ausência de valor obrigatório; preencher exigiria inventar um valor de negócio."}], "legacy_row_id": 1, "rejection_origin": "own_invalid"}
cycle: {"classification": "rejected", "findings": [{"action": "reject", "cleaned_value": "1", "code": "PARENT_REJECTED", "column": "parent_id", "context": {"parent_row_id": 1, "parent_table": "categories"}, "original_value": "1", "reason": "O pai foi rejeitado; empilhar o filho produziria fato sem a entidade que o explica."}], "legacy_row_id": 2, "rejection_origin": "parent_rejected"}
job_keys: ['bytesSynced', 'connectionId', 'duration', 'jobId', 'jobType', 'lastUpdatedAt', 'rowsSynced', 'startTime', 'status']
job: {"endTime": null, "jobId": 25, "jobType": "sync", "legacy_connection": true, "rowsSynced": 12746, "startTime": "2026-09-07T17:49:45Z", "status": "succeeded"}
job_keys: ['bytesSynced', 'connectionId', 'duration', 'jobId', 'jobType', 'lastUpdatedAt', 'rowsSynced', 'startTime', 'status']
job: {"endTime": null, "jobId": 26, "jobType": "sync", "legacy_connection": true, "rowsSynced": 12747, "startTime": "2026-09-07T17:51:31Z", "status": "succeeded"}
~~~

**Há uma contraprova real já retida:** o job 25 foi `succeeded`, e seu total bate com a geração 15,
mas só 39 tabelas aparecem nela. V05 identifica a ausente como `brands`.
O teste atual de presença já pode recusar esse caso; sucesso e total, sozinhos, não o recusam.

Nos dois jobs consultados, todas as linhas das respectivas gerações carregam
`_airbyte_meta.sync_id` igual ao `jobId`. É evidência observada de uma alternativa mais forte
para investigar, **não prova de que essa igualdade seja contrato universal da API**.
A [documentação oficial dos metadados do Airbyte](https://docs.airbyte.com/platform/understanding-airbyte/airbyte-metadata-fields)
descreve `sync_id` como identificação monotônica da sincronização, sem significado inerente;
a [API de consulta de job](https://reference.airbyte.com/reference/getjob) identifica a execução
por `jobId`. A correspondência na versão/conector usados precisa ser fixada e testada,
incluindo tentativas repetidas. O plano não examinou esse metadado.

**V05 — esperado recuperável e testes de leitura.** Cruzei o manifesto com as 26 ocorrências
`corrected` em `trusted.legacy_classifications`, por tabela e identidade física.
Fiz a coleta da suíte e executei apenas os dois arquivos indicados abaixo, excluindo o teste
que invoca `dbt compile`. Usei `PYTHONDONTWRITEBYTECODE=1`, desabilitei o cache do pytest
e forcei transações de leitura via `PGOPTIONS`.

~~~text
manifest_value_findings: 80
generation_15_missing_tables: ['brands']
corrected_null: {"cleaned": null, "column": "color", "manifest_legacy": "NULL", "manifest_original": "Vermelho", "row": 27, "table": "product_variants"}
collection_exit: 0
149 tests collected in 0.39s
command: .venv/bin/pytest -q -p no:cacheprovider tests/test_legado_deteccao.py tests/test_legacy_classification.py -k not configuracao_divergente_da_impressao_recusa_a_compilacao
...............................                                          [100%]
31 passed, 1 deselected in 16.67s
pytest_exit: 0
~~~

A coleta de 149 testes **não reproduz 149 testes passando**. O número reproduzido nesta revisão
é **31 passed**, sem testes pulados entre os selecionados. A suíte de carga destrói estado,
por isso ficou fora desta revisão de plano; a afirmação restante recebe P11, conforme solicitado.

O caso `product_variants.color` é decisivo: a injeção substituiu `Vermelho` por `NULL`;
o contrato manda produzir nulo. Comparar o resultado com `valor_original` como exige a §2
acusaria uma implementação correta. Não é diferença de representação corrigível por cast.

**V06 — chave real da tabela de movimentos.** Percorri as tabelas de `Base.metadata`
e imprimi as que não contêm `id`, com a chave primária e as colunas legadas:

~~~text
inventory_movements primary_key=movement_id legacy_columns=movement_id,idempotency_key,warehouse_id,product_variant_id,movement_type,quantity_delta,unit_cost,source_type,source_id,correlation_id,causation_id,aggregate_version,occurred_at,recorded_at,schema_version,metadata
~~~

**V07 — verificações estáticas relevantes.** Buscas com `rg -n` nos testes de carga, snapshot
de cliente, dimensão, staging de estoque e CLI legada. Saídas literais:

~~~text
tests/test_carga.py:27:from conftest import FATOR_REDUZIDO
tests/test_carga.py:31:AUTORIZA_ESCRITA = "MVP_TESTE_CARGA"
tests/test_carga.py:51:    dados = pipeline.gerar(Motor(config, fator=FATOR_REDUZIDO))
tests/test_carga.py:53:    resultado = escrever(engine, dados, forcar=True)
dbt/snapshots/scd_customer.sql:8:    `strategy='check'` com colunas **declaradas**, nunca `check_cols='all'`: com
dbt/snapshots/scd_customer.sql:22:        unique_key="source_system || '-' || customer_id",
dbt/snapshots/scd_customer.sql:24:        check_cols=[
dbt/snapshots/scd_customer.sql:29:            'is_deleted',
dbt/models/analytics/dim_customer.sql:4:-- versiona as colunas declaradas em `check_cols`, e congela as demais no valor
dbt/models/analytics/dim_customer.sql:62:    v.is_deleted,
dbt/models/analytics/dim_customer.sql:73:join atual a on a.source_system = v.source_system and a.customer_id = v.customer_id
tests/conftest.py:23:FATOR_REDUZIDO = 0.05
tests/conftest.py:39:    return pipeline.gerar(Motor(config, fator=FATOR_REDUZIDO))
dbt/models/staging/stg_retail__inventory_movements.sql:50:    from {{ source('retail', 'inventory_movements_stream') }}
dbt/models/staging/stg_retail__inventory_movements.sql:118:        false                                       as is_deleted,
~~~

~~~text
src/mvp_ed1/legacy/cli.py:91:    sub.add_parser("plan")
src/mvp_ed1/legacy/cli.py:92:    sub.add_parser("catalogo")
src/mvp_ed1/legacy/cli.py:93:    sub.add_parser("models")
src/mvp_ed1/legacy/cli.py:94:    semear = sub.add_parser("seed")
~~~

A leitura de `writer.py:36–39`, `schema.py:160–173` e `db/migrations/env.py`
confirma o DDL fora de Alembic; V04 confirma a ausência de tabela de versão no banco legado.
A leitura de `airflow/dags/fluxo_batch.py:84–90,126–139` confirma a escolha por máximo
posterior: `rowsSynced` já é devolvido em XCom como `linhas`, mas não certifica a captura.
A leitura do seletor e dos modelos confirma que `staging`/classificação só expõem a captura
selecionada. Não encontrei detector de exclusão física nem comando de remoção.
A leitura dos dois arquivos de testes confirma a falta de oráculo completo do lote.
Essas premissas funcionais das §§2–5 conferem; as imprecisões restantes estão em P10/P11.

### 13.3 Decisões já tomadas: análise para o Owner

A autorização já existe. Não peço nova autorização para implementar o que está decidido.
As objeções abaixo devolvem **fundamentos e consequências** ao Owner; o executor não deve
resolvê-las escolhendo outro contrato por conta própria.

| Decisão da §12 | Confronto com ADRs e consequências | Registro proposto |
|---|---|---|
| D39-a — identidade por `id` tratado entre aptos | A chave real de `inventory_movements` é `movement_id` (V06); excluir rejeitados estreita a detecção do ADR-0015. Identidades alteradas/nulas e mudança de tratamento precisam de destino explícito. P12. | ADR novo é adequado; ADR-0044 precisa declarar a identidade por tabela e o universo coberto. |
| D39-b — maior anterior completa e conferida | É compatível com ADR-0015/0037 quanto a pular incompletas. Falta decidir como comparar aptidão sob tratamentos diferentes e como obter a anterior, ausente das tabelas correntes. `_capturas` também ainda não existe para as 16 gerações retidas. P04. | Cabe no ADR-0044, incluindo início sem anterior elegível, metadados históricos e contrapartida no BigQuery. |
| D39-c — marca até a dimensão; fato não se apaga | Preservar o membro acompanha ADR-0029. A frase sobre a fato conflita com ADR-0042, que remove movimentos legados ausentes/rejeitados. A cascata de ADR-0038 continua retirando filhos de pais apagados; guardar o pai na ponte não desfaz classificações anteriores. A marca calculada só entre duas capturas não dura até a terceira. P13/P14. | ADR novo é necessário, com emenda explícita aos contratos afetados, equações, SCD e retenção/reprocessamento no BigQuery. Uma nota não resolve esse conflito. |
| D40 — desempate técnico dentro da captura | Não encontrei ADR aceito que prometa ordem de evento para essa identidade legada. ADR-0039 trata procedência; não fundamenta uma proibição geral de ordenação. P09. | Nota datada **de referência**, preservando o ADR, é suficiente para apontar o esclarecimento no dono do contrato; não precisa reescrever a decisão de procedência. |
| R09 — controle em `raw_legacy._capturas` | ADR-0023 já declarou `governance` para execução/reconciliação; a alternativa de controle não parte necessariamente de um schema novo. Há tensão entre controle auditável, sua participação no fluxo e a fronteira de ADR-0008/0023. Falta a tradução da escrita Python/DDL no warehouse para BigQuery. P15. | Não tratar essa alteração de fronteira como mera retificação factual no ADR-0008. Volta ao Owner para explicitar a exceção em ADR, preservando os aceitos. Não escolho automaticamente `governance` nem o `seed` alternativo. |
| R13 — quatro casos de cascata | Excedente exato com canônica apta, duplicata parcial sem pai apto e FK que não resolve após id nulo são compatíveis com ADR-0038/0040. **Toda a componente como `parent_rejected`**, incluindo a raiz inválida, não é o que o teste citado fixa; V04 mostra raiz `own_invalid`. P16. | Os esclarecimentos compatíveis podem ficar no dono com nota de referência. Mudar a origem da rejeição da raiz altera o contrato de classificação/reconciliação e exige decisão expressa em ADR novo, não nota que apresente o caso como já decidido no ADR-0038. |
| R13 — corrigir SQL divergente na mesma entrega | Autorização suficiente para corrigir defeito demonstrado contra o contrato. Não torna o novo oráculo infalível, nem autoriza alterar tratamento sob a mesma impressão/versão auditada. P06/P16/P17. | Dossiê basta para defeitos sem mudança de decisão. Respeitar D34, catálogo e fingerprint; mudança semântica além do contrato exige ADR pelo procedimento vigente. |

A regra de registro aplicada foi `docs/adr/README.md` §1, itens 2–5: mudança relevante ganha
ADR; o aceito não é reescrito; toda decisão declara a contrapartida GCP. Uma nota datada pode
apontar um esclarecimento compatível ou uma nova medição no seu dono. Ela não transforma
mudança de contrato em correção editorial. O precedente do ADR-0037 mostra como emendar
uma decisão sem apagar a anterior.

### 13.4 Força dos oráculos

O manifesto de injeção é independente **da transformação**, mas o novo
`esperado_por_ocorrencia()` também será uma implementação sujeita a defeitos.
Usar `Base.metadata` como declaração comum é correto; reutilizar o classificador, sua resolução
de vínculos ou seus resultados para fabricar o esperado eliminaria a independência.
É preciso revisar integralmente essa declaração e ancorar o cálculo nas mutações registradas,
no conjunto íntegro anterior e em resultados de contrato fixados antes do SQL. P06/P07/P18.

Há provas mais fortes e viáveis:

- **R09:** manifesto de extração por stream, com identidade da execução e resultado de leitura,
  confrontado com identidades e conteúdo recebidos. Investigar o `sync_id` nativo medido em V04;
  contagem escrita pelo destino não é oráculo independente da integralidade da origem.
  A geração 15 fornece uma contraprova retida sem precisar renomear agora uma tabela.
- **R10:** registrar as linhas efetivamente apagadas, por retorno da operação e confirmação
  da transação, preservando manifesto anterior e posterior. Conferir identidades, payloads e
  ausência real; quantidade escolhida pelo CLI não prova quantidade removida.
  Exercitar também rejeição nova **sem apagar**, inclusão simultânea, terceira captura sem novas
  mudanças, reaparecimento e remoção da última linha de uma tabela.
- **R13:** conferir multiconjuntos, vínculos e todos os achados relevantes, incluindo correções
  em ocorrências cujo veredito final seja rejeição. O valor esperado vem da semântica de cada
  transformação: original para a falha reversível, alvo canônico declarado nos demais casos.
  A concordância entre dois algoritmos do mesmo autor precisa das contraprovas discriminantes.
- **R12:** além de `alembic check`, comparar os catálogos físicos obtidos por dois caminhos
  independentes em bancos isolados: DDL de referência e migração. Conferir identidade, tipos,
  nulabilidade e constraints, e exercitar evolução/reversão com conteúdo representativo.

Os casos construídos por autor são úteis como especificação; não substituem o lote observado.
Igualdade entre esperado e obtido também precisa de contraprova em que um defeito deliberado
cause falha do teste. Não executei essas novas provas; são ajustes à estratégia do plano.

### 13.5 Ambiente e memória

O plano acerta ao concentrar sincronizações, usar a troca existente e parar diante de recusa.
R13/R12/R26/R14 não precisam subir ambiente pesado. Entretanto, as §§7/9 descrevem uma DAG
ao vivo com Airbyte pausado: suas primeiras tarefas chamam a API do Airbyte. Isso não funciona.

`docs/execucao_local.md:223` exige bancos **mais Airbyte e Airflow** para esse cenário.
`docker/preflight.sh:46–50,147–152` trata Airbyte/Airflow como a mesma família `batch`;
`airflow-up` não pausa o Airbyte. Há, portanto, uma incompatibilidade entre a descrição
do plano, a formulação geral em `CLAUDE.md` §5 e o cenário documentado/implementado.
Isso precisa ser explicitado ao Owner, não contornado com retomada ou `FORCE=1`.

O pico aceito no ADR-0041 é **4,95 GiB**; `preflight.sh:36` usa `CUSTO_airbyte=5000`,
não os ~4,5 GB da §9. A DAG ainda dispara as duas sincronizações em paralelo
(`fluxo_batch.py:177–191`); a medição de uma sincronização não certifica o pico de duas
mais Airflow e ambiente de trabalho.

Consulta inicial: `docker ps -a --format 'table {{.Names}}\\t{{.Status}}'`.
O sandbox primeiro devolveu:

~~~text
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
~~~

Após liberação da consulta, estes são os trechos literais referentes ao projeto:

~~~text
NAMES                                        STATUS
mvp_ed1_warehouse_db                         Up 49 minutes (healthy)
mvp_ed1_legacy_db                            Up 49 minutes (healthy)
mvp_ed1_source_db                            Up 49 minutes (healthy)
mvp_ed1_kafka_connect                        Exited (137) 6 days ago
mvp_ed1_redpanda                             Exited (0) 6 days ago
airbyte-abctl-control-plane                  Up 49 minutes
~~~

Leitura posterior, durante esta revisão: `rg '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo`:

~~~text
MemTotal:       12021776 kB
MemAvailable:    1084980 kB
SwapTotal:      16215540 kB
SwapFree:       12294224 kB
~~~

Isso corresponde a cerca de **11,46 GiB totais e 1,03 GiB disponíveis naquele instante**.
Não é medição de pico nem previsão de disponibilidade na execução futura.
A partir dessa leitura não fiz novas consultas ao banco/testes; só consolidei o parecer.
Nenhum ambiente foi pausado, retomado ou iniciado pelo revisor. Não houve execução do preflight
com troca nem validação de memória sob sincronização. P19 delimita o bloqueio da prova planejada.

### 13.6 Escopo adicional e omissões

São acréscimos ao pedido original: a CLI de remoção, a tabela de controle, o segundo ambiente
Alembic, os unit tests dbt e o tratamento da ausência até as dimensões. Os primeiros são meios
plausíveis de validação/implementação. A propagação histórica foi decidida pelo Owner e tem
efeitos adicionais em SCD, fatos e reconciliação; por isso exige o ADR previsto, corrigido pelas
consequências acima. Não cabe descartá-la só porque o R10 original era mais estreito.

Destruir os três bancos para provar a migração legada amplia o alcance operacional de R12.
Se a validação integral do zero for mantida, o plano precisa tratar consumidores, cursores do
Airbyte e o destino do streaming que o dbt já lê. A prova isolada de migração não exige apagar
o warehouse observado. P20.

O que ficou de fora sem delimitação suficiente: ingestão parcial **dentro** de tabela não vazia,
concorrência/retry entre CLI e DAG, tabela que fica vazia por exclusão legítima, identidades sem
`id`, exclusão de rejeitados, classificação da captura anterior, preservação por três ou mais
capturas, reaparecimento, efeito sobre filhos/fatos, associação do manifesto ao lote e
governança dos novos campos. A §7 também não executa toda a lista de `REVISAO.md:835–849`:
não prova concorrência/restauração parcial dos ambientes, aplicação do chart, picos/OOM,
streaming ao vivo ou paridade GCP. Algumas dessas validações foram declaradas fora do escopo
da etapa/rodada; outras já tiveram trabalho posterior. O plano deve marcar cada uma como
coberta por evidência identificada ou ainda pendente, sem anunciar a execução integral daquela lista.

D36, descarte de capturas antigas, `jit` nas origens e agendamento da Etapa 12 podem continuar fora,
como já declarado. R25, porém, não pode permanecer “fora” se D39-c mudar a regra do ADR-0042.
A retirada dos arquivos transitórios só encerra a passagem que foi efetivamente entregue;
não é evidência de aceite da etapa.

### 13.7 Tabela de achados

“**Owner**” identifica fundamento de decisão que volta ao Owner. As demais linhas são ajustes
do plano pelo executor, dentro do contrato já autorizado. `Bloqueante` impede executar o plano
como escrito; `ajuste` deve ser incorporado antes da execução; `observação` delimita alcance.

| # | Seção do plano | Achado | Veredito |
|---|---|---|---|
| P01 | §4, regra do vínculo; §12/R09 | **Máximo e total não demonstram a autoria das linhas.** A conclusão depende de premissas não declaradas nem exercitadas: geração exclusiva por execução/conexão, sem mistura entre tentativas, e ausência de corrida entre a leitura de `antes`, o disparo e a conferência. Cardinalidade igual não verifica essas premissas; a regra que recusa gerações intermediárias só cobre parte dos intercalamentos. V04 encontrou `sync_id` nativo coincidente com jobs 25/26, caminho mais forte que o plano não investigou. Fixar conexão, execução/tentativa e identidade das linhas, ou provar as condições que tornam a inferência válida. Validar a correspondência na versão implantada e exercitar concorrência/retry, sem presumir contrato universal. Responde parcialmente ao R09 (`REVISAO.md:823`). | bloqueante |
| P02 | §4, itens 1, 3 e 4; §5/D39-b | **A prova por tabela não cabe no registro agregado.** `_capturas(snapshot_id, job_id, rows_synced, capturado_em)` não guarda nome/contagem/estado de cada stream. Comparar o total do próprio destino com `rowsSynced` não prova extração integral, nem detecta perdas compensadas por duplicatas ou truncamento dentro de tabela não vazia. V04/V05 mostram job bem-sucedido e total exato com `brands` ausente; o teste de presença cobre esse caso limitado. Declarar esperado de extração independente por stream, conclusão/erro e vazio legítimo. Com `VAZIAS_LEGITIMAS` vazio, apagar a última linha torna remoção real indistinguível de ingestão incompleta, contrariando R09/R10 (`REVISAO.md:823–824`). | bloqueante |
| P03 | §5, itens 2–3 | **O SQL planejado contradiz D39-a e sua equação.** “Apto anterior sem id apto atual” inclui linha ainda presente que passou a rejeitada, embora o Owner diga que rejeição nova não é remoção. Ela entra em `removidos` e em `rejeitados_novos`. Se a diferença for de contagens, inclusão e remoção simultâneas ainda se anulam. Definir conjuntos de identidades e transições disjuntas: presença física, perda de aptidão e novas aptas. Provar também rejeição sem DELETE e entrada simultânea à remoção. A prova de apagar cinco clientes não discrimina esses defeitos; R10 exige exclusão física (`REVISAO.md:824`). | bloqueante |
| P04 | §§4–5; §12/D39-b | **Owner — falta o contrato de tratamento da captura anterior.** As tabelas atuais de staging e `legacy_classifications` só contêm a selecionada (V03); retenção bruta não fornece as aptas anteriores. Comparar vereditos obtidos sob tratamentos distintos pode fabricar desaparecimentos. Declarar no ADR-0044 qual tratamento avalia os dois lados, como obtê-los sem substituir a captura corrente ou ler quarentena como entrada, e como tratar a primeira execução/gerações antigas sem `_capturas`. Registrar custo/materialização e equivalente BigQuery. A escolha “maior anterior completa” é compatível com ADR-0037, mas não resolve isso. | bloqueante |
| P05 | §3, migração e prova | **Falta a entrada do banco existente no ciclo Alembic.** V04 encontrou 40 tabelas e nenhuma `alembic_version` em `legacy_db`. `downgrade` não desfaz DDL nunca versionado; autogenerate sobre esse schema pode gerar revisão vazia, e uma revisão de criação aplicada diretamente pode colidir com as tabelas. Separar geração/aplicação do zero em banco isolado da adoção verificada do schema existente; não usar `stamp` sem conferir equivalência. `alembic check` compara banco com metadata, não executa `schema.ddl()`: incluir conferência física desse caminho. Preservar os chamadores OLTP ao trocar `[alembic]` por `[oltp]`. O ADR que fixa Alembic é **0010**, não 0009. O objetivo de R12 está correto (`REVISAO.md:825`). | ajuste |
| P06 | §2, `valor_esperado_tipado`, testes e correção automática | **A recuperação universal do original é impossível e contraria o catálogo.** V05: `product_variants` #27, `color`, original `Vermelho`, injetado `NULL`, resultado canônico nulo e ocorrência `corrected`. Nenhuma normalização de tipo torna esses valores iguais. ADR-0040 preserva a conversão e admite nulo opcional. Declarar esperado canônico por transformação; exigir retorno ao original apenas onde a informação foi preservada. Não “corrigir o SQL” para satisfazer esse esperado errado. R13 pede recuperação correta, não reconstrução de informação apagada (`REVISAO.md:826,843–844`). | bloqueante |
| P07 | §2, oráculo e três testes | **Veredito final não mede todos os achados.** Comparar somente `classification/rejection_origin` permite perder `NULL_REQUIRED`, duplicata, correção ou motivo adicional quando outro achado conserva o mesmo rótulo. Comparação de conjuntos ainda esconde multiplicidade indevida. O grafo de FKs sozinho não declara unicidades alternativas/parciais nem totais de pedido; o contrato atual os inclui. Acrescentar esperado dos códigos, colunas, multiplicidades, vínculos causais e valores, com precisão/recall no grão explicitado, inclusive em ocorrências rejeitadas que tiveram conversão. Revisar o oráculo independentemente dos helpers do classificador e provar que erros deliberados fazem os testes falharem. `REVISAO.md:826,843–844`. | ajuste |
| P08 | §§8 e 10 | **Entrega técnica não encerra revisão e aceite.** O plano prevê preencher situações, retirar dossiê e fechar a terceira revisão antes da revisão do desenvolvimento prometida nesta conversa. Explicitar “implementado e medido, aguardando revisão” e a revisão integral do declarativo/aceite do Owner; não anunciar a Etapa 10 aceita só porque os comandos passaram. A skill autoriza retirar o transitório no commit que entrega os pedidos; não concede poder de aprovação ao executor. Preservar no registro permanente evidências e pendências antes da retirada. `REVISAO.md:827,853–854`; `CLAUDE.md` §§5/7. | ajuste |
| P09 | §6, teste estrutural | **O teste proíbe mais que D40.** A decisão permite desempate técnico dentro da captura; a proibição de qualquer ordenação legada por `event_sequence` exclui esse uso. A busca global também alcança sequências distintas de atendimento/entrega; aliases podem esconder o uso que interessa. Delimitar o campo derivado de `legacy_row_id` e a garantia proibida — ordem de evento/estabilidade entre recapturas. Quando houver consumidor relevante, uma recaptura com identidades físicas permutadas e indicadores invariantes é prova mais forte. O esclarecimento contratual em si atende R26 (`REVISAO.md:830`). | ajuste |
| P10 | §§2 e 4, afirmações [medido] | **Duas descrições não se reproduzem literalmente.** O manifesto tem 106 achados totais, **80 de valor** no recorte do teste, e 88 ocorrências; “106 falhas de valor” está errado (V02/V05). `rowsSynced` também já é retornado pela DAG como `linhas` em XCom (`fluxo_batch.py:90`), embora não seja usado para certificar a captura. Corrigir o recorte e distinguir “não validado” de “só impresso”. As demais premissas funcionais estáticas foram confirmadas no alcance descrito em V07. | ajuste |
| P11 | §§0, 5 e 7, `make test CARGA=1` | **149 passed não foi reproduzido; a prova planejada destrói a origem que deveria validar.** Coleta: 149; execução de leitura: 31 passed. `test_carga.py:53` grava com `forcar=True`, usando fator 0,05, e não restaura o lote anterior. `execucao_local.md:124–125` exige banco isolado. V04 já encontra 672 movimentos na origem principal, contra 15.900 retail na fato; isso não prova a causa histórica, mas impede tomar a suíte como certificação da mesma base. Executar testes destrutivos em bases isoladas e medir o pipeline sobre um lote comum, preservado. Manter a medição integral como não reproduzida nesta revisão. | ajuste |
| P12 | §5/D39-a; §12 | **Owner — `id` não identifica as 40 tabelas.** `inventory_movements` tem PK `movement_id` e nenhuma coluna `id` (V06), justamente na fato regida pelo ADR-0042. O ADR-0015 não restringe detecção a aptos; exclusões de rejeitados e identidade que deixa de resolver ficam sem cobertura explícita. Registrar no ADR-0044 a chave por tabela, o domínio/tipagem de `business_id`, tratamento de chave alterada/nula e destino dessas ausências. Não universalizar silenciosamente `id`, nem excluir estoque do teste. A contrapartida BigQuery precisa preservar essa identidade. | bloqueante |
| P13 | §5/D39-c; §§0/12 | **Owner — “fato não se apaga” conflita com ADR-0042 aceito.** Ele determina que o ramo legado de `fact_inventory_movement` reflita a captura corrente por `delete+insert`, removendo ausentes/rejeitados. ADR-0029 preserva membros dimensionais; não revoga essa decisão. Além disso, apagar um cliente mantém seus pedidos na origem, mas pode rejeitá-los por FK e cascatear pelos itens antes de a ponte receber a marca. Decidir se a garantia é só sobre exclusão do pai ou também exclusão do próprio fato, como interage com ADR-0038, e como as equações fecham. ADR-0044 deve emendar explicitamente o que mudar e declarar a tradução BigQuery. R25 não pode seguir fora se seu contrato mudar. | bloqueante |
| P14 | §5, materialização/ponte; §12/D39-c | **Owner — a marca dura só uma comparação.** Se uma chave existe em A, some em B e continua ausente em C, o modelo limitado a B/C não volta a entregá-la. `dim_customer.sql:73` faz inner join com o cadastro atual; guardar apenas o snapshot SCD não salva o membro quando a ponte o perde. Definir retenção/reconstituição das marcas, último payload apto, reaparecimento e reprocessamento fora de ordem; distinguir instante observado de ausência de instante real da exclusão. Materializar A antes da exclusão, reprocessar B e uma C válida, e conferir fatos/chaves/medidas sem full refresh; só construir após B não prova preservação de histórico. Isso é consequência de D39-c a resolver no ADR, não escolha silenciosa do implementador. | bloqueante |
| P15 | §4, controle/DDL; §12/R09 | **Owner — o fundamento do registro por nota está incompleto.** ADR-0023 já declarou `governance` para execução/reconciliação e o mantém fora do fluxo; ADR-0008 separa contratos das camadas. Uma nova fonte de controle que decide elegibilidade para R10 exige explicitar essa fronteira e evitar duplicação na Etapa 11. Nota no ADR-0008 não basta para mudar o contrato aceito. Declarar ciclo de criação/evolução, idempotência, concorrência, falha entre captura e registro e paridade da escrita no BigQuery. ADR-0010 não obriga Alembic no warehouse; tampouco `CREATE TABLE IF NOT EXISTS` prova evolução. O `seed` vazio alternativo pode apagar controles ao ser recarregado e não deve ser escolhido pelo revisor por conveniência. | bloqueante |
| P16 | §2, ciclo de autorreferência; §12/R13 | **Owner — o teste citado não decide a origem da rejeição.** `test_self_reference_cycle_terminates_with_rejected_root` só exige duas linhas rejeitadas. V04 mede raiz `own_invalid/NULL_REQUIRED` e filho `parent_rejected/PARENT_REJECTED`; ADR-0038 fala em filho íntegro e ADR-0040 conserva o defeito próprio. Rotular toda a componente `parent_rejected` apaga a distinção usada na reconciliação. Confirmar se “cai inteiro” significa apenas `classification=rejected`, preservando a causa da raiz, ou se muda o contrato. A segunda opção exige ADR novo. Não classificar o SQL atual como defeito com base na leitura incorreta do teste. | bloqueante |
| P17 | §§2 e 7, ciclo D34; §12/SQL divergente | **Avançar para v8 não provoca a recusa descrita.** D34 acusa fingerprints diferentes sob a **mesma** captura/versão; outra versão conserva a auditoria anterior e admite a nova. A prova precisa alterar o tratamento mantendo o rótulo, medir recusa e retenção, avançar a versão, medir sucesso e reverter de forma identificada. Correções da §2 também exigem regeração/build e versão coerente antes de comparar com o manifesto; `make test` seguido apenas de `dbt-test` pode continuar lendo v7 materializada. A autorização para corrigir não dispensa esse ciclo. `REVISAO.md:841–842`. | ajuste |
| P18 | §§2 e 5, manifesto/oráculos | **O oráculo não está ligado a uma captura e pode confirmar a própria ação declarada.** O arquivo atual tem só `achados/ocorrencias` (V02); a proposta acrescenta listas, sem identidade do lote, tratamento esperado, imagem anterior/posterior ou vínculo verificável com A/B. Depois de remover/regerar, um único arquivo mutável não serve simultaneamente para capturas antigas e novas. Preservar manifestos identificados por conteúdo/parâmetros e conferir o vínculo com o bruto selecionado. A remoção deve registrar retorno efetivo e confirmação da transação, não só IDs sorteados; também provar ausência e payload dos sobreviventes. Os modelos nunca devem ler esse esperado. | ajuste |
| P19 | §§7 e 9 | **A DAG ao vivo exige Airbyte disponível; a sequência manda pausá-lo.** Execução Local §5 e o preflight agrupam Airbyte/Airflow em `batch`; subir Airflow não faz a pausa prometida. Manter ambos ativos contraria a descrição geral invocada pelo plano e exige resolver o cenário com o Owner, considerando as duas sincronizações paralelas. O número de 4,5 GB não é o pico do ADR-0041. Foram observados só 1,03 GiB disponíveis, sem medição de pico nesta revisão. Separar simulação da DAG de prova ao vivo; antes desta, cenário e capacidade precisam estar resolvidos. Não usar `FORCE=1` nem retomar serviço para contornar recusa. | bloqueante |
| P20 | §7, reconstrução dos três bancos | **O “do zero” deixa estados externos incompatíveis e uma dependência ausente.** Apagar volumes PostgreSQL não limpa cursores/configuração do Airbyte; `sync-airbyte` sem reset não garante reler dados com os mesmos timestamps. O dbt de estoque lê `raw.inventory_movements_stream` (`stg_retail__inventory_movements.sql:50`), criada pelo sink, ausente no warehouse novo; a sequência não a repõe. Slots/offsets dos consumidores também não são resolvidos por apagar os bancos. Preferir banco isolado para R12; se mantiver reconstrução integral, declarar isolamento, preservação/retorno, reset coordenado e preparação do destino pelo caminho versionado já existente, sem subir serviços incompatíveis. | bloqueante |
| P21 | §§4–5 e 7, comandos de prova | **As contraprovas podem testar estado antigo ou não produzir a captura anunciada.** `dbt-test` não rematerializa `legacy_selected_capture`: após duas syncs pode continuar testando 16. Renomear uma tabela pode abortar o job sem criar C; pausar `legacy_db` só exercita a recusa de job falho, que já existe, sem alcançar o novo vínculo. O plano também não restaura banco/tabela e uma captura válida antes do build positivo seguinte. Fixar e conferir captura/job em cada etapa, preparar a seleção, distinguir falha sem captura de captura parcial e provar o bloqueio antes de publicar removidos; não interpretar tabela antiga/inexistente após build abortado como zero falso positivo. R09/R10 e `REVISAO.md:839–840`. | ajuste |
| P22 | §§2, 5, 6, 8 e 10 | **Faltam donos declarativos e o restante da definição de pronto.** `_legacy__models.yml` é gerado por `classification.py`; inserir `unit_tests:` só no derivado desaparece em `make legacy-models`. O dicionário também é gerado. Identificar os geradores a alterar e registrar metadados/linhagem/classificação dos novos controles, identidades, marcas e `last_payload`, além das equações afetadas, índices de ADR e mapa de paridade. Não marcar critérios prontos com “testes passam **ou** corrigiu a declaração”: o derivado corrigido precisa ser reexecutado. São requisitos de `CLAUDE.md` §§5/7 e da coerência cobrada em R14 (`REVISAO.md:827`). | ajuste |
| P23 | §§1, 7, 10 e 11 | **A validação não cobre toda a lista que anuncia.** `REVISAO.md:845–849` inclui concorrência/restauração real de ambientes, aplicação do chart, picos/OOM, streaming e paridade GCP; a §7 não tem passos que os demonstrem. Delimitar o que foi coberto por entregas posteriores, o que será exercitado aqui e o que continua pendente, sem reabrir D36 por implicação. Identificar no dossiê o número efetivo de commits e a versão final; o `fix:` condicional pode produzir mais ou menos que os “nove” anunciados. Esta revisão não executou nem certificou esses caminhos. | observação |

Nenhum P acima foi implementado nesta revisão. Só esta seção foi acrescentada ao plano.
As decisões com objeção permanecem com o Owner; as validações de desenvolvimento e o
encerramento formal da Etapa 10 continuam pendentes.

Conferência da alteração documental: `git diff --check` terminou com código 0 e sem saída.
A comparação binária com `git show HEAD:PLANO_fechamento_etapa_10.md` confirmou que o conteúdo
anterior continua sendo prefixo intacto. Trechos literais dessa conferência e de `git status --short`:

~~~text
original_sha256: 3a5f53c388f2a3f74b7e02f3fc37c640856671428535e8be5a9990c289e788ea
prefix_preserved: True
section_13_count: 1
findings: 23
bloqueante: 12
ajuste: 10
observação: 1
unique_ids: True
 M PLANO_fechamento_etapa_10.md
~~~
