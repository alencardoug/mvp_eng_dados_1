# Plano — fechar os achados abertos da Etapa 10

> **Transitório.** Não é documentação do projeto e não entra no mapa do README. Sai no *commit*
> que entrega o último item. Escrito em 14/09/2026 sobre `a66f869`
> (`feat/troca-entre-ambientes-pesados`), para ser **revisado antes de qualquer código**.
>
> Regime de leitura: o que está marcado **[medido]** tem saída de comando por trás; o que está
> marcado **[planejado]** é intenção. Os dois não se misturam (P5).
>
> **Revisão 4 — 14/09/2026.** Reescrito depois do segundo parecer (§15). A mudança central é uma
> decisão do Owner: **a marca `is_deleted` nas dimensões sai** (D39-c″) — sob os ADRs 0038 e 0042 a
> remoção física já cascateia para fora das fatos, e a memória do removido é o bruto retido; a
> detecção passa a ser derivada **só de `raw_legacy`**, persistente por construção. Com isso caem
> P14 e P24–P27 de uma vez. A certificação da captura (R09) e a remoção física (R10) viram **dois
> ADRs, 0044 e 0045**, ambos antes do código respectivo. §§13–15 preservados; §16 dá a situação de
> cada achado remanescente. Revisões anteriores: `f51fc2a`, `819b88f`, `186d8d7`.

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

Já fechado e **fora deste plano**: R25 (ADR-0042, confirmado por P13) e a quarta revisão
(`2fb6f55`). Também fora: **D36** e a Etapa 11.

**[medido]** em 14/09/2026 (reproduzido pelo revisor, §13.2 e §15.2): armazém com captura **16**,
tratamento **v7**, **16/16** views, fato **16.453** (15.900 `retail` + 553 `legacy`); `raw_legacy`
retém as gerações 1–16; a geração **15 tem 39 tabelas** (`brands` ausente) e o *job* 25 dela
terminou `succeeded` com `rowsSynced` = 12.746 = total da geração; em todas as linhas das gerações
15 e 16, `_airbyte_meta->>'sync_id'` é igual ao `jobId` (25, 26). Manifesto: 106 achados, **80 de
valor** no recorte do teste, 26 de contexto, 88 ocorrências. `legacy_classifications`: 10.441
`accepted`, 26 `corrected`, 67 `own_invalid`, 3 `duplicate_excess`, 2.210 `parent_rejected`.
`dim_customer` já tem **1 marca legada e 6 `retail`** de exclusão lógica (ADR-0029) — a linha de
base de qualquer prova não é "marcas zero". Os quatro *snapshots* não têm `dbt_is_deleted`.

**[planejado]**, e dito como tal (P28): que a geração 15 seja **recusada** pelo novo
`legacy_captura_completa` é expectativa deste plano; o que está medido é só que ela tem 39 tabelas
e que `governance.legacy_captures` ainda não existe. O comando e a falha observada entram no
dossiê depois de implementado.

**Origem principal:** `make test CARGA=1` a substituiu pela carga reduzida em 08/09 e 14/09;
restaurada em 14/09 (`seed-data FORCE=1`, 252.955 linhas, conferida contra o `raw` e reproduzida
pelo revisor em VF02). Nenhum "N passed" da suíte com `CARGA=1` vale como medição da base.

---

## 1. Ordem, e por quê

```
R13 ──┐
      ├──► ADR-0044 ──► R09 ──► ADR-0045 ──► R10 ──► validação ──► R14 ("aguardando revisão")
R12 ──┘
R26 (nota de referência; entra no commit do R14)
```

1. **R13 primeiro** — código local; o oráculo do lote e o diário de mutações são reutilizados por
   R10. Os testes do gerador rodam sem banco; a integração roda contra a captura 16 amarrada por
   **hash de conteúdo** (§2), sem regerar a origem.
2. **R12 em paralelo lógico**, em banco isolado.
3. **ADR-0044 antes do R09** (P15): a exceção ao ADR-0023 precede o código que a exerce.
4. **ADR-0045 antes do R10**.
5. **Validação** no cenário `batch`, com a máquina liberada.
6. **R14 por último**: "implementado e medido, **aguardando revisão**"; nunca "aceita" (P08).

---

## 2. R13 — o esperado independente por ocorrência

### O que existe hoje **[medido]**

Manifesto com `achados` (106; 80 de valor no recorte `DE_CONTEXTO`) e `ocorrencias` (88);
nenhum teste compara `trusted.legacy_classifications` com esperado por ocorrência; cascata sem
oráculo; `product_variants` #27 `color`: `Vermelho` → `'NULL'` → nulo, `corrected` — correto pelo
ADR-0040, e o esperado **não** é o original. `legacy_row_id` é renumerado de 1 a cada geração
(`injetor.py:98–113`): contagem e conjunto de identidades **não** identificam conteúdo (P18).

### O que muda **[planejado]**

**Declaração (revisão integral):**

1. **`catalogo.yml`** — cada falha declara `recuperacao: original | canonico` (e o alvo canônico).
   É o contrato de recuperação, dito uma vez; o oráculo tira dele o `valor_esperado`. Revisão
   integral desta tabela pelo Owner.
2. **`injetor.py`** — `Resultado.esperado_por_ocorrencia()`: para **toda** ocorrência, o
   multiconjunto de achados esperados `(codigo, coluna, vinculo_causal)`, `classification`,
   `rejection_origin`, `valor_esperado`. Calculado das mutações aplicadas, do conjunto íntegro
   anterior e do grafo declarativo (`Base.metadata` + regras do catálogo), **sem importar nada
   de `classification.py`, `dbt.py` ou `ponte.py`**.
3. **Semântica da cascata — decidida pelo Owner em 14/09/2026:** excedente de `DUP_EXACT` com
   canônica apta não cascateia · `DUP_PARTIAL` cascateia · pai com chave nula dá `FK_ORPHAN`
   (`own_invalid`) · ciclo com raiz rejeitada: tudo `rejected`, **raiz conserva a causa própria**.
   Compatível com ADR-0038/0040 (§13.3, §15.3); nota de referência nos donos, sem ADR.
4. **Lote identificado por conteúdo (P18):** o manifesto grava, por tabela, `hash_conteudo` =
   `md5` do texto canônico de cada linha (todas as colunas do legado, que são `text`, na ordem
   declarada, com a normalização de transporte declarada — `''` → nulo, que é o que o Airbyte
   faz) agregado em ordem de `legacy_row_id`, mais `linhas`; e os **parâmetros efetivos**
   (`semente, fator, versao_catalogo, as_of`). Arquivo `manifesto-<hash_global>.json`; o mais
   recente por *symlink*; nenhum é apagado. A mesma função de hash é usada pelo R09 sobre a origem
   e sobre o `raw`, então a cadeia **manifesto ↔ `legacy_db` ↔ geração** é conferível de ponta a
   ponta por igualdade de hash.
5. **CLI `manifesto`** (novo): recalcula o manifesto da geração determinística **sem tocar no
   banco** — é o que permite trocar o formato do manifesto e amarrá-lo à captura 16 já retida sem
   `seed-legacy` nem sincronização (P21). O teste de integração confere primeiro que o hash por
   tabela da geração 16 em `raw_legacy` é igual ao do manifesto; só então compara vereditos.
6. **Diário de mutações**: o manifesto ganha `mutacoes: []` — cada `remover`/`inserir`/`alterar`
   do CLI (§5) registra o que o banco devolveu (`RETURNING`), confirmação pós-*commit*, e o hash
   por tabela **antes e depois**. É dele que saem os esperados de A→B→…→F.

**Derivado (amostragem):**

7. Três testes sobre `legacy_classifications` (veredito + multiconjunto de achados; cascata aponta
   ao pai certo; recuperação tipada, inclusive em rejeitadas), uma consulta por tabela.
8. **Contraprovas por mutação:** (a) defeito deliberado no oráculo → os testes falham; (b) defeito
   deliberado no SQL compilado → falham; (c) **lote com as mesmas identidades e os mesmos achados,
   mas conteúdo diferente** (alterar um valor que não é achado) → o hash de conteúdo diverge e o
   teste recusa comparar (P18/15.4).
9. `DE_CONTEXTO` sai. SQL divergente do oráculo se corrige na mesma entrega, um `fix:` por defeito,
   com o ciclo inteiro: regerar modelos, `versao` v8, `dbt build`, comparar (P17). Contratos aceitos
   não se alteram para fazer teste passar.

### Prova

```
.venv/bin/python -m mvp_ed1.legacy.cli manifesto          # sem banco; hash por tabela
make test                                                 # gerador + oráculo + mutações (a)(b)(c)
# integração, contra a captura 16 já retida — nenhum seed, nenhuma sync:
MVP_TESTE_LEGADO=1 .venv/bin/pytest tests/test_legado_deteccao.py   # hash 16 == manifesto; vereditos
```

Se houver `fix:` no SQL: `make legacy-models && make dbt-build DBT_ARGS='--select legacy_selected_capture+'`
e a integração de novo, sobre v8.

### Critério de pronto

- [ ] Esperado por ocorrência (achados, veredito, valor) calculado sem ler o classificador.
- [ ] `recuperacao` declarada e revisada; manifesto identificado por conteúdo e parâmetros.
- [ ] Integração passa sobre a captura 16 amarrada por hash; as três mutações falham de propósito.

---

## 3. R12 — o schema legado no ciclo Alembic

Inalterado da revisão 3 (P05 respondido): segundo ambiente `db/migrations_legacy/` com seção
`[legacy]` (a `[alembic]` continua sendo a da origem principal); revisão inicial por
*autogenerate* em banco isolado vazio; **equivalência física tripla** (isolado migrado × isolado
por `schema.ddl()` × `legacy_db` atual, via `information_schema`: tabelas, colunas, tipos,
nulabilidade, *constraints*, ordem) **antes** de `alembic stamp head` no banco existente;
`criar_schema` deixa de emitir DDL; `make migrate-legacy*`; `tests/test_migracao_legado.py` com
`upgrade` → carga → `downgrade` → `upgrade` e a comparação tripla como teste. Aplica o
**ADR-0010** à segunda origem; nota datada em `origem_legada.md` §2. O armazém **não** é tocado.

---

## 4. R09 — a captura pertence à sincronização, e é íntegra por conteúdo

### O que existe hoje **[medido]**

`geracao_do_legado` lê o máximo depois; `rowsSynced` vai ao XCom e não certifica nada;
`sync_id = jobId` observado nas gerações 15 e 16; geração 15 `succeeded` com 39 tabelas.
**Contagem não certifica conteúdo** (P02, VF05): a origem pode trocar `{1,2}` por `{1,3}` e a
extração entregar `[1,1]` com as três contagens iguais.

### ADR-0044 — certificação da captura do legado (antes do código)

Decide e registra: (a) o registro por *stream* em **`governance.legacy_captures`**; (b) a **exceção
delimitada ao ADR-0023**: o fluxo lê **uma** tabela de controle, só para elegibilidade de captura
— auditoria e reconciliação continuam fora do fluxo, e a Etapa 11 não a duplica; (c) o vínculo por
linha `sync_id = job_id`, fixado por teste na versão instalada, com *retry* como premissa; (d)
integralidade **por conteúdo**; (e) criação e evolução por DDL versionado em `mvp_ed1/governance.py`
(o ADR-0010 não exige Alembic no armazém; se o Owner quiser estendê-lo, é decisão da Etapa 11);
(f) paridade: *dataset* `governance`, tabela `legacy_captures` escrita pelo **mesmo módulo** via
cliente BigQuery (`insert_rows_json`), evolução pelas mesmas funções de migração traduzidas, e
recuperação por reexecução do registro a partir do *job* e do bruto — o registro é **recalculável**
do bruto + origem, nunca fonte única.

### O que muda **[planejado]**

1. `airbyte.py::registrar_captura(job)` grava uma linha por `(job_id, source_table)`:
   `snapshot_id, source_rows_before, source_hash_before, source_rows_after, source_hash_after,
   received_rows, received_hash, sync_id_matches, status, captured_at`.
   - Hash canônico = a função do §2 item 4, **a mesma** sobre `legacy_db` e sobre `raw_legacy`
     (colunas de negócio, `''` → nulo declarado como normalização de transporte).
   - `status = complete` ⇔ para todas as 40 tabelas: `hash_before = hash_after` (origem estável
     durante o *job*), `received_hash = source_hash_after` e `received_rows = source_rows_after`
     (conteúdo e multiplicidade — perda compensada por duplicata e alteração sem mudança de
     contagem **falham** aqui), e `sync_id_matches`. Tabela 0/0 com hash vazio dos dois lados é
     completa (`VAZIAS_LEGITIMAS` vira medida).
   - `unstable` (origem mudou), `incomplete` (tabela ou conteúdo faltando), `inconsistent`
     (`sync_id` misturado) são os outros estados; nenhum é elegível.
2. DAG: `contar_e_hashear_origem` → `sincronizar` → `registrar_captura` → `geracao_do_legado`
   devolve o `snapshot_id` **do registro `complete`** ou falha.
3. `legacy_captura_completa` (gerado em `legacy/dbt.py`) passa a exigir `status = complete` no
   registro da captura selecionada e `received_rows` = contagem no bruto por tabela. Capturas
   1–16 não têm registro e **não são elegíveis** como anterior; expectativa: a 15 falha pelo
   registro ausente e por `brands` (P28 — a medir).
4. `make sync-legacy` chama a mesma função.

### Prova (Airbyte de pé)

```
make sync-legacy      # captura A: 40 linhas complete em legacy_captures; hashes iguais; sync_id = job
make dbt-build DBT_ARGS='--select legacy_selected_capture+'
```

**Contraprovas:** (a) `legacy_snapshot_id=15` → falha (registro ausente; `brands`); (b) *stream*
desabilitado pela API → captura `incomplete` (estado `succeeded` no Airbyte) → recusada; reabilitar
e sincronizar antes de qualquer *build* positivo; (c) **conteúdo alterado sem mudar contagem** na
origem durante a janela (`UPDATE` entre o hash "antes" e o fim do *job*, forçado no teste) →
`unstable`; (d) duplicata compensando perda, simulada no teste unitário da função de certificação
com bruto fictício → `incomplete`. (c) e (d) são o que o P02 pede.

---

## 5. R10 — exclusão física entre capturas certificadas

### O que existe hoje **[medido]**

`raw_legacy` retém tudo; nenhum modelo compara capturas; `inventory_movements` tem PK
`movement_id`; o contrato de estoque referencia SKU/armazém, **não cliente** — apagar clientes não
apaga movimentos (P21). `dim_customer` já carrega 7 marcas de exclusão **lógica** (ADR-0029).

### D39 — decidida pelo Owner em três rodadas (14/09/2026)

| # | Decisão |
|---|---|
| D39-a′ | Remoção é **ausência física no bruto**, pela **PK declarada por tabela** (`Base.metadata`), com a chave canonizada por `identidade_canonica` (`08` = `8`; P12). Chave nula ou não conversível → **`sem identidade`**: não entra na comparação, é contada à parte e **não é relabelada** — o achado próprio (`NULL_REQUIRED` ou o de conversão que couber) continua sendo o do catálogo. A equação física conta **linhas físicas com multiplicidade**; chaves distintas são medida separada. Transições disjuntas por tabela: `removida`, `adicionada`, `mantida` |
| D39-b | "Anterior certificada" = capturas com `status = complete` em `legacy_captures` e `snapshot_id < selecionada`. Sem registro → não elegível; a primeira comparação é entre duas capturas novas |
| D39-c″ | **Sem marca dimensional.** Sob os ADRs 0038 e 0042 a remoção física cascateia para fora de todas as fatos (pedidos do cliente removido viram `FK_ORPHAN`, itens `parent_rejected`, ramo legado da fato reconstruído da captura) — nenhuma fato fica órfã, então a marca não protegeria integridade, só memória, e a memória é o bruto retido (ADR-0037). ADR-0017 e ADR-0029 **ficam intactos**; nenhum *snapshot* muda. A quarentena explica a cascata; `legacy_removed_records` explica a raiz |

**Persistência por construção (P14):** `legacy_removed_records` compara a selecionada com **todas**
as capturas certificadas anteriores: uma chave que apareceu em qualquer uma delas e está ausente na
selecionada está removida, com `last_seen_snapshot_id` (máximo onde esteve) e
`removed_in_snapshot_id` (mínima certificada posterior onde faltou). Em C ela continua listada com
os mesmos valores; em D (reaparecimento) sai da lista, e a transição `reapareceu` é derivável da
mesma consulta. Reprocessar uma captura antiga X compara só com certificadas `< X` — consistente.
Nenhum estado além do bruto e do registro de captura.

### ADR-0045 — exclusão física do legado (antes do código)

Registra D39-a′/b/c″, a chave por tabela e sua canonização, o universo (presença física; aptidão é
outra pergunta e fica no histórico SCD que já existe), a relação com 0015/0037/0038/0042 (nenhum
substituído; 0042 confirmado), o custo (varredura das capturas certificadas por tabela — medido
aqui, e no BigQuery partições por `snapshot_at`) e a paridade.

### O que muda **[planejado]**

1. `cli.py`: `remover --tabela T --chaves …|--quantidade N`, `inserir`, `alterar` — todos gravam no
   diário do manifesto o `RETURNING`, a confirmação pós-*commit* e os hashes antes/depois (P18).
2. `trusted/legacy/legacy_removed_records.sql` (`table`): removidas, adicionadas, reaparecidas, e
   `sem_identidade` por tabela e captura, com `last_payload` **bruto** (dito no dicionário).
3. `dbt/tests/legado_presenca_fisica_reconcilia.sql`: `presentes(anterior_certificada_mais_recente)
   − removidas + adicionadas = presentes(selecionada)` por tabela, em linhas físicas; e
   `sem_identidade` reportado, nunca somado em silêncio.
4. **Unit tests dbt** declarados em `classification.py` (gera o YAML): duas certificadas com
   remoção; anterior `incomplete` ignorada; reaparecimento; chave `08`/`8`.
5. `tests/test_legado_remocao.py` (integração, leitura): `legacy_removed_records` × diário.

### Prova (Airbyte de pé; máquina liberada)

Esperados de cada passo saem do **diário**, por tabela; cada captura conferida (`complete`, `snapshot_id`)
antes do *build* seguinte (P21):

| Passo | O que prova |
|---|---|
| **A** certificada → *build* | linha de base; `removidas = 0` (não há anterior certificada) |
| `remover customers 5` + `remover inventory_movements 3` (por `movement_id`) + `alterar` 1 cliente para inválido (rejeição **sem** apagar) + `inserir` 1 → **B** → *build* incremental | `removidas` = 5 + 3 iguais ao diário; fato perdeu **os 3 movimentos** (ADR-0042) e os itens dos pedidos dos 5 clientes por cascata (quarentena explica); `perdeu_aptidao` visível na reconciliação de aptos, não em `removidas`; `adicionadas = 1` |
| **C** sem mudança → *build* | as 8 continuam listadas com os mesmos `last_seen`/`removed_in` (P14) |
| reinserir 1 cliente → **D** | `reapareceu = 1`; sai de `removidas` |
| `remover` a última linha de uma tabela pequena → **E** | 0/0 é `complete`; a remoção é remoção |
| *stream* desabilitado → **F** `incomplete` | `legacy_captura_completa` falha; F não entra como anterior; reabilitar antes de seguir |

---

## 6. R26 — o contrato de `event_sequence` no legado

Inalterado (P09 respondido): D40 — desempate técnico dentro da captura; nota de referência no
ADR-0039; comentário em `ponte.py`, dicionário; teste delimitado (único por `(snapshot_id,
source_table)` e igual a `legacy_row_id` nas linhas legadas).

---

## 7. Validação

| Item de `REVISAO.md:835–849` | Situação |
|---|---|
| Build integral, 16 views, reconciliação | **Aqui**, `make dbt-build` completo após R13 |
| DAG do zero, vínculo *job*–captura | **Aqui, ao vivo**, cenário `batch` |
| Carga incompleta; duas capturas com exclusão física | **Aqui** (§4 contraprovas, §5 A–F) |
| Reprocessamento da fato incremental | Coberto em 08/09; o passo B o exercita com remoção real por `movement_id` |
| Ciclo D34 | **Aqui**: mesmo rótulo v7 com tratamento alterado → recusa; v8 → sucesso; reversão identificada |
| Oráculo da cascata e valores; *recall*/precisão | **Aqui** (§2) |
| Troca real de ambientes, concorrência, restauração | **Pendente** — fora desta rodada |
| Chart/OOM do Airbyte; streaming ao vivo; paridade GCP | **Pendente** / não medível localmente |
| Migrações do zero | **Aqui**, isolado (§3); nenhum volume apagado |

Ordem de integração (P21): testes locais do gerador primeiro (sem banco); R13 integração contra a
captura 16 por hash; **depois** do R09, toda captura nova é seguida de
`dbt build --select legacy_selected_capture+` antes de qualquer teste.

---

## 8. R14 — coerência documental, com o estado medido

Como na revisão 3: Pendências (D39, D40 decididas; "aguardando revisão"), Plano §Etapa 10 (✓ só
com medição, captura e versão citadas; etapa **continua reaberta**), Origem Legada (§3.2 manifesto
por conteúdo, §4.1 D40, §4.2 certificação, §5 cascata, §6 remoção), geradores e não derivados
(`classification.py`, dicionário), `arquitetura.md` §5 (linha de `governance.legacy_captures`),
`docs/adr/README.md` (0044, 0045, notas), README status. `REVISAO.md` e este plano saem no
*commit* de entrega, com pareceres e situações já no histórico.

---

## 9. Ambiente e memória

- R13, R12, R26, R14: só os três bancos.
- R09, R10, DAG: cenário `batch` (bancos + Airbyte + Airflow; `airflow-up` não pausa o Airbyte);
  pico aceito do Airbyte 4,95 GiB; pico conjunto **não medido**; só com a máquina liberada pelo
  Owner e `make preflight ALVO=airbyte` antes; recusa é parada.
- **Testes que escrevem, dois interruptores separados (P11):** `make test CARGA=1` → cria banco
  efêmero `CARGA_DB`, aponta `SOURCE_DB_*` para ele, roda `test_carga.py`, derruba; recusa se
  `CARGA_DB = SOURCE_DB_NAME`. `make test FATO=1` → só `test_fato_incremental.py`, que escreve no
  armazém de trabalho **por desenho** (repara por SQL e confere; herda o ambiente para o `dbt run`) —
  autorização separada, dita no alvo. A flag única `MVP_TESTE_CARGA` deixa de ativar os dois.
- Nenhuma reconstrução seletiva sem `+`.

---

## 10. Commits previstos (número efetivo vai ao dossiê)

1. `fix: separa os interruptores dos testes que escrevem e isola o teste de carga` (P11)
2. `feat: declara a recuperação esperada por falha no catálogo do legado` (R13)
3. `feat: identifica o manifesto por conteúdo e calcula o esperado de toda ocorrência` (R13)
4. `test: confere veredito, cascata e recuperação contra o oráculo, com mutações` (R13)
5. `fix: …` por divergência (v8)
6. `feat: leva o schema legado para o ciclo Alembic` (R12)
7. `docs: registra ADR-0044 — certificação da captura do legado` (antes do R09)
8. `feat: certifica cada captura do legado por stream, conteúdo e job` (R09)
9. `docs: registra ADR-0045 — exclusão física do legado detectada no bruto retido` (antes do R10)
10. `feat: detecta exclusão física entre capturas certificadas do legado` (R10)
11. `docs: registra o contrato de event_sequence no legado` (R26)
12. `docs: atualiza o estado da Etapa 10 com as medições — aguardando revisão` (R14)

---

## 11. O que este plano **não** decide

D36; descarte de capturas antigas; `jit` nas origens; agendamento da Etapa 12; Alembic no armazém
(Etapa 11); aceite da Etapa 10.

## 12. Decisões do Owner — 14/09/2026, três rodadas

| Decisão | Resposta | Onde fica |
|---|---|---|
| D39-a′ identidade e detecção | PK declarada, canonizada; remoção = ausência física; `sem identidade` contada, não relabelada | ADR-0045 |
| D39-b anterior certificada | `status = complete` em `legacy_captures`; sem registro, não elegível | ADR-0045 |
| D39-c″ destino do removido | **Sem marca dimensional**; fato segue 0042; cascata 0038; memória = bruto retido; 0017 e 0029 intactos | ADR-0045 |
| D40 `event_sequence` | Desempate técnico dentro da captura | Nota no ADR-0039 |
| Certificação da captura (R09) | `governance.legacy_captures`, por *stream*, por **conteúdo**; exceção delimitada ao 0023 | **ADR-0044** |
| Cascata (R13) | Quatro casos; raiz conserva a causa própria | `origem_legada.md` §5 + notas |
| SQL divergente | Corrigir na mesma entrega, com v8 | Dossiê |
| Origem reduzida pelo teste | Restaurada; interruptores separados | §0, §9 |

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

---

## 15. Parecer final do revisor — 14/09/2026

**A revisão 3 ainda não está pronta para execução integral: restam seis bloqueantes e seis
ajustes.** Este parecer avalia o plano em `186d8d7`, depois da atualização do Claude Code;
não é revisão de uma implementação nova. A restauração da origem principal foi reproduzida.
As decisões do Owner são tratadas como tomadas; as devoluções abaixo apontam consequências e
contradições que o registro dessas decisões ainda precisa resolver.

As seções anteriores, inclusive o parecer da §13 e a resposta do executor na §14, foram
preservadas. “Aplicado” na §14 não equivale ao aceite do revisor. No nível do **plano**, considero
respondidos P03, P05–P10, P13, P16, P17, P19, P20, P22 e P23. P01 avançou para vínculo por linha
na versão instalada, com a limitação de retry expressamente pendente; P04 foi respondido para a
**detecção física**, que deixou de depender da classificação anterior. A cobertura da aptidão
histórica ainda depende do universo discutido em P26. Permanecem P02, P11, P12, P14, P15, P18
e P21, nos recortes precisados abaixo. P24–P28 são achados desta rodada.

### 15.1. Fidelidade aos seis achados

| Achado original | Avaliação da revisão 3 |
|---|---|
| R09 — `REVISAO.md:823` | A §4 agora trata vínculo por linha, registro por stream e vazio legítimo. Isso responde melhor ao pedido. A integralidade continua reduzida a cardinalidade: perdas compensadas por duplicatas e alterações sem mudança de contagem passam na regra proposta (P02). A localização do controle foi decidida, mas a exceção à fronteira de `governance` ainda exige registro adequado (P15). |
| R10 — `REVISAO.md:824` | A §5 corrigiu o objeto da comparação: presença física pela PK declarada, independentemente da aptidão, entre duas capturas novas certificadas. A detecção atende ao objeto do achado; a propagação proposta ainda contradiz a própria prova de C e contratos dimensionais aceitos (P14, P24–P27). O cenário com clientes também não prova a remoção de movimentos que anuncia (P21). |
| R12 — `REVISAO.md:825` | A §3 responde ao pedido: migração do zero, evolução/reversão, equivalência física tripla e adoção do banco existente somente depois da conferência, preservando `[alembic]`. P05 está respondido no planejamento. Nenhuma dessas migrações foi executada nesta revisão. |
| R13 — `REVISAO.md:826,843–844` | A §2 passou a exigir multiconjunto de achados, vínculos causais, recuperação por transformação e contraprova por mutação. P06/P07 estão respondidos no desenho. Falta ligar o esperado ao **conteúdo** efetivamente capturado (P18), e a sequência de prova ainda não sincroniza o lote regenerado (P21). |
| R14 — `REVISAO.md:827` | As §§7–8 distinguem estado medido, entrega, revisão e aceite; explicitam as validações deixadas para outra rodada. A atualização documental proposta atende ao achado, condicionada às medições futuras. A afirmação de execução já medida em §4 precisa ser corrigida (P28). |
| R26 — `REVISAO.md:830` | A §6 atende ao esclarecimento pedido e retirou o teste que proibia usos permitidos pelo Owner. O contrato limita o desempate à captura; não promete ordem do evento nem identidade entre recapturas. A nota de referência é adequada. |

### 15.2. Verificações executadas e saídas literais

Reli `CLAUDE.md` §§5–7 e o plano atualizado; confrontei o diff com o parecer anterior,
`REVISAO.md`, os ADRs, os declarativos, os modelos consumidores, os testes e a implementação
instalada do dbt. As consultas aos bancos usaram `default_transaction_read_only=on`,
`statement_timeout=20000` e `jit=off`, com credenciais carregadas do `.env` sem imprimi-las.
A conexão inicial foi bloqueada pelo sandbox e a mesma consulta foi repetida com a permissão
necessária para acessar os bancos locais.

Houve somente leitura, SELECTs e diagnósticos pequenos em memória. Não executei seed, migração,
suíte destrutiva, build dbt, sincronização, DAG ou alvo que ligue ambientes. A única alteração
documental desta rodada é este acréscimo.

**VF01 — revisão examinada e decisões vigentes.** `git rev-parse HEAD`,
`git diff --name-only e65efa5 HEAD` e busca em `docs/adr/`. A atualização entre os dois
commits mudou somente o plano, não código ou ADR aceito.

~~~text
186d8d7d6af1095c173e53b60b4b249c21c0b340
PLANO_fechamento_etapa_10.md
docs/adr/0037-reter-capturas-do-legado-por-acrescimo.md:40:| Snapshot pelo banco, fora do Airbyte | Controle total sobre o instante e a consistência entre tabelas | Acrescenta um componente ao fluxo, contra a regra 5 do [`CLAUDE.md`](../../CLAUDE.md), para resolver o que a ferramenta já resolve. E cria um segundo caminho de ingestão que o `streams.yml` não descreve — a declaração deixaria de ser única |
docs/adr/0029-exclusao-logica-como-marca-na-dimensao.md:59:2. `trusted` e as **dimensões preservam todos os membros**, excluídos inclusive, marcados com
docs/adr/0017-chaves-substitutas-e-scd.md:39:Cada fato carrega a chave substituta **vigente no instante do evento**, resolvida por *join*
docs/adr/0007-catalogo-como-codigo.md:23:| Contêiner de catálogo local (OpenMetadata, DataHub) | Interface rica desde o início | Contêiner pesado — agrava o risco **R11**; metadados fora do versionamento; sem contrapartida direta no fluxo de migração |
docs/adr/0023-escopo-do-schema-governance.md:55:  dbt; e o schema precisa ser mantido **fora** do fluxo de dados — nenhum modelo de `analytics` pode
~~~

**VF02 — restauração da origem e estrutura dos snapshots.** Contagem das 40 tabelas de
`oltp`; comparação com `raw` nas quatro tabelas citadas na §0; consulta ao catálogo de
colunas dos quatro snapshots. O MD5 foi calculado sobre os pares `id:updated_at`, ordenados
por `id::bigint`, separados por quebra de linha, com timestamp convertido para UTC e seis
casas fracionárias; nulo representado por `<null>`. A comparação reproduz o recorte anunciado,
não uma igualdade de todos os campos das 40 tabelas. A execução histórica de `seed-data`
não foi repetida.

~~~text
read_only: on on on
source: tables=40 rows=252955
customers: source=(1500, 'eac3def3b2db89d4b575fd5cd7ff2f87') raw=(1500, 'eac3def3b2db89d4b575fd5cd7ff2f87') equal=True
orders: source=(3500, 'c06c7a75587352a4b1d46782febde380') raw=(3500, 'c06c7a75587352a4b1d46782febde380') equal=True
order_items: source=(7500, 'aba15be3e89517cf20dff7bd35816405') raw=(7500, 'aba15be3e89517cf20dff7bd35816405') equal=True
products: source=(300, 'e10920a97044c7baa83d0a7248f3c38a') raw=(300, 'e10920a97044c7baa83d0a7248f3c38a') equal=True
snapshot columns:
('snapshots', 'scd_coupon', False, 27)
('snapshots', 'scd_customer', False, 32)
('snapshots', 'scd_product', False, 31)
('snapshots', 'scd_support_agent', False, 19)
warehouse capture: [(16,)]
legacy tables/version: 40 []
~~~

**VF03 — estado atual do armazém e das capturas.** Consultas de contagem/agrupamento nas
relações indicadas pela saída; contagem por geração nas 40 tabelas físicas de `raw_legacy`.
A consulta `dimension_deleted` leu `analytics.dim_customer`: as marcas lógicas já existem
antes do trabalho proposto. `snapshot_history` leu `snapshots.scd_product`; não há versões
encerradas nessa amostra atual, portanto a preservação de múltiplas versões ainda precisa
de um cenário dirigido.

~~~text
read_only: on
classifications: [(16, 7, 'accepted', None, 10441), (16, 7, 'corrected', None, 26), (16, 7, 'rejected', 'duplicate_excess', 3), (16, 7, 'rejected', 'own_invalid', 67), (16, 7, 'rejected', 'parent_rejected', 2210)]
facts: [('legacy', 553), ('retail', 15900)]
views: [(16,)]
dimension_deleted: [('legacy', 74, 1), ('retail', 1500, 6)]
customer_captures: [(1, 75, '9', '9'), (2, 75, '10', '10'), (3, 75, '11', '11'), (4, 75, '12', '12'), (5, 75, '13', '13'), (6, 75, '14', '14'), (7, 75, '15', '15'), (8, 75, '16', '16'), (9, 75, '17', '17'), (10, 75, '18', '18'), (11, 75, '21', '21'), (12, 75, '22', '22'), (13, 75, '23', '23'), (14, 75, '24', '24'), (15, 75, '25', '25'), (16, 75, '26', '26')]
snapshot_history: [('legacy', 25, 25, 0), ('retail', 600, 600, 0)]
dbt_governance_models: []
raw_generation: 15 tables= 39 rows= 12746 absent= ['brands']
raw_generation: 16 tables= 40 rows= 12747 absent= []
~~~

**VF04 — manifesto atual.** Leitura de `data/legacy/manifesto.json`, contagem dos arrays e
agrupamento de `achados[].codigo`. Confirma os números corrigidos na §0; o vínculo por lote
continua sendo trabalho planejado.

~~~text
manifest keys: ['achados', 'ocorrencias']
findings: 106 occurrences: 88
findings_by_code: {'BOOL_VARIANT': 5, 'DATE_FORMAT_KNOWN': 5, 'DATE_FUTURE': 3, 'DATE_IMPOSSIBLE': 4, 'DATE_TZ_MISSING': 5, 'DATE_UNPARSEABLE': 3, 'DUP_EXACT': 4, 'DUP_PARTIAL': 2, 'EMAIL_MALFORMED': 4, 'ENUM_UNKNOWN': 4, 'FK_ORPHAN': 5, 'MONEY_AMBIGUOUS': 3, 'MONEY_LOCALE': 6, 'MONEY_NEGATIVE': 3, 'NULL_DISGUISED': 7, 'NULL_REQUIRED': 12, 'NUM_AMBIGUOUS': 4, 'NUM_OUT_OF_RANGE': 4, 'NUM_TEXT_EQUIV': 5, 'TEXT_DELIMITER': 3, 'TEXT_ENCODING': 5, 'TEXT_TRUNCATED': 1, 'TEXT_WHITESPACE_CASE': 6, 'TOTAL_MISMATCH': 3}
~~~

**VF05 — contraprovas reduzidas, sem escrita no banco.** Executei a validação de estratégia do
`BaseAdapter` instalado com uma relação simulada que contém as três colunas SCD obrigatórias,
mas não `dbt_is_deleted` — ausência também observada nos quatro destinos reais em VF02.
A validação anterior da relação foi substituída por um stub; foi exercitada a guarda específica
de `new_record`, não um `dbt snapshot`.

Nos outros diagnósticos, traduzi literalmente as condições do plano para conjuntos/listas:
A contém a chave 1, B e C não a contêm; na prova de contagem, origem antes = {1,2}, depois =
{1,3}, recebido = [1,1], com metadados do job assumidos válidos; na prova do lote, duas linhas
têm o mesmo `legacy_row_id=1` e diferem apenas no nome, A/B. São contraprovas das regras
**propostas**, não alegações de execução de modelos ainda inexistentes. A PK e as FKs de
estoque foram lidas de `Base.metadata`.

~~~text
dbt-core=1.12.3
strategy_check_without_dbt_is_deleted: SnapshotTargetNotSnapshotTableError
Compilation Error
  Snapshot target is missing configured columns (missing "dbt_is_deleted"). See https://docs.getdbt.com/docs/build/snapshots#snapshot-meta-fields for more information.
inventory primary key: movement_id
inventory foreign keys: product_variants.id, warehouses.id
counterexample: keys(A)={1}; keys(B)=empty; keys(C)=empty
B: removed=[1], dbt_is_deleted=True, planned_is_deleted=True
C: removed=[], dbt_is_deleted=True, planned_is_deleted=False
counterexample counts: 2 2 2 complete_by_plan= True same_source_keys= False received_matches_after= False
counterexample lot: same_counts= True same_identity_hash= True same_payload_hash= False
~~~

A macro instalada chama essa guarda em `snapshot.sql:40`, antes da adição de colunas em
`:57–61`. A documentação oficial também exige migração explícita de snapshots existentes
ao habilitar `hard_deletes`; não há migração automática.
[Referência oficial do dbt](https://docs.getdbt.com/reference/resource-configs/hard-deletes).

**VF06 — escritas autorizadas pela flag de carga e contratos afetados.** Saída literal das
buscas por flag, conexão, DML, restrições dos ADRs, definição de `NULL_REQUIRED` e fontes
das dimensões sem snapshot:

~~~text
tests/test_fato_incremental.py:47:AUTORIZA_ESCRITA = "MVP_TESTE_CARGA"
tests/test_fato_incremental.py:56:    motor = create_engine(database_url(WAREHOUSE), poolclass=NullPool)
tests/test_fato_incremental.py:149:                    f"insert into {FATO} select {projecao} from {FATO} "
tests/test_fato_incremental.py:156:                    f"update {FATO} set quantity_delta = quantity_delta + 1000 "
tests/test_fato_incremental.py:216:                f"update {FATO} set quantity_delta = :v "
docs/adr/0029-exclusao-logica-como-marca-na-dimensao.md:59:2. `trusted` e as **dimensões preservam todos os membros**, excluídos inclusive, marcados com
docs/adr/0029-exclusao-logica-como-marca-na-dimensao.md:60:   `is_deleted`. Uma dimensão nunca perde linha por exclusão na origem.
docs/adr/0017-chaves-substitutas-e-scd.md:39:Cada fato carrega a chave substituta **vigente no instante do evento**, resolvida por *join*
docs/adr/0023-escopo-do-schema-governance.md:55:  dbt; e o schema precisa ser mantido **fora** do fluxo de dados — nenhum modelo de `analytics` pode
docs/adr/README.md:20:3. Um ADR aceito **nunca é apagado nem reescrito**. Se for revertido, passa a `Substituída` e o
docs/adr/README.md:22:4. Toda *mudança relevante*, no sentido do [Termo de Abertura](../../Abertura_de_projeto.md), exige
docs/adr/README.md:24:5. Todo ADR declara a sua **contrapartida na fase GCP**. Decisão sem equivalente na nuvem não é
src/mvp_ed1/legacy/catalogo.yml:327:  NULL_REQUIRED:
src/mvp_ed1/legacy/catalogo.yml:332:    deteccao: Campo obrigatório permanece nulo após a limpeza, inclusive nulo recebido sem marcador.
src/mvp_ed1/legacy/catalogo.yml:333:    rejeicao: Ausência de valor obrigatório; preencher exigiria inventar um valor de negócio.
dbt/models/analytics/dim_warehouse.sql:23:from {{ ref('warehouses') }} w
dbt/models/analytics/dim_carrier.sql:26:from {{ ref('carriers') }} c
dbt/models/analytics/dim_supplier.sql:25:from {{ ref('suppliers') }}
dbt/models/analytics/dim_sales_channel.sql:17:from {{ ref('sales_channels') }}
dbt/models/analytics/dim_payment_method.sql:18:from {{ ref('payment_methods') }}
dbt/models/analytics/dim_campaign.sql:23:from {{ ref('campaigns') }} c
~~~

Além desses trechos, conferi `dim_customer.sql:1–73`, `dim_product.sql:1–125`,
`product_skus.sql`, os quatro snapshots e `fact_inventory_movement.sql:136–148`.
Os dois primeiros documentam atributos de tipo 1 lidos do cadastro corrente e atributos de
tipo 2 vindos de **todas** as versões. A fato de estoque usa SKU/armazém e vigência temporal;
não referencia cliente.

**VF07 — memória e preservação do parecer anterior, antes da escrita.** Leitura de
`/proc/meminfo` e comparação binária com o Git. A memória disponível desta amostra é
aproximadamente 2,85 GiB; o valor histórico de 1,03 GiB continua corretamente identificado
como histórico na §9. Não foi medido pico do cenário batch.

~~~text
MemTotal:       12021776 kB
MemAvailable:    2987044 kB
SwapTotal:      16215540 kB
SwapFree:       13358796 kB
head_sha256: 51050660f9ddf7acfc8afc1f42215ce19f1c4f01e2dfbd7b08d9c363e120304a
working_copy_equals_HEAD: True
section_13_preserved_from_e65efa5: True
~~~

As medições numéricas corrigidas das §§0/2/3/5 foram reproduzidas no alcance acima ou já
têm as reproduções literais da §13, que não foram convertidas em novas execuções. O estado
`succeeded` dos jobs 25/26 e a correspondência de todas as linhas com seus `sync_id`
continuam sustentados pela consulta da rodada anterior (§13, V04), não por nova chamada à
API nesta rodada. A afirmação que não se reproduz como execução do procedimento novo está
individualizada em P28.

### 15.3. Consequências das decisões do Owner e forma de registro

| Decisão da §12 | Confronto com ADRs, consequência e registro |
|---|---|
| D39-a′ — PK declarada e ausência física | Compatível com a detecção por comparação de capturas dos ADRs 0015/0037. O novo ADR é adequado. A exclusão de chaves sem identidade está explícita, mas a tipagem/canonização e a equiparação de não conversível a `NULL_REQUIRED` ainda precisam do contrato indicado em P12, também para o BigQuery. |
| D39-b — anterior certificada | Compatível com ADR-0037. A decisão de não certificar retrospectivamente 1–16 resolve o bootstrap da detecção: a comparação começa com duas novas capturas. Cabe no ADR-0044. É preciso aplicar essa restrição também à ordem das provas, conforme P21. |
| D39-c′ — fato corrente e marcas dimensionais | A preservação do ADR-0042 responde a P13. Contudo, “última versão” conflita com ADR-0017; “`is_deleted` só com remoção física” conflita com a exclusão lógica do ADR-0029. A implementação nativa não resolve persistência da **causa física**, migração, atributos de tipo 1 ou dimensões sem snapshot. P14/P24–P27 voltam ao Owner como consequências da decisão. O ADR-0044 deve explicitar a interação e os limites; não pode declarar ausência de mudança nos ADRs enquanto prescreve comportamento contrário. |
| D40 — desempate dentro da captura | Não encontrei ADR aceito que atribua ordem observada ao campo legado. Nota datada de referência no ADR-0039, apontando para `origem_legada.md`, é suficiente se não reescrever a decisão histórica. |
| R09 — registro em `governance` | Guardar o log cabe no ADR-0023; usá-lo como entrada de elegibilidade contraria sua restrição de ficar fora do fluxo. A decisão do Owner autoriza a escolha, mas uma nota datada não substitui o ADR novo que registra essa exceção. P15. A contrapartida BigQuery precisa incluir a escrita/atualização do controle, não apenas o nome do dataset. |
| R13 — quatro casos de cascata | As respostas são compatíveis com ADR-0038/0040: existência de canônica apta evita a cascata; duplicata parcial rejeitada a provoca; referência à chave ausente é órfã; a raiz inválida conserva causa própria no ciclo. As notas de referência e o contrato no dono documental bastam. P16 está respondido. |
| SQL divergente do oráculo | A autorização para corrigir permanece válida. A §2 agora exige declaração de recuperação, revisão dessa declaração e ciclo de versão/build; a §7 descreve a recusa sob o mesmo rótulo. Não exige novo ADR para consertar defeito dentro dos contratos aceitos. Uma divergência não autoriza alterar um desses contratos para fazer o teste passar. |
| Restauração e isolamento dos testes | O estado anunciado foi confirmado em VF02. Registro de execução e guarda operacional são adequados; não é nova escolha de arquitetura. A guarda precisa cobrir todos os destinos de escrita ativados pela flag (P11). |

Pelo `docs/adr/README.md:20–25`, mudança relevante exige ADR e contrapartida GCP; um ADR
aceito não é reescrito. No caso de P15, o registro novo precisa preceder a implementação do
R09 afetada pela exceção, não apenas o R10. Não imponho Alembic ao warehouse: o ADR-0010
não o determina ali. DDL versionado com evolução testada pode ser avaliado como solução
técnica; a escolha de ampliar o escopo do Alembic continua sendo do Owner.

### 15.4. Oráculos, ambiente e escopo

A §2 melhorou a independência do esperado: catálogo e grafo são declarações compartilhadas,
e não há problema em ambos os caminhos lerem o mesmo contrato. A separação dos helpers,
o multiconjunto por ocorrência e as mutações deliberadas devem permanecer. O que ainda
é insuficiente é verificar o transporte por contagem, vincular lotes por identidades
renumeráveis e apresentar uma equação derivada das próprias diferenças de conjuntos
como prova de que os **conjuntos de entrada** estão corretos.

Há oráculos mais fortes viáveis nesta escala: manifesto imutável do conteúdo entregue,
conferido após a gravação na origem; comparação por stream das identidades físicas,
multiplicidades e payloads recebidos; diário das mutações efetivamente confirmadas,
incluindo inserção e alteração além do DELETE; e valores esperados de atributos/chaves
dimensionais antes e depois, calculados a partir desse diário. `DELETE RETURNING` com
confirmação posterior é uma melhora concreta, mas não certifica sozinho os sobreviventes
nem o lote após os outros tipos de mutação. Uma contraprova deve trocar conteúdo sem mudar
a contagem ou `legacy_row_id`, além das mutações de achados já planejadas.

A §9 corrigiu a descrição dos ambientes: Airbyte e Airflow integram a família batch, e
streaming é o conflitante. O pico de 4,95 GiB é o do ADR-0041; não é medição do pico conjunto
da DAG com as duas sincronizações e as ferramentas de trabalho. A condição de liberar
memória, conferir o preflight para o alvo concreto e parar diante de recusa deve ser
mantida. P19 está respondido como **condição de execução**, não como certificação de
capacidade. Nesta revisão nenhum ambiente foi ligado, pausado ou retomado.

A propagação dimensional, a migração necessária para `new_record` e a guarda dos testes
excedem a formulação mínima de R10/R12/R13, mas decorrem das decisões do Owner ou são
pré-requisitos das provas escolhidas; não são motivo para cortar o trabalho em silêncio.
A §7 agora declara corretamente o que deixa para outra rodada: troca real de ambientes,
chart/OOM, streaming e medição no GCP. Permanecem sem delimitação suficiente o universo
dimensional e o grão de `perdeu_aptidao` (P26). A revisão de código posterior deve cobrar
as provas de desenvolvimento e a definição de pronto, sem tratar este parecer como
encerramento da Etapa 10.

### 15.5. Achados remanescentes e novos

Os identificadores antigos são mantidos quando o problema permanece. Os novos começam em P24.
“Owner” identifica consequência contratual a devolver ao decisor, sem substituir a decisão
dele por uma escolha do revisor.

| # | Seção do plano | Achado | Veredito |
|---|---|---|---|
| P02 | §4, item 1, linhas 241–253 | **Contagem independente ainda não certifica conteúdo integral ou origem estável.** A origem pode trocar {1,2} por {1,3}, e a extração entregar [1,1], mantendo as três contagens iguais e o mesmo job em todas as linhas. VF05 mostra a regra aceitando esse caso. A geração 15 prova falta de stream inteiro, não esse defeito dentro de stream. Exigir equivalência verificável das ocorrências/conteúdo por tabela, preservando multiplicidade, ou condições de extração que sustentem essa garantia; incluir alteração sem mudança de contagem e perda compensada por duplicata nas contraprovas. O manifesto do produtor e uma conferência da origem são viáveis. R09 pede integralidade, `REVISAO.md:823`. | bloqueante |
| P11 | §9, linhas 440–443; §10, commit 1 | **Isolar somente `SOURCE_DB_NAME` não isola `make test CARGA=1`.** A mesma flag ativa `test_fato_incremental.py:47,56,149–168`, que conecta a `WAREHOUSE`, adultera a fato e chama `dbt run` com o ambiente herdado. VF06 confirma esses destinos. A restauração da origem está confirmada, mas não fecha a guarda planejada. Declarar isolamento também do warehouse e do subprocesso, com seus pré-requisitos, ou delimitar a seleção da suíte isolada e a autorização separada do teste da fato. Uma troca apenas de `CARGA_DB` não pode ser anunciada como proteção de todos os bancos de trabalho. | ajuste |
| P12 | §5/D39-a′, linha 312; §12 | **Owner — a PK foi corrigida, mas o domínio da identidade ainda mistura causas.** O catálogo atual define `NULL_REQUIRED` como valor nulo após limpeza (`catalogo.yml:332`, ADR-0040); uma chave textual não conversível não é automaticamente nula. Explicitar no ADR-0044 representação canônica por tipo, tratamento de não conversível e a classificação/contagem de `sem identidade`, sem relabelar silenciosamente o achado. Provar `08` versus `8`, UUID, alteração real de PK e múltiplas ocorrências com a mesma chave; a equação deve dizer se conta entidades distintas ou linhas físicas. Essa distinção também precisa sobreviver no BigQuery. | ajuste |
| P14 | §5/D39-c′, linhas 314, 335 e 354 | **Owner — a marca continua durando só uma comparação.** A versão nativa com `dbt_is_deleted=true` persiste, mas a regra adicional exige que a chave esteja nas remoções da comparação corrente. Em C contra B esse conjunto é vazio; VF05 produz `planned_is_deleted=False`. Usar apenas a marca nativa também não resolve, pois ela pode nascer de perda de aptidão. Definir persistência da causa física confirmada até reaparecimento, consulta desse estado e regra para reprocessamento de captura antiga. A prova C deve demonstrar a regra escolhida; hoje contradiz a implementação descrita. R10, `REVISAO.md:824`. | bloqueante |
| P15 | §4, linhas 235–261; §§10–12 | **Owner — nota datada não pode criar a exceção ao ADR-0023.** A proibição está em `0023:54–56`: governance fica fora do fluxo de dados. O plano torna o controle entrada do pipeline, inclusive da seleção usada por analytics. Registrar a exceção em ADR novo antes desse código, delimitando leitura de controle versus auditoria e sua relação com a Etapa 11. “Mesma tabela, escrita pelo mesmo Python” também não especifica como a atual conexão PostgreSQL escreve/atualiza BigQuery: declarar o caminho de escrita, evolução e recuperação do registro na nuvem. A escolha da localização já foi feita; o achado é seu contrato e registro, não uma sugestão de outra camada. | bloqueante |
| P18 | §2, item 4, linhas 120–124; §5, item 1 | **Hash de identidades não identifica o lote de conteúdo.** `injetor.py:98–113` renumera `legacy_row_id` a partir de 1; contagem e conjunto dessas identidades podem se repetir com valores diferentes. VF05 reproduz essa colisão de significado sem colisão criptográfica. Preservar arquivos e registrar o DELETE efetivo respondeu parte do achado. Falta vincular captura e manifesto ao payload canônico completo e aos parâmetros efetivos, e atualizar esse vínculo para as inserções/alterações da sequência B/D. Testar explicitamente um lote com mesmas identidades e achados finais, mas conteúdo diferente. R13, `REVISAO.md:826`. | ajuste |
| P21 | §1; §2/prova, linhas 152–154; §5/prova, linha 353 | **A sequência ainda não prepara os estados que anuncia provar.** `seed-legacy` grava na origem; o build seguinte lê o bruto da captura anterior, pois não há sync entre eles. Depois do R09, a captura 16 também será inelegível por falta de registro. Separar testes locais do gerador da integração, que exige sincronizar o novo manifesto e conferir a captura antes do build. Além disso, apagar clientes não apaga “os movimentos das 5”: o contrato de estoque só referencia SKU/armazém (VF05/VF06). Incluir DELETE real por `movement_id` para a prova incremental e manter a exclusão de clientes como prova dimensional/cascata, com esperados próprios por tabela. `REVISAO.md:839–844`. | ajuste |
| P24 | §5, configuração dos snapshots; §10 | **Falta migrar os quatro snapshots já existentes.** VF02 confirma ausência de `dbt_is_deleted` em todos; VF05 reproduz a recusa da implementação instalada ao ativar `new_record` sem essa coluna. A validação acontece antes da expansão automática de colunas. Incluir migração versionada, inicialização coerente da marca e prova sobre cópia isolada de histórico existente, preservando `dbt_scd_id`, vigências e chaves usadas pelas fatos. Validar também criação do zero e caminho equivalente no BigQuery. Apenas acrescentar a configuração abortará a primeira execução sobre o estado atual; reconstruir apagando snapshots eliminaria a história que a decisão quer preservar. | bloqueante |
| P25 | §5/D39-c′ e item 4; §12 | **Owner — “dimensões leem a última versão” suprime o contrato SCD vigente.** ADR-0017:31–40 exige chave por versão e join temporal, usado de fato por `fact_inventory_movement.sql:139–144`. Filtrar pela última versão remove versões necessárias às fatos históricas. Ler todos os atributos somente do snapshot também congela os de tipo 1 fora de `check_cols`; os comentários de `dim_customer` e `dim_product` explicam por que o modelo atual é misto. Preservar versões, vigências e chaves, mantendo os atributos correntes onde o membro existe e definindo o fallback apto para ausentes. Provar evento anterior à mudança, múltiplas versões e atualização apenas de atributo de tipo 1. Se o Owner quiser alterar esses contratos, o ADR-0044 deve emendar o ADR-0017 explicitamente. | bloqueante |
| P26 | §5/D39-c′; §5, itens 2–4; §14/P04 | **Owner — o universo dimensional e o grão da perda de aptidão não estão fechados.** A detecção cobre 40 tabelas, mas a retenção só atua nos quatro snapshots. Supplier, warehouse, carrier, payment method, sales channel e campaign continuam lendo apenas cadastros correntes (VF06). Tampouco uma PK removida de `products` é a chave do snapshot de SKU, que usa `product_variant_id`. Definir quais dimensões devem reter membros, como mapear tabela/PK para cada membro e em que universo se calcula `sumiu_do_snapshot − removidas`; os conjuntos não são intercambiáveis. Se houver exclusões dessa cobertura, registrá-las no ADR-0044 e no escopo, em vez de prometer genericamente “marca nas dimensões” ou aptidão anterior para todo o lote. | ajuste |
| P27 | §5/D39-c′; prova A/B/D; §12 | **Owner — a nova regra pode apagar a exclusão lógica já aceita.** “`is_deleted=true` só quando a chave está em `legacy_removed_records`” e reaparecimento sempre falso desconsideram `source_deleted_at` e as marcas já propagadas pelo ADR-0029. VF03 encontra 1 marca legada e 6 retail em `dim_customer` antes de qualquer DELETE; “marcas zero” em A não é o estado atual. Especificar a composição entre exclusão lógica e ausência física, preservando o contrato aceito nas duas origens. A prova deve comparar as novas marcas físicas com a linha de base e incluir reinserção de payload que continua logicamente excluído. A decisão pode acrescentar causa de exclusão; não pode zerar a anterior sem assumir essa mudança no ADR. | bloqueante |
| P28 | §4, item 3, linha 267 | **“A geração 15 falha aqui, medido” mistura dado observado com teste futuro.** Está reproduzido que 15 tem 39 tabelas e que `governance.legacy_captures` não existe no estado atual. Não existe ainda a versão proposta de `legacy_captura_completa` que lê o registro e compara origem/destino; sua execução não foi reproduzida. Trocar a afirmação por expectativa planejada, vinculando a evidência já medida ao fato exato que ela sustenta. Depois da implementação, colar o comando e a falha observada desse novo teste. | ajuste |

Nenhum desses achados foi implementado nesta revisão. A revisão do desenvolvimento e o aceite
da Etapa 10 permanecem posteriores às correções do plano e às provas executadas.

Conferência da alteração documental: `git diff --check` terminou com código 0 e sem saída.
A comparação binária confirmou que o arquivo de `HEAD` permanece prefixo intacto, e
`git status --short` mostrou somente o plano modificado. Saída literal da conferência:

~~~text
original_sha256: 51050660f9ddf7acfc8afc1f42215ce19f1c4f01e2dfbd7b08d9c363e120304a
prefix_preserved: True
section_15_count: 1
findings: 12
ajuste: 6
bloqueante: 6
unique_ids: True
section_15_line: 992
findings_line: 1241
 M PLANO_fechamento_etapa_10.md
~~~


---

## 16. Situação dos achados do segundo parecer — 14/09/2026

| # | Veredito | Situação |
|---|---|---|
| P02 | bloqueante | **Aplicado, §4.** Integralidade por **conteúdo**: hash canônico por tabela na origem (antes e depois do *job*) e no bruto, com multiplicidade; `complete` exige igualdade de hash e contagem; contraprovas (c) alteração sem mudar contagem → `unstable` e (d) duplicata compensando perda → `incomplete`. |
| P11 | ajuste | **Aplicado, §9.** Dois interruptores: `CARGA=1` isolado em banco efêmero; `FATO=1` separado, escrevendo no armazém por desenho e dito. |
| P12 | ajuste | **Aplicado, §5.** Canonização por `identidade_canonica`; não conversível = `sem identidade`, contada e não relabelada; equação em linhas físicas, chaves distintas à parte; `08`/`8` nos unit tests; no ADR-0045 com paridade. |
| P14 | bloqueante | **Resolvido pela decisão D39-c″ e pelo desenho:** detecção contra **todas** as capturas certificadas anteriores, derivada do bruto — persiste por construção em C, reaparece em D, sem estado nem marca. |
| P15 | bloqueante | **Devolvido ao Owner e decidido:** **ADR-0044** registra a exceção delimitada ao 0023 e precede o código do R09; caminho de escrita/evolução/recuperação no BigQuery declarado. |
| P18 | ajuste | **Aplicado, §2.** Manifesto identificado por hash de **conteúdo** e parâmetros efetivos; a mesma função amarra manifesto ↔ origem ↔ geração; diário de mutações com `RETURNING` e hashes antes/depois; contraprova (c) com mesmas identidades e conteúdo diferente. |
| P21 | ajuste | **Aplicado, §§2, 5, 7.** CLI `manifesto` sem banco amarra a captura 16 sem reseed; toda captura nova é seguida de *build* da seleção; prova incremental com `remover inventory_movements` por `movement_id`; clientes ficam como prova de cascata. |
| P24 | bloqueante | **Cai com D39-c″:** nenhum *snapshot* muda. |
| P25 | bloqueante | **Cai com D39-c″:** ADR-0017 intacto; dimensões não mudam. |
| P26 | ajuste | **Cai com D39-c″:** universo dimensional deixa de existir como pergunta; a aptidão histórica fica no SCD que já existe e não é promessa deste plano. |
| P27 | bloqueante | **Cai com D39-c″:** ADR-0029 intacto; linha de base das 7 marcas lógicas registrada na §0 e não tocada. |
| P28 | ajuste | **Aplicado, §0 e §4.** "A geração 15 falha aqui" virou expectativa marcada **[planejado]**; o medido é só 39 tabelas e ausência da tabela de controle. |

---

## 17. Reavaliação do revisor — 14/09/2026

**A revisão 4 ainda tem três bloqueantes e dois ajustes.** Avaliei o plano em `caae643`,
incluindo a nova decisão D39-c″. A retirada da marca dimensional é respeitada: não é necessário
implementar snapshots ou preservar membros dimensionais para responder ao R10 original.
P24–P27 perderam objeto neste escopo. A persistência da lista de ausentes em C, objeto de P14,
também está respondida pelo novo desenho; a equação que usa essa lista tem outro defeito,
registrado em P29.

P02, P11, P18 e P28 foram respondidos no nível do planejamento: conteúdo substitui contagem
isolada; as autorizações de escrita são separadas; o manifesto ganha vínculo por conteúdo;
e a recusa futura da geração 15 deixou de ser anunciada como medida. Isso não encerra os R
correspondentes antes da implementação e das provas. P12, P15 e P21 permanecem nos recortes
abaixo. P29/P30 são novos. Os pareceres anteriores e a resposta da §16 permanecem intactos.

### 17.1. Fidelidade aos achados e decisões do Owner

| Achado original | Resultado desta reavaliação |
|---|---|
| R09 — `REVISAO.md:823` | A §4 atende ao objeto de vincular job, conteúdo e cobertura por tabela; as novas contraprovas distinguem perda compensada por duplicata e alteração sem mudança de contagem. Falta resolver a recuperação do certificado sem inventar a medição anterior à sync (P15) e a idempotência do caminho BigQuery escolhido (P30). |
| R10 — `REVISAO.md:824` | A §5 passou a detectar ausências exclusivamente no bruto retido, conforme a decisão do Owner. A lista persistente responde à memória da exclusão. Contudo, não pode ser usada diretamente como o fluxo de remoções entre duas capturas consecutivas, nem a comparação de chaves fechar uma equação de linhas físicas com multiplicidade (P29). A identidade UUID também não é normalizada pela macro escolhida (P12). |
| R12 — `REVISAO.md:825` | A §3 preservou migração do zero, comparação física tripla e adoção verificada do banco existente. Continua adequado no nível do plano. A abreviação desta seção não autoriza omitir as provas nela enumeradas. |
| R13 — `REVISAO.md:826,843–844` | A §2 conserva esperado por ocorrência, multiconjunto, cascata, recuperação tipada e mutações que devem fazer o teste falhar. O hash por conteúdo é adequado para impedir comparação com lote diferente. Porém, o gerador atual produz justamente um lote diferente da captura 16, tornando inviável a sequência de integração anunciada sem um passo adicional (P21). |
| R14 — `REVISAO.md:827` | As §§7–8 continuam distinguindo implementado, medido, revisão e aceite, com pendências externas explícitas. Nada nesta reavaliação autoriza declarar a etapa aceita. |
| R26 — `REVISAO.md:830` | A §6 mantém o contrato delimitado e a nota de referência apropriada. Sem nova objeção. |

**Confronto das decisões da §12:** D39-a′ acerta ao separar `sem identidade` da classificação
de qualidade, mas ainda precisa do domínio por tipo de P12 e do grão de P29. D39-b mantém a
certificação como requisito e a exclusão de 1–16 como antecedentes; a lista persistente pode
consultar todos os antecedentes certificados, enquanto a reconciliação de transições precisa
nomear seu par de capturas. D39-c″ é compatível com conservar o ADR-0042 e com a memória no bruto
do ADR-0037. O ADR-0045 deve explicitar que trata de **hard delete legado**; a marca de exclusão
**lógica** do ADR-0029 e as vigências do ADR-0017 continuam com seus contratos atuais.
Não há motivo para reintroduzir a mudança dimensional retirada pelo Owner.

O **ADR-0044 antes do R09** é agora a forma correta de registrar a exceção ao ADR-0023.
O **ADR-0045 antes do R10** também é adequado. Não encontrei ADR aceito novo desde o parecer
anterior; os dois documentos ainda são entregas planejadas. A recuperação e a contrapartida
BigQuery precisam das decisões indicadas em P15/P30 dentro desse registro, sem trocar
silenciosamente de ferramenta ou de camada.

D40 e os quatro casos de cascata continuam compatíveis com ADR-0039 e ADR-0038/0040,
respectivamente; notas de referência bastam. A autorização para corrigir divergências de SQL
com ciclo de versão permanece válida. A restauração da origem e os interruptores separados
são registros de execução/controle operacional, sem novo conflito arquitetural identificado.
A implementação do teste de carga isolado deverá preparar o schema OLTP pelas migrações
existentes e provar que a suíte executou, sem usar skips como evidência de sucesso.

### 17.2. Verificações executadas — saídas literais

Reli `CLAUDE.md` e o plano, comparei `deb3c40..caae643`, revisei os contratos citados e os
pontos de código que sustentam as novas premissas. As verificações novas foram geração em
memória, consultas somente leitura a `legacy_db`/warehouse, aplicação da macro existente
a valores sintéticos e contraprovas de conjuntos. Não executei o CLI planejado, que ainda
não existe, nem seed, migração, build dbt, sync, DAG ou alvo de ambiente pesado.

**VR01 — revisão, memória e famílias do preflight.** Comandos: `git status --short --branch`,
`git rev-parse HEAD`, leitura de `/proc/meminfo` e busca das constantes em
`docker/preflight.sh`.

~~~text
## feat/troca-entre-ambientes-pesados...origin/feat/troca-entre-ambientes-pesados [ahead 14]
caae6434a0c3b18df2201c12cb5d94cdf9b9a61d
MemTotal:       12021776 kB
MemAvailable:    2561872 kB
SwapTotal:      16215540 kB
SwapFree:       13517964 kB
36:CUSTO_airbyte=5000
37:CUSTO_airflow=1400
49:  airbyte|airflow) FAMILIA="batch" ;;
~~~

**VR02 — conteúdo do gerador, origem e captura 16.** Executei `legacy.cli._gerar()` sem
chamar o writer. Li de cada tabela somente `legacy_row_id` e as colunas declaradas em
`schema.colunas(tabela)`, ordenadas por `legacy_row_id`; no bruto, filtrei geração 16.
Usei arrays JSON em UTF-8, sem espaços de serialização, uma linha por registro, e MD5 para
comparar as sequências. Fiz a comparação preservando o vazio e repetindo com a normalização
`'' → null` proposta no plano. A mesma serialização foi aplicada aos três lados.

O resultado confirma a normalização de transporte no lote observado: seis células vazias na
origem chegam nulas ao bruto, e **40/40 tabelas** coincidem depois dessa normalização.
Também demonstra que a regeneração atual não é a captura 16: apenas **27/40 tabelas**
coincidem. Isso verifica a premissa de bootstrap; não é execução da nova função de hash
ainda planejada.

~~~text
generated: version= 7 tables= 40 rows= 12747 findings= 105
serialization: JSON arrays of [legacy_row_id, declared business columns], UTF-8, no whitespace, one row per line, sorted by legacy_row_id
read_only: on on
source_raw_differences: support_agents count= 2 sample= [(2, 'first_name', "''", 'None'), (2, 'last_name', "''", 'None')]
source_raw_differences: products count= 2 sample= [(5, 'status', "''", 'None'), (5, 'launched_at', "''", 'None')]
source_raw_differences: stock_reservations count= 2 sample= [(80, 'warehouse_id', "''", 'None'), (80, 'product_variant_id', "''", 'None')]
matching_tables: {'generator_raw16_empty_as_null': 27, 'generator_raw16_exact': 26, 'generator_source_empty_as_null': 27, 'generator_source_exact': 27, 'source_raw16_empty_as_null': 40, 'source_raw16_exact': 37}
empty_strings: {'generator': 6, 'raw16': 0, 'source': 6}
warehouse_capture: [(16,)]
~~~

A geração usou o caminho atual de `src/mvp_ed1/legacy/cli.py:35–43`: configuração corrente,
semente/fator do catálogo e `as_of_date` da configuração. Uma segunda geração em memória
também produziu 105 achados; o manifesto salvo continua com 106. Não atribuo a divergência
a uma causa não demonstrada, nem substituo a medição histórica pelo resultado regenerado.
Para o plano, basta a consequência: a integração não pode assumir que o novo manifesto
reproduz o lote antigo.

**VR03 — identidade canônica e testemunhas da prova de estoque.** Renderizei a macro de
`dbt/macros/identidade_do_vinculo.sql` com Jinja e executei SELECTs sobre os dois pares de
valores abaixo, comparando com a igualdade dos tipos declarados. Consultei também as
classificações atuais de `inventory_movements` e a contagem na fato. As conexões de VR02/VR03
usaram `default_transaction_read_only=on`, `statement_timeout=20000` e `jit=off`; as
credenciais foram carregadas do `.env` sem impressão.

~~~text
read_only: on
canonical_key: integer '8' '8' macro_equal= True typed_equal= True
canonical_key: uuid 'ABCDEFAB-1234-5678-9ABC-DEF012345678' 'abcdefab-1234-5678-9abc-def012345678' macro_equal= False typed_equal= True
inventory_classifications: [('accepted', None, 551), ('corrected', None, 2), ('rejected', 'own_invalid', 3), ('rejected', 'parent_rejected', 136)]
current_inventory_rows: [('legacy', 553), ('retail', 15900)]
registry: None
~~~

A macro diz expressamente, em `:15–17`, que só age sobre inteiros por extenso e conserva
outros textos. O caso UUID não é hipótese sobre a ferramenta: a comparação acima foi
executada. Os 139 movimentos rejeitados mostram também por que apagar três linhas físicas
quaisquer não garante retirar três linhas previamente existentes na fato.

**VR04 — equação e recuperação, em memória.** Para a equação usei A={1,2}, B={2}, C={2},
D={1,2}, E={2}, todas consideradas certificadas. `cumulative_absent` segue a regra das
linhas 241–246; a equação segue as linhas 262–264. O segundo exemplo preserva a chave 7,
mas reduz sua multiplicidade de duas ocorrências para uma. São contraprovas das regras
propostas, não execução de SQL novo.

~~~text
B: previous_rows=2 current_rows=1 cumulative_absent=[1] interval_removed=[1] interval_added=[] proposed_equation=1 matches=True
C: previous_rows=1 current_rows=1 cumulative_absent=[1] interval_removed=[] interval_added=[] proposed_equation=0 matches=False
D: previous_rows=1 current_rows=2 cumulative_absent=[] interval_removed=[] interval_added=[1] proposed_equation=2 matches=True
E: previous_rows=2 current_rows=1 cumulative_absent=[1] interval_removed=[1] interval_added=[] proposed_equation=1 matches=True
E re-deletion: last_seen=D removed_in=E
multiplicity counterexample: previous_rows= 2 current_rows= 1 business_keys_removed= [] equation_by_key= 2
registration_recovery: before_hash is not a function of current_source_and_raw
history_1: before=X, after=Y, raw=Y, source_now=Y -> unstable
history_2: before=Y, after=Y, raw=Y, source_now=Y -> complete
~~~

As duas histórias de recuperação no final têm **o mesmo bruto e a mesma origem atual**,
mas exigem certificados diferentes porque o hash anterior ao job era diferente.
Logo, esse hash não pode ser reconstruído apenas dos dois estados finais. Persistir a
medição anterior, ou conservar uma referência inequívoca a ela, resolve a perda de
informação; recalculá-la sobre a origem atual não resolve.

**VR05 — contrato da API escolhida para o GCP.** Consultei a documentação oficial:
`insert_rows_json` retorna erros por linha e usa IDs gerados por padrão; a deduplicação de
`insertAll` é de melhor esforço, não garantia de unicidade. A documentação também admite
inserção parcial mesmo com resposta HTTP de sucesso.
[Cliente Python BigQuery](https://docs.cloud.google.com/python/docs/reference/bigquery/latest/google.cloud.bigquery.client.Client#google_cloud_bigquery_client_Client_insert_rows_json),
[inserções e deduplicação](https://docs.cloud.google.com/bigquery/docs/write-api-rest#best_effort_de-duplication),
[respostas de sucesso com falhas por linha](https://docs.cloud.google.com/bigquery/docs/write-api-rest#success_http_response_codes).
Não foi executada escrita no GCP.

**VR06 — preservação dos pareceres e ausência de implementação nova.** Comparei os bytes
das §§13–15 com `deb3c40`, o arquivo de trabalho com `HEAD` e os caminhos alterados sob
`docs/adr/`. Antes deste acréscimo:

~~~text
original_sha256: e22cb8195fe58181ec83bf7e2aed5f027485d82ff0bcb2abefbc37edd3b94044
working_copy_equals_HEAD: True
sections_13_15_preserved: True
new_accepted_adrs_since_previous_review: []
~~~

Os números antigos que o plano cita como reproduzidos nas §§13/15 continuam sendo
evidência daquelas execuções. Nesta rodada não repeti, por exemplo, a contagem integral
da origem principal nem a consulta à API dos jobs 25/26. As novas premissas de transporte,
bootstrap, identidade e reconciliação foram verificadas acima. Não identifiquei nova
contagem marcada `[medido]` sem a reprodução já registrada; a premissa de regeneração que
não se reproduziu, embora esteja sob `[planejado]`, está explicitamente em P21.

### 17.3. Oráculos, ambiente e escopo

A equivalência por conteúdo fecha a lacuna de cardinalidade de P02 no desenho da certificação.
Compartilhar a serialização entre manifesto, origem e destino evita formatos incompatíveis;
não torna o SQL de classificação dono do esperado. A serialização deve ter vetores literais
para nulo/vazio, delimitadores, Unicode, identidades e multiplicidade, para que uma omissão na
função comum não seja validada pela própria função. A igualdade dos hashes nos dois extremos
atesta igualdade desses estados observados; não prova que nenhuma alteração transitória
aconteceu durante todo o intervalo.

A lista cumulativa de ausentes pode ser derivada do bruto. A prova independente deve vir do
diário de ações confirmadas e separar **ausentes no estado corrente**, **transições do par de
capturas** e **quantidades físicas**. Repetir a mesma diferença de conjuntos no teste e no
modelo não resolve P29. A contraprova sem mudança em C já está no plano e deve testar também
a equação, não apenas a permanência dos oito registros na lista.

A §9 continua respeitando o cenário batch e a recusa do preflight. A amostra de VR01 tinha
cerca de 2,44 GiB disponíveis; não é certificação do pico conjunto. O novo custo de varrer
todos os antecedentes certificados ainda não foi medido — a tabela de certificação nem
existe. A medição prevista no ADR-0045 deve vir da implementação, incluindo memória, antes
de anunciar cabimento. Não há motivo para subir streaming ou apagar volumes nesta rodada.

A retirada da marca dimensional reduz escopo por decisão expressa, sem abandonar a detecção
pedida em R10. As exclusões de D36, troca real de ambientes, chart/OOM, streaming e medição
no GCP estão declaradas. O trabalho adicional que falta é tornar executáveis o bootstrap
escolhido e a recuperação do controle, e fechar o grão da reconciliação; não reinstalar o
desenho dimensional descartado.

### 17.4. Achados remanescentes e novos

| # | Seção do plano | Achado | Veredito |
|---|---|---|---|
| P12 | §5/D39-a′, linha 237; §12 | **Owner — a macro escolhida não canoniza a PK de estoque pelo seu tipo.** `identidade_canonica` só normaliza inteiros. VR03 mostra dois textos do mesmo UUID com `macro_equal=False` e `typed_equal=True`; o plano pode anunciar remoção/adição por mudança apenas de representação de `movement_id`. A correção da classificação de `sem identidade` está respondida, mas o ADR-0045 ainda precisa declarar a canonização por tipo e os limites de conversão, inclusive a representação equivalente no BigQuery. Acrescentar casos de UUID e entrada não conversível, preservando os usos inteiros já existentes. | ajuste |
| P15 | §4/ADR-0044, linhas 182–185; §4, itens 1–2 | **Owner — o certificado não é recalculável apenas do bruto e da origem atual.** `source_hash_before` pertence ao instante anterior à sync. Depois de mutação na origem e falha na gravação do controle, os estados finais não determinam esse valor: VR04 dá duas histórias indistinguíveis na recuperação, uma `unstable` e outra `complete`. Registrar onde a medição anterior fica durável e ligada ao job nos dois caminhos, DAG e CLI; incluir recuperação após falha entre sync e registro. Se essa evidência não existir, recusar certificação retrospectiva e exigir nova captura, em vez de medir a origem de hoje como se fosse a de antes. O ADR novo resolveu a forma de registrar a exceção; falta esse contrato de recuperação. | bloqueante |
| P21 | §§1–2, linhas 67–69, 112–115 e 134–148; §5/B | **A integração prometida contra 16 não está viabilizada.** VR02 reproduz somente 27/40 tabelas entre geração atual e captura 16, mesmo com a normalização declarada; a geração tem 105 achados e o manifesto retido, 106. Não basta criar um comando que chama novamente o gerador. Prever identificação/reprodução do gerador e insumos históricos ou mudar a ordem para validar um lote novo, cujo manifesto completo nasce antes da carga e da sync; nunca derivar o esperado do SQL sob teste nem ignorar divergência do hash. No passo B, escolher também três movimentos aptos e já materializados, identificados pelo oráculo e conferidos antes da ação: dos 692 movimentos atuais, 139 já são rejeitados, de modo que três DELETEs arbitrários não provam a saída de três linhas da fato. `REVISAO.md:826,839–844`. | bloqueante |
| P29 | §5, linhas 237, 241–246 e 260–266 | **A lista de ausentes históricos não é o fluxo de remoções da equação.** Em A={1,2}, B=C={2}, C mantém a chave 1 na lista, mas a equação contra B dá `1−1+0=0` para uma linha presente (VR04). Há ainda conflito de grão: A=[7,7], B=[7] não perde chave, mas perde linha física. Separar estado cumulativo, transições entre a anterior mais recente e a selecionada, e variação de multiplicidade; dizer como cada um entra no modelo, no diário e na equação. Isso preserva a decisão de reter a memória da ausência. Incluir C sem mudança, redução de duplicata, reaparecimento seguido de nova exclusão e regra do `removed_in` posterior ao último `last_seen`. As três transições por chave da D39-a′ não fecham sozinhas a equação física anunciada. R10, `REVISAO.md:824`. | bloqueante |
| P30 | §4/ADR-0044, linhas 182–184 e 189–202; §12/R09 | **Owner — escolher `insert_rows_json` não garante um registro por job/stream após retry.** A API admite erros por linha e deduplicação de melhor esforço (VR05). O ADR-0044 precisa declarar idempotência e publicação do certificado somente após cobertura válida das 40 tabelas, incluindo o tratamento de duplicatas, respostas parciais e retorno perdido. Isso pode ser testado localmente com respostas simuladas da API; a medição ao vivo no GCP continua pendente. Não tratar simples reenvio do lote como equivalente a uma escrita única e concluída no PostgreSQL. | ajuste |

A revisão de desenvolvimento posterior deve verificar a implementação e as provas acordadas.
Nesta rodada foi acrescentado somente este parecer; nenhuma decisão foi implementada e
nenhum R foi encerrado.

Conferência documental: `git diff --check` terminou com código 0 e sem saída; somente o
plano aparece modificado. Saída literal da verificação de preservação e contagem:

~~~text
original_sha256: e22cb8195fe58181ec83bf7e2aed5f027485d82ff0bcb2abefbc37edd3b94044
prefix_preserved: True
section_17_count: 1
findings: 5
ajuste: 2
bloqueante: 3
unique_ids: True
section_17_line: 1189
table_line: 1393
 M PLANO_fechamento_etapa_10.md
~~~
