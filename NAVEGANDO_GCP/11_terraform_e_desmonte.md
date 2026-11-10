# 11 — Terraform, o estado e o desmonte

> **Quando fazer.** **Seg 09**, passos 1, 3 e 4. O desmonte, **qui 12**, segue a [§6.5 do plano](../PLANO_etapa_13.md#65-a-ordem-do-desmonte-rv13-1-02), não este capítulo.

**Em uma frase.** O Docker Compose da nuvem: o `terraform/` descreve tudo o que existe, `apply`
faz existir, `destroy` faz deixar de existir, e o **estado** (um arquivo **local**, D74) é
o que o Terraform acredita que existe. A janela é `apply` em degraus, de sábado a quarta, e desmonte
até quinta; a diferença entre o que o estado diz e o que existe é o que o inventário prova.

**Quanto custa e por quê.** O Terraform em si, nada. O que custa é
o que ele **não** destrói: tudo o que foi criado fora dele (assinatura à mão, *backup on-demand*,
disco do GKE, *job* de Dataflow lançado por alvo do `Makefile`, chave de conta de serviço). O
`destroy` só conhece o HCL.

**Onde fica.** No seu terminal (`make gcp-plan` e `make gcp-apply`, §6.3 do plano), no arquivo
`terraform/terraform.tfstate` (permissão só do dono, porque guarda as senhas do Cloud SQL), e na consola
que diz a verdade: ☰ → *IAM & Admin → Asset Inventory* (`console.cloud.google.com/iam-admin/asset-inventory`)
— **tudo o que existe no projeto, de qualquer serviço, numa lista**.

**O que é deste projeto aqui.** `terraform/` ([ADR-0004](../docs/adr/0004-terraform-como-iac.md)), raiz única com interruptores por degrau,
com Cloud SQL, BigQuery (*datasets*, taxonomia), IAM/contas de serviço/federação, rede, GKE +
Airbyte e Debezium, Composer, Dataflow, Pub/Sub, Secret Manager — e a ordem de dependência entre eles, que
é a ordem de subida e a inversa de descida. O `airbyte/*.tf` que já existe localmente (o Airbyte
configurado por Terraform desde a fase local) é o precedente.

## Roteiro guiado

1. **`.tools/terraform -chdir=terraform state list`** no seu terminal (só leitura): a lista de recursos que o
   estado conhece. Conte. *Por quê:* é o número contra o qual o *Asset Inventory* será comparado.
2. **O estado é um arquivo local** (D74): `terraform/terraform.tfstate`, com permissão só do dono, porque guarda as senhas do Cloud SQL. *Por quê:* em produção ele viveria num *bucket* versionado e privado; nesta janela curta, com um só operador, o `make gcp-apply` guarda uma cópia antes de cada `apply`.
3. **Asset Inventory → Resource.** Filtre por *Asset type* e olhe a contagem por tipo:
   `sqladmin.googleapis.com/Instance`, `bigquery.googleapis.com/Dataset`,
   `composer.googleapis.com/Environment`, `container.googleapis.com/Cluster`,
   `dataflow.googleapis.com/Job`, `pubsub.googleapis.com/Subscription`,
   `storage.googleapis.com/Bucket`, `iam.googleapis.com/ServiceAccountKey` (**deve ser zero**).
   *Por quê:* a lista do que existe **de fato**, independente do Terraform. Exporte
   (*Export → CSV* ou `gcloud asset search-all-resources --scope=projects/<id>`). Faça **na
   segunda** (linha de base). A conferência final é o `make gcp-desmonte-inventario` de quinta (§6.5,
   passo 9), antes de o projeto ser apagado.
4. **Diferença estado × inventário.** O que está no inventário e não no estado é o que o
   `destroy` **não vai apagar**. A lista aceita está em `src/mvp_ed1/gcp/residuos_esperados.yml`:
   o que não estiver lá e não for do Terraform é resíduo. *Por quê:* é o exercício que o critério "Composer e Airbyte criados e
   destruídos na mesma janela" exige de verdade.
5. **O plano de destruição** não se roda à mão: o desmonte é por passos (`make gcp-plan PASSO=n`, §6.5). Leitura, para quinta. Leia a ordem: Composer e GKE
   primeiro (dependem de rede e contas), Cloud SQL depois, IAM por último. Procure
   `deletion_protection` no Cloud SQL (cap. 03: se `true`, o `destroy` falha — e é bom que falhe
   até você decidir) e `force_destroy` nos *buckets* (sem ele, *bucket* com objeto não morre).
   *Por quê:* o plano de destruição lido antes é o que evita a quinta virar depuração.
6. **A lista de sobreviventes conhecidos** — o que **não** morre com o `destroy` e precisa de
   mão ou de HCL explícito. O inventário de quinta confere cada um; o desmonte (§6.5) tem um alvo para cada:

   | Sobrevivente | Por quê | Onde conferir | O que fazer |
   |---|---|---|---|
   | *Bucket* do Composer | do Terraform, com `force_destroy` | Cloud Storage | `make gcp-composer-exportar` antes |
   | *Job* de Dataflow em *streaming* | lançado pelo `Makefile`, não pelo HCL | Dataflow → Jobs | `make gcp-dataflow-parar` antes do `destroy` (cap. 08) |
   | *Backups* do Cloud SQL (*on-demand*) e PITR | sobrevivem à instância se *on-demand* | SQL → Backups | apagar |
   | *Replication slot* / WAL retido | *pod* do Debezium fora sem apagar o *slot* | Cloud SQL → System insights | `make gcp-desmonte-slot` antes da instância |
   | Assinaturas/tópicos criados à mão | fora do HCL | Pub/Sub | apagar |
   | *Datasets* | aqui com `delete_contents_on_destroy=true` | BigQuery | saem no plano do degrau |
      | Discos órfãos do GKE | *PersistentVolume* do Airbyte e do Debezium | Compute Engine → Disks | `make gcp-desmonte-kubernetes` antes do *cluster* |
   | *Logs* | somem com o projeto | Logging | exportar o que for evidência (cap. 10) |
   | Chaves de conta de serviço | não deveriam existir | IAM → Service accounts → Keys | apagar e registrar |

7. **A ordem do desmonte** é a da [§6.5 do plano](../PLANO_etapa_13.md#65-a-ordem-do-desmonte-rv13-1-02), com um alvo e uma prova por passo, e o relógio da §6.4: faturamento desligado na quinta às 12:00 e projeto apagado às 15:00.

## Onde aciona, onde registra, o que controla

- **Aciona:** `terraform apply` / `destroy` (você; nunca o CI, pelo Termo §4).
- **Registra:** o estado (cópia `tfstate_<plano>.bak` a cada `apply`), a saída em
  `data/medicoes/etapa_13/planos/<plano>_apply.txt`, os *audit logs* de criação/exclusão (cap. 10 §4)
  e o *Asset Inventory*.
- **Controla:** tudo o que está no HCL; `deletion_protection`, `force_destroy`,
  `delete_contents_on_destroy`; `-target` para desmontar por partes; *labels* em todo recurso
  (`etapa=13`) — o eixo de leitura da fatura.

## Armadilhas

- `destroy` "concluído" não é "nada de pé". Só o *Asset Inventory* e a fatura da semana seguinte
  dizem isso.
- Estado corrompido ou perdido = recursos órfãos que só o inventário acha. O `gcp-apply` guarda
  uma cópia antes de cada `apply`; em produção, *bucket* versionado.
- `-target` parcial deixa dependências; o `destroy` completo depois pode falhar por ordem —
  leia o erro, não repita às cegas.
- Composer leva 10–20 min para apagar e **falha** se o *bucket* tiver sido apagado antes por
  outra mão. Ordem: ambiente, depois *bucket*.

## Evidência a levar

- `terraform state list` de segunda e os planos de destruição da §6.5.
- CSV do *Asset Inventory* de segunda e a saída do `make gcp-desmonte-inventario`.
- A tabela de sobreviventes preenchida: o que ficou, o que foi apagado à mão, quando.
- Custo estimado antes (Capacidade §2.14) e custo real depois (cap. 01) — lado a lado, rotulados.

## O que você saberá dizer depois

- "Subi e derrubei o ambiente por Terraform, em degraus com plano revisado; comparei o que sobrou
  com a lista esperada, no *Asset Inventory*."
- "Sei o que sobrevive a um `destroy`: *bucket* do Composer, *job* de Dataflow, *backups*,
  *slot* de replicação — e o desmonte tem um alvo e uma prova para cada um."
- "O custo estimado da janela era X; o real, lido na semana seguinte, foi Y."
