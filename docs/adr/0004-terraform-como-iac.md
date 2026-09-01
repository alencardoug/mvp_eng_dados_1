# ADR-0004 — Usar Terraform para levar o ambiente local ao GCP

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 01/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D12 |

## Contexto

A fase GCP precisa provisionar Cloud SQL, BigQuery, IAM, contas de serviço, redes, *policy tags* e
os serviços do fluxo contínuo. Fazer isso pelo console produziria um ambiente que ninguém consegue
recriar — o oposto do princípio **P2** (reprodutibilidade por padrão), que a fase local leva a
sério.

Há ainda o risco **R9**: custo inesperado na nuvem. Provisionamento manual não permite revisar
antes o que será criado.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Terraform** | Padrão de mercado, multi-nuvem, estado explícito, `plan` antes de `apply`; ecossistema maduro para GCP | Mais uma linguagem e mais um estado a gerenciar |
| Console do GCP | Nenhum aprendizado inicial | Ambiente irreprodutível; sem revisão prévia; sem versionamento |
| `gcloud` em scripts | Baixo atrito | Imperativo: não descreve o estado desejado nem detecta divergência |
| Config Connector / Deployment Manager | Nativos do GCP | Menor portabilidade e comunidade menor |

## Decisão

A infraestrutura da fase GCP é descrita em **Terraform**, versionada em `terraform/`, e nenhum
recurso é criado fora dele.

O `terraform plan` é revisado pelo Owner **antes** de qualquer `apply`, funcionando também como
estimativa do que será cobrado.

## Consequências

- **Positivas:** o ambiente de nuvem passa a ser recriável e descartável; a revisão prévia trata
  diretamente o risco **R9**; as *policy tags* que materializam a classificação de sensibilidade
  passam a ser provisionadas como código, junto do restante.
- **Negativas:** o estado do Terraform precisa de armazenamento remoto e de disciplina de uso; há
  curva de aprendizado adicional, concentrada na Etapa 13.
- **Paridade com o GCP:** o Docker Compose local e o Terraform na nuvem descrevem a mesma
  topologia. A equivalência entre os dois é registrada no
  [mapa de paridade](../arquitetura.md#5-mapa-de-paridade-local--gcp).
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md),
  [Plano de Desenvolvimento](../plano_de_desenvolvimento.md),
  [Política de Governança de Dados](../governanca_de_dados.md).
