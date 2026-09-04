# ADR-0024 — Replicar Airbyte e Airflow no GCP preservando a paridade

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 04/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D11, D22 |

## Contexto

O [ADR-0003](0003-stack-airbyte-dbt-airflow.md) adotou Airbyte, dbt e Airflow desde a fase local
sob a premissa de que teriam contrapartida na nuvem — mas sem nomear qual. A Etapa 13 precisa desse
nome para escrever o Terraform.

O dbt não é questão: roda igual em qualquer destino. Airbyte e Airflow são, e pela mesma razão —
os dois são serviços que **ficam ligados**, e ficar ligado na nuvem custa dinheiro. É aqui que a
restrição do [Termo](../../Abertura_de_projeto.md) §8, "evitar custos recorrentes desnecessários",
encontra o princípio **P4**, que exige paridade real.

As duas decisões são tratadas juntas porque a resposta é a mesma: **paridade com janela curta**.

## Alternativas consideradas

| Carga (D11) | A favor | Contra |
|---|---|---|
| **Airbyte em contêiner, por Terraform** | Mesmos conectores e mesma configuração versionada: a replicação é replicação, não reconstrução. O critério de sincronização do [ADR-0015](0015-sincronizacao-e-exclusoes.md) atravessa sem ser repensado | Exige GKE ou VM — o Airbyte não roda bem em Cloud Run —, então há custo por hora ligada |
| Datastream ou serviço nativo | Serverless, sem infraestrutura a manter, custo em repouso próximo de zero; é o que a maioria dos times GCP escolhe | Nenhuma configuração do Airbyte se reaproveita, e o critério por tabela precisa ser reexpresso em outra ferramenta — a Etapa 13 vira desenvolvimento, não replicação |
| Airbyte Cloud gerenciado | Mesmos conectores, zero infraestrutura | Assinatura recorrente e dependência de serviço externo à conta GCP; tensão direta com "evitar custos recorrentes" e com o provisionamento integral por Terraform |

| Orquestração (D22) | A favor | Contra |
|---|---|---|
| **Cloud Composer** | Airflow gerenciado: as DAGs sobem praticamente sem alteração, com IAM, *logging* e monitoramento integrados — o operacional que um ambiente real exige. É o que empresas usam | Cobra por ambiente ligado, na ordem de centenas de dólares por mês |
| Airflow em contêiner no GKE | Paridade igualmente alta, custo bem menor, controle total de versão e imagem | Passa a ser você operando o Airflow — banco de metadados, *scheduler*, *workers*, atualizações —, que é exatamente o trabalho que o Composer existe para eliminar |
| Cloud Workflows + Scheduler | Serverless, custo praticamente zero em repouso | As DAGs precisam ser reescritas em outro modelo, e a orquestração deixa de ser comparável entre as fases |

## Decisão

**Airbyte em contêiner** e **Cloud Composer**, ambos provisionados por Terraform
([ADR-0004](0004-terraform-como-iac.md)).

E, junto, a decisão que os torna aceitáveis: **os dois existem apenas durante a janela de
demonstração da Etapa 13**, criados e destruídos pelo mesmo Terraform, com o custo estimado
registrado antes de subir e o custo real registrado depois. Não é um ambiente que fica no ar.

O Termo já classifica "operação continuada na nuvem após a replicação" como fora do escopo — esta
decisão é a aplicação literal dessa fronteira, e não uma exceção a ela.

## Consequências

- **Positivas:** a fase GCP demonstra a arquitetura completa com as mesmas ferramentas, o que torna
  a paridade do **P4** verificável e não declarada; e o custo fica limitado por construção, não por
  disciplina.
- **Negativas:** nada fica no ar para mostrar depois da Etapa 13 — a evidência é o código Terraform,
  o registro de execução e as capturas, não um ambiente vivo. E destruir e recriar o Composer é
  lento (dezenas de minutos), o que torna a janela pouco tolerante a erro de configuração: o
  Terraform precisa estar certo antes de rodar, não depois.
- **Paridade com o GCP:** é o próprio objeto da decisão. Airbyte → Airbyte; Airflow → Airflow
  gerenciado; Terraform provisiona os dois.
- **Documentos a atualizar:** [Arquitetura](../arquitetura.md) §5 — o mapa de paridade;
  [Plano de Desenvolvimento](../plano_de_desenvolvimento.md) — Etapa 13, com a janela e o registro
  de custo; [Capacidade e Recuperação](../capacidade_e_recuperacao.md) — o custo estimado da janela.
