# ADR-0045 — Detectar a exclusão física do legado no bruto retido, sem marca dimensional

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 14/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D39 — levantada e decidida em 14/09/2026, em três rodadas, no plano de fechamento da Etapa 10 |
| Substitui / é substituída por | — ; cumpre o que o [ADR-0015](0015-sincronizacao-e-exclusoes.md) prometeu e o [ADR-0037](0037-reter-capturas-do-legado-por-acrescimo.md) tornou possível; **confirma** o [ADR-0042](0042-reconciliar-a-captura-legada-na-fato-incremental.md) |

## Contexto

O [ADR-0015](0015-sincronizacao-e-exclusoes.md) decidiu que o legado pratica *hard delete* e que "a
ausência é detectada por reconciliação contra o *snapshot* anterior". O
[ADR-0037](0037-reter-capturas-do-legado-por-acrescimo.md) tornou isso possível ao reter todas as
capturas em `raw_legacy`. Mas **nenhum modelo comparava capturas**: um registro apagado na origem
simplesmente não estava na captura seguinte, `trusted` nascia só da captura selecionada, e o
registro sumia do armazém sem rastro — o "descartado em silêncio" que a regra 4 do `CLAUDE.md`
proíbe. Era o achado **R10** da terceira revisão, e o critério de conclusão da Etapa 10 que dele
depende — "duas capturas completas distinguem remoção real de falha de ingestão" — não tinha prova
possível.

A decisão passou por três rodadas em 14/09/2026, e o registro do que foi **descartado** importa
tanto quanto o do que ficou:

1. A primeira forma comparava conjuntos **aptos** entre capturas e carregava uma marca `is_deleted`
   até a dimensão, pelo caminho do [ADR-0029](0029-exclusao-logica-como-marca-na-dimensao.md). A
   revisão mostrou que misturava remoção física com rejeição nova (P03), exigia classificar a
   captura anterior — que não é materializada (P04) —, e que a chave `id` não existe em
   `inventory_movements` (P12).
2. A segunda forma detectava por presença física e persistia a marca com `hard_deletes: new_record`
   nos *snapshots*. A revisão mostrou cinco consequências que se puxavam: a marca só durava uma
   comparação (P14); os quatro *snapshots* existentes exigiriam migração (P24); "ler a última versão"
   suprimia o contrato SCD do [ADR-0017](0017-chaves-substitutas-e-scd.md) usado pelas fatos (P25);
   só 4 das dimensões seriam cobertas (P26); e a regra colidia com a exclusão lógica já propagada —
   `dim_customer` tem 7 marcas do ADR-0029 antes de qualquer `DELETE` (P27).
3. Ao reexaminar, uma consequência dos ADRs já aceitos apareceu: sob o
   [ADR-0038](0038-quarentena-de-excedente-e-rejeicao-em-cascata.md) (cascata) e o
   [ADR-0042](0042-reconciliar-a-captura-legada-na-fato-incremental.md) (o ramo legado da fato segue
   a captura por `delete+insert`), **a remoção física de um registro já retira dele tudo do
   datamart**: os pedidos do cliente removido viram `FK_ORPHAN`, os itens cascateiam, o ramo legado
   da fato é reconstruído da captura corrente. Nenhuma fato fica órfã. A marca dimensional não
   protegeria integridade — só memória —, e a memória já existe, mais forte, no bruto retido: "o
   histórico de capturas é o dado" (ADR-0037).

Medido em 14/09/2026: `raw_legacy` retém as gerações 1–16; `movement_id` é `Uuid` no SQLAlchemy e a
macro `identidade_canonica` só normaliza inteiros — dois textos do mesmo UUID não casam por ela; dos
692 movimentos legados, 139 estão rejeitados, então apagar três quaisquer não prova saída de três
linhas da fato; e uma lista cumulativa de ausentes não fecha a equação de um intervalo (em A={1,2},
B=C={2}, a lista mantém a chave 1 em C e a equação B→C daria `1−1+0=0` para uma linha presente), nem a
comparação por chave vê `[7,7] → [7]`.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Detecção pela presença física no bruto, em dois modelos — estado cumulativo e transições de intervalo com multiplicidade —, sem marca dimensional** (escolhida) | Persiste por construção: a memória é o bruto retido, sem estado novo; nenhum *snapshot*, dimensão ou ADR de modelagem muda (0017, 0029 e 0042 intactos); a equação fecha em linhas físicas; a chave é a PK declarada por tabela, canonizada pelo tipo; volta ao pedido original do R10 | O datamart **não retém** o membro removido: quem quiser saber que o cliente 42 existiu consulta `legacy_removed_records` ou o bruto, não `dim_customer`; e a varredura compara a selecionada com **todas** as certificadas anteriores por tabela, custo que cresce com o número de capturas |
| Marca `is_deleted` nas quatro dimensões com *snapshot*, via `hard_deletes: new_record` | O datamart lembra do membro, como faz com a exclusão lógica | Migração versionada dos *snapshots*; emenda explícita ao ADR-0017 (fallback preservando versões) e composição com o ADR-0029 (`deletion_kind`); universo limitado e declarado (supplier, warehouse, carrier, campaign fora); mais uma rodada de revisão provável. **Descartada pelo Owner em 14/09**, depois de constatado que a marca não protegeria integridade |
| Comparar conjuntos **aptos** entre capturas | Mais próximo do que "sumiu do datamart" | Mistura remoção com rejeição nova; exige classificar a captura anterior (dobro de 40 tabelas de 60–120 kB de SQL, ADR-0043). Descartada na segunda rodada |
| Só reportar, sem detectar transições | Um modelo só | Uma lista cumulativa não fecha a equação do intervalo nem vê redução de multiplicidade (VR04) |
| Enviar removidos para `quarantine` | Reaproveita o destino existente | Ausência não é rejeição: a quarentena passaria a conter registros que nunca tiveram defeito, e a equação `extraídos = aceitos + corrigidos + rejeitados` deixaria de significar o que significa |

## Decisão

**A exclusão física do legado é detectada exclusivamente em `raw_legacy`, pela presença da chave de
negócio entre a captura selecionada e as capturas certificadas anteriores, em dois modelos de
`trusted` — um de memória, um de intervalo —, e nenhuma dimensão recebe marca por isso.**

1. **Identidade.** A chave de negócio é a **chave primária declarada no SQLAlchemy, por tabela**
   (`Base.metadata`: `id` em 39 tabelas, `movement_id` na 40ª), lida da declaração, nunca literal.
   É canonizada **pelo tipo declarado**: inteiro por `identidade_canonica` (`08` = `8`); `Uuid` por
   `cast` (caixa e hífens deixam de importar); texto por `trim`. Chave nula ou **não conversível para
   o tipo** é **`sem identidade`**: não entra na comparação, é contada à parte, e o achado próprio
   dela continua sendo o do catálogo — nada é relabelado.
2. **Capturas comparáveis.** Só capturas com certificado `complete` nas 40 tabelas
   ([ADR-0044](0044-certificar-cada-captura-do-legado-por-conteudo.md)) entram na comparação, como
   selecionada ou como anteriores. As gerações 1–16 não têm certificado e não são elegíveis; a
   primeira comparação acontece entre duas capturas novas. Reprocessar uma captura X compara só com
   certificadas `< X`.
3. **Memória — `trusted.legacy_removed_records`** (`table`): toda chave que apareceu em **qualquer**
   captura certificada anterior à selecionada e está ausente nela, com `last_seen_snapshot_id` (a
   maior onde esteve), `removed_in_snapshot_id` (a menor certificada posterior ao `last_seen` onde
   faltou) e o `last_payload` **bruto** da última captura em que existiu. Persiste por construção em
   toda captura seguinte; sai quando a chave reaparece; reexclusão depois de reaparecimento dá
   `last_seen` e `removed_in` novos. **Não entra em equação nenhuma** — é auditoria.
4. **Intervalo — `trusted.legacy_capture_transitions`** (`table`): entre a certificada anterior
   **mais recente** e a selecionada, por tabela e chave canônica, com **multiplicidade**
   (`n_anterior`, `n_selecionada`) e a transição `removida` (n > 0 → 0), `adicionada` (0 → n > 0),
   `reduzida`/`aumentada` (as duas > 0 e diferentes) ou `mantida`; linhas `sem identidade` contadas
   por lado. A equação, em **linhas físicas**,
   `linhas(anterior) − Σ max(0, n_ant − n_sel) + Σ max(0, n_sel − n_ant) + Δ sem_identidade = linhas(selecionada)`,
   fecha por construção e é teste de dados a cada *build*.
5. **O datamart segue os ADRs 0038 e 0042.** O que a remoção retira da origem sai das fatos por
   cascata e por `delete+insert`; a quarentena explica a cascata (`PARENT_REJECTED`, `FK_ORPHAN`) e
   `legacy_removed_records` explica a raiz. Rejeição nova **sem** remoção não é remoção: a chave é
   `mantida` no intervalo, e a perda de aptidão aparece na classificação, não aqui.
6. **O esperado é independente.** Quem apaga, insere ou altera a origem para provar isto — a CLI do
   legado — grava no diário do manifesto o que o banco **devolveu** (`RETURNING`), a confirmação
   pós-*commit* e o hash de conteúdo antes e depois; as testemunhas da prova são escolhidas pelo
   oráculo entre ocorrências aptas **e** conferidas presentes na fato antes do `DELETE`.

## Consequências

- **Positivas:** o registro que some da origem deixa de sumir em silêncio — tem linha, captura em
  que sumiu e último payload; "remoção real" e "falha de ingestão" são distinguíveis por evidência,
  porque só captura certificada compara; nenhum contrato aceito muda; e o critério de conclusão da
  Etapa 10 que dependia disto passa a ter prova possível.
- **Negativas:** o datamart não lembra do membro removido — é decisão, não omissão, e quem precisar
  dessa memória tem o bruto retido e a tabela de auditoria; a comparação cumulativa varre todas as
  capturas certificadas por tabela, e o custo cresce com elas (o descarte de capturas antigas
  continua sendo a decisão futura que o ADR-0037 adiou); e a canonização por tipo é uma macro a
  mais, com os limites de conversão do PostgreSQL como fronteira do que é "mesma chave".
- **Paridade com o GCP:** a mesma comparação entre partições de `raw_legacy` por `snapshot_at` no
  BigQuery, com `SAFE_CAST` aos mesmos tipos para canonizar a chave; os dois modelos são dbt, sem
  mudança; a elegibilidade vem da mesma tabela `governance.legacy_captures` do ADR-0044.
- **Documentos a atualizar:** [Origem Legada](../origem_legada.md) §6 — a detecção e os dois
  modelos; [ADR-0015](0015-sincronizacao-e-exclusoes.md) — nota datada de referência, sem reescrita;
  [Qualidade de Dados](../qualidade_de_dados.md) — a equação física e os testes;
  [Arquitetura](../arquitetura.md) §5 — linha de paridade; [Modelo de Dados](../modelo_de_dados.md)
  §6 — os dois objetos em `trusted`.
