# Plano — a revisão da governança (G01 a G06) e o pacote para o portal

| Campo | Informação |
|---|---|
| Data | 10/11/2026, noite |
| Pedido do Owner | "Já que o processo está ocioso, vamos avançar com as transformações sugeridas em `revisao_governanca.md`" — e, em seguida, "primeiro crie somente o plano" |
| Origem | O parecer `REVISAO_GOVERNANCA.md` (outra sessão, 10/11/2026, sobre `8e606d9`; fora do Git, na raiz) e a **V2** das [Pendências](docs/pendencias.md) |
| Base | `main` em `846050c`, publicado; árvore limpa, exceto o parecer e este plano |
| Natureza | Plano. Ao escrevê-lo, nada foi alterado (§2). **Bloco A executado em 10/11/2026, 20:44 → 21:20** (§9); Blocos B e C depois do M6 |
| Revisão | Integral pelo Owner; pelo codex2 antes de executar — rodada 1 feita (§10) |

---

## 0. O que este plano muda na decisão de 10/11

A V2 registra a decisão do Owner, tomada hoje, de **não** tratar estes achados durante a Etapa 13:
eles entrariam quando não houvesse mais pendências. O pedido desta noite antecipa esse trabalho
enquanto a janela está parada (o próximo passo é quarta, 07:00, §6.9 do `PLANO_etapa_13.md`).

O plano antecipa **só o que não toca no que a janela de quarta usa** (§1): o Bloco A agora e a
decisão do Bloco C. O G06 e a implementação do pacote ficam para depois do M6 (§6). Ao executar, a
V2 registra a nova decisão e o que cada achado recebeu.

## 1. A fronteira: o que a janela de quarta usa e este plano não toca

- **O projeto dbt e o glossário.** O `make gcp-composer-publicar` monta o layout no momento em que
  roda e o copia para o *bucket* do Composer (`PLANO_etapa_13.md`, §6.9). Um `.yml` alterado no
  *checkout* antes da publicação de quarta vai junto para o Composer. A mudança só afeta a
  descrição, mas um erro de sintaxe derrubaria o *parse* na parte cara da janela, além de mudar o
  declarativo que o Owner revisou para ela.
- **Os dois *manifests* do *checkout*.** O `dbt/target/manifest.json` (09/11, 15:23 UTC) é a base
  das comparações locais da janela; o `make gcp-evidencias` lê o `dbt/target_gcp/manifest.json`, o
  do alvo `gcp` (RVG-1-05). Um `dbt compile` aqui trocaria um ou outro.
- **Terraform, alvos `gcp-*` do Makefile e *values* do Helm** ficam fora do plano.

Consequência: o **Bloco A** (texto fora do dbt) pode ir para o `main` agora. O **Bloco B** (os
`.yml`) fica **para depois do M6**, como a V2 já previa (Q2-c, decidida em 10/11, noite).

## 2. O que já foi conferido para escrever este plano (sem efeito)

- Leitura do parecer, da V2, do README, da Arquitetura §1 e §5, da Governança §5.2 e §10, do
  cabeçalho do `docker/docker-compose.yml` e de `terraform/cloud_sql.tf`, de `tests/test_descricao.py`,
  de `models/descriptions.py`, da ponte do legado e da D03 e E1 do `gdados`.
- Contagem no *manifest* de 09/11: as 141 faltas por modelo (tabela da §4) coincidem com os tetos.
- `python -m mvp_ed1.docs_check`: 120 documentos, 1.208 links, nada quebrado.
- `.claude/skills/adr/verificar.py`: **código de saída 1**, com dois tipos de problema que o parecer
  não viu (A2.3 e A2.4).

**Não executado:** `make check`, `make check-offline`, dbt, qualquer acesso a banco ou ao GCP.

---

## 3. Bloco A — conciliar os documentos (G01 a G05, mais o que a conferência achou)

Só documentos e o comentário de um arquivo de configuração. Nada de modelo, teste de dados ou
infraestrutura. Um *commit* por assunto; *push* só com o Owner.

### A1 (G01) — o estado da Etapa 13

| Onde | Hoje | Proposta |
|---|---|---|
| [Plano](docs/plano_de_desenvolvimento.md), linha *Etapa atual* (**dono**) | "em planejamento no plano transitório" | autorizada em 06/11/2026, **em execução** na janela de 09 a 12/11/2026; andamento no [Registro](docs/registro_fase_gcp.md); aceite (M6) só no G8. Versão 3.12 → 3.13 |
| [Pendências](docs/pendencias.md), cabeçalho *Etapa atual* | repete o Plano, com o mesmo "em planejamento" | uma frase com link para o Plano, sem repetir o estado |
| README, *Em resumo › Estado* e *Status* | "planejada e não começou"; "não começou; o pré-requisito é a autorização" | autorizada e em execução, com links para o Plano e o Registro. Sem portas, datas de prova ou contagens (G02) |
| README, *Fases*, item 2 (**achado adicional**) | "Cloud SQL, BigQuery, **Datastream**, Pub/Sub e Dataflow" | contradiz o próprio README e o [ADR-0051](docs/adr/0051-cdc-da-fase-gcp-pelo-debezium-server.md). Trocar a lista por uma frase com link para o [mapa de paridade](docs/arquitetura.md#5-mapa-de-paridade-local--gcp) |

**Fica como está:** a autorização de 06/11. **Não se afirma** conclusão de etapa, aceite ou M6.
O texto não depende de nenhuma prova isolada.

*Commit:* `docs: atualiza o estado da Etapa 13 no plano, nas pendências e no README`.

### A2 (G02) — números e versões do README

1. **Em resumo.** As linhas *Qualidade* (905 nós, 637 testes, 4.161 colunas) e *Processo*
   (48 ADRs, 306 *commits*) são números da `v1.0.0` apresentados sem data, e o mesmo README já cita
   51 ADRs e `PASS=907` com 1.079 testes da `v1.1.0`. Proposta (Q1-a): cada número histórico ganha
   versão e data ("no aceite da `v1.0.0`, 04/10/2026"), e a contagem de ADRs sai do resumo, porque
   já existe na linha do mapa, guardada pelo verificador.
2. **Mapa, coluna *Situação*.** Ela repete a versão que cada documento traz no cabeçalho, e sete
   estão divergentes. Proposta (Q1-a): tirar a versão e a narrativa datada da coluna, deixando um
   rótulo estável (*Vigente*, *Gerado*, *Aprovado*). A versão continua no cabeçalho do documento,
   o seu dono.

   | Documento | README | Cabeçalho |
   |---|---|---|
   | Plano | v3.10 | 3.12 |
   | Arquitetura | v2.5 | 2.7 |
   | Origem Legada | v2.10 | 2.11 |
   | Streaming | v2.2 | 2.3 |
   | Qualidade | v1.15 | 1.18 |
   | Governança | v2.6 | 2.22 |
   | Execução Local | v1.17 | 1.18 |
3. **A linha *Pendências do Owner*** (**achado do verificador**). Ela conta 4, mas o verificador
   conta 6 (D43, D63, D64, D66, V1 e V2), e acusa D62, D65 e D67, já fechadas, como pendentes.
   A causa: a linha *Verificações e trabalho adiados*, criada com a V1, não é conhecida pelo
   verificador. Ele conta V1 e V2 como *aprovações pendentes*, enquanto o cabeçalho das Pendências
   diz "Aprovações pendentes: 0". Proposta: o verificador passa a conhecer a linha dos V (Vn em
   `###`, contadas nessa linha) e ganha um cenário em `tests/test_verificador_adr.py`. A linha do
   README fica com a contagem e o link, sem a lista das já fechadas.
4. **O verificador lê arquivos não rastreados** (**achado do verificador**). Os dez "links
   quebrados" são de `data/medicoes/…`, que está no `.gitignore`. O `docs_check` lê só os documentos
   rastreados. Proposta: o verificador faz o mesmo (`git ls-files`), com um cenário no teste.

5. **O verificador entra no `check-offline`** (Q5-a). Depois dos itens 3 e 4, o alvo
   `check-offline` do Makefile passa a rodar o `verificar.py` e falha com o código de saída dele.
   É declarativo, portanto entra na revisão integral do Owner. Por causa da `makefile-sem-make-n`,
   a receita é conferida lendo o texto, e um teste de `tests/test_makefile.py` guarda a presença
   do passo.

*Commits:* `docs: tira do README as contagens e versões mantidas à mão` (itens 1 a 3, a parte do
README); `fix: o verificador de ADR conhece as verificações adiadas e lê só o rastreado` (itens 3
e 4, a parte do verificador); `feat: o check-offline confere os contadores de decisões` (item 5).

### A3 (G03) — o diagrama da Arquitetura §1

O rótulo `analytics<br/>9 fatos + 17 dimensões` passa a ser `analytics<br/>fatos e dimensões`, com uma
linha sob o diagrama apontando para o [Modelo de Dados §3](docs/modelo_de_dados.md), dono do
inventário (na execução se viu que o §3 **não** é trecho gerado, ao contrário do que esta linha dizia). Versão 2.7 → 2.8.

**Fica como está:** ADR-0017, ADR-0028 e ADR-0035, que citam as contagens da época em que foram
aceitos.

*Commit:* `docs: tira do diagrama da arquitetura a contagem de fatos e dimensões`.

### A4 (G04) — a Governança §5.2

- **Item 1** reescrito pela D80: descrições pelo `persist_docs`; `domain`, `owner` e `retention`
  como *labels* do BigQuery, derivados do `meta` por *post-hook*, e lidos pelo Dataplex; linhagem
  por coluna capturada pelo próprio BigQuery e **medida** contra o módulo; travessias de fora do
  BigQuery por tabela, pela API. Link para o [Registro §23](docs/registro_fase_gcp.md#23-g5-catálogo-e-linhagem-07112026-noite).
  Sai a escolha "pacote ou script, a fazer na Etapa 13".
- **Item 2** conferido contra a D79 e a D71:
  - só `confidential` e `personal` viram *tag*; o texto atual fala só de `personal`;
  - o Terraform cria a taxonomia, as *tags* e o IAM;
  - o dbt aplica as *tags* nas tabelas que materializa, e o fluxo do ADR-0025 converge as outras;
  - o fluxo só roda na janela.

  Link para o [Registro §22](docs/registro_fase_gcp.md#22-g4-as-policy-tags-07112026-noite).
- A linha *Catálogo corporativo* da [Arquitetura §4](docs/arquitetura.md) ("Dataplex, alimentado
  pelo `manifest.json`") é conferida contra a D80 e só muda se contradisser.
- Versão 2.22 → 2.23, com *Última revisão* preenchida.

**Ponto de atenção:** a Governança §10 diz que alterar a política "exige decisão explícita do Owner
e ADR". A decisão já existe (D79, D80); a pergunta é se registrar o texto pede ADR novo (Q3).

*Commit:* `docs: alinha a Governança §5.2 às decisões D79 e D80`.

### A5 (G05) — o comentário do `docker/docker-compose.yml`

As linhas 5 a 7 dizem que "cada banco é uma instância Cloud SQL própria". No
[`terraform/cloud_sql.tf`](terraform/cloud_sql.tf), as duas origens estão numa instância só, com dois
bancos, e o armazém é o BigQuery. Texto proposto:

- o que espelha a fase GCP é a separação entre as **origens** (Cloud SQL) e o **armazém**
  (BigQuery);
- lá as duas origens dividem uma instância;
- aqui ficam em contêineres separados, porque o `wal_level=logical` é da origem e não deve ser
  imposto ao armazém.

O Terraform não muda.

*Commit:* `docs: corrige no compose a topologia das origens na fase GCP`.

### A6 — as Pendências e o parecer

- **D91** registrada nas [Pendências](docs/pendencias.md) §2 como **decidida** em 10/11/2026: o
  pacote de metadados para o `gdados` (Bloco C, Q4a-a e Q4b-a), com implementação depois do M6.
  Contadores do cabeçalho, do README e do Registro de Decisões acertados pela skill `adr`.
- **V2** reescrita com o que este plano decidiu e fez:
  - G01 a G05 fechados, com os *commits*;
  - a antecipação do Bloco A, em 10/11, noite;
  - o G06 e a implementação da D91 depois do M6;
  - G07 a G10 no `gdados`;
  - o parecer citado pelo *commit*, e não mais como "fora do Git".
- **O parecer `REVISAO_GOVERNANCA.md`** entra no Git como está (Q7-a), no primeiro *commit* do
  Bloco A, e sai com `git rm` quando a V2 fechar, como os dossiês `REVISAO.md`.

*Commits:* `docs: versiona o parecer da revisão da governança para o portal` (o primeiro do
bloco) e `docs: registra a D91 e o andamento da V2` (o último).

### Validação do Bloco A

- `make check-offline`, com o *commit* condicionado ao código de saída;
- `python -m mvp_ed1.docs_check`;
- `verificar.py` com código de saída 0;
- leitura do *diff* inteiro.

Nada no dbt, nos bancos ou no GCP. **Estimativa:** cerca de 1 h de trabalho e 15 min de revisão
do Owner (planejado, não medido). **Medido:** 36 min de relógio, de `fa98214` (20:44) a `01c684f`
(21:20), a maior parte nos dois `check-offline` (8 min 54 s e 6 min 43 s, contra os ~4 min
estimados); a revisão do Owner, pendente.

---

## 4. Bloco B — G06, as 141 descrições

### 4.1 Onde cada falta se resolve

As 141 faltas se concentram em poucos pontos de declaração. Corrigir na declaração resolve o
derivado (CLAUDE.md §5).

| Ponto | Faltas | Arquivos | Como se resolve |
|---|---:|---:|---|
| **B1** — gerador da ponte do legado: `ingested_at` das `legado__*` | 36 | 36 | A coluna nasce de `snapshot_at AS ingested_at`. Ela não transporta o `ingested_at` do `stg_retail__*`, por isso não tem `description_from`. O texto vai no gerador (`legacy/ponte.py`, onde "o texto na ponte é escrito pelo gerador"), e `make legacy-models` regenera |
| **B2** — `stg_retail__inventory_movements`: `schema_version`, `arrived_by_stream`, `arrived_by_batch`, `ingested_at` | 4 | 1 | É a união do lote com o *streaming*. Texto no `.yml` à mão. Cascata esperada: o `schema_version` da ponte já declara `description_from` para ele |
| **B3** — `legado__inventory_movements`: `event_sequence`, `schema_version`, `arrived_by_*` | 4 | 1 | O `schema_version` deve herdar depois do B2. Os outros vão no gerador da ponte: par declarado, se a coluna reproduz a do `stg_retail__*`, ou texto, se calcula |
| **B4** — colunas calculadas da `trusted` (17 modelos e 2 *seeds*) | 85 | 19 | Contagens, valores, *flags* e instantes agregados de carts, orders, payments, payment_transactions, shipments, support_tickets, purchase_orders, inventory_balances, delivery_events e outros. Texto no `.yml` à mão de cada modelo e *seed*, **lido do SQL** |
| **B5** — `snapshots`: `scd_coupon`, `scd_customer`, `scd_product` | 6 | 3 | São cópias de colunas da `trusted` que entram no B4. Espera-se que herdem por transporte; se não herdarem, o texto vai no `.yml` do *snapshot* |
| **B6** — `quarantine.rejected_shipment_deliveries` e `staging.legacy_selected_capture.snapshot_id` | 6 | 2 | `.yml` à mão |

### 4.2 Regras de escrita

São as do módulo `models/descriptions.py`:

- texto só no que **calcula**; o que transporta herda;
- nada de `description_reason` sem motivo;
- cada texto descreve **o que o SQL faz**: grão, filtro, unidade e sinal.

Pelo **P5**, significado de negócio que o SQL ou o glossário não sustentam não é inventado: vira
pergunta ao Owner, numa lista anexa ao *commit*.

### 4.3 Observação O1, fora do escopo

`trusted.legacy_order_totals_divergence` tem colunas em português (`itens_empilhados`,
`itens_rejeitados`, `motivos_da_rejeicao`), contra o CLAUDE.md §2. Renomear muda o modelo e o que o
lê, e por isso é decisão do Owner (Q6). Este plano só descreve essas colunas com o nome que têm.

### 4.4 Execução — depois do M6 (Q2-c)

1. No `main`, depois do desmonte e do aceite da Etapa 13. Sem *worktree*: o Composer e as medições
   da janela já não leem o *checkout*.
2. B1 e B3 no gerador, depois `make legacy-models`. B2, B4, B5 e B6 nos `.yml`.
3. `make catalog`, que regenera a classificação, a descrição derivada, o dicionário e a linhagem.
   Ele precisa do *manifest*, e o `dbt compile` conecta no armazém local.
4. `make preflight ALVO=check`, sem `FORCE`. Depois `make check` completo, com o `dbt build` no
   armazém local e a catraca de `tests/test_descricao.py`, que é de integração.
5. **A catraca baixa no mesmo *commit* da melhora**: o teste exige igualdade. Cada *commit* leva o
   seu teto. *Commits* por assunto:
   - a ponte do legado (B1 e B3);
   - o estoque (B2 e parte do B4);
   - vendas e pagamentos;
   - logística;
   - atendimento;
   - *snapshots* e o restante.
6. Revisão **integral** do Owner sobre os textos (declarativo) e por amostragem sobre o
   `_derived.yml` e o dicionário (derivado).
**Estimativa:** de 2 a 3 h de escrita, mais a revisão do Owner, que é o gargalo, sobre cerca de
140 textos (planejado, não medido).

---

## 5. Bloco C — o alvo de exportação para o `gdados` (decidido; implementação depois do M6)

**Decidido em 10/11/2026, noite (D91):** o pacote é um arquivo JSON **versionado neste
repositório**, gerado de forma determinística, e regenerado **dentro do `make catalog`**. O
`check-offline` confere que ele está em dia — sem precedente a copiar: hoje a classificação e a
linhagem se conferem no `check` completo, com o *manifest* (RVG-1-04). O contrato dessa guarda, o
nome e o caminho
do arquivo, o formato (número de versão, como o `lineage --json`) e o tratamento de artefato
incompleto se fecham na implementação, com a E1 do `gdados` como consumidor.

O `gdados` só lê este repositório, e `dbt/target/` e `data/` estão fora do Git (G09, G10; a D03 do
`gdados`, pendente lá). O pacote precisa nascer de um alvo **deste** projeto.

**O que o pacote compõe**, reutilizando os exportadores que já existem, sem reimplementar a
inferência:

- o `lineage --json`, no formato 1;
- descrições, sensibilidade e `meta` do *manifest*;
- as perguntas do glossário;
- as travessias de `crossings`;
- as faltas da catraca, explícitas;
- a procedência: *commit*, árvore suja ou limpa, `generated_at` e `invocation_id` do *manifest*, do
  `catalog` e do `run_results`, e o ambiente.

**As alternativas que foram apresentadas** (Q4; o Owner escolheu a **a**):

| | Formato e lugar | Gatilho | Guarda |
|---|---|---|---|
| **a** | arquivo gerado e **versionado** aqui, como o Dicionário | dentro do `make catalog` | conferência de atraso no `check-offline` (o "como a da classificação" da apresentação estava errado: RVG-1-04) |
| **b** | anexo de *release*, com versão e *hash* | alvo manual `make portal-pacote` | o *hash* fixado no *build* do `gdados` |
| **c** | o `gdados` lê o `dbt/target/` direto | — | nenhuma; é o problema da G09 |

A implementação vem depois do M6: ela lê o *manifest* e toca no `make catalog`, que a janela usa.

**Fora deste plano:** G07 a G10, que são requisitos do portal e vivem no `gdados`, e o tratamento
permanente do `airbyte_internal`, que é o outro item da V2.

---

## 6. Decisões pedidas ao Owner

### Rodada 1 (antes de executar) — respondida em 10/11/2026, noite

| | Decisão do Owner |
|---|---|
| **Q1** | **(a)** Tirar do README as versões e contagens mantidas à mão; números históricos com versão e data |
| **Q2** | **(c)** O G06 fica para depois do M6, como a V2 previa — sem *worktree* |
| **Q3** | **(a)** Alinhar a §5.2 citando a D79 e a D80, sem ADR novo |
| **Q4** | **(a)** Decidir formato e gatilho agora, registrar como Dnn e implementar depois do M6 |

As opções como foram apresentadas:

| | Pergunta | Recomendação | Alternativas |
|---|---|---|---|
| **Q1** | Números e versões do README | **(a)** Tirar do README as versões e contagens mantidas à mão; os fatos históricos ficam com versão e data. Um dono só, e a regra de não duplicar já pede isso | (b) manter e guardar com teste no `docs_check`, que compara a versão do mapa com a do cabeçalho; (c) só realinhar à mão |
| **Q2** | Quando o G06 entra no `main` | **(a)** Escrever agora na *worktree* e integrar depois de quarta, 22:00 (fluxo e exportação do Composer feitos). Aproveita a noite e não mexe no que a parte cara usa | (b) direto no `main` agora, arriscando o layout e o *manifest* de quarta; (c) depois do M6, como decidido às 18h |
| **Q3** | A §5.2 da Governança e a regra da §10 | **(a)** Alinhar o texto citando a D79 e a D80, sem ADR novo: a decisão já foi tomada e registrada, e o texto só a reflete | (b) ADR curto da materialização da governança no GCP, que junta D71, D79 e D80 para o portfólio; (c) adiar para o G8 |
| **Q4** | O alvo de exportação | **(a)** Decidir formato e gatilho agora, como Dnn, e implementar depois do M6 | (b) implementar agora, com o mesmo risco da Q2-b; (c) esperar a E1 do `gdados` |

### Rodada 2 — respondida em 10/11/2026, noite

| | Decisão do Owner |
|---|---|
| **Q4a** | Pacote **versionado neste repositório**, como o Dicionário (alternativas: anexo de *release* com *hash*; os dois) |
| **Q4b** | Regenerado **dentro do `make catalog`**, conferido em dia no `check-offline` (alternativas: alvo manual; só na *release*) |
| **Q5** | O `verificar.py` corrigido **entra no `check-offline`** (alternativas: só no `make check` completo; só pela skill) |
| **Q7** | O parecer **entra no Git** com o Bloco A e sai com `git rm` ao fechar a V2 (alternativas: mover para `data/medicoes`; apagar ao fechar) |

### Fica para o Bloco B, depois do M6

| | Pergunta |
|---|---|
| **Q6** | A O1: renomear para inglês as três colunas de `legacy_order_totals_divergence` (entrega própria, com o que as lê), ou registrar como exceção? |

---

## 7. Riscos

| Risco | Tratamento |
|---|---|
| Colidir com a janela de quarta | O Bloco A não toca o dbt; o Bloco B só depois do M6 (§1, Q2-c) |
| R14: volume de texto que ninguém revisa | Cerca de 140 textos, em *commits* por domínio, com *diff* pequeno em cada um; revisão integral só do declarativo |
| Inventar significado (P5) | Texto lido do SQL; o que for duvidoso vira pergunta, não frase |
| R11: o `make check` do Bloco B usa o armazém local | `make preflight ALVO=check` antes, sem `FORCE` |
| Tirar a atenção do Owner antes de quarta, 07:00 | Hoje só as rodadas de perguntas e a revisão do Bloco A; o Bloco B, depois do M6 |

## 8. Definição de pronto aplicada

- **Bloco A:**
  - `check-offline` verde;
  - `docs_check` sem quebra;
  - verificador com código de saída 0;
  - documentação revisada, sem duplicar;
  - V2 atualizada, com G01 a G05 fechados e seus *commits*.
- **Bloco B:**
  - `make check` verde;
  - catálogo, dicionário e linhagem regenerados na mesma entrega;
  - catraca baixada em cada *commit*;
  - revisão integral do declarativo e por amostragem do derivado;
  - nenhum campo novo, portanto nada a classificar;
  - V2 com o G06 fechado ou o que sobrou, medido.
- **Registro da fase GCP:** uma entrada curta, com hora, o que entrou e a confirmação de que nada
  tocou a janela, apontando para a V2. O registro conta a história e não repete os achados.

## 9. Ordem

1. ~~Rodadas 1 e 2 de perguntas~~ (feitas, §6).
2. ~~Revisão deste plano pelo codex2~~ (rodada 1, §10).
3. ~~Bloco A no `main`~~ (feito em 10/11/2026, noite: `fa98214`, `69479e4`, `5831da8`, `3e6fbac`,
   `eb93a5d`, `a95e910`, `728c08d`, `034cec8`, `1dd4dcf`, `bd2313b`, `01c684f`, e este plano).
   Bloco A no `main`, na ordem: o parecer (A6), A1 a A5, o verificador no `check-offline` (A2.5)
   e a D91 com a V2 (A6). Revisão do Owner; *push* com o Owner.
4. Depois do M6: Bloco B (G06, com a Q6) e a implementação da D91.
   Antes, os ajustes do §10 para o Bloco B e a D91.

---

## 10. Rodadas de revisão

### Rodada 1 — codex2, sobre o plano congelado (10/11/2026, noite)

Sessão `01a1c7d4…`, esforço *high*, sobre `846050c` e uma cópia congelada do plano. Veredito:
**mudanças necessárias**, nenhuma contra o Bloco A. Relatório, pedido e *log* fora do Git, em
`data/medicoes/governanca/` (`codex2_plano_governanca_r1*`).

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RVG-1-01 | §4.1, B1/B3 | O texto próprio gerado na ponte é recusado pelo contrato atual (`descriptions.py:295`, "texto na ponte sem description_from"); falta desenhar a declaração e a validação, com contraprovas | bloqueante | **Aberto, depois do M6.** O desenho vem antes de implementar o B1 e o B3, revisado; se precisa de ADR é pergunta ao Owner |
| RVG-1-02 | §4.4, passos 2 a 4 | A ponte é regenerada antes do B2, e o texto que ela copia muda depois | ajuste | **Aberto, depois do M6.** A ordem passa a ser: B2, `make legacy-models`, `make catalog` de novo, no mesmo *commit* do estoque |
| RVG-1-03 | §4.1, B5; §4.2 | Os seis campos de *snapshot* ficam fora dos `check_cols` e congelados na versão; herdar o texto da `trusted` descreveria errado | ajuste | **Aberto, depois do M6.** Texto próprio com `description_reason`, como em `_snapshots.yml:3`; o teto de `snapshots` baixa junto com o B4 que o mover |
| RVG-1-04 | §5, D91 | Falta o contrato da guarda sem os artefatos fora do Git e sem autorreferência da procedência | ajuste | **Parte feita:** a D91 e a §5 deixaram de dizer que o `check-offline` já confere derivados (`bd2313b`). O contrato se fecha na implementação, com as contraprovas pedidas (clone sem artefatos, regeneração repetida, *commit* posterior sem mudança dos insumos) |
| RVG-1-05 | §1 | O `gcp-evidencias` lê o `dbt/target_gcp/manifest.json`, não o local | observação | **Feito:** §1 corrigida neste *commit* |

**Do Bloco A, na execução** (não achados da rodada): a frase da A3 de que o §3 do Modelo de Dados é
gerado estava errada e foi corrigida; o "como faz com os outros derivados" da D91 veio deste plano e
foi o RVG-1-04.
