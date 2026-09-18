# Navegando o GCP — a viagem de um dia pelo país onde a Etapa 13 vai morar

> **O que é isto.** Material de estudo do Owner, escrito **antes** da Etapa 13, para que a janela
> na nuvem seja *ligar, olhar, medir, desligar* — e não descobrir a consola com o taxímetro
> correndo. Não é documentação do projeto (o mapa dela está no [README](../README.md)); é o guia
> de viagem: lê-se antes, carrega-se no bolso durante.
>
> **O que não é.** Nada aqui é medição. Custos são os da
> [conversa de arquitetura e custos](../CONVERSAS_COM_CHAT/ARQUITETURA_E_CUSTOS_GCP.md) — estimativas,
> rotuladas como tal. Caminhos de menu são os da consola que eu conheço; a Google renomeia produtos
> e move menus com frequência, então cada capítulo diz também **como achar quando o menu mudou**
> (a barra de busca da consola, tecla `/`, encontra qualquer produto ou recurso pelo nome).

---

## 1. O plano em uma frase

**O plano 1** é a §3 da conversa de custos, em janela curta: segunda liga, terça e quarta correm o
fluxo e colhem evidência, quinta derruba. Composer é a peça mais cara e a que este guia mais
detalha — sobe por último, desce primeiro, e é onde você tem de saber andar sem pensar.

O que vai existir lá, peça a peça, com o que cada uma substitui daqui:

| Aqui (fase local) | Lá (GCP) | Capítulo |
|---|---|---|
| Conta, `.env`, taxímetro nenhum | Projeto, **Billing** e alertas de orçamento | [01](01_faturamento_e_orcamento.md) |
| Papéis do PostgreSQL, `.env` | **IAM**, contas de serviço, *Workload Identity Federation*, **Secret Manager** | [02](02_iam_contas_de_servico_e_segredos.md) |
| PostgreSQL em contêiner (`source_db`, `legacy_db`) | **Cloud SQL for PostgreSQL** | [03](03_cloud_sql.md) |
| `warehouse_db`, nove schemas | **BigQuery**, nove *datasets*, tabelas particionadas, *authorized views* | [04](04_bigquery.md) |
| Airbyte local (abctl) | **Airbyte em contêiner no GKE**, por Terraform | [05](05_airbyte_no_gke.md) |
| Airflow local (`fluxo_batch`) | **Cloud Composer** — a peça cara | [06](06_cloud_composer.md) |
| Debezium + Redpanda | **Datastream** + **Pub/Sub** | [07](07_datastream_e_pubsub.md) |
| Beam no Prism | **Dataflow** | [08](08_dataflow.md) |
| `.yml` do dbt, Dicionário §3, papéis | **Dataplex**, linhagem por coluna, **policy tags** | [09](09_dataplex_linhagem_e_policy_tags.md) |
| `docker logs`, `make dag-status` | **Cloud Logging**, **Monitoring**, *audit logs* | [10](10_observabilidade_logs_e_auditoria.md) |
| Docker Compose | **Terraform**, estado, `plan`/`apply`/`destroy` | [11](11_terraform_e_desmonte.md) |

Antes dos capítulos, leia o [mapa do país](00_mapa_do_pais.md): a gramática comum a toda consola
(projeto, região, API ativada, IAM, *logs*, cota, fatura) e o desenho do fluxo inteiro. Depois de
tudo, o [caderno de evidências](12_caderno_de_evidencias.md) — a lista do que trazer da viagem.

---

## 2. Como usar

**Antes (a leitura, ~2 h).** Mapa do país e os doze capítulos, na ordem. Cada capítulo tem a mesma
estrutura, para que no dia você saiba onde olhar sem reler:

1. *Em uma frase* — o que é e o que substitui;
2. *Quanto custa e por quê* — ordem de grandeza e o que faz o número subir;
3. *Onde fica* — caminho de menu e o padrão da URL;
4. *O que é deste projeto aqui* — os nomes que você vai procurar;
5. *Roteiro guiado* — passos numerados, cada um com "o que olhar" e "por que importa";
6. *Onde aciona, onde registra, o que controla* — a tríade que prova uso real;
7. *Armadilhas* — o que custa dinheiro ou tempo sem avisar;
8. *Evidência a levar* — o que salvar;
9. *O que você saberá dizer depois* — três frases que só quem operou a ferramenta diz.

**Durante (o dia, ~8 h).** O [roteiro do dia](#3-o-roteiro-do-dia) abaixo é o itinerário com
horário. Com o Composer de pé, cada hora custa; o roteiro põe o que **depende** dele no meio do dia,
num bloco só, e o que não depende antes e depois.

**Depois.** Preencha o caderno de evidências com o que **mediu** — número, captura, consulta —, não
com o que planejou. Planejado e medido não se misturam (P5).

---

## 3. O roteiro do dia

Pressupõe o ambiente já de pé (o `apply` é de segunda; este dia é terça ou quarta). Horários são
guia, não contrato; o único fixo é o bloco do Composer, porque é o que custa.

| Hora | Bloco | Capítulo | Depende do Composer? |
|---|---|---|---|
| 08:00 | O taxímetro: fatura de ontem, alertas de orçamento, o que está de pé (*Asset Inventory*) | 01, 11 | não |
| 08:30 | A fundação: IAM, contas de serviço, federação, segredos | 02 | não |
| 09:00 | A origem: Cloud SQL — instância, bancos, conexões, *Query Insights*, *logs* | 03 | não |
| 09:30 | O armazém: BigQuery — *datasets*, partições, *authorized views*, histórico de *jobs*, `INFORMATION_SCHEMA` | 04 | não |
| 10:30 | A carga: Airbyte no GKE — *workloads*, UI, conexões, histórico de sincronização | 05 | não |
| 11:00 | **A peça cara: Cloud Composer** — ambiente, *bucket*, UI do Airflow, disparar `fluxo_batch`, acompanhar, *logs* | 06 | **sim** |
| 12:30 | Almoço — com o `fluxo_batch` rodando, não parado: hora de Composer parado é dinheiro sem evidência | — | — |
| 13:30 | O caminho quente: Datastream e Pub/Sub — *stream*, objetos, atraso, tópicos, assinaturas, puxar mensagem | 07 | não |
| 14:15 | O processamento: Dataflow — grafo do *job*, métricas, *autoscaling*, *logs* de *worker*, chegada em `raw` | 08 | não |
| 15:00 | A governança: Dataplex, linhagem por coluna, *policy tags* e o acesso negado comprovado | 09 | não |
| 15:45 | A prova: Logs Explorer, *audit logs*, Monitoring — a trilha do que você fez hoje | 10 | não |
| 16:30 | O desmonte: Terraform — estado, `plan` de destruição, a lista do que sobrevive a um `destroy` | 11 | não |
| 17:00 | Caderno de evidências: o que foi medido, o que ficou pendente | 12 | — |

Se o dia escorregar, a ordem de corte é a inversa da de custo: corte o que não cobra (10, 09, 07)
antes de encurtar o bloco do Composer — e nunca deixe o bloco 11 de fora: é ele que diz o que a
fatura vai cobrar depois que você sair.

---

## 4. As três regras da viagem

1. **Toda tela tem um "onde aciona, onde registra, o que controla".** Se você saiu de um produto
   sem saber os três, não visitou — passou pela porta. É essa tríade que diferencia "vi a
   consola" de "operei o serviço".
2. **Evidência é o que se pode reproduzir.** Captura de tela vale; mais vale o *log* filtrado
   com a consulta que o achou, ou a consulta SQL que devolveu o número. Anote a consulta.
3. **O taxímetro não para no almoço.** Antes de qualquer pausa longa, olhe o
   [capítulo 11](11_terraform_e_desmonte.md) §Armadilhas e decida o que fica ligado de propósito.
