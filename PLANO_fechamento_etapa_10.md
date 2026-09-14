# Plano — fechar os achados abertos da Etapa 10

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item. Escrito em 14/09/2026 sobre `a66f869`
> (`feat/troca-entre-ambientes-pesados`), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: o que está marcado **[medido]** tem saída de comando por trás; o que está
> marcado **[planejado]** é intenção. Os dois não se misturam (P5).
>
> **Revisão 3 — 14/09/2026.** Reescrito depois do parecer do revisor (§13, preservado na íntegra
> como veio) e de mais uma rodada de decisões do Owner sobre as consequências que o parecer
> devolveu. A §12 tem as onze decisões; a §14 diz o que foi feito com cada um dos 23 achados
> P01–P23. As duas primeiras revisões estão no `git` (`f51fc2a`, `819b88f`).

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

Já fechado e **fora deste plano**: R25 (ADR-0042 — e a decisão P13 o mantém como está) e a quarta
revisão (memória/reconciliação, `2fb6f55`). Também fora: **D36** e a Etapa 11.

**[medido]** em 14/09/2026 (por mim e reproduzido pelo revisor, §13.2 V03–V05): armazém com
captura **16**, tratamento **v7**, **16/16** views, fato **16.453** (15.900 `retail` + 553
`legacy`); `raw_legacy` retém as gerações 1–16 (`customers`: 75 linhas em cada); a geração **15
tem 39 tabelas** (`brands` ausente) e o *job* 25 dela terminou `succeeded` com `rowsSynced`
exato — é uma **contraprova real já retida** para o R09. Manifesto: 106 achados, dos quais **80
de valor** no recorte do teste e 26 de contexto; 88 ocorrências diretamente atingidas.
`trusted.legacy_classifications`: 10.441 `accepted`, 26 `corrected`, 67 `own_invalid`, 3
`duplicate_excess`, 2.210 `parent_rejected`.

**Um estado que este plano herdou e consertou hoje:** `make test CARGA=1` substitui `source_db`
pela carga reduzida (fator 0,05; `test_carga.py:53`), e a Execução Local §3.2 já dizia "só em banco
isolado". Foi executado contra a origem de trabalho em 08/09 e de novo em 14/09. Restaurado em
14/09 por `make seed-data FORCE=1` (252.955 linhas); `customers`, `orders`, `order_items` e
`products` conferem com o `raw` por chave e `updated_at` (mesmo `md5`). **O "149 passed" citado
nas versões anteriores não vale como medição da base** — o revisor reproduziu 31 (leitura), e este
plano trata a suíte de carga como o que ela é: destrutiva, só em banco isolado (§9).

---

## 1. Ordem, e por quê

```
R13 ──┐
      ├──► ADR-0044 ──► R10 ──► validação ──► R14 (estado medido; "aguardando revisão", não "aceita")
R12 ──┤                  ▲
R09 ──┘                  │
R26 (nota de referência; entra no commit do R14)
```

1. **R13 primeiro.** Só código local; produz o oráculo do lote que a validação final usa.
2. **R12 em paralelo lógico**, em banco isolado — não toca no armazém nem no `legacy_db` até a
   equivalência estar provada.
3. **R09 antes de R10**: o registro de captura por *stream* é o que define "anterior completa".
4. **ADR-0044 antes do código do R10** — a implementação nasce do ADR.
5. **Validação** com tudo entregue, no cenário `batch` (bancos + Airbyte + Airflow), com a máquina
   liberada pelo Owner.
6. **R14 por último**, e o que ele declara é "implementado e medido, **aguardando revisão**" — a
   entrega técnica não encerra revisão nem aceite (P08). O `REVISAO.md` e este plano saem no
   *commit* de entrega porque são transitórios, **não** porque a etapa foi aceita; o parecer e as
   situações ficam no histórico antes de sair.

---

## 2. R13 — o esperado independente por ocorrência

### O que existe hoje **[medido]**

- Manifesto com `achados` (106; 80 de valor no recorte `DE_CONTEXTO`) e `ocorrencias` (88).
- `test_os_modelos_encontram_tudo_que_o_injetor_produziu` compara **só** achados de valor do
  `staging`, excluindo os cinco códigos de contexto.
- **Nenhum teste** compara `trusted.legacy_classifications` com um esperado por ocorrência; a
  cascata (2.210 linhas, 17% da captura) não tem oráculo; valores recuperados são conferidos por
  amostra dirigida. `test_legacy_classification.py` é especificação por casos do autor — útil, não
  lote.
- Caso decisivo (P06, V05): `product_variants` #27, coluna `color`, original `Vermelho`, injetado
  `'NULL'` (`NULL_DISGUISED`), resultado **nulo** e `corrected`. Está certo pelo ADR-0040: o
  esperado **não** é o original.

### O que muda **[planejado]**

**Declaração (revisão integral):**

1. **`catalogo.yml`** — cada falha declara `recuperacao: original | canonico`, e para `canonico` o
   alvo (`nulo`, `forma_canonica`…). É a semântica de cada transformação dita **uma vez**, no
   catálogo, e é de lá que o oráculo tira o valor esperado. `NULL_DISGUISED` → `canonico: nulo`;
   `TEXT_ENCODING`, `TEXT_WHITESPACE_CASE`, `MONEY_LOCALE`, `DATE_FORMAT_KNOWN`, `BOOL_VARIANT`,
   `NUM_TEXT_EQUIV` → `original` (a informação foi preservada). Revisão integral desta tabela pelo
   Owner: ela é o contrato de recuperação (R07 já cobrava).
2. **`injetor.py`** — `Resultado.esperado_por_ocorrencia()` devolve, para **toda** ocorrência
   gerada, o **multiconjunto de achados esperados** — `(codigo, coluna, vinculo_causal)` —, a
   `classification`, a `rejection_origin` e, por achado corrigível, o `valor_esperado` derivado do
   item 1. Calculado a partir das **mutações que o próprio injetor aplicou**, do conjunto íntegro
   anterior à injeção e do grafo declarativo (`Base.metadata`: FKs, PKs, unicidades parciais,
   obrigatoriedade; totais de pedido pela regra do catálogo) — **sem importar nada de
   `classification.py`, `dbt.py` ou `ponte.py`**. O grafo é declaração comum; os *helpers* do
   classificador não são (13.4).
3. **Semântica da cascata — decidida pelo Owner em 14/09/2026**, e é o que o oráculo implementa:

   | Caso | Decisão |
   |---|---|
   | Filho aponta para `id` que existe numa excedente de `DUP_EXACT` rejeitada **e** numa canônica apta | **Não cascateia** |
   | `DUP_PARTIAL` rejeita as duas versões | Filhos **cascateiam** (`parent_rejected`) |
   | Pai rejeitado por `NULL_REQUIRED` na própria chave | Filhos são **`FK_ORPHAN` / `own_invalid`** — o vínculo não resolve |
   | Ciclo de auto-referência com raiz rejeitada | Toda a componente é `rejected`; **a raiz conserva a causa própria** (`own_invalid`), os alcançados são `parent_rejected` — é o que o SQL faz hoje (V04) |

   As quatro são **compatíveis** com ADR-0038/0040 — nota de referência nos donos, sem ADR (P16).
4. **Manifesto ligado ao lote (P18):** ganha `lote: {semente, fator, versao_catalogo, geradas_por_tabela,
   hash_das_identidades}`; o teste confere que a captura selecionada tem as mesmas contagens e o
   mesmo conjunto de `legacy_row_id` por tabela **antes** de comparar vereditos. Manifestos são
   gravados com o `hash` no nome (`manifesto-<hash>.json`), e o mais recente é um *symlink* —
   regerar não apaga o anterior, que o R10 precisa.

**Derivado (amostragem):**

5. Três testes novos em `tests/test_legado_deteccao.py`, sobre `trusted.legacy_classifications`
   da captura selecionada, uma consulta por tabela (ADR-0043):
   - **veredito e achados**: para cada ocorrência, `(classification, rejection_origin)` e o
     **multiconjunto** de `(code, column, vínculo)` de `findings` iguais ao esperado — a
     diferença é impressa dos dois lados (precisão e *recall* no grão da ocorrência × achado);
   - **cascata**: cada `parent_rejected` aponta (`context.parent_table/parent_row_id`) para o pai
     que o oráculo diz;
   - **recuperação**: `cleaned_payload->>coluna` igual ao `valor_esperado`, com comparação tipada
     pelo tipo do modelo SQLAlchemy, **inclusive** em ocorrências cujo veredito final é rejeição
     (a conversão é preservada pelo ADR-0040).
6. **Contraprova por mutação (13.4):** um teste que injeta um defeito deliberado no oráculo
   (inverte um caso da cascata) e outro que o injeta no SQL compilado (troca um código) e afirma
   que os testes do item 5 **falham**. Sem isso, dois algoritmos do mesmo autor concordando não
   provam nada.
7. `DE_CONTEXTO` sai: os cinco códigos passam a ser cobertos pelo teste de veredito.
8. Se o oráculo e o SQL divergirem, **o SQL se corrige na mesma entrega** (decisão do Owner), um
   `fix:` por defeito — e a correção exige o ciclo inteiro (P17): regerar modelos, subir a
   `versao` do catálogo (v8) porque o tratamento mudou, `make dbt-build`, e só então comparar.
   Tratamento diferente sob a **mesma** versão é o que a D34 recusa — e essa recusa é medida uma
   vez de propósito no §7, não contornada aqui.

### Prova

```
make seed-legacy FORCE=1                                   # manifesto novo, com lote identificado
make dbt-build DBT_ARGS='--select legacy_selected_capture+'  # o legado inteiro, na captura corrente
make test                                                  # os testes novos + mutação
```

Saída esperada: `faltando = []`, `sobrando = []`, `recuperados = N/N`, e os dois testes de mutação
**falhando de propósito e passando por isso**.

### Critério de pronto

- [ ] Toda ocorrência da captura tem veredito e achados esperados, calculados sem ler o classificador.
- [ ] `recuperacao` declarada no catálogo para todo código corrigível, revisada pelo Owner.
- [ ] Os testes passam sobre a captura selecionada, **depois** de regerar e reconstruir; e falham sob mutação.
- [ ] Manifesto identificado pelo lote; a captura conferida contra ele antes de comparar.

---

## 3. R12 — o schema legado no ciclo Alembic

### O que existe hoje **[medido]**

`alembic.ini` → `db/migrations`, uma revisão (schema `oltp`), alvo `source_db`. `legacy_db` tem
as 40 tabelas e **nenhuma `alembic_version`** (V04). O ADR que fixa o Alembic é o **0010**.

### O que muda **[planejado]**

1. Segundo ambiente, `db/migrations_legacy/`, com `env.py` apontando para `legacy_db` e
   `target_metadata` derivado de `schema.py`. No `alembic.ini`, a seção `[alembic]` existente
   **continua** sendo a da origem principal (nenhum chamador muda); entra `[legacy]`, usada por
   `-n legacy`.
2. Revisão inicial gerada por *autogenerate* **num banco isolado vazio** e revisada (é derivado;
   a declaração é `schema.py`). `downgrade` derruba o schema.
3. **Adoção do `legacy_db` existente, em três passos medidos (P05):** (a) catálogo físico do banco
   isolado migrado; (b) catálogo físico de um segundo banco isolado criado por `schema.ddl()` —
   o caminho de referência; (c) catálogo físico do `legacy_db` atual. Os três comparados por
   `information_schema` (tabelas, colunas, tipos, nulabilidade, *constraints*, ordem). **Só se os
   três forem idênticos** o `legacy_db` recebe `alembic stamp head`; se não forem, o que diverge
   é achado e se conserta na declaração antes de qualquer `stamp`.
4. `writer.criar_schema` deixa de emitir DDL: exige `alembic_version` na cabeça e falha apontando
   `make migrate-legacy`. `schema.ddl()` permanece como **referência de teste** (item 3b), não
   como caminho de criação.
5. `Makefile`: `migrate-legacy`, `migrate-legacy-status`, `migrate-legacy-down`; `seed-legacy`
   depende de `migrate-legacy`. Execução Local §3 ganha a linha.
6. `tests/test_migracao_legado.py`: em banco isolado (`createdb` efêmero no próprio contêiner
   `legacy_db`), `upgrade head` → carga representativa → `downgrade base` → `upgrade head`, e a
   comparação tripla do item 3 como teste, não só como procedimento.

Não é ADR novo: aplica o ADR-0010 à segunda origem. Nota datada em `origem_legada.md` §2.

### Prova

```
.venv/bin/alembic -n legacy upgrade head     # no banco isolado; saída literal
<comparação tripla>                          # 0 diferenças
.venv/bin/alembic -n legacy stamp head       # só depois do zero acima
make migrate-legacy-status && make test
```

### Critério de pronto

- [ ] `legacy_db` isolado sobe do zero só por migração; `downgrade`/`upgrade` medidos.
- [ ] Equivalência tripla provada **antes** do `stamp` no banco existente.
- [ ] `criar_schema` não emite DDL.

---

## 4. R09 — a captura pertence à sincronização que acabou de acontecer

### O que existe hoje **[medido]**

- `geracao_do_legado` lê `max(_airbyte_generation_id)` depois da sincronização; `rowsSynced` já
  vai ao XCom como `linhas` (`fluxo_batch.py:90`), **mas não certifica nada** (P10).
- **V04:** em todas as linhas das gerações 15 e 16, `_airbyte_meta->>'sync_id'` é igual ao
  `jobId` (25 e 26). A documentação do Airbyte descreve `sync_id` como identificador monotônico
  da sincronização, sem prometer essa igualdade — é **contrato observado na versão instalada**, e
  entra como tal: fixado por teste, não presumido universal.
- **Geração 15:** *job* `succeeded`, `rowsSynced` = 12.746 = total da geração, **39 tabelas** —
  `brands` não veio. Máximo crescente e total exato **aceitariam** essa captura.

### O que muda **[planejado]**

**Declaração:**

1. **Registro de captura por *stream*, em `governance.legacy_captures`** — decidido pelo Owner em
   14/09/2026, pelo ADR-0023 (log de execução: "cada execução de pipeline, início, fim,
   resultado"). Uma linha por `(job_id, source_table)`:
   `snapshot_id, source_rows_before, source_rows_after, received_rows, sync_id_matches, status,
   captured_at`. Escrita por `mvp_ed1/airbyte.py::registrar_captura(job)`, chamada pela DAG e por
   `make sync-legacy` — uma implementação, dois chamadores.
   - `source_rows_before/after`: contagem em `legacy_db` por tabela, **antes de disparar** o *job*
     e **depois** de ele terminar. Diferentes → a origem mudou durante a carga → `status =
     unstable`, captura **não elegível** (nem como selecionada nem como anterior). É o esperado
     de extração **independente do destino** que o P02 pede.
   - `received_rows`: linhas em `raw_legacy.<t>` com `_airbyte_generation_id = snapshot_id` **e**
     `_airbyte_meta->>'sync_id' = job_id`. `sync_id_matches = false` se alguma linha da geração
     tiver outro `sync_id`, ou se linhas com este `sync_id` estiverem noutra geração → `status =
     inconsistent`.
   - `status = complete` só se, para **todas** as 40 tabelas, `received_rows = source_rows_after`
     e `source_rows_before = source_rows_after` e `sync_id_matches`. Tabela com 0 na origem e 0
     recebida é **completa** — `VAZIAS_LEGITIMAS` deixa de ser lista declarada e vira medida
     (resolve a tensão que o P02 apontou: apagar a última linha de uma tabela é remoção, não
     ingestão incompleta, porque a origem também diz 0).
   - Criação: DDL idempotente e versionado em `mvp_ed1/governance.py` (o armazém não tem
     Alembic, e o ADR-0010 não o exige lá); evolução por função de migração no mesmo módulo, com
     teste. O revisor decide no parecer se isso basta ou se o armazém precisa entrar no Alembic —
     é escopo da Etapa 11, e fica dito.
   - **Nota datada no ADR-0023:** a tabela é a primeira do conjunto "log de execução", e é **lida
     pelo fluxo** (os modelos do legado a declaram como `source` para decidir elegibilidade) — a
     única leitura de `governance` pelo pipeline, dita e justificada. Paridade: *dataset*
     `governance` no BigQuery, mesma tabela, escrita pelo mesmo Python.
2. **DAG:** `contar_origem_do_legado` antes de `sincronizar`, `registrar_captura(job)` depois;
   `geracao_do_legado` passa a devolver o `snapshot_id` **do registro `complete`**, e falha se o
   *job* não produziu um. A docstring perde "o que esta tarefa não prova" e ganha o que prova.
3. **Testes dbt** (`legacy/dbt.py`): `legacy_captura_existe` mantido; `legacy_captura_completa`
   passa a exigir `status = complete` no registro da captura selecionada **e** as contagens por
   tabela iguais — a geração 15 falha aqui, medido. Capturas 1–16 **não têm registro** e não têm
   como ter (as contagens de origem passaram): para elas a elegibilidade como "anterior completa"
   é **negada por construção**; a primeira comparação do R10 acontece entre duas capturas novas.
   Fica dito no ADR-0044.
4. **Premissas e o que não se exercita:** tentativa repetida (*retry*) do mesmo *job* — o teste de
   `sync_id_matches` recusa mistura entre gerações, mas um *retry* que reescreva a mesma geração
   com o mesmo `sync_id` não é reproduzível localmente sem forçar falha no destino. Registrado
   como premissa no dossiê, não como prova.

### Prova (Airbyte de pé — bloco compartilhado com R10)

```
make sync-legacy      # captura A: status=complete, 40 linhas em legacy_captures, sync_id = job
make dbt-build DBT_ARGS='--select legacy_selected_capture legacy_captura_completa legacy_captura_existe'
```

**Contraprovas:** (a) a geração 15 retida — `legacy_snapshot_id=15` → `legacy_captura_completa`
falha por `brands` e por ausência de registro; (b) captura **incompleta mas `succeeded`**:
desabilitar o *stream* `brands` na conexão pela API, `make sync-legacy` (captura C) → registro com
`status = incomplete`, `geracao_do_legado` recusa; reabilitar o *stream* e sincronizar de novo
antes de qualquer *build* positivo (P21). Renomear tabela e pausar o banco **não** servem: só
produzem *job* falho, que já é recusado hoje.

### Critério de pronto

- [ ] Captura nova, reutilizada, `unstable` e `incomplete` produzem resultados diferentes, medidos.
- [ ] `sync_id = job_id` fixado por teste na versão instalada.
- [ ] Geração 15 recusada pelo teste dbt.

---

## 5. R10 — exclusão física entre capturas completas

### O que existe hoje **[medido]**

`raw_legacy` retém tudo; nenhum modelo compara capturas; registro apagado some do armazém sem
rastro. `legacy_row_id` é renumerado a cada geração. **`inventory_movements` não tem coluna
`id`** — a PK é `movement_id` (V06). Quatro *snapshots* SCD existem (`scd_customer`,
`scd_product`, `scd_coupon`, `scd_support_agent`), sem tratamento de *hard delete*; `dim_customer`
faz *inner join* com o cadastro atual (`dim_customer.sql:73`).

### D39 — decidida pelo Owner em 14/09/2026, refinada na segunda rodada

| # | Decisão |
|---|---|
| D39-a′ | **Remoção é ausência física no bruto.** `legacy_removed_records` compara presença em `raw_legacy`, pela **PK declarada no SQLAlchemy por tabela** (`id` em 39, `movement_id` na 40ª — lida de `Base.metadata`, nunca literal), entre a anterior completa e a selecionada. Chave nula ou não conversível não entra na comparação e é reportada como `sem identidade` (é `NULL_REQUIRED`, rejeição própria). Três transições **disjuntas** por tabela: `removida` (presente antes, ausente agora), `adicionada`, `mantida` — e a equação física `presentes(anterior) − removidas + adicionadas = presentes(selecionada)` fecha por construção. Aptidão **não** entra na detecção: rejeição nova não é remoção (P03), e a captura anterior não é classificada (P04) |
| D39-b | "Anterior completa" = maior `snapshot_id < selecionada` com `status = complete` em `governance.legacy_captures`. Sem registro (gerações 1–16) → não elegível |
| D39-c′ | **A fato segue o ADR-0042** — o movimento que sumiu sai do ramo legado por `delete+insert`, aparece em `legacy_removed_records` e a reconciliação explica (P13). **A marca é nas dimensões**, e persiste por construção pelo mecanismo nativo do dbt: os quatro *snapshots* passam a `hard_deletes: new_record` — membro que some da entrada ganha versão nova com `dbt_is_deleted = true`, e ela dura em toda captura seguinte (P14). A dimensão lê a última versão do *snapshot* (o *inner join* com o cadastro atual sai) e marca `is_deleted = true` **só** quando a chave está em `legacy_removed_records` — ausência **sem** remoção física (perda de aptidão) mantém o membro na última versão válida, não marcado, e é contada na reconciliação como `perdeu_aptidao = sumiu_do_snapshot − removidas`. Reaparecimento: versão nova, `dbt_is_deleted = false`, `is_deleted = false` |

**ADR-0044** registra as três, a chave por tabela, o universo coberto (presença física; aptidão
é outra pergunta), a relação com ADR-0015/0029/0037/0038/0042 (nenhum é substituído; 0042 é
**confirmado**), o custo (mais uma versão por membro removido nos *snapshots*) e a paridade
(BigQuery: mesma comparação entre partições por `snapshot_at`; `hard_deletes` é do dbt, igual lá).
Entra em `pendencias.md` como D39 decidida e é fechado por `/adr` **antes** do código.

### O que muda **[planejado]**

**Declaração:**

1. `cli.py` ganha `remover --tabela T --quantidade N`: escolhe N chaves **aptas** (pelo oráculo
   do R13) de forma determinística, executa o `DELETE … RETURNING`, **grava no manifesto o que o
   banco devolveu** (chaves e payloads efetivamente apagados, confirmação pós-*commit* de que não
   existem mais) — não o que sorteou (P18). Manifesto anterior preservado (§2 item 4).
2. `trusted/legacy/legacy_removed_records.sql` (`table`): as três transições da D39-a′, com
   `source_table, business_key, last_seen_snapshot_id, removed_in_snapshot_id, last_payload`
   (o `original_payload` bruto da última captura em que existiu — não é tratado, e o dicionário
   diz isso).
3. `dbt/tests/legado_presenca_fisica_reconcilia.sql`: a equação física por tabela.
4. *Snapshots*: `hard_deletes: new_record` nos quatro; dimensões leem a última versão; `is_deleted`
   conforme D39-c′. `dim_customer` e as outras três ganham a coluna onde ainda não existe, com
   classificação de sensibilidade e descrição **no gerador do YAML** onde for gerado (P22).
5. **Unit tests dbt** para `legacy_removed_records`, declarados **em `classification.py`**, que
   gera `_legacy__models.yml` (P22) — duas capturas fictícias: anterior completa com remoção;
   anterior `incomplete`, que deve ser ignorada. Primeiro uso de `unit_tests:` no projeto — nota
   em `qualidade_de_dados.md`.
6. `tests/test_legado_remocao.py` (integração, banco de trabalho, **só leitura**): compara
   `legacy_removed_records` com `manifesto.removidas` depois do ciclo real; e confere as marcas
   nas dimensões.

### Prova (Airbyte de pé; a máquina liberada — §9)

Sequência única, cada passo com captura e *job* conferidos antes do seguinte (P21):

| Passo | O que prova |
|---|---|
| captura **A** (`complete`) → `dbt build --select legacy_selected_capture+` | linha de base materializada, marcas zero |
| `remover customers 5` (manifesto grava as 5 devolvidas) + **rejeição nova sem apagar** (`UPDATE` que torna 1 cliente inválido) + **inserção** de 1 cliente → captura **B** → *build* incremental | `removidas = 5` iguais ao manifesto; `perdeu_aptidao = 1`; `adicionadas = 1`; `is_deleted` só nas 5; a fato perdeu os movimentos das 5 e a reconciliação explica |
| captura **C** sem mudança → *build* | as 5 marcas **persistem** (P14); `removidas` de C contra B = 0 |
| reinserir 1 dos 5 → captura **D** → *build* | reaparecimento: `is_deleted = false`, versão nova |
| `remover` a **última** linha de uma tabela pequena → captura **E** | tabela com 0 na origem e 0 recebida é `complete`; a remoção é detectada como remoção |
| desabilitar *stream* → captura **F** `incomplete` → tentar *build* | `legacy_captura_completa` falha; `legacy_removed_records` **não** acusa a tabela ausente; reabilitar antes de seguir |

### Critério de pronto

- [ ] As seis provas medidas, com saída literal.
- [ ] Equação física fecha por tabela em todo *build*.
- [ ] Unit tests dbt no gerador; ADR-0044 aceito antes do código.

---

## 6. R26 — o contrato de `event_sequence` no legado

**Decidido pelo Owner em 14/09/2026 (D40):** `event_sequence` nas linhas legadas é desempate
técnico **dentro da captura** — sem promessa de ordem entre capturas nem de ordem observada do
evento. Nota datada **de referência** no ADR-0039, apontando para o dono (`origem_legada.md` §4.1);
nenhum ADR aceito promete o contrário (13.3).

Entrega: comentário em `ponte.py:68` reescrito; dicionário de dados (no gerador que o produz);
e um teste **delimitado** (P09): nas linhas `source_system = 'legacy'`, `event_sequence` é único
por `(snapshot_id, source_table)` e igual a `legacy_row_id` — o contrato como está escrito, nada
além. O teste estrutural "nenhum consumidor ordena por `event_sequence`" **sai**: proibia mais do
que a decisão e confundiria colunas homônimas.

---

## 7. Validação

Separada em **simulada** (sem ambiente pesado) e **ao vivo** (cenário `batch`), e a lista de
`REVISAO.md:835–849` marcada item a item (P23):

| Item da lista | Situação neste plano |
|---|---|
| Build integral, 16 views, reconciliação | **Aqui**, `make dbt-build` completo depois do R13 (v8) |
| DAG do zero, vínculo *job*–captura | **Aqui, ao vivo** (§4/§5), cenário `batch` |
| Carga incompleta; duas capturas com exclusão física | **Aqui** (§4 contraprovas, §5 sequência) |
| Reprocessamento da fato incremental | **Coberto** em 08/09 (ADR-0042, `2fb6f55`); a sequência do §5 o exercita de novo com remoção real |
| Ciclo D34 | **Aqui, medido de propósito**: mesmo rótulo v7 com tratamento alterado → recusa e retenção; subir para v8 → sucesso; reverter identificado (P17) |
| Oráculo completo da cascata e valores; *recall*/falsos positivos | **Aqui** (§2) |
| Troca real de ambientes, concorrência, restauração parcial | **Pendente** — fora desta rodada; continua no `REVISAO.md`/Pendências |
| Aplicação dos valores do Airbyte ao chart, picos/OOM sob limite | **Pendente** — Etapa 12 / D36 |
| Streaming ao vivo | **Pendente** — não é desta rodada |
| Migrações do zero | **Aqui**, em banco isolado (§3); o armazém **não** é destruído (P20) |
| Paridade GCP | **Não é medível localmente**; declarada no ADR-0044 e nas notas |

**O que não se faz:** apagar volumes dos três bancos. O `raw.inventory_movements_stream` é criado
pelo *sink* do streaming e o dbt o lê; cursores do Airbyte e *offsets* não são limpos por apagar
banco (P20). A prova de migração é isolada; a de fluxo é sobre o estado corrente, conferido.

Depois de cada sincronização: `dbt build --select legacy_selected_capture+` (ou o subconjunto
declarado no passo) — `dbt test` sozinho **não** rematerializa a seleção (P21).

---

## 8. R14 — coerência documental, com o estado medido

Depois de tudo acima, e só depois:

- `docs/pendencias.md`: D39 e D40 decididas; o parágrafo "R10, R12, R13 são implementação" sai;
  §6 descreve o estado real: **"implementado e medido em <data>, aguardando revisão"** (P08).
- `docs/plano_de_desenvolvimento.md` §Etapa 10: critérios com ✓ **só** onde há medição nesta
  rodada, citando captura e versão; a frase "fronteira de empilhamento não existe" e a ressalva de
  R11 saem; a etapa **continua reaberta** até a revisão do desenvolvimento e o aceite.
- `docs/origem_legada.md` §4.2: "quem sustenta a afirmação são os dois testes" passa a descrever o
  vínculo do R09; §4.1 o D40; §5 a semântica da cascata; §3.2 o manifesto por lote.
- Geradores, não derivados (P22): `classification.py` (YAML dos modelos legados, unit tests,
  colunas novas com sensibilidade), o gerador do dicionário, `docs/arquitetura.md` §5 (linha de
  `governance.legacy_captures` e de `hard_deletes`), `docs/adr/README.md` (0044 e as notas).
- `README.md` status: Etapa 10, quarta rodada, **aguardando revisão** — nunca "aceita".
- `REVISAO.md`: coluna *Situação* dos seis achados; sai no *commit* de entrega junto com este
  plano, com o parecer e as situações já no histórico.

---

## 9. Ambiente e memória

- R13, R12, R26, R14: só os três bancos.
- **R09, R10 e a DAG: cenário `batch` = bancos + Airbyte + Airflow, juntos** — é assim que
  Execução Local §5 e o `preflight` os tratam (mesma família; `airflow-up` **não** pausa o
  Airbyte). O pico aceito do Airbyte é **4,95 GiB** (ADR-0041; `CUSTO_airbyte=5000`), não 4,5; a
  DAG dispara as duas sincronizações em paralelo, e o pico de duas + Airflow + ambiente de trabalho
  **não foi medido**. Na revisão havia **1,03 GiB disponíveis**. Conclusão: esse bloco só começa
  **depois de o Owner liberar a máquina** (fechar editor/navegador), com `make preflight` antes;
  recusa é parada, nunca `FORCE=1` (P19).
- **`make test CARGA=1` só em banco isolado**, e o Makefile passa a garantir: o alvo exige
  `CARGA_DB=<nome>` diferente de `SOURCE_DB_NAME`, cria o banco efêmero, roda e o derruba;
  `conftest.py` recusa `MVP_TESTE_CARGA=1` contra o banco de trabalho. É o que impede repetir o que
  aconteceu em 08/09 e 14/09 (P11).
- Nenhuma reconstrução seletiva sem `+` (Execução Local §6).

---

## 10. Commits previstos

Um por assunto; **o número efetivo** e a versão final vão no dossiê (P23):

1. `fix: exige banco isolado para o teste de carga` (P11 — primeiro, para não repetir o erro)
2. `feat: declara a recuperação esperada por falha no catálogo do legado` (R13, catálogo)
3. `feat: calcula o veredito e os achados esperados de toda ocorrência no gerador` (R13, oráculo)
4. `test: confere veredito, cascata e recuperação contra o oráculo, com contraprova por mutação` (R13)
5. `fix: …` — um por divergência que o oráculo encontrar, com v8 do catálogo
6. `feat: leva o schema legado para o ciclo Alembic` (R12)
7. `feat: registra cada captura do legado por stream e a vincula ao job` (R09; `governance.legacy_captures`, nota no ADR-0023)
8. `docs: registra ADR-0044 — exclusão física do legado como marca nas dimensões` (D39)
9. `feat: detecta exclusão física entre capturas completas e a leva às dimensões` (R10)
10. `docs: registra o contrato de event_sequence no legado` (R26/D40)
11. `docs: atualiza o estado da Etapa 10 com as medições — aguardando revisão` (R14; apaga
    `REVISAO.md` e este plano)

Dossiê para o revisor ao fim: `dossie.py --desde a66f869`, um só.

---

## 11. O que este plano **não** decide

- D36; descarte de capturas antigas (ADR-0037); `jit` nas origens; agendamento da Etapa 12.
- Se o armazém entra no Alembic (Etapa 11) — o `governance.py` do §4 é DDL versionado e
  idempotente, e o revisor diz se basta.
- Aceite da Etapa 10 — é do Owner, depois da revisão do desenvolvimento.

## 12. Decisões do Owner — 14/09/2026, duas rodadas

| Decisão | Resposta | Onde fica |
|---|---|---|
| D39-a′ identidade e detecção | PK declarada por tabela (`Base.metadata`); remoção = ausência **física** no bruto; três transições disjuntas | ADR-0044 |
| D39-b anterior completa | Maior `snapshot_id < selecionada` com `status = complete` em `legacy_captures`; sem registro, não elegível | ADR-0044 |
| D39-c′ destino do removido | Fato segue o **ADR-0042**; marca nas dimensões via *snapshots* com `hard_deletes: new_record`; `is_deleted` só com remoção física confirmada | **ADR-0044** |
| D40 `event_sequence` | Desempate técnico dentro da captura | Nota de referência no ADR-0039 |
| Registro de captura (R09) | **`governance.legacy_captures`**, por *stream*, pelo ADR-0023 | Nota datada no ADR-0023 |
| Cascata (R13), quatro casos | Excedente exato não cascateia · `DUP_PARTIAL` cascateia · pai com chave nula dá `FK_ORPHAN` · ciclo: tudo `rejected`, **raiz conserva a causa própria** | `origem_legada.md` §5 + notas de referência |
| SQL divergente do oráculo | Corrigir na mesma entrega, com o ciclo de versão (v8) | Dossiê |
| Origem principal reduzida pelo teste de carga | Restaurada em 14/09 (`seed-data FORCE=1`); guarda no Makefile | §0, §9 |

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


---

## 14. Situação dos achados do parecer — 14/09/2026

Todos os 23 foram aplicados na revisão 3 ou devolvidos ao Owner e decididos. Nenhum recusado.

| # | Veredito | Situação |
|---|---|---|
| P01 | bloqueante | **Aplicado, §4.** O vínculo passa a ser `_airbyte_meta.sync_id = job_id`, fixado por teste na versão instalada e conferido linha a linha (`sync_id_matches`); máximo e total deixam de ser a prova. *Retry* registrado como premissa não exercitável. |
| P02 | bloqueante | **Aplicado, §4.** Registro **por stream** com contagem na origem antes/depois do *job* e recebida; `complete` exige igualdade nas 40; tabela 0/0 é completa e `VAZIAS_LEGITIMAS` vira medida, não lista. Geração 15 é a contraprova retida. |
| P03 | bloqueante | **Aplicado, §5 / D39-a′.** Detecção por presença física; três transições disjuntas; equação física; rejeição nova é `perdeu_aptidao`, contada à parte. |
| P04 | bloqueante | **Devolvido ao Owner e decidido (D39-a′):** a captura anterior **não** é classificada; a aptidão anterior vem do histórico SCD. Gerações sem registro não são elegíveis; primeira comparação entre duas capturas novas. |
| P05 | ajuste | **Aplicado, §3.** Banco isolado, comparação física tripla antes do `stamp`, `[alembic]` preservada, ADR-0010. |
| P06 | bloqueante | **Aplicado, §2.** `recuperacao: original \| canonico` declarada no catálogo por falha; o oráculo tira o esperado de lá; `NULL_DISGUISED → nulo`. Nenhum "conserto" do SQL para satisfazer esperado errado. |
| P07 | ajuste | **Aplicado, §2.** Multiconjunto de achados por ocorrência, vínculos, valores inclusive em rejeitadas; oráculo sem *helpers* do classificador; contraprova por mutação. |
| P08 | ajuste | **Aplicado, §§1, 8.** "Implementado e medido, aguardando revisão"; retirada dos transitórios não é aceite; parecer e situações no histórico antes. |
| P09 | ajuste | **Aplicado, §6.** Teste delimitado ao contrato; o estrutural sai. |
| P10 | ajuste | **Aplicado, §0.** 106/80/26/88 corrigidos; `rowsSynced` "só impresso", não "inexistente". |
| P11 | ajuste | **Aplicado e agido.** Origem restaurada em 14/09 (`seed-data FORCE=1`, conferida contra `raw`); "149 passed" retirado como medição; guarda de banco isolado no Makefile é o **primeiro** commit. |
| P12 | bloqueante | **Devolvido ao Owner e decidido:** PK declarada no SQLAlchemy por tabela; chave nula = `sem identidade`. ADR-0044. |
| P13 | bloqueante | **Devolvido ao Owner e decidido:** o ADR-0042 vale; a fato segue a captura; marca só nas dimensões. R25 continua fechado. |
| P14 | bloqueante | **Devolvido ao Owner e decidido:** `hard_deletes: new_record` nos *snapshots*; persistência por construção; reaparecimento e terceira captura na sequência de prova. |
| P15 | bloqueante | **Devolvido ao Owner e decidido:** `governance.legacy_captures`, pelo ADR-0023, com nota datada declarando a leitura pelo fluxo; DDL versionado em `governance.py`; se o armazém deve entrar no Alembic fica para o parecer/Etapa 11. `raw_legacy._capturas` descartado. |
| P16 | bloqueante | **Devolvido ao Owner e decidido:** componente toda `rejected`, raiz conserva `own_invalid`. Compatível com o SQL atual; sem ADR. |
| P17 | ajuste | **Aplicado, §§2, 7.** Correção exige regerar, v8, *build*; D34 medida de propósito com mesmo rótulo e tratamento alterado. |
| P18 | ajuste | **Aplicado, §§2, 5.** Manifesto por lote com hash, preservado; captura conferida contra ele; remoção grava o `RETURNING` e confirma pós-*commit*. |
| P19 | bloqueante | **Aplicado, §9.** Cenário `batch` = bancos + Airbyte + Airflow; 4,95 GiB; bloco só com a máquina liberada pelo Owner e `preflight`; nunca `FORCE=1`. |
| P20 | bloqueante | **Aplicado, §§3, 7.** Nenhum volume apagado; migração provada em banco isolado. |
| P21 | ajuste | **Aplicado, §§4, 5, 7.** `dbt build --select legacy_selected_capture+` após cada captura; contraprova incompleta por *stream* desabilitado, não por renomear/pausar; restauração antes de *build* positivo. |
| P22 | ajuste | **Aplicado, §§5, 8.** Unit tests e colunas novas nos **geradores**; dicionário, paridade e índice de ADR listados; critério "passa **ou** corrigiu" retirado. |
| P23 | observação | **Aplicado, §§7, 10.** Lista de `REVISAO.md:835–849` marcada item a item; número efetivo de commits vai ao dossiê. |
