# Revisão da entrega — plano da Etapa 13

> Dossiê escrito à mão pelo Claude Code, na estrutura do `.claude/skills/revisao/dossie.py`.
> **Transitório**: sai no *commit* que fecha a revisão do plano. Não é documentação do projeto e não
> entra no mapa do README. **É um convite, não uma ordem.**
>
> **Por que à mão:** a entrega é só documentação, e o único comando de `comandos.txt` é
> `make check`, que exige os três bancos de pé. Subi-los para medir um diff sem código nem modelo
> não mede nada desta entrega — e o primeiro comando `docker` depois do *boot* sobe Airbyte e
> Airflow juntos (R11). O portão rodado foi o `make check-offline` (§3).

## 1. Escopo

Intervalo: `8309b66..ce4e850` — leia o diff, ele não é repetido aqui.

```
01979d0 docs: registra a autorização da Etapa 13 e a D68, fase GCP no fator dev
817f25b docs: reduz o GEMINI.md a verificador de fatos e arquiva os registros do Gemini
ed406ce docs: adiciona o plano transitório da Etapa 13
ce4e850 docs: registra no plano da Etapa 13 o crédito, o prazo e a cota do Gemini
```

**O objeto da revisão é o `PLANO_etapa_13.md`** — um plano de execução, revisado **antes** de
qualquer código, como o da Etapa 12. Os outros arquivos registram decisões que o Owner já tomou
(autorização, D68) e não são o foco.

## 2. Mapa de revisão

| Arquivo | Natureza | Revisão |
|---|---|---|
| `PLANO_etapa_13.md` | declaração: o plano inteiro | integral |
| `Abertura_de_projeto.md` (v1.3), `docs/plano_de_desenvolvimento.md` (v3.11), `docs/pendencias.md` (D68) | registro de decisão do Owner | conferir só coerência com o plano |
| `docs/adr/0014…`, `docs/adr/0016…` | nota datada (ADR aceito não se reescreve) | conferir só a nota |
| `GEMINI.md`, `CONVERSAS_COM_CHAT/gemini/` | instrução de agente e registro de conversa | amostragem |

## 3. O que foi executado

**Portão offline, em `ce4e850`:**

```
$ make check-offline
894 passed, 188 deselected in 155.94s (0:02:35)
check-offline: as três etapas passaram
```

**Leituras na conta GCP, só leitura (06/11/2026):**

```
$ gcloud billing accounts list
ACCOUNT_ID            NAME                        OPEN  MASTER_ACCOUNT_ID
0199D3-0FDAC3-ED35E5  Minha conta de faturamento  True
$ gcloud projects list   # 9 projetos, todos na mesma conta; o mais antigo criado em 2026-08-17
$ gcloud compute project-info describe --project analisador-de-risco   # extrato
CPUS_ALL_REGIONS 32.0 0.0
GPUS_ALL_REGIONS 0.0 0.0
IN_USE_ADDRESSES 8.0 0.0
$ gcloud compute regions describe us-central1 --project analisador-de-risco   # extrato
CPUS 200.0 0.0
E2_CPUS 24.0 0.0
N2D_CPUS 16.0 0.0
INSTANCES 24.0 0.0
```

A consola, lida pelo Owner em 06/11: "Você tem R$ 1.740,37 de crédito e 9 dias restantes no seu
teste gratuito."

**Páginas oficiais lidas pelo Claude Code (06/11/2026)** — citação curta, para conferência:

| Fato do plano | Página | O que a página diz |
|---|---|---|
| §3.1 Datastream sem Pub/Sub | docs.cloud.google.com/datastream/docs/destinations | destinos: BigQuery, Cloud Storage e tabelas Iceberg no BigQuery; Pub/Sub não aparece |
| §3.2 retenção travada | docs.cloud.google.com/storage/docs/bucket-lock | "automatically applies a lien on the project"; "Locking a bucket's retention policy is irreversible" |
| §3.3 HMAC | docs.airbyte.com/integrations/destinations/bigquery | GCS Staging recomendado, exige HMAC; `credentials_json` "optional for open-source"; ADC desde 1.1.14 |
| D73 Composer | docs.cloud.google.com/composer/docs/composer-versions | `composer-3-airflow-3.2.2-build.9`, 20/10/2026; a página não diz GA ou Preview |
| D69a Debezium Server | debezium.io/…/debezium-server.html | `debezium.sink.type=pubsub`; 3.7.1.Final; a página **não** afirma o mesmo envelope do Kafka Connect nem a autenticação |
| §0 Free Trial | docs.cloud.google.com/free/docs/free-cloud-features | sem aumento de cota; recursos parados no fim, 30 dias de carência, depois apagados |
| G5 *policy tags* | docs.cloud.google.com/bigquery/docs/column-level-security-intro | Policy Tag Manager não descontinuada; catálogo do Data Catalog em transição para *Knowledge Catalog* |

**Gemini:** a rodada 1 do questionário (`CONVERSAS_COM_CHAT/gemini/2026-11-06_questionario_1.md`)
não produziu resposta — 429 `RESOURCE_EXHAUSTED` em toda chamada com busca na web, em
`gemini-3-flash-preview`, `gemini-3-pro-preview`, `gemini-3.1-pro-preview` e `gemini-flash-latest`.

## 4. Não verificado

1. **Nada do código foi lido para além do inventário.** As contagens do G1 — 192 modelos, "~107"
   com sintaxe só do PostgreSQL, 13 macros, 34 testes singulares — vêm de um `grep` por `::`,
   `plpgsql`, `pg_input_is_valid`, `jsonb`, `distinct on`, `ilike`, `generate_series`, `regexp_`,
   `to_char`, `interval`; o *grep* casa com comentários e não sabe o que é conversão trivial. A
   dimensão real da conversão não foi medida.
2. **Os ~20 módulos Python "presos ao PostgreSQL"** são os arquivos que citam `advisory`, `pg_`,
   `psycopg` ou `postgresql`; nenhum foi lido para dizer o que muda.
3. **A DAG no Composer:** que `fluxo_batch.py` rode com o pacote no *bucket*, que `dbt-core 1.12.3`
   + `dbt-bigquery` instalem sem conflito na imagem do Composer, que a rede deixe o Composer chamar
   a API do Airbyte no GKE. Nada disso foi conferido.
4. **A §3.4** (`create or replace` apaga *policy tags*?) é hipótese.
5. **O cronograma** (§6.1) não tem medição por trás: as durações de cada bloco são estimativa do
   autor, e o custo/dia é o de 15/09, não conferido.
6. **A cota do projeto novo** é suposta igual à de `analisador-de-risco`.
7. **O envelope do Debezium Server** no Pub/Sub ser igual ao do Kafka Connect (D69a).
8. Os itens da V1 da Pendências que a Etapa 13 deveria revisitar não foram cruzados com os blocos.

## 5. Premissas sobre o ambiente

- A Free Trial não bloqueia Composer, GKE, Datastream, Dataflow nem Cloud SQL (a página lista só
  GPU, Windows, Marketplace, VMware e cota).
- Um projeto novo ligado à conta da avaliação herda a cota de 32 vCPUs.
- `us-central1` tem todos os serviços do plano.
- O Owner está disponível todos os dias até 13/11 para os passos que só ele dá.

## 6. Ambiente necessário para esta revisão

**Nada de pé.** É revisão de plano: leitura do repositório, `grep`, e rede para conferir páginas
oficiais. Não suba bancos, Airbyte, Airflow nem *streaming*; não rode `make check`, `make up` nem
nenhum alvo que chame `docker`; não rode `gcloud` nem `terraform`.

## 7. Onde hesitei

- **D69 (a) contra (b).** Recomendei o Debezium Server porque preserva o envelope e o código do
  Beam, mas isso troca o "Datastream" do mapa — e o capítulo 07 do `NAVEGANDO_GCP` foi escrito
  para ele. Se o envelope não for o mesmo, (a) perde a vantagem.
- **D74, estado local do Terraform.** É o oposto do padrão corporativo (P10); escolhi pelo prazo e
  porque o *backend* remoto no mesmo projeto morreria com ele.
- **Escopo inteiro em sete dias.** O Owner recusou o corte preventivo; o plano responde com ponto
  de decisão na quarta 12:00 e "encurta-se o escopo, nunca a margem". Não sei se o cronograma cabe.
- **G1 numa árvore só, dois alvos.** Mais barato de manter, mas cada modelo convertido mexe no
  caminho local e pede `make check` completo antes do *commit*.

## 8. Rodadas

## Rodada 1 — plano da Etapa 13

### Conclusão

**Changes required.** Executado como escrito, o plano não assegura o desmonte até
**12/11/2026 18:00, America/Sao_Paulo**, nem cobre toda a paridade exigida para M6. A estratégia
de projeto dedicado, retenção sem trava e três camadas de desmonte é aproveitável, mas as camadas
de emergência dependem de terminar as anteriores. Há também trabalho de portabilidade ausente
do caminho crítico. Não há medição de esforço que permita afirmar que ele cabe até segunda.

Este é um parecer sobre o **plano**, não sobre uma implementação GCP existente. Referências ao
código demonstram pré-requisitos que a execução precisa contemplar; não reabrem defeitos aceitos
da `v1.1.0`. Nenhum recurso foi consultado ou alterado na conta GCP nesta revisão.

### Escopo e versão

- Estado observado: branch `main`, HEAD `9dac5f82d87af03e2e46b7f7401333291a2c7181`, árvore limpa
  antes deste parecer. Leitura iniciada em 06/11; parecer concluído em 07/11/2026.
- Intervalo exclusivo: `8309b66..9dac5f8`, os cinco commits indicados pelo Owner. O dossiê §1
  termina em `ce4e850`; este parecer inclui também `9dac5f8`, que acrescenta o próprio dossiê.
- Objeto integral: `PLANO_etapa_13.md`, revisão 1, 395 linhas. Código de `8309b66` usado como
  evidência de contexto: o intervalo contém somente documentação. As alterações de autorização,
  D68 e notas datadas nos ADRs são coerentes; não encontrei reescrita das decisões aceitas.
- Requisitos: `AGENTS.md`, `CLAUDE.md` §§5–7, tabela da Etapa 13, Arquitetura §5, ADRs
  0024/0025/0044/0046/0050, D43 e V1. Consultados também ADR-0019 e Governança §§5.2/9 quando
  necessários para verificar entrega idempotente, catálogo e segredos.

### Achados por gravidade

`bloqueante` corresponde a gravidade crítica ou alta; `ajuste`, média; `observação`, baixa.
Situação fica para a resposta do autor.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV13-1-01 | §4 D74; §6.3, linhas 318–330 | O corte de faturamento fica atrás de etapas que podem falhar ou não terminar | bloqueante | **Corrigido** na revisão 2: relógio de emergência independente da §6.5 (§0 regra 2, §6.4) — qui 11:00 abandona o que não saiu, **12:00 desliga o faturamento haja o que houver** (espera de 30 min, depois a consola), 15:00 apaga o projeto com o Owner, guardando o estado `DELETE_REQUESTED` sem chamá-lo de eliminação física; G0 confere antes de tudo a permissão de desligar, o vínculo e a ausência de *lien*. |
| RV13-1-02 | G3; §6.3 passos 2–4 | Ordem de exclusão contradiz D70; resíduos são listados sem procedimento de remoção | bloqueante | **Corrigido**: §6.5 reescrita em 11 passos com ação e prova — produtores e Dataflow, Composer, Debezium e o *slot* no Cloud SQL, `helm uninstall` com Services/PVCs/PVs antes do *cluster*, retenção removida **antes** de apagar *buckets* (todos declarados, os do Beam inclusive, com `force_destroy`), Cloud SQL, rede/IAM/APIs por último, inventário com lista identificada e o orçamento apagado da conta; G3 fixa `deletion_protection=false` no estado para Cloud SQL e GKE. |
| RV13-1-03 | G1; §6.1 | A premissa de conversão majoritariamente por casts não corresponde ao SQL; falta portão de prontidão anterior à janela | bloqueante | **Corrigido**: reproduzido — na minha contagem, 8 de 106 se resumem a *cast* (classificador mais estreito; o do Codex dá 4); de qualquer modo, a premissa caiu. §4 nova com a medição; G1 passa a ter geradores do legado, as sete macros, *snapshots*, testes e contratos; portas P1–P4 antes da janela (§6.2), a janela movida para quarta 07:00 → quinta 07:00 para ganhar um dia de desenvolvimento; critério pendente deixa o M6 incompleto (§0 regra 3). Horas continuam não medidas, e o plano diz isso. |
| RV13-1-04 | G2 itens 1–2 e 4 | Escrita do certificado e publicação GCS não portam as leituras, recuperação, guardas e abertura da época | bloqueante | **Corrigido**: G2.1 com o contrato inteiro — leitura e escrita no BigQuery, *locks* no Cloud SQL separados do *insert*, confirmação do *job* antes de soltar, livro em GCS no lugar do `os.link`, DDL da governança, guarda do `airbyte.py`, `capture_recovery.recover` dentro do escopo (§1) e a época inicial; provas com API simulada e depois reais na terça. |
| RV13-1-05 | D69a; G2 item 3 | Trocar leitura e sink deixa alerta, semeadura, confirmação e cursor dependentes do caminho local | bloqueante | **Corrigido**: G2.3 inclui semeadura do BigQuery, alerta no Pub/Sub, *ack* nativo, *offsets* do Debezium Server em disco persistente apagado no desmonte, `schemas.enable=false` e decimal como *string*; a idempotência por `movement_id` vira a **D75**, no ADR-0051 anunciado (insertId e deduplicação do Dataflow não contam como garantia); provas de *replay*, reinício e retorno perdido. |
| RV13-1-06 | G2 item 4; G6 | A prova de G2 não exercita a implantação da DAG proposta para Composer | bloqueante | **Corrigido**: G2.4 declara o layout (`dags/`, `data/`), `PROJETO` do ambiente, diretório temporário do dbt por execução, dependências travadas contra a imagem e o aviso de `google-api-core`, *backend* do Secret Manager e a rede; prova da importação e do dbt no layout antes da janela, *smoke test* no Composer antes do fluxo inteiro. |
| RV13-1-07 | G4–G5 | O módulo de classificação/linhagem fixa dialeto e tipos PostgreSQL; sua portabilidade não tem bloco nem prova | bloqueante | **Corrigido**: reproduzido (`sensitivity.py:147`, `:188`, `:589` com `postgres`). G2.2 novo, antes do G4/G5: dialeto e tipos do alvo, comparação de folhas e classificação de todas as colunas entre os dois alvos. |
| RV13-1-08 | D71; G4; §6.1 | A prova de tags precede a ingestão real e não cobre o ciclo de recriação de todas as colunas sensíveis | bloqueante | **Corrigido**, com decisão do Owner (D71 = o dbt aplica, 07/11): G4 tem o ciclo por produtor — dbt nos modelos; o fluxo converge fontes do Airbyte (tarefa da DAG depois de cada sincronização), *sink* e `governance`; inventário repetido depois de carga, nova sincronização, *rebuild* e reclassificação; prova de chave restrita a `USER_MANAGED`. Nota datada no ADR-0025 no G8. |
| RV13-1-09 | §1; G1/G3; Arquitetura §5 | Authorized views e Secret Manager não têm entrega explícita nem evidência de paridade | bloqueante | **Corrigido**: G1.5 com *authorized views* por `grant_access_to` e prova de negação em `analytics`; G3 com o módulo `segredos` — senhas do Cloud SQL no Secret Manager, *backend* de segredos do Composer, entrega ao Airbyte pelo *provider*; o estado local com segredo é declarado e fica fora do Git. |
| RV13-1-10 | D43; G6/G8; §7 | Uma geração e testes verdes não provam a memória entre capturas; faltam recortes de D43/V1 e portão formal de aceite | ajuste | **Corrigido**: §7.2 com duas capturas e a matriz esperada, comparação normalizada sem metadados de execução, cobertura de §7 do `CLAUDE.md`; D43 nas três identidades (§2.3), sem declarar paridade até a decisão; V1 por recorte no G8; portão formal de aceite e *tag* só com todos os critérios. |
| RV13-1-11 | §1; G6/G8; §6.1/6.3 | A estimativa por serviço vem depois do provisionamento; sexta pode ter custo ainda incompleto | ajuste | **Corrigido**: a estimativa por serviço entra na Capacidade no G0, antes do primeiro `apply` cobrável, e cada degrau confere a sua linha (§6.3); custo real conciliado depois de o faturamento completar, parcial na sexta, relatório exportado na sexta para não depender do acesso depois do fim da avaliação. |

### Evidências, correções e validação

**RV13-1-01 — Tornar a emergência independente do sucesso do destroy. Gravidade: crítica.**

O gatilho é um drain demorado, erro do provider, proteção de exclusão ou inventário não vazio.
D74 e §6.3 só chegam a `billing projects unlink` depois dessas etapas; não dão horário de
abandono da tentativa normal, limite de espera nem caminho de falha. A folga de um dia reduz
probabilidade, mas não resolve a dependência. “Três camadas” assim não asseguram o prazo duro.

Evidência documental: desligar o faturamento interrompe os serviços e a cobrança do projeto;
exige permissões próprias e pode exigir destravar o vínculo. A página diz: “billing on that
project stops”. A responsabilidade pelos gastos anteriores permanece.
[Cloud Billing — desabilitar faturamento](https://docs.cloud.google.com/billing/docs/how-to/modify-project#disable_billing_for_a_project).
Isso sustenta a segunda camada, não a hipótese de que ela precise aguardar um destroy bem-sucedido.

Correção: definir no plano responsável, horário limite **anterior a 18:00**, tempos máximos de
espera e escalada ao Owner para cortar faturamento mesmo com drain/destroy/inventário falhando;
conferir em G0 permissões, vínculo não travado e ausência de liens impeditivos. Manter a confirmação
do Owner para exclusão do projeto e agendá-la antes do limite, inclusive no caminho de emergência.
Validar posteriormente o tratamento de erro sem criar recursos adicionais só para o ensaio;
na execução, guardar a confirmação de faturamento desligado e o estado retornado pela exclusão.
Pedido de exclusão não deve ser rotulado como eliminação física instantânea de todos os recursos.

**RV13-1-02 — Resolver dependências e remover os resíduos. Gravidade: alta.**

§6.3 passo 2 destrói o barato; só no passo 3 remove a retenção do bucket do livro. D70 diz a ordem
contrária. Se houver objeto ainda retido, o primeiro destroy pode parar ali. G3 só prevê
`force_destroy` onde **não** há retenção, deixando também indefinido como esvaziar esse bucket
depois de retirar a política. A documentação confirma a recusa por `retentionPolicyNotMet` e
permite remover política não travada.
[Bucket Lock](https://docs.cloud.google.com/storage/docs/bucket-lock#bucket-retention-policies).

O inventário de discos, load balancers, backups e bucket do Composer é um bom contrapeso à
hipótese de esquecimento; porém **listar não remove**, e nenhum desvio do roteiro trata o que
aparecer. No GKE, “GKE retains persistent disk volumes during cluster deletion.” A Google também
recomenda excluir Services LoadBalancer antes do cluster.
[Excluir cluster](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster).
O requisito de `deletion_protection=false` está explícito só para Cloud SQL; o trecho indexado do
[provider de GKE](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster.html)
exige esse campo falso **no state** para permitir destroy. A versão do provider ainda será escolhida;
não foi inferido aqui um default para ela.

Correção: ordenar parada dos produtores e DAGs/jobs, remoção de retenções/holds, exclusão do
conteúdo, desinstalação do Helm com API Kubernetes ainda disponível, limpeza de Services/PVCs/PVs
e recursos associados, Composer e seus resíduos, cluster, Cloud SQL e finalmente rede/IAM/APIs.
Explicitar proteções de exclusão de cada recurso aplicável, dependências dos providers e tratamento
dos buckets de trabalho do Beam, não apenas do livro. Se D69b vencer, incluir stream/slots nessa
ordem; com D69a, encerrar o consumidor CDC antes do Cloud SQL. Incluir o orçamento no inventário
e na exclusão: mesmo filtrado por projeto, seu gerenciamento envolve a conta de faturamento,
e não se deve presumir sua remoção pelo delete do projeto. O trecho oficial indexado distingue
escopo do orçamento e permissões de exclusão na conta.
[Cloud Billing Budget API — acesso](https://docs.cloud.google.com/billing/docs/how-to/budget-api-access-control).
Validação futura: revisar o grafo de destruição e executar o roteiro completo na janela, com ações
e resultados para cada resíduo; exceções “padrão do projeto” devem ser uma lista identificada,
sem recurso cobrável implicitamente permitido.

**RV13-1-03 — Redimensionar G1 e liberar a janela por evidência. Gravidade: alta.**

Medição estática executada com Python de biblioteca padrão, lendo `dbt/models/**/*.sql`, removendo
comentários SQL/Jinja e buscando o padrão declarado no dossiê:

```text
modelos SQL: 192
matches de ::|plpgsql|pg_input_is_valid|jsonb|distinct on|ilike|generate_series|regexp_|to_char|interval: 106
candidatos cuja sintaxe detectada se resume a casts: 4/106 = 3,8%
demais matches com outras construções: 102/106
modelos gerados entre os 106: 81 (41 em staging/legacy; 40 em trusted/legacy)
arquivos de macros: 13; testes singulares SQL: 34; snapshots SQL: 4
```

Os quatro candidatos são `rejected_legacy_records`, `legacy_selected_capture`, `shipment_items`
e `legacy_capture_transitions`. **3,8% é limite superior lexical**, não promessa de conversão
automática: tipos e macros chamadas ainda exigem conferência. O classificador adicional procurou
JSON, operadores de regex, calendário/fuso, agregações/filtros e `extract(epoch ...)`, preservando
argumentos SQL escritos dentro do Jinja e evitando contar seu `~` de concatenação como regex SQL.
Sem expandir macros, a busca não mede toda a superfície. Exemplo que o cast sozinho esconde:
`trusted/inventory_movements.sql:64`, `order_status_events.sql:50` e `orders.sql:89` extraem epoch
da diferença entre instantes. O número aproximado “~107” não é o defeito; “a maior parte é ::” é.

Não são 102 implementações independentes. Os gerados vêm de `legacy/dbt.py`, `regras.py`,
`classification.py` e `classification.sql`: há JSONB, validação de entradas, regex e conversões
tipadas no **gerador**, não só nos SQL finais (`legacy/dbt.py:235`, `:243`, `:248`). Editá-los à
mão viola a fonte declarativa e perde o trabalho na regeneração. O plano não nomeia essa conversão.
Nas macros, `chave_canonica`, `identidade_canonica`, `dias_no_calendario`, `snapshot_get_time`,
`explicado_pela_quarentena`, `test_fato_reconcilia_com_a_condutora` e
`vigencias_sem_sobreposicao` emitem SQL PostgreSQL; esta última usa literal `timestamptz`
e concatenação de identidade (`test_vigencias_sem_sobreposicao.sql:27`).
`aplicar_acesso_por_camada` e `analisar_apos_materializar` **já** se desativam fora de PostgreSQL;
não precisam de reescrita indiscriminada. `generate_schema_name`, `empilhado`,
`legacy_snapshot_id` e `chave_desconhecida` não apresentam o mesmo SQL específico; seus
resultados/tipos ainda dependem dos modelos e do adaptador.

Correção: incluir geradores, macros de tempo/identidade, snapshots, contratos e testes no G1,
com regeneração determinística para os dois alvos. Caminho crítico inferido da dependência real:
**decisões/ADRs → APIs/datasets e fixture → geradores/macros e catálogo → certificado/livro/Beam →
integração Airbyte/Composer → ensaio concorrente → provas → desmonte**. O `plan` sozinho não
valida essas interfaces. Exigir prontidão funcional anterior ao apply caro, com verificações
residuais da integração agendadas e limitadas logo no começo da janela. O ponto de quarta 12:00
vem tarde para ser o primeiro portão de viabilidade.

Para caber, antecipar os testes baratos e o desenho das tags; retirar da janela desenvolvimento
de dialeto, dependências e catálogo. Cortáveis sem reduzir o critério são apenas extras, como
Autopilot opcional e tentativas adicionais do Gemini. Adiar um critério de M6 exige decisão do
Owner e impede declarar a etapa completa; não autoriza estender o desmonte. Validar com builds
dos dois alvos, declaração revisada e duração realmente observada dos ensaios. **Não medi horas
de implementação e não afirmo impossibilidade absoluta do prazo.**

**RV13-1-04 — Portar o protocolo inteiro do legado. Gravidade: alta.**

G2 prevê staging + MERGE e escrita GCS, mas a DAG começa por recuperação e barreira, não pelo
insert do certificado (`fluxo_batch.py:135`, `:182`). `captura.py:151` lê hashes, gerações e
intrusas com `->>`/`any`; `:236` mistura lock de abertura e insert na mesma transação PostgreSQL.
`capture_recovery.py:171` faz `SET LOCAL` e lê todos os sync_ids; `ledger.py:210`, `:235` lê bruto
e certificado; `:84`, `:145` usa diretório, épocas e publicação por `os.link`. `airbyte.py:126`
abre o warehouse PostgreSQL para a guarda **antes** do disparo. `governance.py:311` instala DDL,
versões e papéis PostgreSQL. Um destino BigQuery configurável não altera essas chamadas.

Contraprova considerada: G2 já cita locks no Cloud SQL e respostas parciais/retorno perdido;
isso cobre parte importante da escrita, mas não o lado leitor e a separação entre os dois bancos.
Excluir “recuperação pelo pacote” (§1) não exclui `capture_recovery.recover`, chamado por toda DAG
e exigido pelo ADR-0050. Também falta abrir e provar uma **época inicial** no projeto novo;
sem ela o portão recusa a primeira captura, por desenho aceito.

Correção: explicitar fronteiras de leitura/escrita BigQuery, armazenamento GCS, locks Cloud SQL,
DDL de governança e todos os chamadores da CLI/DAG; definir confirmação de jobs BigQuery antes
de soltar locks, reenvio sem remedir certificado final e criação da linha de base. Validar os
casos já exigidos pelo ADR-0044/0050 com API simulada e depois uma primeira captura real, recuperação
de tentativa interrompida e segunda captura, sem POST indevido nem alteração de memória anterior.

**RV13-1-05 — Portar também o caminho de alerta e as garantias de entrega. Gravidade: alta.**

G2 item 3 descreve fonte Pub/Sub e sink BigQuery. Entretanto `streaming/pipeline.py:160` semeia
saldo consultando o sink por SQLAlchemy; `transport.py:261` publica alertas com
`confluent_kafka.Producer`; `sink.py:190` depende de `ON CONFLICT DO NOTHING RETURNING` para emitir
**só** eventos que entraram, e depois confirma offsets Kafka. A deduplicação em janela é descrita
no próprio código como otimização, não garantia. Trocar apenas as duas pontas descritas deixa o
alerta preso ao Kafka/PostgreSQL, ou perde a semântica que impede somar o mesmo movimento duas vezes.

A documentação do Debezium confirma o sink `pubsub`, mas também que Server assume a persistência
de offsets, cujo padrão é `FileOffsetBackingStore`; isso precisa sobreviver ao reinício do pod.
Não é a mesma configuração de operação do Kafka Connect.
[Debezium Server — source e sink](https://debezium.io/documentation/reference/stable/operations/debezium-server.html).
O parser local (`envelope.py:60`) espera `op/after/source` no nível superior; o formato JSON precisa
ser fixado explicitamente, incluindo `schemas.enable=false`, decimal como string e timestamps.
Não foi confirmada documentalmente a autenticação ADC/WIF específica desse sink.

Correção: acrescentar semeadura, publicador de alertas, ack nativo, persistência do cursor,
representação de tipos e contrato do sink à D69/G2. **Não assumir** que insertId ou deduplicação
do runner por mensagem equivalem à unicidade por `movement_id` após replay. Se mudar a garantia
do ADR-0019 ou adicionar componente, submeter ao Owner e registrar no ADR anunciado para D69.
Validar snapshot e CDC no parser, decimal/fuso exatos, reinício do pod/worker, replay do mesmo
movimento inclusive fora da janela e após retorno perdido, contagem física e alerta observado.
Os problemas locais aceitos D62/D63 não são novos achados desta revisão nem ficam resolvidos por
uma reconciliação de contagens no BigQuery.

**RV13-1-06 — Definir um artefato executável no Composer. Gravidade: alta.**

Em `fluxo_batch.py:38`, projeto e comando dbt estão fixos em `/opt/mvp_ed1`; a configuração local
de importação e perfil vem de `docker/airflow.Dockerfile:25`, não da DAG. A imagem também instala
SQLAlchemy, psycopg e PyYAML, além do dbt. Subir arquivos num bucket e adicionar dois pacotes PyPI
não estabelece paths, importabilidade, arquivos de dados do pacote nem área gravável do dbt em
cada worker. O projeto ainda referencia `../docs/glossario_de_negocio` e dependências dbt.
URL, alvo e destino do certificado, sozinhos, não fecham a implantação. A rede privada até o
Cloud SQL e a API autenticada do Airbyte também precisa de um caminho definido.

G2 reconhece o risco de dependências e promete conferi-las, o que evita afirmar conflito já
demonstrado. Contudo sua **prova** é só API simulada e Beam em Pub/Sub, e não importa nem executa
a DAG empacotada. O primeiro ensaio previsto é terça, com o taxímetro de todos os serviços ligado.

Correção: declarar layout de distribuição, PYTHONPATH/perfil/alvo, dependências travadas,
configuração/segredos e diretórios temporários por execução; definir testes de importação e
comando dbt no layout de destino, seguidos de smoke test no Composer antes do fluxo completo.
Instalar/subir arquivos de maneira versionada e conferir conectividade e identidade de cada
chamador. Validar que as 15 tarefas percorrem também recuperação/portão, sem montagem local.
Não há bloqueio de versão demonstrado: ver confirmação de D73 abaixo.

**RV13-1-07 — Tornar o catálogo compatível com o novo SQL. Gravidade: alta.**

G5 reutiliza o módulo do Dicionário, e G4 depende da classificação que ele deriva. Esse caminho
não é apenas publicação de JSON: `models/sensitivity.py:147` cria tipos PostgreSQL; `:188` e
`:589–590` analisam e qualificam SQL com `read="postgres"`/`dialect="postgres"`. Receber um manifest
BigQuery não muda esses parâmetros. Construções convertidas podem ser recusadas ou ganhar
linhagem/tipos incorretos; o resultado alimenta inclusive a classificação sensível.

Correção: incluir a adaptação do leitor de manifest, tipos e dialeto e da identidade no consumo
no trabalho anterior a G4/G5; definir origem e validação dos eventos de linhagem por coluna.
Validação: compilar ambos os alvos, comparar conjuntos de folhas e classificações de colunas
representativas e cobrir JSON, casts, janelas, snapshots e agregações. Publicar uma coluna na
consola é prova de integração; não substitui a cobertura da classificação do catálogo todo.
A aceitação de OpenLineage por coluna pela API não foi confirmada nesta rodada.

**RV13-1-08 — Fechar o ciclo de vida das tags, incluindo fontes. Gravidade: alta.**

A suspeita §3.4 está **confirmada**: ao substituir uma tabela, “all existing policy tags on the
original table are dropped”. WRITE_TRUNCATE também remove tags se o schema fornecido não as
incluir.
[BigQuery — impacto nas policy tags](https://docs.cloud.google.com/bigquery/docs/column-level-security-intro).
O dbt suporta a propriedade de coluna `policy_tags`, condicionada a `persist_docs` por coluna;
isso sustenta D71a para os objetos que ele materializa.
[dbt — policy tags](https://docs.getdbt.com/reference/resource-configs/bigquery-configs#policy-tags).

G4 está na segunda, antes das primeiras cargas reais Airbyte de terça; o gatilho declarado é
mudança no YAML. As tabelas de `raw`/`raw_legacy` são fontes, não materializações dbt. D71a não
as protege por si só, e não há passo que garanta reaplicar/conferir tags quando essas colunas
nascem ou são substituídas sem mudança do YAML. Uma prova sobre a carga de desenvolvimento não
vale automaticamente para a carga real que a substitui.

Correção: resolver D71 antes de depender dela no G1; explicitar fluxo inicial e convergência
posterior de tags por proprietário da tabela, incluindo fontes Airbyte, sink e governança.
Identificar quais operações realmente preservam tags na versão fixada; não estou afirmando que
todo sync Airbyte as apague. Validar inventário de **todas** as colunas sensíveis contra o YAML,
depois de carga inicial, novo sync, rebuild/full-refresh e reclassificação, com identidade de
leitura sem privilégio e logs de negação/permissão. Registrar alteração da decisão por ADR/nota
datada apropriada, preservando o texto aceito do ADR-0025.

A prova de credenciais no mesmo G4 deve procurar chaves **USER_MANAGED**, não exigir lista vazia
de todas as chaves: a API distingue também chaves gerenciadas pelo sistema. Essa distinção foi
confirmada em trecho oficial indexado, sem auditoria da conta.
[IAM — tipos de chave](https://docs.cloud.google.com/iam/docs/service-account-monitoring).

**RV13-1-09 — Completar as linhas sem bloco no mapa de paridade. Gravidade: alta.**

Arquitetura §5 exige view de consumo **autorizada** e segredos no **Secret Manager**. G1 só
traduz `+grants`; G3 lista módulos e identidades, sem authorized views, Secret Manager ou sua
integração com Composer/Airbyte. A única menção a Secret Manager é a alternativa HMAC rejeitada
em D72. Não há prova de que o analyst leia consumption sem acesso às tabelas subjacentes.

Concessão à identidade e autorização da view são mecanismos diferentes: “The grants config and
the grant_access_to config are distinct.”
[dbt — authorized views](https://docs.getdbt.com/reference/resource-configs/bigquery-configs#authorized-views).
Portanto o `+grants` citado não supre sozinho a linha do mapa; ampliar acesso a analytics para
fazer a consulta passar alteraria a política aceita.

Correção: mapear autorização das views aos datasets necessários, identidades consumidoras,
segredos remanescentes e obtenção em runtime, sem chave de serviço ou HMAC. Validar leitura das
views, negação de acesso direto às camadas internas e leitura do segredo só pelo serviço
destinatário. Se o Owner decidir eliminar uma dessas linhas, registrar a mudança arquitetural
antes da execução, sem declarar paridade com o mapa antigo.

**RV13-1-10 — Fazer a prova distinguir exercício de teste vazio. Gravidade: média.**

§7 fixa uma geração e compara contagens/PASS/checksums. Num projeto vazio, uma captura não dá
“anterior certificada”: `trusted/legacy/legacy_capture_transitions.sql:38` só escolhe anterior
existente; sem ela o intervalo não é exercitado. Não há roteiro para duas capturas com mudança
controlada, preservação da primeira e tratamento de exclusão física, linha expressa do mapa.
Também não basta contar PASS para conferir todas as tabelas/casos de borda exigidos por §7 do
CLAUDE.md. D43 cobre no plano apenas `chave_canonica`, mas a pendência registra **três** noções de
identidade; as formas a comparar estão em `tests/test_legado_remocao.py:237–252`, incluindo bases,
separadores, limites e UUID. Não foi executado SAFE_CAST nesta revisão; não se afirma igualdade
ou divergência específica sem a medição.

Correção: incluir cenário de memória/exclusão entre capturas e matriz de resultados esperados,
comparação de dados normalizados com exclusão explícita dos metadados de execução e prova dos
casos de borda; conservar evidências fora do projeto antes do teardown. Para D43, registrar
resultado das três identidades e decisão do Owner antes de afirmar paridade; não unificar
tratamento por conta própria. Transformar a referência genérica de G8 à V1 em recortes antes das
alterações correspondentes: lote 1 para livro/recuperação, lote 2 para identidade/leitura, lote 3
para catálogo/fuso; itens não exercitados continuam abertos, com motivo.

Acrescentar ao aceite G8 a conferência de §7 inteira, incluindo migrações do zero, cobertura,
segredos/.gitignore e revisão integral do declarativo pelo Owner, distinguindo-a do review técnico
do `plan`. Se quarta 12:00 restar critério obrigatório, o desmonte prossegue e **M6 fica
incompleto**; pendência registrada não equivale a conclusão nem autoriza a tag de aceite.

**RV13-1-11 — Medir custo no momento certo. Gravidade: média.**

O mapa §1 põe a estimativa **por serviço** no G6, já durante a janela. G3 só exige contagens do
plan, e §6.1 oferece totais antigos e explicitamente não conferidos. Isso não satisfaz a
estimativa anterior ao provisionamento do ADR-0024/Arquitetura §4. Os rótulos “estimado” estão
corretos; não há achado de custo inventado, e não se propõe uma nova estimativa sem medi-la.

G8 reconhece atraso de 24–48 horas, mas o desmonte barato pode terminar quinta 18:00 e o aceite
está em quinta/sexta. A documentação admite até dois dias para os gastos aparecerem depois do
desligamento; sexta pode ainda não conter o total final.
[Cloud Billing — cobranças após desligamento](https://docs.cloud.google.com/billing/docs/how-to/modify-project#disable_billing_for_a_project).

Correção: fazer a planilha por serviço/região/configuração/duração um pré-requisito de cada apply,
com fonte e data, dimensionamento e cotas reais do projeto novo. Exportar as medições técnicas
antes de excluir recursos e coletar faturamento depois, identificando crédito consumido/custo de
uso separadamente do valor pago. Na sexta, marcar custo parcial quando aplicável e deixar o
fechamento econômico/aceite pendente até conferir a completude; isso não estende a vida dos recursos.
Validação: estimativa aprovada antes do apply e custo final conciliado por projeto/serviço e período.

### Decisões e hipóteses que não viraram defeito

| Item | Resultado desta rodada |
|---|---|
| D68 | Autorização e fator `dev` já decididos; não exigir alto volume nem nova autorização. |
| D69 | Sink Pub/Sub oficial confirmado. D69a é alternativa plausível, condicionada ao protocolo completo de RV13-1-05 e à prova de autenticação/envelope. Não se recomenda substituir ferramentas por preferência. |
| D70 | Retenção sem trava é removível e evita o bloqueio irreversível identificado pelo autor. A decisão do Owner precisa aceitar explicitamente a diferença para a retenção travada do ADR-0050; não reescrever o ADR aceito. |
| D71 | Hipótese resolvida documentalmente; D71a tem suporte documentado, com `persist_docs` por coluna. Falta fechar também as fontes e a ordem de execução (RV13-1-08). |
| D72 | Documentação Airbyte confirma Standard Inserts sem staging externo, JSON de credencial opcional no OSS e ADC desde 1.1.14. **Não confirma a combinação concreta chart/pod de job/KSA/WIF**; provar no conector que executa a carga, sem chave, como portão de integração. [Destino BigQuery](https://docs.airbyte.com/integrations/destinations/bigquery). |
| D73 | A imagem `composer-3-airflow-3.2.2-build.9`, Python 3.11.8 e lançamento em 20/10/2026 constam da [lista oficial](https://docs.cloud.google.com/composer/docs/composer-versions). Airflow 3 é GA desde 15/04/2026, a partir do build 3.1.7-build.4; 3.2.2 aparece em 29/07 e build.9 em 20/10 nas [release notes](https://docs.cloud.google.com/composer/docs/release-notes). Não há evidência de que seja Preview. |
| Composer — tempo | A [criação](https://docs.cloud.google.com/composer/docs/composer-3/create-environments) é documentada em aproximadamente **25 minutos**, não SLA. Sozinha, essa duração não inviabiliza 34 h; configuração, pacotes e reexecuções precisam de margem. As release notes de 30/10 registram possível degradação com determinadas versões de `google-api-core`; considerar no exame de dependências já previsto, sem afirmar que o ambiente futuro está afetado. |
| D74 | Projeto dedicado e state local ignorado (`.gitignore:25`, `:60`) não são defeitos por si; cópia em `data/` permanece local e precisa existir até a confirmação do desmonte. Corrigir RV13-1-01/02. |
| WIF GitHub | G4 já exige attribute condition no repositório, alinhado ao aviso oficial de restringir admissão no pool. Não há omissão demonstrada nesse ponto. [google-github-actions/auth](https://github.com/google-github-actions/auth#workload-identity-federation). |
| Cotação/cotas | “~107” é aproximação admissível; durações e preços antigos estão rotulados estimados. Os 32 vCPUs observados em outro projeto **não comprovam** a cota nova nem a soma dos pools/workers; G0 já promete lê-la. Não tratei “cabe com folga” como dimensionamento validado. |

### Verificações executadas e resultados

- `git status --short`, branch/HEAD, `git log --oneline 8309b66..9dac5f8`, diff de nomes/estatística
  e trechos das alterações contextuais: cinco commits, dez arquivos de documentação, sem código
  alterado; estado inicial limpo.
- Leitura integral do plano, regras e dossiê; leitura dos ADRs indicados e trechos de requisitos;
  buscas e leituras dirigidas da DAG/Dockerfile, configuração dbt, macros, SQL exemplares e módulos
  de legado, recuperação, governança, Airbyte, classificação/linhagem e streaming citados acima.
- Inventário lexical com Python somente de leitura: resultados reproduzidos em RV13-1-03. Não
  é compilação, medição de runtime nem estimativa de horas. Linhas de módulo não foram usadas como
  medida de esforço.
- **12 páginas oficiais distintas lidas com sucesso**: faturamento; criação de projetos; Bucket
  Lock; configurações BigQuery do dbt; destino BigQuery Airbyte; segurança por coluna BigQuery;
  versões Composer; Debezium Server; google-github-actions/auth; criação Composer 3; exclusão GKE;
  release notes Composer. Buscas adicionais restritas aos domínios autorizados retornaram trechos
  indexados sobre exclusão de projetos, proteção do provider, orçamentos e tipos de chave IAM; não equivalem
  à leitura integral dessas páginas. A página genérica de criação de projetos não respondeu à
  hipótese de exclusão. Tentativas de abrir a página de exclusão e a lista específica de pacotes
  falharam; não foram usadas como confirmação.
- Nenhum `make`, teste, serviço, banco, `.env`, `docker`, `abctl`, `gcloud`, `terraform`, `dbt` ou
  instalação foi executado/tocado. Os **894 passed** continuam sendo evidência **do autor**, em
  `ce4e850`, não resultado independente desta rodada. Única escrita: este acréscimo em `REVISAO.md`.

### Limitações e perguntas abertas

1. Sem conta GCP: não foram confirmados permissões de emergência, vínculo de billing, liens,
   cotas herdadas, capacidade regional, preços atuais ou disponibilidade de todos os serviços na
   Free Trial. Isso não comprova bloqueio desses serviços; exige portões antes do gasto.
2. ADC/WIF no sink Debezium e nos pods de job da versão Airbyte escolhida, envelope real, tipo
   físico de `_airbyte_meta`, igualdade sync_id/job_id e normalização de transporte precisam de
   medição. ADR-0044 trata parte disso como contrato observado **na versão local**, não universal.
3. Compatibilidade exata `dbt-core 1.12.3`/`dbt-bigquery`/pacotes Composer não foi resolvida; a
   consulta à lista de pacotes falhou. Não há conflito de dependência demonstrado nesta revisão.
4. Não foram confirmados suporte a Autopilot, Beam 2.76 no runner escolhido, importação de
   linhagem OpenLineage por coluna nem comportamento das recriações de tags na versão fixada.
5. Não foi lida toda a documentação específica de backups retidos/finais Cloud SQL, soft delete
   GCS, teardown Composer, IAM/API disable e defaults de todos os recursos Terraform. O plano
   deve conferir esses detalhes contra as versões fixadas antes de qualquer apply; o inventário
   e o corte independente de billing continuam necessários. Não foi declarada ausência de resíduos.
6. Sem execução SQL/serviços, não se mediram paridade, concorrência, latência, contagens de dados,
   custos ou tempo de desenvolvimento. As mudanças necessárias acima não são prova de que o
   restante do plano esteja correto. Nenhuma ambiguidade exigiu pergunta ao Owner para emitir
   este parecer; as decisões arquiteturais continuam dele.

### Passagem para o Claude Code

Checklist para a revisão 2; **corrigir o plano antes da implementação**, mantendo estas situações
vazias até a resposta formal do autor:

- [ ] **RV13-1-01:** caminho de emergência com responsável, relógio e limites de espera;
  falha em qualquer etapa anterior não impede unlink/delete dentro do prazo.
- [ ] **RV13-1-02:** retenção removida antes da exclusão; grafo/providers/proteções declarados;
  cada resíduo tem ação e prova, com IAM/rede/APIs disponíveis até terminar a limpeza.
- [ ] **RV13-1-03:** inventário de geradores/macros/testes e portões anteriores à janela;
  cronograma distingue estimativa de prova e não reduz o critério de M6 sem decisão do Owner.
- [ ] **RV13-1-04:** contrato dos backends de certificado/leitura/livro/locks e bootstrap da época,
  com recuperação e guardas em CLI e DAG cobertos pelas validações planejadas.
- [ ] **RV13-1-05:** alerta, semeadura, ack, cursor e idempotência por evento incluídos;
  replay/reinício/retorno perdido e autenticação sem chave têm provas explícitas.
- [ ] **RV13-1-06:** artefato/layout/dependências/configuração de Composer e teste de implantação
  definidos; prova inclui a DAG e o portão do legado, além do Beam.
- [ ] **RV13-1-07:** adaptação de dialeto/tipos do catálogo antes de G4/G5, com comparação das
  folhas/classificação e prova da integração por coluna.
- [ ] **RV13-1-08:** D71 resolvida e ciclo das tags documentado por produtor, inclusive fontes;
  inventário e negações repetidos sobre a carga real após as operações que recriam objetos.
- [ ] **RV13-1-09:** authorized views e Secret Manager com bloco, configuração e testes de
  permissão; cada linha do mapa ganha evidência verificável.
- [ ] **RV13-1-10:** cenário entre capturas, D43 completa e recortes V1/§7 mapeados;
  pendência de critério obrigatório impede aceite/tag M6, preservando o prazo de desmonte.
- [ ] **RV13-1-11:** estimativa por serviço antes dos applies e fechamento econômico somente
  com custo completo; coleta posterior não depende da existência do projeto.

## Rodada 2 — plano da Etapa 13

### Conclusão

**Changes required.** A revisão 2 cobre a maior parte das omissões da rodada 1 e torna o corte de
faturamento independente do `destroy`. Resta um bloqueante na **prova planejada da idempotência
concorrente** do destino quente, além de três ajustes de coerência. A revisão do plano **ainda não
pode ser encerrada**. Não é necessário implementar a D75 para responder ao parecer: é necessário
definir o contrato de concorrência e a prova que libera sua implementação para a janela.

A regra de **M6 incompleto, sem aceite nem `v2.0.0`**, quando faltar critério, está explícita e é
adequada. Ela não transforma uma prova insuficiente em prova de paridade. Nenhuma decisão do
Owner sobre escopo, D68 ou D69–D74 foi reaberta.

### Escopo e versão

- Estado inicial: branch `main`, HEAD `20703a7fa3f915753895a1a8691e2be762f3c363`, árvore limpa
  (`git status --short` sem saída). Parecer em 07/11/2026.
- Intervalo exclusivo: `9dac5f8..20703a7`, três commits: `a7c4266`, `e4c6def`, `20703a7`;
  12 arquivos, somente documentação. Objeto: `PLANO_etapa_13.md`, revisão 2, 458 linhas, respostas
  RV13-1-01…11 e regressões dessas alterações. A rodada 1 acima foi preservada integralmente.
- Requisitos confrontados: `AGENTS.md`, `CLAUDE.md` §§5–7, Plano de Desenvolvimento — Etapa 13,
  Arquitetura §5, Pendências §2 e ADRs citados. As medições estáticas da rodada 1 foram reutilizadas,
  sem recontagem dos modelos nem nova revisão do código local.

### Achados por gravidade

Gravidade alta corresponde a `bloqueante`; média, `ajuste`; baixa, `observação`.
*Situação* fica vazia para a resposta do autor.

| # | Onde | Achado | Veredito | Situação |
|---|---|---|---|---|
| RV13-2-01 | Plano §2.3, L128–133; G2.3, L238–242 | **Alta:** a proposta transacional e a prova de replay não cobrem dois lotes concorrentes com o mesmo `movement_id`; P3 pode passar sem demonstrar a garantia do ADR-0019 | bloqueante | **Corrigido** na revisão 3: a D75 ganhou o contrato — exclusão por chave sob concorrência (citando a concorrência das transações só de acréscimo), conflito e reexecução sem alerta duplo, recuperação do *job* de retorno perdido —, e a prova do G2.3 exige dois lotes concorrentes com a mesma chave nova e duplicata no lote; sem ela o caminho quente não entra na janela. |
| RV13-2-02 | Plano §2.1, L89–90; §6.2, P1/P4, L343–346; §6.3 | **Média:** as saídas das portas permitem seguir com bloqueante ou abrir a janela mesmo sem revisão/aprovação, contrariando as condições obrigatórias do próprio plano | ajuste | **Corrigido**: P1 não deixa começar o bloco do bloqueante; P4 abre parcial só por falha funcional de P2/P3 com dependências satisfeitas, e estimativa não aprovada ou `plan` não revisado impedem o `apply` daquele degrau. |
| RV13-2-03 | Plano §0; G6/G7; §6.1; §6.4, L361–362 | **Média:** Composer/Dataflow devem estar removidos quarta 22:00, mas a janela vai até quinta 07:00 e o desmonte começa então; a vida do Airbyte desde terça também não está incluída na definição da janela | ajuste | **Corrigido**: parte cara quarta 07:00 → 22:00 (provas até 21:00, exportação até 21:30, Composer e Dataflow fora até 22:00), G7 começa quarta 21:30; a janela total vai de terça 08:00 (GKE com Airbyte) a quinta 12:00, com duração real por serviço; as horas de quinta (12:00, 15:00, 18:00) mantidas. |
| RV13-2-04 | Plano §7.1, L399–401; Arquitetura §5, L189/193 | **Média:** o mapa dito “já corrigido (D69, D70, D72)” ainda exige retenção travada e fixa `streaming inserts`, divergindo de D70 e do mecanismo ainda aberto da D75 | ajuste | **Corrigido**: `docs/arquitetura.md` — destino quente idempotente por `movement_id` com a D75 e o ADR-0051, sem fixar mecanismo; livro com a trava em produção e **sem trava** na janela (D70); §7.1 do plano alinhada. |
| RV13-2-05 | Plano D73/G3/§8, L114–118/259–267/434–435 | **Baixa:** “2 nós = 8 vCPU” precisa de topologia explícita; num pool regional padrão, dois nós por zona resultam em seis nós | observação | **Corrigido**: GKE Standard **zonal** (`us-central1-a`), 2 nós `e2-standard-4` no total, autoescala desligada (D73 e §8), com o cálculo do regional registrado; conferido contra a cota real no G0. |

### Evidências, correções e validação

**RV13-2-01 — Exigir prova de concorrência no sink. Gravidade: alta.**

O gatilho são dois lotes simultâneos que contêm o mesmo movimento ainda ausente. O procedimento
proposto lê os IDs ausentes, faz `MERGE` e os devolve; não declara como impede ambos os lotes de
observar a ausência e inserir. A documentação distingue transações que atualizam/excluem de
transações que apenas leem/acrescentam linhas: estas podem executar concorrentemente. Assim,
envolver uma inserção condicional em transação não estabelece, sozinho, exclusão mútua.
[BigQuery — concorrência de transações](https://docs.cloud.google.com/bigquery/docs/transactions#transaction_concurrency).

Contraprova considerada: a D75 está marcada **proposta**, o ADR-0051 rejeita `insertId` como
garantia e G2.3 exige replay, reinício e retorno perdido. Isso mantém a intenção correta, mas não
exige sobreposição de transações: esses ensaios podem passar em série com um destino vulnerável
à concorrência. Não se está afirmando um defeito em código inexistente, nem que todo `MERGE`
necessariamente duplica.

Correção no plano: incluir na D75 a obrigação de impedir decisões concorrentes de inserção da
mesma chave, de tratar conflito/reexecução e de recuperar o resultado de um job cujo retorno se
perdeu. A escolha do mecanismo pode continuar no G2.3. A prova de P3 deve incluir **dois lotes
concorrentes com a mesma chave nova**, duplicata no próprio lote e reenvio após confirmação perdida;
conferir unicidade física, saldo e quais eventos são enviados ao alerta, antes de permitir o
caminho quente na janela. Sem prova, esse critério permanece incompleto. É lacuna residual de
RV13-1-05, exposta pela nova proposta; não reabre D69 nem os defeitos locais D62/D63.

**RV13-2-02 — Separar falha funcional de impedimento para provisionar. Gravidade: média.**

P1 oferece “seguir com o bloqueante declarado”, embora §2.1 determine que bloqueante para tudo.
P4 agrega P2/P3, estimativa aprovada e `plan` revisado, mas dá a todas as falhas a mesma saída:
“a janela abre do mesmo jeito”. O gatilho pode ser justamente **ausência de aprovação/revisão**,
não somente um bloco funcional incompleto.

Contraprova: §6.3 exige aprovação do Owner e aplicação do plano salvo; §0.3 impede aceite de M6
incompleto. Não foi demonstrada autorização inequívoca para um `apply` irregular: há instruções
incompatíveis, que precisam de precedência expressa.

Correção: limitar a abertura parcial a falhas funcionais de P2/P3, com dependências dos blocos
restantes satisfeitas e M6 incompleto. Revisão do plano, ausência de bloqueante aplicável,
estimativa e aprovação do `plan` devem continuar pré-requisitos de qualquer `apply` correspondente.
Validação documental: percorrer separadamente P2 falha, P3 falha, estimativa não aprovada e `plan`
não revisado; nos dois últimos casos nenhum recurso daquele degrau nasce. Regressão da revisão 2.

**RV13-2-03 — Unificar os horários de parada e os intervalos de custo. Gravidade: média.**

G6 e §6.1 reservam quarta 11/11 07:00 → quinta 12/11 07:00; G7/§6.5 começam o desmonte quinta
07:00. Entretanto a primeira ação do relógio de emergência exige **Composer e Dataflow fora
quarta 22:00**, com remoção manual se necessário. Não se define se as provas terminam até 22:00
ou se ainda podem usar esses serviços de madrugada. G6 manda exportar as evidências antes de
qualquer destruição, o que também depende desse corte.

Além disso, §1 L71 repete “Composer e Airbyte criados e destruídos na mesma janela”, enquanto
Airbyte nasce terça para P3 (§0.4/§6.1), antes da janela nomeada em G6. O ADR-0024 exige uma
janela de demonstração limitada para ambos; é possível distinguir a janela total da parte cara,
mas o texto atual não o faz.

Contraprova: desligar serviços **mais cedo** não ameaça o limite duro; o corte de billing continua
independente quinta 12:00. O achado é de roteiro/custo ambíguos, não retorno do bloqueio de
RV13-1-01. Correção: declarar uma única hora-limite de provas/exportação e outra de início da
remoção, ou dizer expressamente que quarta 22:00 encerra antecipadamente a parte cara. Definir o
intervalo total que inclui a integração de terça e contabilizar a duração real de cada serviço.
Validar a concordância de §0, G6/G7 e §6.1/6.4/6.5, mantendo unlink quinta 12:00, delete 15:00 e
limite 18:00. Regressão da mudança de cronograma na revisão 2.

**RV13-2-04 — Refletir as decisões no mapa usado como critério. Gravidade: média.**

Em `20703a7`, `docs/arquitetura.md:193` ainda diz **retenção travada**; `:189` ainda fixa o
destino por **streaming inserts**. D70 e a nota datada no ADR-0050 autorizam retenção **sem trava**
na janela. ADR-0051/Streaming agora preservam a garantia de unicidade e deixam o mecanismo D75
aberto; o plano propõe DML transacional. A mudança `a7c4266` atualizou a linha da captura, mas não
essas duas linhas, embora §7.1 diga que o mapa já foi corrigido também quanto a D70/D72.

Contraprova: G8 prevê atualizar o mapa, e §0 impede encerrar critério pendente. Isso permite
concluir a transação documental depois, mas não sustenta a afirmação de correção já realizada
nem uma prova de paridade contra o requisito antigo de trava. A linha genérica de Airbyte não
contradiz D72 por si; não há achado separado sobre ela.

Correção: distinguir no mapa a exceção D70 da contrapartida de produção não medida e referenciar
ADR-0051/D75 no destino quente sem fixar um mecanismo ainda não escolhido; alinhar a afirmação de
§7.1. Validar cada linha contra a decisão vigente, mantendo os corpos dos ADRs aceitos intactos.
São células preexistentes que se tornaram divergentes com as decisões deste intervalo.

**RV13-2-05 — Dimensionar o total de nós, incluindo as zonas. Gravidade: baixa.**

A documentação do GKE mostra que pools regionais usam três zonas por padrão: `num-nodes=2`
significa **seis** nós; uma localização de nós explicitamente limitada permite dois no total.
[GKE — criar cluster regional](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/creating-a-regional-cluster).
Com o tipo proposto, isso distingue 8 de 24 vCPU, antes de Cloud SQL e Dataflow. São cálculos de
configurações alternativas, **não cotas ou consumos medidos**.

Contraprova: §8 diz “estimado”, G0 confere a cota nova e não há HCL que demonstre uso do padrão
regional. Portanto não afirmo que a cota será excedida. Registrar no dimensionamento de G0 a
localização do cluster, `node_locations`, quantidade **total** e limites de escalabilidade; conferir
esse total e os demais serviços contra as cotas efetivas antes do `apply`. Observação sobre a
nova estimativa, sem pedir troca de GKE Standard nem reabrir D73.

### Situação independente dos achados da rodada 1

“Resolvido no plano” avalia a resposta documental; não significa implementação validada.

| Achado | Resultado | Seção que responde e fundamento |
|---|---|---|
| RV13-1-01 | Resolvido no plano | §0.2, G0 e §6.4: permissão/vínculo/lien antes dos recursos; abandono quinta 11:00, unlink 12:00 com espera limitada e consola, delete 15:00 independente do `destroy`. `DELETE_REQUESTED` não é chamado de eliminação física. A divergência de parada antecipada está em RV13-2-03. |
| RV13-1-02 | Resolvido no plano | G3 e §6.5: proteções falsas no estado, produtores/job antes da infraestrutura, slot enquanto Cloud SQL existe, Helm/PVCs/PVs/Services antes do cluster, retenção antes dos buckets, orçamento da conta e ação/prova para resíduos. A execução e os defaults do provider permanecem por validar. |
| RV13-1-03 | Parcialmente resolvido | §4 e G1 incluem geradores/macros/snapshots/testes; P2/P3 antecipam provas e §0.3 impede aceite parcial. As saídas P1/P4 ainda precisam do ajuste RV13-2-02. Não se refez a medição de esforço. |
| RV13-1-04 | Resolvido no plano | G2.1 e §1 incluem leitores, recuperação, DDL, guardas, locks Cloud SQL separados da escrita BigQuery e confirmação do job, época inicial e provas simuladas/reais. |
| RV13-1-05 | Parcialmente resolvido | D69/ADR-0051 e G2.3 incluem fonte, envelope/tipos, cursor persistente, ack, semeadura, publicador e garantia por chave. Falta tornar a prova da D75 suficiente sob concorrência: RV13-2-01. |
| RV13-1-06 | Resolvido no plano | G2.4 declara layout, dependências, configuração, diretórios de execução, rede, ensaio antes da janela e smoke test no Composer. Compatibilidade efetiva dos pacotes continua não verificada. |
| RV13-1-07 | Resolvido no plano | G2.2 porta dialeto/tipos/manifest e exige comparação das folhas e classificação de todas as colunas antes de G4/G5. A integração de linhagem tem ressalva explícita em G5. |
| RV13-1-08 | Resolvido no plano | D71, nota datada no ADR-0025 e G4: aplicação por produtor, convergência após sync antes do dbt e inventário repetido após carga, sync, rebuild e reclassificação; prova de negação/permissão e filtro `USER_MANAGED`. |
| RV13-1-09 | Resolvido no plano | G1.5, G3, G2.4 e §7.3 entregam authorized views, Secret Manager e provas de acesso. O backend de Connections/Variables do Composer 3 tem suporte documental; não depende de chave de serviço. |
| RV13-1-10 | Resolvido no plano | §2.3/G1, §7.2 e G8: duas capturas com mudança e matriz esperada, normalização, três identidades D43 sem paridade antecipada, V1 por recorte e definição de pronto/revisão integral pelo Owner. Tag condicionada a todos os critérios. |
| RV13-1-11 | Resolvido no plano | G0/§6.3 exigem estimativa por serviço antes do apply; G8 distingue custo parcial de final e mantém fechamento pendente. Os intervalos de duração precisam da coerência indicada em RV13-2-03. |

### Conferências adicionais e hipóteses descartadas

- **ADR-0051/D75:** a decisão preserva expressamente a garantia do ADR-0019; não a dá como medida.
  O mecanismo é implementação dentro desse contrato enquanto não trocar ferramenta, camada,
  modelagem central ou tratamento de dados. Qualquer mudança desses itens volta ao Owner
  (`CLAUDE.md` §5); não se exige nova decisão apenas por existir o identificador D75. ADR-0051
  identifica expressamente a troca da contrapartida de ADR-0006/0020 e registra o custo de operar
  pod/disco/cursor. Não há contradição **sem registro** que justifique reabrir D69 ou reescrever
  esses ADRs aceitos. O déficit é a prova do mecanismo, RV13-2-01.
- **Secret Manager no Composer 3:** a página oficial documenta backend, prefixos de Connections e
  Variables e acesso pela conta do ambiente sem `gcp_key_path`. A hipótese de backend inexistente
  foi descartada. [Configurar Secret Manager](https://docs.cloud.google.com/composer/docs/composer-3/configure-secret-manager).
- **Ensaio local do Composer:** a página oficial declara suporte a Airflow 3.2.2 desde
  `composer-3-airflow-3.2.2-build.3`, anterior ao build.9 escolhido. A dúvida de suporte pode ser
  retirada de §8; instalação/importação/pacotes continuam por provar. Esse ensaio continua sujeito
  a R11. [Desenvolvimento local](https://docs.cloud.google.com/composer/docs/composer-3/run-local-airflow-environments).
- **Liens:** o comando `gcloud alpha resource-manager liens list` existe e lista os liens do
  projeto selecionado; não foi executado nem demonstrada sua permissão nesta conta.
  [Referência oficial](https://docs.cloud.google.com/sdk/gcloud/reference/alpha/resource-manager/liens/list).
- **Estado com segredos:** G3 reconhece a presença de senhas no state; `.gitignore` cobre
  `terraform.tfstate*` e `data/`, inclusive a cópia. A senha do banco não é uma chave de conta de
  serviço GCP. Não há evidência de chave longeva introduzida pelo plano; conteúdos de state e
  permissões locais não foram inspecionados. D74 não foi reaberta.
- **Linhagem por coluna:** trechos oficiais indexados de `openlineage-mapping` e da integração
  atual dizem que eventos OpenLineage **customizados** materializam arestas por tabela e não
  renderizam linhagem por coluna na consola. O resultado antigo de `/dataplex/docs/open-lineage`
  menciona limites de colunas, mas não demonstra suporte ao produtor customizado proposto.
  Portanto G5 não pode tratar resposta HTTP bem-sucedida como prova por coluna. Sua ressalva
  expressa — linha pendente e M6 incompleto se não houver suporte — já trata essa consequência;
  não foi aberto bloqueante duplicado. Atualizar o “não confirmado” com essa limitação, sem
  escolher nova ferramenta. [Mapeamento OpenLineage](https://docs.cloud.google.com/knowledge-catalog/docs/openlineage-mapping),
  [integração e limitações](https://docs.cloud.google.com/knowledge-catalog/docs/open-lineage).
- **Transação documental:** 51 ADRs aceitos conferidos nos cabeçalhos, excluído o template; o
  índice inclui 0051/D69, e as duas decisões arquiteturais pendentes indexadas seguem D43/D66.
  O total de cinco decisões do Owner em Pendências continua coerente com D62–D64/D43/D66;
  D75 é mecanismo de implementação, não sexta decisão do Owner demonstrada. Notas de D70/D71
  foram acrescentadas sem reescrever os corpos aceitos. Links novos para ADR-0051 e notas
  conferidos por leitura; não houve varredura geral de links. Divergências do mapa: RV13-2-04.

### Verificações executadas / não executadas

- Executados somente comandos de leitura: branch/HEAD/status/log, diff do intervalo e dos
  documentos alterados, `git diff --check 9dac5f8..20703a7` (sem saída), `rg`, `sed`, `cat`, `nl`
  e Python de biblioteca padrão para contar cabeçalhos de ADRs. Resultado da contagem: **51
  aceitos**, mais o template com estado de proposta; este não foi contado como decisão.
- Leitura integral do plano rev. 2, das respostas e evidências da rodada 1; conferência dirigida
  dos requisitos/ADRs e da transação documental. Não se refez a revisão da versão local.
- Rede: **cinco páginas oficiais abertas com sucesso** — Secret Manager Composer 3,
  desenvolvimento local Composer, comando de liens, cluster regional GKE e transações BigQuery;
  busca restrita a `docs.cloud.google.com` retornou os trechos de linhagem citados acima.
  `/dataplex/docs/lineage-integration` falhou e não foi usado como evidência.
- Nenhum teste foi executado. `make check-offline` verde em `20703a7` é informação do autor
  fornecida para esta rodada, não resultado independente. Nenhum `make`, `docker`, `abctl`,
  `gcloud`, `terraform`, `dbt`, instalação, serviço, banco ou `.env` foi executado/tocado.
  Única escrita autorizada: este acréscimo em `REVISAO.md`.

Saídas das conferências estáticas finais (Python somente de leitura; comparação com o arquivo de
`20703a7` e contagem dos cabeçalhos):

```text
$ git status --short
 M REVISAO.md
Rodada 1 e dossie preservados: True
Achados novos: RV13-2-01, RV13-2-02, RV13-2-03, RV13-2-04, RV13-2-05
Situacao vazia nas 5 linhas: True
ADRs aceitos (sem template): 51
```

### Limitações e questões abertas

Não foram verificadas permissões reais de unlink/delete, vínculo de billing, liens, cotas,
disponibilidade/capacidade, preços, grafo Terraform ou resíduos reais. O roteiro agora cobre
orçamento da conta, job Dataflow, bucket Composer/Beam, discos/Services/PVCs/PVs, slot e Secret
Manager; a ausência efetiva de resíduos exige as provas de execução. O corte de billing permanece
necessário mesmo se o inventário falhar. Não se pressupôs eliminação física às 15:00.

WIF nos pods Airbyte/Debezium, envelope/tipos, compatibilidade exata dos pacotes, paridade D43,
correção das tags em cada recriação, custos completos e duração das tarefas continuam sem medição
independente. Nenhum desses fatos foi inventado ou convertido em resultado. A viabilidade de
terminar todo o M6 até o prazo permanece condicionada às provas; a alternativa autorizada é
declarar M6 incompleto e desmontar. Não há pergunta que impeça o autor de corrigir este plano.

### Passagem para o Claude Code

- [ ] **RV13-2-01:** acrescentar contrato de concorrência/reexecução e prova simultânea na D75/G2.3/P3;
  não declarar unicidade por movimento com base apenas em replay serial.
- [ ] **RV13-2-02:** restringir a abertura parcial a blocos funcionalmente prontos; revisão,
  estimativa e aprovação continuam obrigatórias antes dos applies correspondentes.
- [ ] **RV13-2-03:** unificar parada/exportação/desmonte e definir a janela total incluindo Airbyte
  desde terça, com estimativa por duração; preservar as horas de emergência de quinta.
- [ ] **RV13-2-04:** alinhar mapa e §7.1 a D70/ADR-0051/D75, distinguindo produção de janela e
  mecanismo proposto de mecanismo provado.
- [ ] **RV13-2-05:** levar ao dimensionamento de G0 a topologia/quantidade total do pool e a soma
  contra as cotas reais, sem presumir dois nós totais pela quantidade por zona.
