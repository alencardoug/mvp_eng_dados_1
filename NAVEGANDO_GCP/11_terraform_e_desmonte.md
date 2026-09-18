# 11 — Terraform, o estado e o desmonte

**Em uma frase.** O Docker Compose da nuvem: o `terraform/` descreve tudo o que existe, `apply`
faz existir, `destroy` faz deixar de existir, e o **estado** (um arquivo, guardado num *bucket*) é
o que o Terraform acredita que existe. A janela inteira é `apply` na segunda, `destroy` na
quinta, e a diferença entre o que o estado diz e o que a fatura cobra é o que sobra para a sexta.

**Quanto custa e por quê.** O Terraform em si, nada. O *bucket* do estado, centavos. O que custa é
o que ele **não** destrói: tudo o que foi criado fora dele (assinatura à mão, *backup on-demand*,
*bucket* do Composer, *job* de Dataflow lançado pelo `cli`, chave de conta de serviço). O
`destroy` só conhece o HCL.

**Onde fica.** No seu terminal (`terraform plan/apply/destroy` em `terraform/`), no *bucket* do
estado (☰ → *Cloud Storage → Buckets* → o *bucket* `…-tfstate` → `default.tfstate`), e na consola
que diz a verdade: ☰ → *IAM & Admin → Asset Inventory* (`console.cloud.google.com/iam-admin/asset-inventory`)
— **tudo o que existe no projeto, de qualquer serviço, numa lista**.

**O que é deste projeto aqui.** `terraform/` (a escrever na Etapa 13, [ADR-0004](../docs/adr/0004-terraform-como-iac.md))
com Cloud SQL, BigQuery (*datasets*, taxonomia), IAM/contas de serviço/federação, rede, GKE +
Airbyte, Composer, Datastream, Pub/Sub, Secret Manager — e a ordem de dependência entre eles, que
é a ordem de subida e a inversa de descida. O `airbyte/*.tf` que já existe localmente (o Airbyte
configurado por Terraform desde a fase local) é o precedente.

## Roteiro guiado

1. **`terraform show`** (ou `terraform state list`) no seu terminal: a lista de recursos que o
   estado conhece. Conte. *Por quê:* é o número contra o qual o *Asset Inventory* será comparado.
2. **O *bucket* do estado.** *Cloud Storage → Buckets → …tfstate*: o arquivo, o **versionamento
   ligado** (*Object versioning*: cada `apply` guarda a versão anterior), permissões (só você e o
   CI). *Por quê:* estado sem versionamento e um `apply` errado = não há volta; estado público =
   segredos expostos (o estado guarda senhas em texto claro — regra 1: o *bucket* é privado, e
   isso se confere em *Permissions*).
3. **Asset Inventory → Resource.** Filtre por *Asset type* e olhe a contagem por tipo:
   `sqladmin.googleapis.com/Instance`, `bigquery.googleapis.com/Dataset`,
   `composer.googleapis.com/Environment`, `container.googleapis.com/Cluster`,
   `dataflow.googleapis.com/Job`, `pubsub.googleapis.com/Subscription`,
   `storage.googleapis.com/Bucket`, `iam.googleapis.com/ServiceAccountKey` (**deve ser zero**).
   *Por quê:* a lista do que existe **de fato**, independente do Terraform. Exporte
   (*Export → CSV* ou `gcloud asset search-all-resources --scope=projects/<id>`). Faça **na
   terça** (linha de base) e **na sexta** (o que sobrou).
4. **Diferença estado × inventário.** O que está no inventário e não no estado é o que o
   `destroy` **não vai apagar**. Anote cada item e a decisão: apagar à mão na quinta, ou
   incluir no HCL. *Por quê:* é o exercício que o critério "Composer e Airbyte criados e
   destruídos na mesma janela" exige de verdade.
5. **`terraform plan -destroy`** (só o plano — não aplica). Leia a ordem: Composer e GKE
   primeiro (dependem de rede e contas), Cloud SQL depois, IAM por último. Procure
   `deletion_protection` no Cloud SQL (cap. 03: se `true`, o `destroy` falha — e é bom que falhe
   até você decidir) e `force_destroy` nos *buckets* (sem ele, *bucket* com objeto não morre).
   *Por quê:* o `plan` de destruição lido na terça é o que evita a quinta virar depuração.
6. **A lista de sobreviventes conhecidos** — o que **não** morre com o `destroy` e precisa de
   mão ou de HCL explícito. Confira cada um no *Asset Inventory* na sexta:

   | Sobrevivente | Por quê | Onde conferir | O que fazer |
   |---|---|---|---|
   | *Bucket* do Composer | apagar o ambiente não apaga o *bucket* | Cloud Storage | copiar `logs/` (evidência) e apagar |
   | *Job* de Dataflow em *streaming* | lançado pelo `cli`, não pelo HCL | Dataflow → Jobs | **Drain** antes do `destroy` (cap. 08) |
   | *Backups* do Cloud SQL (*on-demand*) e PITR | sobrevivem à instância se *on-demand* | SQL → Backups | apagar |
   | *Replication slot* / WAL retido | *stream* pausado sem apagar o *slot* | Cloud SQL → System insights | apagar o *stream* antes da instância |
   | Assinaturas/tópicos criados à mão | fora do HCL | Pub/Sub | apagar |
   | *Datasets* com `delete_contents_on_destroy=false` | BigQuery recusa apagar *dataset* com tabela | BigQuery | decidir: manter para evidência (custo de centavos) ou apagar |
   | *Bucket* do estado | de propósito | Cloud Storage | fica |
   | Discos órfãos do GKE | *PersistentVolume* do Airbyte | Compute Engine → Disks | apagar |
   | *Logs* | ficam 30 dias | Logging | exportar o que for evidência (cap. 10) |
   | Chaves de conta de serviço | não deveriam existir | IAM → Service accounts → Keys | apagar e registrar |

7. **A ordem do desmonte, como *checklist* de quinta:**
   1. `drain` do Dataflow → esperar `Drained`.
   2. Pausar e **apagar** o *stream* do Datastream (libera o *slot*).
   3. `terraform destroy -target` no Composer (o mais caro primeiro; ~15 min) — ou o `destroy`
      completo se o `plan` da terça estava limpo.
   4. GKE/Airbyte.
   5. O resto.
   6. *Asset Inventory* → comparar com a linha de base da terça → apagar sobreviventes.
   7. Sexta: *Asset Inventory* de novo, *Billing → Reports* do dia (o que ainda cobra), e na
      semana seguinte o custo real da janela (cap. 01).

## Onde aciona, onde registra, o que controla

- **Aciona:** `terraform apply` / `destroy` (você; nunca o CI, pelo Termo §4).
- **Registra:** o estado (versões no *bucket*), a saída de `apply`/`destroy` (salve em arquivo:
  `terraform apply 2>&1 | tee apply_<data>.log`), os *audit logs* de criação/exclusão (cap. 10 §4)
  e o *Asset Inventory*.
- **Controla:** tudo o que está no HCL; `deletion_protection`, `force_destroy`,
  `delete_contents_on_destroy`; `-target` para desmontar por partes; *labels* em todo recurso
  (`projeto`, `etapa`, `janela`) — o eixo de leitura da fatura.

## Armadilhas

- `destroy` "concluído" não é "nada de pé". Só o *Asset Inventory* e a fatura da semana seguinte
  dizem isso.
- Estado corrompido ou perdido = recursos órfãos que só o inventário acha. Versionamento no
  *bucket*, sempre.
- `-target` parcial deixa dependências; o `destroy` completo depois pode falhar por ordem —
  leia o erro, não repita às cegas.
- Composer leva 10–20 min para apagar e **falha** se o *bucket* tiver sido apagado antes por
  outra mão. Ordem: ambiente, depois *bucket*.

## Evidência a levar

- `terraform state list` da terça e a saída do `plan -destroy`.
- CSV do *Asset Inventory* da terça e o da sexta, com a diferença anotada.
- `destroy_<data>.log`.
- A tabela de sobreviventes preenchida: o que ficou, o que foi apagado à mão, quando.
- Custo estimado antes (conversa §8) e custo real depois (cap. 01) — lado a lado, rotulados.

## O que você saberá dizer depois

- "Subi e derrubei o ambiente por Terraform, com estado versionado em *bucket* privado; comparei
  o estado com o *Asset Inventory* antes e depois do `destroy`."
- "Sei o que sobrevive a um `destroy`: *bucket* do Composer, *job* de Dataflow, *backups*,
  *slot* de replicação — e apaguei cada um na sexta."
- "O custo estimado da janela era X; o real, lido na semana seguinte, foi Y."
