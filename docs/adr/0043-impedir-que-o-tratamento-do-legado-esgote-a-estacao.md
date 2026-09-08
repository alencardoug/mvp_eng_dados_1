# ADR-0043 — Impedir que o tratamento do legado esgote a memória da estação

| Campo | Informação |
|---|---|
| Estado | Aceita |
| Data | 08/09/2026 |
| Decisor | Owner principal |
| Decisão pendente resolvida | D38 |
| Substitui / é substituída por | — |

## Contexto

Em 08/09/2026 a estação travou duas vezes — 23:12 e 01:25 —, sempre do mesmo jeito: o OOM *killer*
escolhia um `backend` do `warehouse_db` com 7,7 e 7,85 GB de RSS anônimo numa máquina de 11,5 GB, o
armazém reiniciava em recuperação de *crash* e o editor ficava inutilizável por minutos antes disso,
enquanto o núcleo empurrava tudo para o *zram*. É a terceira ocorrência da mesma família: o
[ADR-0041](0041-teto-de-memoria-nos-servicos-do-airbyte.md) fechou a versão dela que vinha do
Airbyte, em 07/09/2026.

Desta vez a origem não é ambiente pesado. É o **tratamento do legado**, e a causa é medível.

Os modelos de limpeza do legado são código gerado: cada `stg_legacy__<t>` tem de 60 a 120 kB de SQL,
com dezenas de expressões regulares por coluna. O PostgreSQL sobe isso ao LLVM quando `jit=on` — o
padrão —, e o que o LLVM aloca para compilar a árvore **não volta**. O ganho que o JIT existe para
dar, amortizar a compilação sobre muitas linhas, não se aplica aqui: a expressão é enorme e as
linhas são poucas. O resultado, medido com uma variável só — mesma view, mesma consulta, sessão
recém-aberta:

| | `jit=on` | `jit=off` |
|---|---|---|
| `stg_legacy__carts`, todas as colunas materializadas | **passa de 2 GB** (morta no teto) | **281 MB** |

Sobre isso vinha uma segunda causa, independente. O `staging` é *view* por
[ADR-0016](0016-materializacao-por-camada.md) — passagem, não destino —, e o planejador **embute** a
definição da view no lugar da referência. O modelo `legacy_records` lê as quarenta de uma vez, num
`union all` de quarenta braços: são três megabytes de árvore de expressão para pré-processar numa
consulta só, e isso passa de 2 GB **mesmo com o JIT desligado**. As mesmas quarenta relações, quando
materializadas como tabela, custam 180 MB — com o JIT ligado ou desligado, indiferente, porque a
expressão gigante deixa de ser replanejada a cada leitura.

Nada disso é volume: cada uma dessas relações tem uma linha.

Duas consequências que só apareceram ao medir. A primeira é que o defeito **não era novo, era
silencioso**: os `timeouts` que a segunda e a terceira revisões registraram como "detecção integral
no banco não medida" são esta mesma falha, e por isso o achado R13 nunca fechou. A segunda é que os
três contêineres PostgreSQL subiam com `mem_limit=0` — sem teto de *cgroup* —, então uma consulta
desgovernada não tinha como falhar sozinha: ela competia com o ambiente de trabalho pela memória da
máquina inteira, e ganhava. Redpanda e Kafka Connect já tinham teto pelo
[ADR-0020](0020-debezium-sobre-kafka-connect.md), e os serviços do Airbyte pelo ADR-0041. Os bancos
eram a exceção que sobrou.

## Alternativas consideradas

| Alternativa | A favor | Contra |
|---|---|---|
| **`jit=off` no armazém e `staging` legado como tabela** (escolhida) | Ataca as duas causas medidas, cada uma no seu nível: o custo por view e o custo do leque de quarenta. Ambas declarativas e versionadas — uma linha no `docker-compose.yml`, um bloco no `dbt_project.yml` | Abre exceção por origem no ADR-0016, que até aqui tinha uma regra por camada e nenhuma por origem; e o `staging` legado passa a ocupar disco e a exigir reconstrução |
| Só `jit=off` | Uma linha; resolve o custo por view, que é a causa raiz | Não resolve o `legacy_records`: a união de quarenta braços sobre views continua acima de 2 GB com o JIT desligado, então `make dbt-build` seguiria capaz de travar a estação |
| Só materializar o `staging` legado | Resolve tudo que está medido hoje — sobre tabelas o pico é 180 MB com JIT ligado ou desligado | Deixa de pé a armadilha do JIT para qualquer consulta futura de expressão grande sobre view, e a próxima ocorrência voltaria a aparecer como travamento sem causa aparente |
| `jit_above_cost` alto em vez de desligar | Mantém o JIT para consulta normal e o desliga só para as monstruosas | O limiar é um número arbitrário que ninguém saberá revalidar quando os modelos mudarem de tamanho; e não resolve a união de quarenta braços |
| Cercar só no teste, sem tocar no banco | Não mexe em configuração de armazém | Trata o sintoma no lugar errado: quem estoura a memória é `make dbt-build`, não o `pytest`. O teste é onde o defeito aparece, não onde ele mora |
| Aumentar a memória da máquina | Resolveria por força bruta | Não é decisão de engenharia disponível, e o defeito continuaria — só mudaria o limiar em que ele derruba a estação |

## Decisão

**O `warehouse_db` roda com `jit=off`, os modelos de `staging` do ramo legado são materializados como
tabela, e os três contêineres PostgreSQL declaram teto de 2 GB de memória.**

A exceção de materialização é **por origem, não por camada**: o ramo `retail` do `staging` continua
sendo view, como o ADR-0016 determina. O que sai da regra é o ramo legado, e sai por ser código
gerado de tamanho patológico — não por ser legado.

## Consequências

- **Positivas:** `make dbt-build` e a suíte de testes deixam de ser capazes de derrubar a estação;
  o pico do armazém no `build` completo cai de 7,7 GB para a ordem de centenas de megabytes; a
  detecção integral no banco volta a ser mensurável, o que desbloqueia o achado R13, aberto desde a
  segunda revisão por `timeout`; e os bancos passam a ser tratados pelo mesmo critério de teto que o
  Redpanda, o Kafka Connect e o Airbyte já tinham — a exceção deixa de existir.
- **Negativas:** o ADR-0016 passa a ter uma exceção por origem, e quem ler a regra de camada precisa
  saber que ela existe; o `staging` legado ocupa disco e exige reconstrução quando a limpeza muda, em
  vez de acompanhar a view de graça; `jit=off` vale para o armazém **inteiro**, inclusive para
  consultas analíticas grandes que poderiam se beneficiar do JIT — nenhuma delas foi medida, e a
  troca é aceita porque o custo do JIT aqui é travar a máquina e o ganho é hipotético; e um teto de
  2 GB transforma consulta desgovernada em contêiner reiniciado, o que é falha visível, mas ainda é
  falha.
- **Paridade com o GCP:** as três medidas têm equivalente direto. O `jit` é parâmetro de instância no
  Cloud SQL, onde também vem ligado por padrão — a armadilha viaja junto com o projeto, e a decisão
  precisa viajar com ela; a materialização é a mesma configuração `dbt`, sem mudança nenhuma; e o
  teto de memória, que localmente é `mem_limit` de *cgroup*, na fase GCP é o *tier* da instância
  Cloud SQL, que já é um limite declarado. O BigQuery não entra: o ramo legado é tratado antes dele.
- **Documentos a atualizar:** [Capacidade e Recuperação](../capacidade_e_recuperacao.md) — medições
  na §2, que é o dono documental delas; [Origem Legada](../origem_legada.md) — a materialização dos
  modelos de limpeza; [ADR-0016](0016-materializacao-por-camada.md) — a exceção por origem, apontada
  a partir dele.
