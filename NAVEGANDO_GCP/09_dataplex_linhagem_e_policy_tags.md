# 09 — Dataplex, linhagem e *policy tags*: a governança que nega de verdade

**Em uma frase.** Três coisas que na fase local eram YAML, testes e papéis do PostgreSQL viram
serviço: o **catálogo** (os `.yml` do dbt publicados no Dataplex — descrição, classificação,
retenção por tabela e coluna), a **linhagem** (o grafo que a Data Lineage API recebe, alimentado
pelo [Dicionário §3](../docs/dicionario_de_dados.md#3-linhagem)) e as ***policy tags*** (a
classificação `sensitivity` como etiqueta que **nega leitura de coluna** a quem não tem o papel
`Fine-Grained Reader` — aplicadas pelo fluxo automatizado do
[ADR-0025](../docs/adr/0025-policy-tags-por-fluxo-automatizado.md)).

**Quanto custa e por quê.** Catálogo por metadado: quase nada; *policy tags*: nada; linhagem:
por evento registrado, centavos. O que cobra são *scans* (perfil e qualidade de dados no Dataplex)
— não use na janela, a qualidade é do dbt. Casa de US$ 0–20/mês
([conversa §3](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md)).

**Onde fica.** Dataplex: ☰ → *Dataplex* (hoje *Dataplex Universal Catalog*) → *Search*,
*Catalog*/*Entries*, *Lakes*, *Data quality*, *Data profile*. *Policy tags*: ☰ → *BigQuery* →
*Policy tags* (taxonomias; `console.cloud.google.com/bigquery/policy-tags`), ou dentro do
Dataplex/Data Catalog. Linhagem: aba **Lineage** de qualquer tabela no BigQuery (exige a API
`datalineage.googleapis.com` ativada) e a busca do Dataplex. A Google reorganizou o Data Catalog
dentro do Dataplex recentemente: se o menu não bater, `/` e "policy tags" / "lineage".

**O que é deste projeto aqui.** Uma taxonomia (ex.: `sensibilidade`) com quatro *tags* —
`public`, `internal`, `confidential`, `personal` — do [ADR-0011](../docs/adr/0011-classificacao-e-papeis-de-acesso.md);
as colunas com `meta.sensitivity: personal` nos `.yml` (as derivadas por `sensitivity.py`, 4.161
colunas classificadas) etiquetadas pelo fluxo; `analyst` **sem** `Fine-Grained Reader`;
a linhagem `oltp → raw → … → consumption` visível tabela a tabela (e por coluna nas 188 de
consumo, se publicada); as descrições e o `meta.retention` do dbt visíveis como metadados.

## Roteiro guiado

1. **Policy tags → a taxonomia.** As quatro *tags*, hierárquicas ou planas; *Enforce access
   control* **ligado** (sem isso a *tag* é só etiqueta). Clique em `personal` → *Permissions*:
   quem tem `Fine-Grained Reader` (`auditor`? ninguém?). *Por quê:* é a tabela da
   [Governança §5.1](../docs/governanca_de_dados.md#51-padrão-de-metadados) virando negação
   real — e "*enforce* ligado" é a frase que separa quem configurou de quem só criou.
2. **Uma coluna etiquetada.** BigQuery → `trusted.customers` → *Schema*: a coluna `first_name`
   com a *policy tag* `sensibilidade:personal` ao lado do tipo. *Por quê:* a classificação
   derivada do `.yml` chegou à coluna — é o resultado do fluxo do ADR-0025.
3. **O acesso negado, comprovado.** No Cloud Shell, como `analyst`
   (`bq --impersonate_service_account=analyst@…`):
   `select first_name from consumption.<view que exponha algo pessoal> limit 1` → **Access
   Denied: … policy tag**; `select count(*) from a mesma view` → funciona. Como `auditor` (se tiver
   o papel) → funciona. *Por quê:* critério da Etapa 13 por extenso: "*policy tag* aplicada …
   com acesso negado comprovado". Sem esta prova, o resto do capítulo é decoração.
4. **O fluxo automatizado.** Onde ele roda (GitHub Actions, provavelmente): a execução que
   aplicou as *tags* — *log* com a lista de colunas etiquetadas, autenticação por federação
   (cap. 02, sem chave). Mude a classificação de **uma** coluna no `.yml`, abra o PR/commit, veja
   o fluxo rodar e a *tag* mudar na coluna. *Por quê:* "aplicada a partir do YAML por fluxo
   automatizado" é o que a decisão diz; ver o ciclo fechar é a evidência.
5. **Dataplex → Search.** Busque `fact_sales_order_item`. A entrada: descrição (do `.yml`),
   colunas com descrição, *aspects*/*tags* (classificação, retenção), *labels*. Busque por
   `personal` — todas as colunas etiquetadas. *Por quê:* é o "catálogo como código" do ADR-0007
   publicado; quem procura um dado acha aqui, não no repositório.
6. **Lineage.** BigQuery → `consumption.<view>` → aba *Lineage*: o grafo para trás até `raw`,
   com os *jobs* do dbt como arestas (o BigQuery registra linhagem de cada consulta que escreve
   tabela automaticamente, se a API está ativada). Compare com a §3 do Dicionário. Se a linhagem
   por coluna foi publicada pelo módulo `lineage.py`, veja uma coluna de consumo e as suas
   origens. *Por quê:* a paridade da Arquitetura §5 ("a linhagem por coluna, do mesmo módulo, é o
   que a Data Lineage API recebe") em tela.
7. **Retenção como propriedade.** BigQuery → *dataset* `raw` → *Details* → *Default table
   expiration* (permanente = nenhuma) e `quarantine`/`snapshots` conforme a
   [Governança §8](../docs/governanca_de_dados.md#8-retenção). *Por quê:* `meta.retention` do dbt
   e a expiração real têm de dizer o mesmo — `tests/test_retencao.py` cobra a declaração; aqui
   você cobra a aplicação.

## Onde aciona, onde registra, o que controla

- **Aciona:** o fluxo automatizado (aplica *tags*), o dbt (escreve descrições no BigQuery ao
  materializar, com `persist_docs`), o próprio BigQuery (registra linhagem de cada *job*).
- **Registra:** *audit logs* de leitura negada por *policy tag* (`bigquery.googleapis.com`,
  `PERMISSION_DENIED` com `policyTag` no detalhe); a busca do Dataplex; o grafo de linhagem;
  os *logs* do fluxo.
- **Controla:** taxonomias e *enforce*; `Fine-Grained Reader` por *tag*; *aspects*; APIs ativadas.

## Armadilhas

- Taxonomia sem *Enforce access control* ligado não nega nada — e a tela não grita.
- *Policy tag* é cobrada na **leitura da coluna de base**: uma view (*authorized* ou não) que
  leia `first_name`, mesmo dentro de `first_name || last_name`, falha para quem não tem o papel.
  O que **não** herda nada é uma **cópia**: cada tabela que o dbt materializa em `staging`,
  `trusted`, `analytics` é uma tabela nova, sem *tag* — é exatamente por isso que a classificação
  é **derivada** camada a camada (`sensitivity.py`) e o fluxo do ADR-0025 tem de etiquetar todas
  as camadas, não só `raw`. Confira uma coluna pessoal em `analytics`, não só em `raw`.
- Linhagem só aparece com a API ativada **antes** de o dbt rodar; ativada depois, o histórico
  não volta.
- *Scans* de qualidade/perfil do Dataplex cobram por execução; não são o teste do dbt.

## Evidência a levar

- Captura da taxonomia com *Enforce access control* ligado e as permissões de `personal`.
- Captura do *Schema* de uma tabela com a *tag* na coluna.
- Saída do `bq` como `analyst`: a coluna negada (com o texto do erro citando a *policy tag*) e a
  contagem permitida. O *audit log* correspondente (cap. 10).
- *Log* de uma execução do fluxo automatizado (colunas etiquetadas, autenticação por federação).
- Captura do grafo de *Lineage* de uma view de consumo até `raw`.

## O que você saberá dizer depois

- "A classificação do YAML vira *policy tag* por um fluxo com federação de identidade; mudei uma
  coluna e vi a *tag* mudar."
- "Provei acesso negado por coluna como `analyst`, com o *audit log* da negação."
- "A linhagem no BigQuery é registrada por *job* e bate com a §3 do Dicionário, que o repositório
  gera do SQL compilado."
