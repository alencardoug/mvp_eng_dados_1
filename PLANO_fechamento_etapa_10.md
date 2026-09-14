# Plano — fechar os achados abertos da Etapa 10

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item. Escrito em 14/09/2026 sobre `a66f869`
> (`feat/troca-entre-ambientes-pesados`), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: o que está marcado **[medido]** tem saída de comando por trás; o que está
> marcado **[planejado]** é intenção. Os dois não se misturam (P5).

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

### Perguntas de semântica que o oráculo obriga a fechar (antes de codificar)

São casos em que a documentação vigente não decide, e o oráculo independente **não pode** copiar o
que o SQL faz por acaso. Proponho e peço confirmação:

| Caso | Proposta | Alternativa |
|---|---|---|
| Filho aponta para `id` de negócio que existe numa linha rejeitada **e** numa canônica aceita (excedente de `DUP_EXACT`) | **Não cascateia** — o pai de negócio existe e está apto | Cascatear se qualquer ocorrência do pai foi rejeitada |
| `DUP_PARTIAL` rejeita as duas versões; filhos delas | Cascateiam (nenhuma versão está apta) | — |
| Pai rejeitado por `NULL_REQUIRED` na própria chave (`id` nulo) | Filhos que apontariam para ele são `FK_ORPHAN`, não `PARENT_REJECTED` (o vínculo não resolve) | Tratar como cascata |
| Ciclo de auto-referência com raiz rejeitada | Toda a componente é `parent_rejected` (é o que `test_self_reference_cycle_terminates_with_rejected_root` já fixa) | — |

Se alguma resposta for diferente do que o SQL faz hoje, **o SQL está errado e o achado é bloqueante**
— é o que o oráculo existe para descobrir. A resposta vai para o dono documental
(`origem_legada.md` §5), não para o teste.

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

   > **Decisão do Owner:** escrever `raw_legacy._capturas` é acrescentar uma tabela a um schema
   > declarado como "snapshot imutável do Airbyte". Alternativas: (a) tabela de controle em
   > `raw_legacy` (**recomendo** — fica ao lado do que descreve, e o nome com `_` a separa das
   > 40); (b) em `trusted` como *seed*/modelo — mas é escrita de ingestão, não de transformação;
   > (c) não persistir e verificar só em tempo de DAG — perde a prova para `make sync-legacy` e
   > para o teste dbt. Se (a), é **nota no ADR-0008** (o schema ganha uma tabela de controle), não
   > ADR novo; se o Owner discordar, vira Dnn.

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

### Decisões que precisam do Owner antes do código

As Pendências dizem que R10 é "implementação, não decisão". Concordo quanto ao *se*; o *como*
tem três escolhas que mudam modelagem, e eu não as tomo sozinho:

| # | Pergunta | Recomendação | Alternativas |
|---|---|---|---|
| D39-a | **Qual identidade diz "mesmo registro" entre capturas?** | A chave de negócio da origem (`id`), **depois do tratamento** — só entre ocorrências aptas (`accepted`/`corrected`) das duas capturas. Comparar bruto contra bruto acusaria como "removido" o que na verdade passou a ser rejeitado, e são coisas diferentes | `legacy_row_id` (não é estável — descartado); `original_payload` inteiro (frágil a qualquer correção) |
| D39-b | **O que é "captura anterior completa"?** | A maior `snapshot_id < selecionada` que passa em `legacy_captura_completa` **e** cujas contagens conferem com `_capturas` (R09). Captura incompleta é pulada, nunca comparada — é isto que "distingue remoção real de falha de ingestão" | Sempre `selecionada − 1` (compararia contra carga quebrada) |
| D39-c | **Onde o removido aparece, e o que acontece com ele adiante?** | Modelo `trusted.legacy_removed_records` (`source_table, business_id, last_seen_snapshot_id, removed_in_snapshot_id, last_payload`), lido pela reconciliação; e **marca `is_deleted`/`deleted_at`** carregada até a dimensão, pelo mesmo caminho do ADR-0029 — a origem apagou, o datamart lembra. Fato não se apaga | Só reportar, sem marca (o datamart esqueceria o membro, e as fatos antigas ficariam órfãs — contradiz o ADR-0029); enviar para `quarantine` (não é rejeição, é ausência) |

Se o Owner confirmar as três recomendações, **isto é ADR** — muda a modelagem do empilhamento
(marca de exclusão vinda de ausência, não de coluna). Proponho registrar como **D39** e fechar por
`/adr` antes de codificar. Se preferir só reportar (sem marca), continua sendo nota no ADR-0015.

### O que muda **[planejado]**, assumindo as recomendações

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

Entra no plano como **D40** (decisão de contrato), fechada por nota no ADR-0039 ou ADR próprio se
a resposta for a segunda.

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
6. `docs: registra ADR-0044 — exclusão física do legado como marca` (D39, se confirmado)
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

## 12. Perguntas ao Owner, resumidas

Antes de codificar, preciso de resposta para: **D39-a, D39-b, D39-c** (R10), **D40** (R26), a
**tabela de controle `raw_legacy._capturas`** (R09) e as **quatro semânticas de cascata** (R13).
Tudo o mais é implementação do que já está decidido.
