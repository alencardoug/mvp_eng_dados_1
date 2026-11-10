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
>
> **Atualizado em 09/11/2026**, para a Etapa 13 como ela ficou: nomes, peças e horários reais. O
> que manda na janela é o [plano](../PLANO_etapa_13.md#6-a-janela), e os custos estimados são os da
> [Capacidade §2.14](../docs/capacidade_e_recuperacao.md#214-a-estimativa-da-janela-da-etapa-13--07112026); onde um capítulo citar a conversa de custos, vale a Capacidade.

---

## 1. O plano em uma frase

A janela é a do [plano da Etapa 13](../PLANO_etapa_13.md#61-cronograma-estimado): segunda o Cloud SQL, terça o
GKE e o caminho quente, quarta o Composer, quinta o desmonte. Composer é a peça mais cara e a que este guia mais
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
| Debezium + Redpanda | **Debezium Server** no GKE + **Pub/Sub** (ADR-0051) | [07](07_datastream_e_pubsub.md) |
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

**Durante (de segunda a quarta).** O [calendário](#3-quando-fazer-cada-capítulo) abaixo encaixa cada
capítulo no que estiver de pé. Com o Composer ligado, cada hora custa; ele fica por último, e o que
não depende dele vem antes.

**Depois.** Preencha o caderno de evidências com o que **mediu** — número, captura, consulta —, não
com o que planejou. Planejado e medido não se misturam (P5).

---

## 3. Quando fazer cada capítulo

Sugestão para 09 a 12/11/2026, encaixada nos roteiros do [plano](../PLANO_etapa_13.md#6-a-janela). Passos citados
como §6.x são do plano; os demais são do próprio capítulo.

| Quando | O quê | Depende de |
|---|---|---|
| **Seg 09** | Cap. 00; 01 (só olhar); 02; 03 (passos 1 a 6, 8 e 9) | Cloud SQL, de pé desde 11:30 |
| **Seg 09, ou ter 10 antes do passo 7 do §6.7** | Cap. 04 (1 a 7 e 9); 09 (1 a 3, 5 e 7); 10 (2 a 5); 11 (1, 3 e 4) | O dado de desenvolvimento, que o passo 7 do §6.7 apaga |
| **Ter 10**, depois do passo 6 do §6.7 | Cap. 05 | GKE e Airbyte |
| **Ter 10**, durante a §6.8 | Cap. 07; cap. 08 com o *job* de pé (passos 7 a 9 e 22 a 29); cap. 05 ao vivo (passos 10 a 13) | Debezium, Dataflow |
| **Ter 10**, depois do passo 15 da §6.8 | Cap. 04 de novo (passo 8) e 09 com o dado real | O `dbt build` da nuvem |
| **Qua 11**, ~07:30 a 21:30 | Cap. 06; cap. 08 completo (passos 7 a 17 da §6.9); cap. 10 (1, 6 e 8) | Composer e Dataflow; a parte cara |
| **Qui 12** | O desmonte é a [§6.5 do plano](../PLANO_etapa_13.md#65-a-ordem-do-desmonte-rv13-1-02) | Faturamento desligado às 12:00; projeto apagado às 15:00 |
| **Sex 13 em diante** | Cap. 01 (custo real); cap. 12 | A fatura atrasa até dois dias |

O laboratório (`data/medicoes/estudo_gcp/laboratorio_gcp.html`, fora do Git) roda à parte, no projeto
`mvp-ed1-estudo`, e o calendário dele está na própria página. Vai até quarta à noite.

**Três limites no `mvp-ed1-gcp`, que valem para todos os capítulos:**

1. **Não crie nada à mão** (assinatura, *sink*, *dashboard*, alerta, orçamento): o inventário de
   quinta reprova o que estiver fora da lista (§6.5, passo 9). Para praticar, use o `mvp-ed1-estudo`.
2. **Não dispare nada fora do roteiro** (*Sync now*, *Trigger*, *Clear*, *Publish*): os alvos da
   §6.8 e da §6.9 medem essas execuções.
3. **Não mude configuração pela consola** (*flags*, Query Insights, *Data Access*): o Terraform é a
   fonte, e o próximo `plan` acusaria a diferença.

Se o dia escorregar, corte o que não cobra (10, 09, 07), nunca o desmonte.

---

## 4. As três regras da viagem

1. **Toda tela tem um "onde aciona, onde registra, o que controla".** Se você saiu de um produto
   sem saber os três, não visitou — passou pela porta. É essa tríade que diferencia "vi a
   consola" de "operei o serviço".
2. **Evidência é o que se pode reproduzir.** Captura de tela vale; mais vale o *log* filtrado
   com a consulta que o achou, ou a consulta SQL que devolveu o número. Anote a consulta.
3. **O taxímetro não para no almoço.** Antes de qualquer pausa longa, olhe o
   [capítulo 11](11_terraform_e_desmonte.md) §Armadilhas e decida o que fica ligado de propósito.
