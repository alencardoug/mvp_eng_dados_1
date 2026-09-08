# ADR-0041 — Declarar teto de memória em todo serviço permanente do Airbyte

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 07/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | Parte da D36 — o restante dela, o dimensionamento da Etapa 12, segue aberto |
| Substitui / é substituída por | — |

## Contexto

Em 07/09/2026 a estação de trabalho travou duas vezes, com o OOM *killer* disparando 151 vezes em
uma hora e reinício forçado no botão. O diagnóstico está medido em
[Capacidade §2.8](../capacidade_e_recuperacao.md#28-o-número-de-dimensionamento-não-incluía-o-ambiente-de-trabalho--07092026).

Ao investigar, apareceu um defeito estrutural no dimensionamento do Airbyte local, e ele é a
combinação de dois padrões que sozinhos não estão errados:

- o *chart* entrega `resources.limits: {}` para todo serviço da plataforma — sem limite de *cgroup*;
- o *template* fixa `-XX:MaxRAMPercentage=75.0` em toda JVM (`templates/_helpers.tpl`), e o valor
  **não** é parametrizável por `values.yaml`.

Sem limite no contêiner, "75% da RAM" é lido sobre a **máquina inteira**: cada uma das cinco JVMs
permanentes se considerava autorizada a um *heap* de ~8,6 GB numa máquina de 11,5 GB. Elas não
chegam lá — mas o GC não tem por que ser econômico enquanto houver teto nominal, e nada impede o
inchaço sob pressão.

É exatamente a armadilha que o [ADR-0020](0020-debezium-sobre-kafka-connect.md) já havia encontrado
no Redpanda e no Kafka Connect, e que lá foi fechada por `--memory` e `-Xmx` declarados no
`docker-compose.streaming.yml` ([Capacidade §2.4](../capacidade_e_recuperacao.md#24-medido-na-etapa-7--o-caminho-quente)).
No Airbyte, o mesmo tratamento nunca foi aplicado: o `airbyte/values.yaml` dimensionava apenas os
*jobs* efêmeros — replicação, `check` e `discover` —, e os serviços que ficam de pé o dia inteiro
não tinham teto nenhum.

Corrigir isso é alterar a topologia da ingestão, e por **`CLAUDE.md` §5** não é decisão de quem
implementa. Foi levantada como parte da D36 e devolvida ao Owner, que decidiu por atacar a raiz.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **Declarar `limits.memory` por serviço** (escolhida) | Declarativo, revisável, sobrevive à reinstalação; o Java 21 é *container-aware* e passa a ler `MaxRAMPercentage` sobre o teto do contêiner | Teto apertado demais não faz o GC trabalhar, faz o Kubernetes matar o *pod*; exige medir para dimensionar |
| Limitar o contêiner `kind` inteiro com `docker --memory` | Uma linha, e cobre tudo de uma vez | O limite recai sobre o *kubelet* e o plano de controle junto com as cargas; o Kubernetes passa a despejar *pods* por pressão do nó, e a falha aparece como instabilidade sem causa aparente |
| Sobrescrever `MaxRAMPercentage` por `global.java.opts` | Ataca o número diretamente | Depende de a última bandeira `-XX` repetida vencer — comportamento que o *chart* não promete e que muda sem aviso entre versões; e continua sem limite de *cgroup*, então nada impede o processo de crescer |
| Não fazer nada e confiar no `preflight` | O guarda já garante que os dois ambientes não fiquem de pé juntos, pausando um para subir o outro | Deixa de pé um defeito real: uma JVM sem teto pode inchar sozinha, e o guarda mede antes de subir, não durante |
| Apertar também os limites dos *jobs* | Cortaria o pico, que é o que de fato esgota a máquina | Os limites dos *jobs* estão altos por decisão medida na Etapa 5; *job* morto por limite falha **em silêncio**, que é o pior modo de falha deste projeto |

## Decisão

Todo serviço permanente do Airbyte passa a declarar `resources.limits.memory` e
`resources.requests.memory` em `airbyte/values.yaml` — e **apenas memória**: a CPU fica intocada,
porque a restrição descoberta na Etapa 5 foi CPU e pedido alto demais torna o *pod* não-agendável,
com falha silenciosa.

## Consequências

- **Positivas:** nenhuma JVM permanente pode mais dimensionar o próprio *heap* pela máquina inteira;
  o teto vive no declarativo e sobrevive à reinstalação, ao contrário de um *patch* no cluster; e o
  ambiente local passa a tratar Airbyte, Redpanda e Kafka Connect pelo mesmo critério.

- **Negativas — e esta é a parte que o número não confirma.** O ganho medido é pequeno, e o custo
  aceito é registrar isso em vez de escondê-lo. Com `make sync-airbyte` completando 26.093 linhas
  ([Capacidade §2.9](../capacidade_e_recuperacao.md#29-o-teto-de-memória-do-airbyte-medido--07092026)):

  | Medida | Sem teto | Com teto |
  |---|---|---|
  | JVMs permanentes, ocioso | 2.803 MB | 2.596 MB (−7%) |
  | Pico do cluster durante a sincronização | 4,47 GiB | 4,95 GiB |

  O ocioso cai pouco porque o RSS já estava abaixo dos tetos — teto acima do consumo não aperta
  nada. E **o pico não cai**, porque é dominado pelos *pods de job*, cujos limites não foram
  tocados. Quem impede o travamento da estação não é este ADR: é o `docker/preflight.sh`, que pausa o
  ambiente conflitante antes de subir o pedido, dimensionado pelo pico de **5,0 GB** medido aqui. Este ADR fecha um defeito
  estrutural, não o problema de capacidade.

  Some-se o custo corrente: mais um bloco a manter no `values.yaml`, e limites que precisam ser
  revistos se a carga crescer — teto dimensionado para hoje é dívida amanhã.

- **Paridade com o GCP:** é a mesma disciplina, e lá ela deixa de ser opcional. O
  [ADR-0024](0024-airbyte-e-airflow-no-gcp.md) põe o Airbyte em contêiner no GCP, onde memória é
  cobrada por hora ligada: serviço sem limite declarado é fatura sem teto, e o *autoscaler* não tem
  como decidir sem `requests`. Os valores daqui viram o ponto de partida do dimensionamento de lá, e
  a lição que viaja é a que este ADR registra — dimensionar pelo **pico medido**, não pelo ocioso.

- **Documentos a atualizar:** [`airbyte/values.yaml`](../../airbyte/values.yaml) (a declaração),
  [Capacidade §2.9](../capacidade_e_recuperacao.md) (as medições) e
  [`docs/pendencias.md`](../pendencias.md) (a D36 perde a parte resolvida e mantém a da Etapa 12).
