# 02 — IAM, contas de serviço, federação e segredos: a fundação

**Em uma frase.** IAM decide **quem pode o quê em qual recurso**; contas de serviço são as
identidades dos componentes; *Workload Identity Federation* deixa um sistema de fora agir como uma
delas sem chave; Secret Manager guarda o que o `.env` guardava. É o equivalente na nuvem dos cinco
papéis do [ADR-0011](../docs/adr/0011-classificacao-e-papeis-de-acesso.md) e da
[Governança §7](../docs/governanca_de_dados.md#7-regras-de-acesso-por-camada).

**Quanto custa e por quê.** IAM: nada. Secret Manager: centavos (por versão ativa e por acesso).
É o único capítulo em que o custo é irrelevante e o **risco** não: uma chave de conta de serviço
gerada e baixada é um segredo longevo — a regra 1 do `CLAUDE.md` não admite.

**Onde fica.** ☰ → *IAM & Admin*. Subpáginas: *IAM* (a tabela principal ↔ papel), *Service
accounts*, *Workload Identity Federation*, *Audit Logs*, *Quotas*, *Asset Inventory*. Secret
Manager: ☰ → *Security → Secret Manager* (`console.cloud.google.com/security/secret-manager`).

**O que é deste projeto aqui.** Uma conta de serviço por papel — o Terraform deve criá-las com os
nomes do ADR-0011: `ingestor` (Airbyte), `transformer` (dbt no Composer), `streamer` (Dataflow),
`analyst`, `auditor` — mais as que os produtos exigem (a do ambiente Composer, a dos *workers* do
Dataflow, a do Datastream). Um *pool* de federação para o fluxo das *policy tags* (ADR-0025). Os
segredos: senhas do Cloud SQL, credenciais do Airbyte.

## Roteiro guiado

1. **IAM (a tabela).** *View by principals*. *O que olhar:* cada conta de serviço e os papéis
   dela; procure `roles/bigquery.dataViewer`, `dataEditor`, `jobUser`, `roles/cloudsql.client`,
   `roles/pubsub.subscriber`, `roles/dataflow.worker`. *Por quê:* é a §7 traduzida — `analyst` só
   deve ter leitura no *dataset* `consumption` (e isso **não aparece aqui**: permissão por
   *dataset* é dada no BigQuery, cap. 04; aqui só o que é de projeto). Marque *Include
   Google-provided role grants* para ver as contas que os produtos criaram sozinhos.
2. **Papéis (*Roles*).** Abra `BigQuery Data Viewer` e leia as permissões (`bigquery.tables.getData`
   …). *Por quê:* saber que um papel é um conjunto de permissões nomeadas é o que permite ler
   qualquer erro `PERMISSION_DENIED: missing bigquery.tables.getData`.
3. **Service accounts.** Abra a de `transformer`. Abas: *Details*, *Permissions* (quem pode
   **usar** esta conta — `Service Account User`/`Token Creator`), **Keys** — deve estar
   **vazia**: nenhuma chave criada. *Logs* → mostra o uso. *Por quê:* "conta sem chave" é a
   frase que separa quem seguiu a regra 1 de quem não.
4. **Workload Identity Federation.** *Pools* → o *pool* do CI → *Providers* (GitHub, OIDC) →
   *Connected service accounts*. *O que olhar:* a condição de atributo (`assertion.repository ==
   "…"`) que restringe quem pode assumir. *Por quê:* é a "condição inseparável" do ADR-0025 em
   forma de tela.
5. **Policy Troubleshooter** (*IAM & Admin → Policy Troubleshooter*). Pergunte: "a conta
   `analyst` tem `bigquery.tables.getData` na tabela `trusted.orders`?" Resposta esperada:
   **não**, com a explicação de por quê. *Por quê:* é a asserção de falha da Governança §7
   ("um `SELECT` de `analyst` contra `raw` precisa falhar") **sem executar nada**.
6. **Secret Manager.** Abra um segredo → *Versions* (cada versão é imutável; a corrente é a
   *latest*), *Permissions* (`Secret Accessor` para quem lê), *Logs* (cada acesso é registrado).
   *Por quê:* onde o `.env` virou recurso com IAM e trilha.
7. **Audit Logs** (*IAM & Admin → Audit Logs*). Veja quais serviços têm *Data Access* ligado
   (o *Admin Activity* é sempre ligado). *Por quê:* BigQuery com *Data Access* ligado registra
   **quem leu qual tabela** — é a evidência de acesso negado do cap. 09.

## Onde aciona, onde registra, o que controla

- **Aciona:** concessão e revogação (consola, `gcloud projects add-iam-policy-binding`,
  Terraform). *Impersonation*: `gcloud auth print-access-token --impersonate-service-account=…`.
- **Registra:** *audit logs* (`protoPayload.methodName="SetIamPolicy"` — cap. 10); *Logs* da
  conta de serviço; *Secret Manager → Logs*.
- **Controla:** papéis por projeto, por recurso (*dataset*, tópico, segredo), condições IAM,
  *organization policies* (ex.: "não criar chaves de conta de serviço" —
  `iam.disableServiceAccountKeyCreation` — vale ver se está ligada).

## Armadilhas

- IAM **propaga com atraso** (até minutos): "acabei de dar e não funciona" costuma ser isso.
- Permissão de *dataset* e de *policy tag* não estão na tabela de IAM do projeto — estão no
  BigQuery e no Dataplex (cap. 04 e 09). Quem procura só aqui conclui errado.
- Conta de serviço com `Owner`/`Editor` no projeto "funciona" e é o erro de segurança mais
  comum. O Terraform deve dar papéis mínimos; se vir `Editor` numa conta de serviço, anote como
  achado.
- Chave criada "só para testar" fica em `Keys` para sempre. Se existir uma, apague e registre.

## Evidência a levar

- Captura da tabela IAM filtrada pelas cinco contas de serviço.
- Captura de *Keys* vazia da conta `transformer` (ou de todas).
- Resultado do *Policy Troubleshooter* negando `analyst` em `trusted`.
- `gcloud projects get-iam-policy <projeto> --format=yaml` salvo (no Cloud Shell).

## O que você saberá dizer depois

- "Cada componente tem conta de serviço própria com papel mínimo; nenhuma tem chave."
- "O CI aplica *policy tags* por federação de identidade, com condição de repositório."
- "Provei que o perfil de análise não alcança `trusted` com o *Policy Troubleshooter* e com o
  *audit log* de uma leitura negada."
